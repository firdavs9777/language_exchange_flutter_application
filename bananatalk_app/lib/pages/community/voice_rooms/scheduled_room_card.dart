import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class ScheduledRoomCard extends ConsumerStatefulWidget {
  final VoiceRoom room;
  final VoidCallback? onRsvpToggle;

  const ScheduledRoomCard({super.key, required this.room, this.onRsvpToggle});

  @override
  ConsumerState<ScheduledRoomCard> createState() => _ScheduledRoomCardState();
}

class _ScheduledRoomCardState extends ConsumerState<ScheduledRoomCard> {
  bool _isToggling = false;

  Future<void> _toggleRsvp() async {
    if (_isToggling) return;
    final myId = ref.read(authServiceProvider).userId;
    if (myId.isEmpty) return;
    final isRsvpd = widget.room.rsvpUserIds.contains(myId);
    setState(() => _isToggling = true);
    try {
      if (isRsvpd) {
        await ref.read(voiceRoomProvider).unrsvp(widget.room.id);
      } else {
        await ref.read(voiceRoomProvider).rsvp(widget.room.id);
      }
      widget.onRsvpToggle?.call();
    } catch (_) {
      // Silent fail; UI state untouched
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  String _countdown(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheduledFor = widget.room.scheduledFor;
    if (scheduledFor == null) return l10n.startsNow;
    final diff = scheduledFor.difference(DateTime.now());
    if (diff.isNegative) return l10n.startsNow;
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    if (h > 0) return l10n.inHours(h, m);
    return l10n.inMinutes(m);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final myId = ref.watch(authServiceProvider).userId;
    final isRsvpd = widget.room.rsvpUserIds.contains(myId);
    return Container(
      width: 240,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.room.title,
            style: context.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            widget.room.hostName,
            style: context.bodySmall.copyWith(color: context.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: context.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _countdown(context),
                  style: context.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.rsvpCount(widget.room.rsvpUserIds.length),
            style: context.captionSmall.copyWith(color: context.textMuted),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isToggling ? null : _toggleRsvp,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isRsvpd ? context.containerColor : AppColors.primary,
                foregroundColor:
                    isRsvpd ? context.textPrimary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(isRsvpd ? l10n.cantMakeIt : l10n.iWillBeThere),
            ),
          ),
        ],
      ),
    );
  }
}
