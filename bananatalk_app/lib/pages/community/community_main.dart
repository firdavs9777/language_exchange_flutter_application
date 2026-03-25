import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/pages/community/partner_discovery_tab.dart';
import 'package:bananatalk_app/pages/community/nearby_tab.dart';
import 'package:bananatalk_app/pages/community/city_tab.dart';
import 'package:bananatalk_app/pages/community/genders_tab.dart';
import 'package:bananatalk_app/pages/community/topics_tab.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_rooms_tab.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/community/community_filter.dart';
import 'package:bananatalk_app/services/user_service.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

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

  static const Map<String, dynamic> _defaultFilters = {
    'minAge': 18,
    'maxAge': 100,
    'gender': null,
    'nativeLanguage': null,
    'learningLanguage': null,
    'country': null,
    'topics': <String>[],
    'languageLevel': null,
    'onlineOnly': false,
    'newUsersOnly': false,
    'prioritizeNearby': false,
  };

  Map<String, dynamic> _filters = Map<String, dynamic>.from(_defaultFilters);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadSavedFilters();
  }

  /// Load saved filters from SharedPreferences
  Future<void> _loadSavedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFilters = prefs.getString(_filtersKey);
      if (savedFilters != null) {
        final decoded = json.decode(savedFilters) as Map<String, dynamic>;
        setState(() {
          _filters = {
            'minAge': decoded['minAge'] ?? 18,
            'maxAge': decoded['maxAge'] ?? 100,
            'gender': decoded['gender'],
            'nativeLanguage': decoded['nativeLanguage'],
            'learningLanguage': decoded['learningLanguage'],
            'country': decoded['country'],
            'topics': List<String>.from(decoded['topics'] ?? []),
            'languageLevel': decoded['languageLevel'],
            'onlineOnly': decoded['onlineOnly'] ?? false,
            'newUsersOnly': decoded['newUsersOnly'] ?? false,
            'prioritizeNearby': decoded['prioritizeNearby'] ?? false,
          };
        });
      } else {
      }
    } catch (e) {
    }
  }

  /// Save filters to SharedPreferences
  Future<void> _saveFilters(Map<String, dynamic> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_filtersKey, json.encode(filters));
    } catch (e) {
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openFilters() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CommunityFilter(
          onApplyFilters: (filters) {
            setState(() {
              _filters = filters;
            });
            // Save filters to SharedPreferences for persistence
            _saveFilters(filters);
          },
          initialFilters: _filters,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(colorScheme),
      body: Column(
        children: [
          // Search bar (shown when searching)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isSearching ? 60 : 0,
            child: _isSearching ? _buildSearchBar(colorScheme) : null,
          ),
          // Tab bar
          _buildTabBar(colorScheme),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                PartnerDiscoveryTab(
                  key: ValueKey('partners_${_filters.hashCode}'),
                  filters: _filters,
                  searchQuery: _searchQuery,
                  onClearFilters: () {
                    setState(() {
                      _filters = Map<String, dynamic>.from(_defaultFilters);
                    });
                    _saveFilters(_filters);
                  },
                ),
                GendersTab(
                  key: ValueKey('genders_${_filters.hashCode}'),
                  filters: _filters,
                  searchQuery: _searchQuery,
                ),
                NearbyTab(
                  key: ValueKey('nearby_${_filters.hashCode}'),
                  filters: _filters,
                  searchQuery: _searchQuery,
                ),
                CityTab(
                  key: ValueKey('city_${_filters.hashCode}'),
                  filters: _filters,
                  searchQuery: _searchQuery,
                ),
                TopicsTab(
                  key: ValueKey('topics_${_filters.hashCode}'),
                  filters: _filters,
                  searchQuery: _searchQuery,
                ),
                const VoiceRoomsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: _isSearching
          ? null
          : Text(
              AppLocalizations.of(context)!.community,
              style: context.displayMedium.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
      actions: [
        // Smart Match button
        IconButton(
          onPressed: () => context.push('/matching'),
          icon: Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
          ),
          tooltip: AppLocalizations.of(context)!.findPartners,
        ),
        // Search button
        IconButton(
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
          icon: Icon(
            _isSearching ? Icons.close_rounded : Icons.search_rounded,
            color: context.textPrimary,
          ),
        ),
        // Filter button
        Container(
          margin: const EdgeInsets.only(right: Spacing.sm),
          decoration: BoxDecoration(
            color: context.primaryColor,
            borderRadius: AppRadius.borderMD,
          ),
          child: IconButton(
            onPressed: _openFilters,
            icon: Icon(
              Icons.tune_rounded,
              color: colorScheme.onPrimary,
            ),
            tooltip: AppLocalizations.of(context)!.filters,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    final isUsernameSearch = _searchQuery.trim().startsWith('@');
    final username = isUsernameSearch && _searchQuery.trim().length > 1
        ? _searchQuery.trim().substring(1)
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
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
          prefixIcon: Icon(
            Icons.search_rounded,
            color: context.primaryColor,
          ),
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
                  child: const Text('Find', style: TextStyle(fontWeight: FontWeight.w600)),
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

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
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
      Navigator.of(context).pop(); // Close loading

      if (user != null) {
        // Clear search
        _searchController.clear();
        setState(() {
          _searchQuery = '';
          _isSearching = false;
        });

        // Navigate to user profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SingleCommunity(community: user),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User @$username not found'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: context.primaryColor,
        unselectedLabelColor: context.textSecondary,
        labelStyle: context.labelLarge.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: context.labelLarge.copyWith(fontWeight: FontWeight.w500),
        indicatorColor: context.primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        labelPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_rounded, size: 20),
                Spacing.hGapSM,
                const Text('All'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wc_rounded, size: 20),
                Spacing.hGapSM,
                const Text('Gender'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.near_me_rounded, size: 20),
                Spacing.hGapSM,
                Text(AppLocalizations.of(context)!.nearby),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_city_rounded, size: 20),
                Spacing.hGapSM,
                const Text('City'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tag_rounded, size: 20),
                Spacing.hGapSM,
                Text(AppLocalizations.of(context)!.topics),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mic_rounded, size: 20),
                Spacing.hGapSM,
                Text(AppLocalizations.of(context)!.voiceRooms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
