import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'db/favorites_db.dart';

late MyAudioHandler audioHandler;

/// ================= AUDIO HANDLER =================
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return; // ← prevent re-init on every PlayerPage open
    _loaded = true;

    mediaItem.add(const MediaItem(
      id: 'local_song',
      title: 'Local Song',
      artist: 'My App',
    ));

    await _player.setAsset('assets/audio/song.mp3');
    _player.playbackEventStream.map(_event).pipe(playbackState);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  bool get isPlaying => _player.playing;

  Stream<bool> get playingStream => _player.playingStream;

  @override
  Future<void> skipToNext() async {
    await _player.seek(Duration.zero);
    _player.play();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seek(Duration.zero);
    _player.play();
  }

  PlaybackState _event(PlaybackEvent e) => PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        playing: _player.playing,
        updatePosition: _player.position,
        processingState: AudioProcessingState.ready,
      );
}

/// ================= SONG MODEL =================
class Song {
  final String title;
  final String artist;
  final String url;
  final String cover;
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

  Map<String, dynamic> toMap() => {
        'title': title,
        'artist': artist,
        'url': url,
        'cover': cover,
        'description': description,
        'album': album,
        'year': year,
        'genre': genre,
      };

  factory Song.fromMap(Map<String, dynamic> map) => Song(
        title: map['title'],
        artist: map['artist'],
        url: map['url'],
        cover: map['cover'],
        description: map['description'],
        album: map['album'],
        year: map['year'],
        genre: map['genre'],
      );
}

/// ================= DATA =================
final List<Song> playlist = [
  Song(
    title: "Song 1",
    artist: "Artist A",
    url: "1",
    cover: "https://picsum.photos/400?1",
    description: "desc",
    album: "A",
    year: 2020,
    genre: "Pop",
  ),
  Song(
    title: "Song 2",
    artist: "Artist B",
    url: "2",
    cover: "https://picsum.photos/400?2",
    description: "desc",
    album: "B",
    year: 2021,
    genre: "Lo-fi",
  ),
];

List<Song> randomList = [];
List<Song> favorites = [];

/// ================= MAIN =================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'music',
      androidNotificationChannelName: 'Music',
      androidNotificationOngoing: true,
    ),
  );

  runApp(const MyApp());
}

/// ================= APP =================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

/// ================= SPLASH =================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _Splash();
}

class _Splash extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // Shuffle playlist
    randomList = List.from(playlist)..shuffle();

    // Pre-load favorites from DB
    favorites = await FavoritesDB.getAll();

    // Ensure minimum 2s splash time
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return; // ← safe guard

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PlaylistPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, color: Colors.white, size: 64),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// ================= PLAYLIST =================
class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _Playlist();
}

class _Playlist extends State<PlaylistPage> {
  @override
  void initState() {
    super.initState();
    loadFav();
  }

  Future<void> loadFav() async {
    favorites = await FavoritesDB.getAll();
    if (mounted) setState(() {});
  }

  bool isFav(Song s) => favorites.any((e) => e.url == s.url);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Random Playlist"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesPage()),
              );
              loadFav(); // ← refresh after returning from favorites
            },
          )
        ],
      ),
      body: randomList.isEmpty
          ? const Center(
              child: Text("No songs", style: TextStyle(color: Colors.white)),
            )
          : ListView.builder(
              itemCount: randomList.length,
              itemBuilder: (_, i) {
                final s = randomList[i];

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      s.cover,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.music_note,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  title: Text(s.title,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.artist,
                      style: const TextStyle(color: Colors.grey)),
                  trailing: IconButton(
                    icon: Icon(
                      isFav(s) ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      if (isFav(s)) {
                        await FavoritesDB.remove(s.url);
                      } else {
                        await FavoritesDB.add(s);
                      }
                      loadFav();
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerPage(song: s), // ← pass song
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

/// ================= FAVORITES =================
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _Fav();
}

class _Fav extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    favorites = await FavoritesDB.getAll();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Favorites"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: favorites.isEmpty
          ? const Center(
              child: Text("No favorites yet",
                  style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (_, i) {
                final s = favorites[i];

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      s.cover,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.music_note,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  title: Text(s.title,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(s.artist,
                      style: const TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.delete_outline,
                      color: Colors.grey, size: 20),
                  onLongPress: () async {
                    await FavoritesDB.remove(s.url);
                    load();
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerPage(song: s),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

/// ================= PLAYER =================
class PlayerPage extends StatefulWidget {
  final Song song;

  const PlayerPage({super.key, required this.song});

  @override
  State<PlayerPage> createState() => _Player();
}

class _Player extends State<PlayerPage> {
  @override
  void initState() {
    super.initState();
    audioHandler.load(); // safe — guarded by _loaded flag inside handler
  }

  void toggle() async {
    if (audioHandler.isPlaying) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.song.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cover art
          Padding(
            padding: const EdgeInsets.all(32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.song.cover,
                width: 280,
                height: 280,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 280,
                  height: 280,
                  color: Colors.grey[900],
                  child: const Icon(Icons.music_note,
                      color: Colors.white, size: 80),
                ),
              ),
            ),
          ),

          // Song info
          Text(widget.song.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(widget.song.artist,
              style: const TextStyle(color: Colors.grey, fontSize: 16)),

          const SizedBox(height: 40),

          // Controls — use StreamBuilder so button stays in sync with actual state
          StreamBuilder<bool>(
            stream: audioHandler.playingStream,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: () => audioHandler.skipToPrevious(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    iconSize: 64,
                    icon: Icon(
                      isPlaying ? Icons.pause_circle : Icons.play_circle,
                      color: Colors.white,
                    ),
                    onPressed: toggle,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: () => audioHandler.skipToNext(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}