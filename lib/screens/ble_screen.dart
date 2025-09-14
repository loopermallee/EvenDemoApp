import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble.dart'; // Import BLEService

class BLESScreen extends StatefulWidget {
  const BLESScreen({super.key});

  @override
  State<BLESScreen> createState() => _BLESScreenState();
}

class _BLESScreenState extends State<BLESScreen> {
  final BLEService _bleService = BLEService();
  List<BluetoothDevice> devices = [];
  BluetoothDevice? connectedDevice;
  bool isScanning = false;

  Future<void> _scanDevices() async {
    setState(() => isScanning = true);
    final results = await _bleService.scanForDevices();
    setState(() {
      devices = results;
      isScanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _bleService.connectToDevice(device);
      setState(() => connectedDevice = device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Connected to ${device.name.isNotEmpty ? device.name : device.id}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Connection failed: $e")),
        );
      }
    }
  }

  Future<void> _disconnectDevice() async {
    if (connectedDevice != null) {
      await _bleService.disconnectFromDevice(connectedDevice!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🔌 Disconnected from ${connectedDevice!.name.isNotEmpty ? connectedDevice!.name : connectedDevice!.id}")),
        );
      }
      setState(() => connectedDevice = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🔍 BLUETOOTH SCAN"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _scanDevices,
          ),
          if (connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.link_off),
              onPressed: _disconnectDevice,
            ),
        ],
      ),
      body: isScanning
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : devices.isEmpty
              ? Center(
                  child: Text(
                    "No devices found.\nPress refresh to scan.",
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isConnected = connectedDevice?.id == device.id;

                    return ListTile(
                      title: Text(
                        device.name.isNotEmpty ? device.name : device.id.toString(),
                        style: theme.textTheme.bodyLarge,
                      ),
                      trailing: ElevatedButton(
                        onPressed: isConnected
                            ? _disconnectDevice
                            : () => _connectToDevice(device),
                        child: Text(isConnected ? "DISCONNECT" : "CONNECT"),
                      ),
                    );
                  },
                ),
    );
  }
}