import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/conversation_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class MuteDialog extends StatefulWidget {
  final String conversationId;
  final String userName;
  final bool isMuted;
  final VoidCallback? onMuteChanged;

  const MuteDialog({
    Key? key,
    required this.conversationId,
    required this.userName,
    this.isMuted = false,
    this.onMuteChanged,
  }) : super(key: key);

  /// Show the mute dialog
  static Future<bool?> show({
    required BuildContext context,
    required String conversationId,
    required String userName,
    bool isMuted = false,
    VoidCallback? onMuteChanged,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => MuteDialog(
        conversationId: conversationId,
        userName: userName,
        isMuted: isMuted,
        onMuteChanged: onMuteChanged,
      ),
    );
  }

  @override
  State<MuteDialog> createState() => _MuteDialogState();
}

class _MuteDialogState extends State<MuteDialog> {
  final ConversationService _conversationService = ConversationService();
  bool _isLoading = false;
  String? _selectedDuration;

  // Duration options in milliseconds
  final Map<String, int?> _durationOptions = {
    '1 hour': 1 * 60 * 60 * 1000,
    '8 hours': 8 * 60 * 60 * 1000,
    '1 week': 7 * 24 * 60 * 60 * 1000,
    'Always': null, // Permanent mute
  };

  Future<void> _handleMute() async {
    if (_selectedDuration == null && !widget.isMuted) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (widget.isMuted) {
        // Unmute the conversation
        result = await _conversationService.unmuteConversation(
          conversationId: widget.conversationId,
        );
      } else {
        // Mute the conversation with selected duration
        result = await _conversationService.muteConversation(
          conversationId: widget.conversationId,
          duration: _durationOptions[_selectedDuration],
        );
      }

      if (mounted) {
        if (result['success'] == true) {
          widget.onMuteChanged?.call();
          Navigator.of(context).pop(true);
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isMuted
                    ? l10n.notificationsUnmutedFor(widget.userName)
                    : l10n.notificationsMutedFor(widget.userName),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? l10n.failedToUpdateMuteSettings),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMuted) {
      return _buildUnmuteDialog();
    }
    return _buildMuteDialog();
  }

  Widget _buildUnmuteDialog() {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.unmuteUser(widget.userName)),
      content: Text(l10n.willReceiveNotifications),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleMute,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.unmute),
        ),
      ],
    );
  }

  Widget _buildMuteDialog() {
    final l10n = AppLocalizations.of(context)!;
    final durationLabels = {
      '1 hour': l10n.oneHour,
      '8 hours': l10n.eightHours,
      '1 week': l10n.oneWeek,
      'Always': l10n.always,
    };
    return AlertDialog(
      title: Text(l10n.muteNotifications),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.muteNotificationsFor(widget.userName),
            style: TextStyle(color: Colors.grey[600]),
          ),
          Spacing.gapMD,
          ..._durationOptions.keys.map((duration) => RadioListTile<String>(
                title: Text(durationLabels[duration] ?? duration),
                value: duration,
                groupValue: _selectedDuration,
                onChanged: (value) {
                  setState(() => _selectedDuration = value);
                },
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedDuration == null ? null : _handleMute,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.mute),
        ),
      ],
    );
  }
}

