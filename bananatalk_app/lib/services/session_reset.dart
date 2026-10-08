import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bananatalk_app/pages/authentication/biometric/biometric_service.dart';
import 'package:bananatalk_app/pages/chat/state/chat_state_provider.dart'
    as chat_page_state;
import 'package:bananatalk_app/pages/community/main/community_main.dart';
import 'package:bananatalk_app/pages/learning/main/sections/daily_practice_card.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/pages/moments/feed/moments_main.dart';
import 'package:bananatalk_app/pages/moments/feed/muted_users_provider.dart';
import 'package:bananatalk_app/providers/active_voice_room_count_provider.dart';
import 'package:bananatalk_app/providers/ad_providers.dart';
import 'package:bananatalk_app/providers/app_provider_container.dart';
import 'package:bananatalk_app/providers/badge_count_provider.dart';
import 'package:bananatalk_app/providers/chat_state_provider.dart'
    as chat_state;
import 'package:bananatalk_app/providers/coins_provider.dart';
import 'package:bananatalk_app/providers/matching_provider.dart';
import 'package:bananatalk_app/providers/message_count_provider.dart';
import 'package:bananatalk_app/providers/notification_history_provider.dart';
import 'package:bananatalk_app/providers/notification_settings_provider.dart';
import 'package:bananatalk_app/providers/presence_provider.dart';
import 'package:bananatalk_app/providers/pronunciation_provider.dart';
import 'package:bananatalk_app/providers/provider_root/ai_providers.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_root/block_provider.dart';
import 'package:bananatalk_app/providers/provider_root/comments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/community_provider.dart';
import 'package:bananatalk_app/providers/provider_root/daily_matches_provider.dart';
import 'package:bananatalk_app/providers/provider_root/exam_study_provider.dart';
import 'package:bananatalk_app/providers/provider_root/learning/achievements_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/challenges_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/daily_pack_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/leaderboard_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/lessons_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/progress_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/quizzes_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocab_packs_providers.dart';
import 'package:bananatalk_app/providers/provider_root/learning/vocabulary_providers.dart';
import 'package:bananatalk_app/providers/provider_root/message_provider.dart';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:bananatalk_app/providers/provider_root/profile_visitor_provider.dart';
import 'package:bananatalk_app/providers/provider_root/user_limits_provider.dart';
import 'package:bananatalk_app/providers/provider_root/vip_provider.dart';
import 'package:bananatalk_app/providers/reels_provider.dart';
import 'package:bananatalk_app/providers/rooms_provider.dart';
import 'package:bananatalk_app/providers/tutor_provider.dart';
import 'package:bananatalk_app/providers/tutor_quota_provider.dart';
import 'package:bananatalk_app/providers/unread_count_provider.dart';
import 'package:bananatalk_app/providers/voice_room_provider.dart';
import 'package:bananatalk_app/services/api_client.dart';
import 'package:bananatalk_app/services/boost_api_client.dart';
import 'package:bananatalk_app/services/chat_socket_service.dart';
import 'package:bananatalk_app/services/global_chat_listener.dart';
import 'package:bananatalk_app/services/notification_service.dart';
import 'package:bananatalk_app/services/referral_service.dart';

/// Every Riverpod provider whose state belongs to the signed-in user, keyed
/// by its declared name (the key is what `session_reset_test.dart` checks
/// against the source, so a new provider must be classified here or in
/// [kAppScopedProviderNames] or the test fails).
///
/// Logout used to invalidate only `userProvider` + `authServiceProvider`, and
/// account deletion invalidated nothing, so the next account on the phone saw
/// the previous one's coins, blocked users, tutor memory, matches, visitors,
/// notification settings and waves badge until each happened to refetch.
///
/// Rule: anything loaded with the user's token, or UI state about their data,
/// is here. Public content that only costs a refetch is here too -- a reset
/// that is slightly too wide is harmless, one that is too narrow leaks.
final Map<String, ProviderOrFamily> userScopedProviders = {
  // Auth + profile
  'authServiceProvider': authServiceProvider,
  'userProvider': userProvider,
  'userLimitsProvider': userLimitsProvider,
  'currentUserLimitsProvider': currentUserLimitsProvider,
  'vipStatusProvider': vipStatusProvider,
  'isVipProvider': isVipProvider,
  'purchaseStateProvider': purchaseStateProvider,
  'purchaseErrorProvider': purchaseErrorProvider,
  'showAdsProvider': showAdsProvider,
  'myVisitorStatsProvider': myVisitorStatsProvider,
  'referralServiceProvider': referralServiceProvider,
  'boostApiClientProvider': boostApiClientProvider,
  // Coins
  'coinApiClientProvider': coinApiClientProvider,
  'coinBalanceProvider': coinBalanceProvider,
  'coinUnlockCatalogProvider': coinUnlockCatalogProvider,
  'coinUnlockedFeaturesProvider': coinUnlockedFeaturesProvider,
  'dailyRewardStatusProvider': dailyRewardStatusProvider,
  // Safety
  'blockedUsersProvider': blockedUsersProvider,
  'blockedUserIdsProvider': blockedUserIdsProvider,
  'mutedMomentsProvider': mutedMomentsProvider,
  // Notifications + badges
  'notificationSettingsProvider': notificationSettingsProvider,
  'notificationHistoryProvider': notificationHistoryProvider,
  'badgeCountProvider': badgeCountProvider,
  // Chat
  'messageServiceProvider': messageServiceProvider,
  'chatPartnersProvider': chatPartnersProvider,
  'totalUnreadProvider': totalUnreadProvider,
  'messageCountProvider': messageCountProvider,
  'canCallProvider': canCallProvider,
  'chatStateProvider (providers/)': chat_state.chatStateProvider,
  'chatStateProvider (pages/chat/state/)': chat_page_state.chatStateProvider,
  'presenceProvider': presenceProvider,
  // Re-armed on invalidate: its dispose() stops the old subscriptions and the
  // rebuild (MyApp watches it) starts fresh ones for the next account. Before
  // this, logout's GlobalChatListener().stop() left it dead until a restart.
  'globalChatListenerProvider': globalChatListenerProvider,
  // Community / matching
  'communityProvider': communityProvider,
  'communityServiceProvider': communityServiceProvider,
  'filterMatchCountProvider': filterMatchCountProvider,
  'singleCommunityProvider': singleCommunityProvider,
  'wavesUnreadProvider': wavesUnreadProvider,
  'pendingIntrosProvider': pendingIntrosProvider,
  'topicUsersProvider': topicUsersProvider,
  'partnerSegmentProvider': partnerSegmentProvider,
  'partnerFilterProvider': partnerFilterProvider,
  'communityPendingSubTabProvider': communityPendingSubTabProvider,
  'dailyMatchesProvider': dailyMatchesProvider,
  'matchingRecommendationsProvider': matchingRecommendationsProvider,
  'quickMatchesProvider': quickMatchesProvider,
  'matchByLanguageProvider': matchByLanguageProvider,
  'similarUsersProvider': similarUsersProvider,
  'matchingTabProvider': matchingTabProvider,
  'matchingLanguageFilterProvider': matchingLanguageFilterProvider,
  'matchingLanguagesProvider': matchingLanguagesProvider,
  // Moments / reels / comments
  'momentsServiceProvider': momentsServiceProvider,
  'momentsProvider': momentsProvider,
  'momentsFeedFreshnessProvider': momentsFeedFreshnessProvider,
  'momentsFeedProvider': momentsFeedProvider,
  'forYouMomentsProvider': forYouMomentsProvider,
  'followingMomentsProvider': followingMomentsProvider,
  'exploreMomentsProvider': exploreMomentsProvider,
  'trendingMomentsProvider': trendingMomentsProvider,
  'promptOfDayProvider': promptOfDayProvider,
  'userMomentsProvider': userMomentsProvider,
  'momentFilterProvider': momentFilterProvider,
  'filteredMomentsProvider': filteredMomentsProvider,
  'momentsFeedTabProvider': momentsFeedTabProvider,
  'filteredMomentsForTabProvider': filteredMomentsForTabProvider,
  'reelsApiClientProvider': reelsApiClientProvider,
  'reelsFeedProvider': reelsFeedProvider,
  'commentsServiceProvider': commentsServiceProvider,
  'paginatedCommentsProvider': paginatedCommentsProvider,
  // Rooms
  'roomApiClientProvider': roomApiClientProvider,
  'roomsProvider': roomsProvider,
  'voiceRoomProvider': voiceRoomProvider,
  'activeVoiceRoomCountProvider': activeVoiceRoomCountProvider,
  // Tutor + AI
  'tutorServiceProvider': tutorServiceProvider,
  'tutorMemoryAndQuotasProvider': tutorMemoryAndQuotasProvider,
  'tutorMemoryProvider': tutorMemoryProvider,
  'tutorDailyPlanProvider': tutorDailyPlanProvider,
  'tutorRecentSessionsProvider': tutorRecentSessionsProvider,
  'tutorScenariosProvider': tutorScenariosProvider,
  'tutorChatControllerProvider': tutorChatControllerProvider,
  'tutorQuotaProvider': tutorQuotaProvider,
  'pronunciationControllerProvider': pronunciationControllerProvider,
  'conversationProvider': conversationProvider,
  'conversationHistoryProvider': conversationHistoryProvider,
  'conversationTopicsProvider': conversationTopicsProvider,
  'practiceScenariosProvider': practiceScenariosProvider,
  'grammarFeedbackHistoryProvider': grammarFeedbackHistoryProvider,
  'pronunciationHistoryProvider': pronunciationHistoryProvider,
  'pronunciationStatsProvider': pronunciationStatsProvider,
  'aiQuizzesProvider': aiQuizzesProvider,
  'aiQuizStatsProvider': aiQuizStatsProvider,
  'aiQuizProvider': aiQuizProvider,
  'weakAreasProvider': weakAreasProvider,
  // Learning
  'dailyPracticeProvider': dailyPracticeProvider,
  'achievementsProvider': achievementsProvider,
  'challengesProvider': challengesProvider,
  'dailyPackProvider': dailyPackProvider,
  'masteryProvider': masteryProvider,
  'weeklyReportProvider': weeklyReportProvider,
  'xpLeaderboardProvider': xpLeaderboardProvider,
  'streakLeaderboardProvider': streakLeaderboardProvider,
  'friendsLeaderboardProvider': friendsLeaderboardProvider,
  'myRanksProvider': myRanksProvider,
  'leaderboardPeriodProvider': leaderboardPeriodProvider,
  'streakTypeProvider': streakTypeProvider,
  'leaderboardTabIndexProvider': leaderboardTabIndexProvider,
  'lessonFilterProvider': lessonFilterProvider,
  'lessonsProvider': lessonsProvider,
  'recommendedLessonsProvider': recommendedLessonsProvider,
  'lessonDetailProvider': lessonDetailProvider,
  'lessonPlayerProvider': lessonPlayerProvider,
  'learningProgressProvider': learningProgressProvider,
  'weeklyDigestProvider': weeklyDigestProvider,
  'quizzesProvider': quizzesProvider,
  'quizDetailProvider': quizDetailProvider,
  'quizPlayerProvider': quizPlayerProvider,
  'vocabPackLevelFilterProvider': vocabPackLevelFilterProvider,
  'vocabPacksProvider': vocabPacksProvider,
  'vocabPackDetailProvider': vocabPackDetailProvider,
  'vocabularyFilterProvider': vocabularyFilterProvider,
  'vocabularyListProvider': vocabularyListProvider,
  'dueReviewsProvider': dueReviewsProvider,
  'vocabularyStatsProvider': vocabularyStatsProvider,
  'vocabularyReviewProvider': vocabularyReviewProvider,
  // Exam study (progress + plan are per user; the content refetches cheaply)
  'examStudyServiceProvider': examStudyServiceProvider,
  'examLanguagesProvider': examLanguagesProvider,
  'examsForLanguageProvider': examsForLanguageProvider,
  'sectionsForExamProvider': sectionsForExamProvider,
  'questionsForSectionProvider': questionsForSectionProvider,
  'topicsForSectionProvider': topicsForSectionProvider,
  'userExamProgressProvider': userExamProgressProvider,
  'userStudyPlanProvider': userStudyPlanProvider,
  'vocabularyLevelsProvider': vocabularyLevelsProvider,
  'vocabularyTopicsProvider': vocabularyTopicsProvider,
  'vocabularyWordsProvider': vocabularyWordsProvider,
  'examStudyTipsProvider': examStudyTipsProvider,
  // Navigation: the next account starts on the first tab.
  'selectedTabProvider': selectedTabProvider,
};

/// Providers deliberately NOT reset: device/app-level, public catalogs, or
/// objects whose identity other code holds on to.
const Set<String> kAppScopedProviderNames = {
  'themeProvider', // device appearance
  'languageProvider', // app UI language
  'apiClientProvider', // ApiClient() singleton; its token cache is cleared
  'globalErrorProvider', // the session-expiry plumbing itself
  'callProvider', // wired to the socket once in MyApp; an active call is
  // ended by AuthService.onSessionEnding instead
  'adServiceProvider',
  'languagesProvider', // public language catalog
  'languageNamesProvider',
  'taggableLanguagesProvider',
  'voiceRoomLanguagesProvider',
  'appConfigServiceProvider',
  'appConfigProvider',
  'runningAppVersionProvider',
  'iosProductsProvider', // store catalog
  'androidProductsProvider',
  'pronunciationVoiceServiceProvider', // TTS engine
  'giphyServiceProvider',
  // The upload queue is a singleton the providers only observe; its tasks
  // are dropped and in-flight uploads abandoned by
  // UploadQueueService.endSession() (AuthService.onSessionEnding).
  'uploadQueueServiceProvider',
  'uploadManagerProvider',
  'uploadProgressStreamProvider',
  'activeUploadsCountProvider',
  'hasActiveUploadsProvider',
  'currentUploadingTaskProvider',
};

/// Invalidates one provider; `ref.invalidate` / `container.invalidate`.
typedef ProviderInvalidator = void Function(ProviderOrFamily provider);

/// The ONE place a signed-in session is torn down on this device.
///
/// Used by logout, account deletion, the suspended-account handler and the
/// session-expired (refresh definitively failed) handler, so they cannot drift
/// apart again. Steps:
///  1. stop GlobalChatListener and disconnect the chat socket;
///  2. when [clearAuthData] (callers whose AuthService call has not already
///     done it): AuthService's local teardown -- socket logout event, push
///     token unregistered, in-memory + stored tokens, user prefs, ApiClient
///     token caches, image cache;
///  3. drop the ApiClient token cache again (cheap, and covers callers that
///     skip step 2) and zero the OS app-icon badge;
///  4. when [forgetBiometric] (account deleted / suspended): wipe the
///     biometric snapshot, which would otherwise offer "Continue as <name>"
///     for an account that no longer exists;
///  5. invalidate every provider in [userScopedProviders].
///
/// Never throws: a logout must always complete.
Future<void> resetUserSession({
  ProviderInvalidator? invalidate,
  bool clearAuthData = true,
  bool forgetBiometric = false,
  ProviderContainer? container,
}) async {
  final c = container ?? appProviderContainer;
  final inv = invalidate ?? c.invalidate;

  try {
    GlobalChatListener().stop();
  } catch (e) {
    debugPrint('[session-reset] listener stop failed: $e');
  }
  try {
    final socket = ChatSocketService();
    socket.disableReconnection();
    await socket.disconnect();
  } catch (e) {
    debugPrint('[session-reset] socket disconnect failed: $e');
  }

  if (clearAuthData) {
    try {
      await c.read(authServiceProvider).clearLocalSession();
    } catch (e) {
      debugPrint('[session-reset] auth clear failed: $e');
    }
  }

  ApiClient().clearTokenCache();
  try {
    await NotificationService().updateBadgeCount(0);
  } catch (_) {}

  if (forgetBiometric) {
    try {
      await BiometricService().disable();
    } catch (e) {
      debugPrint('[session-reset] biometric wipe failed: $e');
    }
  }

  invalidateUserScopedProviders(inv);
}

/// Step 5 of [resetUserSession], split out so it is testable without plugins.
void invalidateUserScopedProviders(ProviderInvalidator invalidate) {
  for (final entry in userScopedProviders.entries) {
    try {
      invalidate(entry.value);
    } catch (e) {
      debugPrint('[session-reset] invalidate ${entry.key} failed: $e');
    }
  }
}

/// Server logout + full local reset, for the gates that end a session the
/// user cannot enter (declined Terms, unfinished mandatory profile).
/// Leaving one of those with the session alive sent the user to /login and
/// straight back into the same gate on the next launch.
Future<void> signOutAndReset(AuthService auth, {ProviderContainer? container}) async {
  try {
    await auth.logout();
  } catch (e) {
    debugPrint('[session-reset] logout failed: $e');
  }
  await resetUserSession(clearAuthData: false, container: container);
}
