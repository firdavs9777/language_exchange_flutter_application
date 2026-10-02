import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/boost.dart';
import 'package:bananatalk_app/models/coin_transaction.dart';
import 'package:bananatalk_app/pages/chat/conversation/chat_limit_outcome.dart';
import 'package:bananatalk_app/pages/coins/boost_screen.dart';
import 'package:bananatalk_app/pages/community/tabs/matches_tab.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/boost_api_client.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/services/interstitial_policy.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';

class _FakeCoinClient implements CoinApiClient {
  _FakeCoinClient({this.unlockResponse, this.rewardedResponse});
  final ApiResponse? unlockResponse;
  final ApiResponse? rewardedResponse;
  final rewardedCalls = <String>[];

  @override
  Future<ApiResponse> unlock(String featureKey) async => unlockResponse!;

  @override
  Future<ApiResponse> rewardedUnlock(String feature) async {
    rewardedCalls.add(feature);
    return rewardedResponse!;
  }

  @override
  Future<int> getBalance() async => 100;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeBoostClient implements BoostApiClient {
  _FakeBoostClient(this.error);
  final BoostError error;
  @override
  Future<Boost> purchaseProfileBoost() async => throw BoostException(error);
  @override
  Future<Boost?> getActive() async => null;
  @override
  Future<List<Boost>> getHistory() async => const [];
}

AppConfig _config() => AppConfig(
      minVersion: '0.0.0',
      latestVersion: '0.0.0',
      forceUpdate: false,
      iosUrl: '',
      androidUrl: '',
      releaseNotes: '',
      coinsEnabled: true,
      boostsEnabled: true,
    );

Widget _app(Widget child, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  group('F1 handleLimitDialogResult', () {
    test('unlocked -> retry', () {
      expect(handleLimitDialogResult('unlocked'), ChatLimitOutcome.retry);
    });
    test('rewarded -> rewardedOnly', () {
      expect(
          handleLimitDialogResult('rewarded'), ChatLimitOutcome.rewardedOnly);
    });
    test('null / other -> none', () {
      expect(handleLimitDialogResult(null), ChatLimitOutcome.none);
      expect(handleLimitDialogResult('x'), ChatLimitOutcome.none);
    });
  });

  testWidgets('F1 rewarded 200 -> unlocked + success snackbar',
      (tester) async {
    final fake = _FakeCoinClient(
      rewardedResponse: ApiResponse(
        success: true,
        statusCode: 200,
        data: {'granted': 3},
      ),
    );
    late ScaffoldMessengerState messenger;
    await tester.pumpWidget(_app(
      Builder(builder: (context) {
        messenger = ScaffoldMessenger.of(context);
        return const SizedBox();
      }),
      const [],
    ));
    final result = await runRewardedUnlock(
      client: fake,
      flagOn: true,
      featureKey: 'dm',
      rewardable: true,
      messenger: messenger,
      limitMessage: 'limit',
      successMessage: 'unlocked!',
    );
    await tester.pump();
    expect(result, 'unlocked');
    expect(fake.rewardedCalls, ['dm']);
    expect(find.text('unlocked!'), findsOneWidget);
  });

  group('F2 shouldShowExtraMatchesCta', () {
    test('flag off -> false', () {
      expect(shouldShowExtraMatchesCta(boostsEnabled: false, count: 6),
          isFalse);
    });
    test('9 cards -> true (more purchases allowed)', () {
      expect(
          shouldShowExtraMatchesCta(boostsEnabled: true, count: 9), isTrue);
    });
    test('15 cards -> false (server max)', () {
      expect(
          shouldShowExtraMatchesCta(boostsEnabled: true, count: 15), isFalse);
    });
  });

  testWidgets('F2 UnlockCta maps 409 extra_matches_maxed and hides',
      (tester) async {
    final fake = _FakeCoinClient(
      unlockResponse: ApiResponse(
        success: false,
        statusCode: 409,
        error: 'extra_matches_maxed',
      ),
    );
    await tester.pumpWidget(_app(
      const UnlockCta(featureKey: 'extra_matches'),
      [
        appConfigProvider.overrideWith((ref) async => _config()),
        coinApiClientProvider.overrideWithValue(fake),
        coinUnlockCatalogProvider.overrideWith((ref) async => {
              'extra_matches': const CoinUnlockEntry(
                  featureKey: 'extra_matches', cost: 40, grant: 3),
            }),
      ],
    ));
    await tester.pump();
    await tester.pump();
    expect(find.byType(OutlinedButton), findsOneWidget);
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    await tester.pump();
    expect(find.text(en.extraMatchesMaxed), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  group('M2 boostErrorFor', () {
    test('429 capacity_full -> capacityFull', () {
      expect(boostErrorFor(429, 'capacity_full'), BoostError.capacityFull);
    });
    test('429 from the rate limiter -> null (generic failure)', () {
      expect(boostErrorFor(429, 'Too many requests'), isNull);
      expect(boostErrorFor(429, null), isNull);
    });
    test('402 / 409 unchanged', () {
      expect(boostErrorFor(402, 'insufficient_coins'),
          BoostError.insufficientCoins);
      expect(boostErrorFor(409, 'already_boosted'), BoostError.alreadyBoosted);
    });
  });

  group('M3 formatBoostRemaining', () {
    test('hours + minutes', () {
      expect(formatBoostRemaining(en, const Duration(hours: 3, minutes: 5)),
          '3h 5m');
    });
    test('ending soon when elapsed', () {
      expect(formatBoostRemaining(en, const Duration(seconds: -1)),
          en.boostEndingSoon);
    });
  });

  test('M4 rewardedFeatures tolerates a non-list', () {
    final c = AppConfig.fromJson({
      'minVersion': '1.0.0',
      'latestVersion': '1.0.0',
      'forceUpdate': false,
      'iosUrl': '',
      'androidUrl': '',
      'releaseNotes': '',
      'rewardedFeatures': 'x',
    });
    expect(c.rewardedFeatures, isEmpty);
  });

  testWidgets('M5 alreadyBoosted with no active boost shows boostFailed',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        boostApiClientProvider
            .overrideWithValue(_FakeBoostClient(BoostError.alreadyBoosted)),
        coinBalanceProvider.overrideWith((ref) async => 480),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BoostScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('boost_confirm')));
    await tester.pumpAndSettle();
    expect(find.text(en.boostFailed), findsOneWidget);
  });

  group('M7 everyNInterstitialAllowed', () {
    test('cap off -> always allowed (legacy)', () {
      expect(
          everyNInterstitialAllowed(
              sessionCapOn: false, alreadyShownThisSession: true),
          isTrue);
    });
    test('cap on + already shown -> blocked', () {
      expect(
          everyNInterstitialAllowed(
              sessionCapOn: true, alreadyShownThisSession: true),
          isFalse);
    });
    test('cap on + not yet shown -> allowed', () {
      expect(
          everyNInterstitialAllowed(
              sessionCapOn: true, alreadyShownThisSession: false),
          isTrue);
    });
  });

  group('M10 app version header', () {
    test('version + build', () {
      expect(ApiClient.buildAppVersionHeader('2.6.0', '10573'),
          '2.6.0+10573');
    });
    test('unknown -> null', () {
      expect(ApiClient.buildAppVersionHeader(null, null), isNull);
      expect(ApiClient.buildAppVersionHeader('', '1'), isNull);
    });
  });
}
