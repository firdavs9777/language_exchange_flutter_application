import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/chat/dialogs/forward_message_dialog.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';

ChatPartnerData _p(String id, String name, {String? username}) =>
    ChatPartnerData(id: id, name: name, username: username, images: const []);

void main() {
  group('forwardCandidates', () {
    final partners = [
      _p('a', 'Alice', username: 'alice'),
      _p('b', 'Bob'),
      _p('c', 'Carol'),
      _p('d', 'Dave'),
    ];

    test('lists every conversation partner except the current one', () {
      final result = forwardCandidates(
        partners,
        currentPartnerId: 'b',
        blockedIds: const {},
      );
      expect(result.map((p) => p.id), ['a', 'c', 'd']);
    });

    test('drops blocked users, the viewer and duplicate or empty ids', () {
      final result = forwardCandidates(
        [...partners, _p('a', 'Alice again'), _p('', 'Ghost'), _p('me', 'Me')],
        currentPartnerId: 'b',
        currentUserId: 'me',
        blockedIds: const {'c'},
      );
      expect(result.map((p) => p.id), ['a', 'd']);
    });

    test('filters by name or username, case-insensitively', () {
      expect(
        filterForwardCandidates(partners, 'ALI').map((p) => p.id),
        ['a'],
      );
      expect(
        filterForwardCandidates(partners, '  ').map((p) => p.id),
        ['a', 'b', 'c', 'd'],
      );
      expect(filterForwardCandidates(partners, 'zzz'), isEmpty);
    });
  });
}
