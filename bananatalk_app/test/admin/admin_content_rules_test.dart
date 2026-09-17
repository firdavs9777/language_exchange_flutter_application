import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/admin/admin_content_rules.dart';

void main() {
  group('isRemoved', () {
    test('archived and cancelled both mean removed from discovery', () {
      // Both are states the app ALREADY filters on, which is why moderation
      // uses them instead of deleting.
      expect(isRemoved('archived'), isTrue);
      expect(isRemoved('cancelled'), isTrue);
    });

    test('live states are not removed', () {
      for (final s in ['active', 'scheduled', 'confirmed', 'live', 'ended']) {
        expect(isRemoved(s), isFalse, reason: s);
      }
    });

    test('a missing status is not treated as removed', () {
      // Guessing "removed" would strike through a healthy row and offer the
      // wrong action.
      expect(isRemoved(null), isFalse);
      expect(isRemoved(''), isFalse);
    });
  });

  group('moderationActionLabel', () {
    test('a club toggles between Archive and Restore', () {
      expect(moderationActionLabel(isClub: true, status: 'active'), 'Archive');
      expect(moderationActionLabel(isClub: true, status: 'archived'), 'Restore');
    });

    test('a gathering always says Cancel, never Restore', () {
      // People were told it was off. Silently reinstating it would summon them
      // back to something they have stopped planning around.
      for (final s in ['scheduled', 'confirmed', 'cancelled', null]) {
        expect(moderationActionLabel(isClub: false, status: s), 'Cancel');
      }
    });
  });

  group('actionNeedsReason', () {
    test('removing something asks why', () {
      expect(actionNeedsReason(isClub: true, status: 'active'), isTrue);
      expect(actionNeedsReason(isClub: false, status: 'scheduled'), isTrue);
    });

    test('restoring does not interrogate the moderator', () {
      expect(actionNeedsReason(isClub: true, status: 'archived'), isFalse);
    });
  });

  group('moderationSubtitle', () {
    test('composes owner, status and size', () {
      expect(
        moderationSubtitle(
            isClub: true, ownerName: 'Dana', status: 'active', count: 12),
        'Dana · active · 12 members',
      );
      expect(
        moderationSubtitle(
            isClub: false, ownerName: 'Sam', status: 'scheduled', count: 3),
        'Sam · scheduled · 3 going',
      );
    });

    test('an unpopulated owner leaves no stray separator', () {
      // Common in lean payloads; "· active · 0 members" reads as a bug.
      expect(
        moderationSubtitle(isClub: true, ownerName: '', status: 'active'),
        'active · 0 members',
      );
      expect(
        moderationSubtitle(isClub: true, ownerName: null, status: null),
        '0 members',
      );
    });

    test('whitespace-only values are dropped too', () {
      expect(
        moderationSubtitle(isClub: true, ownerName: '   ', status: '  '),
        '0 members',
      );
    });
  });
}
