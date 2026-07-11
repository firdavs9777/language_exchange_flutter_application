enum AuthErrorCode {
  codeExpired,
  codeInvalid,
  accountLocked,
  rateLimited,
  emailExists,
  profileIncomplete,
  unknown,
}

AuthErrorCode parseAuthErrorCode(String? code) => switch (code) {
  'CODE_EXPIRED' => AuthErrorCode.codeExpired,
  'CODE_INVALID' => AuthErrorCode.codeInvalid,
  'ACCOUNT_LOCKED' => AuthErrorCode.accountLocked,
  'RATE_LIMITED' => AuthErrorCode.rateLimited,
  'EMAIL_EXISTS' => AuthErrorCode.emailExists,
  'PROFILE_INCOMPLETE' => AuthErrorCode.profileIncomplete,
  _ => AuthErrorCode.unknown,
};

/// Derives the countdown to show in [AuthErrorState] from an auth result map
/// — prefers `retryAfter` (seconds, used for rate limiting), falling back to
/// `lockUntil` (an ISO timestamp, used for account lockouts). Returns null
/// when neither field is present (current backend behavior for most auth
/// endpoints), in which case AuthErrorState falls back to generic copy
/// ("later"/"shortly") instead of a real countdown.
Duration? parseAuthErrorRetryAfter(Map<String, dynamic> result) {
  final retryAfter = result['retryAfter'];
  if (retryAfter != null) {
    final seconds = retryAfter is num
        ? retryAfter.toInt()
        : int.tryParse(retryAfter.toString());
    if (seconds != null && seconds > 0) return Duration(seconds: seconds);
  }

  final lockUntil = result['lockUntil'];
  if (lockUntil != null) {
    try {
      final lockTime = DateTime.parse(lockUntil.toString());
      final remaining = lockTime.difference(DateTime.now());
      if (remaining > Duration.zero) return remaining;
    } catch (_) {
      // Malformed timestamp — fall through to null.
    }
  }

  return null;
}
