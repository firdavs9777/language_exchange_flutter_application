import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/pages/notifications/notification_settings_screen.dart';
import 'package:bananatalk_app/pages/profile/settings.dart';
import 'package:bananatalk_app/pages/profile/theme.dart';
import 'package:bananatalk_app/pages/profile/edit/picture_edit.dart';
import 'package:bananatalk_app/pages/profile/edit/privacy_edit.dart';
import 'package:bananatalk_app/pages/settings/account_deletion.dart';
import 'package:bananatalk_app/pages/settings/legal_screen.dart';
import 'package:bananatalk_app/pages/settings/blocked_users_screen.dart';
import 'package:bananatalk_app/pages/settings/language_settings_screen.dart';
import 'package:bananatalk_app/pages/settings/data_storage_screen.dart';
import 'package:bananatalk_app/pages/reports/my_reports_screen.dart';
import 'package:bananatalk_app/pages/reports/admin_reports_screen.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:bananatalk_app/services/global_chat_listener.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/profile/widgets/profile_snackbar.dart';

import 'about_dialog.dart';
import 'drawer_section.dart';
import 'logout_dialog.dart';

class LeftDrawer extends ConsumerWidget {
  final Community user;

  const LeftDrawer({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appVersion = ref.watch(runningAppVersionProvider).maybeWhen(
      data: (v) => v,
      orElse: () => '',
    );

    return Drawer(
      backgroundColor: context.scaffoldBackground,
      child: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(context, ref),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Account
                  DrawerSectionTitle(title: l10n.profileSettings),
                  DrawerSectionContainer(
                    children: [
                      DrawerMenuItem(
                        icon: Icons.person_rounded,
                        iconColor: AppColors.primary,
                        title: l10n.profileSettings,
                        subtitle: l10n.editYourProfileInformation,
                        isFirst: true,
                        isLast: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            AppPageRoute(
                              builder: (context) => ProfileSettings(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Preferences
                  DrawerSectionTitle(title: l10n.drawerPreferences),
                  DrawerSectionContainer(
                    children: [
                      DrawerMenuItem(
                        icon: Icons.notifications_rounded,
                        iconColor: const Color(0xFF2196F3),
                        title: l10n.notifications,
                        subtitle: l10n.manageNotificationSettings,
                        isFirst: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            AppPageRoute(
                              builder: (context) =>
                                  const NotificationSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const DrawerDivider(),
                      DrawerMenuItem(
                        icon: Icons.lock_rounded,
                        iconColor: const Color(0xFF7C4DFF),
                        title: l10n.privacySecurity,
                        subtitle: l10n.controlYourPrivacy,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            AppPageRoute(
                              builder: (context) => const ProfilePrivacy(),
                            ),
                          );
                        },
                      ),
                      const DrawerDivider(),
                      DrawerMenuItem(
                        icon: Icons.block_rounded,
                        iconColor: AppColors.error,
                        title: l10n.blockedUsers,
                        subtitle: l10n.manageBlockedUsers,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            AppPageRoute(
                              builder: (context) => const BlockedUsersScreen(),
                            ),
                          );
                        },
                      ),
                      const DrawerDivider(),
                      DrawerMenuItem(
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF00BCD4),
                        title: l10n.language,
                        subtitle: l10n.changeAppLanguage,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            AppPageRoute(
                              builder: (context) =>
                                  const LanguageSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const DrawerDivider(),
                      DrawerMenuItem(
                        icon: Icons.dark_mode_rounded,
                        iconColor: const Color(0xFF673AB7),
                        title: l10n.appearance,
                        subtitle: l10n.themeAndDisplaySettings,
                        isLast: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            AppPageRoute(
                              builder: (context) => const ProfileTheme(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Storage
                  DrawerSectionTitle(title: l10n.drawerStorage),
                  DrawerSectionContainer(
                    children: [
                      DrawerMenuItem(
                        icon: Icons.storage_rounded,
                        iconColor: const Color(0xFF607D8B),
                        title: l10n.dataAndStorage,
                        subtitle: l10n.manageStorageAndDownloads,
                        isFirst: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            AppPageRoute(
                              builder: (context) => const DataStorageScreen(),
                            ),
                          );
                        },
                      ),
                      const DrawerDivider(),
                      DrawerMenuItem(
                        icon: Icons.cleaning_services_rounded,
                        iconColor: const Color(0xFFFF9800),
                        title: l10n.clearCache,
                        subtitle: l10n.clearCacheSubtitle,
                        isLast: true,
                        onTap: () => _showClearCacheDialog(context, ref),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Reports
                  DrawerSectionTitle(title: l10n.drawerReports),
                  DrawerSectionContainer(
                    children: [
                      DrawerMenuItem(
                        icon: Icons.flag_rounded,
                        iconColor: const Color(0xFFF44336),
                        title: l10n.myReports,
                        subtitle: l10n.viewYourSubmittedReports,
                        isFirst: true,
                        isLast: !_isAdmin(user),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            AppPageRoute(
                              builder: (context) => const MyReportsScreen(),
                            ),
                          );
                        },
                      ),
                      if (_isAdmin(user)) ...[
                        const DrawerDivider(),
                        DrawerMenuItem(
                          icon: Icons.admin_panel_settings_rounded,
                          iconColor: const Color(0xFF9C27B0),
                          title: l10n.reportsManagement,
                          subtitle: l10n.manageAllReportsAdmin,
                          showAdminBadge: true,
                          isLast: true,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              AppPageRoute(
                                builder: (context) =>
                                    const AdminReportsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Support
                  DrawerSectionTitle(title: l10n.drawerSupport),
                  DrawerSectionContainer(
                    children: [
                      DrawerMenuItem(
                        icon: Icons.help_rounded,
                        iconColor: const Color(0xFF4CAF50),
                        title: l10n.helpCenter,
                        subtitle: l10n.getHelpAndSupport,
                        isFirst: true,
                        onTap: () {
                          Navigator.pop(context);
                          _showHelpCenterDialog(context);
                        },
                      ),
                      const DrawerDivider(),
                      DrawerMenuItem(
                        icon: Icons.gavel_rounded,
                        iconColor: const Color(0xFF795548),
                        title: l10n.legalPrivacy,
                        subtitle: l10n.termsPrivacySubscriptionInfo,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            AppPageRoute(
                              builder: (context) => const LegalScreen(),
                            ),
                          );
                        },
                      ),
                      const DrawerDivider(),
                      DrawerMenuItem(
                        icon: Icons.info_rounded,
                        iconColor: AppColors.info,
                        title: l10n.aboutBananatalk,
                        subtitle: appVersion.isEmpty
                            ? l10n.aboutBananatalk
                            : 'Version $appVersion',
                        isLast: true,
                        onTap: () {
                          Navigator.pop(context);
                          showProfileAboutDialog(context, appVersion);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Danger zone
                  DrawerSectionTitle(
                    title: l10n.drawerAccount,
                    danger: true,
                  ),
                  DrawerSectionContainer(
                    children: [
                      DrawerMenuItem(
                        icon: Icons.delete_forever_rounded,
                        iconColor: AppColors.error,
                        title: l10n.deleteAccount,
                        subtitle: l10n.permanentlyDeleteYourAccount,
                        isFirst: true,
                        isLast: true,
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToDeleteAccount(context, ref);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Logout
                  _buildLogoutButton(context, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== HEADER ==========
  Widget _buildModernHeader(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0.1),
                ]
              : [AppColors.primary, const Color(0xFF00897B)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        children: [
          // Close button
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.white.withValues(alpha: 0.2),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Avatar
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                AppPageRoute(
                  builder: (context) => ProfilePictureEdit(user: user),
                ),
              );
              if (context.mounted) ref.invalidate(userProvider);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: user.imageUrls.isNotEmpty
                          ? CachedImageWidget(
                              imageUrl: ImageUtils.normalizeImageUrl(
                                user.imageUrls[0],
                              ),
                              fit: BoxFit.cover,
                              errorWidget: Container(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 42,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.person_rounded,
                                size: 42,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Email
          Text(
            user.email,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Stats pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderStat('${user.followers.length}', 'Followers'),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildHeaderStat('${user.followings.length}', 'Following'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ========== LOGOUT BUTTON ==========
  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleLogout(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.error,
                  AppColors.error.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)!.logout,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== LOGOUT HANDLER ==========
  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showLogoutConfirmDialog(context);
    if (confirmed != true || !context.mounted) return;

    final l10n = AppLocalizations.of(context)!;

    // Show loading overlay
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (loadingCtx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: loadingCtx.surfaceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.loggingOut,
                  style: loadingCtx.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      GlobalChatListener().stop();
      await ref.read(authServiceProvider).logout();
      ref.read(badgeCountProvider.notifier).reset();
      ref.read(chatPartnersProvider.notifier).reset();
      ref.invalidate(userProvider);
      ref.invalidate(authServiceProvider);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close loading
        Navigator.pop(context); // close drawer
        context.go('/login');
        showProfileSnackBar(
          context,
          message: l10n.loggedOutSuccessfully,
          type: ProfileSnackBarType.success,
        );
      }
    } catch (error) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close loading
        showProfileSnackBar(
          context,
          message: '${l10n.logoutFailedPrefix}: $error',
          type: ProfileSnackBarType.error,
        );
      }
    }
  }

  // ========== CLEAR CACHE ==========
  void _showClearCacheDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDrawerConfirmDialog(
      context: context,
      icon: Icons.cleaning_services_rounded,
      iconColor: const Color(0xFFFF9800),
      title: l10n.clearCache,
      content: '${l10n.clearCacheDescription}\n\n${l10n.clearCacheHint}',
      confirmLabel: l10n.clearCache,
      cancelLabel: l10n.cancel,
    );

    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (loadingCtx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: loadingCtx.surfaceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF9800),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.clearingCache,
                  style: loadingCtx.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await AppImageCacheManager.clearCache();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showProfileSnackBar(
          context,
          message: l10n.cacheCleared,
          type: ProfileSnackBarType.success,
        );
      }
    } catch (error) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showProfileSnackBar(
          context,
          message: '${l10n.clearCacheFailed}: $error',
          type: ProfileSnackBarType.error,
        );
      }
    }
  }

  // ========== HELP CENTER DIALOG ==========
  void _showHelpCenterDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: ctx.surfaceColor,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.help_rounded,
                        color: Color(0xFF4CAF50),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.helpCenter,
                        style: ctx.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHelpTile(
                  ctx: ctx,
                  icon: Icons.email_rounded,
                  color: const Color(0xFF2196F3),
                  title: l10n.helpEmailSupport,
                  subtitle: l10n.helpEmailSupportSubtitle,
                  onTap: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 8),
                _buildHelpTile(
                  ctx: ctx,
                  icon: Icons.bug_report_rounded,
                  color: const Color(0xFFFF9800),
                  title: l10n.helpReportBug,
                  subtitle: l10n.helpReportBugSubtitle,
                  onTap: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 8),
                _buildHelpTile(
                  ctx: ctx,
                  icon: Icons.question_answer_rounded,
                  color: const Color(0xFF7C4DFF),
                  title: l10n.helpFaqs,
                  subtitle: l10n.helpFaqsSubtitle,
                  onTap: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: ctx.containerColor,
                    ),
                    child: Text(
                      l10n.close,
                      style: TextStyle(
                        color: ctx.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpTile({
    required BuildContext ctx,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ctx.containerColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ctx.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: ctx.captionSmall.copyWith(color: ctx.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ctx.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== HELPERS ==========
  void _navigateToDeleteAccount(BuildContext context, WidgetRef ref) {
    final userAsync = ref.read(userProvider);
    final user = userAsync.valueOrNull;
    final isGoogleUser = user?.googleId != null && user!.googleId!.isNotEmpty;
    final isAppleUser = user?.appleId != null && user!.appleId!.isNotEmpty;
    final isOAuthUser = isGoogleUser || isAppleUser;

    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => DeleteAccountScreen(
          isOAuthUser: isOAuthUser,
          isGoogleUser: isGoogleUser,
          isAppleUser: isAppleUser,
        ),
      ),
    );
  }

  bool _isAdmin(Community user) {
    final adminEmails = [
      'testdemo@gmail.com',
      'fmutalipov7@gmail.com',
      'fdwvycq6wh@privaterelay.appleid.com'
          '000104.e36e48f4990f451eabc83e84eaa435f8.0931@privaterelay.appleid.com',
    ];
    return adminEmails.contains(user.email.toLowerCase());
  }
}
