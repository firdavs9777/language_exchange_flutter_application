import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/active_voice_room_count_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The way into voice rooms, at the top of the Rooms tab. ALWAYS shown.
///
/// It replaced a "🔴 N live" pill that hid itself whenever nothing was live.
/// Creating a room lives inside the voice rooms screen, so with zero live
/// rooms nobody could get in to start one, and zero is the usual state: voice
/// rooms became unreachable. The live count still shows here, as a badge, once
/// there is something to join.
///
/// Fed by [activeVoiceRoomCountProvider], which is only watched while the
/// Rooms tab is open (it used to poll `/voicerooms` on every Community tab).
class VoiceRoomsEntry extends ConsumerWidget {
  const VoiceRoomsEntry({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Loading or errored reads as "nothing live": the row itself never waits
    // on the count, only the badge does.
    final count = ref.watch(activeVoiceRoomCountProvider).valueOrNull ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Material(
        color: context.containerHighColor,
        borderRadius: AppRadius.borderMD,
        child: InkWell(
          key: const Key('voice-rooms-entry'),
          onTap: onTap,
          borderRadius: AppRadius.borderMD,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.mic_rounded, color: context.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.voiceRooms,
                        style: context.titleSmall,
                      ),
                      Text(
                        l10n.voiceRoomsDescription,
                        style: context.bodyMedium.copyWith(
                          color: context.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  _LiveBadge(label: l10n.communityLive(count)),
                ],
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: context.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('voice-rooms-live-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
