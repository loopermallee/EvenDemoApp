package com.example.demo_ai_even

import android.os.Bundle
import android.util.Log
import com.example.demo_ai_even.bluetooth.BleChannelHelper
import com.example.demo_ai_even.bluetooth.BleManager
import com.example.demo_ai_even.cpp.Cpp
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity(), EventChannel.StreamHandler {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Keep your native inits (from your original file)
        Cpp.init()
        BleManager.instance.initBluetooth(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // All channels (BLE + speech) are set up inside BleChannelHelper
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