package com.example.demo_ai_even.bluetooth

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Build
import android.util.Log
import android.widget.Toast
import com.evenreality.g1app.bluetooth.GlassArm
import com.evenreality.g1app.bluetooth.GlassBluetoothManager
import com.example.demo_ai_even.cpp.Cpp
import com.example.demo_ai_even.model.BleDevice
import com.example.demo_ai_even.model.BlePairDevice
import com.example.demo_ai_even.utils.ByteUtil
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.lang.ref.WeakReference
import java.util.UUID

@SuppressLint("MissingPermission")
class BleManager private constructor() {

    companion object {
        const val LOG_TAG = "BleManager"

        private const val SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
        private const val WRITE_CHARACTERISTIC_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
        private const val READ_CHARACTERISTIC_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

        val instance: BleManager by lazy(LazyThreadSafetyMode.SYNCHRONIZED) { BleManager() }
    }

    private lateinit var appContext: Context
    private lateinit var weakActivity: WeakReference<Activity>
    private lateinit var bluetoothManager: BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter
        get() = bluetoothManager.adapter

    private val glassManager = GlassBluetoothManager.instance

    private val bleDevices: MutableList<BleDevice> = mutableListOf()
    private val devicesByChannel: MutableMap<String, MutableList<BleDevice>> = mutableMapOf()
    private val knownPairs: MutableMap<String, BlePairDevice> = mutableMapOf()
    private var connectedDevice: BlePairDevice? = null
    private var lastChannel: String? = null
    private var lastLeftSnapshot: BleDevice? = null
    private var lastRightSnapshot: BleDevice? = null
    private var isScanning: Boolean = false

    private val scanSettings = ScanSettings
        .Builder()
        .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
        .build()

    private val scanCallback: ScanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            super.onScanResult(callbackType, result)
            val device = result?.device ?: return
            val name = device.name ?: return
            if (!name.contains("G\\d+".toRegex())) {
                return
            }
            val parts = name.split("_")
            if (parts.size != 4) {
                return
            }
            if (bleDevices.any { it.address == device.address }) {
                return
            }
            val channelNum = parts[1]
            val bleDevice = BleDevice.createByDevice(name, device.address, channelNum)
            bleDevices.add(bleDevice)
            val bucket = devicesByChannel.getOrPut(channelNum) { mutableListOf() }
            bucket.add(bleDevice)

            val leftDevice = bucket.firstOrNull { it.isLeft() }
            val rightDevice = bucket.firstOrNull { it.isRight() }
            if (leftDevice != null && rightDevice != null) {
                val pair = BlePairDevice(leftDevice, rightDevice)
                val firstDiscovery = knownPairs.put(channelNum, pair) == null
                if (firstDiscovery) {
                    mainScope.launch {
                        BleChannelHelper.bleMC.flutterFoundPairedGlasses(pair)
                    }
                }
            }
        }

        override fun onScanFailed(errorCode: Int) {
            super.onScanFailed(errorCode)
            Log.e(LOG_TAG, "ScanCallback - Failed: ErrorCode = $errorCode")
        }
    }

    private val mainScope: CoroutineScope = MainScope()
    private val ioScope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    fun initBluetooth(context: Activity) {
        appContext = context.applicationContext
        weakActivity = WeakReference(context)
        bluetoothManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.getSystemService(BluetoothManager::class.java)
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        }
        Log.v(LOG_TAG, "BleManager init success")
    }

    fun startScan(result: MethodChannel.Result) {
        if (!checkBluetoothStatus()) {
            result.error("Permission", "", null)
            return
        }
        bleDevices.clear()
        devicesByChannel.clear()
        isScanning = true
        bluetoothAdapter.bluetoothLeScanner.startScan(null, scanSettings, scanCallback)
        Log.v(LOG_TAG, "Start scan")
        result.success("Scanning for devices...")
    }

    fun stopScan(result: MethodChannel.Result? = null) {
        if (!::bluetoothManager.isInitialized || !isScanning) {
            result?.success("Scan stopped")
            return
        }
        if (!checkBluetoothStatus()) {
            result?.error("Permission", "", null)
            return
        }
        bluetoothAdapter.bluetoothLeScanner.stopScan(scanCallback)
        isScanning = false
        Log.v(LOG_TAG, "Stop scan")
        result?.success("Scan stopped")
    }

    fun connectToGlass(deviceChannel: String, result: MethodChannel.Result) {
        Log.i(LOG_TAG, "connectToGlass: deviceChannel = $deviceChannel")
        if (!checkBluetoothStatus()) {
            result.error("Permission", "", null)
            return
        }
        val pair = findPair(deviceChannel)
        if (pair?.leftDevice == null || pair.rightDevice == null) {
            result.error("PeripheralNotFound", "One or both peripherals are not found", null)
            return
        }

        stopScan()
        connectedDevice = pair
        lastChannel = deviceChannel
        updateSnapshots()

        pair.leftDevice?.let {
            it.isConnect = false
            it.gatt?.disconnect()
            it.gatt?.close()
            it.gatt = null
            it.writeCharacteristic = null
        }
        pair.rightDevice?.let {
            it.isConnect = false
            it.gatt?.disconnect()
            it.gatt?.close()
            it.gatt = null
            it.writeCharacteristic = null
        }

        mainScope.launch {
            BleChannelHelper.bleMC.flutterGlassesConnecting(pair.statusJson("connecting"))
        }

        val context = connectionContext()
        if (context == null) {
            result.error("ContextUnavailable", "Unable to obtain context for connection", null)
            return
        }

        pair.leftDevice?.let { device ->
            bluetoothAdapter.getRemoteDevice(device.address)
                .connectGatt(context, false, bleGattCallback(GlassArm.LEFT))
        }
        pair.rightDevice?.let { device ->
            bluetoothAdapter.getRemoteDevice(device.address)
                .connectGatt(context, false, bleGattCallback(GlassArm.RIGHT))
        }

        result.success("Connecting to G1_$deviceChannel ...")
    }

    fun disconnectFromGlasses(result: MethodChannel.Result) {
        val pair = connectedDevice
        if (pair == null) {
            result.success("Disconnected all devices.")
            return
        }

        pair.leftDevice?.let { device ->
            try {
                device.gatt?.disconnect()
                device.gatt?.close()
            } catch (t: Throwable) {
                Log.w(LOG_TAG, "disconnectFromGlasses: left disconnect error", t)
            }
            device.gatt = null
            device.writeCharacteristic = null
            device.isConnect = false
            glassManager.updateWriteTarget(GlassArm.LEFT, null, null, "manual disconnect")
        }

        pair.rightDevice?.let { device ->
            try {
                device.gatt?.disconnect()
                device.gatt?.close()
            } catch (t: Throwable) {
                Log.w(LOG_TAG, "disconnectFromGlasses: right disconnect error", t)
            }
            device.gatt = null
            device.writeCharacteristic = null
            device.isConnect = false
            glassManager.updateWriteTarget(GlassArm.RIGHT, null, null, "manual disconnect")
        }

        updateSnapshots()
        connectedDevice = null
        mainScope.launch {
            BleChannelHelper.bleMC.flutterGlassesDisconnected(pair.statusJson("disconnected"))
        }
        result.success("Disconnected all devices.")
    }

    fun ensureConnected() {
        mainScope.launch {
            ensureConnectedInternal()
        }
    }

    fun reconnectLastDevice() {
        ensureConnected()
    }

    fun senData(params: Map<*, *>?) {
        val rawData = params?.get("data")
        if (rawData !is ByteArray) {
            Log.e(LOG_TAG, "Send data is empty or invalid")
            return
        }
        val lr = params["lr"] as? String
        ioScope.launch {
            when (lr) {
                null -> requestData(rawData)
                "L" -> requestData(rawData, sendLeft = true)
                "R" -> requestData(rawData, sendRight = true)
                else -> requestData(rawData)
            }
        }
    }

    private fun ensureConnectedInternal() {
        if (!checkBluetoothStatus()) {
            return
        }
        val currentChannel = lastChannel
            ?: connectedDevice?.leftDevice?.channelNumber
            ?: connectedDevice?.rightDevice?.channelNumber
        if (connectedDevice == null && currentChannel != null) {
            val pair = findPair(currentChannel)
                ?: createPairFromSnapshots(currentChannel)
            if (pair != null) {
                connectedDevice = pair
                updateSnapshots()
            }
        }
        val pair = connectedDevice ?: return
        val context = connectionContext() ?: return

        BleChannelHelper.bleMC.flutterGlassesConnecting(pair.statusJson("connecting"))

        if (pair.leftDevice?.isConnect != true) {
            bluetoothAdapter.getRemoteDevice(pair.leftDevice!!.address)
                .connectGatt(context, false, bleGattCallback(GlassArm.LEFT))
        }
        if (pair.rightDevice?.isConnect != true) {
            bluetoothAdapter.getRemoteDevice(pair.rightDevice!!.address)
                .connectGatt(context, false, bleGattCallback(GlassArm.RIGHT))
        }
    }

    private fun findPair(channel: String): BlePairDevice? {
        knownPairs[channel]?.let { return it }
        val candidates = devicesByChannel[channel] ?: return null
        val leftDevice = candidates.firstOrNull { it.isLeft() }
        val rightDevice = candidates.firstOrNull { it.isRight() }
        return if (leftDevice != null && rightDevice != null) {
            BlePairDevice(leftDevice, rightDevice).also { knownPairs[channel] = it }
        } else {
            null
        }
    }

    private fun createPairFromSnapshots(channel: String): BlePairDevice? {
        val left = lastLeftSnapshot?.copy(gatt = null, writeCharacteristic = null, isConnect = false)
        val right = lastRightSnapshot?.copy(gatt = null, writeCharacteristic = null, isConnect = false)
        if (left == null || right == null) {
            return null
        }
        val pair = BlePairDevice(left, right)
        knownPairs[channel] = pair
        return pair
    }

    private fun connectionContext(): Context? {
        val activity = if (::weakActivity.isInitialized) weakActivity.get() else null
        if (activity != null) {
            return activity
        }
        return if (::appContext.isInitialized) appContext else null
    }

    private fun checkBluetoothStatus(): Boolean {
        if (!::bluetoothManager.isInitialized) {
            return false
        }
        val activity = if (::weakActivity.isInitialized) weakActivity.get() else null
        if (!bluetoothAdapter.isEnabled) {
            activity?.let {
                Toast.makeText(it, "Bluetooth is turned off, please turn it on first!", Toast.LENGTH_SHORT).show()
            }
            return false
        }
        if (activity != null && !BlePermissionUtil.checkBluetoothPermission(activity)) {
            return false
        }
        return true
    }

    private fun bleGattCallback(arm: GlassArm): BluetoothGattCallback {
        val delegate = glassManager.gattCallback(arm)
        return object : BluetoothGattCallback() {
            override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
                super.onConnectionStateChange(gatt, status, newState)
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    gatt?.discoverServices()
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    handleGattDisconnect(arm, gatt)
                }
            }

            override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
                super.onServicesDiscovered(gatt, status)
                Log.d(LOG_TAG, "BluetoothGattCallback[$arm] - onServicesDiscovered: $gatt, status = $status")
                val pair = connectedDevice ?: return
                val device = if (arm == GlassArm.LEFT) pair.leftDevice else pair.rightDevice
                if (device == null) {
                    return
                }
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    Log.e(LOG_TAG, "Service discovery failed for $arm with status $status")
                    glassManager.updateWriteTarget(arm, null, null, "service discovery failed")
                    return
                }
                device.gatt = gatt
                val server = gatt?.getService(UUID.fromString(SERVICE_UUID))
                val readCharacteristic = server?.getCharacteristic(UUID.fromString(READ_CHARACTERISTIC_UUID))
                val writeCharacteristic = server?.getCharacteristic(UUID.fromString(WRITE_CHARACTERISTIC_UUID))
                if (readCharacteristic == null || writeCharacteristic == null) {
                    Log.e(LOG_TAG, "Characteristics missing for $arm from $server")
                    glassManager.updateWriteTarget(arm, null, null, "characteristic missing")
                    return
                }
                gatt.setCharacteristicNotification(readCharacteristic, true)
                device.writeCharacteristic = writeCharacteristic
                val descriptor = readCharacteristic.getDescriptor(UUID.fromString("00002902-0000-1000-8000-00805f9b34fb"))
                descriptor?.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
                val descriptorWrite = descriptor?.let { gatt.writeDescriptor(it) } ?: true
                Log.d(LOG_TAG, "Descriptor write [$arm]: $descriptorWrite")
                gatt.requestMtu(251)
                gatt.device?.createBond()
                device.isConnect = true
                glassManager.updateWriteTarget(arm, gatt, writeCharacteristic, "services discovered")
                updateSnapshots()

                if (pair.isBothConnected()) {
                    BleChannelHelper.bleMC.flutterGlassesConnected(pair.toConnectedJson())
                }

                ioScope.launch {
                    requestData(byteArrayOf(0xf4.toByte(), 0x01.toByte()))
                }
            }

            override fun onCharacteristicChanged(
                gatt: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
                value: ByteArray
            ) {
                super.onCharacteristicChanged(gatt, characteristic, value)
                mainScope.launch {
                    val isLeft = gatt.device.address == connectedDevice?.leftDevice?.address
                    val isRight = gatt.device.address == connectedDevice?.rightDevice?.address
                    if (!isLeft && !isRight) {
                        return@launch
                    }
                    val isMicData = value.isNotEmpty() && value[0] == 0xF1.toByte()
                    if (isMicData && value.size != 202) {
                        return@launch
                    }
                    if (isMicData) {
                        val lc3 = value.copyOfRange(2, 202)
                        val pcmData = Cpp.decodeLC3(lc3)
                        Log.d(this::class.simpleName ?: LOG_TAG, "LC3 length=${lc3.size} pcm=${pcmData?.size}")
                    }
                    BleChannelHelper.bleReceive(
                        mapOf(
                            "lr" to if (isLeft) "L" else "R",
                            "data" to value,
                            "type" to if (isMicData) "VoiceChunk" else "Receive"
                        )
                    )
                }
            }

            override fun onCharacteristicWrite(
                gatt: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
                status: Int
            ) {
                delegate.onCharacteristicWrite(gatt, characteristic, status)
            }
        }
    }

    private fun handleGattDisconnect(arm: GlassArm, bluetoothGatt: BluetoothGatt?) {
        Log.w(LOG_TAG, "Gatt disconnected for $arm: $bluetoothGatt")
        glassManager.updateWriteTarget(arm, null, null, "connection lost")
        val pair = connectedDevice
        if (pair != null) {
            if (arm == GlassArm.LEFT) {
                pair.leftDevice?.apply {
                    isConnect = false
                    writeCharacteristic = null
                    gatt = null
                }
            } else {
                pair.rightDevice?.apply {
                    isConnect = false
                    writeCharacteristic = null
                    gatt = null
                }
            }
            updateSnapshots()
            mainScope.launch {
                BleChannelHelper.bleMC.flutterGlassesDisconnected(pair.statusJson("disconnected"))
            }
        }
        try {
            bluetoothGatt?.close()
        } catch (t: Throwable) {
            Log.w(LOG_TAG, "Error closing gatt for $arm", t)
        }
    }

    private fun updateSnapshots() {
        lastLeftSnapshot = connectedDevice?.leftDevice?.copy(
            gatt = null,
            writeCharacteristic = null,
            isConnect = false
        )
        lastRightSnapshot = connectedDevice?.rightDevice?.copy(
            gatt = null,
            writeCharacteristic = null,
            isConnect = false
        )
    }

    private fun requestData(data: ByteArray, sendLeft: Boolean = false, sendRight: Boolean = false) {
        val sendBoth = !sendLeft && !sendRight
        Log.d(
            LOG_TAG,
            "Send ${when {
                sendBoth -> "both"
                sendLeft -> "left"
                else -> "right"
            }} data = ${ByteUtil.byteToHexArray(data)}"
        )
        if (sendBoth) {
            val results = glassManager.writePacketsToBoth(listOf(data), description = "payload-${data.size}")
            GlassArm.values().forEach { arm ->
                val result = results[arm]
                if (result == null || !result.isSuccess) {
                    queueWrite(arm, data)
                }
            }
        } else {
            if (sendLeft) {
                queueWrite(GlassArm.LEFT, data)
            }
            if (sendRight) {
                queueWrite(GlassArm.RIGHT, data)
            }
        }
    }

    private fun queueWrite(arm: GlassArm, data: ByteArray): Boolean {
        val device = if (arm == GlassArm.LEFT) connectedDevice?.leftDevice else connectedDevice?.rightDevice
        if (device?.gatt == null || device.writeCharacteristic == null) {
            Log.w(LOG_TAG, "queueWrite: missing gatt or characteristic for $arm, fallback to legacy write")
            return fallbackWriteAndReturn(arm, data)
        }
        val result = glassManager.writePacketList(arm, listOf(data), "payload-${data.size}")
        return if (result.isSuccess) {
            true
        } else {
            Log.e(LOG_TAG, "Queue write failed for $arm: ${result.message}")
            fallbackWriteAndReturn(arm, data)
        }
    }

    private fun fallbackWriteAndReturn(arm: GlassArm, data: ByteArray): Boolean {
        val device = if (arm == GlassArm.LEFT) connectedDevice?.leftDevice else connectedDevice?.rightDevice
        if (device == null) {
            Log.e(LOG_TAG, "fallbackWrite: no device available for $arm")
            return false
        }
        val success = device.sendData(data)
        if (!success) {
            Log.e(LOG_TAG, "fallbackWrite: writeCharacteristic failed for $arm")
        }
        return success
    }

    private fun BlePairDevice.statusJson(status: String): Map<String, Any> = mapOf(
        "leftDeviceName" to (leftDevice?.name ?: ""),
        "rightDeviceName" to (rightDevice?.name ?: ""),
        "status" to status,
        "channelNumber" to (leftDevice?.channelNumber ?: rightDevice?.channelNumber ?: "")
    )
}
