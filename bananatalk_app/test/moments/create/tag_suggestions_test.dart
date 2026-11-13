import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/moments/create/create_tag_dialog.dart';
import 'package:bananatalk_app/providers/provider_models/hashtag_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('suggestedTagsFromCaption', () {
    test('last three distinct tags not already chosen, in caption order', () {
      expect(suggestedTagsFromCaption('a #x b #y #z #w', ['y']), ['x', 'z', 'w']);
      expect(suggestedTagsFromCaption('#a #b #c #d', []), ['b', 'c', 'd']);
    });

    test('case-insensitive, duplicates collapse, no tags gives empty', () {
      expect(suggestedTagsFromCaption('#Food #food #FOOD', []), ['food']);
      expect(suggestedTagsFromCaption('#Food', ['FOOD']), isEmpty);
      expect(suggestedTagsFromCaption('no tags here', []), isEmpty);
      expect(suggestedTagsFromCaption('', []), isEmpty);
    });
  });

  group('tag dialog suggestions', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> open(
      WidgetTester tester,
      Future<List<HashtagCount>> Function(String)? suggest,
      List<String> existing,
      void Function(List<String>) onResult,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => onResult(
                await showCreateTagDialog(
                  context,
                  existingTags: existing,
                  maxTags: 5,
                  suggest: suggest,
                ),
              ),
              child: const Text('open'),
            ),
          )),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('typing asks once after the debounce; tapping adds the tag',
        (tester) async {
      final asked = <String>[];
      List<String>? result;
      await open(tester, (q) async {
        asked.add(q);
        return [const HashtagCount(tag: 'korean', postCount: 4)];
      }, [], (r) => result = r);

      await tester.enterText(find.byType(TextField), '#Ko');
      await tester.pump(const Duration(milliseconds: 100));
      expect(asked, isEmpty);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(asked, ['ko']);

      await tester.tap(find.widgetWithText(ActionChip, '#korean'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, ['korean']);
    });

    testWidgets('a failing suggest shows nothing and no suggest means no calls',
        (tester) async {
      await open(tester, (q) async => throw Exception('boom'), [], (_) {});
      await tester.enterText(find.byType(TextField), 'ko');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byType(ActionChip), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the cap of five still applies to suggestions', (tester) async {
      List<String>? result;
      await open(tester, (q) async => [const HashtagCount(tag: 'six', postCount: 1)],
          ['a', 'b', 'c', 'd', 'e'], (r) => result = r);
      await tester.enterText(find.byType(TextField), 'si');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, '#six'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, ['a', 'b', 'c', 'd', 'e']);
    });
  });
}
