// lib/providers/presence_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';

class PresenceState {
  final Set<String> onlineUserIds;
  final Map<String, DateTime> lastSeen;

  const PresenceState({
    this.onlineUserIds = const {},
    this.lastSeen = const {},
  });

  bool isOnline(String userId) => onlineUserIds.contains(userId);

  PresenceState withOnline(String userId) => PresenceState(
    onlineUserIds: {...onlineUserIds, userId},
    lastSeen: lastSeen,
  );

  PresenceState withOffline(String userId, DateTime at) => PresenceState(
    onlineUserIds: onlineUserIds.where((id) => id != userId).toSet(),
    lastSeen: {...lastSeen, userId: at},
  );

  PresenceState withBulk(List<String> ids) =>
      PresenceState(onlineUserIds: ids.toSet(), lastSeen: lastSeen);
}

class PresenceNotifier extends StateNotifier<PresenceState> {
  PresenceNotifier(this._socket) : super(const PresenceState()) {
    _subOnline = _socket.onPresenceOnline.listen((data) {
      final id = data['userId']?.toString();
      if (id != null && id.isNotEmpty) {
        state = state.withOnline(id);
      }
    });
    _subOffline = _socket.onPresenceOffline.listen((data) {
      final id = data['userId']?.toString();
      if (id == null || id.isEmpty) return;
      final at =
          DateTime.tryParse(data['lastSeenAt']?.toString() ?? '') ??
          DateTime.now();
      state = state.withOffline(id, at);
    });
    _subBulk = _socket.onPresenceBulk.listen((ids) {
      state = state.withBulk(ids);
    });
  }

  final ChatSocketService _socket;
  late final StreamSubscription<Map<String, dynamic>> _subOnline;
  late final StreamSubscription<Map<String, dynamic>> _subOffline;
  late final StreamSubscription<List<String>> _subBulk;

  @override
  void dispose() {
    _subOnline.cancel();
    _subOffline.cancel();
    _subBulk.cancel();
    super.dispose();
  }
}

final presenceProvider = StateNotifierProvider<PresenceNotifier, PresenceState>(
  (ref) {
    // ChatSocketService() always returns the process-wide singleton via its
    // factory constructor — same pattern used throughout the codebase.
    final notifier = PresenceNotifier(ChatSocketService());
    ref.onDispose(notifier.dispose);
    return notifier;
  },
);
