import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/moments/card/moment_double_tap_heart.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: Center(child: child)),
      ),
    );

/// Two taps at the SAME point, inside kDoubleTapTimeout.
///
/// Separate `tester.tap` calls land at the widget centre each time but the
/// recognizer needs both within the timeout to resolve the arena — pumping a
/// long gap between them yields two single taps.
Future<void> _doubleTap(WidgetTester tester) async {
  final where = tester.getCenter(find.byType(MomentDoubleTapHeart));
  await tester.tapAt(where);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tapAt(where);
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('double-tap on an unliked moment calls onLike', (tester) async {
    var liked = 0;
    await tester.pumpWidget(_host(MomentDoubleTapHeart(
      isLiked: false,
      onLike: () => liked++,
      child: const SizedBox(width: 200, height: 200),
    )));
    await _doubleTap(tester);
    expect(liked, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('the heart appears on like', (tester) async {
    await tester.pumpWidget(_host(MomentDoubleTapHeart(
      isLiked: false,
      onLike: () {},
      child: const SizedBox(width: 200, height: 200),
    )));
    await _doubleTap(tester);
    expect(find.byKey(const Key('double-tap-heart')), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('GLOBAL CONSTRAINT: no heart when already liked', (tester) async {
    // Un-liking is a correction. Animating it celebrates the removal, which
    // reads as confirming the wrong action.
    var called = 0;
    await tester.pumpWidget(_host(MomentDoubleTapHeart(
      isLiked: true,
      onLike: () => called++,
      child: const SizedBox(width: 200, height: 200),
    )));
    await _doubleTap(tester);
    expect(find.byKey(const Key('double-tap-heart')), findsNothing);
    expect(called, 0, reason: 'a double-tap must never un-like');
    await tester.pumpAndSettle();
  });

  testWidgets('GLOBAL CONSTRAINT: nothing animates when motion is disabled',
      (tester) async {
    var liked = 0;
    await tester.pumpWidget(_host(
      MomentDoubleTapHeart(
        isLiked: false,
        onLike: () => liked++,
        child: const SizedBox(width: 200, height: 200),
      ),
      disableAnimations: true,
    ));
    await _doubleTap(tester);
    expect(find.byKey(const Key('double-tap-heart')), findsNothing);
    expect(liked, 1, reason: 'the like must still register');
    await tester.pumpAndSettle();
  });

  testWidgets('a single tap does not like', (tester) async {
    var liked = 0;
    await tester.pumpWidget(_host(MomentDoubleTapHeart(
      isLiked: false,
      onLike: () => liked++,
      child: const SizedBox(width: 200, height: 200),
    )));
    await tester.tap(find.byType(MomentDoubleTapHeart));
    await tester.pump(const Duration(milliseconds: 400));
    expect(liked, 0);
  });
}
