import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/pages/profile/edit_main/edit_main.dart';
import 'package:bananatalk_app/pages/settings/blocked_users_screen.dart';
import 'package:bananatalk_app/pages/settings/language_settings_screen.dart';
import 'package:bananatalk_app/pages/settings/notification_preferences_screen.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

/// One drawer shared across the main app surfaces (chat list, moments, …).
/// Surfaces profile + cross-tab shortcuts + standard settings so users don't
/// have to dig through the Me tab.
///
/// [extraItems] is rendered between the profile header and the cross-tab
/// shortcuts — use it for screen-specific actions like "Add Moment" or
/// "Add Story" on the Moments shell.
///
/// [currentTabIndex] suppresses the cross-tab shortcut for the tab the user
/// is already on (e.g. don't show "Moments" in the Moments drawer).
class AppShellDrawer extends ConsumerWidget {
  final List<AppShellDrawerItem> extraItems;
  final int? currentTabIndex;

  const AppShellDrawer({
    super.key,
    this.extraItems = const [],
    this.currentTabIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(userProvider);
    final user = userAsync.valueOrNull;

    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Profile header — avatar + name + @username.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  CachedCircleAvatar(
                    imageUrl: user?.profileImageUrl,
                    radius: 28,
                    backgroundColor: colors.surfaceVariant,
                    errorWidget: Text(
                      (user?.name.isNotEmpty ?? false)
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user?.displayUsername != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            user!.displayUsername!,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: colors.outline.withValues(alpha: 0.2), height: 1),

            // Standard profile items.
            AppShellDrawerItem(
              icon: Icons.person_outline_rounded,
              label: l10n.profile,
              onTap: () => _switchTab(context,4),
            ),
            AppShellDrawerItem(
              icon: Icons.edit_outlined,
              label: l10n.editProfile,
              onTap: () async {
                if (user == null) {
                  Navigator.pop(context);
                  return;
                }
                // Capture the ProviderContainer before closing the drawer —
                // after Navigator.pop the drawer's `ref` is disposed, so any
                // ref.invalidate(...) call from this closure would throw
                // "Cannot use ref after the widget was disposed". The
                // container outlives the drawer and is safe to invalidate on.
                final container = ProviderScope.containerOf(context);
                final navigator = Navigator.of(context);
                Navigator.pop(context);
                await navigator.push(
                  AppPageRoute(
                    builder: (_) => ProfileEdit(
                      userName: user.name,
                      mbti: user.mbti,
                      bloodType: user.bloodType,
                      location: user.location,
                      nativeLanguage: user.native_language,
                      languageToLearn: user.language_to_learn,
                      gender: user.gender,
                      bio: user.bio,
                      topics: user.topics,
                      languageLevel: user.languageLevel,
                    ),
                  ),
                );
                container.invalidate(userProvider);
              },
            ),
            AppShellDrawerItem(
              icon: Icons.workspace_premium_rounded,
              label: l10n.upgradeToVIP,
              iconColor: const Color(0xFFFFA000),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  AppPageRoute(builder: (_) => const VipPlansScreen()),
                );
              },
            ),

            // Screen-specific actions ("Add Moment", "Add Story", etc).
            if (extraItems.isNotEmpty) ...[
              Divider(color: colors.outline.withValues(alpha: 0.2), height: 1),
              ...extraItems,
            ],

            Divider(color: colors.outline.withValues(alpha: 0.2), height: 1),

            // Cross-tab shortcuts. Tab indices come from TabsScreen:
            // 0 = AI Study, 1 = Community, 2 = Chats, 3 = Moments, 4 = Profile.
            if (currentTabIndex != 0)
              AppShellDrawerItem(
                icon: Icons.school_rounded,
                label: l10n.studyHub,
                onTap: () => _switchTab(context,0),
              ),
            if (currentTabIndex != 1)
              AppShellDrawerItem(
                icon: Icons.people_alt_rounded,
                label: l10n.community,
                onTap: () => _switchTab(context,1),
              ),
            if (currentTabIndex != 2)
              AppShellDrawerItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: l10n.chats,
                onTap: () => _switchTab(context,2),
              ),
            if (currentTabIndex != 3)
              AppShellDrawerItem(
                icon: Icons.photo_library_outlined,
                label: l10n.moments,
                onTap: () => _switchTab(context,3),
              ),

            Divider(color: colors.outline.withValues(alpha: 0.2), height: 1),
            AppShellDrawerItem(
              icon: Icons.notifications_none_rounded,
              label: l10n.notificationSettings,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  AppPageRoute(
                    builder: (_) => const NotificationPreferencesScreen(),
                  ),
                );
              },
            ),
            AppShellDrawerItem(
              icon: Icons.translate_rounded,
              label: l10n.language,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  AppPageRoute(
                    builder: (_) => const LanguageSettingsScreen(),
                  ),
                );
              },
            ),
            AppShellDrawerItem(
              icon: Icons.block_rounded,
              label: l10n.blockedUsers,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  AppPageRoute(builder: (_) => const BlockedUsersScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Switch the bottom-nav tab from a drawer item by writing to the global
/// [selectedTabProvider]. Capturing the ProviderContainer first so the
/// write survives the drawer's synchronous Navigator.pop tear-down.
void _switchTab(BuildContext context, int index) {
  // Capture the ProviderContainer before closing the drawer — after
  // Navigator.pop the drawer's `ref` is disposed and any read against it
  // throws "Cannot use ref after the widget was disposed". The container
  // outlives the drawer.
  final container = ProviderScope.containerOf(context);
  Navigator.pop(context);
  container.read(selectedTabProvider.notifier).state = index;
}

class AppShellDrawerItem extends StatelessWidget {
  const AppShellDrawerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? colors.onSurface, size: 22),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }
}
