package com.example.demo_ai_even

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.MethodChannel

class NotificationService : NotificationListenerService() {
    companion object {
        var channel: MethodChannel? = null
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val pkg = sbn.packageName ?: "unknown"
            val extras = sbn.notification.extras
            val title = extras.getString("android.title") ?: ""
            val text = extras.getCharSequence("android.text")?.toString() ?: ""

            // Ignore empty notifications (system noise)
            if (title.isBlank() && text.isBlank()) return

            // Format nicely
            val msg = if (title.isNotBlank()) {
                "[$pkg] $title: $text"
            } else {
                "[$pkg] $text"
            }

            channel?.invokeMethod("onNotification", msg)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // Optional: could send "removed" events if needed
    }
}