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
/// represents the currently-logged-in user. The button is greyed-out
/// when the 24 h client-side cooldown has not yet elapsed.
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

  // Returns true if the wave cooldown (24 h) is still active for [userId].
  static Future<bool> _inCooldown(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$waveCooldownPrefsPrefix$userId');
    if (ts == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - ts;
    return elapsed < const Duration(hours: 24).inMilliseconds;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(authServiceProvider).userId;

    // Hide wave button entirely on own profile
    if (currentUserId.isNotEmpty && currentUserId == community.id) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: _inCooldown(community.id),
      builder: (context, snapshot) {
        final cooldownActive = snapshot.data ?? false;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildWaveButton(context, cooldownActive),
            const SizedBox(height: 6),
            ConversationStarterRibbon(community: community, compact: true),
          ],
        );
      },
    );
  }

  Widget _buildWaveButton(BuildContext context, bool cooldownActive) {
    final isActive = !cooldownActive;
    return Container(
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
        color: cooldownActive ? context.containerColor : null,
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
            onTap: cooldownActive
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
    );
  }
}
