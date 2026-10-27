import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/community/widgets/visitor_recall_card.dart';

void main() {
  test('free account: visible + locked visitors (live: 1 + 9)', () {
    expect(visitorTotal({'count': 1, 'locked': 9}, shown: 1), 10);
  });

  test('VIP / no locked field: just the count', () {
    expect(visitorTotal({'count': 4}, shown: 4), 4);
  });

  test('no count field: the rows shown', () {
    expect(visitorTotal({}, shown: 2), 2);
  });
}
