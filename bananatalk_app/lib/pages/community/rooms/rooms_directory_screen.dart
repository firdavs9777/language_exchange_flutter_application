import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/pages/community/rooms/create_topic_room_sheet.dart';
import 'package:bananatalk_app/pages/community/rooms/room_card.dart';
import 'package:bananatalk_app/pages/community/rooms/room_screen.dart';
import 'package:bananatalk_app/pages/community/widgets/community_empty_state.dart';
import 'package:bananatalk_app/pages/community/widgets/community_error_state.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/rooms_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/community/user_skeleton.dart';

/// Directory of public Language Rooms ("hubs") plus user-created topic
/// rooms nested under them — Workstream D.
///
/// Lists every hub with member/online counts; the caller's auto-joined hub
/// is pinned first (backend already orders it that way; the provider
/// defensively re-pins client-side too). Rooms are then grouped by
/// `targetLanguage` — each language section shows its seeded hub first,
/// followed by any user-created topic rooms for that language. Tapping any
/// room opens the real `RoomScreen` (Task 10). The "＋ New room" FAB opens
/// `showCreateTopicRoomSheet` to create a topic room, then refreshes the
/// directory and jumps straight into the new room.
class RoomsDirectoryScreen extends ConsumerWidget {
  const RoomsDirectoryScreen({super.key});

  Future<void> _createTopicRoom(BuildContext context, WidgetRef ref) async {
    // Best-effort: prefill the language picker with the caller's learning
    // language so most people don't have to touch the dropdown at all.
    // Falls back to the sheet's own default when the profile hasn't loaded
    // yet or has no learning language set.
    final me = ref.read(userProvider).valueOrNull;
    final presetLanguage =
        (me != null && me.language_to_learn.isNotEmpty)
            ? me.language_to_learn
            : null;

    final room = await showCreateTopicRoomSheet(
      context,
      presetLanguage: presetLanguage,
    );
    if (room == null) return;

    await ref.read(roomsProvider.notifier).refresh();
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RoomScreen(room: room)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'rooms-directory-fab',
        onPressed: () => _createTopicRoom(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New room'),
      ),
      body: roomsAsync.when(
        loading: () => const UserListSkeleton(count: 6),
        error: (error, _) => CommunityErrorState(
          message: 'Could not load rooms',
          onRetry: () => ref.read(roomsProvider.notifier).refresh(),
          retryLabel: 'Try again',
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
            return const CommunityEmptyState(
              icon: Icons.forum_outlined,
              title: 'No language rooms yet',
              subtitle: 'Check back soon — hubs are being set up.',
            );
          }
          return _RoomsList(rooms: rooms);
        },
      ),
    );
  }
}

/// A `targetLanguage` section: its hub(s) first, then user-created topic
/// rooms for that language, in the order they first appeared in the
/// (already pinned-first) flat room list.
class _LanguageSection {
  const _LanguageSection({required this.language, required this.rooms});

  final String language;
  final List<Room> rooms;
}

/// Groups [rooms] by `targetLanguage`, preserving first-seen order per
/// language (so the section containing the caller's pinned hub stays
/// first) and putting hubs before topic rooms within each section.
List<_LanguageSection> _groupByLanguage(List<Room> rooms) {
  final order = <String>[];
  final byLanguage = <String, List<Room>>{};
  for (final room in rooms) {
    final language = room.targetLanguage.isEmpty ? 'Other' : room.targetLanguage;
    final bucket = byLanguage.putIfAbsent(language, () {
      order.add(language);
      return [];
    });
    bucket.add(room);
  }
  return order.map((language) {
    final bucket = byLanguage[language]!;
    final hubs = bucket.where((r) => !r.isTopicRoom).toList();
    final topics = bucket.where((r) => r.isTopicRoom).toList();
    return _LanguageSection(language: language, rooms: [...hubs, ...topics]);
  }).toList();
}

class _RoomsList extends ConsumerWidget {
  const _RoomsList({required this.rooms});

  final List<Room> rooms;

  Future<void> _refresh(WidgetRef ref) => ref.read(roomsProvider.notifier).refresh();

  void _openRoom(BuildContext context, Room room) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoomScreen(room: room)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = _groupByLanguage(rooms);

    // Flatten sections into a single item list (language header or Room) so
    // the existing staggered fade/slide-in animation keeps working per row.
    final items = <Object>[];
    for (final section in sections) {
      items.add(section.language);
      items.addAll(section.rooms);
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          Spacing.md,
          Spacing.md,
          Spacing.md,
          80, // keep the last card clear of the FAB
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final delay = Duration(milliseconds: (index * 40).clamp(0, 400));

          if (item is String) {
            return Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 0 : Spacing.md,
                bottom: Spacing.sm,
                left: 4,
              ),
              child: Text(
                item,
                style: context.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: delay);
          }

          final room = item as Room;
          return Padding(
                padding: EdgeInsets.only(
                  left: room.isTopicRoom ? Spacing.md : 0,
                  bottom: Spacing.sm,
                ),
                child: RoomCard(
                  room: room,
                  isPinned: room.isMember,
                  onTap: () => _openRoom(context, room),
                ),
              )
              .animate()
              .fadeIn(duration: 300.ms, delay: delay)
              .slideY(
                begin: 0.05,
                end: 0,
                duration: 300.ms,
                delay: delay,
                curve: Curves.easeOutCubic,
              );
        },
      ),
    );
  }
}
