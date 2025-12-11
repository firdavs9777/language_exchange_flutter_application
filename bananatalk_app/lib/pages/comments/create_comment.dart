import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:bananatalk_app/utils/api_error_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class CreateComment extends ConsumerStatefulWidget {
  final FocusNode focusNode;
  final String id;
  final VoidCallback onCommentAdded; // Callback when a comment is added

  const CreateComment({
    super.key,
    required this.id,
    required this.focusNode,
    required this.onCommentAdded, // Pass the callback here
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
      print('Error checking limits: $e');
    }

    try {
      // Create the comment
      await ref.read(commentsServiceProvider).createComment(
        title: commentText,
        id: widget.id,
      );

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
        print('Error refreshing limits: $e');
      }

      // Call the callback to update comment count in parent
      widget.onCommentAdded();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Comment added successfully'),
          duration: const Duration(seconds: 1),
          backgroundColor: colorScheme.primary,
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
          print('Error handling limit error: $err');
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: ${e.toString().replaceFirst('Exception: ', '')}'),
            duration: const Duration(seconds: 3),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryText = context.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.onSurface.withOpacity(0.15),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      commentController.text = value;
                    });
                  },
                  focusNode: widget.focusNode,
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: commentController,
            builder: (context, value, child) {
              final hasText = value.text.trim().isNotEmpty;
              return Container(
                decoration: BoxDecoration(
                  color: hasText 
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.send, color: colorScheme.onPrimary),
                  onPressed: hasText ? submitComment : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
