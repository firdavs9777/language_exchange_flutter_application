import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/moments/single_moment.dart';

/// Moments tab body: fetches and renders a Facebook-style post list for the
/// given community profile.
class SingleCommunityMoments extends ConsumerWidget {
  final Community community;
  final String? profileImageUrl;

  const SingleCommunityMoments({
    super.key,
    required this.community,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      key: const PageStorageKey<String>('moments'),
      padding: const EdgeInsets.all(16),
      children: [
        _buildMomentsSection(context, ref),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section dispatcher
  // ---------------------------------------------------------------------------

  Widget _buildMomentsSection(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final momentsAsync = ref.watch(userMomentsProvider(community.id));

        return momentsAsync.when(
          loading: () => _buildMomentsLoading(context),
          error: (error, stack) => _buildMomentsError(context, error.toString()),
          data: (moments) {
            if (moments.isEmpty) return _buildMomentsEmpty(context);
            return _buildMomentsGrid(context, moments);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Widget _buildMomentsLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMomentsHeader(context, 0, isLoading: true),
        Spacing.gapSM,
        for (int i = 0; i < 2; i++) ...[
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : context.dividerColor,
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: context.containerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 60,
                          height: 10,
                          decoration: BoxDecoration(
                            color: context.containerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 14,
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.photo_outlined,
                      color: context.textMuted.withValues(alpha: 0.3),
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (i < 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildMomentsError(BuildContext context, String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMomentsHeader(context, 0),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.unableToLoadMoments,
                  style: TextStyle(color: Colors.red[700], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Empty
  // ---------------------------------------------------------------------------

  Widget _buildMomentsEmpty(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMomentsHeader(context, 0),
        Spacing.gapSM,
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : context.dividerColor,
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : context.containerColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library_outlined, size: 32, color: context.textMuted),
              ),
              Spacing.gapMD,
              Text(
                AppLocalizations.of(context)!.noMomentsYet,
                style: context.bodyMedium.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacing.gapXS,
              Text(
                AppLocalizations.of(context)!.hasntSharedMoments(community.name),
                style: context.caption.copyWith(color: context.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildMomentsHeader(BuildContext context, int count, {bool isLoading = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 18),
          ),
          Spacing.hGapSM,
          Text(AppLocalizations.of(context)!.moments, style: context.titleMedium),
          Spacing.hGapSM,
          if (!isLoading && count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.containerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count', style: context.labelSmall),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Grid (list)
  // ---------------------------------------------------------------------------

  Widget _buildMomentsGrid(BuildContext context, List<Moments> moments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMomentsHeader(context, moments.length),
        Spacing.gapSM,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: moments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildMomentPost(context, moments[index]);
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Post card
  // ---------------------------------------------------------------------------

  Widget _buildMomentPost(BuildContext context, Moments moment) {
    final hasVideo = moment.hasVideo;
    final hasImages = moment.hasImages;
    final hasMultipleImages = moment.imageUrls.length > 1;
    final hasText = moment.description.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppPageRoute(builder: (context) => SingleMoment(moment: moment)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : context.dividerColor,
            width: 0.5,
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accent,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null
                        ? const Icon(Icons.person, size: 18, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community.name,
                          style: context.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimeAgo(moment.createdAt),
                          style: context.captionSmall.copyWith(color: context.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Post text
            if (hasText)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  moment.description,
                  style: context.bodyMedium.copyWith(color: context.textPrimary),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            if (hasText && (hasImages || hasVideo))
              const SizedBox(height: 10),

            // Media
            if (hasImages || hasVideo)
              _buildMomentMedia(moment, hasVideo, hasImages, hasMultipleImages, isDark),

            Divider(
              height: 1,
              thickness: 0.5,
              color: isDark ? Colors.white.withValues(alpha: 0.1) : context.dividerColor,
            ),

            // Engagement counts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (moment.likeCount > 0) ...[
                    Icon(Icons.favorite, size: 16, color: Colors.red[400]),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(moment.likeCount),
                      style: context.labelSmall.copyWith(color: context.textSecondary),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (moment.commentCount > 0) ...[
                    Icon(Icons.chat_bubble_outline, size: 15, color: context.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatCount(moment.commentCount)} ${moment.commentCount == 1 ? 'comment' : 'comments'}',
                      style: context.labelSmall.copyWith(color: context.textSecondary),
                    ),
                  ],
                  if (moment.likeCount == 0 && moment.commentCount == 0)
                    Text(
                      'Be the first to like this',
                      style: context.captionSmall.copyWith(color: context.textMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentMedia(
    Moments moment,
    bool hasVideo,
    bool hasImages,
    bool hasMultipleImages,
    bool isDark,
  ) {
    final videoThumbnail = moment.video?.thumbnail;
    final overlayColor = isDark
        ? Colors.black.withValues(alpha: 0.7)
        : Colors.black.withValues(alpha: 0.5);

    if (hasVideo && videoThumbnail != null && videoThumbnail.isNotEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedImageWidget(imageUrl: videoThumbnail, fit: BoxFit.cover),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: overlayColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
          ),
        ],
      );
    } else if (hasImages && moment.imageUrls.isNotEmpty) {
      if (moment.imageUrls.length == 1) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: CachedImageWidget(
            imageUrl: moment.imageUrls.first,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        );
      } else if (moment.imageUrls.length == 2) {
        return Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedImageWidget(imageUrl: moment.imageUrls[0], fit: BoxFit.cover),
              ),
            ),
            SizedBox(width: isDark ? 1 : 2),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedImageWidget(imageUrl: moment.imageUrls[1], fit: BoxFit.cover),
              ),
            ),
          ],
        );
      } else {
        return Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: CachedImageWidget(
                imageUrl: moment.imageUrls.first,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            SizedBox(height: isDark ? 1 : 2),
            SizedBox(
              height: 100,
              child: Row(
                children: [
                  Expanded(
                    child: CachedImageWidget(imageUrl: moment.imageUrls[1], fit: BoxFit.cover),
                  ),
                  SizedBox(width: isDark ? 1 : 2),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedImageWidget(
                          imageUrl: moment.imageUrls.length > 2
                              ? moment.imageUrls[2]
                              : moment.imageUrls[1],
                          fit: BoxFit.cover,
                        ),
                        if (moment.imageUrls.length > 3)
                          Container(
                            color: overlayColor,
                            child: Center(
                              child: Text(
                                '+${moment.imageUrls.length - 3}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    }

    return const SizedBox.shrink();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()}mo ago';
    return '${(difference.inDays / 365).floor()}y ago';
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
