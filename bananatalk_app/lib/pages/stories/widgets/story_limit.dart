import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/widgets/limit_exceeded_dialog.dart';

/// Daily story limit reached: the same upgrade dialog as moments and
/// comments, instead of a dead-end error snackbar. Shared by the composer
/// (blocking post) and the own-ring chip (a queued post that hit the limit).
Future<void> showStoryLimitDialog(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return;
  await LimitExceededDialog.show(
    context: context,
    limitType: 'stories',
    userId: prefs.getString('userId') ?? '',
  );
}
