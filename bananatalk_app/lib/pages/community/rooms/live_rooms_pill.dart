import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/active_voice_room_count_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown at the top of the Rooms tab (it was in the Community app bar, where
/// it polled `/voicerooms` every 30 s on every Community tab).
/// "🔴 N live" pill fed by [activeVoiceRoomCountProvider]. Hidden entirely
/// while the count is loading, errored, or zero — a live-room pull is only
/// worth the app-bar real estate once there's actually something to join.
class LiveRoomsPill extends ConsumerWidget {
  const LiveRoomsPill({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(activeVoiceRoomCountProvider);
    final count = countAsync.asData?.value ?? 0;
    if (countAsync.isLoading || countAsync.hasError || count == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
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
                  AppLocalizations.of(context)!.communityLive(count),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
