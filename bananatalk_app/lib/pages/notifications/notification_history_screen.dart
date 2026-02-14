import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/providers/notification_history_provider.dart';
import 'package:bananatalk_app/services/notification_router.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  ConsumerState<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends ConsumerState<NotificationHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Refresh notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationHistoryProvider.notifier).fetchHistory(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationHistoryProvider.notifier).loadMore();
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'moment_like':
        return Icons.favorite_rounded;
      case 'moment_comment':
        return Icons.comment_rounded;
      case 'friend_request':
        return Icons.person_add_rounded;
      case 'profile_visit':
        return Icons.visibility_rounded;
      case 'follower_moment':
        return Icons.auto_awesome_rounded;
      case 'system':
        return Icons.info_rounded;
      case 'chat_message':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'moment_like':
        return AppColors.error;
      case 'moment_comment':
        return AppColors.success;
      case 'friend_request':
        return AppColors.info;
      case 'profile_visit':
        return AppColors.warning;
      case 'follower_moment':
        return AppColors.accent;
      case 'system':
        return AppColors.gray500;
      case 'chat_message':
        return AppColors.primary;
      default:
        return AppColors.gray600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationHistoryProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
        title: Text(
          'Notifications',
          style: context.titleLarge,
        ),
        actions: [
          if (state.notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: context.iconColor),
              onSelected: (value) async {
                if (value == 'mark_all_read') {
                  await ref
                      .read(notificationHistoryProvider.notifier)
                      .markAllAsRead();
                } else if (value == 'clear_all') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderLG,
                      ),
                      title: Text(
                        'Clear All Notifications',
                        style: context.titleLarge,
                      ),
                      content: Text(
                        'Are you sure you want to clear all notifications? This cannot be undone.',
                        style: context.bodyMedium,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: context.labelLarge.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: Text(
                            'Clear All',
                            style: context.labelLarge.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(notificationHistoryProvider.notifier)
                        .clearAll();
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20, color: context.iconColor),
                      Spacing.hGapMD,
                      Text('Mark all as read', style: context.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                      Spacing.hGapMD,
                      Text(
                        'Clear all',
                        style: context.bodyMedium.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationHistoryState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            Spacing.gapLG,
            Text(
              'Failed to load notifications',
              style: context.bodyMedium,
            ),
            Spacing.gapSM,
            TextButton(
              onPressed: () {
                ref.read(notificationHistoryProvider.notifier).fetchHistory();
              },
              child: Text(
                'Retry',
                style: context.labelLarge.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: context.textHint,
            ),
            Spacing.gapLG,
            Text(
              'No notifications yet',
              style: context.titleLarge,
            ),
            Spacing.gapSM,
            Text(
              'When you get notifications, they\'ll show up here',
              style: context.bodyMedium.copyWith(
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(notificationHistoryProvider.notifier)
            .fetchHistory(refresh: true);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.notifications.length) {
            return Padding(
              padding: Spacing.paddingLG,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final notification = state.notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    final iconColor = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      onDismissed: (_) {
        ref
            .read(notificationHistoryProvider.notifier)
            .removeNotification(notification.id);
      },
      child: InkWell(
        onTap: () {
          // Mark as read
          if (!notification.read) {
            ref
                .read(notificationHistoryProvider.notifier)
                .markAsRead(notification.id);
          }

          // Navigate based on notification data
          if (notification.data.isNotEmpty) {
            NotificationRouter.handleNotification(context, notification.data);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.read
                ? Colors.transparent
                : iconColor.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: context.dividerColor.withOpacity(0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: iconColor,
                  size: 22,
                ),
              ),
              Spacing.hGapMD,

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: context.titleSmall.copyWith(
                        fontWeight:
                            notification.read ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                    Spacing.gapXS,
                    Text(
                      notification.body,
                      style: context.bodySmall.copyWith(
                        color: context.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.gapSM,
                    Text(
                      timeago.format(notification.createdAt),
                      style: context.caption,
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (!notification.read)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
