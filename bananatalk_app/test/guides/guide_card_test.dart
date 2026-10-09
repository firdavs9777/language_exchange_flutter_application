import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/widgets/guides/guide_card.dart';
import 'package:bananatalk_app/widgets/guides/pulse_highlight.dart';

Widget _host({
  required double width,
  String title = 'Post something',
  String body = 'A photo or one line.',
  String? cta = 'Post a moment',
  VoidCallback? onCta,
}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: GuideCard(
              icon: Icons.add_a_photo_rounded,
              accent: const Color(0xFF7C4DFF),
              title: title,
              body: body,
              ctaLabel: cta,
              onCta: cta == null ? null : (onCta ?? () {}),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('it shows the title, the body and the one action',
      (tester) async {
    await tester.pumpWidget(_host(width: 390));
    await tester.pumpAndSettle();

    expect(find.text('Post something'), findsOneWidget);
    expect(find.text('A photo or one line.'), findsOneWidget);
    expect(find.text('Post a moment'), findsOneWidget);
  });

  testWidgets('it does not overflow at a narrow phone width', (tester) async {
    // Same failure class as the chat_app_bar overflow found on 2026-10-09:
    // unconstrained text in a bounded row.
    await tester.pumpWidget(_host(width: 280));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('it survives a very narrow width', (tester) async {
    await tester.pumpWidget(_host(width: 180));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long translation does not overflow the card', (tester) async {
    // Nineteen locales are machine-drafted, and German and Russian routinely
    // run half again the English length.
    await tester.pumpWidget(_host(
      width: 300,
      title: 'Veröffentliche etwas in der Sprache, die du gerade lernst',
      body: 'Ein Foto oder eine Zeile. Muttersprachler korrigieren, '
          'was du hier schreibst, meistens innerhalb weniger Stunden.',
      cta: 'Einen Moment veröffentlichen',
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the pulse ring does not swallow the tap', (tester) async {
    // The ring is painted in a Stack above the button in paint order. Behind
    // an IgnorePointer it must not intercept the gesture -- a highlight that
    // makes the highlighted button unpressable is worse than no highlight.
    var taps = 0;
    await tester.pumpWidget(_host(width: 390, onCta: () => taps++));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Post a moment'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('with no CTA there is no button and no pulse', (tester) async {
    await tester.pumpWidget(_host(width: 390, cta: null));
    await tester.pumpAndSettle();

    expect(find.byType(PulseHighlight), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('it has no dismiss control', (tester) async {
    await tester.pumpWidget(_host(width: 390));
    await tester.pumpAndSettle();

    // A dismiss invites dismissal INSTEAD of acting; the view cap bounds the
    // annoyance instead.
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('a rebuild after the pulse has finished does not crash',
      (tester) async {
    // Device crash, 2026-10-10: _PulseHighlightState disposed its controller
    // when the ring finished, then the next rebuild saw a null controller,
    // decided the ring had never started, and asked a
    // SingleTickerProviderStateMixin for a second ticker:
    //
    //   _PulseHighlightState is a SingleTickerProviderStateMixin but
    //   multiple tickers were created.
    //
    // Guides sit at the top of pages that rebuild constantly (every provider
    // on the Chats and Profile tabs), so this fired within seconds.
    await tester.pumpWidget(_host(width: 390));
    await tester.pumpAndSettle();

    for (var i = 0; i < 5; i++) {
      await tester.pumpWidget(_host(width: 390 - i.toDouble()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'rebuild ${i + 1} after the ring finished');
    }
  });

  testWidgets('the ring does not restart on every rebuild', (tester) async {
    // The same null-controller check also meant the ring began again on each
    // rebuild, so a card on a busy page pulsed forever -- the exact "reads as
    // broken rather than inviting" the cycle cap exists to avoid.
    await tester.pumpWidget(_host(width: 390));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(width: 389));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse,
        reason: 'a finished ring must stay finished');
  });

  testWidgets('the pulse stops, so the page is not animating forever',
      (tester) async {
    // A ring that never stops holds a frame callback for as long as the tab
    // is alive -- and every pumpAndSettle in this suite would time out.
    await tester.pumpWidget(_host(width: 390));
    await tester.pumpAndSettle();

    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
