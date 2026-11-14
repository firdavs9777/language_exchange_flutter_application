import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/pages/learning/main/sections/progress_card.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

import '../learning/study_feature_groups_test.dart' show harness;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'the hub has no Challenges tile and the progress card no Achievements link',
    (tester) async {
      expect(
        StudyFeature.values.map((f) => f.slug),
        isNot(contains('challenges')),
      );
      expect(studyFeatureOrder.length, 11);

      await tester.pumpWidget(harness(pushed: []));
      await tester.pumpAndSettle();
      expect(find.text('Challenges'), findsNothing);
      expect(find.byType(InkWell), findsNWidgets(11));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProgressCard(progress: null, onFullReport: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Achievements'), findsNothing);
      expect(find.text('Full report'), findsOneWidget);
    },
  );
}
