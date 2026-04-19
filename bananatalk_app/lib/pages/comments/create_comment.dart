import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bananatalk_app/pages/chat/gif_picker_panel.dart';
import 'package:bananatalk_app/services/giphy_service.dart';
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

/// A simple data class to represent a mention within a comment.
class CommentMention {
  final String userId;
  final String username;

  const CommentMention({required this.userId, required this.username});
}

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

  // Mention state
  List<CommentMention> _mentions = [];
  bool _showMentionOverlay = false;
  String _mentionQuery = '';
  List<dynamic> _mentionSuggestions = [];

  // Media state
  File? _selectedImage;
  String? _selectedGifUrl;

  // -------------------------------------------------------------------------
  // GIF picker
  // -------------------------------------------------------------------------

  void _openGifPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: GifPickerPanel(
          onGifSelected: (GiphyGif gif) {
            Navigator.pop(context);
            setState(() {
              _selectedGifUrl = gif.originalUrl;
              _selectedImage = null;
            });
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Image picker
  // -------------------------------------------------------------------------

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _selectedGifUrl = null;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  Future<void> submitComment() async {
    String commentText = commentController.text.trim();
    final bool hasMedia = _selectedImage != null || _selectedGifUrl != null;
    if (commentText.isEmpty && !hasMedia) return;

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
      // Create the comment (or reply), passing GIF URL if set
      // Backend requires text - use space if only media is sent
      final textToSend = commentText.isNotEmpty ? commentText : ' ';
      await ref.read(commentsServiceProvider).createComment(
        title: textToSend,
        id: widget.id,
        parentCommentId: widget.parentCommentId,
        imageUrl: _selectedGifUrl,
      );

      // Clear reply state after successful submission
      widget.onCancelReply?.call();

      // Clear the text field and media after successful submission
      commentController.clear();
      setState(() {
        _selectedImage = null;
        _selectedGifUrl = null;
        _mentions = [];
      });

      // Refresh comments list to show the new comment
      ref.invalidate(commentsProvider(widget.id));

      // Refresh the moment to update comment count
      ref.invalidate(momentsFeedProvider);

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

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

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

        // Image / GIF preview
        if (_selectedImage != null || _selectedGifUrl != null)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            color: colorScheme.surfaceContainerHighest,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, height: 80, width: 80, fit: BoxFit.cover)
                      : CachedNetworkImage(
                          imageUrl: _selectedGifUrl!,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedImage = null;
                      _selectedGifUrl = null;
                    }),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Input bar
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
              // Text field
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

              // Camera button
              IconButton(
                icon: Icon(Icons.camera_alt_outlined, size: 20, color: context.textMuted),
                onPressed: _pickImage,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),

              // GIF button
              IconButton(
                icon: Icon(Icons.gif_box_outlined, size: 20, color: context.textMuted),
                onPressed: _openGifPicker,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),

              // Send button — evaluated on every build so media-only comments
              // activate the button even when the text field is empty.
              Builder(
                builder: (context) {
                  final hasContent = commentController.text.trim().isNotEmpty ||
                      _selectedImage != null ||
                      _selectedGifUrl != null;
                  return Container(
                    decoration: BoxDecoration(
                      color: hasContent
                          ? AppColors.primary
                          : colorScheme.outlineVariant,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: AppColors.white),
                      onPressed: hasContent ? submitComment : null,
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
