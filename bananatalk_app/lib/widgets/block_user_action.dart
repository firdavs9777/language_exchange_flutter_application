import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bananatalk_app/widgets/block_user_dialog.dart';

/// Start the block flow for [targetUserId], resolving the viewer's own id.
///
/// Exists because report and block were badly asymmetric: a user could report
/// a moment, a story or a comment, but had to navigate to the author's profile
/// to block them. Reporting asks someone else to act later; blocking is the
/// thing that stops the harassment now, and it was the harder of the two to
/// reach from the place where you actually encounter the person.
///
/// [BlockUserDialog] needs the viewer's id, and four separate call sites each
/// re-reading SharedPreferences is how that detail drifts. Reading it here
/// keeps each surface to a single call.
///
/// Returns silently when the viewer's id is unknown or is the target's own —
/// a confirmation dialog that cannot complete is worse than no entry point,
/// so callers should gate the menu item with [canBlockUser] rather than relying
/// on this to report failure.
Future<void> showBlockUserFlow({
  required BuildContext context,
  required String targetUserId,
  required String targetUserName,
}) async {
  if (targetUserId.isEmpty) return;

  String me = '';
  try {
    final prefs = await SharedPreferences.getInstance();
    me = prefs.getString('userId') ?? '';
  } catch (e) {
    debugPrint('[blockUserAction] could not read userId: $e');
    return;
  }

  if (me.isEmpty || me == targetUserId) return;
  if (!context.mounted) return;

  await BlockUserDialog.show(
    context: context,
    currentUserId: me,
    targetUserId: targetUserId,
    targetUserName: targetUserName,
  );
}

/// Whether a block entry should be offered at all.
///
/// Pure, so the menu-visibility rule can be tested without a widget tree.
/// Blocking yourself is meaningless, and an empty id cannot be blocked.
bool canBlockUser({required String viewerId, required String targetUserId}) =>
    viewerId.isNotEmpty && targetUserId.isNotEmpty && viewerId != targetUserId;
