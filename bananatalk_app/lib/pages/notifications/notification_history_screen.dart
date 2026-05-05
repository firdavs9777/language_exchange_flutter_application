import 'package:bananatalk_app/models/notification_models.dart';
import 'package:bananatalk_app/providers/notification_history_provider.dart';
import 'package:bananatalk_app/services/notification_router.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(notificationHistoryProvider.notifier)
          .fetchHistory(refresh: true);
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
        return const Color(0xFFE91E63); // pink
      case 'moment_comment':
        return const Color(0xFF4CAF50); // green
      case 'friend_request':
        return const Color(0xFF00BCD4); // cyan
      case 'profile_visit':
        return const Color(0xFFFF9800); // orange
      case 'follower_moment':
        return const Color(0xFF7C4DFF); // purple
      case 'system':
        return const Color(0xFF607D8B); // gray
      case 'chat_message':
        return AppColors.primary; // teal
      default:
        return const Color(0xFF607D8B);
    }
  }

  Future<bool?> _showClearAllDialog() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: ctx.surfaceColor,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_sweep_rounded,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.clearAllNotifications,
                  style: ctx.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.clearAllNotificationsConfirm,
                  style: ctx.bodySmall.copyWith(
                    color: ctx.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: ctx.containerColor,
                        ),
                        child: Text(
                          l10n.cancel,
                          style: TextStyle(
                            color: ctx.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                        child: Text(
                          l10n.clearAll,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationHistoryProvider);
    final l10n = AppLocalizations.of(context)!;
    final unreadCount = state.notifications.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              l10n.notifications,
              style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (state.notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: context.textPrimary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                color: context.surfaceColor,
                elevation: 8,
                onSelected: (value) async {
                  if (value == 'mark_all_read') {
                    HapticFeedback.lightImpact();
                    await ref
                        .read(notificationHistoryProvider.notifier)
                        .markAllAsRead();
                  } else if (value == 'clear_all') {
                    HapticFeedback.lightImpact();
                    final confirm = await _showClearAllDialog();
                    if (confirm == true) {
                      await ref
                          .read(notificationHistoryProvider.notifier)
                          .clearAll();
                    }
                  }
                },
                itemBuilder: (popupContext) => [
                  PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.done_all_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.markAllRead,
                          style: context.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_sweep_rounded,
                            size: 16,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.clearAll,
                          style: context.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _buildBody(state, l10n),
    );
  }

  Widget _buildBody(NotificationHistoryState state, AppLocalizations l10n) {
    if (state.isLoading && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading notifications...',
              style: context.bodySmall.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    if (state.error != null && state.notifications.isEmpty) {
      return _buildErrorState(l10n);
    }

    if (state.notifications.isEmpty) {
      return _buildEmptyState(l10n);
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await ref
            .read(notificationHistoryProvider.notifier)
            .fetchHistory(refresh: true);
      },
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.notifications.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            );
          }

          final notification = state.notifications[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildNotificationItem(notification),
          );
        },
      ),
    );
  }

  // ========== EMPTY STATE ==========
  Widget _buildEmptyState(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(
                            alpha: isDark ? 0.25 : 0.15,
                          ),
                          AppColors.primary.withValues(
                            alpha: isDark ? 0.08 : 0.04,
                          ),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.noNotificationsYet,
                    style: context.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.whenYouGetNotifications,
                    style: context.bodyMedium.copyWith(
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== ERROR STATE ==========
  Widget _buildErrorState(AppLocalizations l10n) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.failedToLoadNotifications,
                    style: context.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(notificationHistoryProvider.notifier)
                            .fetchHistory();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.retry,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== NOTIFICATION ITEM ==========
  Widget _buildNotificationItem(NotificationItem notification) {
    final iconColor = _getNotificationColor(notification.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnread = !notification.read;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        ref
            .read(notificationHistoryProvider.notifier)
            .removeNotification(notification.id);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            if (!notification.read) {
              ref
                  .read(notificationHistoryProvider.notifier)
                  .markAsRead(notification.id);
            }
            if (notification.data.isNotEmpty) {
              NotificationRouter.handleNotification(context, notification.data);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUnread
                  ? iconColor.withValues(alpha: isDark ? 0.1 : 0.06)
                  : context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnread
                    ? iconColor.withValues(alpha: isDark ? 0.3 : 0.2)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : context.dividerColor.withValues(alpha: 0.5)),
                width: 1,
              ),
              boxShadow: !isDark && !isUnread
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [iconColor, iconColor.withValues(alpha: 0.78)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: context.titleSmall.copyWith(
                                fontWeight: isUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: context.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (notification.bundleSize > 1) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(
                                  alpha: isDark ? 0.25 : 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+${notification.bundleSize}',
                                style: TextStyle(
                                  color: iconColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                          if (notification.suppressedReason != null) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message:
                                  notification.suppressedReason == 'quiet_hours'
                                  ? AppLocalizations.of(
                                      context,
                                    )!.silencedByQuietHours
                                  : AppLocalizations.of(context)!.silencedByCap,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: context.containerColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_paused_rounded,
                                  size: 12,
                                  color: context.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: context.bodySmall.copyWith(
                          color: context.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: context.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            timeago.format(notification.createdAt),
                            style: context.captionSmall.copyWith(
                              color: context.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Unread indicator
                if (isUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
