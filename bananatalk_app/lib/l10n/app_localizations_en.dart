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
  String get more => 'more';

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
  String get overview => 'Overview';

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
  String get deleteComment => 'Delete Comment?';

  @override
  String get commentDeleted => 'Comment deleted';

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
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheSubtitle => 'Free up storage space';

  @override
  String get clearCacheDescription => 'This will clear all cached images, videos, and audio files. The app may load content slower temporarily as it re-downloads media.';

  @override
  String get clearCacheHint => 'Use this if images or audio aren\'t loading properly.';

  @override
  String get clearingCache => 'Clearing cache...';

  @override
  String get cacheCleared => 'Cache cleared successfully! Images will reload fresh.';

  @override
  String get clearCacheFailed => 'Failed to clear cache';

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
  String get chats => 'Chats';

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
  String get bloodType => 'Blood Type';

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
  String get notificationTypes => 'NOTIFICATION TYPES';

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
  String get sessionExpired => 'Session expired. Please login again.';

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
    return 'Sent!';
  }

  @override
  String get replySent => 'Reply sent!';

  @override
  String get deleteStory => 'Delete story?';

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
  String get subscriptionExpired => 'Subscription Expired';

  @override
  String get vipExpiredMessage => 'Your VIP subscription has expired. Renew now to continue enjoying unlimited features!';

  @override
  String get expiredOn => 'Expired on';

  @override
  String get renewVIP => 'Renew VIP';

  @override
  String get whatYoureMissing => 'What you\'re missing';

  @override
  String get manageInAppStore => 'Manage in App Store';

  @override
  String get becomeVIP => 'Become VIP';

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
  String get selectNativeLanguage => 'Please select your native language';

  @override
  String get subscriptionDetails => 'Subscription Details';

  @override
  String get activeFeatures => 'Active Features';

  @override
  String get legalInformation => 'Legal Information';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get manageSubscriptionInSettings => 'To cancel your subscription, go to Settings > [Your Name] > Subscriptions on your device.';

  @override
  String get contactSupportToCancel => 'To cancel your subscription, please contact our support team.';

  @override
  String get status => 'Status';

  @override
  String get active => 'active';

  @override
  String get plan => 'Plan';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get nextBillingDate => 'Next Billing Date';

  @override
  String get autoRenew => 'Auto Renew';

  @override
  String get pleaseLogInToContinue => 'Please log in to continue';

  @override
  String get purchaseCanceledOrFailed => 'Purchase was canceled or failed. Please try again.';

  @override
  String get maximumTagsAllowed => 'Maximum 5 tags allowed';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => 'Please remove images first to add a video';

  @override
  String get unsupportedFormat => 'Unsupported format';

  @override
  String get errorProcessingVideo => 'Error processing video';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'Please remove images first to record a video';

  @override
  String get locationAdded => 'Location added';

  @override
  String get failedToGetLocation => 'Failed to get location';

  @override
  String get notNow => 'Not Now';

  @override
  String get videoUploadFailed => 'Video Upload Failed';

  @override
  String get skipVideo => 'Skip Video';

  @override
  String get retryUpload => 'Retry Upload';

  @override
  String get momentCreatedSuccessfully => 'Moment created successfully';

  @override
  String get uploadingMomentInBackground => 'Uploading moment in background...';

  @override
  String get failedToQueueUpload => 'Failed to queue upload';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get mediaLinksAndDocs => 'Media, links, and docs';

  @override
  String get wallpaper => 'Wallpaper';

  @override
  String get userIdNotAvailable => 'User ID not available';

  @override
  String get cannotBlockYourself => 'Cannot block yourself';

  @override
  String get chatWallpaper => 'Chat Wallpaper';

  @override
  String get wallpaperSavedLocally => 'Wallpaper saved locally';

  @override
  String get messageCopied => 'Message copied';

  @override
  String get forwardFeatureComingSoon => 'Forward feature coming soon';

  @override
  String get momentUnsaved => 'Removed from saved';

  @override
  String get documentPickerComingSoon => 'Document picker coming soon';

  @override
  String get contactSharingComingSoon => 'Contact sharing coming soon';

  @override
  String get featureComingSoon => 'Feature coming soon';

  @override
  String get answerSent => 'Answer sent!';

  @override
  String get noImagesAvailable => 'No images available';

  @override
  String get mentionPickerComingSoon => 'Mention picker coming soon';

  @override
  String get musicPickerComingSoon => 'Music picker coming soon';

  @override
  String get repostFeatureComingSoon => 'Repost feature coming soon';

  @override
  String get addFriendsFromYourProfile => 'Add friends from your profile';

  @override
  String get quickReplyAdded => 'Quick reply added';

  @override
  String get quickReplyDeleted => 'Quick reply deleted';

  @override
  String get linkCopied => 'Link copied!';

  @override
  String get maximumOptionsAllowed => 'Maximum 10 options allowed';

  @override
  String get minimumOptionsRequired => 'Minimum 2 options required';

  @override
  String get pleaseEnterAQuestion => 'Please enter a question';

  @override
  String get pleaseAddAtLeast2Options => 'Please add at least 2 options';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => 'Please select the correct answer for quiz';

  @override
  String get correctionSent => 'Correction sent!';

  @override
  String get sort => 'Sort';

  @override
  String get savedMoments => 'Saved Moments';

  @override
  String get unsave => 'Unsave';

  @override
  String get playingAudio => 'Playing audio...';

  @override
  String get failedToGenerateQuiz => 'Failed to generate quiz';

  @override
  String get failedToAddComment => 'Failed to add comment';

  @override
  String get hello => 'Hello!';

  @override
  String get howAreYou => 'How are you?';

  @override
  String get cannotOpen => 'Cannot open';

  @override
  String get errorOpeningLink => 'Error opening link';

  @override
  String get saved => 'Saved';

  @override
  String get follow => 'Follow';

  @override
  String get unfollow => 'Unfollow';

  @override
  String get mute => 'Mute';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get lastSeen => 'Last seen';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(String count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgo(String count) {
    return '$count hours ago';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String get signInWithEmail => 'Sign in with Email';

  @override
  String get partners => 'Partners';

  @override
  String get nearby => 'Nearby';

  @override
  String get topics => 'Topics';

  @override
  String get waves => 'Waves';

  @override
  String get voiceRooms => 'Voice';

  @override
  String get filters => 'Filters';

  @override
  String get searchCommunity => 'Search by name, language, or interests...';

  @override
  String get bio => 'Bio';

  @override
  String get noBioYet => 'No bio available yet.';

  @override
  String get languages => 'Languages';

  @override
  String get native => 'Native';

  @override
  String get interests => 'Interests';

  @override
  String get noMomentsYet => 'No moments yet';

  @override
  String get unableToLoadMoments => 'Unable to load moments';

  @override
  String get map => 'Map';

  @override
  String get mapUnavailable => 'Map unavailable';

  @override
  String get location => 'Location';

  @override
  String get unknownLocation => 'Unknown location';

  @override
  String get noImagesAvailable2 => 'No images available';

  @override
  String get permissionsRequired => 'Permissions Required';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get refresh => 'Refresh';

  @override
  String get videoCall => 'Video';

  @override
  String get voiceCall => 'Call';

  @override
  String get message => 'Message';

  @override
  String get pleaseLoginToFollow => 'Please login to follow users';

  @override
  String get pleaseLoginToCall => 'Please login to make a call';

  @override
  String get cannotCallYourself => 'You cannot call yourself';

  @override
  String get failedToFollowUser => 'Failed to follow user';

  @override
  String get failedToUnfollowUser => 'Failed to unfollow user';

  @override
  String get areYouSureUnfollow => 'Are you sure you want to unfollow this user?';

  @override
  String get areYouSureUnblock => 'Are you sure you want to unblock this user?';

  @override
  String get youFollowed => 'You followed';

  @override
  String get youUnfollowed => 'You unfollowed';

  @override
  String get alreadyFollowing => 'You are already following';

  @override
  String get soon => 'Soon';

  @override
  String comingSoon(String feature) {
    return '$feature is coming soon!';
  }

  @override
  String get muteNotifications => 'Mute notifications';

  @override
  String get unmuteNotifications => 'Unmute notifications';

  @override
  String get operationCompleted => 'Operation completed';

  @override
  String get couldNotOpenMaps => 'Could not open maps';

  @override
  String hasntSharedMoments(Object name) {
    return '$name hasn\'t shared any moments';
  }

  @override
  String messageUser(String name) {
    return 'Message $name';
  }

  @override
  String notFollowingUser(String name) {
    return 'You were not following $name';
  }

  @override
  String youFollowedUser(String name) {
    return 'You followed $name';
  }

  @override
  String youUnfollowedUser(String name) {
    return 'You unfollowed $name';
  }

  @override
  String unfollowUser(String name) {
    return 'Unfollow $name';
  }

  @override
  String get typing => 'typing';

  @override
  String get connecting => 'Connecting...';

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get maxTagsAllowed => 'Maximum 5 tags allowed';

  @override
  String maxImagesAllowed(int count) {
    return 'Maximum $count images allowed';
  }

  @override
  String get pleaseRemoveImagesFirst => 'Please remove images first to add a video';

  @override
  String get exchange3MessagesBeforeCall => 'Exchange 3+ messages before calling';

  @override
  String mediaWithUser(String name) {
    return 'Media with $name';
  }

  @override
  String get errorLoadingMedia => 'Error loading media';

  @override
  String get savedMomentsTitle => 'Saved Moments';

  @override
  String get removeBookmark => 'Remove bookmark?';

  @override
  String get thisWillRemoveBookmark => 'This will remove the message from your bookmarks.';

  @override
  String get remove => 'Remove';

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get bookmarkedMessages => 'Bookmarked Messages';

  @override
  String get wallpaperSaved => 'Wallpaper saved locally';

  @override
  String get typeDeleteToConfirm => 'Type DELETE to confirm';

  @override
  String get storyArchive => 'Story Archive';

  @override
  String get newHighlight => 'New Highlight';

  @override
  String get addToHighlight => 'Add to Highlight';

  @override
  String get repost => 'Repost';

  @override
  String get repostFeatureSoon => 'Repost feature coming soon';

  @override
  String get closeFriends => 'Close Friends';

  @override
  String get addFriends => 'Add Friends';

  @override
  String get highlights => 'Highlights';

  @override
  String get createHighlight => 'Create Highlight';

  @override
  String get deleteHighlight => 'Delete Highlight';

  @override
  String get editHighlight => 'Edit Highlight';

  @override
  String get addMoreToStory => 'Add more to story';

  @override
  String get noViewersYet => 'No viewers yet';

  @override
  String get noReactionsYet => 'No reactions yet';

  @override
  String get leaveRoom => 'Leave Room';

  @override
  String get areYouSureLeaveRoom => 'Are you sure you want to leave this voice room?';

  @override
  String get stay => 'Stay';

  @override
  String get leave => 'Leave';

  @override
  String get enableGPS => 'Enable GPS';

  @override
  String wavedToUser(String name) {
    return 'Waved to $name!';
  }

  @override
  String get areYouSureFollow => 'Are you sure you want to follow';

  @override
  String get failedToLoadProfile => 'Failed to load profile';

  @override
  String get noFollowersYet => 'No followers yet';

  @override
  String get noFollowingYet => 'Not following anyone yet';

  @override
  String get searchUsers => 'Search users...';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get loadingFailed => 'Loading failed';

  @override
  String get copyLink => 'Copy link';

  @override
  String get shareStory => 'Share story';

  @override
  String get thisWillDeleteStory => 'This will permanently delete this story.';

  @override
  String get storyDeleted => 'Story deleted';

  @override
  String get addCaption => 'Add a caption...';

  @override
  String get yourStory => 'Your Story';

  @override
  String get sendMessage => 'Send message';

  @override
  String get replyToStory => 'Reply to story...';

  @override
  String get viewAllReplies => 'View all replies';

  @override
  String get preparingVideo => 'Preparing video...';

  @override
  String videoOptimized(String size, String savings) {
    return 'Video optimized: ${size}MB (saved $savings%)';
  }

  @override
  String get failedToProcessVideo => 'Failed to process video';

  @override
  String get optimizingForBestExperience => 'Optimizing for the best story experience';

  @override
  String get pleaseSelectImageOrVideo => 'Please select an image or video for your story';

  @override
  String get storyCreatedSuccessfully => 'Story created successfully!';

  @override
  String get uploadingStoryInBackground => 'Uploading story in background...';

  @override
  String get storyCreationFailed => 'Story Creation Failed';

  @override
  String get pleaseCheckConnection => 'Please check your connection and try again.';

  @override
  String get uploadFailed => 'Upload Failed';

  @override
  String get tryShorterVideo => 'Try using a shorter video or try again later.';

  @override
  String get shareMomentsThatDisappear => 'Share moments that disappear in 24 hours';

  @override
  String get photo => 'Photo';

  @override
  String get record => 'Record';

  @override
  String get addSticker => 'Add Sticker';

  @override
  String get poll => 'Poll';

  @override
  String get question => 'Question';

  @override
  String get mention => 'Mention';

  @override
  String get music => 'Music';

  @override
  String get hashtag => 'Hashtag';

  @override
  String get whoCanSeeThis => 'Who can see this?';

  @override
  String get everyone => 'Everyone';

  @override
  String get anyoneCanSeeStory => 'Anyone can see this story';

  @override
  String get friendsOnly => 'Friends Only';

  @override
  String get onlyFollowersCanSee => 'Only your followers can see';

  @override
  String get onlyCloseFriendsCanSee => 'Only your close friends can see';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get fontStyle => 'Font Style';

  @override
  String get normal => 'Normal';

  @override
  String get bold => 'Bold';

  @override
  String get italic => 'Italic';

  @override
  String get handwriting => 'Handwriting';

  @override
  String get addLocation => 'Add Location';

  @override
  String get enterLocationName => 'Enter location name';

  @override
  String get addLink => 'Add Link';

  @override
  String get buttonText => 'Button text';

  @override
  String get learnMore => 'Learn More';

  @override
  String get addHashtags => 'Add Hashtags';

  @override
  String get addHashtag => 'Add hashtag';

  @override
  String get sendAsMessage => 'Send as Message';

  @override
  String get shareExternally => 'Share Externally';

  @override
  String get checkOutStory => 'Check out this story on BananaTalk!';

  @override
  String viewsTab(String count) {
    return 'Views ($count)';
  }

  @override
  String reactionsTab(String count) {
    return 'Reactions ($count)';
  }

  @override
  String get processingVideo => 'Processing video...';

  @override
  String get link => 'Link';

  @override
  String unmuteUser(String name) {
    return 'Unmute $name?';
  }

  @override
  String get willReceiveNotifications => 'You will receive notifications for new messages.';

  @override
  String muteNotificationsFor(String name) {
    return 'Mute notifications for $name';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return 'Notifications unmuted for $name';
  }

  @override
  String notificationsMutedFor(String name) {
    return 'Notifications muted for $name';
  }

  @override
  String get failedToUpdateMuteSettings => 'Failed to update mute settings';

  @override
  String get oneHour => '1 hour';

  @override
  String get eightHours => '8 hours';

  @override
  String get oneWeek => '1 week';

  @override
  String get always => 'Always';

  @override
  String get failedToLoadBookmarks => 'Failed to load bookmarks';

  @override
  String get noBookmarkedMessages => 'No bookmarked messages';

  @override
  String get longPressToBookmark => 'Long press on a message to bookmark it';

  @override
  String get thisWillRemoveFromBookmarks => 'This will remove the message from your bookmarks.';

  @override
  String navigateToMessage(String name) {
    return 'Navigate to message in chat with $name';
  }

  @override
  String bookmarkedOn(String date) {
    return 'Bookmarked $date';
  }

  @override
  String get voiceMessage => 'Voice message';

  @override
  String get document => 'Document';

  @override
  String get attachment => 'Attachment';

  @override
  String get sendMeAMessage => 'Send me a message';

  @override
  String get shareWithFriends => 'Share with friends';

  @override
  String get shareAnywhere => 'Share anywhere';

  @override
  String get emailPreferences => 'Email Preferences';

  @override
  String get receiveEmailNotifications => 'Receive email notifications from BananaTalk';

  @override
  String get whenAwayFor24Hours => 'When you\'re away for 24+ hours';

  @override
  String get passwordAndLoginAlerts => 'Password & login alerts';

  @override
  String get failedToLoadPreferences => 'Failed to load preferences';

  @override
  String get failedToUpdateSetting => 'Failed to update setting';

  @override
  String get securityAlertsRecommended => 'We recommend keeping Security Alerts enabled to stay informed about important account activity.';

  @override
  String chatWallpaperFor(String name) {
    return 'Chat wallpaper for $name';
  }

  @override
  String get solidColors => 'Solid Colors';

  @override
  String get gradients => 'Gradients';

  @override
  String get customImage => 'Custom Image';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get preview => 'Preview';

  @override
  String get wallpaperUpdated => 'Wallpaper updated';

  @override
  String get category => 'Category';

  @override
  String get mood => 'Mood';

  @override
  String get sortBy => 'Sort By';

  @override
  String get timePeriod => 'Time Period';

  @override
  String get searchLanguages => 'Search languages...';

  @override
  String get selected => 'Selected';

  @override
  String get categories => 'Categories';

  @override
  String get moods => 'Moods';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String applyNFilters(int count) {
    return 'Apply $count Filters';
  }

  @override
  String get videoMustBeUnder1GB => 'Video must be under 1GB.';

  @override
  String get failedToRecordVideo => 'Failed to record video';

  @override
  String get errorSendingVideo => 'Error sending video';

  @override
  String get errorSendingVoiceMessage => 'Error sending voice message';

  @override
  String get errorSendingMedia => 'Error sending media';

  @override
  String get cameraPermissionRequired => 'Camera and microphone permissions are required to record videos.';

  @override
  String get locationPermissionRequired => 'Location permission is required to share your location.';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get tryAgainLater => 'Try again later';

  @override
  String get messageSent => 'Message sent';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get messageEdited => 'Message edited';

  @override
  String get edited => '(edited)';

  @override
  String get now => 'now';

  @override
  String weeksAgo(int count) {
    return '${count}w ago';
  }

  @override
  String viewRepliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'replies',
      one: 'reply',
    );
    return '── View $count $_temp0';
  }

  @override
  String get hideReplies => '── Hide replies';

  @override
  String get saveMoment => 'Save Moment';

  @override
  String get removeFromSaved => 'Remove from Saved';

  @override
  String get momentSaved => 'Saved';

  @override
  String get failedToSave => 'Failed to save';

  @override
  String get checkOutMoment => 'Check out this moment on BananaTalk!';

  @override
  String get failedToLoadMoments => 'Failed to load moments';

  @override
  String get noMomentsMatchFilters => 'No moments match your filters';

  @override
  String get beFirstToShareMoment => 'Be the first to share a moment!';

  @override
  String get tryDifferentSearch => 'Try a different search term';

  @override
  String get tryAdjustingFilters => 'Try adjusting your filters to find language exchange partners.';

  @override
  String get noSavedMoments => 'No saved moments';

  @override
  String get tapBookmarkToSave => 'Tap the bookmark icon on a moment to save it';

  @override
  String get failedToLoadVideo => 'Failed to load video';

  @override
  String get titleRequired => 'Title is required';

  @override
  String titleTooLong(int max) {
    return 'Title must be $max characters or less';
  }

  @override
  String get descriptionRequired => 'Description is required';

  @override
  String descriptionTooLong(int max) {
    return 'Description must be $max characters or less';
  }

  @override
  String get scheduledDateMustBeFuture => 'Scheduled date must be in the future';

  @override
  String get recent => 'Recent';

  @override
  String get popular => 'Popular';

  @override
  String get trending => 'Trending';

  @override
  String get mostRecent => 'Most Recent';

  @override
  String get mostPopular => 'Most Popular';

  @override
  String get allTime => 'All Time';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String replyingTo(String userName) {
    return 'Replying to $userName';
  }

  @override
  String get listView => 'List';

  @override
  String get quickMatch => 'Quick Match';

  @override
  String get onlineNow => 'Online Now';

  @override
  String speaksLanguage(String language) {
    return 'Speaks $language';
  }

  @override
  String learningLanguage(String language) {
    return 'Learning $language';
  }

  @override
  String get noPartnersFound => 'No partners found';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return 'No users found who speak $learning natively or want to learn $native.';
  }

  @override
  String get removeAllFilters => 'Remove all filters';

  @override
  String get browseAllUsers => 'Browse all users';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get loadingMore => 'Loading more...';

  @override
  String get findingMorePartners => 'Finding more language partners for you...';

  @override
  String get seenAllPartners => 'You\'ve seen all available partners. Check back later for more!';

  @override
  String get startOver => 'Start Over';

  @override
  String get changeFilters => 'Change Filters';

  @override
  String get findingPartners => 'Finding partners...';

  @override
  String get setLocationReminder => 'Set your location in your profile to see nearby users first.';

  @override
  String get updateLocationReminder => 'Update your location in Profile > Edit to get accurate nearby results.';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get browseMen => 'Browse men';

  @override
  String get browseWomen => 'Browse women';

  @override
  String get noMaleUsersFound => 'No male users found';

  @override
  String get noFemaleUsersFound => 'No female users found';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => 'New Users Only';

  @override
  String get showNewUsers => 'Show users who joined in the last 6 days';

  @override
  String get prioritizeNearby => 'Prioritize Nearby';

  @override
  String get showNearbyFirst => 'Show nearby users first in results';

  @override
  String get setLocationToEnable => 'Set your location to enable this feature';

  @override
  String get radius => 'Radius';

  @override
  String get findingYourLocation => 'Finding your location...';

  @override
  String get enableLocationForDistance => 'Enable Location for Distance';

  @override
  String get enableLocationDescription => 'Enable GPS to see exact distance to partners. You can still browse by city/country without GPS.';

  @override
  String get enableGps => 'Enable GPS';

  @override
  String get browseByCityCountry => 'Browse by City/Country';

  @override
  String get peopleNearby => 'People Nearby';

  @override
  String get noNearbyUsersFound => 'No nearby users found';

  @override
  String get tryExpandingSearch => 'Try expanding your search or check back later.';

  @override
  String get exploreByCity => 'Explore by City';

  @override
  String get exploreByCurrentCity => 'Browse users on an interactive map, see who\'s in your city, and discover language partners worldwide.';

  @override
  String get interactiveWorldMap => 'Interactive world map';

  @override
  String get searchByCityName => 'Search by city name';

  @override
  String get seeUserCountsPerCountry => 'See user counts per country';

  @override
  String get upgradeToVip => 'Upgrade to VIP';

  @override
  String get searchByCity => 'Search by city...';

  @override
  String usersWorldwide(String count) {
    return '$count users worldwide';
  }

  @override
  String get noUsersFound => 'No users found';

  @override
  String get tryDifferentCity => 'Try a different city or country';

  @override
  String usersCount(String count) {
    return '$count users';
  }

  @override
  String get searchCountry => 'Search country...';

  @override
  String get wave => 'Wave';

  @override
  String get newUser => 'NEW';

  @override
  String get warningPermanent => 'Warning: This action is permanent!';

  @override
  String get deleteAccountWarning => 'Deleting your account will permanently remove:\n\n• Your profile and all personal data\n• All your messages and conversations\n• All your moments and stories\n• Your VIP subscription (no refund)\n• All your connections and followers\n\nThis action cannot be undone.';

  @override
  String get requiredForEmailOnly => 'Required for email accounts only';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get typeDELETE => 'Type DELETE to confirm';

  @override
  String get mustTypeDELETE => 'You must type DELETE to confirm';

  @override
  String get deletingAccount => 'Deleting Account...';

  @override
  String get deleteMyAccountPermanently => 'Delete My Account Permanently';

  @override
  String get whatsYourNativeLanguage => 'What\'s your native language?';

  @override
  String get helpsMatchWithLearners => 'This helps us match you with learners';

  @override
  String get whatAreYouLearning => 'What are you learning?';

  @override
  String get connectWithNativeSpeakers => 'We\'ll connect you with native speakers';

  @override
  String get selectLearningLanguage => 'Please select the language you\'re learning';

  @override
  String get selectCurrentLevel => 'Please select your current level';

  @override
  String get beginner => 'Beginner';

  @override
  String get elementary => 'Elementary';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get upperIntermediate => 'Upper Intermediate';

  @override
  String get advanced => 'Advanced';

  @override
  String get proficient => 'Proficient';

  @override
  String get showingPartnersByDistance => 'Showing partners sorted by distance';

  @override
  String get enableLocationForResults => 'Enable location for distance-based results';

  @override
  String get enable => 'Enable';

  @override
  String get locationNotSet => 'Location not set';

  @override
  String get tellUsAboutYourself => 'Tell us about yourself';

  @override
  String get justACoupleQuickThings => 'Just a couple of quick things';

  @override
  String get gender => 'Gender';

  @override
  String get birthDate => 'Birth Date';

  @override
  String get selectYourBirthDate => 'Select your birth date';

  @override
  String get continueButton => 'Continue';

  @override
  String get pleaseSelectGender => 'Please select your gender';

  @override
  String get pleaseSelectBirthDate => 'Please select your birth date';

  @override
  String get mustBe18 => 'You must be at least 18 years old';

  @override
  String get invalidDate => 'Invalid date';

  @override
  String get almostDone => 'Almost done!';

  @override
  String get addPhotoLocationForMatches => 'Add a photo and location to get more matches';

  @override
  String get addProfilePhoto => 'Add Profile Photo';

  @override
  String get optionalUpTo6Photos => 'Optional — up to 6 photos';

  @override
  String get requiredUpTo6Photos => 'Required — up to 6 photos';

  @override
  String get profilePhotoRequired => 'Please add at least one profile photo';

  @override
  String get locationOptional => 'Location is optional — you can add it later';

  @override
  String get maximum6Photos => 'Maximum 6 photos';

  @override
  String get tapToDetectLocation => 'Tap to detect location';

  @override
  String get optionalHelpsNearbyPartners => 'Optional — helps find nearby partners';

  @override
  String get startLearning => 'Start Learning!';

  @override
  String get photoLocationOptional => 'Photo & location are optional — you can add them later';

  @override
  String get pleaseAcceptTerms => 'Please accept the Terms of Service';

  @override
  String get iAgreeToThe => 'I agree to the ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get tapToSelectLanguage => 'Tap to select a language';

  @override
  String yourLevelIn(String language) {
    return 'Your level in $language (optional)';
  }

  @override
  String get yourCurrentLevel => 'Your current level';

  @override
  String get nativeCannotBeSameAsLearning => 'Native language cannot be the same as learning language';

  @override
  String get learningCannotBeSameAsNative => 'Learning language cannot be the same as native language';

  @override
  String stepOf(String current, String total) {
    return 'Step $current of $total';
  }

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get registerLink => 'Register';

  @override
  String get pleaseEnterBothEmailAndPassword => 'Please enter both email and password';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get loginSuccessful => 'Login Successful!';

  @override
  String get stepOneOfTwo => 'Step 1 of 2';

  @override
  String get createYourAccount => 'Create Your Account';

  @override
  String get basicInfoToGetStarted => 'Basic info to get you started';

  @override
  String get emailVerifiedLabel => 'Email (Verified)';

  @override
  String get nameLabel => 'Name';

  @override
  String get yourDisplayName => 'Your display name';

  @override
  String get atLeast8Characters => 'At least 8 characters';

  @override
  String get confirmPasswordHint => 'Confirm password';

  @override
  String get nextButton => 'Next';

  @override
  String get pleaseEnterYourName => 'Please enter your name';

  @override
  String get pleaseEnterAPassword => 'Please enter a password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get otherGender => 'Other';

  @override
  String get continueWithGoogleAccount => 'Continue with your Google account\nfor a seamless experience';

  @override
  String get signingYouIn => 'Signing you in...';

  @override
  String get backToSignInMethods => 'Back to sign-in methods';

  @override
  String get securedByGoogle => 'Secured by Google';

  @override
  String get dataProtectedEncryption => 'Your data is protected with industry-standard encryption';

  @override
  String get welcomeCompleteProfile => 'Welcome! Please complete your profile';

  @override
  String welcomeBackName(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String get continueWithAppleId => 'Continue with your Apple ID\nfor a secure experience';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get securedByApple => 'Secured by Apple';

  @override
  String get privacyProtectedApple => 'Your privacy is protected with Apple Sign-In';

  @override
  String get createAccount => 'Create Account';

  @override
  String get enterEmailToGetStarted => 'Enter your email to get started';

  @override
  String get continueText => 'Continue';

  @override
  String get pleaseEnterEmailAddress => 'Please enter your email address';

  @override
  String get verificationCodeSent => 'Verification code sent to your email!';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get enterEmailForResetCode => 'Enter your email address and we\'ll send you a code to reset your password';

  @override
  String get sendResetCode => 'Send Reset Code';

  @override
  String get resetCodeSent => 'Reset code sent to your email!';

  @override
  String get rememberYourPassword => 'Remember your password?';

  @override
  String get verifyCode => 'Verify Code';

  @override
  String get enterResetCode => 'Enter Reset Code';

  @override
  String get weSentCodeTo => 'We sent a 6-digit code to';

  @override
  String get pleaseEnterAll6Digits => 'Please enter all 6 digits';

  @override
  String get codeVerifiedCreatePassword => 'Code verified! Create your new password';

  @override
  String get verify => 'Verify';

  @override
  String get didntReceiveCode => 'Didn\'t receive the code?';

  @override
  String get resend => 'Resend';

  @override
  String resendWithTimer(String timer) {
    return 'Resend (${timer}s)';
  }

  @override
  String get resetCodeResent => 'Reset code resent!';

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get verifyYourEmail => 'Verify Your Email';

  @override
  String get emailVerifiedSuccessfully => 'Email verified successfully!';

  @override
  String get verificationCodeResent => 'Verification code resent!';

  @override
  String get createNewPassword => 'Create New Password';

  @override
  String get enterNewPasswordBelow => 'Enter your new password below';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get pleaseFillAllFields => 'Please fill in all fields';

  @override
  String get passwordResetSuccessful => 'Password reset successful! Please login with your new password';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get profileVisibility => 'Profile Visibility';

  @override
  String get showCountryRegion => 'Show Country/Region';

  @override
  String get showCountryRegionDesc => 'Display your country on your profile';

  @override
  String get showCity => 'Show City';

  @override
  String get showCityDesc => 'Display your city on your profile';

  @override
  String get showAge => 'Show Age';

  @override
  String get showAgeDesc => 'Display your age on your profile';

  @override
  String get showZodiacSign => 'Show Zodiac Sign';

  @override
  String get showZodiacSignDesc => 'Display your zodiac sign on your profile';

  @override
  String get onlineStatusSection => 'Online Status';

  @override
  String get showOnlineStatus => 'Show Online Status';

  @override
  String get showOnlineStatusDesc => 'Let others see when you are online';

  @override
  String get otherSettings => 'Other Settings';

  @override
  String get showGiftingLevel => 'Show Gifting Level';

  @override
  String get showGiftingLevelDesc => 'Display your gifting level badge';

  @override
  String get birthdayNotifications => 'Birthday Notifications';

  @override
  String get birthdayNotificationsDesc => 'Receive notifications on your birthday';

  @override
  String get personalizedAds => 'Personalized Ads';

  @override
  String get personalizedAdsDesc => 'Allow personalized advertisements';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get privacySettingsSaved => 'Privacy settings saved';

  @override
  String get locationSection => 'Location';

  @override
  String get updateLocation => 'Update Location';

  @override
  String get updateLocationDesc => 'Refresh your current location';

  @override
  String get currentLocation => 'Current location';

  @override
  String get locationNotAvailable => 'Location not available';

  @override
  String get locationUpdated => 'Location updated successfully';

  @override
  String get locationPermissionDenied => 'Location permission denied. Please enable it in settings.';

  @override
  String get locationServiceDisabled => 'Location services are disabled. Please enable them.';

  @override
  String get updatingLocation => 'Updating location...';

  @override
  String get locationCouldNotBeUpdated => 'Location could not be updated';

  @override
  String get incomingAudioCall => 'Incoming Audio Call';

  @override
  String get incomingVideoCall => 'Incoming Video Call';

  @override
  String get outgoingCall => 'Calling...';

  @override
  String get callRinging => 'Ringing...';

  @override
  String get callConnecting => 'Connecting...';

  @override
  String get callConnected => 'Connected';

  @override
  String get callReconnecting => 'Reconnecting...';

  @override
  String get callEnded => 'Call Ended';

  @override
  String get callFailed => 'Call Failed';

  @override
  String get callMissed => 'Missed Call';

  @override
  String get callDeclined => 'Call Declined';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => 'Accept';

  @override
  String get declineCall => 'Decline';

  @override
  String get endCall => 'End';

  @override
  String get muteCall => 'Mute';

  @override
  String get unmuteCall => 'Unmute';

  @override
  String get speakerOn => 'Speaker';

  @override
  String get speakerOff => 'Earpiece';

  @override
  String get videoOn => 'Video On';

  @override
  String get videoOff => 'Video Off';

  @override
  String get switchCamera => 'Switch Camera';

  @override
  String get callPermissionDenied => 'Microphone permission is required for calls';

  @override
  String get cameraPermissionDenied => 'Camera permission is required for video calls';

  @override
  String get callConnectionFailed => 'Could not connect. Please try again.';

  @override
  String get userBusy => 'User is busy';

  @override
  String get userOffline => 'User is offline';

  @override
  String get callHistory => 'Call History';

  @override
  String get noCallHistory => 'No call history';

  @override
  String get missedCalls => 'Missed Calls';

  @override
  String get allCalls => 'All Calls';

  @override
  String get callBack => 'Call Back';

  @override
  String callAt(String time) {
    return 'Call at $time';
  }

  @override
  String get audioCall => 'Audio Call';

  @override
  String get voiceRoom => 'Voice Room';

  @override
  String get noVoiceRooms => 'No voice rooms active';

  @override
  String get createVoiceRoom => 'Create Voice Room';

  @override
  String get joinRoom => 'Join Room';

  @override
  String get leaveRoomConfirm => 'Leave Room?';

  @override
  String get leaveRoomMessage => 'Are you sure you want to leave this room?';

  @override
  String get roomTitle => 'Room Title';

  @override
  String get roomTitleHint => 'Enter room title';

  @override
  String get roomTopic => 'Topic';

  @override
  String get roomLanguage => 'Language';

  @override
  String get roomHost => 'Host';

  @override
  String roomParticipants(int count) {
    return '$count participants';
  }

  @override
  String roomMaxParticipants(int count) {
    return 'Max $count participants';
  }

  @override
  String get selectTopic => 'Select Topic';

  @override
  String get raiseHand => 'Raise Hand';

  @override
  String get lowerHand => 'Lower Hand';

  @override
  String get handRaisedNotification => 'Hand raised! The host will see your request.';

  @override
  String get handLoweredNotification => 'Hand lowered';

  @override
  String get muteParticipant => 'Mute Participant';

  @override
  String get kickParticipant => 'Remove from Room';

  @override
  String get promoteToCoHost => 'Make Co-Host';

  @override
  String get endRoomConfirm => 'End Room?';

  @override
  String get endRoomMessage => 'This will end the room for all participants.';

  @override
  String get roomEnded => 'Room ended by host';

  @override
  String get youWereRemoved => 'You were removed from the room';

  @override
  String get roomIsFull => 'Room is full';

  @override
  String get roomChat => 'Room Chat';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get voiceRoomsDescription => 'Join live conversations and practice speaking';

  @override
  String liveRoomsCount(int count) {
    return '$count Live';
  }

  @override
  String get noActiveRooms => 'No active rooms';

  @override
  String get noActiveRoomsDescription => 'Be the first to start a voice room and practice speaking with others!';

  @override
  String get startRoom => 'Start a Room';

  @override
  String get createRoom => 'Create Room';

  @override
  String get roomCreated => 'Room created successfully!';

  @override
  String get failedToCreateRoom => 'Failed to create room';

  @override
  String get errorLoadingRooms => 'Error loading rooms';

  @override
  String get pleaseEnterRoomTitle => 'Please enter a room title';

  @override
  String get startLiveConversation => 'Start a live conversation';

  @override
  String get maxParticipants => 'Max Participants';

  @override
  String nPeople(int count) {
    return '$count people';
  }

  @override
  String hostedBy(String name) {
    return 'Hosted by $name';
  }

  @override
  String get liveLabel => 'LIVE';

  @override
  String get joinLabel => 'Join';

  @override
  String get fullLabel => 'Full';

  @override
  String get justStarted => 'Just started';

  @override
  String get allLanguages => 'All Languages';

  @override
  String get allTopics => 'All Topics';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get competeWithLearners => 'Compete with other learners!';

  @override
  String get xpRankings => 'XP Rankings';

  @override
  String get streaks => 'Streaks';

  @override
  String get friends => 'Friends';

  @override
  String get myRanks => 'My Ranks';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get longestStreak => 'Longest Streak';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yourRank => 'Your Rank';

  @override
  String outOf(int total) {
    return 'out of $total';
  }

  @override
  String topPercent(String percent) {
    return 'Top $percent%';
  }

  @override
  String get xpRank => 'XP Rank';

  @override
  String get streakRank => 'Streak Rank';

  @override
  String get days => 'days';

  @override
  String get learningStats => 'Learning Stats';

  @override
  String get totalXp => 'Total XP';

  @override
  String get lessonsCompleted => 'Lessons Completed';

  @override
  String get rankings => 'Rankings';

  @override
  String get yourPosition => 'Your Position';

  @override
  String get keepLearning => 'Keep learning to climb!';

  @override
  String get noRankingsYet => 'No rankings yet';

  @override
  String get startLearningToAppear => 'Start learning to appear on the leaderboard!';

  @override
  String get noFriendsYet => 'No friends yet';

  @override
  String get addFriendsToCompete => 'Add friends to compete with them!';

  @override
  String get failedToLoadLeaderboard => 'Failed to load leaderboard';

  @override
  String get you => 'You';

  @override
  String get findPartners => 'Find Partners';

  @override
  String get discoverLanguagePartners => 'Discover language partners';

  @override
  String get byLanguage => 'By Language';

  @override
  String get match => 'match';

  @override
  String get matchScore => 'Match Score';

  @override
  String get noMatchesFound => 'No matches found';

  @override
  String get noUsersOnline => 'No users online';

  @override
  String get checkBackLater => 'Check back later';

  @override
  String get selectLanguagePrompt => 'Select a language';

  @override
  String get findPartnersByLanguage => 'Find partners who speak or learn this language';

  @override
  String noPartnersForLanguage(String language) {
    return 'No partners for $language';
  }

  @override
  String get tryAnotherLanguage => 'Try selecting another language';

  @override
  String get failedToLoadMatches => 'Failed to load matches';

  @override
  String get dataAndStorage => 'Data & Storage';

  @override
  String get manageStorageAndDownloads => 'Manage storage and downloads';

  @override
  String get storageUsage => 'Storage Usage';

  @override
  String get totalCacheSize => 'Total Cache Size';

  @override
  String get imageCache => 'Image Cache';

  @override
  String get voiceMessagesCache => 'Voice Messages';

  @override
  String get videoCache => 'Video Cache';

  @override
  String get otherCache => 'Other Cache';

  @override
  String get autoDownloadMedia => 'Auto-Download Media';

  @override
  String get currentNetwork => 'Current Network';

  @override
  String get images => 'Images';

  @override
  String get videos => 'Videos';

  @override
  String get voiceMessagesShort => 'Voice Messages';

  @override
  String get documentsLabel => 'Documents';

  @override
  String get wifiOnly => 'WiFi Only';

  @override
  String get never => 'Never';

  @override
  String get clearAllCache => 'Clear All Cache';

  @override
  String get allCache => 'All Cache';

  @override
  String get clearAllCacheConfirmation => 'This will clear all cached images, voice messages, videos, and other files. The app may load content slower temporarily.';

  @override
  String clearCacheConfirmationFor(String category) {
    return 'Clear $category?';
  }

  @override
  String storageToFree(String size) {
    return '$size will be freed';
  }

  @override
  String get calculating => 'Calculating...';

  @override
  String get noDataToShow => 'No data to show';

  @override
  String get profileCompletion => 'Profile Completion';

  @override
  String get justGettingStarted => 'Just getting started';

  @override
  String get lookingGood => 'Looking good!';

  @override
  String get almostThere => 'Almost there!';

  @override
  String addMissingFields(String fields, Object field) {
    return 'Add: $fields';
  }

  @override
  String get profilePicture => 'Profile Picture';

  @override
  String get nativeSpeaker => 'Native Speaker';

  @override
  String peopleInterestedInTopic(Object count) {
    return 'People interested in this topic';
  }

  @override
  String get beFirstToAddTopic => 'Be the first to add this topic to your interests!';

  @override
  String get recentMoments => 'Recent Moments';

  @override
  String get seeAll => 'See All';

  @override
  String get study => 'Study';

  @override
  String get followerMoments => 'Follower Moments';

  @override
  String get whenPeopleYouFollowPost => 'When people you follow post new moments';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get whenYouGetNotifications => 'When you get notifications, they\'ll show up here';

  @override
  String get failedToLoadNotifications => 'Failed to load notifications';

  @override
  String get clearAllNotificationsConfirm => 'Are you sure you want to clear all notifications? This cannot be undone.';

  @override
  String get tapToChange => 'Tap to change';

  @override
  String get noPictureSet => 'No picture set';

  @override
  String get nameAndGender => 'Name & Gender';

  @override
  String get languageLevel => 'Language Level';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get mbti => 'MBTI';

  @override
  String get topicsOfInterest => 'Topics of Interest';

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelElementary => 'Elementary';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelUpperIntermediate => 'Upper Intermediate';

  @override
  String get levelAdvanced => 'Advanced';

  @override
  String get levelProficient => 'Proficient';

  @override
  String get selectYourLevel => 'Select Your Level';

  @override
  String howWellDoYouSpeak(String language) {
    return 'How well do you speak $language?';
  }

  @override
  String get theLanguage => 'the language';

  @override
  String languageLevelSetTo(String level) {
    return 'Language level set to $level';
  }

  @override
  String get failedToUpdate => 'Failed to update';

  @override
  String get editHometown => 'Edit Hometown';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get detecting => 'Detecting...';

  @override
  String get getCurrentLocation => 'Get Current Location';

  @override
  String get country => 'Country';

  @override
  String get city => 'City';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get noLocationDetectedYet => 'No location detected yet.';

  @override
  String get detected => 'Detected';

  @override
  String get savedHometown => 'Saved hometown';

  @override
  String get locationServicesDisabled => 'Location services are disabled. Please enable them.';

  @override
  String get locationPermissionPermanentlyDenied => 'Location permissions are permanently denied.';

  @override
  String get unknown => 'Unknown';

  @override
  String get editBio => 'Edit Bio';

  @override
  String get bioUpdatedSuccessfully => 'Bio updated successfully';

  @override
  String get tellOthersAboutYourself => 'Tell others about yourself...';

  @override
  String charactersCount(int count) {
    return '$count/500 characters';
  }

  @override
  String get selectYourMbti => 'Select Your MBTI';

  @override
  String get myBloodType => 'My Blood Type';

  @override
  String get pleaseSelectABloodType => 'Please select a blood type';

  @override
  String get nativeLanguageRequired => 'Native Language (Required)';

  @override
  String get languageToLearnRequired => 'Language to Learn (Required)';

  @override
  String get nativeLanguageCannotBeSame => 'Native language cannot be the same as the language you\'re learning';

  @override
  String get learningLanguageCannotBeSame => 'Learning language cannot be the same as your native language';

  @override
  String get pleaseSelectALanguage => 'Please select a language';

  @override
  String get editInterests => 'Edit Interests';

  @override
  String maxTopicsAllowed(int count) {
    return 'Maximum $count topics allowed';
  }

  @override
  String get topicsUpdatedSuccessfully => 'Topics updated successfully!';

  @override
  String get failedToUpdateTopics => 'Failed to update topics';

  @override
  String selectedCount(int count, int max) {
    return '$count/$max selected';
  }

  @override
  String get profilePictures => 'Profile Pictures';

  @override
  String get addImages => 'Add Images';

  @override
  String get selectUpToImages => 'Select up to 5 images';

  @override
  String get takeAPhoto => 'Take a Photo';

  @override
  String get removeImage => 'Remove Image';

  @override
  String get removeImageConfirm => 'Are you sure you want to remove this image?';

  @override
  String get removeAll => 'Remove All';

  @override
  String get removeAllSelectedImages => 'Remove All Selected Images';

  @override
  String get removeAllSelectedImagesConfirm => 'Are you sure you want to remove all selected images?';

  @override
  String get yourProfilePictureWillBeKept => 'Your existing profile picture will be kept';

  @override
  String get removeAllImages => 'Remove All Images';

  @override
  String get removeAllImagesConfirm => 'Are you sure you want to remove all profile pictures?';

  @override
  String get currentImages => 'Current Images';

  @override
  String get newImages => 'New Images';

  @override
  String get addMoreImages => 'Add More Images';

  @override
  String uploadImages(int count) {
    return 'Upload $count Image(s)';
  }

  @override
  String get imageRemovedSuccessfully => 'Image removed successfully';

  @override
  String get imagesUploadedSuccessfully => 'Images uploaded successfully';

  @override
  String get selectedImagesCleared => 'Selected images cleared';

  @override
  String get extraImagesRemovedSuccessfully => 'Extra images removed successfully';

  @override
  String get mustKeepAtLeastOneProfilePicture => 'You must keep at least one profile picture';

  @override
  String get noProfilePicturesToRemove => 'No profile pictures to remove';

  @override
  String get authenticationTokenNotFound => 'Authentication token not found';

  @override
  String get saveChangesQuestion => 'Save Changes?';

  @override
  String youHaveUnuploadedImages(int count) {
    return 'You have $count image(s) selected but not uploaded. Do you want to upload them now?';
  }

  @override
  String get discard => 'Discard';

  @override
  String get upload => 'Upload';

  @override
  String maxImagesInfo(int max, int current) {
    return 'You can upload up to $max images. Currently: $current/$max\nMax 5 images per upload.';
  }

  @override
  String canOnlyAddMoreImages(int count, int max) {
    return 'You can only add $count more image(s). Maximum is $max images total.';
  }

  @override
  String get maxImagesPerUpload => 'You can upload maximum 5 images at once. Only first 5 will be added.';

  @override
  String canOnlyHaveMaxImages(int max) {
    return 'You can only have up to $max images';
  }

  @override
  String get imageSizeExceedsLimit => 'Image size exceeds 10MB limit';

  @override
  String get unsupportedImageFormat => 'Unsupported image format';

  @override
  String get pleaseSelectAtLeastOneImage => 'Please select at least one image to upload';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get languageToLearn => 'Language to Learn';

  @override
  String get hometown => 'Hometown';

  @override
  String get characters => 'characters';

  @override
  String get failedToLoadLanguages => 'Failed to load languages';

  @override
  String get studyHub => 'Study Hub';

  @override
  String get dailyLearningJourney => 'Your daily learning journey';

  @override
  String get learnTab => 'Learn';

  @override
  String get aiTools => 'AI Tools';

  @override
  String get streak => 'Streak';

  @override
  String get lessons => 'Lessons';

  @override
  String get words => 'Words';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get review => 'Review';

  @override
  String wordsDue(int count) {
    return '$count words due';
  }

  @override
  String get addWords => 'Add Words';

  @override
  String get buildVocabulary => 'Build vocabulary';

  @override
  String get practiceWithAI => 'Practice with AI';

  @override
  String get aiPracticeDescription => 'Chat, quiz, grammar & pronunciation';

  @override
  String get dailyChallenges => 'Daily Challenges';

  @override
  String get allChallengesCompleted => 'All challenges completed!';

  @override
  String get continueLearning => 'Continue Learning';

  @override
  String get structuredLearningPath => 'Structured learning path';

  @override
  String get vocabulary => 'Vocabulary';

  @override
  String get yourWordCollection => 'Your word collection';

  @override
  String get achievements => 'Achievements';

  @override
  String get badgesAndMilestones => 'Badges and milestones';

  @override
  String get failedToLoadLearningData => 'Failed to load learning data';

  @override
  String get startYourJourney => 'Start your journey!';

  @override
  String get startJourneyDescription => 'Complete lessons, build vocabulary, and\ntrack your progress';

  @override
  String levelN(int level) {
    return 'Level $level';
  }

  @override
  String xpEarned(int xp) {
    return '$xp XP earned';
  }

  @override
  String nextLevel(int level) {
    return 'Next: Level $level';
  }

  @override
  String xpToGo(int xp) {
    return '$xp XP to go';
  }

  @override
  String get aiConversationPartner => 'AI Conversation Partner';

  @override
  String get practiceWithAITutor => 'Practice speaking with your AI tutor';

  @override
  String get startConversation => 'Start Conversation';

  @override
  String get aiFeatures => 'AI Features';

  @override
  String get aiLessons => 'AI Lessons';

  @override
  String get learnWithAI => 'Learn with AI';

  @override
  String get grammar => 'Grammar';

  @override
  String get checkWriting => 'Check writing';

  @override
  String get pronunciation => 'Pronunciation';

  @override
  String get improveSpeaking => 'Improve speaking';

  @override
  String get translation => 'Translation';

  @override
  String get smartTranslate => 'Smart translate';

  @override
  String get aiQuizzes => 'AI Quizzes';

  @override
  String get testKnowledge => 'Test knowledge';

  @override
  String get lessonBuilder => 'Lesson Builder';

  @override
  String get customLessons => 'Custom lessons';

  @override
  String get yourAIProgress => 'Your AI Progress';

  @override
  String get quizzes => 'Quizzes';

  @override
  String get avgScore => 'Avg Score';

  @override
  String get focusAreas => 'Focus Areas';

  @override
  String accuracyPercent(String accuracy) {
    return '$accuracy% accuracy';
  }

  @override
  String get practice => 'Practice';

  @override
  String get browse => 'Browse';

  @override
  String get noRecommendedLessons => 'No recommended lessons available';

  @override
  String get noLessonsFound => 'No lessons found';

  @override
  String get createCustomLessonDescription => 'Create your own custom lesson with AI';

  @override
  String get createLessonWithAI => 'Create Lesson with AI';

  @override
  String get allLevels => 'All Levels';

  @override
  String get levelA1 => 'A1 Beginner';

  @override
  String get levelA2 => 'A2 Elementary';

  @override
  String get levelB1 => 'B1 Intermediate';

  @override
  String get levelB2 => 'B2 Upper-Int';

  @override
  String get levelC1 => 'C1 Advanced';

  @override
  String get levelC2 => 'C2 Proficient';

  @override
  String get failedToLoadLessons => 'Failed to load lessons';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get editMessage => 'Edit Message';

  @override
  String get enterMessage => 'Enter message...';

  @override
  String get deleteMessageTitle => 'Delete Message';

  @override
  String get actionCannotBeUndone => 'This action cannot be undone.';

  @override
  String get onlyRemovesFromDevice => 'Only removes from your device';

  @override
  String get availableWithinOneHour => 'Only available within 1 hour';

  @override
  String get available => 'Available';

  @override
  String get forwardMessage => 'Forward Message';

  @override
  String get selectUsersToForward => 'Select users to forward to:';

  @override
  String forwardCount(int count) {
    return 'Forward ($count)';
  }

  @override
  String get pinnedMessage => 'Pinned Message';

  @override
  String get photoMedia => 'Photo';

  @override
  String get videoMedia => 'Video';

  @override
  String get voiceMessageMedia => 'Voice message';

  @override
  String get documentMedia => 'Document';

  @override
  String get locationMedia => 'Location';

  @override
  String get stickerMedia => 'Sticker';

  @override
  String get smileys => 'Smileys';

  @override
  String get emotions => 'Emotions';

  @override
  String get handGestures => 'Hand Gestures';

  @override
  String get hearts => 'Hearts';

  @override
  String get tapToSayHi => 'Tap to say hi!';

  @override
  String get sendWaveToStart => 'Send a wave to start chatting';

  @override
  String get documentMustBeUnder50MB => 'Document must be under 50MB.';

  @override
  String get editWithin15Minutes => 'Messages can only be edited within 15 minutes';

  @override
  String messageForwardedTo(int count) {
    return 'Message forwarded to $count user(s)';
  }

  @override
  String get failedToLoadUsers => 'Failed to load users';

  @override
  String get voice => 'Voice';

  @override
  String get searchGifs => 'Search GIFs...';

  @override
  String get trendingGifs => 'Trending';

  @override
  String get poweredByGiphy => 'Powered by GIPHY';

  @override
  String get gif => 'GIF';

  @override
  String get noGifsFound => 'No GIFs found';

  @override
  String get failedToLoadGifs => 'Failed to load GIFs';

  @override
  String get gifSent => 'GIF';

  @override
  String get filterCommunities => 'Filter';

  @override
  String get reset => 'Reset';

  @override
  String get findYourPerfect => 'Find Your Perfect';

  @override
  String get languagePartner => 'Language Partner';

  @override
  String get learningLanguageLabel => 'Learning Language';

  @override
  String get ageRange => 'Age Range';

  @override
  String get genderPreference => 'Gender Preference';

  @override
  String get any => 'Any';

  @override
  String get showNewUsersSubtitle => 'Show users who joined in the last 6 days';

  @override
  String get autoDetectLocation => 'Auto-detect my location';

  @override
  String get selectCountry => 'Select Country';

  @override
  String get anyCountry => 'Any Country';

  @override
  String get loadingLanguages => 'Loading languages...';

  @override
  String minAge(int age) {
    return 'Min: $age';
  }

  @override
  String maxAge(int age) {
    return 'Max: $age';
  }

  @override
  String get captionRequired => 'Caption is required';

  @override
  String captionTooLong(int maxLength) {
    return 'Caption must be $maxLength characters or less';
  }

  @override
  String get maximumImagesReached => 'Maximum Images Reached';

  @override
  String maximumImagesReachedDescription(int maxImages) {
    return 'You can only upload up to $maxImages images per moment.';
  }

  @override
  String maximumImagesAddedPartial(int maxImages, int added) {
    return 'Maximum $maxImages images allowed. Only $added images added.';
  }

  @override
  String get locationAccessRestricted => 'Location Access Restricted';

  @override
  String get locationPermissionNeeded => 'Location Permission Needed';

  @override
  String get addToYourMoment => 'Add to your moment';

  @override
  String get categoryLabel => 'Category';

  @override
  String get languageLabel => 'Language';

  @override
  String get scheduleOptional => 'Schedule (optional)';

  @override
  String get scheduleForLater => 'Schedule for later';

  @override
  String get addMore => 'Add More';

  @override
  String get howAreYouFeeling => 'How are you feeling?';

  @override
  String get pleaseWaitOptimizingVideo => 'Please wait while we optimize your video';

  @override
  String unsupportedVideoFormat(String formats) {
    return 'Unsupported format. Use: $formats';
  }

  @override
  String get chooseBackground => 'Choose a background';

  @override
  String likedByXPeople(int count) {
    return 'Liked by $count people';
  }

  @override
  String xComments(int count) {
    return '$count comments';
  }

  @override
  String get oneComment => '1 comment';

  @override
  String get addAComment => 'Add a comment...';

  @override
  String viewXReplies(int count) {
    return 'View $count replies';
  }

  @override
  String seenByX(int count) {
    return 'Seen by $count';
  }

  @override
  String xHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String xMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String get repliedToYourStory => 'Replied to your story';

  @override
  String mentionedYouInComment(String name) {
    return '$name mentioned you in a comment';
  }

  @override
  String repliedToYourComment(String name) {
    return '$name replied to your comment';
  }

  @override
  String reactedToYourComment(String name) {
    return '$name reacted to your comment';
  }

  @override
  String get addReaction => 'Add reaction';

  @override
  String get attachImage => 'Attach image';

  @override
  String get pickGif => 'Pick a GIF';

  @override
  String get textStory => 'Text';

  @override
  String get typeYourStory => 'Type your story...';

  @override
  String get selectBackground => 'Select background';

  @override
  String get highlightsTitle => 'Highlights';

  @override
  String get highlightTitle => 'Highlight Title';

  @override
  String get createNewHighlight => 'Create New';

  @override
  String get selectStories => 'Select Stories';

  @override
  String get selectCover => 'Select Cover';

  @override
  String get addText => 'Add Text';

  @override
  String get fontStyleLabel => 'Font Style';

  @override
  String get textColorLabel => 'Text Color';

  @override
  String get dragToDelete => 'Drag here to delete';

  @override
  String get noBlockedUsers => 'No blocked users';

  @override
  String get usersYouBlockWillAppearHere => 'Users you block will appear here';

  @override
  String unblockConfirm(String name) {
    return 'Are you sure you want to unblock $name?';
  }

  @override
  String reasonLabel(String reason) {
    return 'Reason: $reason';
  }

  @override
  String blockedAgo(String time) {
    return 'Blocked $time';
  }

  @override
  String errorLoadingBlockedUsers(String error) {
    return 'Error loading blocked users: $error';
  }

  @override
  String get logoutConfirmMessage => 'Are you sure you want to logout from BanaTalk?';

  @override
  String get loggingOut => 'Logging out...';

  @override
  String get quietHours => 'Quiet Hours';

  @override
  String get quietHoursEnable => 'Enable Quiet Hours';

  @override
  String get quietHoursSubtitle => 'Pause non-urgent notifications during a time window';

  @override
  String get quietHoursStart => 'Start time';

  @override
  String get quietHoursEnd => 'End time';

  @override
  String get quietHoursAllowUrgent => 'Allow urgent notifications';

  @override
  String get quietHoursAllowUrgentSubtitle => 'Calls and messages from VIP partners can still come through';

  @override
  String get silencedByQuietHours => 'Silenced by Quiet Hours';

  @override
  String get silencedByCap => 'Silenced by daily limit';
}
