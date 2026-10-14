import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/widgets/study/study_upgrade_sheet.dart';

void main() {
  final events = <String, Map<String, Object>>{};
  setUp(() {
    events.clear();
    AnalyticsService.debugLogSink = (n, p) => events[n] = p;
  });
  tearDown(() => AnalyticsService.debugLogSink = null);

  Future<void> open(WidgetTester tester, StudyUpgradeReason reason) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Coins off: UnlockCta renders nothing, no network.
        appConfigProvider.overrideWith((ref) async =>
            const AppConfig(minVersion: '0', latestVersion: '0', forceUpdate: false,
                iosUrl: '', androidUrl: '', releaseNotes: '')),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showStudyUpgradeSheet(context,
                feature: StudyFeature.tutor, reason: reason),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('exhausted copy, VIP + Not now, logs shown', (tester) async {
    await open(tester, StudyUpgradeReason.exhausted);
    expect(find.text("You've used today's AI Tutor"), findsOneWidget);
    expect(find.text('Get VIP — unlimited'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);
    expect(events['study_upgrade_sheet_shown'], {'feature': 'tutor', 'reason': 'exhausted'});
  });

  testWidgets('locked copy', (tester) async {
    await open(tester, StudyUpgradeReason.locked);
    expect(find.text('AI Tutor is a VIP feature'), findsOneWidget);
  });

  testWidgets('Not now closes', (tester) async {
    await open(tester, StudyUpgradeReason.exhausted);
    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();
    expect(find.text('Get VIP — unlimited'), findsNothing);
  });
}
