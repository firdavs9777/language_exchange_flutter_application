import 'package:bananatalk_app/pages/authentication/screens/login.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/pages/profile/main/profile_settings.dart';
import 'package:bananatalk_app/pages/settings/account_deletion.dart';
import 'package:bananatalk_app/pages/settings/legal_screen.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/pages/reports/my_reports_screen.dart';
import 'package:bananatalk_app/pages/reports/admin_reports_screen.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeftDrawer extends ConsumerWidget {
  final Community user;

  const LeftDrawer({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF00BFA5).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header with Profile
              _buildModernHeader(context),

              const SizedBox(height: 8),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildSectionTitle('Account'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.person_outline,
                      title: 'Profile Settings',
                      subtitle: 'Edit your profile information',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfileSettings()),
                        );
                        // Navigate to profile settings
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.workspace_premium,
                      title: 'VIP Membership',
                      subtitle: 'Unlock premium features',
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade400,
                          Colors.orange.shade400,
                        ],
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('userId');
                        if (userId != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VipPlansScreen(userId: userId),
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    _buildSectionTitle('Preferences'),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage notification settings',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to notifications
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.lock_outline,
                      title: 'Privacy & Security',
                      subtitle: 'Control your privacy',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to privacy settings
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: 'Change app language',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to language settings
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.dark_mode_outlined,
                      title: 'Appearance',
                      subtitle: 'Theme and display settings',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to appearance settings
                      },
                    ),

                    const SizedBox(height: 16),
                    _buildSectionTitle('Reports'),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.flag_outlined,
                      title: 'My Reports',
                      subtitle: 'View your submitted reports',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyReportsScreen(),
                          ),
                        );
                      },
                    ),

                    // Admin Reports Management (only for admins)
                    if (_isAdmin(user))
                      _buildMenuItem(
                        context: context,
                        icon: Icons.admin_panel_settings,
                        title: 'Reports Management',
                        subtitle: 'Manage all reports (Admin)',
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.purple.shade600,
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminReportsScreen(),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 16),
                    _buildSectionTitle('Support'),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.gavel_outlined,
                      title: 'Legal & Privacy',
                      subtitle: 'Terms, Privacy & Subscription info',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LegalScreen(),
                          ),
                        );
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      subtitle: 'Get help and support',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to help center
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.info_outline,
                      title: 'About BanaTalk',
                      subtitle: 'Version 1.0.0',
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog(context);
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.delete_forever_outlined,
                      title: 'Delete Account',
                      subtitle: 'Permanently delete your account',
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade400,
                          Colors.red.shade600,
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToDeleteAccount(context, ref);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Logout Button
                    _buildLogoutButton(context, ref),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00BFA5),
            const Color(0xFF00BFA5).withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Profile Picture with proper null safety
          GestureDetector(
            onTap: () {
              // Navigate to profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageGallery(
                    imageUrls: user.imageUrls,
                    initialIndex: 0,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: user.imageUrls.isNotEmpty
                  ? CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(
                        ImageUtils.normalizeImageUrl(user.imageUrls[0]),
                      ),
                      onBackgroundImageError: (exception, stackTrace) {
                        print('Failed to load profile image: $exception');
                      },
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: const Color(0xFF00BFA5),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // User Name
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // User Email
          Text(
            user.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderStat(
                  Icons.people,
                  '${user.followers.length}',
                  'Followers',
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  width: 1,
                  height: 30,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildHeaderStat(
                  Icons.person_add,
                  '${user.followings.length}',
                  'Following',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Gradient? gradient,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: gradient ??
                        LinearGradient(
                          colors: [
                            const Color(0xFF00BFA5).withOpacity(0.1),
                            const Color(0xFF00BFA5).withOpacity(0.05),
                          ],
                        ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: gradient != null
                        ? Colors.amber.shade700
                        : const Color(0xFF00BFA5),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
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

                // Arrow Icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDeleteAccount(BuildContext context, WidgetRef ref) {
    print(user.appleId.toString());
    final isOAuthUser = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeleteAccountScreen(isOAuthUser: isOAuthUser),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.red.shade400,
            Colors.red.shade500,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutConfirmation(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing by tapping outside during logout
      builder: (BuildContext dialogContext) {
        bool isLoggingOut = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.logout,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you sure you want to logout from BanaTalk?',
                    style: TextStyle(fontSize: 15),
                  ),
                  if (isLoggingOut) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF00BFA5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Logging out...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: isLoggingOut
                  ? [] // Hide buttons during logout
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isLoggingOut = true;
                          });

                          try {
                            // Perform logout
                            await ref.read(authServiceProvider).logout();

                            print('✅ Logout successful');

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext); // Close dialog
                            }

                            if (context.mounted) {
                              Navigator.pop(context); // Close drawer

                              // Navigate to login and clear all routes
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const Login(),
                                ),
                                (route) => false,
                              );

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text('Logged out successfully'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (error) {
                            print('❌ Logout error: $error');

                            setState(() {
                              isLoggingOut = false;
                            });

                            if (dialogContext.mounted) {
                              // Show error message
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Logout failed: ${error.toString()}',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  duration: const Duration(seconds: 4),
                                  action: SnackBarAction(
                                    label: 'Retry',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      // Retry logout
                                    },
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  /// Check if user is admin
  /// TODO: Update this to check actual admin role from backend
  /// For now, checking by email pattern or you can add a role field to User/Community model
  bool _isAdmin(Community user) {
    // Option 1: Check by email pattern (update with your admin emails)
    final adminEmails = [
      'testdemo@gmail.com',
      'fmutalipov7@gmail.com',
      'fdwvycq6wh@privaterelay.appleid.com'
          '000104.e36e48f4990f451eabc83e84eaa435f8.0931@privaterelay.appleid.com'
    ];
    if (adminEmails.contains(user.email.toLowerCase())) {
      return true;
    }

    // Option 2: Check if user has a role field (if backend provides it)
    // You can add a role field to Community model and check here:
    // return user.role == 'admin' || user.role == 'moderator';

    // Option 3: Check by user ID (for testing)
    // final adminIds = ['admin_user_id_here'];
    // if (adminIds.contains(user.id)) {
    //   return true;
    // }

    return false;
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00BFA5),
                      Color(0xFF00897B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About BanaTalk',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BanaTalk - Language Exchange Platform',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Connect with language learners worldwide and improve your language skills through real conversations.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '© 2024 BanaTalk. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
