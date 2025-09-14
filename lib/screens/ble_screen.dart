import 'package:flutter/material.dart';

class BLESScreen extends StatefulWidget {
  const BLESScreen({super.key});

  @override
  State<BLESScreen> createState() => _BLESScreenState();
}

class _BLESScreenState extends State<BLESScreen> {
  List<String> devices = ["Device_A", "Device_B"]; // Mock list for now

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🔍 BLUETOOTH SCAN"),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.black,
        child: devices.isEmpty
            ? Center(
                child: Text(
                  "No devices found",
                  style: theme.textTheme.bodyLarge,
                ),
              )
            : ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 1),
                      color: Colors.black,
                    ),
                    child: ListTile(
                      title: Text(
                        devices[index],
                        style: theme.textTheme.bodyLarge,
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Connected to ${devices[index]}",
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          );
                        },
                        child: const Text("CONNECT"),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}