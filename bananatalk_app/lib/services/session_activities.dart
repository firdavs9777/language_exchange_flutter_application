import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bananatalk_app/services/call_manager.dart';
import 'package:bananatalk_app/services/upload_queue_service.dart';
import 'package:bananatalk_app/services/voice_room_manager.dart';

/// Ends everything the signed-out account still has running on this device.
///
/// Wired by main() into `AuthService.onSessionEnding`, which runs at the
/// start of every local session teardown (logout, account deletion,
/// suspension, session expiry) -- BEFORE the tokens are cleared, so the
/// "end call" / "leave room" requests still carry the account's own token.
///
///  - Uploads: abandoned at their next step and dropped from the queue
///    ([UploadQueueService.endSession]).
///  - 1:1 call (ringing or connected): ended, so the peer is not left talking
///    to a signed-out device and CallKit is cleared.
///  - Voice room: left (LiveKit disconnect + server leave).
///
/// Never throws: a logout must always complete.
Future<void> endSessionActivities() async {
  try {
    await UploadQueueService().endSession();
  } catch (e) {
    debugPrint('[session-end] uploads: $e');
  }
  try {
    final calls = CallManager();
    if (calls.currentCall != null) await calls.endCall();
  } catch (e) {
    debugPrint('[session-end] call: $e');
  }
  try {
    final rooms = VoiceRoomManager();
    if (rooms.isInRoom) {
      await rooms.leaveRoom().timeout(const Duration(seconds: 5));
    }
  } catch (e) {
    debugPrint('[session-end] voice room: $e');
  }
}
