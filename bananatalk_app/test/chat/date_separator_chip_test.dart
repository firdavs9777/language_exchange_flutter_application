import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/chat/message/date_separator_chip.dart';

void main() {
  final now = DateTime(2026, 7, 18, 15, 0);
  test('today', () {
    expect(dateSeparatorLabel(DateTime(2026, 7, 18), now), 'Today');
  });
  test('yesterday', () {
    expect(dateSeparatorLabel(DateTime(2026, 7, 17), now), 'Yesterday');
  });
  test('within last week -> weekday', () {
    expect(dateSeparatorLabel(DateTime(2026, 7, 14), now), 'Tuesday');
  });
  test('this year older -> MMM d', () {
    expect(dateSeparatorLabel(DateTime(2026, 3, 2), now), 'Mar 2');
  });
  test('other year -> MMM d, yyyy', () {
    expect(dateSeparatorLabel(DateTime(2025, 3, 2), now), 'Mar 2, 2025');
  });
}
