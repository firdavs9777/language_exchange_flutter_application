import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/promo_service.dart';
import 'package:bananatalk_app/widgets/promos/feature_spotlight_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('aiStudy is appended so stored rotation indexes keep their meaning', () {
    expect(PromoType.values,
        [PromoType.coins, PromoType.rooms, PromoType.voice, PromoType.aiStudy]);
  });

  test('AI Study rotates in until a lesson is done', () async {
    final picks = [
      for (var i = 0; i < 4; i++)
        await pickPromoFor(coinsEligible: false, lessonDone: false),
    ];
    expect(picks,
        [PromoType.rooms, PromoType.voice, PromoType.aiStudy, PromoType.rooms]);
  });

  test('skipped after a lesson', () async {
    final picks = [
      for (var i = 0; i < 4; i++)
        await pickPromoFor(coinsEligible: false, lessonDone: true),
    ];
    expect(picks, isNot(contains(PromoType.aiStudy)));
  });

  testWidgets('the spotlight renders the AI Study promo', (t) async {
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (c) => TextButton(
          onPressed: () => showFeatureSpotlight(c, PromoType.aiStudy, onTry: () {}),
          child: const Text('open'),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Practice with AI scenarios'), findsOneWidget);
  });
}
