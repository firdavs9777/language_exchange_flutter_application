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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeUserState();
  }

  Future<void> _checkBlockStatus() async {
    try {
      final result = await BlockService.checkBlockStatus(
        userId: userId,
        targetUserId: widget.community.id,
      );

      if (result['success'] == true) {
        setState(() {
          isBlocked = result['isBlocked'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking block status: $e');
    }
  }

  Future<void> _initializeUserState() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    setState(() {
      isFollower = widget.community.followers.contains(userId);
    });
    if (userId.isNotEmpty && userId != widget.community.id) {
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
        userId: widget.community.id,
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
    if (userId.isEmpty || userId == widget.community.id) {
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
      print('Error checking profile view limits: $e');
    }
  }

  int calculateAge(String birthYear) {
    final currentYear = DateTime.now().year;
    return currentYear - int.parse(birthYear);
  }

  Future<void> _handleUnblock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.unblockUser),
        content:
            Text('Are you sure you want to unblock ${widget.community.name}?'),
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
        blockedUserId: widget.community.id,
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
    try {
      await ref.read(communityServiceProvider).followUser(
            userId: userId,
            targetUserId: targetUserId,
          );
      setState(() {
        isFollower = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You followed ${widget.community.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to follow user')),
      );
    }
  }

  void unFollowUser(String userId, String targetUserId) async {
    bool? shouldUnfollow = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unfollow ${widget.community.name}'),
          content: Text('Are you sure you want to unfollow this user?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Unfollow'),
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
        setState(() {
          isFollower = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You unfollowed ${widget.community.name}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unfollow user')),
        );
      }
    }
  }

  void _navigateToChat() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
          userId: widget.community.id,
          userName: widget.community.name,
          profilePicture: widget.community.imageUrls.isNotEmpty
              ? widget.community.imageUrls[0]
              : null,
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

    if (userId == widget.community.id) {
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
      final profilePicture = widget.community.imageUrls.isNotEmpty
          ? widget.community.imageUrls[0]
          : null;

      // Setup error callback to handle permission errors
      callNotifier.setCallErrorCallback((error) {
        if (mounted) {
          _handleCallError(context, error);
        }
      });

      await callNotifier.initiateCall(
        widget.community.id,
        widget.community.name,
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

      print('✅ Video call initiated to ${widget.community.name}');
    } catch (e) {
      print('❌ Error initiating video call: $e');
      if (mounted) {
        _handleCallError(context, e.toString());
      }
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

    if (userId == widget.community.id) {
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
      final profilePicture = widget.community.imageUrls.isNotEmpty
          ? widget.community.imageUrls[0]
          : null;

      // Setup error callback to handle permission errors
      callNotifier.setCallErrorCallback((error) {
        if (mounted) {
          _handleCallError(context, error);
        }
      });

      await callNotifier.initiateCall(
        widget.community.id,
        widget.community.name,
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

      print('✅ Voice call initiated to ${widget.community.name}');
    } catch (e) {
      print('❌ Error initiating voice call: $e');
      if (mounted) {
        _handleCallError(context, e.toString());
      }
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
    final calculatedAge = calculateAge(widget.community.birth_year);
    final age = PrivacyUtils.getAge(widget.community, calculatedAge);
    final locationText = PrivacyUtils.getLocationText(widget.community);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          age != null
              ? '${widget.community.name}, $age'
              : widget.community.name,
        ),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          if (userId.isNotEmpty && userId != widget.community.id)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onSelected: (value) async {
                if (value == 'report') {
                  showDialog(
                    context: context,
                    builder: (context) => ReportDialog(
                      type: 'user',
                      reportedId: widget.community.id,
                      reportedUserId: widget.community.id,
                    ),
                  );
                } else if (value == 'block') {
                  if (userId.isNotEmpty && userId != widget.community.id) {
                    await BlockUserDialog.show(
                      context: context,
                      currentUserId: userId,
                      targetUserId: widget.community.id,
                      targetUserName: widget.community.name,
                      targetUserAvatar: widget.community.imageUrls.isNotEmpty
                          ? widget.community.imageUrls[0]
                          : null,
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
                    if (widget.community.imageUrls.isNotEmpty) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageGallery(
                                imageUrls: widget.community.imageUrls),
                          ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No images available')),
                      );
                    }
                  },
                  child: Hero(
                    tag: 'profile_${widget.community.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
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
                        backgroundImage: widget.community.imageUrls.isNotEmpty
                            ? NetworkImage(widget.community.imageUrls[0])
                            : null,
                        child: widget.community.imageUrls.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.white,
                              )
                            : null,
                        onBackgroundImageError: (exception, stackTrace) {
                          // Image failed to load, will use icon fallback
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  widget.community.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
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

              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildActionButton(
                    Icons.video_call,
                    'Video',
                    Colors.blue[600]!,
                    _makeVideoCall,
                  ),
                  _buildActionButton(
                    Icons.call,
                    'Call',
                    Colors.green[600]!,
                    _makeVoiceCall,
                  ),
                  _buildActionButton(
                    Icons.message,
                    'Message',
                    Colors.purple[600]!,
                    _navigateToChat,
                  ),
                  _buildActionButton(
                    isFollower ? Icons.check_circle : Icons.person_add,
                    isFollower ? 'Following' : 'Follow',
                    isFollower ? Colors.green[600]! : Colors.blue[600]!,
                    isFollower
                        ? () => unFollowUser(userId, widget.community.id)
                        : () => followUser(userId, widget.community.id),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Stats section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      '${widget.community.followers.length}',
                      'Followers',
                      Icons.people,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    _buildStatItem(
                      '${widget.community.followings?.length ?? 0}',
                      'Following',
                      Icons.person_add,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.grey),

              _buildCard(
                Icons.person,
                'Bio',
                widget.community.bio.isNotEmpty
                    ? widget.community.bio
                    : 'No bio available yet.',
                Colors.blue[600]!,
              ),

              _buildCard(
                Icons.language,
                'Languages',
                'Native: ${widget.community.native_language}\nLearning: ${widget.community.language_to_learn}',
                Colors.green[600]!,
              ),

              const SizedBox(height: 16),

              // Quick chat button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _navigateToChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label:
                      Text('Start Conversation with ${widget.community.name}'),
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

  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
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
}
