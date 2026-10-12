import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/guide_store.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Which message (if any) holds the tip this app run. A plain object, not
/// state: claiming happens during build, where a provider write is refused,
/// and nothing needs to rebuild when it changes. User-scoped.
class ChatTipClaim {
  String? messageId;

  /// True for the first id ever offered this run, and for it only.
  bool claim(String id) {
    messageId ??= id;
    return messageId == id;
  }
}

final chatTipClaimProvider = Provider<ChatTipClaim>((ref) => ChatTipClaim());

/// "Long-press to translate or correct" under the first received text
/// message the user sees during the guide period (spec §3.3). Once ever.
class ChatTipRow extends ConsumerWidget {
  const ChatTipRow({super.key, required this.messageId});

  final String messageId;

  static const _surface = GuideSurface.chatTip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cheapest check first: another bubble already holds the tip, so this
    // one never subscribes to anything.
    final holder = ref.read(chatTipClaimProvider).messageId;
    if (holder != null && holder != messageId) return const SizedBox.shrink();

    // Fail closed: loading, error (even one carrying a stale value) and
    // storage-unreadable all mean "no tip".
    final periodAsync = ref.watch(isGuidePeriodProvider);
    final period = !periodAsync.isLoading &&
        !periodAsync.hasError &&
        periodAsync.hasValue &&
        periodAsync.value == true;
    if (!period) return const SizedBox.shrink();
    final stateAsync = ref.watch(guideStateProvider(_surface));
    final acted = stateAsync.isLoading ||
        stateAsync.hasError ||
        !stateAsync.hasValue ||
        stateAsync.value!.acted;
    if (acted) return const SizedBox.shrink();
    if (!ref.read(chatTipClaimProvider).claim(messageId)) {
      return const SizedBox.shrink();
    }
    _recordShownAfterFrame(ref);

    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 52, right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l10n.guideChatTip,
              style: TextStyle(fontSize: 12.5, color: context.textSecondary),
            ),
          ),
          const SizedBox(width: 4),
          InkResponse(
            key: const Key('chat_tip_dismiss'),
            radius: 16,
            onTap: () => retireChatTip(ref, target: 'dismiss'),
            child: Semantics(
              label: MaterialLocalizations.of(context).closeButtonTooltip,
              button: true,
              child: Icon(Icons.close_rounded,
                  size: 16, color: context.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _recordShownAfterFrame(WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final latch = ref.read(guideRecordedProvider(_surface).notifier);
      if (latch.state) return;
      latch.state = true;
      final s = await GuideStore.read(_surface);
      AnalyticsService.instance
          .guideShown(surface: _surface.slug, timesShown: s.timesShown + 1);
      await GuideStore.recordShown(_surface);
    });
  }
}

/// Retires the tip: the first context menu on any message (target
/// 'primary') or its ✕ ('dismiss'). The tap is logged only if the tip was
/// actually on screen this run.
Future<void> retireChatTip(WidgetRef ref, {required String target}) async {
  const surface = GuideSurface.chatTip;
  final state = ref.read(guideStateProvider(surface)).valueOrNull;
  if (state == null || state.acted) return;
  if (ref.read(chatTipClaimProvider).messageId != null) {
    AnalyticsService.instance
        .guideCtaTapped(surface: surface.slug, target: target);
  }
  await GuideStore.markActed(surface);
  ref.invalidate(guideStateProvider(surface));
}
