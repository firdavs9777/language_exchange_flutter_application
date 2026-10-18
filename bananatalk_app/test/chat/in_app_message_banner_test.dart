import 'package:bananatalk_app/widgets/in_app_message_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A message arriving while the app is open (another screen, or another
/// chat) shows a banner; tapping opens that chat (2026-10-18).
void main() {
  testWidgets('shows sender and preview, tap opens, hides after 4s', (t) async {
    final key = GlobalKey<NavigatorState>();
    await t.pumpWidget(MaterialApp(
      navigatorKey: key,
      home: const Scaffold(body: Text('AI Study')),
    ));
    var opened = 0;
    InAppMessageBanner.show(
      overlay: key.currentState!.overlay!,
      senderName: 'Mina',
      preview: 'Hi 👋',
      onTap: () => opened++,
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('Hi 👋'), findsOneWidget);

    await t.tap(find.byKey(const Key('in-app-message-banner')));
    await t.pump();
    expect(opened, 1);
    expect(InAppMessageBanner.isShowing, isFalse);

    InAppMessageBanner.show(
      overlay: key.currentState!.overlay!,
      senderName: 'Jun',
      preview: 'hello',
      onTap: () {},
    );
    await t.pump();
    await t.pump(InAppMessageBanner.visibleFor + const Duration(milliseconds: 50));
    expect(InAppMessageBanner.isShowing, isFalse);
    expect(find.text('Jun'), findsNothing);
  });

  testWidgets('a second message replaces the first banner', (t) async {
    final key = GlobalKey<NavigatorState>();
    await t.pumpWidget(MaterialApp(navigatorKey: key, home: const Scaffold()));
    final overlay = key.currentState!.overlay!;
    InAppMessageBanner.show(overlay: overlay, senderName: 'Bora', preview: 'one', onTap: () {});
    await t.pump();
    InAppMessageBanner.show(overlay: overlay, senderName: 'Chen', preview: 'two', onTap: () {});
    await t.pump();
    expect(find.text('Bora'), findsNothing);
    expect(find.text('Chen'), findsOneWidget);
    InAppMessageBanner.hide();
  });
}
