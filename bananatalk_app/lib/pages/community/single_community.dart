import 'package:bananatalk_app/pages/chat/chat_main.dart';
import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
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

  void _makeVideoCall() {
    // Implement video call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Video call with ${widget.community.name} initiated'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  void _makeVoiceCall() {
    // Implement voice call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voice call with ${widget.community.name} initiated'),
        backgroundColor: Colors.green[600],
      ),
    );
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
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
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
