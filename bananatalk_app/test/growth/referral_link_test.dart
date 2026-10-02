import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/deep_link_parser.dart';

void main() {
  test('https invite link uppercases the code', () {
    expect(routePathFromUri(Uri.parse('https://banatalk.com/i/abc234')),
        '/invite/ABC234');
  });
  test('custom scheme invite link', () {
    expect(routePathFromUri(Uri.parse('bananatalk://i/ABC234')),
        '/invite/ABC234');
  });
  test('empty code is null', () {
    expect(routePathFromUri(Uri.parse('https://banatalk.com/i/')), isNull);
  });
  test('too-short code is null', () {
    expect(routePathFromUri(Uri.parse('https://banatalk.com/i/ab')), isNull);
  });
  test('invalid characters are null', () {
    expect(routePathFromUri(Uri.parse('https://banatalk.com/i/abc018')), isNull);
  });
  test('existing links unchanged', () {
    expect(routePathFromUri(Uri.parse('https://banatalk.com/moment/123')),
        '/moment/123');
    expect(routePathFromUri(Uri.parse('bananatalk://profile/u9')),
        '/profile/u9');
  });
}
