import 'dart:async';
import 'package:flutter/material.dart';
import '../db/favorites_db.dart';
import '../data/playlist_data.dart';
import 'playlist_page.dart';
import '../models/song.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _controller.forward();

    Timer(const Duration(seconds: 2), () async {
      // We'll store favorites globally – for simplicity, we'll keep a global var
      // but you could use a provider. I'll keep the original approach:
      // a global List<Song> favorites in a separate file? 
      // To avoid too many changes, we keep it as is but you can refactor.
      // For now, I'll just load them and store in a separate global file.
      // Instead, we'll import a global favorites list from a new file.
      // Let's create `lib/data/favorites_state.dart` (next step)
      // For now, I'll assume you'll pass the loaded favorites back.
      // I'll show a simple global approach.
      final loaded = await FavoritesDb.getFavorites();
      // We'll set a global variable defined in a separate file.
      // We'll create `lib/data/favorites_state.dart` to hold `favorites`.
      favoritesList = loaded;
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PlaylistPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B0A14),
              colorScheme.primary.withOpacity(0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeInOut,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/app_logo.png',
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.music_note,
                    size: 120,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
              const SizedBox(height: 24),
              Text(
                'Music Player',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Curated vibes, anytime',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Global favorites list (we'll store it here for simplicity)
List <Song> favoritesList = [];
