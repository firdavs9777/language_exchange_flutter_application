import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/l10n/app_localizations_en.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/pages/community/gatherings/club_detail_screen.dart';
import 'package:bananatalk_app/pages/community/rooms/club_notice_banner.dart';
import 'package:bananatalk_app/pages/community/rooms/room_screen.dart' show roomMenuActions;
import 'package:bananatalk_app/providers/provider_root/clubs_v2_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';

/// Clubs v2 slice 2: a member opens the club's chat from the club page; the
/// organizers' notice shows on the page and atop the chat.
class _FakeApi extends GatheringApiClient {
  _FakeApi(this.club, {this.access = true, this.roomId = 'r1'});
  Club club;
  final bool access;
  final String? roomId;
  int chatCalls = 0;
  String? sentNotice;

  @override
  Future<bool> getClubsV2Access() async => access;

  @override
  Future<Club?> getClub(String id) async => club;

  @override
  Future<String?> getClubChatRoomId(String clubId) async {
    chatCalls++;
    return roomId;
  }

  @override
  Future<GatheringResult<Club>> updateClub(
    String id, {
    String? name,
    String? description,
    String? interest,
    String? city,
    String? placeName,
    String? placeAddress,
    String? secondLanguage,
    List<String>? rules,
    String? notice,
    String? format,
    bool? joinApproval,
  }) async {
    sentNotice = notice;
    return GatheringResult.ok(club);
  }
}

final en = AppLocalizationsEn();

Club _club({bool member = true, bool owner = false, String notice = 'Sat 8am, exit 2'}) => Club.fromJson({
      '_id': 'c1',
      'name': 'Hangang Running',
      'language': 'en',
      'memberCount': 2,
      'notice': notice,
      'owner': {'_id': 'o1', 'name': 'Owner'},
      'viewerIsMember': member,
      'viewerIsOwner': owner,
      'viewerCanManage': owner,
    });

Widget _app(_FakeApi api, {void Function(String roomId)? onOpen}) => ProviderScope(
      overrides: [
        clubsV2ApiProvider.overrideWithValue(api),
        clubMomentsProvider.overrideWith((ref, id) async => const []),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ClubDetailScreen(
          clubId: 'c1',
          apiClient: api,
          openRoom: onOpen == null ? null : (_, id) => onOpen(id),
        ),
      ),
    );

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  test('a club room parses its club and notice', () {
    final room = Room.fromJson({
      '_id': 'r1', 'title': 'Hangang Running', 'roomType': 'club',
      'clubId': 'c1', 'clubNotice': 'Sat 8am', 'isMember': true,
    });
    expect(room.isClubRoom, isTrue);
    expect(room.clubId, 'c1');
    expect(room.clubNotice, 'Sat 8am');
    expect(Room.fromJson({'_id': 'r2', 'roomType': 'topic'}).isClubRoom, isFalse);
    expect(room.copyWith(memberCount: 3).clubNotice, 'Sat 8am');
  });

  testWidgets('the notice banner shows text, and nothing when empty', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: ClubNoticeBanner(notice: 'Sat 8am')),
    ));
    expect(find.text('Sat 8am'), findsOneWidget);
    expect(find.text(en.clubNoticeTitle), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ClubNoticeBanner(notice: ''))));
    expect(find.byKey(const Key('club-notice-banner')), findsNothing);
  });

  testWidgets('a member with access opens the chat', (tester) async {
    _tall(tester);
    String? opened;
    final api = _FakeApi(_club());
    await tester.pumpWidget(_app(api, onOpen: (id) => opened = id));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('club-notice')), findsOneWidget);
    await tester.tap(find.byKey(const Key('club-chat')));
    await tester.pumpAndSettle();
    expect(api.chatCalls, 1);
    expect(opened, 'r1');
  });

  testWidgets('a failed open says so', (tester) async {
    _tall(tester);
    final api = _FakeApi(_club(), roomId: null);
    await tester.pumpWidget(_app(api, onOpen: (_) {}));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('club-chat')));
    await tester.pumpAndSettle();
    expect(find.text(en.clubChatFailed), findsOneWidget);
  });

  testWidgets('no chat button for non-members or without access; no notice without access', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_FakeApi(_club(member: false))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('club-chat')), findsNothing);
  });

  testWidgets('without access: no chat, no notice', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_FakeApi(_club(), access: false)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('club-chat')), findsNothing);
    expect(find.byKey(const Key('club-notice')), findsNothing);
  });

  testWidgets('the owner edits the notice', (tester) async {
    _tall(tester);
    final api = _FakeApi(_club(owner: true));
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('club-owner-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.clubEdit).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('club-edit-notice')), 'Sunday this week');
    await tester.ensureVisible(find.byKey(const Key('club-edit-save')));
    await tester.tap(find.byKey(const Key('club-edit-save')));
    await tester.pumpAndSettle();
    expect(api.sentNotice, 'Sunday this week');
  });

  test('a club chat\'s top-bar menu offers no Leave or Members', () {
    Room room(String type) => Room.fromJson({
          '_id': 'r', 'roomType': type, 'isMember': true, 'isOwnerOrAdmin': true,
          'pendingRequestCount': 2,
        });
    expect(roomMenuActions(room('topic')), ['requests', 'members', 'leave']);
    expect(roomMenuActions(room('club')), isEmpty);
  });
}
