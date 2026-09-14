import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/daily_pack_hero_card.dart';

/// Every curated pack is English. A learner whose target is Korean is served
/// English vocabulary and English listening, with the grammar station silently
/// auto-satisfied -- and because servedLevel == requestedLevel, the existing
/// level-fallback banner never fires, so nothing on screen says so. That is
/// 469 of 810 active learners (prod, 2026-09-14).
///
/// This does not decide what to do about the content gap. It stops the card
/// from presenting another language's material as the learner's own.
DailyPack _pack({
  String? contentLanguage = 'en',
  String? contentLanguageName = 'English',
  bool matches = true,
}) =>
    DailyPack(
      needsLanguage: false,
      dateKey: '2026-09-14',
      weekKey: '2026-W38',
      dayInWeek: 1,
      language: matches ? 'en' : 'ko',
      requestedLevel: 'A2',
      servedLevel: 'A2',
      contentLanguage: contentLanguage,
      contentLanguageName: contentLanguageName,
      contentLanguageMatches: matches,
      theme: const PackTheme(id: 'p1', topic: 'Work & careers', level: 'intermediate'),
      stations: const [PackStation(kind: 'vocabulary', status: StationStatus.todo)],
    );

Widget _host(DailyPack pack) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DailyPackHeroCard(
          pack: pack,
          mastery: null,
          onOpen: () {},
          onPickLanguage: () {},
          onOpenProgress: () {},
          onTakePlacement: () {},
        ),
      ),
    );

void main() {
  testWidgets('warns when the content is in another language', (tester) async {
    await tester.pumpWidget(_host(_pack(matches: false)));
    expect(find.byKey(const Key('today-content-language')), findsOneWidget);
    expect(find.textContaining('English'), findsWidgets);
  });

  testWidgets('stays quiet when the content is in the target language',
      (tester) async {
    await tester.pumpWidget(_host(_pack(matches: true)));
    expect(find.byKey(const Key('today-content-language')), findsNothing);
  });

  testWidgets('stays quiet when the server made no claim', (tester) async {
    await tester.pumpWidget(
      _host(_pack(contentLanguage: null, contentLanguageName: null, matches: true)),
    );
    expect(find.byKey(const Key('today-content-language')), findsNothing);
  });

  testWidgets('an older server that omits the fields never warns', (tester) async {
    final pack = DailyPack.fromJson(const {'dateKey': '2026-09-14'});
    expect(pack.contentLanguageMatches, true);
    expect(pack.contentLanguage, null);
    await tester.pumpWidget(_host(pack));
    expect(find.byKey(const Key('today-content-language')), findsNothing);
  });

  testWidgets('parses the fields the server sends', (tester) async {
    final pack = DailyPack.fromJson(const {
      'dateKey': '2026-09-14',
      'contentLanguage': 'en',
      'contentLanguageName': 'English',
      'contentLanguageMatches': false,
    });
    expect(pack.contentLanguage, 'en');
    expect(pack.contentLanguageName, 'English');
    expect(pack.contentLanguageMatches, false);
  });
}
