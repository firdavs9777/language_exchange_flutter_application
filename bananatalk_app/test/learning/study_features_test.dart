import 'package:flutter_test/flutter_test.dart';
import 'package:bananatalk_app/models/ai/ai_quiz_model.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/providers/provider_models/exam/exam_language.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';

TutorQuotaInfo q({int used = 0, int? cap = 10, bool unlimited = false, int bonus = 0}) =>
    TutorQuotaInfo(
      used: used,
      cap: unlimited ? null : cap,
      remaining: unlimited ? null : (cap! - used),
      resetAt: null,
      unlimited: unlimited,
      bonus: bonus,
    );

WeakArea area(String name, double acc, int attempts) => WeakArea(
    name: name, category: 'grammar', accuracy: acc, attempts: attempts, recommendation: '');

void main() {
  group('catalogue', () {
    test('12 unique tiles in spec order', () {
      expect(studyFeatureOrder, [
        StudyFeature.tutor, StudyFeature.roleplay, StudyFeature.story, StudyFeature.photo,
        StudyFeature.speak, StudyFeature.review, StudyFeature.writing, StudyFeature.quizzes,
        StudyFeature.exam, StudyFeature.lessons, StudyFeature.challenges, StudyFeature.leaderboard,
      ]);
      expect(studyFeatureOrder.toSet().length, StudyFeature.values.length);
    });
    test('each tile sits in its own group', () {
      for (final e in studyFeatureGroups.entries) {
        for (final f in e.value) {
          expect(f.group, e.key);
        }
      }
    });
    test('quota keys match tutorQuotaProvider keys', () {
      expect(StudyFeature.tutor.quotaKey, 'chat');
      expect(StudyFeature.review.quotaKey, isNull);
    });
    test('speak has no tutor quota: PronunciationScreen never spends one', () {
      // The tutor "pronunciation" quota is spent only by the tutor's
      // pronunciation summary; gating the Speak tile on it showed
      // "exhausted" and sold coins for a screen that is not capped.
      expect(StudyFeature.speak.quotaKey, isNull);
      expect(StudyFeature.review.quotaKey, isNull);
    });
  });

  group('badgeFor', () {
    TileBadge? b(StudyFeature f,
            {bool vip = false, Set<String> lock = const {}, TutorQuotaInfo? quota,
             int due = 0, bool isNew = false}) =>
        badgeFor(f, isVip: vip, vipOnly: lock, quota: quota, dueCount: due, isNew: isNew);

    test('locked', () => expect(b(StudyFeature.photo, lock: {'photo'})?.kind, TileBadgeKind.locked));
    test('VIP never sees locked', () => expect(b(StudyFeature.photo, vip: true, lock: {'photo'}), isNull));
    test('exhausted', () {
      final r = b(StudyFeature.tutor, quota: q(used: 10));
      expect(r?.kind, TileBadgeKind.exhausted);
      expect(r?.count, 0);
    });
    test('low at >= 50 %', () {
      final r = b(StudyFeature.tutor, quota: q(used: 5));
      expect(r?.kind, TileBadgeKind.low);
      expect(r?.count, 5);
    });
    test('below 50 % shows nothing', () => expect(b(StudyFeature.tutor, quota: q(used: 4)), isNull));
    test('unlimited shows nothing', () => expect(b(StudyFeature.tutor, quota: q(unlimited: true)), isNull));
    test('quota not loaded shows nothing', () => expect(b(StudyFeature.tutor), isNull));
    test('due only on review', () {
      expect(b(StudyFeature.review, due: 7)?.kind, TileBadgeKind.due);
      expect(b(StudyFeature.review, due: 7)?.count, 7);
      expect(b(StudyFeature.lessons, due: 7), isNull);
    });
    test('new', () => expect(b(StudyFeature.lessons, isNew: true)?.kind, TileBadgeKind.isNew));
    test('precedence: locked > exhausted', () =>
        expect(b(StudyFeature.photo, lock: {'photo'}, quota: q(used: 10))?.kind, TileBadgeKind.locked));
    test('precedence: exhausted > low (exhausted also passes the 50 % test)', () =>
        expect(b(StudyFeature.tutor, quota: q(used: 10))?.kind, TileBadgeKind.exhausted));
    test('precedence: low > new', () =>
        expect(b(StudyFeature.tutor, quota: q(used: 6), isNew: true)?.kind, TileBadgeKind.low));
    test('coin bonus left: not exhausted, low shows remaining + bonus', () {
      final r = b(StudyFeature.tutor, quota: q(used: 10, bonus: 2));
      expect(r?.kind, TileBadgeKind.low);
      expect(r?.count, 2);
    });
    test('bonus spent too: exhausted', () =>
        expect(b(StudyFeature.tutor, quota: q(used: 10, bonus: 0))?.kind, TileBadgeKind.exhausted));
    test('plenty left with bonus: no low badge', () =>
        expect(b(StudyFeature.tutor, quota: q(used: 5, bonus: 3)), isNull));
    test('precedence: due > new', () =>
        expect(b(StudyFeature.review, due: 1, isNew: true)?.kind, TileBadgeKind.due));
  });

  group('newBadgeFeatures', () {
    test('at most 3, first unseen in grid order', () {
      expect(newBadgeFeatures({}), {StudyFeature.tutor, StudyFeature.roleplay, StudyFeature.story});
    });
    test('skips seen tiles', () {
      expect(newBadgeFeatures({'tutor', 'story'}),
          {StudyFeature.roleplay, StudyFeature.photo, StudyFeature.speak});
    });
    test('all seen -> none', () {
      expect(newBadgeFeatures(StudyFeature.values.map((f) => f.slug).toSet()), isEmpty);
    });
  });

  group('featureCoverage', () {
    final langs = [
      const ExamLanguage(id: '1', name: 'Korean', code: 'ko', active: true),
    ];
    test('exam: supported when the target is an exam language (name or code)', () {
      expect(featureCoverage(StudyFeature.exam, 'Korean', examLanguages: langs), FeatureCoverage.supported);
      expect(featureCoverage(StudyFeature.exam, 'ko', examLanguages: langs), FeatureCoverage.supported);
    });
    test('exam: unknown when the list is not loaded', () {
      expect(featureCoverage(StudyFeature.exam, 'Korean'), FeatureCoverage.unknown);
    });
    test('no target language -> unknown', () {
      expect(featureCoverage(StudyFeature.tutor, null), FeatureCoverage.unknown);
      expect(featureCoverage(StudyFeature.tutor, ''), FeatureCoverage.unknown);
    });
  });

  group('pickRecommended', () {
    test('lowest accuracy with >= 3 attempts', () {
      final r = pickRecommended([area('a', 0.4, 2), area('b', 0.6, 5), area('c', 0.5, 3)]);
      expect(r?.name, 'c');
    });
    test('none qualifies -> null', () => expect(pickRecommended([area('a', 0.1, 2)]), isNull));
    test('empty -> null', () => expect(pickRecommended([]), isNull));
  });

  group('TutorQuotaInfo', () {
    test('parses bonus, defaults to 0 for old servers', () {
      final withBonus = TutorQuotaInfo.fromJson(
          {'used': 10, 'cap': 10, 'remaining': 0, 'unlimited': false, 'bonus': 2});
      expect(withBonus.bonus, 2);
      expect(withBonus.available, 2);
      expect(withBonus.isExhausted, isFalse);
      final old = TutorQuotaInfo.fromJson(
          {'used': 10, 'cap': 10, 'remaining': 0, 'unlimited': false});
      expect(old.bonus, 0);
      expect(old.isExhausted, isTrue);
      expect(old.shouldShowIndicator, isTrue);
    });
    test('negative bonus is clamped', () {
      final i = TutorQuotaInfo.fromJson(
          {'used': 10, 'cap': 10, 'remaining': 0, 'unlimited': false, 'bonus': -3});
      expect(i.bonus, 0);
    });
    test('unlimited is never exhausted', () {
      final i = TutorQuotaInfo.fromJson({'unlimited': true, 'bonus': 0});
      expect(i.isExhausted, isFalse);
      expect(i.available, isNull);
    });
  });
}
