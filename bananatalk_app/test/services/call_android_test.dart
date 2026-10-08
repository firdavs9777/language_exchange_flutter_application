import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/call/full_screen_intent_prompt.dart';

import '../helpers/call_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
