import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/l10n/app_localizations_en.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/pages/community/gatherings/club_detail_screen.dart';
import 'package:bananatalk_app/pages/community/gatherings/club_rules.dart';
import 'package:bananatalk_app/pages/community/gatherings/create_club_sheet.dart';
import 'package:bananatalk_app/providers/provider_root/clubs_v2_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';

/// Clubs v2: the language pair and rules on create/edit, and the rules shown
/// before joining. With access off every screen renders exactly as before.
class _FakeApi extends GatheringApiClient {
  _FakeApi({this.club, this.access = false});
  Club? club;
  final bool access;
  List<String>? sentRules;
  String? sentSecondLanguage;

  @override
  Future<bool> getClubsV2Access() async => access;

  @override
  Future<Club?> getClub(String id) async => club;

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
    sentRules = rules;
    sentSecondLanguage = secondLanguage;
    return GatheringResult.ok(Club(id: 'new', name: name));
  }
}

final en = AppLocalizationsEn();

Widget _app(Widget child, {bool access = false, _FakeApi? api, bool page = false}) => ProviderScope(
      overrides: [
        clubsV2ApiProvider.overrideWithValue(api ?? _FakeApi(access: access)),
        // The club page loads club posts for members (slice 3).
        clubMomentsProvider.overrideWith((ref, id) async => const []),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page ? child : Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

Club _club({List<String> rules = const ['Be kind.', 'No selling.'], bool member = false}) =>
    Club.fromJson({
      '_id': 'c1',
      'name': 'Hangang Running',
      'language': 'en',
      'languageLabel': 'English',
      'secondLanguage': 'ko',
      'secondLanguageLabel': 'Korean',
      'rules': rules,
      'memberCount': 3,
      'owner': {'_id': 'o1', 'name': 'Owner'},
      'viewerIsMember': member,
    });

void main() {
  test('the language line shows the pair only with access', () {
    expect(clubLanguageLine(_club(), clubsV2: true), 'English ↔ Korean');
    expect(clubLanguageLine(_club(), clubsV2: false), 'English');
    expect(clubLanguageLine(Club(id: 'x', name: 'x', languageLabel: 'English'), clubsV2: true), 'English');
  });

  testWidgets('create sheet without access: no pair field, no rules editor', (tester) async {
    await tester.pumpWidget(_app(const CreateClubSheet(defaultLanguage: 'English')));
    expect(find.byKey(const Key('club-second-language')), findsNothing);
    expect(find.text(en.clubRulesTitle), findsNothing);
  });

  testWidgets('create sheet with access: 4 default rules, at most 10, sent on create',
      (tester) async {
    final api = _FakeApi(access: true);
    await tester.pumpWidget(_app(
      CreateClubSheet(defaultLanguage: 'English', clubsV2: true, apiClient: api),
      api: api,
    ));
    expect(find.byKey(const Key('club-second-language')), findsOneWidget);
    for (final rule in [en.clubRuleRespect, en.clubRuleBothLanguages, en.clubRuleNoSelling, en.clubRuleReleaseSeat]) {
      expect(find.text(rule), findsOneWidget);
    }
    for (var i = 0; i < 6; i++) {
      await tester.ensureVisible(find.byKey(const Key('club-rule-add')));
      await tester.tap(find.byKey(const Key('club-rule-add')));
      await tester.pump();
    }
    expect(find.byKey(const Key('club-rule-add')), findsNothing);
    expect(find.byKey(const Key('club-rule-9')), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Run & Talk');
    await tester.enterText(find.byKey(const Key('club-second-language')), 'Korean');
    await tester.ensureVisible(find.text(en.clubCreate));
    await tester.tap(find.text(en.clubCreate));
    await tester.pump();
    expect(api.sentSecondLanguage, 'Korean');
    expect(api.sentRules, [en.clubRuleRespect, en.clubRuleBothLanguages, en.clubRuleNoSelling, en.clubRuleReleaseSeat]);
  });

  testWidgets('club page with access: rules before joining, "Agree and join", the pair',
      (tester) async {
    final api = _FakeApi(club: _club(), access: true);
    await tester.pumpWidget(_app(ClubDetailScreen(clubId: 'c1', apiClient: api), api: api, page: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('club-rules')), findsOneWidget);
    expect(find.text('1. Be kind.'), findsOneWidget);
    expect(find.text(en.clubJoinAgree), findsOneWidget);
    expect(find.textContaining('English ↔ Korean'), findsOneWidget);
  });

  testWidgets('club page without access looks as before', (tester) async {
    final api = _FakeApi(club: _club(), access: false);
    await tester.pumpWidget(_app(ClubDetailScreen(clubId: 'c1', apiClient: api), api: api, page: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('club-rules')), findsNothing);
    expect(find.text(en.clubJoin), findsOneWidget);
    expect(find.textContaining('↔'), findsNothing);
  });

  testWidgets('a club with no rules keeps plain "Join" even with access', (tester) async {
    final api = _FakeApi(club: _club(rules: const []), access: true);
    await tester.pumpWidget(_app(ClubDetailScreen(clubId: 'c1', apiClient: api), api: api, page: true));
    await tester.pumpAndSettle();
    expect(find.text(en.clubJoin), findsOneWidget);
  });
}
