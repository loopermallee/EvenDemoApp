import 'package:flutter/material.dart';

class BLESScreen extends StatefulWidget {
  const BLESScreen({super.key});

  @override
  State<BLESScreen> createState() => _BLESScreenState();
}

class _BLESScreenState extends State<BLESScreen> {
  List<String> devices = ["Device_A", "Device_B"]; // Mock list

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🔍 BLUETOOTH SCAN")),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(devices[index]),
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Connected to ${devices[index]}")),
                );
              },
              child: const Text("CONNECT"),
            ),
          );
        },
      ),
    );
  }
}