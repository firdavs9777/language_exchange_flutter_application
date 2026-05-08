import 'dart:convert';
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
import 'package:bananatalk_app/pages/community/single/single_community_screen.dart';
import 'package:bananatalk_app/pages/community/filter/community_filter_sheet.dart';
import 'package:bananatalk_app/pages/community/filter/filter_state.dart';
import 'package:bananatalk_app/pages/community/main/community_app_bar.dart';
import 'package:bananatalk_app/pages/community/main/community_tab_bar.dart';
import 'package:bananatalk_app/pages/community/main/community_filter_chips.dart';
import 'package:bananatalk_app/services/user_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// Main Community screen with HelloTalk-style tabs
class CommunityMain extends ConsumerStatefulWidget {
  const CommunityMain({super.key});

  @override
  ConsumerState<CommunityMain> createState() => _CommunityMainState();
}

class _CommunityMainState extends ConsumerState<CommunityMain>
    with SingleTickerProviderStateMixin {
  static const String _filtersKey = 'community_filters';

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  FilterState _filters = FilterState.defaults;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadSavedFilters();
  }

  /// Load saved filters from SharedPreferences.
  ///
  /// Uses [FilterState.fromJson] which is backwards-compatible with the old
  /// `Map<String,dynamic>` shape previously written under [_filtersKey].
  Future<void> _loadSavedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFilters = prefs.getString(_filtersKey);
      if (savedFilters != null) {
        final decoded = json.decode(savedFilters) as Map<String, dynamic>;
        setState(() {
          _filters = FilterState.fromJson(decoded);
        });
      }
    } catch (e) {
      // ignore: filter load failure is non-fatal
    }
  }

  /// Save filters to SharedPreferences.
  Future<void> _saveFilters(FilterState filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_filtersKey, json.encode(filters.toJson()));
    } catch (e) {
      // ignore: filter save failure is non-fatal
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommunityFilter(
        onApplyFilters: (filtersMap) {
          final updated = FilterState.fromJson(filtersMap);
          setState(() {
            _filters = updated;
          });
          _saveFilters(updated);
        },
        initialFilters: _filters.toJson(),
      ),
    );
  }

  void _removeFilter(String key) {
    FilterState updated;
    switch (key) {
      case 'age':
        updated = _filters.copyWith(minAge: 18, maxAge: 100);
        break;
      case 'gender':
        updated = FilterState.fromJson({..._filters.toJson(), 'gender': null});
        break;
      case 'nativeLanguage':
        updated = FilterState.fromJson({
          ..._filters.toJson(),
          'nativeLanguage': null,
        });
        break;
      case 'learningLanguage':
        updated = FilterState.fromJson({
          ..._filters.toJson(),
          'learningLanguage': null,
        });
        break;
      case 'country':
        updated = FilterState.fromJson({..._filters.toJson(), 'country': null});
        break;
      case 'languageLevel':
        updated = FilterState.fromJson({
          ..._filters.toJson(),
          'languageLevel': null,
        });
        break;
      case 'onlineOnly':
        updated = _filters.copyWith(onlineOnly: false);
        break;
      case 'newUsersOnly':
        updated = _filters.copyWith(newUsersOnly: false);
        break;
      case 'prioritizeNearby':
        updated = _filters.copyWith(prioritizeNearby: false);
        break;
      default:
        updated = _filters;
    }
    setState(() {
      _filters = updated;
    });
    _saveFilters(_filters);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CommunityAppBar(
        isSearching: _isSearching,
        onSearchToggle: () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _searchController.clear();
              _searchQuery = '';
            }
          });
        },
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
          CommunityTabBar(tabController: _tabController),
          // Active filter chips
          if (CommunityFilterChips.hasActiveFilters(_filters.toJson()))
            CommunityFilterChips(
              filters: _filters.toJson(),
              onRemove: _removeFilter,
              onClearAll: () {
                setState(() {
                  _filters = FilterState.defaults;
                });
                _saveFilters(_filters);
              },
            ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                PartnerDiscoveryTab(
                  key: ValueKey('partners_${_filters.hashCode}'),
                  filters: _filters.toJson(),
                  searchQuery: _searchQuery,
                  onClearFilters: () {
                    setState(() {
                      _filters = FilterState.defaults;
                    });
                    _saveFilters(_filters);
                  },
                ),
                GendersTab(
                  key: ValueKey('genders_${_filters.hashCode}'),
                  filters: _filters.toJson(),
                  searchQuery: _searchQuery,
                ),
                NearbyTab(
                  key: ValueKey('nearby_${_filters.hashCode}'),
                  filters: _filters.toJson(),
                  searchQuery: _searchQuery,
                ),
                CityTab(
                  key: ValueKey('city_${_filters.hashCode}'),
                  filters: _filters.toJson(),
                  searchQuery: _searchQuery,
                ),
                TopicsTab(
                  key: ValueKey('topics_${_filters.hashCode}'),
                  filters: _filters.toJson(),
                  searchQuery: _searchQuery,
                ),
                const VoiceRoomsTab(),
                const WavesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    final isUsernameSearch = _searchQuery.trim().startsWith('@');
    final username = isUsernameSearch && _searchQuery.trim().length > 1
        ? _searchQuery.trim().substring(1)
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
          hintText: 'Search or type @username',
          hintStyle: context.bodyMedium.copyWith(color: context.textSecondary),
          prefixIcon: Icon(Icons.search_rounded, color: context.primaryColor),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Find user button when searching with @
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
              // Clear button
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: context.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
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
          // Auto-strip leading @ when pasting a username
          if (value.startsWith('@') &&
              value.length > 1 &&
              !value.contains(' ')) {
            final stripped = value.substring(1);
            _searchController.text = stripped;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: stripped.length),
            );
            setState(() {
              _searchQuery = stripped;
            });
            // Auto-search the username
            _findUserByUsername(stripped);
            return;
          }
          setState(() {
            _searchQuery = value;
          });
        },
        onSubmitted: (value) {
          if (isUsernameSearch && username.isNotEmpty) {
            _findUserByUsername(username);
          }
        },
      ),
    );
  }

  /// Find user by username and navigate to their profile
  Future<void> _findUserByUsername(String username) async {
    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);

    // Use rootNavigator for dialog so it doesn't conflict with page navigation
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    // Show loading dialog on root navigator
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
      final userService = UserService();
      final user = await userService.getUserByUsername(username);

      if (!mounted) return;

      // Close loading dialog on root navigator
      rootNavigator.pop();

      if (user != null) {
        // Clear search
        _searchController.clear();
        setState(() {
          _searchQuery = '';
          _isSearching = false;
        });

        // Navigate to user profile
        Navigator.of(
          context,
        ).push(AppPageRoute(builder: (_) => SingleCommunity(community: user)));
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('User @$username not found'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog safely on root navigator
      try {
        rootNavigator.pop();
      } catch (_) {}

      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
