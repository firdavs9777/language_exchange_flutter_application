import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';

const kId = '64b7f0c2a1b2c3d4e5f60718';
String? p(String s) => routePathFromUri(Uri.parse(s));

void main() {
  group('story links (links#1)', () {
    test('https and custom scheme', () {
      expect(p('https://banatalk.com/story/$kId'), '/story/$kId');
      expect(p('bananatalk://story/$kId'), '/story/$kId');
    });
    test('malformed ids are dropped', () {
      for (final bad in [
        'abc',
        '64b7f0c2a1b2c3d4e5f6071',
        '64b7f0c2a1b2c3d4e5f60718x',
        'zzzzzzzzzzzzzzzzzzzzzzzz',
      ]) {
        expect(p('https://banatalk.com/story/$bad'), isNull, reason: bad);
      }
      expect(p('https://banatalk.com/story/'), isNull);
    });
    test('the parked domain and www are not ours', () {
      expect(p('https://bananatalk.com/story/$kId'), isNull);
      expect(p('https://www.banatalk.com/story/$kId'), isNull);
    });
  });

  group('chat links (links#6)', () {
    test('open the chat with that user', () {
      expect(p('https://banatalk.com/chat/$kId'), '/chat/$kId');
      expect(p('bananatalk://chat/$kId'), '/chat/$kId');
    });
    test('query parameters never reach the route (no auto-call, no prefill)', () {
      expect(p('https://banatalk.com/chat/$kId?call=video&prefill=hi'), '/chat/$kId');
      expect(p('bananatalk://chat/$kId?call=audio'), '/chat/$kId');
    });
    test('malformed ids and the bare /chat page are dropped', () {
      expect(p('https://banatalk.com/chat/settings'), isNull);
      expect(p('https://banatalk.com/chat'), isNull);
    });
  });

  group('legacy profile QR bananatalk://user/<id> (links#8)', () {
    test('opens the profile', () {
      expect(p('bananatalk://user/$kId'), '/profile/$kId');
    });
    test('only as the custom scheme, only with a real id', () {
      expect(p('https://banatalk.com/user/$kId'), isNull);
      expect(p('bananatalk://user/abc'), isNull);
    });
  });

  group('userIdFromQrPayload', () {
    test('accepts the https profile link and both scheme forms', () {
      expect(userIdFromQrPayload('https://banatalk.com/profile/$kId'), kId);
      expect(userIdFromQrPayload('bananatalk://user/$kId'), kId);
      expect(userIdFromQrPayload('  bananatalk://profile/$kId  '), kId);
    });
    test('rejects everything else', () {
      for (final raw in [
        'https://banatalk.com/moment/$kId',
        'https://banatalk.com/profile/edit',
        'https://banatalk.com/profile/stats',
        'https://evil.com/profile/$kId',
        'bananatalk://user/',
        'hello',
        '',
      ]) {
        expect(userIdFromQrPayload(raw), isNull, reason: raw);
      }
    });
  });

  group('normalizeInviteCode', () {
    test('upper-cases and trims', () {
      expect(normalizeInviteCode('abcd2345'), 'ABCD2345');
      expect(normalizeInviteCode(' ABCD2345 '), 'ABCD2345');
    });
    test('rejects non-codes', () {
      for (final bad in [null, '', 'ABC', 'ABCD1890', 'ABCD-2345', 'A' * 17]) {
        expect(normalizeInviteCode(bad), isNull, reason: '$bad');
      }
    });
  });

  test('existing link shapes are unchanged (2.6.1 links keep working)', () {
    expect(p('https://banatalk.com/moment/123'), '/moment/123');
    expect(p('bananatalk://profile/u9'), '/profile/u9');
    expect(p('https://banatalk.com/community/c1'), '/community/c1');
    expect(p('https://banatalk.com/community/waves'), '/community/waves');
    expect(p('https://banatalk.com/i/abcd2345'), '/invite/ABCD2345');
    expect(p('https://banatalk.com/settings'), isNull);
  });
}
