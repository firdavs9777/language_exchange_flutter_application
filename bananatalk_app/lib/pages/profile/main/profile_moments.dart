import 'package:bananatalk_app/pages/profile/about/profile_single_moment.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileMoments extends ConsumerStatefulWidget {
  const ProfileMoments({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ProfileMoments> createState() => _ProfileMomentsState();
}

class _ProfileMomentsState extends ConsumerState<ProfileMoments> {
  bool _isGridView = false;

  Future<void> _refreshMoments() async {
    if (!mounted) return;
    
    // Invalidate to clear cache
    ref.invalidate(userMomentsProvider(widget.id));
    
    // Force refresh by reading the provider (triggers immediate refetch)
    // This ensures fresh data is loaded from backend
    try {
      await ref.read(userMomentsProvider(widget.id).future);
      // Clear image cache to ensure fresh images are loaded
      imageCache.clear();
      imageCache.clearLiveImages();
    } catch (e) {
      // Ignore errors - provider will handle them in the UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final momentsAsync = ref.watch(userMomentsProvider(widget.id));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Moments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMoments,
        child: momentsAsync.when(
          data: (moments) {
            if (moments.isEmpty) {
              return _buildEmptyState();
            }
            return _buildMomentsList(moments);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.photo_library_outlined,
                size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            'No moments yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your language learning journey!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Error: ${error.toString()}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshMoments,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentsList(List<Moments> moments) {

    if (_isGridView) {
      return _buildGridView(moments);
    } else {
      return _buildListView(moments);
    }
  }

  Widget _buildGridView(List<Moments> moments) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: moments.length,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final moment = moments[index];
        return _buildGridItem(moment);
      },
    );
  }

  Widget _buildGridItem(Moments moment) {
    final imageUrl = moment.imageUrls.isNotEmpty
        ? ImageUtils.normalizeImageUrl(moment.imageUrls[0])
        : null;

    return GestureDetector(
      onTap: () => _showMomentDetail(moment),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
              // Overlay for multiple images indicator
              if (moment.imageUrls.length > 1)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.collections,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${moment.imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Moments> moments) {
    return ListView.builder(
      itemCount: moments.length,
      cacheExtent: 200,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        // Use a key that includes the moment's image count and first image URL hash
        // This forces a rebuild when images change
        final moment = moments[index];
        final imageKey = moment.imageUrls.isNotEmpty 
            ? moment.imageUrls[0].hashCode 
            : 0;
        return ProfileSingleMoment(
          key: ValueKey('moment_${moment.id}_${moment.imageUrls.length}_$imageKey'),
          moment: moment,
          onDeleted: () => _refreshMoments(),
          onUpdated: () => _refreshMoments(),
        );
      },
    );
  }

  void _showMomentDetail(Moments moment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: ProfileSingleMoment(
              key: ValueKey('detail_${moment.id}'),
              moment: moment,
              onDeleted: () {
                Navigator.pop(context);
                _refreshMoments();
              },
              onUpdated: () {
                _refreshMoments();
              },
            ),
          );
        },
      ),
    );
  }
}
