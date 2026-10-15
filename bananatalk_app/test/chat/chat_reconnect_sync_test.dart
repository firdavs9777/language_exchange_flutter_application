import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/chat_state_provider.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/chat_socket_state_manager.dart';

/// The socket server does not replay messages that were stored while a
/// client's socket was down. An open conversation therefore has to re-read
/// the latest page itself when the socket comes back (or the app resumes),
/// or those messages only appear after leaving and reopening the chat.
const _me = 'me';
const _partner = 'partner';

Community _user(String id) => Community(
      id: id,
      name: id,
      email: '',
      bio: '',
      mbti: '',
      bloodType: '',
      images: const [],
      imageUrls: const [],
      birth_day: '',
      birth_month: '',
      birth_year: '',
      gender: '',
      native_language: '',
      language_to_learn: '',
      followers: const [],
      followings: const [],
      createdAt: '',
      version: 0,
      location: Location.defaultLocation(),
    );

Message _msg(
  String id,
  String text, {
  String from = _partner,
  required int minute,
  String type = 'text',
}) =>
    Message(
      id: id,
      sender: _user(from),
      receiver: _user(from == _me ? _partner : _me),
      message: text,
      createdAt: DateTime.utc(2026, 1, 1, 10, minute).toIso8601String(),
      version: 0,
      read: false,
      type: type,
    );

class _FakeStateManager extends ChatSocketStateManager {
  _FakeStateManager() : super(chatPartnerId: _partner, currentUserId: _me);

  bool connected = true;
  int markAsReadCalls = 0;
  Map<String, dynamic> nextSendResult = {'status': 'error', 'error': 'x'};

  @override
  Future<void> initialize() async {}

  @override
  bool get isConnected => connected;

  @override
  void requestUserStatus() {}

  @override
  void markAsRead() => markAsReadCalls++;

  @override
  void sendTyping(bool isTyping) {}

  @override
  Future<Map<String, dynamic>> sendMessage(
    String message, {
    String? messageType,
  }) async =>
      nextSendResult;

  @override
  void dispose() {}
}

class _Harness {
  _Harness({this.active = true});

  bool active;
  final manager = _FakeStateManager();
  List<Message> serverPage = [];
  int fetches = 0;
  Completer<void>? gate;

  late final ChatStateNotifier notifier = ChatStateNotifier(
    chatPartnerId: _partner,
    currentUserId: _me,
    stateManagerFactory: () => manager,
    fetchLatestMessages: () async {
      fetches++;
      if (gate != null) await gate!.future;
      return List<Message>.from(serverPage);
    },
    isActiveChat: () => active,
  );

  Future<void> init() => notifier.initialize();

  void reconnect() => manager.onConnectionChanged!(true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reconnect fetches the latest page and merges it without duplicates',
      () async {
    final h = _Harness();
    await h.init();
    h.notifier.setMessages([
      _msg('a', 'hi', minute: 1),
      _msg('b', 'hello', from: _me, minute: 2),
    ]);
    final localId = h.notifier.addOptimisticMessage(
      message: 'still sending',
      currentUserId: _me,
      receiverId: _partner,
    );

    // While the socket was down the partner sent two messages.
    h.serverPage = [
      _msg('a', 'hi', minute: 1),
      _msg('b', 'hello', from: _me, minute: 2),
      _msg('c', 'are you there?', minute: 3),
      _msg('d', 'ping', minute: 4),
    ];

    h.reconnect();
    await pumpEventQueue();

    expect(h.fetches, 1);
    final ids = h.notifier.state.messages.map((m) => m.id).toList();
    expect(ids.where((id) => id == 'a').length, 1);
    expect(ids.where((id) => id == 'b').length, 1);
    expect(ids, containsAllInOrder(['a', 'b', 'c', 'd']));
    // The pending local message survives the merge, still sending, last.
    final pending = h.notifier.state.messages.last;
    expect(pending.localId, localId);
    expect(pending.sendingStatus, MessageSendingStatus.sending);
  });

  test('a failed local message is left alone by the merge', () async {
    final h = _Harness();
    await h.init();
    h.notifier.setMessages([_msg('a', 'hi', minute: 1)]);
    final localId = h.notifier.addOptimisticMessage(
      message: 'nope',
      currentUserId: _me,
      receiverId: _partner,
    );
    h.notifier.updateOptimisticMessage(localId, failed: true);
    h.serverPage = [_msg('a', 'hi', minute: 1), _msg('c', 'new', minute: 3)];

    h.reconnect();
    await pumpEventQueue();

    final failed =
        h.notifier.state.messages.where((m) => m.localId == localId).toList();
    expect(failed, hasLength(1));
    expect(failed.single.sendingStatus, MessageSendingStatus.failed);
    expect(h.notifier.state.messages.map((m) => m.id), contains('c'));
  });

  test('a pending message the server already stored is not shown twice',
      () async {
    final h = _Harness();
    await h.init();
    h.notifier.setMessages([_msg('a', 'hi', minute: 1)]);
    final localId = h.notifier.addOptimisticMessage(
      message: 'on its way',
      currentUserId: _me,
      receiverId: _partner,
    );
    final stored = _msg('srv1', 'on its way', from: _me, minute: 5);
    h.serverPage = [_msg('a', 'hi', minute: 1), stored];

    h.reconnect();
    await pumpEventQueue();

    expect(
      h.notifier.state.messages.where((m) => m.message == 'on its way'),
      hasLength(1),
    );

    // The late ack for the same send must not add a second copy either.
    h.notifier.updateOptimisticMessage(localId, confirmedMessage: stored);
    expect(
      h.notifier.state.messages.where((m) => m.id == 'srv1'),
      hasLength(1),
    );
  });

  test('a confirmed ack never duplicates a copy the socket already added',
      () async {
    final h = _Harness();
    await h.init();
    final localId = h.notifier.addOptimisticMessage(
      message: 'yo',
      currentUserId: _me,
      receiverId: _partner,
    );
    final stored = _msg('srv2', 'yo', from: _me, minute: 6);
    h.manager.onNewMessage!(stored); // multi-device echo beats the ack

    h.notifier.updateOptimisticMessage(localId, confirmedMessage: stored);

    expect(h.notifier.state.messages, hasLength(1));
    expect(h.notifier.state.messages.single.id, 'srv2');
  });

  test('only the active chat refetches, and only after the first load',
      () async {
    final h = _Harness(active: false);
    await h.init();
    h.notifier.setMessages([_msg('a', 'hi', minute: 1)]);
    h.reconnect();
    await pumpEventQueue();
    expect(h.fetches, 0, reason: 'a background chat must not hit the API');

    final fresh = _Harness();
    await fresh.init();
    fresh.reconnect(); // the screen's own initial load covers this one
    await pumpEventQueue();
    expect(fresh.fetches, 0);
  });

  test('reconnect events while a fetch is in flight share one request',
      () async {
    final h = _Harness();
    await h.init();
    h.notifier.setMessages([_msg('a', 'hi', minute: 1)]);
    h.gate = Completer<void>();

    h.reconnect();
    h.reconnect();
    h.reconnect();
    await pumpEventQueue();
    expect(h.fetches, 1);

    h.gate!.complete();
    await pumpEventQueue();
  });

  test('resuming with the socket still up also refetches', () async {
    final h = _Harness();
    await h.init();
    h.notifier.setMessages([_msg('a', 'hi', minute: 1)]);
    h.serverPage = [_msg('a', 'hi', minute: 1), _msg('z', 'late', minute: 9)];

    h.notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
    h.notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();

    expect(h.fetches, 1);
    expect(h.notifier.state.messages.map((m) => m.id), contains('z'));
  });

  test('a failed fetch leaves the conversation as it was', () async {
    final manager = _FakeStateManager();
    final notifier = ChatStateNotifier(
      chatPartnerId: _partner,
      currentUserId: _me,
      stateManagerFactory: () => manager,
      fetchLatestMessages: () async => throw Exception('offline'),
      isActiveChat: () => true,
    );
    await notifier.initialize();
    notifier.setMessages([_msg('a', 'hi', minute: 1)]);

    manager.onConnectionChanged!(true);
    await pumpEventQueue();

    expect(notifier.state.messages.map((m) => m.id), ['a']);
    expect(notifier.state.error, isEmpty);
  });

  group('retry', () {
    test('resends the same failed bubble instead of adding a new one',
        () async {
      final h = _Harness();
      await h.init();
      final localId = h.notifier.addOptimisticMessage(
        message: '🙂',
        currentUserId: _me,
        receiverId: _partner,
        type: 'sticker',
      );
      await h.notifier.sendMessage('🙂', localId: localId, messageType: 'sticker');
      expect(h.notifier.state.messages.single.isFailed, isTrue);

      expect(h.notifier.prepareRetry(localId), isTrue);
      expect(h.notifier.state.messages, hasLength(1));
      expect(
        h.notifier.state.messages.single.sendingStatus,
        MessageSendingStatus.sending,
      );

      h.manager.nextSendResult = {
        'status': 'success',
        'message': {
          '_id': 'srv3',
          'sender': {'_id': _me},
          'receiver': {'_id': _partner},
          'message': '🙂',
          'messageType': 'sticker',
          'createdAt': DateTime.utc(2026, 1, 1, 11).toIso8601String(),
        },
      };
      await h.notifier.sendMessage('🙂', localId: localId, messageType: 'sticker');

      expect(h.notifier.state.messages, hasLength(1));
      expect(h.notifier.state.messages.single.id, 'srv3');
      expect(h.notifier.state.messages.single.type, 'sticker');
    });

    test('refuses to retry a bubble that is not failed', () async {
      final h = _Harness();
      await h.init();
      final localId = h.notifier.addOptimisticMessage(
        message: 'x',
        currentUserId: _me,
        receiverId: _partner,
      );
      expect(h.notifier.prepareRetry(localId), isFalse);
      expect(h.notifier.prepareRetry('missing'), isFalse);
    });
  });
}
