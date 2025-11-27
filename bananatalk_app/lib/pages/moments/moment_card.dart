import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/pages/moments/single_moment.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MomentCard extends ConsumerStatefulWidget {
  final Moments moments;
  final VoidCallback? onRefresh;

  const MomentCard({
    super.key,
    required this.moments,
    this.onRefresh,
  });

  @override
  _MomentCardState createState() => _MomentCardState();
}

class _MomentCardState extends ConsumerState<MomentCard> {
  late bool isLiked;
  late int likeCount;
  bool isSaved = false;
  bool isExpanded = false;

  // Language code to flag emoji mapping
  final Map<String, String> _languageFlags = {
    'en': '🇺🇸',
    'es': '🇪🇸',
    'fr': '🇫🇷',
    'de': '🇩🇪',
    'it': '🇮🇹',
    'pt': '🇵🇹',
    'ru': '🇷🇺',
    'ja': '🇯🇵',
    'jp': '🇯🇵',
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
    return language
        .toUpperCase()
        .substring(0, language.length > 2 ? 2 : language.length);
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

  @override
  void initState() {
    super.initState();
    isLiked = false;
    likeCount = widget.moments.likeCount;
    _loadSavedStatus();
  }

  Future<void> _loadSavedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMoments = prefs.getStringList('savedMoments') ?? [];
    if (mounted) {
      setState(() {
        isSaved = savedMoments.contains(widget.moments.id);
      });
    }
  }

  Future<void> _toggleSave() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMoments = prefs.getStringList('savedMoments') ?? [];

    setState(() {
      if (isSaved) {
        savedMoments.remove(widget.moments.id);
        isSaved = false;
      } else {
        savedMoments.add(widget.moments.id);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: const Color(0xFF00BFA5),
        ),
      );
    }
  }

  void toggleLike() async {
    // Optimistically update UI
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

    // Call API to persist the change
    try {
      Map<String, dynamic> result;
      if (previousLiked) {
        result = await ref
            .read(momentsServiceProvider)
            .dislikeMoment(widget.moments.id);
      } else {
        result = await ref
            .read(momentsServiceProvider)
            .likeMoment(widget.moments.id);
      }

      if (mounted) {
        setState(() {
          isLiked = result['isLiked'] ?? !previousLiked;
          likeCount = result['likeCount'] ?? previousCount;
        });
      }
    } catch (e) {
      // Revert on error
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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _shareMoment(BuildContext context, String id) {
    final momentText = 'Check out this moment: ${widget.moments.title}';
    final momentUrl = 'https://banatalk.com/moment/$id';
    Share.share('$momentText\n\n$momentUrl');
  }

  void _showMoreOptions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    final isOwnMoment = currentUserId == widget.moments.user.id;

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
                  _shareMoment(context, widget.moments.id);
                },
              ),
              if (!isOwnMoment)
                ListTile(
                  leading: Icon(Icons.flag_outlined, color: Colors.orange[700]),
                  title: const Text('Report'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Moment reported')),
                    );
                  },
                ),
              if (isOwnMoment) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit feature coming soon')),
                    );
                  },
                ),
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
                            .deleteUserMoment(id: widget.moments.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Moment deleted')),
                        );
                        widget.onRefresh?.call();
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
  Widget build(BuildContext context) {
    final fullText = widget.moments.description.isEmpty
        ? widget.moments.title
        : widget.moments.description;
    final shouldShowMore = fullText.length > 150;
    final displayText = !isExpanded && shouldShowMore
        ? '${fullText.substring(0, 150)}...'
        : fullText;

    return GestureDetector(
      onTap: () async {
        Moments singleMoment = await ref
            .watch(momentsServiceProvider)
            .getSingleMoment(id: widget.moments.id);

        ref.refresh(commentsProvider(singleMoment.id));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SingleMoment(moment: singleMoment),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      Community community = await ref
                          .watch(communityServiceProvider)
                          .getSingleCommunity(id: widget.moments.user.id);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SingleCommunity(community: community),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: widget.moments.user.imageUrls.isNotEmpty
                          ? NetworkImage(
                              widget.moments.user.imageUrls[0],
                            )
                          : null,
                      child: widget.moments.user.imageUrls.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 22,
                              color: Colors.grey[600],
                            )
                          : null,
                      onBackgroundImageError: (exception, stackTrace) {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.moments.user.name.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // VIP Badge (conditionally shown)
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //       horizontal: 6, vertical: 2),
                            //   decoration: BoxDecoration(
                            //     gradient: const LinearGradient(
                            //       colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                            //     ),
                            //     borderRadius: BorderRadius.circular(4),
                            //   ),
                            //   child: const Text(
                            //     'VIP',
                            //     style: TextStyle(
                            //       fontSize: 9,
                            //       fontWeight: FontWeight.w700,
                            //       color: Colors.white,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            // Native language with underline
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
                                    widget.moments.user.native_language),
                                style: TextStyle(
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
                            // Learning language with dots
                            Text(
                              _getLanguageCode(
                                  widget.moments.user.language_to_learn),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Language level dots (3 filled, 2 empty)
                            Row(
                              children: List.generate(5, (index) {
                                return Container(
                                  margin: const EdgeInsets.only(left: 2),
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
                  // Time + More button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => _showMoreOptions(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.more_horiz,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getRelativeTime(widget.moments.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  if (shouldShowMore)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          isExpanded ? 'show less' : 'show more',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Images
            if (widget.moments.imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildImageGrid(),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    count: likeCount,
                    color: isLiked ? Colors.red[400]! : Colors.grey[600]!,
                    onTap: toggleLike,
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    count: widget.moments.commentCount,
                    color: Colors.grey[600]!,
                    onTap: () {},
                  ),
                  const SizedBox(width: 4),
                  // Translate icon
                  IconButton(
                    icon: Icon(
                      Icons.translate,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Translation functionality
                    },
                  ),
                  // Gift icon
                  IconButton(
                    icon: Icon(
                      Icons.card_giftcard_outlined,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Gift functionality
                    },
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
                    onPressed: () => _shareMoment(context, widget.moments.id),
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
          ],
        ),
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
    final imageCount = widget.moments.imageUrls.length;

    if (imageCount == 1) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageGallery(
                imageUrls: widget.moments.imageUrls,
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
              widget.moments.imageUrls[0],
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

    // HelloTalk style: 2 images side-by-side with gap
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
                  child: _buildImageItem(widget.moments.imageUrls[0], 0),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: _buildImageItem(widget.moments.imageUrls[1], 1),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // For 3+ images, use grid
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
              widget.moments.imageUrls[index],
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
              imageUrls: widget.moments.imageUrls,
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
