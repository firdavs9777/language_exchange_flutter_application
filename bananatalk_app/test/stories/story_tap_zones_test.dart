import 'package:bananatalk_app/pages/stories/viewer/story_tap_zones.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// The 30% "previous" zone sat on the left in every locale; in Arabic (RTL)
/// "back" is on the right.
void main() {
  test('LTR: the left 30% goes back, the rest goes forward', () {
    expect(storyTapGoesBack(dx: 50, width: 400, direction: TextDirection.ltr),
        isTrue);
    expect(storyTapGoesBack(dx: 300, width: 400, direction: TextDirection.ltr),
        isFalse);
  });

  test('RTL: the zones are mirrored', () {
    expect(storyTapGoesBack(dx: 350, width: 400, direction: TextDirection.rtl),
        isTrue);
    expect(storyTapGoesBack(dx: 50, width: 400, direction: TextDirection.rtl),
        isFalse);
  });
}
