import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/profile/visitors_screen.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/router/app_router.dart';

const _cfg = AppConfig(
  minVersion: '0',
  latestVersion: '0',
  forceUpdate: false,
  iosUrl: '',
  androidUrl: '',
  releaseNotes: '',
);

void main() {
  Future<Map<String, dynamic>> fetch({
    required String userId,
    int limit = 20,
    int page = 1,
    bool reveal = false,
    bool seen = false,
  }) async => {'success': true, 'visitors': const []};

  Widget app(Future<String?> Function() saved) {
    final router = GoRouter(
      initialLocation: '/visitors',
      routes: [
        GoRoute(
          path: '/visitors',
          builder: (_, __) =>
              VisitorsLanding(savedUserId: saved, fetchVisitors: fetch),
        ),
        GoRoute(
          path: '/tabs/:index',
          builder: (_, s) => Text('tabs ${s.pathParameters['index']}'),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        userProvider.overrideWith(
          (ref) async => throw Exception('offline'),
        ),
        appConfigProvider.overrideWith((ref) async => _cfg),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  testWidgets(
    'masked push opened offline: the list opens for the saved user id, not a blank screen',
    (tester) async {
      await tester.pumpWidget(app(() async => 'me'));
      await tester.pumpAndSettle();
      final screen = tester.widget<ProfileVisitorsScreen>(
        find.byType(ProfileVisitorsScreen),
      );
      expect(screen.userId, 'me');
    },
  );

  testWidgets('offline with no saved id: goes to the tabs', (tester) async {
    await tester.pumpWidget(app(() async => null));
    await tester.pumpAndSettle();
    expect(find.text('tabs 0'), findsOneWidget);
  });
}
