// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tagalog (`tl`).
class AppLocalizationsTl extends AppLocalizations {
  AppLocalizationsTl([String locale = 'tl']) : super(locale);

  @override
  String get appName => 'BananaTalk';

  @override
  String get login => 'Mag-login';

  @override
  String get signUp => 'Mag-sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Nakalimutan ang Password?';

  @override
  String get or => 'O';

  @override
  String get signInWithGoogle => 'Mag-sign in gamit ang Google';

  @override
  String get signInWithApple => 'Mag-sign in gamit ang Apple';

  @override
  String get signInWithFacebook => 'Mag-sign in gamit ang Facebook';

  @override
  String get welcome => 'Maligayang pagdating';

  @override
  String get home => 'Home';

  @override
  String get messages => 'Mga Mensahe';

  @override
  String get moments => 'Mga Sandali';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Mga Setting';

  @override
  String get logout => 'Mag-logout';

  @override
  String get language => 'Wika';

  @override
  String get selectLanguage => 'Pumili ng Wika';

  @override
  String get autoTranslate => 'Auto-translate';

  @override
  String get autoTranslateMessages => 'Auto-translate ng mga Mensahe';

  @override
  String get autoTranslateMoments => 'Auto-translate ng mga Sandali';

  @override
  String get autoTranslateComments => 'Auto-translate ng mga Komento';

  @override
  String get translate => 'I-translate';

  @override
  String get translated => 'Naisalin';

  @override
  String get showOriginal => 'Ipakita ang Original';

  @override
  String get showTranslation => 'Ipakita ang Salin';

  @override
  String get translating => 'Nagsasalin...';

  @override
  String get translationFailed => 'Nabigo ang pagsasalin';

  @override
  String get noTranslationAvailable => 'Walang available na salin';

  @override
  String translatedFrom(String language) {
    return 'Isinalin mula sa $language';
  }

  @override
  String get save => 'I-save';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get delete => 'Burahin';

  @override
  String get edit => 'I-edit';

  @override
  String get share => 'Ibahagi';

  @override
  String get like => 'Like';

  @override
  String get comment => 'Komento';

  @override
  String get send => 'Ipadala';

  @override
  String get search => 'Maghanap';

  @override
  String get notifications => 'Mga Notipikasyon';

  @override
  String get followers => 'Mga Tagasunod';

  @override
  String get following => 'Sinusundan';

  @override
  String get posts => 'Mga Post';

  @override
  String get visitors => 'Mga Bisita';

  @override
  String get loading => 'Naglo-load...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Tagumpay';

  @override
  String get tryAgain => 'Subukan Muli';

  @override
  String get networkError => 'Error sa network. Suriin ang iyong koneksyon.';

  @override
  String get somethingWentWrong => 'May nangyaring mali';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Oo';

  @override
  String get no => 'Hindi';

  @override
  String get languageSettings => 'Mga Setting ng Wika';

  @override
  String get deviceLanguage => 'Wika ng Device';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return 'Ang iyong device ay naka-set sa: $flag $name';
  }

  @override
  String get youCanOverride => 'Maaari mong baguhin ang wika ng device sa ibaba.';

  @override
  String languageChangedTo(String name) {
    return 'Binago ang wika sa $name';
  }

  @override
  String get errorChangingLanguage => 'Error sa pagbabago ng wika';

  @override
  String get autoTranslateSettings => 'Mga Setting ng Auto-Translate';

  @override
  String get automaticallyTranslateIncomingMessages => 'Awtomatikong i-translate ang mga papasok na mensahe';

  @override
  String get automaticallyTranslateMomentsInFeed => 'Awtomatikong i-translate ang mga sandali sa feed';

  @override
  String get automaticallyTranslateComments => 'Awtomatikong i-translate ang mga komento';

  @override
  String get translationServiceBeingConfigured => 'Ini-configure ang translation service. Subukan muli mamaya.';

  @override
  String get translationUnavailable => 'Hindi available ang translation';

  @override
  String get showLess => 'ipakita ng mas kaunti';

  @override
  String get showMore => 'ipakita pa';

  @override
  String get comments => 'Mga Komento';

  @override
  String get beTheFirstToComment => 'Maging una sa pagkomento.';

  @override
  String get writeAComment => 'Magsulat ng komento...';

  @override
  String get report => 'I-report';

  @override
  String get reportMoment => 'I-report ang Sandali';

  @override
  String get reportUser => 'I-report ang User';

  @override
  String get deleteMoment => 'Burahin ang Sandali?';

  @override
  String get thisActionCannotBeUndone => 'Hindi na maaaring bawiin ang aksyong ito.';

  @override
  String get momentDeleted => 'Nabura ang sandali';

  @override
  String get deleteComment => 'Delete Comment?';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get editFeatureComingSoon => 'Malapit nang dumating ang edit feature';

  @override
  String get userNotFound => 'Hindi nahanap ang user';

  @override
  String get cannotReportYourOwnComment => 'Hindi mo maaaring i-report ang sarili mong komento';

  @override
  String get profileSettings => 'Mga Setting ng Profile';

  @override
  String get editYourProfileInformation => 'I-edit ang impormasyon ng iyong profile';

  @override
  String get blockedUsers => 'Mga Na-block na User';

  @override
  String get manageBlockedUsers => 'Pamahalaan ang mga na-block na user';

  @override
  String get manageNotificationSettings => 'Pamahalaan ang mga setting ng notipikasyon';

  @override
  String get privacySecurity => 'Privacy at Seguridad';

  @override
  String get controlYourPrivacy => 'Kontrolin ang iyong privacy';

  @override
  String get changeAppLanguage => 'Baguhin ang wika ng app';

  @override
  String get appearance => 'Hitsura';

  @override
  String get themeAndDisplaySettings => 'Mga setting ng tema at display';

  @override
  String get myReports => 'Mga Report Ko';

  @override
  String get viewYourSubmittedReports => 'Tingnan ang iyong mga na-submit na report';

  @override
  String get reportsManagement => 'Pamamahala ng mga Report';

  @override
  String get manageAllReportsAdmin => 'Pamahalaan ang lahat ng report (Admin)';

  @override
  String get legalPrivacy => 'Legal at Privacy';

  @override
  String get termsPrivacySubscriptionInfo => 'Terms, Privacy at impormasyon ng subscription';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get getHelpAndSupport => 'Kumuha ng tulong at suporta';

  @override
  String get aboutBanaTalk => 'Tungkol sa BanaTalk';

  @override
  String get deleteAccount => 'Burahin ang Account';

  @override
  String get permanentlyDeleteYourAccount => 'Permanenteng burahin ang iyong account';

  @override
  String get loggedOutSuccessfully => 'Matagumpay na nag-logout';

  @override
  String get retry => 'Subukan Muli';

  @override
  String get giftsLikes => 'Mga Regalo/Like';

  @override
  String get details => 'Mga Detalye';

  @override
  String get to => 'kay';

  @override
  String get banaTalk => 'BanaTalk';

  @override
  String get chats => 'Mga Chat';

  @override
  String get community => 'Komunidad';

  @override
  String get editProfile => 'I-edit ang Profile';

  @override
  String yearsOld(String age) {
    return '$age taong gulang';
  }

  @override
  String get searchConversations => 'Maghanap ng mga usapan...';

  @override
  String get visitorTrackingNotAvailable => 'Hindi pa available ang visitor tracking feature. Kailangan ng backend update.';

  @override
  String get chatList => 'Listahan ng Chat';

  @override
  String get languageExchange => 'Language Exchange';

  @override
  String get nativeLanguage => 'Katutubong Wika';

  @override
  String get learning => 'Nag-aaral';

  @override
  String get notSet => 'Hindi naka-set';

  @override
  String get about => 'Tungkol';

  @override
  String get aboutMe => 'Tungkol sa Akin';

  @override
  String get bloodType => 'Uri ng Dugo';

  @override
  String get photos => 'Mga Larawan';

  @override
  String get camera => 'Camera';

  @override
  String get createMoment => 'Gumawa ng Sandali';

  @override
  String get addATitle => 'Magdagdag ng pamagat...';

  @override
  String get whatsOnYourMind => 'Ano ang iniisip mo?';

  @override
  String get addTags => 'Magdagdag ng mga Tag';

  @override
  String get done => 'Tapos na';

  @override
  String get add => 'Idagdag';

  @override
  String get enterTag => 'Maglagay ng tag';

  @override
  String get post => 'I-post';

  @override
  String get commentAddedSuccessfully => 'Matagumpay na naidagdag ang komento';

  @override
  String get clearFilters => 'I-clear ang mga Filter';

  @override
  String get notificationSettings => 'Mga Setting ng Notipikasyon';

  @override
  String get enableNotifications => 'I-enable ang mga Notipikasyon';

  @override
  String get turnAllNotificationsOnOrOff => 'I-on o i-off ang lahat ng notipikasyon';

  @override
  String get notificationTypes => 'Mga Uri ng Notipikasyon';

  @override
  String get chatMessages => 'Mga Mensahe sa Chat';

  @override
  String get getNotifiedWhenYouReceiveMessages => 'Maabisuhan kapag nakatanggap ka ng mga mensahe';

  @override
  String get likesAndCommentsOnYourMoments => 'Mga like at komento sa iyong mga sandali';

  @override
  String get whenPeopleYouFollowPostMoments => 'Kapag nag-post ng mga sandali ang mga taong sinusundan mo';

  @override
  String get friendRequests => 'Mga Friend Request';

  @override
  String get whenSomeoneFollowsYou => 'Kapag may sumunod sa iyo';

  @override
  String get profileVisits => 'Mga Bisita sa Profile';

  @override
  String get whenSomeoneViewsYourProfileVIP => 'Kapag may tumingin sa iyong profile (VIP)';

  @override
  String get marketing => 'Marketing';

  @override
  String get updatesAndPromotionalMessages => 'Mga update at promotional na mensahe';

  @override
  String get notificationPreferences => 'Mga Kagustuhan sa Notipikasyon';

  @override
  String get sound => 'Tunog';

  @override
  String get playNotificationSounds => 'Magpatugtog ng mga tunog ng notipikasyon';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrateOnNotifications => 'Mag-vibrate sa mga notipikasyon';

  @override
  String get showPreview => 'Ipakita ang Preview';

  @override
  String get showMessagePreviewInNotifications => 'Ipakita ang preview ng mensahe sa mga notipikasyon';

  @override
  String get mutedConversations => 'Mga Naka-mute na Usapan';

  @override
  String get conversation => 'Usapan';

  @override
  String get unmute => 'I-unmute';

  @override
  String get systemNotificationSettings => 'Mga Setting ng System Notification';

  @override
  String get manageNotificationsInSystemSettings => 'Pamahalaan ang mga notipikasyon sa system settings';

  @override
  String get errorLoadingSettings => 'Error sa paglo-load ng mga setting';

  @override
  String get unblockUser => 'I-unblock ang User';

  @override
  String get unblock => 'I-unblock';

  @override
  String get goBack => 'Bumalik';

  @override
  String get messageSendTimeout => 'Nag-timeout ang pagpapadala ng mensahe. Suriin ang iyong koneksyon.';

  @override
  String get failedToSendMessage => 'Nabigo ang pagpapadala ng mensahe';

  @override
  String get dailyMessageLimitExceeded => 'Nalampasan na ang daily message limit. Mag-upgrade sa VIP para sa unlimited na mga mensahe.';

  @override
  String get cannotSendMessageUserMayBeBlocked => 'Hindi maipadala ang mensahe. Maaaring naka-block ang user.';

  @override
  String get sessionExpired => 'Nag-expire na ang session. Mag-login muli.';

  @override
  String get sendThisSticker => 'Ipadala ang sticker na ito?';

  @override
  String get chooseHowYouWantToDeleteThisMessage => 'Piliin kung paano mo gustong burahin ang mensaheng ito:';

  @override
  String get deleteForEveryone => 'Burahin para sa lahat';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => 'Tinatanggal ang mensahe para sa iyo at sa tatanggap';

  @override
  String get deleteForMe => 'Burahin para sa akin';

  @override
  String get removesTheMessageOnlyFromYourChat => 'Tinatanggal ang mensahe mula sa iyong chat lamang';

  @override
  String get copy => 'Kopyahin';

  @override
  String get reply => 'Tumugon';

  @override
  String get forward => 'I-forward';

  @override
  String get moreOptions => 'Higit pang mga Opsyon';

  @override
  String get noUsersAvailableToForwardTo => 'Walang available na user para i-forward';

  @override
  String get searchMoments => 'Maghanap ng mga sandali...';

  @override
  String searchInChatWith(String name) {
    return 'Maghanap sa chat kasama si $name';
  }

  @override
  String get typeAMessage => 'Mag-type ng mensahe...';

  @override
  String get enterYourMessage => 'Ilagay ang iyong mensahe';

  @override
  String get detectYourLocation => 'I-detect ang iyong lokasyon';

  @override
  String get tapToUpdateLocation => 'I-tap para i-update ang lokasyon';

  @override
  String get helpOthersFindYouNearby => 'Tulungan ang iba na mahanap ka sa malapit';

  @override
  String get selectYourNativeLanguage => 'Piliin ang iyong katutubong wika';

  @override
  String get whichLanguageDoYouWantToLearn => 'Anong wika ang gusto mong matutunan?';

  @override
  String get selectYourGender => 'Piliin ang iyong kasarian';

  @override
  String get addACaption => 'Magdagdag ng caption...';

  @override
  String get typeSomething => 'Mag-type ng kahit ano...';

  @override
  String get gallery => 'Gallery';

  @override
  String get video => 'Video';

  @override
  String get text => 'Text';

  @override
  String get provideMoreInformation => 'Magbigay ng higit pang impormasyon...';

  @override
  String get searchByNameLanguageOrInterests => 'Maghanap sa pamamagitan ng pangalan, wika, o interes...';

  @override
  String get addTagAndPressEnter => 'Magdagdag ng tag at pindutin ang enter';

  @override
  String replyTo(String name) {
    return 'Tumugon kay $name...';
  }

  @override
  String get highlightName => 'Pangalan ng highlight';

  @override
  String get searchCloseFriends => 'Maghanap ng mga kaibigan...';

  @override
  String get askAQuestion => 'Magtanong...';

  @override
  String option(String number) {
    return 'Opsyon $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return 'Bakit mo ito ini-report $type?';
  }

  @override
  String get additionalDetailsOptional => 'Karagdagang detalye (opsyonal)';

  @override
  String get warningThisActionIsPermanent => 'Babala: Permanente ang aksyong ito!';

  @override
  String get deletingYourAccountWillPermanentlyRemove => 'Deleting your account will permanently remove:\n\n• Your profile and all personal data\n• All your messages and conversations\n• All your moments and stories\n• Your VIP subscription (no refund)\n• All your connections and followers\n\nThis action cannot be undone.';

  @override
  String get clearAllNotifications => 'I-clear ang lahat ng notipikasyon?';

  @override
  String get clearAll => 'I-clear Lahat';

  @override
  String get notificationDebug => 'Notification Debug';

  @override
  String get markAllRead => 'Markahan lahat na nabasa';

  @override
  String get clearAll2 => 'Clear all';

  @override
  String get emailAddress => 'Email address';

  @override
  String get username => 'Username';

  @override
  String get alreadyHaveAnAccount => 'Mayroon nang account?';

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
  String get couldNotOpenLink => 'Hindi mabuksan ang link';

  @override
  String get legalPrivacy2 => 'Legal & Privacy';

  @override
  String get termsOfUseEULA => 'Mga Tuntunin ng Paggamit (EULA)';

  @override
  String get viewOurTermsAndConditions => 'Tingnan ang aming mga tuntunin at kundisyon';

  @override
  String get privacyPolicy => 'Patakaran sa Privacy';

  @override
  String get howWeHandleYourData => 'Paano namin pinangangasiwaan ang iyong data';

  @override
  String get emailNotifications => 'Mga Email Notification';

  @override
  String get receiveEmailNotificationsFromBananaTalk => 'Tumanggap ng mga email notification mula sa BananaTalk';

  @override
  String get weeklySummary => 'Lingguhang Buod';

  @override
  String get activityRecapEverySunday => 'Recap ng aktibidad tuwing Linggo';

  @override
  String get newMessages => 'Mga Bagong Mensahe';

  @override
  String get whenYoureAwayFor24PlusHours => 'Kapag wala ka ng 24+ oras';

  @override
  String get newFollowers => 'Mga Bagong Tagasunod';

  @override
  String get whenSomeoneFollowsYou2 => 'When someone follows you';

  @override
  String get securityAlerts => 'Mga Alerto sa Seguridad';

  @override
  String get passwordLoginAlerts => 'Mga alerto sa password at login';

  @override
  String get unblockUser2 => 'Unblock User';

  @override
  String get blockedUsers2 => 'Blocked Users';

  @override
  String get finalWarning => 'Huling Babala';

  @override
  String get deleteForever => 'Burahin Habang-buhay';

  @override
  String get deleteAccount2 => 'Delete Account';

  @override
  String get enterYourPassword => 'Ilagay ang iyong password';

  @override
  String get yourPassword => 'Ang iyong password';

  @override
  String get typeDELETEToConfirm => 'I-type ang DELETE para kumpirmahin';

  @override
  String get typeDELETEInCapitalLetters => 'I-type ang DELETE sa malalaking letra';

  @override
  String sent(String emoji) {
    return '$emoji naipadala!';
  }

  @override
  String get replySent => 'Naipadala ang tugon!';

  @override
  String get deleteStory => 'Burahin ang Story?';

  @override
  String get thisStoryWillBeRemovedPermanently => 'Permanenteng tatanggalin ang story na ito.';

  @override
  String get noStories => 'Walang mga story';

  @override
  String views(String count) {
    return '$count views';
  }

  @override
  String get reportStory => 'I-report ang Story';

  @override
  String get reply2 => 'Reply...';

  @override
  String get failedToPickImage => 'Nabigo ang pagpili ng larawan';

  @override
  String get failedToTakePhoto => 'Nabigo ang pagkuha ng larawan';

  @override
  String get failedToPickVideo => 'Nabigo ang pagpili ng video';

  @override
  String get pleaseEnterSomeText => 'Mangyaring maglagay ng text';

  @override
  String get pleaseSelectMedia => 'Mangyaring pumili ng media';

  @override
  String get storyPosted => 'Na-post ang story!';

  @override
  String get textOnlyStoriesRequireAnImage => 'Kailangan ng larawan ang text-only stories';

  @override
  String get createStory => 'Gumawa ng Story';

  @override
  String get change => 'Baguhin';

  @override
  String get userIdNotFound => 'Hindi nahanap ang User ID. Mag-login muli.';

  @override
  String get pleaseSelectAPaymentMethod => 'Mangyaring pumili ng paraan ng pagbabayad';

  @override
  String get startExploring => 'Magsimulang Mag-explore';

  @override
  String get close => 'Isara';

  @override
  String get payment => 'Pagbabayad';

  @override
  String get upgradeToVIP => 'Mag-upgrade sa VIP';

  @override
  String get errorLoadingProducts => 'Error sa paglo-load ng mga produkto';

  @override
  String get cancelVIPSubscription => 'Kanselahin ang VIP Subscription';

  @override
  String get keepVIP => 'Panatilihin ang VIP';

  @override
  String get cancelSubscription => 'Kanselahin ang Subscription';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'Matagumpay na nakansela ang VIP subscription';

  @override
  String get vipStatus => 'Status ng VIP';

  @override
  String get noActiveVIPSubscription => 'Walang aktibong VIP subscription';

  @override
  String get subscriptionExpired => 'Nag-expire ang Subscription';

  @override
  String get vipExpiredMessage => 'Nag-expire na ang iyong VIP subscription. Mag-renew ngayon para patuloy na mag-enjoy ng unlimited features!';

  @override
  String get expiredOn => 'Nag-expire noong';

  @override
  String get renewVIP => 'I-renew ang VIP';

  @override
  String get whatYoureMissing => 'Ano ang napapalampas mo';

  @override
  String get manageInAppStore => 'Pamahalaan sa App Store';

  @override
  String get becomeVIP => 'Maging VIP';

  @override
  String get unlimitedMessages => 'Unlimited na Mensahe';

  @override
  String get unlimitedProfileViews => 'Unlimited na Profile Views';

  @override
  String get prioritySupport => 'Priority Support';

  @override
  String get advancedSearch => 'Advanced Search';

  @override
  String get profileBoost => 'Profile Boost';

  @override
  String get adFreeExperience => 'Walang Ads na Karanasan';

  @override
  String get upgradeYourAccount => 'I-upgrade ang Iyong Account';

  @override
  String get moreMessages => 'Higit pang mga Mensahe';

  @override
  String get moreProfileViews => 'Higit pang Profile Views';

  @override
  String get connectWithFriends => 'Kumonekta sa mga Kaibigan';

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
  String get skip => 'Laktawan';

  @override
  String get startReview => 'Simulan ang Review';

  @override
  String get resolve => 'Lutasin';

  @override
  String get dismiss => 'I-dismiss';

  @override
  String get filterReports => 'I-filter ang mga Report';

  @override
  String get all => 'Lahat';

  @override
  String get clear => 'I-clear';

  @override
  String get apply => 'Ilapat';

  @override
  String get myReports2 => 'My Reports';

  @override
  String get blockUser => 'I-block ang User';

  @override
  String get block => 'I-block';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => 'Gusto mo rin bang i-block ang user na ito?';

  @override
  String get noThanks => 'Hindi, salamat';

  @override
  String get yesBlockThem => 'Oo, i-block sila';

  @override
  String get reportUser2 => 'Report User';

  @override
  String get submitReport => 'Isumite ang Report';

  @override
  String get addAQuestionAndAtLeast2Options => 'Add a question and at least 2 options';

  @override
  String get addOption => 'Magdagdag ng opsyon';

  @override
  String get anonymousVoting => 'Anonymous na pagboto';

  @override
  String get create => 'Gumawa';

  @override
  String get typeYourAnswer => 'I-type ang iyong sagot...';

  @override
  String get send2 => 'Send';

  @override
  String get yourPrompt => 'Ang iyong prompt...';

  @override
  String get add2 => 'Add';

  @override
  String get contentNotAvailable => 'Hindi available ang content';

  @override
  String get profileNotAvailable => 'Hindi available ang profile';

  @override
  String get noMomentsToShow => 'Walang mga sandaling ipapakita';

  @override
  String get storiesNotAvailable => 'Hindi available ang mga story';

  @override
  String get cantMessageThisUser => 'Hindi maaaring ma-message ang user na ito';

  @override
  String get pleaseSelectAReason => 'Mangyaring pumili ng dahilan';

  @override
  String get reportSubmitted => 'Naisumite ang report. Salamat sa pagtulong na panatilihing ligtas ang aming komunidad.';

  @override
  String get youHaveAlreadyReportedThisMoment => 'Nai-report mo na ang sandaling ito';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => 'Sabihin sa amin kung bakit mo ito ini-report';

  @override
  String get errorSharing => 'Error sa pagbabahagi';

  @override
  String get deviceInfo => 'Impormasyon ng Device';

  @override
  String get recommended => 'Inirerekomenda';

  @override
  String get anyLanguage => 'Kahit anong Wika';

  @override
  String get noLanguagesFound => 'Walang nahanap na mga wika';

  @override
  String get selectALanguage => 'Pumili ng wika';

  @override
  String get languagesAreStillLoading => 'Naglo-load pa ang mga wika...';

  @override
  String get selectNativeLanguage => 'Piliin ang katutubong wika';

  @override
  String get subscriptionDetails => 'Mga Detalye ng Subscription';

  @override
  String get activeFeatures => 'Mga Aktibong Feature';

  @override
  String get legalInformation => 'Legal na Impormasyon';

  @override
  String get termsOfUse => 'Mga Tuntunin ng Paggamit';

  @override
  String get manageSubscription => 'Pamahalaan ang Subscription';

  @override
  String get manageSubscriptionInSettings => 'Para kanselahin ang iyong subscription, pumunta sa Settings > [Iyong Pangalan] > Subscriptions sa iyong device.';

  @override
  String get contactSupportToCancel => 'Para kanselahin ang iyong subscription, mangyaring makipag-ugnayan sa aming support team.';

  @override
  String get status => 'Status';

  @override
  String get active => 'Aktibo';

  @override
  String get plan => 'Plano';

  @override
  String get startDate => 'Petsa ng Pagsisimula';

  @override
  String get endDate => 'Petsa ng Pagtatapos';

  @override
  String get nextBillingDate => 'Susunod na Petsa ng Pagsingil';

  @override
  String get autoRenew => 'Auto Renew';

  @override
  String get pleaseLogInToContinue => 'Mangyaring mag-login para magpatuloy';

  @override
  String get purchaseCanceledOrFailed => 'Nakansela o nabigo ang pagbili. Subukan muli.';

  @override
  String get maximumTagsAllowed => 'Maximum na 5 tags ang pinapayagan';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => 'Mangyaring tanggalin muna ang mga larawan para magdagdag ng video';

  @override
  String get unsupportedFormat => 'Hindi suportadong format';

  @override
  String get errorProcessingVideo => 'Error sa pagproseso ng video';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'Mangyaring tanggalin muna ang mga larawan para mag-record ng video';

  @override
  String get locationAdded => 'Naidagdag ang lokasyon';

  @override
  String get failedToGetLocation => 'Nabigo ang pagkuha ng lokasyon';

  @override
  String get notNow => 'Hindi Ngayon';

  @override
  String get videoUploadFailed => 'Nabigo ang Pag-upload ng Video';

  @override
  String get skipVideo => 'Laktawan ang Video';

  @override
  String get retryUpload => 'Subukang Muli ang Upload';

  @override
  String get momentCreatedSuccessfully => 'Matagumpay na nagawa ang sandali';

  @override
  String get uploadingMomentInBackground => 'Ina-upload ang sandali sa background...';

  @override
  String get failedToQueueUpload => 'Nabigo ang pag-queue ng upload';

  @override
  String get viewProfile => 'Tingnan ang Profile';

  @override
  String get mediaLinksAndDocs => 'Media, links, at docs';

  @override
  String get wallpaper => 'Wallpaper';

  @override
  String get userIdNotAvailable => 'Hindi available ang User ID';

  @override
  String get cannotBlockYourself => 'Hindi mo maaaring i-block ang sarili mo';

  @override
  String get chatWallpaper => 'Wallpaper ng Chat';

  @override
  String get wallpaperSavedLocally => 'Nai-save ang wallpaper sa local';

  @override
  String get messageCopied => 'Nakopya ang mensahe';

  @override
  String get forwardFeatureComingSoon => 'Malapit nang dumating ang forward feature';

  @override
  String get momentUnsaved => 'Inalis sa naka-save';

  @override
  String get documentPickerComingSoon => 'Malapit nang dumating ang document picker';

  @override
  String get contactSharingComingSoon => 'Malapit nang dumating ang contact sharing';

  @override
  String get featureComingSoon => 'Malapit nang dumating ang feature';

  @override
  String get answerSent => 'Naipadala ang sagot!';

  @override
  String get noImagesAvailable => 'Walang available na mga larawan';

  @override
  String get mentionPickerComingSoon => 'Malapit nang dumating ang mention picker';

  @override
  String get musicPickerComingSoon => 'Malapit nang dumating ang music picker';

  @override
  String get repostFeatureComingSoon => 'Malapit nang dumating ang repost feature';

  @override
  String get addFriendsFromYourProfile => 'Magdagdag ng mga kaibigan mula sa iyong profile';

  @override
  String get quickReplyAdded => 'Naidagdag ang quick reply';

  @override
  String get quickReplyDeleted => 'Nabura ang quick reply';

  @override
  String get linkCopied => 'Nakopya ang link!';

  @override
  String get maximumOptionsAllowed => 'Maximum na 10 opsyon ang pinapayagan';

  @override
  String get minimumOptionsRequired => 'Minimum na 2 opsyon ang kailangan';

  @override
  String get pleaseEnterAQuestion => 'Mangyaring maglagay ng tanong';

  @override
  String get pleaseAddAtLeast2Options => 'Mangyaring magdagdag ng hindi bababa sa 2 opsyon';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => 'Mangyaring piliin ang tamang sagot para sa quiz';

  @override
  String get correctionSent => 'Naipadala ang pagwawasto!';

  @override
  String get sort => 'I-sort';

  @override
  String get savedMoments => 'Mga Nai-save na Sandali';

  @override
  String get unsave => 'I-unsave';

  @override
  String get playingAudio => 'Nagpe-play ang audio...';

  @override
  String get failedToGenerateQuiz => 'Nabigo ang paggawa ng quiz';

  @override
  String get failedToAddComment => 'Nabigo ang pagdagdag ng komento';

  @override
  String get hello => 'Kumusta!';

  @override
  String get howAreYou => 'Kumusta ka?';

  @override
  String get cannotOpen => 'Hindi mabuksan';

  @override
  String get errorOpeningLink => 'Error sa pagbukas ng link';

  @override
  String get saved => 'Nai-save';

  @override
  String get follow => 'Sundan';

  @override
  String get unfollow => 'I-unfollow';

  @override
  String get mute => 'I-mute';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get lastSeen => 'Huling nakita';

  @override
  String get justNow => 'ngayon lang';

  @override
  String minutesAgo(String count) {
    return '$count minuto ang nakalipas';
  }

  @override
  String hoursAgo(String count) {
    return '$count oras ang nakalipas';
  }

  @override
  String get yesterday => 'Kahapon';

  @override
  String get signInWithEmail => 'Mag-sign in gamit ang Email';

  @override
  String get partners => 'Mga Partner';

  @override
  String get nearby => 'Malapit';

  @override
  String get topics => 'Mga Paksa';

  @override
  String get waves => 'Mga Wave';

  @override
  String get voiceRooms => 'Voice';

  @override
  String get filters => 'Mga Filter';

  @override
  String get searchCommunity => 'Maghanap sa pamamagitan ng pangalan, wika, o interes...';

  @override
  String get bio => 'Bio';

  @override
  String get noBioYet => 'Wala pang bio.';

  @override
  String get languages => 'Mga Wika';

  @override
  String get native => 'Katutubong';

  @override
  String get interests => 'Mga Interes';

  @override
  String get noMomentsYet => 'Wala pang mga sandali';

  @override
  String get unableToLoadMoments => 'Hindi ma-load ang mga sandali';

  @override
  String get map => 'Mapa';

  @override
  String get mapUnavailable => 'Hindi available ang mapa';

  @override
  String get location => 'Lokasyon';

  @override
  String get unknownLocation => 'Hindi kilalang lokasyon';

  @override
  String get noImagesAvailable2 => 'No images available';

  @override
  String get permissionsRequired => 'Kailangan ang mga Permiso';

  @override
  String get openSettings => 'Buksan ang Settings';

  @override
  String get refresh => 'I-refresh';

  @override
  String get videoCall => 'Video';

  @override
  String get voiceCall => 'Tawag';

  @override
  String get message => 'Mensahe';

  @override
  String get pleaseLoginToFollow => 'Mangyaring mag-login para sundan ang mga user';

  @override
  String get pleaseLoginToCall => 'Mangyaring mag-login para tumawag';

  @override
  String get cannotCallYourself => 'Hindi mo maaaring tawagan ang sarili mo';

  @override
  String get failedToFollowUser => 'Nabigo ang pagsunod sa user';

  @override
  String get failedToUnfollowUser => 'Nabigo ang pag-unfollow sa user';

  @override
  String get areYouSureUnfollow => 'Sigurado ka bang gusto mong i-unfollow ang user na ito?';

  @override
  String get areYouSureUnblock => 'Sigurado ka bang gusto mong i-unblock ang user na ito?';

  @override
  String get youFollowed => 'Sinundan mo';

  @override
  String get youUnfollowed => 'In-unfollow mo';

  @override
  String get alreadyFollowing => 'Sinusundan mo na';

  @override
  String get soon => 'Malapit na';

  @override
  String comingSoon(String feature) {
    return 'Malapit nang dumating ang $feature!';
  }

  @override
  String get muteNotifications => 'I-mute ang mga notipikasyon';

  @override
  String get unmuteNotifications => 'I-unmute ang mga notipikasyon';

  @override
  String get operationCompleted => 'Nakumpleto ang operasyon';

  @override
  String get couldNotOpenMaps => 'Hindi mabuksan ang maps';

  @override
  String hasntSharedMoments(Object name) {
    return 'Hindi pa nagbabahagi si $name ng mga sandali';
  }

  @override
  String messageUser(String name) {
    return 'I-message si $name';
  }

  @override
  String notFollowingUser(String name) {
    return 'Hindi mo sinusundan si $name';
  }

  @override
  String youFollowedUser(String name) {
    return 'Sinundan mo si $name';
  }

  @override
  String youUnfollowedUser(String name) {
    return 'In-unfollow mo si $name';
  }

  @override
  String unfollowUser(String name) {
    return 'I-unfollow si $name';
  }

  @override
  String get typing => 'nagta-type';

  @override
  String get connecting => 'Kumokonekta...';

  @override
  String daysAgo(int count) {
    return '${count}d ang nakalipas';
  }

  @override
  String get maxTagsAllowed => 'Maximum na 5 tags ang pinapayagan';

  @override
  String maxImagesAllowed(int count) {
    return 'Maximum na $count larawan ang pinapayagan';
  }

  @override
  String get pleaseRemoveImagesFirst => 'Please remove images first to add a video';

  @override
  String get exchange3MessagesBeforeCall => 'Kailangan mong magpalitan ng hindi bababa sa 3 mensahe bago ka makatawag sa user na ito';

  @override
  String mediaWithUser(String name) {
    return 'Media kasama si $name';
  }

  @override
  String get errorLoadingMedia => 'Error sa paglo-load ng media';

  @override
  String get savedMomentsTitle => 'Mga Nai-save na Sandali';

  @override
  String get removeBookmark => 'Alisin ang bookmark?';

  @override
  String get thisWillRemoveBookmark => 'Aalisin nito ang mensahe mula sa iyong mga bookmark.';

  @override
  String get remove => 'Alisin';

  @override
  String get bookmarkRemoved => 'Naalis ang bookmark';

  @override
  String get bookmarkedMessages => 'Mga Na-bookmark na Mensahe';

  @override
  String get wallpaperSaved => 'Wallpaper saved locally';

  @override
  String get typeDeleteToConfirm => 'Type DELETE to confirm';

  @override
  String get storyArchive => 'Archive ng Story';

  @override
  String get newHighlight => 'Bagong Highlight';

  @override
  String get addToHighlight => 'Idagdag sa Highlight';

  @override
  String get repost => 'I-repost';

  @override
  String get repostFeatureSoon => 'Repost feature coming soon';

  @override
  String get closeFriends => 'Mga Matalik na Kaibigan';

  @override
  String get addFriends => 'Magdagdag ng mga Kaibigan';

  @override
  String get highlights => 'Mga Highlight';

  @override
  String get createHighlight => 'Gumawa ng Highlight';

  @override
  String get deleteHighlight => 'Burahin ang Highlight?';

  @override
  String get editHighlight => 'I-edit ang Highlight';

  @override
  String get addMoreToStory => 'Magdagdag pa sa story';

  @override
  String get noViewersYet => 'Wala pang mga tumitingin';

  @override
  String get noReactionsYet => 'Wala pang mga reaksyon';

  @override
  String get leaveRoom => 'Umalis sa Room?';

  @override
  String get areYouSureLeaveRoom => 'Sigurado ka bang gusto mong umalis sa voice room na ito?';

  @override
  String get stay => 'Manatili';

  @override
  String get leave => 'Umalis';

  @override
  String get enableGPS => 'I-enable ang GPS';

  @override
  String wavedToUser(String name) {
    return 'Kumaway kay $name!';
  }

  @override
  String get areYouSureFollow => 'Sigurado ka bang gusto mong sundan';

  @override
  String get failedToLoadProfile => 'Nabigo ang paglo-load ng profile';

  @override
  String get noFollowersYet => 'Wala pang mga tagasunod';

  @override
  String get noFollowingYet => 'Wala pang sinusundan';

  @override
  String get searchUsers => 'Maghanap ng mga user...';

  @override
  String get noResultsFound => 'Walang nahanap na resulta';

  @override
  String get loadingFailed => 'Nabigo ang paglo-load';

  @override
  String get copyLink => 'Kopyahin ang link';

  @override
  String get shareStory => 'Ibahagi ang story';

  @override
  String get thisWillDeleteStory => 'Permanenteng buburahin nito ang story na ito.';

  @override
  String get storyDeleted => 'Nabura ang story';

  @override
  String get addCaption => 'Magdagdag ng caption...';

  @override
  String get yourStory => 'Iyong Story';

  @override
  String get sendMessage => 'Magpadala ng mensahe';

  @override
  String get replyToStory => 'Tumugon sa story...';

  @override
  String get viewAllReplies => 'Tingnan ang lahat ng tugon';

  @override
  String get preparingVideo => 'Inihahandang video...';

  @override
  String videoOptimized(String size, String savings) {
    return 'Na-optimize ang video: ${size}MB (nakatipid ng $savings%)';
  }

  @override
  String get failedToProcessVideo => 'Nabigo ang pagproseso ng video';

  @override
  String get optimizingForBestExperience => 'Ino-optimize para sa pinakamahusay na karanasan sa story';

  @override
  String get pleaseSelectImageOrVideo => 'Mangyaring pumili ng larawan o video para sa iyong story';

  @override
  String get storyCreatedSuccessfully => 'Matagumpay na nagawa ang story!';

  @override
  String get uploadingStoryInBackground => 'Ina-upload ang story sa background...';

  @override
  String get storyCreationFailed => 'Nabigo ang Paggawa ng Story';

  @override
  String get pleaseCheckConnection => 'Suriin ang iyong koneksyon at subukan muli.';

  @override
  String get uploadFailed => 'Nabigo ang Upload';

  @override
  String get tryShorterVideo => 'Subukang gumamit ng mas maikling video o subukan muli mamaya.';

  @override
  String get shareMomentsThatDisappear => 'Magbahagi ng mga sandaling mawawala sa loob ng 24 oras';

  @override
  String get photo => 'Larawan';

  @override
  String get record => 'I-record';

  @override
  String get addSticker => 'Magdagdag ng Sticker';

  @override
  String get poll => 'Poll';

  @override
  String get question => 'Tanong';

  @override
  String get mention => 'Mention';

  @override
  String get music => 'Musika';

  @override
  String get hashtag => 'Hashtag';

  @override
  String get whoCanSeeThis => 'Sino ang makakakita nito?';

  @override
  String get everyone => 'Lahat';

  @override
  String get anyoneCanSeeStory => 'Kahit sino ay makakakita ng story na ito';

  @override
  String get friendsOnly => 'Mga Kaibigan Lamang';

  @override
  String get onlyFollowersCanSee => 'Ang iyong mga tagasunod lamang ang makakakita';

  @override
  String get onlyCloseFriendsCanSee => 'Ang iyong mga matalik na kaibigan lamang ang makakakita';

  @override
  String get backgroundColor => 'Kulay ng Background';

  @override
  String get fontStyle => 'Istilo ng Font';

  @override
  String get normal => 'Normal';

  @override
  String get bold => 'Bold';

  @override
  String get italic => 'Italic';

  @override
  String get handwriting => 'Sulat-kamay';

  @override
  String get addLocation => 'Magdagdag ng Lokasyon';

  @override
  String get enterLocationName => 'Ilagay ang pangalan ng lokasyon';

  @override
  String get addLink => 'Magdagdag ng Link';

  @override
  String get buttonText => 'Text ng button';

  @override
  String get learnMore => 'Alamin Pa';

  @override
  String get addHashtags => 'Magdagdag ng mga Hashtag';

  @override
  String get addHashtag => 'Magdagdag ng hashtag';

  @override
  String get sendAsMessage => 'Ipadala bilang Mensahe';

  @override
  String get shareExternally => 'Ibahagi sa Labas';

  @override
  String get checkOutStory => 'Tingnan ang story na ito sa BananaTalk!';

  @override
  String viewsTab(String count) {
    return 'Views ($count)';
  }

  @override
  String reactionsTab(String count) {
    return 'Reaksyon ($count)';
  }

  @override
  String get processingVideo => 'Pinoproseso ang video...';

  @override
  String get link => 'Link';

  @override
  String unmuteUser(String name) {
    return 'I-unmute si $name?';
  }

  @override
  String get willReceiveNotifications => 'Makakatanggap ka ng mga notipikasyon para sa mga bagong mensahe.';

  @override
  String muteNotificationsFor(String name) {
    return 'I-mute ang mga notipikasyon para kay $name';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return 'Na-unmute ang mga notipikasyon para kay $name';
  }

  @override
  String notificationsMutedFor(String name) {
    return 'Na-mute ang mga notipikasyon para kay $name';
  }

  @override
  String get failedToUpdateMuteSettings => 'Nabigo ang pag-update ng mga setting ng mute';

  @override
  String get oneHour => '1 oras';

  @override
  String get eightHours => '8 oras';

  @override
  String get oneWeek => '1 linggo';

  @override
  String get always => 'Palagi';

  @override
  String get failedToLoadBookmarks => 'Nabigo ang paglo-load ng mga bookmark';

  @override
  String get noBookmarkedMessages => 'Walang mga na-bookmark na mensahe';

  @override
  String get longPressToBookmark => 'Pindutin nang matagal ang mensahe para i-bookmark';

  @override
  String get thisWillRemoveFromBookmarks => 'Aalisin nito ang mensahe mula sa iyong mga bookmark.';

  @override
  String navigateToMessage(String name) {
    return 'Pumunta sa mensahe sa chat kasama si $name';
  }

  @override
  String bookmarkedOn(String date) {
    return 'Na-bookmark noong $date';
  }

  @override
  String get voiceMessage => 'Voice message';

  @override
  String get document => 'Dokumento';

  @override
  String get attachment => 'Attachment';

  @override
  String get sendMeAMessage => 'Magpadala sa akin ng mensahe';

  @override
  String get shareWithFriends => 'Ibahagi sa mga kaibigan';

  @override
  String get shareAnywhere => 'Ibahagi kahit saan';

  @override
  String get emailPreferences => 'Mga Kagustuhan sa Email';

  @override
  String get receiveEmailNotifications => 'Tumanggap ng mga email notification mula sa BananaTalk';

  @override
  String get whenAwayFor24Hours => 'Kapag wala ka ng 24+ oras';

  @override
  String get passwordAndLoginAlerts => 'Mga alerto sa password at login';

  @override
  String get failedToLoadPreferences => 'Nabigo ang paglo-load ng mga kagustuhan';

  @override
  String get failedToUpdateSetting => 'Nabigo ang pag-update ng setting';

  @override
  String get securityAlertsRecommended => 'Inirerekomenda naming panatilihing naka-enable ang Security Alerts para manatiling may kaalaman tungkol sa mahalagang aktibidad ng account.';

  @override
  String chatWallpaperFor(String name) {
    return 'Wallpaper ng chat para kay $name';
  }

  @override
  String get solidColors => 'Solid na mga Kulay';

  @override
  String get gradients => 'Mga Gradient';

  @override
  String get customImage => 'Custom na Larawan';

  @override
  String get chooseFromGallery => 'Pumili mula sa gallery';

  @override
  String get preview => 'Preview';

  @override
  String get wallpaperUpdated => 'Na-update ang wallpaper';

  @override
  String get category => 'Kategorya';

  @override
  String get mood => 'Mood';

  @override
  String get sortBy => 'I-sort Ayon Sa';

  @override
  String get timePeriod => 'Panahon';

  @override
  String get searchLanguages => 'Maghanap ng mga wika...';

  @override
  String get selected => 'Napili';

  @override
  String get categories => 'Mga Kategorya';

  @override
  String get moods => 'Mga Mood';

  @override
  String get applyFilters => 'Ilapat ang mga Filter';

  @override
  String applyNFilters(int count) {
    return 'Ilapat ang $count Filter';
  }

  @override
  String get videoMustBeUnder1GB => 'Dapat mas mababa sa 1GB ang video.';

  @override
  String get failedToRecordVideo => 'Nabigo ang pag-record ng video';

  @override
  String get errorSendingVideo => 'Error sa pagpapadala ng video';

  @override
  String get errorSendingVoiceMessage => 'Error sa pagpapadala ng voice message';

  @override
  String get errorSendingMedia => 'Error sa pagpapadala ng media';

  @override
  String get cameraPermissionRequired => 'Kailangan ang mga permiso sa camera at mikropono para mag-record ng video.';

  @override
  String get locationPermissionRequired => 'Kailangan ang permiso sa lokasyon para ibahagi ang iyong lokasyon.';

  @override
  String get noInternetConnection => 'Walang koneksyon sa internet';

  @override
  String get tryAgainLater => 'Subukan muli mamaya';

  @override
  String get messageSent => 'Naipadala ang mensahe';

  @override
  String get messageDeleted => 'Nabura ang mensahe';

  @override
  String get messageEdited => 'Na-edit ang mensahe';

  @override
  String get edited => '(na-edit)';

  @override
  String get now => 'ngayon';

  @override
  String weeksAgo(int count) {
    return '$count linggo ang nakalipas';
  }

  @override
  String viewRepliesCount(int count) {
    return '── Tingnan ang $count tugon';
  }

  @override
  String get hideReplies => '── Itago ang mga tugon';

  @override
  String get saveMoment => 'I-save ang Moment';

  @override
  String get removeFromSaved => 'Alisin sa Naka-save';

  @override
  String get momentSaved => 'Na-save';

  @override
  String get failedToSave => 'Hindi na-save';

  @override
  String checkOutMoment(String title) {
    return 'Tingnan ang moment na ito: $title';
  }

  @override
  String get failedToLoadMoments => 'Hindi na-load ang mga moment';

  @override
  String get noMomentsMatchFilters => 'Walang moment na tumutugma sa iyong mga filter';

  @override
  String get beFirstToShareMoment => 'Maging una sa pagbahagi ng moment!';

  @override
  String get tryDifferentSearch => 'Subukan ang ibang salita sa paghahanap';

  @override
  String get tryAdjustingFilters => 'Subukang i-adjust ang iyong mga filter';

  @override
  String get noSavedMoments => 'Walang naka-save na moment';

  @override
  String get tapBookmarkToSave => 'I-tap ang bookmark icon para i-save ang moment';

  @override
  String get failedToLoadVideo => 'Hindi na-load ang video';

  @override
  String get titleRequired => 'Kailangan ang pamagat';

  @override
  String titleTooLong(int max) {
    return 'Ang pamagat ay dapat $max character o mas kaunti';
  }

  @override
  String get descriptionRequired => 'Kailangan ang paglalarawan';

  @override
  String descriptionTooLong(int max) {
    return 'Ang paglalarawan ay dapat $max character o mas kaunti';
  }

  @override
  String get scheduledDateMustBeFuture => 'Ang naka-schedule na petsa ay dapat sa hinaharap';

  @override
  String get recent => 'Kamakailan';

  @override
  String get popular => 'Sikat';

  @override
  String get trending => 'Trending';

  @override
  String get mostRecent => 'Pinakabago';

  @override
  String get mostPopular => 'Pinakasikat';

  @override
  String get allTime => 'Lahat ng Oras';

  @override
  String get today => 'Ngayon';

  @override
  String get thisWeek => 'Ngayong Linggo';

  @override
  String get thisMonth => 'Ngayong Buwan';

  @override
  String replyingTo(String userName) {
    return 'Sumasagot kay $userName';
  }

  @override
  String get listView => 'Listahan';

  @override
  String get quickMatch => 'Mabilis na match';

  @override
  String get onlineNow => 'Online ngayon';

  @override
  String speaksLanguage(String language) {
    return 'Nagsasalita ng $language';
  }

  @override
  String learningLanguage(String language) {
    return 'Nag-aaral ng $language';
  }

  @override
  String get noPartnersFound => 'Walang nahanap na partner';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return 'Walang nahanap na user na nagsasalita ng $learning bilang katutubong wika o gustong matuto ng $native.';
  }

  @override
  String get removeAllFilters => 'Alisin lahat ng filter';

  @override
  String get browseAllUsers => 'Tingnan lahat ng user';

  @override
  String get allCaughtUp => 'Nakita mo na lahat!';

  @override
  String get loadingMore => 'Naglo-load pa...';

  @override
  String get findingMorePartners => 'Naghahanap pa ng mga partner...';

  @override
  String get seenAllPartners => 'Nakita mo na lahat ng partner';

  @override
  String get startOver => 'Magsimula muli';

  @override
  String get changeFilters => 'Baguhin ang mga filter';

  @override
  String get findingPartners => 'Naghahanap ng mga partner...';

  @override
  String get setLocationReminder => 'I-set ang iyong lokasyon para mahanap ang mga partner na malapit';

  @override
  String get updateLocationReminder => 'I-update ang iyong lokasyon para sa mas magandang resulta';

  @override
  String get male => 'Lalaki';

  @override
  String get female => 'Babae';

  @override
  String get other => 'Iba pa';

  @override
  String get browseMen => 'Maghanap ng mga lalaki';

  @override
  String get browseWomen => 'Maghanap ng mga babae';

  @override
  String get noMaleUsersFound => 'Walang nahanap na lalaking user';

  @override
  String get noFemaleUsersFound => 'Walang nahanap na babaeng user';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => 'Mga bagong user lamang';

  @override
  String get showNewUsers => 'Ipakita ang mga bagong user';

  @override
  String get prioritizeNearby => 'Unahin ang mga malapit';

  @override
  String get showNearbyFirst => 'Ipakita muna ang mga malapit';

  @override
  String get setLocationToEnable => 'I-set ang lokasyon para ma-enable';

  @override
  String get radius => 'Radius';

  @override
  String get findingYourLocation => 'Hinahanap ang iyong lokasyon...';

  @override
  String get enableLocationForDistance => 'I-enable ang lokasyon para sa distansya';

  @override
  String get enableLocationDescription => 'I-enable ang mga serbisyo ng lokasyon para mahanap ang mga partner sa malapit';

  @override
  String get enableGps => 'I-enable ang GPS';

  @override
  String get browseByCityCountry => 'Maghanap ayon sa lungsod/bansa';

  @override
  String get peopleNearby => 'Mga tao sa malapit';

  @override
  String get noNearbyUsersFound => 'Walang nahanap na malapit na user';

  @override
  String get tryExpandingSearch => 'Subukang palawakin ang paghahanap';

  @override
  String get exploreByCity => 'Mag-explore ayon sa lungsod';

  @override
  String get exploreByCurrentCity => 'Mag-explore ayon sa kasalukuyang lungsod';

  @override
  String get interactiveWorldMap => 'Interactive na mapa ng mundo';

  @override
  String get searchByCityName => 'Maghanap ayon sa pangalan ng lungsod';

  @override
  String get seeUserCountsPerCountry => 'Tingnan ang bilang ng mga user bawat bansa';

  @override
  String get upgradeToVip => 'Mag-upgrade sa VIP';

  @override
  String get searchByCity => 'Maghanap ayon sa lungsod';

  @override
  String usersWorldwide(String count) {
    return '$count user sa buong mundo';
  }

  @override
  String get noUsersFound => 'Walang nahanap na user';

  @override
  String get tryDifferentCity => 'Subukan ang ibang lungsod';

  @override
  String usersCount(String count) {
    return '$count user';
  }

  @override
  String get searchCountry => 'Maghanap ng bansa';

  @override
  String get wave => 'Kumaway';

  @override
  String get newUser => 'Bagong user';

  @override
  String get warningPermanent => 'Babala: Permanente ang aksyong ito!';

  @override
  String get deleteAccountWarning => 'Ang pagbura ng iyong account ay permanenteng mag-aalis ng:\n\n• Iyong profile at lahat ng personal na data\n• Lahat ng iyong mensahe at usapan\n• Lahat ng iyong mga sandali at story\n• Iyong VIP subscription (walang refund)\n• Lahat ng iyong koneksyon at tagasunod\n\nHindi na maaaring bawiin ang aksyong ito.';

  @override
  String get requiredForEmailOnly => 'Kailangan lang para sa mga email account';

  @override
  String get pleaseEnterPassword => 'Mangyaring ilagay ang iyong password';

  @override
  String get typeDELETE => 'I-type ang DELETE';

  @override
  String get mustTypeDELETE => 'Kailangan mong i-type ang DELETE para magpatuloy';

  @override
  String get deletingAccount => 'Binubura ang account...';

  @override
  String get deleteMyAccountPermanently => 'Permanenteng burahin ang aking account';

  @override
  String get whatsYourNativeLanguage => 'Ano ang iyong katutubong wika?';

  @override
  String get helpsMatchWithLearners => 'Tumutulong sa paghahanap ng mga nag-aaral';

  @override
  String get whatAreYouLearning => 'Ano ang pinag-aaralan mo?';

  @override
  String get connectWithNativeSpeakers => 'Kumonekta sa mga native speaker';

  @override
  String get selectLearningLanguage => 'Pumili ng wikang aaraling';

  @override
  String get selectCurrentLevel => 'Pumili ng kasalukuyang antas';

  @override
  String get beginner => 'Baguhan';

  @override
  String get elementary => 'Elementarya';

  @override
  String get intermediate => 'Katamtaman';

  @override
  String get upperIntermediate => 'Mataas na katamtaman';

  @override
  String get advanced => 'Abansado';

  @override
  String get proficient => 'Bihasa';

  @override
  String get showingPartnersByDistance => 'Mga partner ayon sa distansya';

  @override
  String get enableLocationForResults => 'I-enable ang lokasyon para sa mas magandang resulta';

  @override
  String get enable => 'I-enable';

  @override
  String get locationNotSet => 'Hindi pa naka-set ang lokasyon';

  @override
  String get tellUsAboutYourself => 'Sabihin sa amin tungkol sa iyo';

  @override
  String get justACoupleQuickThings => 'Ilang mabilis na bagay lang';

  @override
  String get gender => 'Kasarian';

  @override
  String get birthDate => 'Petsa ng kapanganakan';

  @override
  String get selectYourBirthDate => 'Piliin ang iyong petsa ng kapanganakan';

  @override
  String get continueButton => 'Magpatuloy';

  @override
  String get pleaseSelectGender => 'Mangyaring piliin ang iyong kasarian';

  @override
  String get pleaseSelectBirthDate => 'Mangyaring piliin ang iyong petsa ng kapanganakan';

  @override
  String get mustBe18 => 'Dapat ay 18 taong gulang ka o higit pa';

  @override
  String get invalidDate => 'Hindi wastong petsa';

  @override
  String get almostDone => 'Halos tapos na!';

  @override
  String get addPhotoLocationForMatches => 'Magdagdag ng larawan at lokasyon para sa mas magandang match';

  @override
  String get addProfilePhoto => 'Magdagdag ng profile photo';

  @override
  String get optionalUpTo6Photos => 'Opsyonal - hanggang 6 na larawan';

  @override
  String get maximum6Photos => 'Maximum na 6 na larawan';

  @override
  String get tapToDetectLocation => 'I-tap para i-detect ang lokasyon';

  @override
  String get optionalHelpsNearbyPartners => 'Opsyonal - tumutulong mahanap ang mga partner sa malapit';

  @override
  String get startLearning => 'Magsimulang matuto';

  @override
  String get photoLocationOptional => 'Ang larawan at lokasyon ay opsyonal';

  @override
  String get pleaseAcceptTerms => 'Mangyaring tanggapin ang mga tuntunin ng serbisyo';

  @override
  String get iAgreeToThe => 'Sumasang-ayon ako sa';

  @override
  String get termsOfService => 'Mga Tuntunin ng Serbisyo';

  @override
  String get tapToSelectLanguage => 'I-tap para pumili ng wika';

  @override
  String yourLevelIn(String language) {
    return 'Ang iyong antas sa $language (opsyonal)';
  }

  @override
  String get yourCurrentLevel => 'Ang iyong kasalukuyang antas';

  @override
  String get nativeCannotBeSameAsLearning => 'Ang katutubong wika ay hindi maaaring pareho sa wikang pinag-aaralan';

  @override
  String get learningCannotBeSameAsNative => 'Ang wikang pinag-aaralan ay hindi maaaring pareho sa katutubong wika';

  @override
  String stepOf(String current, String total) {
    return 'Hakbang $current ng $total';
  }

  @override
  String get continueWithGoogle => 'Magpatuloy gamit ang Google';

  @override
  String get registerLink => 'Mag-register';

  @override
  String get pleaseEnterBothEmailAndPassword => 'Ilagay ang email at password';

  @override
  String get pleaseEnterValidEmail => 'Maglagay ng wastong email';

  @override
  String get loginSuccessful => 'Matagumpay na naka-login!';

  @override
  String get stepOneOfTwo => 'Hakbang 1 ng 2';

  @override
  String get createYourAccount => 'Gumawa ng account';

  @override
  String get basicInfoToGetStarted => 'Basic na impormasyon para magsimula';

  @override
  String get emailVerifiedLabel => 'Email (Na-verify)';

  @override
  String get nameLabel => 'Pangalan';

  @override
  String get yourDisplayName => 'Display name mo';

  @override
  String get atLeast8Characters => 'Hindi bababa sa 8 character';

  @override
  String get confirmPasswordHint => 'Kumpirmahin ang password';

  @override
  String get nextButton => 'Susunod';

  @override
  String get pleaseEnterYourName => 'Ilagay ang iyong pangalan';

  @override
  String get pleaseEnterAPassword => 'Maglagay ng password';

  @override
  String get passwordsDoNotMatch => 'Hindi magkatugma ang mga password';

  @override
  String get otherGender => 'Iba pa';

  @override
  String get continueWithGoogleAccount => 'Magpatuloy gamit ang Google account\npara sa magandang karanasan';

  @override
  String get signingYouIn => 'Nag-si-sign in...';

  @override
  String get backToSignInMethods => 'Bumalik sa mga paraan ng pag-sign in';

  @override
  String get securedByGoogle => 'Pinoprotektahan ng Google';

  @override
  String get dataProtectedEncryption => 'Ang data mo ay protektado ng standard encryption';

  @override
  String get welcomeCompleteProfile => 'Welcome! Kumpletuhin ang profile mo';

  @override
  String welcomeBackName(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String get continueWithAppleId => 'Magpatuloy gamit ang Apple ID\npara sa ligtas na karanasan';

  @override
  String get continueWithApple => 'Magpatuloy gamit ang Apple';

  @override
  String get securedByApple => 'Pinoprotektahan ng Apple';

  @override
  String get privacyProtectedApple => 'Protektado ang privacy mo sa Apple Sign-In';

  @override
  String get createAccount => 'Gumawa ng account';

  @override
  String get enterEmailToGetStarted => 'Ilagay ang email mo para magsimula';

  @override
  String get continueText => 'Magpatuloy';

  @override
  String get pleaseEnterEmailAddress => 'Ilagay ang email address mo';

  @override
  String get verificationCodeSent => 'Naipadala na ang verification code!';

  @override
  String get forgotPasswordTitle => 'Nakalimutan ang password';

  @override
  String get resetPasswordTitle => 'I-reset ang password';

  @override
  String get enterEmailForResetCode => 'Ilagay ang email mo at padadalhan ka namin ng reset code';

  @override
  String get sendResetCode => 'Ipadala ang reset code';

  @override
  String get resetCodeSent => 'Naipadala na ang reset code!';

  @override
  String get rememberYourPassword => 'Naalala mo ba ang password?';

  @override
  String get verifyCode => 'I-verify ang code';

  @override
  String get enterResetCode => 'Ilagay ang reset code';

  @override
  String get weSentCodeTo => 'Nagpadala kami ng 6-digit code sa';

  @override
  String get pleaseEnterAll6Digits => 'Ilagay lahat ng 6 digits';

  @override
  String get codeVerifiedCreatePassword => 'Na-verify ang code! Gumawa ng bagong password';

  @override
  String get verify => 'I-verify';

  @override
  String get didntReceiveCode => 'Hindi natanggap ang code?';

  @override
  String get resend => 'Ipadala ulit';

  @override
  String resendWithTimer(String timer) {
    return 'Ipadala ulit (${timer}s)';
  }

  @override
  String get resetCodeResent => 'Naipadala ulit ang reset code!';

  @override
  String get verifyEmail => 'I-verify ang email';

  @override
  String get verifyYourEmail => 'I-verify ang email mo';

  @override
  String get emailVerifiedSuccessfully => 'Na-verify na ang email!';

  @override
  String get verificationCodeResent => 'Naipadala ulit ang verification code!';

  @override
  String get createNewPassword => 'Gumawa ng bagong password';

  @override
  String get enterNewPasswordBelow => 'Ilagay ang bagong password sa ibaba';

  @override
  String get newPassword => 'Bagong password';

  @override
  String get confirmPasswordLabel => 'Kumpirmahin ang password';

  @override
  String get pleaseFillAllFields => 'Punan lahat ng fields';

  @override
  String get passwordResetSuccessful => 'Na-reset na ang password! Mag-login gamit ang bagong password';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get profileVisibility => 'Visibility ng Profile';

  @override
  String get showCountryRegion => 'Ipakita ang Bansa/Rehiyon';

  @override
  String get showCountryRegionDesc => 'Ipakita ang iyong bansa sa profile';

  @override
  String get showCity => 'Ipakita ang Lungsod';

  @override
  String get showCityDesc => 'Ipakita ang iyong lungsod sa profile';

  @override
  String get showAge => 'Ipakita ang Edad';

  @override
  String get showAgeDesc => 'Ipakita ang iyong edad sa profile';

  @override
  String get showZodiacSign => 'Ipakita ang Zodiac Sign';

  @override
  String get showZodiacSignDesc => 'Ipakita ang iyong zodiac sign sa profile';

  @override
  String get onlineStatusSection => 'Status ng Online';

  @override
  String get showOnlineStatus => 'Ipakita ang Online Status';

  @override
  String get showOnlineStatusDesc => 'Hayaan ang iba na makita kapag ikaw ay online';

  @override
  String get otherSettings => 'Ibang Settings';

  @override
  String get showGiftingLevel => 'Ipakita ang Gifting Level';

  @override
  String get showGiftingLevelDesc => 'Ipakita ang badge ng gifting level';

  @override
  String get birthdayNotifications => 'Birthday Notifications';

  @override
  String get birthdayNotificationsDesc => 'Tumanggap ng notifications sa iyong birthday';

  @override
  String get personalizedAds => 'Personalized Ads';

  @override
  String get personalizedAdsDesc => 'Payagan ang personalized advertisements';

  @override
  String get saveChanges => 'I-save ang Pagbabago';

  @override
  String get privacySettingsSaved => 'Na-save ang privacy settings';

  @override
  String get locationSection => 'Lokasyon';

  @override
  String get updateLocation => 'I-update ang Lokasyon';

  @override
  String get updateLocationDesc => 'I-refresh ang kasalukuyang lokasyon';

  @override
  String get currentLocation => 'Kasalukuyang lokasyon';

  @override
  String get locationNotAvailable => 'Hindi available ang lokasyon';

  @override
  String get locationUpdated => 'Matagumpay na na-update ang lokasyon';

  @override
  String get locationPermissionDenied => 'Tinanggihan ang lokasyon permission. I-enable sa settings.';

  @override
  String get locationServiceDisabled => 'Naka-disable ang location services. I-enable.';

  @override
  String get updatingLocation => 'Ina-update ang lokasyon...';

  @override
  String get locationCouldNotBeUpdated => 'Hindi ma-update ang lokasyon';
}
