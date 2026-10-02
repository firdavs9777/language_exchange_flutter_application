import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:bananatalk_app/pages/community/tabs/waves_tab.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/daily_matches_provider.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';
import 'package:bananatalk_app/services/notification_router.dart';

Future<ProviderContainer> _pump(WidgetTester tester,
    {required bool matchesLayout, required bool rooms}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWith(
          (ref) async => AppConfig.fromJson({
            'matchesLayoutEnabled': matchesLayout,
            'roomsEnabled': rooms,
          }),
        ),
        dailyMatchesProvider.overrideWith(
          (ref) async => DailyMatchesResult.fromJson({'matches': []}),
        ),
        communityPendingSubTabProvider
            .overrideWith((ref) => communityWavesSubTab),
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
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  return ProviderScope.containerOf(tester.element(find.byType(CommunityMain)));
}

void main() {
  group('targetPathForType', () {
    test('daily_matches -> /tabs/1', () {
      expect(NotificationRouter.targetPathForType('daily_matches', {}),
          '/tabs/1');
    });
    test('lifecycle_online -> chat with userId', () {
      expect(
          NotificationRouter.targetPathForType(
              'lifecycle_online', {'userId': 'u1'}),
          '/chat/u1');
    });
    test('lifecycle_online without userId -> null', () {
      expect(NotificationRouter.targetPathForType('lifecycle_online', {}),
          isNull);
    });
    test('lifecycle_waves -> /tabs/1', () {
      expect(NotificationRouter.targetPathForType('lifecycle_waves', {}),
          '/tabs/1');
    });
  });

  group('communitySubTabForType', () {
    test('maps lifecycle types, null otherwise', () {
      expect(NotificationRouter.communitySubTabForType('daily_matches'),
          communityMatchesSubTab);
      expect(NotificationRouter.communitySubTabForType('lifecycle_waves'),
          communityWavesSubTab);
      expect(NotificationRouter.communitySubTabForType('chat_message'),
          isNull);
    });
  });

  group('deep link parser', () {
    test('community/matches and waves (https + scheme)', () {
      expect(
          routePathFromUri(Uri.parse('https://banatalk.com/community/matches')),
          '/community/matches');
      expect(routePathFromUri(Uri.parse('bananatalk://community/waves')),
          '/community/waves');
    });
    test('community/<id> unchanged', () {
      expect(routePathFromUri(Uri.parse('https://banatalk.com/community/c1')),
          '/community/c1');
    });
  });

  group('pre-set Waves request lands on Waves in every layout', () {
    for (final matches in [true, false]) {
      for (final rooms in [true, false]) {
        testWidgets('matchesLayout=$matches rooms=$rooms', (tester) async {
          final c = await _pump(tester, matchesLayout: matches, rooms: rooms);
          expect(find.byType(WavesTab), findsOneWidget);
          expect(c.read(communityPendingSubTabProvider), isNull);
        });
      }
    }
  });
}
