// ─────────────────────────────────────────────────────────────────────────────
// favorites_page.dart
//
// FIXES:
//   1. Replaced raw `favoritesList` global with FavoritesNotifier.instance.
//      The page now rebuilds automatically when any other page adds/removes
//      a favorite — no manual setState() needed.
//   2. Long-press → confirmation dialog → remove: now calls
//      FavoritesNotifier.instance.remove() which persists to DB and notifies
//      all listeners. Previously _confirmRemoveFavorite called the DB but
//      also mutated a different in-memory list than the one the widget read from.
//   3. Landscape mode split-view is preserved.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../data/favorites_notifier.dart';
import '../models/song.dart';
import '../widgets/song_details_view.dart';
import 'song_details_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Song? _selected;

  // ── Long-press removal with confirmation ───────────────────────────────────
  Future<void> _confirmRemove(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove favorite?'),
        content: Text('Remove "${song.title}" from favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // FIX: remove() updates DB and notifies all listeners atomically.
      await FavoritesNotifier.instance.remove(song);
      if (_selected == song) {
        setState(() => _selected = null);
      }
    }
  }

  // ── List builder ──────────────────────────────────────────────────────────
  Widget _buildList({required bool isLandscape}) {
    // FIX: ListenableBuilder so the list auto-updates when notifier fires.
    return ListenableBuilder(
      listenable: FavoritesNotifier.instance,
      builder: (context, child) {
        final favorites = FavoritesNotifier.instance.favorites;
        if (favorites.isEmpty) {
          return const Center(
            child: Text(
              'No favorites yet',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        return ListView.builder(
          itemCount: favorites.length,
          itemBuilder: (_, index) {
            final song = favorites[index];
            return ListTile(
              selected: isLandscape && _selected == song,
              selectedTileColor: Colors.white12,
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
              subtitle: Text(
                song.artist,
                style: const TextStyle(color: Colors.grey),
              ),
              onLongPress: () => _confirmRemove(song),
              onTap: () {
                if (!isLandscape) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SongDetailsPage(song: song),
                    ),
                  );
                } else {
                  setState(() => _selected = song);
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: isLandscape
          ? Row(
              children: [
                SizedBox(width: 360, child: _buildList(isLandscape: true)),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.white24,
                ),
                Expanded(
                  child: _selected == null
                      ? const Center(
                          child: Text(
                            'Select a song to see details',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : SongDetailsView(song: _selected!),
                ),
              ],
            )
          : _buildList(isLandscape: false),
    );
  }
}
