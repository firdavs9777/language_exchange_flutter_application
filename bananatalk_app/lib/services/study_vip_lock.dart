import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';

/// Key under which `AIService` results carry the [StudyFeature] a
/// STUDY_VIP_ONLY_FEATURES lock refused.
const String studyVipLockKey = 'vipLockedFeature';

const String _vipOnlyPrefix = 'vip_only_';

/// The feature the server's `requireStudyVip` gate refused, or null.
///
/// The gate answers 429 `{error: 'quota_exceeded', reason: 'vip_required',
/// feature: 'vip_only_<slug>'}`. ApiClient routes every quota_exceeded body to
/// its paywall, but the screens on raw `http` (Speak, Writing, Quizzes) only
/// see a failed call, so they detect the lock here.
StudyFeature? studyVipLockFeature(int statusCode, Map<String, dynamic>? body) {
  if (statusCode != 429 || body == null) return null;
  if (body['error'] != 'quota_exceeded') return null;
  // `feature` alone decides: a plain daily cap ('story', 'photo', ...) is
  // never prefixed, and coins can lift it, so it keeps the exhausted path.
  final feature = body['feature']?.toString() ?? '';
  if (!feature.startsWith(_vipOnlyPrefix)) return null;
  final slug = feature.substring(_vipOnlyPrefix.length);
  for (final f in StudyFeature.values) {
    if (f.slug == slug) return f;
  }
  return null;
}
