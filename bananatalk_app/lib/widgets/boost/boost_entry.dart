import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/boost.dart';
import 'package:bananatalk_app/pages/coins/boost_screen.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/boost_api_client.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Whether Profile Boost is switched on server-side (`boostsEnabled`).
bool boostsEnabled(WidgetRef ref) => ref.watch(appConfigProvider).maybeWhen(
      data: (config) => config?.boostsEnabled ?? false,
      orElse: () => false,
    );

/// The same, read once from an event handler (a menu, a snackbar action),
/// where watching is not allowed. The config is loaded at startup.
bool boostsEnabledNow(WidgetRef ref) =>
    ref.read(appConfigProvider).valueOrNull?.boostsEnabled ?? false;

/// The signed-in user's live boost, or null. A failed read counts as "none":
/// the entry points then offer a Boost, and the Boost screen sorts it out.
final myActiveBoostProvider = FutureProvider.autoDispose<Boost?>((ref) async {
  try {
    final b = await ref.read(boostApiClientProvider).getActive();
    return (b != null && b.isLive) ? b : null;
  } catch (_) {
    return null;
  }
});

/// The signed-in user's last boost that ended within the result window, or
/// null (also on a failed read). Drives "Boost again" in the entry row.
final myLastBoostProvider = FutureProvider.autoDispose<Boost?>((ref) async {
  try {
    final history = await ref.read(boostApiClientProvider).getHistory();
    return lastEndedBoost(history, DateTime.now());
  } catch (_) {
    return null;
  }
});

/// Opens the Boost screen, then re-reads the live boost so the entry points
/// switch to "Your boost is live" after a purchase.
Future<void> openBoostScreen(BuildContext context, WidgetRef ref) async {
  await Navigator.push(
    context,
    AppPageRoute<void>(builder: (_) => const BoostScreen()),
  );
  ref.invalidate(myActiveBoostProvider);
  ref.invalidate(myLastBoostProvider);
}

/// One slim row that starts a Boost where people look for partners and
/// moments, not only from the profile drawer. While a boost is live it shows
/// the time left instead. Renders nothing while boosts are switched off.
class BoostEntryRow extends ConsumerWidget {
  const BoostEntryRow({super.key, this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 4)});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!boostsEnabled(ref)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(myActiveBoostProvider).valueOrNull;
    final live = active != null && active.endsAt != null;
    // Only asked for when no boost is live.
    final last = live ? null : ref.watch(myLastBoostProvider).valueOrNull;
    final title = live
        ? l10n.boostActiveTitle
        : last != null
            ? l10n.boostAgain
            : l10n.boostTitle;
    final subtitle = live
        ? '${l10n.boostTimeLeft(formatBoostRemaining(l10n, active.endsAt!.difference(DateTime.now())))}'
            ' · ${l10n.boostSeenBy(active.impressions)}'
        : last != null
            ? l10n.boostLastResult(last.impressions)
            : l10n.boostSubtitle;

    return Padding(
      padding: margin,
      child: Material(
        color: AppColors.matchAccent.withValues(alpha: live ? 0.35 : 0.22),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: const Key('boost-entry-row'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => openBoostScreen(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.rocket_launch_rounded,
                    size: 20, color: Color(0xFFFFB300)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: context.labelLarge
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.bodySmall
                              .copyWith(color: context.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
