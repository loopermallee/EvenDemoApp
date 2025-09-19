package com.example.demo_ai_even

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotificationService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val pkg = sbn.packageName ?: return
        val extras = sbn.notification.extras
        val title = extras.getString("android.title")?.trim().orEmpty()
        val text = extras.getCharSequence("android.text")?.toString()?.trim().orEmpty()

        if (title.isEmpty() && text.isEmpty()) return

        NotificationBridge.emit(
            NotificationEvent(
                packageName = pkg,
                title = title,
                text = text
            )
        )
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // No-op: removal events can be handled if needed later.
    }
}
