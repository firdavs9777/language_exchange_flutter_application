import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/promo_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Content (icon, copy, accent) for one [PromoType], resolved against the
/// current locale.
class _SpotlightContent {
  const _SpotlightContent({
    required this.emoji,
    required this.headline,
    required this.subtitle,
    required this.accent,
  });

  final String emoji;
  final String headline;
  final String subtitle;
  final Color accent;
}

_SpotlightContent _contentFor(PromoType type, AppLocalizations l10n) {
  switch (type) {
    case PromoType.coins:
      return _SpotlightContent(
        emoji: '💎',
        headline: l10n.promoSpotlightCoinsHeadline,
        subtitle: l10n.promoSpotlightCoinsSubtitle,
        accent: AppColors.warning,
      );
    case PromoType.rooms:
      return _SpotlightContent(
        emoji: '💬',
        headline: l10n.promoSpotlightRoomsHeadline,
        subtitle: l10n.promoSpotlightRoomsSubtitle,
        accent: AppColors.primary,
      );
    case PromoType.voice:
      return _SpotlightContent(
        emoji: '🎙️',
        headline: l10n.promoSpotlightVoiceHeadline,
        subtitle: l10n.promoSpotlightVoiceSubtitle,
        accent: AppColors.accent,
      );
  }
}

/// How the user left the sheet — decides which [PromoService] bookkeeping
/// call to make after it closes.
enum _SpotlightOutcome { tried, dismissed }

/// Shows the rotating "feature spotlight" bottom sheet for [type].
///
/// A dismissible, non-blocking `showModalBottomSheet` (drag handle, tap
/// outside or swipe down to close — never a modal dialog the user is stuck
/// in). Calls [onTry] only when the user taps the primary CTA; the caller
/// owns the actual deep-link/navigation.
///
/// Bookkeeping: records a dismissal via [incrementDismiss] when the user
/// closes the sheet without trying it (tapping "Maybe later" or
/// swiping/tapping away), or [markDontShowAgain] when they toggled the
/// "Don't show this again" option — regardless of which button they used to
/// close it. The caller is still responsible for calling [markShown] once
/// this returns, so the once-per-day cap is enforced at the trigger site.
Future<void> showFeatureSpotlight(
  BuildContext context,
  PromoType type, {
  required VoidCallback onTry,
}) async {
  var dontShowAgain = false;
  var outcome = _SpotlightOutcome.dismissed;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (builderContext, setSheetState) {
          final l10n = AppLocalizations.of(builderContext)!;
          final content = _contentFor(type, l10n);
          final bottomInset = MediaQuery.of(builderContext).padding.bottom;

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: content.accent.withValues(
                      alpha: builderContext.isDarkMode ? 0.18 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    content.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  content.headline,
                  textAlign: TextAlign.center,
                  style: builderContext.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  content.subtitle,
                  textAlign: TextAlign.center,
                  style: builderContext.bodyMedium.copyWith(
                    color: builderContext.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      outcome = _SpotlightOutcome.tried;
                      Navigator.of(sheetContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: content.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.promoSpotlightTryIt,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    outcome = _SpotlightOutcome.dismissed;
                    Navigator.of(sheetContext).pop();
                  },
                  child: Text(
                    l10n.promoSpotlightMaybeLater,
                    style: TextStyle(color: builderContext.textSecondary),
                  ),
                ),
                InkWell(
                  onTap: () =>
                      setSheetState(() => dontShowAgain = !dontShowAgain),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: dontShowAgain,
                            onChanged: (checked) => setSheetState(
                              () => dontShowAgain = checked ?? false,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.promoSpotlightDontShowAgain,
                          style: builderContext.labelMedium.copyWith(
                            color: builderContext.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  if (dontShowAgain) {
    await markDontShowAgain(type);
  } else if (outcome == _SpotlightOutcome.dismissed) {
    await incrementDismiss();
  }

  if (outcome == _SpotlightOutcome.tried && context.mounted) {
    onTry();
  }
}
