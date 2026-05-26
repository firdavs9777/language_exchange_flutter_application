import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/ai/tutor/scenario_picker_screen.dart';

/// Weekly promo for the AI Study (practice scenarios) feature.
///
/// Surfaces in `TabsScreen.initState` after the first frame. Throttled to
/// once per 7 days per device via SharedPreferences.
class AiStudyPromoModal {
  static const _prefKey = 'ai_study_promo_last_shown_at';
  static const _cooldown = Duration(days: 7);

  /// Show the modal if at least 7 days have passed since the last impression.
  /// Records the impression time on both 'shown' and any user action so the
  /// timer restarts whether they tapped Maybe later or Try it.
  static Future<void> showIfDue(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final lastIso = prefs.getString(_prefKey);
    if (lastIso != null) {
      final last = DateTime.tryParse(lastIso);
      if (last != null && DateTime.now().difference(last) < _cooldown) {
        return; // still within cooldown
      }
    }
    if (!context.mounted) return;
    await prefs.setString(_prefKey, DateTime.now().toIso8601String());
    if (!context.mounted) return;
    await _show(context);
  }

  static Future<void> _show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _PromoSheet(),
    );
  }
}

class _PromoSheet extends StatelessWidget {
  const _PromoSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text('🎭', style: TextStyle(fontSize: 34)),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.aiStudyPromoTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.aiStudyPromoBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (_) => const ScenarioPickerScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.aiStudyPromoCTA,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.aiStudyPromoDismiss,
                style: TextStyle(color: context.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
