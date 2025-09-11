package com.example.demo_ai_even.bluetooth

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// Global channel refs so BleManager.kt can call into Flutter
lateinit var bleMC: MethodChannel
lateinit var bleReceive: EventChannel