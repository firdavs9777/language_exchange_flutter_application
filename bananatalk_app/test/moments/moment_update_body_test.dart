import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('momentUpdateBody', () {
    test('an empty mood and empty tags are SENT, so they can be cleared', () {
      final body = momentUpdateBody(
        description: ' hi ',
        mood: '',
        tags: const [],
        backgroundColor: '',
      );
      expect(body['description'], 'hi');
      expect(body.containsKey('mood'), isTrue);
      expect(body['mood'], '');
      expect(body['tags'], isEmpty);
      expect(body['backgroundColor'], '');
    });

    test('null fields are omitted and images are never sent', () {
      final body = momentUpdateBody(description: 'hi');
      expect(body.keys, ['description']);
    });

    test('tags are capped at five', () {
      final body = momentUpdateBody(
        description: 'hi',
        tags: const ['a', 'b', 'c', 'd', 'e', 'f'],
      );
      expect(body['tags'], ['a', 'b', 'c', 'd', 'e']);
    });

    test('location and scheduledFor only when included; null clears', () {
      expect(
        momentUpdateBody(description: 'hi', location: {'x': 1})
            .containsKey('location'),
        isFalse,
      );
      final cleared = momentUpdateBody(
        description: 'hi',
        includeLocation: true,
        includeScheduledFor: true,
      );
      expect(cleared.containsKey('location'), isTrue);
      expect(cleared['location'], isNull);
      expect(cleared.containsKey('scheduledFor'), isTrue);
      expect(cleared['scheduledFor'], isNull);

      final set = momentUpdateBody(
        description: 'hi',
        includeLocation: true,
        location: {
          'coordinates': [127.0, 37.5],
          'formattedAddress': 'Seoul',
        },
        includeScheduledFor: true,
        scheduledFor: '2030-01-01T00:00:00.000Z',
      );
      expect(set['location']['formattedAddress'], 'Seoul');
      expect(set['scheduledFor'], '2030-01-01T00:00:00.000Z');
    });
  });
}
