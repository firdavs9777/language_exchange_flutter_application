import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';

void main() {
  test('parses https universal link', () {
    expect(routePathFromUri(Uri.parse('https://banatalk.com/moment/123')), '/moment/123');
  });
  test('parses custom scheme', () {
    expect(routePathFromUri(Uri.parse('bananatalk://profile/u9')), '/profile/u9');
  });
  test('parses community', () {
    expect(routePathFromUri(Uri.parse('https://banatalk.com/community/c1')), '/community/c1');
  });
  test('returns null for unknown host path', () {
    expect(routePathFromUri(Uri.parse('https://banatalk.com/settings')), isNull);
  });
  test('returns null for wrong domain', () {
    expect(routePathFromUri(Uri.parse('https://evil.com/moment/1')), isNull);
  });
}
