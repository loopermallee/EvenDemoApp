package com.example.demo_ai_even.bluetooth

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.*
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.widget.Toast
import com.example.demo_ai_even.BLEForegroundService
import com.example.demo_ai_even.cpp.Cpp
import com.example.demo_ai_even.model.BleDevice
import com.example.demo_ai_even.model.BlePairDevice
import com.example.demo_ai_even.utils.ByteUtil
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import java.lang.ref.WeakReference
import java.util.UUID

@SuppressLint("MissingPermission")
class BleManager private constructor() {

    companion object {
        val LOG_TAG = BleManager::class.simpleName

        private const val SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
        private const val WRITE_CHARACTERISTIC_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
        private const val READ_CHARACTERISTIC_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

        //  SingleInstance
        private var mInstance: BleManager? = null
        val instance: BleManager = mInstance ?: BleManager()
    }

    //  Context
    private lateinit var weakActivity: WeakReference<Activity>
    private lateinit var bluetoothManager: BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter
        get() = bluetoothManager.adapter

    //  Save device address
    private val bleDevices: MutableList<BleDevice> = mutableListOf()
    private var connectedDevice: BlePairDevice? = null
    private var lastConnectedChannel: String? = null  // ✅ Save last channel for auto-reconnect

    /// Scan Config
    private val scanSettings = ScanSettings
        .Builder()
        .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
        .build()

    private val scanCallback: ScanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            super.onScanResult(callbackType, result)
            val device = result?.device
            if (device == null ||
                device.name.isNullOrEmpty() ||
                !device.name.contains("G\\d+".toRegex()) ||
                device.name.split("_").size != 4 ||
                bleDevices.firstOrNull { it.address == device.address } != null) {
                return
            }
            Log.i(LOG_TAG, "ScanCallback - Found: ${device.name}")
            val channelNum = device.name.split("_")[1]
            bleDevices.add(BleDevice.createByDevice(device.name, device.address, channelNum))

            val pairDevices = bleDevices.filter { it.name.contains("_$channelNum" + "_") }
            if (pairDevices.size <= 1) return

            val leftDevice = pairDevices.firstOrNull { it.isLeft() }
            val rightDevice = pairDevices.firstOrNull { it.isRight() }
            if (leftDevice == null || rightDevice == null) return

            BleChannelHelper.bleMC.flutterFoundPairedGlasses(BlePairDevice(leftDevice, rightDevice))
        }

        override fun onScanFailed(errorCode: Int) {
            super.onScanFailed(errorCode)
            Log.e(LOG_TAG, "Scan failed: $errorCode")
        }
    }

    private val mainScope: CoroutineScope = MainScope()

    //*================= Method - Public =================*//

    fun initBluetooth(context: Activity) {
        weakActivity = WeakReference(context)
        bluetoothManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.getSystemService(BluetoothManager::class.java)
        } else {
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
        bluetoothAdapter.bluetoothLeScanner.startScan(null, scanSettings, scanCallback)
        result.success("Scanning for devices...")
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
        Log.i(LOG_TAG, "Connecting to glasses channel: $deviceChannel")
        lastConnectedChannel = deviceChannel  // ✅ Save for reconnect
        val leftPairChannel = "_$deviceChannel" + "_L_"
        var leftDevice = connectedDevice?.leftDevice
        if (leftDevice?.name?.contains(leftPairChannel) != true) {
            leftDevice = bleDevices.firstOrNull { it.name.contains(leftPairChannel) }
        }
        val rightPairChannel = "_$deviceChannel" + "_R_"
        var rightDevice = connectedDevice?.rightDevice
        if (rightDevice?.name?.contains(rightPairChannel) != true) {
            rightDevice = bleDevices.firstOrNull { it.name.contains(rightPairChannel) }
        }
        if (leftDevice == null || rightDevice == null) {
            result.error("PeripheralNotFound", "One or both peripherals not found", null)
            return
        }
        connectedDevice = BlePairDevice(leftDevice, rightDevice)
        weakActivity.get()?.let {
            bluetoothAdapter.getRemoteDevice(leftDevice.address).connectGatt(it, false, bleGattCallBack())
            bluetoothAdapter.getRemoteDevice(rightDevice.address).connectGatt(it, false, bleGattCallBack())

            // ✅ Start foreground service once connected
            val intent = Intent(it, BLEForegroundService::class.java)
            it.startForegroundService(intent)
        }
        result.success("Connecting to G1_$deviceChannel ...")
    }

    fun disconnectFromGlasses(result: MethodChannel.Result) {
        Log.i(LOG_TAG, "Disconnecting from G1_${connectedDevice?.deviceName()}")
        connectedDevice = null
        result.success("Disconnected all devices.")
    }

    fun senData(params: Map<*, *>?) {
        val data = params?.get("data") as ByteArray? ?: byteArrayOf()
        if (data.isEmpty()) {
            Log.e(LOG_TAG, "Send data is empty")
            return
        }
        val lr = params?.get("lr") as String?
        when (lr) {
            null -> requestData(data)
            "L" -> requestData(data, sendLeft = true)
            "R" -> requestData(data, sendRight = true)
        }
    }

    //*================= Method - Private =================*//

    private fun checkBluetoothStatus(): Boolean {
        if (weakActivity.get() == null) return false
        if (!bluetoothAdapter.isEnabled) {
            Toast.makeText(weakActivity.get()!!, "Bluetooth is turned off!", Toast.LENGTH_SHORT).show()
            return false
        }
        if (!BlePermissionUtil.checkBluetoothPermission(weakActivity.get()!!)) {
            return false
        }
        return true
    }

    private fun bleGattCallBack(): BluetoothGattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
            super.onConnectionStateChange(gatt, status, newState)
            if (newState == BluetoothGatt.STATE_CONNECTED) {
                gatt?.discoverServices()
            } else if (newState == BluetoothGatt.STATE_DISCONNECTED) {
                Log.w(LOG_TAG, "Device disconnected: ${gatt?.device?.address}")
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
            super.onServicesDiscovered(gatt, status)
            Log.d(LOG_TAG, "Services discovered on ${gatt?.device?.address}, status = $status")
            // ... keep your existing service discovery code ...
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
                if (!isLeft && !isRight) return@launch

                val isMicData = value[0] == 0xF1.toByte()
                if (isMicData && value.size == 202) {
                    val lc3 = value.copyOfRange(2, 202)
                    val pcmData = Cpp.decodeLC3(lc3)!!
                    Log.d(LOG_TAG, "Decoded PCM: $pcmData")
                }
                BleChannelHelper.bleReceive(
                    mapOf(
                        "lr" to if (isLeft) "L" else "R",
                        "data" to value,
                        "type" to if (isMicData) "VoiceChunk" else "Receive",
                    )
                )
            }
        }
    }

    private fun requestData(data: ByteArray, sendLeft: Boolean = false, sendRight: Boolean = false) {
        val isBothSend = !sendLeft && !sendRight
        if (sendLeft || isBothSend) {
            connectedDevice?.leftDevice?.sendData(data)
        }
        if (sendRight || isBothSend) {
            connectedDevice?.rightDevice?.sendData(data)
        }
    }

    // ✅ Auto-reconnect if service restarts
    fun ensureConnected() {
        lastConnectedChannel?.let {
            Log.d(LOG_TAG, "Auto-reconnect to $it")
            connectToGlass(it, object : MethodChannel.Result {
                override fun success(result: Any?) { Log.d(LOG_TAG, "Reconnect success: $result") }
                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    Log.e(LOG_TAG, "Reconnect error: $errorMessage")
                }
                override fun notImplemented() {}
            })
        }
    }
}