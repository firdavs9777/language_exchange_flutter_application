import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// PayPal account handle shown as a hint under the support buttons (not a translatable string).
const String _paypalHandle = '@firdavsDev';

class SupportSheet extends StatefulWidget {
  const SupportSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const SupportSheet(),
  );

  @override
  State<SupportSheet> createState() => SupportSheetState();
}

class SupportSheetState extends State<SupportSheet> {
  static const _paypalUrl = 'https://paypal.me/firdavsDev';
  bool _adWatched = false;
  bool _adLoading = false;

  Future<void> _donate() async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(_paypalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _watchAd() async {
    if (_adLoading) return;
    HapticFeedback.lightImpact();

    final adService = AdService();
    if (!adService.isRewardedAdReady) {
      // Ad not loaded yet — try loading and show a brief wait state
      setState(() => _adLoading = true);
      adService.loadRewarded();
      // Poll up to 8 seconds for the ad to load
      for (int i = 0; i < 16; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        if (adService.isRewardedAdReady) break;
      }
      if (mounted) setState(() => _adLoading = false);
      if (!adService.isRewardedAdReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.adNotReady)),
          );
        }
        return;
      }
    }

    await adService.showRewarded(
      onRewarded: () {
        if (mounted) setState(() => _adWatched = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // The app theme, not the phone setting: the in-app theme can differ.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.60)
        : const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Emoji + headline
          const Text('☕', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(
            l10n.supportSheetGreeting,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          // Story card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(
                0xFF00BFA5,
              ).withValues(alpha: isDark ? 0.12 : 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(
                  0xFF00BFA5,
                ).withValues(alpha: isDark ? 0.22 : 0.18),
              ),
            ),
            child: Text(
              l10n.supportSheetStory,
              style: TextStyle(fontSize: 14, color: textSecondary, height: 1.6),
            ),
          ),
          const SizedBox(height: 20),

          // Watch an ad button
          GestureDetector(
            onTap: _adWatched ? null : _watchAd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _adWatched
                      ? [const Color(0xFF43A047), const Color(0xFF2E7D32)]
                      : [const Color(0xFFFF6F00), const Color(0xFFE65100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_adWatched
                                ? const Color(0xFF43A047)
                                : const Color(0xFFFF6F00))
                            .withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_adLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Text(
                      _adWatched ? '✅' : '▶️',
                      style: const TextStyle(fontSize: 18),
                    ),
                  const SizedBox(width: 10),
                  Text(
                    _adWatched
                        ? l10n.profileThanksForWatching
                        : l10n.supportSheetWatchAd,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Divider with "or"
          Row(
            children: [
              Expanded(
                child: Divider(color: textSecondary.withValues(alpha: 0.3)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.profileOr,
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ),
              Expanded(
                child: Divider(color: textSecondary.withValues(alpha: 0.3)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // PayPal donate button
          GestureDetector(
            onTap: _donate,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003087), Color(0xFF009CDE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF003087).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💙', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    l10n.supportSheetDonateButton,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // PayPal handle hint
          Text(
            _paypalHandle,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
