import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/friendly_error.dart';

/// What to do when the user fetch right after a SUCCESSFUL sign-in fails.
///
/// The login screens used to treat every failure as "Session expired": they
/// logged the user out and said so -- including when the phone had merely
/// dropped its connection a second after the server accepted the password.
/// Only a rejected token (or a missing account) means the session is bad;
/// anything else is retryable and must keep the user signed in.
enum PostLoginFailure { sessionRejected, retryable }

PostLoginFailure classifyPostLoginError(Object error) {
  final text = error.toString();
  if (text.contains('Not authenticated') ||
      RegExp(r'Failed to load user info: (401|403|404)\b').hasMatch(text)) {
    return PostLoginFailure.sessionRejected;
  }
  return PostLoginFailure.retryable;
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
