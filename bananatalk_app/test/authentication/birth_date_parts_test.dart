import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/authentication/register/birth_date_parts.dart';

void main() {
  group('parseBirthDateParts', () {
    test('splits a normal date', () {
      final parts = parseBirthDateParts('1995.07.04');
      expect(parts, isNotNull);
      expect(parts!.year, '1995');
      expect(parts.month, '07');
      expect(parts.day, '04');
    });

    test('an empty string is null, not empty parts', () {
      // THE BUG: ''.split('.') is [''], so `isNotEmpty ? parts[0] : ''` handed
      // back '' and the guard never fired. birth_year: '' then shipped to the
      // server with profileCompleted: true.
      expect(''.split('.').isNotEmpty, isTrue, reason: 'the trap itself');
      expect(''.split('.').first, '');
      expect(parseBirthDateParts(''), isNull);
      expect(parseBirthDateParts('   '), isNull);
    });

    test('a partial date is null', () {
      expect(parseBirthDateParts('1995'), isNull);
      expect(parseBirthDateParts('1995.07'), isNull);
      expect(parseBirthDateParts('1995..04'), isNull);
      expect(parseBirthDateParts('..'), isNull);
    });

    test('a dash-separated date is null rather than a garbage year', () {
      // Would otherwise yield year = "1995-07-04", which the server stores
      // happily and ageFrom can never parse — worse than a rejection, because
      // it looks like a real value.
      expect(parseBirthDateParts('1995-07-04'), isNull);
    });

    test('non-numeric parts are rejected', () {
      expect(parseBirthDateParts('abcd.07.04'), isNull);
      expect(parseBirthDateParts('1995.jul.04'), isNull);
    });

    test('impossible dates are rejected', () {
      expect(parseBirthDateParts('1995.13.04'), isNull);
      expect(parseBirthDateParts('1995.00.04'), isNull);
      expect(parseBirthDateParts('1995.07.32'), isNull);
      expect(parseBirthDateParts('1995.07.00'), isNull);
      expect(parseBirthDateParts('1800.07.04'), isNull);
    });

    test('dates that do not exist are rejected, not rolled forward', () {
      // THE BUG: step 1 validated with DateTime(y, m, d), which turns
      // 1995.13.40 into 1996.02.09 and 1995.02.30 into 1995.03.02.
      expect(DateTime(1995, 2, 30).month, 3, reason: 'the trap itself');
      expect(parseBirthDateParts('1995.13.40'), isNull);
      expect(parseBirthDateParts('1995.02.30'), isNull);
      expect(parseBirthDateParts('2001.04.31'), isNull);
      expect(parseBirthDateParts('1999.02.29'), isNull);
      expect(parseBirthDate('1995.13.40'), isNull);
    });

    test('real edge dates are accepted', () {
      expect(parseBirthDateParts('2000.02.29'), isNotNull); // leap year
      expect(parseBirthDate('1995.12.31'), DateTime(1995, 12, 31));
    });

    test('boundary years are accepted', () {
      expect(parseBirthDateParts('1900.01.01'), isNotNull);
      expect(parseBirthDateParts('2200.12.31'), isNotNull);
    });
  });

  group('ageInYears', () {
    test('counts a birthday not yet reached this year as one fewer', () {
      final today = DateTime(2026, 10, 8);
      expect(ageInYears(DateTime(2008, 10, 8), today), 18);
      expect(ageInYears(DateTime(2008, 10, 9), today), 17);
      expect(ageInYears(DateTime(2008, 11, 1), today), 17);
    });
  });
}
