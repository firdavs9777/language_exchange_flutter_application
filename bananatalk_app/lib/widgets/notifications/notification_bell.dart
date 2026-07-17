import 'package:bananatalk_app/pages/notifications/notification_history_screen.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-bar notification bell with an unread-count badge, opening the
/// notification inbox ([NotificationHistoryScreen]).
///
/// Single source of truth for the bell so it can sit consistently in every
/// tab's app bar (chat, community, learning, profile) instead of only chat.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.color, this.size = 26});

  /// Icon colour. Defaults to the theme's onSurface when null.
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.onSurface;
    final badgeBorder = theme.scaffoldBackgroundColor;
    final notificationCount = ref.watch(badgeCountProvider).notifications;

    return IconButton(
      tooltip: 'Notifications',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: iconColor, size: size),
          if (notificationCount > 0)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeBorder, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  notificationCount > 99 ? '99+' : notificationCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        Navigator.push(
          context,
          AppPageRoute(
            builder: (context) => const NotificationHistoryScreen(),
          ),
        );
      },
    );
  }
}
