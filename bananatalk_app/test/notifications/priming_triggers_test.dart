import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/call_manager.dart';
import 'package:bananatalk_app/services/launch_modal_coordinator.dart';
import 'package:bananatalk_app/services/notification_permission.dart';
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:bananatalk_app/pages/community/first_session/first_message_reporter.dart';
import 'package:bananatalk_app/widgets/notifications/notification_priming_sheet.dart';

import '../helpers/call_fakes.dart';

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
    bool live({
      String id = 'n',
      String sender = 'them',
      String at = '2026-10-12T10:00:05Z',
    }) => isLiveIncoming(
      beforeIds: {'old'},
      id: id,
      senderId: sender,
      me: 'me',
      createdAt: at,
      openedAt: opened,
    );
    test(
      'a new partner message after open is live',
      () => expect(live(), isTrue),
    );
    test(
      'history is not',
      () => expect(live(at: '2026-10-11T09:00:00Z'), isFalse),
    );
    test('my own message is not', () => expect(live(sender: 'me'), isFalse));
    test('an already-listed id is not', () => expect(live(id: 'old'), isFalse));
  });

  group('chat baseline', () {
    final opened = DateTime.utc(2026, 10, 12, 10);
    ({String id, String senderId, String createdAt}) msg(
      String id,
      String at, {
      String sender = 'them',
    }) => (id: id, senderId: sender, createdAt: at);
    bool live(
      bool baseline,
      Set<String> before,
      List<({String id, String senderId, String createdAt})> next,
    ) => shouldTreatAsLive(
      baselineSet: baseline,
      beforeIds: before,
      next: next,
      me: 'me',
      openedAt: opened,
    );

    test('empty chat: load completes, then the first reply primes', () {
      expect(
        isHistoryLoadComplete(previousLoading: true, nextLoading: false),
        isTrue,
      );
      expect(live(true, {}, [msg('a', '2026-10-12T10:00:03Z')]), isTrue);
    });
    test('history load (even a fresh message) never primes', () {
      expect(live(false, {}, [msg('a', '2026-10-12T10:00:03Z')]), isFalse);
    });
    test('history, then a new live message, primes', () {
      final hist = msg('h', '2026-10-12T09:59:58Z');
      expect(live(true, {'h'}, [hist]), isFalse);
      expect(
        live(true, {'h'}, [hist, msg('n', '2026-10-12T10:00:20Z')]),
        isTrue,
      );
    });
    test('state changes that are not a load completion are no baseline', () {
      expect(
        isHistoryLoadComplete(previousLoading: false, nextLoading: false),
        isFalse,
      );
      expect(
        isHistoryLoadComplete(previousLoading: true, nextLoading: true),
        isFalse,
      );
    });
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
    final chat = File(
      'lib/pages/chat/conversation/chat_conversation_screen.dart',
    ).readAsStringSync();
    expect(chat.contains("trigger: 'first_message_received'"), isTrue);
    expect(
      chat.contains('if (mounted) maybePrimeNotifications(context);'),
      isFalse,
    );
    expect(
      File('lib/pages/community/tabs/matches_tab.dart')
          .readAsStringSync()
          .contains('primeNotifications = primeAfterFirstMatches'),
      isTrue,
    );
    expect(
      File(
        'lib/pages/community/tabs/waves_tab.dart',
      ).readAsStringSync().contains('primeNotifications = primeAfterFirstWave'),
      isTrue,
    );
    expect(
      File(
        'lib/widgets/notifications/notification_priming_sheet.dart',
      ).readAsStringSync().contains('PopupBudget.tryConsume()'),
      isTrue,
    );
  });

  group('maybePrimeNotifications (behaviour)', () {
    late CallManager originalCalls;
    late List<String> events;

    setUp(() {
      originalCalls = CallManager();
      PopupBudget.debugReset();
      events = [];
      AnalyticsService.debugLogSink = (n, p) => events.add(n);
      NotificationService().debugSetPendingAction(NotificationAction.ask);
    });
    tearDown(() {
      CallManager.debugSetInstance(originalCalls);
      originalCalls.currentCall = null;
      PopupBudget.debugReset();
      AnalyticsService.debugLogSink = null;
      NotificationService().debugSetPendingAction(null);
    });

    Future<BuildContext> pumpHost(WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (c) {
              ctx = c;
              return const Scaffold();
            },
          ),
        ),
      );
      return ctx;
    }

    testWidgets('eligible: sheet shows, budget spent, shown event logged', (
      tester,
    ) async {
      final ctx = await pumpHost(tester);
      maybePrimeNotifications(ctx, trigger: 'first_wave').ignore();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(PopupBudget.spent, isTrue);
      expect(events, contains('notification_prime_shown'));
    });

    testWidgets('budget already spent: no sheet', (tester) async {
      PopupBudget.tryConsume();
      final ctx = await pumpHost(tester);
      maybePrimeNotifications(ctx).ignore();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(events, isEmpty);
    });

    testWidgets('not eligible (no pending action): no sheet, budget kept', (
      tester,
    ) async {
      NotificationService().debugSetPendingAction(null);
      final ctx = await pumpHost(tester);
      maybePrimeNotifications(ctx).ignore();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(PopupBudget.spent, isFalse);
    });

    testWidgets('not eligible (already granted: none): no sheet, budget kept', (
      tester,
    ) async {
      NotificationService().debugSetPendingAction(NotificationAction.none);
      final ctx = await pumpHost(tester);
      maybePrimeNotifications(ctx).ignore();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(PopupBudget.spent, isFalse);
    });

    testWidgets('active call: no sheet, budget kept', (tester) async {
      final h = CallHarness();
      CallManager.debugSetInstance(h.manager);
      h.manager.currentCall = CallModel(
        callId: 'c',
        userId: 'u',
        userName: 'Ada',
        callType: CallType.audio,
        direction: CallDirection.incoming,
        startTime: DateTime.now(),
      );
      final ctx = await pumpHost(tester);
      maybePrimeNotifications(ctx).ignore();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(PopupBudget.spent, isFalse);
    });
  });
}
