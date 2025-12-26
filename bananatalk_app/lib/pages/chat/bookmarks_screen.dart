import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/services/bookmark_service.dart';
import 'package:intl/intl.dart';
import 'package:bananatalk_app/utils/time_utils.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to remove bookmark'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bookmark removed'),
            ),
          );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarked Messages'),
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
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBookmarks,
              child: const Text('Retry'),
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
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No bookmarked messages',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Long press on a message to bookmark it',
              style: TextStyle(
                color: Colors.grey[400],
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
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove bookmark?'),
            content: const Text('This will remove the message from your bookmarks.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Navigate to message in chat with $senderName'),
              ),
            );
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
                    const SizedBox(width: 12),
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
                              color: Colors.grey[500],
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
                const SizedBox(height: 12),
                
                // Message content
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
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
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getMediaLabel(message.media!.type),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
                const SizedBox(height: 8),
                Text(
                  'Bookmarked ${_formatDate(bookmark.bookmarkedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
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

