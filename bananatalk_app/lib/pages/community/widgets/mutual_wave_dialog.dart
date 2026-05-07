import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

void showMutualWaveDialog(
  BuildContext context, {
  required String name,
  required String targetUserId,
}) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(l10n.itsAMatch,
              style: context.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(l10n.itsAMatchSubtitle(name),
              textAlign: TextAlign.center, style: context.bodyMedium),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Later'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          onPressed: () {
            Navigator.pop(dialogContext);
            // Navigate to chat using the go_router '/chat/:userId' route.
            context.push('/chat/$targetUserId');
          },
          child: Text(l10n.sendAMessage),
        ),
      ],
    ),
  );
}
