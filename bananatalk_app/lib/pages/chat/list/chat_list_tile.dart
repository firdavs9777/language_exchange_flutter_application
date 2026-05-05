import 'package:bananatalk_app/pages/chat/models/chat_partner.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/vip_avatar_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// Per-thread row in the chat list.
///
/// Renders: avatar with VIP frame + online-status dot, name row (VIP badge,
/// pin/mute indicators, timestamp), last-message preview (or typing indicator),
/// unread-count badge, and three swipe actions (pin, mute, delete).
///
/// All state lives in the parent [ChatMain]; this widget is purely
/// presentational.
class ChatListTile extends StatelessWidget {
  final ChatPartner partner;
  final bool isActive;
  final bool isTyping;
  final String realtimeStatus;
  final VoidCallback onTap;
  final ValueChanged<ChatPartner> onPin;
  final ValueChanged<ChatPartner> onMute;
  final ValueChanged<ChatPartner> onDelete;

  const ChatListTile({
    super.key,
    required this.partner,
    required this.isActive,
    required this.isTyping,
    required this.realtimeStatus,
    required this.onTap,
    required this.onPin,
    required this.onMute,
    required this.onDelete,
  });

  // ─── Status helpers ───────────────────────────────────────────────────────

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return const Color(0xFF4ADE80);
      case 'away':
        return const Color(0xFFFBBF24);
      case 'busy':
      case 'dnd':
        return const Color(0xFFF87171);
      case 'recently online':
        return const Color(0xFF60A5FA);
      case 'offline':
      default:
        return const Color(0xFFD1D5DB);
    }
  }

  bool get _isOnline => realtimeStatus.toLowerCase() == 'online';

  // ─── Time formatter ───────────────────────────────────────────────────────

  static String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 6) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  // ─── Typing indicator ─────────────────────────────────────────────────────

  Widget _buildTypingDots() {
    return SizedBox(
      width: 24,
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 150)),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withValues(alpha: value),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTypingDots(),
        const SizedBox(width: 6),
        const Text(
          'typing...',
          style: TextStyle(
            color: Color(0xFF4ADE80),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Slidable(
      key: ValueKey(partner.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.75,
        children: [
          // Pin / Unpin
          SlidableAction(
            onPressed: (_) => onPin(partner),
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            icon: partner.isPinned
                ? Icons.push_pin
                : Icons.push_pin_outlined,
            label: partner.isPinned ? 'Unpin' : 'Pin',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          // Mute / Unmute
          SlidableAction(
            onPressed: (_) => onMute(partner),
            backgroundColor: const Color(0xFFFF9800),
            foregroundColor: Colors.white,
            icon: partner.isMuted
                ? Icons.notifications
                : Icons.notifications_off,
            label: partner.isMuted ? 'Unmute' : 'Mute',
          ),
          // Delete
          SlidableAction(
            onPressed: (_) => onDelete(partner),
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // ─── Avatar ───────────────────────────────────────────────────
              Stack(
                children: [
                  VipAvatarFrameCompact(
                    isVip: partner.isVip,
                    size: 56,
                    child: CachedCircleAvatar(
                      imageUrl: partner.avatar != null &&
                              partner.avatar!.isNotEmpty
                          ? partner.avatar
                          : null,
                      radius: 28,
                      backgroundColor: colors.surfaceVariant,
                      errorWidget: Text(
                        partner.name.isNotEmpty
                            ? partner.name[0].toUpperCase()
                            : '?',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Online status dot
                  Positioned(
                    bottom: partner.isVip ? 4 : 2,
                    right: partner.isVip ? 4 : 2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isOnline ? 16 : 12,
                      height: _isOnline ? 16 : 12,
                      decoration: BoxDecoration(
                        color: getStatusColor(realtimeStatus),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.surface,
                          width: 2.5,
                        ),
                        boxShadow: _isOnline
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // ─── Content ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name row
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  partner.name,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (partner.isVip) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFFA500),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.workspace_premium,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'VIP',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Pin indicator
                        if (partner.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.push_pin,
                              size: 14,
                              color: colors.primary,
                            ),
                          ),
                        // Mute indicator
                        if (partner.isMuted)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.notifications_off,
                              size: 14,
                              color: colors.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        if (partner.lastMessageTime != null)
                          Text(
                            formatTime(partner.lastMessageTime!),
                            style: TextStyle(
                              color: partner.unreadCount > 0
                                  ? const Color(0xFFEF4444)
                                  : colors.onSurface.withValues(alpha: 0.4),
                              fontSize: 12,
                              fontWeight: partner.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Last message + unread badge
                    Row(
                      children: [
                        Expanded(
                          child: isTyping
                              ? _buildTypingIndicator()
                              : Row(
                                  children: [
                                    if (_isOnline) ...[
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4ADE80),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                    Expanded(
                                      child: Text(
                                        partner.lastMessage ?? 'No messages yet',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: partner.unreadCount > 0
                                              ? colors.onSurface
                                              : colors.onSurface
                                                  .withValues(alpha: 0.5),
                                          fontWeight: partner.unreadCount > 0
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        // Unread count badge
                        if (partner.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              partner.unreadCount > 99
                                  ? '99+'
                                  : partner.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
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
      ),
    );
  }
}
