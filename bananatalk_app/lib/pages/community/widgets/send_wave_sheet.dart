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
      final isRateLimited = e.toString().toLowerCase().contains(
        'too many waves',
      );
      showCommunitySnackBar(
        context,
        message: isRateLimited
            ? l10n.waveCooldown(widget.targetUserName, '24h')
            : l10n.waveCouldntSend,
        type: CommunitySnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSend =
        !_isSending &&
        (_selectedQuickReply != null ||
            _customController.text.trim().isNotEmpty);
    return CommunityDialogScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.sendWaveTo(widget.targetUserName),
            style: context.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _quickReplies(l10n)
                .map(
                  (reply) => ChoiceChip(
                    label: Text(reply),
                    selected: _selectedQuickReply == reply,
                    onSelected: (selected) => setState(() {
                      _selectedQuickReply = selected ? reply : null;
                      _customController.clear();
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customController,
            onChanged: (_) => setState(() => _selectedQuickReply = null),
            decoration: InputDecoration(
              hintText: l10n.waveCustomMessage,
              border: OutlineInputBorder(borderRadius: AppRadius.borderMD),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: canSend ? _send : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(_isSending ? '…' : l10n.sendWave),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
