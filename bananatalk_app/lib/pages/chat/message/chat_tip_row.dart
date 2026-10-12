import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/services/analytics_service.dart';
import 'package:bananatalk_app/services/guide_store.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Which message (if any) holds the tip this app run, per conversation. A
/// plain object, not state: claiming happens during build, where a provider
/// write is refused, and nothing needs to rebuild when it changes.
/// User-scoped.
class ChatTipClaim {
  String? chatId;
  String? messageId;

  /// The claimant has been on screen and its shown-record has happened. Until
  /// then the claim is released if the claimant goes away unseen.
  bool shown = false;

  /// Run-level latch: the guide period ended or the tip was acted on, so
  /// every row short-circuits with a read, before any watch.
  bool ineligible = false;

  /// In-memory retire latch, set before the first await in [retireChatTip].
  bool retiring = false;

  /// True if [id] in [chat] holds the claim after this call. The first id
  /// offered in a conversation takes it; a different conversation takes it
  /// over (guide_shown stays once per run via its own latch).
  bool claim(String chat, String id) {
    if (messageId == null || chatId != chat) {
      chatId = chat;
      messageId = id;
      shown = false;
    }
    return messageId == id;
  }

  /// Another bubble in the same conversation already holds the tip.
  bool heldByOther(String chat, String id) =>
      messageId != null && chatId == chat && messageId != id;

  /// Released when the claimant disappears before it was ever shown.
  void release(String chat, String id) {
    if (!shown && chatId == chat && messageId == id) {
      messageId = null;
      chatId = null;
    }
  }
}

final chatTipClaimProvider = Provider<ChatTipClaim>((ref) => ChatTipClaim());

/// "Long-press to translate or correct" under the first received text
/// message the user sees during the guide period (spec §3.3). Once ever.
class ChatTipRow extends ConsumerStatefulWidget {
  const ChatTipRow({super.key, required this.messageId, this.chatId = ''});

  final String messageId;

  /// The conversation (the other user's id). The claim is per conversation.
  final String chatId;

  @override
  ConsumerState<ChatTipRow> createState() => _ChatTipRowState();
}

class _ChatTipRowState extends ConsumerState<ChatTipRow> {
  static const _surface = GuideSurface.chatTip;
  ChatTipClaim? _claim;

  @override
  void dispose() {
    _claim?.release(widget.chatId, widget.messageId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final claim = ref.read(chatTipClaimProvider);
    _claim = claim;
    final messageId = widget.messageId;
    // Cheapest checks first, before any watch: the run is ineligible, or
    // another bubble in this conversation already holds the tip.
    if (claim.ineligible || claim.heldByOther(widget.chatId, messageId)) {
      return const SizedBox.shrink();
    }

    // Fail closed: loading, error (even one carrying a stale value) and
    // storage-unreadable all mean "no tip".
    final periodAsync = ref.watch(isGuidePeriodProvider);
    final period =
        !periodAsync.isLoading &&
        !periodAsync.hasError &&
        periodAsync.hasValue &&
        periodAsync.value == true;
    if (!periodAsync.isLoading &&
        !periodAsync.hasError &&
        periodAsync.hasValue &&
        !period) {
      claim.ineligible = true;
    }
    if (!period) return const SizedBox.shrink();
    final stateAsync = ref.watch(guideStateProvider(_surface));
    final acted =
        stateAsync.isLoading ||
        stateAsync.hasError ||
        !stateAsync.hasValue ||
        stateAsync.value!.acted;
    if (!stateAsync.isLoading &&
        !stateAsync.hasError &&
        stateAsync.hasValue &&
        stateAsync.value!.acted) {
      claim.ineligible = true;
    }
    if (acted) return const SizedBox.shrink();
    if (!claim.claim(widget.chatId, messageId)) {
      return const SizedBox.shrink();
    }
    _recordShownAfterFrame(claim);

    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 52, right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.touch_app_rounded,
            size: 16,
            color: AppColors.primary,
          ),
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
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: context.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _recordShownAfterFrame(ChatTipClaim claim) {
    final chat = widget.chatId;
    final id = widget.messageId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (claim.chatId != chat || claim.messageId != id) return;
      claim.shown = true;
      final latch = ref.read(guideRecordedProvider(_surface).notifier);
      if (latch.state) return;
      latch.state = true;
      final s = await GuideStore.read(_surface);
      AnalyticsService.instance.guideShown(
        surface: _surface.slug,
        timesShown: s.timesShown + 1,
      );
      await GuideStore.recordShown(_surface);
    });
  }
}

/// Retires the tip: the first context menu on any message (target
/// 'primary') or its ✕ ('dismiss'), once per run.
Future<void> retireChatTip(WidgetRef ref, {required String target}) async {
  const surface = GuideSurface.chatTip;
  final claim = ref.read(chatTipClaimProvider);
  // Only a tip that has been offered this run can be retired; a long-press
  // before any tip appeared must not use it up.
  if (claim.messageId == null || claim.retiring) return;
  final state = ref.read(guideStateProvider(surface)).valueOrNull;
  if (state == null || state.acted) return;
  claim.retiring = true;
  claim.ineligible = true;
  AnalyticsService.instance.guideCtaTapped(
    surface: surface.slug,
    target: target,
  );
  await GuideStore.markActed(surface);
  ref.invalidate(guideStateProvider(surface));
}
