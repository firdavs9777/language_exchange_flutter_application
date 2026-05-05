import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/pages/profile/edit_main/edit_main.dart'
    show ProfileEdit;
import 'package:bananatalk_app/pages/profile/drawer/profile_drawer.dart';
import 'package:bananatalk_app/pages/profile/highlights.dart';
import 'package:bananatalk_app/pages/profile/edit/picture_edit.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:bananatalk_app/services/global_chat_listener.dart';
import 'package:bananatalk_app/providers/provider_root/profile_visitor_provider.dart';
import 'package:bananatalk_app/widgets/profile/profile_main_skeleton.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
// Extracted section widgets
import 'package:bananatalk_app/pages/profile/profile_main/sections/profile_tab_bar.dart';
import 'package:bananatalk_app/pages/profile/profile_main/sections/profile_action_buttons.dart';
import 'package:bananatalk_app/pages/profile/profile_main/sections/profile_stats_row.dart';
import 'package:bananatalk_app/pages/profile/profile_main/sections/profile_highlights_tab.dart';
import 'package:bananatalk_app/pages/profile/profile_main/sections/profile_about_tab.dart';
import 'package:bananatalk_app/pages/profile/profile_main/sections/profile_moments_tab.dart';

class ProfileMain extends ConsumerStatefulWidget {
  const ProfileMain({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileMain> createState() => _ProfileMainState();
}

class _ProfileMainState extends ConsumerState<ProfileMain> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(userProvider));
  }

  int? _calculateAge(String birthYear) {
    if (birthYear.isEmpty) return null;
    final year = int.tryParse(birthYear);
    if (year == null) return null;
    return DateTime.now().year - year;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      endDrawer: Builder(
        builder: (context) {
          return userAsync.when(
            data: (user) => LeftDrawer(user: user),
            loading: () =>
                const Drawer(child: Center(child: CircularProgressIndicator())),
            error: (error, stack) {
              final l10n = AppLocalizations.of(context)!;
              return Drawer(
                child: Center(child: Text('${l10n.error}: $error')),
              );
            },
          );
        },
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          HapticUtils.onRefresh();
          final currentUser = ref.read(userProvider).valueOrNull;
          ref.invalidate(userProvider);
          ref.invalidate(myVisitorStatsProvider);
          if (currentUser != null) {
            ref.invalidate(userMomentsProvider(currentUser.id));
          }
          await ref.read(userProvider.future);
        },
        child: userAsync.when(
          skipLoadingOnRefresh: true,
          data: (user) => CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildSliverAppBar(context, user),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    ProfileTabBar(
                      user: user,
                      calculatedAge: _calculateAge(user.birth_year),
                      onAvatarTap: () async {
                        await Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) =>
                                ProfilePictureEdit(user: user),
                          ),
                        );
                        if (mounted) ref.invalidate(userProvider);
                      },
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(
                          begin: 0.02,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 16),
                    ProfileActionButtons(
                      user: user,
                      onEditTap: () async {
                        await Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) => ProfileEdit(
                              nativeLanguage: user.native_language,
                              languageToLearn: user.language_to_learn,
                              userName: user.name,
                              mbti: user.mbti,
                              bloodType: user.bloodType,
                              location: user.location,
                              gender: user.gender,
                              bio: user.bio,
                              topics: user.topics,
                              languageLevel: user.languageLevel,
                            ),
                          ),
                        );
                        if (mounted) {
                          ref.invalidate(userProvider);
                          await ref.read(userProvider.future);
                        }
                      },
                    ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
                    const SizedBox(height: 16),
                    ProfileStatsRow(user: user)
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 150.ms),
                    const SizedBox(height: 20),
                    ProfileHighlightsTab(user: user)
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 200.ms),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SmallBannerAdWidget(),
                    ),
                    const SizedBox(height: 20),
                    ProfileHighlights(
                      userId: user.id,
                      isOwnProfile: true,
                      user: user,
                    ).animate().fadeIn(duration: 350.ms, delay: 275.ms),
                    const SizedBox(height: 20),
                    ProfileAboutTab(user: user)
                        .animate()
                        .fadeIn(duration: 350.ms, delay: 300.ms),
                    const SizedBox(height: 16),
                    ProfileMomentsTab(user: user),
                    const SizedBox(height: 24),
                    _buildLogoutButton(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const ProfileMainSkeleton(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  // ========== APP BAR ==========
  Widget _buildSliverAppBar(BuildContext context, Community user) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: context.surfaceColor,
      foregroundColor: context.textPrimary,
      automaticallyImplyLeading: false,
      title: Text(
        user.name.isNotEmpty ? user.name : 'Profile',
        style: context.titleLarge.copyWith(fontWeight: FontWeight.w800),
      ),
      actions: [
        Builder(
          builder: (ctx) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.containerColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color: context.textPrimary,
                  size: 22,
                ),
              ),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ),
      ],
    );
  }

  // ========== LOGOUT BUTTON ==========
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: () => _showLogoutConfirmation(context),
          icon: Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
          label: Text(
            AppLocalizations.of(context)!.logout,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== ERROR STATE ==========
  Widget _buildErrorState(Object error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n.error}: $error',
              style: context.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(userProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== LOGOUT CONFIRMATION ==========
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) => _LogoutDialog(
        rootContext: context,
        ref: ref,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private logout dialog — extracted to remove deep nesting from the state
// ---------------------------------------------------------------------------

class _LogoutDialog extends StatefulWidget {
  const _LogoutDialog({required this.rootContext, required this.ref});

  final BuildContext rootContext;
  final WidgetRef ref;

  @override
  State<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<_LogoutDialog> {
  bool _isLoggingOut = false;

  Future<void> _doLogout(BuildContext dialogContext) async {
    setState(() => _isLoggingOut = true);
    final l10n = AppLocalizations.of(widget.rootContext)!;
    try {
      GlobalChatListener().stop();
      await widget.ref.read(authServiceProvider).logout();
      await ChatSocketService().disconnect();
      widget.ref.read(badgeCountProvider.notifier).reset();
      widget.ref.read(chatPartnersProvider.notifier).reset();
      widget.ref.invalidate(userProvider);
      widget.ref.invalidate(authServiceProvider);

      if (dialogContext.mounted) Navigator.pop(dialogContext);

      if (widget.rootContext.mounted) {
        widget.rootContext.go('/login');
        ScaffoldMessenger.of(widget.rootContext).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.loggedOutSuccessfully)),
            ]),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (error) {
      setState(() => _isLoggingOut = false);
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $error'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: context.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(l10n.logout,
                style: context.titleMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              l10n.logoutConfirmMessage,
              style: context.bodySmall.copyWith(
                  color: context.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (_isLoggingOut) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.loggingOut, style: context.bodySmall),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (!_isLoggingOut)
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: context.containerColor,
                      ),
                      child: Text(l10n.cancel,
                          style: TextStyle(
                              color: context.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _doLogout(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: AppColors.error,
                      ),
                      child: Text(l10n.logout,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
