import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';

String studyFeatureTitle(AppLocalizations l, StudyFeature f) => switch (f) {
      StudyFeature.tutor => l.studyTileTutor,
      StudyFeature.roleplay => l.studyTileRoleplay,
      StudyFeature.story => l.studyTileStory,
      StudyFeature.photo => l.studyTilePhoto,
      StudyFeature.speak => l.studyTileSpeak,
      StudyFeature.review => l.studyTileReview,
      StudyFeature.writing => l.studyTileWriting,
      StudyFeature.quizzes => l.studyTileQuizzes,
      StudyFeature.exam => l.studyTileExam,
      StudyFeature.lessons => l.studyTileLessons,
      StudyFeature.challenges => l.studyTileChallenges,
      StudyFeature.leaderboard => l.studyTileLeaderboard,
    };

String studyFeatureDescription(AppLocalizations l, StudyFeature f) => switch (f) {
      StudyFeature.tutor => l.studyTileTutorDesc,
      StudyFeature.roleplay => l.studyTileRoleplayDesc,
      StudyFeature.story => l.studyTileStoryDesc,
      StudyFeature.photo => l.studyTilePhotoDesc,
      StudyFeature.speak => l.studyTileSpeakDesc,
      StudyFeature.review => l.studyTileReviewDesc,
      StudyFeature.writing => l.studyTileWritingDesc,
      StudyFeature.quizzes => l.studyTileQuizzesDesc,
      StudyFeature.exam => l.studyTileExamDesc,
      StudyFeature.lessons => l.studyTileLessonsDesc,
      StudyFeature.challenges => l.studyTileChallengesDesc,
      StudyFeature.leaderboard => l.studyTileLeaderboardDesc,
    };

IconData studyFeatureIcon(StudyFeature f) => switch (f) {
      StudyFeature.tutor => Icons.smart_toy_rounded,
      StudyFeature.roleplay => Icons.theater_comedy_rounded,
      StudyFeature.story => Icons.auto_stories_rounded,
      StudyFeature.photo => Icons.photo_camera_rounded,
      StudyFeature.speak => Icons.record_voice_over_rounded,
      StudyFeature.review => Icons.replay_circle_filled_rounded,
      StudyFeature.writing => Icons.edit_note_rounded,
      StudyFeature.quizzes => Icons.quiz_rounded,
      StudyFeature.exam => Icons.school_rounded,
      StudyFeature.lessons => Icons.menu_book_rounded,
      StudyFeature.challenges => Icons.flag_rounded,
      StudyFeature.leaderboard => Icons.leaderboard_rounded,
    };

/// Group accent (foreground) and fill (light mode). Spec §4.2.
({Color fg, Color fill}) studyGroupColors(StudyGroup g, {required bool dark}) {
  final fg = switch (g) {
    StudyGroup.talk => const Color(0xFF6D3FE0),
    StudyGroup.practice => const Color(0xFF00786A),
    StudyGroup.prepare => const Color(0xFFA85E00),
  };
  if (dark) {
    final light = Color.lerp(fg, Colors.white, 0.45)!;
    return (fg: light, fill: fg.withValues(alpha: 0.18));
  }
  final fill = switch (g) {
    StudyGroup.talk => const Color(0xFFEFE9FE),
    StudyGroup.practice => const Color(0xFFDDF5EF),
    StudyGroup.prepare => const Color(0xFFFEF0D9),
  };
  return (fg: fg, fill: fill);
}

String studyGroupLabel(AppLocalizations l, StudyGroup g) => switch (g) {
      StudyGroup.talk => l.studyGroupTalk,
      StudyGroup.practice => l.studyGroupPractice,
      StudyGroup.prepare => l.studyGroupPrepare,
    };
