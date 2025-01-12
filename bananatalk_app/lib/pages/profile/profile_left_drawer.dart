import 'package:bananatalk_app/pages/home/Home.dart';
import 'package:bananatalk_app/pages/profile/profile_followers.dart';
import 'package:bananatalk_app/pages/profile/profile_followings.dart';
import 'package:bananatalk_app/pages/profile/profile_main.dart';
import 'package:bananatalk_app/pages/profile/profile_moments.dart';
import 'package:bananatalk_app/pages/profile/profile_notifications.dart';
import 'package:bananatalk_app/pages/profile/profile_privacy.dart';
import 'package:bananatalk_app/pages/profile/profile_settings.dart';
import 'package:bananatalk_app/pages/profile/profile_theme.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // import your pages

class LeftDrawer extends ConsumerWidget {
  final Community user;
  const LeftDrawer({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero, // Optional: remove default padding
        children: [
          // User Info Header with a better profile picture section
          UserAccountsDrawerHeader(
            accountName: Text(
              user.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              user.birth_year,
              style: TextStyle(color: Colors.black87),
            ),
            currentAccountPicture: CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(user.imageUrls.isNotEmpty
                  ? user.imageUrls[0]
                  : 'https://example.com/default-avatar.jpg'),
            ),
            // decoration: BoxDecoration(
            //   color: Colors.blueAccent,
            //   image: DecorationImage(
            //     image: NetworkImage(user.imageUrls.isNotEmpty
            //         ? user.imageUrls[0]
            //         : 'https://example.com/default-avatar.jpg'),
            //     fit: BoxFit.cover,
            //     colorFilter: ColorFilter.mode(
            //         Colors.black.withOpacity(0.3), BlendMode.darken),
            //   ),
            // ),
          ),
          // Use MaterialPageRoute to navigate to different pages
          buildMenuItem(context, Icons.person_add, 'Followings', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProfileFollowings(id: user.id)),
            );
          }),
          buildMenuItem(context, Icons.supervised_user_circle, 'Followers', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProfileFollowers(id: user.id)),
            );
          }),
          buildMenuItem(context, Icons.public_outlined, 'Moments', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileMoments(id: user.id),
              ),
            );
            ref.refresh(momentsServiceProvider).getMomentsUser(id: user.id);
          }),
          Divider(), // Add this divider
          buildMenuItem(context, Icons.account_circle, 'Account', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileSettings()),
            );
          }),
          buildMenuItem(context, Icons.privacy_tip, 'Privacy', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePrivacy()),
            );
          }),
          buildMenuItem(context, Icons.notifications, 'Notifications', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ProfileNotifications()),
            );
          }),
          buildMenuItem(context, Icons.dark_mode, 'Dark Mode', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileTheme()),
            );
          }),
          buildMenuItem(context, Icons.logout, 'Logout', () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }),
        ],
      ),
    );
  }

  // Simplify card item creation with common design for menu items
  Widget buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    Function onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 3, // Slightly increased shadow for a more prominent effect
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // More rounded corners
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Icon(Icons.arrow_forward, color: Colors.blueAccent),
        onTap: () => onTap(),
      ),
    );
  }
}
