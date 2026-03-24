import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/pages/notifications/notification_settings_screen.dart';
import 'package:bananatalk_app/pages/profile/main/profile_settings.dart';
import 'package:bananatalk_app/pages/profile/main/profile_theme.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_picture_edit.dart';
import 'package:bananatalk_app/pages/settings/account_deletion.dart';
import 'package:bananatalk_app/pages/settings/legal_screen.dart';
import 'package:bananatalk_app/pages/settings/blocked_users_screen.dart';
import 'package:bananatalk_app/pages/settings/language_settings_screen.dart';
import 'package:bananatalk_app/pages/reports/my_reports_screen.dart';
import 'package:bananatalk_app/pages/reports/admin_reports_screen.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:bananatalk_app/services/global_chat_listener.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeftDrawer extends ConsumerWidget {
  final Community user;

  const LeftDrawer({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF00BFA5).withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header with Profile
              _buildModernHeader(context, ref),

              Spacing.gapSM,

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildSectionTitle('Account'),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.person_outline,
                      title: AppLocalizations.of(context)!.profileSettings,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.editYourProfileInformation,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileSettings(),
                          ),
                        );
                        // Navigate to profile settings
                      },
                    ),

                    // VIP Membership - Hidden
                    // _buildMenuItem(
                    //   context: context,
                    //   icon: Icons.workspace_premium,
                    //   title: 'VIP Membership',
                    //   subtitle: 'Unlock premium features',
                    //   gradient: LinearGradient(
                    //     colors: [
                    //       Colors.amber.shade400,
                    //       Colors.orange.shade400,
                    //     ],
                    //   ),
                    //   onTap: () async {
                    //     Navigator.pop(context);
                    //     final prefs = await SharedPreferences.getInstance();
                    //     final userId = prefs.getString('userId');
                    //     if (userId != null && context.mounted) {
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //           builder: (context) =>
                    //               VipPlansScreen(userId: userId),
                    //         ),
                    //       );
                    //     }
                    //   },
                    // ),
                    Spacing.gapLG,
                    _buildSectionTitle('Preferences'),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.block,
                      iconColor: AppColors.error,
                      title: AppLocalizations.of(context)!.blockedUsers,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.manageBlockedUsers,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BlockedUsersScreen(),
                          ),
                        );
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.notifications_outlined,
                      title: AppLocalizations.of(context)!.notifications,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.manageNotificationSettings,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.lock_outline,
                      title: AppLocalizations.of(context)!.privacySecurity,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.controlYourPrivacy,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BlockedUsersScreen(),
                          ),
                        );
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.language_outlined,
                      title: AppLocalizations.of(context)!.language,
                      subtitle: AppLocalizations.of(context)!.changeAppLanguage,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LanguageSettingsScreen(),
                          ),
                        );
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.dark_mode_outlined,
                      title: AppLocalizations.of(context)!.appearance,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.themeAndDisplaySettings,
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

                    Spacing.gapLG,
                    _buildSectionTitle('Reports'),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.flag_outlined,
                      title: AppLocalizations.of(context)!.myReports,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.viewYourSubmittedReports,
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
                        title: AppLocalizations.of(context)!.reportsManagement,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.manageAllReportsAdmin,
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

                    Spacing.gapLG,
                    _buildSectionTitle('Support'),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.gavel_outlined,
                      title: AppLocalizations.of(context)!.legalPrivacy,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.termsPrivacySubscriptionInfo,
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
                      title: AppLocalizations.of(context)!.helpCenter,
                      subtitle: AppLocalizations.of(context)!.getHelpAndSupport,
                      onTap: () {
                        Navigator.pop(context);
                        _showHelpCenterDialog(context);
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.info_outline,
                      title: AppLocalizations.of(context)!.aboutBanaTalk,
                      subtitle: 'Version 1.9.2',
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog(context);
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.delete_forever_outlined,
                      title: AppLocalizations.of(context)!.deleteAccount,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.permanentlyDeleteYourAccount,
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToDeleteAccount(context, ref);
                      },
                    ),

                    Spacing.gapLG,

                    // Logout Button
                    _buildLogoutButton(context, ref),

                    Spacing.gapXXL,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
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

          Spacing.gapSM,

          // Profile Picture with proper null safety
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePictureEdit(user: user),
                ),
              );
              // Refresh user data after returning
              if (context.mounted) {
                ref.refresh(userProvider);
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
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
                          },
                        )
                      : const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.primary,
                          ),
                        ),
                ),
                // Edit Icon Overlay
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: AppShadows.md,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Spacing.gapLG,

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

          Spacing.gapXS,

          // User Email
          Text(
            user.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),

          Spacing.gapLG,

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
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          title.toUpperCase(),
          style: context.labelSmall.copyWith(
            letterSpacing: 1.2,
          ),
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
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderLG,
          child: Padding(
            padding: Spacing.paddingLG,
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient:
                        gradient ??
                        LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.1),
                            AppColors.primary.withValues(alpha: 0.05),
                          ],
                        ),
                    borderRadius: AppRadius.borderMD,
                  ),
                  child: Icon(
                    icon,
                    color:
                        iconColor ??
                        (gradient != null
                            ? AppColors.secondaryDark
                            : AppColors.primary),
                    size: 24,
                  ),
                ),

                Spacing.hGapLG,

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.titleSmall,
                      ),
                      Spacing.gapXXS,
                      Text(
                        subtitle,
                        style: context.caption,
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(Icons.chevron_right, color: context.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDeleteAccount(BuildContext context, WidgetRef ref) {
    final userAsync = ref.read(userProvider);
    final user = userAsync.valueOrNull;
    final isGoogleUser = user?.googleId != null && user!.googleId!.isNotEmpty;
    final isAppleUser = user?.appleId != null && user!.appleId!.isNotEmpty;
    final isOAuthUser = isGoogleUser || isAppleUser;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeleteAccountScreen(
          isOAuthUser: isOAuthUser,
          isGoogleUser: isGoogleUser,
          isAppleUser: isAppleUser,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderLG,
        gradient: LinearGradient(
          colors: [AppColors.error.withValues(alpha: 0.9), AppColors.error],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutConfirmation(context, ref),
          borderRadius: AppRadius.borderLG,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: Colors.white, size: 24),
                Spacing.hGapMD,
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
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool isLoggingOut = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderXL,
              ),
              title: Row(
                children: [
                  Container(
                    padding: Spacing.paddingSM,
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: AppRadius.borderSM,
                    ),
                    child: Icon(
                      Icons.logout,
                      color: AppColors.error,
                      size: 24,
                    ),
                  ),
                  Spacing.hGapMD,
                  const Text(
                    'Logout',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    Spacing.gapXL,
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        Spacing.hGapMD,
                        Builder(
                          builder: (ctx) => Text(
                            'Logging out...',
                            style: ctx.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: isLoggingOut
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: context.textSecondary,
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

                            // 1. Stop global chat listener FIRST
                            GlobalChatListener().stop();

                            // 2. Disconnect socket and perform backend logout
                            await ref.read(authServiceProvider).logout();

                            // 3. Reset all providers and badge counts
                            ref.read(badgeCountProvider.notifier).reset();
                            ref.read(chatPartnersProvider.notifier).reset();

                            // 4. Invalidate providers
                            ref.invalidate(userProvider);
                            ref.invalidate(authServiceProvider);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext); // Close dialog
                            }

                            if (context.mounted) {
                              Navigator.pop(context); // Close drawer

                              // 5. Navigate to login and clear all routes
                              context.go('/login');

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.white,
                                      ),
                                      Spacing.hGapMD,
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.loggedOutSuccessfully,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.borderSM,
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (error) {

                            setState(() {
                              isLoggingOut = false;
                            });

                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                      ),
                                      Spacing.hGapMD,
                                      Expanded(
                                        child: Text(
                                          'Logout failed: ${error.toString()}',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.borderSM,
                                  ),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderSM,
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
          '000104.e36e48f4990f451eabc83e84eaa435f8.0931@privaterelay.appleid.com',
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
            borderRadius: AppRadius.borderXL,
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppRadius.borderSM,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Spacing.hGapMD,
              Text(
                AppLocalizations.of(context)!.aboutBanaTalk,
                style: context.titleLarge,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BanaTalk - Language Exchange Platform',
                style: context.titleMedium,
              ),
              Spacing.gapSM,
              Text(
                'Version 1.9.2',
                style: context.bodySmall,
              ),
              Spacing.gapLG,
              Text(
                'Connect with language learners worldwide and improve your language skills through real conversations.',
                style: context.bodyMedium,
              ),
              Spacing.gapLG,
              Text(
                '(c) 2024 BanaTalk. All rights reserved.',
                style: context.caption,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showHelpCenterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderXL,
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppRadius.borderSM,
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Spacing.hGapMD,
              Text(
                AppLocalizations.of(context)!.helpCenter,
                style: context.titleLarge,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                title: const Text('Email Support'),
                subtitle: const Text('support@bananatalk.com'),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  // Could open email client
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined, color: AppColors.primary),
                title: const Text('Report a Bug'),
                subtitle: const Text('Help us improve BanaTalk'),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  // Could open bug report form
                },
              ),
              ListTile(
                leading: const Icon(Icons.question_answer_outlined, color: AppColors.primary),
                title: const Text('FAQs'),
                subtitle: const Text('Frequently asked questions'),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  // Could navigate to FAQ screen
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
