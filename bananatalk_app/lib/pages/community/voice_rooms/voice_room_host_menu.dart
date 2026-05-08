import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';

Future<void> showEndRoomConfirm(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.voiceRoomEndConfirm),
      content: Text(l10n.voiceRoomEndConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            ref.read(voiceRoomProvider).endRoom();
            Navigator.pop(dialogContext);
            if (Navigator.of(context).canPop()) Navigator.pop(context);
          },
          child: Text(l10n.voiceRoomEnd),
        ),
      ],
    ),
  );
}
