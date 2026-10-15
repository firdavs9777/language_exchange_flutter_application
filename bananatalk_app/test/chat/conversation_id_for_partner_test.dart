import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/services/conversation_service.dart';

Conversation _conv(String id, List<String> participantIds, {String? other}) =>
    Conversation.fromJson({
      '_id': id,
      'participants': [
        for (final p in participantIds) {'_id': p, 'name': p, 'images': []},
      ],
      if (other != null) 'otherParticipant': {'_id': other, 'name': other},
    });

void main() {
  test('finds the 1:1 conversation with the partner by participants', () {
    final convs = [
      _conv('c1', ['me', 'alice']),
      _conv('c2', ['me', 'bob']),
    ];
    expect(conversationIdWithUser(convs, 'bob'), 'c2');
  });

  test('prefers otherParticipant when the server sends it', () {
    final convs = [_conv('c3', const [], other: 'carol')];
    expect(conversationIdWithUser(convs, 'carol'), 'c3');
  });

  test('null when there is no conversation with that user', () {
    expect(conversationIdWithUser([_conv('c1', ['me', 'alice'])], 'bob'),
        isNull);
    expect(conversationIdWithUser(const [], 'bob'), isNull);
  });

  test('ignores group conversations that merely include the user', () {
    final convs = [
      _conv('g1', ['me', 'bob', 'dave']),
      _conv('c2', ['me', 'bob']),
    ];
    expect(conversationIdWithUser(convs, 'bob'), 'c2');
  });
}
