import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../data/playlist_data.dart';
import '../data/favorites_state.dart';
import '../utils/route_observer.dart';
import '../models/song.dart';

Map<int, int> songPositions = {};
Map<int, bool> songWasPlaying = {};

class PlayerPage extends StatefulWidget {
  final int initialIndex;
  const PlayerPage({super.key, required this.initialIndex});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with WidgetsBindingObserver, RouteAware {
  final AudioPlayer _player = AudioPlayer();
  late int currentIndex;
  bool isPlaying = false;

  Song get currentSong => playlist[currentIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentIndex = widget.initialIndex;
    loadSong();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  Future<void> stopBecauseNotVisible() async {
    savePosition();
    if (_player.playing) await _player.pause();
    if (mounted) setState(() => isPlaying = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      stopBecauseNotVisible();
    }
  }

  @override
  void didPushNext() => stopBecauseNotVisible();

  Future<void> loadSong() async {
    await _player.setUrl(currentSong.url);
    if (songPositions.containsKey(currentIndex)) {
      await _player.seek(Duration(seconds: songPositions[currentIndex]!));
    }
    if (songWasPlaying.containsKey(currentIndex)) {
      final wasPlaying = songWasPlaying[currentIndex]!;
      isPlaying = wasPlaying;
      setState(() {});
      if (wasPlaying) await _player.play();
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
    setState(() => isPlaying = !isPlaying);
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void nextSong() async {
    savePosition();
    currentIndex = (currentIndex + 1) % playlist.length;
    await loadSong();
    if (isPlaying) _player.play();
  }

  void prevSong() async {
    savePosition();
    currentIndex = (currentIndex - 1 + playlist.length) % playlist.length;
    await loadSong();
    if (isPlaying) _player.play();
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
            Text(currentSong.title,
                style: const TextStyle(color: Colors.white, fontSize: 22)),
            const SizedBox(height: 10),
            Text(currentSong.artist,
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
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
                              onChanged: (value) => _player
                                  .seek(Duration(milliseconds: value.round())),
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
                    onPressed: prevSong),
                const SizedBox(width: 20),
                IconButton(
                    icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white),
                    iconSize: 60,
                    onPressed: playPause),
                const SizedBox(width: 20),
                IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    iconSize: 40,
                    onPressed: nextSong),
              ],
            ),
          ],
        ),
      ),
    );
  }
}