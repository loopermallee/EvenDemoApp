import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import placeholder screens
import 'translate_screen.dart';
import 'navigate_screen.dart';
import 'teleprompt_screen.dart';
import 'ai_screen.dart';
import 'transcribe_screen.dart';
import 'todo_screen.dart';
import 'commute_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<String> tiles = [
    "Translate",
    "Navigate",
    "Teleprompt",
    "AI",
    "Transcribe",
    "To-Do",
    "Commute",
    "Notifications"
  ];

  double brightness = 50;

  @override
  void initState() {
    super.initState();
    _loadTiles();
    _loadBrightness();
  }

  Future<void> _loadTiles() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTiles = prefs.getStringList("dashboard_tiles");
    if (savedTiles != null && savedTiles.isNotEmpty) {
      setState(() => tiles = savedTiles);
    }
  }

  Future<void> _saveTiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("dashboard_tiles", tiles);
  }

  Future<void> _loadBrightness() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBrightness = prefs.getDouble("brightness");
    if (savedBrightness != null) {
      setState(() => brightness = savedBrightness);
    }
  }

  Future<void> _saveBrightness() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("brightness", brightness);
  }

  void _navigateToTile(String tile) {
    switch (tile) {
      case "Translate":
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslateScreen()));
        break;
      case "Navigate":
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NavigateScreen()));
        break;
      case "Teleprompt":
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TelepromptScreen()));
        break;
      case "AI":
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AIScreen()));
        break;
      case "Transcribe":
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TranscribeScreen()));
        break;
      case "To-Do":
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ToDoScreen()));
        break;
      case "Commute":
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CommuteScreen()));
        break;
      case "Notifications":
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        break;
    }
  }

  Widget _buildTile(String tile) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _navigateToTile(tile),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.greenAccent, width: 2),
          color: Colors.black,
        ),
        child: Text(
          tile,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontFamily: "PixelFont",
            color: Colors.greenAccent,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("📟 DASHBOARD"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Brightness control
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "☀ BRIGHTNESS",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: "PixelFont",
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  min: 0,
                  max: 100,
                  value: brightness,
                  activeColor: Colors.greenAccent,
                  inactiveColor: Colors.greenAccent.withOpacity(0.3),
                  onChanged: (value) {
                    setState(() => brightness = value);
                    _saveBrightness();
                  },
                ),
              ],
            ),
          ),

          // Tiles (reorderable & persistent)
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.all(16),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = tiles.removeAt(oldIndex);
                  tiles.insert(newIndex, item);
                });
                _saveTiles();
              },
              children: [
                for (final tile in tiles)
                  Padding(
                    key: ValueKey(tile),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildTile(tile),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}