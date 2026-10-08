import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/services/call_history_service.dart';

/// Unseen missed calls (receiver side, §3) — the chat-tab phone-icon badge.
class MissedCallsNotifier extends StateNotifier<int> {
  MissedCallsNotifier(this._service) : super(0);

  final CallHistoryService _service;

  Future<void> refresh() async {
    try {
      state = await _service.missedCount();
    } catch (_) {
      // Keep the last known count; the badge is advisory.
    }
  }

  /// The Calls list was opened.
  Future<void> markSeen() async {
    state = 0;
    try {
      await _service.markMissedSeen();
    } catch (_) {}
  }
}

final missedCallsProvider = StateNotifierProvider<MissedCallsNotifier, int>(
  (ref) => MissedCallsNotifier(ref.watch(callHistoryServiceProvider)),
);
