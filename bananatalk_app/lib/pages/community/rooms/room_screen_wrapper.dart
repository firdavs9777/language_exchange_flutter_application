// lib/pages/community/rooms/room_screen_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/room.dart';
import 'package:bananatalk_app/pages/community/rooms/room_screen.dart';
import 'package:bananatalk_app/pages/community/widgets/community_error_state.dart';
import 'package:bananatalk_app/providers/rooms_provider.dart';

/// Fetch-by-id wrapper for `/room/:roomId` — mirrors `ChatScreenWrapper` /
/// `MomentDetailWrapper` / `ProfileWrapper` (`lib/router/app_router.dart`):
/// `RoomScreen` needs a full `Room` object, but a deep link (notification
/// tap) only carries a `roomId`, so this fetches it via
/// `RoomApiClient.getRoom` first and builds the real screen once it lands.
///
/// Task 16 (client layer C) — this is what lets `NotificationRouter` deep
/// link `room_message` / `room_join` / `room_join_request` /
/// `room_join_approved` / `room_join_denied` straight into the room instead
/// of only as far as the Community tab.
class RoomScreenWrapper extends ConsumerStatefulWidget {
  const RoomScreenWrapper({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<RoomScreenWrapper> createState() => _RoomScreenWrapperState();
}

class _RoomScreenWrapperState extends ConsumerState<RoomScreenWrapper> {
  late final Future<Room?> _roomFuture =
      ref.read(roomApiClientProvider).getRoom(widget.roomId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Room?>(
      future: _roomFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final room = snapshot.data;
        if (room == null) {
          // Room not found (deleted) or the notification is stale — fall
          // back to the Community tab (rooms directory lives inside it)
          // rather than stranding the user on a dead-end error screen.
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            appBar: AppBar(),
            body: CommunityErrorState(
              message: l10n.roomNotAvailable,
              onRetry: () => context.go('/tabs/1'),
              retryLabel: l10n.roomGoToRooms,
            ),
          );
        }

        return RoomScreen(room: room);
      },
    );
  }
}
