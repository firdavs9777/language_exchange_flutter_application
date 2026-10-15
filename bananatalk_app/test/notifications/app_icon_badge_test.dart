import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/app_icon_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppIconBadge.channel, (call) async {
      calls.add(call);
      return null;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppIconBadge.channel, null);
  });

  test('iOS: sets the icon badge to the count', () async {
    await AppIconBadge.set(4, isIOS: true);
    expect(calls.single.method, 'setBadge');
    expect(calls.single.arguments, {'count': 4});
  });

  test('iOS: clear sets 0, negatives clamp to 0', () async {
    await AppIconBadge.set(0, isIOS: true);
    await AppIconBadge.set(-3, isIOS: true);
    expect(calls.map((c) => c.arguments), [
      {'count': 0},
      {'count': 0},
    ]);
  });

  test('other platforms: no channel call', () async {
    await AppIconBadge.set(4, isIOS: false);
    expect(calls, isEmpty);
  });

  test('a missing native side never throws', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppIconBadge.channel, null);
    await AppIconBadge.set(1, isIOS: true);
  });
}
