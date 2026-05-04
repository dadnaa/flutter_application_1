// ─────────────────────────────────────────────────────────────────────────────
// miniplayer.dart
//
// FIXES:
//   1. MiniPlayer only updated on 'song_changed' events — if the user
//      opened the app with music already playing, the mini player stayed
//      blank. Now it also listens to 'status', 'playing', and 'paused' events.
//   2. Requests 'get_status' on init so it populates immediately if the
//      service is already running (not just after the next song change).
//   3. FIX: Shows the online player info (from AudioPlayerController) when
//      no foreground service is running, so the miniplayer is always useful.
//   4. Navigation: tapping the miniplayer opens the correct player mode.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/music_service.dart';
import '../services/audio_player_controller.dart';
import '../data/playlist_data.dart';
import '../pages/player_page.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  // ── State from foreground service ──────────────────────────────────────────
  String _fsTitle = '';
  String _fsArtist = '';
  bool _fsIsPlaying = false;

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onData);
    // FIX: Request current status in case service is already running.
    if (MusicService.isRunning) {
      MusicService.sendCommand({'command': 'get_status'});
    }
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onData);
    super.dispose();
  }

  void _onData(Object data) {
    if (!mounted || data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final event = map['event'] as String?;
    switch (event) {
      case 'song_changed':
      case 'status': // FIX: also handle status response
        setState(() {
          _fsTitle = map['song'] as String? ?? '';
          _fsArtist = map['artist'] as String? ?? '';
          _fsIsPlaying = map['isPlaying'] as bool? ?? false;
        });
        break;
      case 'playing':
        setState(() => _fsIsPlaying = true);
        break;
      case 'paused':
        setState(() => _fsIsPlaying = false);
        break;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ServicePlaybackSnapshot>(
      valueListenable: MusicService.playback,
      builder: (context, snapshot, child) {
        if (snapshot.hasSong) {
          return _buildBar(
            title: snapshot.title,
            artist: snapshot.artist,
            isPlaying: snapshot.isPlaying,
            onPlayPause: () => MusicService.sendCommand({
              'command': snapshot.isPlaying ? 'pause' : 'play',
            }),
            onNext: () => MusicService.sendCommand({'command': 'next'}),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const PlayerPage(initialIndex: 0, isLocalMode: true),
              ),
            ),
          );
        }
        return _buildOnlineFallback(context);
      },
    );
  }

  Widget _buildOnlineFallback(BuildContext context) {
    // Show foreground-service track if available, otherwise online player.
    if (_fsTitle.isNotEmpty) {
      return _buildBar(
        title: _fsTitle,
        artist: _fsArtist,
        isPlaying: _fsIsPlaying,
        onPlayPause: () => MusicService.sendCommand({
          'command': _fsIsPlaying ? 'pause' : 'play',
        }),
        onNext: () => MusicService.sendCommand({'command': 'next'}),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const PlayerPage(initialIndex: 0, isLocalMode: true),
          ),
        ),
      );
    }

    // FIX: Fall through to online player state if service not running.
    return StreamBuilder(
      stream: AudioPlayerController.instance.playerStateStream,
      builder: (_, snap) {
        final ctrl = AudioPlayerController.instance;
        final playing = snap.data?.playing ?? false;
        // Only show if a song is actually loaded (duration != null)
        if (ctrl.duration == null) return const SizedBox.shrink();
        final song = playlist[ctrl.currentIndex];
        return _buildBar(
          title: song.title,
          artist: song.artist,
          isPlaying: playing,
          onPlayPause: ctrl.togglePlayPause,
          onNext: ctrl.next,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerPage(initialIndex: ctrl.currentIndex),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBar({
    required String title,
    required String artist,
    required bool isPlaying,
    required VoidCallback onPlayPause,
    required VoidCallback onNext,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: const Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.music_note, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    artist,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: onPlayPause,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white),
              onPressed: onNext,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
