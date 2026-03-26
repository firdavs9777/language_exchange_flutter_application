import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/widgets/community/compact_user_tile.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/chat/chat_single.dart';
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

  List<Topic> get _filteredTopics {
    if (_selectedCategory == null) {
      return Topic.defaultTopics;
    }
    return Topic.defaultTopics
        .where((t) => t.category == _selectedCategory)
        .toList();
  }

  void _loadTopicUsers(String topicId) {
    ref.read(topicUsersProvider.notifier).loadTopic(topicId);
  }

  void _viewProfile(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SingleCommunity(community: community),
      ),
    );
  }

  // Send Hi message in background (fire and forget)
  Future<void> _sendHiMessage(String receiverId) async {
    try {
      final messageService = ref.read(messageServiceProvider);
      await messageService.sendMessage(
        receiver: receiverId,
        message: 'Hi 👋',
      );
    } catch (e) {
    }
  }

  void _onWave(Community user) {
    HapticFeedback.mediumImpact();

    // Navigate to chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          userId: user.id,
          userName: user.name,
          profilePicture: user.profileImageUrl,
          isVip: user.isVip,
        ),
      ),
    );

    // Send "Hi 👋" message in background
    _sendHiMessage(user.id);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primary;

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
                    ? (isDark
                        ? primaryColor.withValues(alpha: 0.25)
                        : primaryColor.withValues(alpha: 0.15))
                    : (isDark ? Colors.grey[850] : Colors.grey[100]),
                borderRadius: AppRadius.borderLG,
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.grey[700]! : Colors.transparent),
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
                        ? primaryColor
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
            // Load users from server
            _loadTopicUsers(topic.id);
          },
        );
      },
    );
  }

  Widget _buildUsersForTopic() {
    final topicUsersState = ref.watch(topicUsersProvider);

    final selectedTopic = Topic.defaultTopics.firstWhere(
      (t) => t.id == _selectedTopicId,
      orElse: () => Topic(
        id: _selectedTopicId!,
        name: _selectedTopicId!,
        icon: '🏷️',
        category: 'other',
      ),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  ref.read(topicUsersProvider.notifier).clear();
                },
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey[850] : Colors.grey[100],
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
        // Users list - Server-side paginated
        Expanded(
          child: Builder(
            builder: (context) {
              // Show loading if initial load
              if (topicUsersState.isLoading && topicUsersState.users.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
                );
              }

              // Show error if any
              if (topicUsersState.error != null && topicUsersState.users.isEmpty) {
                return Center(
                  child: Text('Error: ${topicUsersState.error}'),
                );
              }

              final users = topicUsersState.users;

              if (users.isEmpty) {
                return _buildNoUsersForTopic();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  if (_selectedTopicId != null) {
                    _loadTopicUsers(_selectedTopicId!);
                  }
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    // Load more when near bottom
                    if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200 &&
                        !topicUsersState.isLoadingMore &&
                        topicUsersState.hasMore) {
                      ref.read(topicUsersProvider.notifier).loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length + (topicUsersState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= users.length) {
                        // Loading indicator at bottom
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
                          ),
                        );
                      }
                      final user = users[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CompactUserTile(
                          user: user,
                          onTap: () => _viewProfile(user),
                          onWave: () => _onWave(user),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoUsersForTopic() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                : null,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
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
                        color: context.textPrimary,
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
                color: isDark ? Colors.grey[600] : Colors.grey[400],
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
