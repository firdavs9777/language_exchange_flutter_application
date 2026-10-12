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
  'L8': [
    'aiAnalyzing',
    'aiExcellentPronunciation',
    'aiGenerateLesson',
    'aiGeneratingEllipsis',
    'aiGoodJob',
    'aiIssuesCount',
    'aiNoActiveConversations',
    'aiNoCompletedConversations',
    'aiSelect',
    'aiStartInLanguage',
    'aiFailedLoadHistory',
    'aiConversationMessageCount',
    'aiStartNewConversationSee',
    'aiLoadingMessages',
    'aiNoMessagesConversation',
    'aiDifficultyLevel',
    'aiScenarios',
    'aiGrammarCheck',
    'aiRecentAnalysis',
    'aiCheckGrammar',
    'aiLanguageLabel',
    'aiGrammarIssuesFound',
    'aiPerfect',
    'aiNoGrammarIssuesFound',
    'aiIssuesFound',
    'aiCorrected',
    'aiWhy',
    'aiGrammarExamples',
    'aiImprovedSuggestions',
    'aiNoAnalysisHistoryYet',
    'aiLessonBuilder',
    'aiGenerateCustomLessons',
    'aiCreatesPersonalizedLessonsAny',
    'aiExercises',
    'aiSuggestedTopics',
    'aiCreatingLesson',
    'aiGeneratingExercisesContent',
    'aiLessonGenerated',
    'aiGenerateAnother',
    'aiStartLesson',
    'aiPronunciationPractice',
    'aiPracticeHistory',
    'aiTextPractice',
    'aiWordAnalysis',
    'aiNoPracticeHistoryYet',
    'aiSmartTranslation',
    'aiWordBreakdown',
    'aiAlternativeTranslations',
    'aiGrammarNotes',
    'aiIdiomsExpressions',
    'aiLiteral',
    'aiMeaning',
    'aiEquivalent',
    'aiCulturalContext',
  ],
  'L9': [
    'profileBuyMeCoffee',
    'profileOr',
    'profileLoadingNotifications',
    'profileLoadingSettings',
    'profileAdmin',
    'profileSelected',
    'profilePrivacyIntro',
    'profileUpdate',
    'profileNoTopicsCategory',
    'profileAdminTools',
    'profileCompletionAdd',
    'profileActive',
    'profileAutoSaveEnabled',
    'profileChangesSavedInstantlyWhen',
    'profileCurrentTheme',
    'profileThemeChangesApplyInstantly',
    'profileLoadingVisitors',
    'momentsPullDownRefresh',
    'profileSeeWhoChecked',
    'profileRecentVisitors',
    'profileNoReportsSubmitted',
    'profileReportsSubmitWillAppear',
    'profileReportTypeTitle',
    'profileReportReason',
    'profileDeleteAccountFinalBody',
    'profileThanksForWatching',
    'profileNotificationsOn',
    'profileNotificationsOff',
    'profileMaximumReached',
    'profilePickYourInterests',
    'profileDeselectToChooseAnother',
    'profileTapTopicsMatchVibe',
    'profileEnjoyingPremium',
    'profileUnlockUnlimited',
    'profileBirthYear',
    'profileReportTypeUser',
    'profileReportTypeMoment',
    'profileReportTypeComment',
    'profileReportTypeMessage',
    'profileReportTypeStory',
    'profileReportReasonCopyright',
  ],
  'L10': [
    'storyOptimizingBestExperience',
    'storyCreate',
    'storyAddTags',
    'storyVideoSelected',
    'storyAddPoll',
    'storyOptions',
    'storyAddQuestion',
    'storyPrompt',
    'storyTapAnywhereAddText',
    'storyHighlightStoryCount',
    'storySendFriends',
    'storySelected',
    'storyShareSave',
    'storySeenBy',
    'storyNoViewsYet',
    'storyEditVideo',
    'storyVotes',
    'storyCreatePoll',
    'storySendAnonymously',
    'storyResponseCount',
    'storyViewResponses',
    'storyResponsesTitle',
    'storyNoResponsesYet',
    'storyQuestionBox',
    'storySent',
    'storyProcessing',
    'storyHd',
    'storyVideoMeta',
    'storyUserFallback',
    'storySendCount',
    'storyFailedToDelete',
    'storyAnonymous',
  ],
  'L11': [
    'vipNoCoinActivityYet',
    'vipCoinShopExplainer',
    'vipLimitReached',
    'vipCoins',
    'vipBonusIncluded',
    'vipVisitorModeLimitReached',
    'vipWhatGetFreeAccount',
    'vipCreateFreeAccount',
    'vipGoUnlimitedAccess',
    'vipContinueAsVisitor',
    'vipResets',
    'vipUsedToday',
    'vipTierVisitor',
    'vipTierMember',
    'vipAd',
    'promoAdsNoticeTitle',
    'promoAdsNoticeBody',
    'promoAdsNoticeGotIt',
    'vipOnly',
    'vipTapUpgrade',
    'vipUnlockFeatures',
    'vipUpPillUp',
    'vipChooseOption',
    'promoWelcomeBackTitle',
    'promoWelcomeBackBody',
    'promoWelcomeBackCta',
    'vipCoinsPerAdInfo',
    'vipUpgradeUnlockMore',
    'vipUpgradeNow',
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
  'L8': [
    'pages/ai/conversation/conversation_history_screen.dart',
    'pages/ai/conversation/topic_selection_sheet.dart',
    'pages/ai/grammar/grammar_feedback_screen.dart',
    'pages/ai/lesson_builder/lesson_builder_screen.dart',
    'pages/ai/pronunciation/pronunciation_screen.dart',
    'pages/ai/translation/translation_screen.dart',
  ],
  'L9': [
    'pages/menu_tab/TabBarMenu.dart',
    'pages/notifications/notification_history_screen.dart',
    'pages/notifications/notification_settings_screen.dart',
    'pages/profile/drawer/drawer_section.dart',
    'pages/profile/edit/language_edit.dart',
    'pages/profile/edit/picture_edit/photo_grid_tile.dart',
    'pages/profile/edit/privacy_edit.dart',
    'pages/profile/edit/topics_edit.dart',
    'pages/profile/profile_main.dart',
    'pages/profile/profile_main/sections/profile_about_tab.dart',
    'pages/profile/profile_main/sections/profile_highlights_tab.dart',
    'pages/profile/settings.dart',
    'pages/profile/theme.dart',
    'pages/profile/visitors_screen.dart',
    'pages/reports/my_reports_screen.dart',
    'pages/settings/account_deletion.dart',
  ],
  'L10': [
    'pages/stories/create/create_story_screen.dart',
    'pages/stories/create/poll_sticker_editor.dart',
    'pages/stories/create/question_sticker_editor.dart',
    'pages/stories/create/studio/story_canvas.dart',
    'pages/stories/create/studio/text_overlay_editor.dart',
    'pages/stories/feed/stories_feed_widget.dart',
    'pages/stories/highlights/highlight_editor_sheet.dart',
    'pages/stories/viewer/story_share_sheet.dart',
    'pages/stories/viewer/story_viewer_screen.dart',
    'pages/stories/viewer/story_viewers_sheet.dart',
    'pages/video_editor/video_editor_screen.dart',
    'widgets/story/story_poll_widget.dart',
    'widgets/story/story_question_box_widget.dart',
  ],
  'L11': [
    'pages/coins/coin_history_screen.dart',
    'pages/coins/coin_shop_screen.dart',
    'pages/vip/visitor_upgrade_screen.dart',
    'utils/api_error_handler.dart',
    'utils/feature_gate.dart',
    'widgets/ads/ad_widgets.dart',
    'widgets/promo/ads_notice_modal.dart',
    'widgets/promo/announcement_modal.dart',
    'widgets/tutor/persona_upgrade_sheet.dart',
    'widgets/vip_locked_feature.dart',
    'widgets/vip_up_pill.dart',
    'widgets/visitor_limit_dialog.dart',
    'widgets/welcome_back_modal.dart',
  ],
};

/// Keys whose draft may legitimately equal the English in some locale
/// (loanwords). Add with a one-line reason; empty by default.
const Set<String> _mayMatchEnglish = {
  'vipUpPillUp', // fr keeps the English "Up" badge word
  'profileReportTypeMoment', // de/fr/tl use the English loanword "Moment"
  'profileReportTypeMessage', // fr "Message" is the same word
  'profileReportTypeStory', // de/fr/pt/tl/vi use the English loanword "Story"
  'profileReportReasonCopyright', // it uses the English loanword "Copyright"
  'profileAdmin', // de/es/fr/id/it/pt/tl use the same "ADMIN" badge abbreviation
  'aiLiteral', // es/pt/tl "Literal: {…}" is the same word
  'aiConversationMessageCount', // fr "{count} messages" is the same word
  'aiLessonBuilder', // tl keeps the English product name "AI Lesson Builder"
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
  'storyHd', // "HD" is the international quality badge in every locale
  'storyVideoMeta', // ja/ko/zh/zh_TW/tl keep the "MB" unit: "{duration} | {size}MB"
  'storyUserFallback', // tl uses the loanword "User"
  'storyAnonymous', // tl uses the loanword "Anonymous"
  'storyOptions', // fr "Options" is the same word
  'storyPrompt', // tl uses the loanword "Prompt"
  'storyHighlightStoryCount', // fr/pt use the loanword "stories" (same plural form)
  'storyEditVideo', // id "Edit Video" is the same phrase
  'storyVotes', // fr "{totalVotes} votes" is the same word
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
