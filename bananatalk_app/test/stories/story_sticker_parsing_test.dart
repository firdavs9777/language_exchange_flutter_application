import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// "Ask me anything!" appeared on every story.
///
/// questionBox is a nested Mongoose object whose inner `responses` array
/// carries a default, so it materialises as `{ responses: [] }` even when
/// nobody added a sticker. A bare `!= null` check passed, and the prompt fell
/// back to the "Ask me anything!" default — so a sticker nobody created
/// rendered on all of them.
void main() {
  group('StoryQuestionBox.fromJsonOrNull', () {
    test('the empty shape Mongoose always produces is not a sticker', () {
      expect(StoryQuestionBox.fromJsonOrNull({'responses': []}), isNull);
    });

    test('a real prompt is a sticker', () {
      final box = StoryQuestionBox.fromJsonOrNull(
        {'prompt': 'What city?', 'responses': []},
      );
      expect(box, isNotNull);
      expect(box!.prompt, 'What city?');
    });

    test('a blank or whitespace prompt is not a sticker', () {
      // Otherwise the box renders with an invisible question.
      expect(StoryQuestionBox.fromJsonOrNull({'prompt': ''}), isNull);
      expect(StoryQuestionBox.fromJsonOrNull({'prompt': '   '}), isNull);
    });

    test('null and non-map input are safe', () {
      expect(StoryQuestionBox.fromJsonOrNull(null), isNull);
      expect(StoryQuestionBox.fromJsonOrNull('nope'), isNull);
      expect(StoryQuestionBox.fromJsonOrNull(42), isNull);
    });

    test('responses still parse when the sticker is real', () {
      final box = StoryQuestionBox.fromJsonOrNull({
        'prompt': 'Ask away',
        'responses': [
          {'text': 'hi', 'user': {'_id': 'u1'}},
        ],
      });
      expect(box!.responses.length, 1);
    });
  });
}
