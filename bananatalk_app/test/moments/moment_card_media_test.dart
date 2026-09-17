import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/moments/card/moment_card_media.dart';
import 'package:bananatalk_app/pages/moments/card/moment_media_carousel.dart';
import 'package:bananatalk_app/pages/moments/single/moment_image_grid.dart';

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

void main() {
  testWidgets('three images use the carousel, not a grid', (tester) async {
    await tester.pumpWidget(_host(const MomentCardMedia(
      imageUrls: ['a.jpg', 'b.jpg', 'c.jpg'],
    )));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(MomentMediaCarousel), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('one image uses the carousel too, for a consistent frame',
      (tester) async {
    await tester.pumpWidget(_host(const MomentCardMedia(imageUrls: ['a.jpg'])));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(MomentMediaCarousel), findsOneWidget);
  });

  testWidgets('no images renders no carousel', (tester) async {
    await tester.pumpWidget(_host(const MomentCardMedia(imageUrls: [])));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(MomentMediaCarousel), findsNothing);
  });

  testWidgets('detail uses the same carousel, so swiping keeps working',
      (tester) async {
    await tester.pumpWidget(_host(const MomentImageGrid(
      imageUrls: ['a.jpg', 'b.jpg', 'c.jpg'],
    )));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(MomentMediaCarousel), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('detail exposes all nine images, as the feed does',
      (tester) async {
    // The detail grid carried the same `> 6 ? 6` truncation as the feed.
    await tester.pumpWidget(_host(MomentImageGrid(
      imageUrls: List.generate(9, (i) => '$i.jpg'),
    )));
    await tester.pump(const Duration(milliseconds: 50));
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.childrenDelegate.estimatedChildCount, 9);
  });
}
