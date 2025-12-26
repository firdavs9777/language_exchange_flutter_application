import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';
import 'package:intl/intl.dart';

/// Screen showing archived stories
class StoryArchiveScreen extends StatefulWidget {
  const StoryArchiveScreen({Key? key}) : super(key: key);

  @override
  State<StoryArchiveScreen> createState() => _StoryArchiveScreenState();
}

class _StoryArchiveScreenState extends State<StoryArchiveScreen> {
  List<Story> _stories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadArchive();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadArchive({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _isLoading = true;
      });
    }

    try {
      final response = await StoriesService.getArchivedStories(
        page: _page,
        limit: 20,
      );
      
      if (mounted) {
        setState(() {
          if (refresh || _page == 1) {
            _stories = response.data;
          } else {
            _stories.addAll(response.data);
          }
          _totalPages = response.pages;
          _isLoading = false;
          _error = response.error;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _page >= _totalPages) return;
    
    setState(() => _isLoadingMore = true);
    _page++;
    await _loadArchive();
    setState(() => _isLoadingMore = false);
  }

  void _viewStory(Story story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArchivedStoryViewerScreen(story: story),
      ),
    );
  }

  void _addToHighlight(Story story) async {
    // Get highlights list
    final highlightsResponse = await StoriesService.getMyHighlights();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddToHighlightSheet(
        story: story,
        highlights: highlightsResponse.data,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Story Archive'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.grey[600], size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadArchive(refresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _stories.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () => _loadArchive(refresh: true),
                      child: _buildArchiveGrid(),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.archive_outlined, color: Colors.grey[600], size: 64),
          const SizedBox(height: 16),
          Text(
            'No archived stories',
            style: TextStyle(color: Colors.grey[600], fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Your expired stories will appear here',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveGrid() {
    // Group stories by month
    final groupedStories = <String, List<Story>>{};
    for (final story in _stories) {
      final monthKey = DateFormat('MMMM yyyy').format(story.createdAt);
      groupedStories.putIfAbsent(monthKey, () => []).add(story);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: groupedStories.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == groupedStories.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final month = groupedStories.keys.elementAt(index);
        final monthStories = groupedStories[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                month,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: monthStories.length,
              itemBuilder: (context, gridIndex) {
                final story = monthStories[gridIndex];
                return _ArchiveStoryTile(
                  story: story,
                  onTap: () => _viewStory(story),
                  onLongPress: () => _addToHighlight(story),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ArchiveStoryTile extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ArchiveStoryTile({
    required this.story,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: story.mediaType == 'text'
              ? Color(int.parse(story.backgroundColor.replaceFirst('#', '0xFF')))
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(4),
        ),
        child: story.mediaType == 'text'
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    story.text ?? '',
                    style: TextStyle(
                      color: Color(int.parse(story.textColor.replaceFirst('#', '0xFF'))),
                      fontSize: 10,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      story.mediaUrl.isNotEmpty 
                          ? story.mediaUrl 
                          : (story.mediaUrls.isNotEmpty ? story.mediaUrls.first : ''),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  if (story.mediaType == 'video')
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(Icons.play_circle_outline, color: Colors.white, size: 20),
                    ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility, color: Colors.white, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            '${story.viewCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class ArchivedStoryViewerScreen extends StatelessWidget {
  final Story story;

  const ArchivedStoryViewerScreen({Key? key, required this.story}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          DateFormat('MMM d, yyyy • h:mm a').format(story.createdAt),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: Colors.grey[900],
            onSelected: (value) async {
              switch (value) {
                case 'highlight':
                  final highlights = await StoriesService.getMyHighlights();
                  if (context.mounted) {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.grey[900],
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => _AddToHighlightSheet(
                        story: story,
                        highlights: highlights.data,
                      ),
                    );
                  }
                  break;
                case 'repost':
                  // Implement repost logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Repost feature coming soon')),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'highlight',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Add to Highlight', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'repost',
                child: Row(
                  children: [
                    Icon(Icons.repeat, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Repost', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: story.mediaType == 'text'
            ? Container(
                color: Color(int.parse(story.backgroundColor.replaceFirst('#', '0xFF'))),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(32),
                child: Text(
                  story.text ?? '',
                  style: TextStyle(
                    color: Color(int.parse(story.textColor.replaceFirst('#', '0xFF'))),
                    fontSize: 24,
                    fontWeight: story.fontStyle == 'bold' ? FontWeight.bold : FontWeight.normal,
                    fontStyle: story.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : Image.network(
                story.mediaUrl.isNotEmpty 
                    ? story.mediaUrl 
                    : (story.mediaUrls.isNotEmpty ? story.mediaUrls.first : ''),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                ),
              ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black,
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text(
                '${story.viewCount} views',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(width: 24),
              Icon(Icons.favorite, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text(
                '${story.reactionCount} reactions',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddToHighlightSheet extends StatelessWidget {
  final Story story;
  final List<StoryHighlight> highlights;

  const _AddToHighlightSheet({
    required this.story,
    required this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Add to Highlight',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          title: const Text('New Highlight', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) => _CreateHighlightWithStoryDialog(storyId: story.id),
            );
          },
        ),
        const Divider(color: Colors.grey),
        if (highlights.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No highlights yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: highlights.length,
              itemBuilder: (context, index) {
                final highlight = highlights[index];
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[600]!),
                      image: highlight.coverImage != null
                          ? DecorationImage(
                              image: NetworkImage(highlight.coverImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: highlight.coverImage == null
                        ? const Icon(Icons.auto_awesome, color: Colors.grey)
                        : null,
                  ),
                  title: Text(highlight.title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${highlight.storyCount} stories',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  onTap: () async {
                    final result = await StoriesService.addToHighlight(
                      highlightId: highlight.id,
                      storyId: story.id,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result['success'] == true 
                              ? 'Added to ${highlight.title}'
                              : 'Failed to add',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CreateHighlightWithStoryDialog extends StatefulWidget {
  final String storyId;

  const _CreateHighlightWithStoryDialog({required this.storyId});

  @override
  State<_CreateHighlightWithStoryDialog> createState() => _CreateHighlightWithStoryDialogState();
}

class _CreateHighlightWithStoryDialogState extends State<_CreateHighlightWithStoryDialog> {
  final _controller = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('New Highlight', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Highlight name',
          hintStyle: TextStyle(color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
        ),
        ElevatedButton(
          onPressed: _isCreating
              ? null
              : () async {
                  if (_controller.text.trim().isEmpty) return;
                  setState(() => _isCreating = true);
                  
                  final result = await StoriesService.createHighlight(
                    title: _controller.text.trim(),
                    storyId: widget.storyId,
                  );
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['success'] == true 
                            ? 'Highlight created' 
                            : 'Failed to create highlight',
                      ),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

