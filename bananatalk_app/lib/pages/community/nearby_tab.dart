import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/widgets/community/compact_user_tile.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/services/location_service.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';

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
  Map<String, double> _userDistances = {}; // Cache distances

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadUserLocation();
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
  }

  /// Calculate distance for a user (with caching)
  double? _getDistanceForUser(Community community) {
    if (_userPosition == null) return null;

    // Check if user has valid coordinates
    final coords = community.location.coordinates;
    if (coords.length < 2) return null;

    // GeoJSON format: [longitude, latitude]
    final lon = coords[0];
    final lat = coords[1];

    if (lat == 0 && lon == 0) return null;

    // Check cache
    if (_userDistances.containsKey(community.id)) {
      return _userDistances[community.id];
    }

    // Calculate distance
    final distance = LocationService.calculateDistance(
      lat1: _userPosition!.latitude,
      lon1: _userPosition!.longitude,
      lat2: lat,
      lon2: lon,
    );

    _userDistances[community.id] = distance;
    return distance;
  }

  List<Community> _getFilteredCommunities(
    List<Community> communities,
    Set<String> blockedUserIds,
  ) {
    var filtered = communities.where((community) {
      if (community.id == _userId) return false;
      if (blockedUserIds.contains(community.id)) return false;

      // Apply age filter
      if (widget.filters['minAge'] != null || widget.filters['maxAge'] != null) {
        final age = community.age;
        if (age != null) {
          final minAge = widget.filters['minAge'] as int?;
          final maxAge = widget.filters['maxAge'] as int?;
          if (minAge != null && age < minAge) return false;
          if (maxAge != null && age > maxAge) return false;
        }
      }

      // Apply gender filter
      if (widget.filters['gender'] != null &&
          widget.filters['gender'].toString().isNotEmpty) {
        final filterGender = widget.filters['gender'].toString().toLowerCase();
        if (filterGender != community.gender.toLowerCase()) return false;
      }

      // Apply online only filter
      if (widget.filters['onlineOnly'] == true && !community.isOnline) {
        return false;
      }

      // Apply country filter
      if (widget.filters['country'] != null &&
          widget.filters['country'].toString().isNotEmpty) {
        final filterCountry = widget.filters['country'].toString().toLowerCase();
        final userCountry = community.location.country.toLowerCase();
        if (!userCountry.contains(filterCountry) && !filterCountry.contains(userCountry)) {
          return false;
        }
      }

      // Apply distance filter (if user has location)
      if (_userPosition != null && widget.filters['maxDistance'] != null) {
        final distance = _getDistanceForUser(community);
        final maxDistance = widget.filters['maxDistance'] as double;
        if (distance != null && distance > maxDistance) return false;
      }

      // Apply search query
      if (widget.searchQuery.isNotEmpty) {
        final query = widget.searchQuery.toLowerCase();
        return community.name.toLowerCase().contains(query) ||
            community.bio.toLowerCase().contains(query) ||
            community.location.city.toLowerCase().contains(query);
      }

      return true;
    }).toList();

    // Sort by actual distance (nearest first)
    if (_userPosition != null) {
      filtered.sort((a, b) {
        final distA = _getDistanceForUser(a);
        final distB = _getDistanceForUser(b);

        // Users with distance come first
        if (distA == null && distB == null) return 0;
        if (distA == null) return 1;
        if (distB == null) return -1;

        return distA.compareTo(distB);
      });
    } else {
      // Fallback: sort by has location
      filtered.sort((a, b) {
        final aHasLocation = a.location.city.isNotEmpty;
        final bHasLocation = b.location.city.isNotEmpty;
        if (aHasLocation && !bHasLocation) return -1;
        if (!aHasLocation && bHasLocation) return 1;
        return 0;
      });
    }

    return filtered;
  }

  void _viewProfile(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SingleCommunity(community: community),
      ),
    );
  }

  void _onWave(String userName) {
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

  @override
  Widget build(BuildContext context) {
    final communityAsync = ref.watch(communityProvider);
    final blockedUserIdsAsync = ref.watch(blockedUserIdsProvider);
    final userAsync = ref.watch(userProvider);
    final isVip = userAsync.valueOrNull?.isVip ?? false;

    // Show VIP upgrade prompt for non-VIP users
    if (!isVip) {
      return _buildVipUpgradePrompt();
    }

    // Show location permission request if denied
    if (_locationDenied && !_locationLoading) {
      return _buildLocationPermissionRequest();
    }

    return communityAsync.when(
      data: (communities) {
        final blockedUserIds = blockedUserIdsAsync.value ?? <String>{};
        final filteredCommunities =
            _getFilteredCommunities(communities, blockedUserIds);

        if (filteredCommunities.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            _userDistances.clear(); // Clear distance cache
            await _loadUserLocation();
            ref.invalidate(communityProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Location header
              SliverToBoxAdapter(
                child: _buildLocationHeader(),
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
                      final user = filteredCommunities[index];
                      final distance = _getDistanceForUser(user);
                      return _NearbyUserCard(
                        user: user,
                        distance: distance,
                        onTap: () => _viewProfile(user),
                        onWave: () => _onWave(user.name),
                      );
                    },
                    childCount: filteredCommunities.length,
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
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
      ),
      error: (e, s) => _buildError(e),
    );
  }

  Widget _buildLocationPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 40,
                color: Color(0xFF00BFA5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Enable Location for Distance',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enable GPS to see exact distance to partners. You can still browse by city/country without GPS.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
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
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Skip GPS - show users sorted by location from profile
                setState(() {
                  _locationDenied = false;
                  _locationLoading = false;
                });
              },
              child: const Text(
                'Browse by City/Country',
                style: TextStyle(
                  color: Color(0xFF00BFA5),
                  fontWeight: FontWeight.w600,
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00BFA5).withOpacity(0.1),
            const Color(0xFF00ACC1).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00BFA5).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _locationLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00BFA5),
                    ),
                  )
                : Icon(
                    hasLocation ? Icons.near_me_rounded : Icons.location_off_rounded,
                    color: const Color(0xFF00BFA5),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'People Nearby',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  hasLocation
                      ? 'Showing partners sorted by distance'
                      : 'Enable location for distance-based results',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!hasLocation && !_locationLoading)
            TextButton(
              onPressed: () async {
                await _loadUserLocation();
              },
              child: const Text(
                'Enable',
                style: TextStyle(
                  color: Color(0xFF00BFA5),
                  fontWeight: FontWeight.w600,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No nearby users found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try expanding your search or check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(communityProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // VIP icon with golden glow
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Find Nearby Partners',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Discover language partners near you!\nSee who\'s just around the corner.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Benefits list
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  _buildVipBenefitRow(Icons.near_me_rounded, 'See exact distance to partners'),
                  const SizedBox(height: 12),
                  _buildVipBenefitRow(Icons.sort, 'Partners sorted by proximity'),
                  const SizedBox(height: 12),
                  _buildVipBenefitRow(Icons.location_city, 'Find partners in your city'),
                ],
              ),
            ),
            const SizedBox(height: 32),
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
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Upgrade to VIP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Lock indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'VIP Feature',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFFA500),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Icon(
          Icons.check_circle,
          color: Color(0xFF4CAF50),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
              ),
              child: Row(
                children: [
                  // Language flags
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[200]!),
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
