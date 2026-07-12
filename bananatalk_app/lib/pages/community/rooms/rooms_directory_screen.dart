import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/pages/community/rooms/room_card.dart';
import 'package:bananatalk_app/pages/community/widgets/community_empty_state.dart';
import 'package:bananatalk_app/pages/community/widgets/community_error_state.dart';
import 'package:bananatalk_app/providers/rooms_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/community/user_skeleton.dart';

/// Directory of public Language Rooms ("hubs") — Workstream D.
///
/// Lists every hub with member/online counts; the caller's auto-joined hub
/// is pinned first (backend already orders it that way; the provider
/// defensively re-pins client-side too). Tapping a hub opens the room chat
/// screen — Task 10 builds the real `RoomScreen`; for now this navigates to
/// a minimal placeholder so the directory is fully clickable end to end.
class RoomsDirectoryScreen extends ConsumerWidget {
  const RoomsDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
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

class _RoomsList extends ConsumerWidget {
  const _RoomsList({required this.rooms});

  final List<Room> rooms;

  Future<void> _refresh(WidgetRef ref) => ref.read(roomsProvider.notifier).refresh();

  void _openRoom(BuildContext context, Room room) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _RoomScreenPlaceholder(room: room)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView.separated(
        padding: const EdgeInsets.all(Spacing.md),
        itemCount: rooms.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacing.sm),
        itemBuilder: (context, index) {
          final room = rooms[index];
          return RoomCard(
                room: room,
                isPinned: room.isMember,
                onTap: () => _openRoom(context, room),
              )
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: (index * 50).clamp(0, 400)),
              )
              .slideY(
                begin: 0.05,
                end: 0,
                duration: 300.ms,
                delay: Duration(milliseconds: (index * 50).clamp(0, 400)),
                curve: Curves.easeOutCubic,
              );
        },
      ),
    );
  }
}

/// TODO(Task 10): replace with the real `RoomScreen` — hub chat with
/// history, composer, live presence, and the pinned daily-prompt card. This
/// stub exists only so the directory is navigable in this batch; it does
/// not join the socket room or send/receive messages.
class _RoomScreenPlaceholder extends StatelessWidget {
  const _RoomScreenPlaceholder({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${room.emojiFlag} ${room.title}'.trim()),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forum_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                'Room chat is coming soon',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${room.memberCount} members · ${room.onlineCount} online',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
