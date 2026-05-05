import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/bookmark_service.dart';
import 'package:intl/intl.dart';
import 'package:bananatalk_app/utils/time_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/chat/widgets/chat_snackbar.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<BookmarkedMessage> _bookmarks = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMoreBookmarks();
    }
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await BookmarkService.getBookmarks(page: 1, limit: 20);

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _bookmarks = result['data'] as List<BookmarkedMessage>;
            _totalPages = result['pages'] as int;
            _currentPage = 1;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result['error'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load bookmarks';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreBookmarks() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;

    setState(() => _isLoadingMore = true);

    try {
      final result = await BookmarkService.getBookmarks(
        page: _currentPage + 1,
        limit: 20,
      );

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _bookmarks.addAll(result['data'] as List<BookmarkedMessage>);
            _currentPage++;
            _isLoadingMore = false;
          });
        } else {
          setState(() => _isLoadingMore = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _removeBookmark(BookmarkedMessage bookmark) async {
    final index = _bookmarks.indexOf(bookmark);
    
    // Optimistically remove
    setState(() {
      _bookmarks.removeAt(index);
    });

    try {
      final result = await BookmarkService.removeBookmark(
        messageId: bookmark.message.id,
      );

      if (mounted) {
        if (result['success'] != true) {
          // Restore on failure
          setState(() {
            _bookmarks.insert(index, bookmark);
          });
          showChatSnackBar(context, message: result['error'] ?? 'Failed to remove bookmark', type: ChatSnackBarType.error);
        } else {
          showChatSnackBar(context, message: AppLocalizations.of(context)!.bookmarkRemoved, type: ChatSnackBarType.success);
        }
      }
    } catch (e) {
      if (mounted) {
        // Restore on error
        setState(() {
          _bookmarks.insert(index, bookmark);
        });
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = parseToKoreaTime(dateString);
      final now = getKoreaNow();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today ${DateFormat('HH:mm').format(date)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday ${DateFormat('HH:mm').format(date)}';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE HH:mm').format(date);
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookmarkedMessages),
        actions: [
          if (_bookmarks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadBookmarks,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.textMuted),
            Spacing.gapMD,
            Text(
              _error!,
              style: TextStyle(color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
            Spacing.gapMD,
            ElevatedButton(
              onPressed: _loadBookmarks,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: context.textHint),
            Spacing.gapMD,
            Text(
              l10n.noBookmarkedMessages,
              style: TextStyle(
                fontSize: 18,
                color: context.textSecondary,
              ),
            ),
            Spacing.gapSM,
            Text(
              l10n.longPressToBookmark,
              style: TextStyle(
                color: context.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookmarks,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _bookmarks.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _bookmarks.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final bookmark = _bookmarks[index];
          return _buildBookmarkItem(bookmark);
        },
      ),
    );
  }

  Widget _buildBookmarkItem(BookmarkedMessage bookmark) {
    final message = bookmark.message;
    final senderName = message.sender.name ?? 'Unknown';
    final messageText = message.message ?? '[Media]';

    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      confirmDismiss: (direction) async {
        final l10n = AppLocalizations.of(context)!;
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.removeBookmark),
            content: Text(l10n.thisWillRemoveFromBookmarks),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.remove),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        _removeBookmark(bookmark);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () {
            // Navigate to the message in its conversation
            // This would need to be implemented based on your navigation structure
            showChatSnackBar(context, message: 'Navigate to message in chat with $senderName', type: ChatSnackBarType.info);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with sender info and bookmark date
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      backgroundImage: message.sender.images?.isNotEmpty == true
                          ? NetworkImage(message.sender.images!.first)
                          : null,
                      child: message.sender.images?.isEmpty != false
                          ? Text(
                              senderName.isNotEmpty
                                  ? senderName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Spacing.hGapMD,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(message.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.bookmark,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ],
                ),
                Spacing.gapMD,
                
                // Message content
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.containerColor,
                    borderRadius: AppRadius.borderMD,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Media indicator
                      if (message.media != null) ...[
                        Row(
                          children: [
                            Icon(
                              _getMediaIcon(message.media!.type),
                              size: 16,
                              color: context.textSecondary,
                            ),
                            Spacing.hGapXS,
                            Text(
                              _getMediaLabel(message.media!.type),
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (message.message != null) const SizedBox(height: 8),
                      ],
                      
                      // Text content
                      if (message.message != null)
                        Text(
                          messageText,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                // Bookmarked date
                Spacing.gapSM,
                Text(
                  'Bookmarked ${_formatDate(bookmark.bookmarkedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getMediaIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
      case 'voice':
        return Icons.mic;
      case 'document':
        return Icons.insert_drive_file;
      case 'location':
        return Icons.location_on;
      default:
        return Icons.attachment;
    }
  }

  String _getMediaLabel(String type) {
    switch (type) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'voice':
        return 'Voice message';
      case 'document':
        return 'Document';
      case 'location':
        return 'Location';
      default:
        return 'Attachment';
    }
  }
}

