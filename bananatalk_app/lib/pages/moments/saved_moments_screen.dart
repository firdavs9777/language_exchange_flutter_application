import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/services/moments_service.dart';
import 'package:bananatalk_app/pages/moments/moment_card.dart';

class SavedMomentsScreen extends StatefulWidget {
  const SavedMomentsScreen({Key? key}) : super(key: key);

  @override
  State<SavedMomentsScreen> createState() => _SavedMomentsScreenState();
}

class _SavedMomentsScreenState extends State<SavedMomentsScreen> {
  List<Moments> _moments = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSavedMoments();
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
      _loadMoreMoments();
    }
  }

  Future<void> _loadSavedMoments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await MomentsService.getSavedMoments(page: 1, limit: 10);

      if (mounted) {
        if (response.success) {
          setState(() {
            _moments = response.data;
            _totalPages = (response.totalMoments / 10).ceil();
            _currentPage = 1;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = response.error;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load saved moments';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreMoments() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;

    setState(() => _isLoadingMore = true);

    try {
      final response = await MomentsService.getSavedMoments(
        page: _currentPage + 1,
        limit: 10,
      );

      if (mounted) {
        if (response.success) {
          setState(() {
            _moments.addAll(response.data);
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

  void _removeMoment(String momentId) {
    setState(() {
      _moments.removeWhere((m) => m.id == momentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Moments'),
        actions: [
          if (_moments.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSavedMoments,
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
              onPressed: _loadSavedMoments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_moments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No saved moments',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the bookmark icon on a moment to save it',
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSavedMoments,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _moments.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _moments.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final moment = _moments[index];
          return Dismissible(
            key: Key(moment.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_remove, color: Colors.white),
                  SizedBox(height: 4),
                  Text('Unsave', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              final result = await MomentsService.unsaveMoment(momentId: moment.id);
              return result['success'] == true;
            },
            onDismissed: (direction) {
              _removeMoment(moment.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Moment unsaved')),
              );
            },
            child: MomentCard(
              moment: moment,
              onSaveChanged: () => _removeMoment(moment.id),
            ),
          );
        },
      ),
    );
  }
}

/// Reusable moment card that can be used across the app
class MomentCard extends StatelessWidget {
  final Moments moment;
  final VoidCallback? onSaveChanged;
  final VoidCallback? onTap;

  const MomentCard({
    Key? key,
    required this.moment,
    this.onSaveChanged,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: moment.user.images.isNotEmpty
                        ? NetworkImage(moment.user.images.first)
                        : null,
                    child: moment.user.images.isEmpty
                        ? Text(
                            moment.user.name?.isNotEmpty == true
                                ? moment.user.name![0].toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moment.user.name ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatDate(moment.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Category badge
                  if (moment.category.isNotEmpty && moment.category != 'general')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        moment.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Content
              if (moment.title.isNotEmpty)
                Text(
                  moment.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (moment.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  moment.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Images
              if (moment.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    moment.imageUrls.first,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  ),
                ),
              ],

              // Tags
              if (moment.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: moment.tags.take(5).map((tag) {
                    return Chip(
                      label: Text(
                        '#$tag',
                        style: const TextStyle(fontSize: 12),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${moment.likeCount}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.comment, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${moment.commentCount}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.bookmark, size: 16, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '${moment.saveCount}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  if (moment.mood.isNotEmpty)
                    Text(
                      _getMoodEmoji(moment.mood),
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getMoodEmoji(String mood) {
    final moods = MomentMood.all;
    final moodData = moods.firstWhere(
      (m) => m['value'] == mood,
      orElse: () => {'emoji': ''},
    );
    return moodData['emoji'] ?? '';
  }
}

