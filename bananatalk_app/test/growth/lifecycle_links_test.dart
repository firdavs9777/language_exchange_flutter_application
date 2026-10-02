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

  // F1 — the deployed backend lifecycle job sends only `route` (no `type`).
  group('live lifecycle payload (route only)', () {
    String? pathFor(Map<String, dynamic> raw) {
      final data = NotificationRouter.normalizeLifecycleData(raw);
      return NotificationRouter.planFor(
              NotificationRouter.resolveType(data), data)
          .path;
    }

    test('chat/u1 -> /chat/u1', () {
      expect(NotificationRouter.resolveType({'route': 'chat/u1'}),
          'lifecycle_online');
      expect(pathFor({'route': 'chat/u1'}), '/chat/u1');
    });
    test('community/waves -> /tabs/1 + Waves sub-tab', () {
      final type = NotificationRouter.resolveType({'route': 'community/waves'});
      expect(type, 'lifecycle_waves');
      expect(pathFor({'route': 'community/waves'}), '/tabs/1');
      expect(NotificationRouter.communitySubTabForType(type),
          communityWavesSubTab);
    });
    test('community/matches -> /tabs/1 + Matches sub-tab', () {
      final type =
          NotificationRouter.resolveType({'route': 'community/matches'});
      expect(type, 'daily_matches');
      expect(pathFor({'route': 'community/matches'}), '/tabs/1');
      expect(NotificationRouter.communitySubTabForType(type),
          communityMatchesSubTab);
    });
    test('explicit type wins over route', () {
      final raw = <String, dynamic>{
        'type': 'chat_message',
        'senderId': 's1',
        'route': 'community/waves',
      };
      expect(NotificationRouter.resolveType(raw), 'chat_message');
      expect(pathFor(raw), '/chat/s1');
    });
    test('chat/ with empty id -> no crash, home fallback', () {
      final data = NotificationRouter.normalizeLifecycleData({'route': 'chat/'});
      expect(NotificationRouter.resolveType(data), '');
      expect(data.containsKey('userId'), isFalse);
      final plan = NotificationRouter.planFor('', data);
      expect(plan.path, '/home');
      expect(plan.usePushAfterHome, isFalse);
    });
    test('normalize injects type and userId, keeps other fields', () {
      final data = NotificationRouter.normalizeLifecycleData(
          {'route': 'chat/u9', 'notificationId': 'n1'});
      expect(data['type'], 'lifecycle_online');
      expect(data['userId'], 'u9');
      expect(data['notificationId'], 'n1');
    });
  });

  // F2 — sub-tab pushes go straight to /tabs/1 (no hidden /home CommunityMain
  // consuming the request first); detail pushes keep home + push.
  group('planFor', () {
    test('lifecycle_waves is a direct go(/tabs/1)', () {
      final plan = NotificationRouter.planFor(
          'lifecycle_waves', {'route': 'community/waves'});
      expect(plan.path, '/tabs/1');
      expect(plan.usePushAfterHome, isFalse);
    });
    test('daily_matches is a direct go(/tabs/1)', () {
      final plan = NotificationRouter.planFor('daily_matches', {});
      expect(plan.path, '/tabs/1');
      expect(plan.usePushAfterHome, isFalse);
    });
    test('chat_message is home + push', () {
      final plan =
          NotificationRouter.planFor('chat_message', {'senderId': 's'});
      expect(plan.path, '/chat/s');
      expect(plan.usePushAfterHome, isTrue);
    });
    test('lifecycle_online is home + push', () {
      final plan =
          NotificationRouter.planFor('lifecycle_online', {'userId': 'u1'});
      expect(plan.path, '/chat/u1');
      expect(plan.usePushAfterHome, isTrue);
    });
  });

  // Warm app: if the tab shell is already the base route, re-go to it (same
  // page key -> same CommunityMain) instead of building a second shell whose
  // sibling would consume the pending sub-tab first.
  group('subTabGoLocation', () {
    test('reuses an existing shell location', () {
      expect(NotificationRouter.subTabGoLocation('/home'), '/home');
      expect(NotificationRouter.subTabGoLocation('/tabs/3'), '/tabs/3');
    });
    test('otherwise opens /tabs/1', () {
      expect(NotificationRouter.subTabGoLocation(null), '/tabs/1');
      expect(NotificationRouter.subTabGoLocation('/splash'), '/tabs/1');
      expect(NotificationRouter.subTabGoLocation('/login'), '/tabs/1');
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
