import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_pack_hero_card.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';

const _pack = DailyPack(
  needsLanguage: false,
  dateKey: '2026-09-07',
  weekKey: '2026-W37',
  dayInWeek: 1,
  theme: PackTheme(id: 'p1', topic: 'Work & careers', level: 'intermediate'),
  stations: [
    PackStation(kind: 'grammar', status: StationStatus.todo),
    PackStation(kind: 'review', status: StationStatus.empty),
  ],
);

void main() {
  testWidgets('the hero card renders from the pack provider', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [dailyPackProvider.overrideWith((ref) async => _pack)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ref.watch(dailyPackProvider).when(
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (pack) => DailyPackHeroCard(
                    pack: pack,
                    onOpen: () {},
                    onPickLanguage: () {},
                    onOpenProgress: () {},
                    onTakePlacement: () {},
                  ),
                ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Work & careers'), findsOneWidget);
  });

  test('the retired two-card widgets are actually gone', () {
    // Guards against the old UI surviving as dead code that a later change
    // could wire back in. Paths are relative to bananatalk_app/, the directory
    // flutter test runs from.
    expect(File('lib/pages/learning/daily/widgets/today_section.dart').existsSync(), isFalse);
    expect(File('lib/pages/learning/daily/daily_drop_screen.dart').existsSync(), isFalse);
  });
}
