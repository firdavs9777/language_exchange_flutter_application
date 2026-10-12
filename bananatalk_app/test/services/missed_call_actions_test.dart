import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/call/missed_call_actions.dart';
import 'package:bananatalk_app/services/notification_api_client.dart';

void main() {
  const data = {'type': 'missed_call', 'callerId': 'u1', 'callType': 'video', 'actions': '["call_back","message"]'};

  test('Call back opens the chat and starts a call of the same type', () {
    expect(missedCallActionRoute(data, 'call_back'), '/chat/u1?call=video');
    expect(missedCallActionRoute({...data, 'callType': 'audio'}, 'call_back'), '/chat/u1?call=audio');
  });

  test('Message opens the chat; plain tap and other types are not ours', () {
    expect(missedCallActionRoute(data, 'message'), '/chat/u1');
    expect(missedCallActionRoute(data, null), isNull);
    expect(missedCallActionRoute({...data, 'type': 'chat_message'}, 'call_back'), isNull);
    expect(missedCallActionRoute({...data, 'callerId': ''}, 'call_back'), isNull);
  });

  test('actions parse from JSON or a comma list; this build declares the capability', () {
    expect(missedCallActions(data), ['call_back', 'message']);
    expect(missedCallActions({'actions': 'call_back,message'}), ['call_back', 'message']);
    expect(missedCallActions({}), isEmpty);
    expect(kCallPushCapabilities, containsAll(['call_cancel', 'missed_call_actions']));
  });

  group('MissedCallTapGate', () {
    late List<String> routes;
    late bool signedIn;
    late Set<String> blocked;
    late MissedCallTapGate gate;

    const push = {
      'type': 'missed_call',
      'callId': 'c1',
      'callUuid': 'uuid-1',
      'callerId': 'u1',
      'callType': 'video',
    };

    setUp(() {
      routes = [];
      signedIn = true;
      blocked = {};
      gate = MissedCallTapGate(
        navigate: routes.add,
        isSignedIn: () => signedIn,
        isBlocked: (id) async => blocked.contains(id),
      );
    });

    test('only missed_call taps with a caller are taken', () {
      expect(gate.submit({...push, 'type': 'chat_message'}, null), isFalse);
      expect(gate.submit({...push, 'callerId': ''}, 'call_back'), isFalse);
      expect(gate.submit(push, 'call_back'), isTrue);
    });

    test('a cold-start tap waits for the splash, then routes once', () async {
      gate.submit(push, 'call_back');
      await pumpEventQueue();
      expect(routes, isEmpty, reason: 'never routes over the splash');

      gate.settle();
      await pumpEventQueue();
      expect(routes, ['/chat/u1?call=video']);

      gate.settle();
      await pumpEventQueue();
      expect(routes, hasLength(1));
    });

    test('the same notification arriving three ways fires its action once', () async {
      gate.settle();
      // Local-notification action, getInitialMessage (plain) and
      // onMessageOpenedApp (plain) for the same call.
      gate.submit(push, 'call_back');
      gate.submit(push, null);
      gate.submit(push, null);
      gate.submit(push, 'call_back');
      await pumpEventQueue();
      expect(routes, ['/chat/u1?call=video']);
    });

    test('the native copy (callId only, no type extras) dedupes with the push', () async {
      gate.settle();
      gate.submit({'type': 'missed_call', 'callId': 'c1', 'callerId': 'u1', 'callType': 'video'}, 'call_back');
      gate.submit(push, 'call_back');
      await pumpEventQueue();
      expect(routes, hasLength(1));
    });

    test('an action beats a plain tap still waiting for the splash', () async {
      gate.submit(push, null);
      gate.submit(push, 'message');
      gate.settle();
      await pumpEventQueue();
      expect(routes, ['/chat/u1']);

      routes.clear();
      final other = MissedCallTapGate(
        navigate: routes.add,
        isSignedIn: () => true,
        isBlocked: (_) async => false,
      );
      other.submit(push, 'call_back');
      other.submit(push, null);
      other.settle();
      await pumpEventQueue();
      expect(routes, ['/chat/u1?call=video'], reason: 'a later plain tap never downgrades the action');
    });

    test('a different call is a different tap', () async {
      gate.settle();
      gate.submit(push, 'call_back');
      gate.submit({...push, 'callId': 'c2', 'callUuid': 'uuid-2'}, 'message');
      await pumpEventQueue();
      expect(routes, ['/chat/u1?call=video', '/chat/u1']);
    });

    test('a plain tap opens the chat', () async {
      gate.settle();
      gate.submit(push, null);
      await pumpEventQueue();
      expect(routes, ['/chat/u1']);
    });

    test('signed out: nothing beyond opening the app', () async {
      signedIn = false;
      gate.submit(push, 'call_back');
      gate.settle();
      await pumpEventQueue();
      expect(routes, isEmpty);
    });

    test('a blocked caller: nothing beyond opening the app', () async {
      blocked = {'u1'};
      gate.settle();
      gate.submit(push, 'call_back');
      gate.submit({...push, 'callId': 'c2'}, 'message');
      gate.submit({...push, 'callId': 'c3'}, null);
      await pumpEventQueue();
      expect(routes, isEmpty);
    });

    test('a block lookup that fails or hangs still routes (the server refuses blocked calls)', () async {
      final failing = MissedCallTapGate(
        navigate: routes.add,
        isSignedIn: () => true,
        isBlocked: (_) async => throw StateError('offline'),
      );
      failing.settle();
      failing.submit(push, 'call_back');
      await pumpEventQueue();
      expect(routes, ['/chat/u1?call=video']);

      routes.clear();
      final hanging = MissedCallTapGate(
        navigate: routes.add,
        isSignedIn: () => true,
        isBlocked: (_) => Completer<bool>().future,
        blockLookupTimeout: const Duration(milliseconds: 10),
      );
      hanging.settle();
      hanging.submit(push, 'message');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(routes, ['/chat/u1']);
    });

    test('a navigation error is swallowed', () async {
      final saved = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {};
      addTearDown(() => debugPrint = saved);
      final throwing = MissedCallTapGate(
        navigate: (_) => throw StateError('no router'),
        isSignedIn: () => true,
        isBlocked: (_) async => false,
      );
      throwing.settle();
      expect(() => throwing.submit(push, 'call_back'), returnsNormally);
      await pumpEventQueue();
    });
  });

  group('missedCallNotificationContent', () {
    test('uses the server title and body', () {
      final c = missedCallNotificationContent(
        {'title': 'Missed video call', 'body': 'Ana called you', 'callerName': 'Ana'},
        fallbackTitle: 'Missed Call',
      );
      expect(c.title, 'Missed video call');
      expect(c.body, 'Ana called you');
    });

    test('falls back to a localized title and the caller name', () {
      final c = missedCallNotificationContent({'callerName': 'Ana'}, fallbackTitle: 'Missed Call');
      expect(c.title, 'Missed Call');
      expect(c.body, 'Ana');
    });

    test('a stable id per call, so a repeat replaces instead of stacking', () {
      expect(missedCallNotificationId({'callId': 'c1'}), missedCallNotificationId({'callId': 'c1'}));
      expect(missedCallNotificationId({'callId': 'c1'}), isNot(missedCallNotificationId({'callId': 'c2'})));
      expect(missedCallNotificationId({}), isNonNegative);
    });
  });
}
