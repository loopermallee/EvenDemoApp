package com.example.demo_ai_even.bluetooth

import android.app.Activity
import android.util.Log
import com.example.demo_ai_even.speech.SpeechBridge
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// Top-level globals so BleManager can use them too
lateinit var bleMC: MethodChannel
lateinit var bleReceive: EventChannel

object BleChannelHelper {
    private const val TAG = "BleChannelHelper"

    // Channel names
    private const val METHOD_BLUETOOTH = "method.bluetooth"        // Flutter → Android (BLE + callbacks Android→Flutter)
    private const val EVENT_BLE_RECEIVE = "eventBleReceive"        // Android → Flutter (BLE stream)
    private const val METHOD_SPEECH = "method.speech"              // Flutter → Android (STT)
    private const val EVENT_SPEECH = "eventSpeechRecognize"        // Android → Flutter (STT stream)

    private val sinks: MutableMap<String, EventChannel.EventSink> = mutableMapOf()

    fun initChannel(activity: Activity, flutterEngine: FlutterEngine) {
        // === BLE EventChannel (Android → Flutter) ===
        bleReceive = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_BLE_RECEIVE)
        bleReceive.setStreamHandler(activity as? EventChannel.StreamHandler)

        // === BLE MethodChannel (Flutter → Android) ===
        bleMC = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_BLUETOOTH)
        bleMC.setMethodCallHandler { call, result ->
            when (call.method) {
                "startScan" -> {
                    BleManager.instance.startScan(result)
                }
                "stopScan" -> {
                    BleManager.instance.stopScan(result)
                }
                "connectToGlass" -> {
                    val deviceChannel = call.argument<String>("deviceChannel")
                    if (deviceChannel.isNullOrEmpty()) {
                        result.error("bad_args", "deviceChannel is required", null)
                    } else {
                        BleManager.instance.connectToGlass(deviceChannel, result)
                    }
                }
                "disconnectFromGlasses" -> {
                    BleManager.instance.disconnectFromGlasses(result)
                }
                "sendData" -> {
                    // Dart sends List<int>, convert to ByteArray
                    val list = call.argument<ArrayList<Int>>("data") ?: arrayListOf()
                    val lr = call.argument<String>("lr")
                    val bytes = ByteArray(list.size) { i -> (list[i] and 0xFF).toByte() }
                    val params = hashMapOf<String, Any?>("data" to bytes, "lr" to lr)
                    BleManager.instance.senData(params)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // === Speech EventChannel (Android → Flutter) ===
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_SPEECH)
            .setStreamHandler(activity as? EventChannel.StreamHandler)

        // === Speech MethodChannel (Flutter → Android) ===
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_SPEECH)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "start" -> SpeechBridge.start(activity) { ok, err ->
                        if (ok) result.success(true) else result.error("speech_start_failed", err ?: "unknown", null)
                    }
                    "stop" -> { SpeechBridge.stop(finalize = true); result.success(true) }
                    "cancel" -> { SpeechBridge.stop(finalize = false); result.success(true) }
                    else -> result.notImplemented()
                }
            }

        // Forward STT partial/final text to Flutter UI
        SpeechBridge.init(activity) { text, isFinal ->
            emit(EVENT_SPEECH, mapOf("script" to (text ?: ""), "isFinal" to isFinal))
        }
    }

    // Stream helpers used by MainActivity
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