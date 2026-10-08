import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/call_model.dart';

import '../helpers/call_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('video call keeps the screen on until it ends', () async {
    final h = CallHarness();
    await h.startOutgoing(type: CallType.video);
    expect(h.platform.log, contains('wakelock:on'));
    await h.manager.endCall();
    expect(h.platform.log, contains('wakelock:off'));
  });

  test('voice call never takes the wakelock', () async {
    final h = CallHarness();
    await h.startOutgoing(type: CallType.audio);
    await h.manager.endCall();
    expect(h.platform.log, isNot(contains('wakelock:on')));
  });

  test('leaving the app mid-video pauses the camera; coming back resumes it', () async {
    final h = CallHarness();
    await h.startOutgoing(type: CallType.video);
    await h.state('active');
    h.liveKit.onPeerConnected!();
    h.manager.didChangeAppLifecycleState(AppLifecycleState.inactive); // CallKit banner etc.
    expect(h.liveKit.cameraCalls, isEmpty);
    h.manager.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(h.liveKit.cameraCalls, [false]);
    h.manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(h.liveKit.cameraCalls, [false, true]);
  });

  test('a camera the user turned off stays off after resume', () async {
    final h = CallHarness();
    await h.startOutgoing(type: CallType.video);
    await h.state('active');
    h.manager.setVideoEnabled(false);
    h.manager.didChangeAppLifecycleState(AppLifecycleState.paused);
    h.manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(h.liveKit.cameraCalls, [false]);
  });
}
