import 'package:flutter/material.dart';

class BleScreen extends StatefulWidget {
  const BleScreen({Key? key}) : super(key: key);

  @override
  State<BleScreen> createState() => _BleScreenState();
}

class _BleScreenState extends State<BleScreen> {
  bool scanning = false;
  List<String> devices = ["Demo Glasses G1", "Test Device"]; // mock list for now

  void toggleScan() {
    setState(() {
      scanning = !scanning;
    });
    // TODO: integrate with ble_manager.dart scan logic
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("📡 BLE Manager"),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              scanning ? "🔍 Scanning for devices..." : "Idle",
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: toggleScan,
              child: Text(scanning ? "STOP SCAN" : "START SCAN"),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return Card(
                    color: Colors.black,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.greenAccent.shade400, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(device, style: theme.textTheme.bodyLarge),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Connecting to $device...")),
                        );
                        // TODO: integrate with ble_manager.dart connect logic
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}