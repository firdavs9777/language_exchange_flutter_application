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
  late String
      userId; // Declare userId as late since it'll be initialized in initState

  @override
  void initState() {
    super.initState();
    _initializeUserState();
  }

  Future<void> _initializeUserState() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    print(userId);
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
        isFollower = true; // Update state to reflect following
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
    bool shouldUnfollow = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unfollow ${widget.community.name}'),
          content: Text('Are you sure you want to unfollow this user?'),
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
          isFollower = false; // Update state to reflect unfollowing
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
          '${widget.community.name}, ${calculateAge(widget.community.birth_year).toString()}',
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (widget.community.imageUrls.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageGallery(
                            imageUrls: widget.community.imageUrls,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No images available'),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage: widget.community.imageUrls.isNotEmpty
                        ? NetworkImage(widget.community.imageUrls[0])
                        : AssetImage('assets/images/logo_no_background.png')
                            as ImageProvider,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  widget.community.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  widget.community.bio,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Column(
                      children: [
                        Icon(Icons.video_call, color: Colors.blue),
                        SizedBox(height: 4),
                        Text('Video', style: TextStyle(fontFamily: 'Roboto')),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.call, color: Colors.blue),
                        SizedBox(height: 4),
                        Text('Call', style: TextStyle(fontFamily: 'Roboto')),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          Icon(Icons.message, color: Colors.blue),
                          SizedBox(height: 4),
                          Text('Message',
                              style: TextStyle(fontFamily: 'Roboto')),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: isFollower
                          ? () {
                              unFollowUser(userId, widget.community.id);
                            }
                          : () {
                              followUser(userId, widget.community.id);
                            },
                      child: Column(
                        children: [
                          Icon(
                            isFollower ? Icons.check_circle : Icons.person_add,
                            color: isFollower ? Colors.green : Colors.blue,
                          ),
                          SizedBox(height: 4),
                          Text(
                            isFollower ? 'Following' : 'Follow',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: isFollower ? Colors.green : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Divider(color: Colors.grey),
              Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Bio',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.community.bio,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          Icon(Icons.language, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Languages',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Native: ${widget.community.native_language}',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      Text(
                        'Learning: ${widget.community.language_to_learn}',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
