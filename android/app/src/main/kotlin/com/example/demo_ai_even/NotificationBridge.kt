package com.example.demo_ai_even

import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

data class NotificationEvent(
    val packageName: String,
    val title: String,
    val text: String,
    val postedAt: Long = System.currentTimeMillis()
) {
    val summary: String = buildString {
        if (title.isNotBlank()) {
            append(title)
            if (text.isNotBlank()) {
                append(": ")
            }
        }
        append(text)
    }
}

object NotificationBridge {
    private val _events = MutableSharedFlow<NotificationEvent>(
        replay = 0,
        extraBufferCapacity = 32,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )

    val events: SharedFlow<NotificationEvent> = _events.asSharedFlow()

    fun emit(event: NotificationEvent) {
        _events.tryEmit(event)
    }
}
