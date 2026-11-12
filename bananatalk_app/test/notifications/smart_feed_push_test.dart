import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/create/compose_from_prompt_screen.dart';
import 'package:bananatalk_app/pages/moments/moment_detail_wrapper.dart';
import 'package:bananatalk_app/services/notification_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('targetPathForType', () {
    test('moment_needs_feedback opens the moment', () {
      expect(
        NotificationRouter.targetPathForType('moment_needs_feedback', {'momentId': 'm1'}),
        '/moment/m1',
      );
    });

    test('moment_needs_feedback without an id opens the Moments tab', () {
      expect(NotificationRouter.targetPathForType('moment_needs_feedback', {}), '/tabs/3');
      expect(
        NotificationRouter.targetPathForType('moment_needs_feedback', {'momentId': ''}),
        '/tabs/3',
      );
    });

    test('daily_prompt opens the composer with the prompt id', () {
      expect(
        NotificationRouter.targetPathForType('daily_prompt', {'promptId': 'p1', 'language': 'ko'}),
        '/moments/compose?promptId=p1',
      );
    });

    test('daily_prompt without an id opens a plain composer route', () {
      expect(NotificationRouter.targetPathForType('daily_prompt', {}), '/moments/compose');
    });

    test('both push over home', () {
      expect(NotificationRouter.planFor('daily_prompt', {'promptId': 'p1'}).usePushAfterHome, isTrue);
      expect(NotificationRouter.planFor('moment_needs_feedback', {'momentId': 'm'}).usePushAfterHome, isTrue);
    });
  });

  group('promptToPrefill', () {
    final today = {'promptId': 'p1', 'text': 'Describe your day'};
    test('fills in when the id matches', () {
      expect(promptToPrefill(today, 'p1'), (text: 'Describe your day', id: 'p1'));
    });
    test('plain composer on a different id, no id, or no prompt', () {
      expect(promptToPrefill(today, 'p2'), isNull);
      expect(promptToPrefill(today, null), isNull);
      expect(promptToPrefill(null, 'p1'), isNull);
      expect(promptToPrefill({'promptId': 'p1'}, 'p1'), isNull);
    });
  });

  group('MomentDetailWrapper when the moment is gone', () {
    testWidgets('lands on the Moments tab with the not-available snackbar', (t) async {
      final router = GoRouter(
        initialLocation: '/moment/m1',
        routes: [
          GoRoute(
            path: '/moment/:momentId',
            builder: (_, s) => MomentDetailWrapper(
              momentId: s.pathParameters['momentId']!,
              loadMoment: (_) async => throw Exception('Moment not found'),
            ),
          ),
          GoRoute(
            path: '/tabs/:index',
            builder: (_, s) => Scaffold(body: Text('tab ${s.pathParameters['index']}')),
          ),
        ],
      );
      await t.pumpWidget(ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ));
      await t.pumpAndSettle();
      expect(find.text('tab 3'), findsOneWidget);
      expect(find.text('Moment not found'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
