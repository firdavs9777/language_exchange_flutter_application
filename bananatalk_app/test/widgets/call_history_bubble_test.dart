import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/call_record_model.dart';
import 'package:bananatalk_app/widgets/call/call_history_bubble.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

CallRecord _record(String outcome, {String type = 'audio', int duration = 0}) => CallRecord.fromJson({
      '_id': 'c1', 'callId': 'c1', 'initiator': 'caller', 'participants': [], 'type': type,
      'startTime': '2026-10-08T12:00:00.000Z', 'duration': duration, 'status': 'missed', 'outcome': outcome,
    }, 'viewer');

void main() {
  testWidgets('receiver sees "Missed voice call" in red with the missed arrow', (tester) async {
    await tester.pumpWidget(_wrap(CallHistoryBubble(call: _record('no_answer'), isOutgoing: false, otherName: 'Ada')));
    expect(find.text('Missed voice call'), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.call_missed)).color, Colors.red);
  });

  testWidgets('caller sees "Voice call · No answer", busy shows the name', (tester) async {
    await tester.pumpWidget(_wrap(CallHistoryBubble(call: _record('no_answer'), isOutgoing: true, otherName: 'Bo')));
    expect(find.text('Voice call · No answer'), findsOneWidget);
    expect(find.byIcon(Icons.call_made), findsOneWidget);
    await tester.pumpWidget(_wrap(CallHistoryBubble(call: _record('busy'), isOutgoing: true, otherName: 'Bo')));
    expect(find.text('Bo was on another call'), findsOneWidget);
  });

  testWidgets('completed video call shows direction and duration; tap calls back', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(CallHistoryBubble(
      call: _record('completed', type: 'video', duration: 83), isOutgoing: true, otherName: 'Bo', onTap: () => taps++)));
    expect(find.text('Outgoing video call · 1:23'), findsOneWidget);
    await tester.tap(find.byType(CallHistoryBubble));
    expect(taps, 1);
  });
}
