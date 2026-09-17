import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/notification_permission.dart';

void main() {
  group('notificationActionFor', () {
    test('an authorized user is never disturbed', () {
      // The safety property of the whole change: anyone who already granted
      // notifications must see no behavioural difference at all.
      for (final prompted in [true, false]) {
        expect(
          notificationActionFor(
            permission: NotificationPermission.authorized,
            alreadyPrompted: prompted,
          ),
          NotificationAction.none,
        );
      }
    });

    test('a provisional iOS user is offered an upgrade, once', () {
      expect(
        notificationActionFor(
          permission: NotificationPermission.provisional,
          alreadyPrompted: false,
        ),
        NotificationAction.upgrade,
      );
      expect(
        notificationActionFor(
          permission: NotificationPermission.provisional,
          alreadyPrompted: true,
        ),
        NotificationAction.none,
      );
    });

    test('an unasked user is asked, once', () {
      expect(
        notificationActionFor(
          permission: NotificationPermission.notDetermined,
          alreadyPrompted: false,
        ),
        NotificationAction.ask,
      );
      expect(
        notificationActionFor(
          permission: NotificationPermission.notDetermined,
          alreadyPrompted: true,
        ),
        NotificationAction.none,
      );
    });

    test('a denied user is offered recovery, and is never asked again', () {
      // The OS will not show the dialog a second time, so returning `ask` here
      // would be a silent no-op that burns the one chance the UI has to say
      // something useful.
      for (final prompted in [true, false]) {
        expect(
          notificationActionFor(
            permission: NotificationPermission.denied,
            alreadyPrompted: prompted,
          ),
          NotificationAction.recover,
        );
      }
    });

    test('every permission maps to some action', () {
      // Guards the switch against a future enum value falling through.
      for (final p in NotificationPermission.values) {
        expect(
          () => notificationActionFor(permission: p, alreadyPrompted: false),
          returnsNormally,
        );
      }
    });
  });

  group('permissionFromStatusName', () {
    test('maps the Firebase AuthorizationStatus names', () {
      expect(permissionFromStatusName('authorized'),
          NotificationPermission.authorized);
      expect(permissionFromStatusName('provisional'),
          NotificationPermission.provisional);
      expect(permissionFromStatusName('denied'), NotificationPermission.denied);
      expect(permissionFromStatusName('notDetermined'),
          NotificationPermission.notDetermined);
    });

    test('an unknown name becomes notDetermined, never authorized', () {
      // Guessing "authorized" would permanently suppress the ask on a platform
      // whose status name we failed to anticipate -- a failure invisible in
      // production, because nothing would ever be shown or logged.
      expect(permissionFromStatusName('ephemeral'),
          NotificationPermission.notDetermined);
      expect(permissionFromStatusName(''), NotificationPermission.notDetermined);
    });
  });
}
