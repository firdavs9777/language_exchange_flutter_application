import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/l10n/app_localizations_en.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/gatherings/club_detail_screen.dart';
import 'package:bananatalk_app/pages/community/gatherings/create_club_sheet.dart';
import 'package:bananatalk_app/providers/provider_root/clubs_v2_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';
import 'package:bananatalk_app/services/notification_router.dart';

/// Clubs v2 slice 4: ask to join an approval club; hosts approve or decline.
class _FakeApi extends GatheringApiClient {
  _FakeApi(this.club, {this.access = true});
  Club club;
  final bool access;
  int joins = 0;
  int leaves = 0;
  final decided = <String, bool>{};

  @override
  Future<bool> getClubsV2Access() async => access;
  @override
  Future<Club?> getClub(String id) async => club;
  @override
  Future<GatheringResult<Club>> joinClub(String id) async {
    joins++;
    return GatheringResult.ok(club);
  }

  @override
  Future<GatheringResult<Club>> leaveClub(String id) async {
    leaves++;
    return GatheringResult.ok(club);
  }

  @override
  Future<List<ClubJoinRequest>?> getClubJoinRequests(String clubId) async => [
        ClubJoinRequest.fromJson({
          'user': {'_id': 'u9', 'name': 'Mina', 'native_language': 'Korean', 'language_to_learn': 'English'},
          'requestedAt': '2026-10-28T10:00:00Z',
          'meetupsAttended': 3,
        }),
      ];
  @override
  Future<bool> decideClubJoinRequest(String clubId, String userId, {required bool approve}) async {
    decided[userId] = approve;
    return true;
  }
}

final en = AppLocalizationsEn();

Club _club({bool member = false, bool pending = false, bool manager = false, int requests = 0, String format = 'offline'}) =>
    Club.fromJson({
      '_id': 'c1', 'name': 'Hangang Running', 'language': 'en', 'memberCount': 2,
      'owner': {'_id': 'o1', 'name': 'Owner'},
      'format': format, 'needsApproval': format == 'offline',
      'viewerIsMember': member, 'viewerIsOwner': manager, 'viewerCanManage': manager,
      'viewerRequestPending': pending,
      if (manager) 'pendingRequestCount': requests,
    });

Widget _app(_FakeApi api) => ProviderScope(
      overrides: [
        clubsV2ApiProvider.overrideWithValue(api),
        clubMomentsProvider.overrideWith((ref, id) async => const []),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ClubDetailScreen(clubId: 'c1', apiClient: api),
      ),
    );

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  test('club parses format, approval and the viewer request', () {
    final c = _club(pending: true, manager: true, requests: 2);
    expect(c.format, 'offline');
    expect(c.needsApproval, isTrue);
    expect(c.viewerRequestPending, isTrue);
    expect(c.pendingRequestCount, 2);
    final old = Club.fromJson({'_id': 'x', 'name': 'x'});
    expect(old.format, 'online');
    expect(old.needsApproval, isFalse);
  });

  test('a club_join_* tap opens the club', () {
    for (final t in ['club_join_request', 'club_join_approved', 'club_join_denied']) {
      expect(NotificationRouter.targetPathForType(t, const {'clubId': 'c1'}), '/club/c1');
    }
  });

  testWidgets('an approval club says "Ask to join"', (tester) async {
    _tall(tester);
    final api = _FakeApi(_club());
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    expect(find.text(en.gatheringAskToJoin), findsOneWidget);
    await tester.tap(find.text(en.gatheringAskToJoin));
    await tester.pumpAndSettle();
    expect(api.joins, 1);
  });

  testWidgets('a pending request shows, and can be withdrawn', (tester) async {
    _tall(tester);
    final api = _FakeApi(_club(pending: true));
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    expect(find.text(en.gatheringRequestPending), findsOneWidget);
    await tester.tap(find.text(en.gatheringWithdrawRequest));
    await tester.pumpAndSettle();
    expect(api.leaves, 1);
  });

  testWidgets('a host sees waiting requests and approves one', (tester) async {
    _tall(tester);
    final api = _FakeApi(_club(manager: true, member: true, requests: 1));
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.gatheringRequests(1)));
    await tester.pumpAndSettle();
    expect(find.text('Mina'), findsOneWidget);
    expect(find.textContaining(en.clubRequestMeetups(3)), findsOneWidget);
    expect(find.textContaining('Korean → English'), findsOneWidget);
    await tester.tap(find.text(en.clubApprove));
    await tester.pumpAndSettle();
    expect(api.decided, {'u9': true});
  });

  testWidgets('without access an approval club looks like before (plain Join)', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_FakeApi(_club(), access: false)));
    await tester.pumpAndSettle();
    expect(find.text(en.gatheringAskToJoin), findsNothing);
    expect(find.text(en.clubJoin), findsOneWidget);
  });

  testWidgets('creating an in-person club locks approval on and sends it', (tester) async {
    _tall(tester);
    final api = _CreateApi();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: CreateClubSheet(defaultLanguage: 'English', clubsV2: true, apiClient: api))),
    ));
    await tester.tap(find.text(en.clubFormatOffline));
    await tester.pump();
    expect(find.text(en.clubApprovalOfflineHint), findsOneWidget);
    final sw = tester.widget<SwitchListTile>(find.byKey(const Key('club-approval-switch')));
    expect(sw.value, isTrue);
    expect(sw.onChanged, isNull);
    await tester.enterText(find.byType(TextField).first, 'Hangang Running');
    await tester.ensureVisible(find.text(en.clubCreate));
    await tester.tap(find.text(en.clubCreate));
    await tester.pump();
    expect(api.format, 'offline');
  });

}

class _CreateApi extends GatheringApiClient {
  String? format;
  bool? approval;
  @override
  Future<bool> getClubsV2Access() async => true;
  @override
  Future<GatheringResult<Club>> createClub({
    required String name,
    required String language,
    String description = '',
    String interest = '',
    String? secondLanguage,
    List<String>? rules,
    String? format,
    bool? joinApproval,
  }) async {
    this.format = format;
    approval = joinApproval;
    return GatheringResult.ok(Club(id: 'n', name: name));
  }
}
