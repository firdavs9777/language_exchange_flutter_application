import 'package:flutter/foundation.dart';

/// Turns ApiClient's "session is definitively over" signal into exactly one
/// logout + one navigation to login.
///
/// `ApiClient.onAuthenticationError` was never assigned, so when a refresh
/// failed for good the app kept running on a dead token and every screen went
/// empty. It is raised once per failed request, so a screen firing 20
/// requests raises it 20 times; this handler:
///  - ignores calls while one is in flight (a single reset, a single route);
///  - ignores calls when there is no stored session (stray 401s from screens
///    still unwinding after a logout, or from the login screen itself);
///  - never decides *whether* the session is dead -- ApiClient only raises
///    the signal for a rejected refresh token or a deleted user, never for a
///    network error.
class SessionExpiryHandler {
  SessionExpiryHandler({
    required Future<bool> Function() hasSession,
    required Future<void> Function() resetSession,
    required void Function() onExpired,
  })  : _hasSession = hasSession,
        _resetSession = resetSession,
        _onExpired = onExpired;

  final Future<bool> Function() _hasSession;
  final Future<void> Function() _resetSession;
  final void Function() _onExpired;

  bool _handling = false;

  /// Assign to `ApiClient.onAuthenticationError`.
  Future<void> handle() async {
    if (_handling) return;
    _handling = true;
    try {
      if (!await _hasSession()) return;
      await _resetSession();
      _onExpired();
    } catch (e) {
      debugPrint('[session-expiry] handling failed: $e');
    } finally {
      _handling = false;
    }
  }
}
