import 'package:bananatalk_app/providers/provider_models/message_model.dart';

/// One row in the chat list — a partner the current user has a conversation
/// with, plus the conversation's metadata (last message, unread count, etc.).
class ChatPartner {
  final String id;
  final String name;
  final String? username;
  final String? avatar;
  final String? lastMessage;
  final int unreadCount;
  final DateTime? lastMessageTime;
  final List<String> imageUrls;
  final String status;
  final DateTime? lastSeen;
  final bool isVip;
  final bool isPinned;
  final bool isMuted;
  final String? conversationId;

  ChatPartner({
    required this.id,
    required this.name,
    this.username,
    this.avatar,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastMessageTime,
    this.imageUrls = const [],
    this.status = 'online',
    this.lastSeen,
    this.isVip = false,
    this.isPinned = false,
    this.isMuted = false,
    this.conversationId,
  });

  /// Get display username with @ prefix
  String? get displayUsername => username != null ? '@$username' : null;

  ChatPartner copyWith({
    String? id,
    String? name,
    String? username,
    String? avatar,
    String? lastMessage,
    int? unreadCount,
    DateTime? lastMessageTime,
    List<String>? imageUrls,
    String? status,
    DateTime? lastSeen,
    bool? isVip,
    bool? isPinned,
    bool? isMuted,
    String? conversationId,
  }) {
    return ChatPartner(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isVip: isVip ?? this.isVip,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}

/// Display-friendly preview of a message, used in the chat-list row to show
/// "📷 Photo" / "🎤 Voice message" / etc. instead of the raw message body.
String getMessagePreview(Message message) {
  // Check for story reference first
  if (message.storyReference != null) {
    return '📖 Replied to story';
  }

  // Check message type before raw text
  final type = message.type.toLowerCase();
  switch (type) {
    case 'sticker':
      return '😀 Sticker';
    case 'poll':
      return '📊 Poll';
    case 'gif':
      return '🎬 GIF';
  }

  // Check for GIF/media URLs in message text
  final text = message.message ?? '';
  if (text.startsWith('http') &&
      (text.contains('giphy.com') ||
          text.contains('.gif') ||
          text.contains('tenor.com') ||
          text.contains('gph.is') ||
          text.contains('media.giphy'))) {
    return '🎬 GIF';
  }
  // Also catch any URL-only messages (no readable text)
  if (text.startsWith('http') && !text.contains(' ')) {
    return '📎 Media';
  }

  // Check for text message
  if (text.isNotEmpty) {
    return text;
  }

  // Check media type
  if (message.media != null) {
    final mediaType = message.media!.type.toLowerCase();
    switch (mediaType) {
      case 'voice':
        return '🎤 Voice message';
      case 'audio':
        return '🎵 Audio';
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎬 Video';
      case 'document':
        return '📄 Document';
      case 'location':
        return '📍 Location';
      default:
        return '📎 Attachment';
    }
  }

  return 'Message';
}
