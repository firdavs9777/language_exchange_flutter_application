import 'package:flutter/material.dart';

class ChatOptionsMenu extends StatelessWidget {
  final String userName;

  const ChatOptionsMenu({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuOption(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view_contact',
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('View contact'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'media',
          child: ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Media, links, and docs'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'search',
          child: ListTile(
            leading: Icon(Icons.search),
            title: Text('Search'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'mute',
          child: ListTile(
            leading: Icon(Icons.notifications_off),
            title: Text('Mute notifications'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'wallpaper',
          child: ListTile(
            leading: Icon(Icons.wallpaper),
            title: Text('Wallpaper'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'block',
          child: ListTile(
            leading: Icon(Icons.block, color: Colors.red),
            title: Text('Block', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  void _handleMenuOption(BuildContext context, String value) {
    final messages = {
      'view_contact': 'View contact info',
      'media': 'Media, links and docs',
      'search': 'Search in conversation',
      'mute': 'Mute notifications',
      'wallpaper': 'Change wallpaper',
      'block': 'Block $userName',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messages[value] ?? 'Unknown action'),
        backgroundColor: value == 'block' ? Colors.red : null,
      ),
    );
  }
}
