// lib/views/home_page.dart
// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ble_manager.dart';
import '../services/evenai.dart';
import 'even_list_page.dart';
import 'features_page.dart';
import 'api_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _scanTimer;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    // Keep UI synced with Bluetooth events
    BleManager.get().onStatusChanged = _refreshPage;
  }

  void _refreshPage() => setState(() {});

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    await BleManager.get().startScan();

    _scanTimer?.cancel();
    _scanTimer = Timer(15.seconds, () {
      _stopScan();
    });
  }

  Future<void> _stopScan() async {
    if (_isScanning) {
      await BleManager.get().stopScan();
      setState(() => _isScanning = false);
    }
  }

  Widget _buildPairedList() {
    final pairs = BleManager.get().getPairedGlasses();

    if (pairs.isEmpty) {
      return const Center(
        child: Text("No paired glasses found yet"),
      );
    }

    return Expanded(
      child: ListView.separated(
        separatorBuilder: (_, __) => const SizedBox(height: 5),
        itemCount: pairs.length,
        itemBuilder: (context, index) {
          final glasses = pairs[index];
          return GestureDetector(
            onTap: () async {
              final channelNumber = glasses['channelNumber'] ?? "0";
              await BleManager.get().connectToGlasses("Pair_$channelNumber");
              _refreshPage();
            },
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pair: ${glasses['channelNumber']}'),
                      Text(
                        'Left: ${glasses['leftDeviceName']} \nRight: ${glasses['rightDeviceName']}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = BleManager.get().getConnectionStatus();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Even AI Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'API Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ApiSettingsPage()),
              );
            },
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeaturesPage()),
              );
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.menu),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 44),
        child: Column(
          children: [
            // Connection status tile
            GestureDetector(
              onTap: () async {
                if (status == 'Not connected') {
                  _startScan();
                } else {
                  await BleManager.get().disconnectFromGlasses();
                  _refreshPage();
                }
              },
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Show scan/paired list if not connected
            if (status == 'Not connected') _buildPairedList(),

            // Show EvenAI stream when connected
            if (BleManager.get().isConnected)
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EvenAIListPage(),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      child: StreamBuilder<String>(
                        stream: EvenAI.textStream,
                        initialData:
                            "Press and hold left TouchBar to engage Even AI.",
                        builder: (context, snapshot) => Obx(
                          () => EvenAI.isEvenAISyncing.value
                              ? const SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(),
                                )
                              : Text(
                                  snapshot.data ?? "Loading...",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: BleManager.get().isConnected
                                        ? Colors.black
                                        : Colors.grey.withOpacity(0.5),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _isScanning = false;
    BleManager.get().onStatusChanged = null;
    super.dispose();
  }
}