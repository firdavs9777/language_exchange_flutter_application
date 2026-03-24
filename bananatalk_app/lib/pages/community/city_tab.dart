import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/widgets/community/partner_list_item.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/pages/vip/vip_status_screen.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Country pin on the map
class _CountryPin {
  final String name;
  final String flag;
  final LatLng position;
  int userCount;

  _CountryPin({
    required this.name,
    required this.flag,
    required this.position,
    this.userCount = 0,
  });
}

/// City Tab — interactive map with country markers showing user counts
class CityTab extends ConsumerStatefulWidget {
  final Map<String, dynamic> filters;
  final String searchQuery;

  const CityTab({
    super.key,
    required this.filters,
    required this.searchQuery,
  });

  @override
  ConsumerState<CityTab> createState() => _CityTabState();
}

class _CityTabState extends ConsumerState<CityTab> {
  String _userId = '';
  String _citySearch = '';
  String? _selectedCountry;
  final TextEditingController _citySearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MapController _mapController = MapController();

  bool _isLoadingCounts = true;

  // Users for selected country/city
  List<Community> _users = [];
  bool _isLoadingUsers = false;
  bool _hasMore = true;
  int _currentPage = 1;

  // Country pins with coordinates
  final List<_CountryPin> _countryPins = [
    _CountryPin(name: 'South Korea', flag: '🇰🇷', position: const LatLng(37.5665, 126.9780)),
    _CountryPin(name: 'Japan', flag: '🇯🇵', position: const LatLng(35.6762, 139.6503)),
    _CountryPin(name: 'United States', flag: '🇺🇸', position: const LatLng(39.8283, -98.5795)),
    _CountryPin(name: 'China', flag: '🇨🇳', position: const LatLng(35.8617, 104.1954)),
    _CountryPin(name: 'United Kingdom', flag: '🇬🇧', position: const LatLng(51.5074, -0.1278)),
    _CountryPin(name: 'Germany', flag: '🇩🇪', position: const LatLng(51.1657, 10.4515)),
    _CountryPin(name: 'France', flag: '🇫🇷', position: const LatLng(46.2276, 2.2137)),
    _CountryPin(name: 'Spain', flag: '🇪🇸', position: const LatLng(40.4637, -3.7492)),
    _CountryPin(name: 'Brazil', flag: '🇧🇷', position: const LatLng(-14.2350, -51.9253)),
    _CountryPin(name: 'India', flag: '🇮🇳', position: const LatLng(20.5937, 78.9629)),
    _CountryPin(name: 'Russia', flag: '🇷🇺', position: const LatLng(61.5240, 105.3188)),
    _CountryPin(name: 'Turkey', flag: '🇹🇷', position: const LatLng(38.9637, 35.2433)),
    _CountryPin(name: 'Indonesia', flag: '🇮🇩', position: const LatLng(-0.7893, 113.9213)),
    _CountryPin(name: 'Thailand', flag: '🇹🇭', position: const LatLng(15.8700, 100.9925)),
    _CountryPin(name: 'Vietnam', flag: '🇻🇳', position: const LatLng(14.0583, 108.2772)),
    _CountryPin(name: 'Philippines', flag: '🇵🇭', position: const LatLng(12.8797, 121.7740)),
    _CountryPin(name: 'Mexico', flag: '🇲🇽', position: const LatLng(23.6345, -102.5528)),
    _CountryPin(name: 'Italy', flag: '🇮🇹', position: const LatLng(41.8719, 12.5674)),
    _CountryPin(name: 'Canada', flag: '🇨🇦', position: const LatLng(56.1304, -106.3468)),
    _CountryPin(name: 'Australia', flag: '🇦🇺', position: const LatLng(-25.2744, 133.7751)),
    _CountryPin(name: 'Uzbekistan', flag: '🇺🇿', position: const LatLng(41.3775, 64.5853)),
    _CountryPin(name: 'Taiwan', flag: '🇹🇼', position: const LatLng(23.6978, 120.9605)),
    _CountryPin(name: 'Malaysia', flag: '🇲🇾', position: const LatLng(4.2105, 101.9758)),
    _CountryPin(name: 'Saudi Arabia', flag: '🇸🇦', position: const LatLng(23.8859, 45.0792)),
    _CountryPin(name: 'Egypt', flag: '🇪🇬', position: const LatLng(26.8206, 30.8025)),
    _CountryPin(name: 'Argentina', flag: '🇦🇷', position: const LatLng(-38.4161, -63.6167)),
    _CountryPin(name: 'Colombia', flag: '🇨🇴', position: const LatLng(4.5709, -74.2973)),
    _CountryPin(name: 'Nigeria', flag: '🇳🇬', position: const LatLng(9.0820, 8.6753)),
    _CountryPin(name: 'Pakistan', flag: '🇵🇰', position: const LatLng(30.3753, 69.3451)),
    _CountryPin(name: 'Bangladesh', flag: '🇧🇩', position: const LatLng(23.6850, 90.3563)),
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _citySearchController.dispose();
    _scrollController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userId = prefs.getString('userId') ?? '';
      });
    }
    await _loadCountryCounts();
  }

  Future<void> _loadCountryCounts() async {
    if (mounted) setState(() => _isLoadingCounts = true);

    try {
      final service = ref.read(communityServiceProvider);

      // Fetch counts in batches of 6 to avoid overwhelming the server
      for (var i = 0; i < _countryPins.length; i += 6) {
        final batch = _countryPins.skip(i).take(6);
        await Future.wait(batch.map((pin) async {
          try {
            final result = await service.getCommunityPaginated(
              page: 1,
              limit: 1,
              country: pin.name,
            );
            pin.userCount = result.total;
          } catch (_) {
            pin.userCount = 0;
          }
        }));
        if (mounted) setState(() {});
      }

      if (mounted) setState(() => _isLoadingCounts = false);
    } catch (e) {
      if (mounted) setState(() => _isLoadingCounts = false);
    }
  }

  Future<void> _selectCountry(String country, LatLng position) async {
    // Animate map to the selected country
    _mapController.move(position, 5.0);

    setState(() {
      _selectedCountry = country;
      _users = [];
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadUsers();
  }

  Future<void> _searchByCity() async {
    if (_citySearch.trim().isEmpty) return;
    setState(() {
      _selectedCountry = null;
      _users = [];
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (_isLoadingUsers) return;
    if (mounted) setState(() => _isLoadingUsers = true);

    try {
      final service = ref.read(communityServiceProvider);
      final result = await service.getCommunityPaginated(
        page: _currentPage,
        limit: 20,
        country: _selectedCountry,
        search: _citySearch.trim().isNotEmpty ? _citySearch.trim() : null,
      );

      final filtered = result.users.where((u) => u.id != _userId).toList();

      if (mounted) {
        setState(() {
          _users.addAll(filtered);
          _hasMore = result.hasMore;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingUsers || !_hasMore) return;
    _currentPage++;
    await _loadUsers();
  }

  void _goBack() {
    setState(() {
      _selectedCountry = null;
      _users = [];
      _citySearch = '';
      _citySearchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildCitySearchBar(),
        Expanded(
          child: _selectedCountry != null ||
                  (_citySearch.trim().isNotEmpty && _users.isNotEmpty)
              ? _buildUserList()
              : _buildMapView(isDark),
        ),
      ],
    );
  }

  Widget _buildVipGate(bool isDark, AsyncValue<Community> userAsync) {
    return Stack(
      children: [
        // Blurred map background
        Positioned.fill(
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(20.0, 15.0),
                  initialZoom: 2.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.bananatalk.app',
                  ),
                  // Show some pins to tease the feature
                  MarkerLayer(
                    markers: _countryPins.take(10).map((pin) => Marker(
                      point: pin.position,
                      width: 70,
                      height: 64,
                      child: _MapPin(flag: pin.flag, count: 0, isLoading: false),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Dark overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
          ),
        ),
        // VIP prompt
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // VIP icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.exploreByCity,
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.exploreByCurrentCity,
                  textAlign: TextAlign.center,
                  style: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                // Feature bullets
                _VipFeatureRow(
                  icon: Icons.map_rounded,
                  text: AppLocalizations.of(context)!.interactiveWorldMap,
                  color: context.textSecondary,
                ),
                _VipFeatureRow(
                  icon: Icons.search_rounded,
                  text: AppLocalizations.of(context)!.searchByCityName,
                  color: context.textSecondary,
                ),
                _VipFeatureRow(
                  icon: Icons.people_rounded,
                  text: AppLocalizations.of(context)!.seeUserCountsPerCountry,
                  color: context.textSecondary,
                ),
                const SizedBox(height: 20),
                // Upgrade button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final userId = userAsync.whenOrNull(data: (u) => u.id) ?? '';
                      if (userId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VipStatusScreen(userId: userId),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.workspace_premium, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.upgradeToVip,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCitySearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: AppRadius.borderLG,
        border: Border.all(color: context.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _citySearchController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchByCity,
          hintStyle: context.bodyMedium.copyWith(color: context.textMuted),
          prefixIcon: Icon(Icons.search_rounded, color: context.primaryColor),
          suffixIcon: _citySearch.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: context.textSecondary, size: 20),
                  onPressed: () {
                    _citySearchController.clear();
                    setState(() {
                      _citySearch = '';
                      _users = [];
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: context.bodyMedium,
        onChanged: (value) {
          setState(() => _citySearch = value);
        },
        onSubmitted: (_) => _searchByCity(),
      ),
    );
  }

  Widget _buildMapView(bool isDark) {
    return Stack(
      children: [
        // Interactive map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(20.0, 15.0),
            initialZoom: 2.0,
            minZoom: 2.0,
            maxZoom: 8.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // OpenStreetMap tiles
            TileLayer(
              urlTemplate: isDark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.bananatalk.app',
            ),
            // Country markers
            MarkerLayer(
              markers: _countryPins
                  .where((pin) => pin.userCount > 0 || _isLoadingCounts)
                  .map((pin) => Marker(
                        point: pin.position,
                        width: 70,
                        height: 64,
                        child: GestureDetector(
                          onTap: () => _selectCountry(pin.name, pin.position),
                          child: _MapPin(
                            flag: pin.flag,
                            count: pin.userCount,
                            isLoading: _isLoadingCounts && pin.userCount == 0,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        // Total user count overlay
        Positioned(
          top: 8,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.surfaceColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public_rounded, size: 16, color: context.primaryColor),
                const SizedBox(width: 6),
                Text(
                  _isLoadingCounts
                      ? AppLocalizations.of(context)!.loading
                      : AppLocalizations.of(context)!.usersWorldwide(_countryPins.fold<int>(0, (a, b) => a + b.userCount).toString()),
                  style: context.labelMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserList() {
    final title = _selectedCountry ?? 'Search: $_citySearch';

    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: _goBack,
                icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: context.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_users.isNotEmpty)
                Text(
                  AppLocalizations.of(context)!.usersCount(_users.length.toString()),
                  style: context.bodySmall.copyWith(color: context.textSecondary),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        // User list
        Expanded(
          child: _isLoadingUsers && _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_rounded, size: 48, color: context.textMuted),
                          const SizedBox(height: 12),
                          Text(AppLocalizations.of(context)!.noUsersFound, style: context.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.tryDifferentCity,
                            style: context.bodySmall.copyWith(color: context.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      itemCount: _users.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: context.dividerColor,
                      ),
                      itemBuilder: (context, index) {
                        if (index >= _users.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final user = _users[index];
                        return PartnerListItem(
                          user: user,
                          onTap: () => _viewProfile(user),
                          onWave: () => _onWave(user),
                          onMessage: () => _onMessage(user),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _viewProfile(Community user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SingleCommunity(community: user)),
    );
  }

  Future<void> _onWave(Community user) async {
    // Navigate to chat immediately
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          userId: user.id,
          userName: user.name,
          profilePicture: user.profileImageUrl,
          isVip: user.isVip,
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

  void _onMessage(Community user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          userId: user.id,
          userName: user.name,
          profilePicture: user.profileImageUrl,
        ),
      ),
    );
  }
}

/// Map pin widget showing flag + user count bubble
class _MapPin extends StatelessWidget {
  final String flag;
  final int count;
  final bool isLoading;

  const _MapPin({
    required this.flag,
    required this.count,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Count bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: context.primaryColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _formatCount(count),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        // Flag
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(flag, style: const TextStyle(fontSize: 24)),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

class _VipFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _VipFeatureRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFFD700)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}
