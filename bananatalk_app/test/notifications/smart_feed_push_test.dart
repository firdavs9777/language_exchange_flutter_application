import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/create/compose_from_prompt_screen.dart';
import 'package:bananatalk_app/pages/moments/moment_detail_wrapper.dart';
import 'package:bananatalk_app/services/notification_router.dart';
import 'package:bananatalk_app/pages/moments/create/create_moment.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeMoments extends MomentsService {
  _FakeMoments(this.prompt);
  final Map<String, dynamic> prompt;
  @override
  Future<Map<String, dynamic>> getPromptOfDay({String? language}) async => prompt;
}

Widget _routed(GoRouter router, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

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
              loadMoment: (_) async => throw MomentNotFoundException(),
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

  group('MomentDetailWrapper on an unreachable server', () {
    testWidgets('keeps the error page and does not claim not found', (t) async {
      final router = GoRouter(
        initialLocation: '/moment/m1',
        routes: [
          GoRoute(
            path: '/moment/:momentId',
            builder: (_, s) => MomentDetailWrapper(
              momentId: 'm1',
              loadMoment: (_) async => throw Exception('SocketException'),
            ),
          ),
          GoRoute(
            path: '/tabs/:index',
            builder: (_, s) => const Scaffold(body: Text('tab')),
          ),
        ],
      );
      await t.pumpWidget(_routed(router));
      await t.pumpAndSettle();
      final l10n = AppLocalizations.of(t.element(find.byType(MomentDetailWrapper)))!;
      expect(find.text(l10n.momentFailedToLoad), findsOneWidget);
      expect(find.text(l10n.goBack), findsOneWidget);
      expect(find.text(l10n.momentNotFound), findsNothing);
      expect(find.text('tab'), findsNothing);
    });
  });

  group('ComposeFromPromptScreen', () {
    testWidgets('prefills from a fresh service answer, not the stale cached provider', (t) async {
      final router = GoRouter(
        initialLocation: '/moments/compose?promptId=today',
        routes: [
          GoRoute(
            path: '/moments/compose',
            builder: (_, s) => ComposeFromPromptScreen(
              promptId: s.uri.queryParameters['promptId'],
            ),
          ),
        ],
      );
      await t.pumpWidget(_routed(router, overrides: [
        authServiceProvider.overrideWith((ref) => AuthService()..isLoggedIn = true),
        momentsServiceProvider.overrideWithValue(
          _FakeMoments({'promptId': 'today', 'text': 'Fresh prompt'}),
        ),
        promptOfDayProvider.overrideWith(
          (ref) async => {'promptId': 'yesterday', 'text': 'Stale prompt'},
        ),
      ]));
      // Prime the stale cache first, as an app alive since yesterday would.
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      final screen = t.widget<CreateMoment>(find.byType(CreateMoment));
      expect(screen.prefillPromptId, 'today');
      expect(screen.prefillPrompt, 'Fresh prompt');
    });

    GoRouter composeRouter() => GoRouter(
          initialLocation: '/moments/compose?promptId=today',
          routes: [
            GoRoute(
              path: '/moments/compose',
              builder: (_, s) => ComposeFromPromptScreen(
                promptId: s.uri.queryParameters['promptId'],
              ),
            ),
            GoRoute(path: '/login', builder: (_, __) => const Text('login')),
          ],
        );

    testWidgets(
        'a stored token opens the composer before the token check finishes',
        (t) async {
      // Cold start from the push: the token is on disk, but the in-memory
      // flag waits for the network validation.
      SharedPreferences.setMockInitialValues({'token': 'stored'});
      await t.pumpWidget(_routed(composeRouter(), overrides: [
        authServiceProvider.overrideWith((ref) => AuthService()..isLoggedIn = false),
        momentsServiceProvider.overrideWithValue(
          _FakeMoments({'promptId': 'today', 'text': 'Fresh prompt'}),
        ),
      ]));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.text('login'), findsNothing);
      expect(find.byType(CreateMoment), findsOneWidget);
    });

    testWidgets('no stored token goes to login', (t) async {
      SharedPreferences.setMockInitialValues({});
      await t.pumpWidget(_routed(composeRouter(), overrides: [
        authServiceProvider.overrideWith((ref) => AuthService()..isLoggedIn = false),
        momentsServiceProvider.overrideWithValue(
          _FakeMoments({'promptId': 'today', 'text': 'Fresh prompt'}),
        ),
      ]));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.text('login'), findsOneWidget);
      expect(find.byType(CreateMoment), findsNothing);
    });
  });
}
