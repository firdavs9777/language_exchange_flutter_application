import 'package:flutter/material.dart';

import 'package:bananatalk_app/services/paywall/paywall_navigation.dart';
import 'package:bananatalk_app/services/paywall/paywall_flow.dart';
import 'package:bananatalk_app/services/paywall/paywall_showing.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';

/// Bottom sheet shown when in-conversation auto-translate hits its daily
/// cap. Offers the à-la-carte coin unlock for the `translation` catalog key.
/// Returns `true` when the user successfully unlocked (caller should retry
/// the translate call once), `false` otherwise (dismissed / not unlocked).
Future<bool> showTranslateUnlockSheet(BuildContext context) async {
  final showing = PaywallShowing.begin(
    PaywallPlacement.translationCap,
    detail: 'chat_sheet',
  );
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
            AppLocalizations.of(ctx)!.chatTranslationLimitReached,
            style: ctx.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(ctx)!.chatTranslateLimitBody,
            style: ctx.bodyMedium.copyWith(color: ctx.textSecondary),
          ),
          const SizedBox(height: 16),
          UnlockCta(
            featureKey: 'translation',
            flow: showing.flow,
            onCtaTapped: showing.markActed,
            onUnlocked: () => Navigator.pop(ctx, true),
          ),
          const SizedBox(height: 8),
          // VIP is unlimited translations; this sheet only offered coins.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('translate-limit-go-vip'),
              icon: const Icon(Icons.workspace_premium_rounded, size: 18),
              label: Text(
                '${AppLocalizations.of(ctx)!.goVip} · '
                '${AppLocalizations.of(ctx)!.perkUnlimitedTranslations}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () {
                showing.markActed();
                Navigator.pop(ctx, false);
                openVipPlans<void>(
                  context,
                  showing.flow,
                  userId: '',
                  route: PaywallRoute.app,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
  showing.finish();
  return result ?? false;
}
