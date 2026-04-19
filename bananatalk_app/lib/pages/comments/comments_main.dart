import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/services/moments_service.dart' as api;
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/translated_comment_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

class CommentsMain extends ConsumerStatefulWidget {
  const CommentsMain({Key? key, required this.id, this.onReply}) : super(key: key);

  final String id;
  final Function(String commentId, String userName)? onReply;

  @override
  ConsumerState<CommentsMain> createState() => _CommentsMainState();
}

class _CommentsMainState extends ConsumerState<CommentsMain> {
  @override
  Widget build(BuildContext context) {
    final commentsAsyncValue = ref.watch(commentsProvider(widget.id));
    final currentUserId = ref.read(authServiceProvider).userId;

    return commentsAsyncValue.when(
      data: (comments) {
        if (comments.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: context.textHint),
                  const SizedBox(height: 12),
                  Text(l10n.beTheFirstToComment, style: context.bodyMedium.copyWith(color: context.textSecondary)),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...comments.map(
              (comment) => _CommentItem(
                comment: comment,
                momentId: widget.id,
                currentUserId: currentUserId,
                onRefresh: () => ref.invalidate(commentsProvider(widget.id)),
                onReply: widget.onReply,
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Error: $error',
            style: context.bodySmall.copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

/// Individual comment item with like, edit, delete, reply support
class _CommentItem extends StatefulWidget {
  final dynamic comment;
  final String momentId;
  final String? currentUserId;
  final VoidCallback onRefresh;
  final Function(String commentId, String userName)? onReply;

  const _CommentItem({
    required this.comment,
    required this.momentId,
    required this.currentUserId,
    required this.onRefresh,
    this.onReply,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _showReplies = false;
  List<dynamic> _replies = [];
  bool _loadingReplies = false;
  late AnimationController _replyAnimController;
  late Animation<double> _replyAnimation;

  @override
  void initState() {
    super.initState();
    _replyAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _replyAnimation = CurvedAnimation(
      parent: _replyAnimController,
      curve: Curves.easeInOut,
    );
    try {
      final likedUsers = widget.comment.likedUsers;
      if (widget.currentUserId != null) {
        _isLiked = likedUsers.contains(widget.currentUserId);
      }
      _likeCount = widget.comment.likeCount;
      debugPrint('💬❤️ CommentItem init: commentId=${widget.comment.id}, userId=${widget.currentUserId}, isLiked=$_isLiked, likeCount=$_likeCount, likedUsers=$likedUsers');
    } catch (e) {
      debugPrint('💬❤️ CommentItem init ERROR: $e');
      _isLiked = false;
      _likeCount = 0;
    }
  }

  @override
  void didUpdateWidget(covariant _CommentItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync like state when comment data changes (e.g. after provider refresh)
    try {
      final likedUsers = widget.comment.likedUsers;
      if (widget.currentUserId != null) {
        _isLiked = likedUsers.contains(widget.currentUserId);
      }
      _likeCount = widget.comment.likeCount;
    } catch (_) {}

    // Reload replies if they were showing
    if (_showReplies) {
      _loadReplies();
    }
  }

  @override
  void dispose() {
    _replyAnimController.dispose();
    super.dispose();
  }

  bool get _isOwnComment => widget.currentUserId == widget.comment.user.id;

  bool _safeIsEdited(dynamic comment) {
    try {
      return comment.isEdited == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _toggleLike() async {
    final previousLiked = _isLiked;
    final previousCount = _likeCount;

    debugPrint('💬❤️ Comment toggleLike: commentId=${widget.comment.id}, wasLiked=$previousLiked, prevCount=$previousCount');

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    final result = await api.MomentsService.likeComment(
      momentId: widget.momentId,
      commentId: widget.comment.id,
    );

    debugPrint('💬❤️ Comment like result: $result');

    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _isLiked = result['isLiked'] ?? !previousLiked;
          _likeCount = result['likeCount'] ?? previousCount;
        });
        debugPrint('💬❤️ Comment updated: isLiked=$_isLiked, likeCount=$_likeCount');
        // Refresh comments so likedUsers list is updated from backend
        widget.onRefresh();
      }
    } else {
      debugPrint('💬❤️ Comment like FAILED: ${result['error']}');
      if (mounted) {
        setState(() {
          _isLiked = previousLiked;
          _likeCount = previousCount;
        });
      }
    }
  }

  Future<void> _editComment() async {
    final controller = TextEditingController(text: widget.comment.text);
    final l10n = AppLocalizations.of(context)!;

    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.edit),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: l10n.writeAComment,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (newText != null && newText.isNotEmpty && newText != widget.comment.text) {
      final result = await api.MomentsService.editComment(
        momentId: widget.momentId,
        commentId: widget.comment.id,
        text: newText,
      );
      if (result['success'] == true) {
        widget.onRefresh();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? AppLocalizations.of(context)!.failedToSave),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteComment),
        content: Text(l10n.thisActionCannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await api.MomentsService.deleteComment(
        momentId: widget.momentId,
        commentId: widget.comment.id,
      );
      if (result['success'] == true) {
        widget.onRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.commentDeleted),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? AppLocalizations.of(context)!.failedToSave),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadReplies() async {
    if (_loadingReplies) return;
    setState(() => _loadingReplies = true);

    final result = await api.MomentsService.getReplies(
      momentId: widget.momentId,
      commentId: widget.comment.id,
    );

    if (mounted) {
      setState(() {
        _loadingReplies = false;
        if (result['success'] == true) {
          _replies = result['data'] ?? [];
          _showReplies = true;
          _replyAnimController.forward();
        }
      });
    }
  }

  void _hideReplies() {
    _replyAnimController.reverse().then((_) {
      if (mounted) {
        setState(() => _showReplies = false);
      }
    });
  }

  void _onReplyAdded() {
    // Reload replies after a new reply is added
    _loadReplies();
    widget.onRefresh();
  }

  String _getRelativeTime(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return l10n.now;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return l10n.weeksAgo((diff.inDays / 7).floor());
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final colorScheme = Theme.of(context).colorScheme;
    int replyCount;
    try {
      replyCount = comment.replyCount;
    } catch (_) {
      replyCount = 0;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              GestureDetector(
                onTap: () => _navigateToProfile(context, comment.user.id),
                child: CachedCircleAvatar(
                  imageUrl: comment.user.imageUrls.isNotEmpty
                      ? comment.user.imageUrls[0]
                      : null,
                  radius: 18,
                  backgroundColor: colorScheme.primaryContainer,
                  errorWidget: Icon(Icons.person, size: 18, color: colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comment bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + time
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _navigateToProfile(context, comment.user.id),
                                child: Text(
                                  comment.user.name ?? '',
                                  style: context.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getRelativeTime(context, comment.createdAt ?? DateTime.now()),
                                style: context.captionSmall.copyWith(color: context.textMuted),
                              ),
                              if (_safeIsEdited(comment)) ...[
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.edited,
                                  style: context.captionSmall.copyWith(
                                    color: context.textMuted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Comment text
                          TranslatedCommentWidget(
                            commentId: comment.id,
                            originalText: comment.text.toString(),
                            originalLanguage: comment.user.native_language,
                            existingTranslations: comment.translations.isNotEmpty
                                ? comment.translations
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Action row: Like, Reply, More
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          // Like button
                          _ActionButton(
                            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                            label: _likeCount > 0 ? '$_likeCount' : null,
                            color: _isLiked ? AppColors.error : context.textMuted,
                            onTap: _toggleLike,
                          ),
                          const SizedBox(width: 16),
                          // Reply button
                          _ActionButton(
                            icon: Icons.reply,
                            label: AppLocalizations.of(context)!.reply,
                            color: context.textSecondary,
                            onTap: () {
                              widget.onReply?.call(comment.id, comment.user.name ?? '');
                            },
                          ),
                          const Spacer(),
                          // More options
                          _buildMoreOptions(context, comment),
                        ],
                      ),
                    ),
                    // Show replies toggle
                    if (replyCount > 0 && !_showReplies)
                      GestureDetector(
                        onTap: _loadReplies,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4, bottom: 4),
                          child: _loadingReplies
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 1,
                                      color: context.textMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!.viewRepliesCount(replyCount),
                                      style: context.captionSmall.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    // Replies list with animation
                    if (_showReplies && _replies.isNotEmpty)
                      FadeTransition(
                        opacity: _replyAnimation,
                        child: SizeTransition(
                          sizeFactor: _replyAnimation,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Hide replies button
                                GestureDetector(
                                  onTap: _hideReplies,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 1,
                                          color: context.textMuted,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(context)!.hideReplies,
                                          style: context.captionSmall.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Reply items with thread line
                                ..._replies.map((reply) => _ReplyItem(
                                  reply: reply,
                                  momentId: widget.momentId,
                                  currentUserId: widget.currentUserId,
                                  onRefresh: _onReplyAdded,
                                  onReply: widget.onReply,
                                  parentCommentUserName: comment.user.name ?? '',
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Divider(thickness: 0.5, color: context.dividerColor, height: 16),
        ],
      ),
    );
  }

  Widget _buildMoreOptions(BuildContext context, dynamic comment) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: context.textMuted, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') _editComment();
        if (value == 'delete') _deleteComment();
        if (value == 'report') {
          showDialog(
            context: context,
            builder: (context) => ReportDialog(
              type: 'comment',
              reportedId: comment.id,
              reportedUserId: comment.user.id,
            ),
          );
        }
      },
      itemBuilder: (context) => [
        if (_isOwnComment)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18, color: context.textSecondary),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.edit),
              ],
            ),
          ),
        if (_isOwnComment)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.delete,
                  style: TextStyle(color: AppColors.error),
                ),
              ],
            ),
          ),
        if (!_isOwnComment)
          PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 18, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.report),
              ],
            ),
          ),
      ],
    );
  }

  void _navigateToProfile(BuildContext context, String userId) async {
    final container = ProviderScope.containerOf(context);
    final community = await container.read(communityServiceProvider).getSingleCommunity(id: userId);

    if (community == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.userNotFound)),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => SingleCommunity(community: community),
      ),
    );
  }
}

/// Reply item with full edit/delete/like/reply support
class _ReplyItem extends StatefulWidget {
  final dynamic reply;
  final String momentId;
  final String? currentUserId;
  final VoidCallback onRefresh;
  final Function(String commentId, String userName)? onReply;
  final String parentCommentUserName;

  const _ReplyItem({
    required this.reply,
    required this.momentId,
    required this.currentUserId,
    required this.onRefresh,
    this.onReply,
    required this.parentCommentUserName,
  });

  @override
  State<_ReplyItem> createState() => _ReplyItemState();
}

class _ReplyItemState extends State<_ReplyItem> {
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _initLikeState();
  }

  void _initLikeState() {
    final reply = widget.reply;
    if (reply is Map) {
      final likedUsers = reply['likedUsers'];
      if (likedUsers is List && widget.currentUserId != null) {
        _isLiked = likedUsers.map((e) => e.toString()).contains(widget.currentUserId);
      }
      _likeCount = reply['likeCount'] is int ? reply['likeCount'] : 0;
    } else {
      try {
        final likedUsers = reply.likedUsers;
        if (likedUsers is List && widget.currentUserId != null) {
          _isLiked = likedUsers.contains(widget.currentUserId);
        }
        _likeCount = reply.likeCount ?? 0;
      } catch (_) {
        _isLiked = false;
        _likeCount = 0;
      }
    }
  }

  String get _replyId {
    if (widget.reply is Map) return widget.reply['_id']?.toString() ?? '';
    try {
      return widget.reply.id?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  String get _replyText {
    if (widget.reply is Map) return widget.reply['text']?.toString() ?? '';
    try {
      return widget.reply.text?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  String get _replyUserId {
    if (widget.reply is Map) {
      final user = widget.reply['user'];
      if (user is Map) return user['_id']?.toString() ?? '';
      return user?.toString() ?? '';
    }
    try {
      return widget.reply.user.id?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  String get _replyUserName {
    if (widget.reply is Map) {
      final user = widget.reply['user'];
      if (user is Map) return user['name']?.toString() ?? '';
      return '';
    }
    try {
      return widget.reply.user.name?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  String? get _replyUserImage {
    if (widget.reply is Map) {
      final user = widget.reply['user'];
      if (user is Map) {
        final imageUrls = user['imageUrls'] ?? user['images'] ?? [];
        if (imageUrls is List && imageUrls.isNotEmpty) return imageUrls[0]?.toString();
      }
      return null;
    }
    try {
      final imageUrls = widget.reply.user.imageUrls;
      if (imageUrls is List && imageUrls.isNotEmpty) return imageUrls[0]?.toString();
    } catch (_) {}
    return null;
  }

  DateTime get _replyCreatedAt {
    if (widget.reply is Map) {
      final createdAt = widget.reply['createdAt'];
      if (createdAt is String) return DateTime.tryParse(createdAt) ?? DateTime.now();
      return DateTime.now();
    }
    try {
      return widget.reply.createdAt ?? DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  bool get _isEdited {
    if (widget.reply is Map) return widget.reply['isEdited'] == true;
    try {
      return widget.reply.isEdited == true;
    } catch (_) {
      return false;
    }
  }

  bool get _isOwnReply => widget.currentUserId == _replyUserId;

  String _getRelativeTime(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return l10n.now;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return l10n.weeksAgo((diff.inDays / 7).floor());
  }

  Future<void> _toggleLike() async {
    if (_replyId.isEmpty) return;

    final previousLiked = _isLiked;
    final previousCount = _likeCount;

    debugPrint('💬❤️ Reply toggleLike: replyId=$_replyId, wasLiked=$previousLiked, prevCount=$previousCount');

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    final result = await api.MomentsService.likeComment(
      momentId: widget.momentId,
      commentId: _replyId,
    );

    debugPrint('💬❤️ Reply like result: $result');

    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _isLiked = result['isLiked'] ?? !previousLiked;
          _likeCount = result['likeCount'] ?? previousCount;
        });
        debugPrint('💬❤️ Reply updated: isLiked=$_isLiked, likeCount=$_likeCount');
        // Refresh comments so likedUsers list is updated from backend
        widget.onRefresh();
      }
    } else {
      debugPrint('💬❤️ Reply like FAILED: ${result['error']}');
      if (mounted) {
        setState(() {
          _isLiked = previousLiked;
          _likeCount = previousCount;
        });
      }
    }
  }

  Future<void> _editReply() async {
    if (_replyId.isEmpty) return;
    final controller = TextEditingController(text: _replyText);
    final l10n = AppLocalizations.of(context)!;

    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.edit),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: l10n.writeAComment,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (newText != null && newText.isNotEmpty && newText != _replyText) {
      final result = await api.MomentsService.editComment(
        momentId: widget.momentId,
        commentId: _replyId,
        text: newText,
      );
      if (result['success'] == true) {
        widget.onRefresh();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? l10n.failedToSave),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteReply() async {
    if (_replyId.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteComment),
        content: Text(l10n.thisActionCannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await api.MomentsService.deleteComment(
        momentId: widget.momentId,
        commentId: _replyId,
      );
      if (result['success'] == true) {
        widget.onRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.commentDeleted),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? l10n.failedToSave),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToProfile(BuildContext context, String userId) async {
    if (userId.isEmpty) return;
    final container = ProviderScope.containerOf(context);
    final community = await container.read(communityServiceProvider).getSingleCommunity(id: userId);

    if (community == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.userNotFound)),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => SingleCommunity(community: community),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thread line
            Container(
              width: 2,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            // Avatar
            GestureDetector(
              onTap: () => _navigateToProfile(context, _replyUserId),
              child: CachedCircleAvatar(
                imageUrl: _replyUserImage,
                radius: 14,
                backgroundColor: colorScheme.primaryContainer,
                errorWidget: Icon(Icons.person, size: 14, color: colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 8),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reply bubble
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _navigateToProfile(context, _replyUserId),
                              child: Text(
                                _replyUserName,
                                style: context.labelSmall.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getRelativeTime(context, _replyCreatedAt),
                              style: TextStyle(fontSize: 10, color: context.textMuted),
                            ),
                            if (_isEdited) ...[
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.edited,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: context.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(_replyText, style: context.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Actions row
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        // Like
                        _ActionButton(
                          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                          label: _likeCount > 0 ? '$_likeCount' : null,
                          color: _isLiked ? AppColors.error : context.textMuted,
                          onTap: _toggleLike,
                          small: true,
                        ),
                        const SizedBox(width: 12),
                        // Reply
                        _ActionButton(
                          icon: Icons.reply,
                          label: AppLocalizations.of(context)!.reply,
                          color: context.textSecondary,
                          onTap: () {
                            widget.onReply?.call(
                              // Reply to the parent comment (thread), not the reply itself
                              widget.reply is Map
                                  ? (widget.reply['parentComment']?.toString() ?? _replyId)
                                  : _replyId,
                              _replyUserName,
                            );
                          },
                          small: true,
                        ),
                        const Spacer(),
                        // More options
                        if (_isOwnReply || widget.currentUserId != null)
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz, color: context.textMuted, size: 14),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) {
                              if (value == 'edit') _editReply();
                              if (value == 'delete') _deleteReply();
                              if (value == 'report') {
                                showDialog(
                                  context: context,
                                  builder: (context) => ReportDialog(
                                    type: 'comment',
                                    reportedId: _replyId,
                                    reportedUserId: _replyUserId,
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              if (_isOwnReply)
                                PopupMenuItem(
                                  value: 'edit',
                                  height: 40,
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 16, color: context.textSecondary),
                                      const SizedBox(width: 8),
                                      Text(AppLocalizations.of(context)!.edit, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              if (_isOwnReply)
                                PopupMenuItem(
                                  value: 'delete',
                                  height: 40,
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(context)!.delete,
                                        style: TextStyle(color: AppColors.error, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              if (!_isOwnReply)
                                PopupMenuItem(
                                  value: 'report',
                                  height: 40,
                                  child: Row(
                                    children: [
                                      Icon(Icons.flag_outlined, size: 16, color: AppColors.warning),
                                      const SizedBox(width: 8),
                                      Text(AppLocalizations.of(context)!.report, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable small action button for like/reply
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;
  final bool small;

  const _ActionButton({
    required this.icon,
    this.label,
    required this.color,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = small ? 14.0 : 16.0;
    final fontSize = small ? 11.0 : 12.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: color),
            if (label != null) ...[
              const SizedBox(width: 3),
              Text(
                label!,
                style: TextStyle(
                  fontSize: fontSize,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
