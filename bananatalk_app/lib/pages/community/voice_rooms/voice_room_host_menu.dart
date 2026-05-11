import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';

/// Shows a bottom sheet with host-only actions (mute-all, end room, …).
Future<void> showHostMenu(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.mic_off, color: Colors.orange),
              title: Text(l10n.muteAll),
              onTap: () async {
                Navigator.pop(sheetContext);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(l10n.muteAllConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: Text(l10n.cancel),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(d, true),
                        child: Text(l10n.muteAll),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(voiceRoomProvider).muteAll();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_rounded, color: Colors.red),
              title: Text(
                l10n.voiceRoomEnd,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                showEndRoomConfirm(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

Future<void> showEndRoomConfirm(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final rootMessenger = ScaffoldMessenger.maybeOf(context);

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (statefulCtx, setLocalState) {
          bool ending = false;

          Future<void> handleEnd() async {
            setLocalState(() => ending = true);
            final ok = await ref.read(voiceRoomProvider).endRoom();
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext);
            if (ok) {
              // Pop the room screen too. The provider's onRoomEnded path
              // already clears state; this just dismisses the screen.
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.pop(context);
              }
            } else {
              rootMessenger?.showSnackBar(
                SnackBar(
                  content: Text(l10n.voiceRoomEndFailed),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.voiceRoomEndConfirm),
            content: Text(l10n.voiceRoomEndConfirmBody),
            actions: [
              TextButton(
                onPressed: ending ? null : () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: ending ? null : handleEnd,
                child: ending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(l10n.voiceRoomEnd),
              ),
            ],
          );
        },
      );
    },
  );
}
