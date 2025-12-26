import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/story_model.dart';
import 'package:bananatalk_app/services/stories_service.dart';

/// Screen showing all highlights for a user
class StoryHighlightsScreen extends StatefulWidget {
  final String? userId; // null means current user

  const StoryHighlightsScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<StoryHighlightsScreen> createState() => _StoryHighlightsScreenState();
}

class _StoryHighlightsScreenState extends State<StoryHighlightsScreen> {
  List<StoryHighlight> _highlights = [];
  bool _isLoading = true;
  String? _error;

  bool get _isOwnProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    setState(() => _isLoading = true);
    
    try {
      final response = widget.userId != null
          ? await StoriesService.getUserHighlights(userId: widget.userId!)
          : await StoriesService.getMyHighlights();
      
      if (mounted) {
        setState(() {
          _highlights = response.data;
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

  void _createHighlight() {
    showDialog(
      context: context,
      builder: (context) => CreateHighlightDialog(
        onCreated: (highlight) {
          setState(() => _highlights.insert(0, highlight));
        },
      ),
    );
  }

  void _editHighlight(StoryHighlight highlight) {
    showDialog(
      context: context,
      builder: (context) => EditHighlightDialog(
        highlight: highlight,
        onUpdated: () => _loadHighlights(),
        onDeleted: () {
          setState(() => _highlights.removeWhere((h) => h.id == highlight.id));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Highlights'),
        actions: [
          if (_isOwnProfile)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _createHighlight,
            ),
        ],
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
                        onPressed: _loadHighlights,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _highlights.isEmpty
                  ? _buildEmptyState()
                  : _buildHighlightsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, color: Colors.grey[600], size: 64),
          const SizedBox(height: 16),
          Text(
            _isOwnProfile 
                ? 'No highlights yet' 
                : 'No highlights',
            style: TextStyle(color: Colors.grey[600], fontSize: 18),
          ),
          if (_isOwnProfile) ...[
            const SizedBox(height: 8),
            Text(
              'Save your favorite stories to highlights',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createHighlight,
              icon: const Icon(Icons.add),
              label: const Text('Create Highlight'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightsList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _highlights.length + (_isOwnProfile ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isOwnProfile && index == 0) {
          return _buildAddHighlightTile();
        }
        final highlightIndex = _isOwnProfile ? index - 1 : index;
        final highlight = _highlights[highlightIndex];
        return _buildHighlightTile(highlight);
      },
    );
  }

  Widget _buildAddHighlightTile() {
    return GestureDetector(
      onTap: _createHighlight,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[700]!, width: 2),
            ),
            child: Icon(Icons.add, color: Colors.grey[600], size: 32),
          ),
          const SizedBox(height: 8),
          const Text(
            'New',
            style: TextStyle(color: Colors.white, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightTile(StoryHighlight highlight) {
    return GestureDetector(
      onTap: () {
        // Navigate to highlight viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HighlightViewerScreen(highlight: highlight),
          ),
        );
      },
      onLongPress: _isOwnProfile ? () => _editHighlight(highlight) : null,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[600]!,
                width: 2,
              ),
              image: highlight.coverImage != null
                  ? DecorationImage(
                      image: NetworkImage(highlight.coverImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: highlight.coverImage == null
                ? Icon(Icons.auto_awesome, color: Colors.grey[500])
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            highlight.title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${highlight.storyCount} stories',
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
        ],
      ),
    );
  }
}

/// Highlight viewer screen
class HighlightViewerScreen extends StatefulWidget {
  final StoryHighlight highlight;

  const HighlightViewerScreen({Key? key, required this.highlight}) : super(key: key);

  @override
  State<HighlightViewerScreen> createState() => _HighlightViewerScreenState();
}

class _HighlightViewerScreenState extends State<HighlightViewerScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stories = widget.highlight.stories;
    
    if (stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'No stories in this highlight',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            // Left tap - previous
            if (_currentIndex > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            // Right tap - next
            if (_currentIndex < stories.length - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              Navigator.pop(context);
            }
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                return story.mediaType == 'text'
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
                        errorBuilder: (context, error, stackTrace) => 
                            const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      );
              },
            ),
            // Progress bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(stories.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentIndex 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Text(
                    widget.highlight.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Create highlight dialog
class CreateHighlightDialog extends StatefulWidget {
  final Function(StoryHighlight) onCreated;

  const CreateHighlightDialog({Key? key, required this.onCreated}) : super(key: key);

  @override
  State<CreateHighlightDialog> createState() => _CreateHighlightDialogState();
}

class _CreateHighlightDialogState extends State<CreateHighlightDialog> {
  final _titleController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_titleController.text.trim().isEmpty) return;
    
    setState(() => _isCreating = true);
    
    final result = await StoriesService.createHighlight(
      title: _titleController.text.trim(),
    );
    
    if (result['success'] == true && result['data'] != null) {
      widget.onCreated(result['data'] as StoryHighlight);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to create highlight')),
      );
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('New Highlight', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _titleController,
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
          onPressed: _isCreating ? null : _create,
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

/// Edit highlight dialog
class EditHighlightDialog extends StatefulWidget {
  final StoryHighlight highlight;
  final VoidCallback onUpdated;
  final VoidCallback onDeleted;

  const EditHighlightDialog({
    Key? key,
    required this.highlight,
    required this.onUpdated,
    required this.onDeleted,
  }) : super(key: key);

  @override
  State<EditHighlightDialog> createState() => _EditHighlightDialogState();
}

class _EditHighlightDialogState extends State<EditHighlightDialog> {
  late TextEditingController _titleController;
  bool _isUpdating = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.highlight.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_titleController.text.trim().isEmpty) return;
    
    setState(() => _isUpdating = true);
    
    final result = await StoriesService.updateHighlight(
      highlightId: widget.highlight.id,
      title: _titleController.text.trim(),
    );
    
    if (result['success'] == true) {
      widget.onUpdated();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to update')),
      );
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Highlight?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete this highlight.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isDeleting = true);
    
    final result = await StoriesService.deleteHighlight(
      highlightId: widget.highlight.id,
    );
    
    if (result['success'] == true) {
      widget.onDeleted();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to delete')),
      );
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('Edit Highlight', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : _delete,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: _isDeleting
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                )
              : const Text('Delete'),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : _update,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isUpdating
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

/// Highlight circle widget for profile
class HighlightCircle extends StatelessWidget {
  final StoryHighlight highlight;
  final VoidCallback? onTap;
  final double size;

  const HighlightCircle({
    Key? key,
    required this.highlight,
    this.onTap,
    this.size = 70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[600]!, width: 2),
              image: highlight.coverImage != null
                  ? DecorationImage(
                      image: NetworkImage(highlight.coverImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: highlight.coverImage == null
                ? Icon(Icons.auto_awesome, color: Colors.grey[500], size: size * 0.4)
                : null,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: size + 10,
            child: Text(
              highlight.title,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

