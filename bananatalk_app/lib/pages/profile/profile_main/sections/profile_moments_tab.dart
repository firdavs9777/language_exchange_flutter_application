import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/pages/profile/moments/moments_list.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Moments preview grid shown on the own-profile page.
///
/// Displays up to 9 most-recent moments in a 3-column grid.
/// Hidden when the user has no moments.
/// "See all" button navigates to the full [ProfileMoments] screen.
class ProfileMomentsTab extends ConsumerWidget {
  const ProfileMomentsTab({super.key, required this.user});

  final Community user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentsAsync = ref.watch(userMomentsProvider(user.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return momentsAsync.when(
      data: (moments) {
        if (moments.isEmpty) return const SizedBox.shrink();
        final previewMoments = moments.take(9).toList();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.06))
                : null,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)!.recentMoments,
                        style: context.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        AppPageRoute(
                          builder: (context) => ProfileMoments(id: user.id),
                        ),
                      ).then(
                        (_) => ref.invalidate(userMomentsProvider(user.id)),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.seeAll,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: previewMoments.length,
                itemBuilder: (context, index) {
                  final moment = previewMoments[index];
                  final imageUrl = moment.imageUrls.isNotEmpty
                      ? ImageUtils.normalizeImageUrl(moment.imageUrls[0])
                      : null;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl != null
                        ? CachedImageWidget(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: context.containerColor,
                              child: Icon(
                                Icons.broken_image_rounded,
                                color: context.iconColor,
                              ),
                            ),
                          )
                        : Container(
                            color: context.containerColor,
                            child: Icon(
                              Icons.image_rounded,
                              color: context.iconColor,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
