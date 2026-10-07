import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/authentication/register/birth_date_input_formatter.dart';

/// The birth date field used to be tap-to-open-calendar only, which is slow
/// for a date decades in the past: a 1995 birthday is ~30 swipes from today.
/// Typing it must be possible, and must produce exactly the "YYYY.MM.DD" that
/// parseBirthDateParts expects — the separators are inserted here so the user
/// never has to find the '.' key.
void main() {
  final f = BirthDateInputFormatter();

  TextEditingValue type(String s) => f.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length)),
      );

  group('BirthDateInputFormatter', () {
    test('inserts the separators as digits arrive', () {
      expect(type('1').text, '1');
      expect(type('1995').text, '1995');
      expect(type('19950').text, '1995.0');
      expect(type('199507').text, '1995.07');
      expect(type('1995070').text, '1995.07.0');
      expect(type('19950704').text, '1995.07.04');
    });

    test('a fully typed date is left alone', () {
      expect(type('1995.07.04').text, '1995.07.04');
    });

    test('non-digits are ignored rather than rejected', () {
      expect(type('1995/07/04').text, '1995.07.04');
      expect(type('1995-07-04').text, '1995.07.04');
      expect(type('abc1995').text, '1995');
    });

    test('input is capped at eight digits', () {
      expect(type('199507041234').text, '1995.07.04');
    });

    test('deleting back through a separator works', () {
      expect(type('1995.0').text, '1995.0');
      expect(type('1995.').text, '1995');
      expect(type('').text, '');
    });

    test('the caret stays at the end of what was typed', () {
      final v = type('19950704');
      expect(v.selection.baseOffset, v.text.length);
    });

    test('the result parses with the existing birth-date parser', () {
      expect(type('19950704').text, '1995.07.04');
    });
  });
}
