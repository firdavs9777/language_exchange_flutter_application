import 'package:flutter/foundation.dart';

import 'package:bananatalk_app/pages/community/first_session/first_session_store.dart';
import 'package:bananatalk_app/services/analytics_service.dart';

/// Report the first message this user ever sends, once.
///
/// Shared because there is no single send path. The chat screen sends over
/// the socket via ChatStateNotifier; the Partners-tab wave and explicit
/// replies go through MessageService's HTTP calls. The first-session panel
/// sends people down the chat path, so wiring only MessageService -- which an
/// earlier version of this feature did -- left `first_message_sent` firing
/// for nobody who did what the panel asked.
///
/// Fired on a send that SUCCEEDED, never on a Say hi tap: a tap is not a
/// conversation, and counting taps would flatter the panel being measured.
///
/// The stored flag is the guard, so a chatty user reports once rather than
/// forever. Best effort throughout: analytics and prefs must never fail a
/// send.
Future<void> reportFirstMessageIfFirst() async {
  try {
    final state = await FirstSessionStore.read();
    if (state.hasMessaged) {
      if (kDebugMode) debugPrint('[FirstSession] send: not the first, no event');
      return;
    }
    await FirstSessionStore.markMessaged();
    if (kDebugMode) {
      debugPrint('[FirstSession] FIRST MESSAGE SENT — panel retires');
    }
    AnalyticsService.instance.firstMessageSent();
  } catch (_) {
    // Never let reporting break sending.
  }
}
