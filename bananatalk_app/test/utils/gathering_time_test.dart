import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/utils/gathering_time.dart';

/// Table tests for the 모임 time helpers.
///
/// No mocked clock anywhere: every function takes `now` as a parameter, so
/// "two hours before a gathering" is a value, not a wait.
void main() {
  group('gatheringDayBucket', () {
    test('a start that has passed is past, however recently', () {
      final now = DateTime(2026, 9, 16, 20, 0);
      expect(
        gatheringDayBucket(DateTime(2026, 9, 16, 19, 59), now),
        GatheringDayBucket.past,
      );
    });

    test('later today is today', () {
      final now = DateTime(2026, 9, 16, 9, 0);
      expect(
        gatheringDayBucket(DateTime(2026, 9, 16, 19, 0), now),
        GatheringDayBucket.today,
      );
    });

    test('two hours later can still be TOMORROW, and that is the point', () {
      // 23:00 tonight and 01:00 tomorrow are two hours apart. Bucketing by
      // elapsed duration would call both "today"; people plan by calendar
      // day, so the calendar day is what is compared.
      final now = DateTime(2026, 9, 16, 23, 0);
      expect(
        gatheringDayBucket(DateTime(2026, 9, 17, 1, 0), now),
        GatheringDayBucket.tomorrow,
      );
    });

    test('a whole day away but under 24h is still tomorrow', () {
      final now = DateTime(2026, 9, 16, 22, 0);
      expect(
        gatheringDayBucket(DateTime(2026, 9, 17, 9, 0), now),
        GatheringDayBucket.tomorrow,
      );
    });

    test('inside six days is this week, past that is later', () {
      final now = DateTime(2026, 9, 16, 10, 0);
      expect(
        gatheringDayBucket(DateTime(2026, 9, 21, 10, 0), now),
        GatheringDayBucket.thisWeek,
      );
      expect(
        gatheringDayBucket(DateTime(2026, 9, 24, 10, 0), now),
        GatheringDayBucket.later,
      );
    });

    test('a UTC start is bucketed against the viewer\'s local calendar', () {
      // The gathering is stored and sent in UTC; the viewer plans in local
      // time. Bucketing the UTC value directly is how a Seoul evening lands
      // on the wrong day.
      final start = DateTime.utc(2026, 9, 17, 10, 0);
      final now = start.toLocal().subtract(const Duration(hours: 3));
      expect(gatheringDayBucket(start, now), GatheringDayBucket.today);
    });
  });

  group('countdown', () {
    test('minutes until never goes negative', () {
      final now = DateTime(2026, 9, 16, 20, 0);
      expect(minutesUntil(DateTime(2026, 9, 16, 18, 0), now), 0);
    });

    test('the last hour is imminent, ninety minutes is not', () {
      final now = DateTime(2026, 9, 16, 18, 0);
      expect(isImminent(DateTime(2026, 9, 16, 18, 45), now), isTrue);
      expect(isImminent(DateTime(2026, 9, 16, 19, 30), now), isFalse);
    });

    test('a start that has passed is not imminent, it is underway', () {
      final start = DateTime(2026, 9, 16, 19, 0);
      final now = DateTime(2026, 9, 16, 19, 20);
      expect(isImminent(start, now), isFalse);
      expect(isUnderway(start, 60, now), isTrue);
    });

    test('underway ends exactly at the duration', () {
      final start = DateTime(2026, 9, 16, 19, 0);
      expect(isUnderway(start, 60, DateTime(2026, 9, 16, 19, 59)), isTrue);
      expect(isUnderway(start, 60, DateTime(2026, 9, 16, 20, 0)), isFalse);
    });
  });

  group('formatLocalClock', () {
    test('pads both halves', () {
      expect(formatLocalClock(DateTime(2026, 9, 16, 9, 5)), '09:05');
      expect(formatLocalClock(DateTime(2026, 9, 16, 19, 0)), '19:00');
    });

    test('renders a UTC instant in the viewer\'s zone', () {
      final start = DateTime.utc(2026, 9, 16, 10, 0);
      expect(formatLocalClock(start), formatLocalClock(start.toLocal()));
    });
  });

  group('host zone line', () {
    test('a missing or blank zone shows nothing at all', () {
      expect(hostZoneLabel(null), isNull);
      expect(hostZoneLabel('   '), isNull);
    });

    test('the zone name is kept verbatim', () {
      expect(hostZoneLabel('Asia/Seoul'), 'Asia/Seoul');
      expect(hostZoneLabel(' America/New_York '), 'America/New_York');
    });

    test('the same zone is noise and is suppressed', () {
      expect(hostZoneWorthShowing('Asia/Seoul', 'Asia/Seoul'), isFalse);
      expect(hostZoneWorthShowing('Asia/Seoul', 'asia/seoul'), isFalse);
    });

    test('a different zone is shown, and so is an unknown viewer zone', () {
      expect(hostZoneWorthShowing('Asia/Seoul', 'Europe/Berlin'), isTrue);
      expect(hostZoneWorthShowing('Asia/Seoul', null), isTrue);
    });

    test('no host zone means no line, whatever the viewer\'s zone', () {
      expect(hostZoneWorthShowing(null, 'Europe/Berlin'), isFalse);
      expect(hostZoneWorthShowing('', 'Europe/Berlin'), isFalse);
    });
  });

  group('defaultGatheringStart', () {
    test('is tomorrow evening, local, on the hour', () {
      final now = DateTime(2026, 9, 16, 14, 37);
      final start = defaultGatheringStart(now);
      expect(start, DateTime(2026, 9, 17, 19, 0));
    });

    test('rolls the month and the year', () {
      expect(
        defaultGatheringStart(DateTime(2026, 12, 31, 23, 59)),
        DateTime(2027, 1, 1, 19, 0),
      );
    });

    test('is always in the future, even at 23:59', () {
      final now = DateTime(2026, 9, 16, 23, 59);
      expect(defaultGatheringStart(now).isAfter(now), isTrue);
    });
  });
}
