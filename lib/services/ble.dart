import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// =========================
/// Data Model for BLE Packets
/// =========================
class BleReceive {
  String lr = "";
  Uint8List data = Uint8List(0);
  String type = "";
  bool isTimeout = false;
 
  int getCmd() {
    return data[0].toInt();
  }

  BleReceive();

  static BleReceive fromMap(Map map) {
    var ret = BleReceive();
    ret.lr = map["lr"];
    ret.data = map["data"];
    ret.type = map["type"];
    return ret;
  }

  String hexStringData() {
    return data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
  }
}

/// Enum for BLE Events
enum BleEvent {
  exitFunc,
  nextPageForEvenAI,
  upHeader,
  downHeader,
  glassesConnectSuccess, // 17 Bluetooth binding successful
  evenaiStart,           // 23 Notify the phone to start Even AI
  evenaiRecordOver,      // 24 Even AI recording ends
}

/// =========================
/// BLE Manager Service
/// =========================
class BLEService {
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;

  /// Scan for nearby Bluetooth devices
  Future<List<BluetoothDevice>> scanForDevices() async {
    List<BluetoothDevice> devices = [];

    _flutterBlue.startScan(timeout: const Duration(seconds: 5));

    _flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!devices.contains(r.device)) {
          devices.add(r.device);
        }
      }
    });

    await Future.delayed(const Duration(seconds: 6));
    _flutterBlue.stopScan();

    return devices;
  }

  /// Connect to a device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
    } catch (e) {
      if (e.toString().contains("already connected")) {
        // Ignore duplicate connection
      } else {
        rethrow;
      }
    }
  }

  /// Disconnect from a device
  Future<void> disconnectDevice(BluetoothDevice device) async {
    await device.disconnect();
  }
}