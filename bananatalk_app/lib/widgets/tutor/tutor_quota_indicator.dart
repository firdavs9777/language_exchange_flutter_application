import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';

/// Compact "N left today" pill. Renders nothing for VIP / below 50% used.
/// Step 13A.
class TutorQuotaIndicator extends ConsumerWidget {
  final String featureKey;
  final IconData icon;

  const TutorQuotaIndicator({
    super.key,
    required this.featureKey,
    this.icon = Icons.flash_on_rounded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(tutorQuotaProvider).get(featureKey);
    if (info == null || !info.shouldShowIndicator) {
      return const SizedBox.shrink();
    }
    final remaining = info.remaining ?? 0;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 6),
          Text(
            l10n.aiTutorQuotaRemaining(remaining),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
