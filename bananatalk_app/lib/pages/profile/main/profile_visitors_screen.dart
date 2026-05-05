import 'package:bananatalk_app/pages/profile/profile_wrapper.dart';
import 'package:bananatalk_app/services/profile_visitor_service.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:bananatalk_app/utils/app_page_route.dart';

class ProfileVisitorsScreen extends StatefulWidget {
  final String userId;

  const ProfileVisitorsScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<ProfileVisitorsScreen> createState() => _ProfileVisitorsScreenState();
}

class _ProfileVisitorsScreenState extends State<ProfileVisitorsScreen> {
  List<dynamic> _visitors = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');
    _fetchVisitors();
  }

  Future<void> _fetchVisitors({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ProfileVisitorService.getProfileVisitors(
        userId: widget.userId,
        page: page,
        limit: 50,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _visitors = result['visitors'] ?? [];
            _stats = result['stats'];
            _currentPage = page;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result['error'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.visitorTrackingNotAvailableYet;
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToProfile(String userId, String userName) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      AppPageRoute(builder: (context) => ProfileWrapper(userId: userId)),
    );
  }

  Future<void> _refreshVisitors() async {
    HapticFeedback.lightImpact();
    await _fetchVisitors(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.profileVisitorsTitle,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading visitors...',
              style: context.bodySmall.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_visitors.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshVisitors,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          if (_stats != null) SliverToBoxAdapter(child: _buildStatsHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _buildSectionTitle(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final visitor = _visitors[index];
                return _buildVisitorCard(visitor);
              }, childCount: _visitors.length),
            ),
          ),
        ],
      ),
    );
  }

  // ========== ERROR STATE ==========
  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: _refreshVisitors,
      color: AppColors.primary,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.error,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _error!,
                      style: context.bodySmall.copyWith(
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _fetchVisitors(page: 1),
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.retry,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  // ========== EMPTY STATE ==========
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: _refreshVisitors,
      color: AppColors.primary,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(
                              alpha: isDark ? 0.25 : 0.15,
                            ),
                            AppColors.primary.withValues(
                              alpha: isDark ? 0.08 : 0.04,
                            ),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.visibility_off_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.noVisitorsYet,
                      style: context.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.noVisitorsYetSubtitle,
                      style: context.bodyMedium.copyWith(
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: isDark ? 0.15 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pull down to refresh',
                            style: context.captionSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  // ========== STATS HEADER ==========
  Widget _buildStatsHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final totalVisits = _stats?['totalVisits'] ?? 0;
    final uniqueVisitors = _stats?['uniqueVisitors'] ?? 0;
    final visitsToday = _stats?['visitsToday'] ?? 0;
    final visitsThisWeek = _stats?['visitsThisWeek'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
            AppColors.primary.withValues(alpha: isDark ? 0.06 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.visitorStatistics,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'See who checked your profile',
                      style: context.captionSmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.visibility_rounded,
                  value: totalVisits.toString(),
                  label: l10n.visitorsTotalVisits,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people_rounded,
                  value: uniqueVisitors.toString(),
                  label: l10n.visitorsUniqueVisitors,
                  color: const Color(0xFF7C4DFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.today_rounded,
                  value: visitsToday.toString(),
                  label: l10n.visitorsToday,
                  color: const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.bar_chart_rounded,
                  value: visitsThisWeek.toString(),
                  label: l10n.visitorsThisWeek,
                  color: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: isDark ? 0.6 : 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.3,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.captionSmall.copyWith(
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ========== SECTION TITLE ==========
  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Recent Visitors',
          style: context.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${_visitors.length}',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  // ========== VISITOR CARD ==========
  Widget _buildVisitorCard(dynamic visitor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = visitor['user'];
    final lastVisit = DateTime.parse(visitor['lastVisit']);
    final visitCount = visitor['visitCount'] ?? 1;
    final source = visitor['source'] ?? 'direct';

    final userId = user['_id'];
    final userName = user['name'] ?? 'Unknown User';
    final userPhoto = user['imageUrls'] != null && user['imageUrls'].isNotEmpty
        ? user['imageUrls'][0]
        : null;
    final city = user['city'] ?? '';
    final country = user['country'] ?? '';
    final nativeLanguage = user['native_language'] ?? '';
    final learningLanguage = user['language_to_learn'] ?? '';

    String locationText = '';
    if (city.isNotEmpty && country.isNotEmpty) {
      locationText = '$city, $country';
    } else if (country.isNotEmpty) {
      locationText = country;
    }

    final sourceInfo = _getSourceInfo(source);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToProfile(userId, userName),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: isDark
                  ? Border.all(color: Colors.white.withValues(alpha: 0.06))
                  : null,
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Avatar with badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: userPhoto != null
                            ? CachedImageWidget(
                                imageUrl: userPhoto,
                                fit: BoxFit.cover,
                                errorWidget: _avatarPlaceholder(),
                              )
                            : _avatarPlaceholder(),
                      ),
                    ),
                    if (visitCount > 1)
                      Positioned(
                        right: -4,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: context.surfaceColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '×$visitCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: context.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (locationText.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: context.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                locationText,
                                style: context.captionSmall.copyWith(
                                  color: context.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (nativeLanguage.isNotEmpty ||
                          learningLanguage.isNotEmpty) ...[
                        Row(
                          children: [
                            if (nativeLanguage.isNotEmpty) ...[
                              Icon(
                                Icons.translate_rounded,
                                size: 11,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  nativeLanguage,
                                  style: context.captionSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (nativeLanguage.isNotEmpty &&
                                learningLanguage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 10,
                                  color: context.textMuted,
                                ),
                              ),
                            if (learningLanguage.isNotEmpty)
                              Flexible(
                                child: Text(
                                  learningLanguage,
                                  style: context.captionSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFF9800),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      // Source pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: sourceInfo.color.withValues(
                            alpha: isDark ? 0.2 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              sourceInfo.icon,
                              size: 10,
                              color: sourceInfo.color,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              sourceInfo.label,
                              style: TextStyle(
                                color: sourceInfo.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Time + chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        timeago.format(lastVisit, locale: 'en_short'),
                        style: context.captionSmall.copyWith(
                          color: context.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.15),
      child: Icon(Icons.person_rounded, size: 30, color: AppColors.primary),
    );
  }

  // Source info helper
  ({IconData icon, String label, Color color}) _getSourceInfo(String source) {
    final l10n = AppLocalizations.of(context)!;
    switch (source) {
      case 'search':
        return (
          icon: Icons.search_rounded,
          label: l10n.visitedViaSearch,
          color: const Color(0xFF2196F3),
        );
      case 'moments':
        return (
          icon: Icons.photo_library_rounded,
          label: l10n.visitedViaMoments,
          color: const Color(0xFF7C4DFF),
        );
      case 'chat':
        return (
          icon: Icons.chat_rounded,
          label: l10n.visitedViaChat,
          color: const Color(0xFF4CAF50),
        );
      default:
        return (
          icon: Icons.person_rounded,
          label: l10n.visitedDirect,
          color: const Color(0xFF607D8B),
        );
    }
  }
}
