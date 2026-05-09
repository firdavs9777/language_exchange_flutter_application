import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/voice_room_model.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/scheduled_room_card.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class UpcomingSection extends StatelessWidget {
  final List<VoiceRoom> rooms;
  final VoidCallback? onRsvpToggle;

  const UpcomingSection({super.key, required this.rooms, this.onRsvpToggle});

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(l10n.upcomingRooms, style: context.titleMedium),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: rooms.length,
            itemBuilder: (_, i) => ScheduledRoomCard(
              room: rooms[i],
              onRsvpToggle: onRsvpToggle,
            ),
          ),
        ),
      ],
    );
  }
}
