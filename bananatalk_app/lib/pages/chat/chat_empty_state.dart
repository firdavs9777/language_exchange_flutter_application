import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class ChatEmptyState extends StatelessWidget {
  final String userName;

  const ChatEmptyState({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.accent.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.borderRound,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: context.textSecondary,
            ),
          ),
          Spacing.gapXXL,
          Text(
            'No messages yet',
            style: context.displaySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
          Spacing.gapMD,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Send a message to start the conversation with $userName',
              style: context.bodyMedium.copyWith(
                color: context.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Spacing.gapXXL,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              borderRadius: AppRadius.borderXL,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Say hello!',
              style: context.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
