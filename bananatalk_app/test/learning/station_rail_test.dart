import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/widgets/station_rail.dart';

PackStation _s(String kind, StationStatus status) => PackStation(kind: kind, status: status);

Widget _host(List<PackStation> stations, int current) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StationRail(stations: stations, currentIndex: current)),
    );

void main() {
  testWidgets('renders one dot per station', (tester) async {
    await tester.pumpWidget(_host([
      _s('vocabulary', StationStatus.done),
      _s('grammar', StationStatus.todo),
      _s('listening', StationStatus.todo),
      _s('review', StationStatus.empty),
    ], 1));
    expect(find.byKey(const Key('rail-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('rail-dot-3')), findsOneWidget);
  });

  testWidgets('states the server-side progress count', (tester) async {
    // done + empty = 2 of 4; the client never recomputes this.
    await tester.pumpWidget(_host([
      _s('vocabulary', StationStatus.done),
      _s('grammar', StationStatus.todo),
      _s('listening', StationStatus.todo),
      _s('review', StationStatus.empty),
    ], 1));
    expect(find.text('2/4'), findsOneWidget);
  });

  testWidgets('marks the current station', (tester) async {
    await tester.pumpWidget(_host([
      _s('vocabulary', StationStatus.done),
      _s('grammar', StationStatus.todo),
    ], 1));
    final rail = tester.widget<StationRail>(find.byType(StationRail));
    expect(rail.currentIndex, 1);
    expect(find.byKey(const Key('rail-dot-1-current')), findsOneWidget);
  });

  testWidgets('an empty station list renders nothing rather than throwing', (tester) async {
    await tester.pumpWidget(_host(const [], 0));
    expect(find.byType(StationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
