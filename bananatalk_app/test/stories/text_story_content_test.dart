import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/stories_service.dart';

void main() {
  test('an emoji-only story (space text + an emoji overlay) can be posted', () {
    expect(textStoryHasContent(' ', [{'type': 'emoji', 'content': '🎉'}]), isTrue);
  });

  test('a story with nothing at all is refused', () {
    expect(textStoryHasContent(' ', const []), isFalse);
    expect(textStoryHasContent('', null), isFalse);
  });

  test('plain text is enough', () {
    expect(textStoryHasContent('hi', null), isTrue);
  });
}
