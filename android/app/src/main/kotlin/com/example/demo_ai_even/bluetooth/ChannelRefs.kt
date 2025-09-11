package com.example.demo_ai_even.bluetooth

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// Global references so existing BleManager.kt can use them
lateinit var bleMC: MethodChannel
lateinit var bleReceive: EventChannel