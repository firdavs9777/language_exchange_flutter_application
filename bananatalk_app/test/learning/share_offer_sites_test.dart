import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/pages/learning/animations/streak_milestone_celebration.dart';
import 'package:bananatalk_app/pages/learning/lessons/lesson_player_screen.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/share_as_moment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/community_fixture.dart';

AppConfig _config(bool on) => AppConfig(
      minVersion: '1',
      latestVersion: '1',
      forceUpdate: false,
      iosUrl: '',
      androidUrl: '',
      releaseNotes: '',
      shareOffersEnabled: on,
    );

/// With shareOffersEnabled off (today's server) the lesson results and the
/// streak celebration must look exactly as before the share offers existed.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('lesson results layout', () {
    const results = SizedBox(key: ValueKey('results'), height: 100);
    const card = SizedBox(key: ValueKey('card'), height: 40);

    test('flag off: the original Center(results), no scroll view, no card',
        () {
      final w = lessonResultsLayout(
        shareOffersEnabled: false,
        results: results,
        shareCard: card,
      );
      expect(w, isA<Center>());
      expect((w as Center).child, same(results));
    });

    testWidgets('flag on: results stay centred above the card', (t) async {
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: lessonResultsLayout(
            shareOffersEnabled: true,
            results: results,
            shareCard: card,
          ),
        ),
      ));
      expect(find.byKey(const ValueKey('card')), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('streak celebration', () {
    var userReads = 0;
    setUp(() => userReads = 0);

    Future<void> show(WidgetTester t, {required bool flag}) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          appConfigProvider.overrideWith((ref) async => _config(flag)),
          userProvider.overrideWith((ref) {
            userReads++;
            return Future<Community>.value(buildCommunity(id: 'me'));
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    StreakMilestoneCelebration.forceShow(context, 7),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ));
      await t.pump();
      await t.tap(find.text('go'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
    }

    Future<void> close(WidgetTester t) async {
      await t.tap(find.byType(FilledButton).first);
      await t.pump(const Duration(seconds: 4));
    }

    testWidgets('flag off: no share strip and the user is not read',
        (t) async {
      await show(t, flag: false);
      expect(find.byType(ShareAsMomentCard), findsNothing);
      expect(userReads, 0);
      await close(t);
    });

    testWidgets('flag on: the share strip is built', (t) async {
      await show(t, flag: true);
      expect(find.byType(ShareAsMomentCard), findsOneWidget);
      await close(t);
    });
  });
}
