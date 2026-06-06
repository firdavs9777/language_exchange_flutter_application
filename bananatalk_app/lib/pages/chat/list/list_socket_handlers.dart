import 'dart:async';
import 'package:bananatalk_app/pages/chat/models/chat_partner.dart';
import 'package:bananatalk_app/utils/string_sanitizer.dart';
import 'package:flutter/material.dart';

/// Shared context passed to every socket-event free function.
///
/// Maps are passed by reference so mutations are visible back in the State.
/// Callbacks delegate back to the State for things that cannot be shared by
/// reference (Timer reassignment, setState, Riverpod reads).
class ListSocketContext {
  /// Mutable map of userId → isTyping. Mutated in place.
  final Map<String, bool> typingUsers;

  /// Mutable map of userId → {status, lastSeen}. Mutated in place.
  final Map<String, Map<String, dynamic>> userStatuses;

  /// Mutable list of chat partners. Replaced via [doSetState].
  final List<ChatPartner> chatPartners;

  /// The authenticated user's id (used to filter self-generated events).
  final String? currentUserId;

  /// Wrapper around State.setState so handlers can trigger rebuilds.
  final void Function(VoidCallback) doSetState;

  /// Returns the provider's current unread count for [userId].
  final int Function(String userId) readProviderUnreadCount;

  /// Synchronise local partner unread counts with the provider.
  final VoidCallback syncUnreadCounts;

  /// Recompute each partner's status from [userStatuses].
  final VoidCallback processChatPartnersWithStatus;

  /// Read the current typing timer (may be null).
  final Timer? Function() getTypingTimer;

  /// Replace the typing timer (null cancels it).
  final void Function(Timer?) setTypingTimer;

  const ListSocketContext({
    required this.typingUsers,
    required this.userStatuses,
    required this.chatPartners,
    required this.currentUserId,
    required this.doSetState,
    required this.readProviderUnreadCount,
    required this.syncUnreadCounts,
    required this.processChatPartnersWithStatus,
    required this.getTypingTimer,
    required this.setTypingTimer,
  });
}

// ─── Handler free functions ────────────────────────────────────────────────────

void handleUserTyping(ListSocketContext ctx, dynamic data) {
  try {
    final String userId = data['userId'].toString();
    if (userId.isEmpty || userId == ctx.currentUserId) return;

    ctx.doSetState(() {
      ctx.typingUsers[userId] = true;
    });
    ctx.getTypingTimer()?.cancel();
    ctx.setTypingTimer(
      Timer(const Duration(seconds: 5), () {
        ctx.doSetState(() {
          ctx.typingUsers[userId] = false;
        });
      }),
    );
  } catch (_) {}
}

void handleUserStoppedTyping(ListSocketContext ctx, dynamic data) {
  // Intentionally empty — typing auto-clears via handleUserTyping's timer.
}

void handleNewMessage(ListSocketContext ctx, dynamic data) {
  try {
    if (data == null) return;

    final messageData = data['message'] ?? data;

    final senderId =
        messageData['sender']?['_id']?.toString() ??
        messageData['sender']?.toString();
    final senderName =
        sanitize(messageData['sender']?['name'], 'Unknown');
    final senderUsername = messageData['sender']?['username']?.toString();
    final senderAvatar = messageData['sender']?['image']?.toString();
    final senderImageUrls =
        (messageData['sender']?['imageUrls'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final senderIsVip =
        messageData['sender']?['userMode'] == 'vip' ||
        messageData['sender']?['vipSubscription']?['isActive'] == true;

    final createdAt = messageData['createdAt'] != null
        ? DateTime.parse(messageData['createdAt'].toString())
        : DateTime.now();
    final messageText = _extractMessagePreview(messageData);

    if (senderId == null || senderId.isEmpty) return;
    if (senderId == ctx.currentUserId) return;

    final currentProviderCount = ctx.readProviderUnreadCount(senderId);

    ctx.doSetState(() {
      int partnerIndex = ctx.chatPartners.indexWhere((p) => p.id == senderId);

      if (partnerIndex != -1) {
        final existingPartner = ctx.chatPartners[partnerIndex];
        final updatedPartner = existingPartner.copyWith(
          lastMessage: messageText,
          lastMessageTime: createdAt,
          unreadCount: currentProviderCount,
        );
        ctx.chatPartners.removeAt(partnerIndex);
        ctx.chatPartners.insert(0, updatedPartner);
      } else {
        final newPartner = ChatPartner(
          id: senderId,
          name: senderName,
          username: senderUsername,
          avatar: senderAvatar,
          lastMessage: messageText,
          lastMessageTime: createdAt,
          unreadCount: currentProviderCount,
          imageUrls: senderImageUrls,
          status: 'online',
          isVip: senderIsVip,
        );
        ctx.chatPartners.insert(0, newPartner);
      }
    });
  } catch (_) {}
}

void handleMessageSent(ListSocketContext ctx, dynamic data) {
  try {
    if (data == null) return;

    final messageData = data['message'] ?? data;

    final receiverId =
        messageData['receiver']?['_id']?.toString() ??
        messageData['receiver']?.toString();
    final receiverName =
        sanitize(messageData['receiver']?['name'], 'Unknown');
    final receiverUsername = messageData['receiver']?['username']?.toString();
    final receiverAvatar = messageData['receiver']?['image']?.toString();
    final receiverImageUrls =
        (messageData['receiver']?['imageUrls'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final receiverIsVip =
        messageData['receiver']?['userMode'] == 'vip' ||
        messageData['receiver']?['vipSubscription']?['isActive'] == true;

    final createdAt = messageData['createdAt'] != null
        ? DateTime.parse(messageData['createdAt'].toString())
        : DateTime.now();
    final messageText = _extractMessagePreview(messageData);

    if (receiverId == null || receiverId.isEmpty) return;

    ctx.doSetState(() {
      int partnerIndex =
          ctx.chatPartners.indexWhere((p) => p.id == receiverId);

      if (partnerIndex != -1) {
        final existingPartner = ctx.chatPartners[partnerIndex];
        final updatedPartner = existingPartner.copyWith(
          lastMessage: messageText,
          lastMessageTime: createdAt,
        );
        ctx.chatPartners.removeAt(partnerIndex);
        ctx.chatPartners.insert(0, updatedPartner);
      } else {
        final newPartner = ChatPartner(
          id: receiverId,
          name: receiverName,
          username: receiverUsername,
          avatar: receiverAvatar,
          lastMessage: messageText,
          lastMessageTime: createdAt,
          unreadCount: 0,
          imageUrls: receiverImageUrls,
          status: 'online',
          isVip: receiverIsVip,
        );
        ctx.chatPartners.insert(0, newPartner);
      }
    });

    ctx.syncUnreadCounts();
  } catch (_) {}
}

void handleStatusUpdate(ListSocketContext ctx, dynamic data) {
  try {
    final userId = data['userId'];
    final status = data['status'];
    final lastSeen = data['lastSeen'];

    if (userId == null) return;

    ctx.doSetState(() {
      ctx.userStatuses[userId] = {
        'status': status,
        'lastSeen': lastSeen != null ? DateTime.parse(lastSeen) : null,
      };
    });

    ctx.processChatPartnersWithStatus();
  } catch (_) {}
}

void handleBulkStatusUpdate(ListSocketContext ctx, dynamic data) {
  try {
    if (data is! Map) return;

    final Map<String, dynamic> rawData = Map<String, dynamic>.from(data);

    if (rawData.containsKey('type') && rawData['type'] == 'onlineUsers') {
      handleOnlineUsersUpdate(ctx, rawData['data']);
      return;
    }

    if (rawData.containsKey('single')) {
      handleSingleUserStatusUpdate(ctx, rawData['single']);
      return;
    }

    ctx.doSetState(() {
      rawData.forEach((userId, statusData) {
        if (statusData is Map) {
          final statusMap = Map<String, dynamic>.from(statusData);
          ctx.userStatuses[userId] = {
            'status': statusMap['status'],
            'lastSeen': statusMap['lastSeen'] != null
                ? DateTime.parse(statusMap['lastSeen'].toString())
                : null,
          };
        }
      });
    });

    ctx.processChatPartnersWithStatus();
  } catch (_) {}
}

void handleOnlineUsersUpdate(ListSocketContext ctx, dynamic data) {
  if (data is List) {
    ctx.doSetState(() {
      for (final userId in data) {
        if (userId is String) {
          ctx.userStatuses[userId] = {
            'status': 'online',
            'lastSeen': DateTime.now(),
          };
        }
      }
    });
    ctx.processChatPartnersWithStatus();
  }
}

void handleSingleUserStatusUpdate(ListSocketContext ctx, dynamic data) {
  if (data == null) return;

  try {
    final statusMap = data is Map ? Map<String, dynamic>.from(data) : null;
    if (statusMap == null) return;

    final userId = statusMap['userId']?.toString();
    if (userId == null) return;

    ctx.doSetState(() {
      ctx.userStatuses[userId] = {
        'status': statusMap['status'],
        'lastSeen': statusMap['lastSeen'] != null
            ? DateTime.parse(statusMap['lastSeen'].toString())
            : null,
      };
    });

    ctx.processChatPartnersWithStatus();
  } catch (_) {}
}

void handleMessagesRead(ListSocketContext ctx, dynamic data) {
  try {
    final readBy = data['readBy']?.toString();
    if (readBy != null && readBy.isNotEmpty) {}
  } catch (_) {}
}

void handleMessageRead(ListSocketContext ctx, dynamic data) {
  try {
    final senderId = data['senderId'];
    if (senderId == null) return;
  } catch (_) {}
}

// ─── Private helpers (mirrored from chat_list_screen.dart) ────────────────────

/// Derive a short human-readable preview string from a raw socket message map.
String _extractMessagePreview(Map<dynamic, dynamic> messageData) {
  final rawText = messageData['message']?.toString() ?? '';
  final messageType = messageData['type']?.toString() ?? '';
  final mediaType = messageData['media']?['type']?.toString() ?? '';
  final hasStoryRef = messageData['storyReference'] != null &&
      messageData['storyReference']['storyId'] != null;
  final isGifUrl = rawText.startsWith('http') &&
      (rawText.contains('giphy.com') ||
          rawText.contains('.gif') ||
          rawText.contains('tenor.com') ||
          rawText.contains('gph.is') ||
          rawText.contains('media.giphy'));
  final isUrlOnly = rawText.startsWith('http') && !rawText.contains(' ');

  if (hasStoryRef) return '📖 Replied to story';
  if (messageType == 'gif' || isGifUrl) return '🎬 GIF';
  if (isUrlOnly) return '📎 Media';
  if (rawText.isNotEmpty) return rawText;

  if (messageType == 'sticker') return '😀 Sticker';
  if (messageType == 'poll') return '📊 Poll';
  if (mediaType == 'voice') return '🎤 Voice message';
  if (mediaType == 'audio') return '🎵 Audio';
  if (mediaType == 'image') return '📷 Photo';
  if (mediaType == 'video') return '🎬 Video';
  if (mediaType == 'document') return '📄 Document';
  if (mediaType == 'location') return '📍 Location';
  if (mediaType.isNotEmpty) return '📎 Attachment';
  return rawText;
}
