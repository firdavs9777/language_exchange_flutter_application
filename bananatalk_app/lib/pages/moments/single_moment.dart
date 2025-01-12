import 'package:bananatalk_app/pages/comments/comments_main.dart';
import 'package:bananatalk_app/pages/comments/create_comment.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/moments/action_widget.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SingleMoment extends ConsumerStatefulWidget {
  final Moments moment;

  const SingleMoment({
    super.key,
    required this.moment,
  });

  @override
  ConsumerState<SingleMoment> createState() => _SingleMomentState();
}

class _SingleMomentState extends ConsumerState<SingleMoment> {
  late bool isLiked;
  late bool isDisliked;
  late int likeCount;
  late int commentCount;
  TextEditingController commentController = TextEditingController();
  bool showCommentField = false;
  final FocusNode commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    likeCount = widget.moment.likeCount;
    commentCount = widget.moment.commentCount; // Track comment count

    isLiked =
        widget.moment.likedUsers!.contains(widget.moment.user.id) ?? false;
    isDisliked =
        widget.moment.likedUsers!.contains(widget.moment.user.id)! ?? false;
  }

  void incrementLike() async {
    if (isLiked) {
      await ref
          .watch(momentsServiceProvider)
          .dislikeMoment(widget.moment.id, widget.moment.user.id);
      setState(() {
        isLiked = false;
        likeCount--;
      });
    } else {
      await ref
          .watch(momentsServiceProvider)
          .likeMoment(widget.moment.id, widget.moment.user.id);

      setState(() {
        isLiked = true;
        likeCount++;
        widget.moment.likedUsers?.add(widget.moment.user.id);
      });
    }
  }

  void updateCommentCount() {
    setState(() {
      commentCount++;
    });
  }

  void focusCommentField() {
    setState(() {
      showCommentField = true;
    });
    // Delay focusing to allow the UI to rebuild
    Future.delayed(const Duration(milliseconds: 100), () {
      commentFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Moment Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Card(
                    color: Colors.transparent,
                    elevation: 0,
                    child: Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final community = await ref
                                  .read(communityServiceProvider)
                                  .getSingleCommunity(
                                      id: widget.moment.user.id);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SingleCommunity(community: community),
                                ),
                              );
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundImage:
                                    widget.moment.user.imageUrls.isNotEmpty
                                        ? NetworkImage(
                                            widget.moment.user.imageUrls[0])
                                        : null,
                                backgroundColor: Colors.grey[200],
                              ),
                              title: Text(widget.moment.user.name ?? 'No Name'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.moment.createdAt
                                        .toLocal()
                                        .toString()
                                        .split(' ')[0],
                                  ),
                                  // IconButton(
                                  //   icon: Icon(Icons.more_vert),
                                  //   onPressed: () {
                                  //     // Implement delete functionality here
                                  //   },
                                  // ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          // Display Title
                          Center(
                            child: Text(
                              widget.moment.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          // Display Description
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                widget.moment.description,
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          // Display Image (if available)
                          if (widget.moment.images.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: GridView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8.0,
                                  mainAxisSpacing: 8.0,
                                  childAspectRatio: 1,
                                ),
                                itemCount: widget.moment.imageUrls.length,
                                itemBuilder: (context, index) {
                                  final url = widget.moment.imageUrls[index];
                                  return GestureDetector(
                                    onTap: () {
                                      // Open image viewer on image tap
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ImageGallery(
                                            imageUrls: widget.moment.imageUrls,
                                            initialIndex: index,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          // Display Action Buttons (like, comment, etc.)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ActionButton(
                                  icon: isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_outline_sharp,
                                  count: likeCount,
                                  onPressed: incrementLike,
                                  isLiked: isLiked,
                                ),
                                SizedBox(width: 10),
                                ActionButton(
                                  isLiked: false,
                                  icon: commentCount == 0
                                      ? Icons.comment_bank_outlined
                                      : Icons.comment,
                                  count: commentCount,
                                  onPressed: focusCommentField,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(thickness: 2, color: Colors.lightGreenAccent[300]),
                  // Comments Section
                  CommentsMain(id: widget.moment.id),
                ],
              ),
            ),
          ),
          CreateComment(
            focusNode: commentFocusNode,
            id: widget.moment.id,
            onCommentAdded: updateCommentCount, // Pass callback
          ),
        ],
      ),
    );
  }
}
