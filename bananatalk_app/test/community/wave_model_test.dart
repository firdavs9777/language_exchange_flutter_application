import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';

void main() {
  group('Wave.fromJson', () {
    test('parses backend-shaped payload with populated from object', () {
      final json = {
        'waveId': 'w1',
        'from': {
          '_id': 'u1',
          'name': 'Kim',
          'images': ['http://x/a.jpg'],
        },
        'message': 'hi',
        'isRead': false,
        'createdAt': '2026-07-12T00:00:00Z',
      };

      final wave = Wave.fromJson(json);

      expect(wave.id, 'w1');
      expect(wave.fromUserId, 'u1');
      expect(wave.fromUserName, 'Kim');
      expect(wave.fromUserImage, 'http://x/a.jpg');
      expect(wave.message, 'hi');
      expect(wave.isRead, false);
      expect(wave.createdAt, DateTime.parse('2026-07-12T00:00:00Z'));
    });

    test('falls back to legacy flat shape when from object is absent', () {
      final json = {
        '_id': 'w2',
        'fromUserId': 'u2',
        'fromUserName': 'Legacy',
        'fromUserImage': 'http://x/legacy.jpg',
        'message': 'hello',
        'isRead': true,
        'createdAt': '2026-07-01T00:00:00Z',
      };

      final wave = Wave.fromJson(json);

      expect(wave.id, 'w2');
      expect(wave.fromUserId, 'u2');
      expect(wave.fromUserName, 'Legacy');
      expect(wave.fromUserImage, 'http://x/legacy.jpg');
      expect(wave.message, 'hello');
      expect(wave.isRead, true);
      expect(wave.createdAt, DateTime.parse('2026-07-01T00:00:00Z'));
    });

    test('handles missing from.images gracefully', () {
      final json = {
        'waveId': 'w3',
        'from': {'_id': 'u3', 'name': 'NoImage'},
        'isRead': false,
        'createdAt': '2026-07-05T00:00:00Z',
      };

      final wave = Wave.fromJson(json);

      expect(wave.id, 'w3');
      expect(wave.fromUserId, 'u3');
      expect(wave.fromUserName, 'NoImage');
      expect(wave.fromUserImage, isNull);
    });
  });
}
