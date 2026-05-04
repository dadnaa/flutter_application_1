

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/music_service.dart';
import '../services/audio_player_controller.dart';
import '../models/playable_song.dart';
import 'player_page.dart';

class LocalSongsPage extends StatefulWidget {
  const LocalSongsPage({super.key});

  @override
  State<LocalSongsPage> createState() => _LocalSongsPageState();
}

class _LocalSongsPageState extends State<LocalSongsPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  bool _isLoading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoad();
  }

  // ── Permission handling ────────────────────────────────────────────────────
  Future<void> _requestPermissionAndLoad() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
    });

  
    final audioStatus = await Permission.audio.request();
    final storageStatus = await Permission.storage.request();

    final granted = audioStatus.isGranted || storageStatus.isGranted;

    if (granted) {
      await _loadSongs();
    } else {
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
    }
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    setState(() {
      _songs = songs.where((s) => (s.duration ?? 0) > 10000).toList();
      _isLoading = false;
    });
  }

  // ── Play a song via foreground service ────────────────────────────────────
  Future<void> _playThisSong(int index) async {
    await AudioPlayerController.instance.stopForBackground();

    final notifGranted = await MusicService.requestNotificationPermission();
    if (!notifGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permission needed for media controls'),
        ),
      );
    }

    if (!MusicService.isRunning) {
      final started = await MusicService.start();
      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start background service')),
        );
        return;
      }
    }

    final localPlaylist = _songs
        .map(
          (s) => PlayableSong.local(
            title: s.title,
            artist: s.artist ?? 'Unknown',
            localPath: s.data,
          ),
        )
        .toList();

    MusicService.primeLocalPlayback(song: localPlaylist[index], index: index);

    unawaited(
      MusicService.sendCommandReliable({
        'command': 'set_playlist',
        'playlist': localPlaylist.map((e) => e.toJson()).toList(),
        'startIndex': index,
      }),
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PlayerPage(initialIndex: 0, isLocalMode: true),
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Music'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _requestPermissionAndLoad,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              const Text(
                'Storage permission is required to read music files.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await openAppSettings();
                  // Re-check after returning from settings
                  await _requestPermissionAndLoad();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    if (_songs.isEmpty) {
      return const Center(
        child: Text(
          'No music found on device',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (_, i) {
        final s = _songs[i];
        return ListTile(
          leading: const Icon(Icons.audiotrack, color: Colors.white70),
          title: Text(s.title),
          subtitle: Text(
            s.artist ?? 'Unknown',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.play_circle, color: Colors.greenAccent),
            onPressed: () => _playThisSong(i),
          ),
          onTap: () => _playThisSong(i),
        );
      },
    );
  }
}
