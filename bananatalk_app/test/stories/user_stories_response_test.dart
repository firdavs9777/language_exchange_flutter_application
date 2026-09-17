import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/provider_models/story_model.dart';

/// The bug: tapping a profile with a story ring showed "No stories".
///
/// GET /stories/user/:id returns a FLAT array of stories — it is a per-user
/// endpoint, so it has no reason to group. GET /stories/feed returns an array
/// of user GROUPS. The client ran both through StoriesResponse.fromJson, which
/// maps every element through UserStories.fromJson.
///
/// A Story object has no `stories` key, so each one parsed into a group
/// containing ZERO stories. That made `data.isNotEmpty` true — one bogus group
/// per story — so StoryViewerLauncher opened the viewer instead of falling
/// back, and the viewer rendered `activeStories`, which was empty.
///
/// Deterministic: it happened for every user with a story, every time.
Map<String, dynamic> storyJson(String id, {String privacy = 'public'}) => {
      '_id': id,
      'user': {'_id': 'u1', 'name': 'Dana'},
      'mediaType': 'text',
      'text': 'hello',
      'privacy': privacy,
      'isActive': true,
      'isArchived': false,
      'expiresAt':
          DateTime.now().add(const Duration(hours: 5)).toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'views': <dynamic>[],
    };

void main() {
  group('StoriesResponse.fromUserStoriesJson', () {
    test('a flat story array becomes ONE group holding those stories', () {
      final response = StoriesResponse.fromUserStoriesJson({
        'success': true,
        'count': 2,
        'data': [storyJson('s1'), storyJson('s2')],
      }, 'viewer-1');

      expect(response.success, isTrue);
      expect(response.data.length, 1, reason: 'one user, one group');
      expect(response.data.first.stories.length, 2);
      expect(response.data.first.activeStories.length, 2,
          reason: 'unexpired stories must survive the client-side filter');
    });

    test('the group carries the story author', () {
      final response = StoriesResponse.fromUserStoriesJson({
        'success': true,
        'data': [storyJson('s1')],
      }, 'viewer-1');
      expect(response.data.first.user.name, 'Dana');
    });

    test('an empty array yields NO group, so the launcher falls back', () {
      // The old code produced zero groups here too, but for the wrong reason.
      // What matters is that data.isNotEmpty stays false so the caller runs
      // its fallback instead of opening an empty viewer.
      final response = StoriesResponse.fromUserStoriesJson(
          {'success': true, 'count': 0, 'data': <dynamic>[]}, 'viewer-1');
      expect(response.data, isEmpty);
    });

    test('a missing data key yields no group rather than throwing', () {
      final response =
          StoriesResponse.fromUserStoriesJson({'success': true}, 'viewer-1');
      expect(response.data, isEmpty);
    });

    test('blocked responses are preserved', () {
      final response = StoriesResponse.fromUserStoriesJson(
          {'success': true, 'blocked': true, 'data': <dynamic>[]}, 'viewer-1');
      expect(response.blocked, isTrue);
      expect(response.data, isEmpty);
    });

    test('my own stories use the same parser, not a second copy', () {
      // getMyStories duplicated this wrap inline. Two copies of one rule is
      // how they drift; the endpoints share a shape, so they share a parser.
      final mine = StoriesResponse.fromUserStoriesJson({
        'success': true,
        'count': 1,
        'data': [storyJson('s1')],
      }, 'u1');
      expect(mine.data.length, 1);
      expect(mine.data.first.stories.length, 1);
    });

  });
}
