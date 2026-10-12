import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'hardcoded_text_scanner.dart';

/// New keys per localization task (plan part 30, L1–L12). Each task adds its entry.
const Map<String, List<String>> _keysByTask = {
  'L1': [
    'chatDailyLimitBody',
    'chatCompressingVideo',
    'chatShareLocationBody',
    'chatTranslationLimitReached',
    'chatTranslateLimitBody',
    'chatReplyingTo',
    'chatSendingMedia',
    'chatEnterUsernameStart',
    'chatSearching',
    'chatDeleteConversationBody',
    'chatQrCode',
    'chatDraft',
    'chatTyping',
    'chatPoweredBy',
    'chatReconnecting',
    'chatShareLocationThisChat',
    'chatReplyingToFallback',
    'chatDailyLimitReached',
    'chatMessagesRemainingToday',
    'chatTranslatePreviewHint',
    'chatNoMessagesYet',
    'chatMediaPhoto',
    'chatMediaVideo',
    'chatMediaAudio',
    'chatMediaFile',
    'chatMediaGeneric',
  ],
  'L2': [
    'chatMessageFailedToSend',
    'chatSendingEllipsis',
    'chatFailedTapOptions',
    'chatMessageWasDeleted',
    'chatStory',
    'chatHi',
    'chatEdited',
    'chatPremium',
    'chatUnlockPremiumWallpapers',
    'chatWallpaperForName',
    'chatChooseGallery',
    'chatHiThere',
    'chatCorrected',
    'chatCorrectionAccepted',
    'chatForwarded',
    'chatCached',
    'chatWordBreakdown',
    'chatAlternatives',
    'chatTranslationAlso',
    'chatAudioUnavailable',
  ],
  'L3': [
    'momentsMore',
    'momentsAllow',
    'momentsCompressed',
    'momentsPromptDay',
    'momentsAnswer',
    'momentsAnswerCamera',
    'momentsPracticeWriting',
    'momentsReelPolicyBody',
    'momentsIAgree',
    'momentsWhyReportingReel',
    'momentsNoReelsYet',
    'momentsNoReelsBody',
    'momentsPullDownRefresh',
    'momentsErrorLoadingVideo',
    'momentsLoadingVideo',
    'momentsFileSizeMb',
    'momentsMaxDuration',
    'momentsReportSubmitted',
  ],
  'L4': [
    'communityLive',
    'communityFind',
    'communityFinding',
    'communitySeeAll',
    'communitySeeWhoLikes',
    'communityUnlimitedBrowsingNoAds',
    'communityMembersCount',
    'communityPeopleCount',
    'communityFailedLoadArchivedWaves',
    'communityGreatChat',
    'communityStayTouchPeopleJust',
    'communityNotNow',
    'communityPerfect',
    'communityLv',
    'communityReact',
    'communityWavedAtYou',
    'communitySomeone',
    'communityPeopleInterestedInTopic',
  ],
  'L5': [
    'learnThemedWordSetsBuild',
    'learnTapStartRecording',
    'learnWordBank',
    'learnCorrectAnswer',
    'learnMatchingDataNotAvailable',
    'learnExerciseCouldNotLoad',
    'learnSkipExercise',
    'learnTapItemLeftThen',
    'learnMatchedOfTotal',
    'learnCorrectOfTotal',
    'learnDragDropReorderItems',
    'learnCorrectOrder',
    'learnWordsToReview',
    'learnScore',
    'learnGotCorrect',
    'learnQuestionOf',
    'learnMatchEachWordIts',
    'learnCouldNotLoadPacks',
    'learnWordsExercises',
    'learnAiAutoFill',
    'learnPlay',
    'learnFinish',
    'learnNotQuite',
    'learnUnsupportedExercise',
    'examSpeakingSubmit',
  ],
  'L6': [
    'learnFailedLoadAchievements',
    'learnUnlockedOn',
    'learnChallenges',
    'learnFailedLoadChallenges',
    'learnNoChallenges',
    'learnCheckBackLater',
    'learnActiveCount',
    'learnCompletedCount',
    'learnProgress',
    'learnXpReward',
    'learnBonus',
    'learnExpires',
    'learnAchievementUnlocked',
    'learnTapContinue',
    'learnChallengeCompleted',
    'learnDailyGoals',
    'learnLessons',
    'learnLongestDays',
    'learnTapReveal',
    'learnNoAchievements',
    'learnDayStreak',
    'learnDueForReview',
    'learnNextReview',
    'learnChallengeDaily',
    'learnChallengeWeekly',
    'learnChallengeSpecial',
    'learnChallengeDailyDesc',
    'learnChallengeWeeklyDesc',
    'learnChallengeSpecialDesc',
    'learnDateToday',
    'learnDateTomorrow',
    'learnInDays',
    'learnInWeeks',
    'learnInMonths',
  ],
  'L7': [
    'aiGreatJob',
    'aiGoodEffort',
    'aiKeepPracticing',
    'aiFailedToGetHint',
    'aiFailedToGetAnswer',
    'aiFailedToExplain',
    'aiGenerateNewQuiz',
    'aiPreviousQuizzes',
    'aiGeneratingQuiz',
    'aiFocusArea',
    'aiQuizType',
    'aiDifficulty',
    'aiQuestionsLabel',
    'aiGenerateQuiz',
    'aiQuizQuestionCount',
    'aiCorrectOfTotal',
    'aiNoQuizzesYet',
    'aiGenerateFirstQuizAbove',
    'aiCorrectOutOf',
    'aiBackQuizHub',
    'aiNoQuestionsAvailable',
    'aiQuizHasNoQuestions',
    'aiQuestionOf',
    'aiYourAnswerLabel',
    'aiBonusXpWatching',
    'aiNotQuiteRight',
    'aiWhy',
    'aiGotIt',
    'aiHint',
    'aiLevel',
    'aiAskQuestion',
    'aiAsk',
    'aiAssistantExamples',
    'aiExplainConcept',
    'aiRelatedConcepts',
    'aiGeneratingLessonSummary',
    'aiLessonSummary',
    'aiKeyPoints',
    'aiVocabularyRemember',
    'aiGrammarRules',
    'aiWhatPracticeNext',
    'aiPerfectScore',
  ],
};

/// Files (under lib/) each task must leave with no English Text literal.
const Map<String, List<String>> _filesByTask = {
  'L1': [
    'pages/chat/chat_screen_wrapper.dart',
    'pages/chat/conversation/chat_conversation_screen.dart',
    'pages/chat/dialogs/translate_unlock_sheet.dart',
    'pages/chat/input/chat_input_bar.dart',
    'pages/chat/input/chat_input_section.dart',
    'pages/chat/list/chat_list_screen.dart',
    'pages/chat/list/chat_list_tile.dart',
    'pages/chat/panels/gif_picker_panel.dart',
    'widgets/connection_status_indicator.dart',
  ],
  'L2': [
    'pages/chat/message/bubble/bubble_actions_menu.dart',
    'pages/chat/message/message_bubble.dart',
    'pages/chat/message/message_bubble/image_message_view.dart',
    'pages/chat/message/message_bubble/story_share_message_view.dart',
    'pages/chat/message/message_bubble/text_message_view.dart',
    'pages/chat/message/message_bubble/voice_message_view.dart',
    'pages/chat/message/typing_indicator.dart',
    'pages/chat/wallpaper/wallpaper_picker_screen.dart',
    'widgets/correction_message_bubble.dart',
    'widgets/forwarded_message_indicator.dart',
    'widgets/translation_bottom_sheet.dart',
    'widgets/voice_message_player.dart',
  ],
  'L3': [
    'pages/moments/card/moment_media_carousel.dart',
    'pages/moments/create/create_moment.dart',
    'pages/moments/feed/prompt_of_day_card.dart',
    'pages/moments/reels/reel_policy_dialog.dart',
    'pages/moments/reels/reels_feed_screen.dart',
    'pages/moments/reels/reels_grid_screen.dart',
    'pages/moments/viewer/video_player_widget.dart',
    'pages/profile/moments/moment_edit.dart',
    'pages/profile/moments/moments_list.dart',
    'widgets/video_player_screen.dart',
  ],
  'L4': [
    'pages/community/card/community_card_meta.dart',
    'pages/community/main/community_app_bar.dart',
    'pages/community/main/community_filter_chips.dart',
    'pages/community/main/community_main.dart',
    'pages/community/tabs/city_tab.dart',
    'pages/community/tabs/genders_tab.dart',
    'pages/community/tabs/topics_tab.dart',
    'pages/community/tabs/waves_archive_screen.dart',
    'pages/community/voice_rooms/post_room_connect_sheet.dart',
    'pages/matching/match_card_widget.dart',
    'widgets/community/partner_card.dart',
    'widgets/community/partner_list_item.dart',
    'widgets/voice_room/reaction_picker.dart',
  ],
  'L5': [
    'pages/learning/exam_study/exam_picker_screen.dart',
    'pages/learning/exam_study/widgets/audio_recorder.dart',
    'pages/learning/lessons/exercises/fill_blank_widget.dart',
    'pages/learning/lessons/exercises/matching_widget.dart',
    'pages/learning/lessons/exercises/multiple_choice_widget.dart',
    'pages/learning/lessons/exercises/ordering_widget.dart',
    'pages/learning/main/sections/ai_tools_tab.dart',
    'pages/learning/main/sections/daily_practice_card.dart',
    'pages/learning/vocabulary/vocab_pack_practice_screen.dart',
    'pages/learning/vocabulary/vocab_packs_screen.dart',
    'pages/learning/vocabulary/vocabulary_add_screen.dart',
    'pages/learning/vocabulary/vocabulary_screen.dart',
  ],
  'L6': [
    'pages/learning/achievements/achievements_screen.dart',
    'pages/learning/challenges/challenges_screen.dart',
    'widgets/learning/achievement_card.dart',
    'widgets/learning/challenge_card.dart',
    'widgets/learning/daily_goal_widget.dart',
    'widgets/learning/lesson_card.dart',
    'widgets/learning/streak_widget.dart',
    'widgets/learning/vocabulary_card.dart',
  ],
  'L7': [
    'pages/ai/quiz/ai_quiz_screen.dart',
    'pages/ai/quiz/quiz_player_screen.dart',
    'pages/ai/tutor/tutor_chat_screen.dart',
    'widgets/ai/answer_feedback_sheet.dart',
    'widgets/ai/lesson_assistant_widget.dart',
    'widgets/ai/lesson_summary_sheet.dart',
  ],
};

/// Keys whose draft may legitimately equal the English in some locale
/// (loanwords). Add with a one-line reason; empty by default.
const Set<String> _mayMatchEnglish = {
  'learnBonus', // de/fr/it/id/tl/tr use the English loanword "Bonus"
  'communityLv', // ja/ko/de/id/tl/zh/zh_TW keep the "Lv.{level}" abbreviation
  'momentsFileSizeMb', // ja/ko/tl/zh/zh_TW keep the "{size}MB" unit as written
  'chatStory', // de/fr/pt use the English loanword "Story"
  'chatPremium', // "Premium ✨" is the same word in de/es/fr/id/it/pt/tl/tr
  'chatAlternatives', // fr "Alternatives" is the same word
  'chatQrCode', // tl uses the English term
  'chatDraft', // tl uses the English loanword
  'learnWordBank', // tl keeps the English term "Word Bank"
  'learnAiAutoFill', // tl keeps "AI Auto-fill" as is
  'chatMediaPhoto', // fr "photo" is the same word
  'chatMediaVideo', // tl/id/de/it/pt/vi use the loanword "video"
  'chatMediaAudio', // many locales use the loanword "audio"
  'chatMediaFile', // id/tl use the loanword "file"
  'chatMediaGeneric', // id/tl use the loanword "media"
  'chatReplyingToFallback', // tl uses the English loanword "user"
  'aiQuizQuestionCount', // fr "1 question" / "{n} questions" is spelled exactly like English
};

final _placeholder = RegExp(r'\{(\w+)[,}]');

void main() {
  final arbs = <String, Map<String, dynamic>>{
    for (final f in Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb')))
      f.uri.pathSegments.last: jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
  };
  final en = arbs['app_en.arb']!;

  for (final task in _keysByTask.keys) {
    group(task, () {
      test('every key is in all 19 locales, translated, placeholders kept', () {
        expect(arbs.length, 19);
        final problems = <String>[];
        for (final key in _keysByTask[task]!) {
          final source = en[key];
          if (source is! String || source.trim().isEmpty) {
            problems.add('app_en.arb: $key missing');
            continue;
          }
          final names = _placeholder.allMatches(source).map((m) => m.group(1)!).toSet();
          arbs.forEach((file, map) {
            final value = map[key];
            if (value is! String || value.trim().isEmpty) {
              problems.add('$file: $key missing');
              return;
            }
            if (file != 'app_en.arb' && value == source && !_mayMatchEnglish.contains(key)) {
              problems.add('$file: $key left in English');
            }
            for (final n in names) {
              if (!value.contains('{$n')) problems.add('$file: $key lost {$n}');
            }
          });
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      });

      test('its files have no English Text literal left', () {
        final left = scanFiles(_filesByTask[task]!.map((f) => 'lib/$f'));
        expect(left, isEmpty, reason: left.join('\n'));
      });
    });
  }
}
