import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/drawer/profile_drawer.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';

void main() {
  testWidgets('Profile drawer Support row opens the support sheet', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final user = Community.fromJson({'_id': 'u1', 'name': 'Ana', 'email': 'a@b.c'});
    final key = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        runningAppVersionProvider.overrideWith((ref) async => '1.0.0'),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(key: key, drawer: LeftDrawer(user: user), body: const SizedBox()),
      ),
    ));
    key.currentState!.openDrawer();
    await tester.pumpAndSettle();

    final row = find.text('Support BananaTalk');
    await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.text('Donate via PayPal'), findsOneWidget);
  });
}
