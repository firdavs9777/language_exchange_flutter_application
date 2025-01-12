import 'package:bananatalk_app/pages/moments/action_widget.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/pages/profile/profile_moment_edit.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';

import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class ProfileSingleMoment extends ConsumerStatefulWidget {
  final Moments moment;

  const ProfileSingleMoment({
    super.key,
    required this.moment,
  });

  @override
  _ProfileSingleMomentState createState() => _ProfileSingleMomentState();
}

class _ProfileSingleMomentState extends ConsumerState<ProfileSingleMoment> {
  late Moments moment;
  late int likeCount;
  TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    moment = widget.moment;
    likeCount = widget.moment.likeCount;
  }

  //
  void incrementLike() {
    setState(() {
      likeCount++;
    });
  }

  void _shareMoment(BuildContext context) {
    final momentText = 'Check out this moment';
    final momentUrl =
        'https://example.com/moments'; // Construct the shareable URL

    // Use the share plugin to share the moment
    Share.share('$momentText\n\n$momentUrl');
  }

  void _deleteMoment(BuildContext context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Delete Confirmation'),
            content: Text('Are you sure you want to delete this moment?'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Cancel')),
              TextButton(
                  onPressed: () async {
                    final response = await ref
                        .read(momentsServiceProvider)
                        .deleteUserMoment(id: moment.id);
                    if (response['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Moment Deleted')));
                      Navigator.of(context).pop();
                      ref.refresh(momentsServiceProvider);
                    }
                  },
                  child: Text('Delete'))
            ],
          );
        });
  }

  void _editMoment() async {
    final updatedMoment = await Navigator.push<Moments>(
      context,
      MaterialPageRoute(
        builder: (context) => EditMomentScreen(moment: widget.moment),
      ),
    );

    if (updatedMoment != null) {
      setState(() {
        moment = updatedMoment;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Column(
          children: [
            ListTile(
              title: Text(widget.moment.user.name),
              trailing: PopupMenuButton<String>(
                elevation: 3,
                offset: Offset(
                    0,
                    MediaQuery.of(context).size.height *
                        0.05), // Adjust this value as needed
                onSelected: (value) {
                  // Handle menu item selection here
                  if (value == 'delete') {
                    // Implement delete functionality
                    _deleteMoment(context);
                  } else if (value == 'edit') {
                    // Implement edit functionality
                    _editMoment();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            // Display Title
            Center(
              child: Text(
                widget.moment.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            // Display Description
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.moment.description,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 24),
            // Display Image (if available)
            if (widget.moment.images.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: widget.moment.imageUrls.map((url) {
                    return GestureDetector(
                      onTap: () {
                        // Open image viewer on image tap
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageGallery(
                                imageUrls: widget.moment.imageUrls,
                                initialIndex:
                                    widget.moment.imageUrls.indexOf(url)),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            url,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            SizedBox(height: 24),
            // Display Action Buttons (like, comment, etc.)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ActionButton(
                    isLiked: false,
                    icon: Icons.thumb_up,
                    count: likeCount,
                    onPressed: () {},
                  ),
                  SizedBox(width: 10),
                  ActionButton(
                    isLiked: false,
                    icon: Icons.comment,
                    count: 0,
                    onPressed: () {},
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.ios_share_outlined),
                    onPressed: () {
                      // Implement share functionality here
                      _shareMoment(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// You need to provide the `ref` object for your provider
// Replace this with your actual ref implementation
}
