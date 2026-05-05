import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Empty state shown inside a 1:1 conversation when there are no messages
/// yet — invites the user to send a wave to break the ice. Distinct from
/// the generic `widgets/chat_empty_state.dart` (which is used for chat-list
/// / search / bookmarks empty states).
class ConversationEmptyState extends StatelessWidget {
  final String userName;
  final VoidCallback? onSendWave;

  const ConversationEmptyState({
    super.key,
    required this.userName,
    this.onSendWave,
  });

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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSendWave,
              borderRadius: AppRadius.borderXL,
              splashColor: AppColors.primary.withValues(alpha: 0.2),
              highlightColor: AppColors.primary.withValues(alpha: 0.1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  borderRadius: AppRadius.borderXL,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '👋',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tap to say hi!',
                      style: context.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
