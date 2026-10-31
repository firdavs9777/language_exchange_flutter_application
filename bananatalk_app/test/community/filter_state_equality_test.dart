import 'package:bananatalk_app/pages/community/filter/filter_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// FilterState had no `==`, so CommunityMain keyed every filter tab on an
/// identity hashCode: loading saved filters swapped in a new instance after
/// the first frame and every visible tab was disposed and rebuilt, loading
/// Partners twice (audit 2026-10-30).
void main() {
  test('equal values are equal with the same hashCode', () {
    const a = FilterState(gender: 'female', topics: ['music'], minAge: 20);
    final b = FilterState.fromJson(a.toJson());
    expect(b, a);
    expect(b.hashCode, a.hashCode);
  });

  test('different topics are not equal', () {
    const a = FilterState(topics: ['music']);
    const b = FilterState(topics: ['travel']);
    expect(a == b, isFalse);
  });
}
