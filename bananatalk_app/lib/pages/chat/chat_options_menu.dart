import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/services/block_service.dart';

class ChatOptionsMenu extends StatelessWidget {
  final String userName;
  final String? userId;

  const ChatOptionsMenu({Key? key, required this.userName, this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuOption(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view_contact',
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('View contact'),
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
        const PopupMenuItem(
          value: 'mute',
          child: ListTile(
            leading: Icon(Icons.notifications_off),
            title: Text('Mute notifications'),
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
        const PopupMenuItem(
          value: 'block',
          child: ListTile(
            leading: Icon(Icons.block, color: Colors.red),
            title: Text('Block', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _handleMenuOption(BuildContext context, String value) async {
    switch (value) {
      case 'block':
        if (userId != null) {
          await _showBlockDialog(context, userId!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User ID not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      case 'view_contact':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('View contact info for $userName')),
        );
        break;
      case 'media':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media, links and docs')),
        );
        break;
      case 'search':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search in conversation')),
        );
        break;
      case 'mute':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mute notifications for $userName')),
        );
        break;
      case 'wallpaper':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Change wallpaper')),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown action: $value')),
        );
    }
  }

  Future<void> _showBlockDialog(BuildContext context, String targetUserId) async {
    // Get current user ID first to check if trying to block self
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
    if (currentUserId == targetUserId) {
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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block $userName? You will not be able to send or receive messages from this user.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (result == true) {

      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Block user (userId parameter is the target user to block)
      final blockResult = await BlockService.blockUser(
        userId: targetUserId,
        reason: null,
      );

      // Close loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (blockResult['success'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(blockResult['message'] ?? 'User blocked successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to chat list
          Navigator.of(context).pop();
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(blockResult['error'] ?? 'Failed to block user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
