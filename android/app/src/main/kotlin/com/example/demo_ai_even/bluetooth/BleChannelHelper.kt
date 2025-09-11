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
    private const val METHOD_BLUETOOTH = "method.bluetooth"
    private const val EVENT_BLE_RECEIVE = "eventBleReceive"
    private const val METHOD_SPEECH = "method.speech"
    private const val EVENT_SPEECH = "eventSpeechRecognize"

    private val sinks: MutableMap<String, EventChannel.EventSink> = mutableMapOf()

    fun initChannel(activity: Activity, flutterEngine: FlutterEngine) {
        // --- BLE channels (assign globals) ---
        bleReceive = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_BLE_RECEIVE)
        bleReceive.setStreamHandler(activity as? EventChannel.StreamHandler)

        bleMC = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_BLUETOOTH)
        bleMC.setMethodCallHandler { call, result ->
            // TODO: put your BLE method handlers back here if you had them
            result.notImplemented()
        }

        // --- Speech channels ---
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_SPEECH)
            .setStreamHandler(activity as? EventChannel.StreamHandler)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_SPEECH)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "start" -> SpeechBridge.start(activity) { ok, err ->
                        if (ok) result.success(true)
                        else result.error("speech_start_failed", err ?: "unknown", null)
                    }
                    "stop" -> { SpeechBridge.stop(finalize = true); result.success(true) }
                    "cancel" -> { SpeechBridge.stop(finalize = false); result.success(true) }
                    else -> result.notImplemented()
                }
            }

        // Forward STT results to Flutter
        SpeechBridge.init(activity) { text, isFinal ->
            emit(EVENT_SPEECH, mapOf("script" to (text ?: ""), "isFinal" to isFinal))
        }
    }

    fun addEventSink(channelName: String?, sink: EventChannel.EventSink?) {
        if (channelName == null || sink == null) return
        sinks[channelName] = sink
        Log.i(TAG, "addEventSink: $channelName")
    }

    fun removeEventSink(channelName: String?) {
        if (channelName == null) return
        sinks.remove(channelName)
        Log.i(TAG, "removeEventSink: $channelName")
    }

    fun emit(channelName: String, payload: Any?) {
        sinks[channelName]?.success(payload)
            ?: Log.w(TAG, "emit: no active sink for $channelName")
    }
}