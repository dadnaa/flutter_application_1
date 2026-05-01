import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'music_task_handler.dart';

class MusicService {
  static bool _serviceRunning = false;

  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'music_channel',
        channelName: 'Music Playback',
        channelDescription: 'Foreground music player notification',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
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

  static Future<void> start() async {
    if (_serviceRunning) return;
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Music Player',
      notificationText: 'Initializing…',
      notificationButtons: const [NotificationButton(id: 'play_pause', text: 'Play')],
      callback: startCallback,
    );
    _serviceRunning = true;
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
    _serviceRunning = false;
  }

  static void sendCommand(Map<String, dynamic> cmd) {
    FlutterForegroundTask.sendDataToTask(cmd);
  }

  static bool get isRunning => _serviceRunning;
}