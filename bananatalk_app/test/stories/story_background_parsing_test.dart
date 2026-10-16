import 'package:bananatalk_app/pages/stories/models/story_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoryGradient.parseHexColor', () {
    test('CSS forms with #', () {
      expect(StoryGradient.parseHexColor('#112233'), const Color(0xFF112233));
      expect(StoryGradient.parseHexColor('#abc'), const Color(0xFFAABBCC));
      // CSS 8-digit is #RRGGBBAA: alpha last.
      expect(StoryGradient.parseHexColor('#11223380'), const Color(0x80112233));
      expect(StoryGradient.parseHexColor('#abc8'), const Color(0x88AABBCC));
      expect(StoryGradient.parseHexColor('  #FFFFFF '), const Color(0xFFFFFFFF));
    });

    test('bare legacy app forms', () {
      expect(StoryGradient.parseHexColor('112233'), const Color(0xFF112233));
      expect(StoryGradient.parseHexColor('80112233'), const Color(0x80112233));
    });

    test('junk returns null instead of throwing', () {
      for (final v in [
        null,
        '',
        '#',
        '#12',
        '#12345',
        'red',
        'rgb(0,0,0)',
        '#GGHHII',
        'gradient_sunset',
      ]) {
        expect(StoryGradient.parseHexColor(v), isNull, reason: '$v');
      }
    });
  });

  group('StoryGradient.backgroundDecoration', () {
    test('a gradient id paints that gradient', () {
      final d = StoryGradient.backgroundDecoration('gradient_ocean');
      expect(d.gradient, StoryGradient.byId('gradient_ocean').toLinearGradient());
    });

    test('a hex colour from the web paints that colour', () {
      final d = StoryGradient.backgroundDecoration('#336699');
      expect(d.color, const Color(0xFF336699));
      expect(d.gradient, isNull);
    });

    test('unknown values fall back to the default gradient', () {
      for (final v in [null, '', 'tomato', 'rgb(1,2,3)', '#12', 'gradient_nope']) {
        final d = StoryGradient.backgroundDecoration(v);
        expect(d.gradient, isNotNull, reason: '$v');
        expect(d.color, isNull, reason: '$v');
      }
    });
  });
}
