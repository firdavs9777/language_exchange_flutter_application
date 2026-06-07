import 'package:bananatalk_app/pages/chat/list/chat_list_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_main.dart';
import 'package:bananatalk_app/pages/profile/profile_main.dart';
import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:bananatalk_app/pages/learning/main/learning_main_screen.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/widgets/promo/ai_study_promo_modal.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabsScreen extends ConsumerStatefulWidget {
  /// Default to AI Study tab (index 0).
  /// Tab order: AI Study (0) / Community (1) / Chats (2) / Moments (3) / Profile (4).
  const TabsScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends ConsumerState<TabsScreen> {
  late int _selectedPageIndex;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedPageIndex = widget.initialIndex;
    _pages = [
      const LearningMain(),
      const CommunityMain(),
      ChatMain(tabRefreshNotifier: _tabRefreshNotifier),
      MomentsMain(),
      const ProfileMain(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(badgeCountProvider.notifier).fetchBadgeCount();
      // Weekly promo for AI Study / practice scenarios. Self-throttles to
      // once per 7 days via SharedPreferences.
      if (mounted) {
        AiStudyPromoModal.showIfDue(context);
      }
    });
  }

  // Notifiers for each tab to trigger silent refresh
  final ValueNotifier<int> _tabRefreshNotifier = ValueNotifier(0);

  void _selectPage(int index) {
    HapticFeedback.selectionClick();

    // Auto-heal: if userProvider is in error, invalidate it on any tab tap
    // so the next provider read gets a fresh fetch from auth/me.
    final userState = ref.read(userProvider);
    if (userState.hasError) {
      ref.invalidate(userProvider);
    }

    // Refresh badge counts when entering Chats or Profile (badge-bearing tabs).
    if (index == 2 || index == 4) {
      ref.read(badgeCountProvider.notifier).fetchBadgeCount();
    }

    setState(() {
      _selectedPageIndex = index;
    });

    // Notify the selected tab to refresh
    _tabRefreshNotifier.value++;
  }

  @override
  Widget build(BuildContext context) {
    final badgeCount = ref.watch(badgeCountProvider);
    final messageCount = badgeCount.messages;
    final isDark = context.isDarkMode;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // Page content — Stack with AnimatedOpacity preserves state for all
            // pages while crossfading smoothly on tab switch.
            Stack(
              children: List.generate(_pages.length, (index) {
                final isSelected = index == _selectedPageIndex;
                return AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: IgnorePointer(
                    ignoring: !isSelected,
                    child: _pages[index],
                  ),
                );
              }),
            ),
            // Buy me a coffee — floats above the tab bar on the right
            Positioned(
              right: 16,
              bottom: bottomPadding > 0 ? bottomPadding + 76 : 88,
              child: _CoffeeButton(),
            ),

            // Floating tab bar overlay
            Positioned(
              left: 12,
              right: 12,
              bottom: bottomPadding > 0 ? bottomPadding - 4 : 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 68,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1C2E).withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildNavItem(
                          index: 0,
                          icon: Icons.menu_book_outlined,
                          activeIcon: Icons.menu_book_rounded,
                          label: AppLocalizations.of(context)!.study,
                          isDark: isDark,
                        ),
                        _buildNavItem(
                          index: 1,
                          icon: Icons.explore_outlined,
                          activeIcon: Icons.explore_rounded,
                          label: AppLocalizations.of(context)!.community,
                          isDark: isDark,
                        ),
                        _buildNavItem(
                          index: 2,
                          icon: Icons.chat_bubble_outline_rounded,
                          activeIcon: Icons.chat_bubble_rounded,
                          label: AppLocalizations.of(context)!.chats,
                          badgeCount: messageCount,
                          isDark: isDark,
                        ),
                        _buildNavItem(
                          index: 3,
                          icon: Icons.auto_awesome_outlined,
                          activeIcon: Icons.auto_awesome_rounded,
                          label: AppLocalizations.of(context)!.moments,
                          isDark: isDark,
                        ),
                        _buildNavItem(
                          index: 4,
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          label: AppLocalizations.of(context)!.profile,
                          badgeCount: badgeCount.notifications,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
    int badgeCount = 0,
  }) {
    final isSelected = _selectedPageIndex == index;

    // Each tab gets a unique accent color when active
    final Color activeColor = _getTabColor(index);
    final Color inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.35);

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectPage(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isSelected ? 20 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icon with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    size: 24,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1C1C2E)
                              : Colors.white,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: isSelected ? 0.1 : 0,
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
    );
  }

  Color _getTabColor(int index) {
    switch (index) {
      case 0: return const Color(0xFF8B5CF6);
      case 1: return const Color(0xFF00BFA5);
      case 2: return const Color(0xFF667EEA);
      case 3: return const Color(0xFFFF6B6B);
      case 4: return const Color(0xFFF59E0B);
      default: return AppColors.primary;
    }
  }
}

// ─── Buy me a coffee button ───────────────────────────────────────────────────

class _CoffeeButton extends StatefulWidget {
  const _CoffeeButton();

  @override
  State<_CoffeeButton> createState() => _CoffeeButtonState();
}

class _CoffeeButtonState extends State<_CoffeeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    _scale = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    // Auto-collapse label after 4 seconds to keep it unobtrusive
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _expanded = false);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    HapticFeedback.lightImpact();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SupportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.animateTo(0.0),
      onTapUp: (_) async { _ctrl.animateTo(1.0); await _open(); },
      onTapCancel: () => _ctrl.animateTo(1.0),
      onTap: () {
        // Expand label on tap if collapsed
        if (!_expanded) setState(() => _expanded = true);
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          height: 38,
          padding: EdgeInsets.symmetric(
            horizontal: _expanded ? 14 : 10,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFDD57), Color(0xFFFFBB00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFDD57).withValues(alpha: 0.50),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('☕', style: TextStyle(fontSize: 17)),
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                child: _expanded
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 6),
                          Text(
                            'Buy me a coffee',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5C3D00),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Support / donation sheet ─────────────────────────────────────────────────

class _SupportSheet extends StatelessWidget {
  static const _paypalUrl = 'https://paypal.me/firdavsDev';

  const _SupportSheet();

  Future<void> _donate() async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(_paypalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.60)
        : const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Emoji + headline
          const Text('☕', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(
            l10n.supportSheetGreeting,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          // Story card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withValues(alpha: isDark ? 0.12 : 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00BFA5).withValues(alpha: isDark ? 0.22 : 0.18),
              ),
            ),
            child: Text(
              l10n.supportSheetStory,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // PayPal donate button
          GestureDetector(
            onTap: _donate,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003087), Color(0xFF009CDE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF003087).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💙', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    l10n.supportSheetDonateButton,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // PayPal handle hint
          Text(
            '@firdavsDev',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
