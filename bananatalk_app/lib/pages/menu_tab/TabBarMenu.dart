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
  /// Default to Community tab (index 0)
  const TabsScreen({super.key, this.initialIndex = 0});

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
    if (index == 1 || index == 4) {
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
        activePage = const CommunityMain();
        break;
      case 1:
        activePage = ChatMain();
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
        activePage = const CommunityMain();
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: activePage,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.gray900 : AppColors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.gray800 : AppColors.gray100,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    label: AppLocalizations.of(context)!.community,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.message_outlined,
                    activeIcon: Icons.message_rounded,
                    label: AppLocalizations.of(context)!.chats,
                    badgeCount: messageCount,
                    badgeColor: AppColors.primary,
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
                    label: AppLocalizations.of(context)!.study,
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      key: ValueKey(isSelected),
                      size: isSelected ? 25 : 23,
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
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.gray800 : AppColors.gray50,
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
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: isSelected ? 10.5 : 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : isDark
                          ? AppColors.gray400
                          : AppColors.gray600,
                  letterSpacing: isSelected ? 0.2 : 0,
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
