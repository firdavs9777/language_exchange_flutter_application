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
  String get overview => 'نظرة عامة';

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
  String get deleteComment => 'Delete Comment?';

  @override
  String get commentDeleted => 'Comment deleted';

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
  String get chats => 'الدردشات';

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
  String get bloodType => 'Blood Type';

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
  String get unblockUser => 'إلغاء الحظر';

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
  String get sessionExpired => 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.';

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
    return 'تم الإرسال!';
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
  String get subscriptionExpired => 'انتهى الاشتراك';

  @override
  String get vipExpiredMessage => 'انتهى اشتراك VIP الخاص بك. جدد الآن للاستمرار في التمتع بميزات غير محدودة!';

  @override
  String get expiredOn => 'انتهى في';

  @override
  String get renewVIP => 'تجديد VIP';

  @override
  String get whatYoureMissing => 'ما تفتقده';

  @override
  String get manageInAppStore => 'إدارة في متجر التطبيقات';

  @override
  String get becomeVIP => 'كن VIP';

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
  String get clear => 'مسح';

  @override
  String get apply => 'تطبيق';

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

  @override
  String get subscriptionDetails => 'تفاصيل الاشتراك';

  @override
  String get activeFeatures => 'الميزات النشطة';

  @override
  String get legalInformation => 'المعلومات القانونية';

  @override
  String get termsOfUse => 'شروط الاستخدام';

  @override
  String get manageSubscription => 'إدارة الاشتراك';

  @override
  String get manageSubscriptionInSettings => 'لإلغاء اشتراكك، انتقل إلى الإعدادات > [اسمك] > الاشتراكات على جهازك.';

  @override
  String get contactSupportToCancel => 'لإلغاء اشتراكك، يرجى الاتصال بفريق الدعم لدينا.';

  @override
  String get status => 'الحالة';

  @override
  String get active => 'نشط';

  @override
  String get plan => 'الخطة';

  @override
  String get startDate => 'تاريخ البدء';

  @override
  String get endDate => 'تاريخ الانتهاء';

  @override
  String get nextBillingDate => 'تاريخ الفاتورة التالية';

  @override
  String get autoRenew => 'التجديد التلقائي';

  @override
  String get pleaseLogInToContinue => 'يرجى تسجيل الدخول للمتابعة';

  @override
  String get purchaseCanceledOrFailed => 'تم إلغاء الشراء أو فشل. يرجى المحاولة مرة أخرى.';

  @override
  String get maximumTagsAllowed => 'الحد الأقصى 5 علامات مسموح بها';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => 'يرجى إزالة الصور أولاً لإضافة فيديو';

  @override
  String get unsupportedFormat => 'تنسيق غير مدعوم';

  @override
  String get errorProcessingVideo => 'خطأ في معالجة الفيديو';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'يرجى إزالة الصور أولاً لتسجيل فيديو';

  @override
  String get locationAdded => 'تمت إضافة الموقع';

  @override
  String get failedToGetLocation => 'فشل الحصول على الموقع';

  @override
  String get notNow => 'ليس الآن';

  @override
  String get videoUploadFailed => 'فشل رفع الفيديو';

  @override
  String get skipVideo => 'تخطي الفيديو';

  @override
  String get retryUpload => 'إعادة المحاولة';

  @override
  String get momentCreatedSuccessfully => 'تم إنشاء اللحظة بنجاح';

  @override
  String get uploadingMomentInBackground => 'جاري رفع اللحظة في الخلفية...';

  @override
  String get failedToQueueUpload => 'فشل في إضافة إلى قائمة الرفع';

  @override
  String get viewProfile => 'عرض الملف الشخصي';

  @override
  String get mediaLinksAndDocs => 'الوسائط والروابط والمستندات';

  @override
  String get wallpaper => 'خلفية';

  @override
  String get userIdNotAvailable => 'معرف المستخدم غير متاح';

  @override
  String get cannotBlockYourself => 'لا يمكنك حظر نفسك';

  @override
  String get chatWallpaper => 'خلفية المحادثة';

  @override
  String get wallpaperSavedLocally => 'تم حفظ الخلفية محلياً';

  @override
  String get messageCopied => 'تم نسخ الرسالة';

  @override
  String get forwardFeatureComingSoon => 'ميزة إعادة التوجيه قادمة قريباً';

  @override
  String get momentUnsaved => 'تمت الإزالة من المحفوظات';

  @override
  String get documentPickerComingSoon => 'منتقي المستندات قادم قريباً';

  @override
  String get contactSharingComingSoon => 'مشاركة جهات الاتصال قادمة قريباً';

  @override
  String get featureComingSoon => 'الميزة قادمة قريباً';

  @override
  String get answerSent => 'تم إرسال الإجابة!';

  @override
  String get noImagesAvailable => 'لا توجد صور متاحة';

  @override
  String get mentionPickerComingSoon => 'منتقي الإشارات قادم قريباً';

  @override
  String get musicPickerComingSoon => 'منتقي الموسيقى قادم قريباً';

  @override
  String get repostFeatureComingSoon => 'ميزة إعادة النشر قادمة قريباً';

  @override
  String get addFriendsFromYourProfile => 'أضف أصدقاء من ملفك الشخصي';

  @override
  String get quickReplyAdded => 'تمت إضافة الرد السريع';

  @override
  String get quickReplyDeleted => 'تم حذف الرد السريع';

  @override
  String get linkCopied => 'تم نسخ الرابط!';

  @override
  String get maximumOptionsAllowed => 'الحد الأقصى 10 خيارات مسموح بها';

  @override
  String get minimumOptionsRequired => 'الحد الأدنى 2 خيارات مطلوبة';

  @override
  String get pleaseEnterAQuestion => 'يرجى إدخال سؤال';

  @override
  String get pleaseAddAtLeast2Options => 'يرجى إضافة خيارين على الأقل';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => 'يرجى اختيار الإجابة الصحيحة للاختبار';

  @override
  String get correctionSent => 'تم إرسال التصحيح!';

  @override
  String get sort => 'ترتيب';

  @override
  String get savedMoments => 'اللحظات المحفوظة';

  @override
  String get unsave => 'إلغاء الحفظ';

  @override
  String get playingAudio => 'جاري تشغيل الصوت...';

  @override
  String get failedToGenerateQuiz => 'فشل في إنشاء الاختبار';

  @override
  String get failedToAddComment => 'فشل في إضافة التعليق';

  @override
  String get hello => 'مرحباً!';

  @override
  String get howAreYou => 'كيف حالك؟';

  @override
  String get cannotOpen => 'لا يمكن الفتح';

  @override
  String get errorOpeningLink => 'خطأ في فتح الرابط';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get follow => 'متابعة';

  @override
  String get unfollow => 'إلغاء المتابعة';

  @override
  String get mute => 'كتم الصوت';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get lastSeen => 'آخر ظهور';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(String count) {
    return 'منذ $count دقيقة';
  }

  @override
  String hoursAgo(String count) {
    return 'منذ $count ساعة';
  }

  @override
  String get yesterday => 'أمس';

  @override
  String get signInWithEmail => 'تسجيل الدخول بالبريد الإلكتروني';

  @override
  String get partners => 'الشركاء';

  @override
  String get nearby => 'بالقرب';

  @override
  String get topics => 'المواضيع';

  @override
  String get waves => 'التحيات';

  @override
  String get voiceRooms => 'صوت';

  @override
  String get filters => 'التصفية';

  @override
  String get searchCommunity => 'البحث بالاسم أو اللغة أو الاهتمامات...';

  @override
  String get bio => 'نبذة';

  @override
  String get noBioYet => 'لا توجد نبذة حتى الآن.';

  @override
  String get languages => 'اللغات';

  @override
  String get native => 'أصلي';

  @override
  String get interests => 'الاهتمامات';

  @override
  String get noMomentsYet => 'لا توجد لحظات بعد';

  @override
  String get unableToLoadMoments => 'تعذر تحميل اللحظات';

  @override
  String get map => 'خريطة';

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
  String get openSettings => 'فتح الإعدادات';

  @override
  String get refresh => 'Refresh';

  @override
  String get videoCall => 'فيديو';

  @override
  String get voiceCall => 'اتصال';

  @override
  String get message => 'رسالة';

  @override
  String get pleaseLoginToFollow => 'يرجى تسجيل الدخول للمتابعة';

  @override
  String get pleaseLoginToCall => 'يرجى تسجيل الدخول للاتصال';

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
  String get soon => 'قريباً';

  @override
  String comingSoon(String feature) {
    return '$feature قريباً!';
  }

  @override
  String get muteNotifications => 'كتم الإشعارات';

  @override
  String get unmuteNotifications => 'إلغاء كتم الإشعارات';

  @override
  String get operationCompleted => 'تمت العملية';

  @override
  String get couldNotOpenMaps => 'تعذر فتح الخريطة';

  @override
  String hasntSharedMoments(Object name) {
    return '$name لم يشارك أي لحظات بعد';
  }

  @override
  String messageUser(String name) {
    return 'مراسلة $name';
  }

  @override
  String notFollowingUser(String name) {
    return 'لم تكن تتابع $name';
  }

  @override
  String youFollowedUser(String name) {
    return 'تابعت $name';
  }

  @override
  String youUnfollowedUser(String name) {
    return 'ألغيت متابعة $name';
  }

  @override
  String unfollowUser(String name) {
    return 'إلغاء متابعة $name';
  }

  @override
  String get typing => 'يكتب';

  @override
  String get connecting => 'جاري الاتصال...';

  @override
  String daysAgo(int count) {
    return 'منذ $count يوم';
  }

  @override
  String get maxTagsAllowed => '5 وسوم كحد أقصى';

  @override
  String maxImagesAllowed(int count) {
    return '$count صورة كحد أقصى';
  }

  @override
  String get pleaseRemoveImagesFirst => 'يرجى إزالة الصور أولاً';

  @override
  String get exchange3MessagesBeforeCall => 'تحتاج إلى تبادل 3 رسائل على الأقل قبل الاتصال';

  @override
  String mediaWithUser(String name) {
    return 'الوسائط مع $name';
  }

  @override
  String get errorLoadingMedia => 'خطأ في تحميل الوسائط';

  @override
  String get savedMomentsTitle => 'اللحظات المحفوظة';

  @override
  String get removeBookmark => 'إزالة من المحفوظات؟';

  @override
  String get thisWillRemoveBookmark => 'سيتم إزالة الرسالة من إشاراتك المرجعية.';

  @override
  String get remove => 'إزالة';

  @override
  String get bookmarkRemoved => 'تمت إزالة المحفوظة';

  @override
  String get bookmarkedMessages => 'الرسائل المحفوظة';

  @override
  String get wallpaperSaved => 'تم حفظ الخلفية محلياً';

  @override
  String get typeDeleteToConfirm => 'اكتب DELETE للتأكيد';

  @override
  String get storyArchive => 'أرشيف القصص';

  @override
  String get newHighlight => 'إبراز جديد';

  @override
  String get addToHighlight => 'إضافة إلى الإبراز';

  @override
  String get repost => 'إعادة النشر';

  @override
  String get repostFeatureSoon => 'ميزة إعادة النشر قريباً';

  @override
  String get closeFriends => 'الأصدقاء المقربون';

  @override
  String get addFriends => 'إضافة أصدقاء';

  @override
  String get highlights => 'الإبرازات';

  @override
  String get createHighlight => 'إنشاء إبراز';

  @override
  String get deleteHighlight => 'حذف الإبراز؟';

  @override
  String get editHighlight => 'تعديل الإبراز';

  @override
  String get addMoreToStory => 'إضافة المزيد إلى القصة';

  @override
  String get noViewersYet => 'لا يوجد مشاهدون بعد';

  @override
  String get noReactionsYet => 'لا توجد تفاعلات بعد';

  @override
  String get leaveRoom => 'مغادرة الغرفة';

  @override
  String get areYouSureLeaveRoom => 'هل أنت متأكد أنك تريد مغادرة هذه الغرفة؟';

  @override
  String get stay => 'البقاء';

  @override
  String get leave => 'مغادرة';

  @override
  String get enableGPS => 'تفعيل GPS';

  @override
  String wavedToUser(String name) {
    return 'لوّحت لـ $name!';
  }

  @override
  String get areYouSureFollow => 'هل أنت متأكد أنك تريد متابعة';

  @override
  String get failedToLoadProfile => 'فشل تحميل الملف الشخصي';

  @override
  String get noFollowersYet => 'لا يوجد متابعون بعد';

  @override
  String get noFollowingYet => 'لا تتابع أحداً بعد';

  @override
  String get searchUsers => 'البحث عن مستخدمين...';

  @override
  String get noResultsFound => 'لم يتم العثور على نتائج';

  @override
  String get loadingFailed => 'فشل التحميل';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get shareStory => 'مشاركة القصة';

  @override
  String get thisWillDeleteStory => 'سيؤدي هذا إلى حذف هذه القصة نهائياً.';

  @override
  String get storyDeleted => 'تم حذف القصة';

  @override
  String get addCaption => 'إضافة وصف...';

  @override
  String get yourStory => 'قصتك';

  @override
  String get sendMessage => 'إرسال رسالة';

  @override
  String get replyToStory => 'الرد على القصة...';

  @override
  String get viewAllReplies => 'عرض جميع الردود';

  @override
  String get preparingVideo => 'جاري تحضير الفيديو...';

  @override
  String videoOptimized(String size, String savings) {
    return 'تم تحسين الفيديو: $size ميجابايت (وفر $savings%)';
  }

  @override
  String get failedToProcessVideo => 'فشل معالجة الفيديو';

  @override
  String get optimizingForBestExperience => 'جاري التحسين للحصول على أفضل تجربة';

  @override
  String get pleaseSelectImageOrVideo => 'يرجى اختيار صورة أو فيديو لقصتك';

  @override
  String get storyCreatedSuccessfully => 'تم إنشاء القصة بنجاح!';

  @override
  String get uploadingStoryInBackground => 'جاري رفع القصة في الخلفية...';

  @override
  String get storyCreationFailed => 'فشل إنشاء القصة';

  @override
  String get pleaseCheckConnection => 'يرجى التحقق من اتصالك والمحاولة مرة أخرى.';

  @override
  String get uploadFailed => 'فشل الرفع';

  @override
  String get tryShorterVideo => 'حاول استخدام فيديو أقصر أو حاول لاحقاً.';

  @override
  String get shareMomentsThatDisappear => 'شارك لحظات تختفي خلال 24 ساعة';

  @override
  String get photo => 'صورة';

  @override
  String get record => 'تسجيل';

  @override
  String get addSticker => 'إضافة ملصق';

  @override
  String get poll => 'استطلاع';

  @override
  String get question => 'سؤال';

  @override
  String get mention => 'إشارة';

  @override
  String get music => 'موسيقى';

  @override
  String get hashtag => 'هاشتاج';

  @override
  String get whoCanSeeThis => 'من يمكنه رؤية هذا؟';

  @override
  String get everyone => 'الجميع';

  @override
  String get anyoneCanSeeStory => 'يمكن لأي شخص رؤية هذه القصة';

  @override
  String get friendsOnly => 'الأصدقاء فقط';

  @override
  String get onlyFollowersCanSee => 'فقط متابعوك يمكنهم الرؤية';

  @override
  String get onlyCloseFriendsCanSee => 'فقط الأصدقاء المقربون يمكنهم الرؤية';

  @override
  String get backgroundColor => 'لون الخلفية';

  @override
  String get fontStyle => 'نمط الخط';

  @override
  String get normal => 'عادي';

  @override
  String get bold => 'غامق';

  @override
  String get italic => 'مائل';

  @override
  String get handwriting => 'خط يدوي';

  @override
  String get addLocation => 'إضافة موقع';

  @override
  String get enterLocationName => 'أدخل اسم الموقع';

  @override
  String get addLink => 'إضافة رابط';

  @override
  String get buttonText => 'نص الزر';

  @override
  String get learnMore => 'اعرف المزيد';

  @override
  String get addHashtags => 'إضافة هاشتاجات';

  @override
  String get addHashtag => 'إضافة هاشتاج';

  @override
  String get sendAsMessage => 'إرسال كرسالة';

  @override
  String get shareExternally => 'مشاركة خارجياً';

  @override
  String get checkOutStory => 'شاهد هذه القصة على BananaTalk!';

  @override
  String viewsTab(String count) {
    return 'المشاهدات ($count)';
  }

  @override
  String reactionsTab(String count) {
    return 'التفاعلات ($count)';
  }

  @override
  String get processingVideo => 'جاري معالجة الفيديو...';

  @override
  String get link => 'رابط';

  @override
  String unmuteUser(String name) {
    return 'إلغاء كتم $name؟';
  }

  @override
  String get willReceiveNotifications => 'ستتلقى إشعارات للرسائل الجديدة.';

  @override
  String muteNotificationsFor(String name) {
    return 'كتم إشعارات $name';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return 'تم إلغاء كتم إشعارات $name';
  }

  @override
  String notificationsMutedFor(String name) {
    return 'تم كتم إشعارات $name';
  }

  @override
  String get failedToUpdateMuteSettings => 'فشل تحديث إعدادات الكتم';

  @override
  String get oneHour => 'ساعة واحدة';

  @override
  String get eightHours => '8 ساعات';

  @override
  String get oneWeek => 'أسبوع واحد';

  @override
  String get always => 'دائماً';

  @override
  String get failedToLoadBookmarks => 'فشل تحميل المحفوظات';

  @override
  String get noBookmarkedMessages => 'لا توجد رسائل محفوظة';

  @override
  String get longPressToBookmark => 'اضغط مطولاً على رسالة لحفظها';

  @override
  String get thisWillRemoveFromBookmarks => 'سيؤدي هذا إلى إزالة الرسالة من المحفوظات.';

  @override
  String navigateToMessage(String name) {
    return 'الانتقال إلى الرسالة في محادثة $name';
  }

  @override
  String bookmarkedOn(String date) {
    return 'تم الحفظ $date';
  }

  @override
  String get voiceMessage => 'رسالة صوتية';

  @override
  String get document => 'مستند';

  @override
  String get attachment => 'مرفق';

  @override
  String get sendMeAMessage => 'أرسل لي رسالة';

  @override
  String get shareWithFriends => 'مشاركة مع الأصدقاء';

  @override
  String get shareAnywhere => 'مشاركة في أي مكان';

  @override
  String get emailPreferences => 'تفضيلات البريد';

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
  String get category => 'الفئة';

  @override
  String get mood => 'المزاج';

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
  String get applyFilters => 'تطبيق التصفية';

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
  String get edited => '(معدّل)';

  @override
  String get now => 'الآن';

  @override
  String weeksAgo(int count) {
    return 'منذ $count أسبوع';
  }

  @override
  String viewRepliesCount(int count) {
    return '── عرض $count ردود';
  }

  @override
  String get hideReplies => '── إخفاء الردود';

  @override
  String get saveMoment => 'حفظ اللحظة';

  @override
  String get removeFromSaved => 'إزالة من المحفوظات';

  @override
  String get momentSaved => 'تم الحفظ';

  @override
  String get failedToSave => 'فشل في الحفظ';

  @override
  String checkOutMoment(String title) {
    return 'شاهد هذه اللحظة: $title';
  }

  @override
  String get failedToLoadMoments => 'فشل في تحميل اللحظات';

  @override
  String get noMomentsMatchFilters => 'لا توجد لحظات تطابق الفلاتر';

  @override
  String get beFirstToShareMoment => 'كن أول من يشارك لحظة!';

  @override
  String get tryDifferentSearch => 'جرّب مصطلح بحث مختلف';

  @override
  String get tryAdjustingFilters => 'جرّب تعديل الفلاتر';

  @override
  String get noSavedMoments => 'لا توجد لحظات محفوظة';

  @override
  String get tapBookmarkToSave => 'اضغط على أيقونة الإشارة المرجعية لحفظ لحظة';

  @override
  String get failedToLoadVideo => 'فشل في تحميل الفيديو';

  @override
  String get titleRequired => 'العنوان مطلوب';

  @override
  String titleTooLong(int max) {
    return 'يجب أن يكون العنوان $max حرفاً أو أقل';
  }

  @override
  String get descriptionRequired => 'الوصف مطلوب';

  @override
  String descriptionTooLong(int max) {
    return 'يجب أن يكون الوصف $max حرفاً أو أقل';
  }

  @override
  String get scheduledDateMustBeFuture => 'يجب أن يكون التاريخ المجدول في المستقبل';

  @override
  String get recent => 'الأحدث';

  @override
  String get popular => 'الأكثر شعبية';

  @override
  String get trending => 'رائج';

  @override
  String get mostRecent => 'الأحدث';

  @override
  String get mostPopular => 'الأكثر شعبية';

  @override
  String get allTime => 'كل الأوقات';

  @override
  String get today => 'اليوم';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String replyingTo(String userName) {
    return 'الرد على $userName';
  }

  @override
  String get listView => 'قائمة';

  @override
  String get quickMatch => 'مطابقة سريعة';

  @override
  String get onlineNow => 'متصل الآن';

  @override
  String speaksLanguage(String language) {
    return 'يتحدث $language';
  }

  @override
  String learningLanguage(String language) {
    return 'يتعلم $language';
  }

  @override
  String get noPartnersFound => 'لم يتم العثور على شركاء';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return 'لم يتم العثور على مستخدمين يتحدثون $learning أو يتعلمون $native.';
  }

  @override
  String get removeAllFilters => 'إزالة جميع الفلاتر';

  @override
  String get browseAllUsers => 'تصفح جميع المستخدمين';

  @override
  String get allCaughtUp => 'لقد اطلعت على الكل!';

  @override
  String get loadingMore => 'جاري التحميل...';

  @override
  String get findingMorePartners => 'جاري البحث عن المزيد من شركاء اللغة...';

  @override
  String get seenAllPartners => 'لقد شاهدت جميع الشركاء المتاحين. عد لاحقاً!';

  @override
  String get startOver => 'ابدأ من جديد';

  @override
  String get changeFilters => 'تغيير الفلاتر';

  @override
  String get findingPartners => 'جاري البحث عن شركاء...';

  @override
  String get setLocationReminder => 'حدد موقعك في ملفك الشخصي لرؤية المستخدمين القريبين أولاً.';

  @override
  String get updateLocationReminder => 'حدّث موقعك في الملف الشخصي > تعديل للحصول على نتائج دقيقة.';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get other => 'آخر';

  @override
  String get browseMen => 'تصفح الرجال';

  @override
  String get browseWomen => 'تصفح النساء';

  @override
  String get noMaleUsersFound => 'لم يتم العثور على مستخدمين ذكور';

  @override
  String get noFemaleUsersFound => 'لم يتم العثور على مستخدمات';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => 'المستخدمون الجدد فقط';

  @override
  String get showNewUsers => 'عرض المستخدمين الذين انضموا في آخر 6 أيام';

  @override
  String get prioritizeNearby => 'الأولوية للقريبين';

  @override
  String get showNearbyFirst => 'عرض المستخدمين القريبين أولاً';

  @override
  String get setLocationToEnable => 'حدد موقعك لتفعيل هذه الميزة';

  @override
  String get radius => 'النطاق';

  @override
  String get findingYourLocation => 'جاري تحديد موقعك...';

  @override
  String get enableLocationForDistance => 'فعّل الموقع لمعرفة المسافة';

  @override
  String get enableLocationDescription => 'فعّل GPS لرؤية المسافة الدقيقة للشركاء.';

  @override
  String get enableGps => 'تفعيل GPS';

  @override
  String get browseByCityCountry => 'التصفح حسب المدينة/الدولة';

  @override
  String get peopleNearby => 'أشخاص بالقرب';

  @override
  String get noNearbyUsersFound => 'لم يتم العثور على مستخدمين قريبين';

  @override
  String get tryExpandingSearch => 'حاول توسيع نطاق البحث أو عد لاحقاً.';

  @override
  String get exploreByCity => 'استكشف حسب المدينة';

  @override
  String get exploreByCurrentCity => 'تصفح المستخدمين على خريطة تفاعلية واكتشف شركاء لغة حول العالم.';

  @override
  String get interactiveWorldMap => 'خريطة عالمية تفاعلية';

  @override
  String get searchByCityName => 'البحث باسم المدينة';

  @override
  String get seeUserCountsPerCountry => 'عرض عدد المستخدمين حسب الدولة';

  @override
  String get upgradeToVip => 'ترقية إلى VIP';

  @override
  String get searchByCity => 'البحث بالمدينة...';

  @override
  String usersWorldwide(String count) {
    return '$count مستخدم حول العالم';
  }

  @override
  String get noUsersFound => 'لم يتم العثور على مستخدمين';

  @override
  String get tryDifferentCity => 'جرب مدينة أو دولة أخرى';

  @override
  String usersCount(String count) {
    return '$count مستخدم';
  }

  @override
  String get searchCountry => 'البحث عن دولة...';

  @override
  String get wave => 'تحية';

  @override
  String get newUser => 'جديد';

  @override
  String get warningPermanent => 'تحذير: هذا الإجراء نهائي!';

  @override
  String get deleteAccountWarning => 'حذف حسابك سيزيل نهائياً:\n\n• ملفك الشخصي وجميع بياناتك\n• جميع رسائلك ومحادثاتك\n• جميع لحظاتك وقصصك\n• اشتراك VIP (بدون استرداد)\n• جميع متابعيك ومتابعاتك\n\nلا يمكن التراجع عن هذا الإجراء.';

  @override
  String get requiredForEmailOnly => 'مطلوب لحسابات البريد الإلكتروني فقط';

  @override
  String get pleaseEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get typeDELETE => 'اكتب DELETE للتأكيد';

  @override
  String get mustTypeDELETE => 'يجب كتابة DELETE للتأكيد';

  @override
  String get deletingAccount => 'جاري حذف الحساب...';

  @override
  String get deleteMyAccountPermanently => 'حذف حسابي نهائياً';

  @override
  String get whatsYourNativeLanguage => 'ما هي لغتك الأم؟';

  @override
  String get helpsMatchWithLearners => 'يساعدنا في مطابقتك مع المتعلمين';

  @override
  String get whatAreYouLearning => 'ماذا تتعلم؟';

  @override
  String get connectWithNativeSpeakers => 'سنربطك بمتحدثين أصليين';

  @override
  String get selectLearningLanguage => 'يرجى اختيار اللغة التي تتعلمها';

  @override
  String get selectCurrentLevel => 'يرجى اختيار مستواك الحالي';

  @override
  String get beginner => 'مبتدئ — أعرف بعض الكلمات';

  @override
  String get elementary => 'أساسي — أستطيع تكوين جمل بسيطة';

  @override
  String get intermediate => 'متوسط — أستطيع إجراء محادثات بسيطة';

  @override
  String get upperIntermediate => 'فوق المتوسط — أستطيع مناقشة معظم المواضيع';

  @override
  String get advanced => 'متقدم — أتحدث بطلاقة';

  @override
  String get proficient => 'متمكن — مستوى شبه أصلي';

  @override
  String get showingPartnersByDistance => 'عرض الشركاء حسب المسافة';

  @override
  String get enableLocationForResults => 'فعّل الموقع للحصول على نتائج حسب المسافة';

  @override
  String get enable => 'تفعيل';

  @override
  String get locationNotSet => 'لم يتم تحديد الموقع';

  @override
  String get tellUsAboutYourself => 'أخبرنا عن نفسك';

  @override
  String get justACoupleQuickThings => 'فقط بعض الأسئلة السريعة';

  @override
  String get gender => 'الجنس';

  @override
  String get birthDate => 'تاريخ الميلاد';

  @override
  String get selectYourBirthDate => 'اختر تاريخ ميلادك';

  @override
  String get continueButton => 'متابعة';

  @override
  String get pleaseSelectGender => 'يرجى اختيار جنسك';

  @override
  String get pleaseSelectBirthDate => 'يرجى اختيار تاريخ ميلادك';

  @override
  String get mustBe18 => 'يجب أن يكون عمرك 18 سنة على الأقل';

  @override
  String get invalidDate => 'تاريخ غير صالح';

  @override
  String get almostDone => 'أوشكت على الانتهاء!';

  @override
  String get addPhotoLocationForMatches => 'أضف صورة وموقعاً للحصول على مزيد من التطابقات';

  @override
  String get addProfilePhoto => 'إضافة صورة شخصية';

  @override
  String get optionalUpTo6Photos => 'اختياري — حتى 6 صور';

  @override
  String get maximum6Photos => 'الحد الأقصى 6 صور';

  @override
  String get tapToDetectLocation => 'انقر لاكتشاف الموقع';

  @override
  String get optionalHelpsNearbyPartners => 'اختياري — يساعد في العثور على شركاء قريبين';

  @override
  String get startLearning => 'ابدأ التعلم!';

  @override
  String get photoLocationOptional => 'الصورة والموقع اختياريان — يمكنك إضافتهما لاحقاً';

  @override
  String get pleaseAcceptTerms => 'يرجى الموافقة على شروط الخدمة';

  @override
  String get iAgreeToThe => 'أوافق على ';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get tapToSelectLanguage => 'انقر لاختيار لغة';

  @override
  String yourLevelIn(String language) {
    return 'مستواك في $language (اختياري)';
  }

  @override
  String get yourCurrentLevel => 'مستواك الحالي';

  @override
  String get nativeCannotBeSameAsLearning => 'لا يمكن أن تكون اللغة الأم نفس لغة التعلم';

  @override
  String get learningCannotBeSameAsNative => 'لا يمكن أن تكون لغة التعلم نفس اللغة الأم';

  @override
  String stepOf(String current, String total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get continueWithGoogle => 'المتابعة مع Google';

  @override
  String get registerLink => 'تسجيل';

  @override
  String get pleaseEnterBothEmailAndPassword => 'يرجى إدخال البريد الإلكتروني وكلمة المرور';

  @override
  String get pleaseEnterValidEmail => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get loginSuccessful => 'تم تسجيل الدخول بنجاح!';

  @override
  String get stepOneOfTwo => 'الخطوة 1 من 2';

  @override
  String get createYourAccount => 'إنشاء حسابك';

  @override
  String get basicInfoToGetStarted => 'معلومات أساسية للبدء';

  @override
  String get emailVerifiedLabel => 'البريد الإلكتروني (تم التحقق)';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get yourDisplayName => 'اسم العرض';

  @override
  String get atLeast8Characters => '8 أحرف على الأقل';

  @override
  String get confirmPasswordHint => 'تأكيد كلمة المرور';

  @override
  String get nextButton => 'التالي';

  @override
  String get pleaseEnterYourName => 'يرجى إدخال اسمك';

  @override
  String get pleaseEnterAPassword => 'يرجى إدخال كلمة مرور';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get otherGender => 'أخرى';

  @override
  String get continueWithGoogleAccount => 'تابع بحساب Google\nللحصول على تجربة سلسة';

  @override
  String get signingYouIn => 'جاري تسجيل الدخول...';

  @override
  String get backToSignInMethods => 'العودة لطرق تسجيل الدخول';

  @override
  String get securedByGoogle => 'محمي بواسطة Google';

  @override
  String get dataProtectedEncryption => 'بياناتك محمية بتشفير معياري';

  @override
  String get welcomeCompleteProfile => 'مرحباً! يرجى إكمال ملفك الشخصي';

  @override
  String welcomeBackName(String name) {
    return 'مرحباً بعودتك، $name!';
  }

  @override
  String get continueWithAppleId => 'تابع بحساب Apple ID\nللحصول على تجربة آمنة';

  @override
  String get continueWithApple => 'المتابعة مع Apple';

  @override
  String get securedByApple => 'محمي بواسطة Apple';

  @override
  String get privacyProtectedApple => 'خصوصيتك محمية مع Apple Sign-In';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get enterEmailToGetStarted => 'أدخل بريدك الإلكتروني للبدء';

  @override
  String get continueText => 'متابعة';

  @override
  String get pleaseEnterEmailAddress => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get verificationCodeSent => 'تم إرسال رمز التحقق إلى بريدك!';

  @override
  String get forgotPasswordTitle => 'نسيت كلمة المرور';

  @override
  String get resetPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get enterEmailForResetCode => 'أدخل بريدك الإلكتروني وسنرسل لك رمز إعادة تعيين كلمة المرور';

  @override
  String get sendResetCode => 'إرسال رمز إعادة التعيين';

  @override
  String get resetCodeSent => 'تم إرسال رمز إعادة التعيين!';

  @override
  String get rememberYourPassword => 'تتذكر كلمة المرور؟';

  @override
  String get verifyCode => 'التحقق من الرمز';

  @override
  String get enterResetCode => 'أدخل رمز إعادة التعيين';

  @override
  String get weSentCodeTo => 'أرسلنا رمزاً مكوناً من 6 أرقام إلى';

  @override
  String get pleaseEnterAll6Digits => 'يرجى إدخال الأرقام الستة';

  @override
  String get codeVerifiedCreatePassword => 'تم التحقق! أنشئ كلمة مرور جديدة';

  @override
  String get verify => 'تحقق';

  @override
  String get didntReceiveCode => 'لم تستلم الرمز؟';

  @override
  String get resend => 'إعادة إرسال';

  @override
  String resendWithTimer(String timer) {
    return 'إعادة إرسال ($timerث)';
  }

  @override
  String get resetCodeResent => 'تم إعادة إرسال رمز إعادة التعيين!';

  @override
  String get verifyEmail => 'التحقق من البريد';

  @override
  String get verifyYourEmail => 'تحقق من بريدك الإلكتروني';

  @override
  String get emailVerifiedSuccessfully => 'تم التحقق من البريد بنجاح!';

  @override
  String get verificationCodeResent => 'تم إعادة إرسال رمز التحقق!';

  @override
  String get createNewPassword => 'إنشاء كلمة مرور جديدة';

  @override
  String get enterNewPasswordBelow => 'أدخل كلمة المرور الجديدة أدناه';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get pleaseFillAllFields => 'يرجى ملء جميع الحقول';

  @override
  String get passwordResetSuccessful => 'تم إعادة تعيين كلمة المرور بنجاح! سجل الدخول بكلمة المرور الجديدة';

  @override
  String get privacyTitle => 'الخصوصية';

  @override
  String get profileVisibility => 'ظهور الملف الشخصي';

  @override
  String get showCountryRegion => 'إظهار الدولة/المنطقة';

  @override
  String get showCountryRegionDesc => 'عرض دولتك في ملفك الشخصي';

  @override
  String get showCity => 'إظهار المدينة';

  @override
  String get showCityDesc => 'عرض مدينتك في ملفك الشخصي';

  @override
  String get showAge => 'إظهار العمر';

  @override
  String get showAgeDesc => 'عرض عمرك في ملفك الشخصي';

  @override
  String get showZodiacSign => 'إظهار البرج';

  @override
  String get showZodiacSignDesc => 'عرض برجك في ملفك الشخصي';

  @override
  String get onlineStatusSection => 'حالة الاتصال';

  @override
  String get showOnlineStatus => 'إظهار حالة الاتصال';

  @override
  String get showOnlineStatusDesc => 'السماح للآخرين برؤية حالة اتصالك';

  @override
  String get otherSettings => 'إعدادات أخرى';

  @override
  String get showGiftingLevel => 'إظهار مستوى الهدايا';

  @override
  String get showGiftingLevelDesc => 'عرض شارة مستوى الهدايا';

  @override
  String get birthdayNotifications => 'إشعارات عيد الميلاد';

  @override
  String get birthdayNotificationsDesc => 'تلقي إشعارات في عيد ميلادك';

  @override
  String get personalizedAds => 'إعلانات مخصصة';

  @override
  String get personalizedAdsDesc => 'السماح بالإعلانات المخصصة';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get privacySettingsSaved => 'تم حفظ إعدادات الخصوصية';

  @override
  String get locationSection => 'الموقع';

  @override
  String get updateLocation => 'تحديث الموقع';

  @override
  String get updateLocationDesc => 'تحديث موقعك الحالي';

  @override
  String get currentLocation => 'الموقع الحالي';

  @override
  String get locationNotAvailable => 'الموقع غير متاح';

  @override
  String get locationUpdated => 'تم تحديث الموقع بنجاح';

  @override
  String get locationPermissionDenied => 'تم رفض إذن الموقع. يرجى تفعيله في الإعدادات.';

  @override
  String get locationServiceDisabled => 'خدمات الموقع معطلة. يرجى تفعيلها.';

  @override
  String get updatingLocation => 'جارٍ تحديث الموقع...';

  @override
  String get locationCouldNotBeUpdated => 'تعذر تحديث الموقع';

  @override
  String get incomingAudioCall => 'مكالمة صوتية واردة';

  @override
  String get incomingVideoCall => 'مكالمة فيديو واردة';

  @override
  String get outgoingCall => 'جاري الاتصال...';

  @override
  String get callRinging => 'يرن...';

  @override
  String get callConnecting => 'جاري الاتصال...';

  @override
  String get callConnected => 'متصل';

  @override
  String get callReconnecting => 'جاري إعادة الاتصال...';

  @override
  String get callEnded => 'انتهت المكالمة';

  @override
  String get callFailed => 'فشلت المكالمة';

  @override
  String get callMissed => 'مكالمة فائتة';

  @override
  String get callDeclined => 'مكالمة مرفوضة';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => 'قبول';

  @override
  String get declineCall => 'رفض';

  @override
  String get endCall => 'إنهاء';

  @override
  String get muteCall => 'كتم';

  @override
  String get unmuteCall => 'إلغاء الكتم';

  @override
  String get speakerOn => 'مكبر الصوت';

  @override
  String get speakerOff => 'سماعة الأذن';

  @override
  String get videoOn => 'الفيديو مفعل';

  @override
  String get videoOff => 'الفيديو معطل';

  @override
  String get switchCamera => 'تبديل الكاميرا';

  @override
  String get callPermissionDenied => 'إذن الميكروفون مطلوب للمكالمات';

  @override
  String get cameraPermissionDenied => 'إذن الكاميرا مطلوب لمكالمات الفيديو';

  @override
  String get callConnectionFailed => 'تعذر الاتصال. يرجى المحاولة مرة أخرى.';

  @override
  String get userBusy => 'المستخدم مشغول';

  @override
  String get userOffline => 'المستخدم غير متصل';

  @override
  String get callHistory => 'سجل المكالمات';

  @override
  String get noCallHistory => 'لا يوجد سجل مكالمات';

  @override
  String get missedCalls => 'المكالمات الفائتة';

  @override
  String get allCalls => 'جميع المكالمات';

  @override
  String get callBack => 'معاودة الاتصال';

  @override
  String callAt(String time) {
    return 'مكالمة في $time';
  }

  @override
  String get audioCall => 'مكالمة صوتية';

  @override
  String get voiceRoom => 'غرفة صوتية';

  @override
  String get noVoiceRooms => 'لا توجد غرف صوتية نشطة';

  @override
  String get createVoiceRoom => 'إنشاء غرفة صوتية';

  @override
  String get joinRoom => 'انضمام للغرفة';

  @override
  String get leaveRoomConfirm => 'مغادرة الغرفة؟';

  @override
  String get leaveRoomMessage => 'هل أنت متأكد أنك تريد مغادرة هذه الغرفة؟';

  @override
  String get roomTitle => 'عنوان الغرفة';

  @override
  String get roomTitleHint => 'أدخل عنوان الغرفة';

  @override
  String get roomTopic => 'الموضوع';

  @override
  String get roomLanguage => 'اللغة';

  @override
  String get roomHost => 'المضيف';

  @override
  String roomParticipants(int count) {
    return '$count مشاركين';
  }

  @override
  String roomMaxParticipants(int count) {
    return 'الحد الأقصى $count مشاركين';
  }

  @override
  String get selectTopic => 'اختر الموضوع';

  @override
  String get raiseHand => 'رفع اليد';

  @override
  String get lowerHand => 'خفض اليد';

  @override
  String get handRaisedNotification => 'تم رفع اليد! سيرى المضيف طلبك.';

  @override
  String get handLoweredNotification => 'تم خفض اليد';

  @override
  String get muteParticipant => 'كتم المشارك';

  @override
  String get kickParticipant => 'إزالة من الغرفة';

  @override
  String get promoteToCoHost => 'ترقية إلى مضيف مشارك';

  @override
  String get endRoomConfirm => 'إنهاء الغرفة؟';

  @override
  String get endRoomMessage => 'سيتم إنهاء الغرفة لجميع المشاركين.';

  @override
  String get roomEnded => 'تم إنهاء الغرفة من قبل المضيف';

  @override
  String get youWereRemoved => 'تمت إزالتك من الغرفة';

  @override
  String get roomIsFull => 'الغرفة ممتلئة';

  @override
  String get roomChat => 'دردشة الغرفة';

  @override
  String get noMessages => 'لا توجد رسائل بعد';

  @override
  String get typeMessage => 'اكتب رسالة...';

  @override
  String get voiceRoomsDescription => 'انضم إلى المحادثات المباشرة وتدرب على التحدث';

  @override
  String liveRoomsCount(int count) {
    return '$count مباشر';
  }

  @override
  String get noActiveRooms => 'لا توجد غرف نشطة';

  @override
  String get noActiveRoomsDescription => 'كن أول من يبدأ غرفة صوتية وتدرب على التحدث مع الآخرين!';

  @override
  String get startRoom => 'بدء غرفة';

  @override
  String get createRoom => 'إنشاء غرفة';

  @override
  String get roomCreated => 'تم إنشاء الغرفة بنجاح!';

  @override
  String get failedToCreateRoom => 'فشل إنشاء الغرفة';

  @override
  String get errorLoadingRooms => 'خطأ في تحميل الغرف';

  @override
  String get pleaseEnterRoomTitle => 'يرجى إدخال عنوان الغرفة';

  @override
  String get startLiveConversation => 'بدء محادثة مباشرة';

  @override
  String get maxParticipants => 'الحد الأقصى للمشاركين';

  @override
  String nPeople(int count) {
    return '$count أشخاص';
  }

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
}
