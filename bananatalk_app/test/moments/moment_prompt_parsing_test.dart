import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _moment([Map<String, dynamic> extra = const {}]) => {
      '_id': 'm1',
      'description': 'hello',
      'createdAt': '2026-10-15T00:00:00.000Z',
      ...extra,
    };

void main() {
  group('Moments.fromJson prompt / location / isReel', () {
    test('an older backend without the new fields still parses', () {
      final m = Moments.fromJson(_moment());
      expect(m.prompt, isNull);
      expect(m.promptId, isNull);
      expect(m.location, isNull);
      expect(m.isReel, isFalse);
    });

    test('a populated prompt is parsed and displayed with its emoji', () {
      final m = Moments.fromJson(_moment({
        'promptId': 'p1',
        'prompt': {
          '_id': 'p1',
          'text': 'What did you eat today?',
          'emoji': '🍜',
          'language': 'en',
        },
        'isReel': true,
      }));
      expect(m.promptId, 'p1');
      expect(m.prompt!.text, 'What did you eat today?');
      expect(m.prompt!.display, '🍜 What did you eat today?');
      expect(m.isReel, isTrue);
    });

    test('prompt: null with a raw promptId keeps just the id', () {
      final m = Moments.fromJson(_moment({'promptId': 'p2', 'prompt': null}));
      expect(m.promptId, 'p2');
      expect(m.prompt, isNull);
    });

    test('a prompt that is a bare id string or has no text is ignored', () {
      expect(Moments.fromJson(_moment({'prompt': 'p3'})).prompt, isNull);
      expect(
        Moments.fromJson(_moment({
          'prompt': {'_id': 'p3', 'text': '  '}
        })).prompt,
        isNull,
      );
    });

    test('a prompt without an emoji displays only its text', () {
      final m = Moments.fromJson(_moment({
        'prompt': {'_id': 'p4', 'text': 'Hi'}
      }));
      expect(m.prompt!.display, 'Hi');
      expect(m.promptId, 'p4');
    });

    test('location is parsed defensively', () {
      final m = Moments.fromJson(_moment({
        'location': {
          'type': 'Point',
          'coordinates': [127, 37.5],
          'formattedAddress': 'Seoul',
        }
      }));
      expect(m.location!.coordinates, [127.0, 37.5]);
      expect(m.location!.formattedAddress, 'Seoul');

      expect(Moments.fromJson(_moment({'location': 'nope'})).location, isNull);
      expect(Moments.fromJson(_moment({'location': {}})).location, isNull);
      expect(
        Moments.fromJson(_moment({
          'location': {'coordinates': ['x', null]}
        })).location,
        isNull,
      );
    });
  });
}
