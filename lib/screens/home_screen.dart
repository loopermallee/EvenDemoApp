import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tile.dart';
import 'ble_screen.dart';
import 'evenai_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Tile> tiles = [];

  @override
  void initState() {
    super.initState();
    _loadTiles();
  }

  Future<void> _loadTiles() async {
    final prefs = await SharedPreferences.getInstance();

    // Default tiles (if first run)
    final defaultTiles = [
      Tile(
        id: "dashboard",
        label: "🖥 DASHBOARD",
        icon: Icons.dashboard,
        screen: const SettingsScreen(), // placeholder
        order: 0,
      ),
      Tile(
        id: "ble",
        label: "🔍 BLUETOOTH",
        icon: Icons.bluetooth,
        screen: const BLESScreen(),
        order: 1,
      ),
      Tile(
        id: "ai",
        label: "🤖 AI",
        icon: Icons.smart_toy,
        screen: const EvenAIScreen(),
        order: 2,
      ),
      Tile(
        id: "settings",
        label: "⚙ SETTINGS",
        icon: Icons.settings,
        screen: const SettingsScreen(),
        order: 3,
      ),
    ];

    setState(() {
      tiles = defaultTiles;
    });
  }

  void _openTile(Tile tile) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => tile.screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("🟩 Even Demo Hub")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3x3 grid
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: tiles.length,
        itemBuilder: (context, index) {
          final tile = tiles[index];
          if (!tile.visible) return const SizedBox.shrink();

          return GestureDetector(
            onTap: () => _openTile(tile),
            onLongPress: () {
              // 🔧 Open customization menu
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.push_pin, color: Colors.greenAccent),
                          title: const Text("Pin to Top", style: TextStyle(color: Colors.greenAccent, fontFamily: 'PixelFont')),
                          onTap: () {
                            setState(() => tile.pinned = true);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.visibility_off, color: Colors.greenAccent),
                          title: const Text("Hide Tile", style: TextStyle(color: Colors.greenAccent, fontFamily: 'PixelFont')),
                          onTap: () {
                            setState(() => tile.visible = false);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 2),
                color: Colors.black,
              ),
              child: Center(
                child: Text(
                  tile.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'PixelFont',
                    color: Colors.greenAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}