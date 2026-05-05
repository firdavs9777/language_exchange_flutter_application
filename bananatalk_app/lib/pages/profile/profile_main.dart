import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/widgets/ads/ad_widgets.dart';
import 'package:bananatalk_app/pages/profile/edit_main/edit_main.dart'
    show ProfileEdit;
import 'package:bananatalk_app/pages/profile/followers.dart';
import 'package:bananatalk_app/pages/profile/followings.dart';
import 'package:bananatalk_app/pages/profile/drawer/profile_drawer.dart';
import 'package:bananatalk_app/pages/profile/moments/moments_list.dart';
import 'package:bananatalk_app/pages/profile/highlights.dart';
import 'package:bananatalk_app/pages/profile/visitors_screen.dart';
import 'package:bananatalk_app/pages/profile/edit/picture_edit.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:bananatalk_app/services/global_chat_listener.dart';
import 'package:bananatalk_app/providers/provider_root/profile_visitor_provider.dart';
import 'package:bananatalk_app/widgets/profile/profile_main_skeleton.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/utils/haptic_utils.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/vip/vip_plans_screen.dart';
import 'package:bananatalk_app/widgets/vip_locked_feature.dart';
import 'package:bananatalk_app/pages/vip/vip_status_screen.dart';
import 'package:bananatalk_app/widgets/vip_avatar_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

class ProfileMain extends ConsumerStatefulWidget {
  const ProfileMain({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileMain> createState() => _ProfileMainState();
}

class _ProfileMainState extends ConsumerState<ProfileMain> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(userProvider));
  }

  int? _calculateAge(String birthYear) {
    if (birthYear.isEmpty) return null;
    final year = int.tryParse(birthYear);
    if (year == null) return null;
    return DateTime.now().year - year;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
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
        color: AppColors.primary,
        onRefresh: () async {
          HapticUtils.onRefresh();
          final currentUser = ref.read(userProvider).valueOrNull;
          ref.invalidate(userProvider);
          ref.invalidate(myVisitorStatsProvider);
          if (currentUser != null) {
            ref.invalidate(userMomentsProvider(currentUser.id));
          }
          await ref.read(userProvider.future);
        },
        child: userAsync.when(
          skipLoadingOnRefresh: true,
          data: (user) => CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildSliverAppBar(context, user),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildHeroProfile(user)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(
                          begin: 0.02,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 16),
                    _buildEditProfileButton(
                      context,
                      user,
                    ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
                    const SizedBox(height: 16),
                    _buildStatsRow(
                      context,
                      user,
                    ).animate().fadeIn(duration: 350.ms, delay: 150.ms),
                    const SizedBox(height: 20),
                    _buildProfileCompletionCard(
                      user,
                    ).animate().fadeIn(duration: 350.ms, delay: 200.ms),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SmallBannerAdWidget(),
                    ),
                    const SizedBox(height: 20),
                    _buildVipStatusCard(
                      context,
                      user,
                    ).animate().fadeIn(duration: 350.ms, delay: 250.ms),
                    const SizedBox(height: 20),
                    ProfileHighlights(
                      userId: user.id,
                      isOwnProfile: true,
                      user: user,
                    ).animate().fadeIn(duration: 350.ms, delay: 275.ms),
                    const SizedBox(height: 20),
                    _buildLanguageCard(
                      user,
                    ).animate().fadeIn(duration: 350.ms, delay: 300.ms),
                    const SizedBox(height: 16),
                    _buildAboutCard(
                      user,
                    ).animate().fadeIn(duration: 350.ms, delay: 350.ms),
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
          loading: () => const ProfileMainSkeleton(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  // ========== APP BAR ==========
  Widget _buildSliverAppBar(BuildContext context, Community user) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: context.surfaceColor,
      foregroundColor: context.textPrimary,
      automaticallyImplyLeading: false,
      title: Text(
        user.name.isNotEmpty ? user.name : 'Profile',
        style: context.titleLarge.copyWith(fontWeight: FontWeight.w800),
      ),
      actions: [
        Builder(
          builder: (ctx) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.containerColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color: context.textPrimary,
                  size: 22,
                ),
              ),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ),
      ],
    );
  }

  // ========== HERO PROFILE (avatar + name + chips) ==========
  Widget _buildHeroProfile(Community user) {
    final calculatedAge = _calculateAge(user.birth_year);
    final age = PrivacyUtils.getAge(user, calculatedAge);
    final locationText = PrivacyUtils.getLocationText(user);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                AppPageRoute(
                  builder: (context) => ProfilePictureEdit(user: user),
                ),
              );
              if (mounted) ref.invalidate(userProvider);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                user.isVip
                    ? VipAvatarFrame(
                        isVip: true,
                        size: 124,
                        frameWidth: 4,
                        showGlow: true,
                        child: _buildAvatarInner(user, 60),
                      )
                    : Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00BFA5,
                              ).withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            shape: BoxShape.circle,
                          ),
                          child: _buildAvatarInner(user, 60),
                        ),
                      ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.surfaceColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Name + verified badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.name,
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user.isVip) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFFFFD700),
                  size: 22,
                ),
              ],
            ],
          ),

          // Username
          if (user.displayUsername != null) ...[
            const SizedBox(height: 4),
            Text(
              user.displayUsername!,
              style: context.bodyMedium.copyWith(
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // Info chips
          if (age != null || locationText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (age != null)
                  _buildInfoChip(
                    Icons.cake_rounded,
                    AppLocalizations.of(context)!.yearsOld(age.toString()),
                    const Color(0xFF9C27B0),
                  ),
                if (locationText.isNotEmpty)
                  _buildInfoChip(
                    Icons.location_on_rounded,
                    locationText,
                    const Color(0xFF2196F3),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarInner(Community user, double radius) {
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: user.imageUrls.isNotEmpty
            ? CachedImageWidget(imageUrl: user.imageUrls[0], fit: BoxFit.cover)
            : Container(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person_rounded,
                  size: radius,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
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

  // ========== EDIT PROFILE BUTTON ==========
  Widget _buildEditProfileButton(BuildContext context, Community user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                AppPageRoute(
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.editProfile,
                      style: context.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== STATS ROW (4 in a single card) ==========
  Widget _buildStatsRow(BuildContext context, Community user) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                value: user.followers.length.toString(),
                label: l10n.followers,
                icon: Icons.people_rounded,
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (context) => ProfileFollowers(
                        id: user.id,
                        followerIds: user.followers,
                      ),
                    ),
                  ).then((_) => mounted ? ref.invalidate(userProvider) : null);
                },
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: _buildStatItem(
                value: user.followings.length.toString(),
                label: l10n.following,
                icon: Icons.person_add_rounded,
                color: const Color(0xFF2196F3),
                onTap: () {
                  Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (context) => ProfileFollowings(
                        id: user.id,
                        followingIds: user.followings,
                      ),
                    ),
                  ).then((_) => mounted ? ref.invalidate(userProvider) : null);
                },
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final momentsAsync = ref.watch(userMomentsProvider(user.id));
                  return momentsAsync.when(
                    data: (moments) => _buildStatItem(
                      value: moments.length.toString(),
                      label: l10n.moments,
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFF9C27B0),
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) => ProfileMoments(id: user.id),
                          ),
                        ).then(
                          (_) => mounted
                              ? ref.invalidate(userMomentsProvider(user.id))
                              : null,
                        );
                      },
                    ),
                    loading: () => _buildStatItem(
                      value: '...',
                      label: l10n.moments,
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFF9C27B0),
                      onTap: () {},
                    ),
                    error: (_, __) => _buildStatItem(
                      value: '0',
                      label: l10n.moments,
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFF9C27B0),
                      onTap: () {},
                    ),
                  );
                },
              ),
            ),
            _buildVerticalDivider(),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final visitorStatsAsync = ref.watch(myVisitorStatsProvider);

                  void openVisitors() {
                    if (user.isVip) {
                      Navigator.push(
                        context,
                        AppPageRoute(
                          builder: (_) =>
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
                  }

                  return visitorStatsAsync.when(
                    loading: () => _buildStatItem(
                      value: '...',
                      label: l10n.visitors,
                      icon: Icons.visibility_rounded,
                      color: const Color(0xFFFF9800),
                      onTap: () {},
                      lockedForVip: !user.isVip,
                    ),
                    error: (_, __) => _buildStatItem(
                      value: '0',
                      label: l10n.visitors,
                      icon: Icons.visibility_rounded,
                      color: const Color(0xFFFF9800),
                      onTap: openVisitors,
                      lockedForVip: !user.isVip,
                    ),
                    data: (data) {
                      final stats = data['stats'];
                      final uniqueVisitors = stats?['uniqueVisitors'] ?? 0;
                      return _buildStatItem(
                        value: data['success'] == true
                            ? uniqueVisitors.toString()
                            : '0',
                        label: l10n.visitors,
                        icon: Icons.visibility_rounded,
                        color: const Color(0xFFFF9800),
                        onTap: openVisitors,
                        lockedForVip: !user.isVip,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: context.dividerColor.withValues(alpha: 0.4),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool lockedForVip = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 22),
                  if (lockedForVip)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD700),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: context.captionSmall.copyWith(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== PROFILE COMPLETION CARD ==========
  Map<String, dynamic> _calculateProfileCompletion(Community user) {
    final fields = <String, bool>{
      'Profile Picture': user.imageUrls.isNotEmpty,
      'Name': user.name.isNotEmpty,
      'Bio': user.bio.isNotEmpty,
      'Native Language': user.native_language.isNotEmpty,
      'Learning Language': user.language_to_learn.isNotEmpty,
      'Location':
          user.location.country.isNotEmpty || user.location.city.isNotEmpty,
      'Topics': user.topics.isNotEmpty,
      'MBTI': user.mbti.isNotEmpty,
      'Birth Year': user.birth_year.isNotEmpty,
    };

    final completed = fields.values.where((v) => v).length;
    final percentage = (completed / fields.length * 100).round();
    final missing = fields.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .take(3)
        .toList();

    return {'percentage': percentage, 'missing': missing};
  }

  Widget _buildProfileCompletionCard(Community user) {
    final completion = _calculateProfileCompletion(user);
    final percentage = completion['percentage'] as int;
    final missing = completion['missing'] as List<String>;

    if (percentage >= 100) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color color;
    String statusText;
    IconData statusIcon;
    if (percentage < 50) {
      color = const Color(0xFFFF9800);
      statusText = 'Just getting started';
      statusIcon = Icons.rocket_launch_rounded;
    } else if (percentage < 80) {
      color = const Color(0xFF2196F3);
      statusText = 'Looking good!';
      statusIcon = Icons.trending_up_rounded;
    } else {
      color = AppColors.primary;
      statusText = 'Almost there!';
      statusIcon = Icons.celebration_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Completion',
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: context.captionSmall.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: context.titleLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.lightbulb_rounded, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Add: ${missing.join(", ")}',
                    style: context.captionSmall.copyWith(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
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

  // ========== VIP STATUS CARD ==========
  Widget _buildVipStatusCard(BuildContext context, Community user) {
    final isVip = user.isVip;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              AppPageRoute(
                builder: (_) => isVip
                    ? VipStatusScreen(userId: user.id)
                    : VipPlansScreen(userId: user.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: isVip
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    )
                  : null,
              color: isVip ? null : context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: isVip
                  ? null
                  : Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
              boxShadow: isVip
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isVip
                          ? Colors.white.withValues(alpha: 0.25)
                          : const Color(0xFFFFD700).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: isVip ? Colors.white : const Color(0xFFFFD700),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isVip ? 'VIP Member' : 'Upgrade to VIP',
                              style: context.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isVip
                                    ? Colors.white
                                    : context.textPrimary,
                              ),
                            ),
                            if (isVip) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isVip
                              ? 'Enjoying premium features'
                              : 'Unlock unlimited messages & AI tools',
                          style: context.bodySmall.copyWith(
                            color: isVip
                                ? Colors.white.withValues(alpha: 0.9)
                                : context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isVip ? Colors.white : const Color(0xFFFFD700),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== LANGUAGE CARD ==========
  Widget _buildLanguageCard(Community user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                l10n.languageExchange,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildLanguageRow(
            label: l10n.nativeLanguage,
            language: user.native_language.isEmpty
                ? l10n.notSet
                : user.native_language,
            flag: _getLanguageFlag(user.native_language),
            color: AppColors.primary,
            level: 'Native',
            isNative: true,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: context.dividerColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 14),
          _buildLanguageRow(
            label: l10n.learning,
            language: user.language_to_learn.isEmpty
                ? l10n.notSet
                : user.language_to_learn,
            flag: _getLanguageFlag(user.language_to_learn),
            color: const Color(0xFFFF9800),
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
    required String flag,
    required Color color,
    required String? level,
    required bool isNative,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(flag, style: const TextStyle(fontSize: 24)),
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
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                language,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!isNative && level != null && level.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildProficiencyBar(level, color, isDark),
              ] else if (isNative) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 12, color: color),
                      const SizedBox(width: 3),
                      Text(
                        'Native',
                        style: context.captionSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _getLanguageFlag(String language) =>
      LanguageFlags.getFlagByName(language);

  Widget _buildProficiencyBar(String level, Color color, bool isDark) {
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    final currentIndex = levels.indexOf(level.toUpperCase());

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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                level.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              levelDesc,
              style: context.captionSmall.copyWith(
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
                            ? Colors.white.withValues(alpha: 0.08)
                            : color.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ========== ABOUT CARD ==========
  Widget _buildAboutCard(Community user) {
    if (user.bio.isEmpty && user.mbti.isEmpty && user.bloodType.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.aboutMe,
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : context.containerColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                user.bio,
                style: context.bodyMedium.copyWith(
                  color: context.textPrimary,
                  height: 1.55,
                ),
              ),
            ),
          ],
          if (user.mbti.isNotEmpty || user.bloodType.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (user.mbti.isNotEmpty)
                  _buildTagChip(
                    '🧠',
                    user.mbti.toUpperCase(),
                    const Color(0xFF673AB7),
                    isDark,
                  ),
                if (user.bloodType.isNotEmpty)
                  _buildTagChip(
                    '🩸',
                    user.bloodType.toUpperCase(),
                    const Color(0xFFE53935),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ========== MOMENTS GRID ==========
  Widget _buildMomentsGrid(BuildContext context, Community user) {
    return Consumer(
      builder: (context, ref, child) {
        final momentsAsync = ref.watch(userMomentsProvider(user.id));
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return momentsAsync.when(
          data: (moments) {
            if (moments.isEmpty) return const SizedBox.shrink();
            final previewMoments = moments.take(9).toList();

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: isDark
                    ? Border.all(color: Colors.white.withValues(alpha: 0.06))
                    : null,
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E63),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            AppLocalizations.of(context)!.recentMoments,
                            style: context.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            AppPageRoute(
                              builder: (context) => ProfileMoments(id: user.id),
                            ),
                          ).then(
                            (_) => mounted
                                ? ref.invalidate(userMomentsProvider(user.id))
                                : null,
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.seeAll,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                    itemCount: previewMoments.length,
                    itemBuilder: (context, index) {
                      final moment = previewMoments[index];
                      final imageUrl = moment.imageUrls.isNotEmpty
                          ? ImageUtils.normalizeImageUrl(moment.imageUrls[0])
                          : null;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl != null
                            ? CachedImageWidget(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: context.containerColor,
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    color: context.iconColor,
                                  ),
                                ),
                              )
                            : Container(
                                color: context.containerColor,
                                child: Icon(
                                  Icons.image_rounded,
                                  color: context.iconColor,
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
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  // ========== LOGOUT BUTTON ==========
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: () => _showLogoutConfirmation(context),
          icon: Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
          label: Text(
            AppLocalizations.of(context)!.logout,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== ERROR STATE ==========
  Widget _buildErrorState(Object error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n.error}: $error',
              style: context.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(userProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== LOGOUT CONFIRMATION (modernized) ==========
  void _showLogoutConfirmation(BuildContext context) {
    final rootContext = context;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext dialogContext) {
        bool isLoggingOut = false;

        return StatefulBuilder(
          builder: (_, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: context.surfaceColor,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.logout,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.logoutConfirmMessage,
                      style: context.bodySmall.copyWith(
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isLoggingOut) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(l10n.loggingOut, style: context.bodySmall),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (!isLoggingOut)
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: context.containerColor,
                              ),
                              child: Text(
                                l10n.cancel,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                setState(() => isLoggingOut = true);
                                try {
                                  GlobalChatListener().stop();
                                  await ref.read(authServiceProvider).logout();
                                  await ChatSocketService().disconnect();
                                  ref.read(badgeCountProvider.notifier).reset();
                                  ref
                                      .read(chatPartnersProvider.notifier)
                                      .reset();
                                  ref.invalidate(userProvider);
                                  ref.invalidate(authServiceProvider);

                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }

                                  if (rootContext.mounted) {
                                    rootContext.go('/login');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                l10n.loggedOutSuccessfully,
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: AppColors.success,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.all(16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (error) {
                                  setState(() => isLoggingOut = false);
                                  if (dialogContext.mounted) {
                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text('Logout failed: $error'),
                                        backgroundColor: AppColors.error,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: AppColors.error,
                              ),
                              child: Text(
                                l10n.logout,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
