import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The full hub key set, listed explicitly so the keys-covered guard in
/// hardcoded_strings_test.dart sees them and a dropped key fails here.
const _hubKeys = [
  'studyGroupTalk',
  'studyGroupPractice',
  'studyGroupPrepare',
  'studyTileTutor',
  'studyTileTutorDesc',
  'studyTileRoleplay',
  'studyTileRoleplayDesc',
  'studyTileStory',
  'studyTileStoryDesc',
  'studyTilePhoto',
  'studyTilePhotoDesc',
  'studyTileSpeak',
  'studyTileSpeakDesc',
  'studyTileReview',
  'studyTileReviewDesc',
  'studyTileWriting',
  'studyTileWritingDesc',
  'studyTileQuizzes',
  'studyTileQuizzesDesc',
  'studyTileExam',
  'studyTileExamDesc',
  'studyTileLessons',
  'studyTileLessonsDesc',
  'studyTileChallenges',
  'studyTileChallengesDesc',
  'studyTileLeaderboard',
  'studyTileLeaderboardDesc',
  'studyBadgeVip',
  'studyBadgeLeft',
  'studyBadgeDue',
  'studyBadgeNew',
  'studyEnglishOnly',
  'studyTodayPack',
  'studyTodayStart',
  'studyRecommended',
  'studyProgressTitle',
  'studyFullReport',
  'studyStreakDays',
  'studyLevelShort',
  'studyUpgradeLockedTitle',
  'studyUpgradeExhaustedTitle',
  'studyUpgradeBenefitUnlimited',
  'studyUpgradeBenefitNoAds',
  'studyUpgradeGetVip',
  'guideStudyHubTitle',
  'guideStudyHubBody',
  'guideStudyHubCta',
  'guideStudyHubSecondary',
  'supportBananaTalkRow',
  'supportBananaTalkRowSubtitle',
];

/// Every AI Study hub string exists in every locale (same reason as
/// guide_strings_test.dart: a missing key ships silent English).
void main() {
  test('every locale defines every study* / supportBananaTalk* key', () {
    final template = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final keys = template.keys
        .where((k) => !k.startsWith('@') &&
            (k.startsWith('studyTile') || k.startsWith('studyGroup') ||
             k.startsWith('studyBadge') || k.startsWith('studyUpgrade') ||
             k.startsWith('studyToday') || k.startsWith('studyProgress') ||
             k.startsWith('supportBananaTalk') ||
             const {'studyEnglishOnly', 'studyRecommended', 'studyFullReport',
                    'studyStreakDays', 'studyLevelShort'}.contains(k)))
        .toList();
    expect(keys.length, greaterThanOrEqualTo(45));
    keys.addAll(_hubKeys.where((k) => !keys.contains(k)));
    expect(template.keys, containsAll(_hubKeys));
    final arbs = Directory('lib/l10n').listSync().whereType<File>()
        .where((f) => f.path.endsWith('.arb')).toList();
    expect(arbs.length, 19);
    for (final f in arbs) {
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      for (final k in keys) {
        expect(m[k], isA<String>(), reason: '${f.path} is missing $k');
        expect((m[k] as String).trim(), isNotEmpty, reason: '${f.path} $k is empty');
      }
    }
  });
}
