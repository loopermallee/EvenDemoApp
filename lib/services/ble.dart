import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BLEService {
  BluetoothDevice? connectedDevice;

  /// Scan for nearby Bluetooth devices
  Future<List<BluetoothDevice>> scanForDevices() async {
    List<BluetoothDevice> devices = [];
    FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

    await flutterBlue.startScan(timeout: const Duration(seconds: 4));
    await for (var results in flutterBlue.scanResults.first) {
      devices.addAll(results.map((r) => r.device));
    }
    await flutterBlue.stopScan();

    // Remove duplicates by device ID
    final uniqueDevices = {
      for (var d in devices) d.id: d,
    }.values.toList();

    return uniqueDevices;
  }

  /// Connect to a Bluetooth device
  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(autoConnect: true);
    connectedDevice = device;

    // Save device ID for future auto-reconnect
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_connected_device', device.id.id);
  }

  /// Disconnect from current device
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    await device.disconnect();
    connectedDevice = null;

    // Remove saved device ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_connected_device');
  }

  /// Try to reconnect to the last saved device
  Future<BluetoothDevice?> reconnectLastDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('last_connected_device');

    if (deviceId != null) {
      try {
        final device = BluetoothDevice.fromId(deviceId);
        await device.connect(autoConnect: true);
        connectedDevice = device;
        return device;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}