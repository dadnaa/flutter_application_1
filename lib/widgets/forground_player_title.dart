import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/music_service.dart';

class ForegroundPlayerTile extends StatefulWidget {
  const ForegroundPlayerTile({super.key});

  @override
  State<ForegroundPlayerTile> createState() => _ForegroundPlayerTileState();
}

class _ForegroundPlayerTileState extends State<ForegroundPlayerTile> {
  bool _serviceStarted = false;
  bool _isPlaying = false;
  String _currentTitle = '';
  String _currentArtist = '';

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    _checkServiceStatus();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    super.dispose();
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      setState(() => _serviceStarted = true);
    }
  }

  void _onTaskData(Object data) {
    if (!mounted) return;
    if (data is Map) {
      final event = data['event'];
      if (event == 'playing') {
        setState(() => _isPlaying = true);
      } else if (event == 'paused') {
        setState(() => _isPlaying = false);
      } else if (event == 'song_changed') {
        setState(() {
          _currentTitle = data['song'] ?? '';
          _currentArtist = data['artist'] ?? '';
          _isPlaying = data['isPlaying'] ?? false;
        });
      }
    }
  }

  Future<void> _onPlayPause() async {
    if (!_serviceStarted) {
      final perm = await FlutterForegroundTask.checkNotificationPermission();
      if (perm != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      await MusicService.start();
      setState(() {
        _serviceStarted = true;
        _isPlaying = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a local song from the "Local" tab first')),
      );
    } else {
      MusicService.sendCommand({'command': _isPlaying ? 'pause' : 'play'});
    }
  }

  void _onNext() => MusicService.sendCommand({'command': 'next'});
  void _onPrev() => MusicService.sendCommand({'command': 'prev'});
  void _onStop() async => await MusicService.stop();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: ListTile(
        leading: const Icon(Icons.music_note, color: Colors.white, size: 36),
        title: Text(
          _currentTitle.isNotEmpty ? _currentTitle : 'No track selected',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _currentArtist.isNotEmpty ? _currentArtist : (_serviceStarted ? 'Select a local song' : 'Tap ▶ to start'),
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_serviceStarted) ...[
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: _onPrev,
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: Colors.white, size: 36),
                onPressed: _onPlayPause,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: _onNext,
              ),
              IconButton(
                icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
                onPressed: _onStop,
              ),
            ] else
              IconButton(
                icon: const Icon(Icons.play_circle, color: Colors.white, size: 36),
                onPressed: _onPlayPause,
              ),
          ],
        ),
      ),
    );
  }
}