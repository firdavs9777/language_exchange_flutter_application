import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class CommunityEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const CommunityEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: context.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: context.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: context.bodySmall.copyWith(color: context.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
