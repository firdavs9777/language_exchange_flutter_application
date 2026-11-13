import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/image_variant.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';

Map<String, dynamic> _variant(String url) => {
      'url': url,
      'feedUrl': '${url}_feed',
      'placeholder': 'data:image/jpeg;base64,AAAA',
      'width': 1200,
      'height': 900,
    };

Map<String, dynamic> _moment([Map<String, dynamic> extra = const {}]) => {
      '_id': 'm1',
      'description': 'hi',
      'imageUrls': ['a.jpg', 'b.jpg'],
      ...extra,
    };

void main() {
  group('Moments', () {
    test("today's server shape parses with empty defaults", () {
      final m = Moments.fromJson(_moment());
      expect(m.imageVariants, isEmpty);
      expect(m.hashtags, isEmpty);
      expect(m.topics, isEmpty);
      expect(m.needsFeedback, isFalse);
      expect(m.variantFor('a.jpg'), isNull);
    });

    test('variantFor matches on url only', () {
      final m = Moments.fromJson(_moment({
        'imageVariants': [_variant('a.jpg')],
        'hashtags': ['korean'],
        'topics': ['food'],
        'needsFeedback': true,
      }));
      expect(m.variantFor('a.jpg')?.feedUrl, 'a.jpg_feed');
      expect(m.variantFor('b.jpg'), isNull);
      expect(m.hashtags, ['korean']);
      expect(m.topics, ['food']);
      expect(m.needsFeedback, isTrue);
    });

    test('malformed variants never throw', () {
      for (final bad in <Object?>[
        'oops',
        [<String, dynamic>{}],
        [null],
        [_variant('a.jpg')..['width'] = 0],
        {'a': 1},
        7,
      ]) {
        expect(() => Moments.fromJson(_moment({'imageVariants': bad})),
            returnsNormally);
      }
      final m = Moments.fromJson(_moment({'hashtags': 'x', 'topics': 5}));
      expect(m.hashtags, isEmpty);
      expect(m.topics, isEmpty);
    });

    test('copyWith keeps the new fields', () {
      final m = Moments.fromJson(_moment({
        'imageVariants': [_variant('a.jpg')],
        'hashtags': ['k'],
        'needsFeedback': true,
      }));
      final c = m.copyWith(likeCount: 3);
      expect(c.imageVariants, hasLength(1));
      expect(c.hashtags, ['k']);
      expect(c.needsFeedback, isTrue);
    });
  });

  group('ImageVariant', () {
    test('aspectRatio is width / height, null when either is not > 0', () {
      final v = ImageVariant.listFromJson([_variant('a.jpg')]).single;
      expect(v.aspectRatio, closeTo(1.3333, 0.001));
      final zero = ImageVariant.listFromJson([_variant('a.jpg')..['width'] = 0]);
      expect(zero.single.aspectRatio, isNull);
      final none = ImageVariant.listFromJson([
        {'url': 'u', 'feedUrl': 'f'}
      ]);
      expect(none.single.aspectRatio, isNull);
    });

    test('listFromJson skips entries without url and feedUrl', () {
      final list = ImageVariant.listFromJson([
        {'url': 'u'},
        {'feedUrl': 'f'},
        {'url': '', 'feedUrl': 'f'},
        null,
        'x',
        _variant('ok.jpg'),
      ]);
      expect(list.map((v) => v.url), ['ok.jpg']);
      expect(ImageVariant.listFromJson(null), isEmpty);
      expect(ImageVariant.listFromJson('nope'), isEmpty);
    });
  });

  group('Story', () {
    Map<String, dynamic> story([Map<String, dynamic> extra = const {}]) => {
          '_id': 's1',
          'mediaUrl': 'a.jpg',
          'mediaUrls': ['a.jpg'],
          ...extra,
        };

    test('defaults and variantFor', () {
      final s = Story.fromJson(story());
      expect(s.imageVariants, isEmpty);
      expect(s.variantFor('a.jpg'), isNull);
      final v = Story.fromJson(story({
        'imageVariants': [_variant('a.jpg')]
      }));
      expect(v.variantFor('a.jpg')?.url, 'a.jpg');
      expect(v.variantFor('z.jpg'), isNull);
      expect(v.copyWith(viewCount: 2).imageVariants, hasLength(1));
    });

    test('malformed variants never throw', () {
      for (final bad in <Object?>['oops', [null], [<String, dynamic>{}]]) {
        expect(() => Story.fromJson(story({'imageVariants': bad})),
            returnsNormally);
      }
    });
  });

  group('Community.avatarUrl', () {
    Community user(Map<String, dynamic> extra) =>
        Community.fromJson({'_id': 'u', 'name': 'n', ...extra});

    test('prefers avatarThumb', () {
      final u = user({
        'avatarThumb': 't.jpg',
        'imageUrls': ['full.jpg'],
      });
      expect(u.avatarThumb, 't.jpg');
      expect(u.avatarUrl, 't.jpg');
    });

    test('falls back to imageUrls, then images, then null', () {
      expect(user({'imageUrls': ['full.jpg']}).avatarUrl, 'full.jpg');
      expect(user({'images': ['old.jpg']}).avatarUrl, 'old.jpg');
      expect(user({'avatarThumb': ''}).avatarUrl, isNull);
      expect(user({}).avatarUrl, isNull);
      expect(user({'avatarThumb': 5}).avatarThumb, isNull);
    });
  });

  group('AppConfig flags', () {
    test('default false', () {
      final c = AppConfig.fromJson({});
      expect(c.feedThumbnailsEnabled, isFalse);
      expect(c.storyDiscoverEnabled, isFalse);
      expect(c.hashtagsEnabled, isFalse);
      expect(c.interestRankingEnabled, isFalse);
      expect(c.shareOffersEnabled, isFalse);
    });

    test('parse true', () {
      final c = AppConfig.fromJson({
        'feedThumbnailsEnabled': true,
        'storyDiscoverEnabled': true,
        'hashtagsEnabled': true,
        'interestRankingEnabled': true,
        'shareOffersEnabled': true,
      });
      expect(c.feedThumbnailsEnabled, isTrue);
      expect(c.storyDiscoverEnabled, isTrue);
      expect(c.hashtagsEnabled, isTrue);
      expect(c.interestRankingEnabled, isTrue);
      expect(c.shareOffersEnabled, isTrue);
    });

    test('a malformed value reads as off and does not throw', () {
      final c = AppConfig.fromJson({
        'feedThumbnailsEnabled': 'true',
        'storyDiscoverEnabled': 1,
        'hashtagsEnabled': 'yes',
        'interestRankingEnabled': <String>[],
        'shareOffersEnabled': 'true',
      });
      expect(c.feedThumbnailsEnabled, isFalse);
      expect(c.storyDiscoverEnabled, isFalse);
      expect(c.hashtagsEnabled, isFalse);
      expect(c.interestRankingEnabled, isFalse);
      expect(c.shareOffersEnabled, isFalse);
    });
  });
}
