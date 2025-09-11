package com.example.demo_ai_even.bluetooth

import android.app.Activity
import android.util.Log
import com.example.demo_ai_even.speech.SpeechBridge
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object BleChannelHelper {

    private const val TAG = "BleChannelHelper"

    // Existing channels (keep yours)
    private const val METHOD_BLUETOOTH = "method.bluetooth"
    private const val EVENT_BLE_RECEIVE = "eventBleReceive"

    // NEW: speech channels
    private const val METHOD_SPEECH = "method.speech"
    private const val EVENT_SPEECH = "eventSpeechRecognize"

    // We store sinks by channel name
    private val sinks: MutableMap<String, EventChannel.EventSink> = mutableMapOf()

    fun initChannel(activity: Activity, flutterEngine: FlutterEngine) {
        // Existing BLE event channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_BLE_RECEIVE)
            .setStreamHandler(activity as? EventChannel.StreamHandler)

        // Existing BLE method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_BLUETOOTH)
            .setMethodCallHandler { call, result ->
                // Your original BLE handlers should remain here.
                // If you had other code, paste it back here.
                result.notImplemented()
            }

        // NEW: Speech EventChannel (Android → Flutter)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_SPEECH)
            .setStreamHandler(activity as? EventChannel.StreamHandler)

        // NEW: Speech MethodChannel (Flutter → Android)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_SPEECH)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "start" -> {
                        SpeechBridge.start(activity) { ok, err ->
                            if (ok) result.success(true) else result.error("speech_start_failed", err ?: "unknown", null)
                        }
                    }
                    "stop" -> {
                        SpeechBridge.stop(finalize = true)
                        result.success(true)
                    }
                    "cancel" -> {
                        SpeechBridge.stop(finalize = false)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Initialize SpeechRecognizer internals
        SpeechBridge.init(activity) { text, isFinal ->
            // This callback is invoked on partial/final results; emit to Flutter
            emit(EVENT_SPEECH, mapOf("script" to (text ?: ""), "isFinal" to isFinal))
        }
    }

    /** Called by MainActivity.onListen() */
    fun addEventSink(channelName: String?, sink: EventChannel.EventSink?) {
        if (channelName == null || sink == null) return
        sinks[channelName] = sink
        Log.i(TAG, "addEventSink: $channelName")
    }

    /** Called by MainActivity.onCancel() */
    fun removeEventSink(channelName: String?) {
        if (channelName == null) return
        sinks.remove(channelName)
        Log.i(TAG, "removeEventSink: $channelName")
    }

    /** Public emit helper for any channel we manage */
    fun emit(channelName: String, payload: Any?) {
        sinks[channelName]?.success(payload)
            ?: Log.w(TAG, "emit: no active sink for $channelName")
    }
}
