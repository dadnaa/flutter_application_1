// ─────────────────────────────────────────────────────────────────────────────
// splash_screen.dart
//
// FIXES:
//   1. CRITICAL: The original file declared a second `List<Song> favoritesList`
//      at the bottom. This meant there were THREE separate global favorite lists
//      (data/favorites_state.dart, splash_screen.dart, and any local copies).
//      All three are replaced by FavoritesNotifier.instance — one source of truth.
//   2. Loads favorites via FavoritesNotifier.loadFromDb() instead of a raw list.
//   3. Error handling: if DB load fails the app still proceeds (shows empty list).
//   4. Unused playlist_data.dart import removed.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../data/favorites_notifier.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _navigationTimer = Timer(const Duration(seconds: 2), _navigateToHome);
  }

  Future<void> _navigateToHome() async {
    // FIX: Load into singleton FavoritesNotifier instead of a raw global list.
    try {
      await FavoritesNotifier.instance.loadFromDb();
    } catch (_) {
      // DB error — proceed with empty favorites so the app doesn't hard crash.
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: RotationTransition(
          turns: _controller,
          child: Image.network(
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTk9HyeEo51sGaClQfeHOraOhUS9sJ1ULVDMg&s',
            width: 150,
            // FIX: Provide a fallback icon in case network is unavailable.
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.music_note, size: 100, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
