import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/tutor/tutor_session.dart';
import 'package:bananatalk_app/pages/ai/tutor/tutor_chat_screen.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/api_client.dart';

/// Scripted tutor service: [sendScript] holds what each send does, in order.
class _FakeTutorService implements TutorService {
  _FakeTutorService(this.sendScript);
  final List<Object> sendScript; // a String reason to refuse, or 'ok'
  int sends = 0;
  int starts = 0;

  @override
  Future<TutorSession> startSession() async {
    starts++;
    return TutorSession(
      id: 's$starts',
      persona: 'friendly',
      messages: const [],
      startedAt: DateTime(2026, 11, 14),
    );
  }

  @override
  Future<TutorMessage> sendMessage(String sessionId, String content) async {
    final step = sendScript[sends.clamp(0, sendScript.length - 1)];
    sends++;
    if (step != 'ok') throw TutorSendRefused(step as String);
    return TutorMessage(
      role: 'assistant',
      content: 'reply to $content',
      messageType: 'text',
      payload: null,
      createdAt: DateTime(2026, 11, 14),
    );
  }

  @override
  Future<void> endSession(String sessionId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Widget _host(_FakeTutorService svc) => ProviderScope(
  overrides: [
    tutorServiceProvider.overrideWithValue(svc),
    userProvider.overrideWith((ref) async => throw Exception('offline')),
  ],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: TutorChatScreen(),
  ),
);

Future<void> _typeAndSend(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pump();
}

http.Response _json(int status, Map<String, dynamic> body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// Sends a 429 `quota_exceeded` with [reason] and returns how many times the
/// global upgrade-sheet hook ran.
Future<({int hookCalls, ApiResponse res})> _quota429(String? reason) async {
  var calls = 0;
  final client = ApiClient();
  final previous = client.onQuotaExceeded;
  client.onQuotaExceeded = (_) => calls++;
  try {
    final res = await http.runWithClient(
      () => client.post('tutor/sessions/s1/message', body: {'content': 'hi'}),
      () => MockClient(
        (_) async => _json(429, {
          'success': false,
          'error': 'quota_exceeded',
          'feature': 'chat',
          'message': 'limit',
          if (reason != null) 'reason': reason,
        }),
      ),
    );
    return (hookCalls: calls, res: res);
  } finally {
    client.onQuotaExceeded = previous;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('global quota hook (the upgrade sheet)', () {
    test(
      'daily_conversations, an unknown reason and no reason all open it',
      () async {
        for (final reason in ['daily_conversations', 'something_new', null]) {
          final r = await _quota429(reason);
          expect(r.hookCalls, 1, reason: 'reason: $reason');
          expect(r.res.quotaError, isNotNull);
          expect(r.res.quotaError!.reason, reason);
        }
      },
    );

    test('conversation_full and conversation_starting never open it', () async {
      for (final reason in ['conversation_full', 'conversation_starting']) {
        final r = await _quota429(reason);
        expect(r.hookCalls, 0, reason: 'reason: $reason');
        expect(r.res.statusCode, 429);
        expect(r.res.quotaError!.reason, reason);
      }
    });
  });

  group('TutorService.sendMessage', () {
    test(
      'turns the two chat reasons into TutorSendRefused, others stay StateError',
      () async {
        for (final reason in ['conversation_full', 'conversation_starting']) {
          final svc = TutorService();
          await http.runWithClient(
            () async {
              await expectLater(
                svc.sendMessage('s1', 'hi'),
                throwsA(
                  isA<TutorSendRefused>().having(
                    (e) => e.reason,
                    'reason',
                    reason,
                  ),
                ),
              );
            },
            () => MockClient(
              (_) async => _json(429, {
                'success': false,
                'error': 'quota_exceeded',
                'feature': 'chat',
                'reason': reason,
              }),
            ),
          );
        }
        final svc = TutorService();
        await http.runWithClient(
          () async {
            await expectLater(
              svc.sendMessage('s1', 'hi'),
              throwsA(isA<StateError>()),
            );
          },
          () => MockClient(
            (_) async => _json(429, {
              'success': false,
              'error': 'quota_exceeded',
              'feature': 'chat',
              'reason': 'daily_conversations',
            }),
          ),
        );
      },
    );
  });

  testWidgets(
    'conversation_full shows the notice and the new-conversation button, not the upgrade sheet',
    (tester) async {
      final svc = _FakeTutorService(['conversation_full']);
      await tester.pumpWidget(_host(svc));
      await tester.pumpAndSettle();

      await _typeAndSend(tester, 'hello');
      await tester.pumpAndSettle();

      expect(find.text('This conversation is full.'), findsOneWidget);
      expect(find.text('Start a new conversation'), findsOneWidget);
      // Not the generic failed banner, and no bottom sheet.
      expect(find.byKey(const Key('tutor-send-error')), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(svc.sends, 1);

      await tester.tap(find.text('Start a new conversation'));
      await tester.pumpAndSettle();
      expect(svc.starts, 2);
      expect(find.text('This conversation is full.'), findsNothing);
    },
  );

  testWidgets(
    'conversation_starting retries once after 2 seconds and then succeeds silently',
    (tester) async {
      final svc = _FakeTutorService(['conversation_starting', 'ok']);
      await tester.pumpWidget(_host(svc));
      await tester.pumpAndSettle();

      await _typeAndSend(tester, 'hello');
      expect(svc.sends, 1);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(svc.sends, 1, reason: 'waits the full 2 seconds');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(svc.sends, 2);
      expect(find.text('reply to hello'), findsOneWidget);
      expect(find.byKey(const Key('tutor-send-error')), findsNothing);
      expect(find.text('This conversation is full.'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    },
  );

  testWidgets(
    'conversation_starting twice shows send-failed, no loop, no upgrade sheet',
    (tester) async {
      final svc = _FakeTutorService(['conversation_starting']);
      await tester.pumpWidget(_host(svc));
      await tester.pumpAndSettle();

      await _typeAndSend(tester, 'hello');
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(svc.sends, 2, reason: 'one retry, never a loop');
      expect(find.byKey(const Key('tutor-send-error')), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      // The text is back in the input.
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'hello',
      );
    },
  );
}
