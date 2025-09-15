package com.example.demo_ai_even

import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.example.demo_ai_even.bluetooth.BleChannelHelper
import com.example.demo_ai_even.bluetooth.BleManager
import com.example.demo_ai_even.cpp.Cpp
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity(), EventChannel.StreamHandler {

    private val SERVICE_CHANNEL = "com.example.demo_ai_even/ble_service"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Cpp.init()
        BleManager.instance.initBluetooth(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BleChannelHelper.initChannel(this, flutterEngine)

        // ✅ Add MethodChannel for Foreground Service control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startForegroundService" -> {
                        val intent = Intent(this, BLEForegroundService::class.java)
                        startForegroundService(intent)
                        result.success(null)
                    }
                    "stopForegroundService" -> {
                        val intent = Intent(this, BLEForegroundService::class.java)
                        stopService(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Interface - EventChannel.StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.i(
            this::class.simpleName,
            "EventChannel.StreamHandler - OnListen: arguments = $arguments ,events = $events"
        )
        BleChannelHelper.addEventSink(arguments as String?, events)
    }

    /// Interface - EventChannel.StreamHandler
    override fun onCancel(arguments: Any?) {
        Log.i(
            this::class.simpleName,
            "EventChannel.StreamHandler - OnCancel: arguments = $arguments"
        )
        BleChannelHelper.removeEventSink(arguments as String?)
    }
}