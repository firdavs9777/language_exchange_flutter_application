import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/chat/header/chat_app_bar.dart';

/// The online/last-seen line sits beside the chat title and the action icons,
/// so its width is whatever is left over. A device log on 2026-10-09 caught it
/// as `RenderFlex overflowed by 1.1 pixels` at chat_app_bar.dart:76 on an
/// iPhone 15 Pro, under a `0.0<=w<=99.2` constraint: the label had no flex.
///
/// Screen-size dependent, which is why it survived — a wider header hides it.
/// These pin the narrow case.
Widget _host({required double width, required Widget child}) => MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: child)),
      ),
    );

void main() {
  // The exact constraint from the device log.
  const reportedWidth = 99.2;

  testWidgets('a long last-seen label does not overflow at the reported width',
      (tester) async {
    await tester.pumpWidget(_host(
      width: reportedWidth,
      child: const OnlineStatusLine(
        isOnline: false,
        label: 'Last seen 6 days ago',
      ),
    ));
    await tester.pump();

    expect(
      tester.takeException(),
      isNull,
      reason: 'the label must flex rather than overflow the row',
    );
  });

  testWidgets('an unusually long label still does not overflow', (tester) async {
    await tester.pumpWidget(_host(
      width: reportedWidth,
      child: const OnlineStatusLine(
        isOnline: false,
        // Some locales are far longer than English; none may overflow.
        label: 'Zuletzt gesehen vor ungefähr sechs Tagen und drei Stunden',
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a very narrow header still does not overflow', (tester) async {
    await tester.pumpWidget(_host(
      width: 40,
      child: const OnlineStatusLine(isOnline: false, label: 'Last seen 6 days ago'),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the online label renders and the dot is kept', (tester) async {
    await tester.pumpWidget(_host(
      width: 160,
      child: const OnlineStatusLine(isOnline: true, label: 'Online'),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Online'), findsOneWidget);
    // The status dot must survive the squeeze — only the label may ellipsise.
    expect(find.byType(Container), findsWidgets);
  });

  testWidgets('a short label is not ellipsised', (tester) async {
    await tester.pumpWidget(_host(
      width: 300,
      child: const OnlineStatusLine(isOnline: true, label: 'Online'),
    ));
    await tester.pump();

    final text = tester.widget<Text>(find.text('Online'));
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.maxLines, 1);
  });
}
