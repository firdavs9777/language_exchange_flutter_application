import 'package:bananatalk_app/pages/chat/list/chat_list_screen.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_main.dart';
import 'package:bananatalk_app/pages/profile/profile_main.dart';
import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:bananatalk_app/pages/learning/main/learning_main_screen.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/pages/ai/tutor/scenario_picker_screen.dart';
import 'package:bananatalk_app/services/activation_store.dart';
import 'package:bananatalk_app/models/app_config.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/services/guide_store.dart';
import 'package:bananatalk_app/services/launch_candidates.dart';
import 'package:bananatalk_app/services/launch_modal_coordinator.dart';
import 'package:bananatalk_app/services/version_check_coordinator.dart';
import 'package:bananatalk_app/pages/coins/coin_shop_screen.dart';
import 'package:bananatalk_app/services/promo_service.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/navigation/floating_tab_bar.dart';
import 'package:bananatalk_app/widgets/navigation/tab_reselect_scroll_to_top.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global tab-selection state shared between [TabsScreen] and any surface
/// (drawer, deep-link handler, modal) that needs to switch tabs without
/// fighting go_router's page-reuse rules. Reading this provider rebuilds
/// the consumer when the selected tab changes; writing it is what every
/// "go to tab N" entry point should do.
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// Index of the Moments tab in [_TabsScreenState._pages] / the bottom nav.
///
/// Named because "is my page the visible one?" is a real question for pages
/// that own expensive resources: every page lives in a `Stack` behind an
/// `AnimatedOpacity`, so an unselected tab is *invisible but fully alive* —
/// never disposed, still laid out, still building. Anything holding a video
/// decoder, camera or socket has to gate itself on
/// `ref.watch(selectedTabProvider) == <its index>` rather than assuming a
/// tab switch tore it down (see `ReelsGridScreen`).
const int kMomentsTabIndex = 3;

/// The launch pop-ups run once per process (spec §4.1), even if TabsScreen
/// is rebuilt by a deep link. Re-armed per account by [resetLaunchModalsRun].
bool _launchModalsRanThisProcess = false;

/// Lets the next account signed in on this process run the launch pop-ups
/// (called by `resetUserSession` on logout / account switch).
void resetLaunchModalsRun() => _launchModalsRanThisProcess = false;

@visibleForTesting
bool get launchModalsRanThisProcess => _launchModalsRanThisProcess;

@visibleForTesting
void debugMarkLaunchModalsRan() => _launchModalsRanThisProcess = true;

/// Whether a [TabsScreen] has mounted before in this process (see
/// [shouldSeedInitialTab]).
bool _tabsScreenMountedBefore = false;

/// Whether [TabsScreen]'s post-frame seed may write `initialIndex` into
/// [selectedTabProvider].
///
/// * A non-zero [initialIndex] is an explicit destination (`/tabs/:index`,
///   the Community landing) — always seed, as before.
/// * `initialIndex == 0` is just the constructor default. On the FIRST mount
///   in the process the provider's own default is also 0, so the seed could
///   only ever be a no-op — or clobber an external write (a notification /
///   router hop to tab 1 that landed before or in the same frame as the
///   mount). So skip it.
/// * On a later mount (e.g. log out -> log back in) keep today's reset to
///   tab 0, unless the provider changed between initState and the first
///   frame — that change is an external write and wins.
bool shouldSeedInitialTab({
  required int initialIndex,
  required bool firstMount,
  required int valueAtInit,
  required int valueNow,
}) {
  if (initialIndex != 0) return true;
  if (firstMount) return false;
  return valueNow == valueAtInit;
}

class TabsScreen extends ConsumerStatefulWidget {
  /// Default to AI Study tab (index 0).
  /// Tab order: AI Study (0) / Community (1) / Chats (2) / Moments (3) / Profile (4).
  const TabsScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends ConsumerState<TabsScreen> {
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Seed the global provider so deep links into /tabs/:index still land
    // on the right tab. Defer to a post-frame callback because writing to
    // a StateProvider during build / initState would throw.
    final firstMount = !_tabsScreenMountedBefore;
    _tabsScreenMountedBefore = true;
    final valueAtInit = ref.read(selectedTabProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(selectedTabProvider.notifier);
      if (shouldSeedInitialTab(
        initialIndex: widget.initialIndex,
        firstMount: firstMount,
        valueAtInit: valueAtInit,
        valueNow: notifier.state,
      )) {
        notifier.state = widget.initialIndex;
      }
    });
    _pages = [
      const LearningMain(),
      const CommunityMain(),
      ChatMain(tabRefreshNotifier: _tabRefreshNotifier),
      MomentsMain(),
      const ProfileMain(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(badgeCountProvider.notifier).fetchBadgeCount();
      _runLaunchModals();
    });
  }

  /// Whether this shell is the visible route, so a pop-up would land on it
  /// and not over a pushed screen. Callers check [mounted] first.
  bool get _isCurrentRoute {
    final route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  /// At most one pop-up per launch, chosen by [LaunchModalCoordinator]. The
  /// update dialog (and the welcome-back sheet) already ran in splash and
  /// spent the shared PopupBudget if they showed; inside the guide period
  /// nothing follows, so the budget is left for notification priming.
  ///
  /// Runs once per process. If the shell is rebuilt or replaced (a deep link)
  /// or covered by a pushed screen within the first second, the launch
  /// pop-ups are skipped for this process and show on the next launch:
  /// nothing is marked seen, so this is intended.
  Future<void> _runLaunchModals() async {
    if (_launchModalsRanThisProcess) return;
    _launchModalsRanThisProcess = true;
    // Let the shell paint first (the ads notice always waited a second).
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted || !_isCurrentRoute) return;

    final guidePeriod = await launchGuidePeriod(
      () => ref.read(isGuidePeriodProvider.future),
    );
    AppConfig? config;
    try {
      config = await ref.read(appConfigProvider.future);
    } catch (_) {
      config = null;
    }
    if (!mounted || !_isCurrentRoute) return;

    final store = ref.read(activationStoreProvider);
    await LaunchModalCoordinator(
      standardLaunchCandidates(
        config: config,
        pickSpotlight: () async {
          final lessonDone = await store.isDone(ActivationAction.lesson);
          if (!mounted || !_isCurrentRoute) return null;
          final promo = await pickPromo(ref, lessonDone: lessonDone);
          if (!mounted || !_isCurrentRoute) return null;
          return promo;
        },
        onSpotlightTry: _openPromoDestination,
      ),
    ).run(
      context,
      guidePeriod: guidePeriod,
      updateShown: VersionCheckCoordinator.lastCheckShowedUpdate,
    );
  }

  /// Deep-link for the feature spotlight's "Try it" CTA.
  ///
  /// Coins pushes `CoinShopScreen` directly. Rooms/voice live as sub-tabs
  /// inside `CommunityMain`'s internal `TabController`: request the precise
  /// sub-tab via `communityPendingSubTabProvider` (CommunityMain animates to
  /// it), then switch to the Community top-level tab.
  void _openPromoDestination(PromoType promo) {
    switch (promo) {
      case PromoType.coins:
        Navigator.push(
          context,
          AppPageRoute(builder: (_) => const CoinShopScreen()),
        );
      case PromoType.rooms:
        ref.read(communityPendingSubTabProvider.notifier).state =
            communityRoomsSubTab;
        ref.read(selectedTabProvider.notifier).state = 1;
      case PromoType.voice:
        ref.read(communityPendingSubTabProvider.notifier).state =
            communityVoiceRoomsSubTab;
        ref.read(selectedTabProvider.notifier).state = 1;
      case PromoType.aiStudy:
        Navigator.push(
          context,
          AppPageRoute(builder: (_) => const ScenarioPickerScreen()),
        );
    }
  }

  @override
  void didUpdateWidget(TabsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Deep links via go_router (`/tabs/:index`) reuse this page rather than
    // create a fresh one, so initState doesn't re-run. Forward the new
    // initialIndex to the provider so the tab actually switches.
    if (oldWidget.initialIndex != widget.initialIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(selectedTabProvider.notifier).state = widget.initialIndex;
      });
    }
  }

  // Notifiers for each tab to trigger silent refresh
  final ValueNotifier<int> _tabRefreshNotifier = ValueNotifier(0);

  /// Hide-on-scroll state for the floating bar (spec §8.2).
  final BarScrollState _barScroll = BarScrollState();
  bool _barVisible = true;

  void _showBar() {
    _barScroll.reset();
    if (!_barVisible) setState(() => _barVisible = true);
  }

  void _selectPage(int index) {
    HapticFeedback.selectionClick();

    // Re-tapping the active tab asks that tab to scroll to its top.
    if (index == ref.read(selectedTabProvider)) {
      final reselect = ref.read(tabReselectProvider.notifier);
      reselect.state = (tab: index, seq: reselect.state.seq + 1);
    }
    _showBar();

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

    ref.read(selectedTabProvider.notifier).state = index;

    // Notify the selected tab to refresh
    _tabRefreshNotifier.value++;
  }

  @override
  Widget build(BuildContext context) {
    final badgeCount = ref.watch(badgeCountProvider);
    // Pending (unread) intros/waves surface on the Chats tab badge so a
    // received wave is visible from anywhere in the app, not just when the
    // Community > Waves sub-tab happens to be open.
    final pendingIntrosCount = ref
        .watch(wavesUnreadProvider)
        .maybeWhen(data: (n) => n, orElse: () => 0);
    final messageCount = badgeCount.messages + pendingIntrosCount;
    final selectedPageIndex = ref.watch(selectedTabProvider);
    final l = AppLocalizations.of(context)!;
    // Any tab switch — a tap, a deep link, Android back — brings the bar back.
    ref.listen(selectedTabProvider, (prev, next) {
      if (prev != next) _showBar();
    });
    // Profile tab shows the user's own avatar (IG-style); falls back to the
    // person icon while loading / on error / when no photo is set.
    final currentUser = ref.watch(userProvider).valueOrNull;
    final String? profileAvatarUrl =
        (currentUser != null && currentUser.imageUrls.isNotEmpty)
        ? currentUser.imageUrls.first
        : null;

    return PopScope(
      // Android back at the root used to be swallowed entirely: `canPop:
      // false` with no handler meant the button did nothing at all, so the
      // only way out of the app was to minimise it and swipe the task away.
      //
      // Now back behaves the way Android users expect. Away from the first
      // tab it returns there, which is also how you get back to AI Study
      // without reaching for the bar. On the first tab `canPop` is true, so
      // the event falls through to the framework: there is nothing left to
      // pop, so it reaches the platform and Android backgrounds the app —
      // which is gentler than finishing the activity outright and keeps the
      // task resumable from Recents.
      canPop: selectedPageIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ref.read(selectedTabProvider.notifier).state = 0;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Page content — Stack with AnimatedOpacity preserves state for all
            // pages while crossfading smoothly on tab switch.
            Stack(
              children: List.generate(_pages.length, (index) {
                final isSelected = index == selectedPageIndex;
                return AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: IgnorePointer(
                    ignoring: !isSelected,
                    // Hidden tabs stay alive and can still scroll (a chat
                    // list receiving a message), so only the visible tab's
                    // scrolling moves the bar.
                    child: NotificationListener<Notification>(
                      onNotification: (n) {
                        // With TalkBack/VoiceOver on, a bar that slides
                        // away on scroll is hard to find again; keep it.
                        if (MediaQuery.accessibleNavigationOf(context)) {
                          return false;
                        }
                        if (index == ref.read(selectedTabProvider) &&
                            _barScroll.onNotification(n)) {
                          setState(() => _barVisible = _barScroll.visible);
                        }
                        return false;
                      },
                      // Re-tapping the active tab scrolls its visible list
                      // to the top (spec §8.2). StudyHub also listens with
                      // its own controller; both target the same top.
                      child: TabReselectScrollToTop(
                        tab: index,
                        child: _pages[index],
                      ),
                    ),
                  ),
                );
              }),
            ),
            FloatingTabBar(
              selected: selectedPageIndex,
              visible: _barVisible,
              onSelect: _selectPage,
              // A list that fits after the keyboard closes sends no scroll
              // update, so closing the keyboard itself brings the bar back.
              onKeyboardClosed: _showBar,
              items: [
                FloatingTabItem(
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book_rounded,
                  label: l.study,
                  color: const Color(0xFF8B5CF6),
                ),
                FloatingTabItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  label: l.community,
                  color: const Color(0xFF00BFA5),
                ),
                FloatingTabItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  imageAsset: 'assets/images/logo_mark_ios.png',
                  label: l.chats,
                  color: const Color(0xFF667EEA),
                  badgeCount: messageCount,
                ),
                FloatingTabItem(
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome_rounded,
                  label: l.moments,
                  color: const Color(0xFFFF6B6B),
                ),
                FloatingTabItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  avatarUrl: profileAvatarUrl,
                  label: l.profile,
                  color: const Color(0xFFF59E0B),
                  badgeCount: badgeCount.notifications,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

