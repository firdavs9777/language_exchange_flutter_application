import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/guide_store.dart';
import 'package:bananatalk_app/widgets/guides/guide_card.dart';

/// Mounts the first-session guide for one [GuideSurface], or nothing.
///
/// Every page gets its hint through this one widget so the eligibility rule,
/// the view cap, the per-run latch and the two analytics events cannot drift
/// between five copies. The Matches panel is the exception: it predates this
/// and carries its own funnel events, which are reported against the
/// registration funnel and must not be merged into the generic ones.
///
/// Renders `SizedBox.shrink()` when ineligible, so a page can mount it
/// unconditionally at the top of its body.
class PageGuide extends ConsumerWidget {
  const PageGuide({
    super.key,
    required this.surface,
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
    this.ctaLabel,
    this.onCta,
    this.secondaryLabel,
    this.onSecondary,
    this.acted = false,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 4),
  });

  final GuideSurface surface;
  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  final String? ctaLabel;
  final VoidCallback? onCta;

  /// A second destination for a surface with two real goals. See
  /// [GuideCard.secondaryLabel].
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// A page-derived signal that the user has already done this, OR-ed with
  /// the stored flag. The Chats guide passes `conversations.isNotEmpty` and
  /// the Profile guide `photos.isNotEmpty`: telling someone to do a thing
  /// their own screen is currently showing them having done reads as a bug.
  final bool acted;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withinWindow = ref.watch(userProvider).maybeWhen(
          data: (u) => u.joinedWithinDays(kGuideWindowDays),
          orElse: () => false,
        );
    final state = ref
        .watch(guideStateProvider(surface))
        .maybeWhen(data: (s) => s, orElse: () => GuideState.unknown);

    final show = shouldShowGuide(
      withinWindow: withinWindow,
      acted: acted || state.acted,
    );

    // Debug-only: the Matches panel had four conditions and failed silently,
    // which made it untestable on a device until these lines existed.
    if (kDebugMode) {
      debugPrint(
        '[Guide:${surface.slug}] show=$show '
        '(within${kGuideWindowDays}d=$withinWindow '
        'acted=${acted || state.acted} views=${state.timesShown})',
      );
    }

    if (!show) return const SizedBox.shrink();

    _recordAfterFrame(ref, state.timesShown);

    return Padding(
      padding: padding,
      child: GuideCard(
        icon: icon,
        accent: accent,
        title: title,
        body: body,
        ctaLabel: ctaLabel,
        onCta: onCta == null ? null : () => _onCta(ref),
        secondaryLabel: secondaryLabel,
        onSecondary:
            onSecondary == null ? null : () => _onCta(ref, secondary: true),
      ),
    );
  }

  void _onCta(WidgetRef ref, {bool secondary = false}) {
    // `target` is what makes a two-destination card worth having: without it
    // the console says AI Study's guide was tapped, but not whether anyone
    // wanted the tutor or the exam prep.
    AnalyticsService.instance.guideCtaTapped(
      surface: surface.slug,
      target: secondary ? 'secondary' : 'primary',
    );
    // The tap is what the guide exists to produce, so it retires the guide
    // even if the user backs out of what it opened. The view cap would have
    // bounded it anyway; this stops the card nagging someone who complied.
    GuideStore.markActed(surface);
    (secondary ? onSecondary! : onCta!)();
  }

  void _recordAfterFrame(WidgetRef ref, int timesShown) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final latch = ref.read(guideRecordedProvider(surface).notifier);
      if (latch.state) return;
      latch.state = true;
      AnalyticsService.instance.guideShown(
        surface: surface.slug,
        // Post-increment: the event reports the view the user is looking at,
        // not the number of views before it. Reported pre-increment, the
        // first view logged 0 and the cap looked off by one in the console.
        timesShown: timesShown + 1,
      );
      // Deliberately NOT invalidating guideStateProvider afterwards: the
      // latch already stops a second record, and refetching mid-view removed
      // the Matches panel milliseconds after it appeared, jumping the list
      // exactly as the user reached for the first card.
      GuideStore.recordShown(surface);
    });
  }
}
