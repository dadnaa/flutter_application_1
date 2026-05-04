

import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/playable_song.dart';
import 'music_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MusicTaskHandler());
}

class MusicTaskHandler extends TaskHandler {
  final AudioPlayer _player = AudioPlayer();
  List<PlayableSong> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;


  StreamSubscription<PlayerState>? _stateSub;
  Timer? _positionTimer;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _next();
      }
      MusicService.lastKnownPlayingState = state.playing;
    });

    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final dur = _player.duration;
      if (dur != null) {
        FlutterForegroundTask.sendDataToMain({
          'event': 'position',
          'positionSec': _player.position.inSeconds,
          'durationSec': dur.inSeconds,
        });
      }
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // FIX: Cancel all subscriptions and timers to prevent leaks.
    _positionTimer?.cancel();
    _positionTimer = null;
    await _stateSub?.cancel();
    _stateSub = null;
    await _player.stop();
    await _player.dispose();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  // ── Notification button handler ────────────────────────────────────────────
  @override
  void onNotificationButtonPressed(String id) {
    switch (id) {
      case 'play_pause':
        _isPlaying ? _pause() : _play();
        break;
      case 'next':
        _next();
        break;
      case 'prev':
        _prev();
        break;
    }
  }

  // ── Main → Task message handler ────────────────────────────────────────────
  @override
  void onReceiveData(Object data) {
    // FIX: Isolate messages arrive as Map<Object?, Object?>, not Map<String, dynamic>.
    // Cast safely to avoid runtime type errors.
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final cmd = map['command'] as String?;

    switch (cmd) {
      case 'play':
        _play();
        break;
      case 'pause':
        _pause();
        break;
      case 'next':
        _next();
        break;
      case 'prev':
        _prev();
        break;
      case 'seek':
        final sec = (map['positionSec'] as num?)?.toInt() ?? 0;
        _seek(sec);
        break;
      case 'set_playlist':
        final rawList = map['playlist'] as List<dynamic>? ?? [];
        final songs = rawList
            .map(
              (e) => PlayableSong.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        final startIndex = (map['startIndex'] as num?)?.toInt() ?? 0;
        _setPlaylist(songs, startIndex: startIndex);
        break;
      case 'get_status':
        _sendStatus();
        break;
    }
  }

  // ── Playback helpers ───────────────────────────────────────────────────────
  Future<void> _playCurrent() async {
    if (_playlist.isEmpty) return;
    final song = _playlist[_currentIndex];

  
    await _player.stop();

    final url = song.type == SongType.local
        ? Uri.file(song.localPath!).toString()
        : song.onlineUrl!;

    await _player.setUrl(url);
    await _player.play();
    _isPlaying = true;
    MusicService.lastKnownPlayingState = true;

    _updateNotification();

    // Notify UI
    FlutterForegroundTask.sendDataToMain({
      'event': 'song_changed',
      'song': song.title,
      'artist': song.artist,
      'coverUrl': song.coverUrl ?? '', // FIX: include cover for UI
      'isPlaying': true,
      'index': _currentIndex,
      'positionSec': 0,
      'durationSec': _player.duration?.inSeconds ?? 0,
    });
  }

  void _play() {
    if (_playlist.isEmpty || _player.playing) return;
    _player.play().then((_) {
      _isPlaying = true;
      MusicService.lastKnownPlayingState = true;
      _updateNotification();
      FlutterForegroundTask.sendDataToMain({'event': 'playing'});
    });
  }

  void _pause() {
    _player.pause().then((_) {
      _isPlaying = false;
      MusicService.lastKnownPlayingState = false;
      _updateNotification();
      FlutterForegroundTask.sendDataToMain({'event': 'paused'});
    });
  }

  void _next() {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    _playCurrent();
  }

  void _prev() {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    _playCurrent();
  }

  void _seek(int seconds) {
    _player.seek(Duration(seconds: seconds));
  }

  void _setPlaylist(List<PlayableSong> songs, {int startIndex = 0}) {
    _playlist = songs;
    _currentIndex = startIndex.clamp(0, songs.isEmpty ? 0 : songs.length - 1);
    if (songs.isNotEmpty) _playCurrent();
  }

  void _sendStatus() {
    final song = _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
    FlutterForegroundTask.sendDataToMain({
      'event': 'status',
      'song': song?.title ?? '',
      'artist': song?.artist ?? '',
      'coverUrl': song?.coverUrl ?? '',
      'isPlaying': _isPlaying,
      'positionSec': _player.position.inSeconds,
      'durationSec': _player.duration?.inSeconds ?? 0,
      'index': _currentIndex,
    });
  }

  // ── Notification update ────────────────────────────────────────────────────
  void _updateNotification() {
    final song = _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
    FlutterForegroundTask.updateService(
      notificationTitle: song?.title ?? 'Music Player',
      notificationText: _isPlaying ? (song?.artist ?? 'Now playing') : 'Paused',
      notificationButtons: [
        const NotificationButton(id: 'prev', text: 'Prev'),
        NotificationButton(
          id: 'play_pause',
          text: _isPlaying ? 'Pause' : 'Play',
        ),
        const NotificationButton(id: 'next', text: 'Next'),
      ],
    );
  }
}
