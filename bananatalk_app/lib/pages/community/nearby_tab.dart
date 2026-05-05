import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/chat/conversation/chat_conversation_screen.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/widgets/community/user_skeleton.dart';
import 'package:bananatalk_app/services/location_service.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

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
    _initialize();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initialize() async {
    // Load user ID first, then location (userId needed for filtering)
    await _loadUserId();
    await _loadUserLocation();
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
    if (mounted) {
      setState(() {
        _userId = prefs.getString('userId') ?? '';
      });
    }
  }

  Future<void> _loadUserLocation() async {
    if (mounted) setState(() => _locationLoading = true);

    final position = await _locationService.getCurrentPosition();

    if (mounted) {
      setState(() {
        _userPosition = position;
        _locationLoading = false;
        _locationDenied = position == null;
      });
    }

    // Load nearby users once we have location
    if (position != null) {
      _loadNearbyUsers();
    }
  }

  Future<void> _loadNearbyUsers() async {
    if (_userPosition == null) return;

    if (mounted) {
      setState(() {
        _currentOffset = 0;
        _nearbyUsers = [];
        _hasMore = true;
      });
    }

    await _fetchNearbyUsers();
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore || _userPosition == null) return;
    await _fetchNearbyUsers();
  }

  Future<void> _fetchNearbyUsers() async {
    if (_userPosition == null) return;

    if (mounted) setState(() => _isLoadingMore = true);

    try {
      final service = ref.read(communityServiceProvider);

      // Get filter values
      final minAge = widget.filters['minAge'] as int?;
      final maxAge = widget.filters['maxAge'] as int?;
      final gender = widget.filters['gender']?.toString();
      final onlineOnly = widget.filters['onlineOnly'] as bool? ?? false;
      final filterNative = widget.filters['nativeLanguage']?.toString();
      final filterLearning = widget.filters['learningLanguage']?.toString();

      // Default to user's learning language (find native speakers nearby) when no explicit filter
      String? langParam;
      if (filterNative != null && filterNative.isNotEmpty) {
        langParam = filterNative;
      } else if (filterLearning != null && filterLearning.isNotEmpty) {
        langParam = filterLearning;
      } else {
        final me = ref.read(userProvider).valueOrNull;
        if (me != null && me.language_to_learn.isNotEmpty) {
          langParam = me.language_to_learn;
        }
      }

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
        language: langParam,
      );

      if (response.users.isNotEmpty) {
      }

      // Filter out current user from the list
      final filteredUsers = response.users.where((user) => user.id != _userId).toList();

      if (mounted) {
        setState(() {
          _nearbyUsers.addAll(filteredUsers);
          _currentOffset += response.users.length; // Keep original offset for pagination
          _hasMore = response.pagination.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e, stack) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onRadiusChanged(int radius) {
    if (mounted) setState(() => _selectedRadius = radius);
    _loadNearbyUsers();
  }

  Future<void> _onWave(NearbyUser user) async {
    HapticFeedback.mediumImpact();

    // Navigate to chat immediately
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => ChatScreen(
          userId: user.id,
          userName: user.name,
          profilePicture: user.images.isNotEmpty ? user.images.first : null,
        ),
      ),
    );

    // Send wave API + wave sticker message in background
    try {
      final service = ref.read(communityServiceProvider);
      await service.sendWave(targetUserId: user.id);
    } catch (_) {}

    try {
      final messageService = ref.read(messageServiceProvider);
      await messageService.sendMessage(
        receiver: user.id,
        message: '\u{1F44B}',
      );
    } catch (_) {}
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
            child: _buildLocationHeader()
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic),
          ),
          // Radius selector
          SliverToBoxAdapter(
            child: _buildRadiusSelector()
                .animate()
                .fadeIn(duration: 300.ms, delay: 80.ms),
          ),
          // Ad banner
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SmallBannerAdWidget(),
            ),
          ),
          // Skeleton during initial fetch (no users yet)
          if (_nearbyUsers.isEmpty && _isLoadingMore)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 600,
                child: UserGridSkeleton(count: 6, padding: EdgeInsets.fromLTRB(16, 0, 16, 0)),
              ),
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
                    onWave: () => _onWave(user),
                  )
                      .animate()
                      .fadeIn(
                        duration: 350.ms,
                        delay: Duration(milliseconds: (index * 50).clamp(0, 500)),
                      )
                      .scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1.0, 1.0),
                        duration: 350.ms,
                        delay: Duration(milliseconds: (index * 50).clamp(0, 500)),
                        curve: Curves.easeOutBack,
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
            '${AppLocalizations.of(context)!.radius}:',
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
            AppLocalizations.of(context)!.findingYourLocation,
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
          AppPageRoute(
            builder: (_) => SingleCommunity(community: fullProfile),
          ),
        );
      }
    } catch (e) {
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
              AppLocalizations.of(context)!.enableLocationForDistance,
              style: context.displaySmall,
            ),
            Spacing.gapMD,
            Text(
              AppLocalizations.of(context)!.enableLocationDescription,
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
              label: Text(AppLocalizations.of(context)!.enableGps),
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
                AppLocalizations.of(context)!.browseByCityCountry,
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
                  AppLocalizations.of(context)!.peopleNearby,
                  style: context.titleMedium,
                ),
                Text(
                  hasLocation
                      ? AppLocalizations.of(context)!.showingPartnersByDistance
                      : AppLocalizations.of(context)!.enableLocationForResults,
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
                AppLocalizations.of(context)!.enable,
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
              AppLocalizations.of(context)!.noNearbyUsersFound,
              style: context.titleLarge,
            ),
            Spacing.gapSM,
            Text(
              AppLocalizations.of(context)!.tryExpandingSearch,
              textAlign: TextAlign.center,
              style: context.bodySmall,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
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
              AppLocalizations.of(context)!.somethingWentWrong,
              style: context.titleLarge,
            ),
            Spacing.gapXXL,
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(communityProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context)!.retry),
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
    final showOnline = PrivacyUtils.shouldShowOnlineStatus(user);
    final showAge = PrivacyUtils.shouldShowAge(user);
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
                  // Online indicator (respects privacy)
                  if (showOnline && user.isOnline)
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
                              if (showAge && user.age != null)
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
                                      : _getLocationText(context, user),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.waving_hand_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            AppLocalizations.of(context)!.wave,
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

  String _getLanguageFlag(String language) => LanguageFlags.getFlagByName(language);

  /// Get location text with city and country
  String _getLocationText(BuildContext context, Community user) {
    final city = user.location.city;
    final country = user.location.country;

    if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    } else if (city.isNotEmpty) {
      return city;
    } else if (country.isNotEmpty) {
      return country;
    }
    return AppLocalizations.of(context)!.locationNotSet;
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
                  // Online indicator (respect privacy settings)
                  if ((user.privacySettings?.showOnlineStatus ?? true) && user.isOnline)
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
                          if (_getPrivacyLocationText() != null)
                            Text(
                              _getPrivacyLocationText()!,
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.waving_hand_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            AppLocalizations.of(context)!.wave,
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

  String _getLanguageFlag(String language) => LanguageFlags.getFlagByName(language);

  /// Returns location text respecting privacy settings, or null if hidden
  String? _getPrivacyLocationText() {
    final showCity = user.privacySettings?.showCity ?? true;
    final showCountry = user.privacySettings?.showCountryRegion ?? true;

    final city = showCity ? user.city : null;
    final country = showCountry ? user.country : null;

    if (city != null && country != null) return '$city, $country';
    if (city != null) return city;
    if (country != null) return country;
    return null;
  }
}
