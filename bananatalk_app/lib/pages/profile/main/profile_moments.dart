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
  bool _isGridView = true; // default to grid (more modern, photo-first)

  Future<void> _refreshMoments() async {
    if (!mounted) return;
    HapticFeedback.lightImpact();

    ref.invalidate(userMomentsProvider(widget.id));

    try {
      await ref.read(userMomentsProvider(widget.id).future);
      imageCache.clear();
      imageCache.clearLiveImages();
    } catch (e) {
      // Ignore errors - provider will handle them in the UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final momentsAsync = ref.watch(userMomentsProvider(widget.id));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          l10n.myMoments,
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
          // View toggle pill
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildViewToggle(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMoments,
        color: AppColors.primary,
        child: momentsAsync.when(
          data: (moments) {
            if (moments.isEmpty) {
              return _buildEmptyState();
            }
            return _buildMomentsList(moments);
          },
          loading: () => _isGridView
              ? const UserGridSkeleton(
                  count: 9,
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                )
              : const UserGridSkeleton(
                  count: 4,
                  crossAxisCount: 1,
                  childAspectRatio: 1,
                ),
          error: (error, stackTrace) => _buildErrorState(error),
        ),
      ),
    );
  }

  // ========== VIEW TOGGLE ==========
  Widget _buildViewToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : context.containerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.grid_view_rounded,
            isSelected: _isGridView,
            onTap: () {
              if (!_isGridView) {
                HapticFeedback.selectionClick();
                setState(() => _isGridView = true);
              }
            },
            tooltip: AppLocalizations.of(context)!.momentGridView,
          ),
          _buildToggleButton(
            icon: Icons.view_list_rounded,
            isSelected: !_isGridView,
            onTap: () {
              if (_isGridView) {
                HapticFeedback.selectionClick();
                setState(() => _isGridView = false);
              }
            },
            tooltip: AppLocalizations.of(context)!.momentListView,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ========== EMPTY STATE ==========
  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(
                            alpha: isDark ? 0.25 : 0.15,
                          ),
                          AppColors.primary.withValues(
                            alpha: isDark ? 0.08 : 0.04,
                          ),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.noMomentsYet,
                    style: context.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.shareLanguageLearningJourney,
                    style: context.bodyMedium.copyWith(
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pull down to refresh',
                          style: context.captionSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== ERROR STATE ==========
  Widget _buildErrorState(Object error) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.error,
                    style: context.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error.toString(),
                    style: context.bodySmall.copyWith(
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _refreshMoments();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.retry,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMomentsList(List<Moments> moments) {
    if (_isGridView) {
      return _buildGridView(moments);
    } else {
      return _buildListView(moments);
    }
  }

  // ========== GRID VIEW ==========
  Widget _buildGridView(List<Moments> moments) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: moments.length,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final moment = moments[index];
        return _buildGridItem(moment, index);
      },
    );
  }

  Widget _buildGridItem(Moments moment, int index) {
    final imageUrl = moment.imageUrls.isNotEmpty
        ? ImageUtils.normalizeImageUrl(moment.imageUrls[0])
        : null;
    final hasMultiple = moment.imageUrls.length > 1;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: Duration(milliseconds: 200 + (index * 30).clamp(0, 300)),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _showMomentDetail(moment);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: context.containerColor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    CachedImageWidget(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      useNormalization: false,
                      errorWidget: _imagePlaceholder(),
                    )
                  else
                    _imagePlaceholder(),

                  // Subtle gradient overlay at bottom for content visibility
                  if (hasMultiple || (moment.description.isNotEmpty))
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.4),
                              ],
                              stops: const [0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Multiple images indicator (top-right)
                  if (hasMultiple)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.collections_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${moment.imageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Caption indicator (bottom-left) if text exists
                  if (moment.description.isNotEmpty)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: context.containerColor,
      child: Icon(Icons.image_rounded, color: context.textMuted, size: 32),
    );
  }

  // ========== LIST VIEW ==========
  Widget _buildListView(List<Moments> moments) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: moments.length,
      cacheExtent: 200,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final moment = moments[index];
        final imageKey = moment.imageUrls.isNotEmpty
            ? moment.imageUrls[0].hashCode
            : 0;
        return ProfileSingleMoment(
          key: ValueKey(
            'moment_${moment.id}_${moment.imageUrls.length}_$imageKey',
          ),
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
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
