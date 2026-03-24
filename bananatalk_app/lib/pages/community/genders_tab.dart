import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/widgets/community/partner_list_item.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/chat/chat_single.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';

/// Genders Tab — browse users filtered by gender with a polished UI
class GendersTab extends ConsumerStatefulWidget {
  final Map<String, dynamic> filters;
  final String searchQuery;

  const GendersTab({
    super.key,
    required this.filters,
    required this.searchQuery,
  });

  @override
  ConsumerState<GendersTab> createState() => _GendersTabState();
}

class _GendersTabState extends ConsumerState<GendersTab> {
  String _userId = '';
  String _selectedGender = 'male';
  List<Community> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _maleCount = 0;
  int _femaleCount = 0;
  bool _countsLoaded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initialize();
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

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _userId = prefs.getString('userId') ?? '');
    }
    // Load counts and users in parallel
    await Future.wait([_loadGenderCounts(), _loadUsers()]);
  }

  Future<void> _loadGenderCounts() async {
    try {
      final service = ref.read(communityServiceProvider);
      final results = await Future.wait([
        service.getCommunityPaginated(page: 1, limit: 1, gender: 'male'),
        service.getCommunityPaginated(page: 1, limit: 1, gender: 'female'),
      ]);
      if (mounted) {
        setState(() {
          _maleCount = results[0].total;
          _femaleCount = results[1].total;
          _countsLoaded = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _switchGender(String gender) async {
    if (gender == _selectedGender) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedGender = gender;
      _users = [];
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (_isLoading) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      final service = ref.read(communityServiceProvider);
      final minAge = widget.filters['minAge'] as int?;
      final maxAge = widget.filters['maxAge'] as int?;
      final onlineOnly = widget.filters['onlineOnly'] as bool? ?? false;
      final country = widget.filters['country']?.toString();

      final result = await service.getCommunityPaginated(
        page: _currentPage,
        limit: 20,
        gender: _selectedGender,
        minAge: (minAge != null && minAge > 18) ? minAge : null,
        maxAge: (maxAge != null && maxAge < 100) ? maxAge : null,
        onlineOnly: onlineOnly ? true : null,
        country: (country != null && country.isNotEmpty) ? country : null,
      );

      final filtered = result.users.where((u) => u.id != _userId).toList();

      if (mounted) {
        setState(() {
          _users.addAll(filtered);
          _hasMore = result.hasMore;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoading || !_hasMore) return;
    _currentPage++;
    await _loadUsers();
  }

  Future<void> _refresh() async {
    setState(() {
      _users = [];
      _currentPage = 1;
      _hasMore = true;
    });
    await Future.wait([_loadGenderCounts(), _loadUsers()]);
  }

  @override
  void didUpdateWidget(GendersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters != widget.filters) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildGenderSelector(),
        // Preview avatars row
        if (_users.isNotEmpty) _buildPreviewRow(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _isLoading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? _buildEmptyState()
                    : _buildUserGrid(),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    const maleColor = Color(0xFF42A5F5);
    const femaleColor = Color(0xFFEC407A);
    final isMale = _selectedGender == 'male';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          // Male
          Expanded(
            child: GestureDetector(
              onTap: () => _switchGender('male'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isMale ? maleColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isMale
                      ? [
                          BoxShadow(
                            color: maleColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.male_rounded,
                      size: 22,
                      color: isMale ? Colors.white : context.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.male,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isMale ? Colors.white : context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Female
          Expanded(
            child: GestureDetector(
              onTap: () => _switchGender('female'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isMale ? femaleColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !isMale
                      ? [
                          BoxShadow(
                            color: femaleColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.female_rounded,
                      size: 22,
                      color: !isMale ? Colors.white : context.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.female,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: !isMale ? Colors.white : context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow() {
    final previewUsers = _users.take(5).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Stacked avatars
          SizedBox(
            width: 24.0 + (previewUsers.length * 28.0),
            height: 36,
            child: Stack(
              children: previewUsers.asMap().entries.map((entry) {
                final i = entry.key;
                final user = entry.value;
                return Positioned(
                  left: i * 28.0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.surfaceColor,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: user.profileImageUrl != null
                          ? CachedImageWidget(
                              imageUrl: user.profileImageUrl!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: _selectedGender == 'male'
                                  ? const Color(0xFF42A5F5)
                                  : const Color(0xFFEC407A),
                              child: Center(
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedGender == 'male' ? AppLocalizations.of(context)!.browseMen : AppLocalizations.of(context)!.browseWomen,
              style: context.bodySmall.copyWith(
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _users.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _users.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return _GenderUserCard(
          user: _users[index],
          genderColor: _selectedGender == 'male'
              ? const Color(0xFF42A5F5)
              : const Color(0xFFEC407A),
          onTap: () => _viewProfile(_users[index]),
          onWave: () => _onWave(_users[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final color = _selectedGender == 'male'
        ? const Color(0xFF42A5F5)
        : const Color(0xFFEC407A);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedGender == 'male' ? Icons.male_rounded : Icons.female_rounded,
              size: 40,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedGender == 'male' ? AppLocalizations.of(context)!.noMaleUsersFound : AppLocalizations.of(context)!.noFemaleUsersFound,
            style: context.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.tryAdjustingFilters,
            style: context.bodySmall.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _viewProfile(Community user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SingleCommunity(community: user)),
    );
  }

  Future<void> _onWave(Community user) async {
    HapticFeedback.mediumImpact();

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

    // Send wave sticker message
    try {
      final messageService = ref.read(messageServiceProvider);
      await messageService.sendMessage(
        receiver: user.id,
        message: '\u{1F44B}', // Wave emoji - renders as big sticker
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

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

/// Grid card for gender tab — photo-first with overlay info
class _GenderUserCard extends StatelessWidget {
  final Community user;
  final Color genderColor;
  final VoidCallback? onTap;
  final VoidCallback? onWave;

  const _GenderUserCard({
    required this.user,
    required this.genderColor,
    this.onTap,
    this.onWave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Profile image
            user.profileImageUrl != null
                ? CachedImageWidget(
                    imageUrl: user.profileImageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorWidget: _buildFallback(),
                  )
                : _buildFallback(),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Online indicator
            if (PrivacyUtils.shouldShowOnlineStatus(user) && user.isOnline)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            // VIP badge
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
                      Text('VIP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            // Bottom info
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (PrivacyUtils.shouldShowAge(user) && user.age != null && user.age! > 0)
                          Text(
                            ', ${user.age}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                    Builder(
                      builder: (context) {
                        final locationText = PrivacyUtils.getLocationText(user);
                        if (locationText.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  locationText,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Wave button
            Positioned(
              bottom: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onWave?.call();
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            genderColor.withValues(alpha: 0.8),
            genderColor,
          ],
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
}
