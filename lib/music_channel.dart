import 'package:flutter/services.dart';

class MusicChannel {
  static const _channel = MethodChannel('com.example.flutter_application_1/music_service');

  // Callbacks Android → Flutter
  static Function()? onNext;
  static Function()? onPrevious;
  static Function()? onStop;
  static Function()? onPause;

  static void init() { 
    _channel.setMethodCallHandler((call) async { // Android → Flutter
      switch (call.method) {
        case 'onNext':
          onNext?.call();
          break;
        case 'onPrevious':
          onPrevious?.call();
          break;
        case 'onStop':
          onStop?.call();
          break;
        case 'onPause':
          onPause?.call();
          break;
      }
    });
  }
  // Flutter → Android
  static Future<void> startService({
    required String audioPath,
    required String title,
    String artist = '',
  }) async {
    await _channel.invokeMethod('startService', {
      'audioPath': audioPath,
      'title': title,
      'artist': artist,
    });
  }

  static Future<bool> togglePlayPause() async {
    return await _channel.invokeMethod<bool>('togglePlayPause') ?? false;
  }

  static Future<void> stopService() async {
    await _channel.invokeMethod('stopService');
  }

  static Future<bool> isPlayingNow() async {
    return await _channel.invokeMethod<bool>('isPlaying') ?? false;
  }

  static Future<List<int>> getPosition() async {
    final result = await _channel.invokeMethod<List<dynamic>>('getPosition');
    if (result == null) return [0, 0];
    return [result[0] as int, result[1] as int];
  }

  static Future<void> seekTo(int positionMs) async {
    await _channel.invokeMethod('seekTo', {'position': positionMs});
  }
}
