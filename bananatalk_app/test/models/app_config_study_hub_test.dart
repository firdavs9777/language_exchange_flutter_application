import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/app_config.dart';

void main() {
  AppConfig parse(Map<String, dynamic> extra) =>
      AppConfig.fromJson({'minVersion': '1.0.0', ...extra});

  test('older server: hub off, nothing VIP-only', () {
    final c = parse({});
    expect(c.studyHubEnabled, isFalse);
    expect(c.studyVipOnlyFeatures, isEmpty);
  });

  test('reads both fields', () {
    final c = parse({
      'studyHubEnabled': true,
      'studyVipOnlyFeatures': ['photo', 'story'],
    });
    expect(c.studyHubEnabled, isTrue);
    expect(c.studyVipOnlyFeatures, {'photo', 'story'});
  });

  test('malformed list never crashes and keeps strings only', () {
    expect(parse({'studyVipOnlyFeatures': 'photo'}).studyVipOnlyFeatures, isEmpty);
    expect(parse({'studyVipOnlyFeatures': ['photo', 3, null, true]}).studyVipOnlyFeatures,
        {'photo'});
    expect(parse({'studyHubEnabled': 'yes'}).studyHubEnabled, isFalse);
  });
}
