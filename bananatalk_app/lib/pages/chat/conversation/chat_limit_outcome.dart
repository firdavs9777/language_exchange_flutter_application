/// What the chat screen does after `LimitExceededDialog` closes.
enum ChatLimitOutcome {
  /// The server granted extra messages (paid coins unlock, or a rewarded-ad
  /// unlock the server accepted): refresh limits + balance and resend.
  retry,

  /// Legacy rewarded-ad path: grant local bonus messages, no resend.
  rewardedOnly,

  /// Dismissed / upgraded / anything else: nothing to do.
  none,
}

/// Maps the dialog's pop value to the chat screen's next step.
ChatLimitOutcome handleLimitDialogResult(String? result) {
  switch (result) {
    case 'unlocked':
      return ChatLimitOutcome.retry;
    case 'rewarded':
      return ChatLimitOutcome.rewardedOnly;
    default:
      return ChatLimitOutcome.none;
  }
}
