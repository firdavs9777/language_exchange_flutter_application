import 'package:bananatalk_app/pages/moments/image_viewer.dart';
import 'package:bananatalk_app/pages/profile/main/profile_edit_main.dart';
import 'package:bananatalk_app/pages/profile/main/profile_followers.dart';
import 'package:bananatalk_app/pages/profile/main/profile_followings.dart';
import 'package:bananatalk_app/pages/profile/main/profile_left_drawer.dart';
import 'package:bananatalk_app/pages/profile/main/profile_moments.dart';
import 'package:bananatalk_app/pages/profile/main/profile_visitors_screen.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_picture_edit.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/services/profile_visitor_service.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'dart:ui';

class ProfileMain extends ConsumerStatefulWidget {
  const ProfileMain({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileMain> createState() => _ProfileMainState();
}

class _ProfileMainState extends ConsumerState<ProfileMain> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.refresh(userProvider));
  }

  int _calculateAge(String birthYear) {
    try {
      final currentYear = DateTime.now().year;
      final year = int.parse(birthYear);
      return currentYear - year;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      endDrawer: Builder(
        builder: (context) {
          return userAsync.when(
            data: (user) => LeftDrawer(user: user),
            loading: () => const Drawer(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) {
              final l10n = AppLocalizations.of(context)!;
              return Drawer(
                child: Center(child: Text('${l10n.error}: $error')),
              );
            },
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(userProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: userAsync.when(
          data: (user) => CustomScrollView(
            slivers: [
              // Modern App Bar with Gradient
              _buildModernAppBar(context),

              // Profile Content
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildProfileHeader(user),
                    const SizedBox(height: 20),
                    _buildQuickActions(context, user),
                    const SizedBox(height: 20),
                    _buildStatsCards(context, user),
                    const SizedBox(height: 20),
                    _buildLanguageCard(user),
                    const SizedBox(height: 16),
                    _buildAboutCard(user),
                    const SizedBox(height: 16),
                    _buildMomentsGrid(context, user),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            final l10n = AppLocalizations.of(context)!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${l10n.error}: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(userProvider),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00BFA5).withOpacity(0.8),
                  const Color(0xFF00897B).withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.settings, color: Colors.white),
            ),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProfileHeader(Community user) {
    final calculatedAge = _calculateAge(user.birth_year);
    final age = PrivacyUtils.getAge(user, calculatedAge);
    final locationText = PrivacyUtils.getLocationText(user);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 80, 16, 0),
      child: Column(
        children: [
          // Profile Picture with Gradient Border
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePictureEdit(user: user),
                ),
              );
              // Refresh user data after returning
              if (mounted) {
                ref.refresh(userProvider);
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF00BFA5),
                        Color(0xFF00897B),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BFA5).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: user.imageUrls.isNotEmpty
                        ? CachedCircleAvatar(
                            imageUrl: user.imageUrls[0],
                            radius: 64,
                            backgroundColor: Colors.grey[200],
                          )
                        : CircleAvatar(
                            radius: 64,
                            backgroundColor:
                                const Color(0xFF00BFA5).withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              size: 64,
                              color: Color(0xFF00BFA5),
                            ),
                          ),
                  ),
                ),
                // Edit Icon Overlay
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Age and Location with Icons
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (age != null)
                _buildInfoChip(
                  Icons.cake_outlined,
                  AppLocalizations.of(context)!.yearsOld(age.toString()),
                  Colors.purple,
                ),
              if (locationText.isNotEmpty)
                _buildInfoChip(
                  Icons.location_on_outlined,
                  locationText,
                  Colors.blue,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Community user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.edit_outlined,
              label: AppLocalizations.of(context)!.editProfile,
              gradient: const LinearGradient(
                colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileEdit(
                      nativeLanguage: user.native_language,
                      languageToLearn: user.language_to_learn,
                      userName: user.name,
                      mbti: user.mbti,
                      bloodType: user.bloodType,
                      location: user.location,
                      gender: user.gender,
                      bio: user.bio,
                    ),
                  ),
                );
                if (mounted) {
                  ref.invalidate(userProvider);
                  await ref.read(userProvider.future);
                }
              },
            ),
          ),
          // VIP Membership - Hidden for now
          // const SizedBox(width: 12),
          // FutureBuilder<String?>(
          //   future: SharedPreferences.getInstance()
          //       .then((prefs) => prefs.getString('userId')),
          //   builder: (context, snapshot) {
          //     if (!snapshot.hasData) return const SizedBox.shrink();
          //     final userId = snapshot.data!;

          //     return Expanded(
          //       child: Consumer(
          //         builder: (context, ref, child) {
          //           final limitsAsync = ref.watch(userLimitsProvider(userId));

          //           return limitsAsync.when(
          //             data: (limits) {
          //               if (limits.isVIP) {
          //                 return _buildActionButton(
          //                   icon: Icons.workspace_premium,
          //                   label: 'VIP Active',
          //                   gradient: const LinearGradient(
          //                     colors: [Colors.amber, Colors.orange],
          //                   ),
          //                   onTap: () {
          //                     Navigator.push(
          //                       context,
          //                       MaterialPageRoute(
          //                         builder: (context) =>
          //                             VipPlansScreen(userId: userId),
          //                       ),
          //                     );
          //                   },
          //                 );
          //               }

          //               return _buildActionButton(
          //                 icon: Icons.workspace_premium_outlined,
          //                 label: 'Go VIP',
          //                 gradient: LinearGradient(
          //                   colors: [
          //                     Colors.amber.shade400,
          //                     Colors.orange.shade400
          //                   ],
          //                 ),
          //                 onTap: () {
          //                   Navigator.push(
          //                     context,
          //                     MaterialPageRoute(
          //                       builder: (context) =>
          //                           VipPlansScreen(userId: userId),
          //                     ),
          //                   },
          //                 );
          //               );
          //             },
          //             loading: () => const SizedBox.shrink(),
          //             error: (_, __) => const SizedBox.shrink(),
          //           );
          //         },
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, Community user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // First row: Followers and Following
          Row(
        children: [
          Expanded(
            child: _buildStatCard(
              value: user.followers.length.toString(),
              label: AppLocalizations.of(context)!.followers,
              icon: Icons.people_outline,
              color: const Color(0xFF00BFA5),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileFollowers(id: user.id),
                  ),
                ).then((_) => mounted ? ref.refresh(userProvider) : null);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              value: user.followings.length.toString(),
              label: AppLocalizations.of(context)!.following,
              icon: Icons.person_add_outlined,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileFollowings(id: user.id),
                  ),
                ).then((_) => mounted ? ref.refresh(userProvider) : null);
              },
            ),
          ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row: Moments and Visitors
          Row(
            children: [
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final momentsAsync = ref.watch(userMomentsProvider(user.id));
                return momentsAsync.when(
                  data: (moments) => _buildStatCard(
                    value: moments.length.toString(),
                    label: AppLocalizations.of(context)!.moments,
                    icon: Icons.photo_library_outlined,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileMoments(id: user.id),
                        ),
                      ).then((_) => mounted
                          ? ref.invalidate(userMomentsProvider(user.id))
                          : null);
                    },
                  ),
                  loading: () => _buildStatCard(
                    value: '...',
                    label: AppLocalizations.of(context)!.moments,
                    icon: Icons.photo_library_outlined,
                    color: Colors.purple,
                    onTap: () {},
                  ),
                  error: (_, __) => _buildStatCard(
                    value: '0',
                    label: AppLocalizations.of(context)!.moments,
                    icon: Icons.photo_library_outlined,
                    color: Colors.purple,
                    onTap: () {},
                  ),
                );
              },
            ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: ProfileVisitorService.getMyVisitorStats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildStatCard(
                        value: '...',
                        label: AppLocalizations.of(context)!.visitors,
                        icon: Icons.visibility_outlined,
                        color: Colors.orange,
                        onTap: () {},
                      );
                    }

                    // Handle errors gracefully - show 0 if backend not ready
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data?['success'] != true) {
                      final l10n = AppLocalizations.of(context)!;
                      return _buildStatCard(
                        value: '0',
                        label: l10n.visitors,
                        icon: Icons.visibility_outlined,
                        color: Colors.orange,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.visitorTrackingNotAvailable),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                      );
                    }

                    final data = snapshot.data!;
                    final stats = data['stats'];
                    final uniqueVisitors = stats?['uniqueVisitors'] ?? 0;

                    return _buildStatCard(
                      value: uniqueVisitors.toString(),
                      label: AppLocalizations.of(context)!.visitors,
                      icon: Icons.visibility_outlined,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfileVisitorsScreen(userId: user.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(Community user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.language,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.languageExchange,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLanguageRow(
            AppLocalizations.of(context)!.nativeLanguage,
            user.native_language.isEmpty ? AppLocalizations.of(context)!.notSet : user.native_language,
            Icons.translate,
            const Color(0xFF00BFA5),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 16),
          _buildLanguageRow(
            AppLocalizations.of(context)!.learning,
            user.language_to_learn.isEmpty ? AppLocalizations.of(context)!.notSet : user.language_to_learn,
            Icons.school,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageRow(
    String label,
    String language,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                language,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.check_circle, color: color, size: 20),
      ],
    );
  }

  Widget _buildAboutCard(Community user) {
    if (user.bio.isEmpty && user.mbti.isEmpty && user.bloodType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.bio.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.aboutMe,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user.bio,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),
          ],
          if (user.bio.isNotEmpty &&
              (user.mbti.isNotEmpty || user.bloodType.isNotEmpty))
            const SizedBox(height: 24),
          if (user.mbti.isNotEmpty || user.bloodType.isNotEmpty) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (user.mbti.isNotEmpty)
                  _buildTagChip(
                    Icons.psychology,
                    'MBTI: ${user.mbti}',
                    Colors.pink,
                  ),
                if (user.bloodType.isNotEmpty)
                  _buildTagChip(
                    Icons.favorite,
                    'Blood: ${user.bloodType}',
                    Colors.red,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentsGrid(BuildContext context, Community user) {
    return Consumer(
      builder: (context, ref, child) {
        final momentsAsync = ref.watch(userMomentsProvider(user.id));

        return momentsAsync.when(
          data: (moments) {
            if (moments.isEmpty) return const SizedBox.shrink();

            final previewMoments = moments.take(9).toList();

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Moments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileMoments(id: user.id),
                            ),
                          ).then((_) => mounted
                              ? ref.invalidate(userMomentsProvider(user.id))
                              : null);
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: previewMoments.length,
                    itemBuilder: (context, index) {
                      final moment = previewMoments[index];
                      final imageUrl = moment.imageUrls.isNotEmpty
                          ? ImageUtils.normalizeImageUrl(moment.imageUrls[0])
                          : null;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageUrl != null
                            ? CachedImageWidget(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.grey[400],
                                    size: 32,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey[400],
                                  size: 32,
                                ),
                              ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }
}
