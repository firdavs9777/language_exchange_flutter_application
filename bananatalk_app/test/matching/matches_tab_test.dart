import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/tabs/matches_tab.dart';
import 'package:bananatalk_app/providers/provider_models/daily_match_model.dart';
import 'package:bananatalk_app/providers/provider_root/daily_matches_provider.dart';

DailyMatchesResult _result({DateTime? next}) =>
    DailyMatchesResult.fromJson({
      if (next != null) 'nextRefreshAt': next.toIso8601String(),
      'matches': [
        {
          'user': {
            '_id': 'u1',
            'name': 'Minji',
            'native_language': 'Korean',
            'language_to_learn': 'English',
          },
          'matchReasons': ['reciprocal_pair'],
          'reciprocal': true,
        },
      ],
    });

Widget _wrap(Override o) => ProviderScope(
      overrides: [o],
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

void main() {
  testWidgets('failed fetch shows retry; tapping it loads matches',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_wrap(dailyMatchesProvider.overrideWith((ref) async {
      calls++;
      if (calls == 1) throw Exception('boom');
      return _result();
    })));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Minji'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Minji'), findsOneWidget);
  });

  testWidgets('a past nextRefreshAt triggers exactly one refetch',
      (tester) async {
    var calls = 0;
    final past = DateTime.now().subtract(const Duration(hours: 1));
    await tester.pumpWidget(_wrap(dailyMatchesProvider.overrideWith((ref) async {
      calls++;
      return _result(next: past);
    })));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('refresh hint shows the local time derived from nextRefreshAt',
      (tester) async {
    final now = DateTime.now().toUtc();
    final next = DateTime.utc(now.year, now.month, now.day + 1);
    await tester.pumpWidget(
        _wrap(dailyMatchesProvider.overrideWith((ref) async => _result(next: next))));
    await tester.pumpAndSettle();
    final time = DateFormat.jm().format(next.toLocal());
    expect(find.text('refreshes at $time'), findsOneWidget);
    expect(find.textContaining('midnight'), findsNothing);
  });

  testWidgets('refresh hint falls back to old copy when nextRefreshAt is null',
      (tester) async {
    await tester.pumpWidget(
        _wrap(dailyMatchesProvider.overrideWith((ref) async => _result())));
    await tester.pumpAndSettle();
    expect(find.text('refreshes at midnight'), findsOneWidget);
  });
}
