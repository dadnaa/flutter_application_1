import 'package:flutter/material.dart';
import 'playlist_page.dart';
import 'local_songs_page.dart';
import 'favorites_page.dart';
import '../widgets/miniplayer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = const [
    PlaylistPage(),
    LocalSongsPage(),
    FavoritesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _pages[_selectedIndex]),
          const MiniPlayer(), // persistent mini‑player
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: 'Online',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.audiotrack), label: 'Local'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}
