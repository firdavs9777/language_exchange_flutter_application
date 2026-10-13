import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';
import 'package:bananatalk_app/services/link_constants.dart';
import 'package:bananatalk_app/services/moments_service.dart';

void main() {
  test('builds share urls', () {
    expect(shareUrl('moment', '123'), 'https://banatalk.com/moment/123');
    expect(shareUrl('profile', 'u9'), 'https://banatalk.com/profile/u9');
    expect(shareUrl('community', 'c1'), 'https://banatalk.com/community/c1');
  });

  test('the save-sheet moment link is one the app opens (singular /moment/)', () {
    final link = MomentsService.getShareableLink('123');
    expect(link, 'https://banatalk.com/moment/123');
    expect(routePathFromUri(Uri.parse(link)), '/moment/123');
  });
}
