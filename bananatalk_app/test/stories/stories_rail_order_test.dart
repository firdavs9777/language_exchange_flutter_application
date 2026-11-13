import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/stories/feed/stories_rail_order.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

Map<String, dynamic> _story(
  String id,
  String userId, {
  String mediaType = 'image',
  String mediaUrl = 'https://x.test/orig.jpg',
  Map<String, dynamic>? variant,
  String? thumbnail,
  bool seen = false,
}) =>
    {
      '_id': id,
      'user': {'_id': userId, 'name': 'U$userId'},
      'mediaType': mediaType,
      'mediaUrl': mediaUrl,
      'privacy': 'public',
      'isActive': true,
      'isArchived': false,
      'expiresAt':
          DateTime.now().add(const Duration(hours: 5)).toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'views': seen
          ? [
              {'user': 'me'},
            ]
          : <dynamic>[],
      if (variant != null) 'imageVariants': [variant],
      if (thumbnail != null) 'videoMetadata': {'thumbnail': thumbnail},
    };

UserStories _group(
  String userId, {
  bool unseen = true,
  List<Map<String, dynamic>>? stories,
}) =>
    UserStories.fromJson({
      'user': {'_id': userId, 'name': 'U$userId'},
      'stories': stories ??
          [
            _story('s-$userId-1', userId, seen: !unseen),
            _story('s-$userId-2', userId, seen: !unseen),
          ],
      'hasUnviewed': unseen ? 1 : 0,
    }, 'me');

List<String> _ids(List<RailEntry> e) => e.map((r) => r.group.user.id).toList();

void main() {
  group('orderStoriesRail', () {
    test('unseen followed, then Discover, then fully seen followed', () {
      final entries = orderStoriesRail(
        followed: [_group('f1', unseen: false), _group('f2'), _group('f3')],
        discover: [_group('d1'), _group('d2')],
        discoverEnabled: true,
      );
      expect(_ids(entries), ['f2', 'f3', 'd1', 'd2', 'f1']);
      expect(entries.map((e) => e.isDiscover),
          [false, false, true, true, false]);
    });

    test('discoverEnabled false: no Discover entries and the server order', () {
      final entries = orderStoriesRail(
        followed: [_group('f1', unseen: false), _group('f2')],
        discover: [_group('d1')],
        discoverEnabled: false,
      );
      expect(_ids(entries), ['f1', 'f2']);
      expect(entries.any((e) => e.isDiscover), isFalse);
    });

    test('flag on but nothing to discover keeps the server order', () {
      final entries = orderStoriesRail(
        followed: [_group('f1', unseen: false), _group('f2')],
        discover: const [],
        discoverEnabled: true,
      );
      expect(_ids(entries), ['f1', 'f2']);
    });

    test('a Discover user who is also followed appears once, as followed', () {
      final entries = orderStoriesRail(
        followed: [_group('f1')],
        discover: [_group('f1'), _group('d1'), _group('d1')],
        discoverEnabled: true,
      );
      expect(_ids(entries), ['f1', 'd1']);
      expect(entries.first.isDiscover, isFalse);
    });

    test('own and blocked users are filtered from both lists', () {
      final entries = orderStoriesRail(
        followed: [_group('me'), _group('b1'), _group('f1')],
        discover: [_group('me'), _group('b2'), _group('d1')],
        discoverEnabled: true,
        currentUserId: 'me',
        blockedUserIds: {'b1', 'b2'},
      );
      expect(_ids(entries), ['f1', 'd1']);
    });
  });

  group('precache targets', () {
    test('photo: feedUrl when a variant exists, else the original', () {
      final withVariant = Story.fromJson(_story('a', 'u', variant: {
        'url': 'https://x.test/orig.jpg',
        'feedUrl': 'https://x.test/feed.jpg',
      }));
      final without = Story.fromJson(_story('b', 'u'));
      expect(storyPrecacheUrl(withVariant), 'https://x.test/feed.jpg');
      expect(storyPrecacheUrl(without), 'https://x.test/orig.jpg');
    });

    test('video: the thumbnail only, nothing when there is none', () {
      final v = Story.fromJson(_story('v', 'u',
          mediaType: 'video',
          mediaUrl: 'https://x.test/v.mp4',
          thumbnail: 'https://x.test/t.jpg'));
      final noThumb = Story.fromJson(
          _story('w', 'u', mediaType: 'video', mediaUrl: 'https://x.test/v.mp4'));
      expect(storyPrecacheUrl(v), 'https://x.test/t.jpg');
      expect(storyPrecacheUrl(noThumb), isNull);
    });

    test('rail: the first story of the first three of five entries', () {
      final entries = [
        for (var i = 0; i < 5; i++)
          RailEntry(
            group: _group('u$i', stories: [
              _story('a$i', 'u$i', mediaUrl: 'https://x.test/$i-a.jpg'),
              _story('b$i', 'u$i', mediaUrl: 'https://x.test/$i-b.jpg'),
            ]),
            isDiscover: false,
          ),
      ];
      expect(storiesRailPrecacheUrls(entries), [
        'https://x.test/0-a.jpg',
        'https://x.test/1-a.jpg',
        'https://x.test/2-a.jpg',
      ]);
    });

    List<UserStories> twoAuthors() => [
          _group('u0', stories: [
            _story('a0', 'u0', mediaUrl: 'https://x.test/0-a.jpg'),
            _story('b0', 'u0', mediaUrl: 'https://x.test/0-b.jpg'),
          ]),
          _group('u1', stories: [
            _story('a1', 'u1', mediaUrl: 'https://x.test/1-a.jpg'),
          ]),
        ];

    test('viewer on wifi: the next story and the next author\'s first', () {
      expect(
        storyViewerPrecacheUrls(
            groups: twoAuthors(),
            userIndex: 0,
            storyIndex: 0,
            onMobileData: false),
        ['https://x.test/0-b.jpg', 'https://x.test/1-a.jpg'],
      );
    });

    test('viewer on mobile data: only the next story', () {
      expect(
        storyViewerPrecacheUrls(
            groups: twoAuthors(),
            userIndex: 0,
            storyIndex: 0,
            onMobileData: true),
        ['https://x.test/0-b.jpg'],
      );
    });

    test('last story of an author: the next author\'s first, once', () {
      expect(
        storyViewerPrecacheUrls(
            groups: twoAuthors(),
            userIndex: 0,
            storyIndex: 1,
            onMobileData: false),
        ['https://x.test/1-a.jpg'],
      );
      expect(
        storyViewerPrecacheUrls(
            groups: twoAuthors(),
            userIndex: 1,
            storyIndex: 0,
            onMobileData: false),
        isEmpty,
      );
    });
  });
}
