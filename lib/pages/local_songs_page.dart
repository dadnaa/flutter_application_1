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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Music'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSongs,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : _songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.library_music,
                          size: 48, color: theme.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'No music found on device',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add songs to your device and refresh.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white60),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: _songs.length,
                  itemBuilder: (ctx, i) {
                    final s = _songs[i];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.audiotrack,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(s.title),
                        subtitle: Text(
                          s.artist ?? 'Unknown',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.white60),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_circle),
                          color: theme.colorScheme.secondary,
                          onPressed: () => _playThisSong(i),
                        ),
                        onTap: () => _playThisSong(i),
                      ),
                    );
                  },
                ),
    );
  }
}
