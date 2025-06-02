import 'package:flutter/material.dart';
import 'user_avatar.dart';
import 'chat_options_menu.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? profilePicture;
  final bool isTyping;

  const ChatAppBar({
    Key? key,
    required this.userName,
    this.profilePicture,
    required this.isTyping,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          UserAvatar(
            profilePicture: profilePicture,
            userName: userName,
            radius: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isTyping)
                  Text(
                    'typing...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Video call with $userName initiated'),
                backgroundColor: Colors.green,
              ),
            );
          },
          icon: const Icon(Icons.videocam),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Voice call with $userName initiated'),
                backgroundColor: Colors.blue,
              ),
            );
          },
          icon: const Icon(Icons.phone),
        ),
        ChatOptionsMenu(userName: userName),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
