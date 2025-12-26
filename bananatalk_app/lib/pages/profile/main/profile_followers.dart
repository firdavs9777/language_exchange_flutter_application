import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileFollowers extends ConsumerStatefulWidget {
  const ProfileFollowers({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ProfileFollowers> createState() => _ProfileFollowersState();
}

class _ProfileFollowersState extends ConsumerState<ProfileFollowers> {
  late Future<List<Community>> followers;

  @override
  void initState() {
    super.initState();
    followers = ref.read(authServiceProvider).getFollowersUser(id: widget.id);
  }

  Future<void> _refreshFollowers() async {
    setState(() {
      followers =
          ref.read(authServiceProvider).getFollowersUser(id: widget.id);
    });
  }

  Future<void> followUser(
      String userId, String targetUserId, String userName) async {
    final shouldFollow = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Follow'),
          content: Text('Are you sure you want to follow $userName?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
              ),
              child: const Text('Follow'),
            ),
          ],
        );
      },
    );

    if (shouldFollow == true) {
      try {
        await ref.read(communityServiceProvider).followUser(
              userId: userId,
              targetUserId: targetUserId,
            );

        await _refreshFollowers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You followed $userName'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to follow user: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> unFollowUser(
      String userId, String targetUserId, String userName) async {
    final shouldUnfollow = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Unfollow'),
          content: Text('Are you sure you want to unfollow $userName?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Unfollow'),
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

        await _refreshFollowers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You unfollowed $userName'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unfollow user: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> redirect(String id) async {
    try {
      final community =
          await ref.read(communityServiceProvider).getSingleCommunity(id: id);
      if (community == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
        return;
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SingleCommunity(community: community),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Followers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            Navigator.pop(context);
            ref.refresh(userProvider);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFollowers,
        child: FutureBuilder<List<Community>>(
          future: followers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshFollowers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.people_outline,
                          size: 64, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No followers yet',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start connecting with others!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              final filteredFollowers = snapshot.data!;
              return ListView.builder(
                itemCount: filteredFollowers.length,
                cacheExtent: 200,
                itemBuilder: (context, index) {
                  final community = filteredFollowers[index];
                  final isFollowing = community.followers.contains(widget.id);

                  return _UserCard(
                    key: ValueKey(community.id),
                    community: community,
                    isFollowing: isFollowing,
                    onTap: () => redirect(community.id),
                    onFollowTap: () {
                      if (isFollowing) {
                        unFollowUser(widget.id, community.id, community.name);
                      } else {
                        followUser(widget.id, community.id, community.name);
                      }
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    Key? key,
    required this.community,
    required this.isFollowing,
    required this.onTap,
    required this.onFollowTap,
  }) : super(key: key);

  final Community community;
  final bool isFollowing;
  final VoidCallback onTap;
  final VoidCallback onFollowTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00BFA5).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: CachedCircleAvatar(
                      radius: 35,
                      backgroundColor: const Color(0xFF00BFA5),
                      imageUrl: community.imageUrls.isNotEmpty
                          ? community.imageUrls[0]
                          : null,
                      errorWidget: const Icon(
                        Icons.person,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (community.native_language.isNotEmpty ||
                          community.language_to_learn.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (community.native_language.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.translate,
                                        size: 12, color: Colors.blue[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      community.native_language,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (community.language_to_learn.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.school,
                                        size: 12, color: Colors.orange[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      community.language_to_learn,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onFollowTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isFollowing
                            ? Colors.grey[200]
                            : const Color(0xFF00BFA5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isFollowing ? 'Partner' : 'Follow',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isFollowing ? Colors.black87 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

