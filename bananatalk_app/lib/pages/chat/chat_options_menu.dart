import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/chat/chat_search_screen.dart';
import 'package:bananatalk_app/pages/chat/chat_media_screen.dart';
import 'package:bananatalk_app/pages/chat/mute_dialog.dart';
import 'package:bananatalk_app/pages/chat/wallpaper_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/widgets/block_user_dialog.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';

class ChatOptionsMenu extends ConsumerStatefulWidget {
  final String userName;
  final String? userId;
  final String? conversationId;
  final bool isMuted;
  final VoidCallback? onMuteChanged;
  final VoidCallback? onThemeChanged;

  const ChatOptionsMenu({
    Key? key,
    required this.userName,
    this.userId,
    this.conversationId,
    this.isMuted = false,
    this.onMuteChanged,
    this.onThemeChanged,
  }) : super(key: key);

  @override
  ConsumerState<ChatOptionsMenu> createState() => _ChatOptionsMenuState();
}

class _ChatOptionsMenuState extends ConsumerState<ChatOptionsMenu> {
  bool? _isBlocked; // Track block status
  bool _isLoadingBlockStatus = true;

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
  }

  Future<void> _checkBlockStatus() async {
    if (widget.userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');

      if (currentUserId == null) return;

      final result = await BlockService.checkBlockStatus(
        userId: currentUserId,
        targetUserId: widget.userId!,
      );

      if (mounted) {
        setState(() {
          _isBlocked = result['isBlocked'] ?? false;
          _isLoadingBlockStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBlockStatus = false;
        });
      }
    }
  }

  Future<void> redirect(String id) async {
    try {
      final community = await ref
          .read(communityServiceProvider)
          .getSingleCommunity(id: id);

      if (community == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not found')));
        }
        return;
      }

      if (mounted) {
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
                      position:
                          Tween<Offset>(
                            begin: const Offset(0.3, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading community: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuOption(context, value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view_contact',
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('View Profile'),
            subtitle: Text(
              widget.userName,
              style: const TextStyle(fontSize: 12),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'media',
          child: ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Media, links, and docs'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'search',
          child: ListTile(
            leading: Icon(Icons.search),
            title: Text('Search'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'mute',
          child: ListTile(
            leading: Icon(
              widget.isMuted ? Icons.notifications : Icons.notifications_off,
            ),
            title: Text(
              widget.isMuted ? 'Unmute notifications' : 'Mute notifications',
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'wallpaper',
          child: ListTile(
            leading: Icon(Icons.wallpaper),
            title: Text('Wallpaper'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),

        // Block/Unblock - dynamically change based on status
        if (!_isLoadingBlockStatus)
          PopupMenuItem(
            value: _isBlocked == true ? 'unblock' : 'block',
            child: ListTile(
              leading: Icon(
                _isBlocked == true ? Icons.check_circle : Icons.block,
                color: _isBlocked == true ? Colors.green : Colors.red,
              ),
              title: Text(
                _isBlocked == true ? 'Unblock' : 'Block',
                style: TextStyle(
                  color: _isBlocked == true ? Colors.green : Colors.red,
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),

        // Report option
        PopupMenuItem(
          value: 'report',
          child: ListTile(
            leading: Icon(Icons.flag, color: Colors.orange[700]),
            title: Text('Report', style: TextStyle(color: Colors.orange[700])),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _handleMenuOption(BuildContext context, String value) async {
    switch (value) {
      case 'view_contact':
        if (widget.userId != null) {
          await redirect(widget.userId!);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User ID not available'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;

      case 'search':
        if (context.mounted) {
          final prefs = await SharedPreferences.getInstance();
          final currentUserId = prefs.getString('userId');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatSearchScreen(
                conversationId: widget.conversationId,
                senderId: currentUserId,
                receiverId: widget.userId,
                otherUserName: widget.userName,
              ),
            ),
          );
        }
        break;

      case 'mute':
        if (widget.conversationId != null) {
          if (context.mounted) {
            await MuteDialog.show(
              context: context,
              conversationId: widget.conversationId!,
              userName: widget.userName,
              isMuted: widget.isMuted,
              onMuteChanged: widget.onMuteChanged,
            );
          }
        } else {
          // If no conversationId, show a message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.isMuted
                      ? 'Notifications unmuted for ${widget.userName}'
                      : 'Notifications muted for ${widget.userName}',
                ),
              ),
            );
          }
        }
        break;

      case 'wallpaper':
        if (widget.conversationId != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WallpaperPickerScreen(
                conversationId: widget.conversationId!,
                userName: widget.userName,
                onThemeChanged: widget.onThemeChanged,
              ),
            ),
          );
        } else {
          // Create a temporary conversation ID based on userId for local storage
          final tempConversationId = widget.userId ?? 'default';
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WallpaperPickerScreen(
                  conversationId: tempConversationId,
                  userName: widget.userName,
                  onThemeChanged: widget.onThemeChanged,
                ),
              ),
            );
          }
        }
        break;

      case 'block':
        if (widget.userId != null) {
          final prefs = await SharedPreferences.getInstance();
          final currentUserId = prefs.getString('userId');

          if (currentUserId == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User ID not found'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Check if trying to block yourself
          if (currentUserId == widget.userId) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cannot block yourself'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          if (context.mounted) {
            await BlockUserDialog.show(
              context: context,
              currentUserId: currentUserId,
              targetUserId: widget.userId!,
              targetUserName: widget.userName,
              ref: ref,
              onBlocked: () {
                // Update state directly
                setState(() {
                  _isBlocked = true;
                });
                // Navigate back to chat list after blocking
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User ID not available'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;

      case 'unblock':
        if (widget.userId != null) {
          final prefs = await SharedPreferences.getInstance();
          final currentUserId = prefs.getString('userId');

          if (currentUserId == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User ID not found'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Show confirmation dialog
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Unblock User'),
              content: Text(
                'Are you sure you want to unblock ${widget.userName}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Unblock'),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );

            // Call unblock service
            final result = await BlockService.unblockUser(
              currentUserId: currentUserId,
              blockedUserId: widget.userId!,
            );

            // Close loading
            if (context.mounted) {
              Navigator.of(context).pop();
            }

            // Show result and update state directly
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Operation completed'),
                  backgroundColor: result['success'] == true
                      ? Colors.green
                      : Colors.red,
                ),
              );

              // Update state directly on success instead of re-fetching
              if (result['success'] == true) {
                setState(() {
                  _isBlocked = false;
                });
                // Refresh blocked users provider
                ref.invalidate(blockedUsersProvider);
                ref.invalidate(blockedUserIdsProvider);
              }
            }
          }
        }
        break;

      case 'report':
        if (widget.userId != null) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => ReportDialog(
                type: 'user',
                reportedId: widget.userId!,
                reportedUserId: widget.userId!,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User ID not available'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;

      case 'media':
        if (context.mounted) {
          final prefs = await SharedPreferences.getInstance();
          final currentUserId = prefs.getString('userId');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatMediaScreen(
                conversationId: widget.conversationId,
                senderId: currentUserId,
                receiverId: widget.userId,
                otherUserName: widget.userName,
              ),
            ),
          );
        }
        break;

      default:
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Unknown action: $value')));
        }
    }
  }
}
