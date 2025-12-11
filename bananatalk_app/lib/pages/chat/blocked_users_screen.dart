import 'package:flutter/material.dart';
import 'package:bananatalk_app/services/block_service.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<BlockedUser> _blockedUsers = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId');

      if (_currentUserId == null) {
        setState(() {
          _error = 'User ID not found';
          _isLoading = false;
        });
        return;
      }

      final result = await BlockService.getBlockedUsers(userId: _currentUserId!);

      if (result['success'] == true) {
        setState(() {
          _blockedUsers = (result['data'] as List<dynamic>?)
                  ?.map((item) => BlockedUser.fromJson(item as Map<String, dynamic>))
                  .toList() ??
              [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to load blocked users';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading blocked users: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _unblockUser(BlockedUser blockedUser) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock ${blockedUser.user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (result == true && _currentUserId != null) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final unblockResult = await BlockService.unblockUser(userId: _currentUserId!);

      // Close loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (unblockResult['success'] == true) {
        // Reload blocked users list
        await _loadBlockedUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(unblockResult['message'] ?? 'User unblocked successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(unblockResult['error'] ?? 'Failed to unblock user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBlockedUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _blockedUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block, size: 64, color: context.textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            'No blocked users',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Users you block will appear here',
                            style: TextStyle(color: context.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBlockedUsers,
                      child: ListView.builder(
                        itemCount: _blockedUsers.length,
                        itemBuilder: (context, index) {
                          final blockedUser = _blockedUsers[index];
                          final user = blockedUser.user;

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: colorScheme.primaryContainer,
                              backgroundImage: user.imageUrls.isNotEmpty
                                  ? NetworkImage(
                                      ImageUtils.normalizeImageUrl(user.imageUrls[0]),
                                    )
                                  : null,
                              child: user.imageUrls.isEmpty
                                  ? Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (blockedUser.reason != null)
                                  Text(
                                    'Reason: ${blockedUser.reason}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                Text(
                                  'Blocked on ${_formatDate(blockedUser.blockedAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            trailing: TextButton(
                              onPressed: () => _unblockUser(blockedUser),
                              child: const Text('Unblock'),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}

