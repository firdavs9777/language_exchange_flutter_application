import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/pages/chat/conversation/chat_conversation_screen.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/widgets/community/user_skeleton.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

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
  String _selectedGender = 'female';
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

      // Use same filter logic as _loadUsers so counts match what user will see
      final filterNative = widget.filters['nativeLanguage']?.toString();
      final filterLearning = widget.filters['learningLanguage']?.toString();
      final country = widget.filters['country']?.toString();
      final hasExplicitLangFilter = (filterNative != null && filterNative.isNotEmpty) ||
          (filterLearning != null && filterLearning.isNotEmpty);
      String? effectiveNative = filterNative;
      String? effectiveLearning = filterLearning;
      bool useMatchLanguage = false;
      if (!hasExplicitLangFilter) {
        final me = ref.read(userProvider).valueOrNull;
        if (me != null && me.native_language.isNotEmpty && me.language_to_learn.isNotEmpty) {
          effectiveNative = me.native_language;
          effectiveLearning = me.language_to_learn;
          useMatchLanguage = true;
        }
      }

      final results = await Future.wait([
        service.getCommunityPaginated(
          page: 1,
          limit: 1,
          gender: 'male',
          country: (country != null && country.isNotEmpty) ? country : null,
          nativeLanguage: (effectiveNative != null && effectiveNative.isNotEmpty) ? effectiveNative : null,
          learningLanguage: (effectiveLearning != null && effectiveLearning.isNotEmpty) ? effectiveLearning : null,
          matchLanguage: useMatchLanguage,
        ),
        service.getCommunityPaginated(
          page: 1,
          limit: 1,
          gender: 'female',
          country: (country != null && country.isNotEmpty) ? country : null,
          nativeLanguage: (effectiveNative != null && effectiveNative.isNotEmpty) ? effectiveNative : null,
          learningLanguage: (effectiveLearning != null && effectiveLearning.isNotEmpty) ? effectiveLearning : null,
          matchLanguage: useMatchLanguage,
        ),
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
      final nativeLanguage = widget.filters['nativeLanguage']?.toString();
      final learningLanguage = widget.filters['learningLanguage']?.toString();
      final languageLevel = widget.filters['languageLevel']?.toString();

      // Default to exchange matching when no explicit language filter is set
      final hasExplicitLangFilter = (nativeLanguage != null && nativeLanguage.isNotEmpty) ||
          (learningLanguage != null && learningLanguage.isNotEmpty);
      String? effectiveNative = nativeLanguage;
      String? effectiveLearning = learningLanguage;
      bool useMatchLanguage = false;
      if (!hasExplicitLangFilter) {
        final me = ref.read(userProvider).valueOrNull;
        if (me != null && me.native_language.isNotEmpty && me.language_to_learn.isNotEmpty) {
          effectiveNative = me.native_language;
          effectiveLearning = me.language_to_learn;
          useMatchLanguage = true;
        }
      }

      final result = await service.getCommunityPaginated(
        page: _currentPage,
        limit: 20,
        gender: _selectedGender,
        minAge: (minAge != null && minAge > 18) ? minAge : null,
        maxAge: (maxAge != null && maxAge < 100) ? maxAge : null,
        onlineOnly: onlineOnly ? true : null,
        country: (country != null && country.isNotEmpty) ? country : null,
        nativeLanguage: (effectiveNative != null && effectiveNative.isNotEmpty) ? effectiveNative : null,
        learningLanguage: (effectiveLearning != null && effectiveLearning.isNotEmpty) ? effectiveLearning : null,
        matchLanguage: useMatchLanguage,
        languageLevel: (languageLevel != null && languageLevel.isNotEmpty) ? languageLevel : null,
        search: widget.searchQuery.isNotEmpty ? widget.searchQuery : null,
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
    if (oldWidget.filters != widget.filters ||
        oldWidget.searchQuery != widget.searchQuery) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider).valueOrNull;
    final isVip = currentUser?.isVip ?? false;

    return Column(
      children: [
        _buildGenderSelector()
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(
              begin: -0.05,
              end: 0,
              duration: 300.ms,
              curve: Curves.easeOutCubic,
            ),
        // VIP promo banner for non-VIP users
        if (!isVip) _buildVipPromoBanner(),
        // Ad banner for non-VIP
        if (!isVip)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SmallBannerAdWidget(),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _isLoading && _users.isEmpty
                ? const UserGridSkeleton(count: 6)
                : _users.isEmpty
                ? _buildEmptyState()
                : _buildUserGrid(),
          ),
        ),
      ],
    );
  }

  Widget _buildVipPromoBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppPageRoute(builder: (_) => const VipPlansScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD700).withValues(alpha: 0.15),
              const Color(0xFFFFA500).withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'See who likes you',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    'Unlimited browsing, no ads, priority matching',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'VIP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
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
          // Female (first)
          Expanded(
            child: GestureDetector(
              onTap: () => _switchGender('female'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: !isMale
                      ? const LinearGradient(
                          colors: [Color(0xFFEC407A), Color(0xFFD81B60)],
                        )
                      : null,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.female_rounded,
                          size: 22,
                          color: !isMale ? Colors.white : context.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.female,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: !isMale ? Colors.white : context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (_countsLoaded) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${_formatCount(_femaleCount)} members',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: !isMale
                              ? Colors.white.withValues(alpha: 0.8)
                              : context.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Male (second)
          Expanded(
            child: GestureDetector(
              onTap: () => _switchGender('male'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isMale
                      ? const LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                        )
                      : null,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.male_rounded,
                          size: 22,
                          color: isMale ? Colors.white : context.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.male,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isMale ? Colors.white : context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (_countsLoaded) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${_formatCount(_maleCount)} members',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isMale
                              ? Colors.white.withValues(alpha: 0.8)
                              : context.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
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
                  _selectedGender == 'male'
                      ? Icons.male_rounded
                      : Icons.female_rounded,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedGender == 'male'
                    ? AppLocalizations.of(context)!.noMaleUsersFound
                    : AppLocalizations.of(context)!.noFemaleUsersFound,
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
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  void _viewProfile(Community user) {
    Navigator.push(
      context,
      AppPageRoute(builder: (_) => SingleCommunity(community: user)),
    );
  }

  Future<void> _onWave(Community user) async {
    HapticFeedback.mediumImpact();

    // Navigate to chat immediately
    Navigator.push(
      context,
      AppPageRoute(
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
      AppPageRoute(
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
    final nativeFlag = LanguageFlags.getFlagByName(user.native_language);
    final learningFlag = LanguageFlags.getFlagByName(user.language_to_learn);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: genderColor.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
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
                      Colors.black.withValues(alpha: 0.05),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
            // Top row: Online + VIP + New badge
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  // VIP badge
                  if (user.isVip)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium, size: 10, color: Colors.white),
                          SizedBox(width: 2),
                          Text('VIP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  // New user badge
                  if (!user.isVip && user.isNewUser)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  const Spacer(),
                  // Online indicator
                  if (PrivacyUtils.shouldShowOnlineStatus(user) && user.isOnline)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Language flags pill (top-right area below badges)
            if (user.native_language.isNotEmpty || user.language_to_learn.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(nativeFlag, style: const TextStyle(fontSize: 11)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.arrow_forward_rounded, size: 8, color: Colors.white70),
                      ),
                      Text(learningFlag, style: const TextStyle(fontSize: 11)),
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
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
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
                              fontWeight: FontWeight.w700,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (PrivacyUtils.shouldShowAge(user) &&
                            user.age != null &&
                            user.age! > 0)
                          Text(
                            ', ${user.age}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    Builder(
                      builder: (context) {
                        final locationText = PrivacyUtils.getLocationText(user);
                        if (locationText.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 11,
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        genderColor.withValues(alpha: 0.8),
                        genderColor,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: genderColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
          colors: [genderColor.withValues(alpha: 0.7), genderColor],
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
