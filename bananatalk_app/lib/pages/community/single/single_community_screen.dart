import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bananatalk_app/pages/chat/conversation/chat_conversation_screen.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/message_count_provider.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/services/link_constants.dart';
import 'package:bananatalk_app/services/profile_visitor_service.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/pages/moments/viewer/image_viewer.dart';
import 'package:bananatalk_app/pages/stories/viewer/story_viewer_launcher.dart';

import 'package:bananatalk_app/pages/community/single/single_community_header.dart';
import 'package:bananatalk_app/pages/community/single/single_community_actions.dart';
import 'package:bananatalk_app/pages/community/single/single_community_about.dart';
import 'package:bananatalk_app/pages/community/single/single_community_moments.dart';
import 'package:bananatalk_app/pages/stories/highlights/highlights_row.dart';
import 'package:bananatalk_app/widgets/navigation/app_back_button.dart';

// ---------------------------------------------------------------------------
// Public entry point – name preserved for existing navigation call sites.
// ---------------------------------------------------------------------------

class SingleCommunity extends ConsumerStatefulWidget {
  final Community community;
  const SingleCommunity({super.key, required this.community});

  @override
  _SingleCommunityState createState() => _SingleCommunityState();
}

class _SingleCommunityState extends ConsumerState<SingleCommunity>
    with SingleTickerProviderStateMixin {
  bool isFollower = false;
  bool isBlocked = false;
  String userId = '';
  Community? _updatedCommunity;
  late TabController _tabController;

  Community get _community => _updatedCommunity ?? widget.community;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeUserState();
    // Populate the message-count cache so the call-button gate has
    // accurate data before the user opens the chat. Best-effort: the
    // provider swallows network errors and the buttons stay disabled
    // (fail-safe) if the fetch never completes.
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(messageCountProvider.notifier)
          .refreshMessageCount(widget.community.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<String> _getImageUrls() => _community.effectiveImageUrls;
  String? _getProfileImageUrl() => _community.profileImageUrl;

  int? _calculateAge(String birthYear) {
    if (birthYear.isEmpty) return null;
    final year = int.tryParse(birthYear);
    if (year == null) return null;
    return DateTime.now().year - year;
  }

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  Future<void> _initializeUserState() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';

    try {
      final currentUserAsync = ref.read(userProvider);
      final currentUser = currentUserAsync.valueOrNull;

      if (currentUser != null) {
        setState(() {
          isFollower = currentUser.followings.contains(_community.id);
        });
      } else {
        setState(() {
          isFollower = _community.followers.contains(userId);
        });
      }
    } catch (e) {
      setState(() {
        isFollower = _community.followers.contains(userId);
      });
    }

    if (userId.isNotEmpty && userId != _community.id) {
      await _checkBlockStatus();
      _recordProfileVisit();
    }

    _checkProfileViewLimit();
  }

  Future<void> _checkBlockStatus() async {
    try {
      final result = await BlockService.checkBlockStatus(
        userId: userId,
        targetUserId: _community.id,
      );
      if (result['success'] == true) {
        setState(() {
          isBlocked = result['isBlocked'] ?? false;
        });
      }
    } catch (_) {}
  }

  Future<void> _recordProfileVisit() async {
    try {
      await ProfileVisitorService.recordProfileVisit(
        userId: _community.id,
        source: 'direct',
      );
    } catch (_) {}
  }

  Future<void> _checkProfileViewLimit() async {
    if (userId.isEmpty || userId == _community.id) return;

    try {
      final user = await ref.read(userProvider.future);
      final limits = ref.read(currentUserLimitsProvider(userId));

      if (!FeatureGate.canViewProfile(user, limits)) {
        if (mounted) {
          await LimitExceededDialog.show(
            context: context,
            limitType: 'profileViews',
            limitInfo: limits?.profileViews,
            resetTime: limits?.resetTime,
            userId: userId,
          );
        }
      } else {
        ref.invalidate(userLimitsProvider(userId));
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Profile refresh
  // ---------------------------------------------------------------------------

  Future<void> _refreshProfile() async {
    try {
      final communityService = ref.read(communityServiceProvider);
      final refreshedData = await communityService.getSingleCommunity(
        id: widget.community.id,
      );
      if (refreshedData != null && mounted) {
        setState(() {
          _updatedCommunity = refreshedData;
          isFollower = refreshedData.followers.contains(userId);
        });
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Follow / Unfollow
  // ---------------------------------------------------------------------------

  void _followUser() async {
    if (userId.isEmpty) {
      showCommunitySnackBar(
        context,
        message: AppLocalizations.of(context)!.pleaseLoginToFollow,
        type: CommunitySnackBarType.info,
      );
      return;
    }

    try {
      final result = await ref
          .read(communityServiceProvider)
          .followUser(userId: userId, targetUserId: _community.id);

      if (result == 'success' || result == 'already_following') {
        setState(() => isFollower = true);
        ref.invalidate(userProvider);
        ref.invalidate(communityProvider);
        await _refreshProfile();
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          showCommunitySnackBar(
            context,
            message: result == 'already_following'
                ? '${l10n.alreadyFollowing} ${_community.name}'
                : l10n.youFollowedUser(_community.name),
            type: CommunitySnackBarType.success,
          );
        }
      } else {
        if (mounted) {
          showCommunitySnackBar(
            context,
            message: AppLocalizations.of(context)!.failedToFollowUser,
            type: CommunitySnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showCommunitySnackBar(
          context,
          message:
              '${AppLocalizations.of(context)!.failedToFollowUser}: ${e.toString().replaceAll('Exception: ', '')}',
          type: CommunitySnackBarType.error,
        );
      }
    }
  }

  void _unfollowUser() async {
    final l10n = AppLocalizations.of(context)!;
    if (userId.isEmpty) {
      showCommunitySnackBar(
        context,
        message: l10n.pleaseLoginToFollow,
        type: CommunitySnackBarType.info,
      );
      return;
    }

    final shouldUnfollow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unfollowUser(_community.name)),
        content: Text(l10n.areYouSureUnfollow),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.unfollow),
          ),
        ],
      ),
    );

    if (shouldUnfollow != true) return;

    try {
      final result = await ref
          .read(communityServiceProvider)
          .unfollowUser(userId: userId, targetUserId: _community.id);

      if (result == 'success' || result == 'not_following') {
        setState(() => isFollower = false);
        ref.invalidate(userProvider);
        ref.invalidate(communityProvider);
        await _refreshProfile();
        if (mounted) {
          final l10n2 = AppLocalizations.of(context)!;
          showCommunitySnackBar(
            context,
            message: result == 'not_following'
                ? l10n2.notFollowingUser(_community.name)
                : l10n2.youUnfollowedUser(_community.name),
            type: CommunitySnackBarType.success,
          );
        }
      } else {
        if (mounted) {
          showCommunitySnackBar(
            context,
            message: AppLocalizations.of(context)!.failedToUnfollowUser,
            type: CommunitySnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showCommunitySnackBar(
          context,
          message:
              '${AppLocalizations.of(context)!.failedToUnfollowUser}: ${e.toString().replaceAll('Exception: ', '')}',
          type: CommunitySnackBarType.error,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Block / Unblock
  // ---------------------------------------------------------------------------

  Future<void> _handleUnblock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.unblockUser),
        content: Text(AppLocalizations.of(context)!.communityUnblockConfirm(_community.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: Text(AppLocalizations.of(context)!.unblock),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    final result = await BlockService.unblockUser(
      currentUserId: userId,
      blockedUserId: _community.id,
    );

    if (mounted) Navigator.of(context).pop();

    if (mounted) {
      showCommunitySnackBar(
        context,
        message: result['message'] ?? 'Operation completed',
        type: result['success']
            ? CommunitySnackBarType.success
            : CommunitySnackBarType.error,
      );

      if (result['success']) {
        setState(() => isBlocked = false);
        ref.invalidate(blockedUsersProvider);
        ref.invalidate(blockedUserIdsProvider);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _shareCommunity() {
    final l10n = AppLocalizations.of(context)!;
    final communityText = l10n.checkOutCommunity;
    final communityUrl = shareUrl('community', _community.id.toString());
    Share.share('$communityText\n\n$communityUrl');
  }

  void _copyUsername(String username) {
    Clipboard.setData(ClipboardData(text: username));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.communityUsernameCopied),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToChat() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
          userId: _community.id,
          userName: _community.name,
          profilePicture: _getProfileImageUrl(),
          isVip: _community.isVip,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // Opens the existing profile-photo gallery view — the fallback used both
  // when the avatar has no active story and when [StoryViewerLauncher]
  // finds nothing to show (e.g. the story expired between load and tap).
  void _openProfilePhotoView() {
    final urls = _getImageUrls();
    if (urls.isNotEmpty) {
      Navigator.push(
        context,
        AppPageRoute(builder: (context) => ImageGallery(imageUrls: urls)),
      );
    }
  }

  // Avatar tap: open the active story via the same launcher Task 11 wired
  // up elsewhere (chat list, community discovery cards) when this user has
  // one; otherwise go straight to the profile-photo view.
  void _onAvatarTap() {
    if (_community.hasActiveStory) {
      StoryViewerLauncher.open(
        context,
        userId: _community.id,
        fallback: _openProfilePhotoView,
      );
    } else {
      _openProfilePhotoView();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final calculatedAge = _calculateAge(_community.birth_year);
    final age = PrivacyUtils.getAge(_community, calculatedAge);
    final locationText = PrivacyUtils.getLocationText(_community);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Name-only app bar — the visual "hero" is now the ringed
            // avatar inside SingleCommunityHeader, not a background image.
            SliverAppBar(
              pinned: true,
              backgroundColor: context.surfaceColor,
              foregroundColor: context.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              leading: const AppBackButton(),
              title: Text(
                _community.name,
                style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: AppLocalizations.of(context)!.communityRefresh,
                  onPressed: _refreshProfile,
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: l10n.checkOutCommunity,
                  onPressed: _shareCommunity,
                ),
                if (userId.isNotEmpty && userId != _community.id)
                  SingleCommunityMoreMenu(
                    community: _community,
                    currentUserId: userId,
                    isScrolled: innerBoxIsScrolled,
                    isBlocked: isBlocked,
                    profileImageUrl: _getProfileImageUrl(),
                    onBlocked: () => setState(() => isBlocked = true),
                    onUnblock: _handleUnblock,
                  ),
              ],
            ),

            // Header: ringed avatar + display-only stats, name/language
            // line, collapsed bio.
            SliverToBoxAdapter(
              child: SingleCommunityHeader(
                community: _community,
                age: age,
                locationText: locationText,
                onCopyUsername: () {
                  if (_community.displayUsername != null) {
                    _copyUsername(_community.displayUsername!);
                  }
                },
                profileImageUrl: _getProfileImageUrl(),
                onAvatarTap: _onAvatarTap,
              ),
            ),

            // Action buttons row (Follow / Message / Wave)
            SliverToBoxAdapter(
              child: SingleCommunityActions(
                community: _community,
                isFollower: isFollower,
                onMessage: _navigateToChat,
                onFollowToggle: isFollower ? _unfollowUser : _followUser,
              ),
            ),

            // Story highlights row (directly under the header/actions)
            SliverToBoxAdapter(
              child: HighlightsRow(
                userId: _community.id,
                isOwnProfile: false,
                user: _community,
              ),
            ),

            // Tab bar (pinned) — grid (Moments) / info (About)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: context.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(
                      icon: Icon(
                        Icons.grid_on_rounded,
                        semanticLabel: l10n.moments,
                      ),
                    ),
                    Tab(
                      icon: Icon(
                        Icons.info_outline_rounded,
                        semanticLabel: l10n.about,
                      ),
                    ),
                  ],
                ),
                context.surfaceColor,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            SingleCommunityMoments(
              community: _community,
              profileImageUrl: _getProfileImageUrl(),
            ),
            SingleCommunityAbout(community: _community),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delegate for pinned tab bar in SliverPersistentHeader
// ---------------------------------------------------------------------------

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
