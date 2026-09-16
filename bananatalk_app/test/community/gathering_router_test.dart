import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/services/notification_router.dart';

/// Where a 모임 notification lands when it is tapped.
///
/// Every gathering notification the backend sends carries `gatheringId`, and
/// before these cases existed all of them fell through to the home screen —
/// including the 24h reminder, which spec §5 calls the load-bearing one. A
/// reminder that opens the home screen is most of the way to not being a
/// reminder at all.
void main() {
  const gatheringTypes = [
    // services/gatheringNotifications.js — event-driven.
    'gathering_created',
    'gathering_confirmed',
    'gathering_join_request',
    'gathering_join_approved',
    'gathering_join_denied',
    'gathering_ended',
    // jobs/gatheringReminders.js — time-driven. Sent with raw fcmService, so
    // it never appears in the Notification enum, but it is still a tap that
    // has to land somewhere.
    'gathering_reminder',
    'gathering_host_decision',
    'gathering_cancelled',
  ];

  group('gathering notifications open the gathering', () {
    for (final type in gatheringTypes) {
      test('$type deep-links by id', () {
        expect(
          NotificationRouter.targetPathForType(type, const {
            'gatheringId': 'abc123',
          }),
          '/gathering/abc123',
        );
      });
    }

    test('every type the backend sends is routed — none fall through', () {
      // The failure this catches is silent: a new type added on the server
      // with no case here taps through to home, and nothing anywhere reports
      // it. Keep this list in step with the enum in models/Notification.js.
      for (final type in gatheringTypes) {
        final path = NotificationRouter.targetPathForType(type, const {
          'gatheringId': 'g1',
        });
        expect(path, isNotNull, reason: '$type has no router case');
        expect(path, isNot('/'), reason: '$type falls through to home');
      }
    });
  });

  group('fallbacks', () {
    test('a missing id lands on Community, not on home', () {
      // A cancelled or deleted gathering still has a sensible destination:
      // the tab that lists them. Same "closest available surface" rule the
      // room cases use.
      for (final type in gatheringTypes) {
        expect(
          NotificationRouter.targetPathForType(type, const {}),
          '/tabs/1',
          reason: '$type with no gatheringId',
        );
      }
    });

    test('an empty id is treated as missing, not as a path', () {
      // '/gathering/' would be a 404 inside the app rather than a fallback.
      expect(
        NotificationRouter.targetPathForType('gathering_reminder', const {
          'gatheringId': '',
        }),
        '/tabs/1',
      );
    });
  });

  test('an unrelated type is not swept into the gathering route', () {
    expect(
      NotificationRouter.targetPathForType('chat_message', const {
        'senderId': 'u1',
      }),
      '/chat/u1',
    );
  });
}
