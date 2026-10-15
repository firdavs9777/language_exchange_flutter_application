import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_language.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';

/// The three Explore groups (spec 2026-10-13 §4.1).
enum StudyGroup { talk, practice, prepare }

/// Every AI Study feature with a tile. [slug] is the analytics id AND the
/// value the server uses in `studyVipOnlyFeatures` — append-only.
enum StudyFeature {
  tutor('tutor', StudyGroup.talk, quotaKey: 'chat'),
  roleplay('roleplay', StudyGroup.talk, quotaKey: 'roleplay'),
  story('story', StudyGroup.talk, quotaKey: 'story'),
  photo('photo', StudyGroup.talk, quotaKey: 'photo'),
  // No quotaKey: PronunciationScreen calls /speech/pronunciation/evaluate,
  // which spends no tutor quota (only the tutor's pronunciation summary does).
  speak('speak', StudyGroup.practice),
  review('review', StudyGroup.practice),
  writing('writing', StudyGroup.practice),
  quizzes('quizzes', StudyGroup.practice),
  exam('exam', StudyGroup.prepare),
  lessons('lessons', StudyGroup.prepare),
  challenges('challenges', StudyGroup.prepare),
  leaderboard('leaderboard', StudyGroup.prepare);

  const StudyFeature(this.slug, this.group, {this.quotaKey});

  final String slug;
  final StudyGroup group;

  /// Key in `tutorQuotaProvider`, or null for features without a daily cap.
  final String? quotaKey;
}

/// Grid order. Replaces `practice_entries.dart` once the hub flag has been
/// on for a release.
const Map<StudyGroup, List<StudyFeature>> studyFeatureGroups = {
  StudyGroup.talk: [StudyFeature.tutor, StudyFeature.roleplay, StudyFeature.story, StudyFeature.photo],
  StudyGroup.practice: [StudyFeature.speak, StudyFeature.review, StudyFeature.writing, StudyFeature.quizzes],
  StudyGroup.prepare: [StudyFeature.exam, StudyFeature.lessons, StudyFeature.challenges, StudyFeature.leaderboard],
};

List<StudyFeature> get studyFeatureOrder =>
    [for (final g in StudyGroup.values) ...studyFeatureGroups[g]!];

enum TileBadgeKind { locked, exhausted, low, due, isNew }

class TileBadge {
  const TileBadge(this.kind, [this.count]);
  final TileBadgeKind kind;
  final int? count;

  /// `badge` param of `study_tile_tap`.
  String get analyticsName => switch (kind) {
        TileBadgeKind.locked => 'locked',
        TileBadgeKind.exhausted => 'exhausted',
        TileBadgeKind.low => 'low',
        TileBadgeKind.due => 'due',
        TileBadgeKind.isNew => 'new',
      };

  @override
  bool operator ==(Object other) =>
      other is TileBadge && other.kind == kind && other.count == count;

  @override
  int get hashCode => Object.hash(kind, count);
}

/// One badge per tile, first match wins (spec §4.3).
TileBadge? badgeFor(
  StudyFeature f, {
  required bool isVip,
  required Set<String> vipOnly,
  TutorQuotaInfo? quota,
  int dueCount = 0,
  bool isNew = false,
}) {
  if (!isVip && vipOnly.contains(f.slug)) return const TileBadge(TileBadgeKind.locked);
  // Coin unlocks count: the server spends `bonus` after the free cap.
  if (quota != null && quota.isExhausted) {
    return const TileBadge(TileBadgeKind.exhausted, 0);
  }
  if (quota != null && quota.shouldShowIndicator) {
    return TileBadge(TileBadgeKind.low, quota.available ?? 0);
  }
  if (f == StudyFeature.review && dueCount > 0) return TileBadge(TileBadgeKind.due, dueCount);
  if (isNew) return const TileBadge(TileBadgeKind.isNew);
  return null;
}

/// The first [max] unseen tiles in grid order (spec §4.5) — an existing user
/// would otherwise open the hub to twelve NEW badges.
Set<StudyFeature> newBadgeFeatures(Set<String> seenSlugs, {int max = 3}) =>
    studyFeatureOrder.where((f) => !seenSlugs.contains(f.slug)).take(max).toSet();

enum FeatureCoverage { supported, englishOnly, unknown }

/// Hard language restrictions found in the backend (Task 3 Step 1). A feature
/// missing here is `unknown` and shows no note.
const Map<StudyFeature, Set<String>> _staticLanguageSupport = {
  // Step 1 verification (spec §4.6) found no hard language restriction in the
  // backend for any feature, so nothing is listed here. Add `{'en'}` entries
  // only when code proves an English-only path.
};

/// Whether [f] works for [targetLanguage] (a name like "Korean" or a code
/// like "ko", as stored in `language_to_learn`). Only `englishOnly` changes
/// what the tile says.
FeatureCoverage featureCoverage(
  StudyFeature f,
  String? targetLanguage, {
  List<ExamLanguage>? examLanguages,
}) {
  final target = targetLanguage?.trim().toLowerCase() ?? '';
  if (target.isEmpty) return FeatureCoverage.unknown;
  if (f == StudyFeature.exam) {
    if (examLanguages == null) return FeatureCoverage.unknown;
    final hit = examLanguages.any((l) =>
        l.active && (l.code.toLowerCase() == target || l.name.toLowerCase() == target));
    return hit ? FeatureCoverage.supported : FeatureCoverage.unknown;
  }
  final codes = _staticLanguageSupport[f];
  if (codes == null) return FeatureCoverage.unknown;
  if (codes.contains(target) || (target == 'english' && codes.contains('en'))) {
    return FeatureCoverage.supported;
  }
  if (codes.length == 1 && codes.contains('en')) return FeatureCoverage.englishOnly;
  return FeatureCoverage.unknown;
}

/// Weakest area with enough attempts to mean something (spec §5).
WeakArea? pickRecommended(List<WeakArea> areas) {
  WeakArea? best;
  for (final a in areas) {
    if (a.attempts < 3) continue;
    if (best == null || a.accuracy < best.accuracy) best = a;
  }
  return best;
}
