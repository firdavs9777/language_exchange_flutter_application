import 'package:bananatalk_app/pages/community/community_card.dart';
import 'package:bananatalk_app/pages/community/community_filter.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/utils/theme_extensions.dart';

class CommunityMain extends ConsumerStatefulWidget {
  const CommunityMain({Key? key}) : super(key: key);

  @override
  _CommunityMainState createState() => _CommunityMainState();
}

class _CommunityMainState extends ConsumerState<CommunityMain>
    with TickerProviderStateMixin {
  late String userId = '';
  String _searchQuery = '';
  String _selectedTab = 'All'; // All, Nearby, Serious Learners, etc.
  Map<String, dynamic> _filters = {
    'minAge': 18,
    'maxAge': 100,
    'gender': null,
    'nativeLanguage': null,
  };

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeUserId();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
    });
  }

  Future<void> _refresh() async {
    ref.refresh(communityProvider);
  }

  Future<void> _filterSearch() async {
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
            position:
                Tween<Offset>(
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

  Future<void> redirect(String id) async {
    try {
      final community = await ref
          .read(communityServiceProvider)
          .getSingleCommunity(id: id);

      if (community == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User not found')));
        }
        return;
      }

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SingleCommunity(community: community),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.3, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading community: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Community> _getFilteredCommunities(
    List<Community> communities,
    String? myNativeLanguage,
    String? myLanguageToLearn,
    Set<String> blockedUserIds,
  ) {
    return communities.where((community) {
      // Exclude current user
      if (community.id == userId) return false;

      // Exclude blocked users
      if (blockedUserIds.contains(community.id)) return false;

      // Apply age filter
      if (_filters['minAge'] != null || _filters['maxAge'] != null) {
        try {
          final birthYear = int.tryParse(community.birth_year);
          final birthMonth = int.tryParse(community.birth_month);
          final birthDay = int.tryParse(community.birth_day);

          if (birthYear != null) {
            final today = DateTime.now();
            int age = today.year - birthYear;

            // Adjust age if birthday hasn't occurred this year
            if (birthMonth != null && birthDay != null) {
              final thisYearBirthday = DateTime(
                today.year,
                birthMonth,
                birthDay,
              );
              if (today.isBefore(thisYearBirthday)) {
                age--;
              }
            }

            final minAge = _filters['minAge'] as int?;
            final maxAge = _filters['maxAge'] as int?;

            if (minAge != null && age < minAge) return false;
            if (maxAge != null && age > maxAge) return false;
          }
        } catch (e) {
          // If age calculation fails, skip age filtering for this community
        }
      }

      // Check if native language filter is applied
      final hasNativeLanguageFilter =
          _filters['nativeLanguage'] != null &&
          _filters['nativeLanguage'].toString().isNotEmpty;

      // Language matching logic
      bool isLanguageMatch = false;

      if (hasNativeLanguageFilter) {
        // User explicitly filtered by native language
        final filterLang = _filters['nativeLanguage']
            .toString()
            .trim();
        final communityLang = (community.native_language ?? '')
            .trim();

        if (communityLang.isEmpty) return false; // Skip if no language set

        // Compare case-insensitively but also check exact match
        isLanguageMatch = filterLang.toLowerCase() == communityLang.toLowerCase() ||
            filterLang == communityLang;
      } else {
        // Language exchange matching
        final communityNative = (community.native_language ?? '')
            .toLowerCase()
            .trim();
        final communityLearning = (community.language_to_learn ?? '')
            .toLowerCase()
            .trim();

        // Skip if community has no languages set
        if (communityNative.isEmpty && communityLearning.isEmpty) return false;

        if (myLanguageToLearn != null && myLanguageToLearn.isNotEmpty) {
          // They speak what I'm learning
          if (communityNative == myLanguageToLearn.toLowerCase().trim()) {
            isLanguageMatch = true;
          }
        }

        if (!isLanguageMatch &&
            myNativeLanguage != null &&
            myNativeLanguage.isNotEmpty) {
          // They're learning what I speak
          if (communityLearning == myNativeLanguage.toLowerCase().trim()) {
            isLanguageMatch = true;
          }
        }
      }

      if (!isLanguageMatch) return false;

      // Apply gender filter
      if (_filters['gender'] != null &&
          _filters['gender'].toString().isNotEmpty) {
        final filterGender = _filters['gender'].toString().toLowerCase().trim();
        final communityGender = (community.gender ?? '').toLowerCase().trim();

        if (filterGender.isEmpty || communityGender.isEmpty) {
          return false;
        }
        
        if (filterGender != communityGender) return false;
      }

      // Apply search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return (community.name ?? '').toLowerCase().contains(query) ||
            (community.bio ?? '').toLowerCase().contains(query) ||
            (community.native_language ?? '').toLowerCase().contains(query) ||
            (community.language_to_learn ?? '').toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final communityAsyncValue = ref.watch(communityProvider);
    final currentUserAsync = ref.watch(userProvider);

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterTabs(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: colorScheme.primary,
              child: currentUserAsync.when(
                data: (currentUser) {
                  return communityAsyncValue.when(
                    data: (communities) {
                      // Get blocked user IDs
                      final blockedUserIdsAsync = ref.watch(
                        blockedUserIdsProvider,
                      );
                      final blockedUserIds =
                          blockedUserIdsAsync.value ?? <String>{};

                      return _buildCommunityList(
                        communities,
                        currentUser.native_language,
                        currentUser.language_to_learn,
                        blockedUserIds,
                      );
                    },
                    loading: () => _buildLoadingState(),
                    error: (error, stackTrace) => _buildErrorState(error),
                  );
                },
                loading: () => _buildLoadingState(),
                error: (error, stackTrace) => _buildErrorState(error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Find Partners',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: context.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Refresh action
            _refresh();
          },
          icon: Icon(Icons.refresh, color: context.textPrimary),
          tooltip: 'Refresh',
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _filterSearch,
            icon: Icon(Icons.tune, color: colorScheme.onPrimary),
            tooltip: 'Filter & Search',
          ),
        ),
      ],
      elevation: 0,
    );
  }

  Widget _buildFilterTabs() {
    final tabs = ['All', 'Nearby', 'Active Now', 'New Users'];

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = _selectedTab == tab;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTab = tab;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withOpacity(0.15)
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.primary
                        : context.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search by name, language, or interests...',
          hintStyle: TextStyle(color: context.textSecondary, fontSize: 16),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.search, color: colorScheme.onPrimary, size: 20),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: TextStyle(fontSize: 16, color: context.textPrimary),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCommunityList(
    List<Community> communities,
    String? myNativeLanguage,
    String? myLanguageToLearn,
    Set<String> blockedUserIds,
  ) {
    final filteredCommunities = _getFilteredCommunities(
      communities,
      myNativeLanguage,
      myLanguageToLearn,
      blockedUserIds,
    );

    if (filteredCommunities.isEmpty) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredCommunities.length,
          itemBuilder: (context, index) {
            final community = filteredCommunities[index];
            final isFollowing = community.followers.contains(userId);
            return CommunityCard(
              community: community,
              onTap: () => redirect(community.id),
              animationDelay: index * 100,
              isFollowing: isFollowing,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Finding language exchange partners...',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.error.withOpacity(0.12),
                    colorScheme.errorContainer.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load communities: $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.people_outline,
                      size: 50,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No matching communities'
                        : 'No language exchange matches found',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Try adjusting your search or filters'
                        : 'We\'ll show you people who speak the language you\'re learning, or who are learning your native language',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Search'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
