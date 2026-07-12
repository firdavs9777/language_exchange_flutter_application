import 'dart:convert';
import 'package:bananatalk_app/widgets/app_shell_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/pages/community/tabs/partner_discovery_tab.dart';
import 'package:bananatalk_app/pages/community/tabs/nearby_tab.dart';
import 'package:bananatalk_app/pages/community/tabs/city_tab.dart';
import 'package:bananatalk_app/pages/community/tabs/genders_tab.dart';
import 'package:bananatalk_app/pages/community/tabs/topics_tab.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_rooms_tab.dart';
import 'package:bananatalk_app/pages/community/tabs/waves_tab.dart';
import 'package:bananatalk_app/pages/community/rooms/rooms_directory_screen.dart';
import 'package:bananatalk_app/pages/community/single/single_community_screen.dart';
import 'package:bananatalk_app/pages/community/filter/community_filter_sheet.dart';
import 'package:bananatalk_app/pages/community/filter/filter_state.dart';
import 'package:bananatalk_app/pages/community/main/community_app_bar.dart';
import 'package:bananatalk_app/pages/community/main/community_tab_bar.dart';
import 'package:bananatalk_app/pages/community/main/community_filter_chips.dart';
import 'package:bananatalk_app/services/user_service.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/app_config_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';
import 'package:bananatalk_app/pages/community/widgets/visitor_recall_card.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Main Community screen with HelloTalk-style tabs
class CommunityMain extends ConsumerStatefulWidget {
  const CommunityMain({super.key});

  @override
  ConsumerState<CommunityMain> createState() => _CommunityMainState();
}

class _CommunityMainState extends ConsumerState<CommunityMain>
    with TickerProviderStateMixin {
  static const String _filtersKey = 'community_filters';
  static const int _baseTabCount = 7;

  /// Tab index that should display the profile-visitor recall card.
  static const int _partnersTabIndex = 0;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  FilterState _filters = FilterState.defaults;

  /// Whether the 8th "Rooms" tab is currently built into `_tabController`.
  /// Tracked so we only recreate the controller when this actually flips
  /// (`appConfigProvider` re-resolving to the same value shouldn't churn
  /// the controller and reset the user's current tab).
  bool? _roomsTabBuilt;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _baseTabCount, vsync: this)
      ..addListener(_onTabChanged);
    _loadSavedFilters();
  }

  /// Rebuilds `_tabController` with 8 tabs once `roomsEnabled` resolves to
  /// true, or shrinks back to 7 if it's false. Keeps the currently selected
  /// tab index stable when it's still in range.
  void _syncTabCountWithRoomsFlag(bool roomsEnabled) {
    if (_roomsTabBuilt == roomsEnabled) return;
    final newCount = roomsEnabled ? _baseTabCount + 1 : _baseTabCount;
    if (_tabController.length == newCount) {
      _roomsTabBuilt = roomsEnabled;
      return;
    }
    final previousIndex = _tabController.index;
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _tabController = TabController(
      length: newCount,
      initialIndex: previousIndex < newCount ? previousIndex : 0,
      vsync: this,
    )..addListener(_onTabChanged);
    _roomsTabBuilt = roomsEnabled;
  }

  /// Rebuild on tab switch so the visitor card only renders on the
  /// Partners tab (and never wastes vertical space on the other tabs).
  void _onTabChanged() {
    if (mounted) setState(() {});
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
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _searchController.dispose();
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
        onApplyFilters: (filtersMap) =>
            _applyFilters(FilterState.fromJson(filtersMap)),
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Workstream D: hide the Rooms tab entirely while the server-side kill
    // switch is off. Defaults to enabled while the config request is still
    // in flight (matches `AppConfig.roomsEnabled`'s default), then syncs
    // the controller's tab count once the real value resolves.
    final roomsEnabled = ref
        .watch(appConfigProvider)
        .maybeWhen(data: (config) => config?.roomsEnabled ?? true, orElse: () => true);
    _syncTabCountWithRoomsFlag(roomsEnabled);

    // Compute filter-derived values once per build instead of allocating a
    // fresh Map on every widget that needs them.
    final filtersJson = _filters.toJson();
    final filtersKey = _filters.hashCode;
    final hasActiveFilters = CommunityFilterChips.hasActiveFilters(filtersJson);
    final showVisitorCard = _tabController.index == _partnersTabIndex;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const AppShellDrawer(currentTabIndex: 1),
      appBar: CommunityAppBar(
        isSearching: _isSearching,
        onSearchToggle: _toggleSearch,
        onFilterTap: _openFilters,
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
          // Tab bar
          CommunityTabBar(
            tabController: _tabController,
            showRoomsTab: roomsEnabled,
          ),
          // Active filter chips
          if (hasActiveFilters)
            CommunityFilterChips(
              filters: filtersJson,
              onRemove: _removeFilter,
              onClearAll: _clearAllFilters,
            ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                PartnerDiscoveryTab(
                  key: ValueKey('partners_$filtersKey'),
                  filters: filtersJson,
                  searchQuery: _searchQuery,
                  onClearFilters: _clearAllFilters,
                ),
                GendersTab(
                  key: ValueKey('genders_$filtersKey'),
                  filters: filtersJson,
                  searchQuery: _searchQuery,
                ),
                NearbyTab(
                  key: ValueKey('nearby_$filtersKey'),
                  filters: filtersJson,
                  searchQuery: _searchQuery,
                ),
                CityTab(
                  key: ValueKey('city_$filtersKey'),
                  filters: filtersJson,
                  searchQuery: _searchQuery,
                ),
                TopicsTab(
                  key: ValueKey('topics_$filtersKey'),
                  filters: filtersJson,
                  searchQuery: _searchQuery,
                ),
                const VoiceRoomsTab(),
                const WavesTab(),
                if (roomsEnabled) const RoomsDirectoryScreen(),
              ],
            ),
          ),
        ],
      ),
    );
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
                  child: const Text(
                    'Find',
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
                'Finding @$username...',
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
          content: Text(l10n.commonError(e.toString())),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
