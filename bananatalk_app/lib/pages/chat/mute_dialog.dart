import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/conversation_service.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isMuted
                    ? 'Notifications unmuted for ${widget.userName}'
                    : 'Notifications muted for ${widget.userName}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to update mute settings'),
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
    return AlertDialog(
      title: Text('Unmute ${widget.userName}?'),
      content: const Text('You will receive notifications for new messages.'),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleMute,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Unmute'),
        ),
      ],
    );
  }

  Widget _buildMuteDialog() {
    return AlertDialog(
      title: const Text('Mute notifications'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mute notifications for ${widget.userName}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ..._durationOptions.keys.map((duration) => RadioListTile<String>(
                title: Text(duration),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedDuration == null ? null : _handleMute,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Mute'),
        ),
      ],
    );
  }
}

