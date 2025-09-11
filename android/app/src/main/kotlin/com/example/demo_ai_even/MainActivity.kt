package com.example.demo_ai_even

import android.os.Bundle
import android.util.Log
import com.example.demo_ai_even.bluetooth.BleChannelHelper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity(), EventChannel.StreamHandler {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // NOTE: Intentionally not calling Cpp.init() or BleManager.initBluetooth() in this SAFE version
        // so the build cannot fail if those classes or imports are missing/mispackaged.
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // All Event/MethodChannels (BLE + Speech) are created inside BleChannelHelper
        BleChannelHelper.initChannel(this, flutterEngine)
    }

    // === EventChannel.StreamHandler ===
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.i(this::class.simpleName, "onListen: arguments=$arguments, events=$events")
        BleChannelHelper.addEventSink(arguments as String?, events)
    }

    override fun onCancel(arguments: Any?) {
        Log.i(this::class.simpleName, "onCancel: arguments=$arguments")
        BleChannelHelper.removeEventSink(arguments as String?)
    }
}