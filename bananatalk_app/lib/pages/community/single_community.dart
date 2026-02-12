import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/services/profile_visitor_service.dart';
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';
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

class SingleCommunity extends ConsumerStatefulWidget {
  final Community community;
  const SingleCommunity({super.key, required this.community});

  @override
  _SingleCommunityState createState() => _SingleCommunityState();
}

class _SingleCommunityState extends ConsumerState<SingleCommunity> {
  bool isFollower = false;
  bool isBlocked = false;
  String userId = ''; // Initialize to empty string instead of late
  Community? _updatedCommunity; // Holds refreshed data after follow/unfollow

  /// Get current community data (updated or original)
  Community get _community => _updatedCommunity ?? widget.community;

  @override
  void initState() {
    super.initState();
    _debugCommunityData();
    _initializeUserState();
  }

  /// Refresh profile data after follow/unfollow
  Future<void> _refreshProfile() async {
    try {
      debugPrint('🔄 Refreshing profile...');
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
        debugPrint('✅ Profile refreshed:');
        debugPrint('   - Followers: ${refreshedData.followers.length} (${refreshedData.followers})');
        debugPrint('   - Following: ${refreshedData.followings.length}');
        debugPrint('   - isFollower updated to: $isNowFollowing');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to refresh profile: $e');
    }
  }

  void _debugCommunityData() {
    debugPrint('========== COMMUNITY DETAIL DEBUG ==========');
    debugPrint('User ID: ${_community.id}');
    debugPrint('User Name: ${_community.name}');
    debugPrint('Images array: ${_community.images}');
    debugPrint('Images count: ${_community.images.length}');
    debugPrint('ImageUrls array: ${_community.imageUrls}');
    debugPrint('ImageUrls count: ${_community.imageUrls.length}');
    debugPrint('Effective image URLs: ${_getImageUrls()}');
    debugPrint('Followers: ${_community.followers}');
    debugPrint('Followers count: ${_community.followers.length}');
    debugPrint('Following: ${_community.followings}');
    debugPrint('Following count: ${_community.followings.length}');
    debugPrint('---------- LOCATION DEBUG ----------');
    debugPrint('Location city: "${_community.location.city}"');
    debugPrint('Location country: "${_community.location.country}"');
    debugPrint('Location state: "${_community.location.state}"');
    debugPrint('Location street: "${_community.location.street}"');
    debugPrint('Location formattedAddress: "${_community.location.formattedAddress}"');
    debugPrint('Location coordinates: ${_community.location.coordinates}');
    debugPrint('Location type: "${_community.location.type}"');
    debugPrint('Has valid coords for map: ${_hasValidCoordinates()}');
    debugPrint('============================================');
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
      debugPrint('Error checking block status: $e');
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

        debugPrint('🔍 Follow check - userId: $userId, profileId: ${_community.id}');
        debugPrint('🔍 Current user followings: ${currentUser.followings}');
        debugPrint('🔍 Is following (from current user): $isFollowingFromCurrentUser');
        debugPrint('🔍 Is following (from profile): $isFollowingFromProfile');

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
      debugPrint('⚠️ Error checking follow status: $e');
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
      debugPrint('✅ Profile visit recorded');
    } catch (e) {
      // Silently fail - don't disrupt user experience
      debugPrint('⚠️ Failed to record profile visit: $e');
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
      debugPrint('Error checking profile view limits: $e');
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
        const SnackBar(
          content: Text('Please login to follow users'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      debugPrint('📤 Following - userId: $userId, targetUserId: $targetUserId');
      debugPrint('📤 Current isFollower state: $isFollower');

      final result = await ref.read(communityServiceProvider).followUser(
            userId: userId,
            targetUserId: targetUserId,
          );

      debugPrint('📥 Follow result: $result');

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result == 'already_following'
                  ? 'You are already following ${_community.name}'
                  : 'You followed ${_community.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to follow user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Follow error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to follow user: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void unFollowUser(String userId, String targetUserId) async {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to manage follows'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool? shouldUnfollow = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unfollow ${_community.name}'),
          content: const Text('Are you sure you want to unfollow this user?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Unfollow'),
            ),
          ],
        );
      },
    );

    if (shouldUnfollow == true) {
      try {
        debugPrint('📤 Unfollowing - userId: $userId, targetUserId: $targetUserId');
        debugPrint('📤 Current isFollower state: $isFollower');

        final result = await ref.read(communityServiceProvider).unfollowUser(
              userId: userId,
              targetUserId: targetUserId,
            );

        debugPrint('📥 Unfollow result: $result');

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result == 'not_following'
                    ? 'You were not following ${_community.name}'
                    : 'You unfollowed ${_community.name}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to unfollow user'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Unfollow error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unfollow user: ${e.toString().replaceAll('Exception: ', '')}'),
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
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to make a call'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userId == _community.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot call yourself'),
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

      debugPrint('✅ Video call initiated to ${_community.name}');
    } catch (e) {
      // Error is already handled via the callback, no need to handle again
      debugPrint('❌ Error initiating video call: $e');
    }
  }

  Future<void> _makeVoiceCall() async {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to make a call'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userId == _community.id) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot call yourself'),
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

      debugPrint('✅ Voice call initiated to ${_community.name}');
    } catch (e) {
      // Error is already handled via the callback, no need to handle again
      debugPrint('❌ Error initiating voice call: $e');
    }
  }

  void _handleCallError(BuildContext context, String error) {
    if (error.startsWith('PERMANENTLY_DENIED:')) {
      final message = error.substring('PERMANENTLY_DENIED:'.length);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                AppSettings.openAppSettings();
              },
              child: const Text('Open Settings'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          age != null
              ? '${_community.name}, $age'
              : _community.name,
        ),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          if (userId.isNotEmpty && userId != _community.id)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
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
                        // Update blocked status
                        setState(() {
                          isBlocked = true;
                        });
                        // Navigate back after blocking
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  }
                } else if (value == 'unblock') {
                  // ADD UNBLOCK HANDLER
                  await _handleUnblock();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text('Report User'),
                    ],
                  ),
                ),
                // CONDITIONAL MENU ITEM - Show Block or Unblock
                if (isBlocked)
                  const PopupMenuItem(
                    value: 'unblock',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Unblock User',
                            style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  )
                else
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Block User', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: InkWell(
                  onTap: () {
                    final imageUrls = _getImageUrls();
                    if (imageUrls.isNotEmpty) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageGallery(
                                imageUrls: imageUrls),
                          ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No images available')),
                      );
                    }
                  },
                  child: Hero(
                    tag: 'profile_${_community.id}',
                    child: VipAvatarFrame(
                      isVip: _community.isVip,
                      size: 160,
                      frameWidth: 4,
                      showGlow: true,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _community.isVip ? null : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: const Color(0xFF00BFA5),
                          backgroundImage: _getProfileImageUrl() != null
                              ? NetworkImage(_getProfileImageUrl()!)
                              : null,
                          onBackgroundImageError: _getProfileImageUrl() != null
                              ? (exception, stackTrace) {
                                  debugPrint('Profile image failed to load: $exception');
                                }
                              : null,
                          child: _getProfileImageUrl() == null
                              ? const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _community.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_community.isVip) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'VIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (age != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '$age years old',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (locationText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        locationText,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // VIP Upsell Banner - shown when viewing VIP user profile
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

              // Action buttons row - modern style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    // Video call - disabled for now
                    _buildActionButton(
                      Icons.videocam_rounded,
                      'Video',
                      Colors.grey[400]!,
                      () => _showComingSoonSnackbar('Video call'),
                      isDisabled: true,
                    ),
                    // Voice call - disabled for now
                    _buildActionButton(
                      Icons.call_rounded,
                      'Call',
                      Colors.grey[400]!,
                      () => _showComingSoonSnackbar('Voice call'),
                      isDisabled: true,
                    ),
                    _buildActionButton(
                      Icons.chat_bubble_rounded,
                      'Message',
                      const Color(0xFF00BFA5),
                      _navigateToChat,
                    ),
                    _buildActionButton(
                      isFollower ? Icons.check_circle_rounded : Icons.person_add_rounded,
                      isFollower ? 'Following' : 'Follow',
                      isFollower ? Colors.green[600]! : Colors.blue[600]!,
                      isFollower
                          ? () => unFollowUser(userId, _community.id)
                          : () => followUser(userId, _community.id),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Stats section - modern card style
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      '${_community.followers.length}',
                      'Followers',
                      Icons.people_rounded,
                      const Color(0xFF00BFA5),
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: Colors.grey[200],
                    ),
                    _buildStatItem(
                      '${_community.followings.length}',
                      'Following',
                      Icons.person_add_rounded,
                      Colors.blue[600]!,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.grey),

              _buildCard(
                Icons.person,
                'Bio',
                _community.bio.isNotEmpty
                    ? _community.bio
                    : 'No bio available yet.',
                Colors.blue[600]!,
              ),

              _buildCard(
                Icons.language,
                'Languages',
                'Native: ${_community.native_language}\nLearning: ${_community.language_to_learn}',
                Colors.green[600]!,
              ),

              // Location Map Section
              if (_hasValidCoordinates()) ...[
                const SizedBox(height: 16),
                _buildLocationMapCard(),
              ],

              const SizedBox(height: 16),

              // Quick chat button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _navigateToChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label:
                      Text('Start Conversation with ${_community.name}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon!'),
        backgroundColor: Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    bool isDisabled = false,
  }) {
    final displayColor = isDisabled ? Colors.grey[400]! : color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: displayColor.withOpacity(isDisabled ? 0.08 : 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: isDisabled
                        ? null
                        : Border.all(
                            color: displayColor.withOpacity(0.2),
                            width: 1,
                          ),
                  ),
                  child: Icon(icon, color: displayColor, size: 26),
                ),
                if (isDisabled)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[400],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Soon',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: displayColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
      IconData icon, String title, String content, Color iconColor) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
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

  /// Get OpenStreetMap static map URL
  String _getStaticMapUrl() {
    final coords = _community.location.coordinates;
    final lon = coords[0];
    final lat = coords[1];
    // Using OpenStreetMap static map service
    // Zoom level 12 shows neighborhood level (not too precise for privacy)
    return 'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lon&zoom=12&size=600x300&maptype=mapnik&markers=$lat,$lon,red-pushpin';
  }

  /// Build location map card like HelloTalk
  Widget _buildLocationMapCard() {
    final location = _community.location;
    final coords = location.coordinates;

    // Build location text - prefer city/country, fallback to formatted address
    String locationText = [
      if (location.city.isNotEmpty) location.city,
      if (location.country.isNotEmpty) location.country,
    ].join(', ');

    // If no city/country, try formatted address
    if (locationText.isEmpty && location.formattedAddress.isNotEmpty) {
      locationText = location.formattedAddress;
    }

    // Last resort: show approximate coordinates area
    if (locationText.isEmpty && coords.length >= 2) {
      final lat = coords[1];
      final lon = coords[0];
      locationText = 'Near ${lat.toStringAsFixed(1)}°, ${lon.toStringAsFixed(1)}°';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Image
          GestureDetector(
            onTap: () => _openLocationInMaps(),
            child: Stack(
              children: [
                // Static Map Image
                Image.network(
                  _getStaticMapUrl(),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 160,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFF00BFA5),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Map unavailable',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                // Location pin icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: Color(0xFF00BFA5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Location Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF00BFA5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locationText.isNotEmpty ? locationText : 'Unknown location',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tap to open indicator
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Open location in external maps app
  Future<void> _openLocationInMaps() async {
    final coords = _community.location.coordinates;
    if (coords.length < 2) return;

    final lon = coords[0];
    final lat = coords[1];
    final location = _community.location;

    // Try to open in maps app
    final Uri mapsUrl = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon&zoom=14',
    );

    try {
      await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps: ${location.city}, ${location.country}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
