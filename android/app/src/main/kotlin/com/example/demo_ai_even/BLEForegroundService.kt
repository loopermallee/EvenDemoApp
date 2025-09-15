package com.example.demo_ai_even

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.demo_ai_even.bluetooth.BleManager

class BLEForegroundService : Service() {

    override fun onCreate() {
        super.onCreate()
        Log.i("BLEForegroundService", "Service created")

        createNotificationChannel()

        val notification: Notification = NotificationCompat.Builder(this, "BLE_CHANNEL")
            .setContentTitle("Even Glasses Connected")
            .setContentText("Keeping BLE connection active in background")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()

        // ✅ Start foreground mode
        startForeground(1, notification)

        // ✅ Try auto-reconnect immediately
        try {
            BleManager.instance.ensureConnected()
            Log.i("BLEForegroundService", "Auto-reconnect triggered on service start")
        } catch (e: Exception) {
            Log.e("BLEForegroundService", "Failed to auto-reconnect: $e")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i("BLEForegroundService", "Service restarted with intent: $intent")
        // ✅ Ensure reconnect every time service is restarted
        try {
            BleManager.instance.ensureConnected()
        } catch (e: Exception) {
            Log.e("BLEForegroundService", "Error ensuring connection: $e")
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "BLE_CHANNEL",
                "BLE Background Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}