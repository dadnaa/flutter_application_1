import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';
import 'audio_player_controller.dart';
import 'music_service.dart';

class ShakeDetectorService {
  ShakeDetectorService._();

  static final ShakeDetectorService instance = ShakeDetectorService._();

  static const double _shakeThreshold = 11.0;
  static const Duration _cooldown = Duration(milliseconds: 1200);

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  DateTime _lastShakeTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;

    // UserAccelerometerEvent removes gravity, which makes intentional shakes
    // much easier to detect than raw accelerometer magnitude.
    _subscription = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen(_onAccelerometerEvent, onError: (_) {});
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _running = false;
  }

  void _onAccelerometerEvent(UserAccelerometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    if (magnitude <= _shakeThreshold) return;

    final now = DateTime.now();
    if (now.difference(_lastShakeTime) < _cooldown) return;

    _lastShakeTime = now;
    _handleShake();
  }

  void _handleShake() {
    if (MusicService.isRunning) {
      final isPlaying = MusicService.lastKnownPlayingState;
      unawaited(
        MusicService.sendCommandReliable({
          'command': isPlaying ? 'pause' : 'play',
          'source': 'shake',
        }),
      );
      return;
    }

    unawaited(AudioPlayerController.instance.togglePlayPause());
  }
}
