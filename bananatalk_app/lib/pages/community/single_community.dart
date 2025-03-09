import 'package:bananatalk_app/pages/chat/chat_main.dart';
import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SingleCommunity extends ConsumerStatefulWidget {
  final Community community;
  const SingleCommunity({super.key, required this.community});

  @override
  _SingleCommunityState createState() => _SingleCommunityState();
}

class _SingleCommunityState extends ConsumerState<SingleCommunity> {
  bool isFollower = false;
  late String userId;

  @override
  void initState() {
    super.initState();
    _initializeUserState();
  }

  Future<void> _initializeUserState() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    setState(() {
      isFollower = widget.community.followers.contains(userId);
    });
  }

  int calculateAge(String birthYear) {
    final currentYear = DateTime.now().year;
    return currentYear - int.parse(birthYear);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.community.name}, ${calculateAge(widget.community.birth_year)}'),
        elevation: 1,
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
                    child: CircleAvatar(
                      radius: 80,
                      backgroundImage: widget.community.imageUrls.isNotEmpty
                          ? NetworkImage(widget.community.imageUrls[0])
                          : const AssetImage(
                                  'assets/images/logo_no_background.png')
                              as ImageProvider,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(widget.community.name,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildActionButton(Icons.video_call, 'Video',
                      Colors.blue[600]!, () {}), // Adjusted color
                  _buildActionButton(Icons.call, 'Call', Colors.blue[600]!,
                      () {}), // Adjusted color
                  _buildActionButton(Icons.message, 'Message',
                      Colors.blue[600]!, () {}), // Adjusted color
                  _buildActionButton(
                    isFollower ? Icons.check_circle : Icons.person_add,
                    isFollower ? 'Following' : 'Follow',
                    isFollower
                        ? Colors.green[600]!
                        : Colors.blue[600]!, // Adjusted color
                    isFollower
                        ? () => unFollowUser(userId, widget.community.id)
                        : () => followUser(userId, widget.community.id),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              _buildCard(Icons.person, 'Bio', widget.community.bio,
                  Colors.blue[600]!), // Adjusted color
              _buildCard(
                  Icons.language,
                  'Languages',
                  'Native: ${widget.community.native_language}\nLearning: ${widget.community.language_to_learn}',
                  Colors.blue[600]!), // Adjusted color
              const SizedBox(height: 16),
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
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
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
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}
