// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'dart:async';
// import 'dart:math';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart' as p;
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // FOREGROUND TASK HANDLER
// // Runs in a separate isolate; receives play/pause commands via port.
// // ─────────────────────────────────────────────────────────────────────────────
// @pragma('vm:entry-point')
// void startCallback() {
//   FlutterForegroundTask.setTaskHandler(MusicTaskHandler());
// }

// class MusicTaskHandler extends TaskHandler {
//   final AudioPlayer _player = AudioPlayer();
//   bool _isPlaying = false;

//   @override
//   Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
//     await _player.setAsset('assets/song.mp3');
//     await _player.play();
//     _isPlaying = true;
//     _updateNotification();
//   }

//   @override
//   void onRepeatEvent(DateTime timestamp) {
//   }

//   @override
//   Future<void> onDestroy(DateTime timestamp) async {
//     await _player.stop();
//     await _player.dispose();
//   }

//   /// Called when the user taps a notification action button.
//   @override
//   void onNotificationButtonPressed(String id) {
//     if (id == 'play_pause') {
//       _isPlaying ? _pause() : _play();
//     }
//   }

//   /// Called when the main isolate sends data via [FlutterForegroundTask.sendDataToTask].
//   @override
//   void onReceiveData(Object data) {
//     if (data == 'play') _play();
//     if (data == 'pause') _pause();
//   }

//   void _play() async {
//     await _player.play();
//     _isPlaying = true;
//     _updateNotification();
//     // Tell the UI
//     FlutterForegroundTask.sendDataToMain('playing');
//   }

//   void _pause() async {
//     await _player.pause();
//     _isPlaying = false;
//     _updateNotification();
//     FlutterForegroundTask.sendDataToMain('paused');
//   }

//   void _updateNotification() {
//     FlutterForegroundTask.updateService(
//       notificationTitle: 'Music Player',
//       notificationText: _isPlaying ? 'Now playing: song.mp3' : 'Paused',
//       notificationButtons: [
//         NotificationButton(
//           id: 'play_pause',
//           text: _isPlaying ? 'Pause' : 'Play',
//         ),
//       ],
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // ROUTE OBSERVER (unchanged from original)
// // ─────────────────────────────────────────────────────────────────────────────
// final RouteObserver<ModalRoute<void>> routeObserver =
//     RouteObserver<ModalRoute<void>>();

// // ─────────────────────────────────────────────────────────────────────────────
// // DB LAYER (unchanged from original)
// // ─────────────────────────────────────────────────────────────────────────────
// class FavoritesDb {
//   static Database? _db;

//   static Future<Database> get database async {
//     if (_db != null) return _db!;
//     _db = await _initDb();
//     return _db!;
//   }

//   static Future<Database> _initDb() async {
//     final dbPath = await getDatabasesPath();
//     final path = p.join(dbPath, 'favorites.db');
//     return openDatabase(
//       path,
//       version: 1,
//       onCreate: (db, _) async {
//         await db.execute('''
//           CREATE TABLE favorites(
//             url TEXT PRIMARY KEY,
//             title TEXT,
//             artist TEXT,
//             cover TEXT,
//             description TEXT,
//             album TEXT,
//             year INTEGER,
//             genre TEXT
//           )
//         ''');
//       },
//     );
//   }

//   static Future<void> insertFavorite(Song song) async {
//     final db = await database;
//     await db.insert('favorites', song.toMap(),
//         conflictAlgorithm: ConflictAlgorithm.replace);
//   }

//   static Future<void> removeFavorite(String url) async {
//     final db = await database;
//     await db.delete('favorites', where: 'url = ?', whereArgs: [url]);
//   }

//   static Future<List<Song>> getFavorites() async {
//     final db = await database;
//     final rows = await db.query('favorites');
//     return rows.map((e) => Song.fromMap(e)).toList();
//   }

//   static Future<bool> isFavorite(String url) async {
//     final db = await database;
//     final rows =
//         await db.query('favorites', where: 'url = ?', whereArgs: [url]);
//     return rows.isNotEmpty;
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // MODELS & DATA (unchanged from original)
// // ─────────────────────────────────────────────────────────────────────────────
// class Song {
//   final String title;
//   final String artist;
//   final String url;
//   final String cover;
//   final String description;
//   final String album;
//   final int year;
//   final String genre;

//   Song({
//     required this.title,
//     required this.artist,
//     required this.url,
//     required this.cover,
//     required this.description,
//     required this.album,
//     required this.year,
//     required this.genre,
//   });

//   Map<String, dynamic> toMap() => {
//         'title': title,
//         'artist': artist,
//         'url': url,
//         'cover': cover,
//         'description': description,
//         'album': album,
//         'year': year,
//         'genre': genre,
//       };

//   static Song fromMap(Map<String, dynamic> map) => Song(
//         title: map['title'],
//         artist: map['artist'],
//         url: map['url'],
//         cover: map['cover'],
//         description: map['description'],
//         album: map['album'],
//         year: map['year'],
//         genre: map['genre'],
//       );
// }

// final List<Song> playlist = [
//   Song(
//     title: "Song 1",
//     artist: "Artist A",
//     url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
//     cover: "https://picsum.photos/400?1",
//     description:
//         "Song 1 is a high-energy track with a bright melody and strong rhythm.",
//     album: "Album Alpha",
//     year: 2020,
//     genre: "Pop",
//   ),
//   Song(
//     title: "Song 2",
//     artist: "Artist B",
//     url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
//     cover: "https://picsum.photos/400?2",
//     description:
//         "Song 2 is a chill, laid-back piece designed for focus and relaxation.",
//     album: "Album Beta",
//     year: 2021,
//     genre: "Lo-fi",
//   ),
//   Song(
//     title: "Song 3",
//     artist: "Artist C",
//     url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
//     cover: "https://picsum.photos/400?3",
//     description:
//         "Song 3 blends electronic textures with an uplifting chorus and deep bass.",
//     album: "Album Gamma",
//     year: 2022,
//     genre: "Electronic",
//   ),
// ];

// List<Song> favorites = [];
// Map<int, int> songPositions = {};
// Map<int, bool> songWasPlaying = {};

// // ─────────────────────────────────────────────────────────────────────────────
// // FOREGROUND SERVICE HELPER
// // A simple singleton to start/stop/control the foreground service.
// // ─────────────────────────────────────────────────────────────────────────────
// class MusicService {
//   static bool _serviceRunning = false;

//   /// One-time setup – call from main().
//   static void init() {
//     FlutterForegroundTask.init(
//       androidNotificationOptions: AndroidNotificationOptions(
//         channelId: 'music_channel',
//         channelName: 'Music Playback',
//         channelDescription: 'Foreground music player notification',
//         channelImportance: NotificationChannelImportance.LOW,
//         priority: NotificationPriority.LOW,
//       ),
//       iosNotificationOptions: const IOSNotificationOptions(
//         showNotification: true,
//         playSound: false,
//       ),
//       foregroundTaskOptions: ForegroundTaskOptions(
//         eventAction: ForegroundTaskEventAction.nothing(),
//         autoRunOnBoot: false,
//         allowWakeLock: true,
//       ),
//     );
//   }

//   static Future<void> start() async {
//     if (_serviceRunning) return;
//     await FlutterForegroundTask.requestIgnoreBatteryOptimization();

//     final result = await FlutterForegroundTask.startService(
//       serviceId: 256,
//       notificationTitle: 'Music Player',
//       notificationText: 'Starting…',
//       notificationButtons: [
//         NotificationButton(id: 'play_pause', text: 'Pause'),
//       ],
//       callback: startCallback,
//     );
//     _serviceRunning = true;
//   }

//   static Future<void> stop() async {
//     await FlutterForegroundTask.stopService();
//     _serviceRunning = false;
//   }

//   static void sendPlay() =>
//       FlutterForegroundTask.sendDataToTask('play');
//   static void sendPause() =>
//       FlutterForegroundTask.sendDataToTask('pause');

//   static bool get isRunning => _serviceRunning;
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // APP
// // ─────────────────────────────────────────────────────────────────────────────
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   MusicService.init(); // initialise foreground task config
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: const SplashScreen(),
//       navigatorObservers: [routeObserver],
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // SPLASH SCREEN (unchanged)
// // ─────────────────────────────────────────────────────────────────────────────
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
//     _controller =
//         AnimationController(vsync: this, duration: const Duration(seconds: 2));
//     _controller.forward();

//     Timer(const Duration(seconds: 2), () async {
//       favorites = await FavoritesDb.getFavorites();
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const PlaylistPage()),
//         );
//       }
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

// // ─────────────────────────────────────────────────────────────────────────────
// // PLAYLIST PAGE  — adds a "Local Track (Foreground Service)" section at top
// // ─────────────────────────────────────────────────────────────────────────────
// class PlaylistPage extends StatefulWidget {
//   const PlaylistPage({super.key});

//   @override
//   State<PlaylistPage> createState() => _PlaylistPageState();
// }

// class _PlaylistPageState extends State<PlaylistPage> {
//   late List<Song> randomList;

//   @override
//   void initState() {
//     super.initState();
//     final shuffled = [...playlist]..shuffle(Random());
//     randomList = shuffled.take(min(2, shuffled.length)).toList();
//   }

//   Future<void> _toggleFavorite(Song song) async {
//     final isFav = favorites.any((s) => s.url == song.url);
//     if (isFav) {
//       await FavoritesDb.removeFavorite(song.url);
//       favorites.removeWhere((s) => s.url == song.url);
//     } else {
//       await FavoritesDb.insertFavorite(song);
//       favorites.add(song);
//     }
//     if (mounted) setState(() {});
//   }

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
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const FavoritesPage()),
//             ),
//           ),
//         ],
//       ),
//       body: ListView(
//         children: [
//           // ── NEW: Foreground Service player tile ───────────────────────────
//           const Padding(
//             padding: EdgeInsets.all(12.0),
//             child: Text("Local Track (Foreground Service)",
//                 style: TextStyle(color: Colors.white, fontSize: 18)),
//           ),
//           const ForegroundPlayerTile(),
//           const Divider(color: Colors.white24),
//           // ─────────────────────────────────────────────────────────────────

//           const Padding(
//             padding: EdgeInsets.all(12.0),
//             child: Text("Random Picks",
//                 style: TextStyle(color: Colors.white, fontSize: 18)),
//           ),
//           ...randomList.map((song) {
//             final isFavorite = favorites.any((s) => s.url == song.url);
//             return ListTile(
//               leading: Image.network(song.cover, width: 50, height: 50),
//               title:
//                   Text(song.title, style: const TextStyle(color: Colors.white)),
//               subtitle: Text(song.artist,
//                   style: const TextStyle(color: Colors.grey)),
//               trailing: IconButton(
//                 icon: Icon(
//                     isFavorite ? Icons.favorite : Icons.favorite_border,
//                     color: Colors.red),
//                 onPressed: () => _toggleFavorite(song),
//               ),
//               onTap: () {
//                 final index = playlist.indexOf(song);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (_) => PlayerPage(initialIndex: index)),
//                 );
//               },
//             );
//           }),
//           const Divider(color: Colors.white24),
//           const Padding(
//             padding: EdgeInsets.all(12.0),
//             child: Text("All Songs",
//                 style: TextStyle(color: Colors.white, fontSize: 18)),
//           ),
//           ...playlist.asMap().entries.map((entry) {
//             final index = entry.key;
//             final song = entry.value;
//             final isFavorite = favorites.any((s) => s.url == song.url);
//             return ListTile(
//               leading: Image.network(song.cover, width: 50, height: 50),
//               title:
//                   Text(song.title, style: const TextStyle(color: Colors.white)),
//               subtitle: Text(song.artist,
//                   style: const TextStyle(color: Colors.grey)),
//               trailing: IconButton(
//                 icon: Icon(
//                     isFavorite ? Icons.favorite : Icons.favorite_border,
//                     color: Colors.red),
//                 onPressed: () => _toggleFavorite(song),
//               ),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (_) => PlayerPage(initialIndex: index)),
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // FOREGROUND PLAYER TILE
// // A self-contained widget that starts/stops the foreground service and
// // shows a play/pause button. Listens to data sent back from the task isolate.
// // ─────────────────────────────────────────────────────────────────────────────
// class ForegroundPlayerTile extends StatefulWidget {
//   const ForegroundPlayerTile({super.key});

//   @override
//   State<ForegroundPlayerTile> createState() => _ForegroundPlayerTileState();
// }

// class _ForegroundPlayerTileState extends State<ForegroundPlayerTile> {
//   bool _serviceStarted = false;
//   bool _isPlaying = false;

//   @override
//   void initState() {
//     super.initState();
//     // Listen to messages sent from the task isolate (play/paused status)
//     FlutterForegroundTask.addTaskDataCallback(_onTaskData);
//   }

//   @override
//   void dispose() {
//     FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
//     super.dispose();
//   }

//   void _onTaskData(Object data) {
//     if (!mounted) return;
//     if (data == 'playing') setState(() => _isPlaying = true);
//     if (data == 'paused') setState(() => _isPlaying = false);
//   }

//   Future<void> _onPlayPause() async {
//     if (!_serviceStarted) {
//       // First tap → request notification permission then start service
//       final perm = await FlutterForegroundTask.checkNotificationPermission();
//       if (perm != NotificationPermission.granted) {
//         await FlutterForegroundTask.requestNotificationPermission();
//       }
//       await MusicService.start();
//       setState(() {
//         _serviceStarted = true;
//         _isPlaying = true;
//       });
//     } else {
//       // Service already running → toggle via task message
//       if (_isPlaying) {
//         MusicService.sendPause();
//         setState(() => _isPlaying = false);
//       } else {
//         MusicService.sendPlay();
//         setState(() => _isPlaying = true);
//       }
//     }
//   }

//   Future<void> _onStop() async {
//     await MusicService.stop();
//     setState(() {
//       _serviceStarted = false;
//       _isPlaying = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.white10,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white24),
//       ),
//       child: ListTile(
//         leading: const Icon(Icons.music_note, color: Colors.white, size: 36),
//         title: const Text('song.mp3',
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         subtitle: Text(
//           _serviceStarted
//               ? (_isPlaying ? 'Playing via foreground service' : 'Paused')
//               : 'Tap ▶ to start foreground service',
//           style: const TextStyle(color: Colors.grey),
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Play / Pause
//             IconButton(
//               icon: Icon(
//                 _isPlaying ? Icons.pause_circle : Icons.play_circle,
//                 color: Colors.white,
//                 size: 36,
//               ),
//               onPressed: _onPlayPause,
//             ),
//             // Stop (only shown when running)
//             if (_serviceStarted)
//               IconButton(
//                 icon: const Icon(Icons.stop_circle,
//                     color: Colors.redAccent, size: 36),
//                 onPressed: _onStop,
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Everything below is UNCHANGED from the original
// // ─────────────────────────────────────────────────────────────────────────────

// class SongDetailsView extends StatelessWidget {
//   final Song song;
//   const SongDetailsView({super.key, required this.song});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.black,
//       padding: const EdgeInsets.all(16),
//       child: ListView(
//         children: [
//           Center(
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.network(song.cover, height: 220, width: 220),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(song.title,
//               style: const TextStyle(color: Colors.white, fontSize: 22)),
//           const SizedBox(height: 6),
//           Text(song.artist,
//               style: const TextStyle(color: Colors.grey, fontSize: 16)),
//           const SizedBox(height: 16),
//           const Text("Description",
//               style: TextStyle(color: Colors.white, fontSize: 18)),
//           const SizedBox(height: 8),
//           Text(song.description,
//               style: const TextStyle(color: Colors.white70, height: 1.4)),
//           const SizedBox(height: 18),
//           const Text("More info",
//               style: TextStyle(color: Colors.white, fontSize: 18)),
//           const SizedBox(height: 8),
//           _InfoRow(label: "Album", value: song.album),
//           _InfoRow(label: "Year", value: song.year.toString()),
//           _InfoRow(label: "Genre", value: song.genre),
//           const SizedBox(height: 18),
//           const Text("Preview URL",
//               style: TextStyle(color: Colors.white, fontSize: 18)),
//           const SizedBox(height: 8),
//           SelectableText(song.url,
//               style: const TextStyle(color: Colors.white70)),
//         ],
//       ),
//     );
//   }
// }

// class _InfoRow extends StatelessWidget {
//   final String label;
//   final String value;
//   const _InfoRow({required this.label, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Row(
//         children: [
//           SizedBox(
//               width: 70,
//               child: Text(label, style: const TextStyle(color: Colors.grey))),
//           Expanded(
//               child:
//                   Text(value, style: const TextStyle(color: Colors.white))),
//         ],
//       ),
//     );
//   }
// }

// class SongDetailsPage extends StatelessWidget {
//   final Song song;
//   const SongDetailsPage({super.key, required this.song});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title:
//             const Text("Song Details", style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.black,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: SongDetailsView(song: song),
//     );
//   }
// }

// class FavoritesPage extends StatefulWidget {
//   const FavoritesPage({super.key});

//   @override
//   State<FavoritesPage> createState() => _FavoritesPageState();
// }

// class _FavoritesPageState extends State<FavoritesPage> {
//   Song? _selected;

//   Future<void> _confirmRemoveFavorite(Song song) async {
//     final shouldRemove = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Remove favorite?"),
//         content: Text('Remove "${song.title}" from favorites?'),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text("Cancel")),
//           TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text("Remove")),
//         ],
//       ),
//     );

//     if (shouldRemove == true) {
//       await FavoritesDb.removeFavorite(song.url);
//       setState(() {
//         favorites.removeWhere((s) => s.url == song.url);
//         if (_selected == song) _selected = null;
//       });
//     }
//   }

//   Widget _buildFavoritesList({required bool isLandscape}) {
//     if (favorites.isEmpty) {
//       return const Center(
//           child:
//               Text("No favorites yet", style: TextStyle(color: Colors.white)));
//     }
//     return ListView.builder(
//       itemCount: favorites.length,
//       itemBuilder: (context, index) {
//         final song = favorites[index];
//         final isSelected = _selected == song;
//         return ListTile(
//           selected: isLandscape && isSelected,
//           selectedTileColor: Colors.white12,
//           leading: Image.network(song.cover, width: 50, height: 50),
//           title:
//               Text(song.title, style: const TextStyle(color: Colors.white)),
//           subtitle:
//               Text(song.artist, style: const TextStyle(color: Colors.grey)),
//           onLongPress: () => _confirmRemoveFavorite(song),
//           onTap: () {
//             if (!isLandscape) {
//               Navigator.push(context,
//                   MaterialPageRoute(builder: (_) => SongDetailsPage(song: song)));
//             } else {
//               setState(() => _selected = song);
//             }
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isLandscape =
//         MediaQuery.of(context).orientation == Orientation.landscape;
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title:
//             const Text("Favorites", style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.black,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLandscape
//           ? Row(children: [
//               SizedBox(
//                   width: 360,
//                   child: _buildFavoritesList(isLandscape: true)),
//               const VerticalDivider(width: 1, thickness: 1),
//               Expanded(
//                 child: _selected == null
//                     ? const Center(
//                         child: Text("Select a song to see details",
//                             style: TextStyle(color: Colors.white70)))
//                     : SongDetailsView(song: _selected!),
//               ),
//             ])
//           : _buildFavoritesList(isLandscape: false),
//     );
//   }
// }

// class PlayerPage extends StatefulWidget {
//   final int initialIndex;
//   const PlayerPage({super.key, required this.initialIndex});

//   @override
//   State<PlayerPage> createState() => _PlayerPageState();
// }

// class _PlayerPageState extends State<PlayerPage>
//     with WidgetsBindingObserver, RouteAware {
//   final AudioPlayer _player = AudioPlayer();
//   late int currentIndex;
//   bool isPlaying = false;

//   Song get currentSong => playlist[currentIndex];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     currentIndex = widget.initialIndex;
//     loadSong();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final route = ModalRoute.of(context);
//     if (route is PageRoute) routeObserver.subscribe(this, route);
//   }

//   Future<void> stopBecauseNotVisible() async {
//     savePosition();
//     if (_player.playing) await _player.pause();
//     if (mounted) setState(() => isPlaying = false);
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.inactive ||
//         state == AppLifecycleState.paused ||
//         state == AppLifecycleState.detached) {
//       stopBecauseNotVisible();
//     }
//   }

//   @override
//   void didPushNext() => stopBecauseNotVisible();

//   Future<void> loadSong() async {
//     await _player.setUrl(currentSong.url);
//     if (songPositions.containsKey(currentIndex)) {
//       await _player.seek(Duration(seconds: songPositions[currentIndex]!));
//     }
//     if (songWasPlaying.containsKey(currentIndex)) {
//       final wasPlaying = songWasPlaying[currentIndex]!;
//       isPlaying = wasPlaying;
//       setState(() {});
//       if (wasPlaying) await _player.play();
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
//     setState(() => isPlaying = !isPlaying);
//   }

//   String formatDuration(Duration d) {
//     final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   void nextSong() async {
//     savePosition();
//     currentIndex = (currentIndex + 1) % playlist.length;
//     await loadSong();
//     if (isPlaying) _player.play();
//   }

//   void prevSong() async {
//     savePosition();
//     currentIndex = (currentIndex - 1 + playlist.length) % playlist.length;
//     await loadSong();
//     if (isPlaying) _player.play();
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
//             Text(currentSong.title,
//                 style: const TextStyle(color: Colors.white, fontSize: 22)),
//             const SizedBox(height: 10),
//             Text(currentSong.artist,
//                 style: const TextStyle(color: Colors.grey, fontSize: 16)),
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
//                               onChanged: (value) => _player
//                                   .seek(Duration(milliseconds: value.round())),
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
//                     icon: const Icon(Icons.skip_previous, color: Colors.white),
//                     iconSize: 40,
//                     onPressed: prevSong),
//                 const SizedBox(width: 20),
//                 IconButton(
//                     icon: Icon(
//                         isPlaying ? Icons.pause : Icons.play_arrow,
//                         color: Colors.white),
//                     iconSize: 60,
//                     onPressed: playPause),
//                 const SizedBox(width: 20),
//                 IconButton(
//                     icon: const Icon(Icons.skip_next, color: Colors.white),
//                     iconSize: 40,
//                     onPressed: nextSong),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/music_service.dart';
import 'pages/splash_screen.dart';
import 'utils/route_observer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MusicService.init();         // Foreground task config
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      navigatorObservers: [routeObserver],
    );
  }
}