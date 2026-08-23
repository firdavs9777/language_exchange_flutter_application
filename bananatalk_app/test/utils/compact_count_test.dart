import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/utils/compact_count.dart';

void main() {
  group('formatCompactCount', () {
    test('renders counts below a thousand exactly', () {
      expect(formatCompactCount(0), '0');
      expect(formatCompactCount(7), '7');
      expect(formatCompactCount(999), '999');
    });

    test('drops the dead decimal at exact thresholds', () {
      // The bug this replaces rendered these as "1.0k" and "1.0M".
      expect(formatCompactCount(1000), '1k');
      expect(formatCompactCount(1000000), '1m');
    });

    test('keeps one decimal below ten of a unit', () {
      expect(formatCompactCount(1100), '1.1k');
      expect(formatCompactCount(9900), '9.9k');
      expect(formatCompactCount(1500000), '1.5m');
    });

    test('drops the decimal at ten of a unit and above', () {
      expect(formatCompactCount(10000), '10k');
      expect(formatCompactCount(12300), '12.3k');
      expect(formatCompactCount(123400), '123k');
      expect(formatCompactCount(999000), '999k');
    });

    test('truncates rather than rounding up across a threshold', () {
      // 999,999 must not round to "1000k" or "1m"; truncation keeps it at 999k.
      expect(formatCompactCount(999999), '999k');
      // 1,099 truncates to 1k, never rounds to 1.1k.
      expect(formatCompactCount(1099), '1k');
    });

    test('handles millions the same way it handles thousands', () {
      expect(formatCompactCount(10000000), '10m');
      expect(formatCompactCount(1234000000), '1234m');
    });

    test('never emits a negative or a minus sign', () {
      // Counts are cardinalities; a negative is a server bug, not a display
      // case. Clamp rather than render "-5".
      expect(formatCompactCount(-1), '0');
      expect(formatCompactCount(-1000000), '0');
    });
  });
}
