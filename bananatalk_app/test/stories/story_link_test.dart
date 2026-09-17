import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/stories/create/link_sticker_editor.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// Story.link had schema support, a service parameter that was never sent, and
/// no UI at all — the sticker could not have worked even once.
///
/// A user-supplied URL shown to other people is a phishing surface, so the
/// client validates before the server does. That is advice, not a guarantee:
/// parseStoryLink on the server stays authoritative.
void main() {
  group('isAcceptableStoryLink', () {
    test('http and https are accepted', () {
      expect(isAcceptableStoryLink('https://example.com'), isTrue);
      expect(isAcceptableStoryLink('http://example.com/page?x=1'), isTrue);
      expect(isAcceptableStoryLink('  https://example.com  '), isTrue);
    });

    test('payload schemes are refused', () {
      // A story sticker is a tap target on someone else's screen.
      for (final url in [
        'javascript:alert(1)',
        'JavaScript:alert(1)',
        'data:text/html;base64,PHNjcmlwdD4=',
        'file:///etc/passwd',
        'ftp://example.com',
      ]) {
        expect(isAcceptableStoryLink(url), isFalse, reason: url);
      }
    });

    test('a bare domain with no scheme is refused', () {
      // Ambiguous, and guessing https for the user would silently change where
      // their link points.
      expect(isAcceptableStoryLink('example.com'), isFalse);
    });

    test('empty and hostless input is refused', () {
      for (final url in ['', '   ', 'https://', 'https:///']) {
        expect(isAcceptableStoryLink(url), isFalse, reason: '"$url"');
      }
    });
  });

  group('StoryLink', () {
    test('host round-trips from the server payload', () {
      // The viewer shows this under the label; it comes from the server's URL
      // parse, never from anything the poster typed.
      final link = StoryLink.fromJson({
        'url': 'https://example.com/x',
        'displayText': 'Shop Now',
        'host': 'example.com',
      });
      expect(link.host, 'example.com');
      expect(link.displayText, 'Shop Now');
    });

    test('an absent host is null, so the viewer simply omits the line', () {
      final link = StoryLink.fromJson({'url': 'https://example.com'});
      expect(link.host, isNull);
    });
  });
}
