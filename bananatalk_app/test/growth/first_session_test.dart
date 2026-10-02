import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:bananatalk_app/pages/community/tabs/matches_tab.dart';
import 'package:bananatalk_app/pages/community/tabs/partner_discovery_tab.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/daily_matches_provider.dart';
import 'package:bananatalk_app/services/notification_permission.dart';

Future<void> _pump(WidgetTester tester, {required bool matchesLayout}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWith(
          (ref) async => AppConfig.fromJson({
            'matchesLayoutEnabled': matchesLayout,
          }),
        ),
        dailyMatchesProvider.overrideWith(
          (ref) async => DailyMatchesResult.fromJson({'matches': []}),
        ),
        communityPendingSubTabProvider.overrideWith(
          (ref) => communityMatchesSubTab,
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: CommunityMain(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('flag on + matches sub-tab request -> MatchesTab visible',
      (tester) async {
    await _pump(tester, matchesLayout: true);
    expect(find.byType(MatchesTab), findsOneWidget);
    expect(find.byType(PartnerDiscoveryTab), findsNothing);
  });

  testWidgets('flag off + same request -> legacy index 0 is Partners',
      (tester) async {
    await _pump(tester, matchesLayout: false);
    expect(find.byType(PartnerDiscoveryTab), findsOneWidget);
    expect(find.byType(MatchesTab), findsNothing);
  });

  group('homeRouteForNewUser', () {
    test('flag on -> Community tab', () {
      expect(homeRouteForNewUser(matchesLayoutEnabled: true), '/tabs/1');
    });
    test('flag off -> today\'s /home', () {
      expect(homeRouteForNewUser(matchesLayoutEnabled: false), '/home');
    });
  });

  group('shouldPrimeNotifications', () {
    test('only ask / upgrade prime', () {
      expect(shouldPrimeNotifications(NotificationAction.ask), isTrue);
      expect(shouldPrimeNotifications(NotificationAction.upgrade), isTrue);
    });
    test('none / recover / null never prime', () {
      expect(shouldPrimeNotifications(NotificationAction.none), isFalse);
      expect(shouldPrimeNotifications(NotificationAction.recover), isFalse);
      expect(shouldPrimeNotifications(null), isFalse);
    });
  });
}
