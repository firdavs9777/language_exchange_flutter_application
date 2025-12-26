import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';

/// Screen for managing close friends list
class CloseFriendsScreen extends StatefulWidget {
  const CloseFriendsScreen({Key? key}) : super(key: key);

  @override
  State<CloseFriendsScreen> createState() => _CloseFriendsScreenState();
}

class _CloseFriendsScreenState extends State<CloseFriendsScreen> 
    with SingleTickerProviderStateMixin {
  List<Community> _closeFriends = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCloseFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCloseFriends() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await StoriesService.getCloseFriends();
      
      if (mounted) {
        setState(() {
          _closeFriends = (result['data'] as List<Community>?) ?? [];
          _isLoading = false;
          _error = result['error'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _toggleCloseFriend(Community user, bool isCurrentlyCloseFriend) async {
    // Optimistic update
    setState(() {
      if (isCurrentlyCloseFriend) {
        _closeFriends.removeWhere((u) => u.id == user.id);
      } else {
        _closeFriends.add(user);
      }
    });

    final result = isCurrentlyCloseFriend
        ? await StoriesService.removeCloseFriend(userId: user.id)
        : await StoriesService.addCloseFriend(userId: user.id);

    if (result['success'] != true) {
      // Revert on failure
      setState(() {
        if (isCurrentlyCloseFriend) {
          _closeFriends.add(user);
        } else {
          _closeFriends.removeWhere((u) => u.id == user.id);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to update')),
      );
    }
  }

  List<Community> get _filteredFriends {
    if (_searchQuery.isEmpty) return _closeFriends;
    return _closeFriends.where((user) =>
        user.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Close Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.grey[600], size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCloseFriends,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildHeader(),
                    _buildSearchBar(),
                    Expanded(child: _buildFriendsList()),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Close Friends',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_closeFriends.length} people',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search close friends...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    final friends = _filteredFriends;

    if (friends.isEmpty && _closeFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                color: Colors.green[400],
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No close friends yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Add friends to your close friends list to share exclusive stories with them.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to followers/following list to add close friends
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add friends from your profile')),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Friends'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (friends.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Text(
          'No results for "$_searchQuery"',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCloseFriends,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return _CloseFriendTile(
            user: friend,
            onRemove: () => _toggleCloseFriend(friend, true),
          );
        },
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Close Friends', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              Icons.visibility_off,
              'Private Stories',
              'Only your close friends can see stories you share with them.',
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              Icons.notifications_none,
              'No Notifications',
              "People won't be notified when you add or remove them.",
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              Icons.lock_outline,
              'Your List',
              'Only you can see your close friends list.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[500], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CloseFriendTile extends StatelessWidget {
  final Community user;
  final VoidCallback onRemove;

  const _CloseFriendTile({
    required this.user,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: user.imageUrls.isNotEmpty
                ? NetworkImage(user.imageUrls.first)
                : null,
            backgroundColor: Colors.grey[800],
            child: user.imageUrls.isEmpty
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 10),
            ),
          ),
        ],
      ),
      title: Text(
        user.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: user.bio.isNotEmpty
          ? Text(
              user.bio,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: TextButton(
        onPressed: onRemove,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Remove'),
      ),
    );
  }
}

/// Button to add someone as close friend
class AddCloseFriendButton extends StatefulWidget {
  final String userId;
  final bool initialIsCloseFriend;

  const AddCloseFriendButton({
    Key? key,
    required this.userId,
    this.initialIsCloseFriend = false,
  }) : super(key: key);

  @override
  State<AddCloseFriendButton> createState() => _AddCloseFriendButtonState();
}

class _AddCloseFriendButtonState extends State<AddCloseFriendButton> {
  late bool _isCloseFriend;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isCloseFriend = widget.initialIsCloseFriend;
  }

  Future<void> _toggle() async {
    setState(() => _isLoading = true);
    
    final result = _isCloseFriend
        ? await StoriesService.removeCloseFriend(userId: widget.userId)
        : await StoriesService.addCloseFriend(userId: widget.userId);
    
    if (result['success'] == true) {
      setState(() => _isCloseFriend = !_isCloseFriend);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to update')),
      );
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isLoading ? null : _toggle,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isCloseFriend ? Icons.star : Icons.star_border,
              color: _isCloseFriend ? Colors.green : Colors.grey,
            ),
      tooltip: _isCloseFriend ? 'Remove from Close Friends' : 'Add to Close Friends',
    );
  }
}

/// Close friends indicator badge
class CloseFriendsBadge extends StatelessWidget {
  final double size;

  const CloseFriendsBadge({Key? key, this.size = 16}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.star,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}

