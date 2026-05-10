import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Shared bubble shell: rounded shape + shadow + background colour.
///
/// NOTE: This file is scaffolding for C13, which will apply M3 polish and
/// replace the inline container decorations currently in [TextMessageView],
/// [ImageMessageView], etc. It is NOT yet used by any existing widget —
/// the existing inline containers are left unchanged to avoid a restyle in
/// this commit.
class BubbleContainer extends StatelessWidget {
  final Widget child;
  final bool isMe;
  final EdgeInsetsGeometry padding;

  const BubbleContainer({
    super.key,
    required this.child,
    required this.isMe,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? AppColors.primary : context.containerColor;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
