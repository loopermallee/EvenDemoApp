package com.example.demo_ai_even

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.ViewGroup
import android.widget.FrameLayout
import com.example.demo_ai_even.bluetooth.BleChannelHelper
import com.example.demo_ai_even.bluetooth.BleManager
import com.example.demo_ai_even.cpp.Cpp
import com.evenreality.g1app.hud.HudOverlay
import com.evenreality.g1app.hud.HudOverlayState
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity(), EventChannel.StreamHandler {

    private val SERVICE_CHANNEL = "com.example.demo_ai_even/ble_service"
    private val HUD_CHANNEL = "com.example.demo_ai_even/hud_preview"

    private var hudOverlay: HudOverlay? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Cpp.init()
        BleManager.instance.initBluetooth(this)
        ensureHudOverlay()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BleChannelHelper.initChannel(this, flutterEngine)

        // ✅ MethodChannel: Foreground Service + BLE reconnect
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startForegroundService" -> {
                        val intent = Intent(this, BLEForegroundService::class.java)
                        startForegroundService(intent)
                        result.success("✅ Foreground service started")
                    }
                    "stopForegroundService" -> {
                        val intent = Intent(this, BLEForegroundService::class.java)
                        stopService(intent)
                        result.success("✅ Foreground service stopped")
                    }
                    "ensureConnected" -> {
                        BleManager.instance.ensureConnected()
                        result.success("✅ BLE ensureConnected triggered")
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HUD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "render" -> {
                        val state = HudOverlayState.fromMap(call.arguments as? Map<*, *>)
                        renderHud(state)
                        result.success(null)
                    }
                    "hide" -> {
                        renderHud(HudOverlayState.Hidden)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun ensureHudOverlay(): HudOverlay {
        hudOverlay?.let { return it }

        val root = findViewById<ViewGroup>(android.R.id.content)
            ?: (window.decorView as? ViewGroup
                ?: throw IllegalStateException("Unable to locate activity content view for HUD overlay"))
        val container = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            )
            setBackgroundColor(android.graphics.Color.TRANSPARENT)
            isClickable = false
            isFocusable = false
        }
        root.addView(container)

        return HudOverlay(this, container).also {
            it.render(HudOverlayState.Hidden)
            hudOverlay = it
        }
    }

    private fun renderHud(state: HudOverlayState) {
        Log.d(this::class.simpleName, "HUD preview update: $state")
        ensureHudOverlay().render(state)
    }

    // 🔹 EventChannel: for streaming BLE events into Flutter
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.i(
            this::class.simpleName,
            "EventChannel.StreamHandler - OnListen: arguments = $arguments ,events = $events"
        )
        BleChannelHelper.addEventSink(arguments as String?, events)
    }

    override fun onCancel(arguments: Any?) {
        Log.i(
            this::class.simpleName,
            "EventChannel.StreamHandler - OnCancel: arguments = $arguments"
        )
        BleChannelHelper.removeEventSink(arguments as String?)
    }
}