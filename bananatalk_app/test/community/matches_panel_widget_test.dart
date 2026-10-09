import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';
import 'package:bananatalk_app/pages/community/first_session/matches_first_session_panel.dart';
import 'package:bananatalk_app/pages/community/tabs/matches_tab.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/daily_matches_provider.dart';

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
      session: const FirstSessionState(hasMessaged: false, timesShown: 3),
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

  testWidgets('the panel does not vanish from under the user mid-view',
      (tester) async {
    // On the third eligible view the stored count reaches the cap. If the
    // provider is invalidated while the panel is on screen, it is removed
    // milliseconds after appearing and the list jumps by the panel height --
    // exactly as the user reaches for the first card.
    await tester.pumpWidget(_wrap(
      isNew: true,
      session: const FirstSessionState(hasMessaged: false, timesShown: 2),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(MatchesFirstSessionPanel), findsOneWidget,
        reason: 'the third view must stay put for the whole visit');
  });
}
