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

const waveCooldownPrefsPrefix = 'wave_cooldown_';

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

class _SendWaveSheetState extends ConsumerState<_SendWaveSheet> {
  final TextEditingController _customController = TextEditingController();
  String? _selectedQuickReply;
  bool _isSending = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
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
      // Cache cooldown locally (24h client-side; backend authoritative)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        '$waveCooldownPrefsPrefix${widget.targetUserId}',
        DateTime.now().millisecondsSinceEpoch,
      );
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
      final isRateLimited = lower.contains('too many waves') ||
          lower.contains('already waved');
      // Surface the backend's actual error string when available so the
      // user knows *why* it failed (e.g. "Cannot wave at yourself",
      // "Cannot wave to this user", "User not found"). Fall back to the
      // localized generic only if the exception message is empty/useless.
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
              TextField(
                controller: _customController,
                onChanged: (_) =>
                    setState(() => _selectedQuickReply = null),
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
