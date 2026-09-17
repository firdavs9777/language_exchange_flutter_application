import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/widgets/block_user_action.dart';

void main() {
  group('canBlockUser', () {
    test('a normal other user can be blocked', () {
      expect(canBlockUser(viewerId: 'a', targetUserId: 'b'), isTrue);
    });

    test('you cannot block yourself', () {
      expect(canBlockUser(viewerId: 'a', targetUserId: 'a'), isFalse);
    });

    test('an unknown viewer cannot block', () {
      // BlockUserDialog needs the viewer's id; offering an entry that cannot
      // complete is worse than not offering it.
      expect(canBlockUser(viewerId: '', targetUserId: 'b'), isFalse);
    });

    test('an unknown target cannot be blocked', () {
      expect(canBlockUser(viewerId: 'a', targetUserId: ''), isFalse);
    });
  });
}
