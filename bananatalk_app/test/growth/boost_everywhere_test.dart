import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/models/boost.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/widgets/boost/boost_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/moment_fixture.dart';

/// Profile Boost beyond the daily matches (2026-10-17): the booster's latest
/// moment is labelled in the feed, and the Partners list (where the server
/// places a booster 3rd on page 1) never lists the same person twice.
class _PagedService implements CommunityService {
  final pages = <int, List<String>>{};

  @override
  Future<PaginatedCommunityResponse> getCommunityPaginated({
    int page = 1,
    int limit = 20,
    String? nativeLanguage,
    String? learningLanguage,
    bool matchLanguage = false,
    String? gender,
    int? minAge,
    int? maxAge,
    bool? onlineOnly,
    String? country,
    String? languageLevel,
    String? search,
    String? sort,
    bool reciprocal = false,
    String? activeWithin,
    String? joinedWithin,
    List<String> topics = const [],
    int topicsAtLeast = 0,
  }) async =>
      PaginatedCommunityResponse(
        users: (pages[page] ?? const <String>[])
            .map((id) => Community.fromJson({'_id': id, 'name': id}))
            .toList(),
        total: 4,
        page: page,
        pages: 2,
        hasMore: page < 2,
      );

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test('Moments.fromJson reads boosted', () {
    expect(Moments.fromJson({'_id': 'm', 'boosted': true}).boosted, isTrue);
    expect(Moments.fromJson({'_id': 'm'}).boosted, isFalse);
  });

  testWidgets('a boosted moment card says Boosted; others do not',
      (tester) async {
    Widget host(Moments m) => ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(child: MomentCard(moments: m)),
            ),
          ),
        );

    await tester.pumpWidget(host(buildMoment().copyWith(boosted: true)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('moment-boosted')), findsOneWidget);
    expect(find.text('Boosted'), findsOneWidget);

    await tester.pumpWidget(host(buildMoment(id: 'plain')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('moment-boosted')), findsNothing);
  });

  test('Partners paging lists a booster placed on page 1 only once', () async {
    final svc = _PagedService()
      ..pages[1] = ['a', 'booster']
      ..pages[2] = ['booster', 'c'];
    final n = PartnerFilterNotifier(svc, () => false);
    await n.loadWithFilters(const PartnerFilterParams());
    await n.loadMore();
    expect(n.state.users.map((u) => u.id), ['a', 'booster', 'c']);
  });

  entryRowTests();
}

AppConfig _config({required bool boosts}) => AppConfig(
      minVersion: '0',
      latestVersion: '0',
      forceUpdate: false,
      iosUrl: '',
      androidUrl: '',
      releaseNotes: '',
      boostsEnabled: boosts,
    );

Widget _entryHost({required bool boosts, Boost? active}) => ProviderScope(
      overrides: [
        appConfigProvider.overrideWith((ref) async => _config(boosts: boosts)),
        myActiveBoostProvider.overrideWith((ref) async => active),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BoostEntryRow()),
      ),
    );

void entryRowTests() {
  testWidgets('entry row: nothing while boosts are off', (tester) async {
    await tester.pumpWidget(_entryHost(boosts: false));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('boost-entry-row')), findsNothing);
  });

  testWidgets('entry row: offers a Boost when none is live', (tester) async {
    await tester.pumpWidget(_entryHost(boosts: true));
    await tester.pumpAndSettle();
    expect(find.text('Boost my profile'), findsOneWidget);
  });

  testWidgets('entry row: shows the live boost and its time left', (tester) async {
    await tester.pumpWidget(_entryHost(
      boosts: true,
      active: Boost(
        id: 'b1',
        status: 'active',
        endsAt: DateTime.now().add(const Duration(hours: 5, minutes: 10)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Your boost is live'), findsOneWidget);
    expect(find.textContaining('left'), findsOneWidget);
  });

  testWidgets('own moment menu offers Boost; someone else\'s does not',
      (tester) async {
    Future<void> openMenu(String myId) async {
      SharedPreferences.setMockInitialValues({'userId': myId});
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appConfigProvider.overrideWith((ref) async => _config(boosts: true)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Consumer(builder: (context, ref, _) {
                // Loaded at startup in the app; load it here the same way.
                ref.watch(appConfigProvider);
                return MomentCard(moments: buildMoment());
              }),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byIcon(Icons.more_horiz).first);
      await tester.pumpAndSettle();
    }

    await openMenu('author-m1'); // buildMoment's author
    expect(find.byKey(const Key('moment-menu-boost')), findsOneWidget);

    await openMenu('someone-else');
    expect(find.byKey(const Key('moment-menu-boost')), findsNothing);
  });
}
