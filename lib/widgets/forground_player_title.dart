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
    final theme = Theme.of(context);
    return Container(
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
            ),
            child: const Icon(Icons.graphic_eq, color: Colors.white),
          ),
          title: Text(
            _currentTitle.isNotEmpty ? _currentTitle : 'No track selected',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _currentArtist.isNotEmpty
                ? _currentArtist
                : (_serviceStarted ? 'Select a local song' : 'Tap play to start'),
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_serviceStarted) ...[
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: _onPrev,
                ),
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                  iconSize: 36,
                  onPressed: _onPlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: _onNext,
                ),
                IconButton(
                  icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
                  onPressed: _onStop,
                ),
              ] else
                IconButton(
                  icon: const Icon(Icons.play_circle),
                  iconSize: 36,
                  onPressed: _onPlayPause,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
