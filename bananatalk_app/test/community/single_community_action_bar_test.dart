import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/single/single_community_actions.dart';

import '../support/community_fixture.dart';

Widget _host(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('the bar offers Follow, Chat and Wave', (tester) async {
    await tester.pumpWidget(_host(SingleCommunityActionBar(
      community: buildCommunity(id: 'them', showOnlineStatus: false),
      isFollower: false,
      onMessage: () {},
      onFollowToggle: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('action-bar-follow')), findsOneWidget);
    expect(find.byKey(const Key('action-bar-chat')), findsOneWidget);
    expect(find.byIcon(Icons.waving_hand_rounded), findsOneWidget);
  });

  testWidgets('Chat calls onMessage', (tester) async {
    var messaged = false;
    await tester.pumpWidget(_host(SingleCommunityActionBar(
      community: buildCommunity(id: 'them', showOnlineStatus: false),
      isFollower: false,
      onMessage: () => messaged = true,
      onFollowToggle: () {},
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('action-bar-chat')));
    expect(messaged, isTrue);
  });

  testWidgets('Follow calls onFollowToggle', (tester) async {
    var toggled = false;
    await tester.pumpWidget(_host(SingleCommunityActionBar(
      community: buildCommunity(id: 'them', showOnlineStatus: false),
      isFollower: false,
      onMessage: () {},
      onFollowToggle: () => toggled = true,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('action-bar-follow')));
    expect(toggled, isTrue);
  });
}
