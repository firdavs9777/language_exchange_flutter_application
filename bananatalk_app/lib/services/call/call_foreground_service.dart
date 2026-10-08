import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// The plugin calls [CallForegroundService] makes, behind a seam for tests.
abstract class ForegroundServiceBackend {
  Future<bool> isRunning();

  /// Start with type microphone, plus camera when [camera].
  Future<void> start({
    required bool camera,
    required String title,
    required String text,
    required String channelName,
    required String channelDescription,
  });

  Future<void> update({required String title, required String text});
  Future<void> stop();
}

/// flutter_foreground_task 9.x. Its calls report failure as a result instead
/// of throwing; this backend turns a failure into an exception.
class PluginForegroundServiceBackend implements ForegroundServiceBackend {
  static const int _serviceId = 4711;

  static void _check(ServiceRequestResult result) {
    if (result is ServiceRequestFailure) throw result.error;
  }

  @override
  Future<bool> isRunning() => FlutterForegroundTask.isRunningService;

  @override
  Future<void> start({
    required bool camera,
    required String title,
    required String text,
    required String channelName,
    required String channelDescription,
  }) async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'bananatalk_ongoing_call',
        channelName: channelName,
        channelDescription: channelDescription,
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
    // No task callback: the service only keeps the process (and LiveKit's
    // mic/camera) alive, so no TaskHandler isolate runs.
    _check(await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: title,
      notificationText: text,
      serviceTypes: [
        ForegroundServiceTypes.microphone,
        if (camera) ForegroundServiceTypes.camera,
      ],
    ));
  }

  @override
  Future<void> update({required String title, required String text}) async =>
      _check(await FlutterForegroundTask.updateService(notificationTitle: title, notificationText: text));

  @override
  Future<void> stop() async => _check(await FlutterForegroundTask.stopService());
}

/// Android foreground service for the duration of a call: type microphone,
/// plus camera for video. LiveKit provides none, so without it Android stops
/// capturing a few seconds after the app leaves the foreground.
///
/// Starts and stops run one at a time, in call order: a stop issued while a
/// start is in flight runs after it, so no service outlives its call.
class CallForegroundService {
  const CallForegroundService._();

  static ForegroundServiceBackend _backend = PluginForegroundServiceBackend();
  static bool Function() _isAndroid = _platformIsAndroid;
  static Future<void> _queue = Future<void>.value();

  /// Whether the service this process started has the camera type; null when
  /// this process has not started one (a running service is then an orphan).
  static bool? _startedWithCamera;

  static bool _platformIsAndroid() => Platform.isAndroid;

  @visibleForTesting
  static void debugReset({required ForegroundServiceBackend backend, required bool Function() isAndroid}) {
    _backend = backend;
    _isAndroid = isAndroid;
    _queue = Future<void>.value();
    _startedWithCamera = null;
  }

  static Future<void> _serial(String what, Future<void> Function() op) {
    final next = _queue.then((_) => op()).catchError((Object e) {
      debugPrint('📞 call foreground service $what failed: $e');
    });
    _queue = next;
    return next;
  }

  static Future<void> start({
    required bool video,
    required String title,
    required String text,
    required String channelName,
    required String channelDescription,
  }) {
    if (!_isAndroid()) return Future<void>.value();
    return _serial('start', () async {
      final running = await _backend.isRunning();
      if (running && _startedWithCamera == video) {
        await _backend.update(title: title, text: text);
        return;
      }
      if (running) {
        _startedWithCamera = null;
        await _backend.stop();
      }
      await _backend.start(
        camera: video,
        title: title,
        text: text,
        channelName: channelName,
        channelDescription: channelDescription,
      );
      _startedWithCamera = video;
    });
  }

  static Future<void> stop() {
    if (!_isAndroid()) return Future<void>.value();
    return _serial('stop', () async {
      _startedWithCamera = null;
      if (await _backend.isRunning()) await _backend.stop();
    });
  }
}
