import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/ad_providers.dart';
import 'package:bananatalk_app/services/ad_service.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';

// audit_a #19: the watch-ad button read `isRewardedAdReady` once per build.
// AdService notified nobody when the ad finished loading (or reloaded after
// one was watched), so the button stayed disabled until something else
// happened to rebuild its parent.

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      showAdsProvider.overrideWith((ref) => true),
      adServiceProvider.overrideWith((ref) => AdService()),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: RewardedAdButton(onRewarded: () {})),
    ),
  ));
  await tester.pump();
}

OutlinedButton _button(WidgetTester tester) =>
    tester.widget<OutlinedButton>(find.byWidgetPredicate(
      (w) => w is OutlinedButton,
    ));

void main() {
  tearDown(() => AdService().rewardedReady.value = false);

  testWidgets('enables itself when the rewarded ad finishes loading',
      (tester) async {
    AdService().rewardedReady.value = false;
    await _pump(tester);
    expect(_button(tester).onPressed, isNull);

    // What the load callback does — no parent rebuild involved.
    AdService().rewardedReady.value = true;
    await tester.pump();
    expect(_button(tester).onPressed, isNotNull);

    // Watched/disposed: disabled again until the reload lands.
    AdService().rewardedReady.value = false;
    await tester.pump();
    expect(_button(tester).onPressed, isNull);
  });
}
