// lib/views/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// your app files
import 'package:demo_ai_even/ble_manager.dart';
import 'package:demo_ai_even/services/evenai.dart';
import 'package:demo_ai_even/views/even_list_page.dart';
import 'package:demo_ai_even/views/features_page.dart';
import 'package:demo_ai_even/views/api_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? scanTimer;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    BleManager.get().setMethodCallHandler();
    BleManager.get().startListening();
    BleManager.get().onStatusChanged = _refreshPage;
  }

  void _refreshPage() => setState(() {});

  Future<void> _startScan() async {
    setState(() => isScanning = true);
    await BleManager.get().startScan();
    scanTimer?.cancel();
    scanTimer = Timer(const Duration(seconds: 15), _stopScan);
  }

  Future<void> _stopScan() async {
    if (isScanning) {
      await BleManager.get().stopScan();
      setState(() => isScanning = false);
    }
  }

  Widget blePairedList() => Expanded(
        child: ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(height: 5),
          itemCount: BleManager.get().getPairedGlasses().length,
          itemBuilder: (context, index) {
            final glasses = BleManager.get().getPairedGlasses()[index];
            return GestureDetector(
              onTap: () async {
                final channelNumber = glasses['channelNumber']!;
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

  @override
  Widget build(BuildContext context) {
    final bool connected = BleManager.get().isConnected;

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
                MaterialPageRoute(builder: (context) => const FeaturesPage()),
              );
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: const Padding(
              padding: EdgeInsets.only(left: 16, top: 12, bottom: 14, right: 16),
              child: Icon(Icons.menu),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 44),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                if (!connected) {
                  _startScan();
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
                  BleManager.get().getConnectionStatus(),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!connected) blePairedList(),
            if (connected)
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
                                    color: connected
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
    scanTimer?.cancel();
    isScanning = false;
    BleManager.get().onStatusChanged = null;
    super.dispose();
  }
}