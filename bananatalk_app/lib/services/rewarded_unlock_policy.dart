/// Outcome of a "Watch ad" tap on a limit dialog.
class RewardedUnlockOutcome {
  const RewardedUnlockOutcome(
    this.result, {
    this.messageKey,
    this.shouldCallEndpoint = false,
  });

  /// `'unlocked'` (grant applied server-side) or `'rewarded'` (legacy result).
  final String result;

  /// Non-null when the UI should show a message (see
  /// [RewardedUnlockPolicy.limitReachedMessage]).
  final String? messageKey;

  /// Whether the dialog should call `POST /coins/rewarded-unlock` at all.
  final bool shouldCallEndpoint;
}

/// Pure decision logic for rewarded-ad unlocks at feature limits (Growth C6).
class RewardedUnlockPolicy {
  RewardedUnlockPolicy._();

  static const String limitReachedMessage = 'rewardedLimitReached';

  /// Only call the endpoint when the flag is on and the feature is
  /// server-declared rewardable. Otherwise behaviour is exactly as before.
  static bool shouldCall({
    required bool flagOn,
    required String? featureKey,
    required bool featureRewardable,
  }) =>
      flagOn && featureKey != null && featureRewardable;

  /// [statusCode] is the endpoint's HTTP status (null if no call / network
  /// failure). [alreadyCredited] marks a server replay (`granted: 0`), which
  /// fails open to `'rewarded'`.
  static RewardedUnlockOutcome resultFor({
    required bool flagOn,
    required String? featureKey,
    required bool featureRewardable,
    required int? statusCode,
    bool alreadyCredited = false,
  }) {
    if (!shouldCall(
      flagOn: flagOn,
      featureKey: featureKey,
      featureRewardable: featureRewardable,
    )) {
      return const RewardedUnlockOutcome('rewarded');
    }
    if (statusCode == 200 && !alreadyCredited) {
      return const RewardedUnlockOutcome('unlocked', shouldCallEndpoint: true);
    }
    if (statusCode == 429) {
      return const RewardedUnlockOutcome(
        'rewarded',
        messageKey: limitReachedMessage,
        shouldCallEndpoint: true,
      );
    }
    return const RewardedUnlockOutcome('rewarded', shouldCallEndpoint: true);
  }
}
