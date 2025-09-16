// lib/services/ble.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // ✅ for storage permission
import 'package:demo_ai_even/services/evenai.dart';
import 'package:demo_ai_even/services/gesture_handler.dart';

class BLEService {
  static const _serviceChannel =
      MethodChannel("com.example.demo_ai_even/ble_service");

  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? connectedDevice;

  final List<int> _micBuffer = [];
  final EvenAI evenAI = Get.put(EvenAI());

  File? _logFile;

  Future<void> _initLogFile() async {
    // ✅ Request permission first
    if (await Permission.storage.request().isGranted) {
      final dir = Directory("/storage/emulated/0/Download");
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _logFile = File("${dir.path}/ble_debug_log.txt");
    } else {
      // fallback → sandbox storage
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File("${dir.path}/ble_debug_log.txt");
    }

    if (!await _logFile!.exists()) {
      await _logFile!.create(recursive: true);
    }
  }

  Future<void> _writeLog(String message) async {
    await _initLogFile();
    final ts = DateTime.now().toIso8601String();
    await _logFile!.writeAsString("[$ts] $message\n",
        mode: FileMode.append, flush: true);
    print(message);
  }

  Future<List<BluetoothDevice>> scanForDevices() async {
    final results = <BluetoothDevice>[];
    await _flutterBlue.startScan(timeout: const Duration(seconds: 5));

    await for (final result in _flutterBlue.scanResults) {
      results.add(result.device);
    }

    await _flutterBlue.stopScan();
    return results;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(autoConnect: false);
    connectedDevice = device;

    try {
      await _serviceChannel.invokeMethod("startForegroundService");
    } catch (e) {
      await _writeLog("⚠️ Failed to start foreground service: $e");
    }

    List<BluetoothService> services = await device.discoverServices();
    await _writeLog("🔍 Found ${services.length} services");

    for (var service in services) {
      await _writeLog("🟢 Service UUID: ${service.uuid}");

      for (var char in service.characteristics) {
        await _writeLog("   ↳ Characteristic UUID: ${char.uuid}, "
            "read=${char.properties.read}, "
            "write=${char.properties.write}, "
            "notify=${char.properties.notify}, "
            "indicate=${char.properties.indicate}");

        if (char.properties.notify) {
          await char.setNotifyValue(true);
          char.value.listen((data) async {
            await _writeLog("📡 [${char.uuid}] ${data.length} bytes: $data");
          });
        }
      }
    }
  }

  Future<void> stopMicRecording() async {
    if (_micBuffer.isEmpty) {
      await _writeLog("⚠️ No audio captured");
      return;
    }
    final audioBytes = Uint8List.fromList(_micBuffer);
    try {
      await evenAI.startListening(audioBytes);
    } catch (e) {
      await _writeLog("⚠️ Failed to process audio: $e");
    }
    _micBuffer.clear();
  }

  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      connectedDevice = null;
      await _serviceChannel.invokeMethod("stopForegroundService");
    } catch (e) {
      await _writeLog("⚠️ Failed to stop service: $e");
      await evenAI.stopEvenAIByOS();
    }
  }
}