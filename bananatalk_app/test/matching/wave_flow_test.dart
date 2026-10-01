import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';

void main() {
  group('parseWavesUnreadCount', () {
    test('returns the server unreadCount, not the page size', () {
      final body = {
        'success': true,
        'data': {
          'waves': [
            {'_id': 'a'},
          ],
          'unreadCount': 137,
        },
        'pagination': {'total': 400},
      };
      expect(parseWavesUnreadCount(body), 137);
    });

    test('missing / malformed shapes read as 0', () {
      expect(parseWavesUnreadCount(null), 0);
      expect(parseWavesUnreadCount({'data': []}), 0);
      expect(parseWavesUnreadCount({'data': {'waves': []}}), 0);
      expect(parseWavesUnreadCount({'data': {'unreadCount': -3}}), 0);
      expect(parseWavesUnreadCount({'data': {'unreadCount': '5'}}), 5);
    });
  });
}
