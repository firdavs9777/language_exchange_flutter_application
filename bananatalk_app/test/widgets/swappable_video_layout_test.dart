import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/widgets/call/swappable_video_layout.dart';

void main() {
  test('nearestCorner picks the quadrant', () {
    const area = Size(400, 800);
    expect(nearestCorner(const Offset(10, 10), area), PipCorner.topLeft);
    expect(nearestCorner(const Offset(390, 10), area), PipCorner.topRight);
    expect(nearestCorner(const Offset(10, 790), area), PipCorner.bottomLeft);
    expect(nearestCorner(const Offset(390, 790), area), PipCorner.bottomRight);
  });

  Future<void> pump(
    WidgetTester tester, {
    Widget? local = const Text('LOCAL'),
    bool swapEnabled = true,
    EdgeInsets insets = EdgeInsets.zero,
    Size size = const Size(400, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: SwappableVideoLayout(
        remote: const Text('REMOTE'),
        local: local,
        swapEnabled: swapEnabled,
        insets: insets,
        localLabel: 'Your camera',
        remoteLabel: 'Peer',
        swapHint: 'Swap videos',
      ),
    ));
  }

  Finder pip() => find.byKey(const Key('call-pip'));
  Finder inMain(String t) =>
      find.descendant(of: find.byKey(const Key('call-main')), matching: find.text(t));
  Finder inPip(String t) =>
      find.descendant(of: pip(), matching: find.text(t));

  testWidgets('starts top-right; drag to bottom-left snaps there', (tester) async {
    await pump(tester);
    expect(tester.getTopLeft(pip()), const Offset(400 - 20 - 120, 20));
    await tester.drag(pip(), const Offset(-250, 550));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(pip()), const Offset(20, 800 - 20 - 160));
  });

  testWidgets('tap swaps big and small', (tester) async {
    await pump(tester);
    expect(inMain('REMOTE'), findsOneWidget);
    await tester.tap(pip());
    await tester.pumpAndSettle();
    expect(inMain('LOCAL'), findsOneWidget);
    expect(inPip('REMOTE'), findsOneWidget);
  });

  testWidgets('insets keep the tile clear of the top and bottom bars', (tester) async {
    await pump(tester, insets: const EdgeInsets.only(top: 70, bottom: 170));
    expect(tester.getTopLeft(pip()), const Offset(260, 90));
    await tester.drag(pip(), const Offset(-250, 900));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(pip()), const Offset(20, 800 - 170 - 20 - 160));
  });

  testWidgets('a drag past the edge never leaves the screen', (tester) async {
    await pump(tester);
    await tester.drag(pip(), const Offset(900, -900));
    await tester.pump();
    final r = tester.getRect(pip());
    expect(r.left >= 0 && r.top >= 0 && r.right <= 400 && r.bottom <= 800, isTrue);
  });

  testWidgets('rotation re-snaps to the same corner of the new size', (tester) async {
    await pump(tester);
    await tester.drag(pip(), const Offset(-250, 550));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(800, 400);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(pip()), const Offset(20, 400 - 20 - 160));
  });

  testWidgets('swap disabled: tap does nothing', (tester) async {
    await pump(tester, swapEnabled: false);
    await tester.tap(pip());
    await tester.pumpAndSettle();
    expect(inMain('REMOTE'), findsOneWidget);
  });

  testWidgets('turning swap off while swapped restores the remote as main', (tester) async {
    await pump(tester);
    await tester.tap(pip());
    await tester.pumpAndSettle();
    await pump(tester, swapEnabled: false);
    expect(inMain('REMOTE'), findsOneWidget);
    expect(inPip('LOCAL'), findsOneWidget);
  });

  testWidgets('local removed while swapped: remote stays big, no tile', (tester) async {
    await pump(tester);
    await tester.tap(pip());
    await tester.pumpAndSettle();
    await pump(tester, local: null);
    expect(inMain('REMOTE'), findsOneWidget);
    expect(pip(), findsNothing);
  });

  testWidgets('semantics: label and a tap action', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Your camera')),
      matchesSemantics(
          label: 'Your camera',
          hint: 'Swap videos',
          isButton: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true),
    );
    handle.dispose();
  });

  testWidgets('swap disabled then re-enabled does not resurrect the swap', (tester) async {
    await pump(tester);
    await tester.tap(pip());
    await tester.pumpAndSettle();
    await pump(tester, swapEnabled: false);
    await pump(tester);
    expect(inMain('REMOTE'), findsOneWidget);
    expect(inPip('LOCAL'), findsOneWidget);
  });

  testWidgets('semantics follow the feed shown in the tile', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await tester.tap(pip());
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Peer'), findsOneWidget);
    expect(find.bySemanticsLabel('Your camera'), findsNothing);
    handle.dispose();
  });

  testWidgets('drag overshoot is clamped so reversing responds at once', (tester) async {
    await pump(tester);
    final g = await tester.startGesture(tester.getCenter(pip()));
    await g.moveBy(const Offset(500, 0));
    await tester.pump();
    await g.moveBy(const Offset(-50, 0));
    await tester.pump();
    expect(tester.getTopLeft(pip()).dx, 400 - 20 - 120 - 50);
    await g.up();
    await tester.pumpAndSettle();
  });
}
