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
  String get more => 'और';

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
  String get overview => 'अवलोकन';

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
  String get deleteComment => 'Delete Comment?';

  @override
  String get commentDeleted => 'Comment deleted';

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
  String get clearCache => 'कैश साफ़ करें';

  @override
  String get clearCacheSubtitle => 'स्टोरेज स्पेस खाली करें';

  @override
  String get clearCacheDescription => 'यह सभी कैश्ड इमेज, वीडियो और ऑडियो फ़ाइलों को हटा देगा। मीडिया को फिर से डाउनलोड करते समय ऐप अस्थायी रूप से धीमी गति से कंटेंट लोड कर सकता है।';

  @override
  String get clearCacheHint => 'यदि इमेज या ऑडियो ठीक से लोड नहीं हो रहा है तो इसका उपयोग करें।';

  @override
  String get clearingCache => 'कैश साफ़ हो रहा है...';

  @override
  String get cacheCleared => 'कैश सफलतापूर्वक साफ़ हो गया! इमेज फिर से लोड होंगी।';

  @override
  String get clearCacheFailed => 'कैश साफ़ करने में विफल';

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
  String get chats => 'चैट';

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
  String get momentUnsaved => 'सहेजे गए से हटाया गया';

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
  String get openSettings => 'सेटिंग्स खोलें';

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
  String get newHighlight => 'नया हाइलाइट';

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
  String get deleteHighlight => 'हाइलाइट हटाएं';

  @override
  String get editHighlight => 'हाइलाइट संपादित करें';

  @override
  String get addMoreToStory => 'स्टोरी में और जोड़ें';

  @override
  String get noViewersYet => 'अभी तक कोई दर्शक नहीं';

  @override
  String get noReactionsYet => 'अभी तक कोई प्रतिक्रिया नहीं';

  @override
  String get leaveRoom => 'रूम छोड़ें';

  @override
  String get areYouSureLeaveRoom => 'क्या आप वाकई इस वॉयस रूम को छोड़ना चाहते हैं?';

  @override
  String get stay => 'रहें';

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
  String get chooseFromGallery => 'Choose from Gallery';

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
  String get videoMustBeUnder1GB => 'वीडियो 1GB से कम होना चाहिए।';

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
  String get edited => '(संपादित)';

  @override
  String get now => 'अभी';

  @override
  String weeksAgo(int count) {
    return '$count सप्ताह पहले';
  }

  @override
  String viewRepliesCount(int count) {
    return '── $count उत्तर देखें';
  }

  @override
  String get hideReplies => '── उत्तर छुपाएं';

  @override
  String get saveMoment => 'पल सहेजें';

  @override
  String get removeFromSaved => 'सहेजे गए से हटाएं';

  @override
  String get momentSaved => 'सहेजा गया';

  @override
  String get failedToSave => 'सहेजने में विफल';

  @override
  String get checkOutMoment => 'BananaTalk पर यह पल देखें!';

  @override
  String get failedToLoadMoments => 'पल लोड करने में विफल';

  @override
  String get noMomentsMatchFilters => 'आपके फ़िल्टर से कोई पल मेल नहीं खाता';

  @override
  String get beFirstToShareMoment => 'पहला पल साझा करने वाले बनें!';

  @override
  String get tryDifferentSearch => 'कोई अलग खोज शब्द आज़माएं';

  @override
  String get tryAdjustingFilters => 'अपने फ़िल्टर समायोजित करें';

  @override
  String get noSavedMoments => 'कोई सहेजे गए पल नहीं';

  @override
  String get tapBookmarkToSave => 'पल सहेजने के लिए बुकमार्क आइकन टैप करें';

  @override
  String get failedToLoadVideo => 'वीडियो लोड करने में विफल';

  @override
  String get titleRequired => 'शीर्षक आवश्यक है';

  @override
  String titleTooLong(int max) {
    return 'शीर्षक $max अक्षर या कम होना चाहिए';
  }

  @override
  String get descriptionRequired => 'विवरण आवश्यक है';

  @override
  String descriptionTooLong(int max) {
    return 'विवरण $max अक्षर या कम होना चाहिए';
  }

  @override
  String get scheduledDateMustBeFuture => 'निर्धारित तिथि भविष्य में होनी चाहिए';

  @override
  String get recent => 'हाल के';

  @override
  String get popular => 'लोकप्रिय';

  @override
  String get trending => 'ट्रेंडिंग';

  @override
  String get mostRecent => 'सबसे हाल का';

  @override
  String get mostPopular => 'सबसे लोकप्रिय';

  @override
  String get allTime => 'सभी समय';

  @override
  String get today => 'आज';

  @override
  String get thisWeek => 'इस सप्ताह';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String replyingTo(String userName) {
    return '$userName को जवाब';
  }

  @override
  String get listView => 'सूची दृश्य';

  @override
  String get quickMatch => 'त्वरित मैच';

  @override
  String get onlineNow => 'अभी ऑनलाइन';

  @override
  String speaksLanguage(String language) {
    return '$language बोलता है';
  }

  @override
  String learningLanguage(String language) {
    return '$language सीख रहा है';
  }

  @override
  String get noPartnersFound => 'कोई साझेदार नहीं मिला';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return 'कोई उपयोगकर्ता नहीं मिला जो $learning मातृभाषा के रूप में बोलता हो या $native सीखना चाहता हो।';
  }

  @override
  String get removeAllFilters => 'सभी फ़िल्टर हटाएं';

  @override
  String get browseAllUsers => 'सभी उपयोगकर्ता देखें';

  @override
  String get allCaughtUp => 'सब देख लिया!';

  @override
  String get loadingMore => 'और लोड हो रहा है...';

  @override
  String get findingMorePartners => 'और साझेदार खोजे जा रहे हैं...';

  @override
  String get seenAllPartners => 'आपने सभी साझेदार देख लिए';

  @override
  String get startOver => 'फिर से शुरू करें';

  @override
  String get changeFilters => 'फ़िल्टर बदलें';

  @override
  String get findingPartners => 'साझेदार खोजे जा रहे हैं...';

  @override
  String get setLocationReminder => 'पास के साझेदार खोजने के लिए अपना स्थान सेट करें';

  @override
  String get updateLocationReminder => 'बेहतर परिणामों के लिए अपना स्थान अपडेट करें';

  @override
  String get male => 'पुरुष';

  @override
  String get female => 'महिला';

  @override
  String get other => 'अन्य';

  @override
  String get browseMen => 'पुरुष देखें';

  @override
  String get browseWomen => 'महिलाएं देखें';

  @override
  String get noMaleUsersFound => 'कोई पुरुष उपयोगकर्ता नहीं मिला';

  @override
  String get noFemaleUsersFound => 'कोई महिला उपयोगकर्ता नहीं मिली';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => 'केवल नए उपयोगकर्ता';

  @override
  String get showNewUsers => 'नए उपयोगकर्ता दिखाएं';

  @override
  String get prioritizeNearby => 'पास वालों को प्राथमिकता दें';

  @override
  String get showNearbyFirst => 'पहले पास वाले दिखाएं';

  @override
  String get setLocationToEnable => 'सक्षम करने के लिए स्थान सेट करें';

  @override
  String get radius => 'दायरा';

  @override
  String get findingYourLocation => 'आपका स्थान खोजा जा रहा है...';

  @override
  String get enableLocationForDistance => 'दूरी के लिए स्थान सक्षम करें';

  @override
  String get enableLocationDescription => 'पास के भाषा साझेदार खोजने के लिए स्थान सेवाएं सक्षम करें';

  @override
  String get enableGps => 'GPS सक्षम करें';

  @override
  String get browseByCityCountry => 'शहर/देश से खोजें';

  @override
  String get peopleNearby => 'पास के लोग';

  @override
  String get noNearbyUsersFound => 'पास में कोई उपयोगकर्ता नहीं मिला';

  @override
  String get tryExpandingSearch => 'खोज का दायरा बढ़ाएं';

  @override
  String get exploreByCity => 'शहर के अनुसार खोजें';

  @override
  String get exploreByCurrentCity => 'वर्तमान शहर से खोजें';

  @override
  String get interactiveWorldMap => 'इंटरैक्टिव विश्व मानचित्र';

  @override
  String get searchByCityName => 'शहर के नाम से खोजें';

  @override
  String get seeUserCountsPerCountry => 'प्रति देश उपयोगकर्ता संख्या देखें';

  @override
  String get upgradeToVip => 'VIP में अपग्रेड करें';

  @override
  String get searchByCity => 'शहर से खोजें';

  @override
  String usersWorldwide(String count) {
    return 'दुनिया भर में $count उपयोगकर्ता';
  }

  @override
  String get noUsersFound => 'कोई उपयोगकर्ता नहीं मिला';

  @override
  String get tryDifferentCity => 'कोई अलग शहर आज़माएं';

  @override
  String usersCount(String count) {
    return '$count उपयोगकर्ता';
  }

  @override
  String get searchCountry => 'देश खोजें...';

  @override
  String get wave => 'अभिवादन करें';

  @override
  String get newUser => 'नया उपयोगकर्ता';

  @override
  String get warningPermanent => 'चेतावनी: यह क्रिया स्थायी है!';

  @override
  String get deleteAccountWarning => 'आपका खाता हटाने से स्थायी रूप से हटाया जाएगा:\n\n• आपकी प्रोफ़ाइल और सभी व्यक्तिगत डेटा\n• आपके सभी संदेश और बातचीत\n• आपके सभी पल और स्टोरी\n• आपकी VIP सदस्यता (कोई रिफंड नहीं)\n• आपके सभी कनेक्शन और फॉलोअर्स\n\nयह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get requiredForEmailOnly => 'केवल ईमेल खातों के लिए आवश्यक';

  @override
  String get pleaseEnterPassword => 'कृपया अपना पासवर्ड दर्ज करें';

  @override
  String get typeDELETE => 'DELETE टाइप करें';

  @override
  String get mustTypeDELETE => 'जारी रखने के लिए DELETE टाइप करना होगा';

  @override
  String get deletingAccount => 'खाता हटाया जा रहा है...';

  @override
  String get deleteMyAccountPermanently => 'मेरा खाता स्थायी रूप से हटाएं';

  @override
  String get whatsYourNativeLanguage => 'आपकी मातृभाषा क्या है?';

  @override
  String get helpsMatchWithLearners => 'सीखने वालों से मिलाने में मदद करता है';

  @override
  String get whatAreYouLearning => 'आप क्या सीख रहे हैं?';

  @override
  String get connectWithNativeSpeakers => 'मातृभाषा बोलने वालों से जुड़ें';

  @override
  String get selectLearningLanguage => 'सीखने की भाषा चुनें';

  @override
  String get selectCurrentLevel => 'वर्तमान स्तर चुनें';

  @override
  String get beginner => 'शुरुआती';

  @override
  String get elementary => 'प्राथमिक';

  @override
  String get intermediate => 'मध्यवर्ती';

  @override
  String get upperIntermediate => 'उच्च मध्यवर्ती';

  @override
  String get advanced => 'उन्नत';

  @override
  String get proficient => 'कुशल';

  @override
  String get showingPartnersByDistance => 'दूरी के अनुसार साझेदार दिखाए जा रहे हैं';

  @override
  String get enableLocationForResults => 'बेहतर परिणामों के लिए स्थान सक्षम करें';

  @override
  String get enable => 'सक्षम करें';

  @override
  String get locationNotSet => 'स्थान सेट नहीं है';

  @override
  String get tellUsAboutYourself => 'अपने बारे में बताएं';

  @override
  String get justACoupleQuickThings => 'बस कुछ जल्दी बातें';

  @override
  String get gender => 'लिंग';

  @override
  String get birthDate => 'जन्म तिथि';

  @override
  String get selectYourBirthDate => 'अपनी जन्म तिथि चुनें';

  @override
  String get continueButton => 'जारी रखें';

  @override
  String get pleaseSelectGender => 'कृपया अपना लिंग चुनें';

  @override
  String get pleaseSelectBirthDate => 'कृपया अपनी जन्म तिथि चुनें';

  @override
  String get mustBe18 => 'आपकी उम्र कम से कम 18 वर्ष होनी चाहिए';

  @override
  String get invalidDate => 'अमान्य तिथि';

  @override
  String get almostDone => 'लगभग हो गया!';

  @override
  String get addPhotoLocationForMatches => 'बेहतर मैच के लिए फ़ोटो और स्थान जोड़ें';

  @override
  String get addProfilePhoto => 'प्रोफ़ाइल फ़ोटो जोड़ें';

  @override
  String get optionalUpTo6Photos => 'वैकल्पिक - 6 फ़ोटो तक';

  @override
  String get requiredUpTo6Photos => 'आवश्यक — अधिकतम 6 फ़ोटो';

  @override
  String get profilePhotoRequired => 'कृपया कम से कम एक प्रोफ़ाइल फ़ोटो जोड़ें';

  @override
  String get locationOptional => 'स्थान वैकल्पिक है — आप बाद में जोड़ सकते हैं';

  @override
  String get maximum6Photos => 'अधिकतम 6 फ़ोटो';

  @override
  String get tapToDetectLocation => 'स्थान पता करने के लिए टैप करें';

  @override
  String get optionalHelpsNearbyPartners => 'वैकल्पिक - पास के साझेदार खोजने में मदद करता है';

  @override
  String get startLearning => 'सीखना शुरू करें';

  @override
  String get photoLocationOptional => 'फ़ोटो और स्थान वैकल्पिक हैं';

  @override
  String get pleaseAcceptTerms => 'कृपया सेवा की शर्तें स्वीकार करें';

  @override
  String get iAgreeToThe => 'मैं सहमत हूं';

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get tapToSelectLanguage => 'भाषा चुनने के लिए टैप करें';

  @override
  String yourLevelIn(String language) {
    return '$language में आपका स्तर (वैकल्पिक)';
  }

  @override
  String get yourCurrentLevel => 'आपका वर्तमान स्तर';

  @override
  String get nativeCannotBeSameAsLearning => 'मातृभाषा सीखने वाली भाषा से अलग होनी चाहिए';

  @override
  String get learningCannotBeSameAsNative => 'सीखने वाली भाषा मातृभाषा से अलग होनी चाहिए';

  @override
  String stepOf(String current, String total) {
    return 'चरण $current / $total';
  }

  @override
  String get continueWithGoogle => 'Google से जारी रखें';

  @override
  String get registerLink => 'पंजीकरण';

  @override
  String get pleaseEnterBothEmailAndPassword => 'कृपया ईमेल और पासवर्ड दोनों दर्ज करें';

  @override
  String get pleaseEnterValidEmail => 'कृपया एक वैध ईमेल दर्ज करें';

  @override
  String get loginSuccessful => 'लॉगिन सफल!';

  @override
  String get stepOneOfTwo => 'चरण 1 / 2';

  @override
  String get createYourAccount => 'अपना खाता बनाएं';

  @override
  String get basicInfoToGetStarted => 'शुरू करने के लिए बुनियादी जानकारी';

  @override
  String get emailVerifiedLabel => 'ईमेल (सत्यापित)';

  @override
  String get nameLabel => 'नाम';

  @override
  String get yourDisplayName => 'आपका प्रदर्शन नाम';

  @override
  String get atLeast8Characters => 'कम से कम 8 अक्षर';

  @override
  String get confirmPasswordHint => 'पासवर्ड की पुष्टि करें';

  @override
  String get nextButton => 'अगला';

  @override
  String get pleaseEnterYourName => 'कृपया अपना नाम दर्ज करें';

  @override
  String get pleaseEnterAPassword => 'कृपया पासवर्ड दर्ज करें';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get otherGender => 'अन्य';

  @override
  String get continueWithGoogleAccount => 'अपने Google खाते से जारी रखें\nसुगम अनुभव के लिए';

  @override
  String get signingYouIn => 'साइन इन हो रहा है...';

  @override
  String get backToSignInMethods => 'साइन इन विधियों पर वापस';

  @override
  String get securedByGoogle => 'Google द्वारा सुरक्षित';

  @override
  String get dataProtectedEncryption => 'आपका डेटा मानक एन्क्रिप्शन से सुरक्षित है';

  @override
  String get welcomeCompleteProfile => 'स्वागत है! कृपया अपना प्रोफ़ाइल पूरा करें';

  @override
  String welcomeBackName(String name) {
    return 'वापसी पर स्वागत, $name!';
  }

  @override
  String get continueWithAppleId => 'अपने Apple ID से जारी रखें\nसुरक्षित अनुभव के लिए';

  @override
  String get continueWithApple => 'Apple से जारी रखें';

  @override
  String get securedByApple => 'Apple द्वारा सुरक्षित';

  @override
  String get privacyProtectedApple => 'Apple साइन-इन से आपकी गोपनीयता सुरक्षित है';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get enterEmailToGetStarted => 'शुरू करने के लिए ईमेल दर्ज करें';

  @override
  String get continueText => 'जारी रखें';

  @override
  String get pleaseEnterEmailAddress => 'कृपया अपना ईमेल दर्ज करें';

  @override
  String get verificationCodeSent => 'सत्यापन कोड भेजा गया!';

  @override
  String get forgotPasswordTitle => 'पासवर्ड भूल गए';

  @override
  String get resetPasswordTitle => 'पासवर्ड रीसेट';

  @override
  String get enterEmailForResetCode => 'अपना ईमेल दर्ज करें और हम आपको रीसेट कोड भेजेंगे';

  @override
  String get sendResetCode => 'रीसेट कोड भेजें';

  @override
  String get resetCodeSent => 'रीसेट कोड भेजा गया!';

  @override
  String get rememberYourPassword => 'पासवर्ड याद है?';

  @override
  String get verifyCode => 'कोड सत्यापित करें';

  @override
  String get enterResetCode => 'रीसेट कोड दर्ज करें';

  @override
  String get weSentCodeTo => 'हमने 6 अंकों का कोड भेजा';

  @override
  String get pleaseEnterAll6Digits => 'कृपया सभी 6 अंक दर्ज करें';

  @override
  String get codeVerifiedCreatePassword => 'कोड सत्यापित! नया पासवर्ड बनाएं';

  @override
  String get verify => 'सत्यापित करें';

  @override
  String get didntReceiveCode => 'कोड नहीं मिला?';

  @override
  String get resend => 'पुनः भेजें';

  @override
  String resendWithTimer(String timer) {
    return 'पुनः भेजें ($timerस)';
  }

  @override
  String get resetCodeResent => 'रीसेट कोड पुनः भेजा गया!';

  @override
  String get verifyEmail => 'ईमेल सत्यापित करें';

  @override
  String get verifyYourEmail => 'अपना ईमेल सत्यापित करें';

  @override
  String get emailVerifiedSuccessfully => 'ईमेल सफलतापूर्वक सत्यापित!';

  @override
  String get verificationCodeResent => 'सत्यापन कोड पुनः भेजा गया!';

  @override
  String get createNewPassword => 'नया पासवर्ड बनाएं';

  @override
  String get enterNewPasswordBelow => 'नीचे अपना नया पासवर्ड दर्ज करें';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get confirmPasswordLabel => 'पासवर्ड की पुष्टि करें';

  @override
  String get pleaseFillAllFields => 'कृपया सभी फ़ील्ड भरें';

  @override
  String get passwordResetSuccessful => 'पासवर्ड रीसेट सफल! नए पासवर्ड से लॉगिन करें';

  @override
  String get privacyTitle => 'गोपनीयता';

  @override
  String get profileVisibility => 'प्रोफ़ाइल दृश्यता';

  @override
  String get showCountryRegion => 'देश/क्षेत्र दिखाएं';

  @override
  String get showCountryRegionDesc => 'अपने प्रोफ़ाइल पर देश दिखाएं';

  @override
  String get showCity => 'शहर दिखाएं';

  @override
  String get showCityDesc => 'अपने प्रोफ़ाइल पर शहर दिखाएं';

  @override
  String get showAge => 'उम्र दिखाएं';

  @override
  String get showAgeDesc => 'अपने प्रोफ़ाइल पर उम्र दिखाएं';

  @override
  String get showZodiacSign => 'राशि दिखाएं';

  @override
  String get showZodiacSignDesc => 'अपने प्रोफ़ाइल पर राशि दिखाएं';

  @override
  String get onlineStatusSection => 'ऑनलाइन स्थिति';

  @override
  String get showOnlineStatus => 'ऑनलाइन स्थिति दिखाएं';

  @override
  String get showOnlineStatusDesc => 'दूसरों को आपकी ऑनलाइन स्थिति दिखाएं';

  @override
  String get otherSettings => 'अन्य सेटिंग्स';

  @override
  String get showGiftingLevel => 'उपहार स्तर दिखाएं';

  @override
  String get showGiftingLevelDesc => 'उपहार स्तर बैज दिखाएं';

  @override
  String get birthdayNotifications => 'जन्मदिन सूचनाएं';

  @override
  String get birthdayNotificationsDesc => 'जन्मदिन पर सूचनाएं प्राप्त करें';

  @override
  String get personalizedAds => 'व्यक्तिगत विज्ञापन';

  @override
  String get personalizedAdsDesc => 'व्यक्तिगत विज्ञापनों की अनुमति दें';

  @override
  String get saveChanges => 'बदलाव सहेजें';

  @override
  String get privacySettingsSaved => 'गोपनीयता सेटिंग्स सहेजी गईं';

  @override
  String get locationSection => 'स्थान';

  @override
  String get updateLocation => 'स्थान अपडेट करें';

  @override
  String get updateLocationDesc => 'अपना वर्तमान स्थान ताज़ा करें';

  @override
  String get currentLocation => 'वर्तमान स्थान';

  @override
  String get locationNotAvailable => 'स्थान उपलब्ध नहीं';

  @override
  String get locationUpdated => 'स्थान सफलतापूर्वक अपडेट किया गया';

  @override
  String get locationPermissionDenied => 'स्थान अनुमति अस्वीकार। कृपया सेटिंग्स में सक्षम करें।';

  @override
  String get locationServiceDisabled => 'स्थान सेवाएं अक्षम हैं। कृपया सक्षम करें।';

  @override
  String get updatingLocation => 'स्थान अपडेट हो रहा है...';

  @override
  String get locationCouldNotBeUpdated => 'स्थान अपडेट नहीं हो सका';

  @override
  String get incomingAudioCall => 'इनकमिंग ऑडियो कॉल';

  @override
  String get incomingVideoCall => 'इनकमिंग वीडियो कॉल';

  @override
  String get outgoingCall => 'कॉल कर रहे हैं...';

  @override
  String get callRinging => 'रिंग हो रहा है...';

  @override
  String get callConnecting => 'कनेक्ट हो रहा है...';

  @override
  String get callConnected => 'कनेक्टेड';

  @override
  String get callReconnecting => 'पुनः कनेक्ट हो रहा है...';

  @override
  String get callEnded => 'कॉल समाप्त';

  @override
  String get callFailed => 'कॉल विफल';

  @override
  String get callMissed => 'मिस्ड कॉल';

  @override
  String get callDeclined => 'कॉल अस्वीकृत';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => 'स्वीकार करें';

  @override
  String get declineCall => 'अस्वीकार करें';

  @override
  String get endCall => 'समाप्त करें';

  @override
  String get muteCall => 'म्यूट';

  @override
  String get unmuteCall => 'अनम्यूट';

  @override
  String get speakerOn => 'स्पीकर';

  @override
  String get speakerOff => 'ईयरपीस';

  @override
  String get videoOn => 'वीडियो चालू';

  @override
  String get videoOff => 'वीडियो बंद';

  @override
  String get switchCamera => 'कैमरा बदलें';

  @override
  String get callPermissionDenied => 'कॉल के लिए माइक्रोफ़ोन अनुमति आवश्यक है';

  @override
  String get cameraPermissionDenied => 'वीडियो कॉल के लिए कैमरा अनुमति आवश्यक है';

  @override
  String get callConnectionFailed => 'कनेक्ट नहीं हो सका। कृपया पुनः प्रयास करें।';

  @override
  String get userBusy => 'उपयोगकर्ता व्यस्त है';

  @override
  String get userOffline => 'उपयोगकर्ता ऑफ़लाइन है';

  @override
  String get callHistory => 'कॉल इतिहास';

  @override
  String get noCallHistory => 'कोई कॉल इतिहास नहीं';

  @override
  String get missedCalls => 'मिस्ड कॉल्स';

  @override
  String get allCalls => 'सभी कॉल्स';

  @override
  String get callBack => 'वापस कॉल करें';

  @override
  String callAt(String time) {
    return '$time पर कॉल';
  }

  @override
  String get audioCall => 'ऑडियो कॉल';

  @override
  String get voiceRoom => 'वॉयस रूम';

  @override
  String get noVoiceRooms => 'कोई सक्रिय वॉयस रूम नहीं';

  @override
  String get createVoiceRoom => 'वॉयस रूम बनाएं';

  @override
  String get joinRoom => 'रूम में शामिल हों';

  @override
  String get leaveRoomConfirm => 'रूम छोड़ें?';

  @override
  String get leaveRoomMessage => 'क्या आप वाकई इस रूम को छोड़ना चाहते हैं?';

  @override
  String get roomTitle => 'रूम का शीर्षक';

  @override
  String get roomTitleHint => 'रूम का शीर्षक दर्ज करें';

  @override
  String get roomTopic => 'विषय';

  @override
  String get roomLanguage => 'भाषा';

  @override
  String get roomHost => 'होस्ट';

  @override
  String roomParticipants(int count) {
    return '$count प्रतिभागी';
  }

  @override
  String roomMaxParticipants(int count) {
    return 'अधिकतम $count प्रतिभागी';
  }

  @override
  String get selectTopic => 'विषय चुनें';

  @override
  String get raiseHand => 'हाथ उठाएं';

  @override
  String get lowerHand => 'हाथ नीचे करें';

  @override
  String get handRaisedNotification => 'हाथ उठाया! होस्ट आपका अनुरोध देखेगा।';

  @override
  String get handLoweredNotification => 'हाथ नीचे किया';

  @override
  String get muteParticipant => 'प्रतिभागी को म्यूट करें';

  @override
  String get kickParticipant => 'रूम से हटाएं';

  @override
  String get promoteToCoHost => 'को-होस्ट बनाएं';

  @override
  String get endRoomConfirm => 'रूम समाप्त करें?';

  @override
  String get endRoomMessage => 'यह सभी प्रतिभागियों के लिए रूम समाप्त कर देगा।';

  @override
  String get roomEnded => 'होस्ट द्वारा रूम समाप्त';

  @override
  String get youWereRemoved => 'आपको रूम से हटा दिया गया';

  @override
  String get roomIsFull => 'रूम भरा हुआ है';

  @override
  String get roomChat => 'रूम चैट';

  @override
  String get noMessages => 'अभी तक कोई संदेश नहीं';

  @override
  String get typeMessage => 'संदेश लिखें...';

  @override
  String get voiceRoomsDescription => 'लाइव बातचीत में शामिल हों और बोलने का अभ्यास करें';

  @override
  String liveRoomsCount(int count) {
    return '$count लाइव';
  }

  @override
  String get noActiveRooms => 'कोई सक्रिय रूम नहीं';

  @override
  String get noActiveRoomsDescription => 'पहले वॉयस रूम शुरू करें और दूसरों के साथ बोलने का अभ्यास करें!';

  @override
  String get startRoom => 'रूम शुरू करें';

  @override
  String get createRoom => 'रूम बनाएं';

  @override
  String get roomCreated => 'रूम सफलतापूर्वक बनाया गया!';

  @override
  String get failedToCreateRoom => 'रूम बनाने में विफल';

  @override
  String get errorLoadingRooms => 'रूम लोड करने में त्रुटि';

  @override
  String get pleaseEnterRoomTitle => 'कृपया रूम का शीर्षक दर्ज करें';

  @override
  String get startLiveConversation => 'लाइव बातचीत शुरू करें';

  @override
  String get maxParticipants => 'अधिकतम प्रतिभागी';

  @override
  String nPeople(int count) {
    return '$count लोग';
  }

  @override
  String hostedBy(String name) {
    return '$name द्वारा होस्ट किया गया';
  }

  @override
  String get liveLabel => 'लाइव';

  @override
  String get joinLabel => 'शामिल हों';

  @override
  String get fullLabel => 'भरा हुआ';

  @override
  String get justStarted => 'अभी शुरू हुआ';

  @override
  String get allLanguages => 'सभी भाषाएँ';

  @override
  String get allTopics => 'सभी विषय';

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
  String get you => 'आप';

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
  String get dataAndStorage => 'डेटा और स्टोरेज';

  @override
  String get manageStorageAndDownloads => 'स्टोरेज और डाउनलोड प्रबंधित करें';

  @override
  String get storageUsage => 'स्टोरेज उपयोग';

  @override
  String get totalCacheSize => 'कुल कैश साइज';

  @override
  String get imageCache => 'इमेज कैश';

  @override
  String get voiceMessagesCache => 'वॉइस मैसेज';

  @override
  String get videoCache => 'वीडियो कैश';

  @override
  String get otherCache => 'अन्य कैश';

  @override
  String get autoDownloadMedia => 'मीडिया ऑटो-डाउनलोड';

  @override
  String get currentNetwork => 'वर्तमान नेटवर्क';

  @override
  String get images => 'इमेज';

  @override
  String get videos => 'वीडियो';

  @override
  String get voiceMessagesShort => 'वॉइस मैसेज';

  @override
  String get documentsLabel => 'दस्तावेज़';

  @override
  String get wifiOnly => 'केवल WiFi';

  @override
  String get never => 'कभी नहीं';

  @override
  String get clearAllCache => 'सभी कैश साफ़ करें';

  @override
  String get allCache => 'सभी कैश';

  @override
  String get clearAllCacheConfirmation => 'यह सभी कैश की गई इमेज, वॉइस मैसेज, वीडियो और अन्य फाइलें हटा देगा। ऐप अस्थायी रूप से कंटेंट धीमे लोड कर सकता है।';

  @override
  String clearCacheConfirmationFor(String category) {
    return '$category साफ़ करें?';
  }

  @override
  String storageToFree(String size) {
    return '$size खाली होगा';
  }

  @override
  String get calculating => 'गणना हो रही है...';

  @override
  String get noDataToShow => 'दिखाने के लिए कोई डेटा नहीं';

  @override
  String get profileCompletion => 'प्रोफ़ाइल पूर्णता';

  @override
  String get justGettingStarted => 'अभी शुरुआत हुई है';

  @override
  String get lookingGood => 'अच्छा लग रहा है!';

  @override
  String get almostThere => 'लगभग हो गया!';

  @override
  String addMissingFields(String fields, Object field) {
    return 'अपनी प्रोफ़ाइल पूरी करने के लिए $field जोड़ें';
  }

  @override
  String get profilePicture => 'प्रोफ़ाइल फ़ोटो';

  @override
  String get nativeSpeaker => 'मातृभाषी';

  @override
  String peopleInterestedInTopic(Object count) {
    return '$count लोग रुचि रखते हैं';
  }

  @override
  String get beFirstToAddTopic => 'इस विषय को जोड़ने वाले पहले बनें!';

  @override
  String get recentMoments => 'हाल के पल';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get study => 'अध्ययन';

  @override
  String get followerMoments => 'फॉलोअर्स के पल';

  @override
  String get whenPeopleYouFollowPost => 'जब आप जिन लोगों को फॉलो करते हैं वे नए पल पोस्ट करते हैं';

  @override
  String get noNotificationsYet => 'अभी तक कोई सूचना नहीं';

  @override
  String get whenYouGetNotifications => 'जब आपको सूचनाएं मिलेंगी, वे यहां दिखाई देंगी';

  @override
  String get failedToLoadNotifications => 'सूचनाएं लोड करने में विफल';

  @override
  String get clearAllNotificationsConfirm => 'क्या आप सभी सूचनाएं हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get tapToChange => 'बदलने के लिए टैप करें';

  @override
  String get noPictureSet => 'कोई तस्वीर नहीं';

  @override
  String get nameAndGender => 'नाम और लिंग';

  @override
  String get languageLevel => 'भाषा स्तर';

  @override
  String get personalInformation => 'व्यक्तिगत जानकारी';

  @override
  String get mbti => 'MBTI';

  @override
  String get topicsOfInterest => 'रुचि के विषय';

  @override
  String get levelBeginner => 'शुरुआती';

  @override
  String get levelElementary => 'प्राथमिक';

  @override
  String get levelIntermediate => 'मध्यवर्ती';

  @override
  String get levelUpperIntermediate => 'उच्च मध्यवर्ती';

  @override
  String get levelAdvanced => 'उन्नत';

  @override
  String get levelProficient => 'कुशल';

  @override
  String get selectYourLevel => 'अपना स्तर चुनें';

  @override
  String howWellDoYouSpeak(String language) {
    return '$language कितनी अच्छी तरह बोलते हैं?';
  }

  @override
  String get theLanguage => 'भाषा';

  @override
  String languageLevelSetTo(String level) {
    return 'भाषा स्तर $level पर सेट';
  }

  @override
  String get failedToUpdate => 'अपडेट विफल';

  @override
  String get editHometown => 'गृहनगर संपादित करें';

  @override
  String get useCurrentLocation => 'वर्तमान स्थान का उपयोग करें';

  @override
  String get detecting => 'पहचाना जा रहा है...';

  @override
  String get getCurrentLocation => 'वर्तमान स्थान प्राप्त करें';

  @override
  String get country => 'देश';

  @override
  String get city => 'शहर';

  @override
  String get coordinates => 'निर्देशांक';

  @override
  String get noLocationDetectedYet => 'कोई स्थान नहीं मिला';

  @override
  String get detected => 'पता लगा';

  @override
  String get savedHometown => 'गृहनगर सहेजा गया';

  @override
  String get locationServicesDisabled => 'स्थान सेवाएं अक्षम हैं';

  @override
  String get locationPermissionPermanentlyDenied => 'स्थान अनुमति अस्वीकृत';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get editBio => 'बायो संपादित करें';

  @override
  String get bioUpdatedSuccessfully => 'बायो अपडेट हुआ';

  @override
  String get tellOthersAboutYourself => 'अपने बारे में बताएं...';

  @override
  String charactersCount(int count) {
    return '$count/500 अक्षर';
  }

  @override
  String get selectYourMbti => 'MBTI चुनें';

  @override
  String get myBloodType => 'मेरा रक्त प्रकार';

  @override
  String get pleaseSelectABloodType => 'रक्त प्रकार चुनें';

  @override
  String get nativeLanguageRequired => 'मूल भाषा (आवश्यक)';

  @override
  String get languageToLearnRequired => 'सीखने की भाषा (आवश्यक)';

  @override
  String get nativeLanguageCannotBeSame => 'मूल भाषा सीखने वाली भाषा नहीं हो सकती';

  @override
  String get learningLanguageCannotBeSame => 'सीखने की भाषा मूल भाषा नहीं हो सकती';

  @override
  String get pleaseSelectALanguage => 'भाषा चुनें';

  @override
  String get editInterests => 'रुचियां संपादित करें';

  @override
  String maxTopicsAllowed(int count) {
    return 'अधिकतम $count विषय';
  }

  @override
  String get topicsUpdatedSuccessfully => 'विषय अपडेट हुए!';

  @override
  String get failedToUpdateTopics => 'विषय अपडेट विफल';

  @override
  String selectedCount(int count, int max) {
    return '$count/$max चयनित';
  }

  @override
  String get profilePictures => 'प्रोफ़ाइल तस्वीरें';

  @override
  String get addImages => 'तस्वीरें जोड़ें';

  @override
  String get selectUpToImages => '5 तक तस्वीरें चुनें';

  @override
  String get takeAPhoto => 'फोटो लें';

  @override
  String get removeImage => 'तस्वीर हटाएं';

  @override
  String get removeImageConfirm => 'यह तस्वीर हटाएं?';

  @override
  String get removeAll => 'सभी हटाएं';

  @override
  String get removeAllSelectedImages => 'सभी चयनित हटाएं';

  @override
  String get removeAllSelectedImagesConfirm => 'सभी चयनित तस्वीरें हटाएं?';

  @override
  String get yourProfilePictureWillBeKept => 'मौजूदा तस्वीर रहेगी';

  @override
  String get removeAllImages => 'सभी तस्वीरें हटाएं';

  @override
  String get removeAllImagesConfirm => 'सभी प्रोफ़ाइल तस्वीरें हटाएं?';

  @override
  String get currentImages => 'वर्तमान तस्वीरें';

  @override
  String get newImages => 'नई तस्वीरें';

  @override
  String get addMoreImages => 'और तस्वीरें जोड़ें';

  @override
  String uploadImages(int count) {
    return '$count तस्वीर अपलोड करें';
  }

  @override
  String get imageRemovedSuccessfully => 'तस्वीर हटाई गई';

  @override
  String get imagesUploadedSuccessfully => 'तस्वीरें अपलोड हुईं';

  @override
  String get selectedImagesCleared => 'चयनित तस्वीरें साफ़';

  @override
  String get extraImagesRemovedSuccessfully => 'अतिरिक्त तस्वीरें हटाई गईं';

  @override
  String get mustKeepAtLeastOneProfilePicture => 'एक तस्वीर रखनी होगी';

  @override
  String get noProfilePicturesToRemove => 'हटाने के लिए तस्वीर नहीं';

  @override
  String get authenticationTokenNotFound => 'टोकन नहीं मिला';

  @override
  String get saveChangesQuestion => 'परिवर्तन सहेजें?';

  @override
  String youHaveUnuploadedImages(int count) {
    return '$count तस्वीरें अपलोड नहीं हुईं। अभी करें?';
  }

  @override
  String get discard => 'छोड़ें';

  @override
  String get upload => 'अपलोड';

  @override
  String maxImagesInfo(int max, int current) {
    return 'अधिकतम $max तस्वीरें। वर्तमान: $current/$max';
  }

  @override
  String canOnlyAddMoreImages(int count, int max) {
    return 'केवल $count और जोड़ सकते हैं। अधिकतम $max।';
  }

  @override
  String get maxImagesPerUpload => 'एक बार में अधिकतम 5 तस्वीरें';

  @override
  String canOnlyHaveMaxImages(int max) {
    return 'अधिकतम $max तस्वीरें';
  }

  @override
  String get imageSizeExceedsLimit => 'आकार 10MB से अधिक';

  @override
  String get unsupportedImageFormat => 'असमर्थित प्रारूप';

  @override
  String get pleaseSelectAtLeastOneImage => 'एक तस्वीर चुनें';

  @override
  String get basicInformation => 'मूलभूत जानकारी';

  @override
  String get languageToLearn => 'सीखने की भाषा';

  @override
  String get hometown => 'गृहनगर';

  @override
  String get characters => 'अक्षर';

  @override
  String get failedToLoadLanguages => 'भाषाएं लोड विफल';

  @override
  String get studyHub => 'अध्ययन केंद्र';

  @override
  String get dailyLearningJourney => 'आपकी दैनिक सीखने की यात्रा';

  @override
  String get learnTab => 'सीखें';

  @override
  String get aiTools => 'AI उपकरण';

  @override
  String get streak => 'स्ट्रीक';

  @override
  String get lessons => 'पाठ';

  @override
  String get words => 'शब्द';

  @override
  String get quickActions => 'त्वरित क्रियाएं';

  @override
  String get review => 'समीक्षा';

  @override
  String wordsDue(int count) {
    return '$count शब्द बाकी';
  }

  @override
  String get addWords => 'शब्द जोड़ें';

  @override
  String get buildVocabulary => 'शब्द भंडार बनाएं';

  @override
  String get practiceWithAI => 'AI से अभ्यास करें';

  @override
  String get aiPracticeDescription => 'चैट, क्विज़, व्याकरण और उच्चारण';

  @override
  String get dailyChallenges => 'दैनिक चुनौतियां';

  @override
  String get allChallengesCompleted => 'सभी चुनौतियां पूरी!';

  @override
  String get continueLearning => 'सीखना जारी रखें';

  @override
  String get structuredLearningPath => 'संरचित सीखने का मार्ग';

  @override
  String get vocabulary => 'शब्दावली';

  @override
  String get yourWordCollection => 'आपका शब्द संग्रह';

  @override
  String get achievements => 'उपलब्धियां';

  @override
  String get badgesAndMilestones => 'बैज और मील के पत्थर';

  @override
  String get failedToLoadLearningData => 'सीखने का डेटा लोड करने में विफल';

  @override
  String get startYourJourney => 'अपनी यात्रा शुरू करें!';

  @override
  String get startJourneyDescription => 'पाठ पूरे करें, शब्द भंडार बनाएं\nऔर अपनी प्रगति ट्रैक करें';

  @override
  String levelN(int level) {
    return 'स्तर $level';
  }

  @override
  String xpEarned(int xp) {
    return '$xp XP अर्जित';
  }

  @override
  String nextLevel(int level) {
    return 'अगला: स्तर $level';
  }

  @override
  String xpToGo(int xp) {
    return '$xp XP शेष';
  }

  @override
  String get aiConversationPartner => 'AI वार्तालाप साथी';

  @override
  String get practiceWithAITutor => 'अपने AI शिक्षक के साथ बोलने का अभ्यास करें';

  @override
  String get startConversation => 'बातचीत शुरू करें';

  @override
  String get aiFeatures => 'AI सुविधाएं';

  @override
  String get aiLessons => 'AI पाठ';

  @override
  String get learnWithAI => 'AI से सीखें';

  @override
  String get grammar => 'व्याकरण';

  @override
  String get checkWriting => 'लेखन जांचें';

  @override
  String get pronunciation => 'उच्चारण';

  @override
  String get improveSpeaking => 'बोलने में सुधार';

  @override
  String get translation => 'अनुवाद';

  @override
  String get smartTranslate => 'स्मार्ट अनुवाद';

  @override
  String get aiQuizzes => 'AI क्विज़';

  @override
  String get testKnowledge => 'ज्ञान परीक्षण';

  @override
  String get lessonBuilder => 'पाठ निर्माता';

  @override
  String get customLessons => 'कस्टम पाठ';

  @override
  String get yourAIProgress => 'AI के साथ आपकी प्रगति';

  @override
  String get quizzes => 'क्विज़';

  @override
  String get avgScore => 'औसत अंक';

  @override
  String get focusAreas => 'ध्यान देने के क्षेत्र';

  @override
  String accuracyPercent(String accuracy) {
    return '$accuracy% सटीकता';
  }

  @override
  String get practice => 'अभ्यास';

  @override
  String get browse => 'ब्राउज़';

  @override
  String get noRecommendedLessons => 'कोई अनुशंसित पाठ उपलब्ध नहीं';

  @override
  String get noLessonsFound => 'कोई पाठ नहीं मिला';

  @override
  String get createCustomLessonDescription => 'AI से अपना कस्टम पाठ बनाएं';

  @override
  String get createLessonWithAI => 'AI से पाठ बनाएं';

  @override
  String get allLevels => 'सभी स्तर';

  @override
  String get levelA1 => 'A1 शुरुआती';

  @override
  String get levelA2 => 'A2 प्राथमिक';

  @override
  String get levelB1 => 'B1 मध्यवर्ती';

  @override
  String get levelB2 => 'B2 उच्च-मध्यवर्ती';

  @override
  String get levelC1 => 'C1 उन्नत';

  @override
  String get levelC2 => 'C2 कुशल';

  @override
  String get failedToLoadLessons => 'पाठ लोड करने में विफल';

  @override
  String get pin => 'पिन करें';

  @override
  String get unpin => 'अनपिन करें';

  @override
  String get editMessage => 'संदेश संपादित करें';

  @override
  String get enterMessage => 'संदेश दर्ज करें...';

  @override
  String get deleteMessageTitle => 'संदेश हटाएं';

  @override
  String get actionCannotBeUndone => 'यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get onlyRemovesFromDevice => 'केवल आपके डिवाइस से हटाता है';

  @override
  String get availableWithinOneHour => 'केवल 1 घंटे के भीतर उपलब्ध';

  @override
  String get available => 'उपलब्ध';

  @override
  String get forwardMessage => 'संदेश अग्रेषित करें';

  @override
  String get selectUsersToForward => 'अग्रेषित करने के लिए उपयोगकर्ता चुनें:';

  @override
  String forwardCount(int count) {
    return 'अग्रेषित ($count)';
  }

  @override
  String get pinnedMessage => 'पिन किया गया संदेश';

  @override
  String get photoMedia => 'फ़ोटो';

  @override
  String get videoMedia => 'वीडियो';

  @override
  String get voiceMessageMedia => 'वॉयस संदेश';

  @override
  String get documentMedia => 'दस्तावेज़';

  @override
  String get locationMedia => 'स्थान';

  @override
  String get stickerMedia => 'स्टिकर';

  @override
  String get smileys => 'स्माइली';

  @override
  String get emotions => 'भावनाएं';

  @override
  String get handGestures => 'हाथ के इशारे';

  @override
  String get hearts => 'दिल';

  @override
  String get tapToSayHi => 'हाय कहने के लिए टैप करें!';

  @override
  String get sendWaveToStart => 'चैट शुरू करने के लिए हैलो भेजें';

  @override
  String get documentMustBeUnder50MB => 'दस्तावेज़ 50MB से कम होना चाहिए।';

  @override
  String get editWithin15Minutes => 'संदेश केवल 15 मिनट के भीतर संपादित किए जा सकते हैं';

  @override
  String messageForwardedTo(int count) {
    return 'संदेश $count उपयोगकर्ता(ओं) को अग्रेषित किया गया';
  }

  @override
  String get failedToLoadUsers => 'उपयोगकर्ता लोड करने में विफल';

  @override
  String get voice => 'आवाज़';

  @override
  String get searchGifs => 'GIFs खोजें...';

  @override
  String get trendingGifs => 'ट्रेंडिंग';

  @override
  String get poweredByGiphy => 'Powered by GIPHY';

  @override
  String get gif => 'GIF';

  @override
  String get noGifsFound => 'कोई GIF नहीं मिला';

  @override
  String get failedToLoadGifs => 'GIFs लोड करने में विफल';

  @override
  String get gifSent => 'GIF';

  @override
  String get filterCommunities => 'फ़िल्टर';

  @override
  String get reset => 'रीसेट';

  @override
  String get findYourPerfect => 'अपना आदर्श';

  @override
  String get languagePartner => 'भाषा साथी खोजें';

  @override
  String get learningLanguageLabel => 'सीखने की भाषा';

  @override
  String get ageRange => 'आयु सीमा';

  @override
  String get genderPreference => 'लिंग प्राथमिकता';

  @override
  String get any => 'कोई भी';

  @override
  String get showNewUsersSubtitle => 'पिछले 6 दिनों में शामिल हुए उपयोगकर्ता दिखाएं';

  @override
  String get autoDetectLocation => 'मेरा स्थान स्वचालित रूप से पहचानें';

  @override
  String get selectCountry => 'देश चुनें';

  @override
  String get anyCountry => 'कोई भी देश';

  @override
  String get loadingLanguages => 'भाषाएं लोड हो रही हैं...';

  @override
  String minAge(int age) {
    return 'न्यूनतम: $age';
  }

  @override
  String maxAge(int age) {
    return 'अधिकतम: $age';
  }

  @override
  String get captionRequired => 'कैप्शन आवश्यक है';

  @override
  String captionTooLong(int maxLength) {
    return 'कैप्शन $maxLength अक्षर या उससे कम होना चाहिए';
  }

  @override
  String get maximumImagesReached => 'अधिकतम छवि सीमा पूरी';

  @override
  String maximumImagesReachedDescription(int maxImages) {
    return 'आप प्रति मोमेंट अधिकतम $maxImages छवियां अपलोड कर सकते हैं।';
  }

  @override
  String maximumImagesAddedPartial(int maxImages, int added) {
    return 'अधिकतम $maxImages छवियां। केवल $added छवियां जोड़ी गईं।';
  }

  @override
  String get locationAccessRestricted => 'स्थान पहुंच प्रतिबंधित';

  @override
  String get locationPermissionNeeded => 'स्थान अनुमति आवश्यक';

  @override
  String get addToYourMoment => 'अपने मोमेंट में जोड़ें';

  @override
  String get categoryLabel => 'श्रेणी';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get scheduleOptional => 'शेड्यूल (वैकल्पिक)';

  @override
  String get scheduleForLater => 'बाद के लिए शेड्यूल करें';

  @override
  String get addMore => 'और जोड़ें';

  @override
  String get howAreYouFeeling => 'आप कैसा महसूस कर रहे हैं?';

  @override
  String get pleaseWaitOptimizingVideo => 'कृपया प्रतीक्षा करें, वीडियो ऑप्टिमाइज़ हो रहा है';

  @override
  String unsupportedVideoFormat(String formats) {
    return 'असमर्थित प्रारूप। उपयोग करें: $formats';
  }

  @override
  String get chooseBackground => 'पृष्ठभूमि चुनें';

  @override
  String likedByXPeople(int count) {
    return '$count लोगों ने पसंद किया';
  }

  @override
  String xComments(int count) {
    return '$count टिप्पणियाँ';
  }

  @override
  String get oneComment => '1 टिप्पणी';

  @override
  String get addAComment => 'टिप्पणी जोड़ें...';

  @override
  String viewXReplies(int count) {
    return '$count उत्तर देखें';
  }

  @override
  String seenByX(int count) {
    return '$count ने देखा';
  }

  @override
  String xHoursAgo(int count) {
    return '$count घंटे पहले';
  }

  @override
  String xMinutesAgo(int count) {
    return '$count मिनट पहले';
  }

  @override
  String get repliedToYourStory => 'आपकी स्टोरी का जवाब दिया';

  @override
  String mentionedYouInComment(String name) {
    return '$name ने आपको एक टिप्पणी में उल्लेख किया';
  }

  @override
  String repliedToYourComment(String name) {
    return '$name ने आपकी टिप्पणी का जवाब दिया';
  }

  @override
  String reactedToYourComment(String name) {
    return '$name ने आपकी टिप्पणी पर प्रतिक्रिया दी';
  }

  @override
  String get addReaction => 'प्रतिक्रिया जोड़ें';

  @override
  String get attachImage => 'छवि संलग्न करें';

  @override
  String get pickGif => 'GIF चुनें';

  @override
  String get textStory => 'टेक्स्ट';

  @override
  String get typeYourStory => 'अपनी कहानी लिखें...';

  @override
  String get selectBackground => 'पृष्ठभूमि चुनें';

  @override
  String get highlightsTitle => 'हाइलाइट्स';

  @override
  String get highlightTitle => 'हाइलाइट शीर्षक';

  @override
  String get createNewHighlight => 'नया बनाएं';

  @override
  String get selectStories => 'कहानियां चुनें';

  @override
  String get selectCover => 'कवर चुनें';

  @override
  String get addText => 'टेक्स्ट जोड़ें';

  @override
  String get fontStyleLabel => 'फ़ॉन्ट शैली';

  @override
  String get textColorLabel => 'टेक्स्ट रंग';

  @override
  String get dragToDelete => 'हटाने के लिए यहां खींचें';
}
