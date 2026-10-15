import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/tutor/tutor_session.dart';
import 'package:bananatalk_app/pages/ai/tutor/tutor_chat_screen.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';

class _FakeTutorService implements TutorService {
  bool failStart;
  bool failSend;
  int sends = 0;
  _FakeTutorService({this.failStart = false, this.failSend = false});

  @override
  Future<TutorSession> startSession() async {
    if (failStart) throw StateError('offline');
    return TutorSession(
      id: 's1',
      persona: 'friendly',
      messages: const [],
      startedAt: DateTime(2026, 10, 14),
    );
  }

  @override
  Future<TutorMessage> sendMessage(String sessionId, String content) async {
    sends++;
    if (failSend) throw StateError('network');
    return TutorMessage(
      role: 'assistant',
      content: 'reply to $content',
      messageType: 'text',
      payload: null,
      createdAt: DateTime(2026, 10, 14),
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a session that fails to start shows a retry, not a dead input',
      (tester) async {
    final svc = _FakeTutorService(failStart: true);
    await tester.pumpWidget(_host(svc));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tutor-start-error')), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    svc.failStart = false;
    await tester.tap(find.byKey(const Key('tutor-start-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tutor-start-error')), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  testWidgets('a failed send keeps the text and offers a retry', (tester) async {
    final svc = _FakeTutorService(failSend: true);
    await tester.pumpWidget(_host(svc));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hello tutor');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tutor-send-error')), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'hello tutor');

    svc.failSend = false;
    await tester.tap(find.byKey(const Key('tutor-send-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tutor-send-error')), findsNothing);
    expect(find.text('hello tutor'), findsOneWidget, reason: 'sent once, not duplicated');
    expect(find.text('reply to hello tutor'), findsOneWidget);
  });
}
