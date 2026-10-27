import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bananatalk_app/providers/chat_state_provider.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/chat_socket_state_manager.dart';

/// Edits keep the reply quote (C8), failed bubbles survive a reload (C9),
/// and a timed-out send the server did store replaces its failed bubble
/// instead of sitting next to it (C6). Harness copied from
/// chat_reconnect_sync_test.dart.
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

  test('an edit keeps the reply quote and the populated sender', () {
    final quoted = MessageReply(id: 'q', message: 'quoted', sender: _user(_me));
    final current = _msg('a', 'old', minute: 1).copyWith(replyTo: quoted);
    final editedEvent = Message(
      id: 'a',
      sender: _user(''), // the event carries a bare id
      receiver: _user(''),
      message: 'new',
      createdAt: current.createdAt,
      version: 0,
      read: false,
      type: 'text',
      editedAt: '2026-01-01T11:00:00.000Z',
    );
    final merged = applyEdit(current, editedEvent);
    expect(merged.message, 'new');
    expect(merged.isEdited, isTrue);
    expect(merged.replyTo?.id, 'q');
    expect(merged.sender.id, _partner);
  });

  test('a failed bubble survives a reload of the conversation', () async {
    final h = _Harness();
    await h.init();
    h.notifier.setMessages([_msg('a', 'hi', minute: 1)]);
    final localId = h.notifier.addOptimisticMessage(
      message: 'nope',
      currentUserId: _me,
      receiverId: _partner,
    );
    h.notifier.updateOptimisticMessage(localId, failed: true);

    h.notifier.setMessages([_msg('a', 'hi', minute: 1), _msg('b', 'yo', minute: 2)]);

    final failed = h.notifier.state.messages.where((m) => m.isFailed).toList();
    expect(failed, hasLength(1));
    expect(failed.single.localId, localId);
  });

  test('the echo of a timed-out send replaces its failed bubble', () async {
    final h = _Harness();
    await h.init();
    final localId = h.notifier.addOptimisticMessage(
      message: 'are you there?',
      currentUserId: _me,
      receiverId: _partner,
    );
    h.notifier.updateOptimisticMessage(localId, failed: true);
    final optimisticAt = h.notifier.state.messages.single.createdAt;

    final echo = Message(
      id: 'srv1',
      sender: _user(_me),
      receiver: _user(_partner),
      message: 'are you there?',
      createdAt: optimisticAt,
      version: 0,
      read: false,
      type: 'text',
    );
    h.manager.onNewMessage!(echo);

    final messages = h.notifier.state.messages;
    expect(messages, hasLength(1), reason: 'no duplicate next to the failed one');
    expect(messages.single.id, 'srv1');
    expect(messages.single.isFailed, isFalse);
  });

  test("the partner's identical text is not taken for my echo", () async {
    final h = _Harness();
    await h.init();
    final localId = h.notifier.addOptimisticMessage(
      message: 'ok',
      currentUserId: _me,
      receiverId: _partner,
    );
    h.notifier.updateOptimisticMessage(localId, failed: true);
    h.manager.onNewMessage!(_msg('p1', 'ok', minute: 1));
    expect(h.notifier.state.messages.where((m) => m.isFailed), hasLength(1));
    expect(h.notifier.state.messages, hasLength(2));
  });
}
