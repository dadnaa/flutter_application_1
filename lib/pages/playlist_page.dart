import 'dart:math';
import 'package:flutter/material.dart';
import '../data/playlist_data.dart';
import '../data/favorites_state.dart';
import '../db/favorites_db.dart';
import '../models/song.dart';
import '../widgets/forground_player_title.dart';
import 'player_page.dart';
import 'favorites_page.dart';
import 'local_songs_page.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late List<Song> randomList;

  @override
  void initState() {
    super.initState();
    final shuffled = [...playlist]..shuffle(Random());
    randomList = shuffled.take(min(2, shuffled.length)).toList();
  }

  Future<void> _toggleFavorite(Song song) async {
    final isFav = favoritesList.any((s) => s.url == song.url);
    if (isFav) {
      await FavoritesDb.removeFavorite(song.url);
      favoritesList.removeWhere((s) => s.url == song.url);
    } else {
      await FavoritesDb.insertFavorite(song);
      favoritesList.add(song);
    }
    if (mounted) setState(() {});
  }

  Widget _sectionHeader(BuildContext context,
      {required String title, String? subtitle}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white60,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildSongTile(Song song, {required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isFavorite = favoritesList.any((s) => s.url == song.url);
    return Card(
      child: ListTile(
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
        trailing: IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? theme.colorScheme.secondary : Colors.white70,
          ),
          tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
          onPressed: () => _toggleFavorite(song),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRandomPick(Song song) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 170,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final index = playlist.indexOf(song);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlayerPage(initialIndex: index)),
          );
        },
        child: Card(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  song.cover,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Playlist"),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_music),
            tooltip: 'Local music',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocalSongsPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            color: Theme.of(context).colorScheme.secondary,
            tooltip: 'Favorites',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesPage()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _sectionHeader(
            context,
            title: "Foreground Service",
            subtitle: "Control your local playback without opening the player",
          ),
          const ForegroundPlayerTile(),
          _sectionHeader(
            context,
            title: "Random Picks",
            subtitle: "A quick mix selected for you",
          ),
          SizedBox(
            height: 210,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) =>
                  _buildRandomPick(randomList[index]),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: randomList.length,
            ),
          ),
          _sectionHeader(
            context,
            title: "All Songs",
            subtitle: "${playlist.length} tracks ready to play",
          ),
          ...playlist.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            return _buildSongTile(
              song,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlayerPage(initialIndex: index)),
              ),
            );
          }),
        ],
      ),
    );
  }
}
