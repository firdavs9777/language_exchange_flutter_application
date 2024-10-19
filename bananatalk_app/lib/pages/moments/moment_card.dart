import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/moments/action_widget.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/pages/moments/single_moment.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class MomentCard extends ConsumerStatefulWidget {
  final Moments moments;

  const MomentCard({super.key, required this.moments});

  @override
  _MomentCardState createState() => _MomentCardState();
}

class _MomentCardState extends ConsumerState<MomentCard> {
  late bool isLiked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    // Initialize the isLiked and likeCount with the data from the moments object
    isLiked = false;
    likeCount = widget.moments.likeCount;
  }

  void toggleLike() {
    setState(() {
      if (isLiked) {
        likeCount--;
      } else {
        likeCount++;
      }
      isLiked = !isLiked;

      // Optionally, make a network request here to update the like status on the backend
      // For example:
      // await ref.read(momentsServiceProvider).toggleLike(widget.moments.id);
    });
  }

  void _shareMoment(BuildContext context) {
    final momentText = 'Check out this moment';
    final momentUrl =
        'https://example.com/moments'; // Construct the shareable URL

    // Use the share plugin to share the moment
    Share.share('$momentText\n\n$momentUrl');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        Moments singleMoment = await ref
            .watch(momentsServiceProvider)
            .getSingleMoment(id: widget.moments.id);

        ref.refresh(commentsProvider(singleMoment.id));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SingleMoment(moment: singleMoment),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Card(
          color: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () async {
                    Community community = await ref
                        .watch(communityServiceProvider)
                        .getSingleCommunity(id: widget.moments.user.id);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SingleCommunity(community: community),
                      ),
                    );
                  },
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: widget.moments.user.imageUrls.isNotEmpty
                          ? NetworkImage(widget.moments.user.imageUrls[0])
                          : AssetImage('assets/images/logo_no_background.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      widget.moments.user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () {
                        // Implement delete functionality here
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.moments.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.moments.description.length > 100
                      ? widget.moments.description.substring(0, 100) + '...'
                      : widget.moments.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 15),
                if (widget.moments.imageUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
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
                      itemCount: widget.moments.imageUrls.length,
                      itemBuilder: (context, index) {
                        final url = widget.moments.imageUrls[index];
                        return GestureDetector(
                          onTap: () {
                            // Open image viewer on image tap
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageGallery(
                                    imageUrls: widget.moments.imageUrls,
                                    initialIndex: index),
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
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ActionButton(
                          icon:
                              isLiked ? Icons.favorite : Icons.favorite_outline,
                          count: likeCount,
                          onPressed: toggleLike,
                          isLiked: isLiked,
                        ),
                        const SizedBox(width: 10),
                        ActionButton(
                          icon: Icons.comment,
                          count: widget.moments.commentCount,
                          isLiked: false,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.ios_share_outlined),
                      onPressed: () {
                        // Implement share functionality here
                        _shareMoment(context);
                      },
                    ),
                  ],
                ),
                Divider(thickness: 1, color: Colors.lightGreenAccent[300]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
