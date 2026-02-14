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
  String get tryAgain => 'Try again';

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
  String get selectNativeLanguage => 'Select native language';

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
  String get momentUnsaved => 'Moment unsaved';

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
  String get exchange3MessagesBeforeCall => 'You need to exchange at least 3 messages before you can call this user';

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
  String get deleteHighlight => 'Delete Highlight?';

  @override
  String get editHighlight => 'Edit Highlight';

  @override
  String get addMoreToStory => 'Add more to story';

  @override
  String get noViewersYet => 'No viewers yet';

  @override
  String get noReactionsYet => 'No reactions yet';

  @override
  String get leaveRoom => 'Leave Room?';

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
  String get chooseFromGallery => 'Choose from gallery';

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
  String get tryAgainLater => 'Please try again later';

  @override
  String get messageSent => 'Message sent';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get messageEdited => 'Message edited';
}
