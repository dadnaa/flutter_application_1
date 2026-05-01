import 'package:just_audio/just_audio.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/local_song.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MusicTaskHandler());
}

class MusicTaskHandler extends TaskHandler {
  final AudioPlayer _player = AudioPlayer();
  List<LocalSong> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _player.positionStream.listen((_) => _updateNotification());
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _next();
      }
    });
  }

  void _updateNotification() {
    final song = _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
    FlutterForegroundTask.updateService(
      notificationTitle: song?.title ?? 'Music Player',
      notificationText: _isPlaying ? '${song?.artist ?? 'Now playing'}' : 'Paused',
      notificationButtons: [
        const NotificationButton(id: 'prev', text: '⏮'),
        NotificationButton(id: 'play_pause', text: _isPlaying ? '⏸' : '▶'),
        const NotificationButton(id: 'next', text: '⏭'),
      ],
    );
  }

  Future<void> _playCurrent() async {
    if (_playlist.isEmpty) return;
    final path = _playlist[_currentIndex].path;
    await _player.setUrl('file://$path');
    await _player.play();
    _isPlaying = true;
    _updateNotification();
    FlutterForegroundTask.sendDataToMain({
      'event': 'song_changed',
      'song': _playlist[_currentIndex].title,
      'artist': _playlist[_currentIndex].artist,
      'isPlaying': true,
    });
  }

  void _play() async {
    if (_playlist.isEmpty) return;
    if (_player.playing) return;
    await _player.play();
    _isPlaying = true;
    _updateNotification();
    FlutterForegroundTask.sendDataToMain({'event': 'playing'});
  }

  void _pause() async {
    await _player.pause();
    _isPlaying = false;
    _updateNotification();
    FlutterForegroundTask.sendDataToMain({'event': 'paused'});
  }

  void _next() async {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await _playCurrent();
  }

  void _prev() async {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await _playCurrent();
  }

  void _setPlaylist(List<LocalSong> playlist, {int startIndex = 0}) {
    _playlist = playlist;
    _currentIndex = startIndex.clamp(0, playlist.length - 1);
    _playCurrent();
  }

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

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final cmd = data['command'];
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
        case 'set_playlist':
          final List<dynamic> list = data['playlist'];
          final playlist = list.map((e) => LocalSong.fromJson(e)).toList();
          final startIndex = data['startIndex'] ?? 0;
          _setPlaylist(playlist, startIndex: startIndex);
          break;
      }
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _player.stop();
    await _player.dispose();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}
}