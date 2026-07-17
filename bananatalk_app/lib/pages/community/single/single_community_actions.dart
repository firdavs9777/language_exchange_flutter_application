import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/pages/community/widgets/send_wave_sheet.dart';
import 'package:bananatalk_app/pages/community/widgets/conversation_starter_ribbon.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Instagram-style full-width action row below the profile header:
/// Follow (filled teal) | Message (outlined) | Wave (outlined square icon).
///
/// The Wave button is hidden when the profile belongs to the current user.
/// The button is permanently greyed out once the current user has ever
/// waved at this person — one wave per user pair, ever (backend-enforced
/// via ALREADY_WAVED/400; this is just the local mirror).
///
/// Video/voice call entry points were removed from this row as part of the
/// Instagram-style redesign — they remain reachable from the chat header
/// (see chat_app_bar.dart) once a conversation is open.
class SingleCommunityActions extends ConsumerWidget {
  final Community community;
  final bool isFollower;
  final VoidCallback onMessage;
  final VoidCallback onFollowToggle;

  const SingleCommunityActions({
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          bottom: BorderSide(color: context.dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // IntrinsicHeight lets the three buttons share a common height
          // (driven by the tallest, the 46px Wave square) without using
          // CrossAxisAlignment.stretch — stretch on a horizontal Row demands
          // a bounded Row height, which this sliver-hosted Column can't give,
          // and would crash with a BoxConstraints-forces-infinite-height error.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildFollowButton(context, l10n)),
                const SizedBox(width: 10),
                Expanded(child: _buildMessageButton(context, l10n)),
                if (!isOwnProfile) ...[
                  const SizedBox(width: 10),
                  FutureBuilder<bool>(
                    future: _alreadyWaved(community.id),
                    builder: (context, snapshot) {
                      final alreadyWaved = snapshot.data ?? false;
                      return _buildWaveButton(context, alreadyWaved);
                    },
                  ),
                ],
              ],
            ),
          ),
          if (!isOwnProfile) ...[
            const SizedBox(height: 8),
            ConversationStarterRibbon(community: community),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Follow — filled teal when not following, outlined "Following" once followed
  // ---------------------------------------------------------------------------

  Widget _buildFollowButton(BuildContext context, AppLocalizations l10n) {
    if (isFollower) {
      return OutlinedButton.icon(
        onPressed: onFollowToggle,
        icon: const Icon(Icons.check_circle_rounded, size: 18),
        label: Text(l10n.following),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.textPrimary,
          side: BorderSide(color: context.dividerColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onFollowToggle,
      icon: const Icon(Icons.person_add_rounded, size: 18),
      label: Text(l10n.follow),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Message — outlined
  // ---------------------------------------------------------------------------

  Widget _buildMessageButton(BuildContext context, AppLocalizations l10n) {
    return OutlinedButton.icon(
      onPressed: onMessage,
      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
      label: Text(l10n.message),
      style: OutlinedButton.styleFrom(
        foregroundColor: context.textPrimary,
        side: BorderSide(color: context.dividerColor),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Icon(Icons.waving_hand_rounded, color: color, size: 20),
        ),
      ),
    );
  }
}
