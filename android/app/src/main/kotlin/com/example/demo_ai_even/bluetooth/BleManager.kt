package com.example.demo_ai_even.bluetooth

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
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
import java.util.UUID

@SuppressLint("MissingPermission")
class BleManager private constructor() {

    companion object {
        val LOG_TAG = BleManager::class.simpleName

        private const val SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
        private const val WRITE_CHARACTERISTIC_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
        private const val READ_CHARACTERISTIC_UUID  = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

        private var mInstance: BleManager? = null
        val instance: BleManager = mInstance ?: BleManager()
    }

    // Context
    private lateinit var weakActivity: WeakReference<Activity>

    // Bluetooth plumbing
    private lateinit var bluetoothManager: BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter
        get() = bluetoothManager.adapter

    // Discovered devices / active pair
    private val bleDevices: MutableList<BleDevice> = mutableListOf()
    private var connectedDevice: BlePairDevice? = null

    // Scan settings
    private val scanSettings = ScanSettings.Builder()
        .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
        .build()

    // UI thread scope
    private val mainScope: CoroutineScope = MainScope()

    // ===== Public API =====

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
            result.error("Permission", "Bluetooth OFF or permission missing", null)
            return
        }
        bleDevices.clear()
        bluetoothAdapter.bluetoothLeScanner.startScan(null, scanSettings, scanCallback)
        Log.v(LOG_TAG, "Start scan")
        result.success("Scanning...")
    }

    fun stopScan(result: MethodChannel.Result? = null) {
        if (!checkBluetoothStatus()) {
            result?.error("Permission", "Bluetooth OFF or permission missing", null)
            return
        }
        bluetoothAdapter.bluetoothLeScanner.stopScan(scanCallback)
        Log.v(LOG_TAG, "Stop scan")
        result?.success("Scan stopped")
    }

    fun connectToGlass(deviceChannel: String, result: MethodChannel.Result) {
        Log.i(LOG_TAG, "connectToGlass: deviceChannel = $deviceChannel")

        // Expected names: G1_<channel>_L_xxx / G1_<channel>_R_xxx
        val leftKey  = "_${deviceChannel}_L_"
        val rightKey = "_${deviceChannel}_R_"

        val leftDevice  = bleDevices.firstOrNull { it.name.contains(leftKey) }
        val rightDevice = bleDevices.firstOrNull { it.name.contains(rightKey) }

        if (leftDevice == null || rightDevice == null) {
            result.error("PeripheralNotFound", "One or both peripherals are not found", null)
            return
        }

        connectedDevice = BlePairDevice(leftDevice, rightDevice)

        weakActivity.get()?.let {
            bluetoothAdapter.getRemoteDevice(leftDevice.address)
                .connectGatt(it, false, bleGattCallback())

            bluetoothAdapter.getRemoteDevice(rightDevice.address)
                .connectGatt(it, false, bleGattCallback())
        }

        result.success("Connecting to G1_$deviceChannel ...")
    }

    fun disconnectFromGlasses(result: MethodChannel.Result) {
        // If you track GATTs inside BlePairDevice, close them here.
        connectedDevice = null
        result.success("Disconnected all devices.")
    }

    fun senData(params: Map<*, *>?) {
        val data = params?.get("data") as ByteArray? ?: byteArrayOf()
        if (data.isEmpty()) {
            Log.e(LOG_TAG, "Send data is empty")
            return
        }
        val lr = params["lr"] as String?
        when (lr) {
            null  -> requestData(data) // both
            "L"   -> requestData(data, sendLeft = true)
            "R"   -> requestData(data, sendRight = true)
            else  -> requestData(data) // fallback both
        }
    }

    // ===== Internals =====

    private fun checkBluetoothStatus(): Boolean {
        val act = weakActivity.get() ?: return false
        if (!bluetoothAdapter.isEnabled) {
            Toast.makeText(act, "Please turn on Bluetooth", Toast.LENGTH_SHORT).show()
            return false
        }
        if (!BlePermissionUtil.checkBluetoothPermission(act)) {
            return false
        }
        return true
    }

    private val scanCallback: ScanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            val device = result?.device ?: return
            val name = device.name ?: return

            // Example: G1_45_L_XXXXX
            if (!name.contains("G\\d+".toRegex())) return
            if (name.split("_").size != 4) return
            if (bleDevices.any { it.address == device.address }) return

            val channelNum = name.split("_")[1] // "45"
            bleDevices.add(BleDevice.createByDevice(name, device.address, channelNum))

            // See if we now have both L and R for this channel
            val pairDevices = bleDevices.filter { it.name.contains("_$channelNum" + "_") }
            val leftDevice  = pairDevices.firstOrNull { it.isLeft() }
            val rightDevice = pairDevices.firstOrNull { it.isRight() }
            if (leftDevice != null && rightDevice != null) {
                // Notify Flutter that a pair is available
                BleChannelHelper.invokeFlutter(
                    "flutterFoundPairedGlasses",
                    mapOf(
                        "channelNumber"   to channelNum,
                        "leftDeviceName"  to leftDevice.name,
                        "rightDeviceName" to rightDevice.name
                    )
                )
            }
        }

        override fun onScanFailed(errorCode: Int) {
            Log.e(LOG_TAG, "ScanCallback - Failed: ErrorCode = $errorCode")
        }
    }

    private fun bleGattCallback(): BluetoothGattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
            if (newState == BluetoothGatt.STATE_CONNECTED) {
                gatt?.discoverServices()
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) return
            if (gatt == null) return

            val server = gatt.getService(UUID.fromString(SERVICE_UUID)) ?: return
            val readCharacteristic = server.getCharacteristic(UUID.fromString(READ_CHARACTERISTIC_UUID)) ?: return
            val writeCharacteristic = server.getCharacteristic(UUID.fromString(WRITE_CHARACTERISTIC_UUID)) ?: return

            gatt.setCharacteristicNotification(readCharacteristic, true)

            val cccd = readCharacteristic.getDescriptor(
                UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
            )
            cccd?.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
            if (cccd != null) gatt.writeDescriptor(cccd)

            // Save write characteristic side
            connectedDevice?.let { pair ->
                if (gatt.device.address == pair.leftDevice?.address) {
                    pair.leftDevice?.writeCharacteristic = writeCharacteristic
                    pair.update(leftGatt = gatt, isLeftConnect = true)
                } else if (gatt.device.address == pair.rightDevice?.address) {
                    pair.rightDevice?.writeCharacteristic = writeCharacteristic
                    pair.update(rightGatt = gatt, isRightConnected = true)
                }

                // Open mic stream command (example)
                requestData(byteArrayOf(0xF4.toByte(), 0x01.toByte()))

                if (pair.isBothConnected()) {
                    // Notify Flutter that we're connected (use your existing toConnectedJson())
                    weakActivity.get()?.runOnUiThread {
                        BleChannelHelper.invokeFlutter(
                            "flutterGlassesConnected",
                            pair.toConnectedJson()
                        )
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

                // Mic data pack: 0=cmd, 1=seq, 2..201=payload; total 202 bytes; cmd 0xF1
                val isMicData = value.isNotEmpty() && value[0] == 0xF1.toByte()
                if (isMicData && value.size == 202) {
                    val lc3 = value.copyOfRange(2, 202)
                    // Optional: Decode LC3 → PCM for STT
                    try {
                        val pcmData = Cpp.decodeLC3(lc3)
                        Log.d(LOG_TAG, "LC3→PCM size=${pcmData?.size}")
                    } catch (_: Throwable) {}
                }

                // Stream to Flutter
                BleChannelHelper.emit(
                    "eventBleReceive",
                    mapOf(
                        "lr"   to if (isLeft) "L" else "R",
                        "data" to value,
                        "type" to if (isMicData) "VoiceChunk" else "Receive"
                    )
                )
            }
        }
    }

    private fun requestData(
        data: ByteArray,
        sendLeft: Boolean = false,
        sendRight: Boolean = false
    ) {
        val isBoth = !sendLeft && !sendRight
        Log.d(LOG_TAG, "Send ${if (isBoth) "both" else if (sendLeft) "left" else "right"} data = ${ByteUtil.byteToHexArray(data)}")

        if (sendLeft || isBoth) {
            connectedDevice?.leftDevice?.sendData(data)
        }
        if (sendRight || isBoth) {
            connectedDevice?.rightDevice?.sendData(data)
        }
    }
}