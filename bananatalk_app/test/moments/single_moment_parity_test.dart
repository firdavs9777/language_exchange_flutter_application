import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/single/single_moment.dart';

import '../support/moment_fixture.dart';

void main() {
  // Detail had like, comment and share only. The card additionally has save in
  // its action row and a Translate chip under the caption -- so a caption
  // truncated in the feed could be translated, and the full one, on the screen
  // built to show it, could not.
  testWidgets('detail offers save and translate, like the card does',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SingleMoment(moment: buildMoment(description: 'Hello there')),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('detail-save')), findsOneWidget);
    expect(find.byKey(const Key('detail-translate')), findsOneWidget);
  });
}
