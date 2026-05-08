import 'package:flutter/material.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/community/widgets/send_wave_sheet.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

class WaveButton extends StatelessWidget {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserCountry;
  final bool greyedOut;
  final String? cooldownText;
  final VoidCallback? onSent;

  const WaveButton({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserCountry,
    this.greyedOut = false,
    this.cooldownText,
    this.onSent,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: greyedOut ? (cooldownText ?? '') : '',
      child: IconButton(
        icon: Icon(
          Icons.waving_hand_rounded,
          color: greyedOut ? context.textMuted : AppColors.primary,
        ),
        onPressed: greyedOut
            ? null
            : () => showSendWaveSheet(
                context,
                targetUserId: targetUserId,
                targetUserName: targetUserName,
                targetUserCountry: targetUserCountry,
                onSent: onSent,
              ),
      ),
    );
  }
}
