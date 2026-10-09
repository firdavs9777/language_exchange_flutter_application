import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_guidance.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';
import 'package:bananatalk_app/pages/community/first_session/matches_first_session_panel.dart';
import 'package:bananatalk_app/pages/community/tabs/matches_tab.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/daily_matches_provider.dart';
import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:bananatalk_app/widgets/guides/pulse_highlight.dart';

/// The spec requires widget coverage that the panel renders for an eligible
/// user, is absent for each ineligible reason, and never shows on an empty or
/// errored batch. Only the presentational widget had been tested in
/// isolation, so nothing ever mounted MatchesTab with the panel -- which is
/// how the remount bug below survived.
DailyMatchesResult _result({int count = 3}) => DailyMatchesResult.fromJson({
      'matches': [
        for (var i = 0; i < count; i++)
          {
            'user': {
              '_id': 'u$i',
              'name': 'Partner $i',
              'native_language': 'Korean',
              'language_to_learn': 'English',
            },
            'matchReasons': const <String>[],
          },
      ],
    });

Community _user({required bool isNew}) => Community(
      id: 'me',
      appleId: '',
      googleId: '',
      name: 'Me',
      email: '',
      mbti: '',
      bloodType: '',
      bio: '',
      images: const [],
      birth_day: '',
      birth_month: '',
      gender: '',
      birth_year: '',
      native_language: 'English',
      language_to_learn: 'Korean',
      imageUrls: const [],
      createdAt: DateTime.now()
          .subtract(Duration(days: isNew ? 1 : 60))
          .toIso8601String(),
      version: 0,
      followers: const [],
      followings: const [],
      location: Location.defaultLocation(),
    );

Widget _wrap({
  required bool isNew,
  required FirstSessionState session,
  DailyMatchesResult? result,
  bool fail = false,
}) =>
    ProviderScope(
      overrides: [
        userProvider.overrideWith((ref) async => _user(isNew: isNew)),
        firstSessionStateProvider.overrideWith((ref) async => session),
        dailyMatchesProvider.overrideWith((ref) async {
          if (fail) throw Exception('boom');
          return result ?? _result();
        }),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: MatchesTab()),
      ),
    );

const _fresh = FirstSessionState(hasMessaged: false, timesShown: 0);

void main() {
  testWidgets('an eligible new user sees the panel', (tester) async {
    await tester.pumpWidget(_wrap(isNew: true, session: _fresh));
    await tester.pumpAndSettle();
    expect(find.byType(MatchesFirstSessionPanel), findsOneWidget);
  });

  testWidgets('an established account does not', (tester) async {
    await tester.pumpWidget(_wrap(isNew: false, session: _fresh));
    await tester.pumpAndSettle();
    expect(find.byType(MatchesFirstSessionPanel), findsNothing);
  });

  testWidgets('a user who has already messaged does not', (tester) async {
    await tester.pumpWidget(_wrap(
      isNew: true,
      session: const FirstSessionState(hasMessaged: true, timesShown: 0),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(MatchesFirstSessionPanel), findsNothing);
  });

  testWidgets('a user past the view cap does not', (tester) async {
    await tester.pumpWidget(_wrap(
      isNew: true,
      session: const FirstSessionState(
          hasMessaged: false, timesShown: kMaxGuidanceViews),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(MatchesFirstSessionPanel), findsNothing);
  });

  testWidgets('an errored batch shows no panel', (tester) async {
    await tester.pumpWidget(_wrap(isNew: true, session: _fresh, fail: true));
    await tester.pumpAndSettle();
    expect(find.byType(MatchesFirstSessionPanel), findsNothing);
  });

  testWidgets('an empty batch shows no panel', (tester) async {
    await tester.pumpWidget(
        _wrap(isNew: true, session: _fresh, result: _result(count: 0)));
    await tester.pumpAndSettle();
    expect(find.byType(MatchesFirstSessionPanel), findsNothing);
  });

  testWidgets('the panel replaces the header rather than stacking on it',
      (tester) async {
    // The spec says the panel OCCUPIES the header slot. Stacked, a new user
    // read "3 people picked for you today" then "Your 3 matches today" then
    // the refresh hint -- the same number twice, three lines where two were
    // specified.
    await tester.pumpWidget(_wrap(isNew: true, session: _fresh));
    await tester.pumpAndSettle();

    expect(find.byType(MatchesFirstSessionPanel), findsOneWidget);
    expect(find.textContaining('matches today'), findsNothing,
        reason: 'the usual header must give way to the panel, not sit under it');
  });

  testWidgets('the usual header returns once the panel is gone',
      (tester) async {
    await tester.pumpWidget(_wrap(
      isNew: true,
      session: const FirstSessionState(hasMessaged: true, timesShown: 0),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(MatchesFirstSessionPanel), findsNothing);
    expect(find.textContaining('matches today'), findsOneWidget);
  });

  testWidgets('the panel offers the live tab as a quiet secondary',
      (tester) async {
    // A new user whose six matches are all asleep has nothing else to do on
    // this screen. The live tab is the one other thing Community offers on
    // arrival, so the panel names it -- quietly, beside the action it is
    // actually pointing at.
    await tester.pumpWidget(_wrap(isNew: true, session: _fresh));
    await tester.pumpAndSettle();

    expect(find.descendant(
      of: find.byType(MatchesFirstSessionPanel),
      matching: find.byType(InkWell),
    ), findsOneWidget, reason: 'exactly one button on the panel itself');
  });

  testWidgets("the panel's one button is the live tab, not another Say hi",
      (tester) async {
    // The panel's primary action is Say hi on the card BELOW it. A Say hi
    // pill up here would compete with the button it is ringing -- so the one
    // button it does carry must be the other destination.
    //
    // Asserted on the label rather than on "no Say hi anywhere": the panel's
    // own body copy reads "Say hi -- a first message is all it takes", so a
    // textContaining check passes for the wrong reason and would keep passing
    // if a real Say hi button were added.
    await tester.pumpWidget(_wrap(isNew: true, session: _fresh));
    await tester.pumpAndSettle();

    final button = find.descendant(
      of: find.byType(MatchesFirstSessionPanel),
      matching: find.byType(InkWell),
    );
    expect(button, findsOneWidget);
    // appConfig is not overridden here, so gatheringsEnabled falls back to
    // its default of true -- the same default CommunityTabBar uses.
    expect(find.descendant(of: button, matching: find.text('Gatherings')),
        findsOneWidget);
  });

  testWidgets('tapping it requests the live sub-tab', (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(_wrap(isNew: true, session: _fresh));
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MatchesTab)),
    );

    expect(container.read(communityPendingSubTabProvider), isNull);

    await tester.tap(find.descendant(
      of: find.byType(MatchesFirstSessionPanel),
      matching: find.byType(InkWell),
    ));
    await tester.pumpAndSettle();

    // Slot 2 holds Gatherings or Voice Rooms depending on a server flag, so
    // one index is right either way -- and CommunityMain is what listens.
    expect(container.read(communityPendingSubTabProvider),
        communityVoiceRoomsSubTab);
  });

  testWidgets('the guide rings exactly one Say hi button', (tester) async {
    // The panel says "say hi" but carries no button of its own, so something
    // has to say WHICH button. Three cards ringing at once is a page
    // flashing, not a page pointing.
    await tester.pumpWidget(_wrap(isNew: true, session: _fresh));
    await tester.pumpAndSettle();

    final rings = tester
        .widgetList<PulseHighlight>(find.byType(PulseHighlight))
        .where((w) => w.enabled)
        .length;
    expect(rings, 1);
  });

  testWidgets('no Say hi is ringed once the guide is gone', (tester) async {
    await tester.pumpWidget(_wrap(
      isNew: true,
      session: const FirstSessionState(hasMessaged: true, timesShown: 0),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(MatchesFirstSessionPanel), findsNothing);
    final rings = tester
        .widgetList<PulseHighlight>(find.byType(PulseHighlight))
        .where((w) => w.enabled)
        .length;
    expect(rings, 0,
        reason: 'an established user does not need their buttons ringed');
  });

  testWidgets('the panel does not vanish from under the user mid-view',
      (tester) async {
    // On the third eligible view the stored count reaches the cap. If the
    // provider is invalidated while the panel is on screen, it is removed
    // milliseconds after appearing and the list jumps by the panel height --
    // exactly as the user reaches for the first card.
    await tester.pumpWidget(_wrap(
      isNew: true,
      session: const FirstSessionState(
          hasMessaged: false, timesShown: kMaxGuidanceViews - 1),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(MatchesFirstSessionPanel), findsOneWidget,
        reason: 'the third view must stay put for the whole visit');
  });
}
