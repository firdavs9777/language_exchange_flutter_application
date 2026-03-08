import 'package:bananatalk_app/pages/chat/chat_main.dart';
import 'package:bananatalk_app/pages/moments/moments_main.dart';
import 'package:bananatalk_app/pages/profile/profile_main.dart';
import 'package:bananatalk_app/pages/community/community_main.dart';
import 'package:bananatalk_app/pages/learning/learning_main.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabsScreen extends ConsumerStatefulWidget {
  /// Default to Community tab (index 1) - users want to find language partners first
  const TabsScreen({super.key, this.initialIndex = 1});

  final int initialIndex;

  @override
  ConsumerState<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends ConsumerState<TabsScreen> {
  late int _selectedPageIndex;

  @override
  void initState() {
    super.initState();
    _selectedPageIndex = widget.initialIndex;

    // Refresh badge count on app load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(badgeCountProvider.notifier).fetchBadgeCount();
    });
  }

  void _selectPage(int index) {
    // Add haptic feedback for modern feel
    HapticFeedback.selectionClick();

    // Refresh badge count when switching to Chat or Profile tabs
    if (index == 0 || index == 4) {
      ref.read(badgeCountProvider.notifier).fetchBadgeCount();
    }

    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final badgeCount = ref.watch(badgeCountProvider);
    final messageCount = badgeCount.messages;
    final isDark = context.isDarkMode;

    Widget activePage;
    switch (_selectedPageIndex) {
      case 0:
        activePage = ChatMain();
        break;
      case 1:
        activePage = const CommunityMain();
        break;
      case 2:
        activePage = MomentsMain();
        break;
      case 3:
        activePage = const LearningMain(); // Combined Learn + AI Hub
        break;
      case 4:
        activePage = const ProfileMain();
        break;
      default:
        activePage = ChatMain();
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: activePage,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.gray900 : AppColors.white,
            boxShadow: AppShadows.md,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.forum_outlined,
                    activeIcon: Icons.forum_rounded,
                    label: AppLocalizations.of(context)!.banaTalk,
                    badgeCount: messageCount,
                    badgeColor: AppColors.primary,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_rounded,
                    label: AppLocalizations.of(context)!.community,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.auto_awesome_outlined,
                    activeIcon: Icons.auto_awesome_rounded,
                    label: AppLocalizations.of(context)!.moments,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book_rounded,
                    label: 'Study',
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.account_circle_outlined,
                    activeIcon: Icons.account_circle_rounded,
                    label: AppLocalizations.of(context)!.profile,
                    badgeCount: badgeCount.notifications,
                    badgeColor: AppColors.error,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
    Color? badgeColor,
  }) {
    final isSelected = _selectedPageIndex == index;
    final isDark = context.isDarkMode;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectPage(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: isSelected
              ? BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderLG,
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      key: ValueKey(isSelected),
                      size: isSelected ? 26 : 24,
                      color: isSelected
                          ? AppColors.primary
                          : isDark
                              ? AppColors.gray400
                              : AppColors.gray500,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor ?? AppColors.error,
                          borderRadius: AppRadius.borderSM,
                          border: Border.all(
                            color: isDark ? AppColors.gray900 : AppColors.white,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              Spacing.gapXS,
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : isDark
                          ? AppColors.gray400
                          : AppColors.gray600,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
