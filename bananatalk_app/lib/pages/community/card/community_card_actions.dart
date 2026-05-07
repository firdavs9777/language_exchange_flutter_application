import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Actions block for [CommunityCard].
///
/// Renders:
/// - A gradient "wave" button (quick-action, top-right of the header row)
///
/// The wave button is a stub until C14 wires the actual wave flow.
/// When [onWaveTap] is null the button is rendered but non-interactive
/// (IconButton automatically greys out disabled buttons).
class CommunityCardActions extends StatelessWidget {
  const CommunityCardActions({
    super.key,
    required this.community,
    required this.onMessageTap,
    this.onWaveTap,
  });

  final Community community;

  /// Called when the user taps the message button (currently unused in the
  /// header quick-action; reserved for future expansion).
  final VoidCallback onMessageTap;

  /// Called when the user taps the wave button.
  ///
  /// Pass `null` to disable the button (C14 will wire the real callback).
  final VoidCallback? onWaveTap;

  @override
  Widget build(BuildContext context) {
    return _buildWaveButton(context);
  }

  Widget _buildWaveButton(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: onWaveTap != null
            ? const LinearGradient(
                colors: [AppColors.primary, Color(0xFF00ACC1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: onWaveTap == null
            ? context.containerColor
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onWaveTap != null && !context.isDarkMode
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onWaveTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onWaveTap!();
                }
              : null,
          child: Icon(
            Icons.waving_hand_rounded,
            color: onWaveTap != null
                ? Colors.white
                : context.textMuted,
            size: 24,
          ),
        ),
      ),
    );
  }
}
