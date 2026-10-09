import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/widgets/guides/pulse_highlight.dart';

Widget _host({required bool enabled}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: PulseHighlight(
            enabled: enabled,
            color: const Color(0xFF00BFA5),
            child: const SizedBox(width: 120, height: 44, child: Text('Say hi')),
          ),
        ),
      ),
    );

void main() {
  testWidgets('disabled, it is a pass-through that animates nothing',
      (tester) async {
    await tester.pumpWidget(_host(enabled: false));
    await tester.pumpAndSettle();

    expect(find.text('Say hi'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('it starts when enabled turns on after the first frame',
      (tester) async {
    // MatchCard's real path: the card is built with highlightSayHi false
    // while the stored guide state is still resolving, and flips to true a
    // frame or two later when the panel above it decides to show.
    await tester.pumpWidget(_host(enabled: false));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(enabled: true));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue,
        reason: 'the ring has to be able to start late');

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('turning enabled off mid-ring stops it without throwing',
      (tester) async {
    await tester.pumpWidget(_host(enabled: true));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.pumpWidget(_host(enabled: false));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Say hi'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('many rebuilds while enabled create only one ticker',
      (tester) async {
    // The device crash: every rebuild of an enabled guide looked like a fresh
    // start, so the second one asked a SingleTickerProviderStateMixin for a
    // ticker it had already handed out. Guides sit on pages whose providers
    // settle over several seconds, so this fired within seconds of launch.
    await tester.pumpWidget(_host(enabled: true));
    for (var i = 0; i < 10; i++) {
      await tester.pumpWidget(_host(enabled: true));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull, reason: 'rebuild ${i + 1}');
    }

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('re-enabling after it has finished does not start it again',
      (tester) async {
    await tester.pumpWidget(_host(enabled: true));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(enabled: false));
    await tester.pump();
    await tester.pumpWidget(_host(enabled: true));
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isFalse,
        reason: 'the cycle cap is per mount; a flicker in `enabled` must not '
            'buy three more passes');
  });
}
