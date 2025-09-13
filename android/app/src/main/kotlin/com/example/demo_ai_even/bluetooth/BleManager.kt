package com.example.demo_ai_even.bluetooth

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.*
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Build
import android.util.Log
import android.widget.Toast
import com.example.demo_ai_even.cpp.Cpp
import com.example.demo_ai_even.model.BleDevice
import com.example.demo_ai_even.model.BlePairDevice
import com.example.demo_ai_even.utils.ByteUtil
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import java.lang.ref.WeakReference
import java.util.*

@SuppressLint("MissingPermission")
class BleManager private constructor() {

    companion object {
        val LOG_TAG = BleManager::class.simpleName

        private const val SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
        private const val WRITE_CHARACTERISTIC_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
        private const val READ_CHARACTERISTIC_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

        // Singleton
        private var mInstance: BleManager? = null
        val instance: BleManager = mInstance ?: BleManager()
    }

    // Context
    private lateinit var weakActivity: WeakReference<Activity>
    private lateinit var bluetoothManager: BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter
        get() = bluetoothManager.adapter

    // State
    private val bleDevices: MutableList<BleDevice> = mutableListOf()
    private var connectedDevice: BlePairDevice? = null

    private val mainScope: CoroutineScope = MainScope()

    // Scan config
    private val scanSettings = ScanSettings.Builder()
        .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
        .build()

    private val scanCallback: ScanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            super.onScanResult(callbackType, result)
            val device = result?.device ?: return

            if (device.name.isNullOrEmpty() ||
                !device.name.contains("G\\d+".toRegex()) ||
                device.name.split("_").size != 4 ||
                bleDevices.any { it.address == device.address }
            ) return

            Log.i(LOG_TAG, "Scan result: ${device.name}")

            val channelNum = device.name.split("_")[1]
            bleDevices.add(BleDevice.createByDevice(device.name, device.address, channelNum))

            // Try to find pair
            val pairDevices = bleDevices.filter { it.name.contains("_$channelNum" + "_") }
            if (pairDevices.size <= 1) return

            val leftDevice = pairDevices.firstOrNull { it.isLeft() }
            val rightDevice = pairDevices.firstOrNull { it.isRight() }
            if (leftDevice == null || rightDevice == null) return

            // ✅ Notify Flutter: Found paired glasses
            BleChannelHelper.invokeFlutter("flutterFoundPairedGlasses", mapOf(
                "channelNumber" to channelNum,
                "leftDeviceName" to leftDevice.name,
                "rightDeviceName" to rightDevice.name
            ))
        }

        override fun onScanFailed(errorCode: Int) {
            super.onScanFailed(errorCode)
            Log.e(LOG_TAG, "Scan failed: $errorCode")
        }
    }

    // Public API

    fun initBluetooth(context: Activity) {
        weakActivity = WeakReference(context)
        bluetoothManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.getSystemService(BluetoothManager::class.java)
        } else {
            context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        }
        Log.v(LOG_TAG, "Bluetooth manager initialized")
    }

    fun startScan(result: MethodChannel.Result) {
        if (!checkBluetoothStatus()) {
            result.error("Permission", "", null)
            return
        }
        bleDevices.clear()
        bluetoothAdapter.bluetoothLeScanner.startScan(null, scanSettings, scanCallback)
        result.success("Scanning for devices…")
    }

    fun stopScan(result: MethodChannel.Result? = null) {
        if (!checkBluetoothStatus()) {
            result?.error("Permission", "", null)
            return
        }
        bluetoothAdapter.bluetoothLeScanner.stopScan(scanCallback)
        result?.success("Scan stopped")
    }

    fun connectToGlass(deviceChannel: String, result: MethodChannel.Result) {
        Log.i(LOG_TAG, "connectToGlass: $deviceChannel")

        val leftMatch = "_${deviceChannel}_L_"
        val rightMatch = "_${deviceChannel}_R_"

        var leftDevice = connectedDevice?.leftDevice
        if (leftDevice?.name?.contains(leftMatch) != true) {
            leftDevice = bleDevices.firstOrNull { it.name.contains(leftMatch) }
        }

        var rightDevice = connectedDevice?.rightDevice
        if (rightDevice?.name?.contains(rightMatch) != true) {
            rightDevice = bleDevices.firstOrNull { it.name.contains(rightMatch) }
        }

        if (leftDevice == null || rightDevice == null) {
            result.error("PeripheralNotFound", "One or both peripherals missing", null)
            return
        }

        connectedDevice = BlePairDevice(leftDevice, rightDevice)
        weakActivity.get()?.let {
            bluetoothAdapter.getRemoteDevice(leftDevice.address).connectGatt(it, false, bleGattCallBack())
            bluetoothAdapter.getRemoteDevice(rightDevice.address).connectGatt(it, false, bleGattCallBack())
        }
        result.success("Connecting to G1_$deviceChannel…")
    }

    fun disconnectFromGlasses(result: MethodChannel.Result) {
        Log.i(LOG_TAG, "disconnectFromGlasses: ${connectedDevice?.deviceName()}")
        connectedDevice = null
        // ✅ Notify Flutter
        BleChannelHelper.invokeFlutter("flutterGlassesDisconnected", null)
        result.success("Disconnected all devices.")
    }

    fun senData(params: Map<*, *>?) {
        val data = params?.get("data") as? ByteArray ?: byteArrayOf()
        if (data.isEmpty()) {
            Log.e(LOG_TAG, "Send data is empty")
            return
        }
        val lr = params["lr"] as? String
        when (lr) {
            null -> requestData(data)
            "L" -> requestData(data, sendLeft = true)
            "R" -> requestData(data, sendRight = true)
        }
    }

    // Private methods

    private fun checkBluetoothStatus(): Boolean {
        val activity = weakActivity.get() ?: return false
        if (!bluetoothAdapter.isEnabled) {
            Toast.makeText(activity, "Bluetooth is off, enable it!", Toast.LENGTH_SHORT).show()
            return false
        }
        return BlePermissionUtil.checkBluetoothPermission(activity)
    }

    private fun bleGattCallBack(): BluetoothGattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
            if (newState == BluetoothGatt.STATE_CONNECTED) {
                gatt?.discoverServices()
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
            connectedDevice?.let {
                val isLeft = gatt?.device?.address == it.leftDevice?.address
                val isRight = gatt?.device?.address == it.rightDevice?.address

                if (status == BluetoothGatt.GATT_SUCCESS) {
                    val server = gatt?.getService(UUID.fromString(SERVICE_UUID)) ?: return
                    val readChar = server.getCharacteristic(UUID.fromString(READ_CHARACTERISTIC_UUID))
                    val writeChar = server.getCharacteristic(UUID.fromString(WRITE_CHARACTERISTIC_UUID))

                    if (readChar == null || writeChar == null) return

                    gatt.setCharacteristicNotification(readChar, true)

                    if (isLeft) {
                        it.leftDevice?.writeCharacteristic = writeChar
                        it.update(leftGatt = gatt, isLeftConnect = true)
                    } else if (isRight) {
                        it.rightDevice?.writeCharacteristic = writeChar
                        it.update(rightGatt = gatt, isRightConnected = true)
                    }

                    gatt.requestMtu(251)
                    gatt.device?.createBond()

                    // ✅ Notify Flutter if both connected
                    if (it.isBothConnected()) {
                        weakActivity.get()?.runOnUiThread {
                            BleChannelHelper.invokeFlutter("flutterGlassesConnected", it.toConnectedJson())
                        }
                    }
                }
            }
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray
        ) {
            mainScope.launch {
                val isLeft = gatt.device.address == connectedDevice?.leftDevice?.address
                val isRight = gatt.device.address == connectedDevice?.rightDevice?.address
                if (!isLeft && !isRight) return@launch

                val isMicData = value[0] == 0xF1.toByte()
                if (isMicData && value.size != 202) return@launch

                if (isMicData) {
                    val lc3 = value.copyOfRange(2, 202)
                    val pcmData = Cpp.decodeLC3(lc3)!!
                    Log.d(LOG_TAG, "Decoded PCM: ${pcmData.size} bytes")
                }

                // ✅ Emit event to Flutter
                BleChannelHelper.emit("eventBleReceive", mapOf(
                    "lr" to if (isLeft) "L" else "R",
                    "data" to value,
                    "type" to if (isMicData) "VoiceChunk" else "Receive"
                ))
            }
        }
    }

    private fun requestData(data: ByteArray, sendLeft: Boolean = false, sendRight: Boolean = false) {
        val both = !sendLeft && !sendRight
        if (sendLeft || both) connectedDevice?.leftDevice?.sendData(data)
        if (sendRight || both) connectedDevice?.rightDevice?.sendData(data)
    }
}