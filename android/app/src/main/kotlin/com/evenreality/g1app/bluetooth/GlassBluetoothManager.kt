package com.evenreality.g1app.bluetooth

import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.os.Build
import android.os.SystemClock
import android.util.Log
import java.util.ArrayDeque
import java.util.ArrayList
import java.util.EnumMap
import java.util.LinkedHashSet
import java.util.Locale
import java.util.concurrent.CompletableFuture
import java.util.concurrent.ExecutionException

/**
 * Manager responsible for routing Glass BLE traffic through a per-arm write queue.
 *
 * Glasses expose two separate BLE links (left / right). Android only allows a single
 * outstanding write per [BluetoothGatt] at a time, therefore we multiplex packet writes
 * through small FIFO queues to guarantee ordering and to surface failures deterministically.
 */
class GlassBluetoothManager private constructor() {

    private val connections = EnumMap<GlassArm, GlassConnection>(GlassArm::class.java).apply {
        put(GlassArm.LEFT, GlassConnection(GlassArm.LEFT))
        put(GlassArm.RIGHT, GlassConnection(GlassArm.RIGHT))
    }

    /** Returns the singleton [GlassConnection] for a given arm. */
    private fun connectionFor(arm: GlassArm): GlassConnection =
        connections[arm] ?: error("Missing connection for $arm")

    /**
     * Associate a [BluetoothGatt] instance and its write characteristic with an arm.
     * When either argument is null the queue is cleared and any pending requests fail.
     */
    fun updateWriteTarget(
        arm: GlassArm,
        gatt: BluetoothGatt?,
        characteristic: BluetoothGattCharacteristic?,
        reason: String = "connection updated"
    ) {
        val connection = connectionFor(arm)
        val cancelled = LinkedHashSet<WriteBatch>()
        synchronized(connection.lock) {
            connection.gatt = gatt
            connection.writeCharacteristic = characteristic
            if (gatt == null || characteristic == null) {
                connection.lastError = "$reason: GATT unavailable"
                connection.inFlight?.batch?.let(cancelled::add)
                connection.currentBatch?.let(cancelled::add)
                cancelled.addAll(connection.drainQueueLocked())
                connection.clearInFlightLocked()
            } else {
                connection.lastError = null
            }
        }
        if (cancelled.isNotEmpty()) {
            val message = "Queue cleared for $arm: $reason"
            Log.w(TAG, message)
            cancelled.forEach { batch ->
                completeBatch(batch, QueueResult.failure(batch, message))
            }
        }
    }

    /**
     * Expose a dedicated [BluetoothGattCallback] to be used when establishing the connection
     * for the specified arm.
     */
    fun gattCallback(arm: GlassArm): BluetoothGattCallback = connectionFor(arm).callback

    /**
     * Returns true when there are outstanding packets waiting to be written for the given arm.
     */
    fun hasPendingWrites(arm: GlassArm): Boolean {
        val connection = connectionFor(arm)
        synchronized(connection.lock) {
            return connection.inFlight != null || connection.pendingBatches.isNotEmpty()
        }
    }

    /**
     * Enqueue packets for a single arm and block until completion.
     */
    fun writePacketList(
        arm: GlassArm,
        packets: List<ByteArray>,
        description: String = "packets"
    ): QueueResult {
        if (packets.isEmpty()) {
            Log.d(TAG, "writePacketList[$arm]: nothing to send for $description")
            return QueueResult.success(arm, packetsCount = 0, bytes = 0, message = "no packets")
        }

        val connection = connectionFor(arm)
        val batch = WriteBatch(arm, description, packets)
        enqueueBatch(connection, batch)

        return awaitBatchResult(connection, batch)
    }

    /**
     * Enqueue packets for both arms sequentially (left first) and wait for each result.
     * When different payloads are required per arm, pass [rightPackets].
     */
    fun writePacketsToBoth(
        leftPackets: List<ByteArray>,
        rightPackets: List<ByteArray> = leftPackets,
        description: String = "packets"
    ): Map<GlassArm, QueueResult> {
        val results = EnumMap<GlassArm, QueueResult>(GlassArm::class.java)
        results[GlassArm.LEFT] = writePacketList(
            GlassArm.LEFT,
            leftPackets,
            "$description-left"
        )

        results[GlassArm.RIGHT] = writePacketList(
            GlassArm.RIGHT,
            rightPackets,
            "$description-right"
        )
        return results
    }

    /** Clear any queued work with an explicit reason. */
    fun failQueue(arm: GlassArm, reason: String) {
        val connection = connectionFor(arm)
        val cancelled = LinkedHashSet<WriteBatch>()
        synchronized(connection.lock) {
            connection.lastError = reason
            connection.inFlight?.batch?.let(cancelled::add)
            connection.currentBatch?.let(cancelled::add)
            cancelled.addAll(connection.drainQueueLocked())
            connection.clearInFlightLocked()
        }
        cancelled.forEach { batch ->
            completeBatch(batch, QueueResult.failure(batch, reason))
        }
    }

    private fun enqueueBatch(connection: GlassConnection, batch: WriteBatch) {
        val missingTarget: String?
        val startImmediately: Boolean
        synchronized(connection.lock) {
            missingTarget = when {
                connection.gatt == null -> "GATT not connected"
                connection.writeCharacteristic == null -> "write characteristic missing"
                else -> null
            }

            if (missingTarget != null) {
                connection.lastError = missingTarget
                startImmediately = false
            } else if (connection.inFlight == null && connection.currentBatch == null) {
                connection.currentBatch = batch
                connection.inFlight = InFlightWrite(batch, packetIndex = 0)
                startImmediately = true
            } else {
                connection.pendingBatches.addLast(batch)
                startImmediately = false
            }
        }

        if (missingTarget != null) {
            val message = "Unable to enqueue ${batch.label} for ${batch.arm}: $missingTarget"
            Log.e(TAG, message)
            completeBatch(batch, QueueResult.failure(batch, message))
            return
        }

        if (startImmediately) {
            Log.d(TAG, "writePacketList[${batch.arm}]: starting ${batch.label} (${batch.packets.size} packets)")
            if (!issueWrite(connection, batch, packetIndex = 0)) {
                handleImmediateFailure(connection, batch, "Gatt refused initial write")
            }
        } else {
            Log.d(
                TAG,
                String.format(
                    Locale.US,
                    "writePacketList[%s]: queued %s (%d packets). queue=%s",
                    batch.arm,
                    batch.label,
                    batch.packets.size,
                    connection.queueSnapshotLocked()
                )
            )
        }
    }

    private fun awaitBatchResult(connection: GlassConnection, batch: WriteBatch): QueueResult {
        return try {
            batch.future.get()
        } catch (interrupt: InterruptedException) {
            Thread.currentThread().interrupt()
            val message = "Interrupted while waiting for ${batch.label} on ${batch.arm}"
            Log.w(TAG, message, interrupt)
            QueueResult.failure(batch, message, throwable = interrupt)
        } catch (error: ExecutionException) {
            val cause = error.cause ?: error
            val message = "Queue failure waiting for ${batch.label} on ${batch.arm}: ${cause.message}"
            Log.e(TAG, message, cause)
            QueueResult.failure(batch, message, throwable = cause)
        }
    }

    private fun issueWrite(connection: GlassConnection, batch: WriteBatch, packetIndex: Int): Boolean {
        val gatt: BluetoothGatt
        val characteristic: BluetoothGattCharacteristic
        val payload: ByteArray
        synchronized(connection.lock) {
            gatt = connection.gatt ?: return false
            characteristic = connection.writeCharacteristic ?: return false
            payload = batch.packets[packetIndex]
        }

        val accepted = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                gatt.writeCharacteristic(
                    characteristic,
                    payload,
                    BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                )
            } else {
                @Suppress("DEPRECATION")
                run {
                    characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                    characteristic.value = payload
                    gatt.writeCharacteristic(characteristic)
                }
            }
        } catch (t: Throwable) {
            Log.e(TAG, "${batch.arm} ${batch.label}: exception sending packet $packetIndex", t)
            false
        }

        if (!accepted) {
            Log.e(TAG, "${batch.arm} ${batch.label}: gatt refused packet $packetIndex")
        } else {
            Log.v(TAG, "${batch.arm} ${batch.label}: wrote packet $packetIndex (${payload.size} bytes)")
        }
        return accepted
    }

    private fun handleCharacteristicWrite(
        connection: GlassConnection,
        characteristic: BluetoothGattCharacteristic,
        status: Int
    ) {
        val batchToComplete: WriteBatch?
        val resultForBatch: QueueResult?
        val aborted: List<WriteBatch>
        val nextBatch: WriteBatch?
        val nextIndex: Int?

        synchronized(connection.lock) {
            if (connection.writeCharacteristic?.uuid != characteristic.uuid) {
                Log.v(TAG, "Ignoring write callback for unrelated characteristic: ${characteristic.uuid}")
                return
            }

            val inFlight = connection.inFlight
            if (inFlight == null) {
                Log.w(TAG, "${connection.arm}: received write callback with no in-flight request")
                return
            }

            val batch = inFlight.batch
            if (status != BluetoothGatt.GATT_SUCCESS) {
                val message = "${connection.arm} ${batch.label}: write failed with status $status"
                Log.e(TAG, message)
                batchToComplete = batch
                resultForBatch = QueueResult.failure(batch, message, status = status)
                connection.lastError = message
                connection.currentBatch = null
                connection.inFlight = null
                aborted = connection.drainQueueLocked()
                nextBatch = null
                nextIndex = null
            } else {
                val packet = batch.packets[inFlight.packetIndex]
                batch.bytesWritten += packet.size
                if (inFlight.packetIndex + 1 < batch.packets.size) {
                    connection.inFlight = InFlightWrite(batch, inFlight.packetIndex + 1)
                    batchToComplete = null
                    resultForBatch = null
                    aborted = emptyList()
                    nextBatch = batch
                    nextIndex = inFlight.packetIndex + 1
                } else {
                    Log.d(TAG, "${connection.arm} ${batch.label}: completed (${batch.bytesWritten} bytes)")
                    batchToComplete = batch
                    resultForBatch = QueueResult.success(batch)
                    connection.currentBatch = null
                    connection.inFlight = null
                    connection.lastError = null
                    if (connection.pendingBatches.isNotEmpty()) {
                        val pending = connection.pendingBatches.removeFirst()
                        connection.currentBatch = pending
                        connection.inFlight = InFlightWrite(pending, 0)
                        nextBatch = pending
                        nextIndex = 0
                    } else {
                        nextBatch = null
                        nextIndex = null
                    }
                    aborted = emptyList()
                }
            }
        }

        batchToComplete?.let { batch ->
            completeBatch(batch, resultForBatch ?: QueueResult.success(batch))
        }

        if (!aborted.isEmpty()) {
            aborted.forEach { pending ->
                completeBatch(
                    pending,
                    QueueResult.failure(pending, "Aborted because previous write failed")
                )
            }
        }

        if (nextBatch != null && nextIndex != null) {
            if (!issueWrite(connection, nextBatch, nextIndex)) {
                handleImmediateFailure(connection, nextBatch, "Gatt refused follow-up packet")
            }
        }
    }

    private fun handleImmediateFailure(
        connection: GlassConnection,
        batch: WriteBatch,
        message: String,
        status: Int? = null,
        throwable: Throwable? = null
    ) {
        val aborted: List<WriteBatch>
        synchronized(connection.lock) {
            if (connection.currentBatch === batch) {
                connection.currentBatch = null
            } else {
                connection.pendingBatches.remove(batch)
            }
            connection.inFlight = null
            connection.lastError = message
            aborted = connection.drainQueueLocked()
        }

        Log.e(TAG, "${batch.arm} ${batch.label}: $message")
        completeBatch(batch, QueueResult.failure(batch, message, status = status, throwable = throwable))
        aborted.forEach { pending ->
            completeBatch(
                pending,
                QueueResult.failure(pending, "Aborted because previous write failed")
            )
        }
    }

    private fun completeBatch(batch: WriteBatch, result: QueueResult) {
        if (!batch.future.isDone) {
            batch.future.complete(result)
        }
    }

    private inner class GlassConnection(val arm: GlassArm) {
        val lock = Any()
        var gatt: BluetoothGatt? = null
        var writeCharacteristic: BluetoothGattCharacteristic? = null
        val pendingBatches: ArrayDeque<WriteBatch> = ArrayDeque()
        var currentBatch: WriteBatch? = null
        var inFlight: InFlightWrite? = null
        var lastError: String? = null
        val callback: BluetoothGattCallback = object : BluetoothGattCallback() {
            override fun onCharacteristicWrite(
                gatt: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
                status: Int
            ) {
                handleCharacteristicWrite(this@GlassConnection, characteristic, status)
            }
        }

        fun clearInFlightLocked() {
            currentBatch = null
            inFlight = null
        }

        fun queueSnapshotLocked(): String {
            val snapshot = mutableListOf<String>()
            currentBatch?.let { batch ->
                val inFlightIndex = inFlight?.packetIndex ?: -1
                snapshot.add("inFlight=${batch.label}#${inFlightIndex}/${batch.packets.size}")
            }
            pendingBatches.forEach { batch ->
                snapshot.add("pending=${batch.label}")
            }
            if (snapshot.isEmpty()) {
                snapshot.add("empty")
            }
            return snapshot.joinToString(",")
        }

        fun drainQueueLocked(): List<WriteBatch> {
            if (pendingBatches.isEmpty()) return emptyList()
            val drained = ArrayList<WriteBatch>(pendingBatches.size)
            while (pendingBatches.isNotEmpty()) {
                drained.add(pendingBatches.removeFirst())
            }
            return drained
        }
    }

    private class WriteBatch(
        val arm: GlassArm,
        val label: String,
        packets: List<ByteArray>
    ) {
        val packets: List<ByteArray> = packets.map { it.copyOf() }
        val createdAtMs: Long = SystemClock.elapsedRealtime()
        val future: CompletableFuture<QueueResult> = CompletableFuture()
        var bytesWritten: Int = 0
    }

    private data class InFlightWrite(
        val batch: WriteBatch,
        val packetIndex: Int
    )

    companion object {
        private const val TAG = "GlassBtManager"

        val instance: GlassBluetoothManager by lazy(LazyThreadSafetyMode.SYNCHRONIZED) {
            GlassBluetoothManager()
        }
    }
}

enum class GlassArm { LEFT, RIGHT }

data class QueueResult(
    val arm: GlassArm,
    val success: Boolean,
    val packets: Int,
    val bytes: Int,
    val message: String? = null,
    val status: Int? = null,
    val throwable: Throwable? = null
) {
    val isSuccess: Boolean get() = success

    companion object {
        fun success(batch: WriteBatch): QueueResult =
            QueueResult(batch.arm, true, batch.packets.size, batch.bytesWritten)

        fun success(arm: GlassArm, packetsCount: Int, bytes: Int, message: String? = null): QueueResult =
            QueueResult(arm, true, packetsCount, bytes, message)

        fun failure(
            batch: WriteBatch,
            message: String,
            status: Int? = null,
            throwable: Throwable? = null
        ): QueueResult = QueueResult(
            batch.arm,
            false,
            batch.packets.size,
            batch.bytesWritten,
            message,
            status,
            throwable
        )
    }
}
