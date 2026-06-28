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
import 'app_localizations_tg.dart';
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
    Locale('tg'),
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
  /// **'Bananatalk'**
  String get appName;

  /// Title of the AI Study promo modal
  ///
  /// In en, this message translates to:
  /// **'Practice with AI scenarios'**
  String get aiStudyPromoTitle;

  /// Body of the AI Study promo modal
  ///
  /// In en, this message translates to:
  /// **'Roleplay real-life conversations with your AI tutor and build confidence speaking.'**
  String get aiStudyPromoBody;

  /// Primary action button in the AI Study promo modal
  ///
  /// In en, this message translates to:
  /// **'Try a scenario'**
  String get aiStudyPromoCTA;

  /// Dismiss button in the AI Study promo modal
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get aiStudyPromoDismiss;

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

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get more;

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

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

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

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free up storage space'**
  String get clearCacheSubtitle;

  /// No description provided for @clearCacheDescription.
  ///
  /// In en, this message translates to:
  /// **'This will clear all cached images, videos, and audio files. The app may load content slower temporarily as it re-downloads media.'**
  String get clearCacheDescription;

  /// No description provided for @clearCacheHint.
  ///
  /// In en, this message translates to:
  /// **'Use this if images or audio aren\'t loading properly.'**
  String get clearCacheHint;

  /// No description provided for @clearingCache.
  ///
  /// In en, this message translates to:
  /// **'Clearing cache...'**
  String get clearingCache;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully! Images will reload fresh.'**
  String get cacheCleared;

  /// No description provided for @clearCacheFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear cache'**
  String get clearCacheFailed;

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

  /// No description provided for @aiTutorChangePersona.
  ///
  /// In en, this message translates to:
  /// **'Change AI tutor'**
  String get aiTutorChangePersona;

  /// No description provided for @aiTutorChangePersonaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to Nana, Sensei or Riko'**
  String get aiTutorChangePersonaSubtitle;

  /// No description provided for @aiTutorHeroTitleSet.
  ///
  /// In en, this message translates to:
  /// **'Your AI Tutor · {name}'**
  String aiTutorHeroTitleSet(String name);

  /// No description provided for @aiTutorHeroTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Meet your AI Tutor'**
  String get aiTutorHeroTitleNew;

  /// No description provided for @aiTutorHeroSubtitleSet.
  ///
  /// In en, this message translates to:
  /// **'Tap to chat or see today\'s plan'**
  String get aiTutorHeroSubtitleSet;

  /// No description provided for @aiTutorHeroSubtitleLast.
  ///
  /// In en, this message translates to:
  /// **'Last time: {summary}'**
  String aiTutorHeroSubtitleLast(String summary);

  /// No description provided for @aiTutorHeroSubtitleNew.
  ///
  /// In en, this message translates to:
  /// **'Pick a persona — Nana, Sensei, or Riko'**
  String get aiTutorHeroSubtitleNew;

  /// No description provided for @aiTutorChipChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get aiTutorChipChat;

  /// No description provided for @aiTutorChipRoleplay.
  ///
  /// In en, this message translates to:
  /// **'Roleplay'**
  String get aiTutorChipRoleplay;

  /// No description provided for @aiTutorChipStory.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get aiTutorChipStory;

  /// No description provided for @aiTutorChipPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get aiTutorChipPhoto;

  /// No description provided for @aiToolsMoreSection.
  ///
  /// In en, this message translates to:
  /// **'More AI tools'**
  String get aiToolsMoreSection;

  /// No description provided for @aiConversationPartnerTile.
  ///
  /// In en, this message translates to:
  /// **'AI Conversation'**
  String get aiConversationPartnerTile;

  /// No description provided for @aiConversationPartnerTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice with an AI partner'**
  String get aiConversationPartnerTileSubtitle;

  /// No description provided for @aiTutorPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your AI tutor'**
  String get aiTutorPickerTitle;

  /// No description provided for @aiTutorPickerHeader.
  ///
  /// In en, this message translates to:
  /// **'Who do you want to learn with?'**
  String get aiTutorPickerHeader;

  /// No description provided for @aiTutorPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in settings.'**
  String get aiTutorPickerSubtitle;

  /// No description provided for @aiTutorPersonaNanaTagline.
  ///
  /// In en, this message translates to:
  /// **'Warm + encouraging'**
  String get aiTutorPersonaNanaTagline;

  /// No description provided for @aiTutorPersonaNanaSample.
  ///
  /// In en, this message translates to:
  /// **'I\'ll cheer you on, no pressure.'**
  String get aiTutorPersonaNanaSample;

  /// No description provided for @aiTutorPersonaSenseiTagline.
  ///
  /// In en, this message translates to:
  /// **'Precise + exam-focused'**
  String get aiTutorPersonaSenseiTagline;

  /// No description provided for @aiTutorPersonaSenseiSample.
  ///
  /// In en, this message translates to:
  /// **'We will master the rules.'**
  String get aiTutorPersonaSenseiSample;

  /// No description provided for @aiTutorPersonaRikoTagline.
  ///
  /// In en, this message translates to:
  /// **'Playful + slangy'**
  String get aiTutorPersonaRikoTagline;

  /// No description provided for @aiTutorPersonaRikoSample.
  ///
  /// In en, this message translates to:
  /// **'lol let\'s vibe and learn'**
  String get aiTutorPersonaRikoSample;

  /// No description provided for @aiTutorPickerSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String aiTutorPickerSaveError(String error);

  /// No description provided for @aiTutorHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Tutor'**
  String get aiTutorHomeTitle;

  /// No description provided for @aiTutorHomeChangeTutor.
  ///
  /// In en, this message translates to:
  /// **'Change tutor'**
  String get aiTutorHomeChangeTutor;

  /// No description provided for @aiTutorHomeGreetingDefault.
  ///
  /// In en, this message translates to:
  /// **'Hey! Ready to learn together?'**
  String get aiTutorHomeGreetingDefault;

  /// No description provided for @aiTutorHomeTodaysPlan.
  ///
  /// In en, this message translates to:
  /// **'Today\'s plan'**
  String get aiTutorHomeTodaysPlan;

  /// No description provided for @aiTutorHomePlanEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plan for today — start a chat to begin.'**
  String get aiTutorHomePlanEmpty;

  /// No description provided for @aiTutorHomeStartChat.
  ///
  /// In en, this message translates to:
  /// **'Start chat'**
  String get aiTutorHomeStartChat;

  /// No description provided for @aiTutorHomeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get aiTutorHomeRecent;

  /// No description provided for @aiTutorHomePracticeScenarios.
  ///
  /// In en, this message translates to:
  /// **'Practice scenarios'**
  String get aiTutorHomePracticeScenarios;

  /// No description provided for @aiTutorHomePracticeScenariosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Roleplay real-world conversations — restaurant, interview, hotel…'**
  String get aiTutorHomePracticeScenariosSubtitle;

  /// No description provided for @aiTutorHomeReadStory.
  ///
  /// In en, this message translates to:
  /// **'Read a story'**
  String get aiTutorHomeReadStory;

  /// No description provided for @aiTutorHomeReadStorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI writes a short story using your vocab — with quick comprehension checks.'**
  String get aiTutorHomeReadStorySubtitle;

  /// No description provided for @aiTutorHomeDescribePhoto.
  ///
  /// In en, this message translates to:
  /// **'Describe a photo'**
  String get aiTutorHomeDescribePhoto;

  /// No description provided for @aiTutorHomeDescribePhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Snap a picture and describe it — AI grades your vocab + grammar.'**
  String get aiTutorHomeDescribePhotoSubtitle;

  /// No description provided for @aiTutorChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with tutor'**
  String get aiTutorChatTitle;

  /// No description provided for @aiTutorChatVoiceOn.
  ///
  /// In en, this message translates to:
  /// **'Voice on'**
  String get aiTutorChatVoiceOn;

  /// No description provided for @aiTutorChatVoiceOff.
  ///
  /// In en, this message translates to:
  /// **'Voice off'**
  String get aiTutorChatVoiceOff;

  /// No description provided for @aiTutorChatStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get aiTutorChatStopRecording;

  /// No description provided for @aiTutorChatHoldToTalk.
  ///
  /// In en, this message translates to:
  /// **'Hold to talk'**
  String get aiTutorChatHoldToTalk;

  /// No description provided for @aiTutorChatTranscribing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing…'**
  String get aiTutorChatTranscribing;

  /// No description provided for @aiTutorChatListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get aiTutorChatListening;

  /// No description provided for @aiTutorChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get aiTutorChatInputHint;

  /// No description provided for @aiTutorChatTypeReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Type your reply…'**
  String get aiTutorChatTypeReplyHint;

  /// No description provided for @aiTutorChatMicPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission needed for voice mode.'**
  String get aiTutorChatMicPermissionDenied;

  /// No description provided for @aiTutorChatTranscribeFailed.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t catch that — try again.'**
  String get aiTutorChatTranscribeFailed;

  /// No description provided for @aiTutorChatStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start: {error}'**
  String aiTutorChatStartFailed(String error);

  /// No description provided for @aiTutorRoleplayEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get aiTutorRoleplayEnd;

  /// No description provided for @aiTutorRoleplayEndFailed.
  ///
  /// In en, this message translates to:
  /// **'End failed: {error}'**
  String aiTutorRoleplayEndFailed(String error);

  /// No description provided for @aiTutorRoleplayDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get aiTutorRoleplayDone;

  /// No description provided for @aiTutorStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Read a story'**
  String get aiTutorStoryTitle;

  /// No description provided for @aiTutorStoryLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get aiTutorStoryLength;

  /// No description provided for @aiTutorStoryTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get aiTutorStoryTheme;

  /// No description provided for @aiTutorStoryWordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String aiTutorStoryWordCount(int count);

  /// No description provided for @aiTutorStoryWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing…'**
  String get aiTutorStoryWriting;

  /// No description provided for @aiTutorStoryGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate story'**
  String get aiTutorStoryGenerate;

  /// No description provided for @aiTutorStoryGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate: {error}'**
  String aiTutorStoryGenerateFailed(String error);

  /// No description provided for @aiTutorStoryWordCountHint.
  ///
  /// In en, this message translates to:
  /// **'The AI will use up to {n} words from your vocab list.'**
  String aiTutorStoryWordCountHint(int n);

  /// No description provided for @aiTutorStoryThemeFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get aiTutorStoryThemeFree;

  /// No description provided for @aiTutorStoryThemeAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get aiTutorStoryThemeAdventure;

  /// No description provided for @aiTutorStoryThemeMystery.
  ///
  /// In en, this message translates to:
  /// **'Mystery'**
  String get aiTutorStoryThemeMystery;

  /// No description provided for @aiTutorStoryThemeRomance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get aiTutorStoryThemeRomance;

  /// No description provided for @aiTutorStoryThemeSciFi.
  ///
  /// In en, this message translates to:
  /// **'Sci-fi'**
  String get aiTutorStoryThemeSciFi;

  /// No description provided for @aiTutorStoryThemeSliceOfLife.
  ///
  /// In en, this message translates to:
  /// **'Slice of life'**
  String get aiTutorStoryThemeSliceOfLife;

  /// No description provided for @aiTutorStoryReaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get aiTutorStoryReaderTitle;

  /// No description provided for @aiTutorStoryReaderVocab.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get aiTutorStoryReaderVocab;

  /// No description provided for @aiTutorStoryReaderVocabUsed.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary used'**
  String get aiTutorStoryReaderVocabUsed;

  /// No description provided for @aiTutorStoryReaderPart.
  ///
  /// In en, this message translates to:
  /// **'Part {n}'**
  String aiTutorStoryReaderPart(int n);

  /// No description provided for @aiTutorStoryReaderWrongHint.
  ///
  /// In en, this message translates to:
  /// **'Not quite — moving on'**
  String get aiTutorStoryReaderWrongHint;

  /// No description provided for @aiTutorStoryReaderNiceWork.
  ///
  /// In en, this message translates to:
  /// **'Nice work!'**
  String get aiTutorStoryReaderNiceWork;

  /// No description provided for @aiTutorStoryReaderScore.
  ///
  /// In en, this message translates to:
  /// **'You got {correct}/{total} comprehension questions right.'**
  String aiTutorStoryReaderScore(int correct, int total);

  /// No description provided for @aiTutorStoryReaderDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get aiTutorStoryReaderDone;

  /// No description provided for @aiTutorImageVocabTitle.
  ///
  /// In en, this message translates to:
  /// **'Describe a photo'**
  String get aiTutorImageVocabTitle;

  /// No description provided for @aiTutorImagePickHeader.
  ///
  /// In en, this message translates to:
  /// **'Pick a photo to describe'**
  String get aiTutorImagePickHeader;

  /// No description provided for @aiTutorImagePickSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The AI will give you a prompt in your target language, then grade your description.'**
  String get aiTutorImagePickSubtitle;

  /// No description provided for @aiTutorImagePickCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get aiTutorImagePickCamera;

  /// No description provided for @aiTutorImagePickGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get aiTutorImagePickGallery;

  /// No description provided for @aiTutorImagePickError.
  ///
  /// In en, this message translates to:
  /// **'Could not open image: {error}'**
  String aiTutorImagePickError(String error);

  /// No description provided for @aiTutorImageDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Type your description…'**
  String get aiTutorImageDescriptionHint;

  /// No description provided for @aiTutorImageDifferentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Different photo'**
  String get aiTutorImageDifferentPhoto;

  /// No description provided for @aiTutorImageSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get aiTutorImageSubmit;

  /// No description provided for @aiTutorImageGrammarNotes.
  ///
  /// In en, this message translates to:
  /// **'Grammar notes'**
  String get aiTutorImageGrammarNotes;

  /// No description provided for @aiTutorImageThingsYouMissed.
  ///
  /// In en, this message translates to:
  /// **'Things you missed'**
  String get aiTutorImageThingsYouMissed;

  /// No description provided for @aiTutorImageTryAnother.
  ///
  /// In en, this message translates to:
  /// **'Try another photo'**
  String get aiTutorImageTryAnother;

  /// No description provided for @aiTutorCardQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get aiTutorCardQuiz;

  /// No description provided for @aiTutorCardVocab.
  ///
  /// In en, this message translates to:
  /// **'Vocab'**
  String get aiTutorCardVocab;

  /// No description provided for @aiTutorCardGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get aiTutorCardGrammar;

  /// No description provided for @aiTutorCardReviewDue.
  ///
  /// In en, this message translates to:
  /// **'Review due'**
  String get aiTutorCardReviewDue;

  /// No description provided for @aiTutorCardMiniLesson.
  ///
  /// In en, this message translates to:
  /// **'Mini-lesson'**
  String get aiTutorCardMiniLesson;

  /// No description provided for @aiTutorCardAddToVocab.
  ///
  /// In en, this message translates to:
  /// **'Add to vocab'**
  String get aiTutorCardAddToVocab;

  /// No description provided for @aiTutorCardAddedToVocab.
  ///
  /// In en, this message translates to:
  /// **'Added to vocab'**
  String get aiTutorCardAddedToVocab;

  /// No description provided for @aiTutorCardAdding.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get aiTutorCardAdding;

  /// No description provided for @aiTutorCardReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} card waiting for you} other{{count} cards waiting for you}}'**
  String aiTutorCardReviewCount(int count);

  /// No description provided for @aiTutorCardReviewNow.
  ///
  /// In en, this message translates to:
  /// **'Review now'**
  String get aiTutorCardReviewNow;

  /// No description provided for @aiTutorCardReviewStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get aiTutorCardReviewStarting;

  /// No description provided for @aiTutorCardTryIt.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get aiTutorCardTryIt;

  /// No description provided for @aiTutorCardPracticing.
  ///
  /// In en, this message translates to:
  /// **'Practicing…'**
  String get aiTutorCardPracticing;

  /// No description provided for @aiTutorPlanSrsReview.
  ///
  /// In en, this message translates to:
  /// **'Review {count} SRS cards ({done} done)'**
  String aiTutorPlanSrsReview(int count, int done);

  /// No description provided for @aiTutorPlanGrammar.
  ///
  /// In en, this message translates to:
  /// **'Practice: {topic}'**
  String aiTutorPlanGrammar(String topic);

  /// No description provided for @aiTutorPlanChat.
  ///
  /// In en, this message translates to:
  /// **'Chat for {min} min ({done} so far)'**
  String aiTutorPlanChat(int min, int done);

  /// No description provided for @aboutBananatalk.
  ///
  /// In en, this message translates to:
  /// **'About Bananatalk'**
  String get aboutBananatalk;

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
  /// **'Bananatalk'**
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

  /// No description provided for @receiveEmailNotificationsFromBananatalk.
  ///
  /// In en, this message translates to:
  /// **'Receive email notifications from Bananatalk'**
  String get receiveEmailNotificationsFromBananatalk;

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
  /// **'Exchange 5+ messages before calling'**
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
  /// **'Delete Highlight'**
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
  /// **'Leave Room'**
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
  /// **'Check out this story on Bananatalk!'**
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
  /// **'Receive email notifications from Bananatalk'**
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
  /// **'Choose from Gallery'**
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
  /// **'Try again later'**
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
  /// **'Check out this moment on Bananatalk!'**
  String get checkOutMoment;

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
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @elementary.
  ///
  /// In en, this message translates to:
  /// **'Elementary'**
  String get elementary;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @upperIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Upper Intermediate'**
  String get upperIntermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @proficient.
  ///
  /// In en, this message translates to:
  /// **'Proficient'**
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

  /// No description provided for @requiredUpTo6Photos.
  ///
  /// In en, this message translates to:
  /// **'Required — up to 6 photos'**
  String get requiredUpTo6Photos;

  /// No description provided for @profilePhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one profile photo'**
  String get profilePhotoRequired;

  /// No description provided for @locationOptional.
  ///
  /// In en, this message translates to:
  /// **'Please set your location to continue'**
  String get locationOptional;

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
  /// **'Required — helps match you with partners nearby'**
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

  /// Placeholder for the confirm-new-password field
  ///
  /// In en, this message translates to:
  /// **'Re-enter the new password'**
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

  /// No description provided for @incomingAudioCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming Audio Call'**
  String get incomingAudioCall;

  /// No description provided for @incomingVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming Video Call'**
  String get incomingVideoCall;

  /// No description provided for @outgoingCall.
  ///
  /// In en, this message translates to:
  /// **'Calling...'**
  String get outgoingCall;

  /// No description provided for @callRinging.
  ///
  /// In en, this message translates to:
  /// **'Ringing...'**
  String get callRinging;

  /// No description provided for @callConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get callConnecting;

  /// No description provided for @callConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get callConnected;

  /// No description provided for @callReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get callReconnecting;

  /// No description provided for @callEnded.
  ///
  /// In en, this message translates to:
  /// **'Call Ended'**
  String get callEnded;

  /// No description provided for @callFailed.
  ///
  /// In en, this message translates to:
  /// **'Call Failed'**
  String get callFailed;

  /// No description provided for @callMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed Call'**
  String get callMissed;

  /// No description provided for @callDeclined.
  ///
  /// In en, this message translates to:
  /// **'Call Declined'**
  String get callDeclined;

  /// No description provided for @callDuration.
  ///
  /// In en, this message translates to:
  /// **'{duration}'**
  String callDuration(String duration);

  /// No description provided for @acceptCall.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptCall;

  /// No description provided for @declineCall.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineCall;

  /// No description provided for @endCall.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endCall;

  /// No description provided for @muteCall.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get muteCall;

  /// No description provided for @unmuteCall.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmuteCall;

  /// No description provided for @speakerOn.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speakerOn;

  /// No description provided for @speakerOff.
  ///
  /// In en, this message translates to:
  /// **'Earpiece'**
  String get speakerOff;

  /// No description provided for @videoOn.
  ///
  /// In en, this message translates to:
  /// **'Video On'**
  String get videoOn;

  /// No description provided for @videoOff.
  ///
  /// In en, this message translates to:
  /// **'Video Off'**
  String get videoOff;

  /// No description provided for @switchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch Camera'**
  String get switchCamera;

  /// No description provided for @callPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for calls'**
  String get callPermissionDenied;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required for video calls'**
  String get cameraPermissionDenied;

  /// No description provided for @callConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Please try again.'**
  String get callConnectionFailed;

  /// No description provided for @userBusy.
  ///
  /// In en, this message translates to:
  /// **'User is busy'**
  String get userBusy;

  /// No description provided for @userOffline.
  ///
  /// In en, this message translates to:
  /// **'User is offline'**
  String get userOffline;

  /// No description provided for @callHistory.
  ///
  /// In en, this message translates to:
  /// **'Call History'**
  String get callHistory;

  /// No description provided for @noCallHistory.
  ///
  /// In en, this message translates to:
  /// **'No call history'**
  String get noCallHistory;

  /// No description provided for @missedCalls.
  ///
  /// In en, this message translates to:
  /// **'Missed Calls'**
  String get missedCalls;

  /// No description provided for @allCalls.
  ///
  /// In en, this message translates to:
  /// **'All Calls'**
  String get allCalls;

  /// No description provided for @callBack.
  ///
  /// In en, this message translates to:
  /// **'Call Back'**
  String get callBack;

  /// No description provided for @callAt.
  ///
  /// In en, this message translates to:
  /// **'Call at {time}'**
  String callAt(String time);

  /// No description provided for @audioCall.
  ///
  /// In en, this message translates to:
  /// **'Audio Call'**
  String get audioCall;

  /// No description provided for @voiceRoom.
  ///
  /// In en, this message translates to:
  /// **'Voice Room'**
  String get voiceRoom;

  /// No description provided for @noVoiceRooms.
  ///
  /// In en, this message translates to:
  /// **'No voice rooms active'**
  String get noVoiceRooms;

  /// No description provided for @createVoiceRoom.
  ///
  /// In en, this message translates to:
  /// **'Create Voice Room'**
  String get createVoiceRoom;

  /// No description provided for @joinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join Room'**
  String get joinRoom;

  /// No description provided for @leaveRoomConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave Room?'**
  String get leaveRoomConfirm;

  /// No description provided for @leaveRoomMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this room?'**
  String get leaveRoomMessage;

  /// No description provided for @roomTitle.
  ///
  /// In en, this message translates to:
  /// **'Room Title'**
  String get roomTitle;

  /// No description provided for @roomTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter room title'**
  String get roomTitleHint;

  /// No description provided for @roomTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get roomTopic;

  /// No description provided for @roomLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get roomLanguage;

  /// No description provided for @roomHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get roomHost;

  /// No description provided for @roomParticipants.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String roomParticipants(int count);

  /// No description provided for @roomMaxParticipants.
  ///
  /// In en, this message translates to:
  /// **'Max {count} participants'**
  String roomMaxParticipants(int count);

  /// No description provided for @selectTopic.
  ///
  /// In en, this message translates to:
  /// **'Select Topic'**
  String get selectTopic;

  /// No description provided for @raiseHand.
  ///
  /// In en, this message translates to:
  /// **'Raise Hand'**
  String get raiseHand;

  /// No description provided for @lowerHand.
  ///
  /// In en, this message translates to:
  /// **'Lower Hand'**
  String get lowerHand;

  /// No description provided for @handRaisedNotification.
  ///
  /// In en, this message translates to:
  /// **'Hand raised! The host will see your request.'**
  String get handRaisedNotification;

  /// No description provided for @handLoweredNotification.
  ///
  /// In en, this message translates to:
  /// **'Hand lowered'**
  String get handLoweredNotification;

  /// No description provided for @muteParticipant.
  ///
  /// In en, this message translates to:
  /// **'Mute Participant'**
  String get muteParticipant;

  /// No description provided for @kickParticipant.
  ///
  /// In en, this message translates to:
  /// **'Remove from Room'**
  String get kickParticipant;

  /// No description provided for @promoteToCoHost.
  ///
  /// In en, this message translates to:
  /// **'Make Co-Host'**
  String get promoteToCoHost;

  /// No description provided for @endRoomConfirm.
  ///
  /// In en, this message translates to:
  /// **'End Room?'**
  String get endRoomConfirm;

  /// No description provided for @endRoomMessage.
  ///
  /// In en, this message translates to:
  /// **'This will end the room for all participants.'**
  String get endRoomMessage;

  /// No description provided for @roomEnded.
  ///
  /// In en, this message translates to:
  /// **'Room ended by host'**
  String get roomEnded;

  /// No description provided for @youWereRemoved.
  ///
  /// In en, this message translates to:
  /// **'You were removed from the room'**
  String get youWereRemoved;

  /// No description provided for @roomIsFull.
  ///
  /// In en, this message translates to:
  /// **'Room is full'**
  String get roomIsFull;

  /// No description provided for @roomChat.
  ///
  /// In en, this message translates to:
  /// **'Room Chat'**
  String get roomChat;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @voiceRoomsDescription.
  ///
  /// In en, this message translates to:
  /// **'Join live conversations and practice speaking'**
  String get voiceRoomsDescription;

  /// No description provided for @liveRoomsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Live'**
  String liveRoomsCount(int count);

  /// No description provided for @noActiveRooms.
  ///
  /// In en, this message translates to:
  /// **'No active rooms'**
  String get noActiveRooms;

  /// No description provided for @noActiveRoomsDescription.
  ///
  /// In en, this message translates to:
  /// **'Be the first to start a voice room and practice speaking with others!'**
  String get noActiveRoomsDescription;

  /// No description provided for @startRoom.
  ///
  /// In en, this message translates to:
  /// **'Start a Room'**
  String get startRoom;

  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Create Room'**
  String get createRoom;

  /// No description provided for @roomCreated.
  ///
  /// In en, this message translates to:
  /// **'Room created successfully!'**
  String get roomCreated;

  /// No description provided for @failedToCreateRoom.
  ///
  /// In en, this message translates to:
  /// **'Failed to create room'**
  String get failedToCreateRoom;

  /// No description provided for @errorLoadingRooms.
  ///
  /// In en, this message translates to:
  /// **'Error loading rooms'**
  String get errorLoadingRooms;

  /// No description provided for @pleaseEnterRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a room title'**
  String get pleaseEnterRoomTitle;

  /// No description provided for @startLiveConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a live conversation'**
  String get startLiveConversation;

  /// No description provided for @maxParticipants.
  ///
  /// In en, this message translates to:
  /// **'Max Participants'**
  String get maxParticipants;

  /// No description provided for @nPeople.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String nPeople(int count);

  /// No description provided for @hostedBy.
  ///
  /// In en, this message translates to:
  /// **'Hosted by {name}'**
  String hostedBy(String name);

  /// No description provided for @liveLabel.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveLabel;

  /// No description provided for @joinLabel.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinLabel;

  /// No description provided for @fullLabel.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get fullLabel;

  /// No description provided for @justStarted.
  ///
  /// In en, this message translates to:
  /// **'Just started'**
  String get justStarted;

  /// No description provided for @allLanguages.
  ///
  /// In en, this message translates to:
  /// **'All Languages'**
  String get allLanguages;

  /// No description provided for @allTopics.
  ///
  /// In en, this message translates to:
  /// **'All Topics'**
  String get allTopics;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @competeWithLearners.
  ///
  /// In en, this message translates to:
  /// **'Compete with other learners!'**
  String get competeWithLearners;

  /// No description provided for @xpRankings.
  ///
  /// In en, this message translates to:
  /// **'XP Rankings'**
  String get xpRankings;

  /// No description provided for @streaks.
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get streaks;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @myRanks.
  ///
  /// In en, this message translates to:
  /// **'My Ranks'**
  String get myRanks;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @longestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest Streak'**
  String get longestStreak;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yourRank.
  ///
  /// In en, this message translates to:
  /// **'Your Rank'**
  String get yourRank;

  /// No description provided for @outOf.
  ///
  /// In en, this message translates to:
  /// **'out of {total}'**
  String outOf(int total);

  /// No description provided for @topPercent.
  ///
  /// In en, this message translates to:
  /// **'Top {percent}%'**
  String topPercent(String percent);

  /// No description provided for @xpRank.
  ///
  /// In en, this message translates to:
  /// **'XP Rank'**
  String get xpRank;

  /// No description provided for @streakRank.
  ///
  /// In en, this message translates to:
  /// **'Streak Rank'**
  String get streakRank;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @learningStats.
  ///
  /// In en, this message translates to:
  /// **'Learning Stats'**
  String get learningStats;

  /// No description provided for @totalXp.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get totalXp;

  /// No description provided for @lessonsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Lessons Completed'**
  String get lessonsCompleted;

  /// No description provided for @rankings.
  ///
  /// In en, this message translates to:
  /// **'Rankings'**
  String get rankings;

  /// No description provided for @yourPosition.
  ///
  /// In en, this message translates to:
  /// **'Your Position'**
  String get yourPosition;

  /// No description provided for @keepLearning.
  ///
  /// In en, this message translates to:
  /// **'Keep learning to climb!'**
  String get keepLearning;

  /// No description provided for @noRankingsYet.
  ///
  /// In en, this message translates to:
  /// **'No rankings yet'**
  String get noRankingsYet;

  /// No description provided for @startLearningToAppear.
  ///
  /// In en, this message translates to:
  /// **'Start learning to appear on the leaderboard!'**
  String get startLearningToAppear;

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get noFriendsYet;

  /// No description provided for @addFriendsToCompete.
  ///
  /// In en, this message translates to:
  /// **'Add friends to compete with them!'**
  String get addFriendsToCompete;

  /// No description provided for @failedToLoadLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load leaderboard'**
  String get failedToLoadLeaderboard;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @findPartners.
  ///
  /// In en, this message translates to:
  /// **'Find Partners'**
  String get findPartners;

  /// No description provided for @discoverLanguagePartners.
  ///
  /// In en, this message translates to:
  /// **'Discover language partners'**
  String get discoverLanguagePartners;

  /// No description provided for @byLanguage.
  ///
  /// In en, this message translates to:
  /// **'By Language'**
  String get byLanguage;

  /// No description provided for @match.
  ///
  /// In en, this message translates to:
  /// **'match'**
  String get match;

  /// No description provided for @matchScore.
  ///
  /// In en, this message translates to:
  /// **'Match Score'**
  String get matchScore;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesFound;

  /// No description provided for @noUsersOnline.
  ///
  /// In en, this message translates to:
  /// **'No users online'**
  String get noUsersOnline;

  /// No description provided for @checkBackLater.
  ///
  /// In en, this message translates to:
  /// **'Check back later'**
  String get checkBackLater;

  /// No description provided for @selectLanguagePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a language'**
  String get selectLanguagePrompt;

  /// No description provided for @findPartnersByLanguage.
  ///
  /// In en, this message translates to:
  /// **'Find partners who speak or learn this language'**
  String get findPartnersByLanguage;

  /// No description provided for @noPartnersForLanguage.
  ///
  /// In en, this message translates to:
  /// **'No partners for {language}'**
  String noPartnersForLanguage(String language);

  /// No description provided for @tryAnotherLanguage.
  ///
  /// In en, this message translates to:
  /// **'Try selecting another language'**
  String get tryAnotherLanguage;

  /// No description provided for @failedToLoadMatches.
  ///
  /// In en, this message translates to:
  /// **'Failed to load matches'**
  String get failedToLoadMatches;

  /// No description provided for @dataAndStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get dataAndStorage;

  /// No description provided for @manageStorageAndDownloads.
  ///
  /// In en, this message translates to:
  /// **'Manage storage and downloads'**
  String get manageStorageAndDownloads;

  /// No description provided for @storageUsage.
  ///
  /// In en, this message translates to:
  /// **'Storage Usage'**
  String get storageUsage;

  /// No description provided for @totalCacheSize.
  ///
  /// In en, this message translates to:
  /// **'Total Cache Size'**
  String get totalCacheSize;

  /// No description provided for @imageCache.
  ///
  /// In en, this message translates to:
  /// **'Image Cache'**
  String get imageCache;

  /// No description provided for @voiceMessagesCache.
  ///
  /// In en, this message translates to:
  /// **'Voice Messages'**
  String get voiceMessagesCache;

  /// No description provided for @videoCache.
  ///
  /// In en, this message translates to:
  /// **'Video Cache'**
  String get videoCache;

  /// No description provided for @otherCache.
  ///
  /// In en, this message translates to:
  /// **'Other Cache'**
  String get otherCache;

  /// No description provided for @autoDownloadMedia.
  ///
  /// In en, this message translates to:
  /// **'Auto-Download Media'**
  String get autoDownloadMedia;

  /// No description provided for @currentNetwork.
  ///
  /// In en, this message translates to:
  /// **'Current Network'**
  String get currentNetwork;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @voiceMessagesShort.
  ///
  /// In en, this message translates to:
  /// **'Voice Messages'**
  String get voiceMessagesShort;

  /// No description provided for @documentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsLabel;

  /// No description provided for @wifiOnly.
  ///
  /// In en, this message translates to:
  /// **'WiFi Only'**
  String get wifiOnly;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @clearAllCache.
  ///
  /// In en, this message translates to:
  /// **'Clear All Cache'**
  String get clearAllCache;

  /// No description provided for @allCache.
  ///
  /// In en, this message translates to:
  /// **'All Cache'**
  String get allCache;

  /// No description provided for @clearAllCacheConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will clear all cached images, voice messages, videos, and other files. The app may load content slower temporarily.'**
  String get clearAllCacheConfirmation;

  /// No description provided for @clearCacheConfirmationFor.
  ///
  /// In en, this message translates to:
  /// **'Clear {category}?'**
  String clearCacheConfirmationFor(String category);

  /// No description provided for @storageToFree.
  ///
  /// In en, this message translates to:
  /// **'{size} will be freed'**
  String storageToFree(String size);

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @noDataToShow.
  ///
  /// In en, this message translates to:
  /// **'No data to show'**
  String get noDataToShow;

  /// No description provided for @profileCompletion.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get profileCompletion;

  /// No description provided for @justGettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Just getting started'**
  String get justGettingStarted;

  /// No description provided for @lookingGood.
  ///
  /// In en, this message translates to:
  /// **'Looking good!'**
  String get lookingGood;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get almostThere;

  /// No description provided for @addMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Add: {fields}'**
  String addMissingFields(String fields, Object field);

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePicture;

  /// No description provided for @nativeSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Native Speaker'**
  String get nativeSpeaker;

  /// No description provided for @peopleInterestedInTopic.
  ///
  /// In en, this message translates to:
  /// **'People interested in this topic'**
  String peopleInterestedInTopic(Object count);

  /// No description provided for @beFirstToAddTopic.
  ///
  /// In en, this message translates to:
  /// **'Be the first to add this topic to your interests!'**
  String get beFirstToAddTopic;

  /// No description provided for @recentMoments.
  ///
  /// In en, this message translates to:
  /// **'Recent Moments'**
  String get recentMoments;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @study.
  ///
  /// In en, this message translates to:
  /// **'AI Study'**
  String get study;

  /// No description provided for @followerMoments.
  ///
  /// In en, this message translates to:
  /// **'Follower Moments'**
  String get followerMoments;

  /// No description provided for @whenPeopleYouFollowPost.
  ///
  /// In en, this message translates to:
  /// **'When people you follow post new moments'**
  String get whenPeopleYouFollowPost;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @whenYouGetNotifications.
  ///
  /// In en, this message translates to:
  /// **'When you get notifications, they\'ll show up here'**
  String get whenYouGetNotifications;

  /// No description provided for @failedToLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedToLoadNotifications;

  /// No description provided for @clearAllNotificationsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all notifications? This cannot be undone.'**
  String get clearAllNotificationsConfirm;

  /// No description provided for @tapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get tapToChange;

  /// No description provided for @noPictureSet.
  ///
  /// In en, this message translates to:
  /// **'No picture set'**
  String get noPictureSet;

  /// No description provided for @nameAndGender.
  ///
  /// In en, this message translates to:
  /// **'Name & Gender'**
  String get nameAndGender;

  /// No description provided for @languageLevel.
  ///
  /// In en, this message translates to:
  /// **'Language Level'**
  String get languageLevel;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @mbti.
  ///
  /// In en, this message translates to:
  /// **'MBTI'**
  String get mbti;

  /// No description provided for @topicsOfInterest.
  ///
  /// In en, this message translates to:
  /// **'Topics of Interest'**
  String get topicsOfInterest;

  /// No description provided for @levelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelBeginner;

  /// No description provided for @levelElementary.
  ///
  /// In en, this message translates to:
  /// **'Elementary'**
  String get levelElementary;

  /// No description provided for @levelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelIntermediate;

  /// No description provided for @levelUpperIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Upper Intermediate'**
  String get levelUpperIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get levelAdvanced;

  /// No description provided for @levelProficient.
  ///
  /// In en, this message translates to:
  /// **'Proficient'**
  String get levelProficient;

  /// No description provided for @selectYourLevel.
  ///
  /// In en, this message translates to:
  /// **'Select Your Level'**
  String get selectYourLevel;

  /// No description provided for @howWellDoYouSpeak.
  ///
  /// In en, this message translates to:
  /// **'How well do you speak {language}?'**
  String howWellDoYouSpeak(String language);

  /// No description provided for @theLanguage.
  ///
  /// In en, this message translates to:
  /// **'the language'**
  String get theLanguage;

  /// No description provided for @languageLevelSetTo.
  ///
  /// In en, this message translates to:
  /// **'Language level set to {level}'**
  String languageLevelSetTo(String level);

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get failedToUpdate;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @genderRequired.
  ///
  /// In en, this message translates to:
  /// **'Gender (Required)'**
  String get genderRequired;

  /// No description provided for @editHometown.
  ///
  /// In en, this message translates to:
  /// **'Edit Hometown'**
  String get editHometown;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @detecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting...'**
  String get detecting;

  /// No description provided for @getCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Get Current Location'**
  String get getCurrentLocation;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @noLocationDetectedYet.
  ///
  /// In en, this message translates to:
  /// **'No location detected yet.'**
  String get noLocationDetectedYet;

  /// No description provided for @detected.
  ///
  /// In en, this message translates to:
  /// **'Detected'**
  String get detected;

  /// No description provided for @savedHometown.
  ///
  /// In en, this message translates to:
  /// **'Saved hometown'**
  String get savedHometown;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them.'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied.'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @editBio.
  ///
  /// In en, this message translates to:
  /// **'Edit Bio'**
  String get editBio;

  /// No description provided for @bioUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Bio updated successfully'**
  String get bioUpdatedSuccessfully;

  /// No description provided for @tellOthersAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell others about yourself...'**
  String get tellOthersAboutYourself;

  /// No description provided for @charactersCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/500 characters'**
  String charactersCount(int count);

  /// No description provided for @selectYourMbti.
  ///
  /// In en, this message translates to:
  /// **'Select Your MBTI'**
  String get selectYourMbti;

  /// No description provided for @myBloodType.
  ///
  /// In en, this message translates to:
  /// **'My Blood Type'**
  String get myBloodType;

  /// No description provided for @pleaseSelectABloodType.
  ///
  /// In en, this message translates to:
  /// **'Please select a blood type'**
  String get pleaseSelectABloodType;

  /// No description provided for @bloodTypeSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Blood type saved successfully'**
  String get bloodTypeSavedSuccessfully;

  /// No description provided for @hometownSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Hometown saved successfully'**
  String get hometownSavedSuccessfully;

  /// No description provided for @nativeLanguageRequired.
  ///
  /// In en, this message translates to:
  /// **'Native Language (Required)'**
  String get nativeLanguageRequired;

  /// No description provided for @languageToLearnRequired.
  ///
  /// In en, this message translates to:
  /// **'Language to Learn (Required)'**
  String get languageToLearnRequired;

  /// No description provided for @nativeLanguageCannotBeSame.
  ///
  /// In en, this message translates to:
  /// **'Native language cannot be the same as the language you\'re learning'**
  String get nativeLanguageCannotBeSame;

  /// No description provided for @learningLanguageCannotBeSame.
  ///
  /// In en, this message translates to:
  /// **'Learning language cannot be the same as your native language'**
  String get learningLanguageCannotBeSame;

  /// No description provided for @pleaseSelectALanguage.
  ///
  /// In en, this message translates to:
  /// **'Please select a language'**
  String get pleaseSelectALanguage;

  /// No description provided for @editInterests.
  ///
  /// In en, this message translates to:
  /// **'Edit Interests'**
  String get editInterests;

  /// No description provided for @maxTopicsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum {count} topics allowed'**
  String maxTopicsAllowed(int count);

  /// No description provided for @topicsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Topics updated successfully!'**
  String get topicsUpdatedSuccessfully;

  /// No description provided for @failedToUpdateTopics.
  ///
  /// In en, this message translates to:
  /// **'Failed to update topics'**
  String get failedToUpdateTopics;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} selected'**
  String selectedCount(int count, int max);

  /// No description provided for @profilePictures.
  ///
  /// In en, this message translates to:
  /// **'Profile Pictures'**
  String get profilePictures;

  /// No description provided for @addImages.
  ///
  /// In en, this message translates to:
  /// **'Add Images'**
  String get addImages;

  /// No description provided for @selectUpToImages.
  ///
  /// In en, this message translates to:
  /// **'Select up to 5 images'**
  String get selectUpToImages;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takeAPhoto;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get removeImage;

  /// No description provided for @removeImageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this image?'**
  String get removeImageConfirm;

  /// No description provided for @removeAll.
  ///
  /// In en, this message translates to:
  /// **'Remove All'**
  String get removeAll;

  /// No description provided for @removeAllSelectedImages.
  ///
  /// In en, this message translates to:
  /// **'Remove All Selected Images'**
  String get removeAllSelectedImages;

  /// No description provided for @removeAllSelectedImagesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all selected images?'**
  String get removeAllSelectedImagesConfirm;

  /// No description provided for @yourProfilePictureWillBeKept.
  ///
  /// In en, this message translates to:
  /// **'Your existing profile picture will be kept'**
  String get yourProfilePictureWillBeKept;

  /// No description provided for @removeAllImages.
  ///
  /// In en, this message translates to:
  /// **'Remove All Images'**
  String get removeAllImages;

  /// No description provided for @removeAllImagesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all profile pictures?'**
  String get removeAllImagesConfirm;

  /// No description provided for @currentImages.
  ///
  /// In en, this message translates to:
  /// **'Current Images'**
  String get currentImages;

  /// No description provided for @newImages.
  ///
  /// In en, this message translates to:
  /// **'New Images'**
  String get newImages;

  /// No description provided for @addMoreImages.
  ///
  /// In en, this message translates to:
  /// **'Add More Images'**
  String get addMoreImages;

  /// No description provided for @uploadImages.
  ///
  /// In en, this message translates to:
  /// **'Upload {count} Image(s)'**
  String uploadImages(int count);

  /// No description provided for @imageRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image removed successfully'**
  String get imageRemovedSuccessfully;

  /// No description provided for @imagesUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Images uploaded successfully'**
  String get imagesUploadedSuccessfully;

  /// No description provided for @selectedImagesCleared.
  ///
  /// In en, this message translates to:
  /// **'Selected images cleared'**
  String get selectedImagesCleared;

  /// No description provided for @extraImagesRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Extra images removed successfully'**
  String get extraImagesRemovedSuccessfully;

  /// No description provided for @mustKeepAtLeastOneProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'You must keep at least one profile picture'**
  String get mustKeepAtLeastOneProfilePicture;

  /// No description provided for @noProfilePicturesToRemove.
  ///
  /// In en, this message translates to:
  /// **'No profile pictures to remove'**
  String get noProfilePicturesToRemove;

  /// No description provided for @authenticationTokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Authentication token not found'**
  String get authenticationTokenNotFound;

  /// No description provided for @saveChangesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Save Changes?'**
  String get saveChangesQuestion;

  /// No description provided for @youHaveUnuploadedImages.
  ///
  /// In en, this message translates to:
  /// **'You have {count} image(s) selected but not uploaded. Do you want to upload them now?'**
  String youHaveUnuploadedImages(int count);

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @maxImagesInfo.
  ///
  /// In en, this message translates to:
  /// **'You can upload up to {max} images. Currently: {current}/{max}\nMax 5 images per upload.'**
  String maxImagesInfo(int max, int current);

  /// No description provided for @canOnlyAddMoreImages.
  ///
  /// In en, this message translates to:
  /// **'You can only add {count} more image(s). Maximum is {max} images total.'**
  String canOnlyAddMoreImages(int count, int max);

  /// No description provided for @maxImagesPerUpload.
  ///
  /// In en, this message translates to:
  /// **'You can upload maximum 5 images at once. Only first 5 will be added.'**
  String get maxImagesPerUpload;

  /// No description provided for @canOnlyHaveMaxImages.
  ///
  /// In en, this message translates to:
  /// **'You can only have up to {max} images'**
  String canOnlyHaveMaxImages(int max);

  /// No description provided for @imageSizeExceedsLimit.
  ///
  /// In en, this message translates to:
  /// **'Image size exceeds 10MB limit'**
  String get imageSizeExceedsLimit;

  /// No description provided for @unsupportedImageFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported image format'**
  String get unsupportedImageFormat;

  /// No description provided for @pleaseSelectAtLeastOneImage.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one image to upload'**
  String get pleaseSelectAtLeastOneImage;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @languageToLearn.
  ///
  /// In en, this message translates to:
  /// **'Language to Learn'**
  String get languageToLearn;

  /// No description provided for @hometown.
  ///
  /// In en, this message translates to:
  /// **'Hometown'**
  String get hometown;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'characters'**
  String get characters;

  /// No description provided for @failedToLoadLanguages.
  ///
  /// In en, this message translates to:
  /// **'Failed to load languages'**
  String get failedToLoadLanguages;

  /// No description provided for @studyHub.
  ///
  /// In en, this message translates to:
  /// **'Study Hub'**
  String get studyHub;

  /// No description provided for @dailyLearningJourney.
  ///
  /// In en, this message translates to:
  /// **'Your daily learning journey'**
  String get dailyLearningJourney;

  /// No description provided for @learnTab.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learnTab;

  /// No description provided for @aiTools.
  ///
  /// In en, this message translates to:
  /// **'AI Tools'**
  String get aiTools;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @lessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessons;

  /// No description provided for @words.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get words;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @wordsDue.
  ///
  /// In en, this message translates to:
  /// **'{count} words due'**
  String wordsDue(int count);

  /// No description provided for @addWords.
  ///
  /// In en, this message translates to:
  /// **'Add Words'**
  String get addWords;

  /// No description provided for @buildVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Build vocabulary'**
  String get buildVocabulary;

  /// No description provided for @practiceWithAI.
  ///
  /// In en, this message translates to:
  /// **'Practice with AI'**
  String get practiceWithAI;

  /// No description provided for @aiPracticeDescription.
  ///
  /// In en, this message translates to:
  /// **'Chat, quiz, grammar & pronunciation'**
  String get aiPracticeDescription;

  /// No description provided for @dailyChallenges.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenges'**
  String get dailyChallenges;

  /// No description provided for @allChallengesCompleted.
  ///
  /// In en, this message translates to:
  /// **'All challenges completed!'**
  String get allChallengesCompleted;

  /// No description provided for @continueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue Learning'**
  String get continueLearning;

  /// No description provided for @structuredLearningPath.
  ///
  /// In en, this message translates to:
  /// **'Structured learning path'**
  String get structuredLearningPath;

  /// No description provided for @vocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabulary;

  /// No description provided for @yourWordCollection.
  ///
  /// In en, this message translates to:
  /// **'Your word collection'**
  String get yourWordCollection;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @badgesAndMilestones.
  ///
  /// In en, this message translates to:
  /// **'Badges and milestones'**
  String get badgesAndMilestones;

  /// No description provided for @failedToLoadLearningData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load learning data'**
  String get failedToLoadLearningData;

  /// No description provided for @startYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Start your journey!'**
  String get startYourJourney;

  /// No description provided for @startJourneyDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete lessons, build vocabulary, and\ntrack your progress'**
  String get startJourneyDescription;

  /// No description provided for @levelN.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelN(int level);

  /// No description provided for @xpEarned.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP earned'**
  String xpEarned(int xp);

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next: Level {level}'**
  String nextLevel(int level);

  /// No description provided for @xpToGo.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to go'**
  String xpToGo(int xp);

  /// No description provided for @aiConversationPartner.
  ///
  /// In en, this message translates to:
  /// **'AI Conversation Partner'**
  String get aiConversationPartner;

  /// No description provided for @practiceWithAITutor.
  ///
  /// In en, this message translates to:
  /// **'Practice speaking with your AI tutor'**
  String get practiceWithAITutor;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start Conversation'**
  String get startConversation;

  /// No description provided for @aiFeatures.
  ///
  /// In en, this message translates to:
  /// **'AI Features'**
  String get aiFeatures;

  /// No description provided for @aiLessons.
  ///
  /// In en, this message translates to:
  /// **'AI Lessons'**
  String get aiLessons;

  /// No description provided for @learnWithAI.
  ///
  /// In en, this message translates to:
  /// **'Learn with AI'**
  String get learnWithAI;

  /// No description provided for @grammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get grammar;

  /// No description provided for @checkWriting.
  ///
  /// In en, this message translates to:
  /// **'Check writing'**
  String get checkWriting;

  /// No description provided for @pronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get pronunciation;

  /// No description provided for @improveSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Improve speaking'**
  String get improveSpeaking;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @smartTranslate.
  ///
  /// In en, this message translates to:
  /// **'Smart translate'**
  String get smartTranslate;

  /// No description provided for @aiQuizzes.
  ///
  /// In en, this message translates to:
  /// **'AI Quizzes'**
  String get aiQuizzes;

  /// No description provided for @testKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Test knowledge'**
  String get testKnowledge;

  /// No description provided for @lessonBuilder.
  ///
  /// In en, this message translates to:
  /// **'Lesson Builder'**
  String get lessonBuilder;

  /// No description provided for @customLessons.
  ///
  /// In en, this message translates to:
  /// **'Custom lessons'**
  String get customLessons;

  /// No description provided for @yourAIProgress.
  ///
  /// In en, this message translates to:
  /// **'Your AI Progress'**
  String get yourAIProgress;

  /// No description provided for @quizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizzes;

  /// No description provided for @avgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg Score'**
  String get avgScore;

  /// No description provided for @focusAreas.
  ///
  /// In en, this message translates to:
  /// **'Focus Areas'**
  String get focusAreas;

  /// No description provided for @accuracyPercent.
  ///
  /// In en, this message translates to:
  /// **'{accuracy}% accuracy'**
  String accuracyPercent(String accuracy);

  /// No description provided for @practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @noRecommendedLessons.
  ///
  /// In en, this message translates to:
  /// **'No recommended lessons available'**
  String get noRecommendedLessons;

  /// No description provided for @noLessonsFound.
  ///
  /// In en, this message translates to:
  /// **'No lessons found'**
  String get noLessonsFound;

  /// No description provided for @createCustomLessonDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your own custom lesson with AI'**
  String get createCustomLessonDescription;

  /// No description provided for @createLessonWithAI.
  ///
  /// In en, this message translates to:
  /// **'Create Lesson with AI'**
  String get createLessonWithAI;

  /// No description provided for @allLevels.
  ///
  /// In en, this message translates to:
  /// **'All Levels'**
  String get allLevels;

  /// No description provided for @levelA1.
  ///
  /// In en, this message translates to:
  /// **'A1 Beginner'**
  String get levelA1;

  /// No description provided for @levelA2.
  ///
  /// In en, this message translates to:
  /// **'A2 Elementary'**
  String get levelA2;

  /// No description provided for @levelB1.
  ///
  /// In en, this message translates to:
  /// **'B1 Intermediate'**
  String get levelB1;

  /// No description provided for @levelB2.
  ///
  /// In en, this message translates to:
  /// **'B2 Upper-Int'**
  String get levelB2;

  /// No description provided for @levelC1.
  ///
  /// In en, this message translates to:
  /// **'C1 Advanced'**
  String get levelC1;

  /// No description provided for @levelC2.
  ///
  /// In en, this message translates to:
  /// **'C2 Proficient'**
  String get levelC2;

  /// No description provided for @failedToLoadLessons.
  ///
  /// In en, this message translates to:
  /// **'Failed to load lessons'**
  String get failedToLoadLessons;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get editMessage;

  /// No description provided for @enterMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter message...'**
  String get enterMessage;

  /// No description provided for @deleteMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get deleteMessageTitle;

  /// No description provided for @actionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get actionCannotBeUndone;

  /// No description provided for @onlyRemovesFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Only removes from your device'**
  String get onlyRemovesFromDevice;

  /// No description provided for @availableWithinOneHour.
  ///
  /// In en, this message translates to:
  /// **'Only available within 1 hour'**
  String get availableWithinOneHour;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @forwardMessage.
  ///
  /// In en, this message translates to:
  /// **'Forward Message'**
  String get forwardMessage;

  /// No description provided for @selectUsersToForward.
  ///
  /// In en, this message translates to:
  /// **'Select users to forward to:'**
  String get selectUsersToForward;

  /// No description provided for @forwardCount.
  ///
  /// In en, this message translates to:
  /// **'Forward ({count})'**
  String forwardCount(int count);

  /// No description provided for @pinnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Pinned Message'**
  String get pinnedMessage;

  /// No description provided for @photoMedia.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photoMedia;

  /// No description provided for @videoMedia.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoMedia;

  /// No description provided for @voiceMessageMedia.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get voiceMessageMedia;

  /// No description provided for @documentMedia.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentMedia;

  /// No description provided for @locationMedia.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationMedia;

  /// No description provided for @stickerMedia.
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get stickerMedia;

  /// No description provided for @smileys.
  ///
  /// In en, this message translates to:
  /// **'Smileys'**
  String get smileys;

  /// No description provided for @emotions.
  ///
  /// In en, this message translates to:
  /// **'Emotions'**
  String get emotions;

  /// No description provided for @handGestures.
  ///
  /// In en, this message translates to:
  /// **'Hand Gestures'**
  String get handGestures;

  /// No description provided for @hearts.
  ///
  /// In en, this message translates to:
  /// **'Hearts'**
  String get hearts;

  /// No description provided for @tapToSayHi.
  ///
  /// In en, this message translates to:
  /// **'Tap to say hi!'**
  String get tapToSayHi;

  /// No description provided for @sendWaveToStart.
  ///
  /// In en, this message translates to:
  /// **'Send a wave to start chatting'**
  String get sendWaveToStart;

  /// No description provided for @documentMustBeUnder50MB.
  ///
  /// In en, this message translates to:
  /// **'Document must be under 50MB.'**
  String get documentMustBeUnder50MB;

  /// No description provided for @editWithin15Minutes.
  ///
  /// In en, this message translates to:
  /// **'Messages can only be edited within 15 minutes'**
  String get editWithin15Minutes;

  /// No description provided for @messageForwardedTo.
  ///
  /// In en, this message translates to:
  /// **'Message forwarded to {count} user(s)'**
  String messageForwardedTo(int count);

  /// No description provided for @failedToLoadUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load users'**
  String get failedToLoadUsers;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @searchGifs.
  ///
  /// In en, this message translates to:
  /// **'Search GIFs...'**
  String get searchGifs;

  /// No description provided for @trendingGifs.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trendingGifs;

  /// No description provided for @poweredByGiphy.
  ///
  /// In en, this message translates to:
  /// **'Powered by GIPHY'**
  String get poweredByGiphy;

  /// No description provided for @gif.
  ///
  /// In en, this message translates to:
  /// **'GIF'**
  String get gif;

  /// No description provided for @noGifsFound.
  ///
  /// In en, this message translates to:
  /// **'No GIFs found'**
  String get noGifsFound;

  /// No description provided for @failedToLoadGifs.
  ///
  /// In en, this message translates to:
  /// **'Failed to load GIFs'**
  String get failedToLoadGifs;

  /// No description provided for @gifSent.
  ///
  /// In en, this message translates to:
  /// **'GIF'**
  String get gifSent;

  /// No description provided for @filterCommunities.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterCommunities;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @findYourPerfect.
  ///
  /// In en, this message translates to:
  /// **'Find Your Perfect'**
  String get findYourPerfect;

  /// No description provided for @languagePartner.
  ///
  /// In en, this message translates to:
  /// **'Language Partner'**
  String get languagePartner;

  /// No description provided for @learningLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Learning Language'**
  String get learningLanguageLabel;

  /// No description provided for @ageRange.
  ///
  /// In en, this message translates to:
  /// **'Age Range'**
  String get ageRange;

  /// No description provided for @genderPreference.
  ///
  /// In en, this message translates to:
  /// **'Gender Preference'**
  String get genderPreference;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @showNewUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show users who joined in the last 6 days'**
  String get showNewUsersSubtitle;

  /// No description provided for @autoDetectLocation.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect my location'**
  String get autoDetectLocation;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @anyCountry.
  ///
  /// In en, this message translates to:
  /// **'Any Country'**
  String get anyCountry;

  /// No description provided for @loadingLanguages.
  ///
  /// In en, this message translates to:
  /// **'Loading languages...'**
  String get loadingLanguages;

  /// No description provided for @minAge.
  ///
  /// In en, this message translates to:
  /// **'Min: {age}'**
  String minAge(int age);

  /// No description provided for @maxAge.
  ///
  /// In en, this message translates to:
  /// **'Max: {age}'**
  String maxAge(int age);

  /// No description provided for @captionRequired.
  ///
  /// In en, this message translates to:
  /// **'Caption is required'**
  String get captionRequired;

  /// No description provided for @captionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Caption must be {maxLength} characters or less'**
  String captionTooLong(int maxLength);

  /// No description provided for @maximumImagesReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum Images Reached'**
  String get maximumImagesReached;

  /// No description provided for @maximumImagesReachedDescription.
  ///
  /// In en, this message translates to:
  /// **'You can only upload up to {maxImages} images per moment.'**
  String maximumImagesReachedDescription(int maxImages);

  /// No description provided for @maximumImagesAddedPartial.
  ///
  /// In en, this message translates to:
  /// **'Maximum {maxImages} images allowed. Only {added} images added.'**
  String maximumImagesAddedPartial(int maxImages, int added);

  /// No description provided for @locationAccessRestricted.
  ///
  /// In en, this message translates to:
  /// **'Location Access Restricted'**
  String get locationAccessRestricted;

  /// No description provided for @locationPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Needed'**
  String get locationPermissionNeeded;

  /// No description provided for @addToYourMoment.
  ///
  /// In en, this message translates to:
  /// **'Add to your moment'**
  String get addToYourMoment;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @scheduleOptional.
  ///
  /// In en, this message translates to:
  /// **'Schedule (optional)'**
  String get scheduleOptional;

  /// No description provided for @scheduleForLater.
  ///
  /// In en, this message translates to:
  /// **'Schedule for later'**
  String get scheduleForLater;

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get addMore;

  /// No description provided for @howAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get howAreYouFeeling;

  /// No description provided for @pleaseWaitOptimizingVideo.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we optimize your video'**
  String get pleaseWaitOptimizingVideo;

  /// No description provided for @unsupportedVideoFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported format. Use: {formats}'**
  String unsupportedVideoFormat(String formats);

  /// No description provided for @chooseBackground.
  ///
  /// In en, this message translates to:
  /// **'Choose a background'**
  String get chooseBackground;

  /// No description provided for @likedByXPeople.
  ///
  /// In en, this message translates to:
  /// **'Liked by {count} people'**
  String likedByXPeople(int count);

  /// No description provided for @xComments.
  ///
  /// In en, this message translates to:
  /// **'{count} comments'**
  String xComments(int count);

  /// No description provided for @oneComment.
  ///
  /// In en, this message translates to:
  /// **'1 comment'**
  String get oneComment;

  /// No description provided for @addAComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addAComment;

  /// No description provided for @viewXReplies.
  ///
  /// In en, this message translates to:
  /// **'View {count} replies'**
  String viewXReplies(int count);

  /// No description provided for @seenByX.
  ///
  /// In en, this message translates to:
  /// **'Seen by {count}'**
  String seenByX(int count);

  /// No description provided for @xHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String xHoursAgo(int count);

  /// No description provided for @xMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String xMinutesAgo(int count);

  /// No description provided for @repliedToYourStory.
  ///
  /// In en, this message translates to:
  /// **'Replied to your story'**
  String get repliedToYourStory;

  /// No description provided for @mentionedYouInComment.
  ///
  /// In en, this message translates to:
  /// **'{name} mentioned you in a comment'**
  String mentionedYouInComment(String name);

  /// No description provided for @repliedToYourComment.
  ///
  /// In en, this message translates to:
  /// **'{name} replied to your comment'**
  String repliedToYourComment(String name);

  /// No description provided for @reactedToYourComment.
  ///
  /// In en, this message translates to:
  /// **'{name} reacted to your comment'**
  String reactedToYourComment(String name);

  /// No description provided for @addReaction.
  ///
  /// In en, this message translates to:
  /// **'Add reaction'**
  String get addReaction;

  /// No description provided for @attachImage.
  ///
  /// In en, this message translates to:
  /// **'Attach image'**
  String get attachImage;

  /// No description provided for @pickGif.
  ///
  /// In en, this message translates to:
  /// **'Pick a GIF'**
  String get pickGif;

  /// No description provided for @textStory.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textStory;

  /// No description provided for @typeYourStory.
  ///
  /// In en, this message translates to:
  /// **'Type your story...'**
  String get typeYourStory;

  /// No description provided for @selectBackground.
  ///
  /// In en, this message translates to:
  /// **'Select background'**
  String get selectBackground;

  /// No description provided for @highlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlightsTitle;

  /// No description provided for @highlightTitle.
  ///
  /// In en, this message translates to:
  /// **'Highlight Title'**
  String get highlightTitle;

  /// No description provided for @createNewHighlight.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNewHighlight;

  /// No description provided for @selectStories.
  ///
  /// In en, this message translates to:
  /// **'Select Stories'**
  String get selectStories;

  /// No description provided for @selectCover.
  ///
  /// In en, this message translates to:
  /// **'Select Cover'**
  String get selectCover;

  /// No description provided for @addText.
  ///
  /// In en, this message translates to:
  /// **'Add Text'**
  String get addText;

  /// No description provided for @fontStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Font Style'**
  String get fontStyleLabel;

  /// No description provided for @textColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Text Color'**
  String get textColorLabel;

  /// No description provided for @dragToDelete.
  ///
  /// In en, this message translates to:
  /// **'Drag here to delete'**
  String get dragToDelete;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsers;

  /// No description provided for @usersYouBlockWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Users you block will appear here'**
  String get usersYouBlockWillAppearHere;

  /// No description provided for @unblockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unblock {name}?'**
  String unblockConfirm(String name);

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String reasonLabel(String reason);

  /// No description provided for @blockedAgo.
  ///
  /// In en, this message translates to:
  /// **'Blocked {time}'**
  String blockedAgo(String time);

  /// No description provided for @errorLoadingBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Error loading blocked users: {error}'**
  String errorLoadingBlockedUsers(String error);

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from Bananatalk?'**
  String get logoutConfirmMessage;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// No description provided for @quietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get quietHours;

  /// No description provided for @quietHoursEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Quiet Hours'**
  String get quietHoursEnable;

  /// No description provided for @quietHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pause non-urgent notifications during a time window'**
  String get quietHoursSubtitle;

  /// No description provided for @quietHoursStart.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get quietHoursStart;

  /// No description provided for @quietHoursEnd.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get quietHoursEnd;

  /// No description provided for @quietHoursAllowUrgent.
  ///
  /// In en, this message translates to:
  /// **'Allow urgent notifications'**
  String get quietHoursAllowUrgent;

  /// No description provided for @quietHoursAllowUrgentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calls and messages from VIP partners can still come through'**
  String get quietHoursAllowUrgentSubtitle;

  /// No description provided for @silencedByQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Silenced by Quiet Hours'**
  String get silencedByQuietHours;

  /// No description provided for @silencedByCap.
  ///
  /// In en, this message translates to:
  /// **'Silenced by daily limit'**
  String get silencedByCap;

  /// No description provided for @momentUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Moment updated successfully'**
  String get momentUpdatedSuccessfully;

  /// No description provided for @failedToDeleteMoment.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete moment'**
  String get failedToDeleteMoment;

  /// No description provided for @failedToUpdateMoment.
  ///
  /// In en, this message translates to:
  /// **'Failed to update moment'**
  String get failedToUpdateMoment;

  /// No description provided for @mbtiUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'MBTI updated successfully'**
  String get mbtiUpdatedSuccessfully;

  /// No description provided for @pleaseSelectMbti.
  ///
  /// In en, this message translates to:
  /// **'Please select an MBTI type'**
  String get pleaseSelectMbti;

  /// No description provided for @languageUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Language updated successfully'**
  String get languageUpdatedSuccessfully;

  /// No description provided for @bioHintCard.
  ///
  /// In en, this message translates to:
  /// **'A great bio helps others connect with you. Share your interests, languages, or what you\'re looking for.'**
  String get bioHintCard;

  /// No description provided for @bioCounterStartWriting.
  ///
  /// In en, this message translates to:
  /// **'Start writing...'**
  String get bioCounterStartWriting;

  /// No description provided for @bioCounterABitMore.
  ///
  /// In en, this message translates to:
  /// **'A bit more would be great'**
  String get bioCounterABitMore;

  /// No description provided for @bioCounterAlmostAtLimit.
  ///
  /// In en, this message translates to:
  /// **'Almost at the limit'**
  String get bioCounterAlmostAtLimit;

  /// No description provided for @bioCounterTooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long'**
  String get bioCounterTooLong;

  /// No description provided for @bioQuickStarters.
  ///
  /// In en, this message translates to:
  /// **'Quick starters'**
  String get bioQuickStarters;

  /// No description provided for @rhPositive.
  ///
  /// In en, this message translates to:
  /// **'Rh Positive'**
  String get rhPositive;

  /// No description provided for @rhNegative.
  ///
  /// In en, this message translates to:
  /// **'Rh Negative'**
  String get rhNegative;

  /// No description provided for @rhPositiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Most common'**
  String get rhPositiveDesc;

  /// No description provided for @rhNegativeDesc.
  ///
  /// In en, this message translates to:
  /// **'Universal donors / rare'**
  String get rhNegativeDesc;

  /// No description provided for @yourBloodType.
  ///
  /// In en, this message translates to:
  /// **'Your blood type'**
  String get yourBloodType;

  /// No description provided for @noBloodTypeSelected.
  ///
  /// In en, this message translates to:
  /// **'No blood type selected'**
  String get noBloodTypeSelected;

  /// No description provided for @tapTypeBelow.
  ///
  /// In en, this message translates to:
  /// **'Tap a type below'**
  String get tapTypeBelow;

  /// No description provided for @tapButtonToDetectLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to detect your current location'**
  String get tapButtonToDetectLocation;

  /// No description provided for @currentAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Current: {address}'**
  String currentAddressLabel(String address);

  /// No description provided for @onlyCityCountryShown.
  ///
  /// In en, this message translates to:
  /// **'Only your city and country are shown to others. Exact coordinates remain private.'**
  String get onlyCityCountryShown;

  /// No description provided for @updateLocationCta.
  ///
  /// In en, this message translates to:
  /// **'Update Location'**
  String get updateLocationCta;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @tapBelowToBrowseLanguages.
  ///
  /// In en, this message translates to:
  /// **'Tap below to browse from {count} languages'**
  String tapBelowToBrowseLanguages(int count);

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @browseLanguages.
  ///
  /// In en, this message translates to:
  /// **'Browse Languages'**
  String get browseLanguages;

  /// No description provided for @yourLearningLanguageIsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Your learning language is '**
  String get yourLearningLanguageIsPrefix;

  /// No description provided for @yourNativeLanguageIsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Your native language is '**
  String get yourNativeLanguageIsPrefix;

  /// No description provided for @profileCompleteProgress.
  ///
  /// In en, this message translates to:
  /// **'complete'**
  String get profileCompleteProgress;

  /// No description provided for @drawerPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get drawerPreferences;

  /// No description provided for @drawerStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get drawerStorage;

  /// No description provided for @drawerReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get drawerReports;

  /// No description provided for @drawerSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get drawerSupport;

  /// No description provided for @drawerAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get drawerAccount;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from Bananatalk?'**
  String get logoutConfirmBody;

  /// No description provided for @helpEmailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get helpEmailSupport;

  /// No description provided for @helpEmailSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'support@bananatalk.com'**
  String get helpEmailSupportSubtitle;

  /// No description provided for @helpReportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get helpReportBug;

  /// No description provided for @helpReportBugSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve Bananatalk'**
  String get helpReportBugSubtitle;

  /// No description provided for @helpFaqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get helpFaqs;

  /// No description provided for @helpFaqsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get helpFaqsSubtitle;

  /// No description provided for @aboutDialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get aboutDialogClose;

  /// No description provided for @aboutBananatalkTagline.
  ///
  /// In en, this message translates to:
  /// **'Connect with language learners worldwide and improve your skills through real conversations.'**
  String get aboutBananatalkTagline;

  /// No description provided for @aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2024 Bananatalk. All rights reserved.'**
  String get aboutCopyright;

  /// No description provided for @logoutFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailedPrefix;

  /// No description provided for @profileVisitorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Visitors'**
  String get profileVisitorsTitle;

  /// No description provided for @visitorStatistics.
  ///
  /// In en, this message translates to:
  /// **'Visitor Statistics'**
  String get visitorStatistics;

  /// No description provided for @visitorsTotalVisits.
  ///
  /// In en, this message translates to:
  /// **'Total Visits'**
  String get visitorsTotalVisits;

  /// No description provided for @visitorsUniqueVisitors.
  ///
  /// In en, this message translates to:
  /// **'Unique Visitors'**
  String get visitorsUniqueVisitors;

  /// No description provided for @visitorsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get visitorsToday;

  /// No description provided for @visitorsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get visitorsThisWeek;

  /// No description provided for @noVisitorsYet.
  ///
  /// In en, this message translates to:
  /// **'No visitors yet'**
  String get noVisitorsYet;

  /// No description provided for @noVisitorsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When people visit your profile,\nthey will appear here'**
  String get noVisitorsYetSubtitle;

  /// No description provided for @visitedViaSearch.
  ///
  /// In en, this message translates to:
  /// **'via Search'**
  String get visitedViaSearch;

  /// No description provided for @visitedViaMoments.
  ///
  /// In en, this message translates to:
  /// **'via Moments'**
  String get visitedViaMoments;

  /// No description provided for @visitedViaChat.
  ///
  /// In en, this message translates to:
  /// **'via Chat'**
  String get visitedViaChat;

  /// No description provided for @visitedDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct visit'**
  String get visitedDirect;

  /// No description provided for @visitorTrackingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Visitor tracking feature not available. Please update backend.'**
  String get visitorTrackingUnavailable;

  /// No description provided for @visitorTrackingNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Visitor tracking not available yet'**
  String get visitorTrackingNotAvailableYet;

  /// No description provided for @noFollowersYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start connecting with others!'**
  String get noFollowersYetSubtitle;

  /// No description provided for @partnerButton.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get partnerButton;

  /// No description provided for @notFollowingAnyoneYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start following people to see their updates!'**
  String get notFollowingAnyoneYetSubtitle;

  /// No description provided for @unfollowButton.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollowButton;

  /// No description provided for @profileThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Theme'**
  String get profileThemeTitle;

  /// No description provided for @themeAutoSwitch.
  ///
  /// In en, this message translates to:
  /// **'Auto Switch (System Theme)'**
  String get themeAutoSwitch;

  /// No description provided for @themeSystemHint.
  ///
  /// In en, this message translates to:
  /// **'When enabled, the app will follow your system theme settings'**
  String get themeSystemHint;

  /// No description provided for @themeLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get themeLightMode;

  /// No description provided for @themeDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeDarkMode;

  /// No description provided for @myMoments.
  ///
  /// In en, this message translates to:
  /// **'My Moments'**
  String get myMoments;

  /// No description provided for @momentListView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get momentListView;

  /// No description provided for @momentGridView.
  ///
  /// In en, this message translates to:
  /// **'Grid View'**
  String get momentGridView;

  /// No description provided for @shareLanguageLearningJourney.
  ///
  /// In en, this message translates to:
  /// **'Share your language learning journey!'**
  String get shareLanguageLearningJourney;

  /// No description provided for @deleteHighlightTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Highlight'**
  String get deleteHighlightTitle;

  /// No description provided for @deleteHighlightConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? The stories inside won\'t be deleted.'**
  String deleteHighlightConfirm(String title);

  /// No description provided for @highlightDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Highlight deleted'**
  String get highlightDeletedSuccess;

  /// No description provided for @highlightNewBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get highlightNewBadge;

  /// No description provided for @editMoment.
  ///
  /// In en, this message translates to:
  /// **'Edit Moment'**
  String get editMoment;

  /// No description provided for @momentDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get momentDescriptionLabel;

  /// No description provided for @momentImagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get momentImagesLabel;

  /// No description provided for @noImagesYet.
  ///
  /// In en, this message translates to:
  /// **'No images yet'**
  String get noImagesYet;

  /// No description provided for @momentEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get momentEnterDescription;

  /// No description provided for @momentUpdatedImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Moment updated but image upload failed'**
  String get momentUpdatedImageFailed;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get updateRequiredTitle;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailableTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version of Bananatalk is no longer supported. Please update to continue.'**
  String get updateRequiredBody;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'A new version of Bananatalk is available with improvements and bug fixes.'**
  String get updateAvailableBody;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateOpenStoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the store. Please update from the App Store or Play Store.'**
  String get updateOpenStoreFailed;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordWeak;

  /// No description provided for @passwordFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordFair;

  /// No description provided for @passwordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrong;

  /// No description provided for @passwordVeryStrong.
  ///
  /// In en, this message translates to:
  /// **'Very strong'**
  String get passwordVeryStrong;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepProgress(int current, int total);

  /// No description provided for @usernameOptional.
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get usernameOptional;

  /// No description provided for @usernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get usernameAvailable;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Already taken'**
  String get usernameTaken;

  /// No description provided for @usernameNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get usernameNotAvailable;

  /// No description provided for @usernameInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'3–20 characters, letters, numbers, or underscore'**
  String get usernameInvalidFormat;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'@username'**
  String get usernameHint;

  /// No description provided for @enableBiometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID to log in next time?'**
  String get enableBiometricTitle;

  /// No description provided for @enableBiometricBody.
  ///
  /// In en, this message translates to:
  /// **'Skip typing your password by signing in with biometrics.'**
  String get enableBiometricBody;

  /// No description provided for @enableBiometricCta.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enableBiometricCta;

  /// No description provided for @biometricSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to log in to Bananatalk'**
  String get biometricSignInPrompt;

  /// No description provided for @continueAs.
  ///
  /// In en, this message translates to:
  /// **'Continue as {name}'**
  String continueAs(String name);

  /// No description provided for @addProfilePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a profile photo'**
  String get addProfilePhotoTitle;

  /// No description provided for @addProfilePhotoSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get addProfilePhotoSkip;

  /// No description provided for @wavesTab.
  ///
  /// In en, this message translates to:
  /// **'Waves'**
  String get wavesTab;

  /// No description provided for @sendWave.
  ///
  /// In en, this message translates to:
  /// **'Send a wave'**
  String get sendWave;

  /// No description provided for @sendWaveTo.
  ///
  /// In en, this message translates to:
  /// **'Send a wave to {name}'**
  String sendWaveTo(String name);

  /// No description provided for @waveSent.
  ///
  /// In en, this message translates to:
  /// **'Wave sent to {name}'**
  String waveSent(String name);

  /// No description provided for @waveCooldown.
  ///
  /// In en, this message translates to:
  /// **'You can wave {name} again in {time}'**
  String waveCooldown(String name, String time);

  /// No description provided for @waveCouldntSend.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send wave'**
  String get waveCouldntSend;

  /// No description provided for @itsAMatch.
  ///
  /// In en, this message translates to:
  /// **'It\'s a match!'**
  String get itsAMatch;

  /// No description provided for @itsAMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You and {name} both waved'**
  String itsAMatchSubtitle(String name);

  /// No description provided for @sendAMessage.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get sendAMessage;

  /// No description provided for @waveQuickReplyHi.
  ///
  /// In en, this message translates to:
  /// **'Hi!'**
  String get waveQuickReplyHi;

  /// No description provided for @waveQuickReplyCool.
  ///
  /// In en, this message translates to:
  /// **'You seem cool'**
  String get waveQuickReplyCool;

  /// No description provided for @waveQuickReplyHey.
  ///
  /// In en, this message translates to:
  /// **'Hey there'**
  String get waveQuickReplyHey;

  /// No description provided for @waveQuickReplyChat.
  ///
  /// In en, this message translates to:
  /// **'Let\'s chat'**
  String get waveQuickReplyChat;

  /// No description provided for @waveQuickReplyHello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get waveQuickReplyHello;

  /// No description provided for @waveQuickReplyFromCountry.
  ///
  /// In en, this message translates to:
  /// **'Hi from {country}'**
  String waveQuickReplyFromCountry(String country);

  /// No description provided for @waveCustomMessage.
  ///
  /// In en, this message translates to:
  /// **'Or write your own…'**
  String get waveCustomMessage;

  /// No description provided for @voiceRoomChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get voiceRoomChat;

  /// No description provided for @voiceRoomChatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Send a message…'**
  String get voiceRoomChatPlaceholder;

  /// No description provided for @voiceRoomChatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet — say hi'**
  String get voiceRoomChatEmpty;

  /// No description provided for @voiceRoomChatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get voiceRoomChatSend;

  /// No description provided for @voiceRoomChatNewBadge.
  ///
  /// In en, this message translates to:
  /// **'{n}'**
  String voiceRoomChatNewBadge(int n);

  /// No description provided for @voiceRoomEnd.
  ///
  /// In en, this message translates to:
  /// **'End room'**
  String get voiceRoomEnd;

  /// No description provided for @voiceRoomEndConfirm.
  ///
  /// In en, this message translates to:
  /// **'End this room?'**
  String get voiceRoomEndConfirm;

  /// No description provided for @voiceRoomEndConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Everyone will be disconnected.'**
  String get voiceRoomEndConfirmBody;

  /// No description provided for @voiceRoomKick.
  ///
  /// In en, this message translates to:
  /// **'Remove from room'**
  String get voiceRoomKick;

  /// No description provided for @voiceRoomKickConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String voiceRoomKickConfirm(String name);

  /// No description provided for @voiceRoomKicked.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get voiceRoomKicked;

  /// No description provided for @voiceRoomYouAreHostNow.
  ///
  /// In en, this message translates to:
  /// **'You\'re now the host'**
  String get voiceRoomYouAreHostNow;

  /// No description provided for @voiceRoomHostChanged.
  ///
  /// In en, this message translates to:
  /// **'{name} is now the host'**
  String voiceRoomHostChanged(String name);

  /// No description provided for @voiceRoomHostMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Room actions'**
  String get voiceRoomHostMenuTitle;

  /// No description provided for @voiceRoomViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get voiceRoomViewProfile;

  /// No description provided for @voiceRoomReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get voiceRoomReconnecting;

  /// No description provided for @voiceRoomReconnected.
  ///
  /// In en, this message translates to:
  /// **'Reconnected'**
  String get voiceRoomReconnected;

  /// No description provided for @voiceRoomEnded.
  ///
  /// In en, this message translates to:
  /// **'Room ended'**
  String get voiceRoomEnded;

  /// No description provided for @voiceRoomReconnectRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get voiceRoomReconnectRetry;

  /// No description provided for @mutualInterests.
  ///
  /// In en, this message translates to:
  /// **'Mutual interests'**
  String get mutualInterests;

  /// No description provided for @interestsInCommon.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No interests in common yet} =1{1 interest in common} other{{count} interests in common}}'**
  String interestsInCommon(int count);

  /// No description provided for @interestsInCommonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get interestsInCommonSeeAll;

  /// No description provided for @interestsInCommonAddCta.
  ///
  /// In en, this message translates to:
  /// **'Add topics'**
  String get interestsInCommonAddCta;

  /// No description provided for @interestsInCommonAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add topics to your profile to find common ground'**
  String get interestsInCommonAddSubtitle;

  /// No description provided for @activeAgo.
  ///
  /// In en, this message translates to:
  /// **'Active {time} ago'**
  String activeAgo(String time);

  /// No description provided for @filterOnlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get filterOnlineNow;

  /// No description provided for @filterAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get filterAge;

  /// No description provided for @filterGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get filterGender;

  /// No description provided for @filterLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get filterLanguages;

  /// No description provided for @filterCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get filterCountry;

  /// No description provided for @filterTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get filterTopics;

  /// No description provided for @filterLevel.
  ///
  /// In en, this message translates to:
  /// **'Language level'**
  String get filterLevel;

  /// No description provided for @filterToggles.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get filterToggles;

  /// No description provided for @filterMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No partners match} =1{1 partner matches} other{{count} partners match}}'**
  String filterMatchCount(int count);

  /// No description provided for @filterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get filterClearAll;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @filterNewUsers.
  ///
  /// In en, this message translates to:
  /// **'New users only'**
  String get filterNewUsers;

  /// No description provided for @filterPrioritizeNearby.
  ///
  /// In en, this message translates to:
  /// **'Prioritize nearby'**
  String get filterPrioritizeNearby;

  /// No description provided for @filterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterSheetTitle;

  /// No description provided for @notificationPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationPreferencesTitle;

  /// No description provided for @notificationPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which alerts you receive'**
  String get notificationPreferencesSubtitle;

  /// No description provided for @notifPrefChat.
  ///
  /// In en, this message translates to:
  /// **'New messages'**
  String get notifPrefChat;

  /// No description provided for @notifPrefWave.
  ///
  /// In en, this message translates to:
  /// **'Waves'**
  String get notifPrefWave;

  /// No description provided for @notifPrefVoiceRoomStart.
  ///
  /// In en, this message translates to:
  /// **'Voice room invites'**
  String get notifPrefVoiceRoomStart;

  /// No description provided for @notifPrefScheduledRoomReminder.
  ///
  /// In en, this message translates to:
  /// **'Scheduled room reminders'**
  String get notifPrefScheduledRoomReminder;

  /// No description provided for @notifPrefFollowerMoment.
  ///
  /// In en, this message translates to:
  /// **'New moments from people you follow'**
  String get notifPrefFollowerMoment;

  /// No description provided for @notifPrefVisitorAlert.
  ///
  /// In en, this message translates to:
  /// **'Profile visitors'**
  String get notifPrefVisitorAlert;

  /// No description provided for @notifPrefMatchAlert.
  ///
  /// In en, this message translates to:
  /// **'Mutual waves'**
  String get notifPrefMatchAlert;

  /// No description provided for @notifResetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get notifResetToDefaults;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @languageSettingsRow.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingsRow;

  /// No description provided for @waveDailySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'New waves waiting'**
  String get waveDailySummaryTitle;

  /// No description provided for @waveDailySummaryBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person waved at you} other{{count} people waved at you}}'**
  String waveDailySummaryBody(int count);

  /// No description provided for @filterTopicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get filterTopicsTitle;

  /// No description provided for @filterTopicsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No topics selected'**
  String get filterTopicsEmpty;

  /// No description provided for @storiesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stories yet'**
  String get storiesEmpty;

  /// No description provided for @storiesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load stories'**
  String get storiesLoadError;

  /// No description provided for @storiesRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get storiesRetry;

  /// No description provided for @storiesNoMore.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get storiesNoMore;

  /// No description provided for @createTextStoryTab.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get createTextStoryTab;

  /// No description provided for @createImageStoryTab.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get createImageStoryTab;

  /// No description provided for @createVideoStoryTab.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get createVideoStoryTab;

  /// No description provided for @enterTextHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to type'**
  String get enterTextHint;

  /// No description provided for @pickBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get pickBackground;

  /// No description provided for @pickFontStyle.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get pickFontStyle;

  /// No description provided for @pickTextColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get pickTextColor;

  /// No description provided for @addEmoji.
  ///
  /// In en, this message translates to:
  /// **'Add emoji'**
  String get addEmoji;

  /// No description provided for @chooseFont.
  ///
  /// In en, this message translates to:
  /// **'Choose font'**
  String get chooseFont;

  /// No description provided for @chooseColor.
  ///
  /// In en, this message translates to:
  /// **'Choose color'**
  String get chooseColor;

  /// No description provided for @dragToMove.
  ///
  /// In en, this message translates to:
  /// **'Drag to move'**
  String get dragToMove;

  /// No description provided for @pinchToScale.
  ///
  /// In en, this message translates to:
  /// **'Pinch to scale'**
  String get pinchToScale;

  /// No description provided for @removeFromHighlight.
  ///
  /// In en, this message translates to:
  /// **'Remove from highlight'**
  String get removeFromHighlight;

  /// No description provided for @highlightDeleted.
  ///
  /// In en, this message translates to:
  /// **'Highlight deleted'**
  String get highlightDeleted;

  /// No description provided for @storySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to your story'**
  String get storySaved;

  /// No description provided for @storyTooLong.
  ///
  /// In en, this message translates to:
  /// **'Text is too long'**
  String get storyTooLong;

  /// No description provided for @storyPostFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t post story'**
  String get storyPostFailed;

  /// No description provided for @fontNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get fontNormal;

  /// No description provided for @fontBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get fontBold;

  /// No description provided for @fontItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get fontItalic;

  /// No description provided for @fontHandwriting.
  ///
  /// In en, this message translates to:
  /// **'Handwriting'**
  String get fontHandwriting;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @pickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick time'**
  String get pickTime;

  /// No description provided for @upcomingRooms.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingRooms;

  /// No description provided for @inHours.
  ///
  /// In en, this message translates to:
  /// **'in {h}h {m}m'**
  String inHours(int h, int m);

  /// No description provided for @inMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {m}m'**
  String inMinutes(int m);

  /// No description provided for @startsNow.
  ///
  /// In en, this message translates to:
  /// **'Starting now'**
  String get startsNow;

  /// No description provided for @iWillBeThere.
  ///
  /// In en, this message translates to:
  /// **'I\'ll be there'**
  String get iWillBeThere;

  /// No description provided for @cantMakeIt.
  ///
  /// In en, this message translates to:
  /// **'Can\'t make it'**
  String get cantMakeIt;

  /// No description provided for @rsvpCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No RSVPs} =1{1 RSVP} other{{count} RSVPs}}'**
  String rsvpCount(int count);

  /// No description provided for @roomStartsIn1h.
  ///
  /// In en, this message translates to:
  /// **'{title} starts in 1 hour'**
  String roomStartsIn1h(String title);

  /// No description provided for @roomStartsIn15min.
  ///
  /// In en, this message translates to:
  /// **'{title} starts in 15 minutes'**
  String roomStartsIn15min(String title);

  /// No description provided for @roomStarted.
  ///
  /// In en, this message translates to:
  /// **'{title} is starting now'**
  String roomStarted(String title);

  /// No description provided for @cancelRoom.
  ///
  /// In en, this message translates to:
  /// **'Cancel room'**
  String get cancelRoom;

  /// No description provided for @muteAll.
  ///
  /// In en, this message translates to:
  /// **'Mute all'**
  String get muteAll;

  /// No description provided for @mutedByHost.
  ///
  /// In en, this message translates to:
  /// **'Host muted everyone'**
  String get mutedByHost;

  /// No description provided for @muteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mute everyone in the room?'**
  String get muteAllConfirm;

  /// No description provided for @categoryCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get categoryCasual;

  /// No description provided for @categoryLanguagePractice.
  ///
  /// In en, this message translates to:
  /// **'Language practice'**
  String get categoryLanguagePractice;

  /// No description provided for @categoryTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get categoryTopic;

  /// No description provided for @categoryQA.
  ///
  /// In en, this message translates to:
  /// **'Q&A'**
  String get categoryQA;

  /// No description provided for @pickCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get pickCategory;

  /// No description provided for @sortRecentlyActive.
  ///
  /// In en, this message translates to:
  /// **'Recently active'**
  String get sortRecentlyActive;

  /// No description provided for @visitedYourProfile.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person visited your profile} other{{count} people visited your profile}}'**
  String visitedYourProfile(int count);

  /// No description provided for @noRecentVisitors.
  ///
  /// In en, this message translates to:
  /// **'No recent visitors'**
  String get noRecentVisitors;

  /// No description provided for @viewArchive.
  ///
  /// In en, this message translates to:
  /// **'View archive'**
  String get viewArchive;

  /// No description provided for @archivedWaves.
  ///
  /// In en, this message translates to:
  /// **'Archived waves'**
  String get archivedWaves;

  /// No description provided for @noArchivedWaves.
  ///
  /// In en, this message translates to:
  /// **'No archived waves'**
  String get noArchivedWaves;

  /// No description provided for @mutualInterestsMin.
  ///
  /// In en, this message translates to:
  /// **'Mutual interests (min)'**
  String get mutualInterestsMin;

  /// No description provided for @atLeastNTopics.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Any} =1{At least 1 topic in common} other{At least {n} topics in common}}'**
  String atLeastNTopics(int n);

  /// No description provided for @starterAskMoment.
  ///
  /// In en, this message translates to:
  /// **'Ask about their last moment'**
  String get starterAskMoment;

  /// No description provided for @starterSayHi.
  ///
  /// In en, this message translates to:
  /// **'Say hi in their language'**
  String get starterSayHi;

  /// No description provided for @starterCurious.
  ///
  /// In en, this message translates to:
  /// **'What are they curious about?'**
  String get starterCurious;

  /// No description provided for @starterFromCountry.
  ///
  /// In en, this message translates to:
  /// **'Hi from {country}!'**
  String starterFromCountry(String country);

  /// No description provided for @starterPracticeLang.
  ///
  /// In en, this message translates to:
  /// **'Help them practice {language}!'**
  String starterPracticeLang(String language);

  /// Error state on moments feed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load moments'**
  String get momentsLoadError;

  /// Retry button on moments error state
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get momentsRetry;

  /// Header in tag dialog showing tags this user has used recently
  ///
  /// In en, this message translates to:
  /// **'Recent tags'**
  String get recentTags;

  /// Shown when user has no tag history yet
  ///
  /// In en, this message translates to:
  /// **'No recent tags yet'**
  String get noRecentTags;

  /// 3-dot menu action on a moment card
  ///
  /// In en, this message translates to:
  /// **'Hide moments from this user'**
  String get hideMomentsFromUser;

  /// Snackbar confirmation after hiding a user's moments
  ///
  /// In en, this message translates to:
  /// **'Moments from this user will be hidden'**
  String get momentsHidden;

  /// Reverse action — re-show a user's moments
  ///
  /// In en, this message translates to:
  /// **'Show moments from this user'**
  String get unhideMoments;

  /// Plural count of users whose moments are hidden
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No hidden users} =1{1 user hidden} other{{count} users hidden}}'**
  String momentsHiddenCount(int count);

  /// Error snackbar when save toggle fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save moment'**
  String get momentSaveFailed;

  /// Snackbar when user tries to add a duplicate tag
  ///
  /// In en, this message translates to:
  /// **'Tag already added'**
  String get tagAlreadyAdded;

  /// Snackbar when tag limit hit
  ///
  /// In en, this message translates to:
  /// **'Maximum tags reached'**
  String get tagLimitReached;

  /// Short label for the 3-dot menu
  ///
  /// In en, this message translates to:
  /// **'Hide this user\'s posts'**
  String get hideThisUser;

  /// Button on a voice message to convert it to text
  ///
  /// In en, this message translates to:
  /// **'Transcribe'**
  String get transcribeMessage;

  /// Spinner label while voice transcription is in flight
  ///
  /// In en, this message translates to:
  /// **'Transcribing…'**
  String get transcribing;

  /// Error toast when speech-to-text fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t transcribe message'**
  String get transcriptionFailed;

  /// Long-press popup confirming a vocabulary save
  ///
  /// In en, this message translates to:
  /// **'Save \'{word}\' to vocabulary'**
  String saveToVocabulary(String word);

  /// Snackbar after successful vocab save
  ///
  /// In en, this message translates to:
  /// **'Added to your vocabulary'**
  String get addedToVocabulary;

  /// Snackbar when word is already saved
  ///
  /// In en, this message translates to:
  /// **'Already in your vocabulary'**
  String get alreadyInVocabulary;

  /// Optional onboarding hint shown once
  ///
  /// In en, this message translates to:
  /// **'Tap and hold a word to save it'**
  String get tapWordToSave;

  /// Subtitle for the per-chat auto-translate toggle
  ///
  /// In en, this message translates to:
  /// **'Incoming messages will be translated automatically'**
  String get autoTranslateChatHint;

  /// Empty state for the chat list
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// Retry button on chat error states
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get chatRetry;

  /// Title for the learning hub screen
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learningHubTitle;

  /// Generic retry button label in learning surface
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get learningCommonRetry;

  /// Generic continue button label in learning surface
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get learningCommonContinue;

  /// Generic positive reinforcement label
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get learningCommonAwesome;

  /// Generic error message in learning surface
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get learningErrorGeneric;

  /// Label for the current streak count
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get learningStreakCurrent;

  /// Label for the longest streak count
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get learningStreakLongest;

  /// Plural days count for streak display
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 days} =1{1 day} other{{count} days}}'**
  String learningStreakDaysCount(int count);

  /// Plural freeze count for streak freeze display
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No freezes available} =1{1 freeze available} other{{count} freezes available}}'**
  String learningStreakFreezeAvailable(int count);

  /// Button label to use a streak freeze
  ///
  /// In en, this message translates to:
  /// **'Use freeze'**
  String get learningStreakFreezeUse;

  /// Explanatory text for streak freezes
  ///
  /// In en, this message translates to:
  /// **'Freezes protect your streak when you miss a day.'**
  String get learningStreakFreezeDescription;

  /// Snackbar when a streak freeze is applied
  ///
  /// In en, this message translates to:
  /// **'Streak protected!'**
  String get learningStreakFreezeProtected;

  /// Celebration label for 7-day streak milestone
  ///
  /// In en, this message translates to:
  /// **'7-day streak!'**
  String get learningStreakMilestone7;

  /// Celebration label for 30-day streak milestone
  ///
  /// In en, this message translates to:
  /// **'30-day streak!'**
  String get learningStreakMilestone30;

  /// Celebration label for 100-day streak milestone
  ///
  /// In en, this message translates to:
  /// **'100-day streak!'**
  String get learningStreakMilestone100;

  /// Celebration label for 365-day streak milestone
  ///
  /// In en, this message translates to:
  /// **'365-day streak!'**
  String get learningStreakMilestone365;

  /// Title for the weekly digest card
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get learningWeeklyDigestTitle;

  /// XP earned this week in weekly digest
  ///
  /// In en, this message translates to:
  /// **'{xp} XP earned'**
  String learningWeeklyDigestXp(int xp);

  /// Plural lesson count in weekly digest
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lesson} other{{count} lessons}}'**
  String learningWeeklyDigestLessons(int count);

  /// Plural vocabulary words learned in weekly digest
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word learned} other{{count} words learned}}'**
  String learningWeeklyDigestVocab(int count);

  /// Plural active days count in weekly digest
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active day} other{{count} active days}}'**
  String learningWeeklyDigestDaysActive(int count);

  /// Label for top achievement in weekly digest
  ///
  /// In en, this message translates to:
  /// **'Top achievement'**
  String get learningWeeklyDigestTopAchievement;

  /// Positive trend indicator in weekly digest
  ///
  /// In en, this message translates to:
  /// **'Up {pct}% from last week'**
  String learningWeeklyDigestTrendUp(int pct);

  /// Negative trend indicator in weekly digest
  ///
  /// In en, this message translates to:
  /// **'Down {pct}% from last week'**
  String learningWeeklyDigestTrendDown(int pct);

  /// Flat trend indicator in weekly digest
  ///
  /// In en, this message translates to:
  /// **'Same as last week'**
  String get learningWeeklyDigestTrendFlat;

  /// Title for the SRS daily review dashboard
  ///
  /// In en, this message translates to:
  /// **'Daily Review'**
  String get learningSrsDashboardTitle;

  /// Plural SRS cards due today
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No cards due today} =1{1 card due today} other{{count} cards due today}}'**
  String learningSrsDueToday(int count);

  /// SRS cards due tomorrow
  ///
  /// In en, this message translates to:
  /// **'{count} due tomorrow'**
  String learningSrsDueTomorrow(int count);

  /// SRS cards due this week
  ///
  /// In en, this message translates to:
  /// **'{count} due this week'**
  String learningSrsDueThisWeek(int count);

  /// Button to start SRS review session
  ///
  /// In en, this message translates to:
  /// **'Start review'**
  String get learningSrsStartReview;

  /// Empty state when no SRS cards are due
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get learningSrsAllCaughtUp;

  /// Encouragement label in SRS session
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get learningSrsKeepGoing;

  /// Leaderboard tab label for XP ranking
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get learningLeaderboardXpTab;

  /// Leaderboard tab label for streak ranking
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get learningLeaderboardStreakTab;

  /// Leaderboard tab label for language ranking
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get learningLeaderboardLanguageTab;

  /// Leaderboard tab label for friends ranking
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get learningLeaderboardFriendsTab;

  /// Empty state for leaderboard
  ///
  /// In en, this message translates to:
  /// **'No rankings yet'**
  String get learningLeaderboardEmpty;

  /// Label to mark the current user in leaderboard
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get learningLeaderboardYouLabel;

  /// Badge label for friends in leaderboard
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get learningLeaderboardFriendBadge;

  /// Empty state for vocabulary list
  ///
  /// In en, this message translates to:
  /// **'Add words you want to remember'**
  String get learningEmptyVocab;

  /// Empty state for lessons list
  ///
  /// In en, this message translates to:
  /// **'No lessons available yet'**
  String get learningEmptyLessons;

  /// Empty state for quizzes list
  ///
  /// In en, this message translates to:
  /// **'No quizzes available'**
  String get learningEmptyQuizzes;

  /// Empty state for daily challenges
  ///
  /// In en, this message translates to:
  /// **'Check back tomorrow'**
  String get learningEmptyChallenges;

  /// Empty state for achievements list
  ///
  /// In en, this message translates to:
  /// **'Earn your first achievement'**
  String get learningEmptyAchievements;

  /// Empty state for search results in learning surface
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get learningEmptySearchResults;

  /// XP gained notification label
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String learningXpGained(int xp);

  /// Celebration label when user levels up
  ///
  /// In en, this message translates to:
  /// **'Level up!'**
  String get learningLevelUp;

  /// Label showing the level reached on level up
  ///
  /// In en, this message translates to:
  /// **'You reached {level}'**
  String learningLevelReached(String level);

  /// Snackbar/toast when an achievement is unlocked
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked'**
  String get learningAchievementUnlocked;

  /// Hint text for vocabulary search field
  ///
  /// In en, this message translates to:
  /// **'Search vocabulary'**
  String get learningVocabularySearchHint;

  /// Vocabulary filter chip label for all words
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get learningVocabularyFilterAll;

  /// Vocabulary filter chip label for new words
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get learningVocabularyFilterNew;

  /// Vocabulary filter chip label for words in learning
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learningVocabularyFilterLearning;

  /// Vocabulary filter chip label for mastered words
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get learningVocabularyFilterMastered;

  /// Vocabulary sort option by recency
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get learningVocabularySortRecent;

  /// Vocabulary sort option alphabetically
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get learningVocabularySortAlphabetical;

  /// Vocabulary sort option by mastery level
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get learningVocabularySortMastery;

  /// Mastery status label for new vocabulary words
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get learningVocabularyMasteryNew;

  /// Mastery status label for vocabulary words in learning
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learningVocabularyMasteryLearning;

  /// Mastery status label for mastered vocabulary words
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get learningVocabularyMasteryMastered;

  /// Label for the level indicator in progress section
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get learningProgressLevelLabel;

  /// XP needed to reach the next level
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to next level'**
  String learningProgressXpToNextLevel(int xp);

  /// Title for the weekly progress chart
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get learningProgressWeeklyChartTitle;

  /// Loading indicator while fetching a new sentence in the Pronunciation Coach
  ///
  /// In en, this message translates to:
  /// **'Picking a sentence for you…'**
  String get aiTutorPronounceLoading;

  /// Call-to-action below the record button
  ///
  /// In en, this message translates to:
  /// **'Tap to record'**
  String get aiTutorPronounceTapToRecord;

  /// Call-to-action while a recording is active
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get aiTutorPronounceTapToStop;

  /// Progress label while audio is being transcribed and scored
  ///
  /// In en, this message translates to:
  /// **'Listening to you…'**
  String get aiTutorPronounceTranscribing;

  /// Retry the current sentence after seeing the score
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get aiTutorPronounceTryAgain;

  /// Advance to the next sentence after seeing the score
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get aiTutorPronounceNext;

  /// Escape hatch — let the user type a custom sentence to practice
  ///
  /// In en, this message translates to:
  /// **'Use my own ✏️'**
  String get aiTutorPronounceUseYourOwn;

  /// Placeholder for the custom-sentence text field
  ///
  /// In en, this message translates to:
  /// **'Type a sentence you want to practice'**
  String get aiTutorPronounceCustomHint;

  /// Cancel button on the custom-sentence form
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get aiTutorPronounceCustomCancel;

  /// Submit button on the custom-sentence form
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get aiTutorPronounceCustomUse;

  /// Confirm dialog shown when user tries to leave mid-drill
  ///
  /// In en, this message translates to:
  /// **'Quit drill? Your progress won\'t be saved.'**
  String get aiTutorPronounceQuitConfirm;

  /// Confirm-quit button
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get aiTutorPronounceQuitYes;

  /// Cancel-quit button
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get aiTutorPronounceQuitNo;

  /// Progress indicator at the top of the drill
  ///
  /// In en, this message translates to:
  /// **'Sentence {current} of {total}'**
  String aiTutorPronounceSentenceOf(int current, int total);

  /// Title on the end-of-drill summary sheet
  ///
  /// In en, this message translates to:
  /// **'Drill complete'**
  String get aiTutorPronounceSummaryTitle;

  /// Label above the average-score number on the summary sheet
  ///
  /// In en, this message translates to:
  /// **'Average score'**
  String get aiTutorPronounceSummaryAvg;

  /// Label above the list of weakest words on the summary sheet
  ///
  /// In en, this message translates to:
  /// **'Words to practice'**
  String get aiTutorPronounceSummaryWeak;

  /// Primary action on the summary sheet — POSTs weak words and pops the drill
  ///
  /// In en, this message translates to:
  /// **'Save & Close'**
  String get aiTutorPronounceSaveClose;

  /// Button label while the summary is being submitted
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get aiTutorPronounceSaving;

  /// Label for the 5th tutor mode chip — opens the Pronunciation Coach drill
  ///
  /// In en, this message translates to:
  /// **'Pronounce'**
  String get aiTutorChipPronounce;

  /// Daily-plan task label for pronunciation drills, shows progress like '0/1'
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Pronunciation drill ({completed}/1)} other{Pronunciation drills ({completed}/{count})}}'**
  String aiTutorPlanPronunciation(int count, int completed);

  /// Headline at the top of the Pronunciation Coach start screen
  ///
  /// In en, this message translates to:
  /// **'How do you want to practice?'**
  String get aiTutorPronounceStartHeadline;

  /// Subheadline below the start-screen headline
  ///
  /// In en, this message translates to:
  /// **'Pick one to begin a 5-sentence drill.'**
  String get aiTutorPronounceStartSubhead;

  /// Title of the AI-generated mode card on the start screen
  ///
  /// In en, this message translates to:
  /// **'AI generates sentences'**
  String get aiTutorPronounceStartAITitle;

  /// Subtitle of the AI mode card
  ///
  /// In en, this message translates to:
  /// **'Level-tuned, biased toward your tricky words'**
  String get aiTutorPronounceStartAISubtitle;

  /// Title of the custom-sentence mode card on the start screen
  ///
  /// In en, this message translates to:
  /// **'Use my own sentence'**
  String get aiTutorPronounceStartCustomTitle;

  /// Subtitle of the custom-sentence mode card
  ///
  /// In en, this message translates to:
  /// **'Type or paste a phrase you want to nail'**
  String get aiTutorPronounceStartCustomSubtitle;

  /// Daily quota counter pill on tutor chip screens
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 left today} other{{count} left today}}'**
  String aiTutorQuotaRemaining(int count);

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @aiDailyPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Practice'**
  String get aiDailyPracticeTitle;

  /// No description provided for @aiDailyPracticeTranslateThis.
  ///
  /// In en, this message translates to:
  /// **'Translate this:'**
  String get aiDailyPracticeTranslateThis;

  /// No description provided for @aiDailyPracticeSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested:'**
  String get aiDailyPracticeSuggested;

  /// No description provided for @aiDailyPracticeHint.
  ///
  /// In en, this message translates to:
  /// **'Your translation'**
  String get aiDailyPracticeHint;

  /// No description provided for @aiLanguagesLoading.
  ///
  /// In en, this message translates to:
  /// **'Languages are still loading...'**
  String get aiLanguagesLoading;

  /// No description provided for @aiCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get aiCopiedToClipboard;

  /// No description provided for @aiGrammarHint.
  ///
  /// In en, this message translates to:
  /// **'Enter text to analyze...'**
  String get aiGrammarHint;

  /// No description provided for @aiGrammarSectionOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original Text'**
  String get aiGrammarSectionOriginal;

  /// No description provided for @aiGrammarSectionCorrected.
  ///
  /// In en, this message translates to:
  /// **'Corrected Text'**
  String get aiGrammarSectionCorrected;

  /// No description provided for @aiGrammarSectionIssues.
  ///
  /// In en, this message translates to:
  /// **'Issues Found ({count})'**
  String aiGrammarSectionIssues(int count);

  /// No description provided for @aiGrammarSectionWell.
  ///
  /// In en, this message translates to:
  /// **'What You Did Well'**
  String get aiGrammarSectionWell;

  /// No description provided for @aiGrammarSectionSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get aiGrammarSectionSuggestions;

  /// No description provided for @aiGrammarSectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get aiGrammarSectionSummary;

  /// No description provided for @aiLessonBuilderLabelLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get aiLessonBuilderLabelLanguage;

  /// No description provided for @aiLessonBuilderLabelLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get aiLessonBuilderLabelLevel;

  /// No description provided for @aiLessonBuilderTopicHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a topic (e.g., \"Food and Dining\")'**
  String get aiLessonBuilderTopicHint;

  /// No description provided for @aiLessonBuilderSaved.
  ///
  /// In en, this message translates to:
  /// **'Lesson \"{title}\" saved!'**
  String aiLessonBuilderSaved(String title);

  /// No description provided for @aiLessonBuilderBackToLessons.
  ///
  /// In en, this message translates to:
  /// **'Back to Lessons'**
  String get aiLessonBuilderBackToLessons;

  /// No description provided for @aiTranslationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter text to translate...'**
  String get aiTranslationHint;

  /// No description provided for @aiTranslationSavedToVocab.
  ///
  /// In en, this message translates to:
  /// **'Saved to your vocab list'**
  String get aiTranslationSavedToVocab;

  /// No description provided for @aiTranslationCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String aiTranslationCouldNotSave(String error);

  /// No description provided for @aiQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get aiQuizTitle;

  /// No description provided for @aiQuizFailedToGenerate.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate quiz'**
  String get aiQuizFailedToGenerate;

  /// No description provided for @aiQuizSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit Quiz?'**
  String get aiQuizSubmitTitle;

  /// No description provided for @aiQuizSubmitBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to submit your answers?'**
  String get aiQuizSubmitBody;

  /// No description provided for @aiQuizExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit Quiz?'**
  String get aiQuizExitTitle;

  /// No description provided for @aiQuizExitBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be lost.'**
  String get aiQuizExitBody;

  /// No description provided for @aiQuizAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer...'**
  String get aiQuizAnswerHint;

  /// No description provided for @aiQuizTranslationHint.
  ///
  /// In en, this message translates to:
  /// **'Type your translation...'**
  String get aiQuizTranslationHint;

  /// No description provided for @aiPronunciationPlayingAudio.
  ///
  /// In en, this message translates to:
  /// **'Playing audio...'**
  String get aiPronunciationPlayingAudio;

  /// No description provided for @aiPronunciationListenFirst.
  ///
  /// In en, this message translates to:
  /// **'Listen First'**
  String get aiPronunciationListenFirst;

  /// No description provided for @aiPronunciationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter text to practice...'**
  String get aiPronunciationHint;

  /// No description provided for @aiTutorCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load tutor: {error}'**
  String aiTutorCouldNotLoad(String error);

  /// No description provided for @aiTutorPlanUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Plan unavailable: {error}'**
  String aiTutorPlanUnavailable(String error);

  /// No description provided for @aiTutorReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get aiTutorReplay;

  /// No description provided for @aiScenariosTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice scenarios'**
  String get aiScenariosTitle;

  /// No description provided for @aiScenariosCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load scenarios: {error}'**
  String aiScenariosCouldNotLoad(String error);

  /// No description provided for @aiScenariosNoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'No scenarios available yet.'**
  String get aiScenariosNoneAvailable;

  /// No description provided for @aiScenariosCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start: {error}'**
  String aiScenariosCouldNotStart(String error);

  /// No description provided for @aiScenariosForYourLevel.
  ///
  /// In en, this message translates to:
  /// **'For your level ({level})'**
  String aiScenariosForYourLevel(String level);

  /// No description provided for @aiScenariosEasier.
  ///
  /// In en, this message translates to:
  /// **'Easier — warm up'**
  String get aiScenariosEasier;

  /// No description provided for @aiScenariosHarder.
  ///
  /// In en, this message translates to:
  /// **'Harder — stretch'**
  String get aiScenariosHarder;

  /// No description provided for @aiRoleplayStillStarting.
  ///
  /// In en, this message translates to:
  /// **'Still starting the scenario — try again in a moment.'**
  String get aiRoleplayStillStarting;

  /// No description provided for @aiRoleplaySendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String aiRoleplaySendFailed(String error);

  /// No description provided for @aiRoleplayCouldNotGrade.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t grade this one — try again next time.'**
  String get aiRoleplayCouldNotGrade;

  /// No description provided for @aiConversationHistoryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get aiConversationHistoryCompleted;

  /// No description provided for @aiConversationHistoryInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get aiConversationHistoryInProgress;

  /// No description provided for @aiConversationMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get aiConversationMessageHint;

  /// No description provided for @aiConversationTopicSpeak.
  ///
  /// In en, this message translates to:
  /// **'I speak'**
  String get aiConversationTopicSpeak;

  /// No description provided for @aiConversationTopicPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get aiConversationTopicPractice;

  /// No description provided for @aiToolsVipUpgradeDescription.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to VIP to unlock {feature}!'**
  String aiToolsVipUpgradeDescription(String feature);

  /// No description provided for @aiToolsVipBadge.
  ///
  /// In en, this message translates to:
  /// **'VIP'**
  String get aiToolsVipBadge;

  /// No description provided for @aiScenariosBannerPracticingIn.
  ///
  /// In en, this message translates to:
  /// **'Practicing in {language}'**
  String aiScenariosBannerPracticingIn(String language);

  /// No description provided for @aiScenariosBannerSubhead.
  ///
  /// In en, this message translates to:
  /// **'Pick a scenario at your level, or stretch one up.'**
  String get aiScenariosBannerSubhead;

  /// No description provided for @chatListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search or type @username'**
  String get chatListSearchHint;

  /// No description provided for @chatListFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chatListFilterAll;

  /// No description provided for @chatListFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get chatListFilterUnread;

  /// No description provided for @chatListFilterOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get chatListFilterOnline;

  /// No description provided for @chatListNewChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get chatListNewChat;

  /// No description provided for @chatListNewChatByUsernameTooltip.
  ///
  /// In en, this message translates to:
  /// **'New chat by username'**
  String get chatListNewChatByUsernameTooltip;

  /// No description provided for @chatListFindUser.
  ///
  /// In en, this message translates to:
  /// **'Find User'**
  String get chatListFindUser;

  /// No description provided for @chatListFindUserSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Find @{term}'**
  String chatListFindUserSearchTerm(String term);

  /// No description provided for @chatListDeleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get chatListDeleteConversation;

  /// No description provided for @chatListMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Media with {name}'**
  String chatListMediaTitle(String name);

  /// No description provided for @chatListMediaError.
  ///
  /// In en, this message translates to:
  /// **'Error loading media'**
  String get chatListMediaError;

  /// No description provided for @chatDetailViewFullProfile.
  ///
  /// In en, this message translates to:
  /// **'View Full Profile'**
  String get chatDetailViewFullProfile;

  /// No description provided for @chatMessageReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatMessageReply;

  /// No description provided for @chatMessageCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatMessageCopy;

  /// No description provided for @chatMessageCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get chatMessageCorrect;

  /// No description provided for @chatMessageTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get chatMessageTranslate;

  /// No description provided for @chatMessageSavePhrase.
  ///
  /// In en, this message translates to:
  /// **'Save phrase'**
  String get chatMessageSavePhrase;

  /// No description provided for @chatMessageEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get chatMessageEdit;

  /// No description provided for @chatMessageDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatMessageDelete;

  /// No description provided for @chatMessageRetrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try sending this message again'**
  String get chatMessageRetrySubtitle;

  /// No description provided for @chatMessageRemoveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this message'**
  String get chatMessageRemoveSubtitle;

  /// No description provided for @chatWallpaperPreviewHello.
  ///
  /// In en, this message translates to:
  /// **'Hello! 👋'**
  String get chatWallpaperPreviewHello;

  /// No description provided for @chatWallpaperPreviewHow.
  ///
  /// In en, this message translates to:
  /// **'How are you?'**
  String get chatWallpaperPreviewHow;

  /// No description provided for @chatGifSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search GIFs...'**
  String get chatGifSearchHint;

  /// No description provided for @communitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search or type @username'**
  String get communitySearchHint;

  /// No description provided for @communityUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User @{name} not found'**
  String communityUserNotFound(String name);

  /// No description provided for @communityTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get communityTabAll;

  /// No description provided for @communityTabGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get communityTabGender;

  /// No description provided for @communityTabCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get communityTabCity;

  /// No description provided for @communityRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get communityRefresh;

  /// No description provided for @communityNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get communityNoUsersFound;

  /// No description provided for @communityUnblockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unblock {name}?'**
  String communityUnblockConfirm(String name);

  /// No description provided for @communityUsernameCopied.
  ///
  /// In en, this message translates to:
  /// **'Username copied!'**
  String get communityUsernameCopied;

  /// No description provided for @communityLocationDetected.
  ///
  /// In en, this message translates to:
  /// **'Location detected: {country}'**
  String communityLocationDetected(String country);

  /// No description provided for @communityWaveLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get communityWaveLater;

  /// No description provided for @communityAboutMBTI.
  ///
  /// In en, this message translates to:
  /// **'MBTI'**
  String get communityAboutMBTI;

  /// No description provided for @voiceRoomReactTooltip.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get voiceRoomReactTooltip;

  /// No description provided for @momentsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get momentsCancel;

  /// No description provided for @momentsNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get momentsNotNow;

  /// No description provided for @commonOK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOK;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commonError(String error);

  /// No description provided for @chatActiveJustNow.
  ///
  /// In en, this message translates to:
  /// **'Active just now'**
  String get chatActiveJustNow;

  /// No description provided for @chatActiveMinAgo.
  ///
  /// In en, this message translates to:
  /// **'Active {min} min ago'**
  String chatActiveMinAgo(int min);

  /// No description provided for @chatActiveHourAgo.
  ///
  /// In en, this message translates to:
  /// **'Active 1 hour ago'**
  String get chatActiveHourAgo;

  /// No description provided for @chatActiveHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Active {hours}h ago'**
  String chatActiveHoursAgo(int hours);

  /// No description provided for @chatActiveYesterday.
  ///
  /// In en, this message translates to:
  /// **'Active yesterday'**
  String get chatActiveYesterday;

  /// No description provided for @chatActiveDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Active {days}d ago'**
  String chatActiveDaysAgo(int days);

  /// No description provided for @chatSayHiPrompt.
  ///
  /// In en, this message translates to:
  /// **'Say hi and start a conversation!'**
  String get chatSayHiPrompt;

  /// No description provided for @communityConversationStartersTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation Starters'**
  String get communityConversationStartersTitle;

  /// No description provided for @communityConversationStartersTopic.
  ///
  /// In en, this message translates to:
  /// **'You both love {topic} - ask about their favorite!'**
  String communityConversationStartersTopic(String topic);

  /// No description provided for @communityConversationStartersDefault.
  ///
  /// In en, this message translates to:
  /// **'Say hi and introduce yourself!'**
  String get communityConversationStartersDefault;

  /// No description provided for @communityConversationChatAction.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get communityConversationChatAction;

  /// No description provided for @communityConversationMessageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied! Paste to send.'**
  String get communityConversationMessageCopied;

  /// No description provided for @communityConversationCopiedToast.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard!'**
  String get communityConversationCopiedToast;

  /// No description provided for @communityLanguageMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Match'**
  String get communityLanguageMatchTitle;

  /// No description provided for @communityLanguageMatchNative.
  ///
  /// In en, this message translates to:
  /// **'Native'**
  String get communityLanguageMatchNative;

  /// No description provided for @communityLanguageMatchLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get communityLanguageMatchLearning;

  /// No description provided for @communityLanguageMatchPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect language exchange match!'**
  String get communityLanguageMatchPerfect;

  /// No description provided for @communityLanguageMatchSameNative.
  ///
  /// In en, this message translates to:
  /// **'You share the same native language'**
  String get communityLanguageMatchSameNative;

  /// No description provided for @momentsFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get momentsFilterApply;

  /// No description provided for @momentsCreateAddTo.
  ///
  /// In en, this message translates to:
  /// **'Add to your moment'**
  String get momentsCreateAddTo;

  /// No description provided for @momentsCreateCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get momentsCreateCategory;

  /// No description provided for @momentsCreateLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get momentsCreateLanguage;

  /// No description provided for @momentsCreateSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule (optional)'**
  String get momentsCreateSchedule;

  /// No description provided for @momentsCreateScheduleForLater.
  ///
  /// In en, this message translates to:
  /// **'Schedule for later'**
  String get momentsCreateScheduleForLater;

  /// No description provided for @momentsPrivacyPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get momentsPrivacyPublic;

  /// No description provided for @momentsPrivacyFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get momentsPrivacyFriends;

  /// No description provided for @momentsPrivacyPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get momentsPrivacyPrivate;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Learn · Chat · Meet'**
  String get splashTagline;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get splashLoading;

  /// No description provided for @supportSheetGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, I\'m Firdavs 👋'**
  String get supportSheetGreeting;

  /// No description provided for @supportSheetStory.
  ///
  /// In en, this message translates to:
  /// **'I built Bananatalk entirely on my own — every screen, every feature, every late-night bug fix. My goal is to help language learners around the world connect and grow, and I\'m constantly adding new features to make that happen.\n\nIf Bananatalk has helped you in any way, even a small coffee keeps me motivated to keep building. Every contribution means the world to a solo developer. 🙏'**
  String get supportSheetStory;

  /// No description provided for @supportSheetDonateButton.
  ///
  /// In en, this message translates to:
  /// **'Donate via PayPal'**
  String get supportSheetDonateButton;

  /// No description provided for @supportSheetWatchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to support'**
  String get supportSheetWatchAd;

  /// Field label for the user's job / occupation
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get occupation;

  /// Field label for the user's school / education
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get school;

  /// Hint inside the occupation picker search bar (filter-only — free-text input lives on the dedicated Custom tab)
  ///
  /// In en, this message translates to:
  /// **'Search occupations'**
  String get occupationSearchHint;

  /// Label above the currently picked occupation when it's a predefined option
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get occupationSelectedLabel;

  /// Label above the currently picked occupation when the user typed their own
  ///
  /// In en, this message translates to:
  /// **'Custom selection'**
  String get occupationCustomLabel;

  /// Empty state when search returns no predefined occupations; pairs with a button that jumps to the Custom tab
  ///
  /// In en, this message translates to:
  /// **'No matches in the list'**
  String get occupationNoMatches;

  /// No description provided for @occupationCatTech.
  ///
  /// In en, this message translates to:
  /// **'Technology & Software'**
  String get occupationCatTech;

  /// No description provided for @occupationCatHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare & Medicine'**
  String get occupationCatHealthcare;

  /// No description provided for @occupationCatEducation.
  ///
  /// In en, this message translates to:
  /// **'Education & Academia'**
  String get occupationCatEducation;

  /// No description provided for @occupationCatBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business & Finance'**
  String get occupationCatBusiness;

  /// No description provided for @occupationCatCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative & Design'**
  String get occupationCatCreative;

  /// No description provided for @occupationCatMedia.
  ///
  /// In en, this message translates to:
  /// **'Media & Communication'**
  String get occupationCatMedia;

  /// No description provided for @occupationCatEngineering.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get occupationCatEngineering;

  /// No description provided for @occupationCatScience.
  ///
  /// In en, this message translates to:
  /// **'Science & Research'**
  String get occupationCatScience;

  /// No description provided for @occupationCatLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get occupationCatLegal;

  /// No description provided for @occupationCatHospitality.
  ///
  /// In en, this message translates to:
  /// **'Hospitality & Food Service'**
  String get occupationCatHospitality;

  /// No description provided for @occupationCatTrades.
  ///
  /// In en, this message translates to:
  /// **'Trades & Skilled Labor'**
  String get occupationCatTrades;

  /// No description provided for @occupationCatTransport.
  ///
  /// In en, this message translates to:
  /// **'Transportation & Logistics'**
  String get occupationCatTransport;

  /// No description provided for @occupationCatGovernment.
  ///
  /// In en, this message translates to:
  /// **'Government & Public Service'**
  String get occupationCatGovernment;

  /// No description provided for @occupationCatRetail.
  ///
  /// In en, this message translates to:
  /// **'Retail & Customer Service'**
  String get occupationCatRetail;

  /// No description provided for @occupationCatAgriculture.
  ///
  /// In en, this message translates to:
  /// **'Agriculture & Environment'**
  String get occupationCatAgriculture;

  /// No description provided for @occupationCatSports.
  ///
  /// In en, this message translates to:
  /// **'Sports & Fitness'**
  String get occupationCatSports;

  /// No description provided for @occupationCatBeauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty & Personal Care'**
  String get occupationCatBeauty;

  /// No description provided for @occupationCatRealEstate.
  ///
  /// In en, this message translates to:
  /// **'Real Estate & Construction'**
  String get occupationCatRealEstate;

  /// No description provided for @occupationCatReligion.
  ///
  /// In en, this message translates to:
  /// **'Religion & Spirituality'**
  String get occupationCatReligion;

  /// No description provided for @occupationCatStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get occupationCatStudent;

  /// No description provided for @occupationCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get occupationCatOther;

  /// Placeholder text inside the school text field showing example school names
  ///
  /// In en, this message translates to:
  /// **'e.g. Seoul National University, Lincoln High'**
  String get schoolHint;

  /// Field label / screen title for the user's date of birth
  ///
  /// In en, this message translates to:
  /// **'Birthdate'**
  String get birthdate;

  /// Help text shown at the top of the native date picker on the birthdate edit screen
  ///
  /// In en, this message translates to:
  /// **'Select your birthdate'**
  String get birthdateSelectHelp;

  /// Placeholder shown inside the tappable date field when the user hasn't picked a birthdate yet
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get birthdateSelectPlaceholder;

  /// Inline error when the picked birthdate would make the user younger than the COPPA floor
  ///
  /// In en, this message translates to:
  /// **'You must be at least {age} years old.'**
  String birthdateMinAgeError(int age);

  /// Banner under the picker showing how many edits the user has left in the trailing 60-day window
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {max} birthdate changes remaining in the next 60 days.'**
  String birthdateQuotaRemaining(int remaining, int max);

  /// Banner under the picker when the user has hit the quota and cannot change birthdate further
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all {max} birthdate changes for this 60-day window.'**
  String birthdateQuotaLocked(int max);

  /// Suffix appended to the locked-quota banner telling the user when the earliest change will roll off
  ///
  /// In en, this message translates to:
  /// **'Next change available on {date}.'**
  String birthdateNextChangeOn(String date);

  /// Snackbar error when the server returned 429 on a birthdate update
  ///
  /// In en, this message translates to:
  /// **'Birthdate can only be changed 3 times in 60 days.'**
  String get birthdateRateLimited;

  /// Snackbar error when the server returned 429 on a birthdate update and supplied the next-available date
  ///
  /// In en, this message translates to:
  /// **'Birthdate can only be changed 3 times in 60 days. Try again on {date}.'**
  String birthdateRateLimitedUntil(String date);

  /// Title of the change-password screen and the Settings tile that opens it
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// Section label for the current-password field on the change-password screen
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// Section label for the new-password field on the change-password screen (lowercase variant; existing newPassword key uses title case for a different context)
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// Section label for the confirm-new-password field
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// Placeholder for the current-password field
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get currentPasswordHint;

  /// Placeholder summarising the strong-password rules in the new-password field
  ///
  /// In en, this message translates to:
  /// **'At least 8 chars, A-Z, a-z, 0-9'**
  String get newPasswordHint;

  /// Inline error shown when new and confirm passwords differ
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get passwordsDontMatch;

  /// Inline error shown when the new password equals the current one
  ///
  /// In en, this message translates to:
  /// **'New password must be different from current.'**
  String get newPasswordSameAsCurrent;

  /// Success snackbar shown after the change-password API returns 200
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// Strong-password requirement: minimum length
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordRule8Chars;

  /// Strong-password requirement: at least one lowercase letter
  ///
  /// In en, this message translates to:
  /// **'One lowercase letter'**
  String get passwordRuleLowercase;

  /// Strong-password requirement: at least one uppercase letter
  ///
  /// In en, this message translates to:
  /// **'One uppercase letter'**
  String get passwordRuleUppercase;

  /// Strong-password requirement: at least one digit
  ///
  /// In en, this message translates to:
  /// **'One number'**
  String get passwordRuleNumber;

  /// Section header on Settings grouping account-management actions (e.g., Change password)
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountSection;

  /// Subtitle on the Settings tile that opens the change-password screen
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get changePasswordTileSubtitle;

  /// Label of the dedicated tab in the occupation picker that lets the user type their own job title when it isn't in the predefined list
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get occupationCustomTab;

  /// Header copy on the Custom tab explaining the purpose of the free-text input
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your profession? Type it here.'**
  String get occupationCustomTabHint;

  /// Placeholder inside the text field on the Custom tab
  ///
  /// In en, this message translates to:
  /// **'e.g. Marine Biologist, Voice Actor'**
  String get occupationCustomInputHint;

  /// Button on the Custom tab that commits the typed value as the user's occupation
  ///
  /// In en, this message translates to:
  /// **'Use this as my occupation'**
  String get occupationCustomSaveCTA;

  /// No description provided for @vipSelectPlan.
  ///
  /// In en, this message translates to:
  /// **'Select Plan'**
  String get vipSelectPlan;

  /// No description provided for @vipBenefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get vipBenefits;

  /// No description provided for @vipBestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get vipBestValue;

  /// No description provided for @vipPlanMonth.
  ///
  /// In en, this message translates to:
  /// **'1 Month'**
  String get vipPlanMonth;

  /// No description provided for @vipPlanThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get vipPlanThreeMonths;

  /// No description provided for @vipPlanTwelveMonths.
  ///
  /// In en, this message translates to:
  /// **'12 Months'**
  String get vipPlanTwelveMonths;

  /// No description provided for @vipOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get vipOneTime;

  /// No description provided for @vipNonVip.
  ///
  /// In en, this message translates to:
  /// **'Non-VIP'**
  String get vipNonVip;

  /// No description provided for @vipBenefitDailyTranslations.
  ///
  /// In en, this message translates to:
  /// **'Daily translations'**
  String get vipBenefitDailyTranslations;

  /// No description provided for @vipBenefitTranslationsLimit.
  ///
  /// In en, this message translates to:
  /// **'5 / day'**
  String get vipBenefitTranslationsLimit;

  /// No description provided for @vipBenefitUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get vipBenefitUnlimited;

  /// No description provided for @vipBenefitAdvancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced filters'**
  String get vipBenefitAdvancedFilters;

  /// No description provided for @vipBenefitAdFree.
  ///
  /// In en, this message translates to:
  /// **'Ad-free experience'**
  String get vipBenefitAdFree;

  /// No description provided for @vipBenefitVipBadge.
  ///
  /// In en, this message translates to:
  /// **'VIP badge on profile'**
  String get vipBenefitVipBadge;

  /// No description provided for @vipBenefitPrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get vipBenefitPrioritySupport;

  /// No description provided for @vipBrandTitle.
  ///
  /// In en, this message translates to:
  /// **'BananaTalk VIP'**
  String get vipBrandTitle;

  /// No description provided for @vipTagline.
  ///
  /// In en, this message translates to:
  /// **'Your passport to global connections — authentic chats, lasting friends.'**
  String get vipTagline;

  /// No description provided for @vipDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Auto-renews unless canceled 24h before period end. Payment charged to your iTunes or Google Play account.'**
  String get vipDisclosure;

  /// No description provided for @vipLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue'**
  String get vipLoginRequired;

  /// No description provided for @chatListMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get chatListMenu;

  /// No description provided for @chatListNewMessageAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'New Message Alerts'**
  String get chatListNewMessageAlertsTitle;

  /// No description provided for @chatListNewMessageAlertsBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to turn on notifications and never miss a message'**
  String get chatListNewMessageAlertsBody;

  /// No description provided for @chatListFilterMyTurn.
  ///
  /// In en, this message translates to:
  /// **'My turn'**
  String get chatListFilterMyTurn;

  /// No description provided for @partnerTagActiveNow.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get partnerTagActiveNow;

  /// No description provided for @partnerTagVeryResponsive.
  ///
  /// In en, this message translates to:
  /// **'Very Responsive'**
  String get partnerTagVeryResponsive;

  /// No description provided for @partnerTagQuickToReply.
  ///
  /// In en, this message translates to:
  /// **'Quick to Reply'**
  String get partnerTagQuickToReply;

  /// No description provided for @vipSavePercent.
  ///
  /// In en, this message translates to:
  /// **'Save {pct}%'**
  String vipSavePercent(int pct);

  /// No description provided for @vipPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price} / mo'**
  String vipPerMonth(String price);

  /// No description provided for @partnerTagBothLike.
  ///
  /// In en, this message translates to:
  /// **'Both like {topic}'**
  String partnerTagBothLike(String topic);

  /// No description provided for @partnerTagSpeaks.
  ///
  /// In en, this message translates to:
  /// **'Speaks {language}'**
  String partnerTagSpeaks(String language);

  /// No description provided for @partnerTagLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning {language}'**
  String partnerTagLearning(String language);

  /// No description provided for @partnerTagJoinedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Joined {days}d ago'**
  String partnerTagJoinedDaysAgo(int days);

  /// No description provided for @vipPaymentPlanSummary.
  ///
  /// In en, this message translates to:
  /// **'Plan Summary'**
  String get vipPaymentPlanSummary;

  /// No description provided for @vipPaymentSelectMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get vipPaymentSelectMethod;

  /// No description provided for @vipPaymentPurchaseAppStore.
  ///
  /// In en, this message translates to:
  /// **'Purchase via App Store'**
  String get vipPaymentPurchaseAppStore;

  /// No description provided for @vipPaymentPurchaseGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'Purchase via Google Play'**
  String get vipPaymentPurchaseGooglePlay;

  /// No description provided for @vipPaymentSecureAppStore.
  ///
  /// In en, this message translates to:
  /// **'Your purchase will be processed securely through the App Store.'**
  String get vipPaymentSecureAppStore;

  /// No description provided for @vipPaymentSecureGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'Your purchase will be processed securely through Google Play.'**
  String get vipPaymentSecureGooglePlay;

  /// No description provided for @vipPaymentSubscriptionInfo.
  ///
  /// In en, this message translates to:
  /// **'Subscription Information'**
  String get vipPaymentSubscriptionInfo;

  /// No description provided for @vipPaymentInfoLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get vipPaymentInfoLabelTitle;

  /// No description provided for @vipPaymentInfoLabelLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get vipPaymentInfoLabelLength;

  /// No description provided for @vipPaymentInfoLabelPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get vipPaymentInfoLabelPrice;

  /// No description provided for @vipPaymentDisclosure.
  ///
  /// In en, this message translates to:
  /// **'By completing this purchase, you agree to our Terms of Use and Privacy Policy. Your subscription will automatically renew unless cancelled at least 24 hours before the end of the current period.'**
  String get vipPaymentDisclosure;

  /// No description provided for @vipSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to VIP!'**
  String get vipSuccessTitle;

  /// No description provided for @vipSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your VIP subscription is now active. Enjoy all premium features!'**
  String get vipSuccessBody;

  /// No description provided for @vipPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get vipPendingTitle;

  /// No description provided for @vipPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your subscription is processing — please try refreshing in a minute.'**
  String get vipPendingBody;

  /// No description provided for @vipErrorPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Error'**
  String get vipErrorPaymentTitle;

  /// No description provided for @vipErrorPurchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase Error'**
  String get vipErrorPurchaseTitle;

  /// No description provided for @vipErrorVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase Verification Failed'**
  String get vipErrorVerifyTitle;

  /// No description provided for @vipErrorPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get vipErrorPaymentFailed;

  /// No description provided for @vipErrorBodyPrefix.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while processing your payment:'**
  String get vipErrorBodyPrefix;

  /// No description provided for @vipErrorPurchaseCanceled.
  ///
  /// In en, this message translates to:
  /// **'Purchase was canceled or failed. Please try again.'**
  String get vipErrorPurchaseCanceled;

  /// No description provided for @vipErrorVerifyServer.
  ///
  /// In en, this message translates to:
  /// **'Could not verify purchase with server. Please contact support.'**
  String get vipErrorVerifyServer;

  /// No description provided for @vipPlanLengthOneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get vipPlanLengthOneMonth;

  /// No description provided for @vipPlanLengthThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get vipPlanLengthThreeMonths;

  /// No description provided for @vipPlanLengthOneYear.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get vipPlanLengthOneYear;

  /// No description provided for @vipPaymentPayPrice.
  ///
  /// In en, this message translates to:
  /// **'Pay {price}'**
  String vipPaymentPayPrice(String price);

  /// No description provided for @vipExpired.
  ///
  /// In en, this message translates to:
  /// **'VIP Expired'**
  String get vipExpired;

  /// No description provided for @vipMember.
  ///
  /// In en, this message translates to:
  /// **'VIP Member'**
  String get vipMember;

  /// No description provided for @chatPhrasesMostUsed.
  ///
  /// In en, this message translates to:
  /// **'Most Used'**
  String get chatPhrasesMostUsed;

  /// No description provided for @chatPhrasesTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get chatPhrasesTopics;

  /// No description provided for @chatPhrasesAddPhrase.
  ///
  /// In en, this message translates to:
  /// **'Add a phrase'**
  String get chatPhrasesAddPhrase;

  /// No description provided for @chatPhrasesChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get chatPhrasesChange;

  /// No description provided for @chatPhrasesAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a phrase'**
  String get chatPhrasesAddTitle;

  /// No description provided for @chatPhrasesAddHint.
  ///
  /// In en, this message translates to:
  /// **'Type a phrase you use often'**
  String get chatPhrasesAddHint;

  /// No description provided for @chatPhrasesEmptyMostUsed.
  ///
  /// In en, this message translates to:
  /// **'No saved phrases yet. Tap + to add one.'**
  String get chatPhrasesEmptyMostUsed;

  /// No description provided for @chatPhrasesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this phrase?'**
  String get chatPhrasesDeleteTitle;

  /// No description provided for @filterVipPromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your perfect match faster'**
  String get filterVipPromoTitle;

  /// No description provided for @filterVipPromoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock priority discovery, advanced filters, and ad-free chats with VIP.'**
  String get filterVipPromoSubtitle;

  /// No description provided for @filterVipPromoCta.
  ///
  /// In en, this message translates to:
  /// **'Go VIP'**
  String get filterVipPromoCta;

  /// No description provided for @examStudy.
  ///
  /// In en, this message translates to:
  /// **'Exam Study'**
  String get examStudy;

  /// No description provided for @examStudyChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your study language'**
  String get examStudyChooseLanguage;

  /// No description provided for @examStudyChooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the language you want to prepare an exam in.'**
  String get examStudyChooseLanguageSubtitle;

  /// No description provided for @examStudyLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get examStudyLoading;

  /// No description provided for @examStudyEmptyLanguages.
  ///
  /// In en, this message translates to:
  /// **'No study languages available yet.'**
  String get examStudyEmptyLanguages;

  /// No description provided for @examStudyError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load — please try again.'**
  String get examStudyError;

  /// No description provided for @examStudyRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get examStudyRetry;

  /// No description provided for @examPickExam.
  ///
  /// In en, this message translates to:
  /// **'Choose an exam'**
  String get examPickExam;

  /// No description provided for @examPickExamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the exam you want to prepare for.'**
  String get examPickExamSubtitle;

  /// No description provided for @examPickEmpty.
  ///
  /// In en, this message translates to:
  /// **'No exams available for this language yet.'**
  String get examPickEmpty;

  /// No description provided for @examDashboardSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get examDashboardSections;

  /// No description provided for @examDashboardEmptySections.
  ///
  /// In en, this message translates to:
  /// **'No sections to practice yet.'**
  String get examDashboardEmptySections;

  /// No description provided for @examDashboardContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue practice'**
  String get examDashboardContinue;

  /// No description provided for @examDashboardStartStudyPlan.
  ///
  /// In en, this message translates to:
  /// **'Start study plan'**
  String get examDashboardStartStudyPlan;

  /// No description provided for @examDashboardViewProgress.
  ///
  /// In en, this message translates to:
  /// **'View progress'**
  String get examDashboardViewProgress;

  /// No description provided for @examMetaDuration.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String examMetaDuration(int minutes);

  /// No description provided for @examMetaMaxScore.
  ///
  /// In en, this message translates to:
  /// **'Max {score}'**
  String examMetaMaxScore(String score);

  /// No description provided for @examMetaSections.
  ///
  /// In en, this message translates to:
  /// **'{count} sections'**
  String examMetaSections(int count);

  /// No description provided for @examSectionNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get examSectionNotStarted;

  /// No description provided for @examSectionProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} done'**
  String examSectionProgress(int done, int total);

  /// No description provided for @examQuestionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit answer'**
  String get examQuestionSubmit;

  /// No description provided for @examQuestionNext.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get examQuestionNext;

  /// No description provided for @examQuestionCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get examQuestionCorrect;

  /// No description provided for @examQuestionIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get examQuestionIncorrect;

  /// No description provided for @examQuestionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get examQuestionExplanation;

  /// No description provided for @examQuestionNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions in this section yet.'**
  String get examQuestionNoQuestions;

  /// No description provided for @examQuestionEssayComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Essay evaluation is coming soon. Try a reading section for now.'**
  String get examQuestionEssayComingSoon;

  /// No description provided for @examQuestionUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This question type isn\'t supported yet.'**
  String get examQuestionUnsupported;

  /// No description provided for @examPracticeFinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Section complete'**
  String get examPracticeFinishedTitle;

  /// No description provided for @examPracticeFinishedBody.
  ///
  /// In en, this message translates to:
  /// **'Nice work — you\'ve completed every question in this section.'**
  String get examPracticeFinishedBody;

  /// No description provided for @examPracticeBackToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to dashboard'**
  String get examPracticeBackToDashboard;

  /// No description provided for @examPracticeProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String examPracticeProgress(int current, int total);

  /// No description provided for @examEssayPrompt.
  ///
  /// In en, this message translates to:
  /// **'Write your essay'**
  String get examEssayPrompt;

  /// No description provided for @examEssayMinChars.
  ///
  /// In en, this message translates to:
  /// **'Essay must be at least {min} characters'**
  String examEssayMinChars(int min);

  /// No description provided for @examEssayMaxChars.
  ///
  /// In en, this message translates to:
  /// **'Essay must not exceed {max} characters'**
  String examEssayMaxChars(int max);

  /// No description provided for @examEssayWordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String examEssayWordCount(int count);

  /// No description provided for @examEssayCharCount.
  ///
  /// In en, this message translates to:
  /// **'{count} characters'**
  String examEssayCharCount(int count);

  /// No description provided for @examEssaySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit essay'**
  String get examEssaySubmit;

  /// No description provided for @examEssayEvaluating.
  ///
  /// In en, this message translates to:
  /// **'Evaluating your essay…'**
  String get examEssayEvaluating;

  /// No description provided for @examEssayEvaluatingHint.
  ///
  /// In en, this message translates to:
  /// **'This usually takes 10–30 seconds. You can leave this screen — we\'ll keep evaluating in the background.'**
  String get examEssayEvaluatingHint;

  /// No description provided for @examEssayResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluation'**
  String get examEssayResultTitle;

  /// No description provided for @examEssayResultStrengths.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get examEssayResultStrengths;

  /// No description provided for @examEssayResultImprovements.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get examEssayResultImprovements;

  /// No description provided for @examEssayResultScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get examEssayResultScore;

  /// No description provided for @examEssayResultFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t evaluate this essay.'**
  String get examEssayResultFailed;

  /// No description provided for @examEssayResultRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get examEssayResultRetry;

  /// No description provided for @examEssayResultDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get examEssayResultDone;

  /// No description provided for @examEssayPollTimeout.
  ///
  /// In en, this message translates to:
  /// **'Still evaluating — check back in a minute.'**
  String get examEssayPollTimeout;

  /// No description provided for @examEssayPollRefresh.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get examEssayPollRefresh;

  /// No description provided for @examEssayQuotaUsed.
  ///
  /// In en, this message translates to:
  /// **'Daily essay evaluations: {used}/{limit}'**
  String examEssayQuotaUsed(int used, int limit);

  /// No description provided for @examEssayQuotaExhausted.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s free essay evaluations. Upgrade to VIP for unlimited.'**
  String get examEssayQuotaExhausted;

  /// No description provided for @examEssayQuotaUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to VIP'**
  String get examEssayQuotaUpgrade;

  /// No description provided for @examEssayDraftRestored.
  ///
  /// In en, this message translates to:
  /// **'Draft restored'**
  String get examEssayDraftRestored;

  /// No description provided for @examProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get examProgressTitle;

  /// No description provided for @examProgressOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall score'**
  String get examProgressOverall;

  /// No description provided for @examProgressNotStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'No practice yet'**
  String get examProgressNotStartedTitle;

  /// No description provided for @examProgressNotStartedBody.
  ///
  /// In en, this message translates to:
  /// **'Answer a few questions in any section to see your progress here.'**
  String get examProgressNotStartedBody;

  /// No description provided for @examProgressFocusAreas.
  ///
  /// In en, this message translates to:
  /// **'Focus areas'**
  String get examProgressFocusAreas;

  /// No description provided for @examProgressSectionAttempts.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} attempted'**
  String examProgressSectionAttempts(int done, int total);

  /// No description provided for @examProgressNoFocusAreas.
  ///
  /// In en, this message translates to:
  /// **'You\'re doing well across every section — keep practicing!'**
  String get examProgressNoFocusAreas;

  /// No description provided for @examPlanSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Start study plan'**
  String get examPlanSetupTitle;

  /// No description provided for @examPlanTargetScore.
  ///
  /// In en, this message translates to:
  /// **'Target score'**
  String get examPlanTargetScore;

  /// No description provided for @examPlanExamDate.
  ///
  /// In en, this message translates to:
  /// **'Exam date'**
  String get examPlanExamDate;

  /// No description provided for @examPlanPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get examPlanPickDate;

  /// No description provided for @examPlanGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate plan'**
  String get examPlanGenerate;

  /// No description provided for @examPlanGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating your plan…'**
  String get examPlanGenerating;

  /// No description provided for @examPlanInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Please pick a future exam date.'**
  String get examPlanInvalidDate;

  /// No description provided for @examPlanInvalidScore.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid target score.'**
  String get examPlanInvalidScore;

  /// No description provided for @examPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Study plan'**
  String get examPlanTitle;

  /// No description provided for @examPlanEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No active plan'**
  String get examPlanEmptyTitle;

  /// No description provided for @examPlanEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Generate a plan to get weekly milestones tailored to your weak areas.'**
  String get examPlanEmptyBody;

  /// No description provided for @examPlanRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate plan'**
  String get examPlanRegenerate;

  /// No description provided for @examPlanWeek.
  ///
  /// In en, this message translates to:
  /// **'Week {n}'**
  String examPlanWeek(int n);

  /// No description provided for @examPlanWeekEstimate.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String examPlanWeekEstimate(String hours);

  /// No description provided for @examPlanTotalHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours total'**
  String examPlanTotalHours(int hours);

  /// No description provided for @examPlanDailyHeading.
  ///
  /// In en, this message translates to:
  /// **'Suggested daily lessons'**
  String get examPlanDailyHeading;

  /// No description provided for @examPlanLessonMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String examPlanLessonMinutes(int minutes);

  /// No description provided for @examTopicPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a topic'**
  String get examTopicPickerTitle;

  /// No description provided for @examTopicPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice questions on a specific subject, or jump into all questions.'**
  String get examTopicPickerSubtitle;

  /// No description provided for @examTopicAllTopics.
  ///
  /// In en, this message translates to:
  /// **'All topics'**
  String get examTopicAllTopics;

  /// No description provided for @examTopicAllTopicsDescription.
  ///
  /// In en, this message translates to:
  /// **'Mix from every available topic'**
  String get examTopicAllTopicsDescription;

  /// No description provided for @examTopicEmpty.
  ///
  /// In en, this message translates to:
  /// **'No topical content yet. Tap All topics to start practicing.'**
  String get examTopicEmpty;

  /// No description provided for @examTopicQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String examTopicQuestionCount(int count);

  /// No description provided for @examTopicOneQuestion.
  ///
  /// In en, this message translates to:
  /// **'1 question'**
  String get examTopicOneQuestion;

  /// No description provided for @examSpeakingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Speak your answer'**
  String get examSpeakingPrompt;

  /// No description provided for @examSpeakingListenToPrompt.
  ///
  /// In en, this message translates to:
  /// **'Listen to prompt'**
  String get examSpeakingListenToPrompt;

  /// No description provided for @examSpeakingTapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to record your answer'**
  String get examSpeakingTapToRecord;

  /// No description provided for @examSpeakingTranscriptHeading.
  ///
  /// In en, this message translates to:
  /// **'What we heard'**
  String get examSpeakingTranscriptHeading;

  /// No description provided for @examSpeakingPart1.
  ///
  /// In en, this message translates to:
  /// **'Speaking — Part 1'**
  String get examSpeakingPart1;

  /// No description provided for @examSpeakingPart2.
  ///
  /// In en, this message translates to:
  /// **'Speaking — Part 2'**
  String get examSpeakingPart2;

  /// No description provided for @examSpeakingPart3.
  ///
  /// In en, this message translates to:
  /// **'Speaking — Part 3'**
  String get examSpeakingPart3;

  /// No description provided for @examSpeakingSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit recording'**
  String get examSpeakingSubmit;

  /// No description provided for @examSpeakingUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get examSpeakingUploading;

  /// No description provided for @examSpeakingTooShort.
  ///
  /// In en, this message translates to:
  /// **'Recording is too short. Please speak for at least a few seconds.'**
  String get examSpeakingTooShort;

  /// Dashboard group title — Writing
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get examGroupWriting;

  /// Dashboard group title — Speaking
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get examGroupSpeaking;

  /// Dashboard group subtitle — sub-section count for Writing
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task} other{{count} tasks}}'**
  String examGroupWritingSubtitle(int count);

  /// Dashboard group subtitle — sub-section count for Speaking
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 part} other{{count} parts}}'**
  String examGroupSpeakingSubtitle(int count);

  /// AppBar — Vocabulary level picker
  ///
  /// In en, this message translates to:
  /// **'Pick a level'**
  String get examVocabLevelPickerTitle;

  /// Subtitle above the CEFR level grid
  ///
  /// In en, this message translates to:
  /// **'Browse words and practice quizzes by CEFR level.'**
  String get examVocabLevelPickerSubtitle;

  /// Heading — Vocabulary topic picker
  ///
  /// In en, this message translates to:
  /// **'Pick a topic'**
  String get examVocabTopicPickerTitle;

  /// Tile label — no topic filter
  ///
  /// In en, this message translates to:
  /// **'All topics'**
  String get examVocabAllTopics;

  /// Mode toggle — browse word cards
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get examVocabBrowse;

  /// Mode toggle — practice quiz
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get examVocabPractice;

  /// Shown when the word list is empty
  ///
  /// In en, this message translates to:
  /// **'No words yet for this level and topic.'**
  String get examVocabEmptyList;

  /// AppBar after quiz submit
  ///
  /// In en, this message translates to:
  /// **'Quiz complete'**
  String get examVocabQuizComplete;

  /// Score line on the quiz result screen
  ///
  /// In en, this message translates to:
  /// **'You answered {correct} of {total} correctly'**
  String examVocabQuizScore(int correct, int total);

  /// Result row — user's answer
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get examVocabQuizYourAnswer;

  /// Result row — correct answer
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get examVocabQuizCorrectAnswer;

  /// Submit button on final quiz question
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get examVocabQuizSubmit;

  /// Submit button label while in-flight
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get examVocabQuizSubmitting;

  /// Next-question button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get examVocabQuizNext;

  /// Previous-question button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get examVocabQuizPrev;

  /// Restart-quiz button on result + on expiry
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get examVocabQuizRestart;

  /// Empty state when the quiz can't be built
  ///
  /// In en, this message translates to:
  /// **'No questions could be generated. Try another topic or level.'**
  String get examVocabQuizEmpty;

  /// Pool-too-small error from the backend
  ///
  /// In en, this message translates to:
  /// **'Not enough words at this level and topic to build a quiz.'**
  String get examVocabQuizNotEnough;

  /// Title for the quiz-expired dialog
  ///
  /// In en, this message translates to:
  /// **'Quiz expired'**
  String get examVocabQuizExpiredTitle;

  /// Body for the quiz-expired dialog
  ///
  /// In en, this message translates to:
  /// **'This quiz has been idle too long. Restart to get a fresh one.'**
  String get examVocabQuizExpiredBody;

  /// Tooltip on the word-card translate icon
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get examVocabTranslate;

  /// Inline error when translation returns empty
  ///
  /// In en, this message translates to:
  /// **'Translation unavailable. Try again later.'**
  String get examVocabTranslateFailed;

  /// Quick action — open the tips screen
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get examDashboardTips;

  /// AppBar of the study tips screen
  ///
  /// In en, this message translates to:
  /// **'Tips & Techniques'**
  String get examTipsTitle;

  /// Subtitle under the tips title; takes the exam name
  ///
  /// In en, this message translates to:
  /// **'Curated strategy notes for {examName}.'**
  String examTipsSubtitle(String examName);

  /// Shown when no tips exist for the exam
  ///
  /// In en, this message translates to:
  /// **'No tips have been published for this exam yet.'**
  String get examTipsEmpty;

  /// Tip group label
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get examTipsCategoryStrategy;

  /// Tip group label
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get examTipsCategoryGrammar;

  /// Tip group label
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get examTipsCategoryVocabulary;

  /// Tip group label
  ///
  /// In en, this message translates to:
  /// **'Time Management'**
  String get examTipsCategoryTimeManagement;

  /// Tip group label
  ///
  /// In en, this message translates to:
  /// **'Common Mistakes'**
  String get examTipsCategoryCommonMistakes;

  /// Tip group label
  ///
  /// In en, this message translates to:
  /// **'Band Boosters'**
  String get examTipsCategoryBandBooster;

  /// Tip group label
  ///
  /// In en, this message translates to:
  /// **'Cultural Notes'**
  String get examTipsCategoryCulturalNotes;

  /// Tip group label
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get examTipsCategoryPronunciation;

  /// Tip group label
  ///
  /// In en, this message translates to:
  /// **'Fluency'**
  String get examTipsCategoryFluency;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'de', 'en', 'es', 'fr', 'hi', 'id', 'it', 'ja', 'ko', 'pt', 'ru', 'tg', 'th', 'tl', 'tr', 'vi', 'zh'].contains(locale.languageCode);

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
    case 'tg': return AppLocalizationsTg();
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
