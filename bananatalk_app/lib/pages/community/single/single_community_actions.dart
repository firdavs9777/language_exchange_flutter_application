import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Row of compact action buttons below the hero header:
/// Video Call / Voice Call / Message / Follow (or Unfollow).
class SingleCommunityActions extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(bottom: BorderSide(color: context.dividerColor, width: 0.5)),
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
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
