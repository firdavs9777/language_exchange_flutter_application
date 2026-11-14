import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/tutor/tutor_session.dart';
import 'package:bananatalk_app/pages/ai/tutor/tutor_chat_screen.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';

/// The first send is refused with `conversation_full`; every later one works.
class _FakeTutorService implements TutorService {
  int sends = 0;
  int starts = 0;
  final List<String> sentTo = [];
  final List<String> ended = [];

  /// Start numbers (1 = the one on opening) that fail.
  final Set<int> failStarts = {};

  /// When set, starts after the first wait for it.
  Completer<void>? startGate;

  /// When set, ending the first conversation throws.
  bool failEnd = false;

  @override
  Future<TutorSession> startSession() async {
    starts++;
    final n = starts;
    if (startGate != null && n > 1) await startGate!.future;
    if (failStarts.contains(n)) throw StateError('offline');
    return TutorSession(
      id: 's$n',
      persona: 'friendly',
      messages: [
        TutorMessage(
          role: 'assistant',
          content: 'greeting $n',
          messageType: 'text',
          payload: null,
          createdAt: DateTime(2026, 11, 14),
        ),
      ],
      startedAt: DateTime(2026, 11, 14),
    );
  }

  @override
  Future<TutorMessage> sendMessage(String sessionId, String content) async {
    sends++;
    sentTo.add(sessionId);
    if (sends == 1) throw const TutorSendRefused('conversation_full');
    return TutorMessage(
      role: 'assistant',
      content: 'reply to $content',
      messageType: 'text',
      payload: null,
      createdAt: DateTime(2026, 11, 14),
    );
  }

  @override
  Future<void> endSession(String sessionId) async {
    ended.add(sessionId);
    if (failEnd && sessionId == 's1') throw StateError('end failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

TutorQuotaInfo _chat({required int remaining, bool unlimited = false}) =>
    TutorQuotaInfo(
      used: 5 - remaining,
      cap: unlimited ? null : 5,
      remaining: unlimited ? null : remaining,
      resetAt: null,
      unlimited: unlimited,
    );

Widget _host(_FakeTutorService svc, {TutorQuotaInfo? chat}) => ProviderScope(
  overrides: [
    tutorServiceProvider.overrideWithValue(svc),
    userProvider.overrideWith((ref) async => throw Exception('offline')),
    tutorQuotaProvider.overrideWithValue(TutorQuotaState(chat: chat)),
    // Coins off: the upgrade sheet's unlock button renders nothing.
    appConfigProvider.overrideWith(
      (ref) async => const AppConfig(
        minVersion: '0',
        latestVersion: '0',
        forceUpdate: false,
        iosUrl: '',
        androidUrl: '',
        releaseNotes: '',
      ),
    ),
  ],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: TutorChatScreen(),
  ),
);

/// Opens the chat and fills the first conversation.
Future<void> _fillConversation(
  WidgetTester tester,
  _FakeTutorService svc, {
  TutorQuotaInfo? chat,
}) async {
  await tester.pumpWidget(_host(svc, chat: chat));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'hello');
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('tutor-conversation-full')), findsOneWidget);
}

final _newConversation = find.byKey(const Key('tutor-new-conversation'));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ending the full conversation (I-1)', () {
    testWidgets('once the new conversation has started, the old one is ended', (
      tester,
    ) async {
      final svc = _FakeTutorService();
      await _fillConversation(tester, svc);
      expect(svc.ended, isEmpty);

      await tester.tap(_newConversation);
      await tester.pumpAndSettle();
      expect(svc.starts, 2);
      expect(find.text('greeting 2'), findsOneWidget);
      expect(svc.ended, ['s1'], reason: 'the full conversation, once');
    });

    testWidgets('not before the new start has answered', (tester) async {
      final svc = _FakeTutorService();
      await _fillConversation(tester, svc);
      svc.startGate = Completer<void>();
      await tester.tap(_newConversation);
      await tester.pump();
      expect(svc.ended, isEmpty, reason: 'the new start is still in flight');
      svc.startGate!.complete();
      await tester.pumpAndSettle();
      expect(svc.ended, ['s1']);
    });

    testWidgets('a failed new start does not end the old conversation', (
      tester,
    ) async {
      final svc = _FakeTutorService()..failStarts.add(2);
      await _fillConversation(tester, svc);
      await tester.tap(_newConversation);
      await tester.pumpAndSettle();
      expect(svc.starts, 2);
      expect(svc.ended, isEmpty);
      expect(find.byKey(const Key('tutor-conversation-full')), findsOneWidget);
    });

    testWidgets('a failed end is never shown', (tester) async {
      final svc = _FakeTutorService()..failEnd = true;
      await _fillConversation(tester, svc);
      await tester.tap(_newConversation);
      await tester.pumpAndSettle();
      expect(svc.ended, ['s1']);
      expect(tester.takeException(), isNull);
      expect(find.text('greeting 2'), findsOneWidget);
      expect(find.byKey(const Key('tutor-send-error')), findsNothing);
      expect(find.byKey(const Key('tutor-start-error')), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('the first conversation of a visit ends nothing', (
      tester,
    ) async {
      final svc = _FakeTutorService();
      await tester.pumpWidget(_host(svc));
      await tester.pumpAndSettle();
      expect(svc.starts, 1);
      expect(svc.ended, isEmpty);
    });
  });

  group('no conversations left today (I-2)', () {
    testWidgets(
      'the button opens the upgrade sheet and keeps the full conversation',
      (tester) async {
        final svc = _FakeTutorService();
        await _fillConversation(tester, svc, chat: _chat(remaining: 0));

        await tester.tap(_newConversation);
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text("You've used today's AI Tutor"), findsOneWidget);
        expect(svc.starts, 1, reason: 'no new session is requested');

        await tester.tap(find.text('Not Now'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        expect(svc.starts, 1);
        expect(svc.ended, isEmpty);
        // The transcript and the notice are still there.
        expect(find.text('greeting 1'), findsOneWidget);
        expect(find.text('hello'), findsOneWidget);
        expect(
          find.byKey(const Key('tutor-conversation-full')),
          findsOneWidget,
        );
      },
    );

    testWidgets('with conversations left it starts a new one as before', (
      tester,
    ) async {
      final svc = _FakeTutorService();
      await _fillConversation(tester, svc, chat: _chat(remaining: 2));
      await tester.tap(_newConversation);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(svc.starts, 2);
      expect(find.text('greeting 2'), findsOneWidget);
    });

    testWidgets('unlimited (VIP) and an unknown allowance start a new one', (
      tester,
    ) async {
      for (final chat in [_chat(remaining: 0, unlimited: true), null]) {
        final svc = _FakeTutorService();
        await _fillConversation(tester, svc, chat: chat);
        await tester.tap(_newConversation);
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing, reason: '$chat');
        expect(svc.starts, 2, reason: '$chat');
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  testWidgets('sending is blocked while a new conversation is starting (M-2)', (
    tester,
  ) async {
    final svc = _FakeTutorService();
    await _fillConversation(tester, svc);
    svc.startGate = Completer<void>();
    await tester.tap(_newConversation);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'too early');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(svc.sends, 1, reason: 'nothing goes to the old, full session');
    expect(
      tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send))
          .onPressed,
      isNull,
    );

    svc.startGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('greeting 2'), findsOneWidget);
    expect(find.byKey(const Key('tutor-conversation-full')), findsNothing);
    // The typed text is still there and now goes to the new conversation.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'too early',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(svc.sentTo, ['s1', 's2']);
    expect(find.text('reply to too early'), findsOneWidget);
  });
}
