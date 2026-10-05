import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/utils/user_age.dart';

/// These mirror the backend's `test/userAge.test.js` case for case. The two
/// must agree: the server gates minors on its own `isMinor`, so an app that
/// rounds ages up can show a 17-year-old as 18.
void main() {
  final now = DateTime(2026, 9, 17);

  group('ageFrom', () {
    test('a plain birthday computes the age', () {
      expect(ageFrom('2000', '1', '15', now: now), 26);
    });

    test('the birthday has not happened yet this year', () {
      expect(ageFrom('2000', '12', '31', now: now), 25);
    });

    test('the birthday is today -- they are the older age', () {
      expect(ageFrom('2008', '9', '17', now: now), 18);
    });

    test('the day before an 18th birthday is still 17', () {
      expect(ageFrom('2008', '9', '18', now: now), 17);
    });

    test('a later month this year has not come round yet', () {
      expect(ageFrom('2000', '10', '1', now: now), 25);
    });

    test('an earlier month this year has already passed', () {
      expect(ageFrom('2000', '8', '1', now: now), 26);
    });

    test('whitespace around the parts is tolerated', () {
      expect(ageFrom(' 2000 ', ' 1 ', ' 15 ', now: now), 26);
    });

    test('an empty birthdate gives null, never a guess', () {
      expect(ageFrom('', '', '', now: now), isNull);
      expect(ageFrom('2000', '', '', now: now), isNull);
    });

    test('a malformed birthdate gives null, never a guess', () {
      expect(ageFrom('abcd', '1', '1', now: now), isNull);
      expect(ageFrom('2000', 'x', '1', now: now), isNull);
      expect(ageFrom('2000', '1', 'x', now: now), isNull);
    });

    test('an out-of-range month or day gives null', () {
      expect(ageFrom('2000', '0', '15', now: now), isNull);
      expect(ageFrom('2000', '13', '15', now: now), isNull);
      expect(ageFrom('2000', '1', '0', now: now), isNull);
      expect(ageFrom('2000', '1', '32', now: now), isNull);
    });

    test('an implausible age gives null rather than a negative or a 900', () {
      expect(ageFrom('2030', '1', '1', now: now), isNull);
      expect(ageFrom('1850', '1', '1', now: now), isNull);
    });

    test('defaults to the current clock when now is omitted', () {
      // Born today's month/day in 2000: the birthday has arrived, so the age
      // is exactly the year difference whenever this runs.
      final today = DateTime.now();
      expect(
        ageFrom('2000', '${today.month}', '${today.day}'),
        today.year - 2000,
      );
    });
  });
}
