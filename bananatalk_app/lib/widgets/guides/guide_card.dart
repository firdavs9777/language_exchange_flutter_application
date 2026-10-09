import 'package:flutter/material.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/guides/pulse_highlight.dart';

/// The card a page shows a first-time user: what this screen is for, and the
/// one button that gets them started.
///
/// Deliberately an in-page card, not an overlay or a coach-mark tour. The
/// growth spec argues against adding friction at the moment someone is
/// deciding whether to stay, and a modal that must be dismissed before the
/// screen can be used is the largest way to build the thing it argues
/// against. It points at one action instead of narrating the screen.
///
/// No dismiss control — a dismiss invites dismissal instead of acting, and
/// `kMaxGuideViews` already bounds how often this appears.
class GuideCard extends StatelessWidget {
  const GuideCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
    this.ctaLabel,
    this.onCta,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;

  /// Omitted when the page has nothing to send the user to — the Chats tab
  /// guide explains where conversations come from, and the button that would
  /// start one lives on another tab.
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final hasCta = ctaLabel != null && onCta != null;
    return _FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.14),
              accent.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: AppRadius.borderLG,
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: AppRadius.borderMD,
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                // Flexible so a longer localized string wraps instead of
                // overflowing — the same failure the chat app bar hit on
                // 2026-10-09, in the same shape of bounded row.
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasCta) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: PulseHighlight(
                  color: accent,
                  borderRadius: AppRadius.borderRound,
                  child: _CtaPill(
                    label: ctaLabel!,
                    accent: accent,
                    onTap: onCta!,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CtaPill extends StatelessWidget {
  const _CtaPill({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent,
      borderRadius: AppRadius.borderRound,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRound,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bounded so a long translation ellipsises inside the pill
              // rather than pushing the arrow off the card.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short rise-and-fade on first build.
///
/// The card is inserted above content that is already on screen, so without
/// it the page visibly jolts when the stored state resolves a frame or two
/// after the list. Finite, so `pumpAndSettle` terminates.
class _FadeInUp extends StatelessWidget {
  const _FadeInUp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
