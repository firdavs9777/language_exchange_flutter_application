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
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:bananatalk_app/services/profile_visitor_service.dart';
import 'package:bananatalk_app/services/global_chat_listener.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/widgets/vip_locked_feature.dart';
import 'package:bananatalk_app/pages/vip/vip_status_screen.dart';
import 'package:bananatalk_app/widgets/vip_avatar_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
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

  int? _calculateAge(String birthYear) {
    if (birthYear.isEmpty) return null;
    final year = int.tryParse(birthYear);
    if (year == null) return null;
    final currentYear = DateTime.now().year;
    return currentYear - year;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      extendBodyBehindAppBar: true,
      endDrawer: Builder(
        builder: (context) {
          return userAsync.when(
            data: (user) => LeftDrawer(user: user),
            loading: () =>
                const Drawer(child: Center(child: CircularProgressIndicator())),
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
          HapticUtils.onRefresh();
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
                    const SizedBox(height: 16),
                    _buildProfileCompletionCard(user),
                    const SizedBox(height: 20),
                    _buildQuickActions(context, user),
                    const SizedBox(height: 20),
                    _buildStatsCards(context, user),
                    const SizedBox(height: 20),
                    _buildVipStatusCard(context, user),
                    const SizedBox(height: 16),
                    _buildLanguageCard(user),
                    const SizedBox(height: 16),
                    _buildAboutCard(user),
                    const SizedBox(height: 16),
                    _buildMomentsGrid(context, user),
                    const SizedBox(height: 24),
                    _buildLogoutButton(context),
                    const SizedBox(height: 100),
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
                // Use VIP golden frame for VIP users, regular gradient for others
                user.isVip
                    ? VipAvatarFrame(
                        isVip: true,
                        size: 128,
                        frameWidth: 4,
                        showGlow: true,
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
                                  backgroundColor: const Color(
                                    0xFFFFD700,
                                  ).withOpacity(0.1),
                                  child: const Icon(
                                    Icons.person,
                                    size: 64,
                                    color: Color(0xFFFFD700),
                                  ),
                                ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
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
                                  backgroundColor: const Color(
                                    0xFF00BFA5,
                                  ).withOpacity(0.1),
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

          Spacing.gapMD,

          // Name
          Text(user.name, style: context.displayMedium, textAlign: TextAlign.center),

          // Username
          if (user.displayUsername != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                user.displayUsername!,
                style: context.bodyMedium.copyWith(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          Spacing.gapSM,

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          Spacing.hGapXS,
          Text(label, style: context.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }

  /// Calculate profile completion percentage
  Map<String, dynamic> _calculateProfileCompletion(Community user) {
    final fields = <String, bool>{
      'Profile Picture': user.imageUrls.isNotEmpty,
      'Name': user.name.isNotEmpty,
      'Bio': user.bio.isNotEmpty,
      'Native Language': user.native_language.isNotEmpty,
      'Learning Language': user.language_to_learn.isNotEmpty,
      'Location': user.location.country.isNotEmpty || user.location.city.isNotEmpty,
      'Topics': user.topics.isNotEmpty,
      'MBTI': user.mbti.isNotEmpty,
      'Birth Year': user.birth_year.isNotEmpty,
    };

    final completed = fields.values.where((v) => v).length;
    final total = fields.length;
    final percentage = (completed / total * 100).round();

    // Find missing fields for suggestions
    final missing = fields.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .take(3)
        .toList();

    return {
      'percentage': percentage,
      'completed': completed,
      'total': total,
      'missing': missing,
    };
  }

  Widget _buildProfileCompletionCard(Community user) {
    final completion = _calculateProfileCompletion(user);
    final percentage = completion['percentage'] as int;
    final missing = completion['missing'] as List<String>;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Don't show if profile is 100% complete
    if (percentage >= 100) {
      return const SizedBox.shrink();
    }

    // Determine color based on completion
    Color progressColor;
    String statusText;
    IconData statusIcon;

    if (percentage < 50) {
      progressColor = Colors.orange;
      statusText = 'Just getting started';
      statusIcon = Icons.rocket_launch_rounded;
    } else if (percentage < 80) {
      progressColor = Colors.blue;
      statusText = 'Looking good!';
      statusIcon = Icons.trending_up_rounded;
    } else {
      progressColor = AppColors.primary;
      statusText = 'Almost there!';
      statusIcon = Icons.celebration_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : progressColor.withValues(alpha: 0.2),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: progressColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: progressColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Completion',
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: context.captionSmall.copyWith(
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Percentage circle
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 5,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : progressColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: context.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Progress bar
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : progressColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          // Missing fields hint
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: context.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Add: ${missing.join(", ")}',
                    style: context.captionSmall.copyWith(
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
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
                      topics: user.topics,
                      languageLevel: user.languageLevel,
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
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.colored,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                Spacing.hGapSM,
                Text(label, style: context.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
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
                        builder: (context) => ProfileFollowers(
                          id: user.id,
                          followerIds: user.followers,
                        ),
                      ),
                    ).then((_) => mounted ? ref.refresh(userProvider) : null);
                  },
                ),
              ),
              const SizedBox(width: 8),
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
                        builder: (context) => ProfileFollowings(
                          id: user.id,
                          followingIds: user.followings,
                        ),
                      ),
                    ).then((_) => mounted ? ref.refresh(userProvider) : null);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Second row: Moments and Visitors
          Row(
            children: [
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final momentsAsync = ref.watch(
                      userMomentsProvider(user.id),
                    );
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
                          ).then(
                            (_) => mounted
                                ? ref.invalidate(userMomentsProvider(user.id))
                                : null,
                          );
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
              const SizedBox(width: 8),
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
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data?['success'] != true) {
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
                        if (user.isVip) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileVisitorsScreen(userId: user.id),
                            ),
                          );
                        } else {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => const VipUpgradeSheet(
                              featureName: 'Profile Visitors',
                              description:
                                  'See who visited your profile! Upgrade to VIP to unlock visitor tracking with detailed stats.',
                            ),
                          );
                        }
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

  Widget _buildVipStatusCard(BuildContext context, Community user) {
    final isVip = user.isVip;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: isVip
              ? const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isVip ? null : context.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isVip
                  ? const Color(0xFFFFD700).withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => isVip
                      ? VipStatusScreen(userId: user.id)
                      : VipPlansScreen(userId: user.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isVip
                          ? Colors.white.withOpacity(0.2)
                          : const Color(0xFFFFD700).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      color: isVip ? Colors.white : const Color(0xFFFFD700),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVip ? 'VIP Member' : 'Upgrade to VIP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isVip ? AppColors.white : context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isVip
                              ? 'Enjoying unlimited access & premium features'
                              : 'Unlock unlimited messages, filters & AI tools',
                          style: TextStyle(
                            fontSize: 13,
                            color: isVip
                                ? AppColors.white.withValues(alpha: 0.9)
                                : context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isVip)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Upgrade',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: isDark
                ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                : null,
            boxShadow: isDark ? null : AppShadows.sm,
          ),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: isDark ? 0.3 : 0.15),
                      color.withValues(alpha: isDark ? 0.15 : 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: isDark ? 0.3 : 0.2),
                  ),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              // Value and label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: context.titleMedium.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      label,
                      style: context.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: context.textSecondary.withValues(alpha: 0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(Community user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF00897B), const Color(0xFF00695C)]
                        : [const Color(0xFF00BFA5), const Color(0xFF00897B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.languageExchange,
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Native Language
          _buildLanguageRow(
            label: AppLocalizations.of(context)!.nativeLanguage,
            language: user.native_language.isEmpty
                ? AppLocalizations.of(context)!.notSet
                : user.native_language,
            icon: Icons.home_rounded,
            color: const Color(0xFF00BFA5),
            level: 'Native',
            isNative: true,
            isDark: isDark,
          ),

          const SizedBox(height: 16),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : context.dividerColor,
          ),
          const SizedBox(height: 16),

          // Learning Language with proficiency bar
          _buildLanguageRow(
            label: AppLocalizations.of(context)!.learning,
            language: user.language_to_learn.isEmpty
                ? AppLocalizations.of(context)!.notSet
                : user.language_to_learn,
            icon: Icons.school_rounded,
            color: Colors.orange,
            level: user.languageLevel,
            isNative: false,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageRow({
    required String label,
    required String language,
    required IconData icon,
    required Color color,
    required String? level,
    required bool isNative,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.captionSmall.copyWith(
                  color: context.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                language,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              // Proficiency bar for learning language
              if (!isNative && level != null && level.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildProficiencyBar(level, color, isDark),
              ] else if (isNative) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '★ Native Speaker',
                    style: context.captionSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Build visual proficiency bar for language level (A1-C2)
  Widget _buildProficiencyBar(String level, Color color, bool isDark) {
    // CEFR levels: A1, A2, B1, B2, C1, C2
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final currentIndex = levels.indexOf(level.toUpperCase());
    final progress = currentIndex >= 0 ? (currentIndex + 1) / levels.length : 0.0;

    // Get level description
    String levelDesc;
    switch (level.toUpperCase()) {
      case 'A1':
        levelDesc = 'Beginner';
        break;
      case 'A2':
        levelDesc = 'Elementary';
        break;
      case 'B1':
        levelDesc = 'Intermediate';
        break;
      case 'B2':
        levelDesc = 'Upper Intermediate';
        break;
      case 'C1':
        levelDesc = 'Advanced';
        break;
      case 'C2':
        levelDesc = 'Proficient';
        break;
      default:
        levelDesc = level;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level label and description
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.4 : 0.3),
                ),
              ),
              child: Text(
                level.toUpperCase(),
                style: context.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              levelDesc,
              style: context.captionSmall.copyWith(
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar with level markers
        Row(
          children: List.generate(6, (index) {
            final isFilled = index <= currentIndex;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: index < 5 ? 3 : 0),
                decoration: BoxDecoration(
                  color: isFilled
                      ? color
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : color.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        // Level labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'A1',
              style: context.captionSmall.copyWith(
                color: context.textMuted,
                fontSize: 9,
              ),
            ),
            Text(
              'C2',
              style: context.captionSmall.copyWith(
                color: context.textMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutCard(Community user) {
    if (user.bio.isEmpty && user.mbti.isEmpty && user.bloodType.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.1))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Colors.purple.shade600, Colors.purple.shade800]
                          : [Colors.purple.shade400, Colors.purple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.format_quote_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.aboutMe,
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                user.bio,
                style: context.bodyMedium.copyWith(
                  color: context.textPrimary,
                  height: 1.6,
                ),
              ),
            ),
          ],
          if (user.bio.isNotEmpty &&
              (user.mbti.isNotEmpty || user.bloodType.isNotEmpty))
            const SizedBox(height: 20),
          if (user.mbti.isNotEmpty || user.bloodType.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (user.mbti.isNotEmpty)
                  _buildTagChip(
                    '🧠',
                    'MBTI: ${user.mbti.toUpperCase()}',
                    Colors.indigo,
                    isDark,
                  ),
                if (user.bloodType.isNotEmpty)
                  _buildTagChip(
                    '🩸',
                    'Blood: ${user.bloodType.toUpperCase()}',
                    Colors.red,
                    isDark,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagChip(String emoji, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            label,
            style: context.labelMedium.copyWith(
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
                color: context.cardBackground,
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
                      Text(
                        'Recent Moments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileMoments(id: user.id),
                            ),
                          ).then(
                            (_) => mounted
                                ? ref.invalidate(userMomentsProvider(user.id))
                                : null,
                          );
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(fontWeight: FontWeight.w600),
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
                                  color: context.containerColor,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: context.iconColor,
                                    size: 32,
                                  ),
                                ),
                              )
                            : Container(
                                color: context.containerColor,
                                child: Icon(
                                  Icons.image_outlined,
                                  color: context.iconColor,
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

  Widget _buildLogoutButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.error.withValues(alpha: 0.2),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showLogoutConfirmation(context),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)!.logout,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool isLoggingOut = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.logout,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you sure you want to logout from BanaTalk?',
                    style: TextStyle(fontSize: 15),
                  ),
                  if (isLoggingOut) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Logging out...',
                          style: context.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: isLoggingOut
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isLoggingOut = true;
                          });

                          try {
                            // 1. Stop global chat listener
                            GlobalChatListener().stop();

                            // 2. Disconnect socket and perform backend logout
                            await ref.read(authServiceProvider).logout();

                            // 3. Reset all providers and badge counts
                            ref.read(badgeCountProvider.notifier).reset();
                            ref.read(chatPartnersProvider.notifier).reset();

                            // 4. Invalidate providers
                            ref.invalidate(userProvider);
                            ref.invalidate(authServiceProvider);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (context.mounted) {
                              // Navigate to login and clear all routes
                              context.go('/login');

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .loggedOutSuccessfully,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (error) {
                            setState(() {
                              isLoggingOut = false;
                            });

                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Logout failed: ${error.toString()}',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.logout,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }
}
