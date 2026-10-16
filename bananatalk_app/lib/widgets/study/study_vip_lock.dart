import 'package:flutter/widgets.dart';

import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/services/study_vip_lock.dart';
import 'package:bananatalk_app/widgets/study/study_upgrade_sheet.dart';

/// Opens the hub's VIP-lock upgrade sheet (Get VIP + Not now, no coin unlock)
/// when [result] — an `AIService` result map — carries a VIP lock. Returns
/// true when it did, so the caller skips its generic error.
Future<bool> showStudyVipLockIfAny(
        BuildContext context, Map<String, dynamic> result) =>
    showStudyVipLockSheet(context, result[studyVipLockKey]);

/// [showStudyVipLockIfAny] for a lock already pulled out of the result, e.g.
/// one kept in provider state. [lock] is the refused [StudyFeature] or null.
Future<bool> showStudyVipLockSheet(BuildContext context, Object? lock) async {
  if (lock is! StudyFeature || !context.mounted) return false;
  await showStudyUpgradeSheet(context,
      feature: lock, reason: StudyUpgradeReason.locked);
  return true;
}
