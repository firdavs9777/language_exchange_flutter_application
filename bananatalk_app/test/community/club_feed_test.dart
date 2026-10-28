import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/l10n/app_localizations_en.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/gatherings/club_detail_screen.dart';
import 'package:bananatalk_app/pages/moments/card/moment_activity_chip.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/clubs_v2_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';

/// Clubs v2 slice 3: club posts on the club page.
class _FakeApi extends GatheringApiClient {
  _FakeApi(this.club, {this.access = true});
  Club club;
  final bool access;
  @override
  Future<bool> getClubsV2Access() async => access;
  @override
  Future<Club?> getClub(String id) async => club;
}

final en = AppLocalizationsEn();

Club _club({bool member = true}) => Club.fromJson({
      '_id': 'c1', 'name': 'Hangang Running', 'language': 'en', 'memberCount': 2,
      'owner': {'_id': 'o1', 'name': 'Owner'}, 'viewerIsMember': member,
    });

Moments _post(String id, String text, {Map<String, dynamic>? activity}) => Moments.fromJson({
      '_id': id, 'description': text, 'privacy': 'club', 'club': 'c1',
      'user': {'_id': 'u1', 'name': 'Mina'},
      if (activity != null) 'activity': activity,
    });

Widget _app(_FakeApi api, {List<Moments> posts = const [], void Function(String)? onCompose}) => ProviderScope(
      overrides: [
        clubsV2ApiProvider.overrideWithValue(api),
        clubMomentsProvider.overrideWith((ref, id) async => posts),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ClubDetailScreen(
          clubId: 'c1',
          apiClient: api,
          openComposer: onCompose == null ? null : (_, id) async => onCompose(id),
        ),
      ),
    );

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('the activity chip reads distance, time and pace', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
          body: MomentActivityChip(activity: MomentActivity(distanceM: 5200, durationS: 1860))),
    ));
    expect(find.text('5.2 km · 31:00 · 5:58/km'), findsOneWidget);
  });

  testWidgets('members with access see club posts and can post one', (tester) async {
    _tall(tester);
    String? composedFor;
    await tester.pumpWidget(_app(
      _FakeApi(_club()),
      posts: [_post('m1', 'Tempo run', activity: {'distanceM': 5000, 'durationS': 1500})],
      onCompose: (id) => composedFor = id,
    ));
    await tester.pumpAndSettle();
    expect(find.text(en.clubPostsTitle), findsOneWidget);
    expect(find.text('Tempo run'), findsOneWidget);
    expect(find.text('5 km · 25:00 · 5:00/km'), findsOneWidget);
    await tester.tap(find.byKey(const Key('club-post-record')));
    await tester.pumpAndSettle();
    expect(composedFor, 'c1');
  });

  testWidgets('an empty club shows the empty state', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_FakeApi(_club())));
    await tester.pumpAndSettle();
    expect(find.text(en.clubPostsEmpty), findsOneWidget);
  });

  testWidgets('no posts section for non-members or without access', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_FakeApi(_club(member: false)), posts: [_post('m1', 'x')]));
    await tester.pumpAndSettle();
    expect(find.text(en.clubPostsTitle), findsNothing);
  });

  testWidgets('without access: no posts section', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_FakeApi(_club(), access: false), posts: [_post('m1', 'x')]));
    await tester.pumpAndSettle();
    expect(find.text(en.clubPostsTitle), findsNothing);
  });
}
