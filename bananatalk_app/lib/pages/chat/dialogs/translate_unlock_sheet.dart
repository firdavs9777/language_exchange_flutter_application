import 'package:flutter/material.dart';

import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';

/// Bottom sheet shown when in-conversation auto-translate hits its daily
/// cap. Offers the à-la-carte coin unlock for the `translation` catalog key.
/// Returns `true` when the user successfully unlocked (caller should retry
/// the translate call once), `false` otherwise (dismissed / not unlocked).
Future<bool> showTranslateUnlockSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Translation limit reached',
            style: ctx.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve used up today\'s free translations in this chat. '
            'Unlock more instantly with coins.',
            style: ctx.bodyMedium.copyWith(color: ctx.textSecondary),
          ),
          const SizedBox(height: 16),
          UnlockCta(
            featureKey: 'translation',
            onUnlocked: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
