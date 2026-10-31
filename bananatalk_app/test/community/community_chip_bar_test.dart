import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:bananatalk_app/pages/community/main/community_tab_bar.dart';

Widget _host({required int length, bool showRoomsTab = true}) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DefaultTabController(
          length: length,
          child: Builder(
            builder: (context) => Scaffold(
              body: CommunityTabBar(
                tabController: DefaultTabController.of(context),
                tabs: communityTabLayout(
                  matchesLayout: length == 4,
                  rooms: showRoomsTab,
                ),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('tapping a chip moves the controller to that tab', (tester) async {
    await tester.pumpWidget(_host(length: 4));
    await tester.pumpAndSettle();

    final controller = DefaultTabController.of(
      tester.element(find.byType(CommunityTabBar)),
    );
    expect(controller.index, 0);

    // The strip is chips now, not an underlined TabBar. Asserting the type is
    // absent is what makes this test fail against the old render -- tapping a
    // label alone passed either way.
    expect(find.byType(TabBar), findsNothing);
    expect(find.byKey(const Key('community-chip-3')), findsOneWidget);

    await tester.tap(find.byKey(const Key('community-chip-3')));
    await tester.pumpAndSettle();

    // Matches=0, Partners=1, Clubs=2, Rooms=3 (communityTabLayout).
    expect(controller.index, 3);
  });

  testWidgets('the Rooms chip is absent when the kill switch is off',
      (tester) async {
    await tester.pumpWidget(_host(length: 2, showRoomsTab: false));
    await tester.pumpAndSettle();

    expect(find.text('Rooms'), findsNothing);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('a swipe-driven controller change repaints the chips',
      (tester) async {
    await tester.pumpWidget(_host(length: 3));
    await tester.pumpAndSettle();

    final controller = DefaultTabController.of(
      tester.element(find.byType(CommunityTabBar)),
    );

    // Not a tap: the chips must follow the controller however it moved,
    // or a swipe in the TabBarView would leave the wrong chip lit.
    controller.animateTo(1);
    await tester.pumpAndSettle();

    expect(controller.index, 1);
    final selected = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const Key('community-chip-1')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = selected.decoration as BoxDecoration;
    expect(decoration.color, isNot(Colors.transparent),
        reason: 'the chip for the current tab must paint as selected');
  });
}
