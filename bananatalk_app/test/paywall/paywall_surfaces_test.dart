import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/boost.dart';
import 'package:bananatalk_app/models/coin_transaction.dart';
import 'package:bananatalk_app/models/tutor/tutor_memory.dart';
import 'package:bananatalk_app/pages/chat/dialogs/translate_unlock_sheet.dart';
import 'package:bananatalk_app/pages/coins/boost_screen.dart';
import 'package:bananatalk_app/pages/coins/coin_shop_screen.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/pages/profile/visitors_screen.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/boost_api_client.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/services/paywall/paywall_flow.dart';
import 'package:bananatalk_app/services/paywall/paywall_tracker.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:bananatalk_app/widgets/masked_person_tile.dart';
import 'package:bananatalk_app/widgets/study/study_upgrade_sheet.dart';
import 'package:bananatalk_app/widgets/tutor/persona_upgrade_sheet.dart';

class _CoinApi extends CoinApiClient {
  _CoinApi({this.statusCode = 200});
  final int statusCode;
  @override
  Future<ApiResponse> unlock(String featureKey) async => ApiResponse(
    success: statusCode == 200,
    statusCode: statusCode,
    error: statusCode == 200 ? null : 'Not enough coins',
  );

  @override
  Future<int> getBalance() async => 500;
}

class _BoostClient implements BoostApiClient {
  _BoostClient({this.error});
  final BoostError? error;
  Boost? active;

  @override
  Future<Boost> purchaseProfileBoost() async {
    if (error != null) throw BoostException(error!);
    return active = Boost(
      id: 'b1',
      kind: 'profile',
      startsAt: DateTime.now(),
      endsAt: DateTime.now().add(const Duration(hours: 23)),
      impressions: 0,
      coinsSpent: 150,
      status: 'active',
    );
  }

  @override
  Future<Boost?> getActive() async => active;

  @override
  Future<List<Boost>> getHistory() async => const [];
}

const _cfg = AppConfig(
  minVersion: '0',
  latestVersion: '0',
  forceUpdate: false,
  iosUrl: '',
  androidUrl: '',
  releaseNotes: '',
  coinsEnabled: true,
  boostsEnabled: true,
);

typedef _Logged = ({
  String placement,
  String action,
  String flowId,
  String? detail,
});

void main() {
  late List<_Logged> logged;

  List<String> actions() => [for (final l in logged) l.action];

  setUp(() {
    logged = [];
    paywallLogSpy = (flow, action, detail) => logged.add((
      placement: flow.placement,
      action: action,
      flowId: flow.flowId,
      detail: detail,
    ));
  });
  tearDown(() => paywallLogSpy = null);

  Widget host(
    Widget home, {
    int unlockStatus = 200,
    List<Override> extra = const [],
  }) => ProviderScope(
    overrides: [
      appConfigProvider.overrideWith((ref) async => _cfg),
      coinApiClientProvider.overrideWithValue(
        _CoinApi(statusCode: unlockStatus),
      ),
      coinUnlockCatalogProvider.overrideWith(
        (ref) async => const {
          'moment': CoinUnlockEntry(featureKey: 'moment', cost: 20, grant: 1),
          'wave': CoinUnlockEntry(featureKey: 'wave', cost: 10, grant: 1),
          'translation': CoinUnlockEntry(
            featureKey: 'translation',
            cost: 10,
            grant: 5,
          ),
          'chat': CoinUnlockEntry(featureKey: 'chat', cost: 80, grant: 3),
          'who_waved': CoinUnlockEntry(
            featureKey: 'who_waved',
            cost: 60,
            grant: 1,
          ),
        },
      ),
      coinBalanceProvider.overrideWith((ref) async => 500),
      ...extra,
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  Widget launcher(void Function(BuildContext) open) => Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => open(context),
        child: const Text('open'),
      ),
    ),
  );

  Future<void> openIt(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> openLimit(
    WidgetTester tester,
    String type, {
    int unlockStatus = 200,
  }) async {
    await tester.pumpWidget(
      host(
        launcher(
          (c) => LimitExceededDialog.show(
            context: c,
            limitType: type,
            userId: 'u1',
          ),
        ),
        unlockStatus: unlockStatus,
      ),
    );
    await openIt(tester);
  }

  group('limit dialog', () {
    testWidgets('limit dialog: shown, then dismissed on "Maybe later"', (
      tester,
    ) async {
      await openLimit(tester, 'moment');
      expect(actions(), ['shown']);
      await tester.tap(find.text('Maybe Later'));
      await tester.pumpAndSettle();
      expect(actions(), ['shown', 'dismissed']);
      expect(logged.map((l) => l.placement).toSet(), {'moment_cap'});
      expect(logged.map((l) => l.flowId).toSet().length, 1);
    });

    testWidgets(
      'limit dialog: VIP button logs cta_vip and no dismissed, placement follows the limit type',
      (tester) async {
        await openLimit(tester, 'comment');
        await tester.tap(find.text('Upgrade to VIP'));
        await tester.pumpAndSettle();
        expect(actions().take(2), ['shown', 'cta_vip']);
        expect(actions(), isNot(contains('dismissed')));
        expect(logged.first.placement, 'comment_cap');
        expect(logged[1].placement, 'comment_cap');
        expect(
          logged[0].flowId,
          logged[1].flowId,
          reason: 'one showing is one flow',
        );
      },
    );

    testWidgets('wave limit dialog reports wave_cap', (tester) async {
      await openLimit(tester, 'wave');
      expect(logged.single.action, 'shown');
      expect(logged.single.placement, 'wave_cap');
    });

    testWidgets(
      'unlock from the dialog: cta_coins then unlock_succeeded with the feature key, no dismissed',
      (tester) async {
        await openLimit(tester, 'moment');
        await tester.tap(find.byType(UnlockCta));
        await tester.pumpAndSettle();
        expect(actions(), ['shown', 'cta_coins', 'unlock_succeeded']);
        expect(logged.last.detail, 'moment');
        expect(logged.map((l) => l.flowId).toSet().length, 1);
        expect(find.byType(LimitExceededDialog), findsNothing);
      },
    );
  });

  group('UnlockCta', () {
    testWidgets(
      'success logs cta_coins then unlock_succeeded with the feature key',
      (tester) async {
        const flow = PaywallFlow(
          placement: PaywallPlacement.momentCap,
          flowId: 'f-ok',
        );
        await tester.pumpWidget(
          host(
            const Scaffold(
              body: UnlockCta(featureKey: 'moment', flow: flow),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();
        expect(actions(), ['cta_coins', 'unlock_succeeded']);
        expect(logged.last.detail, 'moment');
        expect(logged.every((l) => l.flowId == 'f-ok'), isTrue);
      },
    );

    testWidgets(
      '402 opens the shop as not_enough_coins with the same flow id',
      (tester) async {
        const flow = PaywallFlow(
          placement: PaywallPlacement.translationCap,
          flowId: 'f-402',
        );
        await tester.pumpWidget(
          host(
            const Scaffold(
              body: UnlockCta(featureKey: 'translation', flow: flow),
            ),
            unlockStatus: 402,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Get more coins'));
        await tester.pumpAndSettle();
        expect(find.byType(CoinShopScreen), findsOneWidget);
        expect(actions(), ['cta_coins', 'cta_coins', 'shop_viewed']);
        expect(logged[0].placement, 'translation_cap');
        expect(logged[1].placement, 'not_enough_coins');
        expect(logged[2].placement, 'not_enough_coins');
        expect(logged.every((l) => l.flowId == 'f-402'), isTrue);
        expect(actions(), isNot(contains('unlock_succeeded')));
      },
    );

    testWidgets('without a flow it starts one, placement by feature key', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const Scaffold(body: UnlockCta(featureKey: 'wave'))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(logged.map((l) => l.placement).toSet(), {'wave_cap'});
      expect(logged.map((l) => l.flowId).toSet().length, 1);
    });

    test('placement by feature key', () {
      expect(
        {
          for (final k in [
            'translation',
            'moment',
            'dm',
            'wave',
            'extra_matches',
            'who_waved',
            'chat',
            'roleplay',
            'story',
            'photo',
            'pronunciation',
            'nope',
          ])
            k: paywallPlacementForFeature(k),
        },
        {
          'translation': 'translation_cap',
          'moment': 'moment_cap',
          'dm': 'dm_cap',
          'wave': 'wave_cap',
          'extra_matches': 'extra_matches',
          'who_waved': 'visitor_list',
          'chat': 'tutor_quota',
          'roleplay': 'tutor_quota',
          'story': 'tutor_quota',
          'photo': 'tutor_quota',
          'pronunciation': 'tutor_quota',
          'nope': 'other',
        },
      );
    });
  });

  // The watch-ad button needs a loaded AdMob ad, which a widget test cannot
  // produce; the outcome-to-event mapping is tested directly.
  test(
    'watch-ad result: unlocked logs unlock_succeeded ad:<feature>; other results log nothing',
    () {
      const flow = PaywallFlow(
        placement: PaywallPlacement.waveCap,
        flowId: 'f-ad',
      );
      reportRewardedResult(flow, 'rewarded', 'wave');
      reportRewardedResult(flow, 'limit', 'wave');
      expect(logged, isEmpty);
      reportRewardedResult(flow, 'unlocked', 'wave');
      expect(actions(), ['unlock_succeeded']);
      expect(logged.single.detail, 'ad:wave');
      expect(logged.single.flowId, 'f-ad');
    },
  );

  group('sheets', () {
    testWidgets(
      'persona sheet logs shown once, VIP is cta_vip without dismissed',
      (tester) async {
        await tester.pumpWidget(
          host(
            launcher(
              (c) => showModalBottomSheet<void>(
                context: c,
                isScrollControlled: true,
                builder: (_) => const PersonaUpgradeSheet(triggerChip: 'chat'),
              ),
            ),
            extra: [
              tutorMemoryProvider.overrideWith(
                (ref) => Future<TutorMemory>.error('offline'),
              ),
            ],
          ),
        );
        await openIt(tester);
        expect(actions(), ['shown']);
        expect(logged.single.placement, 'tutor_quota');
        await tester.tap(find.text('Upgrade to VIP'));
        await tester.pumpAndSettle();
        expect(actions().take(2), ['shown', 'cta_vip']);
        expect(actions(), isNot(contains('dismissed')));
        expect(logged[0].flowId, logged[1].flowId);
      },
    );

    testWidgets('persona sheet closed without a CTA logs dismissed', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          launcher(
            (c) => showModalBottomSheet<void>(
              context: c,
              isScrollControlled: true,
              builder: (_) => const PersonaUpgradeSheet(triggerChip: 'chat'),
            ),
          ),
          extra: [
            tutorMemoryProvider.overrideWith(
              (ref) => Future<TutorMemory>.error('offline'),
            ),
          ],
        ),
      );
      await openIt(tester);
      await tester.tapAt(const Offset(10, 10)); // barrier
      await tester.pumpAndSettle();
      expect(actions(), ['shown', 'dismissed']);
    });

    testWidgets('study sheet logs shown once; Not now is dismissed', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          launcher(
            (c) => showStudyUpgradeSheet(
              c,
              feature: StudyFeature.tutor,
              reason: StudyUpgradeReason.exhausted,
            ),
          ),
          extra: [
            tutorMemoryAndQuotasProvider.overrideWith(
              (ref) => Completer<_MemQ>().future,
            ),
          ],
        ),
      );
      await openIt(tester);
      expect(actions(), ['shown']);
      expect(logged.single.placement, 'study_lock');
      await tester.tap(find.text('Not Now'));
      await tester.pumpAndSettle();
      expect(actions(), ['shown', 'dismissed']);
    });

    testWidgets('study sheet VIP button: cta_vip, no dismissed, same flow', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          launcher(
            (c) => showStudyUpgradeSheet(
              c,
              feature: StudyFeature.tutor,
              reason: StudyUpgradeReason.locked,
            ),
          ),
        ),
      );
      await openIt(tester);
      await tester.tap(find.text('Get VIP — unlimited'));
      await tester.pumpAndSettle();
      expect(actions().take(2), ['shown', 'cta_vip']);
      expect(actions(), isNot(contains('dismissed')));
      expect(logged[0].flowId, logged[1].flowId);
    });

    testWidgets('translate sheet logs shown once as translation_cap', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(launcher((c) => showTranslateUnlockSheet(c))),
      );
      await openIt(tester);
      expect(actions(), ['shown']);
      expect(logged.single.placement, 'translation_cap');
      await tester.tap(find.byKey(const Key('translate-limit-go-vip')));
      await tester.pumpAndSettle();
      expect(actions().take(2), ['shown', 'cta_vip']);
      expect(actions(), isNot(contains('dismissed')));
      expect(logged[0].flowId, logged[1].flowId);
    });

    testWidgets(
      'translate sheet: unlock reports cta_coins and unlock_succeeded on the sheet flow',
      (tester) async {
        await tester.pumpWidget(
          host(launcher((c) => showTranslateUnlockSheet(c))),
        );
        await openIt(tester);
        await tester.tap(find.byType(UnlockCta));
        await tester.pumpAndSettle();
        expect(actions(), ['shown', 'cta_coins', 'unlock_succeeded']);
        expect(logged.map((l) => l.flowId).toSet().length, 1);
      },
    );
  });

  group('masked person tile', () {
    testWidgets(
      'waves tile (no host flow): unlock and Go VIP report one placement on one flow',
      (tester) async {
        await tester.pumpWidget(
          host(Scaffold(body: MaskedPersonTile(onUnlocked: () {}))),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(UnlockCta));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('masked-go-vip')));
        await tester.pump();
        expect(actions().take(3), ['cta_coins', 'unlock_succeeded', 'cta_vip']);
        final three = logged.take(3).toList();
        expect(three.map((l) => l.placement).toSet(), {'other'});
        expect(three.map((l) => l.flowId).toSet().length, 1);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });

  group('visitors screen', () {
    Map<String, dynamic> masked() => {
      'revealed': false,
      'lastVisit': '2026-10-16T10:00:00.000Z',
    };

    testWidgets(
      'visitors screen with masked rows logs one shown for visitor_list',
      (tester) async {
        Future<Map<String, dynamic>> fetch({
          required String userId,
          int limit = 20,
          int page = 1,
          bool reveal = false,
          bool seen = false,
        }) async => {
          'success': true,
          'visitors': [masked(), masked(), masked()],
          'maskedCount': 3,
        };
        await tester.pumpWidget(
          host(ProfileVisitorsScreen(userId: 'me', fetchVisitors: fetch)),
        );
        await tester.pumpAndSettle();
        expect(logged.where((l) => l.action == 'shown').length, 1);
        expect(logged.single.placement, 'visitor_list');
      },
    );
  });

  group('boost screen', () {
    testWidgets(
      'shown on open as boost; a purchase logs unlock_succeeded boost',
      (tester) async {
        final client = _BoostClient();
        await tester.pumpWidget(
          host(
            const BoostScreen(),
            extra: [boostApiClientProvider.overrideWithValue(client)],
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(actions(), ['shown']);
        expect(logged.single.placement, 'boost');
        await tester.tap(find.byKey(const ValueKey('boost_confirm')));
        await tester.pump();
        await tester.pump();
        expect(actions(), ['shown', 'unlock_succeeded']);
        expect(logged.last.detail, 'boost');
        expect(logged[0].flowId, logged[1].flowId);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'boost 402 opens the shop as not_enough_coins on the same flow',
      (tester) async {
        final client = _BoostClient(error: BoostError.insufficientCoins);
        await tester.pumpWidget(
          host(
            const BoostScreen(),
            extra: [boostApiClientProvider.overrideWithValue(client)],
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('boost_confirm')));
        await tester.pump();
        await tester.pump();
        expect(actions(), ['shown', 'cta_coins', 'shop_viewed']);
        expect(logged[1].placement, 'not_enough_coins');
        expect(logged.map((l) => l.flowId).toSet().length, 1);
      },
    );
  });
}

typedef _MemQ = ({TutorMemory memory, Map<String, dynamic>? quotas});
