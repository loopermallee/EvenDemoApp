package com.example.demo_ai_even

import android.os.Bundle
import com.example.demo_ai_even.bluetooth.BleChannelHelper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Safe: no direct init of Cpp or BleManager here
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // All Event/MethodChannels (BLE + Speech) are created inside BleChannelHelper
        BleChannelHelper.initChannel(this, flutterEngine)
    }
}