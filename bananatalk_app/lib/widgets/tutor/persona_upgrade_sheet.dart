import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/coins/unlock_cta.dart';

/// Persona-aware variant of VipUpgradeSheet. Copy matches the user's
/// selected persona — falls back to generic if persona is unset.
/// Fires paywall_shown once when shown, paywall_cta_tapped on Upgrade.
/// Step 13A.
class PersonaUpgradeSheet extends ConsumerStatefulWidget {
  final String triggerChip;
  final String reason; // 'quota_exceeded' | 'locked_feature'

  const PersonaUpgradeSheet({
    super.key,
    required this.triggerChip,
    this.reason = 'quota_exceeded',
  });

  @override
  ConsumerState<PersonaUpgradeSheet> createState() => _PersonaUpgradeSheetState();
}

class _PersonaUpgradeSheetState extends ConsumerState<PersonaUpgradeSheet> {
  String get triggerChip => widget.triggerChip;

  @override
  void initState() {
    super.initState();
    // Once per showing. Firing from build counted every rebuild (memory
    // loading, keyboard insets, catalog) as another paywall view.
    AnalyticsService.instance
        .paywallShown(triggerChip: widget.triggerChip, reason: widget.reason);
  }

  String _copyForPersona(AppLocalizations l10n, String? persona) {
    switch (persona) {
      case 'nana':
        return l10n.personaUpgradeNana;
      case 'sensei':
        return l10n.personaUpgradeSensei;
      case 'riko':
        return l10n.personaUpgradeRiko;
      default:
        return l10n.personaUpgradeGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final memAsync = ref.watch(tutorMemoryProvider);
    final persona = memAsync.valueOrNull?.persona;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 28, 24, MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _copyForPersona(AppLocalizations.of(context)!, persona),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                AnalyticsService.instance.paywallCtaTapped(chipName: triggerChip);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VipPlansScreen()),
                );
              },
              child: Text(
                AppLocalizations.of(context)!.upgradeToVip,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          // Coins v1: à-la-carte alternative to VIP for this specific
          // tutor chip — hidden when coinsEnabled is off. `triggerChip` is
          // already the exact backend featureKey (the 429's `feature`
          // field), not a generic "tutor" key, so the unlock grants the
          // chip that actually hit its cap.
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: UnlockCta(
              featureKey: triggerChip,
              // This sheet is shown from a global 429 interceptor
              // (main.dart) with no handle back to the chat screen that
              // triggered it, so there's no gated action to retry inline
              // here — closing the sheet lets the user tap the chip again.
              // Refresh the quota so the chip's indicator shows the new uses
              // instead of 0 until the next gated call.
              onUnlocked: () {
                ref.invalidate(tutorMemoryAndQuotasProvider);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.aiStudyPromoDismiss, style: const TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}
