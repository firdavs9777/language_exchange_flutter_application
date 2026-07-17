import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/moments/text_moment_tile.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/moments/single/single_moment.dart';

/// Moments tab body: Instagram-style 3-column grid of the community's posts.
///
/// Image moments render via [CachedImageWidget]; text/prompt moments (no
/// image) render via the shared [TextMomentTile]. Tapping any tile opens the
/// existing [SingleMoment] detail screen.
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
    final momentsAsync = ref.watch(userMomentsProvider(community.id));

    return momentsAsync.when(
      loading: () => _buildLoading(context),
      error: (error, stack) => _buildError(context),
      data: (moments) {
        if (moments.isEmpty) return _buildEmpty(context);
        return _buildGrid(context, moments);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Grid
  // ---------------------------------------------------------------------------

  Widget _buildGrid(BuildContext context, List<Moments> moments) {
    return GridView.builder(
      key: const PageStorageKey<String>('moments_grid'),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: moments.length,
      itemBuilder: (context, index) => _buildTile(context, moments[index]),
    );
  }

  Widget _buildTile(BuildContext context, Moments moment) {
    final hasImage = moment.imageUrls.isNotEmpty;
    final hasVideo = moment.hasVideo;
    final thumbnail = hasVideo ? moment.video?.thumbnail : null;
    final imageUrl = hasImage
        ? moment.imageUrls.first
        : (thumbnail != null && thumbnail.isNotEmpty ? thumbnail : null);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppPageRoute(builder: (context) => SingleMoment(moment: moment)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrl != null
              ? CachedImageWidget(imageUrl: imageUrl, fit: BoxFit.cover)
              : TextMomentTile(
                  text: moment.description,
                  backgroundColor: moment.backgroundColor,
                ),
          if (hasVideo)
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 18,
                shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
              ),
            ),
          if (moment.imageUrls.length > 1)
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.collections_rounded,
                color: Colors.white,
                size: 18,
                shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Widget _buildLoading(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: 9,
      itemBuilder: (context, index) =>
          Container(color: context.containerColor),
    );
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: context.textMuted, size: 32),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.unableToLoadMoments,
              style: context.bodyMedium.copyWith(color: context.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty
  // ---------------------------------------------------------------------------

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 40,
              color: context.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noMomentsYet,
              style: context.bodyMedium.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.hasntSharedMoments(community.name),
              style: context.caption.copyWith(color: context.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
