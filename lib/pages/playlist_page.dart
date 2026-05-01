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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Playlist", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.music_note, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocalSongsPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesPage()),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("Foreground Service (Local Playback)",
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          const ForegroundPlayerTile(),
          const Divider(color: Colors.white24),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("Random Picks",
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          ...randomList.map((song) {
            final isFavorite = favoritesList.any((s) => s.url == song.url);
            return ListTile(
              leading: Image.network(song.cover, width: 50, height: 50),
              title: Text(song.title, style: const TextStyle(color: Colors.white)),
              subtitle: Text(song.artist, style: const TextStyle(color: Colors.grey)),
              trailing: IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                onPressed: () => _toggleFavorite(song),
              ),
              onTap: () {
                final index = playlist.indexOf(song);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlayerPage(initialIndex: index)),
                );
              },
            );
          }),
          const Divider(color: Colors.white24),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("All Songs",
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          ...playlist.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            final isFavorite = favoritesList.any((s) => s.url == song.url);
            return ListTile(
              leading: Image.network(song.cover, width: 50, height: 50),
              title: Text(song.title, style: const TextStyle(color: Colors.white)),
              subtitle: Text(song.artist, style: const TextStyle(color: Colors.grey)),
              trailing: IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                onPressed: () => _toggleFavorite(song),
              ),
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