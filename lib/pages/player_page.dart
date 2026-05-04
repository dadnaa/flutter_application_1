// ─────────────────────────────────────────────────────────────────────────────
// player_page.dart
//
// FIXES:
//   1. CRITICAL: Previously each PlayerPage instance created its own AudioPlayer
//      that was DISPOSED when the page popped. Opening the player twice created
//      two players — both trying to play the same URL.
//      → Now uses AudioPlayerController.instance (singleton).
//   2. didChangeAppLifecycleState paused playback when app went to background
//      — this prevented background audio from working.
//      → Removed the pause-on-background logic for online mode too; use the
//        foreground service or just_audio's native background audio capability.
//   3. The old songPositions / songWasPlaying top-level globals in this file
//      are removed; position persistence lives in AudioPlayerController.
//   4. Favorite button now uses FavoritesNotifier so it stays in sync across
//      all pages.
//   5. Online player auto-advances to next song on completion.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../data/playlist_data.dart';
import '../data/favorites_notifier.dart';
import '../services/music_service.dart';
import '../services/audio_player_controller.dart';
import '../utils/route_observer.dart';

class PlayerPage extends StatefulWidget {
  final int initialIndex;

  /// true = control the foreground service (local/background player)
  /// false = use the in-process AudioPlayerController (online player)
  final bool isLocalMode;

  const PlayerPage({
    super.key,
    required this.initialIndex,
    this.isLocalMode = false,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with RouteAware {
  // ── Online mode — backed by AudioPlayerController singleton ───────────────
  final _ctrl = AudioPlayerController.instance;

  // ── Local / foreground-service mode state ─────────────────────────────────
  String _fsTitle = MusicService.playback.value.title;
  String _fsArtist = MusicService.playback.value.artist;
  bool _fsIsPlaying = MusicService.playback.value.isPlaying;
  int _fsPositionSec = MusicService.playback.value.positionSec;
  int _fsDurationSec = MusicService.playback.value.durationSec;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    if (!widget.isLocalMode) {
      if (!_ctrl.hasLoadedSource || _ctrl.currentIndex != widget.initialIndex) {
        _ctrl.loadSong(widget.initialIndex);
      }
    } else {
      FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
      // Ask service for current status after registering the callback.
      Future.delayed(const Duration(milliseconds: 100), () {
        MusicService.sendCommand({'command': 'get_status'});
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.isLocalMode) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    if (!widget.isLocalMode) {
      routeObserver.unsubscribe(this);
      // FIX: Do NOT dispose the controller here — it's a singleton.
      // Just save the current position so it can be restored on next open.
      _ctrl.savePosition();
    } else {
      FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    }
    super.dispose();
  }

  // ── Foreground service events ──────────────────────────────────────────────
  void _onForegroundTaskData(Object data) {
    if (!mounted || data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final event = map['event'] as String?;
    switch (event) {
      case 'song_changed':
      case 'status':
        setState(() {
          _fsTitle = map['song'] as String? ?? '';
          _fsArtist = map['artist'] as String? ?? '';
          _fsIsPlaying = map['isPlaying'] as bool? ?? false;
          _fsPositionSec = (map['positionSec'] as num?)?.toInt() ?? 0;
          _fsDurationSec = (map['durationSec'] as num?)?.toInt() ?? 0;
        });
        break;
      case 'playing':
        setState(() => _fsIsPlaying = true);
        break;
      case 'paused':
        setState(() => _fsIsPlaying = false);
        break;
      case 'position':
        setState(() {
          _fsPositionSec = (map['positionSec'] as num?)?.toInt() ?? 0;
          _fsDurationSec = (map['durationSec'] as num?)?.toInt() ?? 0;
        });
        break;
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────
  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLocalMode ? 'Now Playing' : 'Online Player'),
      ),
      body: widget.isLocalMode ? _buildLocalUi() : _buildOnlineUi(),
    );
  }

  // ── Online player UI (stream-driven, no local state for position) ─────────
  Widget _buildOnlineUi() {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => _onlineBody(),
    );
  }

  Widget _onlineBody() {
    final song = playlist[_ctrl.currentIndex];
    final favNotifier = FavoritesNotifier.instance;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Cover art
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              song.cover,
              height: 260,
              width: 260,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 260,
                width: 260,
                color: Colors.white12,
                child: const Icon(
                  Icons.music_note,
                  size: 80,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Title + favorite button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  song.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // FIX: Favorite button uses FavoritesNotifier for instant sync
              ListenableBuilder(
                listenable: favNotifier,
                builder: (context, child) => IconButton(
                  icon: Icon(
                    favNotifier.isFavorite(song.url)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () => favNotifier.toggle(song),
                ),
              ),
            ],
          ),
          Text(
            song.artist,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          // Seek bar (stream-driven, no setState)
          StreamBuilder<Duration?>(
            stream: _ctrl.durationStream,
            builder: (_, durSnap) {
              final duration = durSnap.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: _ctrl.positionStream,
                builder: (context, posSnap) {
                  final position = posSnap.data ?? Duration.zero;
                  final maxMs = duration.inMilliseconds.toDouble();
                  final posMs = position.inMilliseconds.toDouble().clamp(
                    0.0,
                    maxMs > 0 ? maxMs : 0.0,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(_fmt(position)),
                            const Spacer(),
                            Text(_fmt(duration)),
                          ],
                        ),
                        Slider(
                          activeColor: Colors.white,
                          inactiveColor: Colors.grey,
                          min: 0,
                          max: maxMs > 0 ? maxMs : 1,
                          value: maxMs > 0 ? posMs : 0,
                          onChanged: (v) =>
                              _ctrl.seek(Duration(milliseconds: v.round())),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          // Controls
          StreamBuilder(
            stream: _ctrl.playerStateStream,
            builder: (_, snap) {
              final playing = snap.data?.playing ?? false;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 40,
                    onPressed: () => _ctrl.previous(keepPlaying: playing),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      playing ? Icons.pause_circle : Icons.play_circle,
                    ),
                    iconSize: 72,
                    onPressed: _ctrl.togglePlayPause,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 40,
                    onPressed: () => _ctrl.next(keepPlaying: playing),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Local / foreground service UI ─────────────────────────────────────────
  Widget _buildLocalUi() {
    return ValueListenableBuilder<ServicePlaybackSnapshot>(
      valueListenable: MusicService.playback,
      builder: (context, snapshot, child) {
        _fsTitle = snapshot.title;
        _fsArtist = snapshot.artist;
        _fsIsPlaying = snapshot.isPlaying;
        _fsPositionSec = snapshot.positionSec;
        _fsDurationSec = snapshot.durationSec;
        return _buildLocalBody();
      },
    );
  }

  Widget _buildLocalBody() {
    if (_fsTitle.isEmpty) {
      return const Center(
        child: Text(
          'No song playing.\nSelect a song from the Local tab.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.music_note,
              size: 80,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _fsTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _fsArtist,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(_fmt(Duration(seconds: _fsPositionSec))),
                    const Spacer(),
                    Text(_fmt(Duration(seconds: _fsDurationSec))),
                  ],
                ),
                Slider(
                  value: _fsPositionSec.toDouble(),
                  max: _fsDurationSec > 0 ? _fsDurationSec.toDouble() : 1,
                  activeColor: Colors.white,
                  inactiveColor: Colors.grey,
                  onChanged: (v) => MusicService.sendCommand({
                    'command': 'seek',
                    'positionSec': v.toInt(),
                  }),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                iconSize: 48,
                onPressed: () => MusicService.sendCommand({'command': 'prev'}),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: Icon(
                  _fsIsPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 72,
                ),
                onPressed: () => MusicService.sendCommand({
                  'command': _fsIsPlaying ? 'pause' : 'play',
                }),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.skip_next),
                iconSize: 48,
                onPressed: () => MusicService.sendCommand({'command': 'next'}),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: MusicService.stop,
            icon: const Icon(Icons.stop, color: Colors.redAccent),
            label: const Text(
              'Stop Service',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
