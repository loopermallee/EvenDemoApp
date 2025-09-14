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
                    return ListTile(
                      title: Text(
                        device.name.isNotEmpty ? device.name : device.id.toString(),
                        style: theme.textTheme.bodyLarge,
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _connectToDevice(device),
                        child: const Text("CONNECT"),
                      ),
                    );
                  },
                ),
    );
  }
}