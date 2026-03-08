// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appName => 'BananaTalk';

  @override
  String get login => 'เข้าสู่ระบบ';

  @override
  String get signUp => 'สมัครสมาชิก';

  @override
  String get email => 'อีเมล';

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get forgotPassword => 'ลืมรหัสผ่าน?';

  @override
  String get or => 'หรือ';

  @override
  String get signInWithGoogle => 'เข้าสู่ระบบด้วย Google';

  @override
  String get signInWithApple => 'เข้าสู่ระบบด้วย Apple';

  @override
  String get signInWithFacebook => 'เข้าสู่ระบบด้วย Facebook';

  @override
  String get welcome => 'ยินดีต้อนรับ';

  @override
  String get home => 'หน้าหลัก';

  @override
  String get messages => 'ข้อความ';

  @override
  String get moments => 'โมเมนต์';

  @override
  String get profile => 'โปรไฟล์';

  @override
  String get settings => 'ตั้งค่า';

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get language => 'ภาษา';

  @override
  String get selectLanguage => 'เลือกภาษา';

  @override
  String get autoTranslate => 'แปลอัตโนมัติ';

  @override
  String get autoTranslateMessages => 'แปลข้อความอัตโนมัติ';

  @override
  String get autoTranslateMoments => 'แปลโมเมนต์อัตโนมัติ';

  @override
  String get autoTranslateComments => 'แปลความคิดเห็นอัตโนมัติ';

  @override
  String get translate => 'แปล';

  @override
  String get translated => 'แปลแล้ว';

  @override
  String get showOriginal => 'แสดงต้นฉบับ';

  @override
  String get showTranslation => 'แสดงคำแปล';

  @override
  String get translating => 'กำลังแปล...';

  @override
  String get translationFailed => 'การแปลล้มเหลว';

  @override
  String get noTranslationAvailable => 'ไม่มีคำแปล';

  @override
  String translatedFrom(String language) {
    return 'แปลจาก $language';
  }

  @override
  String get save => 'บันทึก';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get delete => 'ลบ';

  @override
  String get edit => 'แก้ไข';

  @override
  String get share => 'แชร์';

  @override
  String get like => 'ถูกใจ';

  @override
  String get comment => 'ความคิดเห็น';

  @override
  String get send => 'ส่ง';

  @override
  String get search => 'ค้นหา';

  @override
  String get notifications => 'การแจ้งเตือน';

  @override
  String get followers => 'ผู้ติดตาม';

  @override
  String get following => 'กำลังติดตาม';

  @override
  String get posts => 'โพสต์';

  @override
  String get visitors => 'ผู้เยี่ยมชม';

  @override
  String get loading => 'กำลังโหลด...';

  @override
  String get error => 'ข้อผิดพลาด';

  @override
  String get success => 'สำเร็จ';

  @override
  String get tryAgain => 'ลองอีกครั้ง';

  @override
  String get networkError => 'ข้อผิดพลาดของเครือข่าย กรุณาตรวจสอบการเชื่อมต่อ';

  @override
  String get somethingWentWrong => 'เกิดข้อผิดพลาด';

  @override
  String get ok => 'ตกลง';

  @override
  String get yes => 'ใช่';

  @override
  String get no => 'ไม่';

  @override
  String get languageSettings => 'ตั้งค่าภาษา';

  @override
  String get deviceLanguage => 'ภาษาของอุปกรณ์';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return 'อุปกรณ์ของคุณตั้งค่าเป็น: $flag $name';
  }

  @override
  String get youCanOverride => 'คุณสามารถเปลี่ยนภาษาของอุปกรณ์ได้ด้านล่าง';

  @override
  String languageChangedTo(String name) {
    return 'เปลี่ยนภาษาเป็น $name';
  }

  @override
  String get errorChangingLanguage => 'ข้อผิดพลาดในการเปลี่ยนภาษา';

  @override
  String get autoTranslateSettings => 'ตั้งค่าการแปลอัตโนมัติ';

  @override
  String get automaticallyTranslateIncomingMessages => 'แปลข้อความขาเข้าโดยอัตโนมัติ';

  @override
  String get automaticallyTranslateMomentsInFeed => 'แปลโมเมนต์ในฟีดโดยอัตโนมัติ';

  @override
  String get automaticallyTranslateComments => 'แปลความคิดเห็นโดยอัตโนมัติ';

  @override
  String get translationServiceBeingConfigured => 'บริการแปลกำลังถูกกำหนดค่า กรุณาลองใหม่ภายหลัง';

  @override
  String get translationUnavailable => 'การแปลไม่พร้อมใช้งาน';

  @override
  String get showLess => 'แสดงน้อยลง';

  @override
  String get showMore => 'แสดงเพิ่มเติม';

  @override
  String get comments => 'ความคิดเห็น';

  @override
  String get beTheFirstToComment => 'เป็นคนแรกที่แสดงความคิดเห็น';

  @override
  String get writeAComment => 'เขียนความคิดเห็น...';

  @override
  String get report => 'รายงาน';

  @override
  String get reportMoment => 'รายงานโมเมนต์';

  @override
  String get reportUser => 'รายงานผู้ใช้';

  @override
  String get deleteMoment => 'ลบโมเมนต์?';

  @override
  String get thisActionCannotBeUndone => 'การกระทำนี้ไม่สามารถยกเลิกได้';

  @override
  String get momentDeleted => 'ลบโมเมนต์แล้ว';

  @override
  String get editFeatureComingSoon => 'ฟีเจอร์แก้ไขเร็วๆ นี้';

  @override
  String get userNotFound => 'ไม่พบผู้ใช้';

  @override
  String get cannotReportYourOwnComment => 'ไม่สามารถรายงานความคิดเห็นของตัวเอง';

  @override
  String get profileSettings => 'ตั้งค่าโปรไฟล์';

  @override
  String get editYourProfileInformation => 'แก้ไขข้อมูลโปรไฟล์ของคุณ';

  @override
  String get blockedUsers => 'ผู้ใช้ที่ถูกบล็อก';

  @override
  String get manageBlockedUsers => 'จัดการผู้ใช้ที่ถูกบล็อก';

  @override
  String get manageNotificationSettings => 'จัดการการตั้งค่าการแจ้งเตือน';

  @override
  String get privacySecurity => 'ความเป็นส่วนตัวและความปลอดภัย';

  @override
  String get controlYourPrivacy => 'ควบคุมความเป็นส่วนตัวของคุณ';

  @override
  String get changeAppLanguage => 'เปลี่ยนภาษาแอป';

  @override
  String get appearance => 'รูปลักษณ์';

  @override
  String get themeAndDisplaySettings => 'ตั้งค่าธีมและการแสดงผล';

  @override
  String get myReports => 'รายงานของฉัน';

  @override
  String get viewYourSubmittedReports => 'ดูรายงานที่คุณส่ง';

  @override
  String get reportsManagement => 'การจัดการรายงาน';

  @override
  String get manageAllReportsAdmin => 'จัดการรายงานทั้งหมด (ผู้ดูแล)';

  @override
  String get legalPrivacy => 'กฎหมายและความเป็นส่วนตัว';

  @override
  String get termsPrivacySubscriptionInfo => 'ข้อกำหนด ความเป็นส่วนตัว และข้อมูลการสมัคร';

  @override
  String get helpCenter => 'ศูนย์ช่วยเหลือ';

  @override
  String get getHelpAndSupport => 'รับความช่วยเหลือและการสนับสนุน';

  @override
  String get aboutBanaTalk => 'เกี่ยวกับ BanaTalk';

  @override
  String get deleteAccount => 'ลบบัญชี';

  @override
  String get permanentlyDeleteYourAccount => 'ลบบัญชีของคุณอย่างถาวร';

  @override
  String get loggedOutSuccessfully => 'ออกจากระบบสำเร็จ';

  @override
  String get retry => 'ลองใหม่';

  @override
  String get giftsLikes => 'ของขวัญ/ถูกใจ';

  @override
  String get details => 'รายละเอียด';

  @override
  String get to => 'ถึง';

  @override
  String get banaTalk => 'BanaTalk';

  @override
  String get community => 'ชุมชน';

  @override
  String get editProfile => 'แก้ไขโปรไฟล์';

  @override
  String yearsOld(String age) {
    return '$age ปี';
  }

  @override
  String get searchConversations => 'ค้นหาการสนทนา...';

  @override
  String get visitorTrackingNotAvailable => 'ฟีเจอร์ติดตามผู้เยี่ยมชมยังไม่พร้อมใช้งาน';

  @override
  String get chatList => 'รายการแชท';

  @override
  String get languageExchange => 'แลกเปลี่ยนภาษา';

  @override
  String get nativeLanguage => 'ภาษาแม่';

  @override
  String get learning => 'กำลังเรียน';

  @override
  String get notSet => 'ยังไม่ตั้งค่า';

  @override
  String get about => 'เกี่ยวกับ';

  @override
  String get aboutMe => 'เกี่ยวกับฉัน';

  @override
  String get bloodType => 'กรุ๊ปเลือด';

  @override
  String get photos => 'รูปภาพ';

  @override
  String get camera => 'กล้อง';

  @override
  String get createMoment => 'สร้างโมเมนต์';

  @override
  String get addATitle => 'เพิ่มหัวข้อ...';

  @override
  String get whatsOnYourMind => 'คุณกำลังคิดอะไรอยู่?';

  @override
  String get addTags => 'เพิ่มแท็ก';

  @override
  String get done => 'เสร็จ';

  @override
  String get add => 'เพิ่ม';

  @override
  String get enterTag => 'ป้อนแท็ก';

  @override
  String get post => 'โพสต์';

  @override
  String get commentAddedSuccessfully => 'เพิ่มความคิดเห็นสำเร็จ';

  @override
  String get clearFilters => 'ล้างตัวกรอง';

  @override
  String get notificationSettings => 'ตั้งค่าการแจ้งเตือน';

  @override
  String get enableNotifications => 'เปิดใช้งานการแจ้งเตือน';

  @override
  String get turnAllNotificationsOnOrOff => 'เปิดหรือปิดการแจ้งเตือนทั้งหมด';

  @override
  String get notificationTypes => 'ประเภทการแจ้งเตือน';

  @override
  String get chatMessages => 'ข้อความแชท';

  @override
  String get getNotifiedWhenYouReceiveMessages => 'รับการแจ้งเตือนเมื่อได้รับข้อความ';

  @override
  String get likesAndCommentsOnYourMoments => 'ถูกใจและความคิดเห็นบนโมเมนต์ของคุณ';

  @override
  String get whenPeopleYouFollowPostMoments => 'เมื่อคนที่คุณติดตามโพสต์โมเมนต์';

  @override
  String get friendRequests => 'คำขอเป็นเพื่อน';

  @override
  String get whenSomeoneFollowsYou => 'เมื่อมีคนติดตามคุณ';

  @override
  String get profileVisits => 'การเยี่ยมชมโปรไฟล์';

  @override
  String get whenSomeoneViewsYourProfileVIP => 'เมื่อมีคนดูโปรไฟล์ของคุณ (VIP)';

  @override
  String get marketing => 'การตลาด';

  @override
  String get updatesAndPromotionalMessages => 'อัปเดตและข้อความโปรโมชัน';

  @override
  String get notificationPreferences => 'ตั้งค่าการแจ้งเตือน';

  @override
  String get sound => 'เสียง';

  @override
  String get playNotificationSounds => 'เล่นเสียงการแจ้งเตือน';

  @override
  String get vibration => 'การสั่น';

  @override
  String get vibrateOnNotifications => 'สั่นเมื่อมีการแจ้งเตือน';

  @override
  String get showPreview => 'แสดงตัวอย่าง';

  @override
  String get showMessagePreviewInNotifications => 'แสดงตัวอย่างข้อความในการแจ้งเตือน';

  @override
  String get mutedConversations => 'การสนทนาที่ปิดเสียง';

  @override
  String get conversation => 'การสนทนา';

  @override
  String get unmute => 'เปิดเสียง';

  @override
  String get systemNotificationSettings => 'ตั้งค่าการแจ้งเตือนระบบ';

  @override
  String get manageNotificationsInSystemSettings => 'จัดการการแจ้งเตือนในตั้งค่าระบบ';

  @override
  String get errorLoadingSettings => 'ข้อผิดพลาดในการโหลดการตั้งค่า';

  @override
  String get unblockUser => 'ปลดบล็อกผู้ใช้';

  @override
  String get unblock => 'ปลดบล็อก';

  @override
  String get goBack => 'ย้อนกลับ';

  @override
  String get messageSendTimeout => 'หมดเวลาส่งข้อความ กรุณาตรวจสอบการเชื่อมต่อ';

  @override
  String get failedToSendMessage => 'ส่งข้อความล้มเหลว';

  @override
  String get dailyMessageLimitExceeded => 'เกินขีดจำกัดข้อความรายวัน อัปเกรดเป็น VIP เพื่อส่งข้อความไม่จำกัด';

  @override
  String get cannotSendMessageUserMayBeBlocked => 'ไม่สามารถส่งข้อความ ผู้ใช้อาจถูกบล็อก';

  @override
  String get sessionExpired => 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบอีกครั้ง';

  @override
  String get sendThisSticker => 'ส่งสติกเกอร์นี้?';

  @override
  String get chooseHowYouWantToDeleteThisMessage => 'เลือกวิธีลบข้อความนี้:';

  @override
  String get deleteForEveryone => 'ลบสำหรับทุกคน';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => 'ลบข้อความสำหรับคุณและผู้รับ';

  @override
  String get deleteForMe => 'ลบสำหรับฉัน';

  @override
  String get removesTheMessageOnlyFromYourChat => 'ลบข้อความจากแชทของคุณเท่านั้น';

  @override
  String get copy => 'คัดลอก';

  @override
  String get reply => 'ตอบกลับ';

  @override
  String get forward => 'ส่งต่อ';

  @override
  String get moreOptions => 'ตัวเลือกเพิ่มเติม';

  @override
  String get noUsersAvailableToForwardTo => 'ไม่มีผู้ใช้ให้ส่งต่อ';

  @override
  String get searchMoments => 'ค้นหาโมเมนต์...';

  @override
  String searchInChatWith(String name) {
    return 'ค้นหาในแชทกับ $name';
  }

  @override
  String get typeAMessage => 'พิมพ์ข้อความ...';

  @override
  String get enterYourMessage => 'ป้อนข้อความของคุณ';

  @override
  String get detectYourLocation => 'ตรวจหาตำแหน่งของคุณ';

  @override
  String get tapToUpdateLocation => 'แตะเพื่ออัปเดตตำแหน่ง';

  @override
  String get helpOthersFindYouNearby => 'ช่วยให้คนอื่นค้นหาคุณในบริเวณใกล้เคียง';

  @override
  String get selectYourNativeLanguage => 'เลือกภาษาแม่ของคุณ';

  @override
  String get whichLanguageDoYouWantToLearn => 'คุณต้องการเรียนภาษาอะไร?';

  @override
  String get selectYourGender => 'เลือกเพศของคุณ';

  @override
  String get addACaption => 'เพิ่มคำบรรยาย...';

  @override
  String get typeSomething => 'พิมพ์อะไรสักอย่าง...';

  @override
  String get gallery => 'แกลเลอรี';

  @override
  String get video => 'วิดีโอ';

  @override
  String get text => 'ข้อความ';

  @override
  String get provideMoreInformation => 'ให้ข้อมูลเพิ่มเติม...';

  @override
  String get searchByNameLanguageOrInterests => 'ค้นหาตามชื่อ ภาษา หรือความสนใจ...';

  @override
  String get addTagAndPressEnter => 'เพิ่มแท็กและกด enter';

  @override
  String replyTo(String name) {
    return 'ตอบกลับ $name...';
  }

  @override
  String get highlightName => 'ชื่อไฮไลท์';

  @override
  String get searchCloseFriends => 'ค้นหาเพื่อนสนิท...';

  @override
  String get askAQuestion => 'ถามคำถาม...';

  @override
  String option(String number) {
    return 'ตัวเลือก $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return 'ทำไมคุณถึงรายงาน$typeนี้?';
  }

  @override
  String get additionalDetailsOptional => 'รายละเอียดเพิ่มเติม (ไม่บังคับ)';

  @override
  String get warningThisActionIsPermanent => 'คำเตือน: การกระทำนี้ถาวร!';

  @override
  String get deletingYourAccountWillPermanentlyRemove => 'Deleting your account will permanently remove:\n\n• Your profile and all personal data\n• All your messages and conversations\n• All your moments and stories\n• Your VIP subscription (no refund)\n• All your connections and followers\n\nThis action cannot be undone.';

  @override
  String get clearAllNotifications => 'ล้างการแจ้งเตือนทั้งหมด?';

  @override
  String get clearAll => 'ล้างทั้งหมด';

  @override
  String get notificationDebug => 'Notification Debug';

  @override
  String get markAllRead => 'ทำเครื่องหมายอ่านทั้งหมด';

  @override
  String get clearAll2 => 'Clear all';

  @override
  String get emailAddress => 'ที่อยู่อีเมล';

  @override
  String get username => 'ชื่อผู้ใช้';

  @override
  String get alreadyHaveAnAccount => 'มีบัญชีแล้ว?';

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
  String get couldNotOpenLink => 'ไม่สามารถเปิดลิงก์';

  @override
  String get legalPrivacy2 => 'Legal & Privacy';

  @override
  String get termsOfUseEULA => 'ข้อกำหนดการใช้งาน (EULA)';

  @override
  String get viewOurTermsAndConditions => 'ดูข้อกำหนดและเงื่อนไขของเรา';

  @override
  String get privacyPolicy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get howWeHandleYourData => 'วิธีที่เราจัดการข้อมูลของคุณ';

  @override
  String get emailNotifications => 'การแจ้งเตือนอีเมล';

  @override
  String get receiveEmailNotificationsFromBananaTalk => 'รับการแจ้งเตือนอีเมลจาก BananaTalk';

  @override
  String get weeklySummary => 'สรุปรายสัปดาห์';

  @override
  String get activityRecapEverySunday => 'สรุปกิจกรรมทุกวันอาทิตย์';

  @override
  String get newMessages => 'ข้อความใหม่';

  @override
  String get whenYoureAwayFor24PlusHours => 'เมื่อคุณไม่อยู่เกิน 24 ชั่วโมง';

  @override
  String get newFollowers => 'ผู้ติดตามใหม่';

  @override
  String get whenSomeoneFollowsYou2 => 'When someone follows you';

  @override
  String get securityAlerts => 'การแจ้งเตือนความปลอดภัย';

  @override
  String get passwordLoginAlerts => 'การแจ้งเตือนรหัสผ่านและการเข้าสู่ระบบ';

  @override
  String get unblockUser2 => 'Unblock User';

  @override
  String get blockedUsers2 => 'Blocked Users';

  @override
  String get finalWarning => 'คำเตือนสุดท้าย';

  @override
  String get deleteForever => 'ลบถาวร';

  @override
  String get deleteAccount2 => 'Delete Account';

  @override
  String get enterYourPassword => 'ป้อนรหัสผ่านของคุณ';

  @override
  String get yourPassword => 'รหัสผ่านของคุณ';

  @override
  String get typeDELETEToConfirm => 'พิมพ์ DELETE เพื่อยืนยัน';

  @override
  String get typeDELETEInCapitalLetters => 'พิมพ์ DELETE ด้วยตัวพิมพ์ใหญ่';

  @override
  String sent(String emoji) {
    return '$emoji ส่งแล้ว!';
  }

  @override
  String get replySent => 'ส่งการตอบกลับแล้ว!';

  @override
  String get deleteStory => 'ลบสตอรี่?';

  @override
  String get thisStoryWillBeRemovedPermanently => 'สตอรี่นี้จะถูกลบอย่างถาวร';

  @override
  String get noStories => 'ไม่มีสตอรี่';

  @override
  String views(String count) {
    return '$count ครั้ง';
  }

  @override
  String get reportStory => 'รายงานสตอรี่';

  @override
  String get reply2 => 'Reply...';

  @override
  String get failedToPickImage => 'เลือกรูปภาพล้มเหลว';

  @override
  String get failedToTakePhoto => 'ถ่ายภาพล้มเหลว';

  @override
  String get failedToPickVideo => 'เลือกวิดีโอล้มเหลว';

  @override
  String get pleaseEnterSomeText => 'กรุณาป้อนข้อความ';

  @override
  String get pleaseSelectMedia => 'กรุณาเลือกสื่อ';

  @override
  String get storyPosted => 'โพสต์สตอรี่แล้ว!';

  @override
  String get textOnlyStoriesRequireAnImage => 'สตอรี่ข้อความต้องมีรูปภาพ';

  @override
  String get createStory => 'สร้างสตอรี่';

  @override
  String get change => 'เปลี่ยน';

  @override
  String get userIdNotFound => 'ไม่พบ User ID กรุณาเข้าสู่ระบบอีกครั้ง';

  @override
  String get pleaseSelectAPaymentMethod => 'กรุณาเลือกวิธีการชำระเงิน';

  @override
  String get startExploring => 'เริ่มสำรวจ';

  @override
  String get close => 'ปิด';

  @override
  String get payment => 'การชำระเงิน';

  @override
  String get upgradeToVIP => 'อัปเกรดเป็น VIP';

  @override
  String get errorLoadingProducts => 'ข้อผิดพลาดในการโหลดผลิตภัณฑ์';

  @override
  String get cancelVIPSubscription => 'ยกเลิกการสมัคร VIP';

  @override
  String get keepVIP => 'เก็บ VIP';

  @override
  String get cancelSubscription => 'ยกเลิกการสมัคร';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'ยกเลิกการสมัคร VIP สำเร็จ';

  @override
  String get vipStatus => 'สถานะ VIP';

  @override
  String get noActiveVIPSubscription => 'ไม่มีการสมัคร VIP ที่ใช้งานอยู่';

  @override
  String get subscriptionExpired => 'การสมัครหมดอายุ';

  @override
  String get vipExpiredMessage => 'การสมัคร VIP ของคุณหมดอายุแล้ว ต่ออายุตอนนี้เพื่อเพลิดเพลินกับฟีเจอร์ไม่จำกัด!';

  @override
  String get expiredOn => 'หมดอายุเมื่อ';

  @override
  String get renewVIP => 'ต่ออายุ VIP';

  @override
  String get whatYoureMissing => 'สิ่งที่คุณพลาด';

  @override
  String get manageInAppStore => 'จัดการใน App Store';

  @override
  String get becomeVIP => 'เป็น VIP';

  @override
  String get unlimitedMessages => 'ข้อความไม่จำกัด';

  @override
  String get unlimitedProfileViews => 'ดูโปรไฟล์ไม่จำกัด';

  @override
  String get prioritySupport => 'การสนับสนุนพิเศษ';

  @override
  String get advancedSearch => 'ค้นหาขั้นสูง';

  @override
  String get profileBoost => 'เพิ่มพลังโปรไฟล์';

  @override
  String get adFreeExperience => 'ประสบการณ์ไม่มีโฆษณา';

  @override
  String get upgradeYourAccount => 'อัปเกรดบัญชีของคุณ';

  @override
  String get moreMessages => 'ข้อความเพิ่มเติม';

  @override
  String get moreProfileViews => 'ดูโปรไฟล์เพิ่มเติม';

  @override
  String get connectWithFriends => 'เชื่อมต่อกับเพื่อน';

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
  String get skip => 'ข้าม';

  @override
  String get startReview => 'เริ่มตรวจสอบ';

  @override
  String get resolve => 'แก้ไข';

  @override
  String get dismiss => 'ปิด';

  @override
  String get filterReports => 'กรองรายงาน';

  @override
  String get all => 'ทั้งหมด';

  @override
  String get clear => 'ล้าง';

  @override
  String get apply => 'ใช้';

  @override
  String get myReports2 => 'My Reports';

  @override
  String get blockUser => 'บล็อกผู้ใช้';

  @override
  String get block => 'บล็อก';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => 'คุณต้องการบล็อกผู้ใช้นี้ด้วยหรือไม่?';

  @override
  String get noThanks => 'ไม่ ขอบคุณ';

  @override
  String get yesBlockThem => 'ใช่ บล็อกพวกเขา';

  @override
  String get reportUser2 => 'Report User';

  @override
  String get submitReport => 'ส่งรายงาน';

  @override
  String get addAQuestionAndAtLeast2Options => 'Add a question and at least 2 options';

  @override
  String get addOption => 'เพิ่มตัวเลือก';

  @override
  String get anonymousVoting => 'การลงคะแนนแบบไม่ระบุตัวตน';

  @override
  String get create => 'สร้าง';

  @override
  String get typeYourAnswer => 'พิมพ์คำตอบของคุณ...';

  @override
  String get send2 => 'Send';

  @override
  String get yourPrompt => 'คำถามของคุณ...';

  @override
  String get add2 => 'Add';

  @override
  String get contentNotAvailable => 'เนื้อหาไม่พร้อมใช้งาน';

  @override
  String get profileNotAvailable => 'โปรไฟล์ไม่พร้อมใช้งาน';

  @override
  String get noMomentsToShow => 'ไม่มีโมเมนต์ให้แสดง';

  @override
  String get storiesNotAvailable => 'สตอรี่ไม่พร้อมใช้งาน';

  @override
  String get cantMessageThisUser => 'ไม่สามารถส่งข้อความถึงผู้ใช้นี้';

  @override
  String get pleaseSelectAReason => 'กรุณาเลือกเหตุผล';

  @override
  String get reportSubmitted => 'ส่งรายงานแล้ว ขอบคุณที่ช่วยรักษาความปลอดภัยของชุมชน';

  @override
  String get youHaveAlreadyReportedThisMoment => 'คุณได้รายงานโมเมนต์นี้แล้ว';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => 'บอกเราเพิ่มเติมว่าทำไมคุณถึงรายงานสิ่งนี้';

  @override
  String get errorSharing => 'ข้อผิดพลาดในการแชร์';

  @override
  String get deviceInfo => 'ข้อมูลอุปกรณ์';

  @override
  String get recommended => 'แนะนำ';

  @override
  String get anyLanguage => 'ภาษาใดก็ได้';

  @override
  String get noLanguagesFound => 'ไม่พบภาษา';

  @override
  String get selectALanguage => 'เลือกภาษา';

  @override
  String get languagesAreStillLoading => 'กำลังโหลดภาษา...';

  @override
  String get selectNativeLanguage => 'เลือกภาษาแม่';

  @override
  String get subscriptionDetails => 'รายละเอียดการสมัคร';

  @override
  String get activeFeatures => 'ฟีเจอร์ที่ใช้งานอยู่';

  @override
  String get legalInformation => 'ข้อมูลทางกฎหมาย';

  @override
  String get termsOfUse => 'ข้อกำหนดการใช้งาน';

  @override
  String get manageSubscription => 'จัดการการสมัคร';

  @override
  String get manageSubscriptionInSettings => 'To cancel your subscription, go to Settings > [Your Name] > Subscriptions on your device.';

  @override
  String get contactSupportToCancel => 'To cancel your subscription, please contact our support team.';

  @override
  String get status => 'สถานะ';

  @override
  String get active => 'ใช้งานอยู่';

  @override
  String get plan => 'แผน';

  @override
  String get startDate => 'วันที่เริ่มต้น';

  @override
  String get endDate => 'วันที่สิ้นสุด';

  @override
  String get nextBillingDate => 'วันที่เรียกเก็บเงินถัดไป';

  @override
  String get autoRenew => 'ต่ออายุอัตโนมัติ';

  @override
  String get pleaseLogInToContinue => 'กรุณาเข้าสู่ระบบเพื่อดำเนินการต่อ';

  @override
  String get purchaseCanceledOrFailed => 'การซื้อถูกยกเลิกหรือล้มเหลว กรุณาลองอีกครั้ง';

  @override
  String get maximumTagsAllowed => 'อนุญาตสูงสุด 5 แท็ก';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => 'Please remove images first to add a video';

  @override
  String get unsupportedFormat => 'Unsupported format';

  @override
  String get errorProcessingVideo => 'Error processing video';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'Please remove images first to record a video';

  @override
  String get locationAdded => 'เพิ่มตำแหน่งแล้ว';

  @override
  String get failedToGetLocation => 'รับตำแหน่งล้มเหลว';

  @override
  String get notNow => 'ไม่ใช่ตอนนี้';

  @override
  String get videoUploadFailed => 'อัปโหลดวิดีโอล้มเหลว';

  @override
  String get skipVideo => 'ข้ามวิดีโอ';

  @override
  String get retryUpload => 'ลองอัปโหลดอีกครั้ง';

  @override
  String get momentCreatedSuccessfully => 'สร้างโมเมนต์สำเร็จ';

  @override
  String get uploadingMomentInBackground => 'กำลังอัปโหลดโมเมนต์ในพื้นหลัง...';

  @override
  String get failedToQueueUpload => 'Failed to queue upload';

  @override
  String get viewProfile => 'ดูโปรไฟล์';

  @override
  String get mediaLinksAndDocs => 'สื่อ ลิงก์ และเอกสาร';

  @override
  String get wallpaper => 'วอลเปเปอร์';

  @override
  String get userIdNotAvailable => 'User ID not available';

  @override
  String get cannotBlockYourself => 'Cannot block yourself';

  @override
  String get chatWallpaper => 'วอลเปเปอร์แชท';

  @override
  String get wallpaperSavedLocally => 'บันทึกวอลเปเปอร์ในเครื่องแล้ว';

  @override
  String get messageCopied => 'คัดลอกข้อความแล้ว';

  @override
  String get forwardFeatureComingSoon => 'Forward feature coming soon';

  @override
  String get momentUnsaved => 'Moment unsaved';

  @override
  String get documentPickerComingSoon => 'Document picker coming soon';

  @override
  String get contactSharingComingSoon => 'Contact sharing coming soon';

  @override
  String get featureComingSoon => 'ฟีเจอร์เร็วๆ นี้';

  @override
  String get answerSent => 'ส่งคำตอบแล้ว!';

  @override
  String get noImagesAvailable => 'ไม่มีรูปภาพ';

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
  String get linkCopied => 'คัดลอกลิงก์แล้ว!';

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
  String get correctionSent => 'ส่งการแก้ไขแล้ว!';

  @override
  String get sort => 'เรียงลำดับ';

  @override
  String get savedMoments => 'โมเมนต์ที่บันทึก';

  @override
  String get unsave => 'ยกเลิกบันทึก';

  @override
  String get playingAudio => 'Playing audio...';

  @override
  String get failedToGenerateQuiz => 'Failed to generate quiz';

  @override
  String get failedToAddComment => 'Failed to add comment';

  @override
  String get hello => 'สวัสดี!';

  @override
  String get howAreYou => 'สบายดีไหม?';

  @override
  String get cannotOpen => 'Cannot open';

  @override
  String get errorOpeningLink => 'Error opening link';

  @override
  String get saved => 'บันทึกแล้ว';

  @override
  String get follow => 'ติดตาม';

  @override
  String get unfollow => 'เลิกติดตาม';

  @override
  String get mute => 'ปิดเสียง';

  @override
  String get online => 'ออนไลน์';

  @override
  String get offline => 'ออฟไลน์';

  @override
  String get lastSeen => 'เห็นล่าสุด';

  @override
  String get justNow => 'เมื่อสักครู่';

  @override
  String minutesAgo(String count) {
    return '$count นาทีที่แล้ว';
  }

  @override
  String hoursAgo(String count) {
    return '$count ชั่วโมงที่แล้ว';
  }

  @override
  String get yesterday => 'เมื่อวาน';

  @override
  String get signInWithEmail => 'เข้าสู่ระบบด้วยอีเมล';

  @override
  String get partners => 'คู่หู';

  @override
  String get nearby => 'ใกล้เคียง';

  @override
  String get topics => 'หัวข้อ';

  @override
  String get waves => 'โบกมือ';

  @override
  String get voiceRooms => 'เสียง';

  @override
  String get filters => 'ตัวกรอง';

  @override
  String get searchCommunity => 'ค้นหาตามชื่อ ภาษา หรือความสนใจ...';

  @override
  String get bio => 'ประวัติ';

  @override
  String get noBioYet => 'ยังไม่มีประวัติ';

  @override
  String get languages => 'ภาษา';

  @override
  String get native => 'ภาษาแม่';

  @override
  String get interests => 'ความสนใจ';

  @override
  String get noMomentsYet => 'ยังไม่มีโมเมนต์';

  @override
  String get unableToLoadMoments => 'Unable to load moments';

  @override
  String get map => 'แผนที่';

  @override
  String get mapUnavailable => 'Map unavailable';

  @override
  String get location => 'ตำแหน่ง';

  @override
  String get unknownLocation => 'Unknown location';

  @override
  String get noImagesAvailable2 => 'No images available';

  @override
  String get permissionsRequired => 'Permissions Required';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get refresh => 'รีเฟรช';

  @override
  String get videoCall => 'วิดีโอ';

  @override
  String get voiceCall => 'โทร';

  @override
  String get message => 'ข้อความ';

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
  String get youFollowed => 'คุณติดตาม';

  @override
  String get youUnfollowed => 'คุณเลิกติดตาม';

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
  String get typing => 'กำลังพิมพ์';

  @override
  String get connecting => 'กำลังเชื่อมต่อ...';

  @override
  String daysAgo(int count) {
    return '$countวันที่แล้ว';
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
  String get closeFriends => 'เพื่อนสนิท';

  @override
  String get addFriends => 'Add Friends';

  @override
  String get highlights => 'ไฮไลท์';

  @override
  String get createHighlight => 'สร้างไฮไลท์';

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
  String get stay => 'อยู่';

  @override
  String get leave => 'ออก';

  @override
  String get enableGPS => 'เปิด GPS';

  @override
  String wavedToUser(String name) {
    return 'โบกมือให้ $name!';
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
  String get yourStory => 'สตอรี่ของคุณ';

  @override
  String get sendMessage => 'ส่งข้อความ';

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
  String get photo => 'รูปภาพ';

  @override
  String get record => 'บันทึก';

  @override
  String get addSticker => 'Add Sticker';

  @override
  String get poll => 'โพล';

  @override
  String get question => 'คำถาม';

  @override
  String get mention => 'พูดถึง';

  @override
  String get music => 'เพลง';

  @override
  String get hashtag => 'แฮชแท็ก';

  @override
  String get whoCanSeeThis => 'Who can see this?';

  @override
  String get everyone => 'ทุกคน';

  @override
  String get anyoneCanSeeStory => 'Anyone can see this story';

  @override
  String get friendsOnly => 'เพื่อนเท่านั้น';

  @override
  String get onlyFollowersCanSee => 'Only your followers can see';

  @override
  String get onlyCloseFriendsCanSee => 'Only your close friends can see';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get fontStyle => 'Font Style';

  @override
  String get normal => 'ปกติ';

  @override
  String get bold => 'ตัวหนา';

  @override
  String get italic => 'ตัวเอียง';

  @override
  String get handwriting => 'Handwriting';

  @override
  String get addLocation => 'เพิ่มตำแหน่ง';

  @override
  String get enterLocationName => 'Enter location name';

  @override
  String get addLink => 'เพิ่มลิงก์';

  @override
  String get buttonText => 'Button text';

  @override
  String get learnMore => 'เรียนรู้เพิ่มเติม';

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
  String get oneHour => '1 ชั่วโมง';

  @override
  String get eightHours => '8 ชั่วโมง';

  @override
  String get oneWeek => '1 สัปดาห์';

  @override
  String get always => 'เสมอ';

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
  String get voiceMessage => 'ข้อความเสียง';

  @override
  String get document => 'เอกสาร';

  @override
  String get attachment => 'ไฟล์แนบ';

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
  String get preview => 'ดูตัวอย่าง';

  @override
  String get wallpaperUpdated => 'Wallpaper updated';

  @override
  String get category => 'หมวดหมู่';

  @override
  String get mood => 'อารมณ์';

  @override
  String get sortBy => 'เรียงตาม';

  @override
  String get timePeriod => 'Time Period';

  @override
  String get searchLanguages => 'Search languages...';

  @override
  String get selected => 'เลือกแล้ว';

  @override
  String get categories => 'หมวดหมู่';

  @override
  String get moods => 'อารมณ์';

  @override
  String get applyFilters => 'ใช้ตัวกรอง';

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
  String get noInternetConnection => 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';

  @override
  String get tryAgainLater => 'กรุณาลองใหม่ภายหลัง';

  @override
  String get messageSent => 'ส่งข้อความแล้ว';

  @override
  String get messageDeleted => 'ลบข้อความแล้ว';

  @override
  String get messageEdited => 'แก้ไขข้อความแล้ว';
}
