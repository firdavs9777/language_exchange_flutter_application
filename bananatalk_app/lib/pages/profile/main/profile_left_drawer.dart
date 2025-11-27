import 'package:bananatalk_app/pages/home/Home.dart';
import 'package:bananatalk_app/pages/profile/main/profile_followers.dart';
import 'package:bananatalk_app/pages/profile/main/profile_followings.dart';
import 'package:bananatalk_app/pages/profile/profile_main.dart';
import 'package:bananatalk_app/pages/profile/main/profile_moments.dart';
import 'package:bananatalk_app/pages/profile/main/profile_notifications.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_privacy.dart';
import 'package:bananatalk_app/pages/profile/main/profile_settings.dart';
import 'package:bananatalk_app/pages/profile/main/profile_theme.dart';
import 'package:bananatalk_app/pages/profile/main/profile_edit_main.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/pages/vip/vip_status_screen.dart';

class LeftDrawer extends ConsumerWidget {
  final Community user;
  const LeftDrawer({Key? key, required this.user}) : super(key: key);

  int _calculateAge(String birthYear) {
    try {
      final currentYear = DateTime.now().year;
      final year = int.parse(birthYear);
      return currentYear - year;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calculatedAge = _calculateAge(user.birth_year);
    final age = PrivacyUtils.getAge(user, calculatedAge);

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00BFA5).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Modern Header with gradient (clickable to edit)
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final userAsyncValue =
                    ref.read(authServiceProvider).getLoggedInUser();
                final currentUser = await userAsyncValue;
                if (context.mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileEdit(
                        nativeLanguage: currentUser.native_language,
                        languageToLearn: currentUser.language_to_learn,
                        userName: currentUser.name,
                        mbti: currentUser.mbti,
                        bloodType: currentUser.bloodType,
                        location: currentUser.location,
                        gender: currentUser.gender,
                        bio: currentUser.bio,
                      ),
                    ),
                  ).then((_) {
                    if (context.mounted) {
                      ref.refresh(userProvider);
                    }
                  });
                }
              },
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF00BFA5),
                      const Color(0xFF00BFA5).withOpacity(0.8),
                      Colors.blue.shade300,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 50,
                      left: 20,
                      right: 20,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.white,
                              backgroundImage: user.imageUrls.isNotEmpty
                                  ? NetworkImage(
                                      ImageUtils.normalizeImageUrl(user.imageUrls[0]),
                                    )
                                  : null,
                              child: user.imageUrls.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 45,
                                      color: Color(0xFF00BFA5),
                                    )
                                  : null,
                              onBackgroundImageError: (exception, stackTrace) {
                                // Image failed to load
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (age != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '$age years old',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to Edit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
              ),
<<<<<<< HEAD
            ),
            const SizedBox(height: 20),
            // Quick Stats Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context: context,
                    icon: Icons.person_add,
                    value: user.followings.length,
                    label: 'Following',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileFollowings(id: user.id),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  _buildStatItem(
                    context: context,
                    icon: Icons.supervised_user_circle,
                    value: user.followers.length,
                    label: 'Followers',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileFollowers(id: user.id),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final momentsFuture = ref
                          .watch(momentsServiceProvider)
                          .getMomentsUser(id: user.id);
                      return FutureBuilder(
                        future: momentsFuture,
                        builder: (context, snapshot) {
                          final count = snapshot.hasData ? snapshot.data!.length : 0;
                          return _buildStatItem(
                            context: context,
                            icon: Icons.public_outlined,
                            value: count,
                            label: 'Moments',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileMoments(id: user.id),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Menu Items
            _buildModernMenuItem(
              context: context,
              icon: Icons.public_outlined,
              title: 'My Moments',
              subtitle: 'View all your moments',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileMoments(id: user.id),
                  ),
                );
              },
            ),
            _buildModernMenuItem(
              context: context,
              icon: Icons.person_add,
              title: 'Following',
              subtitle: '${user.followings.length} people',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileFollowings(id: user.id),
                  ),
                );
              },
            ),
            _buildModernMenuItem(
              context: context,
              icon: Icons.supervised_user_circle,
              title: 'Followers',
              subtitle: '${user.followers.length} people',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileFollowers(id: user.id),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildModernMenuItem(
              context: context,
              icon: Icons.edit,
              title: 'Edit Profile',
              subtitle: 'Update your information',
              color: const Color(0xFF00BFA5),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileEdit(
                      nativeLanguage: user.native_language,
                      languageToLearn: user.language_to_learn,
                      userName: user.name,
                      mbti: user.mbti,
                      bloodType: user.bloodType,
                      location: user.location,
                      gender: user.gender,
                      bio: user.bio,
                    ),
                  ),
                ).then((_) {
                  if (context.mounted) {
                    ref.refresh(userProvider);
                  }
                });
              },
            ),
            _buildModernMenuItem(
              context: context,
              icon: Icons.account_circle,
              title: 'Account Settings',
              subtitle: 'Manage your account',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettings(),
                  ),
                );
              },
            ),
            _buildModernMenuItem(
              context: context,
              icon: Icons.privacy_tip,
              title: 'Privacy',
              subtitle: 'Control your privacy',
              color: Colors.indigo,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePrivacy(),
                  ),
                );
              },
            ),
            _buildModernMenuItem(
              context: context,
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Manage notifications',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileNotifications(),
                  ),
                );
              },
            ),
            _buildModernMenuItem(
              context: context,
              icon: Icons.dark_mode,
              title: 'Theme',
              subtitle: 'Dark mode settings',
              color: Colors.grey[700]!,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileTheme(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // VIP Membership menu item
            _buildModernMenuItem(
              context: context,
              icon: Icons.workspace_premium,
              title: 'VIP Membership',
              subtitle: 'Upgrade to premium',
              color: Colors.amber,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VipPlansScreen(userId: user.id),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Login(),
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red[700]),
                      const SizedBox(width: 16),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required int value,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BFA5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
