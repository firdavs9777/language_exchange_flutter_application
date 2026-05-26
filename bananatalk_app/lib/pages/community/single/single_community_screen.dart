import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';

import 'package:bananatalk_app/pages/chat/conversation/chat_conversation_screen.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';
import 'package:bananatalk_app/router/app_router.dart'
    show callOverlayNavigatorKey;
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/services/profile_visitor_service.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';

import 'package:bananatalk_app/pages/community/single/single_community_header.dart';
import 'package:bananatalk_app/pages/community/single/single_community_actions.dart';
import 'package:bananatalk_app/pages/community/single/single_community_overview.dart';
import 'package:bananatalk_app/pages/community/single/single_community_about.dart';
import 'package:bananatalk_app/pages/community/single/single_community_moments.dart';

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
    _tabController = TabController(length: 3, vsync: this);
    _initializeUserState();
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

  Future<void> _makeVideoCall() async {
    final l10n = AppLocalizations.of(context)!;
    if (userId.isEmpty) {
      showCommunitySnackBar(
        context,
        message: l10n.pleaseLoginToCall,
        type: CommunitySnackBarType.error,
      );
      return;
    }
    if (userId == _community.id) {
      showCommunitySnackBar(
        context,
        message: l10n.cannotCallYourself,
        type: CommunitySnackBarType.info,
      );
      return;
    }

    try {
      final callNotifier = ref.read(callProvider.notifier);
      callNotifier.setCallErrorCallback((error) {
        if (mounted) _handleCallError(context, error);
      });
      await callNotifier.initiateCall(
        _community.id,
        _community.name,
        _getProfileImageUrl(),
        CallType.video,
      );
      if (mounted) {
        final currentCall = callNotifier.currentCall;
        if (currentCall != null) {
          callOverlayNavigatorKey.currentState?.push(
            AppPageRoute(
              builder: (_) => ActiveCallScreen(call: currentCall),
              fullscreenDialog: true,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _makeVoiceCall() async {
    final l10n = AppLocalizations.of(context)!;
    if (userId.isEmpty) {
      showCommunitySnackBar(
        context,
        message: l10n.pleaseLoginToCall,
        type: CommunitySnackBarType.error,
      );
      return;
    }
    if (userId == _community.id) {
      showCommunitySnackBar(
        context,
        message: l10n.cannotCallYourself,
        type: CommunitySnackBarType.info,
      );
      return;
    }

    try {
      final callNotifier = ref.read(callProvider.notifier);
      callNotifier.setCallErrorCallback((error) {
        if (mounted) _handleCallError(context, error);
      });
      await callNotifier.initiateCall(
        _community.id,
        _community.name,
        _getProfileImageUrl(),
        CallType.audio,
      );
      if (mounted) {
        final currentCall = callNotifier.currentCall;
        if (currentCall != null) {
          callOverlayNavigatorKey.currentState?.push(
            AppPageRoute(
              builder: (_) => ActiveCallScreen(call: currentCall),
              fullscreenDialog: true,
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _handleCallError(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;
    if (error.startsWith('PERMANENTLY_DENIED:')) {
      final message = error.substring('PERMANENTLY_DENIED:'.length);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.permissionsRequired),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                AppSettings.openAppSettings();
              },
              child: Text(l10n.openSettings),
            ),
          ],
        ),
      );
    } else if (error.startsWith('DENIED:')) {
      final message = error.substring('DENIED:'.length);
      showCommunitySnackBar(
        context,
        message: message,
        type: CommunitySnackBarType.info,
        duration: const Duration(seconds: 3),
      );
    } else {
      showCommunitySnackBar(
        context,
        message: error,
        type: CommunitySnackBarType.error,
        duration: const Duration(seconds: 3),
      );
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Hero header sliver
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              title: innerBoxIsScrolled
                  ? Text(
                      age != null
                          ? '${_community.name}, $age'
                          : _community.name,
                    )
                  : null,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: innerBoxIsScrolled
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Colors.white,
                  ),
                  tooltip: AppLocalizations.of(context)!.communityRefresh,
                  onPressed: _refreshProfile,
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
              flexibleSpace: FlexibleSpaceBar(
                background: SingleCommunityHeader(
                  community: _community,
                  age: age,
                  locationText: locationText,
                  onCopyUsername: () {
                    if (_community.displayUsername != null) {
                      _copyUsername(_community.displayUsername!);
                    }
                  },
                  imageUrls: _getImageUrls(),
                  profileImageUrl: _getProfileImageUrl(),
                ),
              ),
            ),

            // Action buttons row (pinned below header)
            SliverToBoxAdapter(
              child: SingleCommunityActions(
                community: _community,
                isFollower: isFollower,
                onVideoCall: _makeVideoCall,
                onVoiceCall: _makeVoiceCall,
                onMessage: _navigateToChat,
                onFollowToggle: isFollower ? _unfollowUser : _followUser,
              ),
            ),

            // Tab bar (pinned)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: context.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(text: l10n.overview),
                    Tab(text: l10n.about),
                    Tab(text: l10n.moments),
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
            SingleCommunityOverview(
              community: _community,
              onMessage: _navigateToChat,
            ),
            SingleCommunityAbout(community: _community),
            SingleCommunityMoments(
              community: _community,
              profileImageUrl: _getProfileImageUrl(),
            ),
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
