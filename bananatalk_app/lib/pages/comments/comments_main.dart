import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/translated_comment_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            final l10n = AppLocalizations.of(context)!;
            return Column(
              children: [
                Container(
                    height: 300,
                    child:
                        Center(child: Text(l10n.beTheFirstToComment))),
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
                  '${AppLocalizations.of(context)!.comments} (${comments.length})',
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

                                if (community == null) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('User not found')),
                                    );
                                  }
                                  return;
                                }

                                if (!context.mounted) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SingleCommunity(community: community),
                                  ),
                                );
                              },
                              child: CachedCircleAvatar(
                                imageUrl: comment.user.imageUrls.isNotEmpty
                                    ? comment.user.imageUrls[0]
                                    : null,
                                radius: 25,
                                backgroundColor: const Color(0xFF00BFA5),
                                errorWidget: Icon(
                                  Icons.person,
                                  size: 25,
                                  color: colorScheme.surface,
                                ),
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
                              child: TranslatedCommentWidget(
                                commentId: comment.id,
                                originalText: comment.text.toString(),
                                originalLanguage: comment.user.native_language,
                                existingTranslations: comment.translations.isNotEmpty
                                    ? comment.translations
                                    : null,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: secondaryText),
                              onSelected: (value) async {
                                if (value == 'report') {
                                  final prefs = await SharedPreferences.getInstance();
                                  final currentUserId = prefs.getString('userId');
                                  final isOwnComment = currentUserId == comment.user.id;
                                  
                                  if (isOwnComment) {
                                    final l10n = AppLocalizations.of(context)!;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.cannotReportYourOwnComment),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  showDialog(
                                    context: context,
                                    builder: (context) => ReportDialog(
                                      type: 'comment',
                                      reportedId: comment.id,
                                      reportedUserId: comment.user.id,
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'report',
                                  child: Row(
                                    children: [
                                      Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
                                      SizedBox(width: 8),
                                      Text(AppLocalizations.of(context)!.report),
                                    ],
                                  ),
                                ),
                              ],
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
