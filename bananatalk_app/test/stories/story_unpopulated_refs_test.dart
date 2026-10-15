import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _story([Map<String, dynamic> extra = const {}]) => {
      '_id': 's1',
      'mediaType': 'image',
      'mediaUrl': 'https://x/y.jpg',
      ...extra,
    };

void main() {
  group('unpopulated references in stories', () {
    test('a user id string keeps the id instead of throwing', () {
      final story = Story.fromJson(_story({'user': 'u1'}));
      expect(story.user.id, 'u1');
    });

    test('a populated user is still parsed', () {
      final story = Story.fromJson(_story({
        'user': {'_id': 'u2', 'name': 'Ann'}
      }));
      expect(story.user.id, 'u2');
      expect(story.user.name, 'Ann');
    });

    test('reactions / views / responses with id users parse; junk is skipped',
        () {
      final story = Story.fromJson(_story({
        'user': 'u1',
        'reactions': [
          {'user': 'u3', 'emoji': '🔥'},
          'garbage',
        ],
        'views': [
          {'user': 'u3'},
          null,
        ],
        'questionBox': {
          'prompt': 'Ask me',
          'responses': [
            {'user': 'u4', 'text': 'hi'},
            42,
          ],
        },
      }));
      expect(story.reactions.single.userId, 'u3');
      expect(story.reactions.single.user, isNull);
      expect(story.views.single.userId, 'u3');
      expect(story.questionBox!.responses.single.userId, 'u4');
      expect(story.questionBox!.responses.single.user, isNull);
    });

    test('a highlight entry with an unpopulated story is not turned into a '
        'Story with the subdocument id', () {
      final highlight = StoryHighlight.fromJson({
        '_id': 'h1',
        'user': 'u1',
        'title': 'Trips',
        'stories': [
          {'_id': 'subdoc1', 'story': 's9', 'addedAt': '2026-10-15'},
          {
            '_id': 'subdoc2',
            'story': _story({'_id': 's10', 'user': 'u1'}),
          },
        ],
      });
      expect(highlight.stories.map((s) => s.id), ['s10']);
      expect(highlight.storyCount, 2);
    });

    test('UserStories tolerates an id-string user', () {
      final us = UserStories.fromJson({
        'user': 'u1',
        'stories': [_story({'user': 'u1'})],
      }, 'me');
      expect(us.user.id, 'u1');
    });
  });
}
