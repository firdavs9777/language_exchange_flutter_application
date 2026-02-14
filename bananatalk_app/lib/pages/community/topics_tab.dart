import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/widgets/community/topic_chip.dart';
import 'package:bananatalk_app/widgets/community/compact_user_tile.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Topics Tab - Topic-based discovery
class TopicsTab extends ConsumerStatefulWidget {
  final Map<String, dynamic> filters;
  final String searchQuery;

  const TopicsTab({
    super.key,
    required this.filters,
    required this.searchQuery,
  });

  @override
  ConsumerState<TopicsTab> createState() => _TopicsTabState();
}

class _TopicsTabState extends ConsumerState<TopicsTab> {
  String? _selectedCategory;
  String? _selectedTopicId;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId') ?? '';
    });
  }

  List<Topic> get _filteredTopics {
    if (_selectedCategory == null) {
      return Topic.defaultTopics;
    }
    return Topic.defaultTopics
        .where((t) => t.category == _selectedCategory)
        .toList();
  }

  List<Community> _getUsersForTopic(
    List<Community> communities,
    Set<String> blockedUserIds,
  ) {
    if (_selectedTopicId == null) return [];

    return communities.where((community) {
      if (community.id == _userId) return false;
      if (blockedUserIds.contains(community.id)) return false;

      // Check if user has the selected topic
      if (!community.topics.contains(_selectedTopicId)) return false;

      // Apply search query
      if (widget.searchQuery.isNotEmpty) {
        final query = widget.searchQuery.toLowerCase();
        return community.name.toLowerCase().contains(query) ||
            community.bio.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  void _viewProfile(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SingleCommunity(community: community),
      ),
    );
  }

  void _onWave(String userName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.waving_hand, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Waved to $userName!'),
          ],
        ),
        backgroundColor: const Color(0xFF00BFA5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMD),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category tabs
        _buildCategoryTabs(),
        // Topics grid or user list
        Expanded(
          child: _selectedTopicId != null
              ? _buildUsersForTopic()
              : _buildTopicsGrid(),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['All', ...Topic.categories];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = (category == 'All' && _selectedCategory == null) ||
              category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category == 'All' ? null : category;
                _selectedTopicId = null;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00BFA5).withOpacity(0.15)
                    : Colors.grey[100],
                borderRadius: AppRadius.borderLG,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00BFA5)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Builder(
                builder: (context) => Text(
                  category == 'All'
                      ? 'All'
                      : Topic.getCategoryLabel(category),
                  style: context.labelMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF00BFA5)
                        : context.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopicsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredTopics.length,
      itemBuilder: (context, index) {
        final topic = _filteredTopics[index];
        return _TopicCard(
          topic: topic,
          onTap: () {
            setState(() {
              _selectedTopicId = topic.id;
            });
          },
        );
      },
    );
  }

  Widget _buildUsersForTopic() {
    final communityAsync = ref.watch(communityProvider);
    final blockedUserIdsAsync = ref.watch(blockedUserIdsProvider);

    final selectedTopic = Topic.defaultTopics.firstWhere(
      (t) => t.id == _selectedTopicId,
      orElse: () => Topic(
        id: _selectedTopicId!,
        name: _selectedTopicId!,
        icon: '🏷️',
        category: 'other',
      ),
    );

    return Column(
      children: [
        // Topic header with back button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedTopicId = null;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                ),
              ),
              Spacing.hGapMD,
              Text(
                selectedTopic.icon,
                style: const TextStyle(fontSize: 28),
              ),
              Spacing.hGapMD,
              Expanded(
                child: Builder(
                  builder: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedTopic.name,
                        style: context.titleMedium,
                      ),
                      Text(
                        'People interested in this topic',
                        style: context.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Users list
        Expanded(
          child: communityAsync.when(
            data: (communities) {
              final blockedUserIds = blockedUserIdsAsync.value ?? <String>{};
              final users = _getUsersForTopic(communities, blockedUserIds);

              if (users.isEmpty) {
                return _buildNoUsersForTopic();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(communityProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CompactUserTile(
                        user: user,
                        onTap: () => _viewProfile(user),
                        onWave: () => _onWave(user.name),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
            ),
            error: (e, s) => Center(
              child: Text('Error: $e'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoUsersForTopic() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            Spacing.gapMD,
            Builder(
              builder: (context) => Text(
                'No users found',
                style: context.titleMedium,
              ),
            ),
            Spacing.gapSM,
            Builder(
              builder: (context) => Text(
                'Be the first to add this topic to your interests!',
                textAlign: TextAlign.center,
                style: context.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Topic topic;
  final VoidCallback? onTap;

  const _TopicCard({
    required this.topic,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMD,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppRadius.borderMD,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                topic.icon,
                style: const TextStyle(fontSize: 28),
              ),
              Spacing.hGapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      topic.name,
                      style: context.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (topic.userCount > 0)
                      Text(
                        '${_formatCount(topic.userCount)} people',
                        style: context.caption.copyWith(
                          color: context.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
