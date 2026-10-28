import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/l10n/app_localizations_en.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/gatherings/club_detail_screen.dart';
import 'package:bananatalk_app/providers/provider_root/clubs_v2_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';
import 'package:bananatalk_app/services/notification_router.dart';

/// Clubs v2: organizers warn a member citing a rule; at the 3rd warning the
/// host is ASKED whether to remove them; "Remove now" needs a reason. Members
/// see their own count. Without access the member menu is as before.
class _FakeApi extends GatheringApiClient {
  _FakeApi(this.club, {this.access = true, this.promptRemoval = false});
  Club club;
  final bool access;
  final bool promptRemoval;
  final warned = <String>[];
  final removed = <({String userId, bool ban, String? reason})>[];

  @override
  Future<bool> getClubsV2Access() async => access;

  @override
  Future<Club?> getClub(String id) async => club;

  @override
  Future<GatheringResult<({int warningCount, bool promptRemoval})>> warnClubMember(
    String clubId,
    String userId, {
    required String rule,
    String? note,
  }) async {
    warned.add(rule);
    return GatheringResult.ok((warningCount: promptRemoval ? 3 : 1, promptRemoval: promptRemoval));
  }

  @override
  Future<GatheringResult<bool>> removeClubMember(
    String clubId,
    String userId, {
    bool ban = false,
    String? reason,
  }) async {
    removed.add((userId: userId, ban: ban, reason: reason));
    return const GatheringResult.ok(true);
  }
}

final en = AppLocalizationsEn();

Club _club({bool manager = true, int ownWarnings = 0, int minaWarnings = 0}) => Club.fromJson({
      '_id': 'c1',
      'name': 'Hangang Running',
      'language': 'en',
      'rules': ['Be kind.', 'No selling.'],
      'memberCount': 2,
      'owner': {'_id': 'o1', 'name': 'Owner'},
      'viewerIsMember': true,
      'viewerIsOwner': manager,
      'viewerCanManage': manager,
      'viewerWarningCount': ownWarnings,
      'members': [
        {'_id': 'o1', 'name': 'Owner', 'role': 'owner'},
        {'_id': 'm1', 'name': 'Mina', 'role': 'member', 'warningCount': minaWarnings},
      ],
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

/// The club page is long; a tall test screen keeps the member row on it.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.longPress(find.text('Mina'));
  await tester.pumpAndSettle();
}

void main() {
  test('a club_warning tap opens the club', () {
    expect(NotificationRouter.targetPathForType('club_warning', const {'clubId': 'c1'}), '/club/c1');
    expect(NotificationRouter.targetPathForType('club_warning', const {}), '/tabs/1');
  });

  testWidgets('warn with a rule; no prompt before the third', (tester) async {
    final api = _FakeApi(_club());
    _tall(tester);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await _openMenu(tester);

    await tester.tap(find.text(en.clubWarnMember));
    await tester.pumpAndSettle();
    expect(find.text(en.clubWarnTitle('Mina')), findsOneWidget);
    await tester.tap(find.text('No selling.'));
    await tester.pump();
    await tester.tap(find.text(en.clubWarnSend));
    await tester.pumpAndSettle();

    expect(api.warned, ['No selling.']);
    expect(find.text(en.clubRemoveAfterWarningsTitle('Mina')), findsNothing);
    expect(api.removed, isEmpty);
  });

  testWidgets('the third warning asks the host, and Remove bans', (tester) async {
    final api = _FakeApi(_club(), promptRemoval: true);
    _tall(tester);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await _openMenu(tester);
    await tester.tap(find.text(en.clubWarnMember));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Be kind.'));
    await tester.pump();
    await tester.tap(find.text(en.clubWarnSend));
    await tester.pumpAndSettle();

    expect(find.text(en.clubRemoveAfterWarningsTitle('Mina')), findsOneWidget);
    await tester.tap(find.byKey(const Key('club-remove-after-warnings')));
    await tester.pumpAndSettle();
    expect(api.removed.single.userId, 'm1');
    expect(api.removed.single.ban, isTrue);
  });

  testWidgets('"Not now" removes nobody', (tester) async {
    final api = _FakeApi(_club(), promptRemoval: true);
    _tall(tester);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await _openMenu(tester);
    await tester.tap(find.text(en.clubWarnMember));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Be kind.'));
    await tester.pump();
    await tester.tap(find.text(en.clubWarnSend));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.clubNotNow));
    await tester.pumpAndSettle();
    expect(api.removed, isEmpty);
  });

  testWidgets('remove now needs a reason, then bans and reports', (tester) async {
    final api = _FakeApi(_club());
    _tall(tester);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await _openMenu(tester);
    await tester.tap(find.text(en.clubRemoveNow));
    await tester.pumpAndSettle();

    final submit = find.byKey(const Key('club-remove-now-confirm'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('club-remove-now-reason')), 'harassed a member');
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(api.removed.single.ban, isTrue);
    expect(api.removed.single.reason, 'harassed a member');
  });

  testWidgets('managers see a member\'s count', (tester) async {
    final api = _FakeApi(_club(minaWarnings: 2));
    _tall(tester);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('club-member-warnings-m1')), findsOneWidget);
  });

  testWidgets('a warned member sees their own count', (tester) async {
    final memberApi = _FakeApi(_club(manager: false, ownWarnings: 2));
    _tall(tester);
    await tester.pumpWidget(_app(memberApi));
    await tester.pumpAndSettle();
    expect(find.text(en.clubYourWarnings(2)), findsOneWidget);
  });

  testWidgets('without access: no Warn, no Remove now, no counts', (tester) async {
    final api = _FakeApi(_club(minaWarnings: 2, ownWarnings: 1), access: false);
    _tall(tester);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('club-member-warnings-m1')), findsNothing);
    expect(find.text(en.clubYourWarnings(1)), findsNothing);
    await _openMenu(tester);
    expect(find.text(en.clubWarnMember), findsNothing);
    expect(find.text(en.clubRemoveNow), findsNothing);
    expect(find.text(en.clubRemoveMember), findsOneWidget);
  });
}
