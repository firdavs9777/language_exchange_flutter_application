class Endpoints {
  // Use localhost for development (emulator/simulator)
  // For real device, use your computer's local IP (e.g., http://192.168.1.100:5003/api/v1/)
  // static String baseURL = "http://localhost:5003/api/v1/";
  static String baseURL = "https://api.banatalk.com/api/v1/"; // Production URL
  static String loginURL = "auth/login";
  static String sendCode = "auth/sendCodeEmail";
  static String verifyEmailCode = "auth/verifyEmailCode";
  static String resetPassword = "auth/resetpassword";
  static String logoutURL = "auth/logout";
  static String registerURL = "auth/register";
  static String momentsURL = "moments";
  static String commentUrl = "comments";
  static String messageUrl = "messages";
  static String userUrl = "user";
  static String senderUrl = "senders";
  static String usersURL = "auth/users";
  static String languagesURL = "languages";
  static String countriesURL = "https://restcountries.com/v3.1/all";
  static const String facebookMobileLoginURL =
      'auth/facebook-mobile'; // Add this line

  // You can also add other Facebook-related endpoints if needed
  static const String facebookVerifyURL = 'auth/facebook-verify';

  // Refresh token endpoints
  static const String refreshTokenURL = 'auth/refresh-token';
  static const String logoutAllURL = 'auth/logout-all';

  // OAuth endpoints
  static const String googleLoginURL = 'auth/google';
  static const String googleCallbackURL = 'auth/google/callback';
  
  // Profile update endpoint
  static const String updateDetailsURL = 'auth/updatedetails';
  
  // Terms of Service endpoint
  static const String acceptTermsURL = 'auth/accept-terms';

  // User limits endpoints
  static String getUserLimitsURL(String userId) => 'auth/users/$userId/limits';
  
  // VIP subscription endpoints
  static String getVipStatusURL(String userId) =>
      'auth/users/$userId/vip/status';
  
  // iOS purchase endpoints
  static const String iosVerifyPurchaseURL = 'purchases/ios/verify';
  static const String iosSubscriptionStatusURL =
      'purchases/ios/subscription-status';

  // Chat endpoints - Message Management
  static String editMessageURL(String messageId) => 'messages/$messageId';
  static String deleteMessageURL(String messageId) => 'messages/$messageId';
  static String replyToMessageURL(String messageId) =>
      'messages/$messageId/reply';
  static String forwardMessageURL(String messageId) =>
      'messages/$messageId/forward';
  static String pinMessageURL(String messageId) => 'messages/$messageId/pin';
  static String unpinMessageURL(String messageId) =>
      'messages/$messageId/unpin';
  static String getMessageRepliesURL(String messageId) =>
      'messages/$messageId/replies';
  
  // Chat endpoints - Message Reactions
  static String addReactionURL(String messageId) =>
      'messages/$messageId/reactions';
  static String removeReactionURL(String messageId, String emoji) =>
      'messages/$messageId/reactions/$emoji';
  static String getReactionsURL(String messageId) =>
      'messages/$messageId/reactions';
  
  // Chat endpoints - Message Search
  static const String searchMessagesURL = 'messages/search';
  
  // Chat endpoints - User Blocking
  static String blockUserURL(String userId) => 'users/$userId/block';
  static String unblockUserURL(String userId) => 'users/$userId/block';
  static String getBlockedUsersURL(String userId) => 'users/$userId/blocked';
  static String checkBlockStatusURL(String userId, String targetUserId) =>
      'users/$userId/block-status/$targetUserId';
  static String reportUserURL(String userId) => 'users/$userId/report';
  
  // Chat endpoints - Conversations
  static const String conversationsURL = 'conversations';
  static const String createConversationRoomURL = 'conversations'; // POST
  static String getConversationURL(String conversationId) =>
      'conversations/$conversationId';
  static String muteConversationURL(String conversationId) =>
      'conversations/$conversationId/mute';
  static String unmuteConversationURL(String conversationId) =>
      'conversations/$conversationId/unmute';
  static String archiveConversationURL(String conversationId) =>
      'conversations/$conversationId/archive';
  static String unarchiveConversationURL(String conversationId) =>
      'conversations/$conversationId/unarchive';
  static String pinConversationURL(String conversationId) =>
      'conversations/$conversationId/pin';
  static String unpinConversationURL(String conversationId) =>
      'conversations/$conversationId/unpin';
  static String markConversationReadURL(String conversationId) =>
      'conversations/$conversationId/read';
  
  // Conversation Theme/Wallpaper
  static String conversationThemeURL(String conversationId) =>
      'conversations/$conversationId/theme';
  
  // Quick Replies
  static String quickRepliesURL(String conversationId) =>
      'conversations/$conversationId/quick-replies';
  static String deleteQuickReplyURL(String conversationId, String replyId) =>
      'conversations/$conversationId/quick-replies/$replyId';
  
  // Nicknames
  static String nicknameURL(String conversationId) =>
      'conversations/$conversationId/nickname';
  
  // Voice Messages
  static const String voiceMessageURL = 'messages/voice';
  
  // Message Translation
  static String translateMessageURL(String messageId) =>
      'messages/$messageId/translate';
  static String getTranslationsURL(String messageId) =>
      'messages/$messageId/translations';
  
  // Moment Translation
  static String translateMomentURL(String momentId) =>
      'moments/$momentId/translate';
  static String getMomentTranslationsURL(String momentId) =>
      'moments/$momentId/translations';
  
  // Comment Translation
  static String translateCommentURL(String commentId) =>
      'comments/$commentId/translate';
  static String getCommentTranslationsURL(String commentId) =>
      'comments/$commentId/translations';
  
  // Message Bookmarks
  static String bookmarkMessageURL(String messageId) =>
      'messages/$messageId/bookmark';
  static const String getBookmarksURL = 'messages/bookmarks';
  
  // Message Corrections (HelloTalk style)
  static String correctMessageURL(String messageId) =>
      'messages/$messageId/correct';
  static String getCorrectionsURL(String messageId) =>
      'messages/$messageId/corrections';
  static String acceptCorrectionURL(String messageId, String correctionId) =>
      'messages/$messageId/corrections/$correctionId/accept';
  
  // Polls
  static const String createPollURL = 'messages/poll';
  static String votePollURL(String pollId) => 'messages/poll/$pollId/vote';
  static String getPollURL(String pollId) => 'messages/poll/$pollId';
  static String closePollURL(String pollId) => 'messages/poll/$pollId/close';
  
  // Mentions
  static const String getMentionsURL = 'messages/mentions';
  
  // Disappearing Messages
  static const String disappearingMessageURL = 'messages/disappearing';
  static String triggerDestructURL(String messageId) =>
      'messages/$messageId/trigger-destruct';
  
  // Secret Chat
  static String secretChatURL(String conversationId) =>
      'conversations/$conversationId/secret';
  
  // Moments - Save/Bookmark
  static String saveMomentURL(String momentId) => 'moments/$momentId/save';
  static String unsaveMomentURL(String momentId) => 'moments/$momentId/save';
  static const String savedMomentsURL = 'moments/saved';
  
  // Moments - Share
  static String shareMomentURL(String momentId) => 'moments/$momentId/share';
  
  // Moments - Report
  static String reportMomentURL(String momentId) => 'moments/$momentId/report';
  
  // Moments - Trending & Explore
  static const String trendingMomentsURL = 'moments/trending';
  static const String exploreMomentsURL = 'moments/explore';
  
  // Moments - User specific
  static String userMomentsURL(String userId) => 'moments/user/$userId';
  static String singleMomentURL(String momentId) => 'moments/$momentId';
  static String likeMomentURL(String momentId) => 'moments/$momentId/like';
  
  // Moments - Comments
  static String momentCommentsURL(String momentId) =>
      'moments/$momentId/comments';
  
  // Stories - Basic
  static const String storiesURL = 'stories';
  static const String storiesFeedURL = 'stories/feed';
  static const String myStoriesURL = 'stories/my-stories';
  static String userStoriesURL(String userId) => 'stories/user/$userId';
  static String singleStoryURL(String storyId) => 'stories/$storyId';
  static String viewStoryURL(String storyId) => 'stories/$storyId/view';
  static String storyViewsURL(String storyId) => 'stories/$storyId/views';
  
  // Stories - Reactions
  static String storyReactURL(String storyId) => 'stories/$storyId/react';
  static String storyReactionsURL(String storyId) =>
      'stories/$storyId/reactions';
  
  // Stories - Replies
  static String storyReplyURL(String storyId) => 'stories/$storyId/reply';
  
  // Stories - Polls
  static String storyPollVoteURL(String storyId) =>
      'stories/$storyId/poll/vote';
  
  // Stories - Question Box
  static String storyQuestionAnswerURL(String storyId) =>
      'stories/$storyId/question/answer';
  static String storyQuestionResponsesURL(String storyId) =>
      'stories/$storyId/question/responses';
  
  // Stories - Sharing
  static String storyShareURL(String storyId) => 'stories/$storyId/share';
  
  // Stories - Archive
  static const String storyArchiveURL = 'stories/archive';
  static String archiveStoryURL(String storyId) => 'stories/$storyId/archive';
  
  // Stories - Highlights
  static const String storyHighlightsURL = 'stories/highlights';
  static String highlightUserURL(String userId) =>
      'stories/highlights/user/$userId';
  static String singleHighlightURL(String highlightId) =>
      'stories/highlights/$highlightId';
  static String highlightStoriesURL(String highlightId) =>
      'stories/highlights/$highlightId/stories';
  static String removeFromHighlightURL(String highlightId, String storyId) =>
      'stories/highlights/$highlightId/stories/$storyId';
  
  // Stories - Close Friends
  static const String closeFriendsURL = 'stories/close-friends';
  static String closeFriendURL(String userId) =>
      'stories/close-friends/$userId';

  // Profile Visitors
  static String recordProfileVisitURL(String userId) =>
      'auth/users/$userId/profile-visit';
  static String getProfileVisitorsURL(String userId) =>
      'auth/users/$userId/visitors';
  static const String getMyVisitorStatsURL = 'auth/users/me/visitor-stats';
  static const String clearMyVisitorsURL = 'auth/users/me/visitors';
  static const String getVisitedProfilesURL = 'auth/users/me/visited-profiles';
}
