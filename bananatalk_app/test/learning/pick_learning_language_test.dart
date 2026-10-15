import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/language_model.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/main/sections/learn_tab.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';

import '../helpers/community_fixture.dart';

final _korean = Language(id: 'ko', code: 'ko', name: 'Korean', nativeName: '한국어');

void main() {
  Future<int> run(WidgetTester tester, Future<void> Function(String) save) async {
    var userFetches = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        userProvider.overrideWith((ref) async {
          userFetches++;
          return communityFixture();
        }),
        dailyPackProvider.overrideWith(
          (ref) async => DailyPack.fromJson({'needsLanguage': false, 'stations': []}),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(builder: (context, ref, _) {
            ref.watch(userProvider);
            return TextButton(
              onPressed: () => pickLearningLanguage(
                context, ref,
                pick: (_) async => _korean,
                save: save,
              ),
              child: const Text('pick'),
            );
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final before = userFetches;
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    return userFetches - before;
  }

  testWidgets('a saved learning language refreshes the user', (tester) async {
    expect(await run(tester, (_) async {}), 1);
  });

  testWidgets('a failed save says so instead of failing silently', (tester) async {
    final refetched = await run(tester, (_) async => throw Exception('offline'));
    expect(refetched, 0);
    expect(find.text('Failed to save'), findsOneWidget);
  });
}
