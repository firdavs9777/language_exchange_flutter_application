import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/pages/community/widgets/send_wave_sheet.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// The profile's pinned action bar: Follow | Chat | Wave, floating over the
/// content rather than scrolling with it.
///
/// It used to be a sliver between the header and the tab bar, which meant that
/// by the time someone had scrolled into Moments or About -- the entire point
/// of the screen -- there was no way to start a conversation without scrolling
/// back up. On a language-exchange app that is the only action that matters.
///
/// The Wave button is hidden when the profile belongs to the current user.
/// The button is permanently greyed out once the current user has ever
/// waved at this person — one wave per user pair, ever (backend-enforced
/// via ALREADY_WAVED/400; this is just the local mirror).
///
/// Video/voice call entry points were removed from this row as part of the
/// Instagram-style redesign — they remain reachable from the chat header
/// (see chat_app_bar.dart) once a conversation is open.
class SingleCommunityActionBar extends ConsumerWidget {
  final Community community;
  final bool isFollower;
  final VoidCallback onMessage;
  final VoidCallback onFollowToggle;

  const SingleCommunityActionBar({
    super.key,
    required this.community,
    required this.isFollower,
    required this.onMessage,
    required this.onFollowToggle,
  });

  // Returns true if the current user has ever waved at [userId]. One wave
  // per user pair, ever — presence of the key (regardless of its stored
  // timestamp) now means "already waved," permanently. Older builds wrote
  // this same key as a 24h cooldown marker; this read is compatible with
  // those pre-existing entries too (they just never expire anymore).
  static Future<bool> _alreadyWaved(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$waveCooldownPrefsPrefix$userId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.read(authServiceProvider).userId;
    final isOwnProfile =
        currentUserId.isNotEmpty && currentUserId == community.id;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderRound,
        child: BackdropFilter(
          // Blurred rather than opaque so the content keeps showing through --
          // the bar floats over the feed, it does not cut it off.
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: context.surfaceColor.withValues(alpha: 0.92),
              borderRadius: AppRadius.borderRound,
              border: Border.all(
                color: context.dividerColor.withValues(alpha: 0.5),
              ),
              boxShadow: AppShadows.lg,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 10, child: _buildFollowButton(context, l10n)),
                  const SizedBox(width: 8),
                  Expanded(flex: 14, child: _buildMessageButton(context, l10n)),
                  if (!isOwnProfile) ...[
                    const SizedBox(width: 8),
                    FutureBuilder<bool>(
                      future: _alreadyWaved(community.id),
                      builder: (context, snapshot) =>
                          _buildWaveButton(context, snapshot.data ?? false),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Follow — filled teal when not following, outlined "Following" once followed
  // ---------------------------------------------------------------------------

  Widget _buildFollowButton(BuildContext context, AppLocalizations l10n) {
    if (isFollower) {
      return OutlinedButton.icon(
        key: const Key('action-bar-follow'),
        onPressed: onFollowToggle,
        icon: const Icon(Icons.check_circle_rounded, size: 18),
        label: Text(l10n.following),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.textPrimary,
          side: BorderSide(color: context.dividerColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: const StadiumBorder(),
        ),
      );
    }
    return ElevatedButton.icon(
      key: const Key('action-bar-follow'),
      onPressed: onFollowToggle,
      icon: const Icon(Icons.person_add_rounded, size: 18),
      label: Text(l10n.follow),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: const StadiumBorder(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Message — outlined
  // ---------------------------------------------------------------------------

  Widget _buildMessageButton(BuildContext context, AppLocalizations l10n) {
    return OutlinedButton.icon(
      key: const Key('action-bar-chat'),
      onPressed: onMessage,
      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
      label: Text(l10n.message),
      style: OutlinedButton.styleFrom(
        foregroundColor: context.textPrimary,
        side: BorderSide(color: context.dividerColor),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: const StadiumBorder(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Wave — outlined square icon button
  // ---------------------------------------------------------------------------

  Widget _buildWaveButton(BuildContext context, bool alreadyWaved) {
    final color = alreadyWaved ? context.textMuted : AppColors.primary;
    return Tooltip(
      message: alreadyWaved
          ? 'Already waved — send a message instead'
          : 'Send a wave',
      child: SizedBox(
        width: 46,
        height: 46,
        child: OutlinedButton(
          onPressed: () {
            if (alreadyWaved) {
              showCommunitySnackBar(
                context,
                message:
                    "You've already waved at ${community.name} — send them a message instead.",
                type: CommunitySnackBarType.info,
              );
              return;
            }
            showSendWaveSheet(
              context,
              targetUserId: community.id,
              targetUserName: community.name,
              targetUserCountry: community.location.country.isNotEmpty
                  ? community.location.country
                  : null,
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: context.dividerColor),
            padding: EdgeInsets.zero,
            shape: const StadiumBorder(),
          ),
          child: Icon(Icons.waving_hand_rounded, color: color, size: 20),
        ),
      ),
    );
  }
}
