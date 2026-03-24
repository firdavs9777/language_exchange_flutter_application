import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:bananatalk_app/utils/api_error_handler.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class CreateComment extends ConsumerStatefulWidget {
  final FocusNode focusNode;
  final String id;
  final VoidCallback onCommentAdded;
  final String? parentCommentId;
  final String? replyToUserName;
  final VoidCallback? onCancelReply;

  const CreateComment({
    super.key,
    required this.id,
    required this.focusNode,
    required this.onCommentAdded,
    this.parentCommentId,
    this.replyToUserName,
    this.onCancelReply,
  });

  @override
  ConsumerState<CreateComment> createState() => _CreateCommentState();
}

class _CreateCommentState extends ConsumerState<CreateComment> {
  TextEditingController commentController = TextEditingController();
  Future<void> submitComment() async {
    String commentText = commentController.text.trim();
    if (commentText.isEmpty) return;
    final colorScheme = Theme.of(context).colorScheme;

    // Check limits before submitting
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null) {
        final userAsync = ref.read(userProvider);
        final user = await userAsync;
        final limits = ref.read(currentUserLimitsProvider(userId));

        if (!FeatureGate.canCreateComment(user, limits)) {
          await LimitExceededDialog.show(
            context: context,
            limitType: 'comments',
            limitInfo: limits?.comments,
            resetTime: limits?.resetTime,
            userId: userId,
          );
          return;
        }
      }
    } catch (e) {
      // If limit check fails, allow submitting (fail open)
    }

    try {
      // Create the comment (or reply)
      await ref.read(commentsServiceProvider).createComment(
        title: commentText,
        id: widget.id,
        parentCommentId: widget.parentCommentId,
      );

      // Clear reply state after successful submission
      widget.onCancelReply?.call();

      // Clear the text field after successful submission
      commentController.clear();

      // Refresh comments list to show the new comment
      ref.invalidate(commentsProvider(widget.id));

      // Refresh the moment to update comment count
      ref.invalidate(momentsServiceProvider);

      // Refresh limits after successful creation
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        if (userId != null) {
          ref.refresh(userLimitsProvider(userId));
        }
      } catch (e) {
      }

      // Call the callback to update comment count in parent
      widget.onCommentAdded();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.commentAddedSuccessfully),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      // Handle 429 errors
      if (e.toString().contains('429') ||
          ApiErrorHandler.isLimitExceededError(e)) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('userId');
          await ApiErrorHandler.handleLimitExceededError(
            context: context,
            error: e,
            userId: userId,
          );
        } catch (err) {
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: ${e.toString().replaceFirst('Exception: ', '')}'),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reply indicator
        if (widget.parentCommentId != null && widget.replyToUserName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.reply, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.replyingTo(widget.replyToUserName ?? ''),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onCancelReply,
                  child: Icon(Icons.close, size: 18, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: widget.parentCommentId == null
              ? BorderSide(color: colorScheme.outlineVariant)
              : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: AppRadius.borderXL,
                boxShadow: AppShadows.sm,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      commentController.text = value;
                    });
                  },
                  focusNode: widget.focusNode,
                  controller: commentController,
                  style: context.bodyMedium,
                  decoration: InputDecoration(
                    hintText: widget.parentCommentId != null
                        ? '${AppLocalizations.of(context)!.reply}...'
                        : AppLocalizations.of(context)!.writeAComment,
                    hintStyle: context.bodyMedium.copyWith(color: context.textHint),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
          Spacing.hGapMD,
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: commentController,
            builder: (context, value, child) {
              final hasText = value.text.trim().isNotEmpty;
              return Container(
                decoration: BoxDecoration(
                  color: hasText
                      ? AppColors.primary
                      : colorScheme.outlineVariant,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.send, color: AppColors.white),
                  onPressed: hasText ? submitComment : null,
                ),
              );
            },
          ),
        ],
      ),
    ),
      ],
    );
  }
}
