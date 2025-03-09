import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileFollowers extends ConsumerStatefulWidget {
  const ProfileFollowers({super.key, required this.id});
  final String id;

  @override
  _ProfileFollowersState createState() => _ProfileFollowersState();
}

class _ProfileFollowersState extends ConsumerState<ProfileFollowers> {
  late Future<List<Community>> followers;
  bool isFollower = false;

  @override
  void initState() {
    super.initState();
    followers = ref.read(authServiceProvider).getFollowersUser(id: widget.id);
  }

  void followUser(String userId, String targetUserId, String userName) async {
    bool shouldfollow = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Follow'),
          content: Text('Are you sure you want to follow ${userName}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Return false if user cancels
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true if user confirms
              },
              child: Text('Follow'),
            ),
          ],
        );
      },
    );
    if (shouldfollow == true) {
      try {
        await ref.read(communityServiceProvider).followUser(
              userId: userId,
              targetUserId: targetUserId,
            );

        setState(() {
          followers =
              ref.read(authServiceProvider).getFollowersUser(id: widget.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You followed ${userName} ')),
        );
      } catch (e) {
        print('Failed to follow user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to follow user')),
        );
      }
    }
  }

  void unFollowUser(String userId, String targetUserId, String userName) async {
    bool shouldUnfollow = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unfollow'),
          content: Text('Are you sure you want to unfollow ${userName}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Return false if user cancels
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true if user confirms
              },
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
          followers =
              ref.read(authServiceProvider).getFollowersUser(id: widget.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You unfollowed ${userName} ')),
        );
      } catch (e) {
        print('Failed to unfollow user: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unfollow user')),
        );
      }
    }
  }

  Future<void> redirect(String id) async {
    Community community =
        await ref.read(communityServiceProvider).getSingleCommunity(id: id);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SingleCommunity(community: community)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Followers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            Navigator.pop(context);
            ref.refresh(userProvider);
          },
        ),
      ),
      body: FutureBuilder<List<Community>>(
        future: followers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No followers found.'));
          } else {
            List<Community> filteredFollowers = snapshot.data!;
            return ListView.builder(
              itemCount: filteredFollowers.length,
              itemBuilder: (context, index) {
                final community = filteredFollowers[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage: community.imageUrls.isNotEmpty
                          ? NetworkImage(community.imageUrls[0])
                          : const AssetImage(
                                  'assets/images/logo_no_background.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      community.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 4.0),
                          Text(
                            'Native in ${community.native_language}',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'Learning ${community.language_to_learn}',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      redirect(community.id);
                    },
                    trailing: TextButton(
                      onPressed: () {
                        // Handle Partner button action
                        if (community.followers.contains(widget.id)) {
                          unFollowUser(widget.id, community.id, community.name);
                        } else {
                          followUser(widget.id, community.id, community.name);
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).primaryColor, // Adjust color
                      ),
                      child: Text(
                        community.followers.contains(widget.id)
                            ? 'Partner'
                            : 'Follow',
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
