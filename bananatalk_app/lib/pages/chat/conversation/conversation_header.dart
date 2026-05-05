import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/providers/chat_state_provider.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/pages/chat/header/chat_app_bar.dart';
import 'package:bananatalk_app/utils/privacy_utils.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/community/single_community.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

/// AppBar section for the conversation screen.
///
/// Watches [singleCommunityProvider] to honour the partner's privacy settings
/// (whether online status / last-seen are visible), then delegates rendering
/// to the shared [ChatAppBar] widget.
///
/// All mutable state lives in [_ChatScreenState]; this widget only receives
/// what it needs as constructor params.
class ConversationHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String userName;
  final String? profilePicture;
  final String userId;
  final bool isVip;
  final bool isTyping;
  final bool isSocketConnected;
  final ConnectionStatus? connectionStatus;
  final bool isOtherUserOnline;
  final String? otherUserLastSeen;
  final VoidCallback onThemeChanged;

  const ConversationHeader({
    super.key,
    required this.userName,
    this.profilePicture,
    required this.userId,
    required this.isVip,
    required this.isTyping,
    required this.isSocketConnected,
    this.connectionStatus,
    required this.isOtherUserOnline,
    this.otherUserLastSeen,
    required this.onThemeChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserAsync = ref.watch(singleCommunityProvider(userId));
    final showOnlineStatus =
        otherUserAsync.whenOrNull(
          data: (community) => community != null
              ? PrivacyUtils.shouldShowOnlineStatus(community)
              : true,
        ) ??
        true;

    return ChatAppBar(
      userName: userName,
      profilePicture: profilePicture,
      isTyping: isTyping,
      userId: userId,
      isConnected: isSocketConnected,
      connectionStatus: connectionStatus,
      isOnline: showOnlineStatus ? isOtherUserOnline : null,
      lastSeen: showOnlineStatus ? otherUserLastSeen : null,
      onThemeChanged: onThemeChanged,
      isVip: isVip,
    );
  }
}

/// Scrollable user-info card rendered at the top of the message list.
///
/// Shows avatar (100 px), name, age badge, location, bio, up to 5 topic chips,
/// and a divider. Tapping the avatar navigates to the full community/profile
/// screen. All data is fetched from [singleCommunityProvider].
class ConversationUserInfoHeader extends ConsumerWidget {
  final String userId;
  final String userName;
  final String? profilePicture;

  const ConversationUserInfoHeader({
    super.key,
    required this.userId,
    required this.userName,
    this.profilePicture,
  });

  void _navigateToProfile(BuildContext context, dynamic user) {
    if (user != null) {
      Navigator.push(
        context,
        AppPageRoute(builder: (_) => SingleCommunity(community: user)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityAsync = ref.watch(singleCommunityProvider(userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return communityAsync.when(
      data: (user) {
        int? age;
        if (user?.birth_year != null && user!.birth_year.isNotEmpty) {
          try {
            final birthYear = int.parse(user.birth_year);
            age = DateTime.now().year - birthYear;
          } catch (_) {}
        }

        String? location;
        if (user != null) {
          final locText = PrivacyUtils.getLocationText(user);
          if (locText.isNotEmpty) location = locText;
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar (100 px)
              GestureDetector(
                onTap: () => _navigateToProfile(context, user),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: profilePicture != null && profilePicture!.isNotEmpty
                        ? Image.network(
                            profilePicture!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              child: const Icon(Icons.person, size: 50, color: AppColors.primary),
                            ),
                          )
                        : Container(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            child: const Icon(Icons.person, size: 50, color: AppColors.primary),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Name + age badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.gray900,
                    ),
                  ),
                  if (age != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$age',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Location
              if (location != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.gray400 : AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ],

              // Bio
              if (user?.bio != null && user!.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.05)
                        : AppColors.gray500.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.bio,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],

              // Topic chips (up to 5)
              if (user?.topics != null && user!.topics.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: user.topics.take(5).map((topic) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        topic,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 8),
              Divider(
                color: isDark ? AppColors.gray700 : AppColors.gray300,
                height: 1,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
