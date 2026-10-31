import 'dart:convert';
import 'package:bananatalk_app/widgets/app_shell_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/pages/community/tabs/matches_tab.dart';
import 'package:bananatalk_app/pages/community/tabs/partner_discovery_tab.dart';
import 'package:bananatalk_app/pages/community/partners/partner_query.dart';
import 'package:bananatalk_app/pages/community/gatherings/gatherings_tab.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_rooms_tab.dart';
import 'package:bananatalk_app/pages/community/rooms/rooms_directory_screen.dart';
import 'package:bananatalk_app/widgets/community/user_skeleton.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_rooms_screen.dart';
import 'package:bananatalk_app/pages/community/waves/waves_screen.dart';
import 'package:bananatalk_app/pages/community/single/single_community_screen.dart';
import 'package:bananatalk_app/pages/community/filter/community_filter_sheet.dart';
import 'package:bananatalk_app/pages/community/filter/filter_state.dart';
import 'package:bananatalk_app/pages/community/main/community_app_bar.dart';
import 'package:bananatalk_app/pages/community/main/community_tab_bar.dart';
import 'package:bananatalk_app/pages/community/main/community_filter_chips.dart';
import 'package:bananatalk_app/pages/community/main/search_debounce.dart';
import 'package:bananatalk_app/services/user_service.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/friendly_error.dart';

/// The Community tabs (2026-10-31: four, down from eight). Nearby, City,
/// Gender and Topics are chips on the Partners list; Waves is a header icon.
enum CommunityTabId { matches, partners, clubs, rooms }

/// Ordered tabs for a layout; the tab strip, the `TabBarView` and every deep
/// link derive from this one list.
///
/// Matches only while `matchesLayoutEnabled`; Rooms only while
/// `roomsEnabled`. The Clubs slot shows voice rooms while `gatheringsEnabled`
/// is off (as before), so it always exists.
List<CommunityTabId> communityTabLayout({
  required bool matchesLayout,
  required bool rooms,
}) => [
  if (matchesLayout) CommunityTabId.matches,
  CommunityTabId.partners,
  CommunityTabId.clubs,
  if (rooms) CommunityTabId.rooms,
];

/// Index of [id] in the layout. A tab the layout does not have falls back:
/// Matches -> Partners, Rooms -> Clubs.
int indexOfTab(
  CommunityTabId id, {
  required bool matchesLayout,
  required bool rooms,
}) {
  final tabs = communityTabLayout(matchesLayout: matchesLayout, rooms: rooms);
  final index = tabs.indexOf(id);
  if (index >= 0) return index;
  return switch (id) {
    CommunityTabId.rooms => tabs.indexOf(CommunityTabId.clubs),
    _ => tabs.indexOf(CommunityTabId.partners),
  };
}

/// Where a deep link, push or promo asks Community to open. By identity, not
/// index: the tab count depends on two server flags.
enum CommunityDestination { matches, partners, clubs, rooms, voiceRooms, waves }

/// Set by a deep link to request that Community open a destination once it
/// builds. `CommunityMain` consumes it, then resets it to null.
final communityPendingSubTabProvider = StateProvider<CommunityDestination?>(
  (ref) => null,
);

/// Where a freshly registered user lands. With the Matches layout on, the
/// Community tab (top-level index 1) whose first sub-tab is Matches; otherwise
/// exactly today's `/home`.
String homeRouteForNewUser({required bool matchesLayoutEnabled}) =>
    matchesLayoutEnabled ? '/tabs/1' : '/home';



/// Main Community screen with HelloTalk-style tabs
class CommunityMain extends ConsumerStatefulWidget {
  const CommunityMain({super.key});

  @override
  ConsumerState<CommunityMain> createState() => _CommunityMainState();
}

class _CommunityMainState extends ConsumerState<CommunityMain>
    with TickerProviderStateMixin {
  static const String _filtersKey = 'community_filters';

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  /// What the lists search for: [_searchQuery] 350 ms after the last key.
  String _appliedSearch = '';
  late final SearchDebounce _searchDebounce = SearchDebounce(
    onApply: (q) {
      if (mounted) setState(() => _appliedSearch = q);
    },
  );
  FilterState _filters = FilterState.defaults;

  /// The tabs `_tabController` is currently built for. Null until app-config
  /// resolves (a skeleton shows meanwhile, so the strip never reshuffles and
  /// Partners is never loaded just to be replaced by Matches).
  List<CommunityTabId>? _layout;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadSavedFilters();
    // `ref.listen` ignores a value that was set before this widget mounted
    // (e.g. a fresh /tabs/1 landing), so consume it once here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(communityPendingSubTabProvider);
      if (pending != null) _consumePendingSubTab(pending);
    });
  }

  /// Opens a requested destination, then clears the request. Waits for
  /// app-config (the layout depends on it) before acting.
  void _consumePendingSubTab(CommunityDestination requested) {
    final layout = _layout;
    if (layout == null) {
      ref
          .read(appConfigProvider.future)
          .then<void>((_) {}, onError: (_) {})
          .then((_) {
            if (!mounted) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final pending = ref.read(communityPendingSubTabProvider);
              if (pending != null) _consumePendingSubTab(pending);
            });
          });
      return;
    }
    ref.read(communityPendingSubTabProvider.notifier).state = null;
    final matches = layout.contains(CommunityTabId.matches);
    final rooms = layout.contains(CommunityTabId.rooms);
    int index(CommunityTabId id) =>
        indexOfTab(id, matchesLayout: matches, rooms: rooms);
    switch (requested) {
      case CommunityDestination.waves:
        _openWaves();
      case CommunityDestination.voiceRooms:
        _openLiveRooms();
      case CommunityDestination.matches:
        _tabController.animateTo(index(CommunityTabId.matches));
      case CommunityDestination.partners:
        _tabController.animateTo(index(CommunityTabId.partners));
      case CommunityDestination.clubs:
        _tabController.animateTo(index(CommunityTabId.clubs));
      case CommunityDestination.rooms:
        _tabController.animateTo(index(CommunityTabId.rooms));
    }
  }

  /// Rebuilds `_tabController` when the layout changes, keeping the selected
  /// tab by identity (a tab that disappears falls back via [indexOfTab]).
  void _syncLayout(List<CommunityTabId> layout) {
    final old = _layout;
    if (old != null && listEquals(old, layout)) return;
    final int initial;
    if (old == null) {
      initial = 0;
    } else {
      final selected = old[_tabController.index.clamp(0, old.length - 1)];
      initial = indexOfTab(
        selected,
        matchesLayout: layout.contains(CommunityTabId.matches),
        rooms: layout.contains(CommunityTabId.rooms),
      );
    }
    _tabController.dispose();
    _tabController = TabController(
      length: layout.length,
      initialIndex: initial,
      vsync: this,
    );
    _layout = layout;
  }

  void _openWaves() {
    Navigator.push(
      context,
      AppPageRoute<void>(builder: (_) => const WavesScreen()),
    );
  }

  /// Load saved filters from SharedPreferences.
  ///
  /// Uses [FilterState.fromJson] which is backwards-compatible with the old
  /// `Map<String,dynamic>` shape previously written under [_filtersKey].
  Future<void> _loadSavedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFilters = prefs.getString(_filtersKey);
      if (savedFilters == null) return;
      final decoded = json.decode(savedFilters) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _filters = FilterState.fromJson(decoded));
    } catch (_) {
      // Non-fatal: fall back to default filters.
    }
  }

  /// Save filters to SharedPreferences.
  Future<void> _saveFilters(FilterState filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_filtersKey, json.encode(filters.toJson()));
    } catch (_) {
      // Non-fatal.
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce.dispose();
    super.dispose();
  }

  void _applyFilters(FilterState updated) {
    setState(() => _filters = updated);
    _saveFilters(updated);
  }

  void _clearAllFilters() => _applyFilters(FilterState.defaults);

  void _openFilters() {
    // Filters are free for everyone — the previous rewarded-ad gate was
    // dropped while AdMob serving is throttled. The filter sheet itself
    // promotes VIP inline for non-VIP users.
    _showFilterSheet();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommunityFilter(
        onApplyFilters: (filtersMap) {
          _applyFilters(FilterState.fromJson(filtersMap));
          // Filters only change Partners: show the result there instead of
          // an unchanged screen (2026-10-18).
          final partners = _layout?.indexOf(CommunityTabId.partners) ?? -1;
          if (partners >= 0 && mounted) _tabController.animateTo(partners);
        },
        initialFilters: _filters.toJson(),
      ),
    );
  }

  void _removeFilter(String key) {
    final FilterState updated;
    switch (key) {
      case 'age':
        updated = _filters.copyWith(minAge: 18, maxAge: 100);
      case 'gender':
        updated = FilterState.fromJson({..._filters.toJson(), 'gender': null});
      case 'nativeLanguage':
        updated = FilterState.fromJson({
          ..._filters.toJson(),
          'nativeLanguage': null,
        });
      case 'learningLanguage':
        updated = FilterState.fromJson({
          ..._filters.toJson(),
          'learningLanguage': null,
        });
      case 'country':
        updated = FilterState.fromJson({..._filters.toJson(), 'country': null});
      case 'languageLevel':
        updated = FilterState.fromJson({
          ..._filters.toJson(),
          'languageLevel': null,
        });
      case 'onlineOnly':
        updated = _filters.copyWith(onlineOnly: false);
      case 'newUsersOnly':
        updated = _filters.copyWith(newUsersOnly: false);
      case 'prioritizeNearby':
        updated = _filters.copyWith(prioritizeNearby: false);
      default:
        return;
    }
    _applyFilters(updated);
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _searchDebounce.clearNow();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // The layout waits for app-config: guessing defaults first meant the
    // strip reshuffled when it resolved (and Partners loaded, only to be
    // replaced by Matches). An error falls back to the defaults.
    final config = ref.watch(appConfigProvider);
    final configReady = !config.isLoading;
    final roomsEnabled =
        config.maybeWhen(data: (c) => c?.roomsEnabled ?? true, orElse: () => true);
    final matchesLayout = config.maybeWhen(
      data: (c) => c?.matchesLayoutEnabled ?? false,
      orElse: () => false,
    );
    // 모임 lives in the Clubs slot; with it off the slot shows voice rooms.
    final gatheringsEnabled = config.maybeWhen(
      data: (c) => c?.gatheringsEnabled ?? true,
      orElse: () => true,
    );
    final layout = communityTabLayout(
      matchesLayout: matchesLayout,
      rooms: roomsEnabled,
    );
    if (configReady) _syncLayout(layout);

    // Nearby has no name search: turning it on closes an open search
    // (its close button hides with the icon).
    ref.listen<bool>(partnerQuickChipsProvider.select((c) => c.nearby), (_, on) {
      if (on && _isSearching) _toggleSearch();
    });

    // Deep links / pushes / promos request a destination; open it once.
    ref.listen<CommunityDestination?>(communityPendingSubTabProvider, (_, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _consumePendingSubTab(next);
      });
    });

    // Compute filter-derived values once per build instead of allocating a
    // fresh Map on every widget that needs them.
    final filtersJson = _filters.toJson();
    final hasActiveFilters = CommunityFilterChips.hasActiveFilters(filtersJson);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const AppShellDrawer(currentTabIndex: 1),
      appBar: CommunityAppBar(
        isSearching: _isSearching,
        onSearchToggle: _toggleSearch,
        onFilterTap: _openFilters,
        onWavesTap: _openWaves,
        matchesLayout: matchesLayout,
        showSearch: !ref.watch(
          partnerQuickChipsProvider.select((c) => c.nearby),
        ),
      ),
      body: Column(
        children: [
          // Search bar (shown when searching)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: _isSearching ? 60 : 0,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(),
            child: AnimatedOpacity(
              opacity: _isSearching ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _isSearching ? _buildSearchBar(colorScheme) : null,
            ),
          ),
          if (!configReady)
            const Expanded(child: UserListSkeleton(count: 6))
          else ...[
            CommunityTabBar(
              tabController: _tabController,
              tabs: layout,
              gatheringsEnabled: gatheringsEnabled,
            ),
            // Active filter chips (they only change Partners)
            if (hasActiveFilters)
              CommunityFilterChips(
                filters: filtersJson,
                onRemove: _removeFilter,
                onClearAll: _clearAllFilters,
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  for (final tab in layout)
                    switch (tab) {
                      CommunityTabId.matches => MatchesTab(
                        onBrowsePartners: () => _tabController.animateTo(
                          layout.indexOf(CommunityTabId.partners),
                        ),
                      ),
                      CommunityTabId.partners => PartnerDiscoveryTab(
                        filters: filtersJson,
                        searchQuery: _appliedSearch,
                        onClearFilters: _clearAllFilters,
                      ),
                      // 모임 replaces voice rooms in this slot; with the
                      // server switch off the slot shows voice rooms.
                      CommunityTabId.clubs => gatheringsEnabled
                          ? const GatheringsTab()
                          : const VoiceRoomsTab(),
                      CommunityTabId.rooms => const RoomsDirectoryScreen(),
                    },
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Live voice rooms: the Clubs slot while it shows voice rooms (모임
  /// off), else the full voice-rooms list.
  void _openLiveRooms() {
    final gatherings = ref
        .read(appConfigProvider)
        .maybeWhen(data: (c) => c?.gatheringsEnabled ?? true, orElse: () => true);
    final clubs = _layout?.indexOf(CommunityTabId.clubs) ?? -1;
    if (!gatherings && clubs >= 0) {
      _tabController.animateTo(clubs);
      return;
    }
    openVoiceRoomsScreen(context);
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    final trimmed = _searchQuery.trim();
    final isUsernameSearch = trimmed.startsWith('@');
    final username = isUsernameSearch && trimmed.length > 1
        ? trimmed.substring(1)
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.containerHighColor,
        borderRadius: AppRadius.borderLG,
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.communitySearchHint,
          hintStyle: context.bodyMedium.copyWith(color: context.textSecondary),
          prefixIcon: Icon(Icons.search_rounded, color: context.primaryColor),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isUsernameSearch && username.isNotEmpty)
                TextButton(
                  onPressed: () => _findUserByUsername(username),
                  style: TextButton.styleFrom(
                    foregroundColor: context.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.communityFind,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: context.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _searchDebounce.clearNow();
                  },
                ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: 14,
          ),
        ),
        style: context.bodyMedium,
        onChanged: (value) {
          // Auto-strip leading @ when pasting a username.
          if (value.startsWith('@') &&
              value.length > 1 &&
              !value.contains(' ')) {
            final stripped = value.substring(1);
            _searchController.value = TextEditingValue(
              text: stripped,
              selection: TextSelection.collapsed(offset: stripped.length),
            );
            setState(() => _searchQuery = stripped);
            _findUserByUsername(stripped);
            return;
          }
          setState(() => _searchQuery = value);
          _searchDebounce.typed(value);
        },
        onSubmitted: (_) {
          if (isUsernameSearch && username.isNotEmpty) {
            _findUserByUsername(username);
          }
        },
      ),
    );
  }

  /// Find user by username and navigate to their profile.
  Future<void> _findUserByUsername(String username) async {
    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Use rootNavigator for the dialog so it doesn't conflict with page nav.
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.communityFinding(username),
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final user = await UserService().getUserByUsername(username);
      if (!mounted) return;
      rootNavigator.pop(); // close loading dialog

      if (user != null) {
        _searchController.clear();
        setState(() {
          _searchQuery = '';
          _isSearching = false;
        });
        _searchDebounce.clearNow();
        Navigator.of(
          context,
        ).push(AppPageRoute(builder: (_) => SingleCommunity(community: user)));
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.communityUserNotFound(username)),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      try {
        rootNavigator.pop();
      } catch (_) {}
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyErrorMessage(l10n, e)),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
