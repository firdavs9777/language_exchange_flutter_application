import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/pages/chat/list/list_socket_handlers.dart';
import 'package:bananatalk_app/pages/chat/models/chat_partner.dart';

/// The chat list subscribes once, then every fetch swaps in a new list. The
/// handlers must update the list shown NOW, not the one from subscribe time.
void main() {
  late List<ChatPartner> shown;

  ListSocketContext ctx() => ListSocketContext(
        typingUsers: {},
        userStatuses: {},
        getChatPartners: () => shown,
        setChatPartners: (list) => shown = list,
        currentUserId: 'me',
        doSetState: (fn) => fn(),
        readProviderUnreadCount: (_) => 1,
        syncUnreadCounts: () {},
        processChatPartnersWithStatus: () {},
        getTypingTimer: () => null,
        setTypingTimer: (_) {},
      );

  Map<String, dynamic> incoming(String from, String text) => {
        'message': {
          'sender': {'_id': from, 'name': 'Name $from'},
          'receiver': 'me',
          'message': text,
          'createdAt': '2026-10-27T10:00:00.000Z',
        },
      };

  test('a message moves its row to the top of the list fetched later', () {
    shown = [];
    final context = ctx(); // subscribed while the list was still empty
    shown = [
      ChatPartner(id: 'a', name: 'A'),
      ChatPartner(id: 'b', name: 'B'),
    ]; // first fetch lands

    handleNewMessage(context, incoming('b', 'hi'));

    expect(shown.map((p) => p.id), ['b', 'a']);
    expect(shown.first.lastMessage, 'hi');
    expect(shown.first.unreadCount, 1);
  });

  test('a first message from someone new adds a row', () {
    shown = [ChatPartner(id: 'a', name: 'A')];
    handleNewMessage(ctx(), incoming('c', 'hello'));
    expect(shown.map((p) => p.id), ['c', 'a']);
  });

  test('my own send moves the receiver up', () {
    shown = [
      ChatPartner(id: 'a', name: 'A'),
      ChatPartner(id: 'b', name: 'B'),
    ];
    handleMessageSent(ctx(), {
      'message': {
        'sender': 'me',
        'receiver': {'_id': 'b', 'name': 'B'},
        'message': 'yo',
        'createdAt': '2026-10-27T10:00:00.000Z',
      },
    });
    expect(shown.map((p) => p.id), ['b', 'a']);
  });
}
