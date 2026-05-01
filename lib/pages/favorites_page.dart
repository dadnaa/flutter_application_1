import 'package:flutter/material.dart';
import '../data/favorites_state.dart';
import '../db/favorites_db.dart';
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

  Future<void> _confirmRemoveFavorite(Song song) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove favorite?"),
        content: Text('Remove "${song.title}" from favorites?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Remove")),
        ],
      ),
    );

    if (shouldRemove == true) {
      await FavoritesDb.removeFavorite(song.url);
      setState(() {
        favoritesList.removeWhere((s) => s.url == song.url);
        if (_selected == song) _selected = null;
      });
    }
  }

  Widget _buildFavoritesList({required bool isLandscape}) {
    final theme = Theme.of(context);
    if (favoritesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border,
                size: 48, color: theme.colorScheme.secondary),
            const SizedBox(height: 12),
            Text(
              "No favorites yet",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              "Tap the heart on any song to save it here.",
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: favoritesList.length,
      itemBuilder: (context, index) {
        final song = favoritesList[index];
        final isSelected = _selected == song;
        return Card(
          child: ListTile(
            selected: isLandscape && isSelected,
            selectedTileColor: Colors.white12,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                song.cover,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(song.title),
            subtitle: Text(
              song.artist,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
            onLongPress: () => _confirmRemoveFavorite(song),
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
      ),
      body: isLandscape
          ? Row(children: [
              SizedBox(
                  width: 360,
                  child: _buildFavoritesList(isLandscape: true)),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: _selected == null
                    ? const Center(
                        child: Text("Select a song to see details",
                            style: TextStyle(color: Colors.white70)))
                    : SongDetailsView(song: _selected!),
              ),
            ])
          : _buildFavoritesList(isLandscape: false),
    );
  }
}
