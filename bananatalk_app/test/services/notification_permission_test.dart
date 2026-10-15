import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/notification_permission.dart';

void main() {
  _startupProvisionalTests();

  group('notificationActionFor', () {
    test('an authorized user is never disturbed', () {
      // The safety property of the whole change: anyone who already granted
      // notifications must see no behavioural difference at all.
      for (final prompted in [true, false]) {
        expect(
          notificationActionFor(
            permission: NotificationPermission.authorized,
            alreadyPrompted: prompted,
            isAndroid: false,
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
          isAndroid: false,
        ),
        NotificationAction.upgrade,
      );
      expect(
        notificationActionFor(
          permission: NotificationPermission.provisional,
          alreadyPrompted: true,
          isAndroid: false,
        ),
        NotificationAction.none,
      );
    });

    test('an unasked user is asked, once', () {
      expect(
        notificationActionFor(
          permission: NotificationPermission.notDetermined,
          alreadyPrompted: false,
          isAndroid: false,
        ),
        NotificationAction.ask,
      );
      expect(
        notificationActionFor(
          permission: NotificationPermission.notDetermined,
          alreadyPrompted: true,
          isAndroid: false,
        ),
        NotificationAction.none,
      );
    });

    test('a denied iOS user is offered recovery, and is never asked again', () {
      // The OS will not show the dialog a second time, so returning `ask` here
      // would be a silent no-op that burns the one chance the UI has to say
      // something useful.
      for (final prompted in [true, false]) {
        expect(
          notificationActionFor(
            permission: NotificationPermission.denied,
            alreadyPrompted: prompted,
            isAndroid: false,
          ),
          NotificationAction.recover,
        );
      }
    });

    test('every permission maps to some action', () {
      // Guards the switch against a future enum value falling through.
      for (final p in NotificationPermission.values) {
        expect(
          () => notificationActionFor(
            permission: p,
            alreadyPrompted: false,
            isAndroid: false,
          ),
          returnsNormally,
        );
        expect(
          () => notificationActionFor(
            permission: p,
            alreadyPrompted: false,
            isAndroid: true,
          ),
          returnsNormally,
        );
      }
    });
  });

  group('notificationActionFor on Android', () {
    // firebase_messaging on Android only ever reports authorized or denied --
    // never notDetermined. On Android 13+ a fresh install that has not yet
    // been granted POST_NOTIFICATIONS reads as `denied`, so treating that as
    // a real refusal meant no Android 13+ user was ever asked.
    test('denied, never prompted on this install: ask at a primed moment', () {
      expect(
        notificationActionFor(
          permission: NotificationPermission.denied,
          alreadyPrompted: false,
          isAndroid: true,
        ),
        NotificationAction.ask,
      );
    });

    test('denied after we already asked: recover, never ask again', () {
      expect(
        notificationActionFor(
          permission: NotificationPermission.denied,
          alreadyPrompted: true,
          isAndroid: true,
        ),
        NotificationAction.recover,
      );
    });

    test('authorized (granted, or Android 12 and below): none', () {
      for (final prompted in [true, false]) {
        expect(
          notificationActionFor(
            permission: NotificationPermission.authorized,
            alreadyPrompted: prompted,
            isAndroid: true,
          ),
          NotificationAction.none,
        );
      }
    });

    test('iOS reports notDetermined itself, so a denial there stays final', () {
      expect(
        notificationActionFor(
          permission: NotificationPermission.denied,
          alreadyPrompted: false,
          isAndroid: false,
        ),
        NotificationAction.recover,
      );
    });
  });

  group('needsDeliverySetUpAfterGrant', () {
    test('a grant from the prime finishes the set-up start-up skipped', () {
      // Start-up skips handlers and local notifications for a `denied` status,
      // which on Android 13+ is every never-asked user.
      expect(
        needsDeliverySetUpAfterGrant(granted: true, deliverySetUp: false),
        isTrue,
      );
    });

    test('never repeats set-up, and never sets up without a grant', () {
      expect(
        needsDeliverySetUpAfterGrant(granted: true, deliverySetUp: true),
        isFalse,
      );
      expect(
        needsDeliverySetUpAfterGrant(granted: false, deliverySetUp: false),
        isFalse,
      );
      expect(
        needsDeliverySetUpAfterGrant(granted: false, deliverySetUp: true),
        isFalse,
      );
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

void _startupProvisionalTests() {
  group('shouldRequestProvisionalAtStartup', () {
    test('iOS, never asked: yes — a silent grant costs the user nothing', () {
      expect(
        shouldRequestProvisionalAtStartup(
          permission: NotificationPermission.notDetermined,
          isIOS: true,
        ),
        isTrue,
      );
    });

    test('Android, never asked: no — that would be the cold splash prompt', () {
      // Android has no provisional concept; requestPermission raises the real
      // POST_NOTIFICATIONS dialog, which is the bug this work removes.
      expect(
        shouldRequestProvisionalAtStartup(
          permission: NotificationPermission.notDetermined,
          isIOS: false,
        ),
        isFalse,
      );
    });

    test('never re-asks a user whose status is already settled', () {
      for (final p in [
        NotificationPermission.authorized,
        NotificationPermission.provisional,
        NotificationPermission.denied,
      ]) {
        expect(
          shouldRequestProvisionalAtStartup(permission: p, isIOS: true),
          isFalse,
          reason: '$p is settled and must not be re-requested',
        );
      }
    });
  });
}
