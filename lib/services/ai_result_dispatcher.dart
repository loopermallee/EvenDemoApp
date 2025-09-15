import 'dart:async';
import '../bluetooth/ble.dart';
import 'gesture_handler.dart';

/// Handles splitting long ChatGPT replies into pages,
/// sending them to the glasses via BLE,
/// and coordinating HUD auto-page + gesture page flips.
class AIResultDispatcher {
  static const int maxCharsPerPage = 120; // adjust for glasses screen size
  static const Duration autoPageDelay = Duration(seconds: 6);

  static final List<String> _pages = [];
  static int _currentPage = 0;
  static Timer? _pageTimer;

  /// Send a ChatGPT reply to the glasses in multiple pages
  static Future<void> dispatchReply(String reply) async {
    // Split into pages
    _pages.clear();
    _currentPage = 0;

    for (int i = 0; i < reply.length; i += maxCharsPerPage) {
      _pages.add(reply.substring(
        i,
        i + maxCharsPerPage > reply.length ? reply.length : i + maxCharsPerPage,
      ));
    }

    if (_pages.isEmpty) return;

    _showPage(_currentPage);
    _scheduleNextPage();
  }

  /// Show a page on glasses + HUD
  static void _showPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pages.length) return;

    final text = _pages[pageIndex];
    final hudMessage = "[${pageIndex + 1}/${_pages.length}] $text";

    // ✅ Show HUD countdown
    GestureHandler.showHUD(hudMessage);

    // ✅ Send to glasses over BLE
    BLEService().sendTextToGlasses(text);
  }

  /// Schedule auto-advance
  static void _scheduleNextPage() {
    _pageTimer?.cancel();
    _pageTimer = Timer(autoPageDelay, () {
      if (_currentPage + 1 < _pages.length) {
        _currentPage++;
        _showPage(_currentPage);
        _scheduleNextPage();
      } else {
        GestureHandler.showHUD("~ End of reply ~");
      }
    });
  }

  /// User tapped left = prev / right = next
  static void handleGesture(String gesture) {
    if (_pages.isEmpty) return;

    if (gesture == "left" && _currentPage > 0) {
      _currentPage--;
      _showPage(_currentPage);
    } else if (gesture == "right" && _currentPage + 1 < _pages.length) {
      _currentPage++;
      _showPage(_currentPage);
    }
  }
}