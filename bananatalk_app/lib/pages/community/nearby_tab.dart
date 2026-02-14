import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/services/location_service.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Nearby Tab - Grid view of nearby users with real distance calculation
class NearbyTab extends ConsumerStatefulWidget {
  final Map<String, dynamic> filters;
  final String searchQuery;

  const NearbyTab({
    super.key,
    required this.filters,
    required this.searchQuery,
  });

  @override
  ConsumerState<NearbyTab> createState() => _NearbyTabState();
}

class _NearbyTabState extends ConsumerState<NearbyTab> {
  String _userId = '';
  Position? _userPosition;
  bool _locationLoading = true;
  bool _locationDenied = false;
  final LocationService _locationService = LocationService();
  int _selectedRadius = 50; // Default 50km radius
  bool _isLoadingMore = false;
  int _currentOffset = 0;
  List<NearbyUser> _nearbyUsers = [];
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadUserLocation();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId') ?? '';
    });
  }

  Future<void> _loadUserLocation() async {
    setState(() => _locationLoading = true);

    final position = await _locationService.getCurrentPosition();

    setState(() {
      _userPosition = position;
      _locationLoading = false;
      _locationDenied = position == null;
    });

    // Load nearby users once we have location
    if (position != null) {
      _loadNearbyUsers();
    }
  }

  Future<void> _loadNearbyUsers() async {
    if (_userPosition == null) return;

    setState(() {
      _currentOffset = 0;
      _nearbyUsers = [];
      _hasMore = true;
    });

    await _fetchNearbyUsers();
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore || _userPosition == null) return;
    await _fetchNearbyUsers();
  }

  Future<void> _fetchNearbyUsers() async {
    if (_userPosition == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final service = ref.read(communityServiceProvider);

      // Get filter values
      final minAge = widget.filters['minAge'] as int?;
      final maxAge = widget.filters['maxAge'] as int?;
      final gender = widget.filters['gender']?.toString();
      final onlineOnly = widget.filters['onlineOnly'] as bool? ?? false;

      final response = await service.getNearbyUsers(
        latitude: _userPosition!.latitude,
        longitude: _userPosition!.longitude,
        radius: _selectedRadius,
        limit: 20,
        offset: _currentOffset,
        minAge: (minAge != null && minAge > 18) ? minAge : null,
        maxAge: (maxAge != null && maxAge < 100) ? maxAge : null,
        gender: (gender != null && gender.isNotEmpty) ? gender.toLowerCase() : null,
        onlineOnly: onlineOnly ? true : null,
      );

      debugPrint('📍 Nearby users response for ${_selectedRadius}km radius:');
      debugPrint('   Users count: ${response.users.length}');
      debugPrint('   Has more: ${response.pagination.hasMore}');
      if (response.users.isNotEmpty) {
        debugPrint('   First user distance: ${response.users.first.distance}km');
        debugPrint('   Last user distance: ${response.users.last.distance}km');
      }

      setState(() {
        _nearbyUsers.addAll(response.users);
        _currentOffset += response.users.length;
        _hasMore = response.pagination.hasMore;
        _isLoadingMore = false;
      });
    } catch (e, stack) {
      setState(() => _isLoadingMore = false);
      debugPrint('❌ Error loading nearby users: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  void _onRadiusChanged(int radius) {
    setState(() => _selectedRadius = radius);
    _loadNearbyUsers();
  }

  Future<void> _onWave(String userId, String userName) async {
    try {
      final service = ref.read(communityServiceProvider);
      await service.sendWave(targetUserId: userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.waving_hand, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Waved to $userName!'),
              ],
            ),
            backgroundColor: const Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending wave: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(e.toString().replaceAll('Exception: ', ''))),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void didUpdateWidget(NearbyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when filters change
    if (oldWidget.filters != widget.filters && _userPosition != null) {
      _loadNearbyUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final isVip = userAsync.valueOrNull?.isVip ?? false;

    // Show VIP upgrade prompt for non-VIP users
    if (!isVip) {
      return _buildVipUpgradePrompt();
    }

    // Show loading while getting location
    if (_locationLoading) {
      return _buildLoadingState();
    }

    // Show location permission request if denied
    if (_locationDenied) {
      return _buildLocationPermissionRequest();
    }

    // Show empty state if no users
    if (_nearbyUsers.isEmpty && !_isLoadingMore) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNearbyUsers,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Location header with radius selector
          SliverToBoxAdapter(
            child: _buildLocationHeader(),
          ),
          // Radius selector
          SliverToBoxAdapter(
            child: _buildRadiusSelector(),
          ),
          // Grid of users
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = _nearbyUsers[index];
                  return _NearbyUserCardFromApi(
                    user: user,
                    onTap: () => _viewNearbyUserProfile(user),
                    onWave: () => _onWave(user.id, user.name),
                  );
                },
                childCount: _nearbyUsers.length,
              ),
            ),
          ),
          // Loading more indicator
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
                ),
              ),
            ),
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
      child: Row(
        children: [
          Icon(Icons.radar, color: context.primaryColor, size: 20),
          Spacing.hGapSM,
          Text(
            'Radius:',
            style: context.labelLarge,
          ),
          Spacing.hGapMD,
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [5, 10, 25, 50, 100, 200].map((radius) {
                  final isSelected = _selectedRadius == radius;
                  return Padding(
                    padding: const EdgeInsets.only(right: Spacing.sm),
                    child: ChoiceChip(
                      label: Text('${radius}km'),
                      selected: isSelected,
                      onSelected: (_) => _onRadiusChanged(radius),
                      selectedColor: context.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? context.textOnPrimary : context.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: context.primaryColor),
          Spacing.gapLG,
          Text(
            'Finding your location...',
            style: context.bodyMedium.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  void _viewNearbyUserProfile(NearbyUser user) async {
    // Fetch full profile and navigate
    try {
      final service = ref.read(communityServiceProvider);
      final fullProfile = await service.getSingleCommunity(id: user.id);
      if (fullProfile != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SingleCommunity(community: fullProfile),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Widget _buildLocationPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                size: 40,
                color: context.primaryColor,
              ),
            ),
            Spacing.gapXXL,
            Text(
              'Enable Location for Distance',
              style: context.displaySmall,
            ),
            Spacing.gapMD,
            Text(
              'Enable GPS to see exact distance to partners. You can still browse by city/country without GPS.',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
            Spacing.gapXXL,
            Spacing.gapSM,
            ElevatedButton.icon(
              onPressed: () async {
                final granted = await _locationService.checkAndRequestPermission();
                if (granted) {
                  await _loadUserLocation();
                } else {
                  // Open settings
                  await _locationService.openSettings();
                }
              },
              icon: const Icon(Icons.near_me_rounded),
              label: const Text('Enable GPS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: context.textOnPrimary,
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xxxl, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMD,
                ),
              ),
            ),
            Spacing.gapLG,
            TextButton(
              onPressed: () {
                // Skip GPS - show users sorted by location from profile
                setState(() {
                  _locationDenied = false;
                  _locationLoading = false;
                });
              },
              child: Text(
                'Browse by City/Country',
                style: context.labelLarge.copyWith(
                  color: context.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    final hasLocation = _userPosition != null;

    return Container(
      margin: const EdgeInsets.all(Spacing.lg),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withOpacity(0.1),
            AppColors.info.withOpacity(0.05),
          ],
        ),
        borderRadius: AppRadius.borderLG,
        border: Border.all(
          color: context.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.15),
              borderRadius: AppRadius.borderMD,
            ),
            child: _locationLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.primaryColor,
                    ),
                  )
                : Icon(
                    hasLocation ? Icons.near_me_rounded : Icons.location_off_rounded,
                    color: context.primaryColor,
                  ),
          ),
          Spacing.hGapLG,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'People Nearby',
                  style: context.titleMedium,
                ),
                Text(
                  hasLocation
                      ? 'Showing partners sorted by distance'
                      : 'Enable location for distance-based results',
                  style: context.caption,
                ),
              ],
            ),
          ),
          if (!hasLocation && !_locationLoading)
            TextButton(
              onPressed: () async {
                await _loadUserLocation();
              },
              child: Text(
                'Enable',
                style: context.labelLarge.copyWith(
                  color: context.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 64,
              color: context.textMuted,
            ),
            Spacing.gapLG,
            Text(
              'No nearby users found',
              style: context.titleLarge,
            ),
            Spacing.gapSM,
            Text(
              'Try expanding your search or check back later.',
              textAlign: TextAlign.center,
              style: context.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: context.textMuted,
            ),
            Spacing.gapLG,
            Text(
              'Something went wrong',
              style: context.titleLarge,
            ),
            Spacing.gapXXL,
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(communityProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: context.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVipUpgradePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // VIP icon with golden glow
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.location_on_rounded,
                size: 48,
                color: context.textOnPrimary,
              ),
            ),
            Spacing.gapXXL,
            Spacing.gapSM,
            Text(
              'Find Nearby Partners',
              style: context.displayMedium,
            ),
            Spacing.gapMD,
            Text(
              'Discover language partners near you!\nSee who\'s just around the corner.',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
            Spacing.gapXXL,
            Spacing.gapSM,
            // Benefits list
            Container(
              padding: const EdgeInsets.all(Spacing.xl),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: AppRadius.borderLG,
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  _buildVipBenefitRow(Icons.near_me_rounded, 'See exact distance to partners'),
                  Spacing.gapMD,
                  _buildVipBenefitRow(Icons.sort, 'Partners sorted by proximity'),
                  Spacing.gapMD,
                  _buildVipBenefitRow(Icons.location_city, 'Find partners in your city'),
                ],
              ),
            ),
            Spacing.gapXXL,
            Spacing.gapSM,
            // Upgrade button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VipPlansScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: context.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMD,
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium, size: 20),
                    Spacing.hGapSM,
                    Text(
                      'Upgrade to VIP',
                      style: context.titleMedium.copyWith(color: context.textOnPrimary),
                    ),
                  ],
                ),
              ),
            ),
            Spacing.gapLG,
            // Lock indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 14, color: context.textMuted),
                Spacing.hGapXS,
                Text(
                  'VIP Feature',
                  style: context.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVipBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFFA500),
            size: 18,
          ),
        ),
        Spacing.hGapMD,
        Expanded(
          child: Text(
            text,
            style: context.labelLarge,
          ),
        ),
        const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 18,
        ),
      ],
    );
  }
}

class _NearbyUserCard extends StatelessWidget {
  final Community user;
  final double? distance;
  final VoidCallback? onTap;
  final VoidCallback? onWave;

  const _NearbyUserCard({
    required this.user,
    this.distance,
    this.onTap,
    this.onWave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.borderLG,
          boxShadow: AppShadows.md,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section - takes most of the space
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Profile image - uses model's profileImageUrl getter
                  user.profileImageUrl != null
                      ? CachedImageWidget(
                          imageUrl: user.profileImageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorWidget: _buildFallbackAvatar(),
                        )
                      : _buildFallbackAvatar(),
                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Online indicator
                  if (user.isOnline)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // VIP badge if applicable
                  if (user.isVip)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, size: 10, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'VIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Name and info overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name and age
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user.age != null)
                                Text(
                                  ', ${user.age}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          // Distance or location
                          Row(
                            children: [
                              Icon(
                                distance != null ? Icons.near_me_rounded : Icons.location_on_rounded,
                                size: 11,
                                color: distance != null ? const Color(0xFF00E5CC) : Colors.white60,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  distance != null
                                      ? LocationService.formatDistance(distance!)
                                      : _getLocationText(user),
                                  style: TextStyle(
                                    color: distance != null ? const Color(0xFF00E5CC) : Colors.white60,
                                    fontSize: 11,
                                    fontWeight: distance != null ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom section with languages and action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Spacing.sm),
              decoration: BoxDecoration(
                color: context.containerColor,
              ),
              child: Row(
                children: [
                  // Language flags
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: AppRadius.borderXS,
                      border: Border.all(color: context.dividerColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getLanguageFlag(user.native_language),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 8,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _getLanguageFlag(user.language_to_learn),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Wave button
                  GestureDetector(
                    onTap: onWave,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.waving_hand_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'Wave',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getLanguageFlag(String language) {
    if (language.isEmpty) return LanguageFlags.getFlag('');
    final langLower = language.toLowerCase().trim();
    final nameToCodeMap = {
      'english': 'en',
      'korean': 'ko',
      'japanese': 'ja',
      'chinese': 'zh',
      'spanish': 'es',
      'french': 'fr',
      'german': 'de',
      'uzbek': 'uz',
    };
    if (nameToCodeMap.containsKey(langLower)) {
      return LanguageFlags.getFlag(nameToCodeMap[langLower]!);
    }
    if (langLower.length == 2) {
      return LanguageFlags.getFlag(langLower);
    }
    return LanguageFlags.getFlag('');
  }

  /// Get location text with city and country
  String _getLocationText(Community user) {
    final city = user.location.city;
    final country = user.location.country;

    if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    } else if (city.isNotEmpty) {
      return city;
    } else if (country.isNotEmpty) {
      return country;
    }
    return 'Location not set';
  }
}

/// Card widget for NearbyUser from API (with distance from server)
class _NearbyUserCardFromApi extends StatelessWidget {
  final NearbyUser user;
  final VoidCallback? onTap;
  final VoidCallback? onWave;

  const _NearbyUserCardFromApi({
    required this.user,
    this.onTap,
    this.onWave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.borderLG,
          boxShadow: AppShadows.md,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Profile image
                  user.images.isNotEmpty
                      ? CachedImageWidget(
                          imageUrl: user.images.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorWidget: _buildFallbackAvatar(),
                        )
                      : _buildFallbackAvatar(),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Online indicator
                  if (user.isOnline)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  // Distance badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            _formatDistance(user.distance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Name overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user.city != null || user.country != null)
                            Text(
                              '${user.city ?? ''}${user.city != null && user.country != null ? ', ' : ''}${user.country ?? ''}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom section - languages and wave button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Spacing.sm),
              decoration: BoxDecoration(
                color: context.containerColor,
                border: Border(top: BorderSide(color: context.dividerColor)),
              ),
              child: Row(
                children: [
                  // Language flags
                  if (user.nativeLanguage != null || user.languageToLearn != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: AppRadius.borderXS,
                        border: Border.all(color: context.dividerColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getLanguageFlag(user.nativeLanguage ?? ''),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(Icons.arrow_forward_rounded, size: 8, color: Colors.grey),
                          ),
                          Text(
                            _getLanguageFlag(user.languageToLearn ?? ''),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Wave button
                  GestureDetector(
                    onTap: onWave,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.waving_hand_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'Wave',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceKm.round()}km';
    }
  }

  String _getLanguageFlag(String language) {
    if (language.isEmpty) return LanguageFlags.getFlag('');
    final langLower = language.toLowerCase().trim();
    final nameToCodeMap = {
      'english': 'en', 'spanish': 'es', 'french': 'fr', 'german': 'de',
      'italian': 'it', 'portuguese': 'pt', 'russian': 'ru', 'chinese': 'zh',
      'japanese': 'ja', 'korean': 'ko', 'arabic': 'ar',
    };
    return LanguageFlags.getFlag(nameToCodeMap[langLower] ?? langLower);
  }
}
