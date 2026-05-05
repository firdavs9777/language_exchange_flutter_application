import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Generic empty-state widget for chat screens. Centered icon + title +
/// optional body + optional CTA button. Theme-aware.
class ChatEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final Widget? cta;
  final EdgeInsetsGeometry padding;

  const ChatEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.cta,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 44,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: context.bodyMedium.copyWith(
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            if (cta != null) ...[
              const SizedBox(height: 20),
              cta!,
            ],
          ],
        ),
      ),
    );
  }
}
