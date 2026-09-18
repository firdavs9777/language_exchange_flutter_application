import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/gatherings/create_gathering_form.dart';
import 'package:bananatalk_app/pages/community/gatherings/gatherings_tab.dart';
import 'package:bananatalk_app/pages/community/main/community_tab_bar.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';

/// A client that answers from memory. Widget tests must never touch the
/// network, and the states worth testing here (nothing scheduled at all) are
/// precisely the ones a live server would not reliably produce.
class _FakeApi extends GatheringApiClient {
  _FakeApi({this.clubs = const [], this.gatherings = const []});

  final List<Club> clubs;
  final List<Gathering> gatherings;

  /// The filters the tab actually sent, so a test can assert that narrowing
  /// reaches the server rather than being applied to an already-fetched page.
  String? lastTopic;
  String? lastWhen;
  bool lastHasSeat = false;

  @override
  Future<List<Club>> getClubs({
    String? language,
    String? interest,
    String scope = 'mine',
    int page = 1,
  }) async => clubs;

  @override
  Future<List<Gathering>> getGatherings({
    String? language,
    String? level,
    String scope = 'mine',
    int page = 1,
    String? topic,
    String? when,
    bool hasSeat = false,
  }) async {
    lastTopic = topic;
    lastWhen = when;
    lastHasSeat = hasSeat;
    return gatherings;
  }
}

Gathering _gathering({String id = 'g1', String title = 'Korean evening'}) =>
    Gathering(
      id: id,
      title: title,
      startsAt: DateTime.now().add(const Duration(days: 1)),
      languageLabel: 'Korean',
      going: 2,
      needed: 1,
    );

Club _club({String id = 'c1', String name = 'Korean Learners Club'}) =>
    Club(id: id, name: name, languageLabel: 'Korean', memberCount: 49);

Widget _host(GatheringApiClient api) => ProviderScope(
  overrides: [
    // Never completes: the tab only reads this to pre-fill a language, and a
    // real `userProvider` would make a network call.
    userProvider.overrideWith((ref) => Completer<Community>().future),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: GatheringsTab(apiClient: api),
  ),
);

void main() {
  group('the empty state is a create form, not an apology', () {
    testWidgets('nothing scheduled renders the pre-filled draft', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_FakeApi()));
      await tester.pumpAndSettle();

      // THE assertion from the plan. An empty list is the exact impression
      // that killed voice rooms 93 times; the fix is a draft the viewer can
      // post, not a message telling them there is nothing here.
      expect(
        find.byKey(const Key('gatherings_empty_create_form')),
        findsOneWidget,
        reason: 'the empty state must BE the create form',
      );
      expect(find.byType(CreateGatheringForm), findsOneWidget);

      // And the form is actually usable, not a decorative promise: the
      // post button is the thing one tap lands on.
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.gatheringPost), findsOneWidget);
      expect(find.text(l10n.gatheringEmptyTitle), findsOneWidget);
    });

    testWidgets('a club with nothing scheduled still shows the strip', (
      tester,
    ) async {
      // The whole argument for making the club the primary entity: on a day
      // with nothing scheduled, "49 members" is what stops the tab reading
      // as abandoned.
      await tester.pumpWidget(_host(_FakeApi(clubs: [_club()])));
      await tester.pumpAndSettle();

      // Clubs have their own tab now; the count on the tab label is what
      // carries the "not abandoned" signal from the Gatherings side.
      expect(find.textContaining('1'), findsWidgets);

      await tester.tap(find.byKey(const Key('clubs-inner-tab')));
      await tester.pumpAndSettle();

      expect(find.text('Korean Learners Club'), findsOneWidget);
      expect(find.textContaining('49'), findsOneWidget);

      await tester.tap(find.byKey(const Key('gatherings-inner-tab')));
      await tester.pumpAndSettle();
      // Still offers the draft, because there is nothing to attend yet.
      expect(
        find.byKey(const Key('gatherings_empty_create_form')),
        findsOneWidget,
      );
    });

    testWidgets('with gatherings, the list replaces the form', (tester) async {
      await tester.pumpWidget(
        _host(_FakeApi(gatherings: [_gathering(), _gathering(id: 'g2')])),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gatherings_empty_create_form')), findsNothing);
      expect(find.text('Korean evening'), findsNWidgets(2));
    });
  });

  group('모임 replaces the voice-rooms tab without changing the tab count', () {
    /// Counts the tabs the bar actually builds for a given flag combination.
    Future<int> tabCount(
      WidgetTester tester, {
      required bool gatheringsEnabled,
      required bool showRoomsTab,
    }) async {
      final controller = TabController(
        length: showRoomsTab ? 8 : 7,
        vsync: const TestVSync(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // The waves badge fires a real request otherwise, which outlives
            // the widget tree and trips the pending-timer check.
            wavesUnreadProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CommunityTabBar(
                tabController: controller,
                showRoomsTab: showRoomsTab,
                gatheringsEnabled: gatheringsEnabled,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The strip renders teal pill chips now, not Material Tabs. The
      // invariant under test is unchanged -- 모임 must take the voice-rooms
      // SLOT rather than adding a ninth entry -- so this counts the chips.
      return tester
          .widgetList(find.byWidgetPredicate((w) =>
              w.key is ValueKey<String> &&
              (w.key as ValueKey<String>).value.startsWith('community-chip-')))
          .length;
    }

    testWidgets('the count is identical with the switch on and off', (
      tester,
    ) async {
      // 모임 is NOT a ninth tab. It takes the voice-rooms slot, so flipping
      // the switch must never add or remove one — if it did, the tab count
      // would disagree with the TabController's length and the index
      // arithmetic in `remapTabIndexForRoomsFlag` would be operating on a
      // list that no longer matches.
      final on = await tabCount(
        tester,
        gatheringsEnabled: true,
        showRoomsTab: true,
      );
      final off = await tabCount(
        tester,
        gatheringsEnabled: false,
        showRoomsTab: true,
      );
      expect(on, off);
      expect(on, 8, reason: 'Community keeps 8 tabs with Rooms enabled');
    });

    testWidgets('the switch changes the label, not the structure', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tabCount(tester, gatheringsEnabled: true, showRoomsTab: true);
      expect(find.text(l10n.gatheringsTabLabel), findsOneWidget);
      expect(find.text(l10n.voiceRooms), findsNothing);

      await tabCount(tester, gatheringsEnabled: false, showRoomsTab: true);
      expect(find.text(l10n.voiceRooms), findsOneWidget);
      expect(find.text(l10n.gatheringsTabLabel), findsNothing);
    });

    testWidgets('the rooms flag still controls the count on its own', (
      tester,
    ) async {
      // Guards the interaction: the 모임 switch must not disturb the one
      // flag that IS allowed to change the tab count.
      final withRooms = await tabCount(
        tester,
        gatheringsEnabled: true,
        showRoomsTab: true,
      );
      final withoutRooms = await tabCount(
        tester,
        gatheringsEnabled: true,
        showRoomsTab: false,
      );
      expect(withRooms - withoutRooms, 1);
    });
  });

  testWidgets('a club can be started even when gatherings already exist',
      (tester) async {
    // The gap: the "New club" header rendered only when clubs.isNotEmpty, and
    // the empty state's "Start a club instead" only when gatherings.isEmpty.
    // With no clubs but one gathering, neither did -- so a first club could
    // never be created once anything at all was scheduled.
    final api = _FakeApi(clubs: const [], gatherings: [_gathering()]);
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('clubs-inner-tab')));
    await tester.pumpAndSettle();

    // "New club" is the header action; before the fix it was gated on already
    // having clubs, so a first club was unreachable in exactly this state.
    expect(find.text('New club'), findsOneWidget);
  });

  testWidgets('clubs and gatherings are separate tabs', (tester) async {
    final api = _FakeApi(clubs: [_club()], gatherings: [_gathering()]);
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    // Gatherings lead: the tab is named for them and its empty state is a
    // create form, which is what covers a day with nothing scheduled.
    expect(find.text('Korean evening'), findsOneWidget);
    expect(find.text('Korean Learners Club'), findsNothing);

    await tester.tap(find.byKey(const Key('clubs-inner-tab')));
    await tester.pumpAndSettle();

    expect(find.text('Korean Learners Club'), findsOneWidget);
    expect(find.text('Korean evening'), findsNothing);
  });

  testWidgets('filtering refetches from the server, not the fetched page',
      (tester) async {
    // Narrowing a page already in hand would show three of thirty results and
    // call it "all". The filters have to reach the query.
    final api = _FakeApi(clubs: const [], gatherings: [_gathering()]);
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    expect(api.lastHasSeat, isFalse, reason: 'no filter on first load');
    expect(find.byKey(const Key('filter-has-seat')), findsOneWidget,
        reason: 'the bar must be present to be tapped');

    await tester.tap(find.byKey(const Key('filter-has-seat')));
    await tester.pumpAndSettle();

    expect(api.lastHasSeat, isTrue);
  });

  testWidgets('the filter bar is hidden until it is needed on an empty list',
      (tester) async {
    // Nothing scheduled at all: the create form is the right thing to show,
    // and a row of chips that would narrow nothing is noise.
    final api = _FakeApi(clubs: const [], gatherings: const []);
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('filter-has-seat')), findsNothing);
    expect(find.byKey(const Key('gatherings_empty_create_form')), findsOneWidget);
  });
}
