import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/providers/notification_history_provider.dart';
import 'package:bananatalk_app/services/notification_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      ref.read(notificationHistoryProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await ref.read(notificationHistoryProvider.notifier).fetchHistory(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(notificationHistoryProvider);
    final unreadCount =
        ref.read(notificationHistoryProvider.notifier).unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notifications),
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(notificationHistoryProvider.notifier).markAllAsRead();
              },
              child: Text(
                AppLocalizations.of(context)!.markAllRead,
                style: const TextStyle(color: Color(0xFF00BFA5)),
              ),
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Text(AppLocalizations.of(context)!.clearAll2),
              ),
            ],
            onSelected: (value) {
              if (value == 'clear') {
                _showClearConfirmation();
              }
            },
          ),
        ],
      ),
      body: _buildBody(historyState),
    );
  }

  Widget _buildBody(NotificationHistoryState state) {
    if (state.notifications.isEmpty && !state.isLoading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFF00BFA5),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.notifications.length + (state.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                ),
              ),
            );
          }

          final notification = state.notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
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
          // Navigate to relevant screen
          NotificationRouter.handleNotification(context, notification.data);
        },
        child: Container(
          decoration: BoxDecoration(
            color: notification.read ? Colors.white : Colors.blue.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: ListTile(
            leading: _getNotificationIcon(notification.type),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.read
                    ? FontWeight.normal
                    : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(notification.body),
                const SizedBox(height: 4),
                Text(
                  _formatDate(notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: !notification.read
                ? Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00BFA5),
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'chat_message':
        icon = Icons.chat;
        color = Colors.blue;
        break;
      case 'moment_like':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case 'moment_comment':
        icon = Icons.comment;
        color = Colors.purple;
        break;
      case 'friend_request':
        icon = Icons.person_add;
        color = Colors.green;
        break;
      case 'profile_visit':
        icon = Icons.visibility;
        color = Colors.orange;
        break;
      case 'system':
        icon = Icons.info;
        color = Colors.grey;
        break;
      default:
        icon = Icons.notifications;
        color = const Color(0xFF00BFA5);
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'This will permanently delete all your notification history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notificationHistoryProvider.notifier).clearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.clearAll),
          ),
        ],
      ),
    );
  }
}

