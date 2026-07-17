import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/presence_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/widgets/vip_avatar_frame.dart';
import 'package:bananatalk_app/widgets/story/story_gradient_ring.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:bananatalk_app/widgets/report_dialog.dart';
import 'package:bananatalk_app/widgets/block_user_dialog.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/utils/language_flags.dart';
import 'package:bananatalk_app/widgets/language_flag_badge.dart';

/// Instagram-style header for the community/profile detail screen:
/// ringed avatar + display-only stat counters (Posts/Followers/Following),
/// name + language line, and a collapsed/expandable bio.
///
/// Rendered as a plain [SliverToBoxAdapter] child below a name-only
/// [SliverAppBar] (see [single_community_screen.dart]) — it no longer draws
/// its own hero background; the visual "hero" is the ringed avatar itself.
class SingleCommunityHeader extends ConsumerStatefulWidget {
  final Community community;
  final int? age;
  final String locationText;
  final VoidCallback onCopyUsername;
  final String? profileImageUrl;

  /// Tap target for the avatar. The caller decides whether to open the
  /// story viewer (via [StoryViewerLauncher], only when
  /// `community.hasActiveStory`) or fall back to the profile-photo view —
  /// keeping that navigation/service-call logic in the screen rather than
  /// this presentational widget.
  final VoidCallback onAvatarTap;

  const SingleCommunityHeader({
    super.key,
    required this.community,
    required this.age,
    required this.locationText,
    required this.onCopyUsername,
    required this.profileImageUrl,
    required this.onAvatarTap,
  });

  @override
  ConsumerState<SingleCommunityHeader> createState() =>
      _SingleCommunityHeaderState();
}

class _SingleCommunityHeaderState extends ConsumerState<SingleCommunityHeader> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final community = widget.community;
    final presenceState = ref.watch(presenceProvider);

    return Container(
      color: context.surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + display-only stat counters
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(context),
              const SizedBox(width: 20),
              Expanded(child: _buildStatsRow(context, l10n)),
            ],
          ),
          const SizedBox(height: 16),

          // Name + VIP badge
          Row(
            children: [
              Flexible(
                child: Text(
                  community.name,
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (community.isVip) ...[
                const SizedBox(width: 8),
                _buildVipBadge(),
              ],
            ],
          ),

          // Username + copy
          if (community.displayUsername != null) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  community.displayUsername!,
                  style: context.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: widget.onCopyUsername,
                  child: Icon(
                    Icons.copy_rounded,
                    color: context.textMuted,
                    size: 14,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // Native → learning language line with flags
          _buildLanguageLine(context, l10n),

          // Age / location chips
          if (widget.age != null || widget.locationText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (widget.age != null)
                  _buildInfoChip(
                    context,
                    Icons.cake_rounded,
                    l10n.yearsOld(widget.age.toString()),
                  ),
                if (widget.locationText.isNotEmpty)
                  _buildInfoChip(
                    context,
                    Icons.location_on_rounded,
                    widget.locationText,
                  ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          _buildPresencePill(context, l10n, presenceState),

          // Collapsed / expandable bio
          if (community.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ExpandableBio(bio: community.bio),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Avatar (84px, story-ringed when hasActiveStory, VIP-framed otherwise)
  // ---------------------------------------------------------------------------

  Widget _buildAvatar(BuildContext context) {
    const size = 84.0;
    final community = widget.community;

    Widget inner = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: widget.profileImageUrl != null
            ? CachedImageWidget(
                imageUrl: widget.profileImageUrl!,
                fit: BoxFit.cover,
              )
            : Container(
                color: AppColors.accent.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.person_rounded,
                  size: size * 0.5,
                  color: AppColors.accent,
                ),
              ),
      ),
    );

    // Story ring takes visual priority when the user has an active story;
    // otherwise fall back to the VIP frame/glow treatment.
    Widget avatar;
    if (community.hasActiveStory) {
      avatar = StoryGradientRing(
        size: size,
        strokeWidth: 3,
        hasStory: true,
        animate: false,
        child: inner,
      );
    } else if (community.isVip) {
      avatar = VipAvatarFrame(
        isVip: true,
        size: size,
        frameWidth: 3,
        showGlow: true,
        child: inner,
      );
    } else {
      avatar = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.dividerColor, width: 1),
        ),
        child: inner,
      );
    }

    return GestureDetector(
      onTap: widget.onAvatarTap,
      child: Hero(
        tag: 'profile_${community.id}',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            LanguageFlagBadge(
              nativeLanguage: community.native_language,
              size: 22,
              offset: 0,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stat counters — display only, no tap navigation (Option B)
  // ---------------------------------------------------------------------------

  Widget _buildStatsRow(BuildContext context, AppLocalizations l10n) {
    final momentsAsync = ref.watch(userMomentsProvider(widget.community.id));
    final postsCount = momentsAsync.valueOrNull?.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatColumn(
          value: postsCount?.toString() ?? '-',
          label: l10n.moments,
        ),
        _StatColumn(
          value: widget.community.followers.length.toString(),
          label: l10n.followers,
        ),
        _StatColumn(
          value: widget.community.followings.length.toString(),
          label: l10n.following,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Language line
  // ---------------------------------------------------------------------------

  Widget _buildLanguageLine(BuildContext context, AppLocalizations l10n) {
    final community = widget.community;
    final nativeFlag = LanguageFlags.getFlagByName(community.native_language);
    final learningFlag = LanguageFlags.getFlagByName(
      community.language_to_learn,
    );

    return Row(
      children: [
        Text(nativeFlag, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            community.native_language,
            style: context.bodySmall.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.arrow_forward_rounded, size: 14, color: context.textMuted),
        const SizedBox(width: 6),
        Text(learningFlag, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            community.language_to_learn,
            style: context.bodySmall.copyWith(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.captionSmall.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildVipBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 12, color: Colors.white),
          SizedBox(width: 2),
          Text(
            'VIP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresencePill(
    BuildContext context,
    AppLocalizations l10n,
    PresenceState presenceState,
  ) {
    final community = widget.community;
    if (presenceState.isOnline(community.id)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            l10n.onlineNow,
            style: context.captionSmall.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    final lastSeen = presenceState.lastSeen[community.id];
    if (lastSeen != null) {
      return Text(
        l10n.activeAgo(timeago.format(lastSeen)),
        style: context.captionSmall.copyWith(color: context.textMuted),
      );
    }
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// Stat column (display only)
// ---------------------------------------------------------------------------

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
          style: context.captionSmall.copyWith(color: context.textSecondary),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable bio (3-line collapse + "show more"/"show less")
// ---------------------------------------------------------------------------

class _ExpandableBio extends StatefulWidget {
  final String bio;
  const _ExpandableBio({required this.bio});

  @override
  State<_ExpandableBio> createState() => _ExpandableBioState();
}

class _ExpandableBioState extends State<_ExpandableBio> {
  bool _expanded = false;
  bool _isTruncated = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = context.bodySmall.copyWith(
      color: context.textPrimary,
      height: 1.4,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_expanded) {
          final painter = TextPainter(
            text: TextSpan(text: widget.bio, style: style),
            maxLines: 3,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: constraints.maxWidth);
          _isTruncated = painter.didExceedMaxLines;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bio,
              style: style,
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (_isTruncated || _expanded)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _expanded ? l10n.showLess : l10n.showMore,
                    style: context.captionSmall.copyWith(
                      color: context.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// AppBar "more" menu (report / block / unblock).
/// Extracted so it can be built inline in the SliverAppBar actions list.
class SingleCommunityMoreMenu extends ConsumerWidget {
  final Community community;
  final String currentUserId;
  final bool isScrolled;
  final bool isBlocked;
  final String? profileImageUrl;
  final VoidCallback onBlocked;
  final Future<void> Function() onUnblock;

  const SingleCommunityMoreMenu({
    super.key,
    required this.community,
    required this.currentUserId,
    required this.isScrolled,
    required this.isBlocked,
    required this.profileImageUrl,
    required this.onBlocked,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: context.textPrimary),
      onSelected: (value) async {
        if (value == 'report') {
          showDialog(
            context: context,
            builder: (context) => ReportDialog(
              type: 'user',
              reportedId: community.id,
              reportedUserId: community.id,
            ),
          );
        } else if (value == 'block') {
          if (currentUserId.isNotEmpty && currentUserId != community.id) {
            await BlockUserDialog.show(
              context: context,
              currentUserId: currentUserId,
              targetUserId: community.id,
              targetUserName: community.name,
              targetUserAvatar: profileImageUrl,
              ref: ref,
              onBlocked: () {
                onBlocked();
                if (context.mounted) Navigator.of(context).pop();
              },
            );
          }
        } else if (value == 'unblock') {
          await onUnblock();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(l10n.reportUser),
            ],
          ),
        ),
        if (isBlocked)
          PopupMenuItem(
            value: 'unblock',
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.unblockUser,
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          )
        else
          PopupMenuItem(
            value: 'block',
            child: Row(
              children: [
                const Icon(Icons.block, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(l10n.blockUser, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }
}
