// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BananaTalk';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get or => 'OR';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign In with Apple';

  @override
  String get signInWithFacebook => 'Sign in with Facebook';

  @override
  String get welcome => 'Welcome';

  @override
  String get home => 'Home';

  @override
  String get messages => 'Messages';

  @override
  String get moments => 'Moments';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get autoTranslate => 'Auto Translate';

  @override
  String get autoTranslateMessages => 'Auto Translate Messages';

  @override
  String get autoTranslateMoments => 'Auto Translate Moments';

  @override
  String get autoTranslateComments => 'Auto Translate Comments';

  @override
  String get translate => 'Translate';

  @override
  String get translated => 'Translated';

  @override
  String get showOriginal => 'Show Original';

  @override
  String get showTranslation => 'Show Translation';

  @override
  String get translating => 'Translating...';

  @override
  String get translationFailed => 'Translation failed';

  @override
  String get noTranslationAvailable => 'No translation available';

  @override
  String translatedFrom(String language) {
    return 'Translated from $language';
  }

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get like => 'Like';

  @override
  String get comment => 'Comment';

  @override
  String get send => 'Send';

  @override
  String get search => 'Search';

  @override
  String get notifications => 'Notifications';

  @override
  String get followers => 'Followers';

  @override
  String get following => 'Following';

  @override
  String get posts => 'Posts';

  @override
  String get visitors => 'Visitors';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get networkError => 'Network error. Please check your connection.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get deviceLanguage => 'Device Language';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return 'Your device is set to: $flag $name';
  }

  @override
  String get youCanOverride => 'You can override the device language below.';

  @override
  String languageChangedTo(String name) {
    return 'Language changed to $name';
  }

  @override
  String get errorChangingLanguage => 'Error changing language';

  @override
  String get autoTranslateSettings => 'Auto-Translate Settings';

  @override
  String get automaticallyTranslateIncomingMessages => 'Automatically translate incoming messages';

  @override
  String get automaticallyTranslateMomentsInFeed => 'Automatically translate moments in feed';

  @override
  String get automaticallyTranslateComments => 'Automatically translate comments';

  @override
  String get translationServiceBeingConfigured => 'Translation service is being configured. Please try again later.';

  @override
  String get translationUnavailable => 'Translation unavailable';

  @override
  String get showLess => 'show less';

  @override
  String get showMore => 'show more';

  @override
  String get comments => 'Comments';

  @override
  String get beTheFirstToComment => 'Be the first to comment.';

  @override
  String get writeAComment => 'Write a comment...';

  @override
  String get report => 'Report';

  @override
  String get reportMoment => 'Report Moment';

  @override
  String get reportUser => 'Report User';

  @override
  String get deleteMoment => 'Delete Moment?';

  @override
  String get thisActionCannotBeUndone => 'This action cannot be undone.';

  @override
  String get momentDeleted => 'Moment deleted';

  @override
  String get editFeatureComingSoon => 'Edit feature coming soon';

  @override
  String get userNotFound => 'User not found';

  @override
  String get cannotReportYourOwnComment => 'Cannot report your own comment';

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get editYourProfileInformation => 'Edit your profile information';

  @override
  String get blockedUsers => 'Blocked Users';

  @override
  String get manageBlockedUsers => 'Manage blocked users';

  @override
  String get manageNotificationSettings => 'Manage notification settings';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get controlYourPrivacy => 'Control your privacy';

  @override
  String get changeAppLanguage => 'Change app language';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeAndDisplaySettings => 'Theme and display settings';

  @override
  String get myReports => 'My Reports';

  @override
  String get viewYourSubmittedReports => 'View your submitted reports';

  @override
  String get reportsManagement => 'Reports Management';

  @override
  String get manageAllReportsAdmin => 'Manage all reports (Admin)';

  @override
  String get legalPrivacy => 'Legal & Privacy';

  @override
  String get termsPrivacySubscriptionInfo => 'Terms, Privacy & Subscription info';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get getHelpAndSupport => 'Get help and support';

  @override
  String get aboutBanaTalk => 'About BanaTalk';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get permanentlyDeleteYourAccount => 'Permanently delete your account';

  @override
  String get loggedOutSuccessfully => 'Logged out successfully';

  @override
  String get retry => 'Retry';

  @override
  String get giftsLikes => 'Gifts/Likes';

  @override
  String get details => 'Details';

  @override
  String get to => 'to';

  @override
  String get banaTalk => 'BanaTalk';

  @override
  String get community => 'Community';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String yearsOld(String age) {
    return '$age years old';
  }

  @override
  String get searchConversations => 'Search conversations...';

  @override
  String get visitorTrackingNotAvailable => 'Visitor tracking feature is not available yet. Backend update required.';

  @override
  String get chatList => 'ChatList';

  @override
  String get languageExchange => 'Language Exchange';

  @override
  String get nativeLanguage => 'Native Language';

  @override
  String get learning => 'Learning';

  @override
  String get notSet => 'Not set';

  @override
  String get about => 'About';

  @override
  String get aboutMe => 'About Me';

  @override
  String get photos => 'Photos';

  @override
  String get camera => 'Camera';

  @override
  String get createMoment => 'Create Moment';

  @override
  String get addATitle => 'Add a title...';

  @override
  String get whatsOnYourMind => 'What\'s on your mind?';

  @override
  String get addTags => 'Add Tags';

  @override
  String get done => 'Done';

  @override
  String get add => 'Add';

  @override
  String get enterTag => 'Enter tag';

  @override
  String get post => 'Post';

  @override
  String get commentAddedSuccessfully => 'Comment added successfully';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get turnAllNotificationsOnOrOff => 'Turn all notifications on or off';

  @override
  String get notificationTypes => 'Notification Types';

  @override
  String get chatMessages => 'Chat Messages';

  @override
  String get getNotifiedWhenYouReceiveMessages => 'Get notified when you receive messages';

  @override
  String get likesAndCommentsOnYourMoments => 'Likes and comments on your moments';

  @override
  String get whenPeopleYouFollowPostMoments => 'When people you follow post moments';

  @override
  String get friendRequests => 'Friend Requests';

  @override
  String get whenSomeoneFollowsYou => 'When someone follows you';

  @override
  String get profileVisits => 'Profile Visits';

  @override
  String get whenSomeoneViewsYourProfileVIP => 'When someone views your profile (VIP)';

  @override
  String get marketing => 'Marketing';

  @override
  String get updatesAndPromotionalMessages => 'Updates and promotional messages';

  @override
  String get notificationPreferences => 'Notification Preferences';

  @override
  String get sound => 'Sound';

  @override
  String get playNotificationSounds => 'Play notification sounds';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrateOnNotifications => 'Vibrate on notifications';

  @override
  String get showPreview => 'Show Preview';

  @override
  String get showMessagePreviewInNotifications => 'Show message preview in notifications';

  @override
  String get mutedConversations => 'Muted Conversations';

  @override
  String get conversation => 'Conversation';

  @override
  String get unmute => 'Unmute';

  @override
  String get systemNotificationSettings => 'System Notification Settings';

  @override
  String get manageNotificationsInSystemSettings => 'Manage notifications in system settings';

  @override
  String get errorLoadingSettings => 'Error loading settings';

  @override
  String get unblockUser => 'Unblock User';

  @override
  String get unblock => 'Unblock';

  @override
  String get goBack => 'Go Back';

  @override
  String get messageSendTimeout => 'Message send timeout. Please check your connection.';

  @override
  String get failedToSendMessage => 'Failed to send message';

  @override
  String get dailyMessageLimitExceeded => 'Daily message limit exceeded. Upgrade to VIP for unlimited messages.';

  @override
  String get cannotSendMessageUserMayBeBlocked => 'Cannot send message. User may be blocked.';

  @override
  String get sessionExpired => 'Session expired. Please log in again.';

  @override
  String get sendThisSticker => 'Send this sticker?';

  @override
  String get chooseHowYouWantToDeleteThisMessage => 'Choose how you want to delete this message:';

  @override
  String get deleteForEveryone => 'Delete for everyone';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => 'Removes the message for both you and the recipient';

  @override
  String get deleteForMe => 'Delete for me';

  @override
  String get removesTheMessageOnlyFromYourChat => 'Removes the message only from your chat';

  @override
  String get copy => 'Copy';

  @override
  String get reply => 'Reply';

  @override
  String get forward => 'Forward';

  @override
  String get moreOptions => 'More Options';

  @override
  String get noUsersAvailableToForwardTo => 'No users available to forward to';

  @override
  String get searchMoments => 'Search moments...';

  @override
  String searchInChatWith(String name) {
    return 'Search in chat with $name';
  }

  @override
  String get typeAMessage => 'Type a message...';

  @override
  String get enterYourMessage => 'Enter your message';

  @override
  String get detectYourLocation => 'Detect your location';

  @override
  String get tapToUpdateLocation => 'Tap to update location';

  @override
  String get helpOthersFindYouNearby => 'Help others find you nearby';

  @override
  String get selectYourNativeLanguage => 'Select your native language';

  @override
  String get whichLanguageDoYouWantToLearn => 'Which language do you want to learn?';

  @override
  String get selectYourGender => 'Select your gender';

  @override
  String get addACaption => 'Add a caption...';

  @override
  String get typeSomething => 'Type something...';

  @override
  String get gallery => 'Gallery';

  @override
  String get video => 'Video';

  @override
  String get text => 'Text';

  @override
  String get provideMoreInformation => 'Provide more information...';

  @override
  String get searchByNameLanguageOrInterests => 'Search by name, language, or interests...';

  @override
  String get addTagAndPressEnter => 'Add tag and press enter';

  @override
  String replyTo(String name) {
    return 'Reply to $name...';
  }

  @override
  String get highlightName => 'Highlight name';

  @override
  String get searchCloseFriends => 'Search close friends...';

  @override
  String get askAQuestion => 'Ask a question...';

  @override
  String option(String number) {
    return 'Option $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return 'Why are you reporting this $type?';
  }

  @override
  String get additionalDetailsOptional => 'Additional details (optional)';

  @override
  String get warningThisActionIsPermanent => 'Warning: This action is permanent!';

  @override
  String get deletingYourAccountWillPermanentlyRemove => 'Deleting your account will permanently remove:\n\n• Your profile and all personal data\n• All your messages and conversations\n• All your moments and stories\n• Your VIP subscription (no refund)\n• All your connections and followers\n\nThis action cannot be undone.';

  @override
  String get clearAllNotifications => 'Clear all notifications?';

  @override
  String get clearAll => 'Clear All';

  @override
  String get notificationDebug => 'Notification Debug';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get clearAll2 => 'Clear all';

  @override
  String get emailAddress => 'Email address';

  @override
  String get username => 'Username';

  @override
  String get alreadyHaveAnAccount => 'Already have an account?';

  @override
  String get login2 => 'Login';

  @override
  String get selectYourNativeLanguage2 => 'Select your native language';

  @override
  String get whichLanguageDoYouWantToLearn2 => 'Which language do you want to learn?';

  @override
  String get selectYourGender2 => 'Select your gender';

  @override
  String get dateFormat => 'YYYY.MM.DD';

  @override
  String get detectYourLocation2 => 'Detect your location';

  @override
  String get tapToUpdateLocation2 => 'Tap to update location';

  @override
  String get helpOthersFindYouNearby2 => 'Help others find you nearby';

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get legalPrivacy2 => 'Legal & Privacy';

  @override
  String get termsOfUseEULA => 'Terms of Use (EULA)';

  @override
  String get viewOurTermsAndConditions => 'View our terms and conditions';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get howWeHandleYourData => 'How we handle your data';

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get receiveEmailNotificationsFromBananaTalk => 'Receive email notifications from BananaTalk';

  @override
  String get weeklySummary => 'Weekly Summary';

  @override
  String get activityRecapEverySunday => 'Activity recap every Sunday';

  @override
  String get newMessages => 'New Messages';

  @override
  String get whenYoureAwayFor24PlusHours => 'When you\'re away for 24+ hours';

  @override
  String get newFollowers => 'New Followers';

  @override
  String get whenSomeoneFollowsYou2 => 'When someone follows you';

  @override
  String get securityAlerts => 'Security Alerts';

  @override
  String get passwordLoginAlerts => 'Password & login alerts';

  @override
  String get unblockUser2 => 'Unblock User';

  @override
  String get blockedUsers2 => 'Blocked Users';

  @override
  String get finalWarning => '⚠️ Final Warning';

  @override
  String get deleteForever => 'Delete Forever';

  @override
  String get deleteAccount2 => 'Delete Account';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get yourPassword => 'Your password';

  @override
  String get typeDELETEToConfirm => 'Type DELETE to confirm';

  @override
  String get typeDELETEInCapitalLetters => 'Type DELETE in capital letters';

  @override
  String sent(String emoji) {
    return '$emoji sent!';
  }

  @override
  String get replySent => 'Reply sent!';

  @override
  String get deleteStory => 'Delete Story?';

  @override
  String get thisStoryWillBeRemovedPermanently => 'This story will be removed permanently.';

  @override
  String get noStories => 'No stories';

  @override
  String views(String count) {
    return '$count views';
  }

  @override
  String get reportStory => 'Report Story';

  @override
  String get reply2 => 'Reply...';

  @override
  String get failedToPickImage => 'Failed to pick image';

  @override
  String get failedToTakePhoto => 'Failed to take photo';

  @override
  String get failedToPickVideo => 'Failed to pick video';

  @override
  String get pleaseEnterSomeText => 'Please enter some text';

  @override
  String get pleaseSelectMedia => 'Please select media';

  @override
  String get storyPosted => 'Story posted!';

  @override
  String get textOnlyStoriesRequireAnImage => 'Text-only stories require an image';

  @override
  String get createStory => 'Create Story';

  @override
  String get change => 'Change';

  @override
  String get userIdNotFound => 'User ID not found. Please log in again.';

  @override
  String get pleaseSelectAPaymentMethod => 'Please select a payment method';

  @override
  String get startExploring => 'Start Exploring';

  @override
  String get close => 'Close';

  @override
  String get payment => 'Payment';

  @override
  String get upgradeToVIP => 'Upgrade to VIP';

  @override
  String get errorLoadingProducts => 'Error loading products';

  @override
  String get cancelVIPSubscription => 'Cancel VIP Subscription';

  @override
  String get keepVIP => 'Keep VIP';

  @override
  String get cancelSubscription => 'Cancel Subscription';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'VIP subscription cancelled successfully';

  @override
  String get vipStatus => 'VIP Status';

  @override
  String get noActiveVIPSubscription => 'No active VIP subscription';

  @override
  String get unlimitedMessages => 'Unlimited Messages';

  @override
  String get unlimitedProfileViews => 'Unlimited Profile Views';

  @override
  String get prioritySupport => 'Priority Support';

  @override
  String get advancedSearch => 'Advanced Search';

  @override
  String get profileBoost => 'Profile Boost';

  @override
  String get adFreeExperience => 'Ad-Free Experience';

  @override
  String get upgradeYourAccount => 'Upgrade Your Account';

  @override
  String get moreMessages => 'More Messages';

  @override
  String get moreProfileViews => 'More Profile Views';

  @override
  String get connectWithFriends => 'Connect with Friends';

  @override
  String get reviewStarted => 'Review started';

  @override
  String get reportResolved => 'Report resolved';

  @override
  String get reportDismissed => 'Report dismissed';

  @override
  String get selectAction => 'Select Action';

  @override
  String get noViolation => 'No Violation';

  @override
  String get contentRemoved => 'Content Removed';

  @override
  String get userWarned => 'User Warned';

  @override
  String get userSuspended => 'User Suspended';

  @override
  String get userBanned => 'User Banned';

  @override
  String get addNotesOptional => 'Add Notes (Optional)';

  @override
  String get enterModeratorNotes => 'Enter moderator notes...';

  @override
  String get skip => 'Skip';

  @override
  String get startReview => 'Start Review';

  @override
  String get resolve => 'Resolve';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get filterReports => 'Filter Reports';

  @override
  String get all => 'All';

  @override
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

  @override
  String get myReports2 => 'My Reports';

  @override
  String get blockUser => 'Block User';

  @override
  String get block => 'Block';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => 'Would you also like to block this user?';

  @override
  String get noThanks => 'No, thanks';

  @override
  String get yesBlockThem => 'Yes, block them';

  @override
  String get reportUser2 => 'Report User';

  @override
  String get submitReport => 'Submit Report';

  @override
  String get addAQuestionAndAtLeast2Options => 'Add a question and at least 2 options';

  @override
  String get addOption => 'Add option';

  @override
  String get anonymousVoting => 'Anonymous voting';

  @override
  String get create => 'Create';

  @override
  String get typeYourAnswer => 'Type your answer...';

  @override
  String get send2 => 'Send';

  @override
  String get yourPrompt => 'Your prompt...';

  @override
  String get add2 => 'Add';

  @override
  String get contentNotAvailable => 'Content not available';

  @override
  String get profileNotAvailable => 'Profile not available';

  @override
  String get noMomentsToShow => 'No moments to show';

  @override
  String get storiesNotAvailable => 'Stories not available';

  @override
  String get cantMessageThisUser => 'Can\'t message this user';

  @override
  String get pleaseSelectAReason => 'Please select a reason';

  @override
  String get reportSubmitted => 'Report submitted. Thank you for helping keep our community safe.';

  @override
  String get youHaveAlreadyReportedThisMoment => 'You have already reported this moment';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => 'Tell us more about why you are reporting this';

  @override
  String get errorSharing => 'Error sharing';

  @override
  String get deviceInfo => 'Device Info';

  @override
  String get recommended => 'Recommended';

  @override
  String get anyLanguage => 'Any Language';

  @override
  String get noLanguagesFound => 'No languages found';

  @override
  String get selectALanguage => 'Select a language';

  @override
  String get languagesAreStillLoading => 'Languages are still loading...';

  @override
  String get selectNativeLanguage => 'Select native language';
}
