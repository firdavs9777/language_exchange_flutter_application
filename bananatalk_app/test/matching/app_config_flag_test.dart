import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/app_config.dart';

void main() {
  test('matchesLayoutEnabled parses true', () {
    expect(AppConfig.fromJson({'matchesLayoutEnabled': true}).matchesLayoutEnabled, true);
  });
  test('matchesLayoutEnabled defaults to false', () {
    expect(AppConfig.fromJson({}).matchesLayoutEnabled, false);
  });
}
