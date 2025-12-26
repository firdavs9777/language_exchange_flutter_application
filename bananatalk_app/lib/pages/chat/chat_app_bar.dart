import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/call_provider.dart';
import 'package:bananatalk_app/providers/message_count_provider.dart';
import 'package:bananatalk_app/models/call_model.dart';
import 'package:bananatalk_app/screens/active_call_screen.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/utils/time_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'user_avatar.dart';
import 'chat_options_menu.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String userName;
  final String? profilePicture;
  final bool isTyping;
  final String? userId;
  final bool? isConnected;
  final bool? isOnline;
  final String? lastSeen;
  final VoidCallback? onThemeChanged;

  const ChatAppBar({
    Key? key,
    required this.userName,
    this.profilePicture,
    required this.isTyping,
    this.userId,
    this.isConnected,
    this.isOnline,
    this.lastSeen,
    this.onThemeChanged,
  }) : super(key: key);

  Widget _buildStatusWidget() {
    // Priority: typing > connecting > online/offline status
    if (isTyping) {
      return Text(
        'typing...',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    if (isConnected != null && !isConnected!) {
      return Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Connecting...',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    }
    
    // Show online/offline status
    if (isOnline != null) {
      return Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOnline! ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOnline! ? 'Online' : _formatLastSeen(),
            style: TextStyle(
              fontSize: 11,
              color: isOnline! ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }
  
  String _formatLastSeen() {
    if (lastSeen == null) return 'Offline';
    
    try {
      final lastSeenDate = parseToKoreaTime(lastSeen!);
      final now = getKoreaNow();
      final difference = now.difference(lastSeenDate);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return 'Offline';
      }
    } catch (e) {
      return 'Offline';
    }
  }

  Future<void> _navigateToProfile(BuildContext context, WidgetRef ref) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final communityService = ref.read(communityServiceProvider);
      final community = await communityService.getSingleCommunity(id: userId!);

      if (community == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
        return;
      }

      if (context.mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                SingleCommunity(community: community),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.4, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeIn,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if calling is enabled (requires 3+ messages)
    final canCallFuture = userId != null
        ? ref.read(canCallProvider(userId!))
        : Future.value(false);

    return FutureBuilder<bool>(
      future: canCallFuture,
      builder: (context, snapshot) {
        final canCall = snapshot.data ?? false;

        return AppBar(
          title: InkWell(
            onTap: () => _navigateToProfile(context, ref),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  UserAvatar(
                    profilePicture: profilePicture,
                    userName: userName,
                    radius: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                        _buildStatusWidget(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            // Video call button
            IconButton(
              onPressed: canCall && userId != null
                  ? () => _initiateCall(
                        context,
                        ref,
                        CallType.video,
                      )
                  : () => _showCallDisabledTooltip(context),
              icon: Icon(
                Icons.videocam,
                color: canCall ? null : Colors.grey.withOpacity(0.5),
              ),
            ),
            // Audio call button
            IconButton(
              onPressed: canCall && userId != null
                  ? () => _initiateCall(
                        context,
                        ref,
                        CallType.audio,
                      )
                  : () => _showCallDisabledTooltip(context),
              icon: Icon(
                Icons.phone,
                color: canCall ? null : Colors.grey.withOpacity(0.5),
              ),
            ),
            ChatOptionsMenu(
              userName: userName,
              userId: userId,
              onThemeChanged: onThemeChanged,
            ),
          ],
        );
      },
    );
  }

  void _showCallDisabledTooltip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'You need to exchange at least 3 messages before you can call this user',
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _initiateCall(
    BuildContext context,
    WidgetRef ref,
    CallType callType,
  ) async {
    if (userId == null) return;

    try {
      final callNotifier = ref.read(callProvider.notifier);
      
      // Setup error callback to handle permission errors
      callNotifier.setCallErrorCallback((error) {
        if (context.mounted) {
          _handleCallError(context, error);
        }
      });
      
      await callNotifier.initiateCall(
        userId!,
        userName,
        profilePicture,
        callType,
      );

      // Navigate to active call screen
      if (context.mounted) {
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
      if (context.mounted) {
        _handleCallError(context, e.toString());
      }
    }
  }
  
  void _handleCallError(BuildContext context, String error) {
    if (error.startsWith('PERMANENTLY_DENIED:')) {
      // Show dialog with option to open settings
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
      // Show snackbar for temporary denial
      final message = error.substring('DENIED:'.length);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Generic error
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
