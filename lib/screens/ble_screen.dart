import 'package:flutter/material.dart';

class BLESScreen extends StatefulWidget {
  const BLESScreen({super.key});

  @override
  State<BLESScreen> createState() => _BLESScreenState();
}

class _BLESScreenState extends State<BLESScreen> {
  List<String> logs = ["🔌 BLE MANAGER INITIALIZED..."];
  bool scanning = false;

  void addLog(String message) {
    setState(() {
      logs.add("> $message");
    });
  }

  void startScan() {
    setState(() {
      scanning = true;
      logs.add("🔍 STARTING SCAN FOR DEVICES...");
    });

    // TODO: Replace with real BLE scan integration
    Future.delayed(const Duration(seconds: 2), () {
      addLog("FOUND DEVICE: EVEN_G1_001");
      addLog("FOUND DEVICE: EVEN_G1_002");
      setState(() => scanning = false);
    });
  }

  void connectToDevice(String device) {
    addLog("CONNECTING TO $device...");
    // TODO: Replace with real BLE connect logic
    Future.delayed(const Duration(seconds: 2), () {
      addLog("✅ SUCCESSFULLY CONNECTED TO $device");
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🔌 BLE MANAGER"),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: scanning ? null : startScan,
              child: Text(scanning ? "SCANNING..." : "START SCAN"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.greenAccent, width: 2),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    logs.join("\n"),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      height: 1.5,
                      fontFamily: "PixelFont",
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => connectToDevice("EVEN_G1_001"),
              child: const Text("CONNECT TO EVEN_G1_001"),
            ),
          ],
        ),
      ),
    );
  }
}