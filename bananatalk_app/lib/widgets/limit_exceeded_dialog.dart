import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/user_limits.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/ad_service.dart';
import 'package:bananatalk_app/services/coin_api_client.dart';
import 'package:bananatalk_app/services/rewarded_unlock_policy.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';
import 'package:intl/intl.dart';

/// The "Watch ad" reward handler, extracted so it is testable without the ad
/// SDK. Flag off / feature not rewardable -> `'rewarded'` with no call (the
/// legacy behaviour). Otherwise calls `POST /coins/rewarded-unlock` and maps
/// the status via [RewardedUnlockPolicy]; a server grant returns
/// `'unlocked'` and shows [successMessage], the daily cap shows
/// [limitMessage]. Returns the value the dialog pops.
Future<String> runRewardedUnlock({
  required CoinApiClient client,
  required bool flagOn,
  required String? featureKey,
  required bool rewardable,
  required ScaffoldMessengerState? messenger,
  required String limitMessage,
  required String successMessage,
}) async {
  if (!RewardedUnlockPolicy.shouldCall(
    flagOn: flagOn,
    featureKey: featureKey,
    featureRewardable: rewardable,
  )) {
    return 'rewarded';
  }
  int? status;
  var replay = false;
  try {
    final res = await client.rewardedUnlock(featureKey!);
    status = res.statusCode;
    final data = res.data;
    replay = data is Map && data['alreadyCredited'] == true;
  } catch (_) {
    status = null; // fail open
  }
  final outcome = RewardedUnlockPolicy.resultFor(
    flagOn: flagOn,
    featureKey: featureKey,
    featureRewardable: rewardable,
    statusCode: status,
    alreadyCredited: replay,
  );
  if (outcome.messageKey == RewardedUnlockPolicy.limitReachedMessage) {
    messenger?.showSnackBar(SnackBar(content: Text(limitMessage)));
  } else if (outcome.result == 'unlocked') {
    messenger?.showSnackBar(SnackBar(content: Text(successMessage)));
  }
  return outcome.result;
}

/// True for the daily wave cap surface (`limitType: 'wave'`).
bool isWaveLimitType(String limitType) {
  final t = limitType.toLowerCase();
  return t == 'wave' || t == 'waves';
}

class LimitExceededDialog extends ConsumerWidget {
  final String limitType;
  final LimitInfo? limitInfo;
  final DateTime? resetTime;
  final String? errorMessage;
  final String userId;

  const LimitExceededDialog({
    super.key,
    required this.limitType,
    this.limitInfo,
    this.resetTime,
    this.errorMessage,
    required this.userId,
  });

  static Future<dynamic> show({
    required BuildContext context,
    required String limitType,
    LimitInfo? limitInfo,
    DateTime? resetTime,
    String? errorMessage,
    required String userId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LimitExceededDialog(
        limitType: limitType,
        limitInfo: limitInfo,
        resetTime: resetTime,
        errorMessage: errorMessage,
        userId: userId,
      ),
    );
  }

  bool get _isWave => isWaveLimitType(limitType);

  String _getLimitTypeLabel(AppLocalizations l10n) {
    switch (limitType.toLowerCase()) {
      case 'message':
      case 'messages':
        return l10n.limitLabelMessages;
      case 'moment':
      case 'moments':
        return l10n.limitLabelMoments;
      case 'story':
      case 'stories':
        return l10n.limitLabelStories;
      case 'comment':
      case 'comments':
        return l10n.limitLabelComments;
      case 'profile':
      case 'profileview':
      case 'profileviews':
        return l10n.limitLabelProfileViews;
      case 'wave':
      case 'waves':
        return l10n.limitLabelWaves;
      default:
        return limitType;
    }
  }

  String _getLimitTypeDescription(AppLocalizations l10n) {
    switch (limitType.toLowerCase()) {
      case 'message':
      case 'messages':
        return l10n.limitDescMessages;
      case 'moment':
      case 'moments':
        return l10n.limitDescMoments;
      case 'story':
      case 'stories':
        return l10n.limitDescStories;
      case 'comment':
      case 'comments':
        return l10n.limitDescComments;
      case 'profile':
      case 'profileview':
      case 'profileviews':
        return l10n.limitDescProfileViews;
      case 'wave':
      case 'waves':
        return l10n.waveLimitBody;
      default:
        return l10n.limitDescDefault;
    }
  }

  /// Maps a daily-limit surface to its à-la-carte coin unlock key. The
  /// message cap maps to `dm` (extra direct messages today — backend
  /// coinCatalog `dm`, distinct from the AI-tutor `chat` quota). `moment`
  /// maps to `moment`; the daily wave cap maps to `wave` (catalog
  /// `wave: {cost:10, grant:1}`, also a rewarded feature). Surfaces with no
  /// coin unlock return null (no CTA). The CTA also self-hides if the
  /// returned key isn't in the live catalog.
  @visibleForTesting
  static String? featureKeyForUnlock(String limitType) {
    switch (limitType.toLowerCase()) {
      case 'moment':
      case 'moments':
        return 'moment';
      case 'message':
      case 'messages':
        return 'dm';
      case 'wave':
      case 'waves':
        return 'wave';
      default:
        return null;
    }
  }

  String? _featureKeyForUnlock() => featureKeyForUnlock(limitType);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textPrimary = context.textPrimary;
    final secondaryText = context.textSecondary;
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(appConfigProvider).valueOrNull;
    // The wave dialog only exists with waveCapEnabled on; its "Watch ad"
    // button is offered only when the server would actually grant a wave
    // (no legacy local-bonus fallback exists for waves). Every other limit
    // type keeps today's condition.
    final waveAdGrantable =
        (config?.rewardedLimitsEnabled ?? false) &&
        (config?.rewardedFeatures.contains('wave') ?? false);
    final showWatchAd =
        AdService().isRewardedAdReady && (!_isWave || waveAdGrantable);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.info_outline, color: colorScheme.error, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isWave ? l10n.waveLimitTitle : l10n.limitDailyReachedTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage ?? _getLimitTypeDescription(l10n),
              style: TextStyle(fontSize: 14, color: textPrimary, height: 1.5),
            ),
            if (limitInfo != null && !limitInfo!.isUnlimited) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.limitUsedLabel(_getLimitTypeLabel(l10n)),
                          style: TextStyle(fontSize: 12, color: secondaryText),
                        ),
                        Text(
                          '${limitInfo!.currentInt} / ${limitInfo!.maxInt}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: limitInfo!.usagePercentage,
                        backgroundColor: colorScheme.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.error,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (resetTime != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.limitResetsAt,
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d, y • h:mm a').format(resetTime!),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // VIP Benefits Section
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.15),
                    const Color(0xFFFFA500).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.vipMembersGet,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildVipBenefit(l10n.vipBenefitUnlimitedMessages),
                  _buildVipBenefit(l10n.vipBenefitUnlimitedProfileViews),
                  _buildVipBenefit(l10n.vipBenefitAdvancedFilters),
                  _buildVipBenefit(l10n.vipBenefitAiStudyTools),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.maybeLater,
            style: TextStyle(color: secondaryText, fontWeight: FontWeight.w500),
          ),
        ),
        if (_featureKeyForUnlock() != null)
          UnlockCta(
            featureKey: _featureKeyForUnlock()!,
            // Pops 'unlocked' so callers that can retry inline (the chat
            // screen) resend; other callers ignore the result.
            onUnlocked: () => Navigator.pop(context, 'unlocked'),
          ),
        if (showWatchAd)
          OutlinedButton.icon(
            onPressed: () {
              final config = ref.read(appConfigProvider).valueOrNull;
              final flagOn = config?.rewardedLimitsEnabled ?? false;
              final featureKey = _featureKeyForUnlock();
              final rewardable =
                  featureKey != null &&
                  (config?.rewardedFeatures.contains(featureKey) ?? false);
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.maybeOf(context);
              final l10n = AppLocalizations.of(context)!;
              final client = ref.read(coinApiClientProvider);
              AdService().showRewarded(
                onRewarded: () async {
                  final result = await runRewardedUnlock(
                    client: client,
                    flagOn: flagOn,
                    featureKey: featureKey,
                    rewardable: rewardable,
                    messenger: messenger,
                    limitMessage: l10n.rewardedLimitReached,
                    successMessage: l10n.rewardedUnlockSuccess,
                  );
                  navigator.pop(result);
                },
              );
            },
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: Text(AppLocalizations.of(context)!.watchAd),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF667EEA),
              side: const BorderSide(color: Color(0xFF667EEA)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VipPlansScreen(userId: userId),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium, size: 18),
              const SizedBox(width: 6),
              Text(
                l10n.upgradeToVip,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVipBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
