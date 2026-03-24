import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tl.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tl'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'TW')
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

  /// No description provided for @deleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete Comment?'**
  String get deleteComment;

  /// No description provided for @commentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted'**
  String get commentDeleted;

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

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

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

  /// No description provided for @bloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get bloodType;

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
  /// **'NOTIFICATION TYPES'**
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
  /// **'Session expired. Please login again.'**
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
  /// **'Sent!'**
  String sent(String emoji);

  /// No description provided for @replySent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent!'**
  String get replySent;

  /// No description provided for @deleteStory.
  ///
  /// In en, this message translates to:
  /// **'Delete story?'**
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

  /// No description provided for @subscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expired'**
  String get subscriptionExpired;

  /// No description provided for @vipExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your VIP subscription has expired. Renew now to continue enjoying unlimited features!'**
  String get vipExpiredMessage;

  /// No description provided for @expiredOn.
  ///
  /// In en, this message translates to:
  /// **'Expired on'**
  String get expiredOn;

  /// No description provided for @renewVIP.
  ///
  /// In en, this message translates to:
  /// **'Renew VIP'**
  String get renewVIP;

  /// No description provided for @whatYoureMissing.
  ///
  /// In en, this message translates to:
  /// **'What you\'re missing'**
  String get whatYoureMissing;

  /// No description provided for @manageInAppStore.
  ///
  /// In en, this message translates to:
  /// **'Manage in App Store'**
  String get manageInAppStore;

  /// No description provided for @becomeVIP.
  ///
  /// In en, this message translates to:
  /// **'Become VIP'**
  String get becomeVIP;

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
  /// **'Please select your native language'**
  String get selectNativeLanguage;

  /// No description provided for @subscriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Subscription Details'**
  String get subscriptionDetails;

  /// No description provided for @activeFeatures.
  ///
  /// In en, this message translates to:
  /// **'Active Features'**
  String get activeFeatures;

  /// No description provided for @legalInformation.
  ///
  /// In en, this message translates to:
  /// **'Legal Information'**
  String get legalInformation;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @manageSubscriptionInSettings.
  ///
  /// In en, this message translates to:
  /// **'To cancel your subscription, go to Settings > [Your Name] > Subscriptions on your device.'**
  String get manageSubscriptionInSettings;

  /// No description provided for @contactSupportToCancel.
  ///
  /// In en, this message translates to:
  /// **'To cancel your subscription, please contact our support team.'**
  String get contactSupportToCancel;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get active;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @nextBillingDate.
  ///
  /// In en, this message translates to:
  /// **'Next Billing Date'**
  String get nextBillingDate;

  /// No description provided for @autoRenew.
  ///
  /// In en, this message translates to:
  /// **'Auto Renew'**
  String get autoRenew;

  /// No description provided for @pleaseLogInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue'**
  String get pleaseLogInToContinue;

  /// No description provided for @purchaseCanceledOrFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase was canceled or failed. Please try again.'**
  String get purchaseCanceledOrFailed;

  /// No description provided for @maximumTagsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 tags allowed'**
  String get maximumTagsAllowed;

  /// No description provided for @pleaseRemoveImagesFirstToAddVideo.
  ///
  /// In en, this message translates to:
  /// **'Please remove images first to add a video'**
  String get pleaseRemoveImagesFirstToAddVideo;

  /// No description provided for @unsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported format'**
  String get unsupportedFormat;

  /// No description provided for @errorProcessingVideo.
  ///
  /// In en, this message translates to:
  /// **'Error processing video'**
  String get errorProcessingVideo;

  /// No description provided for @pleaseRemoveImagesFirstToRecordVideo.
  ///
  /// In en, this message translates to:
  /// **'Please remove images first to record a video'**
  String get pleaseRemoveImagesFirstToRecordVideo;

  /// No description provided for @locationAdded.
  ///
  /// In en, this message translates to:
  /// **'Location added'**
  String get locationAdded;

  /// No description provided for @failedToGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location'**
  String get failedToGetLocation;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// No description provided for @videoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Video Upload Failed'**
  String get videoUploadFailed;

  /// No description provided for @skipVideo.
  ///
  /// In en, this message translates to:
  /// **'Skip Video'**
  String get skipVideo;

  /// No description provided for @retryUpload.
  ///
  /// In en, this message translates to:
  /// **'Retry Upload'**
  String get retryUpload;

  /// No description provided for @momentCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Moment created successfully'**
  String get momentCreatedSuccessfully;

  /// No description provided for @uploadingMomentInBackground.
  ///
  /// In en, this message translates to:
  /// **'Uploading moment in background...'**
  String get uploadingMomentInBackground;

  /// No description provided for @failedToQueueUpload.
  ///
  /// In en, this message translates to:
  /// **'Failed to queue upload'**
  String get failedToQueueUpload;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @mediaLinksAndDocs.
  ///
  /// In en, this message translates to:
  /// **'Media, links, and docs'**
  String get mediaLinksAndDocs;

  /// No description provided for @wallpaper.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper'**
  String get wallpaper;

  /// No description provided for @userIdNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'User ID not available'**
  String get userIdNotAvailable;

  /// No description provided for @cannotBlockYourself.
  ///
  /// In en, this message translates to:
  /// **'Cannot block yourself'**
  String get cannotBlockYourself;

  /// No description provided for @chatWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Chat Wallpaper'**
  String get chatWallpaper;

  /// No description provided for @wallpaperSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper saved locally'**
  String get wallpaperSavedLocally;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get messageCopied;

  /// No description provided for @forwardFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Forward feature coming soon'**
  String get forwardFeatureComingSoon;

  /// No description provided for @momentUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get momentUnsaved;

  /// No description provided for @documentPickerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Document picker coming soon'**
  String get documentPickerComingSoon;

  /// No description provided for @contactSharingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Contact sharing coming soon'**
  String get contactSharingComingSoon;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Feature coming soon'**
  String get featureComingSoon;

  /// No description provided for @answerSent.
  ///
  /// In en, this message translates to:
  /// **'Answer sent!'**
  String get answerSent;

  /// No description provided for @noImagesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No images available'**
  String get noImagesAvailable;

  /// No description provided for @mentionPickerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Mention picker coming soon'**
  String get mentionPickerComingSoon;

  /// No description provided for @musicPickerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Music picker coming soon'**
  String get musicPickerComingSoon;

  /// No description provided for @repostFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Repost feature coming soon'**
  String get repostFeatureComingSoon;

  /// No description provided for @addFriendsFromYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Add friends from your profile'**
  String get addFriendsFromYourProfile;

  /// No description provided for @quickReplyAdded.
  ///
  /// In en, this message translates to:
  /// **'Quick reply added'**
  String get quickReplyAdded;

  /// No description provided for @quickReplyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Quick reply deleted'**
  String get quickReplyDeleted;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied!'**
  String get linkCopied;

  /// No description provided for @maximumOptionsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum 10 options allowed'**
  String get maximumOptionsAllowed;

  /// No description provided for @minimumOptionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Minimum 2 options required'**
  String get minimumOptionsRequired;

  /// No description provided for @pleaseEnterAQuestion.
  ///
  /// In en, this message translates to:
  /// **'Please enter a question'**
  String get pleaseEnterAQuestion;

  /// No description provided for @pleaseAddAtLeast2Options.
  ///
  /// In en, this message translates to:
  /// **'Please add at least 2 options'**
  String get pleaseAddAtLeast2Options;

  /// No description provided for @pleaseSelectCorrectAnswerForQuiz.
  ///
  /// In en, this message translates to:
  /// **'Please select the correct answer for quiz'**
  String get pleaseSelectCorrectAnswerForQuiz;

  /// No description provided for @correctionSent.
  ///
  /// In en, this message translates to:
  /// **'Correction sent!'**
  String get correctionSent;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @savedMoments.
  ///
  /// In en, this message translates to:
  /// **'Saved Moments'**
  String get savedMoments;

  /// No description provided for @unsave.
  ///
  /// In en, this message translates to:
  /// **'Unsave'**
  String get unsave;

  /// No description provided for @playingAudio.
  ///
  /// In en, this message translates to:
  /// **'Playing audio...'**
  String get playingAudio;

  /// No description provided for @failedToGenerateQuiz.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate quiz'**
  String get failedToGenerateQuiz;

  /// No description provided for @failedToAddComment.
  ///
  /// In en, this message translates to:
  /// **'Failed to add comment'**
  String get failedToAddComment;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get hello;

  /// No description provided for @howAreYou.
  ///
  /// In en, this message translates to:
  /// **'How are you?'**
  String get howAreYou;

  /// No description provided for @cannotOpen.
  ///
  /// In en, this message translates to:
  /// **'Cannot open'**
  String get cannotOpen;

  /// No description provided for @errorOpeningLink.
  ///
  /// In en, this message translates to:
  /// **'Error opening link'**
  String get errorOpeningLink;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get lastSeen;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(String count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(String count);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @signInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get signInWithEmail;

  /// No description provided for @partners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get partners;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @topics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topics;

  /// No description provided for @waves.
  ///
  /// In en, this message translates to:
  /// **'Waves'**
  String get waves;

  /// No description provided for @voiceRooms.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceRooms;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @searchCommunity.
  ///
  /// In en, this message translates to:
  /// **'Search by name, language, or interests...'**
  String get searchCommunity;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @noBioYet.
  ///
  /// In en, this message translates to:
  /// **'No bio available yet.'**
  String get noBioYet;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @native.
  ///
  /// In en, this message translates to:
  /// **'Native'**
  String get native;

  /// No description provided for @interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// No description provided for @noMomentsYet.
  ///
  /// In en, this message translates to:
  /// **'No moments yet'**
  String get noMomentsYet;

  /// No description provided for @unableToLoadMoments.
  ///
  /// In en, this message translates to:
  /// **'Unable to load moments'**
  String get unableToLoadMoments;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @mapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map unavailable'**
  String get mapUnavailable;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get unknownLocation;

  /// No description provided for @noImagesAvailable2.
  ///
  /// In en, this message translates to:
  /// **'No images available'**
  String get noImagesAvailable2;

  /// No description provided for @permissionsRequired.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get permissionsRequired;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoCall;

  /// No description provided for @voiceCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get voiceCall;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @pleaseLoginToFollow.
  ///
  /// In en, this message translates to:
  /// **'Please login to follow users'**
  String get pleaseLoginToFollow;

  /// No description provided for @pleaseLoginToCall.
  ///
  /// In en, this message translates to:
  /// **'Please login to make a call'**
  String get pleaseLoginToCall;

  /// No description provided for @cannotCallYourself.
  ///
  /// In en, this message translates to:
  /// **'You cannot call yourself'**
  String get cannotCallYourself;

  /// No description provided for @failedToFollowUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to follow user'**
  String get failedToFollowUser;

  /// No description provided for @failedToUnfollowUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to unfollow user'**
  String get failedToUnfollowUser;

  /// No description provided for @areYouSureUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unfollow this user?'**
  String get areYouSureUnfollow;

  /// No description provided for @areYouSureUnblock.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unblock this user?'**
  String get areYouSureUnblock;

  /// No description provided for @youFollowed.
  ///
  /// In en, this message translates to:
  /// **'You followed'**
  String get youFollowed;

  /// No description provided for @youUnfollowed.
  ///
  /// In en, this message translates to:
  /// **'You unfollowed'**
  String get youUnfollowed;

  /// No description provided for @alreadyFollowing.
  ///
  /// In en, this message translates to:
  /// **'You are already following'**
  String get alreadyFollowing;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} is coming soon!'**
  String comingSoon(String feature);

  /// No description provided for @muteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get muteNotifications;

  /// No description provided for @unmuteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Unmute notifications'**
  String get unmuteNotifications;

  /// No description provided for @operationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Operation completed'**
  String get operationCompleted;

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps'**
  String get couldNotOpenMaps;

  /// No description provided for @hasntSharedMoments.
  ///
  /// In en, this message translates to:
  /// **'{name} hasn\'t shared any moments'**
  String hasntSharedMoments(Object name);

  /// No description provided for @messageUser.
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String messageUser(String name);

  /// No description provided for @notFollowingUser.
  ///
  /// In en, this message translates to:
  /// **'You were not following {name}'**
  String notFollowingUser(String name);

  /// No description provided for @youFollowedUser.
  ///
  /// In en, this message translates to:
  /// **'You followed {name}'**
  String youFollowedUser(String name);

  /// No description provided for @youUnfollowedUser.
  ///
  /// In en, this message translates to:
  /// **'You unfollowed {name}'**
  String youUnfollowedUser(String name);

  /// No description provided for @unfollowUser.
  ///
  /// In en, this message translates to:
  /// **'Unfollow {name}'**
  String unfollowUser(String name);

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'typing'**
  String get typing;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @maxTagsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 tags allowed'**
  String get maxTagsAllowed;

  /// No description provided for @maxImagesAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum {count} images allowed'**
  String maxImagesAllowed(int count);

  /// No description provided for @pleaseRemoveImagesFirst.
  ///
  /// In en, this message translates to:
  /// **'Please remove images first to add a video'**
  String get pleaseRemoveImagesFirst;

  /// No description provided for @exchange3MessagesBeforeCall.
  ///
  /// In en, this message translates to:
  /// **'You need to exchange at least 3 messages before you can call this user'**
  String get exchange3MessagesBeforeCall;

  /// No description provided for @mediaWithUser.
  ///
  /// In en, this message translates to:
  /// **'Media with {name}'**
  String mediaWithUser(String name);

  /// No description provided for @errorLoadingMedia.
  ///
  /// In en, this message translates to:
  /// **'Error loading media'**
  String get errorLoadingMedia;

  /// No description provided for @savedMomentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Moments'**
  String get savedMomentsTitle;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark?'**
  String get removeBookmark;

  /// No description provided for @thisWillRemoveBookmark.
  ///
  /// In en, this message translates to:
  /// **'This will remove the message from your bookmarks.'**
  String get thisWillRemoveBookmark;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// No description provided for @bookmarkedMessages.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked Messages'**
  String get bookmarkedMessages;

  /// No description provided for @wallpaperSaved.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper saved locally'**
  String get wallpaperSaved;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get typeDeleteToConfirm;

  /// No description provided for @storyArchive.
  ///
  /// In en, this message translates to:
  /// **'Story Archive'**
  String get storyArchive;

  /// No description provided for @newHighlight.
  ///
  /// In en, this message translates to:
  /// **'New Highlight'**
  String get newHighlight;

  /// No description provided for @addToHighlight.
  ///
  /// In en, this message translates to:
  /// **'Add to Highlight'**
  String get addToHighlight;

  /// No description provided for @repost.
  ///
  /// In en, this message translates to:
  /// **'Repost'**
  String get repost;

  /// No description provided for @repostFeatureSoon.
  ///
  /// In en, this message translates to:
  /// **'Repost feature coming soon'**
  String get repostFeatureSoon;

  /// No description provided for @closeFriends.
  ///
  /// In en, this message translates to:
  /// **'Close Friends'**
  String get closeFriends;

  /// No description provided for @addFriends.
  ///
  /// In en, this message translates to:
  /// **'Add Friends'**
  String get addFriends;

  /// No description provided for @highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlights;

  /// No description provided for @createHighlight.
  ///
  /// In en, this message translates to:
  /// **'Create Highlight'**
  String get createHighlight;

  /// No description provided for @deleteHighlight.
  ///
  /// In en, this message translates to:
  /// **'Delete Highlight?'**
  String get deleteHighlight;

  /// No description provided for @editHighlight.
  ///
  /// In en, this message translates to:
  /// **'Edit Highlight'**
  String get editHighlight;

  /// No description provided for @addMoreToStory.
  ///
  /// In en, this message translates to:
  /// **'Add more to story'**
  String get addMoreToStory;

  /// No description provided for @noViewersYet.
  ///
  /// In en, this message translates to:
  /// **'No viewers yet'**
  String get noViewersYet;

  /// No description provided for @noReactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No reactions yet'**
  String get noReactionsYet;

  /// No description provided for @leaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave Room?'**
  String get leaveRoom;

  /// No description provided for @areYouSureLeaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this voice room?'**
  String get areYouSureLeaveRoom;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @enableGPS.
  ///
  /// In en, this message translates to:
  /// **'Enable GPS'**
  String get enableGPS;

  /// No description provided for @wavedToUser.
  ///
  /// In en, this message translates to:
  /// **'Waved to {name}!'**
  String wavedToUser(String name);

  /// No description provided for @areYouSureFollow.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to follow'**
  String get areYouSureFollow;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get failedToLoadProfile;

  /// No description provided for @noFollowersYet.
  ///
  /// In en, this message translates to:
  /// **'No followers yet'**
  String get noFollowersYet;

  /// No description provided for @noFollowingYet.
  ///
  /// In en, this message translates to:
  /// **'Not following anyone yet'**
  String get noFollowingYet;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get searchUsers;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @loadingFailed.
  ///
  /// In en, this message translates to:
  /// **'Loading failed'**
  String get loadingFailed;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @shareStory.
  ///
  /// In en, this message translates to:
  /// **'Share story'**
  String get shareStory;

  /// No description provided for @thisWillDeleteStory.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this story.'**
  String get thisWillDeleteStory;

  /// No description provided for @storyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Story deleted'**
  String get storyDeleted;

  /// No description provided for @addCaption.
  ///
  /// In en, this message translates to:
  /// **'Add a caption...'**
  String get addCaption;

  /// No description provided for @yourStory.
  ///
  /// In en, this message translates to:
  /// **'Your Story'**
  String get yourStory;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @replyToStory.
  ///
  /// In en, this message translates to:
  /// **'Reply to story...'**
  String get replyToStory;

  /// No description provided for @viewAllReplies.
  ///
  /// In en, this message translates to:
  /// **'View all replies'**
  String get viewAllReplies;

  /// No description provided for @preparingVideo.
  ///
  /// In en, this message translates to:
  /// **'Preparing video...'**
  String get preparingVideo;

  /// No description provided for @videoOptimized.
  ///
  /// In en, this message translates to:
  /// **'Video optimized: {size}MB (saved {savings}%)'**
  String videoOptimized(String size, String savings);

  /// No description provided for @failedToProcessVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to process video'**
  String get failedToProcessVideo;

  /// No description provided for @optimizingForBestExperience.
  ///
  /// In en, this message translates to:
  /// **'Optimizing for the best story experience'**
  String get optimizingForBestExperience;

  /// No description provided for @pleaseSelectImageOrVideo.
  ///
  /// In en, this message translates to:
  /// **'Please select an image or video for your story'**
  String get pleaseSelectImageOrVideo;

  /// No description provided for @storyCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Story created successfully!'**
  String get storyCreatedSuccessfully;

  /// No description provided for @uploadingStoryInBackground.
  ///
  /// In en, this message translates to:
  /// **'Uploading story in background...'**
  String get uploadingStoryInBackground;

  /// No description provided for @storyCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'Story Creation Failed'**
  String get storyCreationFailed;

  /// No description provided for @pleaseCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get pleaseCheckConnection;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload Failed'**
  String get uploadFailed;

  /// No description provided for @tryShorterVideo.
  ///
  /// In en, this message translates to:
  /// **'Try using a shorter video or try again later.'**
  String get tryShorterVideo;

  /// No description provided for @shareMomentsThatDisappear.
  ///
  /// In en, this message translates to:
  /// **'Share moments that disappear in 24 hours'**
  String get shareMomentsThatDisappear;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @addSticker.
  ///
  /// In en, this message translates to:
  /// **'Add Sticker'**
  String get addSticker;

  /// No description provided for @poll.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get poll;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @mention.
  ///
  /// In en, this message translates to:
  /// **'Mention'**
  String get mention;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @hashtag.
  ///
  /// In en, this message translates to:
  /// **'Hashtag'**
  String get hashtag;

  /// No description provided for @whoCanSeeThis.
  ///
  /// In en, this message translates to:
  /// **'Who can see this?'**
  String get whoCanSeeThis;

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get everyone;

  /// No description provided for @anyoneCanSeeStory.
  ///
  /// In en, this message translates to:
  /// **'Anyone can see this story'**
  String get anyoneCanSeeStory;

  /// No description provided for @friendsOnly.
  ///
  /// In en, this message translates to:
  /// **'Friends Only'**
  String get friendsOnly;

  /// No description provided for @onlyFollowersCanSee.
  ///
  /// In en, this message translates to:
  /// **'Only your followers can see'**
  String get onlyFollowersCanSee;

  /// No description provided for @onlyCloseFriendsCanSee.
  ///
  /// In en, this message translates to:
  /// **'Only your close friends can see'**
  String get onlyCloseFriendsCanSee;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// No description provided for @fontStyle.
  ///
  /// In en, this message translates to:
  /// **'Font Style'**
  String get fontStyle;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @bold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get bold;

  /// No description provided for @italic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get italic;

  /// No description provided for @handwriting.
  ///
  /// In en, this message translates to:
  /// **'Handwriting'**
  String get handwriting;

  /// No description provided for @addLocation.
  ///
  /// In en, this message translates to:
  /// **'Add Location'**
  String get addLocation;

  /// No description provided for @enterLocationName.
  ///
  /// In en, this message translates to:
  /// **'Enter location name'**
  String get enterLocationName;

  /// No description provided for @addLink.
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get addLink;

  /// No description provided for @buttonText.
  ///
  /// In en, this message translates to:
  /// **'Button text'**
  String get buttonText;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @addHashtags.
  ///
  /// In en, this message translates to:
  /// **'Add Hashtags'**
  String get addHashtags;

  /// No description provided for @addHashtag.
  ///
  /// In en, this message translates to:
  /// **'Add hashtag'**
  String get addHashtag;

  /// No description provided for @sendAsMessage.
  ///
  /// In en, this message translates to:
  /// **'Send as Message'**
  String get sendAsMessage;

  /// No description provided for @shareExternally.
  ///
  /// In en, this message translates to:
  /// **'Share Externally'**
  String get shareExternally;

  /// No description provided for @checkOutStory.
  ///
  /// In en, this message translates to:
  /// **'Check out this story on BananaTalk!'**
  String get checkOutStory;

  /// No description provided for @viewsTab.
  ///
  /// In en, this message translates to:
  /// **'Views ({count})'**
  String viewsTab(String count);

  /// No description provided for @reactionsTab.
  ///
  /// In en, this message translates to:
  /// **'Reactions ({count})'**
  String reactionsTab(String count);

  /// No description provided for @processingVideo.
  ///
  /// In en, this message translates to:
  /// **'Processing video...'**
  String get processingVideo;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @unmuteUser.
  ///
  /// In en, this message translates to:
  /// **'Unmute {name}?'**
  String unmuteUser(String name);

  /// No description provided for @willReceiveNotifications.
  ///
  /// In en, this message translates to:
  /// **'You will receive notifications for new messages.'**
  String get willReceiveNotifications;

  /// No description provided for @muteNotificationsFor.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications for {name}'**
  String muteNotificationsFor(String name);

  /// No description provided for @notificationsUnmutedFor.
  ///
  /// In en, this message translates to:
  /// **'Notifications unmuted for {name}'**
  String notificationsUnmutedFor(String name);

  /// No description provided for @notificationsMutedFor.
  ///
  /// In en, this message translates to:
  /// **'Notifications muted for {name}'**
  String notificationsMutedFor(String name);

  /// No description provided for @failedToUpdateMuteSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to update mute settings'**
  String get failedToUpdateMuteSettings;

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get oneHour;

  /// No description provided for @eightHours.
  ///
  /// In en, this message translates to:
  /// **'8 hours'**
  String get eightHours;

  /// No description provided for @oneWeek.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get oneWeek;

  /// No description provided for @always.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get always;

  /// No description provided for @failedToLoadBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Failed to load bookmarks'**
  String get failedToLoadBookmarks;

  /// No description provided for @noBookmarkedMessages.
  ///
  /// In en, this message translates to:
  /// **'No bookmarked messages'**
  String get noBookmarkedMessages;

  /// No description provided for @longPressToBookmark.
  ///
  /// In en, this message translates to:
  /// **'Long press on a message to bookmark it'**
  String get longPressToBookmark;

  /// No description provided for @thisWillRemoveFromBookmarks.
  ///
  /// In en, this message translates to:
  /// **'This will remove the message from your bookmarks.'**
  String get thisWillRemoveFromBookmarks;

  /// No description provided for @navigateToMessage.
  ///
  /// In en, this message translates to:
  /// **'Navigate to message in chat with {name}'**
  String navigateToMessage(String name);

  /// No description provided for @bookmarkedOn.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked {date}'**
  String bookmarkedOn(String date);

  /// No description provided for @voiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get voiceMessage;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment;

  /// No description provided for @sendMeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Send me a message'**
  String get sendMeAMessage;

  /// No description provided for @shareWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Share with friends'**
  String get shareWithFriends;

  /// No description provided for @shareAnywhere.
  ///
  /// In en, this message translates to:
  /// **'Share anywhere'**
  String get shareAnywhere;

  /// No description provided for @emailPreferences.
  ///
  /// In en, this message translates to:
  /// **'Email Preferences'**
  String get emailPreferences;

  /// No description provided for @receiveEmailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive email notifications from BananaTalk'**
  String get receiveEmailNotifications;

  /// No description provided for @whenAwayFor24Hours.
  ///
  /// In en, this message translates to:
  /// **'When you\'re away for 24+ hours'**
  String get whenAwayFor24Hours;

  /// No description provided for @passwordAndLoginAlerts.
  ///
  /// In en, this message translates to:
  /// **'Password & login alerts'**
  String get passwordAndLoginAlerts;

  /// No description provided for @failedToLoadPreferences.
  ///
  /// In en, this message translates to:
  /// **'Failed to load preferences'**
  String get failedToLoadPreferences;

  /// No description provided for @failedToUpdateSetting.
  ///
  /// In en, this message translates to:
  /// **'Failed to update setting'**
  String get failedToUpdateSetting;

  /// No description provided for @securityAlertsRecommended.
  ///
  /// In en, this message translates to:
  /// **'We recommend keeping Security Alerts enabled to stay informed about important account activity.'**
  String get securityAlertsRecommended;

  /// No description provided for @chatWallpaperFor.
  ///
  /// In en, this message translates to:
  /// **'Chat wallpaper for {name}'**
  String chatWallpaperFor(String name);

  /// No description provided for @solidColors.
  ///
  /// In en, this message translates to:
  /// **'Solid Colors'**
  String get solidColors;

  /// No description provided for @gradients.
  ///
  /// In en, this message translates to:
  /// **'Gradients'**
  String get gradients;

  /// No description provided for @customImage.
  ///
  /// In en, this message translates to:
  /// **'Custom Image'**
  String get customImage;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @wallpaperUpdated.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper updated'**
  String get wallpaperUpdated;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @mood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @timePeriod.
  ///
  /// In en, this message translates to:
  /// **'Time Period'**
  String get timePeriod;

  /// No description provided for @searchLanguages.
  ///
  /// In en, this message translates to:
  /// **'Search languages...'**
  String get searchLanguages;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @moods.
  ///
  /// In en, this message translates to:
  /// **'Moods'**
  String get moods;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @applyNFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply {count} Filters'**
  String applyNFilters(int count);

  /// No description provided for @videoMustBeUnder1GB.
  ///
  /// In en, this message translates to:
  /// **'Video must be under 1GB.'**
  String get videoMustBeUnder1GB;

  /// No description provided for @failedToRecordVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to record video'**
  String get failedToRecordVideo;

  /// No description provided for @errorSendingVideo.
  ///
  /// In en, this message translates to:
  /// **'Error sending video'**
  String get errorSendingVideo;

  /// No description provided for @errorSendingVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Error sending voice message'**
  String get errorSendingVoiceMessage;

  /// No description provided for @errorSendingMedia.
  ///
  /// In en, this message translates to:
  /// **'Error sending media'**
  String get errorSendingMedia;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone permissions are required to record videos.'**
  String get cameraPermissionRequired;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to share your location.'**
  String get locationPermissionRequired;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get tryAgainLater;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get messageSent;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @messageEdited.
  ///
  /// In en, this message translates to:
  /// **'Message edited'**
  String get messageEdited;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'(edited)'**
  String get edited;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get now;

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String weeksAgo(int count);

  /// No description provided for @viewRepliesCount.
  ///
  /// In en, this message translates to:
  /// **'── View {count} {count, plural, =1{reply} other{replies}}'**
  String viewRepliesCount(int count);

  /// No description provided for @hideReplies.
  ///
  /// In en, this message translates to:
  /// **'── Hide replies'**
  String get hideReplies;

  /// No description provided for @saveMoment.
  ///
  /// In en, this message translates to:
  /// **'Save Moment'**
  String get saveMoment;

  /// No description provided for @removeFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Remove from Saved'**
  String get removeFromSaved;

  /// No description provided for @momentSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get momentSaved;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get failedToSave;

  /// No description provided for @checkOutMoment.
  ///
  /// In en, this message translates to:
  /// **'Check out this moment: {title}'**
  String checkOutMoment(String title);

  /// No description provided for @failedToLoadMoments.
  ///
  /// In en, this message translates to:
  /// **'Failed to load moments'**
  String get failedToLoadMoments;

  /// No description provided for @noMomentsMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No moments match your filters'**
  String get noMomentsMatchFilters;

  /// No description provided for @beFirstToShareMoment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share a moment!'**
  String get beFirstToShareMoment;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters to find language exchange partners.'**
  String get tryAdjustingFilters;

  /// No description provided for @noSavedMoments.
  ///
  /// In en, this message translates to:
  /// **'No saved moments'**
  String get noSavedMoments;

  /// No description provided for @tapBookmarkToSave.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon on a moment to save it'**
  String get tapBookmarkToSave;

  /// No description provided for @failedToLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to load video'**
  String get failedToLoadVideo;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @titleTooLong.
  ///
  /// In en, this message translates to:
  /// **'Title must be {max} characters or less'**
  String titleTooLong(int max);

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// No description provided for @descriptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Description must be {max} characters or less'**
  String descriptionTooLong(int max);

  /// No description provided for @scheduledDateMustBeFuture.
  ///
  /// In en, this message translates to:
  /// **'Scheduled date must be in the future'**
  String get scheduledDateMustBeFuture;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @mostRecent.
  ///
  /// In en, this message translates to:
  /// **'Most Recent'**
  String get mostRecent;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopular;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {userName}'**
  String replyingTo(String userName);

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @quickMatch.
  ///
  /// In en, this message translates to:
  /// **'Quick Match'**
  String get quickMatch;

  /// No description provided for @onlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online Now'**
  String get onlineNow;

  /// No description provided for @speaksLanguage.
  ///
  /// In en, this message translates to:
  /// **'Speaks {language}'**
  String speaksLanguage(String language);

  /// No description provided for @learningLanguage.
  ///
  /// In en, this message translates to:
  /// **'Learning {language}'**
  String learningLanguage(String language);

  /// No description provided for @noPartnersFound.
  ///
  /// In en, this message translates to:
  /// **'No partners found'**
  String get noPartnersFound;

  /// No description provided for @noUsersFoundForLanguages.
  ///
  /// In en, this message translates to:
  /// **'No users found who speak {learning} natively or want to learn {native}.'**
  String noUsersFoundForLanguages(String learning, String native);

  /// No description provided for @removeAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Remove all filters'**
  String get removeAllFilters;

  /// No description provided for @browseAllUsers.
  ///
  /// In en, this message translates to:
  /// **'Browse all users'**
  String get browseAllUsers;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @loadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more...'**
  String get loadingMore;

  /// No description provided for @findingMorePartners.
  ///
  /// In en, this message translates to:
  /// **'Finding more language partners for you...'**
  String get findingMorePartners;

  /// No description provided for @seenAllPartners.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen all available partners. Check back later for more!'**
  String get seenAllPartners;

  /// No description provided for @startOver.
  ///
  /// In en, this message translates to:
  /// **'Start Over'**
  String get startOver;

  /// No description provided for @changeFilters.
  ///
  /// In en, this message translates to:
  /// **'Change Filters'**
  String get changeFilters;

  /// No description provided for @findingPartners.
  ///
  /// In en, this message translates to:
  /// **'Finding partners...'**
  String get findingPartners;

  /// No description provided for @setLocationReminder.
  ///
  /// In en, this message translates to:
  /// **'Set your location in your profile to see nearby users first.'**
  String get setLocationReminder;

  /// No description provided for @updateLocationReminder.
  ///
  /// In en, this message translates to:
  /// **'Update your location in Profile > Edit to get accurate nearby results.'**
  String get updateLocationReminder;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @browseMen.
  ///
  /// In en, this message translates to:
  /// **'Browse men'**
  String get browseMen;

  /// No description provided for @browseWomen.
  ///
  /// In en, this message translates to:
  /// **'Browse women'**
  String get browseWomen;

  /// No description provided for @noMaleUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No male users found'**
  String get noMaleUsersFound;

  /// No description provided for @noFemaleUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No female users found'**
  String get noFemaleUsersFound;

  /// No description provided for @vip.
  ///
  /// In en, this message translates to:
  /// **'VIP'**
  String get vip;

  /// No description provided for @newUsersOnly.
  ///
  /// In en, this message translates to:
  /// **'New Users Only'**
  String get newUsersOnly;

  /// No description provided for @showNewUsers.
  ///
  /// In en, this message translates to:
  /// **'Show users who joined in the last 6 days'**
  String get showNewUsers;

  /// No description provided for @prioritizeNearby.
  ///
  /// In en, this message translates to:
  /// **'Prioritize Nearby'**
  String get prioritizeNearby;

  /// No description provided for @showNearbyFirst.
  ///
  /// In en, this message translates to:
  /// **'Show nearby users first in results'**
  String get showNearbyFirst;

  /// No description provided for @setLocationToEnable.
  ///
  /// In en, this message translates to:
  /// **'Set your location to enable this feature'**
  String get setLocationToEnable;

  /// No description provided for @radius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get radius;

  /// No description provided for @findingYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Finding your location...'**
  String get findingYourLocation;

  /// No description provided for @enableLocationForDistance.
  ///
  /// In en, this message translates to:
  /// **'Enable Location for Distance'**
  String get enableLocationForDistance;

  /// No description provided for @enableLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable GPS to see exact distance to partners. You can still browse by city/country without GPS.'**
  String get enableLocationDescription;

  /// No description provided for @enableGps.
  ///
  /// In en, this message translates to:
  /// **'Enable GPS'**
  String get enableGps;

  /// No description provided for @browseByCityCountry.
  ///
  /// In en, this message translates to:
  /// **'Browse by City/Country'**
  String get browseByCityCountry;

  /// No description provided for @peopleNearby.
  ///
  /// In en, this message translates to:
  /// **'People Nearby'**
  String get peopleNearby;

  /// No description provided for @noNearbyUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No nearby users found'**
  String get noNearbyUsersFound;

  /// No description provided for @tryExpandingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try expanding your search or check back later.'**
  String get tryExpandingSearch;

  /// No description provided for @exploreByCity.
  ///
  /// In en, this message translates to:
  /// **'Explore by City'**
  String get exploreByCity;

  /// No description provided for @exploreByCurrentCity.
  ///
  /// In en, this message translates to:
  /// **'Browse users on an interactive map, see who\'s in your city, and discover language partners worldwide.'**
  String get exploreByCurrentCity;

  /// No description provided for @interactiveWorldMap.
  ///
  /// In en, this message translates to:
  /// **'Interactive world map'**
  String get interactiveWorldMap;

  /// No description provided for @searchByCityName.
  ///
  /// In en, this message translates to:
  /// **'Search by city name'**
  String get searchByCityName;

  /// No description provided for @seeUserCountsPerCountry.
  ///
  /// In en, this message translates to:
  /// **'See user counts per country'**
  String get seeUserCountsPerCountry;

  /// No description provided for @upgradeToVip.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to VIP'**
  String get upgradeToVip;

  /// No description provided for @searchByCity.
  ///
  /// In en, this message translates to:
  /// **'Search by city...'**
  String get searchByCity;

  /// No description provided for @usersWorldwide.
  ///
  /// In en, this message translates to:
  /// **'{count} users worldwide'**
  String usersWorldwide(String count);

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @tryDifferentCity.
  ///
  /// In en, this message translates to:
  /// **'Try a different city or country'**
  String get tryDifferentCity;

  /// No description provided for @usersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} users'**
  String usersCount(String count);

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country...'**
  String get searchCountry;

  /// No description provided for @wave.
  ///
  /// In en, this message translates to:
  /// **'Wave'**
  String get wave;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newUser;

  /// No description provided for @warningPermanent.
  ///
  /// In en, this message translates to:
  /// **'Warning: This action is permanent!'**
  String get warningPermanent;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account will permanently remove:\n\n• Your profile and all personal data\n• All your messages and conversations\n• All your moments and stories\n• Your VIP subscription (no refund)\n• All your connections and followers\n\nThis action cannot be undone.'**
  String get deleteAccountWarning;

  /// No description provided for @requiredForEmailOnly.
  ///
  /// In en, this message translates to:
  /// **'Required for email accounts only'**
  String get requiredForEmailOnly;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @typeDELETE.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get typeDELETE;

  /// No description provided for @mustTypeDELETE.
  ///
  /// In en, this message translates to:
  /// **'You must type DELETE to confirm'**
  String get mustTypeDELETE;

  /// No description provided for @deletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting Account...'**
  String get deletingAccount;

  /// No description provided for @deleteMyAccountPermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account Permanently'**
  String get deleteMyAccountPermanently;

  /// No description provided for @whatsYourNativeLanguage.
  ///
  /// In en, this message translates to:
  /// **'What\'s your native language?'**
  String get whatsYourNativeLanguage;

  /// No description provided for @helpsMatchWithLearners.
  ///
  /// In en, this message translates to:
  /// **'This helps us match you with learners'**
  String get helpsMatchWithLearners;

  /// No description provided for @whatAreYouLearning.
  ///
  /// In en, this message translates to:
  /// **'What are you learning?'**
  String get whatAreYouLearning;

  /// No description provided for @connectWithNativeSpeakers.
  ///
  /// In en, this message translates to:
  /// **'We\'ll connect you with native speakers'**
  String get connectWithNativeSpeakers;

  /// No description provided for @selectLearningLanguage.
  ///
  /// In en, this message translates to:
  /// **'Please select the language you\'re learning'**
  String get selectLearningLanguage;

  /// No description provided for @selectCurrentLevel.
  ///
  /// In en, this message translates to:
  /// **'Please select your current level'**
  String get selectCurrentLevel;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner — I know a few words'**
  String get beginner;

  /// No description provided for @elementary.
  ///
  /// In en, this message translates to:
  /// **'Elementary — I can make simple sentences'**
  String get elementary;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate — I can have basic conversations'**
  String get intermediate;

  /// No description provided for @upperIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Upper Intermediate — I can discuss most topics'**
  String get upperIntermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced — I speak fluently with few errors'**
  String get advanced;

  /// No description provided for @proficient.
  ///
  /// In en, this message translates to:
  /// **'Proficient — Near-native level'**
  String get proficient;

  /// No description provided for @showingPartnersByDistance.
  ///
  /// In en, this message translates to:
  /// **'Showing partners sorted by distance'**
  String get showingPartnersByDistance;

  /// No description provided for @enableLocationForResults.
  ///
  /// In en, this message translates to:
  /// **'Enable location for distance-based results'**
  String get enableLocationForResults;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @locationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Location not set'**
  String get locationNotSet;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get tellUsAboutYourself;

  /// No description provided for @justACoupleQuickThings.
  ///
  /// In en, this message translates to:
  /// **'Just a couple of quick things'**
  String get justACoupleQuickThings;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get birthDate;

  /// No description provided for @selectYourBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Select your birth date'**
  String get selectYourBirthDate;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @pleaseSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Please select your gender'**
  String get pleaseSelectGender;

  /// No description provided for @pleaseSelectBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Please select your birth date'**
  String get pleaseSelectBirthDate;

  /// No description provided for @mustBe18.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old'**
  String get mustBe18;

  /// No description provided for @invalidDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid date'**
  String get invalidDate;

  /// No description provided for @almostDone.
  ///
  /// In en, this message translates to:
  /// **'Almost done!'**
  String get almostDone;

  /// No description provided for @addPhotoLocationForMatches.
  ///
  /// In en, this message translates to:
  /// **'Add a photo and location to get more matches'**
  String get addPhotoLocationForMatches;

  /// No description provided for @addProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Profile Photo'**
  String get addProfilePhoto;

  /// No description provided for @optionalUpTo6Photos.
  ///
  /// In en, this message translates to:
  /// **'Optional — up to 6 photos'**
  String get optionalUpTo6Photos;

  /// No description provided for @maximum6Photos.
  ///
  /// In en, this message translates to:
  /// **'Maximum 6 photos'**
  String get maximum6Photos;

  /// No description provided for @tapToDetectLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap to detect location'**
  String get tapToDetectLocation;

  /// No description provided for @optionalHelpsNearbyPartners.
  ///
  /// In en, this message translates to:
  /// **'Optional — helps find nearby partners'**
  String get optionalHelpsNearbyPartners;

  /// No description provided for @startLearning.
  ///
  /// In en, this message translates to:
  /// **'Start Learning!'**
  String get startLearning;

  /// No description provided for @photoLocationOptional.
  ///
  /// In en, this message translates to:
  /// **'Photo & location are optional — you can add them later'**
  String get photoLocationOptional;

  /// No description provided for @pleaseAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms of Service'**
  String get pleaseAcceptTerms;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeToThe;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @tapToSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Tap to select a language'**
  String get tapToSelectLanguage;

  /// No description provided for @yourLevelIn.
  ///
  /// In en, this message translates to:
  /// **'Your level in {language} (optional)'**
  String yourLevelIn(String language);

  /// No description provided for @yourCurrentLevel.
  ///
  /// In en, this message translates to:
  /// **'Your current level'**
  String get yourCurrentLevel;

  /// No description provided for @nativeCannotBeSameAsLearning.
  ///
  /// In en, this message translates to:
  /// **'Native language cannot be the same as learning language'**
  String get nativeCannotBeSameAsLearning;

  /// No description provided for @learningCannotBeSameAsNative.
  ///
  /// In en, this message translates to:
  /// **'Learning language cannot be the same as native language'**
  String get learningCannotBeSameAsNative;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(String current, String total);

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLink;

  /// No description provided for @pleaseEnterBothEmailAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter both email and password'**
  String get pleaseEnterBothEmailAndPassword;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login Successful!'**
  String get loginSuccessful;

  /// No description provided for @stepOneOfTwo.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2'**
  String get stepOneOfTwo;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createYourAccount;

  /// No description provided for @basicInfoToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Basic info to get you started'**
  String get basicInfoToGetStarted;

  /// No description provided for @emailVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (Verified)'**
  String get emailVerifiedLabel;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @yourDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Your display name'**
  String get yourDisplayName;

  /// No description provided for @atLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8Characters;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordHint;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @pleaseEnterAPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterAPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @otherGender.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherGender;

  /// No description provided for @continueWithGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue with your Google account\nfor a seamless experience'**
  String get continueWithGoogleAccount;

  /// No description provided for @signingYouIn.
  ///
  /// In en, this message translates to:
  /// **'Signing you in...'**
  String get signingYouIn;

  /// No description provided for @backToSignInMethods.
  ///
  /// In en, this message translates to:
  /// **'Back to sign-in methods'**
  String get backToSignInMethods;

  /// No description provided for @securedByGoogle.
  ///
  /// In en, this message translates to:
  /// **'Secured by Google'**
  String get securedByGoogle;

  /// No description provided for @dataProtectedEncryption.
  ///
  /// In en, this message translates to:
  /// **'Your data is protected with industry-standard encryption'**
  String get dataProtectedEncryption;

  /// No description provided for @welcomeCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Please complete your profile'**
  String get welcomeCompleteProfile;

  /// No description provided for @welcomeBackName.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String welcomeBackName(String name);

  /// No description provided for @continueWithAppleId.
  ///
  /// In en, this message translates to:
  /// **'Continue with your Apple ID\nfor a secure experience'**
  String get continueWithAppleId;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @securedByApple.
  ///
  /// In en, this message translates to:
  /// **'Secured by Apple'**
  String get securedByApple;

  /// No description provided for @privacyProtectedApple.
  ///
  /// In en, this message translates to:
  /// **'Your privacy is protected with Apple Sign-In'**
  String get privacyProtectedApple;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @enterEmailToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to get started'**
  String get enterEmailToGetStarted;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @pleaseEnterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get pleaseEnterEmailAddress;

  /// No description provided for @verificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your email!'**
  String get verificationCodeSent;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @enterEmailForResetCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a code to reset your password'**
  String get enterEmailForResetCode;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Code'**
  String get sendResetCode;

  /// No description provided for @resetCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Reset code sent to your email!'**
  String get resetCodeSent;

  /// No description provided for @rememberYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Remember your password?'**
  String get rememberYourPassword;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @enterResetCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Reset Code'**
  String get enterResetCode;

  /// No description provided for @weSentCodeTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to'**
  String get weSentCodeTo;

  /// No description provided for @pleaseEnterAll6Digits.
  ///
  /// In en, this message translates to:
  /// **'Please enter all 6 digits'**
  String get pleaseEnterAll6Digits;

  /// No description provided for @codeVerifiedCreatePassword.
  ///
  /// In en, this message translates to:
  /// **'Code verified! Create your new password'**
  String get codeVerifiedCreatePassword;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didntReceiveCode;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @resendWithTimer.
  ///
  /// In en, this message translates to:
  /// **'Resend ({timer}s)'**
  String resendWithTimer(String timer);

  /// No description provided for @resetCodeResent.
  ///
  /// In en, this message translates to:
  /// **'Reset code resent!'**
  String get resetCodeResent;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// No description provided for @emailVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get emailVerifiedSuccessfully;

  /// No description provided for @verificationCodeResent.
  ///
  /// In en, this message translates to:
  /// **'Verification code resent!'**
  String get verificationCodeResent;

  /// No description provided for @createNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createNewPassword;

  /// No description provided for @enterNewPasswordBelow.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password below'**
  String get enterNewPasswordBelow;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @passwordResetSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful! Please login with your new password'**
  String get passwordResetSuccessful;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @profileVisibility.
  ///
  /// In en, this message translates to:
  /// **'Profile Visibility'**
  String get profileVisibility;

  /// No description provided for @showCountryRegion.
  ///
  /// In en, this message translates to:
  /// **'Show Country/Region'**
  String get showCountryRegion;

  /// No description provided for @showCountryRegionDesc.
  ///
  /// In en, this message translates to:
  /// **'Display your country on your profile'**
  String get showCountryRegionDesc;

  /// No description provided for @showCity.
  ///
  /// In en, this message translates to:
  /// **'Show City'**
  String get showCity;

  /// No description provided for @showCityDesc.
  ///
  /// In en, this message translates to:
  /// **'Display your city on your profile'**
  String get showCityDesc;

  /// No description provided for @showAge.
  ///
  /// In en, this message translates to:
  /// **'Show Age'**
  String get showAge;

  /// No description provided for @showAgeDesc.
  ///
  /// In en, this message translates to:
  /// **'Display your age on your profile'**
  String get showAgeDesc;

  /// No description provided for @showZodiacSign.
  ///
  /// In en, this message translates to:
  /// **'Show Zodiac Sign'**
  String get showZodiacSign;

  /// No description provided for @showZodiacSignDesc.
  ///
  /// In en, this message translates to:
  /// **'Display your zodiac sign on your profile'**
  String get showZodiacSignDesc;

  /// No description provided for @onlineStatusSection.
  ///
  /// In en, this message translates to:
  /// **'Online Status'**
  String get onlineStatusSection;

  /// No description provided for @showOnlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Show Online Status'**
  String get showOnlineStatus;

  /// No description provided for @showOnlineStatusDesc.
  ///
  /// In en, this message translates to:
  /// **'Let others see when you are online'**
  String get showOnlineStatusDesc;

  /// No description provided for @otherSettings.
  ///
  /// In en, this message translates to:
  /// **'Other Settings'**
  String get otherSettings;

  /// No description provided for @showGiftingLevel.
  ///
  /// In en, this message translates to:
  /// **'Show Gifting Level'**
  String get showGiftingLevel;

  /// No description provided for @showGiftingLevelDesc.
  ///
  /// In en, this message translates to:
  /// **'Display your gifting level badge'**
  String get showGiftingLevelDesc;

  /// No description provided for @birthdayNotifications.
  ///
  /// In en, this message translates to:
  /// **'Birthday Notifications'**
  String get birthdayNotifications;

  /// No description provided for @birthdayNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications on your birthday'**
  String get birthdayNotificationsDesc;

  /// No description provided for @personalizedAds.
  ///
  /// In en, this message translates to:
  /// **'Personalized Ads'**
  String get personalizedAds;

  /// No description provided for @personalizedAdsDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow personalized advertisements'**
  String get personalizedAdsDesc;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @privacySettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings saved'**
  String get privacySettingsSaved;

  /// No description provided for @locationSection.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSection;

  /// No description provided for @updateLocation.
  ///
  /// In en, this message translates to:
  /// **'Update Location'**
  String get updateLocation;

  /// No description provided for @updateLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Refresh your current location'**
  String get updateLocationDesc;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @locationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Location not available'**
  String get locationNotAvailable;

  /// No description provided for @locationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated successfully'**
  String get locationUpdated;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Please enable it in settings.'**
  String get locationPermissionDenied;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them.'**
  String get locationServiceDisabled;

  /// No description provided for @updatingLocation.
  ///
  /// In en, this message translates to:
  /// **'Updating location...'**
  String get updatingLocation;

  /// No description provided for @locationCouldNotBeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location could not be updated'**
  String get locationCouldNotBeUpdated;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'de', 'en', 'es', 'fr', 'hi', 'id', 'it', 'ja', 'ko', 'pt', 'ru', 'th', 'tl', 'tr', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh': {
  switch (locale.countryCode) {
    case 'TW': return AppLocalizationsZhTw();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'hi': return AppLocalizationsHi();
    case 'id': return AppLocalizationsId();
    case 'it': return AppLocalizationsIt();
    case 'ja': return AppLocalizationsJa();
    case 'ko': return AppLocalizationsKo();
    case 'pt': return AppLocalizationsPt();
    case 'ru': return AppLocalizationsRu();
    case 'th': return AppLocalizationsTh();
    case 'tl': return AppLocalizationsTl();
    case 'tr': return AppLocalizationsTr();
    case 'vi': return AppLocalizationsVi();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
