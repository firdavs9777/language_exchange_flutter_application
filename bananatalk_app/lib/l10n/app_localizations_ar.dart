// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'BananaTalk';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get or => 'أو';

  @override
  String get signInWithGoogle => 'تسجيل الدخول باستخدام Google';

  @override
  String get signInWithApple => 'تسجيل الدخول باستخدام Apple';

  @override
  String get signInWithFacebook => 'تسجيل الدخول باستخدام Facebook';

  @override
  String get welcome => 'مرحباً';

  @override
  String get home => 'الرئيسية';

  @override
  String get messages => 'الرسائل';

  @override
  String get moments => 'اللحظات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get autoTranslate => 'ترجمة تلقائية';

  @override
  String get autoTranslateMessages => 'ترجمة الرسائل تلقائياً';

  @override
  String get autoTranslateMoments => 'ترجمة اللحظات تلقائياً';

  @override
  String get autoTranslateComments => 'ترجمة التعليقات تلقائياً';

  @override
  String get translate => 'ترجم';

  @override
  String get translated => 'مترجم';

  @override
  String get showOriginal => 'إظهار الأصل';

  @override
  String get showTranslation => 'إظهار الترجمة';

  @override
  String get translating => 'جاري الترجمة...';

  @override
  String get translationFailed => 'فشلت الترجمة';

  @override
  String get noTranslationAvailable => 'الترجمة غير متاحة';

  @override
  String translatedFrom(String language) {
    return 'مترجم من $language';
  }

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get share => 'مشاركة';

  @override
  String get like => 'إعجاب';

  @override
  String get comment => 'تعليق';

  @override
  String get send => 'إرسال';

  @override
  String get search => 'بحث';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get followers => 'المتابعون';

  @override
  String get following => 'يتابع';

  @override
  String get posts => 'المنشورات';

  @override
  String get visitors => 'الزوار';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجح';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get networkError => 'خطأ في الشبكة. يرجى التحقق من اتصالك.';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get ok => 'موافق';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get languageSettings => 'إعدادات اللغة';

  @override
  String get deviceLanguage => 'لغة الجهاز';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return 'جهازك مضبوط على: $flag $name';
  }

  @override
  String get youCanOverride => 'يمكنك تجاوز لغة الجهاز أدناه.';

  @override
  String languageChangedTo(String name) {
    return 'تم تغيير اللغة إلى $name';
  }

  @override
  String get errorChangingLanguage => 'خطأ في تغيير اللغة';

  @override
  String get autoTranslateSettings => 'إعدادات الترجمة التلقائية';

  @override
  String get automaticallyTranslateIncomingMessages => 'ترجمة الرسائل الواردة تلقائياً';

  @override
  String get automaticallyTranslateMomentsInFeed => 'ترجمة اللحظات في الخلاصة تلقائياً';

  @override
  String get automaticallyTranslateComments => 'ترجمة التعليقات تلقائياً';

  @override
  String get translationServiceBeingConfigured => 'خدمة الترجمة قيد التكوين. يرجى المحاولة مرة أخرى لاحقاً.';

  @override
  String get translationUnavailable => 'الترجمة غير متاحة';

  @override
  String get showLess => 'إظهار أقل';

  @override
  String get showMore => 'إظهار المزيد';

  @override
  String get comments => 'التعليقات';

  @override
  String get beTheFirstToComment => 'كن أول من يعلق.';

  @override
  String get writeAComment => 'اكتب تعليقاً...';

  @override
  String get report => 'الإبلاغ';

  @override
  String get reportMoment => 'الإبلاغ عن اللحظة';

  @override
  String get reportUser => 'الإبلاغ عن المستخدم';

  @override
  String get deleteMoment => 'حذف اللحظة؟';

  @override
  String get thisActionCannotBeUndone => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get momentDeleted => 'تم حذف اللحظة';

  @override
  String get editFeatureComingSoon => 'ميزة التحرير قادمة قريباً';

  @override
  String get userNotFound => 'لم يتم العثور على المستخدم';

  @override
  String get cannotReportYourOwnComment => 'لا يمكنك الإبلاغ عن تعليقك الخاص';

  @override
  String get profileSettings => 'إعدادات الملف الشخصي';

  @override
  String get editYourProfileInformation => 'تحرير معلومات ملفك الشخصي';

  @override
  String get blockedUsers => 'المستخدمون المحظورون';

  @override
  String get manageBlockedUsers => 'إدارة المستخدمين المحظورين';

  @override
  String get manageNotificationSettings => 'إدارة إعدادات الإشعارات';

  @override
  String get privacySecurity => 'الخصوصية والأمان';

  @override
  String get controlYourPrivacy => 'التحكم في خصوصيتك';

  @override
  String get changeAppLanguage => 'تغيير لغة التطبيق';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeAndDisplaySettings => 'إعدادات المظهر والعرض';

  @override
  String get myReports => 'تقاريري';

  @override
  String get viewYourSubmittedReports => 'عرض التقارير التي أرسلتها';

  @override
  String get reportsManagement => 'إدارة التقارير';

  @override
  String get manageAllReportsAdmin => 'إدارة جميع التقارير (المسؤول)';

  @override
  String get legalPrivacy => 'القانونية والخصوصية';

  @override
  String get termsPrivacySubscriptionInfo => 'الشروط والخصوصية ومعلومات الاشتراك';

  @override
  String get helpCenter => 'مركز المساعدة';

  @override
  String get getHelpAndSupport => 'الحصول على المساعدة والدعم';

  @override
  String get aboutBanaTalk => 'حول BanaTalk';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get permanentlyDeleteYourAccount => 'حذف حسابك نهائياً';

  @override
  String get loggedOutSuccessfully => 'تم تسجيل الخروج بنجاح';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get giftsLikes => 'الهدايا/الإعجابات';

  @override
  String get details => 'التفاصيل';

  @override
  String get to => 'إلى';

  @override
  String get banaTalk => 'BanaTalk';

  @override
  String get community => 'المجتمع';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String yearsOld(String age) {
    return '$age سنة';
  }

  @override
  String get searchConversations => 'البحث في المحادثات...';

  @override
  String get visitorTrackingNotAvailable => 'ميزة تتبع الزوار غير متاحة بعد. يلزم تحديث الخادم.';

  @override
  String get chatList => 'قائمة الدردشة';

  @override
  String get languageExchange => 'تبادل اللغة';

  @override
  String get nativeLanguage => 'اللغة الأم';

  @override
  String get learning => 'التعلم';

  @override
  String get notSet => 'غير محدد';

  @override
  String get about => 'حول';

  @override
  String get aboutMe => 'نبذة عني';

  @override
  String get photos => 'الصور';

  @override
  String get camera => 'الكاميرا';

  @override
  String get createMoment => 'إنشاء لحظة';

  @override
  String get addATitle => 'إضافة عنوان...';

  @override
  String get whatsOnYourMind => 'بم تفكر؟';

  @override
  String get addTags => 'إضافة علامات';

  @override
  String get done => 'تم';

  @override
  String get add => 'إضافة';

  @override
  String get enterTag => 'أدخل علامة';

  @override
  String get post => 'نشر';

  @override
  String get commentAddedSuccessfully => 'تمت إضافة التعليق بنجاح';

  @override
  String get clearFilters => 'مسح المرشحات';

  @override
  String get notificationSettings => 'إعدادات الإشعارات';

  @override
  String get enableNotifications => 'تفعيل الإشعارات';

  @override
  String get turnAllNotificationsOnOrOff => 'تشغيل أو إيقاف جميع الإشعارات';

  @override
  String get notificationTypes => 'أنواع الإشعارات';

  @override
  String get chatMessages => 'رسائل الدردشة';

  @override
  String get getNotifiedWhenYouReceiveMessages => 'تلقي إشعارات عند استلام الرسائل';

  @override
  String get likesAndCommentsOnYourMoments => 'الإعجابات والتعليقات على لحظاتك';

  @override
  String get whenPeopleYouFollowPostMoments => 'عندما ينشر الأشخاص الذين تتابعهم لحظات';

  @override
  String get friendRequests => 'طلبات الصداقة';

  @override
  String get whenSomeoneFollowsYou => 'عندما يتابعك شخص ما';

  @override
  String get profileVisits => 'زيارات الملف الشخصي';

  @override
  String get whenSomeoneViewsYourProfileVIP => 'عندما يرى شخص ما ملفك الشخصي (VIP)';

  @override
  String get marketing => 'التسويق';

  @override
  String get updatesAndPromotionalMessages => 'التحديثات والرسائل الترويجية';

  @override
  String get notificationPreferences => 'تفضيلات الإشعارات';

  @override
  String get sound => 'الصوت';

  @override
  String get playNotificationSounds => 'تشغيل أصوات الإشعارات';

  @override
  String get vibration => 'الاهتزاز';

  @override
  String get vibrateOnNotifications => 'الاهتزاز عند الإشعارات';

  @override
  String get showPreview => 'إظهار المعاينة';

  @override
  String get showMessagePreviewInNotifications => 'إظهار معاينة الرسالة في الإشعارات';

  @override
  String get mutedConversations => 'المحادثات المكتومة';

  @override
  String get conversation => 'محادثة';

  @override
  String get unmute => 'إلغاء كتم الصوت';

  @override
  String get systemNotificationSettings => 'إعدادات إشعارات النظام';

  @override
  String get manageNotificationsInSystemSettings => 'إدارة الإشعارات في إعدادات النظام';

  @override
  String get errorLoadingSettings => 'خطأ في تحميل الإعدادات';

  @override
  String get unblockUser => 'إلغاء حظر المستخدم';

  @override
  String get unblock => 'إلغاء الحظر';

  @override
  String get goBack => 'رجوع';

  @override
  String get messageSendTimeout => 'انتهت مهلة إرسال الرسالة. يرجى التحقق من اتصالك.';

  @override
  String get failedToSendMessage => 'فشل إرسال الرسالة';

  @override
  String get dailyMessageLimitExceeded => 'تم تجاوز الحد اليومي للرسائل. قم بالترقية إلى VIP للحصول على رسائل غير محدودة.';

  @override
  String get cannotSendMessageUserMayBeBlocked => 'لا يمكن إرسال الرسالة. قد يكون المستخدم محظوراً.';

  @override
  String get sessionExpired => 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get sendThisSticker => 'إرسال هذا الملصق؟';

  @override
  String get chooseHowYouWantToDeleteThisMessage => 'اختر كيفية حذف هذه الرسالة:';

  @override
  String get deleteForEveryone => 'حذف للجميع';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => 'يزيل الرسالة لك وللمستلم';

  @override
  String get deleteForMe => 'حذف لي فقط';

  @override
  String get removesTheMessageOnlyFromYourChat => 'يزيل الرسالة من محادثتك فقط';

  @override
  String get copy => 'نسخ';

  @override
  String get reply => 'رد';

  @override
  String get forward => 'إعادة توجيه';

  @override
  String get moreOptions => 'المزيد من الخيارات';

  @override
  String get noUsersAvailableToForwardTo => 'لا يوجد مستخدمون متاحون لإعادة التوجيه';

  @override
  String get searchMoments => 'البحث في اللحظات...';

  @override
  String searchInChatWith(String name) {
    return 'البحث في الدردشة مع $name';
  }

  @override
  String get typeAMessage => 'اكتب رسالة...';

  @override
  String get enterYourMessage => 'أدخل رسالتك';

  @override
  String get detectYourLocation => 'اكتشاف موقعك';

  @override
  String get tapToUpdateLocation => 'اضغط لتحديث الموقع';

  @override
  String get helpOthersFindYouNearby => 'ساعد الآخرين في العثور عليك بالقرب';

  @override
  String get selectYourNativeLanguage => 'اختر لغتك الأم';

  @override
  String get whichLanguageDoYouWantToLearn => 'ما اللغة التي تريد تعلمها؟';

  @override
  String get selectYourGender => 'اختر جنسك';

  @override
  String get addACaption => 'إضافة تعليق...';

  @override
  String get typeSomething => 'اكتب شيئاً...';

  @override
  String get gallery => 'المعرض';

  @override
  String get video => 'فيديو';

  @override
  String get text => 'نص';

  @override
  String get provideMoreInformation => 'تقديم المزيد من المعلومات...';

  @override
  String get searchByNameLanguageOrInterests => 'البحث بالاسم أو اللغة أو الاهتمامات...';

  @override
  String get addTagAndPressEnter => 'أضف علامة واضغط Enter';

  @override
  String replyTo(String name) {
    return 'رد على $name...';
  }

  @override
  String get highlightName => 'اسم التمييز';

  @override
  String get searchCloseFriends => 'البحث عن الأصدقاء المقربين...';

  @override
  String get askAQuestion => 'اطرح سؤالاً...';

  @override
  String option(String number) {
    return 'خيار $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return 'لماذا تقوم بالإبلاغ عن هذا $type؟';
  }

  @override
  String get additionalDetailsOptional => 'تفاصيل إضافية (اختياري)';

  @override
  String get warningThisActionIsPermanent => 'تحذير: هذا الإجراء دائم!';

  @override
  String get deletingYourAccountWillPermanentlyRemove => 'حذف حسابك سيحذف بشكل دائم:\n\n• ملفك الشخصي وجميع البيانات الشخصية\n• جميع رسائلك ومحادثاتك\n• جميع لحظاتك وقصصك\n• اشتراكك VIP (لا استرداد)\n• جميع اتصالاتك ومتابعيك\n\nلا يمكن التراجع عن هذا الإجراء.';

  @override
  String get clearAllNotifications => 'مسح جميع الإشعارات؟';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get notificationDebug => 'تصحيح الإشعارات';

  @override
  String get markAllRead => 'وضع علامة على الكل كمقروء';

  @override
  String get clearAll2 => 'مسح الكل';

  @override
  String get emailAddress => 'عنوان البريد الإلكتروني';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get alreadyHaveAnAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get login2 => 'تسجيل الدخول';

  @override
  String get selectYourNativeLanguage2 => 'اختر لغتك الأم';

  @override
  String get whichLanguageDoYouWantToLearn2 => 'ما اللغة التي تريد تعلمها؟';

  @override
  String get selectYourGender2 => 'اختر جنسك';

  @override
  String get dateFormat => 'YYYY.MM.DD';

  @override
  String get detectYourLocation2 => 'اكتشاف موقعك';

  @override
  String get tapToUpdateLocation2 => 'اضغط لتحديث الموقع';

  @override
  String get helpOthersFindYouNearby2 => 'ساعد الآخرين في العثور عليك بالقرب';

  @override
  String get couldNotOpenLink => 'لا يمكن فتح الرابط';

  @override
  String get legalPrivacy2 => 'القانون والخصوصية';

  @override
  String get termsOfUseEULA => 'شروط الاستخدام (EULA)';

  @override
  String get viewOurTermsAndConditions => 'عرض شروطنا وأحكامنا';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get howWeHandleYourData => 'كيف نتعامل مع بياناتك';

  @override
  String get emailNotifications => 'إشعارات البريد الإلكتروني';

  @override
  String get receiveEmailNotificationsFromBananaTalk => 'تلقي إشعارات البريد الإلكتروني من BananaTalk';

  @override
  String get weeklySummary => 'ملخص أسبوعي';

  @override
  String get activityRecapEverySunday => 'ملخص النشاط كل يوم أحد';

  @override
  String get newMessages => 'رسائل جديدة';

  @override
  String get whenYoureAwayFor24PlusHours => 'عندما تكون بعيداً لمدة 24+ ساعة';

  @override
  String get newFollowers => 'متابعون جدد';

  @override
  String get whenSomeoneFollowsYou2 => 'عندما يتابعك شخص ما';

  @override
  String get securityAlerts => 'تنبيهات الأمان';

  @override
  String get passwordLoginAlerts => 'تنبيهات كلمة المرور وتسجيل الدخول';

  @override
  String get unblockUser2 => 'إلغاء حظر المستخدم';

  @override
  String get blockedUsers2 => 'المستخدمون المحظورون';

  @override
  String get finalWarning => '⚠️ تحذير نهائي';

  @override
  String get deleteForever => 'حذف إلى الأبد';

  @override
  String get deleteAccount2 => 'حذف الحساب';

  @override
  String get enterYourPassword => 'أدخل كلمة المرور';

  @override
  String get yourPassword => 'كلمة المرور';

  @override
  String get typeDELETEToConfirm => 'اكتب DELETE للتأكيد';

  @override
  String get typeDELETEInCapitalLetters => 'اكتب DELETE بأحرف كبيرة';

  @override
  String sent(String emoji) {
    return 'تم الإرسال $emoji!';
  }

  @override
  String get replySent => 'تم إرسال الرد!';

  @override
  String get deleteStory => 'حذف القصة؟';

  @override
  String get thisStoryWillBeRemovedPermanently => 'سيتم حذف هذه القصة بشكل دائم.';

  @override
  String get noStories => 'لا توجد قصص';

  @override
  String views(String count) {
    return '$count مشاهدة';
  }

  @override
  String get reportStory => 'الإبلاغ عن القصة';

  @override
  String get reply2 => 'رد...';

  @override
  String get failedToPickImage => 'فشل اختيار الصورة';

  @override
  String get failedToTakePhoto => 'فشل التقاط الصورة';

  @override
  String get failedToPickVideo => 'فشل اختيار الفيديو';

  @override
  String get pleaseEnterSomeText => 'يرجى إدخال بعض النص';

  @override
  String get pleaseSelectMedia => 'يرجى اختيار الوسائط';

  @override
  String get storyPosted => 'تم نشر القصة!';

  @override
  String get textOnlyStoriesRequireAnImage => 'القصص النصية فقط تتطلب صورة';

  @override
  String get createStory => 'إنشاء قصة';

  @override
  String get change => 'تغيير';

  @override
  String get userIdNotFound => 'لم يتم العثور على معرف المستخدم. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get pleaseSelectAPaymentMethod => 'يرجى اختيار طريقة الدفع';

  @override
  String get startExploring => 'بدء الاستكشاف';

  @override
  String get close => 'إغلاق';

  @override
  String get payment => 'الدفع';

  @override
  String get upgradeToVIP => 'الترقية إلى VIP';

  @override
  String get errorLoadingProducts => 'خطأ في تحميل المنتجات';

  @override
  String get cancelVIPSubscription => 'إلغاء اشتراك VIP';

  @override
  String get keepVIP => 'الاحتفاظ بـ VIP';

  @override
  String get cancelSubscription => 'إلغاء الاشتراك';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'تم إلغاء اشتراك VIP بنجاح';

  @override
  String get vipStatus => 'حالة VIP';

  @override
  String get noActiveVIPSubscription => 'لا يوجد اشتراك VIP نشط';

  @override
  String get unlimitedMessages => 'رسائل غير محدودة';

  @override
  String get unlimitedProfileViews => 'مشاهدات الملف الشخصي غير محدودة';

  @override
  String get prioritySupport => 'دعم ذو أولوية';

  @override
  String get advancedSearch => 'بحث متقدم';

  @override
  String get profileBoost => 'تعزيز الملف الشخصي';

  @override
  String get adFreeExperience => 'تجربة خالية من الإعلانات';

  @override
  String get upgradeYourAccount => 'ترقية حسابك';

  @override
  String get moreMessages => 'المزيد من الرسائل';

  @override
  String get moreProfileViews => 'المزيد من مشاهدات الملف الشخصي';

  @override
  String get connectWithFriends => 'التواصل مع الأصدقاء';

  @override
  String get reviewStarted => 'بدأت المراجعة';

  @override
  String get reportResolved => 'تم حل التقرير';

  @override
  String get reportDismissed => 'تم رفض التقرير';

  @override
  String get selectAction => 'اختر الإجراء';

  @override
  String get noViolation => 'لا يوجد انتهاك';

  @override
  String get contentRemoved => 'تم إزالة المحتوى';

  @override
  String get userWarned => 'تم تحذير المستخدم';

  @override
  String get userSuspended => 'تم تعليق المستخدم';

  @override
  String get userBanned => 'تم حظر المستخدم';

  @override
  String get addNotesOptional => 'إضافة ملاحظات (اختياري)';

  @override
  String get enterModeratorNotes => 'أدخل ملاحظات المشرف...';

  @override
  String get skip => 'تخطي';

  @override
  String get startReview => 'بدء المراجعة';

  @override
  String get resolve => 'حل';

  @override
  String get dismiss => 'رفض';

  @override
  String get filterReports => 'تصفية التقارير';

  @override
  String get all => 'الكل';

  @override
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

  @override
  String get myReports2 => 'تقاريري';

  @override
  String get blockUser => 'حظر المستخدم';

  @override
  String get block => 'حظر';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => 'هل تريد أيضاً حظر هذا المستخدم؟';

  @override
  String get noThanks => 'لا، شكراً';

  @override
  String get yesBlockThem => 'نعم، احظرهم';

  @override
  String get reportUser2 => 'الإبلاغ عن المستخدم';

  @override
  String get submitReport => 'إرسال التقرير';

  @override
  String get addAQuestionAndAtLeast2Options => 'أضف سؤالاً واختيارين على الأقل';

  @override
  String get addOption => 'إضافة خيار';

  @override
  String get anonymousVoting => 'تصويت مجهول';

  @override
  String get create => 'إنشاء';

  @override
  String get typeYourAnswer => 'اكتب إجابتك...';

  @override
  String get send2 => 'إرسال';

  @override
  String get yourPrompt => 'طلبك...';

  @override
  String get add2 => 'إضافة';

  @override
  String get contentNotAvailable => 'المحتوى غير متاح';

  @override
  String get profileNotAvailable => 'الملف الشخصي غير متاح';

  @override
  String get noMomentsToShow => 'لا توجد لحظات للعرض';

  @override
  String get storiesNotAvailable => 'القصص غير متاحة';

  @override
  String get cantMessageThisUser => 'لا يمكن إرسال رسالة لهذا المستخدم';

  @override
  String get pleaseSelectAReason => 'يرجى اختيار سبب';

  @override
  String get reportSubmitted => 'تم إرسال التقرير. شكراً لمساعدتك في الحفاظ على مجتمعنا آمناً.';

  @override
  String get youHaveAlreadyReportedThisMoment => 'لقد أبلغت بالفعل عن هذه اللحظة';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => 'أخبرنا المزيد عن سبب إبلاغك عن هذا';

  @override
  String get errorSharing => 'خطأ في المشاركة';

  @override
  String get deviceInfo => 'معلومات الجهاز';

  @override
  String get recommended => 'موصى به';

  @override
  String get anyLanguage => 'أي لغة';

  @override
  String get noLanguagesFound => 'لم يتم العثور على لغات';

  @override
  String get selectALanguage => 'اختر لغة';

  @override
  String get languagesAreStillLoading => 'جاري تحميل اللغات...';

  @override
  String get selectNativeLanguage => 'اختر لغتك الأم';
}
