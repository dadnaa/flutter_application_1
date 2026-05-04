import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/playable_song.dart';
import 'music_task_handler.dart';

class ServicePlaybackSnapshot {
  final String title;
  final String artist;
  final String coverUrl;
  final bool isPlaying;
  final int positionSec;
  final int durationSec;
  final int index;

  const ServicePlaybackSnapshot({
    this.title = '',
    this.artist = '',
    this.coverUrl = '',
    this.isPlaying = false,
    this.positionSec = 0,
    this.durationSec = 0,
    this.index = 0,
  });

  bool get hasSong => title.isNotEmpty;

  ServicePlaybackSnapshot copyWith({
    String? title,
    String? artist,
    String? coverUrl,
    bool? isPlaying,
    int? positionSec,
    int? durationSec,
    int? index,
  }) {
    return ServicePlaybackSnapshot(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      coverUrl: coverUrl ?? this.coverUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      positionSec: positionSec ?? this.positionSec,
      durationSec: durationSec ?? this.durationSec,
      index: index ?? this.index,
    );
  }
}

class MusicService {
  MusicService._();

  static bool _serviceRunning = false;
  static bool _callbackRegistered = false;

  static bool lastKnownPlayingState = false;

  // Main-isolate snapshot used by PlayerPage, MiniPlayer, and shake controls.
  // The foreground task isolate has separate memory, so static fields written
  // inside MusicTaskHandler cannot be read directly by app widgets.
  static final ValueNotifier<ServicePlaybackSnapshot> playback =
      ValueNotifier<ServicePlaybackSnapshot>(const ServicePlaybackSnapshot());

  static void init() {
    _registerMainCallback();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'music_channel',
        channelName: 'Music Playback',
        channelDescription: 'Background music player controls',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  static Future<bool> requestNotificationPermission() async {
    final perm = await FlutterForegroundTask.checkNotificationPermission();
    if (perm == NotificationPermission.granted) return true;

    await FlutterForegroundTask.requestNotificationPermission();
    final updated = await FlutterForegroundTask.checkNotificationPermission();
    return updated == NotificationPermission.granted;
  }

  static Future<bool> start() async {
    if (_serviceRunning) return true;

    _registerMainCallback();
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Music Player',
      notificationText: 'Preparing playback',
      notificationButtons: const [
        NotificationButton(id: 'prev', text: 'Prev'),
        NotificationButton(id: 'play_pause', text: 'Play'),
        NotificationButton(id: 'next', text: 'Next'),
      ],
      callback: startCallback,
    );

    _serviceRunning = true;
    // Give the task isolate time to run onStart before the first command.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
    _serviceRunning = false;
    lastKnownPlayingState = false;
    playback.value = const ServicePlaybackSnapshot();
  }

  static void sendCommand(Map<String, dynamic> cmd) {
    if (!_serviceRunning) return;
    FlutterForegroundTask.sendDataToTask(cmd);
  }

  static Future<void> sendCommandReliable(Map<String, dynamic> cmd) async {
    if (!_serviceRunning) return;
    FlutterForegroundTask.sendDataToTask(cmd);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (_serviceRunning) {
      FlutterForegroundTask.sendDataToTask(cmd);
    }
  }

  static void primeLocalPlayback({
    required PlayableSong song,
    required int index,
  }) {
    lastKnownPlayingState = true;
    playback.value = ServicePlaybackSnapshot(
      title: song.title,
      artist: song.artist,
      coverUrl: song.coverUrl ?? '',
      isPlaying: true,
      index: index,
    );
  }

  static void _registerMainCallback() {
    if (_callbackRegistered) return;
    _callbackRegistered = true;
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
  }

  static void _onTaskData(Object data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final event = map['event'] as String?;
    final current = playback.value;

    switch (event) {
      case 'song_changed':
      case 'status':
        final snapshot = ServicePlaybackSnapshot(
          title: map['song'] as String? ?? current.title,
          artist: map['artist'] as String? ?? current.artist,
          coverUrl: map['coverUrl'] as String? ?? current.coverUrl,
          isPlaying: map['isPlaying'] as bool? ?? current.isPlaying,
          positionSec:
              (map['positionSec'] as num?)?.toInt() ?? current.positionSec,
          durationSec:
              (map['durationSec'] as num?)?.toInt() ?? current.durationSec,
          index: (map['index'] as num?)?.toInt() ?? current.index,
        );
        playback.value = snapshot;
        lastKnownPlayingState = snapshot.isPlaying;
        break;
      case 'playing':
        lastKnownPlayingState = true;
        playback.value = current.copyWith(isPlaying: true);
        break;
      case 'paused':
        lastKnownPlayingState = false;
        playback.value = current.copyWith(isPlaying: false);
        break;
      case 'position':
        playback.value = current.copyWith(
          positionSec: (map['positionSec'] as num?)?.toInt(),
          durationSec: (map['durationSec'] as num?)?.toInt(),
        );
        break;
    }
  }

  static bool get isRunning => _serviceRunning;
}
