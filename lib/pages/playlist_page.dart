// ─────────────────────────────────────────────────────────────────────────────
// playlist_page.dart
//
// FIXES:
//   1. CRITICAL: Replaced `favoritesList` global with FavoritesNotifier.
//      Previously the playlist page and favorites page read from different
//      global variables → favorites appeared inconsistent between pages.
//   2. ListenableBuilder wraps the ListView so ONLY the list rebuilds when
//      favorites change, not the entire scaffold.
//   3. Removed unused import of LocalSongsPage (LocalSongs has its own tab).
//   4. Removed duplicate FavoritesPage action button (it's a nav tab now).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';
import '../data/playlist_data.dart';
import '../data/favorites_notifier.dart';
import '../models/song.dart';
import '../services/audio_player_controller.dart';
import '../services/music_service.dart';
import 'player_page.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late final List<Song> _randomPicks;

  @override
  void initState() {
    super.initState();
    final shuffled = [...playlist]..shuffle(Random());
    _randomPicks = shuffled.take(min(2, shuffled.length)).toList();
  }

  Future<void> _openPlayer(int index) async {
    if (MusicService.isRunning) {
      await MusicService.stop();
    }
    // Load song into the shared AudioPlayerController before navigating.
    await AudioPlayerController.instance.loadSong(index, autoPlay: true);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerPage(initialIndex: index)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlist')),
      // FIX: ListenableBuilder so the list rebuilds on favorite changes
      // without a full page setState.
      body: ListenableBuilder(
        listenable: FavoritesNotifier.instance,
        builder: (context, child) {
          final fav = FavoritesNotifier.instance;
          return ListView(
            children: [
              const _SectionHeader('Random Picks'),
              ..._randomPicks.map(
                (song) => _SongTile(
                  song: song,
                  isFavorite: fav.isFavorite(song.url),
                  onToggleFavorite: () => fav.toggle(song),
                  onTap: () => _openPlayer(playlist.indexOf(song)),
                ),
              ),
              const Divider(color: Colors.white24),
              const _SectionHeader('All Songs'),
              ...playlist.asMap().entries.map(
                (e) => _SongTile(
                  song: e.value,
                  isFavorite: fav.isFavorite(e.value.url),
                  onToggleFavorite: () => fav.toggle(e.value),
                  onTap: () => _openPlayer(e.key),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Reusable section header ────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
  );
}

// ── Reusable song tile ─────────────────────────────────────────────────────
class _SongTile extends StatelessWidget {
  final Song song;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const _SongTile({
    required this.song,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: song.cover.isNotEmpty
          ? Image.network(
              song.cover,
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.music_note, color: Colors.white54),
            )
          : const Icon(Icons.music_note, color: Colors.white54),
      title: Text(song.title),
      subtitle: Text(song.artist, style: const TextStyle(color: Colors.grey)),
      trailing: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: Colors.red,
        ),
        onPressed: onToggleFavorite,
      ),
      onTap: onTap,
    );
  }
}
