import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/pages/profile/main/profile_highlights.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/pages/moments/single_moment.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';
import 'package:bananatalk_app/router/app_router.dart' show callOverlayNavigatorKey;
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/services/profile_visitor_service.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'package:bananatalk_app/widgets/block_user_dialog.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/vip_upsell_banner.dart';
import 'package:bananatalk_app/widgets/vip_avatar_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/widgets/community/language_match_card.dart';
import 'package:bananatalk_app/widgets/community/engagement_stats_bar.dart';
import 'package:bananatalk_app/widgets/community/conversation_starters_card.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

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
  String userId = ''; // Initialize to empty string instead of late
  Community? _updatedCommunity; // Holds refreshed data after follow/unfollow
  late TabController _tabController;

  /// Get current community data (updated or original)
  Community get _community => _updatedCommunity ?? widget.community;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _debugCommunityData();
    _initializeUserState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Refresh profile data after follow/unfollow
  Future<void> _refreshProfile() async {
    try {
      final communityService = ref.read(communityServiceProvider);
      final refreshedData = await communityService.getSingleCommunity(
        id: widget.community.id,
      );
      if (refreshedData != null && mounted) {
        // Check if current user is in the followers list
        final isNowFollowing = refreshedData.followers.contains(userId);

        setState(() {
          _updatedCommunity = refreshedData;
          isFollower = isNowFollowing;
        });
      }
    } catch (e) {
    }
  }

  void _debugCommunityData() {
  }

  /// Get the best available image URLs - uses model's effectiveImageUrls
  List<String> _getImageUrls() => _community.effectiveImageUrls;

  /// Get the first available profile image URL - uses model's profileImageUrl
  String? _getProfileImageUrl() => _community.profileImageUrl;

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
    } catch (e) {
    }
  }

  Future<void> _initializeUserState() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';

    // Check if current user is following this profile by checking current user's following list
    // This is more reliable than checking the viewed profile's followers list (which might be stale)
    try {
      final currentUserAsync = ref.read(userProvider);
      final currentUser = currentUserAsync.valueOrNull;

      if (currentUser != null) {
        final isFollowingFromCurrentUser = currentUser.followings.contains(_community.id);
        final isFollowingFromProfile = _community.followers.contains(userId);


        setState(() {
          // Use current user's following list as the source of truth
          isFollower = isFollowingFromCurrentUser;
        });
      } else {
        // Current user not loaded yet, fallback to profile's followers list
        setState(() {
          isFollower = _community.followers.contains(userId);
        });
      }
    } catch (e) {
      // Fallback to checking profile's followers list
      setState(() {
        isFollower = _community.followers.contains(userId);
      });
    }

    if (userId.isNotEmpty && userId != _community.id) {
      await _checkBlockStatus();

      // Record profile visit (don't wait for it to complete)
      _recordProfileVisit();
    }

    // Check profile view limit after userId is initialized
    _checkProfileViewLimit();
  }

  Future<void> _recordProfileVisit() async {
    try {
      await ProfileVisitorService.recordProfileVisit(
        userId: _community.id,
        source: 'direct', // You can track source: 'search', 'moments', 'chat', etc.
      );
    } catch (e) {
      // Silently fail - don't disrupt user experience
    }
  }

  Future<void> _checkProfileViewLimit() async {
    // Only check if viewing another user's profile
    if (userId.isEmpty || userId == _community.id) {
      return;
    }

    try {
      final userAsync = ref.read(userProvider);
      final user = await userAsync;
      final limits = ref.read(currentUserLimitsProvider(userId));

      if (!FeatureGate.canViewProfile(user, limits)) {
        // Show warning but allow viewing (non-blocking)
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
        // Refresh limits after viewing (if within limit)
        ref.refresh(userLimitsProvider(userId));
      }
    } catch (e) {
      // If limit check fails, allow viewing (fail open)
    }
  }

  int? calculateAge(String birthYear) {
    if (birthYear.isEmpty) return null;
    final year = int.tryParse(birthYear);
    if (year == null) return null;
    final currentYear = DateTime.now().year;
    return currentYear - year;
  }

  Future<void> _handleUnblock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.unblockUser),
        content:
            Text('Are you sure you want to unblock ${_community.name}?'),
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

    if (confirmed == true) {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final result = await BlockService.unblockUser(
        currentUserId: userId,
        blockedUserId: _community.id,
      );

      // Close loading
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Operation completed'),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );

        if (result['success']) {
          setState(() {
            isBlocked = false;
          });
          // Refresh blocked users provider
          ref.invalidate(blockedUsersProvider);
          ref.invalidate(blockedUserIdsProvider);
        }
      }
    }
  }

  void followUser(String userId, String targetUserId) async {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseLoginToFollow),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {

      final result = await ref.read(communityServiceProvider).followUser(
            userId: userId,
            targetUserId: targetUserId,
          );


      if (result == 'success' || result == 'already_following') {
        setState(() {
          isFollower = true;
        });
        // Refresh current user data to update following list
        ref.invalidate(userProvider);
        // Refresh community list to update follower counts
        ref.invalidate(communityProvider);
        // Refresh this profile to get updated counts
        await _refreshProfile();
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result == 'already_following'
                  ? '${l10n.alreadyFollowing} ${_community.name}'
                  : l10n.youFollowedUser(_community.name)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failedToFollowUser),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.failedToFollowUser}: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void unFollowUser(String userId, String targetUserId) async {
    final l10n = AppLocalizations.of(context)!;
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseLoginToFollow),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool? shouldUnfollow = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.unfollowUser(_community.name)),
          content: Text(l10n.areYouSureUnfollow),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.unfollow),
            ),
          ],
        );
      },
    );

    if (shouldUnfollow == true) {
      try {

        final result = await ref.read(communityServiceProvider).unfollowUser(
              userId: userId,
              targetUserId: targetUserId,
            );


        if (result == 'success' || result == 'not_following') {
          setState(() {
            isFollower = false;
          });
          // Refresh current user data to update following list
          ref.invalidate(userProvider);
          // Refresh community list to update follower counts
          ref.invalidate(communityProvider);
          // Refresh this profile to get updated counts
          await _refreshProfile();
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result == 'not_following'
                    ? l10n.notFollowingUser(_community.name)
                    : l10n.youUnfollowedUser(_community.name)),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.failedToUnfollowUser),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.failedToUnfollowUser}: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Copy username to clipboard
  void _copyUsername(String username) {
    Clipboard.setData(ClipboardData(text: username));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Username copied!'),
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
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseLoginToCall),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userId == _community.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotCallYourself),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final callNotifier = ref.read(callProvider.notifier);
      final profilePicture = _getProfileImageUrl();

      // Setup error callback to handle permission errors
      callNotifier.setCallErrorCallback((error) {
        if (mounted) {
          _handleCallError(context, error);
        }
      });

      await callNotifier.initiateCall(
        _community.id,
        _community.name,
        profilePicture,
        CallType.video,
      );

      // Navigate to active call screen via overlay navigator
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

    } catch (e) {
      // Error is already handled via the callback, no need to handle again
    }
  }

  Future<void> _makeVoiceCall() async {
    final l10n = AppLocalizations.of(context)!;
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseLoginToCall),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userId == _community.id) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotCallYourself),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final callNotifier = ref.read(callProvider.notifier);
      final profilePicture = _getProfileImageUrl();

      // Setup error callback to handle permission errors
      callNotifier.setCallErrorCallback((error) {
        if (mounted) {
          _handleCallError(context, error);
        }
      });

      await callNotifier.initiateCall(
        _community.id,
        _community.name,
        profilePicture,
        CallType.audio,
      );

      // Navigate to active call screen via overlay navigator
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

    } catch (e) {
      // Error is already handled via the callback, no need to handle again
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
      ),
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    final calculatedAge = calculateAge(_community.birth_year);
    final age = PrivacyUtils.getAge(_community, calculatedAge);
    final locationText = PrivacyUtils.getLocationText(_community);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Custom SliverAppBar with hero header
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              title: innerBoxIsScrolled
                  ? Text(
                      age != null ? '${_community.name}, $age' : _community.name,
                    )
                  : null,
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh_rounded,
                      color: innerBoxIsScrolled
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Colors.white),
                  tooltip: 'Refresh',
                  onPressed: _refreshProfile,
                ),
                if (userId.isNotEmpty && userId != _community.id)
                  _buildMoreMenu(context, innerBoxIsScrolled),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildCompactHeader(age, locationText),
              ),
            ),
            // Action buttons (pinned below header)
            SliverToBoxAdapter(
              child: _buildActionButtonsSection(),
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
            // Overview Tab
            _buildOverviewTab(),
            // About Tab
            _buildAboutTab(),
            // Moments Tab
            _buildMomentsTab(),
          ],
        ),
      ),
    );
  }

  /// Build more menu (report/block)
  Widget _buildMoreMenu(BuildContext context, bool isScrolled) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: isScrolled ? Theme.of(context).colorScheme.onSurface : Colors.white,
      ),
      onSelected: (value) async {
        if (value == 'report') {
          showDialog(
            context: context,
            builder: (context) => ReportDialog(
              type: 'user',
              reportedId: _community.id,
              reportedUserId: _community.id,
            ),
          );
        } else if (value == 'block') {
          if (userId.isNotEmpty && userId != _community.id) {
            await BlockUserDialog.show(
              context: context,
              currentUserId: userId,
              targetUserId: _community.id,
              targetUserName: _community.name,
              targetUserAvatar: _getProfileImageUrl(),
              ref: ref,
              onBlocked: () {
                setState(() => isBlocked = true);
                if (mounted) Navigator.of(context).pop();
              },
            );
          }
        } else if (value == 'unblock') {
          await _handleUnblock();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(l10n.reportUser),
            ],
          ),
        ),
        if (isBlocked)
          PopupMenuItem(
            value: 'unblock',
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.unblockUser, style: const TextStyle(color: Colors.green)),
              ],
            ),
          )
        else
          PopupMenuItem(
            value: 'block',
            child: Row(
              children: [
                const Icon(Icons.block, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(l10n.blockUser, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }

  /// Build compact header with map, avatar, name
  Widget _buildCompactHeader(int? age, String locationText) {
    return Stack(
      children: [
        // Map or gradient background
        Positioned.fill(
          child: _hasValidCoordinates()
              ? _buildMapTileGrid()
              : _buildGradientBackground(),
        ),
        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 150,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
        // Profile info at bottom
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              // Avatar
              InkWell(
                onTap: () {
                  final imageUrls = _getImageUrls();
                  if (imageUrls.isNotEmpty) {
                    Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (context) => ImageGallery(imageUrls: imageUrls),
                      ),
                    );
                  }
                },
                child: Hero(
                  tag: 'profile_${_community.id}',
                  child: VipAvatarFrame(
                    isVip: _community.isVip,
                    size: 80,
                    frameWidth: 3,
                    showGlow: true,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 37,
                        backgroundColor: AppColors.accent,
                        backgroundImage: _getProfileImageUrl() != null
                            ? NetworkImage(_getProfileImageUrl()!)
                            : null,
                        child: _getProfileImageUrl() == null
                            ? const Icon(Icons.person, size: 40, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name and info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _community.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black45),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_community.isVip) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium, size: 12, color: Colors.white),
                                SizedBox(width: 2),
                                Text('VIP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_community.displayUsername != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _community.displayUsername!,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _copyUsername(_community.displayUsername!),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.copy_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (age != null) ...[
                          Text(
                            '$age yrs',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                          ),
                          if (locationText.isNotEmpty) ...[
                            Text(' • ', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                          ],
                        ],
                        if (locationText.isNotEmpty) ...[
                          const Icon(Icons.location_on, size: 12, color: Colors.white70),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              locationText,
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
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

  /// Build action buttons section (below header, above tabs)
  Widget _buildActionButtonsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(bottom: BorderSide(color: context.dividerColor, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactActionButton(
            Icons.videocam_rounded,
            l10n.videoCall,
            Colors.blue[600]!,
            _makeVideoCall,
          ),
          _buildCompactActionButton(
            Icons.call_rounded,
            l10n.voiceCall,
            Colors.green[600]!,
            _makeVoiceCall,
          ),
          _buildCompactActionButton(
            Icons.chat_bubble_rounded,
            l10n.message,
            AppColors.accent,
            _navigateToChat,
          ),
          _buildCompactActionButton(
            isFollower ? Icons.check_circle_rounded : Icons.person_add_rounded,
            isFollower ? l10n.following : l10n.follow,
            isFollower ? Colors.green[600]! : Colors.blue[600]!,
            isFollower
                ? () => unFollowUser(userId, _community.id)
                : () => followUser(userId, _community.id),
          ),
        ],
      ),
    );
  }

  /// Compact action button for header
  Widget _buildCompactActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  /// Overview Tab - Match info, stats, conversation starters
  Widget _buildOverviewTab() {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      key: const PageStorageKey<String>('overview'),
      padding: const EdgeInsets.all(16),
      children: [
        // VIP Upsell Banner
        if (_community.isVip) ...[
          Builder(
            builder: (context) {
              final userAsync = ref.watch(userProvider);
              final isCurrentUserVip = userAsync.valueOrNull?.isVip ?? false;
              return VipUpsellBanner(
                userName: _community.name,
                isCurrentUserVip: isCurrentUserVip,
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Language Match Card
        LanguageMatchCard(profile: _community),

        const SizedBox(height: 12),
        const SmallBannerAdWidget(),

        // Engagement Stats Bar
        EngagementStatsBar(profile: _community),

        const SizedBox(height: 16),

        // Stats section
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                '${_community.followers.length}',
                l10n.followers,
                Icons.people_rounded,
                AppColors.accent,
              ),
              Container(height: 50, width: 1, color: context.dividerColor),
              _buildStatItem(
                '${_community.followings.length}',
                l10n.following,
                Icons.person_add_rounded,
                Colors.blue[600]!,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Conversation Starters
        ConversationStartersCard(profile: _community),

        const SizedBox(height: 16),

        // Quick chat button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _navigateToChat,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: Text(l10n.messageUser(_community.name)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),

      ],
    );
  }

  /// About Tab - Bio, languages, interests, personal info
  Widget _buildAboutTab() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      key: const PageStorageKey<String>('about'),
      padding: const EdgeInsets.all(16),
      children: [
        // Bio Section
        _buildBioSection(isDark),

        const SizedBox(height: 12),

        // Story Highlights
        ProfileHighlights(
          userId: widget.community.id,
          isOwnProfile: false,
          user: widget.community,
        ),

        const SizedBox(height: 12),

        // Languages Section
        _buildLanguagesSection(isDark),

        const SizedBox(height: 12),

        // Interests
        _buildInterestsSection(isDark),

        // Personal Info (MBTI, Blood Type)
        _buildPersonalInfoSection(isDark),
      ],
    );
  }

  /// Build Bio Section with improved UI
  Widget _buildBioSection(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final hasBio = _community.bio.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : context.dividerColor,
          width: 0.5,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.blue[700]!, Colors.blue[900]!]
                        : [Colors.blue[400]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.bio,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bio content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              hasBio ? _community.bio : l10n.noBioYet,
              style: context.bodyMedium.copyWith(
                color: hasBio ? context.textPrimary : context.textMuted,
                fontStyle: hasBio ? FontStyle.normal : FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Languages Section with improved UI
  Widget _buildLanguagesSection(bool isDark) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : context.dividerColor,
          width: 0.5,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.green[700]!, Colors.teal[800]!]
                        : [Colors.green[400]!, Colors.teal[500]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.languages,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Language cards
          Row(
            children: [
              // Native language
              Expanded(
                child: _buildLanguageCard(
                  label: l10n.native,
                  language: _community.native_language,
                  flag: _getLanguageFlag(_community.native_language),
                  icon: Icons.home_rounded,
                  color: Colors.orange,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              // Arrow
              Icon(
                Icons.arrow_forward_rounded,
                color: context.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              // Learning language
              Expanded(
                child: _buildLanguageCard(
                  label: l10n.learning,
                  language: _community.language_to_learn,
                  flag: _getLanguageFlag(_community.language_to_learn),
                  icon: Icons.school_rounded,
                  color: Colors.purple,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual language card
  Widget _buildLanguageCard({
    required String label,
    required String language,
    required String flag,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.captionSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            language,
            style: context.labelMedium.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getLanguageFlag(String language) => LanguageFlags.getFlagByName(language);

  /// Moments Tab - Grid of moments
  Widget _buildMomentsTab() {
    return ListView(
      key: const PageStorageKey<String>('moments'),
      padding: const EdgeInsets.all(16),
      children: [
        _buildMomentsSection(),
      ],
    );
  }

  /// Build Interests Section - horizontal scrollable chips showing user's topics
  /// Highlights shared interests with the current user
  Widget _buildInterestsSection(bool isDark) {
    // Return empty widget if no topics
    if (_community.topics.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get current user's topics for comparison
    final currentUserAsync = ref.watch(userProvider);
    final currentUser = currentUserAsync.valueOrNull;
    final myTopics = currentUser?.topics.toSet() ?? <String>{};
    final theirTopics = _community.topics.toSet();
    final sharedTopics = myTopics.intersection(theirTopics);

    // Sort: shared first, then unique
    final sortedTopics = [
      ...sharedTopics,
      ...theirTopics.difference(sharedTopics),
    ].toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : context.dividerColor,
          width: 0.5,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with shared count
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.pink[700]!, Colors.orange[800]!]
                        : [Colors.pink[400]!, Colors.orange[400]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.interests,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              if (sharedTopics.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.handshake_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${sharedTopics.length} shared',
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
          const SizedBox(height: 16),
          // Wrap of topic chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedTopics.map((topicId) {
              final isShared = sharedTopics.contains(topicId);

              // Find the topic from default topics
              final topic = Topic.defaultTopics.firstWhere(
                (t) => t.id == topicId,
                orElse: () => Topic(
                  id: topicId,
                  name: topicId.replaceAll('_', ' ').split(' ').map((word) =>
                    word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
                  ).join(' '),
                  icon: '🏷️',
                  category: 'other',
                ),
              );

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isShared
                      ? (isDark
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.1))
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : context.containerColor),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isShared
                        ? AppColors.primary.withValues(alpha: isDark ? 0.5 : 0.3)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : context.dividerColor),
                    width: isShared ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(topic.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      topic.name,
                      style: context.labelMedium.copyWith(
                        color: isShared ? AppColors.primary : context.textPrimary,
                        fontWeight: isShared ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (isShared) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build Moments Section - 3-column grid showing user's moments
  Widget _buildMomentsSection() {
    return Consumer(
      builder: (context, ref, child) {
        final momentsAsync = ref.watch(userMomentsProvider(_community.id));

        return momentsAsync.when(
          loading: () => _buildMomentsLoading(),
          error: (error, stack) => _buildMomentsError(error.toString()),
          data: (moments) {
            if (moments.isEmpty) {
              return _buildMomentsEmpty();
            }
            return _buildMomentsGrid(moments);
          },
        );
      },
    );
  }

  /// Build moments loading state with shimmer placeholders
  Widget _buildMomentsLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMomentsHeader(0, isLoading: true),
        Spacing.gapSM,
        // Show 2 placeholder post cards
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
                // Header placeholder
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
                // Text placeholder
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
                // Image placeholder
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

  /// Build moments error state
  Widget _buildMomentsError(String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMomentsHeader(0),
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
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build moments empty state
  Widget _buildMomentsEmpty() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMomentsHeader(0),
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
                child: Icon(
                  Icons.photo_library_outlined,
                  size: 32,
                  color: context.textMuted,
                ),
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
                AppLocalizations.of(context)!.hasntSharedMoments(_community.name),
                style: context.caption.copyWith(color: context.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build moments header with count badge
  Widget _buildMomentsHeader(int count, {bool isLoading = false}) {
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
            child: const Icon(
              Icons.photo_library_rounded,
              color: AppColors.primary,
              size: 18,
            ),
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

  /// Build moments list in Facebook post style
  Widget _buildMomentsGrid(List<Moments> moments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMomentsHeader(moments.length),
        Spacing.gapSM,
        // Facebook-style post list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: moments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final moment = moments[index];
            return _buildMomentPost(moment);
          },
        ),
      ],
    );
  }

  /// Build individual moment as a Facebook-style post
  Widget _buildMomentPost(Moments moment) {
    final hasVideo = moment.hasVideo;
    final hasImages = moment.hasImages;
    final hasMultipleImages = moment.imageUrls.length > 1;
    final hasText = moment.description.isNotEmpty;
    final displayText = moment.description;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _navigateToMoment(moment),
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
            // Post header with avatar, name, and time
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accent,
                    backgroundImage: _getProfileImageUrl() != null
                        ? NetworkImage(_getProfileImageUrl()!)
                        : null,
                    child: _getProfileImageUrl() == null
                        ? const Icon(Icons.person, size: 18, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  // Name and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _community.name,
                          style: context.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimeAgo(moment.createdAt),
                          style: context.captionSmall.copyWith(
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Post text content
            if (hasText)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  displayText,
                  style: context.bodyMedium.copyWith(
                    color: context.textPrimary,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            if (hasText && (hasImages || hasVideo))
              const SizedBox(height: 10),

            // Media content (images/video)
            if (hasImages || hasVideo)
              _buildMomentMedia(moment, hasVideo, hasImages, hasMultipleImages),

            // Divider before engagement
            Divider(
              height: 1,
              thickness: 0.5,
              color: isDark ? Colors.white.withValues(alpha: 0.1) : context.dividerColor,
            ),

            // Engagement stats (likes, comments)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Like count
                  if (moment.likeCount > 0) ...[
                    Icon(Icons.favorite, size: 16, color: Colors.red[400]),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(moment.likeCount),
                      style: context.labelSmall.copyWith(color: context.textSecondary),
                    ),
                    const SizedBox(width: 16),
                  ],
                  // Comment count
                  if (moment.commentCount > 0) ...[
                    Icon(Icons.chat_bubble_outline, size: 15, color: context.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatCount(moment.commentCount)} ${moment.commentCount == 1 ? 'comment' : 'comments'}',
                      style: context.labelSmall.copyWith(color: context.textSecondary),
                    ),
                  ],
                  // If no engagement, show placeholder
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

  /// Build media section for a moment (images or video)
  Widget _buildMomentMedia(Moments moment, bool hasVideo, bool hasImages, bool hasMultipleImages) {
    final videoThumbnail = moment.video?.thumbnail;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayColor = isDark
        ? Colors.black.withValues(alpha: 0.7)
        : Colors.black.withValues(alpha: 0.5);

    if (hasVideo && videoThumbnail != null && videoThumbnail.isNotEmpty) {
      // Video thumbnail with play button
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedImageWidget(
              imageUrl: videoThumbnail,
              fit: BoxFit.cover,
            ),
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
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      );
    } else if (hasImages && moment.imageUrls.isNotEmpty) {
      // Single image or multiple images
      if (moment.imageUrls.length == 1) {
        // Single image
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: CachedImageWidget(
            imageUrl: moment.imageUrls.first,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        );
      } else if (moment.imageUrls.length == 2) {
        // Two images side by side
        return Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedImageWidget(
                  imageUrl: moment.imageUrls[0],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: isDark ? 1 : 2),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedImageWidget(
                  imageUrl: moment.imageUrls[1],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        );
      } else {
        // 3+ images - show first image large, rest in grid with "+N" overlay
        return Column(
          children: [
            // First image full width
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: CachedImageWidget(
                imageUrl: moment.imageUrls.first,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            SizedBox(height: isDark ? 1 : 2),
            // Remaining images in row
            SizedBox(
              height: 100,
              child: Row(
                children: [
                  Expanded(
                    child: CachedImageWidget(
                      imageUrl: moment.imageUrls[1],
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: isDark ? 1 : 2),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedImageWidget(
                          imageUrl: moment.imageUrls.length > 2 ? moment.imageUrls[2] : moment.imageUrls[1],
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

  /// Format timestamp to relative time (e.g., "2h ago", "3d ago")
  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  /// Format count for display (1000 -> 1K, 1000000 -> 1M)
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  /// Navigate to single moment page
  void _navigateToMoment(Moments moment) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => SingleMoment(moment: moment),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        Spacing.gapSM,
        Text(value, style: context.displaySmall),
        Spacing.gapXXS,
        Text(label, style: context.labelSmall),
      ],
    );
  }

  /// Build Personal Info Section (MBTI, Blood Type)
  Widget _buildPersonalInfoSection(bool isDark) {
    final hasMbti = _community.mbti.isNotEmpty;
    final hasBloodType = _community.bloodType.isNotEmpty;

    // Return empty widget if no personal info
    if (!hasMbti && !hasBloodType) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : context.dividerColor,
          width: 0.5,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.purple[700]!, Colors.indigo[800]!]
                        : [Colors.purple[400]!, Colors.indigo[500]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.aboutMe,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Personal info chips in row
          Row(
            children: [
              if (hasMbti)
                Expanded(
                  child: _buildPersonalInfoChip(
                    icon: '🧠',
                    label: 'MBTI',
                    value: _community.mbti.toUpperCase(),
                    color: Colors.indigo,
                    isDark: isDark,
                  ),
                ),
              if (hasMbti && hasBloodType)
                const SizedBox(width: 12),
              if (hasBloodType)
                Expanded(
                  child: _buildPersonalInfoChip(
                    icon: '🩸',
                    label: AppLocalizations.of(context)!.bloodType,
                    value: _community.bloodType.toUpperCase(),
                    color: Colors.red,
                    isDark: isDark,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a personal info chip
  Widget _buildPersonalInfoChip({
    required String icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.captionSmall.copyWith(
                  color: context.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: context.titleMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Check if user has valid location data for map display
  bool _hasValidCoordinates() {
    final location = _community.location;
    final coords = location.coordinates;

    // Must have coordinates array with at least 2 values
    if (coords.length < 2) return false;

    final lon = coords[0];
    final lat = coords[1];

    // Check for valid, non-zero coordinates
    final hasValidCoords = lat != 0 && lon != 0 && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;

    // Also require at least some location info (city, country, or formatted address)
    final hasLocationInfo = location.city.isNotEmpty ||
        location.country.isNotEmpty ||
        location.formattedAddress.isNotEmpty;

    return hasValidCoords && hasLocationInfo;
  }

  /// Round coordinates for privacy (reduces precision to ~1km area)
  /// 2 decimal places = ~1.1km precision
  /// 1 decimal place = ~11km precision
  double _roundCoordinate(double coord, {int decimals = 2}) {
    final factor = math.pow(10, decimals);
    return (coord * factor).round() / factor;
  }

  /// Build a grid of OSM tiles to create a map view
  /// Shows city/district level for privacy (not exact location)
  Widget _buildMapTileGrid() {
    final coords = _community.location.coordinates;
    // Round coordinates to 2 decimal places for privacy (~1km precision)
    final lon = _roundCoordinate(coords[0]);
    final lat = _roundCoordinate(coords[1]);
    // Zoom level 10-11 shows city/district level (privacy-friendly)
    // Zoom 14 = street level (too precise)
    // Zoom 11 = city/district level (good for privacy)
    // Zoom 8 = region level
    final zoom = 10;

    // Calculate center tile coordinates
    final n = 1 << zoom;
    final centerX = ((lon + 180) / 360 * n).floor();
    final latRad = lat * math.pi / 180;
    final centerY = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n).floor();

    // Create a 3x2 grid of tiles (3 wide, 2 tall)
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background color while loading
          Container(color: AppColors.gray300),
          // Tile grid - positioned to center on the location
          Positioned.fill(
            child: Row(
              children: [
                for (int dx = -1; dx <= 1; dx++)
                  Expanded(
                    child: Column(
                      children: [
                        for (int dy = 0; dy <= 1; dy++)
                          Expanded(
                            child: Image.network(
                              'https://tile.openstreetmap.org/$zoom/${centerX + dx}/${centerY + dy}.png',
                              fit: BoxFit.cover,
                              headers: const {
                                'User-Agent': 'Bananatalk App',
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.gray300,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Area indicator (circle showing approximate region, not exact point)
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00BFA5).withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.location_city_rounded,
                  color: Color(0xFF00BFA5),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build gradient background when no map available
  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00BFA5),
            Color(0xFF00ACC1),
            Color(0xFF26C6DA),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.location_off_rounded,
          size: 48,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  /// Open location in external maps app (city level for privacy)
  Future<void> _openLocationInMaps() async {
    final coords = _community.location.coordinates;
    if (coords.length < 2) return;

    // Round coordinates for privacy (~1km precision)
    final lon = _roundCoordinate(coords[0]);
    final lat = _roundCoordinate(coords[1]);
    final location = _community.location;

    // Open at city/district level (zoom 10) with rounded coords for privacy
    final Uri mapsUrl = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon&zoom=10',
    );

    try {
      await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.couldNotOpenMaps}: ${location.city}, ${location.country}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

/// Delegate for pinned tab bar in SliverPersistentHeader
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || backgroundColor != oldDelegate.backgroundColor;
  }
}
