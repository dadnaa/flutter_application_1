
// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'dart:async';

// // 1) Add this RouteObserver (global)
// final RouteObserver<ModalRoute<void>> routeObserver =
//     RouteObserver<ModalRoute<void>>();

// void main() {
//   runApp(const MyApp());
// }

// class Song {
//   final String title;
//   final String artist;
//   final String url;
//   final String cover;

//   Song({
//     required this.title,
//     required this.artist,
//     required this.url,
//     required this.cover,
//   });
// }

// final List<Song> playlist = [
//   Song(
//     title: "Song 1",
//     artist: "Artist A",
//     url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
//     cover: "https://picsum.photos/400?1",
//   ),
//   Song(
//     title: "Song 2",
//     artist: "Artist B",
//     url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
//     cover: "https://picsum.photos/400?2",
//   ),
//   Song(
//     title: "Song 3",
//     artist: "Artist C",
//     url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
//     cover: "https://picsum.photos/400?3",
//   ),
// ];

// List<Song> favorites = [];

// Map<int, int> songPositions = {};
// Map<int, bool> songWasPlaying = {};

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // 2) Remove "const" here because we add navigatorObservers
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: const SplashScreen(),
//       navigatorObservers: [routeObserver], // <-- add this
//     );
//   }
// }

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     );

//     _controller.forward();

//     Timer(const Duration(seconds: 2), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const PlaylistPage()),
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: RotationTransition(
//           turns: _controller,
//           child: Image.network(
//             "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTk9HyeEo51sGaClQfeHOraOhUS9sJ1ULVDMg&s",
//             width: 150,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class PlaylistPage extends StatefulWidget {
//   const PlaylistPage({super.key});

//   @override
//   State<PlaylistPage> createState() => _PlaylistPageState();
// }

// class _PlaylistPageState extends State<PlaylistPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text("Playlist", style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.black,
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.favorite, color: Colors.red),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const FavoritesPage()),
//               );
//             },
//           )
//         ],
//       ),
//       body: ListView.builder(
//         itemCount: playlist.length,
//         itemBuilder: (context, index) {
//           final song = playlist[index];
//           final isFavorite = favorites.contains(song);

//           return ListTile(
//             leading: Image.network(song.cover, width: 50, height: 50),
//             title: Text(song.title, style: const TextStyle(color: Colors.white)),
//             subtitle:
//                 Text(song.artist, style: const TextStyle(color: Colors.grey)),
//             trailing: IconButton(
//               icon: Icon(
//                 isFavorite ? Icons.favorite : Icons.favorite_border,
//                 color: Colors.red,
//               ),
//               onPressed: () {
//                 setState(() {
//                   if (isFavorite) {
//                     favorites.remove(song);
//                   } else {
//                     favorites.add(song);
//                   }
//                 });
//               },
//             ),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => PlayerPage(initialIndex: index),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class FavoritesPage extends StatelessWidget {
//   const FavoritesPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text("Favorites", style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.black,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: favorites.isEmpty
//           ? const Center(
//               child: Text("No favorites yet",
//                   style: TextStyle(color: Colors.white)),
//             )
//           : ListView.builder(
//               itemCount: favorites.length,
//               itemBuilder: (context, index) {
//                 final song = favorites[index];
//                 return ListTile(
//                   leading: Image.network(song.cover, width: 50, height: 50),
//                   title: Text(song.title,
//                       style: const TextStyle(color: Colors.white)),
//                   subtitle: Text(song.artist,
//                       style: const TextStyle(color: Colors.grey)),
//                 );
//               },
//             ),
//     );
//   }
// }

// class PlayerPage extends StatefulWidget {
//   final int initialIndex;
//   const PlayerPage({super.key, required this.initialIndex});

//   @override
//   State<PlayerPage> createState() => _PlayerPageState();
// }

// // 3) Use BOTH WidgetsBindingObserver + RouteAware
// class _PlayerPageState extends State<PlayerPage>
//     with WidgetsBindingObserver, RouteAware {
//   final AudioPlayer _player = AudioPlayer();

//   late int currentIndex;
//   bool isPlaying = false;

//   Song get currentSong => playlist[currentIndex];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this); // <-- lifecycle observer
//     currentIndex = widget.initialIndex;
//     loadSong();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final route = ModalRoute.of(context);
//     if (route is PageRoute) {
//       routeObserver.subscribe(this, route); // <-- route observer
//     }
//   }

//   Future<void> stopBecauseNotVisible() async {
//     // save current position + pause + update UI
//     savePosition();

//     if (_player.playing) {
//       await _player.pause();
//     }

//     if (mounted) {
//       setState(() => isPlaying = false);
//     }
//   }

//   // When user minimizes chrome / leaves the app / app is hidden
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.inactive ||
//         state == AppLifecycleState.paused ||
//         state == AppLifecycleState.hidden ||
//         state == AppLifecycleState.detached) {
//       stopBecauseNotVisible();
//     }
//   }

//   // When another page is pushed on top of PlayerPage
//   @override
//   void didPushNext() {
//     stopBecauseNotVisible();
//   }

//   Future<void> loadSong() async {
//     await _player.setUrl(currentSong.url);

//     if (songPositions.containsKey(currentIndex)) {
//       final seconds = songPositions[currentIndex]!;
//       await _player.seek(Duration(seconds: seconds));
//     }

//     if (songWasPlaying.containsKey(currentIndex)) {
//       final wasPlaying = songWasPlaying[currentIndex]!;
//       if (wasPlaying) {
//         isPlaying = true;
//         setState(() {});
//         await _player.play();
//       } else {
//         isPlaying = false;
//         setState(() {});
//         await _player.pause();
//       }
//     } else {
//       setState(() {});
//     }
//   }

//   void savePosition() {
//     songPositions[currentIndex] = _player.position.inSeconds;
//     songWasPlaying[currentIndex] = isPlaying;
//   }

//   @override
//   void dispose() {
//     // unsubscribe both observers
//     routeObserver.unsubscribe(this);
//     WidgetsBinding.instance.removeObserver(this);

//     savePosition();
//     _player.dispose();
//     super.dispose();
//   }

//   void playPause() {
//     if (isPlaying) {
//       _player.pause();
//     } else {
//       _player.play();
//     }
//     setState(() {
//       isPlaying = !isPlaying;
//     });
//   }

//   String formatDuration(Duration d) {
//     final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return '$minutes:$seconds';
//   }

//   void nextSong() async {
//     savePosition();

//     currentIndex = (currentIndex + 1) % playlist.length;

//     await loadSong();

//     if (isPlaying) {
//       _player.play();
//     }
//   }

//   void prevSong() async {
//     savePosition();

//     currentIndex = (currentIndex - 1 + playlist.length) % playlist.length;

//     await loadSong();

//     if (isPlaying) {
//       _player.play();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Image.network(currentSong.cover, height: 250, width: 250),
//             const SizedBox(height: 30),
//             Text(
//               currentSong.title,
//               style: const TextStyle(color: Colors.white, fontSize: 22),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               currentSong.artist,
//               style: const TextStyle(color: Colors.grey, fontSize: 16),
//             ),
//             const SizedBox(height: 40),
//             StreamBuilder<Duration?>(
//               stream: _player.durationStream,
//               builder: (context, durSnap) {
//                 final duration = durSnap.data ?? Duration.zero;
//                 return StreamBuilder<Duration>(
//                   stream: _player.positionStream,
//                   builder: (context, posSnap) {
//                     final position = posSnap.data ?? Duration.zero;
//                     final maxMillis = duration.inMilliseconds.toDouble();
//                     final posMillis = position.inMilliseconds
//                         .toDouble()
//                         .clamp(0.0, maxMillis > 0 ? maxMillis : 0.0);

//                     return Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                       child: Row(
//                         children: [
//                           Text(formatDuration(position),
//                               style: const TextStyle(color: Colors.white)),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Slider(
//                               activeColor: Colors.white,
//                               inactiveColor: Colors.grey,
//                               min: 0.0,
//                               max: maxMillis > 0 ? maxMillis : 1.0,
//                               value: maxMillis > 0 ? posMillis : 0.0,
//                               onChanged: (value) {
//                                 _player.seek(Duration(
//                                     milliseconds: value.round()));
//                               },
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Text(formatDuration(duration),
//                               style: const TextStyle(color: Colors.white)),
//                         ],
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.skip_previous, color: Colors.white),
//                   iconSize: 40,
//                   onPressed: prevSong,
//                 ),
//                 const SizedBox(width: 20),
//                 IconButton(
//                   icon: Icon(
//                     isPlaying ? Icons.pause : Icons.play_arrow,
//                     color: Colors.white,
//                   ),
//                   iconSize: 60,
//                   onPressed: playPause,
//                 ),
//                 const SizedBox(width: 20),
//                 IconButton(
//                   icon: const Icon(Icons.skip_next, color: Colors.white),
//                   iconSize: 40,
//                   onPressed: nextSong,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

// 1) Add this RouteObserver (global)
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() {
  runApp(const MyApp());
}

class Song {
  final String title;
  final String artist;
  final String url;
  final String cover;

  // Added fields for description + more info
  final String description;
  final String album;
  final int year;
  final String genre;

  Song({
    required this.title,
    required this.artist,
    required this.url,
    required this.cover,
    required this.description,
    required this.album,
    required this.year,
    required this.genre,
  });
}

final List<Song> playlist = [
  Song(
    title: "Song 1",
    artist: "Artist A",
    url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
    cover: "https://picsum.photos/400?1",
    description:
        "Song 1 is a high-energy track with a bright melody and strong rhythm.",
    album: "Album Alpha",
    year: 2020,
    genre: "Pop",
  ),
  Song(
    title: "Song 2",
    artist: "Artist B",
    url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
    cover: "https://picsum.photos/400?2",
    description:
        "Song 2 is a chill, laid-back piece designed for focus and relaxation.",
    album: "Album Beta",
    year: 2021,
    genre: "Lo-fi",
  ),
  Song(
    title: "Song 3",
    artist: "Artist C",
    url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
    cover: "https://picsum.photos/400?3",
    description:
        "Song 3 blends electronic textures with an uplifting chorus and deep bass.",
    album: "Album Gamma",
    year: 2022,
    genre: "Electronic",
  ),
];

List<Song> favorites = [];

Map<int, int> songPositions = {};
Map<int, bool> songWasPlaying = {};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2) Remove "const" here because we add navigatorObservers
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      navigatorObservers: [routeObserver], // <-- add this
    );
  }
}

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

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _controller.forward();

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PlaylistPage()),
      );
    });
  }

  @override
  void dispose() {
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
            "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTk9HyeEo51sGaClQfeHOraOhUS9sJ1ULVDMg&s",
            width: 150,
          ),
        ),
      ),
    );
  }
}

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
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
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesPage()),
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: playlist.length,
        itemBuilder: (context, index) {
          final song = playlist[index];
          final isFavorite = favorites.contains(song);

          return ListTile(
            leading: Image.network(song.cover, width: 50, height: 50),
            title: Text(song.title, style: const TextStyle(color: Colors.white)),
            subtitle:
                Text(song.artist, style: const TextStyle(color: Colors.grey)),
            trailing: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  if (isFavorite) {
                    favorites.remove(song);
                  } else {
                    favorites.add(song);
                  }
                });
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerPage(initialIndex: index),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


class SongDetailsView extends StatelessWidget {
  final Song song;
  const SongDetailsView({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(song.cover, height: 220, width: 220),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            song.title,
            style: const TextStyle(color: Colors.white, fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            song.artist,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            "Description",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            song.description,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 18),
          const Text(
            "More info",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          _InfoRow(label: "Album", value: song.album),
          _InfoRow(label: "Year", value: song.year.toString()),
          _InfoRow(label: "Genre", value: song.genre),
          const SizedBox(height: 18),
          const Text(
            "Preview URL",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          SelectableText(
            song.url,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class SongDetailsPage extends StatelessWidget {
  final Song song;
  const SongDetailsPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Song Details", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SongDetailsView(song: song),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Song? _selected; // used for landscape right pane

  Future<void> _confirmRemoveFavorite(Song song) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Remove favorite?"),
          content: Text('Remove "${song.title}" from favorites?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Remove"),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      setState(() {
        favorites.remove(song);
        if (_selected == song) _selected = null;
      });
    }
  }

  Widget _buildFavoritesList({required bool isLandscape}) {
    if (favorites.isEmpty) {
      return const Center(
        child: Text("No favorites yet", style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final song = favorites[index];
        final isSelected = _selected == song;

        return ListTile(
          selected: isLandscape && isSelected,
          selectedTileColor: Colors.white12,
          leading: Image.network(song.cover, width: 50, height: 50),
          title: Text(song.title, style: const TextStyle(color: Colors.white)),
          subtitle: Text(song.artist, style: const TextStyle(color: Colors.grey)),

          onLongPress: () => _confirmRemoveFavorite(song),

         
          onTap: () {
            if (!isLandscape) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SongDetailsPage(song: song)),
              );
            } else {
              setState(() => _selected = song);
            }
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Favorites", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Landscape: two panes (list + details)
      // Portrait: only list
      body: isLandscape
          ? Row(
              children: [
                SizedBox(
                  width: 360,
                  child: _buildFavoritesList(isLandscape: true),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: _selected == null
                      ? const Center(
                          child: Text(
                            "Select a song to see details",
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : SongDetailsView(song: _selected!),
                ),
              ],
            )
          : _buildFavoritesList(isLandscape: false),
    );
  }
}

class PlayerPage extends StatefulWidget {
  final int initialIndex;
  const PlayerPage({super.key, required this.initialIndex});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

//  WidgetsBindingObserver + RouteAware
class _PlayerPageState extends State<PlayerPage>
    with WidgetsBindingObserver, RouteAware {
  final AudioPlayer _player = AudioPlayer();

  late int currentIndex;
  bool isPlaying = false;

  Song get currentSong => playlist[currentIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // <-- lifecycle observer
    currentIndex = widget.initialIndex;
    loadSong();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route); // <-- route observer
    }
  }

  Future<void> stopBecauseNotVisible() async {
    // save current position + pause + update UI
    savePosition();

    if (_player.playing) {
      await _player.pause();
    }

    if (mounted) {
      setState(() => isPlaying = false);
    }
  }

  // When user minimizes chrome / leaves the app / app is hidden
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        
        state == AppLifecycleState.detached) {
      stopBecauseNotVisible();
    }
  }

  // When another page is pushed on top of PlayerPage
  @override
  void didPushNext() {
    stopBecauseNotVisible();
  }

  Future<void> loadSong() async {
    await _player.setUrl(currentSong.url);

    if (songPositions.containsKey(currentIndex)) {
      final seconds = songPositions[currentIndex]!;
      await _player.seek(Duration(seconds: seconds));
    }

    if (songWasPlaying.containsKey(currentIndex)) {
      final wasPlaying = songWasPlaying[currentIndex]!;
      if (wasPlaying) {
        isPlaying = true;
        setState(() {});
        await _player.play();
      } else {
        isPlaying = false;
        setState(() {});
        await _player.pause();
      }
    } else {
      setState(() {});
    }
  }

  void savePosition() {
    songPositions[currentIndex] = _player.position.inSeconds;
    songWasPlaying[currentIndex] = isPlaying;
  }

  @override
  void dispose() {
    // unsubscribe both observers
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);

    savePosition();
    _player.dispose();
    super.dispose();
  }

  void playPause() {
    if (isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void nextSong() async {
    savePosition();

    currentIndex = (currentIndex + 1) % playlist.length;

    await loadSong();

    if (isPlaying) {
      _player.play();
    }
  }

  void prevSong() async {
    savePosition();

    currentIndex = (currentIndex - 1 + playlist.length) % playlist.length;

    await loadSong();

    if (isPlaying) {
      _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(currentSong.cover, height: 250, width: 250),
            const SizedBox(height: 30),
            Text(
              currentSong.title,
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              currentSong.artist,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            StreamBuilder<Duration?>(
              stream: _player.durationStream,
              builder: (context, durSnap) {
                final duration = durSnap.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, posSnap) {
                    final position = posSnap.data ?? Duration.zero;
                    final maxMillis = duration.inMilliseconds.toDouble();
                    final posMillis = position.inMilliseconds
                        .toDouble()
                        .clamp(0.0, maxMillis > 0 ? maxMillis : 0.0);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Text(formatDuration(position),
                              style: const TextStyle(color: Colors.white)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Slider(
                              activeColor: Colors.white,
                              inactiveColor: Colors.grey,
                              min: 0.0,
                              max: maxMillis > 0 ? maxMillis : 1.0,
                              value: maxMillis > 0 ? posMillis : 0.0,
                              onChanged: (value) {
                                _player.seek(
                                    Duration(milliseconds: value.round()));
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(formatDuration(duration),
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                  iconSize: 40,
                  onPressed: prevSong,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  iconSize: 60,
                  onPressed: playPause,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  iconSize: 40,
                  onPressed: nextSong,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}