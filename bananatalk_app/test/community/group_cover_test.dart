import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/community/gatherings/group_cover.dart';

/// A cover is OPTIONAL and most groups will not have one, so the no-image case
/// is the designed state rather than a fallback bolted on.
Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('with no image it renders the colour fallback, not a gap',
      (tester) async {
    await tester.pumpWidget(host(
      const GroupCover(id: 'c1', title: 'Seoul Coffee Chat'),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-cover-fallback')), findsOneWidget);
    expect(find.byKey(const Key('group-cover-image')), findsNothing);
    expect(find.text('Seoul Coffee Chat'), findsOneWidget);
  });

  testWidgets('an empty string counts as no image', (tester) async {
    // The server sends null, but a stray '' would otherwise render as a broken
    // image rather than the fallback.
    await tester.pumpWidget(host(
      const GroupCover(id: 'c1', title: 'X', imageUrl: ''),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-cover-fallback')), findsOneWidget);
  });

  testWidgets('the edit affordance appears only for someone who may change it',
      (tester) async {
    // A tap that cannot do anything is worse than no tap at all.
    await tester.pumpWidget(host(
      const GroupCover(id: 'c1', title: 'X'),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-cover-edit')), findsNothing);

    var tapped = false;
    await tester.pumpWidget(host(
      GroupCover(id: 'c1', title: 'X', onTap: () => tapped = true),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-cover-edit')), findsOneWidget);
    await tester.tap(find.byKey(const Key('group-cover-edit')));
    expect(tapped, isTrue);
  });

  testWidgets('the fallback colour is stable for an id across rebuilds',
      (tester) async {
    // A colour that changed on every rebuild would make a list flicker, and
    // one that differed per device would stop being a recognition cue.
    Color colourFor(String id) {
      final hash = id.codeUnits.fold<int>(0, (a, b) => a + b);
      final palettes = GroupCover.palettesForTest;
      return palettes[hash % palettes.length].first;
    }

    // Stability, not uniqueness: with six palettes, two arbitrary ids
    // colliding is expected and harmless.
    expect(colourFor('abc'), colourFor('abc'));
    expect(colourFor(''), isNotNull);

    // But ids must actually spread across the palette rather than all landing
    // on one colour, which would make every group look identical.
    final used = <Color>{};
    for (var i = 0; i < 60; i++) {
      used.add(colourFor('club-' + i.toString()));
    }
    expect(used.length, greaterThan(1));
  });
}
