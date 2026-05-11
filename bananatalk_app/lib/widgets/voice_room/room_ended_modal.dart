// lib/widgets/voice_room/room_ended_modal.dart

import 'package:flutter/material.dart';

/// Shows a non-dismissible "ended" modal with an OK button.
///
/// Used by voice rooms when the host ends ("Room ended by host"), by
/// 1:1 calls when either peer hangs up ("Call ended"), and by the kick
/// flow ("Removed by host"). The dialog is intentionally explicit —
/// users should acknowledge the end of session before the screen pops.
Future<void> showRoomEndedModal(
  BuildContext context, {
  required String reason,
  String? subtitle,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(reason),
      content: subtitle != null ? Text(subtitle) : null,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
