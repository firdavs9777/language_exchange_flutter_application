import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/gatherings/gathering_filter_bar.dart';

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('GatheringFilters', () {
    test('starts empty', () {
      const f = GatheringFilters();
      expect(f.isEmpty, isTrue);
      expect(f.activeCount, 0);
    });

    test('copyWith can CLEAR a value, not just replace it', () {
      // The sentinel exists for this: `topic: null` must mean "clear", which a
      // plain `topic ?? this.topic` would read as "leave alone".
      const f = GatheringFilters(topic: 'games');
      expect(f.copyWith(topic: null).topic, isNull);
      expect(f.copyWith(when: 'week').topic, 'games', reason: 'untouched stays');
    });

    test('activeCount counts each axis once', () {
      const f = GatheringFilters(topic: 'games', when: 'week', hasSeat: true);
      expect(f.activeCount, 3);
      expect(f.isEmpty, isFalse);
    });

    test('equality lets the tab skip a pointless refetch', () {
      const a = GatheringFilters(topic: 'games');
      const b = GatheringFilters(topic: 'games');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == const GatheringFilters(topic: 'media'), isFalse);
    });
  });

  test('the client topic list matches the server enum exactly', () {
    // An unknown topic is DROPPED by buildFilterQuery rather than rejected, so
    // drift here would show a chip that silently filters nothing. Read from
    // the real source rather than a copy of it.
    final src = File('../backend/lib/gatheringFilters.js').readAsStringSync();
    final block = RegExp(r'GATHERING_TOPICS = Object\.freeze\(\[(.*?)\]\)', dotAll: true)
        .firstMatch(src)!
        .group(1)!;
    final server = RegExp(r"'([a-z_]+)'")
        .allMatches(block)
        .map((m) => m.group(1)!)
        .toList();

    expect(kGatheringTopics, equals(server));
  });

  testWidgets('every topic has a translated label, none falls through',
      (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(_host(Builder(builder: (context) {
      l10n = AppLocalizations.of(context)!;
      return const SizedBox();
    })));

    for (final topic in kGatheringTopics) {
      final label = gatheringTopicLabel(l10n, topic);
      // The fallback returns the raw slug; a slug reaching the UI means a
      // missing translation.
      expect(label, isNot(equals(topic)), reason: '$topic has no label');
      expect(label.trim(), isNotEmpty);
    }
  });

  testWidgets('an unknown slug shows itself rather than a wrong label',
      (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(_host(Builder(builder: (context) {
      l10n = AppLocalizations.of(context)!;
      return const SizedBox();
    })));
    expect(gatheringTopicLabel(l10n, 'knitting'), 'knitting');
  });

  testWidgets('tapping a lit chip clears it', (tester) async {
    var current = const GatheringFilters(topic: 'games');
    await tester.pumpWidget(_host(StatefulBuilder(
      builder: (context, setState) => GatheringFilterBar(
        filters: current,
        onChanged: (next) => setState(() => current = next),
      ),
    )));
    await tester.pumpAndSettle();

    // The row scrolls horizontally, so the topic chips start off-screen.
    await tester.dragUntilVisible(
      find.byKey(const Key('filter-topic-games')),
      find.byType(ListView),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('filter-topic-games')));
    await tester.pumpAndSettle();
    expect(current.topic, isNull);
  });

  testWidgets('the clear chip appears only when something is filtered',
      (tester) async {
    await tester.pumpWidget(_host(GatheringFilterBar(
      filters: const GatheringFilters(),
      onChanged: (_) {},
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-clear')), findsNothing);

    await tester.pumpWidget(_host(GatheringFilterBar(
      filters: const GatheringFilters(hasSeat: true),
      onChanged: (_) {},
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('filter-clear')), findsOneWidget);
  });

  testWidgets('the bar does not overflow on a 320pt phone', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(GatheringFilterBar(
      filters: const GatheringFilters(topic: 'exam_prep', when: 'weekend', hasSeat: true),
      onChanged: (_) {},
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
