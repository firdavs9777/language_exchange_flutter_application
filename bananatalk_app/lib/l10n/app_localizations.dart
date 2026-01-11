import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('ko'),
    Locale('ru'),
    Locale('zh')
  ];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'BananaTalk'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Apple'**
  String get signInWithApple;

  /// No description provided for @signInWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Facebook'**
  String get signInWithFacebook;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @moments.
  ///
  /// In en, this message translates to:
  /// **'Moments'**
  String get moments;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @autoTranslate.
  ///
  /// In en, this message translates to:
  /// **'Auto Translate'**
  String get autoTranslate;

  /// No description provided for @autoTranslateMessages.
  ///
  /// In en, this message translates to:
  /// **'Auto Translate Messages'**
  String get autoTranslateMessages;

  /// No description provided for @autoTranslateMoments.
  ///
  /// In en, this message translates to:
  /// **'Auto Translate Moments'**
  String get autoTranslateMoments;

  /// No description provided for @autoTranslateComments.
  ///
  /// In en, this message translates to:
  /// **'Auto Translate Comments'**
  String get autoTranslateComments;

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// No description provided for @translated.
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get translated;

  /// No description provided for @showOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show Original'**
  String get showOriginal;

  /// No description provided for @showTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show Translation'**
  String get showTranslation;

  /// No description provided for @translating.
  ///
  /// In en, this message translates to:
  /// **'Translating...'**
  String get translating;

  /// No description provided for @translationFailed.
  ///
  /// In en, this message translates to:
  /// **'Translation failed'**
  String get translationFailed;

  /// No description provided for @noTranslationAvailable.
  ///
  /// In en, this message translates to:
  /// **'No translation available'**
  String get noTranslationAvailable;

  /// No description provided for @translatedFrom.
  ///
  /// In en, this message translates to:
  /// **'Translated from {language}'**
  String translatedFrom(String language);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @visitors.
  ///
  /// In en, this message translates to:
  /// **'Visitors'**
  String get visitors;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @deviceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Device Language'**
  String get deviceLanguage;

  /// No description provided for @yourDeviceIsSetTo.
  ///
  /// In en, this message translates to:
  /// **'Your device is set to: {flag} {name}'**
  String yourDeviceIsSetTo(String flag, String name);

  /// No description provided for @youCanOverride.
  ///
  /// In en, this message translates to:
  /// **'You can override the device language below.'**
  String get youCanOverride;

  /// No description provided for @languageChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {name}'**
  String languageChangedTo(String name);

  /// No description provided for @errorChangingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Error changing language'**
  String get errorChangingLanguage;

  /// No description provided for @autoTranslateSettings.
  ///
  /// In en, this message translates to:
  /// **'Auto-Translate Settings'**
  String get autoTranslateSettings;

  /// No description provided for @automaticallyTranslateIncomingMessages.
  ///
  /// In en, this message translates to:
  /// **'Automatically translate incoming messages'**
  String get automaticallyTranslateIncomingMessages;

  /// No description provided for @automaticallyTranslateMomentsInFeed.
  ///
  /// In en, this message translates to:
  /// **'Automatically translate moments in feed'**
  String get automaticallyTranslateMomentsInFeed;

  /// No description provided for @automaticallyTranslateComments.
  ///
  /// In en, this message translates to:
  /// **'Automatically translate comments'**
  String get automaticallyTranslateComments;

  /// No description provided for @translationServiceBeingConfigured.
  ///
  /// In en, this message translates to:
  /// **'Translation service is being configured. Please try again later.'**
  String get translationServiceBeingConfigured;

  /// No description provided for @translationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Translation unavailable'**
  String get translationUnavailable;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'show less'**
  String get showLess;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'show more'**
  String get showMore;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @beTheFirstToComment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment.'**
  String get beTheFirstToComment;

  /// No description provided for @writeAComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeAComment;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reportMoment.
  ///
  /// In en, this message translates to:
  /// **'Report Moment'**
  String get reportMoment;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUser;

  /// No description provided for @deleteMoment.
  ///
  /// In en, this message translates to:
  /// **'Delete Moment?'**
  String get deleteMoment;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @momentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Moment deleted'**
  String get momentDeleted;

  /// No description provided for @editFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Edit feature coming soon'**
  String get editFeatureComingSoon;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @cannotReportYourOwnComment.
  ///
  /// In en, this message translates to:
  /// **'Cannot report your own comment'**
  String get cannotReportYourOwnComment;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @editYourProfileInformation.
  ///
  /// In en, this message translates to:
  /// **'Edit your profile information'**
  String get editYourProfileInformation;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// No description provided for @manageBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage blocked users'**
  String get manageBlockedUsers;

  /// No description provided for @manageNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage notification settings'**
  String get manageNotificationSettings;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @controlYourPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Control your privacy'**
  String get controlYourPrivacy;

  /// No description provided for @changeAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change app language'**
  String get changeAppLanguage;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeAndDisplaySettings.
  ///
  /// In en, this message translates to:
  /// **'Theme and display settings'**
  String get themeAndDisplaySettings;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReports;

  /// No description provided for @viewYourSubmittedReports.
  ///
  /// In en, this message translates to:
  /// **'View your submitted reports'**
  String get viewYourSubmittedReports;

  /// No description provided for @reportsManagement.
  ///
  /// In en, this message translates to:
  /// **'Reports Management'**
  String get reportsManagement;

  /// No description provided for @manageAllReportsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Manage all reports (Admin)'**
  String get manageAllReportsAdmin;

  /// No description provided for @legalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Legal & Privacy'**
  String get legalPrivacy;

  /// No description provided for @termsPrivacySubscriptionInfo.
  ///
  /// In en, this message translates to:
  /// **'Terms, Privacy & Subscription info'**
  String get termsPrivacySubscriptionInfo;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @getHelpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Get help and support'**
  String get getHelpAndSupport;

  /// No description provided for @aboutBanaTalk.
  ///
  /// In en, this message translates to:
  /// **'About BanaTalk'**
  String get aboutBanaTalk;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @permanentlyDeleteYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get permanentlyDeleteYourAccount;

  /// No description provided for @loggedOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get loggedOutSuccessfully;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @giftsLikes.
  ///
  /// In en, this message translates to:
  /// **'Gifts/Likes'**
  String get giftsLikes;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @banaTalk.
  ///
  /// In en, this message translates to:
  /// **'BanaTalk'**
  String get banaTalk;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String yearsOld(String age);

  /// No description provided for @searchConversations.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get searchConversations;

  /// No description provided for @visitorTrackingNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Visitor tracking feature is not available yet. Backend update required.'**
  String get visitorTrackingNotAvailable;

  /// No description provided for @chatList.
  ///
  /// In en, this message translates to:
  /// **'ChatList'**
  String get chatList;

  /// No description provided for @languageExchange.
  ///
  /// In en, this message translates to:
  /// **'Language Exchange'**
  String get languageExchange;

  /// No description provided for @nativeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Native Language'**
  String get nativeLanguage;

  /// No description provided for @learning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learning;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get aboutMe;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @createMoment.
  ///
  /// In en, this message translates to:
  /// **'Create Moment'**
  String get createMoment;

  /// No description provided for @addATitle.
  ///
  /// In en, this message translates to:
  /// **'Add a title...'**
  String get addATitle;

  /// No description provided for @whatsOnYourMind.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get whatsOnYourMind;

  /// No description provided for @addTags.
  ///
  /// In en, this message translates to:
  /// **'Add Tags'**
  String get addTags;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @enterTag.
  ///
  /// In en, this message translates to:
  /// **'Enter tag'**
  String get enterTag;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @commentAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Comment added successfully'**
  String get commentAddedSuccessfully;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @turnAllNotificationsOnOrOff.
  ///
  /// In en, this message translates to:
  /// **'Turn all notifications on or off'**
  String get turnAllNotificationsOnOrOff;

  /// No description provided for @notificationTypes.
  ///
  /// In en, this message translates to:
  /// **'Notification Types'**
  String get notificationTypes;

  /// No description provided for @chatMessages.
  ///
  /// In en, this message translates to:
  /// **'Chat Messages'**
  String get chatMessages;

  /// No description provided for @getNotifiedWhenYouReceiveMessages.
  ///
  /// In en, this message translates to:
  /// **'Get notified when you receive messages'**
  String get getNotifiedWhenYouReceiveMessages;

  /// No description provided for @likesAndCommentsOnYourMoments.
  ///
  /// In en, this message translates to:
  /// **'Likes and comments on your moments'**
  String get likesAndCommentsOnYourMoments;

  /// No description provided for @whenPeopleYouFollowPostMoments.
  ///
  /// In en, this message translates to:
  /// **'When people you follow post moments'**
  String get whenPeopleYouFollowPostMoments;

  /// No description provided for @friendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend Requests'**
  String get friendRequests;

  /// No description provided for @whenSomeoneFollowsYou.
  ///
  /// In en, this message translates to:
  /// **'When someone follows you'**
  String get whenSomeoneFollowsYou;

  /// No description provided for @profileVisits.
  ///
  /// In en, this message translates to:
  /// **'Profile Visits'**
  String get profileVisits;

  /// No description provided for @whenSomeoneViewsYourProfileVIP.
  ///
  /// In en, this message translates to:
  /// **'When someone views your profile (VIP)'**
  String get whenSomeoneViewsYourProfileVIP;

  /// No description provided for @marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketing;

  /// No description provided for @updatesAndPromotionalMessages.
  ///
  /// In en, this message translates to:
  /// **'Updates and promotional messages'**
  String get updatesAndPromotionalMessages;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @playNotificationSounds.
  ///
  /// In en, this message translates to:
  /// **'Play notification sounds'**
  String get playNotificationSounds;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @vibrateOnNotifications.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on notifications'**
  String get vibrateOnNotifications;

  /// No description provided for @showPreview.
  ///
  /// In en, this message translates to:
  /// **'Show Preview'**
  String get showPreview;

  /// No description provided for @showMessagePreviewInNotifications.
  ///
  /// In en, this message translates to:
  /// **'Show message preview in notifications'**
  String get showMessagePreviewInNotifications;

  /// No description provided for @mutedConversations.
  ///
  /// In en, this message translates to:
  /// **'Muted Conversations'**
  String get mutedConversations;

  /// No description provided for @conversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get conversation;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @systemNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'System Notification Settings'**
  String get systemNotificationSettings;

  /// No description provided for @manageNotificationsInSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage notifications in system settings'**
  String get manageNotificationsInSystemSettings;

  /// No description provided for @errorLoadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error loading settings'**
  String get errorLoadingSettings;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get unblockUser;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @messageSendTimeout.
  ///
  /// In en, this message translates to:
  /// **'Message send timeout. Please check your connection.'**
  String get messageSendTimeout;

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get failedToSendMessage;

  /// No description provided for @dailyMessageLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Daily message limit exceeded. Upgrade to VIP for unlimited messages.'**
  String get dailyMessageLimitExceeded;

  /// No description provided for @cannotSendMessageUserMayBeBlocked.
  ///
  /// In en, this message translates to:
  /// **'Cannot send message. User may be blocked.'**
  String get cannotSendMessageUserMayBeBlocked;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @sendThisSticker.
  ///
  /// In en, this message translates to:
  /// **'Send this sticker?'**
  String get sendThisSticker;

  /// No description provided for @chooseHowYouWantToDeleteThisMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to delete this message:'**
  String get chooseHowYouWantToDeleteThisMessage;

  /// No description provided for @deleteForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get deleteForEveryone;

  /// No description provided for @removesTheMessageForBothYouAndTheRecipient.
  ///
  /// In en, this message translates to:
  /// **'Removes the message for both you and the recipient'**
  String get removesTheMessageForBothYouAndTheRecipient;

  /// No description provided for @deleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get deleteForMe;

  /// No description provided for @removesTheMessageOnlyFromYourChat.
  ///
  /// In en, this message translates to:
  /// **'Removes the message only from your chat'**
  String get removesTheMessageOnlyFromYourChat;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More Options'**
  String get moreOptions;

  /// No description provided for @noUsersAvailableToForwardTo.
  ///
  /// In en, this message translates to:
  /// **'No users available to forward to'**
  String get noUsersAvailableToForwardTo;

  /// No description provided for @searchMoments.
  ///
  /// In en, this message translates to:
  /// **'Search moments...'**
  String get searchMoments;

  /// No description provided for @searchInChatWith.
  ///
  /// In en, this message translates to:
  /// **'Search in chat with {name}'**
  String searchInChatWith(String name);

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @enterYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your message'**
  String get enterYourMessage;

  /// No description provided for @detectYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Detect your location'**
  String get detectYourLocation;

  /// No description provided for @tapToUpdateLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap to update location'**
  String get tapToUpdateLocation;

  /// No description provided for @helpOthersFindYouNearby.
  ///
  /// In en, this message translates to:
  /// **'Help others find you nearby'**
  String get helpOthersFindYouNearby;

  /// No description provided for @selectYourNativeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your native language'**
  String get selectYourNativeLanguage;

  /// No description provided for @whichLanguageDoYouWantToLearn.
  ///
  /// In en, this message translates to:
  /// **'Which language do you want to learn?'**
  String get whichLanguageDoYouWantToLearn;

  /// No description provided for @selectYourGender.
  ///
  /// In en, this message translates to:
  /// **'Select your gender'**
  String get selectYourGender;

  /// No description provided for @addACaption.
  ///
  /// In en, this message translates to:
  /// **'Add a caption...'**
  String get addACaption;

  /// No description provided for @typeSomething.
  ///
  /// In en, this message translates to:
  /// **'Type something...'**
  String get typeSomething;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @provideMoreInformation.
  ///
  /// In en, this message translates to:
  /// **'Provide more information...'**
  String get provideMoreInformation;

  /// No description provided for @searchByNameLanguageOrInterests.
  ///
  /// In en, this message translates to:
  /// **'Search by name, language, or interests...'**
  String get searchByNameLanguageOrInterests;

  /// No description provided for @addTagAndPressEnter.
  ///
  /// In en, this message translates to:
  /// **'Add tag and press enter'**
  String get addTagAndPressEnter;

  /// No description provided for @replyTo.
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}...'**
  String replyTo(String name);

  /// No description provided for @highlightName.
  ///
  /// In en, this message translates to:
  /// **'Highlight name'**
  String get highlightName;

  /// No description provided for @searchCloseFriends.
  ///
  /// In en, this message translates to:
  /// **'Search close friends...'**
  String get searchCloseFriends;

  /// No description provided for @askAQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a question...'**
  String get askAQuestion;

  /// No description provided for @option.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String option(String number);

  /// No description provided for @whyAreYouReportingThis.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this {type}?'**
  String whyAreYouReportingThis(String type);

  /// No description provided for @additionalDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get additionalDetailsOptional;

  /// No description provided for @warningThisActionIsPermanent.
  ///
  /// In en, this message translates to:
  /// **'Warning: This action is permanent!'**
  String get warningThisActionIsPermanent;

  /// No description provided for @deletingYourAccountWillPermanentlyRemove.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account will permanently remove:\n\n• Your profile and all personal data\n• All your messages and conversations\n• All your moments and stories\n• Your VIP subscription (no refund)\n• All your connections and followers\n\nThis action cannot be undone.'**
  String get deletingYourAccountWillPermanentlyRemove;

  /// No description provided for @clearAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications?'**
  String get clearAllNotifications;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @notificationDebug.
  ///
  /// In en, this message translates to:
  /// **'Notification Debug'**
  String get notificationDebug;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @clearAll2.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll2;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAnAccount;

  /// No description provided for @login2.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login2;

  /// No description provided for @selectYourNativeLanguage2.
  ///
  /// In en, this message translates to:
  /// **'Select your native language'**
  String get selectYourNativeLanguage2;

  /// No description provided for @whichLanguageDoYouWantToLearn2.
  ///
  /// In en, this message translates to:
  /// **'Which language do you want to learn?'**
  String get whichLanguageDoYouWantToLearn2;

  /// No description provided for @selectYourGender2.
  ///
  /// In en, this message translates to:
  /// **'Select your gender'**
  String get selectYourGender2;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'YYYY.MM.DD'**
  String get dateFormat;

  /// No description provided for @detectYourLocation2.
  ///
  /// In en, this message translates to:
  /// **'Detect your location'**
  String get detectYourLocation2;

  /// No description provided for @tapToUpdateLocation2.
  ///
  /// In en, this message translates to:
  /// **'Tap to update location'**
  String get tapToUpdateLocation2;

  /// No description provided for @helpOthersFindYouNearby2.
  ///
  /// In en, this message translates to:
  /// **'Help others find you nearby'**
  String get helpOthersFindYouNearby2;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @legalPrivacy2.
  ///
  /// In en, this message translates to:
  /// **'Legal & Privacy'**
  String get legalPrivacy2;

  /// No description provided for @termsOfUseEULA.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use (EULA)'**
  String get termsOfUseEULA;

  /// No description provided for @viewOurTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'View our terms and conditions'**
  String get viewOurTermsAndConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @howWeHandleYourData.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get howWeHandleYourData;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @receiveEmailNotificationsFromBananaTalk.
  ///
  /// In en, this message translates to:
  /// **'Receive email notifications from BananaTalk'**
  String get receiveEmailNotificationsFromBananaTalk;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get weeklySummary;

  /// No description provided for @activityRecapEverySunday.
  ///
  /// In en, this message translates to:
  /// **'Activity recap every Sunday'**
  String get activityRecapEverySunday;

  /// No description provided for @newMessages.
  ///
  /// In en, this message translates to:
  /// **'New Messages'**
  String get newMessages;

  /// No description provided for @whenYoureAwayFor24PlusHours.
  ///
  /// In en, this message translates to:
  /// **'When you\'re away for 24+ hours'**
  String get whenYoureAwayFor24PlusHours;

  /// No description provided for @newFollowers.
  ///
  /// In en, this message translates to:
  /// **'New Followers'**
  String get newFollowers;

  /// No description provided for @whenSomeoneFollowsYou2.
  ///
  /// In en, this message translates to:
  /// **'When someone follows you'**
  String get whenSomeoneFollowsYou2;

  /// No description provided for @securityAlerts.
  ///
  /// In en, this message translates to:
  /// **'Security Alerts'**
  String get securityAlerts;

  /// No description provided for @passwordLoginAlerts.
  ///
  /// In en, this message translates to:
  /// **'Password & login alerts'**
  String get passwordLoginAlerts;

  /// No description provided for @unblockUser2.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get unblockUser2;

  /// No description provided for @blockedUsers2.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers2;

  /// No description provided for @finalWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Final Warning'**
  String get finalWarning;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deleteForever;

  /// No description provided for @deleteAccount2.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount2;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @yourPassword.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get yourPassword;

  /// No description provided for @typeDELETEToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get typeDELETEToConfirm;

  /// No description provided for @typeDELETEInCapitalLetters.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE in capital letters'**
  String get typeDELETEInCapitalLetters;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'{emoji} sent!'**
  String sent(String emoji);

  /// No description provided for @replySent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent!'**
  String get replySent;

  /// No description provided for @deleteStory.
  ///
  /// In en, this message translates to:
  /// **'Delete Story?'**
  String get deleteStory;

  /// No description provided for @thisStoryWillBeRemovedPermanently.
  ///
  /// In en, this message translates to:
  /// **'This story will be removed permanently.'**
  String get thisStoryWillBeRemovedPermanently;

  /// No description provided for @noStories.
  ///
  /// In en, this message translates to:
  /// **'No stories'**
  String get noStories;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'{count} views'**
  String views(String count);

  /// No description provided for @reportStory.
  ///
  /// In en, this message translates to:
  /// **'Report Story'**
  String get reportStory;

  /// No description provided for @reply2.
  ///
  /// In en, this message translates to:
  /// **'Reply...'**
  String get reply2;

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get failedToPickImage;

  /// No description provided for @failedToTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to take photo'**
  String get failedToTakePhoto;

  /// No description provided for @failedToPickVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick video'**
  String get failedToPickVideo;

  /// No description provided for @pleaseEnterSomeText.
  ///
  /// In en, this message translates to:
  /// **'Please enter some text'**
  String get pleaseEnterSomeText;

  /// No description provided for @pleaseSelectMedia.
  ///
  /// In en, this message translates to:
  /// **'Please select media'**
  String get pleaseSelectMedia;

  /// No description provided for @storyPosted.
  ///
  /// In en, this message translates to:
  /// **'Story posted!'**
  String get storyPosted;

  /// No description provided for @textOnlyStoriesRequireAnImage.
  ///
  /// In en, this message translates to:
  /// **'Text-only stories require an image'**
  String get textOnlyStoriesRequireAnImage;

  /// No description provided for @createStory.
  ///
  /// In en, this message translates to:
  /// **'Create Story'**
  String get createStory;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @userIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'User ID not found. Please log in again.'**
  String get userIdNotFound;

  /// No description provided for @pleaseSelectAPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get pleaseSelectAPaymentMethod;

  /// No description provided for @startExploring.
  ///
  /// In en, this message translates to:
  /// **'Start Exploring'**
  String get startExploring;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @upgradeToVIP.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to VIP'**
  String get upgradeToVIP;

  /// No description provided for @errorLoadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Error loading products'**
  String get errorLoadingProducts;

  /// No description provided for @cancelVIPSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel VIP Subscription'**
  String get cancelVIPSubscription;

  /// No description provided for @keepVIP.
  ///
  /// In en, this message translates to:
  /// **'Keep VIP'**
  String get keepVIP;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get cancelSubscription;

  /// No description provided for @vipSubscriptionCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'VIP subscription cancelled successfully'**
  String get vipSubscriptionCancelledSuccessfully;

  /// No description provided for @vipStatus.
  ///
  /// In en, this message translates to:
  /// **'VIP Status'**
  String get vipStatus;

  /// No description provided for @noActiveVIPSubscription.
  ///
  /// In en, this message translates to:
  /// **'No active VIP subscription'**
  String get noActiveVIPSubscription;

  /// No description provided for @unlimitedMessages.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Messages'**
  String get unlimitedMessages;

  /// No description provided for @unlimitedProfileViews.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Profile Views'**
  String get unlimitedProfileViews;

  /// No description provided for @prioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority Support'**
  String get prioritySupport;

  /// No description provided for @advancedSearch.
  ///
  /// In en, this message translates to:
  /// **'Advanced Search'**
  String get advancedSearch;

  /// No description provided for @profileBoost.
  ///
  /// In en, this message translates to:
  /// **'Profile Boost'**
  String get profileBoost;

  /// No description provided for @adFreeExperience.
  ///
  /// In en, this message translates to:
  /// **'Ad-Free Experience'**
  String get adFreeExperience;

  /// No description provided for @upgradeYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Your Account'**
  String get upgradeYourAccount;

  /// No description provided for @moreMessages.
  ///
  /// In en, this message translates to:
  /// **'More Messages'**
  String get moreMessages;

  /// No description provided for @moreProfileViews.
  ///
  /// In en, this message translates to:
  /// **'More Profile Views'**
  String get moreProfileViews;

  /// No description provided for @connectWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Connect with Friends'**
  String get connectWithFriends;

  /// No description provided for @reviewStarted.
  ///
  /// In en, this message translates to:
  /// **'Review started'**
  String get reviewStarted;

  /// No description provided for @reportResolved.
  ///
  /// In en, this message translates to:
  /// **'Report resolved'**
  String get reportResolved;

  /// No description provided for @reportDismissed.
  ///
  /// In en, this message translates to:
  /// **'Report dismissed'**
  String get reportDismissed;

  /// No description provided for @selectAction.
  ///
  /// In en, this message translates to:
  /// **'Select Action'**
  String get selectAction;

  /// No description provided for @noViolation.
  ///
  /// In en, this message translates to:
  /// **'No Violation'**
  String get noViolation;

  /// No description provided for @contentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Content Removed'**
  String get contentRemoved;

  /// No description provided for @userWarned.
  ///
  /// In en, this message translates to:
  /// **'User Warned'**
  String get userWarned;

  /// No description provided for @userSuspended.
  ///
  /// In en, this message translates to:
  /// **'User Suspended'**
  String get userSuspended;

  /// No description provided for @userBanned.
  ///
  /// In en, this message translates to:
  /// **'User Banned'**
  String get userBanned;

  /// No description provided for @addNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Add Notes (Optional)'**
  String get addNotesOptional;

  /// No description provided for @enterModeratorNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter moderator notes...'**
  String get enterModeratorNotes;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @startReview.
  ///
  /// In en, this message translates to:
  /// **'Start Review'**
  String get startReview;

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolve;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @filterReports.
  ///
  /// In en, this message translates to:
  /// **'Filter Reports'**
  String get filterReports;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @myReports2.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReports2;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @wouldYouAlsoLikeToBlockThisUser.
  ///
  /// In en, this message translates to:
  /// **'Would you also like to block this user?'**
  String get wouldYouAlsoLikeToBlockThisUser;

  /// No description provided for @noThanks.
  ///
  /// In en, this message translates to:
  /// **'No, thanks'**
  String get noThanks;

  /// No description provided for @yesBlockThem.
  ///
  /// In en, this message translates to:
  /// **'Yes, block them'**
  String get yesBlockThem;

  /// No description provided for @reportUser2.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUser2;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @addAQuestionAndAtLeast2Options.
  ///
  /// In en, this message translates to:
  /// **'Add a question and at least 2 options'**
  String get addAQuestionAndAtLeast2Options;

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get addOption;

  /// No description provided for @anonymousVoting.
  ///
  /// In en, this message translates to:
  /// **'Anonymous voting'**
  String get anonymousVoting;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @typeYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Type your answer...'**
  String get typeYourAnswer;

  /// No description provided for @send2.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send2;

  /// No description provided for @yourPrompt.
  ///
  /// In en, this message translates to:
  /// **'Your prompt...'**
  String get yourPrompt;

  /// No description provided for @add2.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add2;

  /// No description provided for @contentNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Content not available'**
  String get contentNotAvailable;

  /// No description provided for @profileNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Profile not available'**
  String get profileNotAvailable;

  /// No description provided for @noMomentsToShow.
  ///
  /// In en, this message translates to:
  /// **'No moments to show'**
  String get noMomentsToShow;

  /// No description provided for @storiesNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Stories not available'**
  String get storiesNotAvailable;

  /// No description provided for @cantMessageThisUser.
  ///
  /// In en, this message translates to:
  /// **'Can\'t message this user'**
  String get cantMessageThisUser;

  /// No description provided for @pleaseSelectAReason.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason'**
  String get pleaseSelectAReason;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you for helping keep our community safe.'**
  String get reportSubmitted;

  /// No description provided for @youHaveAlreadyReportedThisMoment.
  ///
  /// In en, this message translates to:
  /// **'You have already reported this moment'**
  String get youHaveAlreadyReportedThisMoment;

  /// No description provided for @tellUsMoreAboutWhyYouAreReportingThis.
  ///
  /// In en, this message translates to:
  /// **'Tell us more about why you are reporting this'**
  String get tellUsMoreAboutWhyYouAreReportingThis;

  /// No description provided for @errorSharing.
  ///
  /// In en, this message translates to:
  /// **'Error sharing'**
  String get errorSharing;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Info'**
  String get deviceInfo;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @anyLanguage.
  ///
  /// In en, this message translates to:
  /// **'Any Language'**
  String get anyLanguage;

  /// No description provided for @noLanguagesFound.
  ///
  /// In en, this message translates to:
  /// **'No languages found'**
  String get noLanguagesFound;

  /// No description provided for @selectALanguage.
  ///
  /// In en, this message translates to:
  /// **'Select a language'**
  String get selectALanguage;

  /// No description provided for @languagesAreStillLoading.
  ///
  /// In en, this message translates to:
  /// **'Languages are still loading...'**
  String get languagesAreStillLoading;

  /// No description provided for @selectNativeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select native language'**
  String get selectNativeLanguage;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'es', 'ko', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'ko': return AppLocalizationsKo();
    case 'ru': return AppLocalizationsRu();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
