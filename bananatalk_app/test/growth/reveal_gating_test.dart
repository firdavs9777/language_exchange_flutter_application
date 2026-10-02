import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/coin_transaction.dart';
import 'package:bananatalk_app/pages/community/tabs/waves_tab.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';
import 'package:bananatalk_app/widgets/masked_person_tile.dart';

class _FakeCommunity implements CommunityService {
  _FakeCommunity(this.waves);
  final List<Wave> waves;
  final revealArgs = <bool>[];
  @override
  Future<List<Wave>> getWavesReceived({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
    bool archive = false,
    bool reveal = false,
  }) async {
    revealArgs.add(reveal);
    return waves;
  }

  @override
  Future<void> markWavesAsRead({List<String>? waveIds}) async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

AppConfig _config({required bool boosts}) => AppConfig(
      minVersion: '0.0.0',
      latestVersion: '0.0.0',
      forceUpdate: false,
      iosUrl: '',
      androidUrl: '',
      releaseNotes: '',
      coinsEnabled: true,
      boostsEnabled: boosts,
    );

List<Override> _ov({bool boosts = true, CommunityService? community}) => [
      appConfigProvider.overrideWith((ref) async => _config(boosts: boosts)),
      coinUnlockCatalogProvider.overrideWith((ref) async => {
            'who_waved': const CoinUnlockEntry(
                featureKey: 'who_waved', cost: 60, grant: 1),
          }),
      if (community != null)
        communityServiceProvider.overrideWithValue(community),
    ];

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
  group('Wave.fromJson reveal', () {
    test('masked row: revealed false, no throw, no id/name', () {
      final w = Wave.fromJson({
        'waveId': 'w1',
        'from': {'name': null, 'images': []},
        'revealed': false,
        'isRead': false,
        'createdAt': '2026-10-01T00:00:00Z',
      });
      expect(w.revealed, isFalse);
      expect(w.fromUserId, '');
      expect(w.fromUserName, '');
    });

    test('absent revealed key defaults to true', () {
      final w = Wave.fromJson({
        'waveId': 'w2',
        'from': {'_id': 'u1', 'name': 'Kim', 'images': []},
      });
      expect(w.revealed, isTrue);
    });
  });

  testWidgets('MaskedPersonTile shows title, cost body and both actions',
      (tester) async {
    var unlocked = 0;
    await tester.pumpWidget(_app(
      MaskedPersonTile(onUnlocked: () => unlocked++),
      _ov(),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('Someone waved at you'), findsOneWidget);
    expect(find.text('Reveal who for 60 coins, or go VIP'), findsOneWidget);
    expect(find.byType(UnlockCta), findsOneWidget);
    expect(find.text('Go VIP'), findsOneWidget);
  });

  testWidgets('WavesTab: one masked + one revealed wave', (tester) async {
    final fake = _FakeCommunity([
      Wave.fromJson({
        'waveId': 'w1',
        'from': {'name': null, 'images': []},
        'revealed': false,
        'isRead': true,
        'createdAt': '2026-10-01T00:00:00Z',
      }),
      Wave.fromJson({
        'waveId': 'w2',
        'from': {'_id': 'u2', 'name': 'Minji', 'images': []},
        'revealed': true,
        'isRead': true,
        'createdAt': '2026-10-01T00:00:00Z',
      }),
    ]);
    await tester.pumpWidget(_app(
      WavesTab(primeNotifications: (_) async {}),
      _ov(community: fake as CommunityService),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(MaskedPersonTile), findsOneWidget);
    expect(find.text('Minji'), findsOneWidget);
    expect(fake.revealArgs, [true]);
  });

  testWidgets('WavesTab does not request reveal when the flag is off',
      (tester) async {
    final fake = _FakeCommunity([]);
    await tester.pumpWidget(_app(
      WavesTab(primeNotifications: (_) async {}),
      _ov(boosts: false, community: fake as CommunityService),
    ));
    await tester.pumpAndSettle();
    expect(fake.revealArgs, [false]);
  });
}
