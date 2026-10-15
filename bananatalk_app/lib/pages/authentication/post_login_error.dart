import 'dart:convert';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/utils/friendly_error.dart';

/// What to do when the user fetch right after a SUCCESSFUL sign-in fails.
///
/// The login screens used to treat every failure as "Session expired": they
/// logged the user out and said so -- including when the phone had merely
/// dropped its connection a second after the server accepted the password.
/// Only a rejected token (or a missing account) means the session is bad;
/// anything else is retryable and must keep the user signed in.
///
/// A suspended account is neither: it goes to AccountSuspendedScreen.
enum PostLoginFailure { suspended, sessionRejected, retryable }

PostLoginFailure classifyPostLoginError(Object error) {
  if (suspensionFromPostLoginError(error) != null) {
    return PostLoginFailure.suspended;
  }
  final text = error.toString();
  if (text.contains('Not authenticated') ||
      RegExp(r'Failed to load user info: (401|403|404)\b').hasMatch(text)) {
    return PostLoginFailure.sessionRejected;
  }
  return PostLoginFailure.retryable;
}

/// A sign-in refused because the account is suspended (backend 403
/// `ACCOUNT_BANNED`, message "Your account has been suspended...").
/// [reason] is the moderator's reason, or null when none was given.
class AccountSuspension {
  const AccountSuspension(this.reason);
  final String? reason;
}

const _suspendedPrefix = 'Your account has been suspended';

/// The suspension in an auth-service result map (login, Google, Apple), or
/// null when the refusal was for anything else. Same contract ApiClient's
/// 403 handling reads: `banReason` when the key is present, else the
/// " Reason: ..." suffix older backends put in the message.
AccountSuspension? suspensionFromAuthResult(Map<String, dynamic> result) {
  final message = (result['message'] ?? result['error'])?.toString() ?? '';
  if (result['code'] != 'ACCOUNT_BANNED' &&
      !message.startsWith(_suspendedPrefix)) {
    return null;
  }
  final reason = result.containsKey('banReason')
      ? result['banReason']
      : RegExp(r'Reason:\s*(.+)$').firstMatch(message)?.group(1);
  return AccountSuspension(
    reason is String && reason.trim().isNotEmpty ? reason.trim() : null,
  );
}

/// The suspension behind a failed post-login `getLoggedInUser()` (it throws
/// "Failed to load user info: 403 <body>"), or null.
AccountSuspension? suspensionFromPostLoginError(Object error) {
  final match = RegExp(r'Failed to load user info: 403 (.*)$', dotAll: true)
      .firstMatch(error.toString());
  if (match == null) return null;
  try {
    final body = jsonDecode(match.group(1)!);
    if (body is Map<String, dynamic>) return suspensionFromAuthResult(body);
  } catch (_) {}
  return null;
}

/// Opens the same AccountSuspendedScreen a suspended 403 on any API call
/// does (main.dart wires [ApiClient.onAccountSuspended]: clears the session
/// and the biometric snapshot, then replaces the stack). Returns false when
/// that hook is not wired, so the caller can fall back to a message.
Future<bool> openAccountSuspended(AccountSuspension suspension) async {
  final handler = ApiClient().onAccountSuspended;
  if (handler == null) return false;
  await handler(suspension.reason);
  return true;
}

/// The message for a [PostLoginFailure.retryable] failure: "No internet
/// connection" when offline, otherwise "Something went wrong" -- never the
/// raw exception text.
String retryablePostLoginMessage(AppLocalizations l10n, Object error) =>
    friendlyErrorMessage(l10n, error);

/// The user-facing message for a failed social sign-in (Google / Apple SDK
/// or the backend exchange), or null when the user simply cancelled.
///
/// Replaces `'$friendly\n\nDetails: ${e.toString()}'`, which put raw
/// PlatformException / ClientException text in front of users. Callers log
/// the raw error instead.
String? socialSignInErrorMessage(AppLocalizations l10n, Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('canceled') ||
      text.contains('cancelled') ||
      text.contains('12501')) {
    return null;
  }
  if (text.contains('network') || text.contains('7:')) {
    return l10n.noInternetConnection;
  }
  return friendlyErrorMessage(l10n, error);
}

/// The message for an auth-service result map with `success: false`:
/// offline maps to the localized string, otherwise the server's own message
/// (lockout minutes, "use Google/Apple sign-in", ...) is shown as-is.
String authResultMessage(
  AppLocalizations l10n,
  Map<String, dynamic> result, {
  required String fallback,
}) {
  if (result['isNetworkError'] == true) return l10n.noInternetConnection;
  final message = result['message']?.toString() ?? '';
  return message.isNotEmpty ? message : fallback;
}
