// android/app/src/main/kotlin/com/example/demo_ai_even/bluetooth/BleChannelHelper.kt
package com.example.demo_ai_even.bluetooth

import android.app.Activity
import android.util.Log
import com.example.demo_ai_even.speech.SpeechBridge
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

object BleChannelHelper {
    private const val TAG = "BleChannelHelper"

    // Channel names
    private const val METHOD_BLUETOOTH = "method.bluetooth"
    private const val EVENT_BLE_RECEIVE = "eventBleReceive"
    private const val METHOD_SPEECH = "method.speech"
    private const val EVENT_SPEECH = "eventSpeechRecognize"

    // Channels
    private lateinit var bleMC: MethodChannel
    private lateinit var bleReceive: EventChannel
    private lateinit var speechMC: MethodChannel
    private lateinit var speechEvent: EventChannel

    // Store active event sinks by name
    private val sinks: MutableMap<String, EventChannel.EventSink> = mutableMapOf()

    fun initChannel(activity: Activity, flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // === BLE MethodChannel ===
        bleMC = MethodChannel(messenger, METHOD_BLUETOOTH)
        bleMC.setMethodCallHandler { call, result ->
            Log.d(TAG, "Received method: ${call.method}, args=${call.arguments}")
            when (call.method) {
                "startScan" -> BleManager.instance.startScan(result)
                "stopScan" -> BleManager.instance.stopScan(result)
                "connectToGlass" -> {
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

        // === BLE EventChannel ===
        bleReceive = EventChannel(messenger, EVENT_BLE_RECEIVE)
        bleReceive.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                sinks[EVENT_BLE_RECEIVE] = sink!!
                Log.i(TAG, "BLE event channel connected")
            }

            override fun onCancel(args: Any?) {
                sinks.remove(EVENT_BLE_RECEIVE)
                Log.i(TAG, "BLE event channel disconnected")
            }
        })

        // === Speech MethodChannel ===
        speechMC = MethodChannel(messenger, METHOD_SPEECH)
        speechMC.setMethodCallHandler { call, result ->
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

        // === Speech EventChannel ===
        speechEvent = EventChannel(messenger, EVENT_SPEECH)
        speechEvent.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                sinks[EVENT_SPEECH] = sink!!
                Log.i(TAG, "Speech event channel connected")
            }

            override fun onCancel(args: Any?) {
                sinks.remove(EVENT_SPEECH)
                Log.i(TAG, "Speech event channel disconnected")
            }
        })
    }

    // Kotlin → Flutter events
    fun emit(eventChannelName: String, payload: Any?) {
        sinks[eventChannelName]?.success(payload)
            ?: Log.w(TAG, "emit: no active sink for $eventChannelName")
    }

    // Flutter → Kotlin (call back into Flutter)
    fun invokeFlutter(method: String, args: Any?) {
        if (::bleMC.isInitialized) {
            bleMC.invokeMethod(method, args)
        } else {
            Log.w(TAG, "invokeFlutter: bleMC not initialized yet")
        }
    }
}