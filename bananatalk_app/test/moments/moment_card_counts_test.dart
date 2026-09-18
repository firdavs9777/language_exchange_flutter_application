import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card.dart';

import '../support/moment_fixture.dart';

Widget _host(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  testWidgets('a liked, commented moment shows each count once', (tester) async {
    await tester.pumpWidget(_host(MomentCard(
      moments: buildMoment(likeCount: 189, commentCount: 21),
    )));
    await tester.pump(const Duration(milliseconds: 300));

    // The action row carries the numbers. The block that repeated them
    // underneath ("189 likes" / "21 comments") is gone.
    expect(find.text('189'), findsOneWidget);
    expect(find.textContaining('189 likes'), findsNothing);
    expect(find.textContaining('21 comments'), findsNothing);
  });
}
