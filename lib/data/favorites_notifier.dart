// ─────────────────────────────────────────────────────────────────────────────
// favorites_notifier.dart
//
// FIX (CRITICAL): The original app used a bare global `List<Song> favoritesList`
// with manual `setState(() {})` calls scattered across multiple widgets.
// This caused several bugs:
//   1. FavoritesPage did NOT rebuild when favorites were toggled from
//      PlaylistPage because they shared no common state notifier.
//   2. Duplicate entries could appear if toggleFavorite was tapped quickly
//      (no guard against concurrent insertions).
//   3. PlaylistPage imported `favoritesList` from splash_screen.dart, while
//      favorites_page.dart imported from data/favorites_state.dart — two
//      different lists that could diverge!
//
// SOLUTION: Replace all raw list globals with FavoritesNotifier (ChangeNotifier).
// All widgets use ListenableBuilder / addListener to get instant UI updates
// without passing setState callbacks around.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../db/favorites_db.dart';

class FavoritesNotifier extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────────────────────
  FavoritesNotifier._();
  static final FavoritesNotifier instance = FavoritesNotifier._();

  // ── Internal list – single source of truth ─────────────────────────────────
  final List<Song> _favorites = [];

  // ── Read-only view for widgets ─────────────────────────────────────────────
  List<Song> get favorites => List.unmodifiable(_favorites);

  // ── Load from DB (call once at startup in SplashScreen) ───────────────────
  Future<void> loadFromDb() async {
    final loaded = await FavoritesDb.getFavorites();
    _favorites
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  // ── Check ─────────────────────────────────────────────────────────────────
  bool isFavorite(String url) => _favorites.any((s) => s.url == url);

  // ── Toggle (add/remove) ────────────────────────────────────────────────────
  // FIX: Added a `_busy` guard so rapid taps cannot insert duplicates while
  // the previous DB operation is still in flight.
  bool _busy = false;

  Future<void> toggle(Song song) async {
    if (_busy) return;
    _busy = true;
    try {
      if (isFavorite(song.url)) {
        await FavoritesDb.removeFavorite(song.url);
        _favorites.removeWhere((s) => s.url == song.url);
      } else {
        // Guard against duplicates even on race conditions
        if (!isFavorite(song.url)) {
          await FavoritesDb.insertFavorite(song);
          _favorites.add(song);
        }
      }
      notifyListeners(); // Triggers instant UI update across all listeners
    } finally {
      _busy = false;
    }
  }

  // ── Remove (used by long-press confirm dialog) ────────────────────────────
  Future<void> remove(Song song) async {
    await FavoritesDb.removeFavorite(song.url);
    _favorites.removeWhere((s) => s.url == song.url);
    notifyListeners();
  }
}
