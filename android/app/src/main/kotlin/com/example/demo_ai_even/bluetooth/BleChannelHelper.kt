package com.example.demo_ai_even.bluetooth

import android.app.Activity
import android.util.Log
import com.example.demo_ai_even.speech.SpeechBridge
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

object BleChannelHelper {
    private const val TAG = "BleChannelHelper"

    private const val METHOD_BLUETOOTH = "method.bluetooth"
    private const val EVENT_BLE_RECEIVE = "eventBleReceive"
    private const val METHOD_SPEECH = "method.speech"
    private const val EVENT_SPEECH = "eventSpeechRecognize"

    private lateinit var bleMC: MethodChannel
    private lateinit var bleReceive: EventChannel

    private val sinks: MutableMap<String, EventChannel.EventSink> = mutableMapOf()

    fun initChannel(activity: Activity, flutterEngine: FlutterEngine) {
        // === BLE EventChannel ===
        bleReceive = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_BLE_RECEIVE)
        bleReceive.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                sink?.let { sinks[EVENT_BLE_RECEIVE] = it }
            }
            override fun onCancel(args: Any?) {
                sinks.remove(EVENT_BLE_RECEIVE)
            }
        })

        // === BLE MethodChannel ===
        bleMC = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_BLUETOOTH)
        bleMC.setMethodCallHandler { call, result ->
            Log.d(TAG, "Received method: ${call.method}")
            when (call.method) {
                "startScan" -> BleManager.instance.startScan(result)
                "stopScan" -> BleManager.instance.stopScan(result)
                "connectToGlass", "connectToGlasses" -> {
                    val deviceChannel = call.argument<String>("deviceChannel")
                    if (deviceChannel != null) {
                        BleManager.instance.connectToGlass(deviceChannel, result)
                    } else {
                        result.error("invalid_args", "deviceChannel missing", null)
                    }
                }
                "disconnectFromGlasses" -> BleManager.instance.disconnectFromGlasses(result)
                "senData" -> {
                    val params = call.arguments as? Map<*, *>
                    BleManager.instance.senData(params)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // === Speech EventChannel ===
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_SPEECH)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    sink?.let { sinks[EVENT_SPEECH] = it }
                }
                override fun onCancel(args: Any?) {
                    sinks.remove(EVENT_SPEECH)
                }
            })

        // === Speech MethodChannel ===
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_SPEECH)
            .setMethodCallHandler { call, result ->
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
    }

    // Kotlin → Flutter (notify via MethodChannel)
    fun invokeFlutter(method: String, args: Any?) {
        if (::bleMC.isInitialized) {
            bleMC.invokeMethod(method, args)
        } else {
            Log.w(TAG, "bleMC not initialized yet")
        }
    }

    // Kotlin → Flutter (send event via EventChannel)
    fun emit(eventChannelName: String, payload: Any?) {
        sinks[eventChannelName]?.success(payload)
            ?: Log.w(TAG, "emit: no sink for $eventChannelName")
    }
}