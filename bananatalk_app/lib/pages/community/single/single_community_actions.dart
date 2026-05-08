import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/community/widgets/send_wave_sheet.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Row of compact action buttons below the hero header:
/// Video Call / Voice Call / Message / Wave / Follow (or Unfollow).
///
/// The Wave button is hidden when the profile belongs to the current user.
/// When the 24 h client-side cooldown is active the button is greyed out.
class SingleCommunityActions extends ConsumerWidget {
  final Community community;
  final bool isFollower;
  final VoidCallback onVideoCall;
  final VoidCallback onVoiceCall;
  final VoidCallback onMessage;
  final VoidCallback onFollowToggle;

  const SingleCommunityActions({
    super.key,
    required this.community,
    required this.isFollower,
    required this.onVideoCall,
    required this.onVoiceCall,
    required this.onMessage,
    required this.onFollowToggle,
  });

  // Returns true when the 24 h wave cooldown is still active for [userId].
  static Future<bool> _inCooldown(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$waveCooldownPrefsPrefix$userId');
    if (ts == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - ts;
    return elapsed < const Duration(hours: 24).inMilliseconds;
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactActionButton(
            context,
            Icons.videocam_rounded,
            l10n.videoCall,
            Colors.blue[600]!,
            onVideoCall,
          ),
          _buildCompactActionButton(
            context,
            Icons.call_rounded,
            l10n.voiceCall,
            Colors.green[600]!,
            onVoiceCall,
          ),
          _buildCompactActionButton(
            context,
            Icons.chat_bubble_rounded,
            l10n.message,
            AppColors.accent,
            onMessage,
          ),
          // Wave button — hidden for own profile
          if (!isOwnProfile)
            FutureBuilder<bool>(
              future: _inCooldown(community.id),
              builder: (context, snapshot) {
                final cooldownActive = snapshot.data ?? false;
                return _buildWaveActionButton(context, l10n, cooldownActive);
              },
            ),
          _buildCompactActionButton(
            context,
            isFollower ? Icons.check_circle_rounded : Icons.person_add_rounded,
            isFollower ? l10n.following : l10n.follow,
            isFollower ? Colors.green[600]! : Colors.blue[600]!,
            onFollowToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildWaveActionButton(
    BuildContext context,
    AppLocalizations l10n,
    bool cooldownActive,
  ) {
    final color = cooldownActive ? Colors.grey[400]! : AppColors.primary;
    return InkWell(
      onTap: cooldownActive
          ? null
          : () => showSendWaveSheet(
              context,
              targetUserId: community.id,
              targetUserName: community.name,
              targetUserCountry: community.location.country.isNotEmpty
                  ? community.location.country
                  : null,
            ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.waving_hand_rounded, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.sendWave,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
