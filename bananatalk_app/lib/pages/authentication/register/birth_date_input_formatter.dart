import 'package:flutter/services.dart';

/// Lets a birth date be TYPED as "YYYY.MM.DD", inserting the separators.
///
/// The field was tap-to-open-calendar only, which is a poor fit for a date
/// decades in the past — a 1995 birthday is dozens of swipes from today, on
/// the one screen where social signups are already abandoning the wizard.
///
/// Digits are the only meaningful input, so anything else is dropped rather
/// than refused: pasting "1995-07-04" or "1995/07/04" yields "1995.07.04"
/// instead of an error the user has to decode. The output format is exactly
/// what [parseBirthDateParts] consumes.
class BirthDateInputFormatter extends TextInputFormatter {
  static const _maxDigits = 8; // YYYYMMDD

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final capped = digits.length > _maxDigits
        ? digits.substring(0, _maxDigits)
        : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      // After the 4-digit year and again after the 2-digit month.
      if (i == 4 || i == 6) buffer.write('.');
      buffer.write(capped[i]);
    }
    final text = buffer.toString();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
