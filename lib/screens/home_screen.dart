import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reorderables/reorderables.dart';
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
    final savedTiles = prefs.getStringList('tiles');

    final defaultTiles = [
      Tile(
        id: "dashboard",
        label: "🖥 DASHBOARD",
        icon: Icons.dashboard,
        screen: const SettingsScreen(),
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
      setState(() {
        tiles = savedTiles.asMap().entries.map((entry) {
          final json = entry.value;
          final fallback = defaultTiles.firstWhere(
            (t) => t.id == Tile.fromJson(json, const SettingsScreen()).id,
            orElse: () => defaultTiles[0],
          );
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
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ReorderableWrap(
          spacing: 12,
          runSpacing: 12,
          padding: const EdgeInsets.all(8),
          needsLongPressDraggable: true,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              final item = tiles.removeAt(oldIndex);
              tiles.insert(newIndex, item);
            });
            _saveTiles();
          },
          children: tiles.where((tile) => tile.visible).map((tile) {
            return GestureDetector(
              key: ValueKey(tile.id),
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
                            title: const Text("Pin to Top",
                                style: TextStyle(fontFamily: 'PixelFont', color: Colors.greenAccent)),
                            onTap: () {
                              setState(() {
                                tiles.remove(tile);
                                tiles.insert(0, tile..pinned = true);
                              });
                              _saveTiles();
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.visibility_off, color: Colors.greenAccent),
                            title: const Text("Hide Tile",
                                style: TextStyle(fontFamily: 'PixelFont', color: Colors.greenAccent)),
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
                width: 100,
                height: 100,
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
          }).toList(),
        ),
      ),
    );
  }
}