package com.example.demo_ai_even.bluetooth

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

object BlePermissionUtil {

    /**
     * Bluetooth scan and connect permissions required for the glasses.
     */
    private val BLUETOOTH_PERMISSIONS: Array<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.ACCESS_FINE_LOCATION,
            )
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }

    /**
     * Checks whether Bluetooth permissions are granted, requesting them if needed.
     */
    fun checkBluetoothPermission(activity: Activity): Boolean {
        val missingPermissions = BLUETOOTH_PERMISSIONS.filter { permission ->
            ContextCompat.checkSelfPermission(activity, permission) != PackageManager.PERMISSION_GRANTED
        }
        if (missingPermissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(activity, missingPermissions.toTypedArray(), REQUEST_CODE)
            return false
        }
        return true
    }

    private const val REQUEST_CODE = 1
}
