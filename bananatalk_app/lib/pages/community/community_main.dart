import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/pages/community/partner_discovery_tab.dart';
import 'package:bananatalk_app/pages/community/nearby_tab.dart';
import 'package:bananatalk_app/pages/community/topics_tab.dart';
import 'package:bananatalk_app/pages/community/voice_rooms/voice_rooms_tab.dart';
import 'package:bananatalk_app/pages/community/waves_tab.dart';
import 'package:bananatalk_app/pages/community/community_filter.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

/// Main Community screen with HelloTalk-style tabs
class CommunityMain extends ConsumerStatefulWidget {
  const CommunityMain({super.key});

  @override
  ConsumerState<CommunityMain> createState() => _CommunityMainState();
}

class _CommunityMainState extends ConsumerState<CommunityMain>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  Map<String, dynamic> _filters = {
    'minAge': 18,
    'maxAge': 100,
    'gender': null,
    'nativeLanguage': null,
    'country': null,
    'topics': <String>[],
    'languageLevel': null,
    'onlineOnly': false,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
                ),
                NearbyTab(
                  key: ValueKey('nearby_${_filters.hashCode}'),
                  filters: _filters,
                  searchQuery: _searchQuery,
                ),
                TopicsTab(
                  key: ValueKey('topics_${_filters.hashCode}'),
                  filters: _filters,
                  searchQuery: _searchQuery,
                ),
                const WavesTab(),
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
          hintText: AppLocalizations.of(context)!.searchCommunity,
          hintStyle: context.bodyMedium.copyWith(color: context.textSecondary),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: context.primaryColor,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
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
                )
              : null,
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
      ),
    );
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
                Text(AppLocalizations.of(context)!.partners),
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
                const Icon(Icons.waving_hand_rounded, size: 20),
                Spacing.hGapSM,
                Text(AppLocalizations.of(context)!.waves),
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
