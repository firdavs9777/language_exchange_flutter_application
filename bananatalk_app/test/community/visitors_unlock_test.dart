import 'package:bananatalk_app/pages/profile/visitors_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// The 60-coin visitors unlock lasts 24h; the screen says how long is left.
void main() {
  test('time left on a coin unlock; none once it ended', () {
    final now = DateTime(2026, 10, 18, 12);
    expect(visitorsUnlockLeft(null, now: now), isNull);
    expect(visitorsUnlockLeft(now.add(const Duration(hours: 23, minutes: 12)), now: now),
        const Duration(hours: 23, minutes: 12));
    expect(visitorsUnlockLeft(now.subtract(const Duration(minutes: 1)), now: now), isNull);
  });
}
