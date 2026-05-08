import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class VoiceRoomReconnectBanner extends StatelessWidget {
  final bool isReconnecting;
  const VoiceRoomReconnectBanner({super.key, required this.isReconnecting});

  @override
  Widget build(BuildContext context) {
    if (!isReconnecting) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber,
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.voiceRoomReconnecting,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
