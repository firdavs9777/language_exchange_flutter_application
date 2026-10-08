import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/call_foreground_service.dart';
import 'package:bananatalk_app/services/call/full_screen_intent_prompt.dart';

import '../helpers/call_fakes.dart';

class FakeServiceBackend implements ForegroundServiceBackend {
  final List<String> ops = [];
  bool running = false;
  Completer<void>? startGate;

  @override
  Future<bool> isRunning() async => running;

  @override
  Future<void> start({
    required bool camera,
    required String title,
    required String text,
    required String channelName,
    required String channelDescription,
  }) async {
    ops.add('start:${camera ? 'video' : 'audio'}');
    if (startGate != null) await startGate!.future;
    running = true;
  }

  @override
  Future<void> update({required String title, required String text}) async => ops.add('update');

  @override
  Future<void> stop() async {
    ops.add('stop');
    running = false;
  }
}

Future<void> startService(bool video) => CallForegroundService.start(
      video: video,
      title: 't',
      text: 'x',
      channelName: 'n',
      channelDescription: 'd',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CallForegroundService', () {
    late FakeServiceBackend backend;
    setUp(() {
      backend = FakeServiceBackend();
      CallForegroundService.debugReset(backend: backend, isAndroid: () => true);
    });

    test('a stop issued while the start is in flight runs after it: no orphan', () async {
      backend.startGate = Completer<void>();
      final start = startService(true);
      await pumpEventQueue();
      expect(backend.ops, ['start:video']);
      final stop = CallForegroundService.stop();
      backend.startGate!.complete();
      await Future.wait([start, stop]);
      expect(backend.ops, ['start:video', 'stop']);
      expect(backend.running, isFalse);
    });

    test('a stop requested while the permission check is pending: never started', () async {
      final check = Completer<CallServicePermissions>();
      final start = CallForegroundService.start(
        video: true,
        title: 't',
        text: 'x',
        channelName: 'n',
        channelDescription: 'd',
        permissions: () => check.future,
      );
      final stop = CallForegroundService.stop();
      check.complete((microphone: true, camera: true));
      await Future.wait([start, stop]);
      expect(backend.ops, isEmpty);
      expect(backend.running, isFalse);
    });

    test('permissions decide inside the queue: no mic, no service; no camera, audio only', () async {
      Future<void> withPerms(CallServicePermissions p) => CallForegroundService.start(
            video: true,
            title: 't',
            text: 'x',
            channelName: 'n',
            channelDescription: 'd',
            permissions: () async => p,
          );
      await withPerms((microphone: false, camera: true));
      expect(backend.ops, isEmpty);
      await withPerms((microphone: true, camera: false));
      expect(backend.ops, ['start:audio']);
    });

    test('a start requested before a stop never starts', () async {
      final start = startService(true);
      final stop = CallForegroundService.stop();
      await Future.wait([start, stop]);
      expect(backend.ops, isEmpty);
    });

    test('a new start after a stop still runs', () async {
      backend.startGate = Completer<void>();
      final first = startService(false);
      await pumpEventQueue();
      final stop = CallForegroundService.stop();
      final second = startService(true);
      backend.startGate!.complete();
      await Future.wait([first, stop, second]);
      expect(backend.ops, ['start:audio', 'stop', 'start:video']);
    });

    test('the same types again only update the notification', () async {
      await startService(false);
      await startService(false);
      expect(backend.ops, ['start:audio', 'update']);
    });

    test('different types restart the service with the new types', () async {
      await startService(false);
      await startService(true);
      expect(backend.ops, ['start:audio', 'stop', 'start:video']);
    });

    test('a service left by a previous process is restarted, not reused', () async {
      backend.running = true;
      await startService(false);
      expect(backend.ops, ['stop', 'start:audio']);
    });

    test('stop with nothing running does nothing', () async {
      await CallForegroundService.stop();
      expect(backend.ops, isEmpty);
    });

    test('not Android: nothing happens', () async {
      CallForegroundService.debugReset(backend: backend, isAndroid: () => false);
      await startService(true);
      await CallForegroundService.stop();
      expect(backend.ops, isEmpty);
    });
  });

  test('full-screen intent: ask only on Android, only when missing, only once', () {
    expect(FullScreenIntentPrompt.shouldAsk(isAndroid: true, canUse: false, alreadyAsked: false), isTrue);
    expect(FullScreenIntentPrompt.shouldAsk(isAndroid: true, canUse: true, alreadyAsked: false), isFalse);
    expect(FullScreenIntentPrompt.shouldAsk(isAndroid: true, canUse: false, alreadyAsked: true), isFalse);
    expect(FullScreenIntentPrompt.shouldAsk(isAndroid: false, canUse: false, alreadyAsked: false), isFalse);
  });

  test('the "asked" flag persists', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await FullScreenIntentPrompt.alreadyAsked(), isFalse);
    await FullScreenIntentPrompt.markAsked();
    expect(await FullScreenIntentPrompt.alreadyAsked(), isTrue);
  });

  test('foreground service runs from media-up to _finish', () async {
    final h = CallHarness();
    await h.startOutgoing(type: CallType.video);
    expect(h.platform.log, contains('service:start:video'));
    await h.manager.endCall();
    expect(h.platform.log, contains('service:stop'));
  });

  test('the full-screen-intent prompt hook runs after incoming calls only', () async {
    final h = CallHarness();
    await h.startOutgoing();
    await h.manager.endCall();
    expect(h.afterIncomingCalls, 0);
    // A new call id: the finished outgoing call-1 is remembered and ignored.
    await h.manager.handleIncoming(CallHarness.incomingPayload(callId: 'call-2'));
    expect(h.manager.currentCall?.callId, 'call-2');
    await h.manager.rejectCall();
    expect(h.afterIncomingCalls, 1);
  });

  test('media up while the app is not resumed: the service waits for the next resume', () async {
    final h = CallHarness()..appResumed = false;
    await h.startOutgoing(type: CallType.video);
    expect(h.platform.log.where((e) => e.startsWith('service:start')), isEmpty);
    h.appResumed = true;
    h.manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(h.platform.log, contains('service:start:video'));
    await h.manager.endCall();
  });

  test('a deferred start is dropped when the call ends first', () async {
    final h = CallHarness()..appResumed = false;
    await h.startOutgoing();
    await h.manager.endCall();
    h.appResumed = true;
    h.manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(h.platform.log.where((e) => e.startsWith('service:start')), isEmpty);
  });

  test('an orphaned service is stopped only when there is no call', () async {
    final h = CallHarness();
    h.manager.stopOrphanCallService();
    expect(h.platform.log, ['service:stop']);
    await h.startOutgoing();
    h.platform.log.clear();
    h.manager.stopOrphanCallService();
    expect(h.platform.log, isNot(contains('service:stop')));
    await h.manager.endCall();
  });
}
