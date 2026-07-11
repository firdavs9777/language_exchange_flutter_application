import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/authentication/widgets/password_strength_meter.dart';

void main() {
  test('scores passwords per backend policy (8+, upper, lower, digit)', () {
    expect(scorePassword(''), PasswordStrength.empty);
    expect(scorePassword('abc'), PasswordStrength.weak);           // too short
    expect(scorePassword('abcdefgh'), PasswordStrength.weak);      // no upper/digit
    expect(scorePassword('Abcdefg1'), PasswordStrength.fair);      // meets minimum
    expect(scorePassword('Abcdefg1!xY23'), PasswordStrength.strong); // length 12+ & symbol
  });
}
