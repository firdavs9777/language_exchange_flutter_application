import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/utils/subscription_links.dart';

void main() {
  test('Android opens Play subscriptions for this app', () {
    expect(
      subscriptionManagementUri(isIOS: false, packageName: 'com.bananatalk.app').toString(),
      'https://play.google.com/store/account/subscriptions?package=com.bananatalk.app',
    );
  });

  test('iOS opens App Store subscriptions', () {
    expect(subscriptionManagementUri(isIOS: true, packageName: 'x').toString(),
        'https://apps.apple.com/account/subscriptions');
  });

  test('the VIP status screen offers Manage on Android too, never "contact support to cancel"', () {
    final src = File('lib/pages/vip/vip_status_screen.dart').readAsStringSync();
    expect(src, contains('subscriptionManagementUri('));
    expect(src, isNot(contains('contactSupportToCancel')));
    expect(src, isNot(contains("apps.apple.com/account/subscriptions")));
    expect(RegExp(r'if \(Platform\.isIOS\)\s*\n\s*Padding').hasMatch(src), isFalse,
        reason: 'the manage buttons show on both platforms');
  });
}
