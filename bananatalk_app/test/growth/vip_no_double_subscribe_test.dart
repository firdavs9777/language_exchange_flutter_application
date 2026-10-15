import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/vip_up_pill.dart';

import '../helpers/community_fixture.dart';

// audit_a #17: an active VIP could tap the always-visible VIP pill and buy a
// second subscription (on Android each plan is its own product, so that is
// two concurrent charges).

AppConfig _config() => const AppConfig(
      minVersion: '0.0.0',
      latestVersion: '0.0.0',
      forceUpdate: false,
      iosUrl: '',
      androidUrl: '',
      releaseNotes: '',
      boostsEnabled: false,
    );

Future<void> _pump(WidgetTester tester, Widget home, {required bool vip}) async {
  tester.view.physicalSize = const Size(900, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      appConfigProvider.overrideWith((ref) async => _config()),
      userProvider.overrideWith((ref) async => communityFixture(vip: vip)),
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
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('the VIP pill is shown to a regular user', (tester) async {
    await _pump(tester, const Scaffold(body: VipUpPill()), vip: false);
    expect(find.text('VIP'), findsOneWidget);
  });

  testWidgets('the VIP pill is hidden for an active VIP', (tester) async {
    await _pump(tester, const Scaffold(body: VipUpPill()), vip: true);
    expect(find.text('VIP'), findsNothing);
  });

  testWidgets('plans screen: a regular user sees plans and Continue',
      (tester) async {
    await _pump(tester, const VipPlansScreen(userId: 'me'), vip: false);
    expect(find.byKey(const ValueKey('vip-plan-monthly')), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.byKey(const ValueKey('vip-active-manage')), findsNothing);
  });

  testWidgets('plans screen: an active VIP gets manage, never a buy button',
      (tester) async {
    await _pump(tester, const VipPlansScreen(userId: 'me'), vip: true);
    expect(find.byKey(const ValueKey('vip-plan-monthly')), findsNothing);
    expect(find.byKey(const ValueKey('vip-plan-yearly')), findsNothing);
    expect(find.text('CONTINUE'), findsNothing);
    expect(find.byKey(const ValueKey('vip-active-manage')), findsOneWidget);
    expect(find.text('Your VIP subscription is already active.'),
        findsOneWidget);
  });
}
