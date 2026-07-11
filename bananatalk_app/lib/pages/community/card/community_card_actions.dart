import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/pages/community/widgets/send_wave_sheet.dart';
import 'package:bananatalk_app/pages/community/widgets/conversation_starter_ribbon.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Actions block for [CommunityCard].
///
/// Renders a gradient wave button. The button is hidden when the card
/// represents the currently-logged-in user. The button is permanently
/// greyed-out once the current user has ever waved at this person — one
/// wave per user pair, ever (backend-enforced via ALREADY_WAVED/400; this
/// is just the local mirror so the button doesn't need a round trip).
class CommunityCardActions extends ConsumerWidget {
  const CommunityCardActions({
    super.key,
    required this.community,
    required this.onMessageTap,
    this.onWaveTap,
  });

  final Community community;

  /// Called when the user taps the message button (reserved for future
  /// expansion; currently the whole card tap navigates to the profile).
  final VoidCallback onMessageTap;

  /// Legacy callback kept for API compatibility. Ignored when the real
  /// wave flow is active (C14+).
  final VoidCallback? onWaveTap;

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
    final currentUserId = ref.read(authServiceProvider).userId;

    // Hide wave button entirely on own profile
    if (currentUserId.isNotEmpty && currentUserId == community.id) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: _alreadyWaved(community.id),
      builder: (context, snapshot) {
        final alreadyWaved = snapshot.data ?? false;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildWaveButton(context, alreadyWaved),
            const SizedBox(height: 6),
            ConversationStarterRibbon(community: community, compact: true),
          ],
        );
      },
    );
  }

  Widget _buildWaveButton(BuildContext context, bool alreadyWaved) {
    final isActive = !alreadyWaved;
    return Tooltip(
      message: alreadyWaved
          ? 'Already waved — send a message instead'
          : 'Send a wave',
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF00ACC1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: alreadyWaved ? context.containerColor : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive && !context.isDarkMode
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Builder(
          builder: (innerContext) => Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: alreadyWaved
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      showSendWaveSheet(
                        innerContext,
                        targetUserId: community.id,
                        targetUserName: community.name,
                        targetUserCountry: community.location.country.isNotEmpty
                            ? community.location.country
                            : null,
                      );
                    },
              child: Icon(
                Icons.waving_hand_rounded,
                color: isActive ? Colors.white : context.textMuted,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
