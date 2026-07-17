import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/link_constants.dart';

void main() {
  test('builds share urls', () {
    expect(shareUrl('moment', '123'), 'https://banatalk.com/moment/123');
    expect(shareUrl('profile', 'u9'), 'https://banatalk.com/profile/u9');
    expect(shareUrl('community', 'c1'), 'https://banatalk.com/community/c1');
  });
}
