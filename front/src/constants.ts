// export const BASE_URL = "http://localhost:5003";
// export const BASE_URL = "http://64.23.181.246:5003";
// export const BASE_URL = "";
export const BASE_URL = process.env.NODE_ENV === "development"
  ? "https://api.banatalk.com"   // Development: direct API
  : "";  // Production: use proxy
export const MOMENTS_URL = "/api/v1/moments";
export const USERS_URL = "/api/v1/users";
export const COMMUNITY_URL = "/api/v1/auth/users";
export const MESSAGES_URL = "/api/v1/messages";
export const LOGIN_URL = "/api/v1/auth/login";
export const REGISTER_URL = "/api/v1/auth/register";
export const LOGOUT_URL = "/api/v1/auth/logout";

// router.post('/forgot-password', forgotPassword);
// router.post('/verify-reset-code', verifyResetCode);
// router.post('/reset-password', resetPassword);
export const SEND_EMAIL_CODE = "/api/v1/auth/forgot-password";
export const REGISTER_EMAIL_CODE = "/api/v1/auth/sendEmailCode";
export const CONFIRM_EMAIL_CODE = "/api/v1/auth/verify-reset-code";
export const RESET_USER_PASSWORD = "/api/v1/auth/reset-password";
export const COMMENTS = "comments";
export const USER_PROFILE_URL = "/api/v1/auth/me";
export const USER_PROFILE_UPDATE = "/api/v1/auth/updatedetails";
export const STORIES_FEED = "/api/v1/stories/feed";
export const MY_STORIES = "/api/v1/stories/my-stories";
export const MAIN_STORIES = "/api/v1/stories";
export const USER_STORIES = "/api/v1/stories/user/";
