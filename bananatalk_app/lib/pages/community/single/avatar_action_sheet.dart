import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// What the viewer wants from a ringed avatar: the story, or the photo.
///
/// Before this, a ring made the profile photo unreachable — tapping always
/// opened the story, and there was no other route to the picture. On a
/// language-exchange app the photo is how someone sizes up a potential
/// partner, so losing access to it costs more than the extra tap.
enum AvatarAction { story, photo }

/// Shown ONLY when a story exists.
///
/// With no story there is nothing to choose between, and a one-option sheet is
/// a worse version of just opening the photo.
Future<AvatarAction?> showAvatarActionSheet(BuildContext context) {
  return showModalBottomSheet<AvatarAction>(
    context: context,
    backgroundColor: context.containerColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              key: const Key('avatar-action-story'),
              leading: const Icon(Icons.auto_stories_rounded),
              title: Text(l10n.avatarViewStory),
              onTap: () => Navigator.pop(sheetContext, AvatarAction.story),
            ),
            ListTile(
              key: const Key('avatar-action-photo'),
              leading: const Icon(Icons.account_circle_rounded),
              title: Text(l10n.avatarViewPhoto),
              onTap: () => Navigator.pop(sheetContext, AvatarAction.photo),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
