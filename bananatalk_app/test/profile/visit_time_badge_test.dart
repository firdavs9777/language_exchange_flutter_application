import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/profile/visitors_screen.dart';

void main() {
  testWidgets('a long localized time stays on one capped, ellipsized line', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: VisitTimeBadge(text: 'vor etwa einem Monat und noch viel länger'),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(VisitTimeBadge));
    expect(size.width, lessThanOrEqualTo(VisitTimeBadge.maxWidth));
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}
