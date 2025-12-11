import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/user_limits.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:intl/intl.dart';

class LimitExceededDialog extends StatelessWidget {
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

  static Future<void> show({
    required BuildContext context,
    required String limitType,
    LimitInfo? limitInfo,
    DateTime? resetTime,
    String? errorMessage,
    required String userId,
  }) async {
    await showDialog(
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

  String _getLimitTypeLabel() {
    switch (limitType.toLowerCase()) {
      case 'message':
      case 'messages':
        return 'Messages';
      case 'moment':
      case 'moments':
        return 'Moments';
      case 'story':
      case 'stories':
        return 'Stories';
      case 'comment':
      case 'comments':
        return 'Comments';
      case 'profile':
      case 'profileview':
      case 'profileviews':
        return 'Profile Views';
      default:
        return limitType;
    }
  }

  String _getLimitTypeDescription() {
    switch (limitType.toLowerCase()) {
      case 'message':
      case 'messages':
        return 'You have reached your daily message limit. Upgrade to VIP for unlimited messaging!';
      case 'moment':
      case 'moments':
        return 'You have reached your daily moment creation limit. Upgrade to VIP for unlimited moments!';
      case 'story':
      case 'stories':
        return 'You have reached your daily story creation limit. Upgrade to VIP for unlimited stories!';
      case 'comment':
      case 'comments':
        return 'You have reached your daily comment limit. Upgrade to VIP for unlimited comments!';
      case 'profile':
      case 'profileview':
      case 'profileviews':
        return 'You have reached your daily profile view limit. Upgrade to VIP for unlimited profile views!';
      default:
        return 'You have reached your daily limit. Upgrade to VIP for unlimited access!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textPrimary = context.textPrimary;
    final secondaryText = context.textSecondary;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline,
              color: colorScheme.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Daily Limit Reached',
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
              errorMessage ?? _getLimitTypeDescription(),
              style: TextStyle(
                fontSize: 14,
                color: textPrimary,
                height: 1.5,
              ),
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
                          '${_getLimitTypeLabel()} Used',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryText,
                          ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.error),
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
                            'Limit Resets At',
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'OK',
            style: TextStyle(
              color: secondaryText,
              fontWeight: FontWeight.w500,
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
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Upgrade to VIP'),
        ),
      ],
    );
  }
}

