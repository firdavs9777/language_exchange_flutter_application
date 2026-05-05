import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/shimmer_loading.dart';
import 'package:bananatalk_app/widgets/community/user_skeleton.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

class ProfileFollowings extends ConsumerStatefulWidget {
  const ProfileFollowings({
    super.key,
    required this.id,
    this.followingIds,
  });
  final String id;
  final List<String>? followingIds;

  @override
  ConsumerState<ProfileFollowings> createState() => _ProfileFollowingsState();
}

class _ProfileFollowingsState extends ConsumerState<ProfileFollowings> {
  late Future<List<Community>> followings;

  @override
  void initState() {
    super.initState();
    followings = ref.read(authServiceProvider).getFollowingsUser(
          id: widget.id,
          followingIds: widget.followingIds,
        );
  }

  Future<void> _refreshFollowings() async {
    HapticUtils.onRefresh();
    setState(() {
      followings = ref.read(authServiceProvider).getFollowingsUser(
            id: widget.id,
            followingIds: widget.followingIds,
          );
    });
  }

  Future<void> unFollowUser(
      String userId, String targetUserId, String userName) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldUnfollow = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(l10n.unfollow),
          content: Text(l10n.areYouSureUnfollow),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.unfollow),
            ),
          ],
        );
      },
    );

    if (shouldUnfollow == true) {
      try {
        await ref.read(communityServiceProvider).unfollowUser(
              userId: userId,
              targetUserId: targetUserId,
            );

        await _refreshFollowings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.youUnfollowedUser(userName)),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.failedToUnfollowUser}: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> redirect(String id) async {
    try {
      final community =
          await ref.read(communityServiceProvider).getSingleCommunity(id: id);
      if (community == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.userNotFound)),
          );
        }
        return;
      }
      if (mounted) {
        Navigator.push(
          context,
          AppPageRoute(
            builder: (context) => SingleCommunity(community: community),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.following,
          style: context.titleLarge,
        ),
        elevation: 0,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            Navigator.pop(context);
            await ref.refresh(userProvider);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFollowings,
        child: FutureBuilder<List<Community>>(
          future: followings,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const UserListSkeleton(count: 6);
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    Spacing.gapLG,
                    Text('Error: ${snapshot.error}', style: context.bodyMedium),
                    Spacing.gapLG,
                    ElevatedButton(
                      onPressed: _refreshFollowings,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                      child: Icon(Icons.person_add_outlined,
                          size: 64, color: context.textMuted),
                    ),
                    Spacing.gapXXL,
                    Text(
                      AppLocalizations.of(context)!.noFollowingYet,
                      style: context.titleLarge,
                    ),
                    Spacing.gapSM,
                    Text(
                      AppLocalizations.of(context)!.notFollowingAnyoneYetSubtitle,
                      style: context.bodySmall,
                    ),
                  ],
                ),
              );
            } else {
              final filteredFollowings = snapshot.data!;
              return ListView.builder(
                itemCount: filteredFollowings.length,
                cacheExtent: 200,
                itemBuilder: (context, index) {
                  final community = filteredFollowings[index];

                  return _UserCard(
                    key: ValueKey(community.id),
                    community: community,
                    onTap: () => redirect(community.id),
                    onUnfollowTap: () {
                      unFollowUser(widget.id, community.id, community.name);
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    Key? key,
    required this.community,
    required this.onTap,
    required this.onUnfollowTap,
  }) : super(key: key);

  final Community community;
  final VoidCallback onTap;
  final VoidCallback onUnfollowTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.md,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderLG,
          child: Padding(
            padding: Spacing.paddingLG,
            child: Row(
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: CachedCircleAvatar(
                      radius: 35,
                      backgroundColor: AppColors.primary,
                      imageUrl: community.imageUrls.isNotEmpty
                          ? community.imageUrls[0]
                          : null,
                      errorWidget: const Icon(
                        Icons.person,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Spacing.hGapLG,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community.name,
                        style: context.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacing.gapSM,
                      if (community.native_language.isNotEmpty ||
                          community.language_to_learn.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (community.native_language.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.translate,
                                        size: 12, color: Colors.blue[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      community.native_language,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (community.language_to_learn.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.school,
                                        size: 12, color: Colors.orange[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      community.language_to_learn,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                Spacing.hGapSM,
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onUnfollowTap,
                    borderRadius: AppRadius.borderRound,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: AppRadius.borderRound,
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.unfollowButton,
                        style: context.labelLarge.copyWith(
                          color: AppColors.error,
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
    );
  }
}

