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

  // User limits endpoints
  static String getUserLimitsURL(String userId) => 'auth/users/$userId/limits';
  
  // VIP subscription endpoints
  static String getVipStatusURL(String userId) => 'auth/users/$userId/vip/status';
  
  // iOS purchase endpoints
  static const String iosVerifyPurchaseURL = 'purchases/ios/verify';
  static const String iosSubscriptionStatusURL = 'purchases/ios/subscription-status';

  // Chat endpoints - Message Management
  static String editMessageURL(String messageId) => 'messages/$messageId';
  static String deleteMessageURL(String messageId) => 'messages/$messageId';
  static String replyToMessageURL(String messageId) => 'messages/$messageId/reply';
  static String forwardMessageURL(String messageId) => 'messages/$messageId/forward';
  static String pinMessageURL(String messageId) => 'messages/$messageId/pin';
  static String unpinMessageURL(String messageId) => 'messages/$messageId/unpin';
  static String getMessageRepliesURL(String messageId) => 'messages/$messageId/replies';
  
  // Chat endpoints - Message Reactions
  static String addReactionURL(String messageId) => 'messages/$messageId/reactions';
  static String removeReactionURL(String messageId, String emoji) => 'messages/$messageId/reactions/$emoji';
  static String getReactionsURL(String messageId) => 'messages/$messageId/reactions';
  
  // Chat endpoints - Message Search
  static const String searchMessagesURL = 'messages/search';
  
  // Chat endpoints - User Blocking
  static String blockUserURL(String userId) => 'users/$userId/block';
  static String unblockUserURL(String userId) => 'users/$userId/block';
  static String getBlockedUsersURL(String userId) => 'users/$userId/blocked';
  static String checkBlockStatusURL(String userId, String targetUserId) => 'users/$userId/block-status/$targetUserId';
  
  // Chat endpoints - Conversations
  static const String conversationsURL = 'conversations';
  static const String createConversationRoomURL = 'conversations'; // POST
  static String getConversationURL(String conversationId) => 'conversations/$conversationId';
  static String muteConversationURL(String conversationId) => 'conversations/$conversationId/mute';
  static String unmuteConversationURL(String conversationId) => 'conversations/$conversationId/unmute';
  static String archiveConversationURL(String conversationId) => 'conversations/$conversationId/archive';
  static String unarchiveConversationURL(String conversationId) => 'conversations/$conversationId/unarchive';
  static String pinConversationURL(String conversationId) => 'conversations/$conversationId/pin';
  static String unpinConversationURL(String conversationId) => 'conversations/$conversationId/unpin';
  static String markConversationReadURL(String conversationId) => 'conversations/$conversationId/read';
}
