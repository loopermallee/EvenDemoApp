package com.example.demo_ai_even.bluetooth

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// DO NOT wrap these inside any class/object/companion.
// They must be top-level so BleManager.kt can see them.
lateinit var bleMC: MethodChannel
lateinit var bleReceive: EventChannel