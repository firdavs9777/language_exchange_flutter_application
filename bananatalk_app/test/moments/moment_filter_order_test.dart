import 'package:bananatalk_app/pages/moments/filter/moment_filter_model.dart';
import 'package:bananatalk_app/pages/moments/filter/moment_filter_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/moment_fixture.dart';

void main() {
  test('filtering keeps the order the server ranked (no client re-sort)', () {
    // Server order: an older but higher-ranked post first.
    final ranked = [
      buildMoment(id: 'old-top', createdAt: DateTime(2026, 10, 1)),
      buildMoment(id: 'new', createdAt: DateTime(2026, 10, 16)),
      buildMoment(id: 'mid', createdAt: DateTime(2026, 10, 10)),
    ];
    // 'recent' is the default saved by older builds; it must not reorder.
    for (final sortBy in ['recent', 'popular', 'trending']) {
      final out = MomentFilterUtility.filterMoments(ranked, MomentFilter(sortBy: sortBy));
      expect(out.map((m) => m.id), ['old-top', 'new', 'mid'], reason: sortBy);
    }
  });
}
