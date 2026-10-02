import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/vip_subscription.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';

AppConfig _config(bool boosts) => AppConfig(
      minVersion: '0.0.0',
      latestVersion: '0.0.0',
      forceUpdate: false,
      iosUrl: '',
      androidUrl: '',
      releaseNotes: '',
      boostsEnabled: boosts,
    );

Future<void> _pump(WidgetTester tester, {required bool boosts}) async {
  tester.view.physicalSize = const Size(900, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      appConfigProvider.overrideWith((ref) async => _config(boosts)),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const VipPlansScreen(userId: 'u1'),
    ),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows exactly monthly + yearly, no quarterly, five perks',
      (tester) async {
    await _pump(tester, boosts: true);
    expect(find.text(r'$3.99'), findsOneWidget);
    expect(find.text(r'$24.99'), findsOneWidget);
    expect(find.text(r'$19.99'), findsNothing);
    expect(find.textContaining('uarter'), findsNothing);
    expect(find.byKey(const ValueKey('vip-plan-monthly')), findsOneWidget);
    expect(find.byKey(const ValueKey('vip-plan-yearly')), findsOneWidget);
    expect(find.byKey(const ValueKey('vip-plan-quarterly')), findsNothing);
    for (final s in [
      'No ads',
      'Unlimited daily matches',
      'See who waved and viewed you',
      'Unlimited waves',
      'Advanced partner filters',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
  });

  testWidgets('flag off: never promises the unshipped perks', (tester) async {
    await _pump(tester, boosts: false);
    expect(find.text('No ads'), findsOneWidget);
    expect(find.text('Advanced partner filters'), findsOneWidget);
    expect(find.text('Unlimited daily matches'), findsNothing);
    expect(find.text('See who waved and viewed you'), findsNothing);
    expect(find.text('Unlimited waves'), findsNothing);
  });

  test('VipPerks.fromJson defaults all-false and parses perks', () {
    final none = VipPerks.fromJson(const {});
    expect(none.adFree || none.revealWaves || none.unlimitedMatches, isFalse);
    final p = VipPerks.fromJson(const {
      'adFree': true,
      'unlimitedMatches': true,
      'revealWaves': true,
      'unlimitedWaves': true,
      'advancedFilters': true,
    });
    expect(p.adFree && p.unlimitedMatches && p.revealWaves, isTrue);
    expect(p.unlimitedWaves && p.advancedFilters, isTrue);
  });
}
