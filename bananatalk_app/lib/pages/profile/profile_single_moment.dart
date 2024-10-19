import 'package:bananatalk_app/pages/comments/comments_main.dart';
import 'package:bananatalk_app/pages/comments/create_comment.dart';
import 'package:bananatalk_app/pages/moments/action_widget.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';


import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';

class ProfileSingleMoment extends StatefulWidget {
  final Moments moment;

  const ProfileSingleMoment({
    super.key,
    required this.moment,
  });

  @override
  State<ProfileSingleMoment> createState() => _SingleMomentState();
}

class _SingleMomentState extends State<ProfileSingleMoment> {
  late int likeCount;
  TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    likeCount = widget.moment.likeCount;
    print(widget.moment.id);
  }

  //
  void incrementLike() {
    setState(() {
      likeCount++;
    });
  }

  void _deleteMoment() {
    print('Deleted');
  }

  void _editMoment() {
    print('Clicked');
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
                elevation: 4,
                offset: Offset(
                    0,
                    MediaQuery.of(context).size.height *
                        0.5), // Adjust this value as needed
                onSelected: (value) {
                  // Handle menu item selection here
                  if (value == 'delete') {
                    // Implement delete functionality
                    _deleteMoment();
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
                            height: 80,
                            width: 80,
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
                    onPressed: incrementLike,
                  ),
                  SizedBox(width: 10),
                  ActionButton(
                    isLiked: false,
                    icon: Icons.comment,
                    count: 0,
                    onPressed: () {},
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
