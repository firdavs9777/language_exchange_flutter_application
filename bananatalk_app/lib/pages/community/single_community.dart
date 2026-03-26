import 'dart:math' as math;
import 'package:bananatalk_app/pages/chat/chat_single.dart';
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
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/services/profile_visitor_service.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
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

      // Navigate to active call screen
      if (mounted) {
        final currentCall = callNotifier.currentCall;
        if (currentCall != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
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

      // Navigate to active call screen
      if (mounted) {
        final currentCall = callNotifier.currentCall;
        if (currentCall != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
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
                      MaterialPageRoute(
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
                      Text(
                        _community.displayUsername!,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
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
    return ListView(
      key: const PageStorageKey<String>('about'),
      padding: const EdgeInsets.all(16),
      children: [
        // Bio
        _buildCard(
          Icons.person,
          l10n.bio,
          _community.bio.isNotEmpty ? _community.bio : l10n.noBioYet,
          Colors.blue[600]!,
        ),

        // Languages
        _buildCard(
          Icons.language,
          l10n.languages,
          '${l10n.native}: ${_community.native_language}\n${l10n.learning}: ${_community.language_to_learn}',
          Colors.green[600]!,
        ),

        // Interests
        _buildInterestsSection(),

        // Personal Info (MBTI, Blood Type)
        _buildPersonalInfoSection(),
      ],
    );
  }

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
  Widget _buildInterestsSection() {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with shared count
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.interests_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              Spacing.hGapSM,
              Text(AppLocalizations.of(context)!.interests, style: context.titleMedium),
              if (sharedTopics.isNotEmpty) ...[
                Spacing.hGapSM,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${sharedTopics.length} shared',
                    style: context.captionSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Horizontal list of topic chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sortedTopics.length,
            separatorBuilder: (context, index) => Spacing.hGapSM,
            itemBuilder: (context, index) {
              final topicId = sortedTopics[index];
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isShared
                      ? AppColors.primary.withOpacity(0.1)
                      : context.containerColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isShared ? AppColors.primary : context.dividerColor,
                    width: isShared ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(topic.icon, style: const TextStyle(fontSize: 14)),
                    Spacing.hGapXS,
                    Text(
                      topic.name,
                      style: context.labelMedium.copyWith(
                        color: isShared ? AppColors.primary : null,
                      ),
                    ),
                    if (isShared) ...[
                      Spacing.hGapXS,
                      Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        Spacing.gapMD,
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMomentsHeader(0, isLoading: true),
        Spacing.gapSM,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: context.containerColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Icon(Icons.photo_outlined, color: context.textMuted, size: 20),
              ),
            );
          },
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMomentsHeader(0),
        Spacing.gapSM,
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.containerColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.dividerColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined, size: 40, color: context.textMuted),
              Spacing.gapSM,
              Text(AppLocalizations.of(context)!.noMomentsYet, style: context.bodyMedium.copyWith(color: context.textSecondary)),
              Spacing.gapXS,
              Text(
                AppLocalizations.of(context)!.hasntSharedMoments(_community.name),
                style: context.caption,
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

  /// Build moments grid with thumbnails
  Widget _buildMomentsGrid(List<Moments> moments) {
    // Show max 9 items in grid
    final displayMoments = moments.take(9).toList();
    final hasMore = moments.length > 9;
    final remainingCount = moments.length - 9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMomentsHeader(moments.length),
        Spacing.gapSM,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: displayMoments.length,
          itemBuilder: (context, index) {
            final moment = displayMoments[index];
            final isLastItem = index == 8 && hasMore;

            return GestureDetector(
              onTap: () => _navigateToMoment(moment),
              child: _buildMomentThumbnail(moment, isLastItem: isLastItem, remainingCount: remainingCount),
            );
          },
        ),
      ],
    );
  }

  /// Build individual moment thumbnail
  Widget _buildMomentThumbnail(Moments moment, {bool isLastItem = false, int remainingCount = 0}) {
    // Determine what to show: video thumbnail, image, or text preview
    final hasVideo = moment.hasVideo;
    final hasImages = moment.hasImages;
    final hasMultipleImages = moment.imageUrls.length > 1;

    Widget thumbnailContent;

    if (hasVideo && moment.video?.thumbnail != null) {
      // Video with thumbnail
      thumbnailContent = CachedImageWidget(
        imageUrl: moment.video!.thumbnail,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(4),
        errorWidget: _buildTextPreview(moment),
      );
    } else if (hasImages) {
      // Image(s)
      thumbnailContent = CachedImageWidget(
        imageUrl: moment.imageUrls.first,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(4),
        errorWidget: _buildTextPreview(moment),
      );
    } else {
      // Text-only moment
      thumbnailContent = _buildTextPreview(moment);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: thumbnailContent,
        ),
        // Video indicator
        if (hasVideo)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        // Multiple images indicator
        if (hasMultipleImages && !hasVideo)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.collections_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        // "+N" overlay for last item when there are more
        if (isLastItem)
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '+$remainingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build text preview for text-only moments
  Widget _buildTextPreview(Moments moment) {
    final text = moment.description.isNotEmpty ? moment.description : moment.title;

    return Container(
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(6),
      child: Center(
        child: Text(
          text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: context.captionSmall,
        ),
      ),
    );
  }

  /// Navigate to single moment page
  void _navigateToMoment(Moments moment) {
    Navigator.push(
      context,
      MaterialPageRoute(
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

  Widget _buildCard(
      IconData icon, String title, String content, Color iconColor) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: Spacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                Spacing.hGapSM,
                Text(title, style: context.titleMedium),
              ],
            ),
            Spacing.gapSM,
            Text(content, style: context.bodyMedium.copyWith(color: context.textSecondary)),
          ],
        ),
      ),
    );
  }

  /// Build Personal Info Section (MBTI, Blood Type)
  Widget _buildPersonalInfoSection() {
    final hasMbti = _community.mbti.isNotEmpty;
    final hasBloodType = _community.bloodType.isNotEmpty;

    // Return empty widget if no personal info
    if (!hasMbti && !hasBloodType) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: Spacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purple[600]!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.psychology_rounded, color: Colors.purple[600], size: 18),
                ),
                Spacing.hGapSM,
                Text(AppLocalizations.of(context)!.aboutMe, style: context.titleMedium),
              ],
            ),
            Spacing.gapSM,
            // Personal info chips
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (hasMbti)
                  _buildPersonalInfoChip(
                    icon: '🧠',
                    label: 'MBTI',
                    value: _community.mbti.toUpperCase(),
                    color: Colors.indigo,
                  ),
                if (hasBloodType)
                  _buildPersonalInfoChip(
                    icon: '🩸',
                    label: AppLocalizations.of(context)!.bloodType,
                    value: _community.bloodType.toUpperCase(),
                    color: Colors.red,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a personal info chip
  Widget _buildPersonalInfoChip({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          Spacing.hGapXS,
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
              Text(
                value,
                style: context.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
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
                                'User-Agent': 'BananaTalk App',
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
