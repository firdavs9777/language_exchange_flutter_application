import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/profile_main/sections/profile_highlights_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/community_fixture.dart';

/// Own profile: free users see a gold VIP card with the real perks.
void main() {
  Future<void> pump(WidgetTester t, {required bool vip, Locale locale = const Locale('en')}) async {
    t.view.physicalSize = const Size(320, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: ProfileHighlightsTab(user: communityFixture(vip: vip))),
        ),
      ),
    ));
    await t.pump();
  }

  testWidgets('a free user sees the VIP card with real perks and Go VIP', (t) async {
    await pump(t, vip: false);
    expect(find.byKey(const Key('profile-vip-upsell')), findsOneWidget);
    expect(find.text('Unlimited AI tutor and roleplay'), findsOneWidget);
    expect(find.byKey(const Key('profile-vip-go')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('no overflow at 320 in German', (t) async {
    await pump(t, vip: false, locale: const Locale('de'));
    expect(t.takeException(), isNull);
  });

  testWidgets('a VIP user does not see the upsell', (t) async {
    await pump(t, vip: true);
    expect(find.byKey(const Key('profile-vip-upsell')), findsNothing);
  });
}
