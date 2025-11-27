import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';

class CommentsMain extends ConsumerWidget {
  const CommentsMain({Key? key, required this.id}) : super(key: key);

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textPrimary = context.textPrimary;
    final secondaryText = context.textSecondary;
    // Watching the commentsProvider to get the list of comments for the given id
    final commentsAsyncValue = ref.watch(commentsProvider(id));

    print(commentsAsyncValue);

    return Card(
      color: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.all(16.0),
      child: commentsAsyncValue.when(
        // Handle different states of AsyncValue: data, loading, error
        data: (comments) {
          if (comments.isEmpty) {
            return Column(
              children: [
                Container(
                    height: 300,
                    child:
                        const Center(child: Text('Be the first to  comment.'))),
              ],
            );
          }
          // Displaying comments in a Column
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Comments (${comments.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              // Mapping comments to ListTiles for display

              ...comments
                  .map(
                    (comment) => Card(
                      color: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            leading: InkWell(
                              onTap: () async {
                                final community = await ref
                                    .read(communityServiceProvider)
                                    .getSingleCommunity(id: comment.user.id);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SingleCommunity(community: community),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: const Color(0xFF00BFA5),
                                backgroundImage: comment
                                        .user.imageUrls.isNotEmpty
                                    ? NetworkImage(comment.user.imageUrls[0])
                                    : null,
                                child: comment.user.imageUrls.isEmpty
                                    ? Icon(
                                        Icons.person,
                                        size: 25,
                                        color: colorScheme.surface,
                                      )
                                    : null,
                                onBackgroundImageError: (exception, stackTrace) {
                                  // Image failed to load, will use icon fallback
                                },
                              ),
                            ),
                            title: Text(
                              comment.user.name ?? 'no',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                comment.text.toString(),
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            trailing: Text(
                              comment.createdAt
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0],
                              style: TextStyle(color: secondaryText),
                            ),
                          ),
                          Divider(
                              thickness: 1,
                              color: colorScheme.primary.withOpacity(0.3)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              // Line separator
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Text('Error: $error $stack'),
      ),
    );
  }
}
