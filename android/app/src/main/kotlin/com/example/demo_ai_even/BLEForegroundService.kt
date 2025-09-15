package com.example.demo_ai_even

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.demo_ai_even.bluetooth.BleManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class BLEForegroundService : Service() {

    private val scope = CoroutineScope(Dispatchers.IO)

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        val notification: Notification = NotificationCompat.Builder(this, "BLE_CHANNEL")
            .setContentTitle("Even Glasses Connected")
            .setContentText("Keeping BLE connection active in background")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()

        // ✅ Start as foreground service
        startForeground(1, notification)

        // ✅ Try to reconnect on service start
        scope.launch {
            try {
                Log.d("BLEForegroundService", "Attempting auto-reconnect...")
                BleManager.instance.reconnectLastDevice()
            } catch (e: Exception) {
                Log.e("BLEForegroundService", "Reconnect failed: $e")
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // ✅ Keeps the service alive even if killed
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
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}