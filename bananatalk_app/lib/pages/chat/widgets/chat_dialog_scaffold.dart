import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Common dialog shape used by delete / mute / forward / edit / options
/// dialogs in chat. Renders an optional gradient hero icon, a centered
/// title, optional body text or custom content, and an action row.
///
/// Used inside `showDialog(builder: (ctx) => ChatDialogScaffold(...))`.
class ChatDialogScaffold extends StatelessWidget {
  final IconData? heroIcon;
  final Color? heroColor;       // null → uses AppColors.primary
  final String title;
  final String? body;
  final Widget? content;        // when non-null, replaces [body]
  final List<Widget> actions;   // typically [CancelButton, ConfirmButton]
  final CrossAxisAlignment titleAlignment;

  const ChatDialogScaffold({
    super.key,
    required this.title,
    this.heroIcon,
    this.heroColor,
    this.body,
    this.content,
    this.actions = const [],
    this.titleAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final color = heroColor ?? AppColors.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: context.surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (heroIcon != null) ...[
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.78)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(heroIcon, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              textAlign: titleAlignment == CrossAxisAlignment.center
                  ? TextAlign.center
                  : TextAlign.start,
              style: context.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
            if (content != null) ...[
              const SizedBox(height: 12),
              content!,
            ] else if (body != null) ...[
              const SizedBox(height: 10),
              Text(
                body!,
                textAlign: titleAlignment == CrossAxisAlignment.center
                    ? TextAlign.center
                    : TextAlign.start,
                style: context.bodyMedium.copyWith(
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    actions[i],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
