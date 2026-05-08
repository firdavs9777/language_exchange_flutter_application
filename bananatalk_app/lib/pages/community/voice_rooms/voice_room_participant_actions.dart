import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/pages/community/widgets/community_dialog_scaffold.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/pages/profile/profile_wrapper.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

Future<void> showParticipantActions(
  BuildContext context,
  WidgetRef ref,
  RoomParticipant participant,
) async {
  final l10n = AppLocalizations.of(context)!;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => CommunityDialogScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.voiceRoomViewProfile),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.push(
                context,
                AppPageRoute(
                  builder: (_) => ProfileWrapper(userId: participant.id),
                ),
              );
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.person_remove_rounded, color: Colors.red),
            title: Text(
              l10n.voiceRoomKick,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(sheetContext);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text(l10n.voiceRoomKickConfirm(participant.name)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(d, false),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(d, true),
                      child: Text(l10n.voiceRoomKick),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(voiceRoomProvider).kickParticipant(participant.id);
                if (context.mounted) {
                  showCommunitySnackBar(
                    context,
                    message: l10n.voiceRoomKicked,
                    type: CommunitySnackBarType.success,
                  );
                }
              }
            },
          ),
        ],
      ),
    ),
  );
}
