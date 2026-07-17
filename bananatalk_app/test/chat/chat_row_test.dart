// test/chat/chat_row_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/pages/chat/message/chat_row.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

Message _msg(String id, String senderId, String iso, {String type = 'text'}) =>
    Message.fromJson({
      '_id': id,
      'sender': {'_id': senderId, 'name': 'U', 'images': []},
      'receiver': {'_id': 'other', 'name': 'O', 'images': []},
      'message': 'hi',
      'createdAt': iso,
      'type': type,
      'read': false,
      'reactions': [],
      'translations': [],
      'corrections': [],
      'mentions': [],
    });

void main() {
  test('one separator for a single-day conversation', () {
    final rows = buildChatRows([
      _msg('1', 'a', '2026-07-18T09:00:00.000Z'),
      _msg('2', 'a', '2026-07-18T09:01:00.000Z'),
    ]);
    expect(rows.whereType<DateSeparatorRow>().length, 1);
    expect(rows.length, 3); // sep + 2 messages
  });

  test('separator inserted at each day boundary and grouping resets', () {
    final rows = buildChatRows([
      _msg('1', 'a', '2026-07-17T09:00:00.000Z'),
      _msg('2', 'a', '2026-07-18T09:00:00.000Z'),
    ]);
    expect(rows.whereType<DateSeparatorRow>().length, 2);
    final firstMsgAfterBreak =
        rows.whereType<MessageRow>().firstWhere((r) => r.message.id == '2');
    expect(firstMsgAfterBreak.isFirstInGroup, true);
  });

  test('same author within 3 minutes groups (middle msg not first/last)', () {
    final rows = buildChatRows([
      _msg('1', 'a', '2026-07-18T09:00:00.000Z'),
      _msg('2', 'a', '2026-07-18T09:01:00.000Z'),
      _msg('3', 'a', '2026-07-18T09:02:00.000Z'),
    ]);
    final middle =
        rows.whereType<MessageRow>().firstWhere((r) => r.message.id == '2');
    expect(middle.isFirstInGroup, false);
    expect(middle.isLastInGroup, false);
  });

  test('empty input yields no rows', () {
    expect(buildChatRows(const []), isEmpty);
  });
}
