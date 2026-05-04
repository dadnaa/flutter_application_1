

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../data/playlist_data.dart';

class AudioPlayerController extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────────────────────
  AudioPlayerController._();
  static final AudioPlayerController instance = AudioPlayerController._();

  // ── Internal player ────────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  bool _hasLoadedSource = false;
  Future<void> _loadChain = Future.value();

  
  final Map<int, int> _savedPositions = {};
  final Map<int, bool> _savedWasPlaying = {};

  // ── Current index ──────────────────────────────────────────────────────────
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  Song get currentSong => playlist[_currentIndex];

  // ── Public stream accessors ────────────────────────────────────────────────
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get hasLoadedSource => _hasLoadedSource;

  Future<void> loadSong(int index, {bool autoPlay = false}) async {
    _loadChain = _loadChain.then((_) async {
      _saveCurrentPosition();
      _currentIndex = index.clamp(0, playlist.length - 1);
      final song = playlist[_currentIndex];
      notifyListeners();

      await _player.stop();
      await _player.setUrl(song.url);
      _hasLoadedSource = true;

      // Restore saved position if available.
      if (_savedPositions.containsKey(_currentIndex)) {
        await _player.seek(Duration(seconds: _savedPositions[_currentIndex]!));
      }

      final shouldPlay = autoPlay || (_savedWasPlaying[_currentIndex] ?? false);
      if (shouldPlay) {
        await _player.play();
      }
      notifyListeners();
    });
    return _loadChain;
  }

  // ── Playback controls ──────────────────────────────────────────────────────
  Future<void> play() async => _player.play();

  Future<void> pause() async => _player.pause();

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async => _player.seek(position);

  Future<void> next({bool keepPlaying = true}) async {
    _saveCurrentPosition();
    _currentIndex = (_currentIndex + 1) % playlist.length;
    await loadSong(_currentIndex, autoPlay: keepPlaying);
  }

  Future<void> previous({bool keepPlaying = true}) async {
    _saveCurrentPosition();
    _currentIndex = (_currentIndex - 1 + playlist.length) % playlist.length;
    await loadSong(_currentIndex, autoPlay: keepPlaying);
  }

  // ── Save/restore position ──────────────────────────────────────────────────
  void _saveCurrentPosition() {
    _savedPositions[_currentIndex] = _player.position.inSeconds;
    _savedWasPlaying[_currentIndex] = _player.playing;
  }

  void savePosition() => _saveCurrentPosition();


  Future<void> stopForBackground() async {
    _saveCurrentPosition();
    if (_player.playing) await _player.pause();
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }
}
