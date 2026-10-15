import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card.dart';
import 'package:bananatalk_app/widgets/moment_translate_chip.dart';

import '../support/moment_fixture.dart';

Widget _host(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

String _renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join();

void main() {
  // substring(0, 150) counts UTF-16 code units, so an emoji straddling index
  // 150 was cut mid-surrogate-pair and rendered as a replacement glyph.
  testWidgets('an emoji at the cut point survives intact', (tester) async {
    final caption = '${'a' * 149}😊${'b' * 200}';

    await tester.pumpWidget(_host(MomentCard(
      moments: buildMoment(description: caption),
    )));
    await tester.pump(const Duration(milliseconds: 300));

    expect(_renderedText(tester), isNot(contains('�')),
        reason: 'a replacement glyph means a surrogate pair was split');
  });

  testWidgets('a Hangul syllable at the cut point survives intact',
      (tester) async {
    final caption = '${'가' * 149}나${'다' * 200}';

    await tester.pumpWidget(_host(MomentCard(
      moments: buildMoment(description: caption, language: 'ko'),
    )));
    await tester.pump(const Duration(milliseconds: 300));

    expect(_renderedText(tester), isNot(contains('�')));
  });

  testWidgets('a short caption gets no show-more toggle', (tester) async {
    await tester.pumpWidget(_host(MomentCard(
      moments: buildMoment(description: 'Hello!'),
    )));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('more'), findsNothing);
  });

  // Photo-only moments are postable now. With no caption the card must not
  // render an empty caption line, nor offer to translate nothing.
  testWidgets('a photo moment with no caption shows no translate chip',
      (tester) async {
    await tester.pumpWidget(_host(MomentCard(
      moments: buildMoment(description: '', images: const ['a.jpg']),
    )));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MomentTranslateChip), findsNothing);
    expect(_renderedText(tester), isNot(contains('null')));
  });

  testWidgets('a photo moment WITH a caption keeps its translate chip',
      (tester) async {
    await tester.pumpWidget(_host(MomentCard(
      moments: buildMoment(description: 'Hello', images: const ['a.jpg']),
    )));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MomentTranslateChip), findsOneWidget);
  });
}
