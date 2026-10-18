import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/chat/input/chat_input_bar.dart';
import 'package:bananatalk_app/pages/community/rooms/room_screen.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rooms get chat's photos, replies and reactions (2026-10-18).
Message _roomMessage(String id, {Map<String, dynamic>? replyTo}) => Message.fromJson({
      '_id': id,
      'conversationId': 'room1',
      'sender': {'_id': 'a', 'name': 'Mina', 'images': []},
      'message': 'hello $id',
      'createdAt': '2026-10-18T12:00:00.000Z',
      'messageType': 'text',
      'reactions': [],
      if (replyTo != null) 'replyTo': replyTo,
    });

void main() {
  test('a room reaction event updates only that message', () {
    final messages = [_roomMessage('m1'), _roomMessage('m2')];
    final next = applyReactionUpdate(messages, {
      'messageId': 'm2',
      'reactions': [
        {'user': {'_id': 'b', 'name': 'Jun', 'images': []}, 'emoji': '❤️'},
      ],
    });
    expect(next, isNotNull);
    expect(next![0].reactions, isEmpty);
    expect(next[1].reactions.single.emoji, '❤️');
    expect(applyReactionUpdate(messages, {'messageId': 'other', 'reactions': []}), isNull);
  });

  test('a room message with a quoted reply parses the quote', () {
    final m = _roomMessage('m3', replyTo: {
      '_id': 'm1',
      'message': 'hello m1',
      'sender': {'_id': 'a', 'name': 'Mina'},
    });
    expect(m.replyTo?.message, 'hello m1');
    expect(m.replyTo?.sender.name, 'Mina');
  });

  testWidgets('the room composer offers camera, gallery and GIF, not location', (t) async {
    final options = <String>[];
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChatInputBar(
            messageController: TextEditingController(),
            isSending: false,
            showMediaPanel: false,
            showStickerPanel: false,
            onSendMessage: ({messageText, messageType}) {},
            onToggleMediaPanel: () {},
            onToggleStickerPanel: () {},
            onTogglePhrasesPanel: () {},
            onTyping: () {},
            onStopTyping: () {},
            onHidePanels: () {},
            roomTools: true,
            onMediaOption: options.add,
          ),
        ),
      ),
    ));
    await t.pump();
    expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
    expect(find.byIcon(Icons.place_rounded), findsNothing);
    await t.tap(find.byIcon(Icons.photo_camera_rounded));
    await t.tap(find.byIcon(Icons.photo_library_rounded));
    await t.tap(find.byIcon(Icons.gif_box_rounded));
    expect(options, ['camera', 'gallery', 'gif']);
  });
}
