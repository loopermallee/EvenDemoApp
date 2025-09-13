// lib/pages/ble_test_page.dart
import 'package:flutter/material.dart';
import '../services/ble_service.dart';

class BleTestPage extends StatefulWidget {
  const BleTestPage({super.key});

  @override
  State<BleTestPage> createState() => _BleTestPageState();
}

class _BleTestPageState extends State<BleTestPage> {
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    // Listen for incoming BLE events
    BleService.instance.bleEvents.listen((event) {
      setState(() {
        _logs.insert(0, event.toString()); // newest first
      });
    });
  }

  void _addLog(String msg) {
    setState(() {
      _logs.insert(0, msg);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE Test Page")),
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await BleService.instance.startScan();
                  _addLog("🔍 Started scanning...");
                },
                child: const Text("Start Scan"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await BleService.instance.stopScan();
                  _addLog("🛑 Stopped scanning.");
                },
                child: const Text("Stop Scan"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await BleService.instance.connectToGlass("45"); // change channel if needed
                  _addLog("🔗 Connecting to glasses...");
                },
                child: const Text("Connect"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await BleService.instance.disconnect();
                  _addLog("❌ Disconnected.");
                },
                child: const Text("Disconnect"),
              ),
            ],
          ),
          const Divider(),
          const Text("Logs:"),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _logs.length,
              itemBuilder: (context, index) =>
                  Text(_logs[index], style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}