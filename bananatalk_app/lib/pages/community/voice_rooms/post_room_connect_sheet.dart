import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/pages/community/widgets/community_dialog_scaffold.dart';
import 'package:bananatalk_app/pages/community/widgets/send_wave_sheet.dart';
import 'package:bananatalk_app/pages/community/widgets/wave_button.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

/// Post-room "connect with who you talked to" prompt (Rooms optimization,
/// audit §6 Tier 2 #5).
///
/// Shown right after a user leaves a voice room, listing the OTHER
/// participants they were just talking with, each with a one-tap "wave"
/// action. Reuses the existing wave flow ([showSendWaveSheet] /
/// [WaveButton]) — no new endpoint, just a different entry point into it.
///
/// Caller is responsible for skipping this entirely when the participant
/// list is empty (user was alone in the room).
Future<void> showPostRoomConnectSheet(
  BuildContext context,
  List<RoomParticipant> participants,
) async {
  if (participants.isEmpty) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _PostRoomConnectSheet(participants: participants),
  );
}

class _PostRoomConnectSheet extends StatelessWidget {
  final List<RoomParticipant> participants;

  const _PostRoomConnectSheet({required this.participants});

  @override
  Widget build(BuildContext context) {
    return CommunityDialogScaffold(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Great chat! 🎉',
              style: context.titleMedium.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Stay in touch with the people you just talked to',
              style: context.bodyMedium.copyWith(color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...participants.map((p) => _ParticipantRow(participant: p)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Not now',
                  style: TextStyle(color: context.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final RoomParticipant participant;

  const _ParticipantRow({required this.participant});

  // Mirrors CommunityCardActions._alreadyWaved — presence of the shared
  // wave-cooldown key means "already waved," permanently (one wave per
  // user pair, ever). Kept local rather than imported since the original
  // is a private static on a different widget.
  static Future<bool> _alreadyWaved(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$waveCooldownPrefsPrefix$userId');
  }

  @override
  Widget build(BuildContext context) {
    if (participant.id.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipOval(
            child: participant.avatar.isNotEmpty
                ? CachedImageWidget(
                    imageUrl: participant.avatar,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    quality: ImageQuality.thumbnail,
                    highQuality: false,
                    errorWidget: _AvatarFallback(name: participant.name),
                  )
                : _AvatarFallback(name: participant.name),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              participant.name.isNotEmpty ? participant.name : 'Someone',
              style: context.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          FutureBuilder<bool>(
            future: _alreadyWaved(participant.id),
            builder: (context, snapshot) {
              final alreadyWaved = snapshot.data ?? false;
              return WaveButton(
                targetUserId: participant.id,
                targetUserName:
                    participant.name.isNotEmpty ? participant.name : 'this user',
                greyedOut: alreadyWaved,
                cooldownText: 'Already waved',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;

  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: const Color(0xFF00BFA5),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
