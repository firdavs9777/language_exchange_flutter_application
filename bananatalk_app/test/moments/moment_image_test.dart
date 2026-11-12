import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/providers/provider_models/image_variant.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/moment_image.dart';

// 1x1 transparent PNG.
const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
const _good = 'data:image/jpeg;base64,$_png';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SizedBox(width: 200, height: 200, child: child)),
    );

ImageVariant _variant({String? placeholder = _good}) => ImageVariant(
      url: 'https://x.test/orig.jpg',
      feedUrl: 'https://x.test/feed.jpg',
      placeholder: placeholder,
      width: 1000,
      height: 1000,
    );

final _memory = find.byWidgetPredicate(
  (w) => w is Image && w.image is MemoryImage,
);

void main() {
  testWidgets('no variant: one CachedImageWidget on the original, no memory image',
      (tester) async {
    await tester.pumpWidget(_host(const MomentImage(
      imageUrl: 'https://x.test/orig.jpg',
      width: double.infinity,
      height: double.infinity,
    )));
    final w = tester.widget<CachedImageWidget>(find.byType(CachedImageWidget));
    expect(w.imageUrl, 'https://x.test/orig.jpg');
    expect(w.fit, BoxFit.cover);
    expect(w.width, double.infinity);
    expect(w.placeholder, isNull);
    expect(find.byType(CachedImageWidget), findsOneWidget);
    expect(_memory, findsNothing);
  });

  testWidgets('variant: placeholder under the feed-size image', (tester) async {
    await tester.pumpWidget(_host(MomentImage(
      imageUrl: 'https://x.test/orig.jpg',
      variant: _variant(),
    )));
    final mem = tester.widget<Image>(_memory);
    expect(mem.gaplessPlayback, isTrue);
    expect(
      tester.widget<CachedImageWidget>(find.byType(CachedImageWidget)).imageUrl,
      'https://x.test/feed.jpg',
    );
  });

  testWidgets('fullSize uses the original even with a variant', (tester) async {
    await tester.pumpWidget(_host(MomentImage(
      imageUrl: 'https://x.test/orig.jpg',
      variant: _variant(),
      fullSize: true,
    )));
    expect(
      tester.widget<CachedImageWidget>(find.byType(CachedImageWidget)).imageUrl,
      'https://x.test/orig.jpg',
    );
    expect(_memory, findsNothing);
  });

  testWidgets('a corrupt placeholder renders without the memory image',
      (tester) async {
    await tester.pumpWidget(_host(MomentImage(
      imageUrl: 'https://x.test/orig.jpg',
      variant: _variant(placeholder: 'data:image/jpeg;base64,@@@not-base64'),
    )));
    expect(tester.takeException(), isNull);
    expect(_memory, findsNothing);
    expect(
      tester.widget<CachedImageWidget>(find.byType(CachedImageWidget)).imageUrl,
      'https://x.test/feed.jpg',
    );
  });

  test('decodePlaceholder accepts only data:image base64', () {
    expect(MomentImage.decodePlaceholder(_good), base64Decode(_png));
    expect(MomentImage.decodePlaceholder(null), isNull);
    expect(MomentImage.decodePlaceholder('https://x.test/a.jpg'), isNull);
    expect(MomentImage.decodePlaceholder('data:text/plain;base64,$_png'), isNull);
    expect(MomentImage.decodePlaceholder('data:image/jpeg;base64,'), isNull);
  });
}
