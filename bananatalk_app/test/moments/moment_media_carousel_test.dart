import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/moments/card/moment_media_carousel.dart';

/// Phone-width, and scrollable.
///
/// A 4:5 frame at the test surface's default 800pt width is 1000pt tall, which
/// overflows — in the app the card always sits inside a scrolling feed at
/// phone width, so the harness has to match that rather than the widget being
/// made to fit an 800pt-wide column nothing ever renders it in.
Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );

List<String> _urls(int n) =>
    List.generate(n, (i) => 'https://example.com/$i.jpg');

void main() {
  testWidgets('GLOBAL CONSTRAINT: a 9-image post exposes all 9', (tester) async {
    // The grid this replaces rendered `imageCount > 6 ? 6 : imageCount`, so
    // images 7-9 were unreachable and the poster had no way to know.
    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: _urls(9))));
    await tester.pump(const Duration(milliseconds: 50));

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.childrenDelegate.estimatedChildCount, 9);
  });

  testWidgets('GLOBAL CONSTRAINT: beyond the cap is limited, and said out loud',
      (tester) async {
    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: _urls(14))));
    await tester.pump(const Duration(milliseconds: 50));

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.childrenDelegate.estimatedChildCount, kMomentImageCap);
    expect(find.byKey(const Key('carousel-cap-notice')), findsOneWidget);
  });

  testWidgets('a single image shows no dots and no cap notice', (tester) async {
    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: _urls(1))));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('carousel-dots')), findsNothing);
    expect(find.byKey(const Key('carousel-cap-notice')), findsNothing);
  });

  testWidgets('several images show one dot each', (tester) async {
    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: _urls(4))));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('carousel-dots')), findsOneWidget);
    expect(find.byKey(const Key('carousel-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('carousel-dot-3')), findsOneWidget);
  });

  testWidgets('swiping advances the page and reports it', (tester) async {
    var reported = -1;
    await tester.pumpWidget(_host(MomentMediaCarousel(
      imageUrls: _urls(3),
      onPageChanged: (i) => reported = i,
    )));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(reported, 1);
  });

  testWidgets('GLOBAL CONSTRAINT: the frame is 4:5', (tester) async {
    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: _urls(2))));
    await tester.pump(const Duration(milliseconds: 50));
    final ratio = tester.widget<AspectRatio>(
      find.ancestor(of: find.byType(PageView), matching: find.byType(AspectRatio)).first,
    );
    expect(ratio.aspectRatio, closeTo(4 / 5, 0.001));
  });

  testWidgets('an empty list renders nothing rather than an empty frame',
      (tester) async {
    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: const [])));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('it does not overflow at 320pt', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(MomentMediaCarousel(imageUrls: _urls(5))));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a hero prefix produces one tag per page', (tester) async {
    await tester.pumpWidget(_host(
      MomentMediaCarousel(imageUrls: _urls(2), heroPrefix: 'moment-abc'),
    ));
    await tester.pump(const Duration(milliseconds: 50));
    final hero = tester.widget<Hero>(find.byType(Hero).first);
    expect(hero.tag, 'moment-abc-0');
  });
}
