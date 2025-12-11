import 'package:bananatalk_app/pages/comments/comments_main.dart';
import 'package:bananatalk_app/pages/comments/create_comment.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SingleMoment extends ConsumerStatefulWidget {
  final Moments moment;

  const SingleMoment({
    super.key,
    required this.moment,
  });

  @override
  ConsumerState<SingleMoment> createState() => _SingleMomentState();
}

class _SingleMomentState extends ConsumerState<SingleMoment> {
  late bool isLiked;
  late int likeCount;
  late int commentCount;
  bool isSaved = false;
  TextEditingController commentController = TextEditingController();
  bool showCommentField = false;
  final FocusNode commentFocusNode = FocusNode();

  final Map<String, String> _languageFlags = {
    'en': '🇺🇸',
    'es': '🇪🇸',
    'fr': '🇫🇷',
    'de': '🇩🇪',
    'it': '🇮🇹',
    'pt': '🇵🇹',
    'ru': '🇷🇺',
    'ja': '🇯🇵',
    'ko': '🇰🇷',
    'zh': '🇨🇳',
    'ar': '🇸🇦',
    'hi': '🇮🇳',
    'korean': '🇰🇷',
    'english': '🇺🇸',
    'spanish': '🇪🇸',
    'japanese': '🇯🇵',
    'da': '🇩🇰',
    'nl': '🇳🇱',
    'th': '🇹🇭',
    'vi': '🇻🇳',
  };

  String _getLanguageCode(String language) {
    final langLower = language.toLowerCase();
    if (langLower.contains('japan') || langLower == 'jp') return 'JP';
    if (langLower.contains('english') || langLower == 'en') return 'EN';
    if (langLower.contains('korean') || langLower == 'ko') return 'KO';
    if (langLower.contains('chinese') || langLower == 'zh') return 'ZH';
    if (langLower.contains('spanish') || langLower == 'es') return 'ES';
    if (langLower.contains('french') || langLower == 'fr') return 'FR';
    if (langLower.contains('german') || langLower == 'de') return 'DE';
    if (langLower.contains('italian') || langLower == 'it') return 'IT';
    if (langLower.contains('portuguese') || langLower == 'pt') return 'PT';
    if (langLower.contains('russian') || langLower == 'ru') return 'RU';
    if (langLower.contains('arabic') || langLower == 'ar') return 'AR';
    if (langLower.contains('hindi') || langLower == 'hi') return 'HI';
    return language.toUpperCase().substring(0, language.length > 2 ? 2 : language.length);
  }

  String _getFlagEmoji(String language) {
    final langLower = language.toLowerCase();
    if (langLower.contains('japan') || langLower == 'jp') return '🇯🇵';
    if (langLower.contains('english') || langLower == 'en') return '🇺🇸';
    if (langLower.contains('korean') || langLower == 'ko') return '🇰🇷';
    if (langLower.contains('chinese') || langLower == 'zh') return '🇨🇳';
    if (langLower.contains('spanish') || langLower == 'es') return '🇪🇸';
    if (langLower.contains('french') || langLower == 'fr') return '🇫🇷';
    if (langLower.contains('german') || langLower == 'de') return '🇩🇪';
    if (langLower.contains('italian') || langLower == 'it') return '🇮🇹';
    if (langLower.contains('portuguese') || langLower == 'pt') return '🇵🇹';
    if (langLower.contains('russian') || langLower == 'ru') return '🇷🇺';
    if (langLower.contains('arabic') || langLower == 'ar') return '🇸🇦';
    if (langLower.contains('hindi') || langLower == 'hi') return '🇮🇳';
    return _languageFlags[langLower] ?? '🌍';
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }

  @override
  void initState() {
    super.initState();
    likeCount = widget.moment.likeCount;
    commentCount = widget.moment.commentCount;
    isLiked =
        widget.moment.likedUsers?.contains(widget.moment.user.id) ?? false;
    _loadSavedStatus();
  }

  Future<void> _loadSavedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMoments = prefs.getStringList('savedMoments') ?? [];
    if (mounted) {
      setState(() {
        isSaved = savedMoments.contains(widget.moment.id);
      });
    }
  }

  Future<void> _toggleSave() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMoments = prefs.getStringList('savedMoments') ?? [];

    setState(() {
      if (isSaved) {
        savedMoments.remove(widget.moment.id);
        isSaved = false;
      } else {
        savedMoments.add(widget.moment.id);
        isSaved = true;
      }
    });

    await prefs.setStringList('savedMoments', savedMoments);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSaved ? '✓ Saved' : 'Removed from saved'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF00BFA5),
        ),
      );
    }
  }

  void incrementLike() async {
    final previousLiked = isLiked;
    final previousCount = likeCount;

    setState(() {
      if (isLiked) {
        likeCount--;
      } else {
        likeCount++;
      }
      isLiked = !isLiked;
    });

    try {
      Map<String, dynamic> result;
      if (previousLiked) {
        result = await ref
            .watch(momentsServiceProvider)
            .dislikeMoment(widget.moment.id);
      } else {
        result = await ref
            .watch(momentsServiceProvider)
            .likeMoment(widget.moment.id);
      }

      if (mounted) {
        setState(() {
          isLiked = result['isLiked'] ?? !previousLiked;
          likeCount = result['likeCount'] ?? previousCount;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLiked = previousLiked;
          likeCount = previousCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void updateCommentCount() {
    setState(() {
      commentCount++;
    });
  }

  void focusCommentField() {
    setState(() {
      showCommentField = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      commentFocusNode.requestFocus();
    });
  }

  void _shareMoment() {
    final momentText = 'Check out this moment: ${widget.moment.title}';
    final momentUrl = 'https://banatalk.com/moment/${widget.moment.id}';
    Share.share('$momentText\n\n$momentUrl');
  }

  void _showMoreOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    final isOwnMoment = currentUserId == widget.moment.user.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  color: const Color(0xFF00BFA5),
                ),
                title: Text(isSaved ? 'Remove from Saved' : 'Save Moment'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleSave();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Color(0xFF00BFA5)),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _shareMoment();
                },
              ),
              if (!isOwnMoment)
                ListTile(
                  leading: Icon(Icons.flag_outlined, color: Colors.orange[700]),
                  title: const Text('Report'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => ReportDialog(
                        type: 'moment',
                        reportedId: widget.moment.id,
                        reportedUserId: widget.moment.user.id,
                      ),
                    );
                  },
                ),
              if (isOwnMoment) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: const Text('Delete Moment?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      try {
                        await ref
                            .read(momentsServiceProvider)
                            .deleteUserMoment(id: widget.moment.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Moment deleted')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black87),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    onTap: () async {
                      final community = await ref
                          .read(communityServiceProvider)
                          .getSingleCommunity(id: widget.moment.user.id);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SingleCommunity(community: community),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[300],
                            backgroundImage:
                                widget.moment.user.imageUrls.isNotEmpty
                                    ? NetworkImage(
                                        widget.moment.user.imageUrls[0])
                                    : null,
                            child: widget.moment.user.imageUrls.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 24,
                                    color: Colors.grey[600],
                                  )
                                : null,
                            onBackgroundImageError: (exception, stackTrace) {},
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.moment.user.name.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.only(bottom: 1),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.green[600]!,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _getLanguageCode(
                                            widget.moment.user.native_language),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 12,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getLanguageCode(widget
                                          .moment.user.language_to_learn),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(left: 2),
                                          width: 3,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: index < 3
                                                ? Colors.grey[700]
                                                : Colors.grey[300],
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _getRelativeTime(widget.moment.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      widget.moment.description.isEmpty
                          ? widget.moment.title
                          : widget.moment.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (widget.moment.imageUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildImageGrid(),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        _buildActionButton(
                          icon: isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          count: likeCount,
                          color: isLiked ? Colors.red[400]! : Colors.grey[600]!,
                          onTap: incrementLike,
                        ),
                        const SizedBox(width: 4),
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          count: commentCount,
                          color: Colors.grey[600]!,
                          onTap: focusCommentField,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            Icons.translate,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.card_giftcard_outlined,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () {},
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.share_outlined,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: _shareMoment,
                        ),
                      ],
                    ),
                  ),
                  if (likeCount > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Text(
                            '$likeCount Gifts/Likes',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios,
                              size: 12, color: Colors.grey[500]),
                        ],
                      ),
                    ),
                  Container(
                    height: 8,
                    color: Colors.grey[100],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Comments (${commentCount})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  CommentsMain(id: widget.moment.id),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          CreateComment(
            focusNode: commentFocusNode,
            id: widget.moment.id,
            onCommentAdded: updateCommentCount,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count > 999
                    ? '${(count / 1000).toStringAsFixed(1)}k'
                    : '$count',
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final imageCount = widget.moment.imageUrls.length;

    if (imageCount == 1) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageGallery(
                imageUrls: widget.moment.imageUrls,
                initialIndex: 0,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.moment.imageUrls[0],
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 280,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 280,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00BFA5),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    if (imageCount == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: _buildImageItem(widget.moment.imageUrls[0], 0),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: _buildImageItem(widget.moment.imageUrls[1], 1),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
          childAspectRatio: 1,
        ),
        itemCount: imageCount > 6 ? 6 : imageCount,
        itemBuilder: (context, index) {
          final isLastItem = index == 5 && imageCount > 6;
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _buildImageItem(
              widget.moment.imageUrls[index],
              index,
              isLastItem: isLastItem,
              remainingCount: isLastItem ? imageCount - 6 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageItem(String url, int index,
      {bool isLastItem = false, int remainingCount = 0}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageGallery(
              imageUrls: widget.moment.imageUrls,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.broken_image,
                  size: 30,
                  color: Colors.grey,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00BFA5),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (isLastItem)
            Container(
              color: Colors.black54,
              child: Center(
                child: Text(
                  '+$remainingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
