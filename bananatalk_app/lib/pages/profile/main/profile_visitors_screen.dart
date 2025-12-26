import 'package:bananatalk_app/pages/profile/profile_wrapper.dart';
import 'package:bananatalk_app/services/profile_visitor_service.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profile Visitors',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
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
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchVisitors(page: 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.visibility_off_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No visitors yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When people visit your profile,\nthey will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
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
            padding: const EdgeInsets.all(16),
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visitor Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 12),
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
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00BFA5),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
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
        sourceColor = Colors.blue;
        break;
      case 'moments':
        sourceIcon = Icons.photo_library;
        sourceText = 'via Moments';
        sourceColor = Colors.purple;
        break;
      case 'chat':
        sourceIcon = Icons.chat;
        sourceText = 'via Chat';
        sourceColor = Colors.green;
        break;
      default:
        sourceIcon = Icons.person;
        sourceText = 'Direct visit';
        sourceColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () => _navigateToProfile(userId, userName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
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
                        backgroundColor: Colors.grey[200],
                      )
                    : CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFF00BFA5).withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          size: 32,
                          color: Color(0xFF00BFA5),
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
                        color: const Color(0xFF00BFA5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '$visitCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (locationText.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (nativeLanguage.isNotEmpty || learningLanguage.isNotEmpty)
                    const SizedBox(height: 4),
                  if (nativeLanguage.isNotEmpty || learningLanguage.isNotEmpty)
                    Row(
                      children: [
                        if (nativeLanguage.isNotEmpty) ...[
                          Icon(
                            Icons.translate,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            nativeLanguage,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (nativeLanguage.isNotEmpty &&
                            learningLanguage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        if (learningLanguage.isNotEmpty)
                          Text(
                            learningLanguage,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(sourceIcon, size: 12, color: sourceColor),
                      const SizedBox(width: 4),
                      Text(
                        sourceText,
                        style: TextStyle(
                          fontSize: 12,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
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

