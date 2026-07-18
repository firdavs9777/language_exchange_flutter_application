import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/chat/message/tick_status.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

Message _m({bool delivered = false, bool read = false}) => Message.fromJson({
      '_id': '1',
      'sender': {'_id': 'a', 'name': 'U', 'images': []},
      'receiver': {'_id': 'b', 'name': 'O', 'images': []},
      'message': 'hi',
      'createdAt': '2026-07-18T09:00:00.000Z',
      'type': 'text',
      'read': read,
      'delivered': delivered,
      'reactions': [],
      'translations': [],
      'corrections': [],
      'mentions': [],
    });

void main() {
  test('sent when neither delivered nor read', () {
    expect(tickRoleFor(_m()), TickRole.sent);
  });
  test('delivered when delivered but not read', () {
    expect(tickRoleFor(_m(delivered: true)), TickRole.delivered);
  });
  test('read wins over delivered', () {
    expect(tickRoleFor(_m(delivered: true, read: true)), TickRole.read);
  });
  test('read even if delivered flag missing', () {
    expect(tickRoleFor(_m(read: true)), TickRole.read);
  });
}
