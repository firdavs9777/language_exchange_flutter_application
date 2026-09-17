import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/gatherings/club_people_section.dart';

/// The club page showed a member COUNT and nothing else — no owner, no faces.
/// That asked people to join something with no visible human behind it.
ClubMember m(String id, String name, String role) =>
    ClubMember(id: id, name: name, role: role);

Widget host(Club club, {void Function(ClubMember)? onLongPress}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ClubPeopleSection(club: club, onMemberLongPress: onLongPress),
      ),
    );

Club club(List<ClubMember> members) => Club(
      id: 'c1',
      name: 'Seoul Coffee Chat',
      memberCount: members.length,
      members: members,
    );

void main() {
  testWidgets('organizers and members render in separate rows', (tester) async {
    await tester.pumpWidget(host(club([
      m('1', 'Dana', 'owner'),
      m('2', 'Sam', 'organizer'),
      m('3', 'Rio', 'member'),
    ])));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('club-organizers')), findsOneWidget);
    expect(find.byKey(const Key('club-members')), findsOneWidget);
    expect(find.text('Dana'), findsOneWidget);
    expect(find.text('Rio'), findsOneWidget);
  });

  testWidgets('a club with no members renders nothing at all', (tester) async {
    // List responses send a thinner shape, and older builds send none. Both
    // must degrade to exactly what they showed before, not to empty headers.
    await tester.pumpWidget(host(club(const [])));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('club-organizers')), findsNothing);
    expect(find.byKey(const Key('club-members')), findsNothing);
  });

  testWidgets('a club with only leaders shows no members row', (tester) async {
    await tester.pumpWidget(host(club([m('1', 'Dana', 'owner')])));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('club-organizers')), findsOneWidget);
    expect(find.byKey(const Key('club-members')), findsNothing);
  });

  testWidgets('long-press reaches management only when handed a callback',
      (tester) async {
    ClubMember? pressed;
    await tester.pumpWidget(host(
      club([m('1', 'Dana', 'owner'), m('3', 'Rio', 'member')]),
      onLongPress: (member) => pressed = member,
    ));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Rio'));
    await tester.pumpAndSettle();
    expect(pressed?.id, '3');
  });

  testWidgets('a nameless member shows a placeholder rather than blank',
      (tester) async {
    // Unpopulated payloads give bare ids; the row must still render.
    await tester.pumpWidget(host(club([m('9', '', 'member'), m('1', 'D', 'owner')])));
    await tester.pumpAndSettle();
    expect(find.text('—'), findsOneWidget);
  });
}
