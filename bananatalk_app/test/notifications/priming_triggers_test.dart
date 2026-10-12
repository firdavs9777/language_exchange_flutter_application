import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/community/first_session/first_message_reporter.dart';
import 'package:bananatalk_app/widgets/notifications/notification_priming_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('result mapping', () {
    expect(primeResultFor(accepted: true, granted: true), 'granted');
    expect(primeResultFor(accepted: true, granted: false), 'declined');
    expect(primeResultFor(accepted: false, granted: false), 'later');
    expect(primeResultFor(accepted: null, granted: false), 'later');
  });

  group('isLiveIncoming', () {
    final opened = DateTime.utc(2026, 10, 12, 10);
    bool live({String id = 'n', String sender = 'them', String at = '2026-10-12T10:00:05Z'}) =>
        isLiveIncoming(
          beforeIds: {'old'},
          id: id,
          senderId: sender,
          me: 'me',
          createdAt: at,
          openedAt: opened,
        );
    test('a new partner message after open is live', () => expect(live(), isTrue));
    test('history is not', () => expect(live(at: '2026-10-11T09:00:00Z'), isFalse));
    test('my own message is not', () => expect(live(sender: 'me'), isFalse));
    test('an already-listed id is not', () => expect(live(id: 'old'), isFalse));
  });

  test('the first send primes once with trigger first_message_sent', () async {
    SharedPreferences.setMockInitialValues({});
    final triggers = <String>[];
    primeAfterFirstMessage = (t) async => triggers.add(t);
    await reportFirstMessageIfFirst();
    await reportFirstMessageIfFirst();
    expect(triggers, ['first_message_sent']);
  });

  test('call sites carry their triggers; chat open no longer primes', () {
    final chat = File('lib/pages/chat/conversation/chat_conversation_screen.dart')
        .readAsStringSync();
    expect(chat.contains("trigger: 'first_message_received'"), isTrue);
    expect(chat.contains('if (mounted) maybePrimeNotifications(context);'), isFalse);
    expect(File('lib/pages/community/tabs/matches_tab.dart')
        .readAsStringSync()
        .contains('primeNotifications = primeAfterFirstMatches'), isTrue);
    expect(File('lib/pages/community/tabs/waves_tab.dart')
        .readAsStringSync()
        .contains('primeNotifications = primeAfterFirstWave'), isTrue);
    expect(File('lib/widgets/notifications/notification_priming_sheet.dart')
        .readAsStringSync()
        .contains('PopupBudget.tryConsume()'), isTrue);
  });
}
