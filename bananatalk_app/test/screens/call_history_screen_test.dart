import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/providers/missed_calls_provider.dart';
import 'package:bananatalk_app/screens/call_history_screen.dart';
import 'package:bananatalk_app/services/call_history_service.dart';

class _FakeHistory implements CallHistoryService {
  _FakeHistory(this.pages);
  final Map<int, CallLogPage> pages;
  int seen = 0;
  final requested = <int>[];

  @override
  Future<CallLogPage> fetchPage(int page) async {
    requested.add(page);
    return pages[page] ?? const CallLogPage([], false);
  }

  @override
  Future<int> missedCount() async => 2;

  @override
  Future<void> markMissedSeen() async => seen++;
}

CallLogEntry _entry(String id, String direction, String outcome, {String type = 'audio', int duration = 0}) =>
    CallLogEntry.fromJson({
      'id': id, 'type': type, 'direction': direction, 'outcome': outcome, 'duration': duration,
      'otherParty': {'id': 'u-$id', 'name': 'Ada', 'avatar': null}, 'createdAt': '2026-10-08T12:00:00.000Z',
    });

Future<void> _pump(WidgetTester tester, _FakeHistory fake) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [callHistoryServiceProvider.overrideWithValue(fake)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const CallHistoryScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('rows: §3 labels, missed in red, opening marks missed calls seen', (tester) async {
    final fake = _FakeHistory({
      1: CallLogPage([
        _entry('1', 'in', 'no_answer'),
        _entry('2', 'out', 'completed', type: 'video', duration: 83),
      ], false),
    });
    await _pump(tester, fake);
    expect(find.textContaining('Missed voice call'), findsOneWidget);
    expect(find.textContaining('Outgoing video call · 1:23'), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.call_missed)).color, Colors.red);
    expect(fake.seen, 1);
    expect(fake.requested, [1]);
  });

  testWidgets('empty state', (tester) async {
    await _pump(tester, _FakeHistory({}));
    expect(find.text('No calls yet'), findsOneWidget);
  });

  test('missed badge: refresh reads the count, markSeen clears it', () async {
    final fake = _FakeHistory({});
    final container = ProviderContainer(overrides: [callHistoryServiceProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);
    await container.read(missedCallsProvider.notifier).refresh();
    expect(container.read(missedCallsProvider), 2);
    await container.read(missedCallsProvider.notifier).markSeen();
    expect(container.read(missedCallsProvider), 0);
    expect(fake.seen, 1);
  });
}
