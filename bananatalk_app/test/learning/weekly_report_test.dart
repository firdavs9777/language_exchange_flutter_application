import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/weekly_report_model.dart';
import 'package:bananatalk_app/pages/learning/progress/weekly_report_screen.dart';

Map<String, dynamic> _json({bool empty = false}) => empty
    ? {
        'weekStartKey': '2026-09-07', 'weekEndKey': '2026-09-13',
        'daysStudied': 0, 'stationsCompleted': 0, 'unitsMastered': 0,
        'wordsLearned': 0, 'accuracy': null, 'bestDayKey': null,
        'bestDayStations': 0, 'isEmpty': true,
      }
    : {
        'weekStartKey': '2026-09-07', 'weekEndKey': '2026-09-13',
        'daysStudied': 5, 'stationsCompleted': 17, 'unitsMastered': 3,
        'wordsLearned': 20, 'accuracy': 0.82, 'bestDayKey': '2026-09-09',
        'bestDayStations': 4, 'isEmpty': false,
      };

Widget _host(WeeklyReport? report) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: WeeklyReportScreen(report: report),
    );

void main() {
  group('model', () {
    test('parses a full week', () {
      final r = WeeklyReport.fromJson(_json());
      expect(r.daysStudied, 5);
      expect(r.stationsCompleted, 17);
      expect(r.unitsMastered, 3);
      expect(r.wordsLearned, 20);
      expect(r.accuracy, 0.82);
      expect(r.bestDayKey, '2026-09-09');
      expect(r.isEmpty, isFalse);
    });

    test('an empty week keeps accuracy null rather than zero', () {
      final r = WeeklyReport.fromJson(_json(empty: true));
      expect(r.isEmpty, isTrue);
      expect(r.accuracy, isNull);
      expect(r.bestDayKey, isNull);
    });

    test('accuracy renders as a whole percentage', () {
      expect(WeeklyReport.fromJson(_json()).accuracyPercent, 82);
      expect(WeeklyReport.fromJson(_json(empty: true)).accuracyPercent, isNull);
    });
  });

  group('screen', () {
    testWidgets('shows the headline numbers of a real week', (tester) async {
      await tester.pumpWidget(_host(WeeklyReport.fromJson(_json())));
      expect(find.textContaining('5'), findsWidgets);
      expect(find.byKey(const Key('weekly-days')), findsOneWidget);
      expect(find.byKey(const Key('weekly-units')), findsOneWidget);
      expect(find.byKey(const Key('weekly-words')), findsOneWidget);
    });

    testWidgets('names the best day when there was one', (tester) async {
      await tester.pumpWidget(_host(WeeklyReport.fromJson(_json())));
      expect(find.byKey(const Key('weekly-best-day')), findsOneWidget);
    });

    testWidgets('an empty week invites a start rather than reporting zeroes',
        (tester) async {
      await tester.pumpWidget(_host(WeeklyReport.fromJson(_json(empty: true))));
      expect(find.byKey(const Key('weekly-empty')), findsOneWidget);
      // Showing "0 days · 0 words · 0%" to someone who did nothing reads as
      // failure, not as a prompt.
      expect(find.byKey(const Key('weekly-days')), findsNothing);
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('a week with study but no accuracy does not print 0%', (tester) async {
      final json = _json()..['accuracy'] = null;
      await tester.pumpWidget(_host(WeeklyReport.fromJson(json)));
      expect(find.text('0%'), findsNothing);
      expect(find.byKey(const Key('weekly-accuracy')), findsNothing);
    });

    testWidgets('a null report shows a loading state, not a crash', (tester) async {
      await tester.pumpWidget(_host(null));
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
