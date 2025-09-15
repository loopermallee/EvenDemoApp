import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tile.dart';
import 'ble_screen.dart';
import 'evenai_screen.dart';
import 'settings_screen.dart';
import 'loading_screen.dart'; // Example extra screen

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
    final savedTiles = prefs.getStringList('tiles');

    // Default tiles
    final defaultTiles = [
      Tile(
        id: "dashboard",
        label: "🖥 DASHBOARD",
        icon: Icons.dashboard,
        screen: const SettingsScreen(), // Placeholder for now
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

    if (savedTiles == null) {
      setState(() => tiles = defaultTiles);
    } else {
      // Map saved order & visibility
      setState(() {
        tiles = savedTiles.asMap().entries.map((entry) {
          final json = entry.value;
          final fallback = defaultTiles[entry.key]; // match ID if possible
          return Tile.fromJson(json, fallback.screen);
        }).toList();
      });
    }
  }

  Future<void> _saveTiles() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = tiles.map((tile) => tile.toJson()).toList();
    await prefs.setStringList('tiles', encoded);
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
          crossAxisCount: 3,
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
              // 🔧 Customization menu
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
                          title: const Text("Pin to Top", style: TextStyle(fontFamily: 'PixelFont', color: Colors.greenAccent)),
                          onTap: () {
                            setState(() {
                              tile.pinned = true;
                              tiles.sort((a, b) => (a.pinned ? 0 : 1).compareTo(b.pinned ? 0 : 1));
                            });
                            _saveTiles();
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.visibility_off, color: Colors.greenAccent),
                          title: const Text("Hide Tile", style: TextStyle(fontFamily: 'PixelFont', color: Colors.greenAccent)),
                          onTap: () {
                            setState(() => tile.visible = false);
                            _saveTiles();
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