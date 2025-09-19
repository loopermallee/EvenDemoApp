package com.example.demo_ai_even.bluetooth

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothStatusCodes
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Build
import android.util.Log
import com.example.demo_ai_even.model.BleDeviceSummary
import com.example.demo_ai_even.utils.ByteUtil
import java.util.LinkedHashMap
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow

class BleManager private constructor() {

    companion object {
        const val LOG_TAG: String = "BleManager"

        val instance: BleManager by lazy(LazyThreadSafetyMode.SYNCHRONIZED) { BleManager() }

        private val CLIENT_CHARACTERISTIC_CONFIG_UUID: UUID =
            UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }

    private lateinit var appContext: Context

    private val bluetoothManager: BluetoothManager?
        get() = appContext.getSystemService(BluetoothManager::class.java)
    private val bluetoothAdapter: BluetoothAdapter?
        get() = bluetoothManager?.adapter

    private var bluetoothLeScanner: BluetoothLeScanner? = null
    private var scanCallback: ScanCallback? = null

    private val knownDevices = ConcurrentHashMap<String, BluetoothDevice>()
    private val scanCache = LinkedHashMap<String, BleDeviceSummary>()

    private val _scanResults = MutableStateFlow<List<BleDeviceSummary>>(emptyList())
    val scanResults: StateFlow<List<BleDeviceSummary>> = _scanResults.asStateFlow()

    private val _isScanning = MutableStateFlow(false)
    val isScanning: StateFlow<Boolean> = _isScanning.asStateFlow()

    private val _connectionState = MutableStateFlow<BleConnectionState>(BleConnectionState.Idle)
    val connectionState: StateFlow<BleConnectionState> = _connectionState.asStateFlow()

    private val _notifications = MutableSharedFlow<BleNotification>(
        extraBufferCapacity = 32,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )
    val notifications: SharedFlow<BleNotification> = _notifications.asSharedFlow()

    private val _logs = MutableSharedFlow<String>(
        replay = 0,
        extraBufferCapacity = 128,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )
    val logs: SharedFlow<String> = _logs.asSharedFlow()

    private var currentGatt: BluetoothGatt? = null
    private var writeCharacteristic: BluetoothGattCharacteristic? = null
    private var notifyCharacteristic: BluetoothGattCharacteristic? = null

    private val preferencesName = "ble_manager"
    private val keyLastAddress = "last_device_address"

    fun initBluetooth(context: Context) {
        if (::appContext.isInitialized) return
        appContext = context.applicationContext
        bluetoothLeScanner = bluetoothAdapter?.bluetoothLeScanner
        if (bluetoothAdapter == null) {
            log("Bluetooth adapter not available on this device")
        }
    }

    @SuppressLint("MissingPermission")
    fun startScan() {
        val adapter = bluetoothAdapter ?: run {
            log("Cannot start scan: Bluetooth adapter unavailable")
            return
        }
        if (_isScanning.value) {
            log("startScan ignored: scanner already running")
            return
        }
        val scanner = bluetoothLeScanner ?: adapter.bluetoothLeScanner ?: run {
            log("Cannot start scan: BluetoothLeScanner unavailable")
            return
        }

        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                handleScanResult(result)
            }

            override fun onBatchScanResults(results: MutableList<ScanResult>) {
                results.forEach(::handleScanResult)
            }

            override fun onScanFailed(errorCode: Int) {
                log("BLE scan failed with code $errorCode")
                _isScanning.value = false
            }
        }

        scanCallback = callback
        scanCache.clear()
        _scanResults.value = emptyList()
        try {
            val settings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                .build()
            scanner.startScan(null, settings, callback)
            _isScanning.value = true
            log("Started BLE scan…")
        } catch (security: SecurityException) {
            log("Unable to start BLE scan. Missing BLUETOOTH_SCAN permission?")
            scanCallback = null
        }
    }

    @SuppressLint("MissingPermission")
    fun stopScan() {
        val callback = scanCallback ?: return
        try {
            bluetoothLeScanner?.stopScan(callback)
        } catch (security: SecurityException) {
            log("Unable to stop scan: ${security.message}")
        } finally {
            scanCallback = null
            _isScanning.value = false
        }
    }

    @SuppressLint("MissingPermission")
    fun connectToGlass(identifier: String) {
        val adapter = bluetoothAdapter ?: run {
            log("Cannot connect: Bluetooth adapter unavailable")
            return
        }
        val device = when {
            knownDevices.containsKey(identifier) -> knownDevices[identifier]
            identifier.contains(":") -> runCatching { adapter.getRemoteDevice(identifier) }.getOrNull()
            else -> knownDevices.values.firstOrNull { it.name == identifier }
        }

        if (device == null) {
            log("No known device matches '$identifier'")
            return
        }

        stopScan()
        disconnectInternal("switching device")

        log("Connecting to ${device.address} (${device.name ?: "unknown"})")
        _connectionState.value = BleConnectionState.Connecting(device.name, device.address)
        try {
            currentGatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                device.connectGatt(appContext, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
            } else {
                device.connectGatt(appContext, false, gattCallback)
            }
        } catch (security: SecurityException) {
            log("Unable to connect. Missing BLUETOOTH_CONNECT permission?")
            _connectionState.value = BleConnectionState.Error("Missing BLUETOOTH_CONNECT permission")
        }
    }

    @SuppressLint("MissingPermission")
    fun disconnectFromGlasses() {
        disconnectInternal("manual disconnect")
        _connectionState.value = BleConnectionState.Disconnected("manual")
    }

    fun ensureConnected() {
        val gatt = currentGatt
        if (gatt == null) {
            if (!reconnectLastDevice()) {
                log("ensureConnected: no previous device to reconnect")
            }
        } else {
            log("ensureConnected: already connected to ${gatt.device.address}")
        }
    }

    fun isBluetoothEnabled(): Boolean = bluetoothAdapter?.isEnabled == true

    fun reconnectLastDevice(): Boolean {
        if (!::appContext.isInitialized) return false
        val prefs = appContext.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val address = prefs.getString(keyLastAddress, null) ?: return false
        connectToGlass(address)
        return true
    }

    @SuppressLint("MissingPermission")
    fun sendPayload(data: ByteArray, description: String = "payload"): Boolean {
        val gatt = currentGatt ?: run {
            log("Cannot send $description: no active GATT connection")
            return false
        }
        val characteristic = writeCharacteristic ?: run {
            log("Cannot send $description: writable characteristic not discovered yet")
            return false
        }
        return try {
            val success = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                gatt.writeCharacteristic(
                    characteristic,
                    data,
                    BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                ) == BluetoothStatusCodes.SUCCESS
            } else {
                characteristic.value = data
                @Suppress("DEPRECATION")
                gatt.writeCharacteristic(characteristic)
            }
            if (success) {
                log("Sent ${data.size} bytes to ${characteristic.uuid}: ${ByteUtil.byteToHexArray(data)}")
            } else {
                log("Gatt refused write to ${characteristic.uuid}")
            }
            success
        } catch (security: SecurityException) {
            log("Failed to send $description: ${security.message}")
            false
        }
    }

    fun sendHexPayload(hex: String): Boolean {
        val data = ByteUtil.hexToByteArray(hex)
        return if (data != null) {
            sendPayload(data, description = "hex payload")
        } else {
            log("Unable to parse hex string '$hex'")
            false
        }
    }

    private fun disconnectInternal(reason: String) {
        val gatt = currentGatt ?: return
        try {
            log("Disconnecting from ${gatt.device.address}: $reason")
            gatt.disconnect()
        } catch (security: SecurityException) {
            log("Gatt disconnect failed: ${security.message}")
        } finally {
            gatt.close()
            currentGatt = null
            writeCharacteristic = null
            notifyCharacteristic = null
        }
    }

    @SuppressLint("MissingPermission")
    private fun handleScanResult(result: ScanResult) {
        val device = result.device ?: return
        val address = device.address ?: return
        knownDevices[address] = device
        val summary = BleDeviceSummary(
            name = device.name,
            address = address,
            rssi = result.rssi,
            lastSeenTimestamp = System.currentTimeMillis(),
            isBonded = device.bondState == BluetoothDevice.BOND_BONDED
        )
        scanCache[address] = summary
        _scanResults.value = scanCache.values.sortedByDescending { it.rssi }
    }

    private fun saveLastAddress(address: String) {
        if (!::appContext.isInitialized) return
        val prefs = appContext.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        prefs.edit().putString(keyLastAddress, address).apply()
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                log("Connection state change error: status=$status")
                _connectionState.value = BleConnectionState.Error("Gatt error $status")
                disconnectInternal("gatt error $status")
                return
            }
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    log("Connected to ${gatt.device.address}")
                    saveLastAddress(gatt.device.address)
                    _connectionState.value = BleConnectionState.Connecting(gatt.device.name, gatt.device.address)
                    gatt.discoverServices()
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    log("Disconnected from ${gatt.device.address}")
                    _connectionState.value = BleConnectionState.Disconnected(null)
                    disconnectInternal("remote disconnect")
                }
                else -> {
                    log("Connection state changed to $newState")
                }
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                log("Service discovery failed with status=$status")
                _connectionState.value = BleConnectionState.Error("Service discovery failed: $status")
                return
            }
            selectCharacteristics(gatt)
            val hasWrite = writeCharacteristic != null
            val serviceCount = gatt.services.size
            _connectionState.value = BleConnectionState.Connected(
                name = gatt.device.name,
                address = gatt.device.address,
                serviceCount = serviceCount,
                hasWritableCharacteristic = hasWrite
            )
            log("Discovered $serviceCount services. Writable characteristic=${writeCharacteristic?.uuid}")
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray
        ) {
            log("Notification from ${characteristic.uuid}: ${ByteUtil.byteToHexArray(value)}")
            _notifications.tryEmit(BleNotification(characteristic.uuid, value))
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int
        ) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                log("Characteristic write failed for ${characteristic.uuid}: status=$status")
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun selectCharacteristics(gatt: BluetoothGatt) {
        writeCharacteristic = null
        notifyCharacteristic = null

        gatt.services.forEach { service ->
            service.characteristics.forEach { characteristic ->
                val props = characteristic.properties
                if (writeCharacteristic == null &&
                    (props and BluetoothGattCharacteristic.PROPERTY_WRITE != 0 ||
                        props and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE != 0)
                ) {
                    writeCharacteristic = characteristic
                }
                if (notifyCharacteristic == null && props and BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0) {
                    enableNotifications(gatt, characteristic)
                }
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun enableNotifications(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
        notifyCharacteristic = characteristic
        try {
            gatt.setCharacteristicNotification(characteristic, true)
            val descriptor = characteristic.descriptors.firstOrNull {
                it.uuid == CLIENT_CHARACTERISTIC_CONFIG_UUID
            }
            if (descriptor != null) {
                descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                gatt.writeDescriptor(descriptor)
            }
            log("Enabled notifications for ${characteristic.uuid}")
        } catch (security: SecurityException) {
            log("Unable to enable notifications: ${security.message}")
        }
    }

    private fun log(message: String) {
        Log.d(LOG_TAG, message)
        _logs.tryEmit(message)
    }
}

sealed class BleConnectionState {
    data object Idle : BleConnectionState()
    data class Connecting(val name: String?, val address: String) : BleConnectionState()
    data class Connected(
        val name: String?,
        val address: String,
        val serviceCount: Int,
        val hasWritableCharacteristic: Boolean
    ) : BleConnectionState()
    data class Disconnected(val reason: String?) : BleConnectionState()
    data class Error(val message: String) : BleConnectionState()
}

data class BleNotification(
    val characteristicUuid: UUID,
    val payload: ByteArray
) {
    val hexPayload: String = ByteUtil.byteToHexArray(payload)
}
