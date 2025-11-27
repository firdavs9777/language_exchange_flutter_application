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
}
