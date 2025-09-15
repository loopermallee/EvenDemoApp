import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble.dart';
import 'evenai_screen.dart'; // ✅ added import

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tryReconnectLast();
  }

  /// 🔄 Try reconnecting to last known device on app launch
  Future<void> _tryReconnectLast() async {
    final device = await _bleService.reconnectLastDevice();
    if (mounted) {
      setState(() {
        connectedDevice = device;
        isLoading = false;
      });
      if (device != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🔄 Auto-reconnected to ${device.name.isNotEmpty ? device.name : device.id}",
              style: const TextStyle(fontFamily: 'PixelFont', color: Colors.greenAccent),
            ),
          ),
        );
      }
    }
  }

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
          SnackBar(
            content: Text(
              "✅ Connected to ${device.name.isNotEmpty ? device.name : device.id}",
              style: const TextStyle(fontFamily: 'PixelFont', color: Colors.greenAccent),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ Connection failed: $e",
              style: const TextStyle(fontFamily: 'PixelFont', color: Colors.greenAccent),
            ),
          ),
        );
      }
    }
  }

  Future<void> _disconnectDevice() async {
    if (connectedDevice != null) {
      await _bleService.disconnectFromDevice(connectedDevice!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🔌 Disconnected from ${connectedDevice!.name.isNotEmpty ? connectedDevice!.name : connectedDevice!.id}",
              style: const TextStyle(fontFamily: 'PixelFont', color: Colors.greenAccent),
            ),
          ),
        );
      }
      setState(() => connectedDevice = null);
    }
  }

  /// 🚀 Navigate to EvenAI with connected device
  void _openEvenAI() {
    if (connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⚠️ Connect a device first before using EvenAI",
            style: TextStyle(fontFamily: 'PixelFont', color: Colors.greenAccent),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvenAIScreen(connectedDevice: connectedDevice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

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
          IconButton(
            icon: const Icon(Icons.smart_toy), // 🤖 shortcut
            onPressed: _openEvenAI,
          ),
        ],
      ),
      body: isScanning
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : devices.isEmpty
              ? Center(
                  child: Text(
                    connectedDevice == null
                        ? "No devices found.\nPress refresh to scan."
                        : "Connected to ${connectedDevice!.name.isNotEmpty ? connectedDevice!.name : connectedDevice!.id}",
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