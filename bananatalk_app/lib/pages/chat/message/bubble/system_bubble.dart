import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Renders an inline system-style notice — used for unknown / unsupported
/// message types. Extracted from [_FallbackMessageView] in message_bubble.dart.
class SystemBubble extends StatelessWidget {
  final String text;

  const SystemBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.containerColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: context.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: context.bodySmall.copyWith(
              color: context.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
