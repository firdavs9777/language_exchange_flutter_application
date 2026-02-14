import 'package:bananatalk_app/pages/profile/profile_wrapper.dart';
import 'package:bananatalk_app/services/profile_visitor_service.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProfileVisitorsScreen extends StatefulWidget {
  final String userId;

  const ProfileVisitorsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

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
            _error = result['error'] ?? 'Visitor tracking feature not available. Please update backend.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Visitor tracking not available yet';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToProfile(String userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileWrapper(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Profile Visitors',
          style: context.titleLarge,
        ),
        elevation: 0,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            Spacing.gapLG,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Error: $_error',
                style: context.bodyMedium.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
            Spacing.gapLG,
            ElevatedButton(
              onPressed: () => _fetchVisitors(page: 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    if (_visitors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: Spacing.paddingXXL,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.visibility_off_outlined,
                size: 64,
                color: context.textHint,
              ),
            ),
            Spacing.gapXXL,
            Text(
              'No visitors yet',
              style: context.titleLarge.copyWith(
                color: context.textSecondary,
              ),
            ),
            Spacing.gapSM,
            Text(
              'When people visit your profile,\nthey will appear here',
              style: context.bodyMedium.copyWith(
                color: context.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchVisitors(page: _currentPage),
      child: CustomScrollView(
        slivers: [
          // Stats header
          if (_stats != null)
            SliverToBoxAdapter(
              child: _buildStatsHeader(),
            ),
          // Visitor list
          SliverPadding(
            padding: Spacing.screenPadding,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final visitor = _visitors[index];
                  return _buildVisitorCard(visitor);
                },
                childCount: _visitors.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalVisits = _stats?['totalVisits'] ?? 0;
    final uniqueVisitors = _stats?['uniqueVisitors'] ?? 0;
    final visitsToday = _stats?['visitsToday'] ?? 0;
    final visitsThisWeek = _stats?['visitsThisWeek'] ?? 0;

    return Container(
      margin: Spacing.screenPadding,
      padding: Spacing.paddingXL,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visitor Statistics',
            style: context.titleLarge,
          ),
          Spacing.gapLG,
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '👁️',
                  totalVisits.toString(),
                  'Total Visits',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '👥',
                  uniqueVisitors.toString(),
                  'Unique Visitors',
                ),
              ),
            ],
          ),
          Spacing.gapMD,
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '📅',
                  visitsToday.toString(),
                  'Today',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '📊',
                  visitsThisWeek.toString(),
                  'This Week',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        Spacing.gapXS,
        Text(
          value,
          style: context.displaySmall.copyWith(
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: context.caption,
        ),
      ],
    );
  }

  Widget _buildVisitorCard(dynamic visitor) {
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

    // Source icon and text
    IconData sourceIcon;
    String sourceText;
    Color sourceColor;

    switch (source) {
      case 'search':
        sourceIcon = Icons.search;
        sourceText = 'via Search';
        sourceColor = AppColors.info;
        break;
      case 'moments':
        sourceIcon = Icons.photo_library;
        sourceText = 'via Moments';
        sourceColor = AppColors.accent;
        break;
      case 'chat':
        sourceIcon = Icons.chat;
        sourceText = 'via Chat';
        sourceColor = AppColors.success;
        break;
      default:
        sourceIcon = Icons.person;
        sourceText = 'Direct visit';
        sourceColor = AppColors.gray500;
    }

    return GestureDetector(
      onTap: () => _navigateToProfile(userId, userName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: Spacing.paddingLG,
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: AppRadius.borderLG,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            // Profile Picture
            Stack(
              children: [
                userPhoto != null
                    ? CachedCircleAvatar(
                        imageUrl: userPhoto,
                        radius: 32,
                        backgroundColor: context.containerColor,
                      )
                    : CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                // Visit count badge
                if (visitCount > 1)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.borderSM,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: Text(
                        '$visitCount',
                        style: context.captionSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Spacing.hGapLG,
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: context.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacing.gapXS,
                  if (locationText.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: context.textSecondary,
                        ),
                        Spacing.hGapXS,
                        Expanded(
                          child: Text(
                            locationText,
                            style: context.labelMedium.copyWith(
                              color: context.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (nativeLanguage.isNotEmpty || learningLanguage.isNotEmpty)
                    Spacing.gapXS,
                  if (nativeLanguage.isNotEmpty || learningLanguage.isNotEmpty)
                    Row(
                      children: [
                        if (nativeLanguage.isNotEmpty) ...[
                          Icon(
                            Icons.translate,
                            size: 14,
                            color: context.textSecondary,
                          ),
                          Spacing.hGapXS,
                          Text(
                            nativeLanguage,
                            style: context.caption,
                          ),
                        ],
                        if (nativeLanguage.isNotEmpty &&
                            learningLanguage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 12,
                              color: context.textHint,
                            ),
                          ),
                        if (learningLanguage.isNotEmpty)
                          Text(
                            learningLanguage,
                            style: context.caption,
                          ),
                      ],
                    ),
                  Spacing.gapSM,
                  Row(
                    children: [
                      Icon(sourceIcon, size: 12, color: sourceColor),
                      Spacing.hGapXS,
                      Text(
                        sourceText,
                        style: context.labelSmall.copyWith(
                          color: sourceColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeago.format(lastVisit, locale: 'en_short'),
                  style: context.caption,
                ),
                Spacing.gapXS,
                Icon(
                  Icons.chevron_right,
                  color: context.textMuted,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
