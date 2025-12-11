import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';
import 'package:bananatalk_app/widgets/media_message_widget.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'user_avatar.dart';

class ChatMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String otherUserName;
  final String? otherUserPicture;
  final Function(Message)? onDelete;
  final Function(Message)? onEdit;
  final Function(Message)? onReply;
  final Message? replyToMessage; // The message this is replying to

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.otherUserName,
    this.otherUserPicture,
    this.onDelete,
    this.onEdit,
    this.onReply,
    this.replyToMessage,
  }) : super(key: key);

  // KakaoTalk-inspired colors
  static const Color myMessageColor = Color(0xFFFEE500); // Kakao yellow
  static const Color otherMessageColor = Color(0xFFFFFFFF); // White
  static const Color myTextColor = Color(0xFF3C1E1E); // Dark brown for contrast
  static const Color otherTextColor = Color(0xFF191919); // Almost black
  static const Color timestampColor = Color(0xFF999999); // Gray
  static const Color backgroundColor = Color(0xFFB2C7D9); // Light blue-gray
  static const Color replyBorderColor =
      Color(0xFF999999); // Gray for reply border

  @override
  Widget build(BuildContext context) {
    final hasMedia = message.media != null;
    final hasText = message.message != null && message.message!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other user (left side)
          if (!isMe) ...[
            UserAvatar(
              profilePicture: otherUserPicture,
              userName: otherUserName,
              radius: 20,
            ),
            const SizedBox(width: 8),
          ],

          // Timestamp and read status (left of my messages)
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(right: 6, bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!message.read)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    _formatMessageTime(DateTime.parse(message.createdAt)),
                    style: const TextStyle(
                      color: timestampColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              child: hasMedia
                  ? _buildMediaMessage(context, hasText)
                  : _buildTextMessage(context, hasText),
            ),
          ),

          // Timestamp (right of other user's messages)
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: Text(
                _formatMessageTime(DateTime.parse(message.createdAt)),
                style: const TextStyle(
                  color: timestampColor,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextMessage(BuildContext context, bool hasText) {
    if (_isSticker(message.message ?? '')) {
      // Stickers/emojis without bubble
      return GestureDetector(
        onLongPress: () => _showMessageActions(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            message.message!,
            style: const TextStyle(fontSize: 48),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () => _showMessageActions(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply preview if this message is a reply
          if (replyToMessage != null) _buildReplyPreview(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? myMessageColor : otherMessageColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasText)
                  Text(
                    message.message!,
                    style: TextStyle(
                      color: isMe ? myTextColor : otherTextColor,
                      fontSize: 15,
                      height: 1.4,
                      letterSpacing: -0.2,
                    ),
                  ),
                if (message.isEdited)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'edited',
                      style: TextStyle(
                        color: (isMe ? myTextColor : otherTextColor)
                            .withOpacity(0.5),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isMe ? myMessageColor : Colors.blue,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyToMessage!.sender == message.sender ? 'You' : otherUserName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isMe ? myTextColor : Colors.blue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyToMessage!.message ?? 'Media',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaMessage(BuildContext context, bool hasText) {
    return GestureDetector(
      onLongPress: () => _showMessageActions(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview if this message is a reply
          if (replyToMessage != null) _buildReplyPreview(),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                MediaMessageWidget(
                  media: message.media!,
                  isSentByMe: isMe,
                  onTap: () {
                    if (message.media!.type == 'image') {
                      // TODO: Open image in full screen viewer
                    }
                  },
                ),
                // Timestamp overlay on media
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatMessageTime(DateTime.parse(message.createdAt)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Text caption below media
          if (hasText)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? myMessageColor : otherMessageColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.message!,
                style: TextStyle(
                  color: isMe ? myTextColor : otherTextColor,
                  fontSize: 15,
                  height: 1.4,
                  letterSpacing: -0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    HapticFeedback.mediumImpact(); // Vibration feedback

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Message info header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMe ? 'You' : otherUserName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFullDateTime(DateTime.parse(message.createdAt)),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (message.read && isMe) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.done_all,
                              size: 16,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Read',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Action buttons
                if (message.message != null && message.message!.isNotEmpty)
                  _buildActionTile(
                    context,
                    icon: Icons.copy,
                    label: 'Copy',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.message!));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message copied'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Colors.black87,
                        ),
                      );
                    },
                  ),

                if (isMe && message.message != null)
                  _buildActionTile(
                    context,
                    icon: Icons.edit,
                    label: 'Edit',
                    onTap: () {
                      Navigator.pop(context);
                      if (onEdit != null) {
                        onEdit!(message);
                      }
                    },
                  ),

                _buildActionTile(
                  context,
                  icon: Icons.reply,
                  label: 'Reply',
                  onTap: () {
                    Navigator.pop(context);
                    if (onReply != null) {
                      onReply!(message);
                    }
                  },
                ),

                _buildActionTile(
                  context,
                  icon: Icons.forward,
                  label: 'Forward',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement forward functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Forward feature coming soon'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                if (!isMe)
                  _buildActionTile(
                    context,
                    icon: Icons.flag_outlined,
                    label: 'Report',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => ReportDialog(
                          type: 'message',
                          reportedId: message.id,
                          reportedUserId: message.sender.id,
                        ),
                      );
                    },
                  ),

                if (isMe)
                  _buildActionTile(
                    context,
                    icon: Icons.delete,
                    label: 'Delete',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context);
                    },
                  ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (onDelete != null) {
                  onDelete!(message);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  bool _isSticker(String text) {
    return text.length <= 2 &&
        RegExp(
          r'[\u{1f300}-\u{1f5ff}\u{1f600}-\u{1f64f}\u{1f680}-\u{1f6ff}\u{2600}-\u{26ff}\u{2700}-\u{27bf}\u{1f900}-\u{1f9ff}\u{1fa00}-\u{1fa6f}]',
          unicode: true,
        ).hasMatch(text);
  }

  String _formatMessageTime(DateTime dateTime) {
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inDays > 6) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else {
      // Always show time in HH:mm format for messages within today
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatFullDateTime(DateTime dateTime) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final weekday = weekdays[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return '$weekday, $month ${dateTime.day}, ${dateTime.year} at $time';
  }
}
