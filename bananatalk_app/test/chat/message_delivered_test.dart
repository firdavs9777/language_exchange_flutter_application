import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

Map<String, dynamic> _base(Map<String, dynamic> extra) => {
      'id': '1',
      'sender': {'_id': 'a', 'name': 'U', 'images': []},
      'receiver': {'_id': 'b', 'name': 'O', 'images': []},
      'message': 'hi',
      'createdAt': '2026-07-18T09:00:00.000Z',
      'type': 'text',
      'read': false,
      'reactions': [],
      'translations': [],
      'corrections': [],
      'mentions': [],
      ...extra,
    };

void main() {
  test('delivered defaults false when absent', () {
    expect(Message.fromJson(_base({})).delivered, false);
  });
  test('delivered parses true', () {
    expect(Message.fromJson(_base({'delivered': true})).delivered, true);
  });
  test('copyWith updates delivered', () {
    final m = Message.fromJson(_base({}));
    expect(m.copyWith(delivered: true).delivered, true);
  });
  test('toJson round-trips delivered', () {
    final m = Message.fromJson(_base({'delivered': true}));
    expect(Message.fromJson(m.toJson()).delivered, true);
  });
}
