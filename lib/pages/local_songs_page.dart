import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/local_song.dart';
import '../services/music_service.dart';

class LocalSongsPage extends StatefulWidget {
  const LocalSongsPage({super.key});

  @override
  State<LocalSongsPage> createState() => _LocalSongsPageState();
}

class _LocalSongsPageState extends State<LocalSongsPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoad();
  }

  Future<void> _requestPermissionAndLoad() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      await _loadSongs();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission needed to read music')),
      );
    }
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    setState(() {
      _songs = songs;
      _isLoading = false;
    });
  }

  void _playThisSong(int index) async {
    final localPlaylist = _songs.map((s) => LocalSong(
      title: s.title,
      artist: s.artist ?? 'Unknown',
      path: s.data,
      id: s.id,
    )).toList();

    if (!MusicService.isRunning) {
      await MusicService.start();
    }
    MusicService.sendCommand({
      'command': 'set_playlist',
      'playlist': localPlaylist.map((e) => e.toJson()).toList(),
      'startIndex': index,
    });
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Local Music', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSongs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? const Center(child: Text('No music found on device', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (ctx, i) {
                    final s = _songs[i];
                    return ListTile(
                      leading: const Icon(Icons.audiotrack, color: Colors.white70),
                      title: Text(s.title, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(s.artist ?? 'Unknown', style: const TextStyle(color: Colors.grey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_circle, color: Colors.green),
                        onPressed: () => _playThisSong(i),
                      ),
                      onTap: () => _playThisSong(i),
                    );
                  },
                ),
    );
  }
}