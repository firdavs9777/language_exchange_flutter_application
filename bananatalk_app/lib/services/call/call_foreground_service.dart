import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Android foreground service for the duration of a call: type microphone,
/// plus camera for video. LiveKit provides none, so without it Android stops
/// capturing a few seconds after the app leaves the foreground.
///
/// The service only keeps the process (and LiveKit's mic/camera) alive, so it
/// starts without a task callback: no TaskHandler isolate runs.
class CallForegroundService {
  const CallForegroundService._();

  static const int _serviceId = 4711;
  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    _initialized = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'bananatalk_ongoing_call',
        channelName: 'Ongoing call',
        channelDescription: 'Keeps your call running while BananaTalk is in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: false,
        allowWifiLock: true,
        // A service the OS restarts after killing the process has no call.
        allowAutoRestart: false,
      ),
    );
  }

  static Future<void> start({required bool video, required String title, required String text}) async {
    if (!Platform.isAndroid) return;
    _init();
    try {
      final ServiceRequestResult result;
      if (await FlutterForegroundTask.isRunningService) {
        result = await FlutterForegroundTask.updateService(
            notificationTitle: title, notificationText: text);
      } else {
        result = await FlutterForegroundTask.startService(
          serviceId: _serviceId,
          notificationTitle: title,
          notificationText: text,
          serviceTypes: [
            ForegroundServiceTypes.microphone,
            if (video) ForegroundServiceTypes.camera,
          ],
        );
      }
      if (result is ServiceRequestFailure) {
        debugPrint('📞 call foreground service failed to start: ${result.error}');
      }
    } catch (e) {
      debugPrint('📞 call foreground service failed to start: $e');
    }
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    try {
      if (!await FlutterForegroundTask.isRunningService) return;
      final result = await FlutterForegroundTask.stopService();
      if (result is ServiceRequestFailure) {
        debugPrint('📞 call foreground service failed to stop: ${result.error}');
      }
    } catch (e) {
      debugPrint('📞 call foreground service failed to stop: $e');
    }
  }
}
