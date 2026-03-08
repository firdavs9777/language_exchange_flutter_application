// lib/widgets/forwarded_message_indicator.dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

/// Indicator shown above forwarded messages
class ForwardedMessageIndicator extends StatelessWidget {
  final ForwardedMessage? forwardedFrom;
  final bool isMe;

  const ForwardedMessageIndicator({
    super.key,
    required this.forwardedFrom,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    if (forwardedFrom == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get sender name from forwarded message
    String senderName = 'Unknown';
    if (forwardedFrom!.sender is Map) {
      senderName = (forwardedFrom!.sender as Map)['name']?.toString() ?? 'Unknown';
    } else if (forwardedFrom!.sender is String) {
      senderName = forwardedFrom!.sender.toString();
    }

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 0 : 8,
        right: isMe ? 8 : 0,
        bottom: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.reply_rounded,
            size: 14,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            'Forwarded from $senderName',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
