package com.example.demo_ai_even.bluetooth

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.*
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

        // SingleInstance
        private var mInstance: BleManager? = null
        val instance: BleManager = mInstance ?: BleManager()
    }

    // Context
    private lateinit var weakActivity: WeakReference<Activity>
    private lateinit var bluetoothManager: BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter
        get() = bluetoothManager.adapter

    // Save device address
    private val bleDevices: MutableList<BleDevice> = mutableListOf()
    private var connectedDevice: BlePairDevice? = null
    private var lastDeviceAddress: String? = null   // ✅ Remember last device

    /// UI Thread
    private val mainScope: CoroutineScope = MainScope()

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
        bluetoothAdapter.bluetoothLeScanner.startScan(null, null, scanCallback)
        Log.v(LOG_TAG, "Start scan")
        result.success("Scanning for devices...")
    }

    fun stopScan(result: MethodChannel.Result? = null) {
        if (!checkBluetoothStatus()) {
            result?.error("Permission", "", null)
            return
        }
        bluetoothAdapter.bluetoothLeScanner.stopScan(scanCallback)
        Log.v(LOG_TAG, "Stop scan")
        result?.success("Scan stopped")
    }

    fun connectToGlass(deviceChannel: String, result: MethodChannel.Result) {
        Log.i(LOG_TAG, "connectToGlass: deviceChannel = $deviceChannel")
        val leftPairChannel = "_$deviceChannel" + "_L_"
        val rightPairChannel = "_$deviceChannel" + "_R_"

        val leftDevice = bleDevices.firstOrNull { it.name.contains(leftPairChannel) }
        val rightDevice = bleDevices.firstOrNull { it.name.contains(rightPairChannel) }

        if (leftDevice == null || rightDevice == null) {
            result.error("PeripheralNotFound", "One or both peripherals are not found", null)
            return
        }

        connectedDevice = BlePairDevice(leftDevice, rightDevice)
        lastDeviceAddress = leftDevice.address   // ✅ Save last address

        weakActivity.get()?.let {
            bluetoothAdapter.getRemoteDevice(leftDevice.address).connectGatt(it, false, bleGattCallBack())
            bluetoothAdapter.getRemoteDevice(rightDevice.address).connectGatt(it, false, bleGattCallBack())
        }

        result.success("Connecting to G1_$deviceChannel ...")
    }

    fun disconnectFromGlasses(result: MethodChannel.Result) {
        Log.i(LOG_TAG, "disconnectFromGlasses: G1_${connectedDevice?.deviceName()}")
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

    // ✅ NEW: Auto reconnect
    fun reconnectLastDevice() {
        val address = lastDeviceAddress
        if (address != null) {
            try {
                Log.i(LOG_TAG, "Attempting reconnect to last device: $address")
                val device = bluetoothAdapter.getRemoteDevice(address)
                weakActivity.get()?.let {
                    device.connectGatt(it, true, bleGattCallBack()) // autoConnect = true
                }
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Reconnect failed: $e")
            }
        } else {
            Log.w(LOG_TAG, "No last device stored, cannot reconnect.")
        }
    }

    // ✅ NEW: ensureConnected (called from MainActivity MethodChannel)
    fun ensureConnected() {
        if (connectedDevice != null) {
            Log.i(LOG_TAG, "ensureConnected: Already connected to ${connectedDevice?.deviceName()}")
        } else {
            Log.w(LOG_TAG, "ensureConnected: No active connection, trying reconnect...")
            reconnectLastDevice()
        }
    }

    // ================= PRIVATE ================= //

    private fun checkBluetoothStatus(): Boolean {
        if (weakActivity.get() == null) return false
        if (!bluetoothAdapter.isEnabled) {
            Toast.makeText(weakActivity.get()!!, "Bluetooth is turned off, please turn it on first!", Toast.LENGTH_SHORT).show()
            return false
        }
        if (!BlePermissionUtil.checkBluetoothPermission(weakActivity.get()!!)) {
            return false
        }
        return true
    }

    private fun bleGattCallBack(): BluetoothGattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
            if (newState == BluetoothGatt.STATE_CONNECTED) {
                gatt?.discoverServices()
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt?, status: Int) {
            Log.i(LOG_TAG, "Services discovered for ${gatt?.device?.address}, status=$status")
            // TODO: Keep existing service/characteristic setup logic here
        }
    }

    private fun requestData(data: ByteArray, sendLeft: Boolean = false, sendRight: Boolean = false) {
        val isBothSend = !sendLeft && !sendRight
        Log.d(LOG_TAG, "Send ${if (isBothSend) "both" else if (sendLeft) "left" else "right"} data = ${ByteUtil.byteToHexArray(data)}")
        if (sendLeft || isBothSend) {
            connectedDevice?.leftDevice?.sendData(data)
        }
        if (sendRight || isBothSend) {
            connectedDevice?.rightDevice?.sendData(data)
        }
    }

    // Existing scan callback (shortened for clarity)
    private val scanCallback: ScanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            super.onScanResult(callbackType, result)
            val device = result?.device
            if (device?.name.isNullOrEmpty()) return
            Log.i(LOG_TAG, "Found device: ${device?.name}")
        }
    }
}