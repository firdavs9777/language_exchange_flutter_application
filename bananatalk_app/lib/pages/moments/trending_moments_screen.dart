import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/services/moments_service.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

class TrendingMomentsScreen extends StatefulWidget {
  const TrendingMomentsScreen({Key? key}) : super(key: key);

  @override
  State<TrendingMomentsScreen> createState() => _TrendingMomentsScreenState();
}

class _TrendingMomentsScreenState extends State<TrendingMomentsScreen> {
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
    _loadTrendingMoments();
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

  Future<void> _loadTrendingMoments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await MomentsService.getTrendingMoments(page: 1, limit: 10);

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
          _error = 'Failed to load trending moments';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreMoments() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;

    setState(() => _isLoadingMore = true);

    try {
      final response = await MomentsService.getTrendingMoments(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Trending'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrendingMoments,
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
              onPressed: _loadTrendingMoments,
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
            Icon(
              Icons.local_fire_department,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No trending moments yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for popular content',
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrendingMoments,
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
          return _TrendingMomentCard(
            moment: moment,
            rank: index + 1,
          );
        },
      ),
    );
  }
}

class _TrendingMomentCard extends StatelessWidget {
  final Moments moment;
  final int rank;

  const _TrendingMomentCard({
    required this.moment,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Navigate to moment detail
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank badge
            Stack(
              children: [
                // Image or placeholder
                if (moment.imageUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: CachedImageWidget(
                      imageUrl: moment.imageUrls.first,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: double.infinity,
                        height: 180,
                        color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 48),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.7),
                          Theme.of(context).primaryColor,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                  ),

                // Rank badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getRankColor(rank),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (rank <= 3)
                          Icon(
                            Icons.emoji_events,
                            size: 16,
                            color: rank == 1 ? Colors.amber : Colors.white,
                          ),
                        if (rank <= 3) const SizedBox(width: 4),
                        Text(
                          '#$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Engagement badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatEngagement(moment.likeCount + moment.commentCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info
                  Row(
                    children: [
                      CachedCircleAvatar(
                        imageUrl: moment.user.images.isNotEmpty
                            ? moment.user.images.first
                            : null,
                        radius: 16,
                        errorWidget: Text(
                          moment.user.name?.isNotEmpty == true
                              ? moment.user.name![0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          moment.user.name ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      // Category
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
                  const SizedBox(height: 8),

                  // Title and description
                  if (moment.title.isNotEmpty)
                    Text(
                      moment.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (moment.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      moment.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Stats
                  Row(
                    children: [
                      _buildStat(Icons.favorite, moment.likeCount, Colors.red),
                      const SizedBox(width: 16),
                      _buildStat(Icons.comment, moment.commentCount, Colors.blue),
                      const SizedBox(width: 16),
                      _buildStat(Icons.bookmark, moment.saveCount, Colors.amber),
                      const Spacer(),
                      Text(
                        _formatDate(moment.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, int count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          _formatCount(count),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.blueGrey;
    }
  }

  String _formatEngagement(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

