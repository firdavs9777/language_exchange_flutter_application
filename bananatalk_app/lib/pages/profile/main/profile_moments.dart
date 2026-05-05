import 'package:bananatalk_app/pages/profile/about/profile_single_moment.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/community/user_skeleton.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileMoments extends ConsumerStatefulWidget {
  const ProfileMoments({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ProfileMoments> createState() => _ProfileMomentsState();
}

class _ProfileMomentsState extends ConsumerState<ProfileMoments> {
  bool _isGridView = false;

  Future<void> _refreshMoments() async {
    if (!mounted) return;
    
    // Invalidate to clear cache
    ref.invalidate(userMomentsProvider(widget.id));
    
    // Force refresh by reading the provider (triggers immediate refetch)
    // This ensures fresh data is loaded from backend
    try {
      await ref.read(userMomentsProvider(widget.id).future);
      // Clear image cache to ensure fresh images are loaded
      imageCache.clear();
      imageCache.clearLiveImages();
    } catch (e) {
      // Ignore errors - provider will handle them in the UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final momentsAsync = ref.watch(userMomentsProvider(widget.id));

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myMoments,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView
                ? AppLocalizations.of(context)!.momentListView
                : AppLocalizations.of(context)!.momentGridView,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMoments,
        child: momentsAsync.when(
          data: (moments) {
            if (moments.isEmpty) {
              return _buildEmptyState();
            }
            return _buildMomentsList(moments);
          },
          loading: () => const UserGridSkeleton(count: 6, crossAxisCount: 3, childAspectRatio: 1),
          error: (error, stackTrace) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.photo_library_outlined,
                size: 64, color: context.iconColor),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noMomentsYet,
            style: context.titleMedium.copyWith(
              color: context.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.shareLanguageLearningJourney,
            style: context.bodySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '${l10n.error}: ${error.toString()}',
              style: context.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _refreshMoments();
              },
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.retry,
                        style: context.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentsList(List<Moments> moments) {

    if (_isGridView) {
      return _buildGridView(moments);
    } else {
      return _buildListView(moments);
    }
  }

  Widget _buildGridView(List<Moments> moments) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: moments.length,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final moment = moments[index];
        return _buildGridItem(moment);
      },
    );
  }

  Widget _buildGridItem(Moments moment) {
    final imageUrl = moment.imageUrls.isNotEmpty
        ? ImageUtils.normalizeImageUrl(moment.imageUrls[0])
        : null;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showMomentDetail(moment);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: context.containerColor,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                CachedImageWidget(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  useNormalization: false, // Already normalized
                  errorWidget: Container(
                    color: context.containerColor,
                    child: Icon(
                      Icons.image_not_supported,
                      color: context.iconColor,
                    ),
                  ),
                )
              else
                Container(
                  color: context.containerColor,
                  child: Icon(
                    Icons.image_not_supported,
                    color: context.iconColor,
                  ),
                ),
              // Overlay for multiple images indicator
              if (moment.imageUrls.length > 1)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.collections,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${moment.imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Moments> moments) {
    return ListView.builder(
      itemCount: moments.length,
      cacheExtent: 200,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        // Use a key that includes the moment's image count and first image URL hash
        // This forces a rebuild when images change
        final moment = moments[index];
        final imageKey = moment.imageUrls.isNotEmpty 
            ? moment.imageUrls[0].hashCode 
            : 0;
        return ProfileSingleMoment(
          key: ValueKey('moment_${moment.id}_${moment.imageUrls.length}_$imageKey'),
          moment: moment,
          onDeleted: () => _refreshMoments(),
          onUpdated: () => _refreshMoments(),
        );
      },
    );
  }

  void _showMomentDetail(Moments moment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: ProfileSingleMoment(
              key: ValueKey('detail_${moment.id}'),
              moment: moment,
              onDeleted: () {
                Navigator.pop(context);
                _refreshMoments();
              },
              onUpdated: () {
                _refreshMoments();
              },
            ),
          );
        },
      ),
    );
  }
}
