import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/community/widgets/community_dialog_scaffold.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/pages/community/widgets/mutual_wave_dialog.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

// Key prefix kept from the original 24h-cooldown design — the name is now a
// misnomer since "one wave per user pair, ever" replaced the 24h cooldown,
// but reusing it means existing SharedPreferences entries on upgraded
// installs still read as "already sent" rather than resetting everyone's
// wave history to unsent. Readers (community_card_actions.dart,
// single_community_actions.dart) now treat *presence* of the key as a
// permanent flag rather than checking elapsed time against it.
const waveCooldownPrefsPrefix = 'wave_cooldown_';

/// Permanently marks [targetUserId] as already-waved-at by the current user.
/// Shared by the send flow (on success) and the 400/ALREADY_WAVED error path
/// (to self-heal local state when the backend says it happened previously,
/// e.g. after a reinstall or a second device).
Future<void> _markAlreadyWaved(String targetUserId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(
    '$waveCooldownPrefsPrefix$targetUserId',
    DateTime.now().millisecondsSinceEpoch,
  );
}

Future<void> showSendWaveSheet(
  BuildContext context, {
  required String targetUserId,
  required String targetUserName,
  String? targetUserCountry,
  VoidCallback? onSent,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _SendWaveSheet(
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      targetUserCountry: targetUserCountry,
      onSent: onSent,
    ),
  );
}

class _SendWaveSheet extends ConsumerStatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserCountry;
  final VoidCallback? onSent;

  const _SendWaveSheet({
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserCountry,
    this.onSent,
  });

  @override
  ConsumerState<_SendWaveSheet> createState() => _SendWaveSheetState();
}

// Icebreaker prompts shown above the message field to help start a
// conversation. No l10n keys exist yet for these strings (checked
// app_en.arb — only waveQuickReply* short replies are localized), and the
// sheet only receives targetUserName/targetUserCountry (no language info),
// so these stay generic/English for now.
// TODO: l10n batch — add icebreaker strings to app_en.arb + translations.
const List<String> _icebreakerPrompts = [
  'What made you start learning a new language?',
  'Hi! I can help you practice 😊',
  "What's your favorite word in your language?",
  'Coffee-break chat sometime?',
  "How's your week going?",
];

class _SendWaveSheetState extends ConsumerState<_SendWaveSheet> {
  final TextEditingController _customController = TextEditingController();
  String? _selectedQuickReply;
  bool _isSending = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _applyIcebreaker(String prompt) {
    setState(() {
      _selectedQuickReply = null;
      _customController.text = prompt;
      _customController.selection = TextSelection.fromPosition(
        TextPosition(offset: _customController.text.length),
      );
    });
  }

  List<String> _quickReplies(AppLocalizations l10n) => [
    '👋 ${l10n.waveQuickReplyHi}',
    '❤️ ${l10n.waveQuickReplyCool}',
    '😊 ${l10n.waveQuickReplyHey}',
    '🎉 ${l10n.waveQuickReplyChat}',
    '✋ ${l10n.waveQuickReplyHello}',
    if (widget.targetUserCountry != null &&
        widget.targetUserCountry!.isNotEmpty)
      '🌟 ${l10n.waveQuickReplyFromCountry(widget.targetUserCountry!)}',
  ];

  Future<void> _send() async {
    if (_isSending) return;
    final l10n = AppLocalizations.of(context)!;
    final message = _customController.text.trim().isNotEmpty
        ? _customController.text.trim()
        : (_selectedQuickReply ?? '👋');
    setState(() => _isSending = true);
    try {
      final response = await ref
          .read(communityServiceProvider)
          .sendWave(targetUserId: widget.targetUserId, message: message);
      // Permanently mark this user as already-waved locally (one wave per
      // user pair, ever — backend is authoritative via ALREADY_WAVED/400).
      // The stored value itself (a timestamp) is no longer used for expiry;
      // readers now treat *presence* of the key as a permanent flag.
      await _markAlreadyWaved(widget.targetUserId);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSent?.call();
      if (response.isMutual) {
        showMutualWaveDialog(
          context,
          name: widget.targetUserName,
          targetUserId: widget.targetUserId,
        );
      } else {
        showCommunitySnackBar(
          context,
          message: l10n.waveSent(widget.targetUserName),
          type: CommunitySnackBarType.success,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      final raw = e.toString();
      final lower = raw.toLowerCase();
      // "Too many waves" is the legacy 429 rate-limit text (unrelated to the
      // one-wave-per-pair rule; kept for safety in case that path is ever
      // reintroduced upstream). "Already waved" now comes from the
      // permanent ALREADY_WAVED/400 — one wave per user pair, ever. Once we
      // see it, self-heal local state so the button greys out immediately
      // even if the local flag was missing (e.g. reinstall, second device).
      final isRateLimited = lower.contains('too many waves');
      final isAlreadyWaved = lower.contains('already waved');
      if (isAlreadyWaved) {
        await _markAlreadyWaved(widget.targetUserId);
        if (!mounted) return;
      }
      // Surface the backend's actual error string when available so the
      // user knows *why* it failed (e.g. "Cannot wave at yourself",
      // "Cannot wave to this user", "User not found", or the permanent
      // ALREADY_WAVED message). Fall back to the localized generic only if
      // the exception message is empty/useless.
      final backendMessage = raw.replaceFirst('Exception: ', '').trim();
      final fallback = l10n.waveCouldntSend;
      showCommunitySnackBar(
        context,
        message: isRateLimited
            ? l10n.waveCooldown(widget.targetUserName, '24h')
            : (backendMessage.isEmpty || backendMessage == 'Failed to send wave'
                  ? fallback
                  : backendMessage),
        type: CommunitySnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Always allow sending while not in-flight; _send() falls back to a
    // friendly '👋' when neither a quick reply nor custom text is set.
    final canSend = !_isSending;
    // Keyboard inset — push the sheet up so the Send button + custom
    // message field stay visible when the keyboard appears.
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: CommunityDialogScaffold(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle — uses textMuted with extra alpha so it's
              // visible on both light surface and dark surface backgrounds.
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: context.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.sendWaveTo(widget.targetUserName),
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _quickReplies(l10n).map((reply) {
                  final selected = _selectedQuickReply == reply;
                  return ChoiceChip(
                    label: Text(reply),
                    selected: selected,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : context.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: context.containerColor,
                    selectedColor: AppColors.primary,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary
                          : context.dividerColor,
                    ),
                    onSelected: (sel) => setState(() {
                      _selectedQuickReply = sel ? reply : null;
                      _customController.clear();
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _icebreakerPrompts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final prompt = _icebreakerPrompts[index];
                    return ActionChip(
                      label: Text(prompt),
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.transparent,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => _applyIcebreaker(prompt),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customController,
                onChanged: (_) => setState(() => _selectedQuickReply = null),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (canSend) _send();
                },
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.waveCustomMessage,
                  hintStyle: TextStyle(color: context.textMuted),
                  filled: true,
                  fillColor: context.containerColor,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.borderMD,
                    borderSide: BorderSide(color: context.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderMD,
                    borderSide: BorderSide(color: context.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderMD,
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: canSend ? _send : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderMD,
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          l10n.sendWave,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
