// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'BananaTalk';

  @override
  String get login => 'लॉगिन';

  @override
  String get signUp => 'साइन अप';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get or => 'या';

  @override
  String get signInWithGoogle => 'Google से साइन इन करें';

  @override
  String get signInWithApple => 'Apple से साइन इन करें';

  @override
  String get signInWithFacebook => 'Facebook से साइन इन करें';

  @override
  String get welcome => 'स्वागत है';

  @override
  String get home => 'होम';

  @override
  String get messages => 'संदेश';

  @override
  String get moments => 'पल';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get autoTranslate => 'ऑटो अनुवाद';

  @override
  String get autoTranslateMessages => 'संदेशों का ऑटो अनुवाद';

  @override
  String get autoTranslateMoments => 'पलों का ऑटो अनुवाद';

  @override
  String get autoTranslateComments => 'टिप्पणियों का ऑटो अनुवाद';

  @override
  String get translate => 'अनुवाद करें';

  @override
  String get translated => 'अनुवादित';

  @override
  String get showOriginal => 'मूल दिखाएं';

  @override
  String get showTranslation => 'अनुवाद दिखाएं';

  @override
  String get translating => 'अनुवाद हो रहा है...';

  @override
  String get translationFailed => 'अनुवाद विफल';

  @override
  String get noTranslationAvailable => 'कोई अनुवाद उपलब्ध नहीं';

  @override
  String translatedFrom(String language) {
    return '$language से अनुवादित';
  }

  @override
  String get save => 'सेव करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get share => 'शेयर करें';

  @override
  String get like => 'पसंद';

  @override
  String get comment => 'टिप्पणी';

  @override
  String get send => 'भेजें';

  @override
  String get search => 'खोजें';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get followers => 'फॉलोअर्स';

  @override
  String get following => 'फॉलोइंग';

  @override
  String get posts => 'पोस्ट';

  @override
  String get visitors => 'विज़िटर्स';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get error => 'त्रुटि';

  @override
  String get success => 'सफल';

  @override
  String get tryAgain => 'पुनः प्रयास करें';

  @override
  String get networkError => 'नेटवर्क त्रुटि। कृपया अपना कनेक्शन जांचें।';

  @override
  String get somethingWentWrong => 'कुछ गलत हो गया';

  @override
  String get ok => 'ठीक है';

  @override
  String get yes => 'हां';

  @override
  String get no => 'नहीं';

  @override
  String get languageSettings => 'भाषा सेटिंग्स';

  @override
  String get deviceLanguage => 'डिवाइस भाषा';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return 'आपका डिवाइस इस पर सेट है: $flag $name';
  }

  @override
  String get youCanOverride => 'आप नीचे डिवाइस भाषा बदल सकते हैं।';

  @override
  String languageChangedTo(String name) {
    return 'भाषा $name में बदल गई';
  }

  @override
  String get errorChangingLanguage => 'भाषा बदलने में त्रुटि';

  @override
  String get autoTranslateSettings => 'ऑटो-अनुवाद सेटिंग्स';

  @override
  String get automaticallyTranslateIncomingMessages => 'आने वाले संदेशों का स्वचालित अनुवाद';

  @override
  String get automaticallyTranslateMomentsInFeed => 'फ़ीड में पलों का स्वचालित अनुवाद';

  @override
  String get automaticallyTranslateComments => 'टिप्पणियों का स्वचालित अनुवाद';

  @override
  String get translationServiceBeingConfigured => 'अनुवाद सेवा कॉन्फ़िगर हो रही है। कृपया बाद में प्रयास करें।';

  @override
  String get translationUnavailable => 'अनुवाद उपलब्ध नहीं';

  @override
  String get showLess => 'कम दिखाएं';

  @override
  String get showMore => 'और दिखाएं';

  @override
  String get comments => 'टिप्पणियां';

  @override
  String get beTheFirstToComment => 'पहली टिप्पणी करें।';

  @override
  String get writeAComment => 'टिप्पणी लिखें...';

  @override
  String get report => 'रिपोर्ट करें';

  @override
  String get reportMoment => 'पल की रिपोर्ट करें';

  @override
  String get reportUser => 'उपयोगकर्ता की रिपोर्ट करें';

  @override
  String get deleteMoment => 'पल हटाएं?';

  @override
  String get thisActionCannotBeUndone => 'यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get momentDeleted => 'पल हटाया गया';

  @override
  String get editFeatureComingSoon => 'संपादन सुविधा जल्द आ रही है';

  @override
  String get userNotFound => 'उपयोगकर्ता नहीं मिला';

  @override
  String get cannotReportYourOwnComment => 'अपनी टिप्पणी की रिपोर्ट नहीं कर सकते';

  @override
  String get profileSettings => 'प्रोफ़ाइल सेटिंग्स';

  @override
  String get editYourProfileInformation => 'अपनी प्रोफ़ाइल जानकारी संपादित करें';

  @override
  String get blockedUsers => 'ब्लॉक किए गए उपयोगकर्ता';

  @override
  String get manageBlockedUsers => 'ब्लॉक किए गए उपयोगकर्ताओं को प्रबंधित करें';

  @override
  String get manageNotificationSettings => 'सूचना सेटिंग्स प्रबंधित करें';

  @override
  String get privacySecurity => 'गोपनीयता और सुरक्षा';

  @override
  String get controlYourPrivacy => 'अपनी गोपनीयता नियंत्रित करें';

  @override
  String get changeAppLanguage => 'ऐप भाषा बदलें';

  @override
  String get appearance => 'दिखावट';

  @override
  String get themeAndDisplaySettings => 'थीम और डिस्प्ले सेटिंग्स';

  @override
  String get myReports => 'मेरी रिपोर्ट्स';

  @override
  String get viewYourSubmittedReports => 'अपनी जमा की गई रिपोर्ट्स देखें';

  @override
  String get reportsManagement => 'रिपोर्ट्स प्रबंधन';

  @override
  String get manageAllReportsAdmin => 'सभी रिपोर्ट्स प्रबंधित करें (एडमिन)';

  @override
  String get legalPrivacy => 'कानूनी और गोपनीयता';

  @override
  String get termsPrivacySubscriptionInfo => 'नियम, गोपनीयता और सदस्यता जानकारी';

  @override
  String get helpCenter => 'सहायता केंद्र';

  @override
  String get getHelpAndSupport => 'सहायता प्राप्त करें';

  @override
  String get aboutBanaTalk => 'BanaTalk के बारे में';

  @override
  String get deleteAccount => 'खाता हटाएं';

  @override
  String get permanentlyDeleteYourAccount => 'अपना खाता स्थायी रूप से हटाएं';

  @override
  String get loggedOutSuccessfully => 'सफलतापूर्वक लॉग आउट हो गए';

  @override
  String get retry => 'पुनः प्रयास';

  @override
  String get giftsLikes => 'उपहार/पसंद';

  @override
  String get details => 'विवरण';

  @override
  String get to => 'को';

  @override
  String get banaTalk => 'BanaTalk';

  @override
  String get community => 'समुदाय';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String yearsOld(String age) {
    return '$age साल';
  }

  @override
  String get searchConversations => 'बातचीत खोजें...';

  @override
  String get visitorTrackingNotAvailable => 'विज़िटर ट्रैकिंग सुविधा अभी उपलब्ध नहीं है।';

  @override
  String get chatList => 'चैट लिस्ट';

  @override
  String get languageExchange => 'भाषा विनिमय';

  @override
  String get nativeLanguage => 'मातृभाषा';

  @override
  String get learning => 'सीखना';

  @override
  String get notSet => 'सेट नहीं';

  @override
  String get about => 'के बारे में';

  @override
  String get aboutMe => 'मेरे बारे में';

  @override
  String get bloodType => 'Blood Type';

  @override
  String get photos => 'फ़ोटो';

  @override
  String get camera => 'कैमरा';

  @override
  String get createMoment => 'पल बनाएं';

  @override
  String get addATitle => 'शीर्षक जोड़ें...';

  @override
  String get whatsOnYourMind => 'आपके मन में क्या है?';

  @override
  String get addTags => 'टैग जोड़ें';

  @override
  String get done => 'हो गया';

  @override
  String get add => 'जोड़ें';

  @override
  String get enterTag => 'टैग दर्ज करें';

  @override
  String get post => 'पोस्ट';

  @override
  String get commentAddedSuccessfully => 'टिप्पणी सफलतापूर्वक जोड़ी गई';

  @override
  String get clearFilters => 'फ़िल्टर साफ़ करें';

  @override
  String get notificationSettings => 'सूचना सेटिंग्स';

  @override
  String get enableNotifications => 'सूचनाएं सक्षम करें';

  @override
  String get turnAllNotificationsOnOrOff => 'सभी सूचनाएं चालू या बंद करें';

  @override
  String get notificationTypes => 'सूचना प्रकार';

  @override
  String get chatMessages => 'चैट संदेश';

  @override
  String get getNotifiedWhenYouReceiveMessages => 'संदेश प्राप्त होने पर सूचित हों';

  @override
  String get likesAndCommentsOnYourMoments => 'आपके पलों पर पसंद और टिप्पणियां';

  @override
  String get whenPeopleYouFollowPostMoments => 'जब आपके फॉलो किए लोग पल पोस्ट करें';

  @override
  String get friendRequests => 'मित्र अनुरोध';

  @override
  String get whenSomeoneFollowsYou => 'जब कोई आपको फॉलो करे';

  @override
  String get profileVisits => 'प्रोफ़ाइल विज़िट';

  @override
  String get whenSomeoneViewsYourProfileVIP => 'जब कोई आपकी प्रोफ़ाइल देखे (VIP)';

  @override
  String get marketing => 'मार्केटिंग';

  @override
  String get updatesAndPromotionalMessages => 'अपडेट और प्रचार संदेश';

  @override
  String get notificationPreferences => 'सूचना प्राथमिकताएं';

  @override
  String get sound => 'ध्वनि';

  @override
  String get playNotificationSounds => 'सूचना ध्वनि बजाएं';

  @override
  String get vibration => 'वाइब्रेशन';

  @override
  String get vibrateOnNotifications => 'सूचनाओं पर वाइब्रेट करें';

  @override
  String get showPreview => 'प्रीव्यू दिखाएं';

  @override
  String get showMessagePreviewInNotifications => 'सूचनाओं में संदेश प्रीव्यू दिखाएं';

  @override
  String get mutedConversations => 'म्यूट बातचीत';

  @override
  String get conversation => 'बातचीत';

  @override
  String get unmute => 'अनम्यूट';

  @override
  String get systemNotificationSettings => 'सिस्टम सूचना सेटिंग्स';

  @override
  String get manageNotificationsInSystemSettings => 'सिस्टम सेटिंग्स में सूचनाएं प्रबंधित करें';

  @override
  String get errorLoadingSettings => 'सेटिंग्स लोड करने में त्रुटि';

  @override
  String get unblockUser => 'अनब्लॉक करें';

  @override
  String get unblock => 'अनब्लॉक';

  @override
  String get goBack => 'वापस जाएं';

  @override
  String get messageSendTimeout => 'संदेश भेजने का समय समाप्त। कृपया कनेक्शन जांचें।';

  @override
  String get failedToSendMessage => 'संदेश भेजने में विफल';

  @override
  String get dailyMessageLimitExceeded => 'दैनिक संदेश सीमा पार। असीमित संदेशों के लिए VIP में अपग्रेड करें।';

  @override
  String get cannotSendMessageUserMayBeBlocked => 'संदेश नहीं भेज सकते। उपयोगकर्ता ब्लॉक हो सकता है।';

  @override
  String get sessionExpired => 'सत्र समाप्त। कृपया फिर से लॉगिन करें।';

  @override
  String get sendThisSticker => 'यह स्टिकर भेजें?';

  @override
  String get chooseHowYouWantToDeleteThisMessage => 'चुनें कि आप इस संदेश को कैसे हटाना चाहते हैं:';

  @override
  String get deleteForEveryone => 'सभी के लिए हटाएं';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => 'आपके और प्राप्तकर्ता दोनों के लिए संदेश हटाता है';

  @override
  String get deleteForMe => 'मेरे लिए हटाएं';

  @override
  String get removesTheMessageOnlyFromYourChat => 'केवल आपकी चैट से संदेश हटाता है';

  @override
  String get copy => 'कॉपी';

  @override
  String get reply => 'जवाब दें';

  @override
  String get forward => 'फॉरवर्ड';

  @override
  String get moreOptions => 'और विकल्प';

  @override
  String get noUsersAvailableToForwardTo => 'फॉरवर्ड करने के लिए कोई उपयोगकर्ता उपलब्ध नहीं';

  @override
  String get searchMoments => 'पल खोजें...';

  @override
  String searchInChatWith(String name) {
    return '$name के साथ चैट में खोजें';
  }

  @override
  String get typeAMessage => 'संदेश टाइप करें...';

  @override
  String get enterYourMessage => 'अपना संदेश दर्ज करें';

  @override
  String get detectYourLocation => 'अपना स्थान पता करें';

  @override
  String get tapToUpdateLocation => 'स्थान अपडेट करने के लिए टैप करें';

  @override
  String get helpOthersFindYouNearby => 'दूसरों को आपको पास में खोजने में मदद करें';

  @override
  String get selectYourNativeLanguage => 'अपनी मातृभाषा चुनें';

  @override
  String get whichLanguageDoYouWantToLearn => 'आप कौन सी भाषा सीखना चाहते हैं?';

  @override
  String get selectYourGender => 'अपना लिंग चुनें';

  @override
  String get addACaption => 'कैप्शन जोड़ें...';

  @override
  String get typeSomething => 'कुछ टाइप करें...';

  @override
  String get gallery => 'गैलरी';

  @override
  String get video => 'वीडियो';

  @override
  String get text => 'टेक्स्ट';

  @override
  String get provideMoreInformation => 'अधिक जानकारी प्रदान करें...';

  @override
  String get searchByNameLanguageOrInterests => 'नाम, भाषा या रुचियों से खोजें...';

  @override
  String get addTagAndPressEnter => 'टैग जोड़ें और एंटर दबाएं';

  @override
  String replyTo(String name) {
    return '$name को जवाब दें...';
  }

  @override
  String get highlightName => 'हाइलाइट नाम';

  @override
  String get searchCloseFriends => 'करीबी दोस्तों को खोजें...';

  @override
  String get askAQuestion => 'सवाल पूछें...';

  @override
  String option(String number) {
    return 'विकल्प $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return 'आप इस $type की रिपोर्ट क्यों कर रहे हैं?';
  }

  @override
  String get additionalDetailsOptional => 'अतिरिक्त विवरण (वैकल्पिक)';

  @override
  String get warningThisActionIsPermanent => 'चेतावनी: यह क्रिया स्थायी है!';

  @override
  String get deletingYourAccountWillPermanentlyRemove => 'आपका खाता हटाने से स्थायी रूप से हटाया जाएगा:\n\n• आपकी प्रोफ़ाइल और सभी व्यक्तिगत डेटा\n• आपके सभी संदेश और बातचीत\n• आपके सभी पल और स्टोरी\n• आपकी VIP सदस्यता (कोई रिफंड नहीं)\n• आपके सभी कनेक्शन और फॉलोअर्स\n\nयह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get clearAllNotifications => 'सभी सूचनाएं साफ़ करें?';

  @override
  String get clearAll => 'सभी साफ़ करें';

  @override
  String get notificationDebug => 'सूचना डीबग';

  @override
  String get markAllRead => 'सभी पढ़ा हुआ चिह्नित करें';

  @override
  String get clearAll2 => 'सभी साफ़ करें';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get username => 'उपयोगकर्ता नाम';

  @override
  String get alreadyHaveAnAccount => 'पहले से खाता है?';

  @override
  String get login2 => 'लॉगिन';

  @override
  String get selectYourNativeLanguage2 => 'अपनी मातृभाषा चुनें';

  @override
  String get whichLanguageDoYouWantToLearn2 => 'आप कौन सी भाषा सीखना चाहते हैं?';

  @override
  String get selectYourGender2 => 'अपना लिंग चुनें';

  @override
  String get dateFormat => 'YYYY.MM.DD';

  @override
  String get detectYourLocation2 => 'अपना स्थान पता करें';

  @override
  String get tapToUpdateLocation2 => 'स्थान अपडेट करने के लिए टैप करें';

  @override
  String get helpOthersFindYouNearby2 => 'दूसरों को आपको पास में खोजने में मदद करें';

  @override
  String get couldNotOpenLink => 'लिंक नहीं खुल सका';

  @override
  String get legalPrivacy2 => 'कानूनी और गोपनीयता';

  @override
  String get termsOfUseEULA => 'उपयोग की शर्तें (EULA)';

  @override
  String get viewOurTermsAndConditions => 'हमारे नियम और शर्तें देखें';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get howWeHandleYourData => 'हम आपके डेटा को कैसे संभालते हैं';

  @override
  String get emailNotifications => 'ईमेल सूचनाएं';

  @override
  String get receiveEmailNotificationsFromBananaTalk => 'BananaTalk से ईमेल सूचनाएं प्राप्त करें';

  @override
  String get weeklySummary => 'साप्ताहिक सारांश';

  @override
  String get activityRecapEverySunday => 'हर रविवार गतिविधि सारांश';

  @override
  String get newMessages => 'नए संदेश';

  @override
  String get whenYoureAwayFor24PlusHours => 'जब आप 24+ घंटे दूर हों';

  @override
  String get newFollowers => 'नए फॉलोअर्स';

  @override
  String get whenSomeoneFollowsYou2 => 'जब कोई आपको फॉलो करे';

  @override
  String get securityAlerts => 'सुरक्षा अलर्ट';

  @override
  String get passwordLoginAlerts => 'पासवर्ड और लॉगिन अलर्ट';

  @override
  String get unblockUser2 => 'उपयोगकर्ता अनब्लॉक करें';

  @override
  String get blockedUsers2 => 'ब्लॉक किए गए उपयोगकर्ता';

  @override
  String get finalWarning => 'अंतिम चेतावनी';

  @override
  String get deleteForever => 'हमेशा के लिए हटाएं';

  @override
  String get deleteAccount2 => 'खाता हटाएं';

  @override
  String get enterYourPassword => 'अपना पासवर्ड दर्ज करें';

  @override
  String get yourPassword => 'आपका पासवर्ड';

  @override
  String get typeDELETEToConfirm => 'पुष्टि के लिए DELETE टाइप करें';

  @override
  String get typeDELETEInCapitalLetters => 'बड़े अक्षरों में DELETE टाइप करें';

  @override
  String sent(String emoji) {
    return 'भेज दिया!';
  }

  @override
  String get replySent => 'जवाब भेजा गया!';

  @override
  String get deleteStory => 'स्टोरी हटाएं?';

  @override
  String get thisStoryWillBeRemovedPermanently => 'यह स्टोरी स्थायी रूप से हटा दी जाएगी।';

  @override
  String get noStories => 'कोई स्टोरी नहीं';

  @override
  String views(String count) {
    return '$count व्यू';
  }

  @override
  String get reportStory => 'स्टोरी की रिपोर्ट करें';

  @override
  String get reply2 => 'जवाब दें...';

  @override
  String get failedToPickImage => 'छवि चुनने में विफल';

  @override
  String get failedToTakePhoto => 'फ़ोटो लेने में विफल';

  @override
  String get failedToPickVideo => 'वीडियो चुनने में विफल';

  @override
  String get pleaseEnterSomeText => 'कृपया कुछ टेक्स्ट दर्ज करें';

  @override
  String get pleaseSelectMedia => 'कृपया मीडिया चुनें';

  @override
  String get storyPosted => 'स्टोरी पोस्ट की गई!';

  @override
  String get textOnlyStoriesRequireAnImage => 'केवल टेक्स्ट स्टोरी के लिए छवि आवश्यक है';

  @override
  String get createStory => 'स्टोरी बनाएं';

  @override
  String get change => 'बदलें';

  @override
  String get userIdNotFound => 'यूजर ID नहीं मिली। कृपया फिर से लॉगिन करें।';

  @override
  String get pleaseSelectAPaymentMethod => 'कृपया भुगतान विधि चुनें';

  @override
  String get startExploring => 'खोजना शुरू करें';

  @override
  String get close => 'बंद करें';

  @override
  String get payment => 'भुगतान';

  @override
  String get upgradeToVIP => 'VIP में अपग्रेड करें';

  @override
  String get errorLoadingProducts => 'उत्पाद लोड करने में त्रुटि';

  @override
  String get cancelVIPSubscription => 'VIP सदस्यता रद्द करें';

  @override
  String get keepVIP => 'VIP रखें';

  @override
  String get cancelSubscription => 'सदस्यता रद्द करें';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'VIP सदस्यता सफलतापूर्वक रद्द की गई';

  @override
  String get vipStatus => 'VIP स्थिति';

  @override
  String get noActiveVIPSubscription => 'कोई सक्रिय VIP सदस्यता नहीं';

  @override
  String get subscriptionExpired => 'सदस्यता समाप्त';

  @override
  String get vipExpiredMessage => 'आपकी VIP सदस्यता समाप्त हो गई है। असीमित सुविधाओं का आनंद लेने के लिए अभी नवीनीकृत करें!';

  @override
  String get expiredOn => 'समाप्त हुई';

  @override
  String get renewVIP => 'VIP नवीनीकृत करें';

  @override
  String get whatYoureMissing => 'आप क्या खो रहे हैं';

  @override
  String get manageInAppStore => 'App Store में प्रबंधित करें';

  @override
  String get becomeVIP => 'VIP बनें';

  @override
  String get unlimitedMessages => 'असीमित संदेश';

  @override
  String get unlimitedProfileViews => 'असीमित प्रोफ़ाइल व्यू';

  @override
  String get prioritySupport => 'प्राथमिकता सहायता';

  @override
  String get advancedSearch => 'उन्नत खोज';

  @override
  String get profileBoost => 'प्रोफ़ाइल बूस्ट';

  @override
  String get adFreeExperience => 'विज्ञापन-मुक्त अनुभव';

  @override
  String get upgradeYourAccount => 'अपना खाता अपग्रेड करें';

  @override
  String get moreMessages => 'और संदेश';

  @override
  String get moreProfileViews => 'और प्रोफ़ाइल व्यू';

  @override
  String get connectWithFriends => 'दोस्तों से जुड़ें';

  @override
  String get reviewStarted => 'समीक्षा शुरू';

  @override
  String get reportResolved => 'रिपोर्ट हल की गई';

  @override
  String get reportDismissed => 'रिपोर्ट खारिज की गई';

  @override
  String get selectAction => 'कार्रवाई चुनें';

  @override
  String get noViolation => 'कोई उल्लंघन नहीं';

  @override
  String get contentRemoved => 'सामग्री हटाई गई';

  @override
  String get userWarned => 'उपयोगकर्ता को चेतावनी दी गई';

  @override
  String get userSuspended => 'उपयोगकर्ता निलंबित';

  @override
  String get userBanned => 'उपयोगकर्ता प्रतिबंधित';

  @override
  String get addNotesOptional => 'नोट्स जोड़ें (वैकल्पिक)';

  @override
  String get enterModeratorNotes => 'मॉडरेटर नोट्स दर्ज करें...';

  @override
  String get skip => 'छोड़ें';

  @override
  String get startReview => 'समीक्षा शुरू करें';

  @override
  String get resolve => 'हल करें';

  @override
  String get dismiss => 'खारिज करें';

  @override
  String get filterReports => 'रिपोर्ट फ़िल्टर करें';

  @override
  String get all => 'सभी';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get apply => 'लागू करें';

  @override
  String get myReports2 => 'मेरी रिपोर्ट्स';

  @override
  String get blockUser => 'उपयोगकर्ता ब्लॉक करें';

  @override
  String get block => 'ब्लॉक';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => 'क्या आप इस उपयोगकर्ता को भी ब्लॉक करना चाहेंगे?';

  @override
  String get noThanks => 'नहीं, धन्यवाद';

  @override
  String get yesBlockThem => 'हां, ब्लॉक करें';

  @override
  String get reportUser2 => 'उपयोगकर्ता की रिपोर्ट करें';

  @override
  String get submitReport => 'रिपोर्ट सबमिट करें';

  @override
  String get addAQuestionAndAtLeast2Options => 'सवाल और कम से कम 2 विकल्प जोड़ें';

  @override
  String get addOption => 'विकल्प जोड़ें';

  @override
  String get anonymousVoting => 'गुमनाम मतदान';

  @override
  String get create => 'बनाएं';

  @override
  String get typeYourAnswer => 'अपना जवाब टाइप करें...';

  @override
  String get send2 => 'भेजें';

  @override
  String get yourPrompt => 'आपका प्रॉम्प्ट...';

  @override
  String get add2 => 'जोड़ें';

  @override
  String get contentNotAvailable => 'सामग्री उपलब्ध नहीं';

  @override
  String get profileNotAvailable => 'प्रोफ़ाइल उपलब्ध नहीं';

  @override
  String get noMomentsToShow => 'दिखाने के लिए कोई पल नहीं';

  @override
  String get storiesNotAvailable => 'स्टोरी उपलब्ध नहीं';

  @override
  String get cantMessageThisUser => 'इस उपयोगकर्ता को संदेश नहीं भेज सकते';

  @override
  String get pleaseSelectAReason => 'कृपया कारण चुनें';

  @override
  String get reportSubmitted => 'रिपोर्ट सबमिट की गई। हमारे समुदाय को सुरक्षित रखने में मदद के लिए धन्यवाद।';

  @override
  String get youHaveAlreadyReportedThisMoment => 'आपने पहले ही इस पल की रिपोर्ट की है';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => 'हमें बताएं कि आप इसकी रिपोर्ट क्यों कर रहे हैं';

  @override
  String get errorSharing => 'शेयर करने में त्रुटि';

  @override
  String get deviceInfo => 'डिवाइस जानकारी';

  @override
  String get recommended => 'अनुशंसित';

  @override
  String get anyLanguage => 'कोई भी भाषा';

  @override
  String get noLanguagesFound => 'कोई भाषा नहीं मिली';

  @override
  String get selectALanguage => 'भाषा चुनें';

  @override
  String get languagesAreStillLoading => 'भाषाएं अभी लोड हो रही हैं...';

  @override
  String get selectNativeLanguage => 'मातृभाषा चुनें';

  @override
  String get subscriptionDetails => 'सदस्यता विवरण';

  @override
  String get activeFeatures => 'सक्रिय सुविधाएं';

  @override
  String get legalInformation => 'कानूनी जानकारी';

  @override
  String get termsOfUse => 'उपयोग की शर्तें';

  @override
  String get manageSubscription => 'सदस्यता प्रबंधित करें';

  @override
  String get manageSubscriptionInSettings => 'अपनी सदस्यता रद्द करने के लिए, अपने डिवाइस पर सेटिंग्स > [आपका नाम] > सदस्यताएं पर जाएं।';

  @override
  String get contactSupportToCancel => 'अपनी सदस्यता रद्द करने के लिए, कृपया हमारी सहायता टीम से संपर्क करें।';

  @override
  String get status => 'स्थिति';

  @override
  String get active => 'सक्रिय';

  @override
  String get plan => 'प्लान';

  @override
  String get startDate => 'शुरू तिथि';

  @override
  String get endDate => 'समाप्ति तिथि';

  @override
  String get nextBillingDate => 'अगली बिलिंग तिथि';

  @override
  String get autoRenew => 'ऑटो नवीनीकरण';

  @override
  String get pleaseLogInToContinue => 'जारी रखने के लिए कृपया लॉगिन करें';

  @override
  String get purchaseCanceledOrFailed => 'खरीद रद्द या विफल हुई। कृपया पुनः प्रयास करें।';

  @override
  String get maximumTagsAllowed => 'अधिकतम 5 टैग की अनुमति';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => 'वीडियो जोड़ने के लिए पहले छवियां हटाएं';

  @override
  String get unsupportedFormat => 'असमर्थित प्रारूप';

  @override
  String get errorProcessingVideo => 'वीडियो प्रोसेस करने में त्रुटि';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'वीडियो रिकॉर्ड करने के लिए पहले छवियां हटाएं';

  @override
  String get locationAdded => 'स्थान जोड़ा गया';

  @override
  String get failedToGetLocation => 'स्थान प्राप्त करने में विफल';

  @override
  String get notNow => 'अभी नहीं';

  @override
  String get videoUploadFailed => 'वीडियो अपलोड विफल';

  @override
  String get skipVideo => 'वीडियो छोड़ें';

  @override
  String get retryUpload => 'पुनः प्रयास करें';

  @override
  String get momentCreatedSuccessfully => 'पल सफलतापूर्वक बनाया गया';

  @override
  String get uploadingMomentInBackground => 'पृष्ठभूमि में पल अपलोड हो रहा है...';

  @override
  String get failedToQueueUpload => 'अपलोड कतार में विफल';

  @override
  String get viewProfile => 'प्रोफ़ाइल देखें';

  @override
  String get mediaLinksAndDocs => 'मीडिया, लिंक और डॉक्स';

  @override
  String get wallpaper => 'वॉलपेपर';

  @override
  String get userIdNotAvailable => 'यूजर ID उपलब्ध नहीं';

  @override
  String get cannotBlockYourself => 'खुद को ब्लॉक नहीं कर सकते';

  @override
  String get chatWallpaper => 'चैट वॉलपेपर';

  @override
  String get wallpaperSavedLocally => 'वॉलपेपर स्थानीय रूप से सेव किया गया';

  @override
  String get messageCopied => 'संदेश कॉपी किया गया';

  @override
  String get forwardFeatureComingSoon => 'फॉरवर्ड सुविधा जल्द आ रही है';

  @override
  String get momentUnsaved => 'पल अनसेव किया गया';

  @override
  String get documentPickerComingSoon => 'डॉक्यूमेंट पिकर जल्द आ रहा है';

  @override
  String get contactSharingComingSoon => 'संपर्क शेयरिंग जल्द आ रही है';

  @override
  String get featureComingSoon => 'सुविधा जल्द आ रही है';

  @override
  String get answerSent => 'उत्तर भेज दिया गया!';

  @override
  String get noImagesAvailable => 'कोई छवि उपलब्ध नहीं';

  @override
  String get mentionPickerComingSoon => 'मेंशन पिकर जल्द आ रहा है';

  @override
  String get musicPickerComingSoon => 'म्यूज़िक पिकर जल्द आ रहा है';

  @override
  String get repostFeatureComingSoon => 'रीपोस्ट सुविधा जल्द आ रही है';

  @override
  String get addFriendsFromYourProfile => 'अपनी प्रोफ़ाइल से दोस्त जोड़ें';

  @override
  String get quickReplyAdded => 'त्वरित जवाब जोड़ा गया';

  @override
  String get quickReplyDeleted => 'त्वरित जवाब हटाया गया';

  @override
  String get linkCopied => 'लिंक कॉपी किया गया!';

  @override
  String get maximumOptionsAllowed => 'अधिकतम 10 विकल्पों की अनुमति';

  @override
  String get minimumOptionsRequired => 'न्यूनतम 2 विकल्प आवश्यक';

  @override
  String get pleaseEnterAQuestion => 'कृपया सवाल दर्ज करें';

  @override
  String get pleaseAddAtLeast2Options => 'कृपया कम से कम 2 विकल्प जोड़ें';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => 'कृपया क्विज़ के लिए सही जवाब चुनें';

  @override
  String get correctionSent => 'सुधार भेजा गया!';

  @override
  String get sort => 'क्रमबद्ध करें';

  @override
  String get savedMoments => 'सेव किए गए पल';

  @override
  String get unsave => 'अनसेव';

  @override
  String get playingAudio => 'ऑडियो चल रहा है...';

  @override
  String get failedToGenerateQuiz => 'क्विज़ बनाने में विफल';

  @override
  String get failedToAddComment => 'टिप्पणी जोड़ने में विफल';

  @override
  String get hello => 'नमस्ते!';

  @override
  String get howAreYou => 'आप कैसे हैं?';

  @override
  String get cannotOpen => 'खोल नहीं सकते';

  @override
  String get errorOpeningLink => 'लिंक खोलने में त्रुटि';

  @override
  String get saved => 'सेव किया गया';

  @override
  String get follow => 'फॉलो करें';

  @override
  String get unfollow => 'अनफॉलो करें';

  @override
  String get mute => 'म्यूट';

  @override
  String get online => 'ऑनलाइन';

  @override
  String get offline => 'ऑफलाइन';

  @override
  String get lastSeen => 'अंतिम बार देखा गया';

  @override
  String get justNow => 'अभी';

  @override
  String minutesAgo(String count) {
    return '$count मिनट पहले';
  }

  @override
  String hoursAgo(String count) {
    return '$count घंटे पहले';
  }

  @override
  String get yesterday => 'कल';

  @override
  String get signInWithEmail => 'ईमेल से साइन इन करें';

  @override
  String get partners => 'साझेदार';

  @override
  String get nearby => 'आस-पास';

  @override
  String get topics => 'विषय';

  @override
  String get waves => 'अभिवादन';

  @override
  String get voiceRooms => 'वॉइस';

  @override
  String get filters => 'फ़िल्टर';

  @override
  String get searchCommunity => 'नाम, भाषा या रुचियों से खोजें...';

  @override
  String get bio => 'परिचय';

  @override
  String get noBioYet => 'अभी कोई परिचय उपलब्ध नहीं है।';

  @override
  String get languages => 'भाषाएं';

  @override
  String get native => 'मातृभाषा';

  @override
  String get interests => 'रुचियां';

  @override
  String get noMomentsYet => 'अभी कोई पल नहीं';

  @override
  String get unableToLoadMoments => 'पल लोड नहीं हो सके';

  @override
  String get map => 'मानचित्र';

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
  String get videoCall => 'वीडियो';

  @override
  String get voiceCall => 'कॉल';

  @override
  String get message => 'संदेश';

  @override
  String get pleaseLoginToFollow => 'फॉलो करने के लिए कृपया लॉगिन करें';

  @override
  String get pleaseLoginToCall => 'कॉल करने के लिए कृपया लॉगिन करें';

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
  String get soon => 'जल्द';

  @override
  String comingSoon(String feature) {
    return '$feature जल्द आ रहा है!';
  }

  @override
  String get muteNotifications => 'सूचनाएं म्यूट करें';

  @override
  String get unmuteNotifications => 'नोटिफिकेशन अनम्यूट करें';

  @override
  String get operationCompleted => 'ऑपरेशन पूरा हुआ';

  @override
  String get couldNotOpenMaps => 'मैप नहीं खुल सका';

  @override
  String hasntSharedMoments(Object name) {
    return '$name ने अभी तक कोई पल साझा नहीं किया';
  }

  @override
  String messageUser(String name) {
    return '$name को संदेश';
  }

  @override
  String notFollowingUser(String name) {
    return 'आप $name को फॉलो नहीं कर रहे थे';
  }

  @override
  String youFollowedUser(String name) {
    return 'आपने $name को फॉलो किया';
  }

  @override
  String youUnfollowedUser(String name) {
    return 'आपने $name को अनफॉलो किया';
  }

  @override
  String unfollowUser(String name) {
    return '$name को अनफॉलो करें';
  }

  @override
  String get typing => 'टाइप कर रहा है';

  @override
  String get connecting => 'कनेक्ट हो रहा है...';

  @override
  String daysAgo(int count) {
    return '$count दिन पहले';
  }

  @override
  String get maxTagsAllowed => 'अधिकतम 5 टैग की अनुमति है';

  @override
  String maxImagesAllowed(int count) {
    return 'अधिकतम $count छवियों की अनुमति है';
  }

  @override
  String get pleaseRemoveImagesFirst => 'कृपया पहले छवियां हटाएं';

  @override
  String get exchange3MessagesBeforeCall => 'कॉल करने से पहले कम से कम 3 संदेशों का आदान-प्रदान करें';

  @override
  String mediaWithUser(String name) {
    return '$name के साथ मीडिया';
  }

  @override
  String get errorLoadingMedia => 'मीडिया लोड करने में त्रुटि';

  @override
  String get savedMomentsTitle => 'सहेजे गए पल';

  @override
  String get removeBookmark => 'बुकमार्क हटाएं?';

  @override
  String get thisWillRemoveBookmark => 'यह संदेश आपके बुकमार्क से हटा दिया जाएगा।';

  @override
  String get remove => 'हटाएं';

  @override
  String get bookmarkRemoved => 'बुकमार्क हटाया गया';

  @override
  String get bookmarkedMessages => 'बुकमार्क किए गए संदेश';

  @override
  String get wallpaperSaved => 'वॉलपेपर स्थानीय रूप से सहेजा गया';

  @override
  String get typeDeleteToConfirm => 'पुष्टि के लिए DELETE टाइप करें';

  @override
  String get storyArchive => 'स्टोरी आर्काइव';

  @override
  String get newHighlight => 'नई हाइलाइट';

  @override
  String get addToHighlight => 'हाइलाइट में जोड़ें';

  @override
  String get repost => 'रीपोस्ट';

  @override
  String get repostFeatureSoon => 'रीपोस्ट सुविधा जल्द आ रही है';

  @override
  String get closeFriends => 'करीबी दोस्त';

  @override
  String get addFriends => 'दोस्त जोड़ें';

  @override
  String get highlights => 'हाइलाइट्स';

  @override
  String get createHighlight => 'हाइलाइट बनाएं';

  @override
  String get deleteHighlight => 'हाइलाइट हटाएं?';

  @override
  String get editHighlight => 'हाइलाइट संपादित करें';

  @override
  String get addMoreToStory => 'स्टोरी में और जोड़ें';

  @override
  String get noViewersYet => 'अभी तक कोई दर्शक नहीं';

  @override
  String get noReactionsYet => 'अभी तक कोई प्रतिक्रिया नहीं';

  @override
  String get leaveRoom => 'कमरा छोड़ें?';

  @override
  String get areYouSureLeaveRoom => 'क्या आप वाकई इस वॉयस रूम को छोड़ना चाहते हैं?';

  @override
  String get stay => 'रुकें';

  @override
  String get leave => 'छोड़ें';

  @override
  String get enableGPS => 'GPS सक्षम करें';

  @override
  String wavedToUser(String name) {
    return 'आपने $name को हाथ हिलाया!';
  }

  @override
  String get areYouSureFollow => 'क्या आप वाकई फॉलो करना चाहते हैं';

  @override
  String get failedToLoadProfile => 'प्रोफ़ाइल लोड करने में विफल';

  @override
  String get noFollowersYet => 'अभी तक कोई फॉलोअर नहीं';

  @override
  String get noFollowingYet => 'अभी तक किसी को फॉलो नहीं कर रहे';

  @override
  String get searchUsers => 'उपयोगकर्ता खोजें...';

  @override
  String get noResultsFound => 'कोई परिणाम नहीं मिला';

  @override
  String get loadingFailed => 'लोडिंग विफल';

  @override
  String get copyLink => 'लिंक कॉपी करें';

  @override
  String get shareStory => 'स्टोरी शेयर करें';

  @override
  String get thisWillDeleteStory => 'यह इस स्टोरी को स्थायी रूप से हटा देगा।';

  @override
  String get storyDeleted => 'स्टोरी हटा दी गई';

  @override
  String get addCaption => 'कैप्शन जोड़ें...';

  @override
  String get yourStory => 'आपकी स्टोरी';

  @override
  String get sendMessage => 'संदेश भेजें';

  @override
  String get replyToStory => 'स्टोरी का जवाब दें...';

  @override
  String get viewAllReplies => 'सभी जवाब देखें';

  @override
  String get preparingVideo => 'वीडियो तैयार हो रहा है...';

  @override
  String videoOptimized(String size, String savings) {
    return 'वीडियो ऑप्टिमाइज़ किया गया: ${size}MB ($savings% बचत)';
  }

  @override
  String get failedToProcessVideo => 'वीडियो प्रोसेस करने में विफल';

  @override
  String get optimizingForBestExperience => 'सर्वश्रेष्ठ अनुभव के लिए ऑप्टिमाइज़ किया जा रहा है';

  @override
  String get pleaseSelectImageOrVideo => 'कृपया अपनी स्टोरी के लिए एक छवि या वीडियो चुनें';

  @override
  String get storyCreatedSuccessfully => 'स्टोरी सफलतापूर्वक बनाई गई!';

  @override
  String get uploadingStoryInBackground => 'बैकग्राउंड में स्टोरी अपलोड हो रही है...';

  @override
  String get storyCreationFailed => 'स्टोरी बनाने में विफल';

  @override
  String get pleaseCheckConnection => 'कृपया अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get uploadFailed => 'अपलोड विफल';

  @override
  String get tryShorterVideo => 'छोटा वीडियो उपयोग करें या बाद में पुनः प्रयास करें।';

  @override
  String get shareMomentsThatDisappear => '24 घंटों में गायब होने वाले पल साझा करें';

  @override
  String get photo => 'फ़ोटो';

  @override
  String get record => 'रिकॉर्ड';

  @override
  String get addSticker => 'स्टिकर जोड़ें';

  @override
  String get poll => 'पोल';

  @override
  String get question => 'प्रश्न';

  @override
  String get mention => 'मेंशन';

  @override
  String get music => 'संगीत';

  @override
  String get hashtag => 'हैशटैग';

  @override
  String get whoCanSeeThis => 'इसे कौन देख सकता है?';

  @override
  String get everyone => 'सभी';

  @override
  String get anyoneCanSeeStory => 'कोई भी इस स्टोरी को देख सकता है';

  @override
  String get friendsOnly => 'केवल दोस्त';

  @override
  String get onlyFollowersCanSee => 'केवल आपके फॉलोअर देख सकते हैं';

  @override
  String get onlyCloseFriendsCanSee => 'केवल करीबी दोस्त देख सकते हैं';

  @override
  String get backgroundColor => 'पृष्ठभूमि रंग';

  @override
  String get fontStyle => 'फ़ॉन्ट शैली';

  @override
  String get normal => 'सामान्य';

  @override
  String get bold => 'बोल्ड';

  @override
  String get italic => 'इटैलिक';

  @override
  String get handwriting => 'हस्तलिखित';

  @override
  String get addLocation => 'स्थान जोड़ें';

  @override
  String get enterLocationName => 'स्थान का नाम दर्ज करें';

  @override
  String get addLink => 'लिंक जोड़ें';

  @override
  String get buttonText => 'बटन टेक्स्ट';

  @override
  String get learnMore => 'और जानें';

  @override
  String get addHashtags => 'हैशटैग जोड़ें';

  @override
  String get addHashtag => 'हैशटैग जोड़ें';

  @override
  String get sendAsMessage => 'संदेश के रूप में भेजें';

  @override
  String get shareExternally => 'बाहरी रूप से साझा करें';

  @override
  String get checkOutStory => 'BananaTalk पर यह स्टोरी देखें!';

  @override
  String viewsTab(String count) {
    return 'व्यूज़ ($count)';
  }

  @override
  String reactionsTab(String count) {
    return 'प्रतिक्रियाएं ($count)';
  }

  @override
  String get processingVideo => 'वीडियो प्रोसेस हो रहा है...';

  @override
  String get link => 'लिंक';

  @override
  String unmuteUser(String name) {
    return '$name को अनम्यूट करें?';
  }

  @override
  String get willReceiveNotifications => 'आपको नए संदेशों की सूचनाएं प्राप्त होंगी।';

  @override
  String muteNotificationsFor(String name) {
    return '$name की सूचनाएं म्यूट करें';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return '$name की सूचनाएं अनम्यूट की गईं';
  }

  @override
  String notificationsMutedFor(String name) {
    return '$name की सूचनाएं म्यूट की गईं';
  }

  @override
  String get failedToUpdateMuteSettings => 'म्यूट सेटिंग्स अपडेट करने में विफल';

  @override
  String get oneHour => '1 घंटा';

  @override
  String get eightHours => '8 घंटे';

  @override
  String get oneWeek => '1 सप्ताह';

  @override
  String get always => 'हमेशा';

  @override
  String get failedToLoadBookmarks => 'बुकमार्क लोड करने में विफल';

  @override
  String get noBookmarkedMessages => 'कोई बुकमार्क किया गया संदेश नहीं';

  @override
  String get longPressToBookmark => 'बुकमार्क करने के लिए संदेश को देर तक दबाएं';

  @override
  String get thisWillRemoveFromBookmarks => 'यह संदेश को आपके बुकमार्क से हटा देगा।';

  @override
  String navigateToMessage(String name) {
    return '$name के साथ चैट में संदेश पर जाएं';
  }

  @override
  String bookmarkedOn(String date) {
    return '$date को बुकमार्क किया गया';
  }

  @override
  String get voiceMessage => 'वॉयस मैसेज';

  @override
  String get document => 'दस्तावेज़';

  @override
  String get attachment => 'अनुलग्नक';

  @override
  String get sendMeAMessage => 'मुझे संदेश भेजें';

  @override
  String get shareWithFriends => 'दोस्तों के साथ साझा करें';

  @override
  String get shareAnywhere => 'कहीं भी साझा करें';

  @override
  String get emailPreferences => 'ईमेल प्राथमिकताएं';

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
  String get category => 'श्रेणी';

  @override
  String get mood => 'मूड';

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
  String get applyFilters => 'फ़िल्टर लागू करें';

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
