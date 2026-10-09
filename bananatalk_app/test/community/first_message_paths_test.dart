import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every path a user can send their FIRST message by must report it.
///
/// The spec asserted "message_provider.sendMessage is the central send path".
/// It is not: the only caller of MessageService.sendMessage in the whole app
/// is the Partners-tab wave button. The chat screen -- the journey the
/// first-session panel actually sends people down -- goes
/// ChatScreen -> ChatStateNotifier.sendMessage -> ChatSocketStateManager,
/// over the socket, never touching MessageService.
///
/// So `first_message_sent` fired for nobody who did what the panel asked, and
/// `first_conversation_done` was never written, leaving the panel to tell a
/// user who had already started a conversation to start one.
///
/// Source-level because the failure was structural: the code was correct, it
/// was simply bolted to a path users do not take. A behavioural test on
/// MessageService passes while the feature is dead. `session_reset_test.dart`
/// scans lib/ the same way and for the same reason.
void main() {
  /// Files that complete an outgoing first message, and why each counts.
  const sendPaths = <String, String>{
    'lib/providers/chat_state_provider.dart':
        'the chat screen: where Say hi actually leads',
    'lib/providers/provider_root/message_provider.dart':
        'the Partners-tab wave and explicit replies',
  };

  for (final entry in sendPaths.entries) {
    test('${entry.key} reports a first message (${entry.value})', () {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: '${entry.key} is missing');
      final source = file.readAsStringSync();
      expect(
        source.contains('reportFirstMessageIfFirst'),
        isTrue,
        reason:
            'This file completes a send a user could make first, but never '
            'reports it. first_message_sent is the one number the '
            'first-session panel is measured by.',
      );
    });
  }
}
