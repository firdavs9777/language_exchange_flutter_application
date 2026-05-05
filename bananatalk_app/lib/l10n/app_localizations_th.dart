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
  String get more => 'เพิ่มเติม';

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
  String get overview => 'ภาพรวม';

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
  String get tryAgain => 'ลองใหม่';

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
  String get deleteComment => 'Delete Comment?';

  @override
  String get commentDeleted => 'Comment deleted';

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
  String get clearCache => 'ล้างแคช';

  @override
  String get clearCacheSubtitle => 'เพิ่มพื้นที่จัดเก็บ';

  @override
  String get clearCacheDescription => 'การดำเนินการนี้จะล้างรูปภาพ วิดีโอ และไฟล์เสียงที่แคชไว้ทั้งหมด แอปอาจโหลดเนื้อหาช้าลงชั่วคราวขณะดาวน์โหลดสื่อใหม่';

  @override
  String get clearCacheHint => 'ใช้ตัวเลือกนี้หากรูปภาพหรือเสียงไม่โหลดอย่างถูกต้อง';

  @override
  String get clearingCache => 'กำลังล้างแคช...';

  @override
  String get cacheCleared => 'ล้างแคชสำเร็จ! รูปภาพจะโหลดใหม่';

  @override
  String get clearCacheFailed => 'ล้างแคชไม่สำเร็จ';

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
  String get chats => 'แชท';

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
  String get momentUnsaved => 'ลบออกจากที่บันทึกแล้ว';

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
  String get openSettings => 'เปิดการตั้งค่า';

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
  String get exchange3MessagesBeforeCall => 'Exchange 3+ messages before calling';

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
  String get newHighlight => 'ไฮไลท์ใหม่';

  @override
  String get addToHighlight => 'เพิ่มไปยังไฮไลท์';

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
  String get deleteHighlight => 'ลบไฮไลท์';

  @override
  String get editHighlight => 'แก้ไขไฮไลท์';

  @override
  String get addMoreToStory => 'Add more to story';

  @override
  String get noViewersYet => 'No viewers yet';

  @override
  String get noReactionsYet => 'No reactions yet';

  @override
  String get leaveRoom => 'ออกจากห้อง';

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
  String get searchUsers => 'ค้นหาผู้ใช้...';

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
  String get addSticker => 'เพิ่มสติกเกอร์';

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
  String get chooseFromGallery => 'Choose from Gallery';

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
  String get videoMustBeUnder1GB => 'วิดีโอต้องมีขนาดไม่เกิน 1GB';

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

  @override
  String get edited => '(แก้ไขแล้ว)';

  @override
  String get now => 'ตอนนี้';

  @override
  String weeksAgo(int count) {
    return '$count สัปดาห์ที่แล้ว';
  }

  @override
  String viewRepliesCount(int count) {
    return '── ดู $count การตอบกลับ';
  }

  @override
  String get hideReplies => '── ซ่อนการตอบกลับ';

  @override
  String get saveMoment => 'บันทึกโมเมนต์';

  @override
  String get removeFromSaved => 'ลบออกจากที่บันทึก';

  @override
  String get momentSaved => 'บันทึกแล้ว';

  @override
  String get failedToSave => 'บันทึกล้มเหลว';

  @override
  String get checkOutMoment => 'ดูโมเมนต์นี้บน BananaTalk!';

  @override
  String get failedToLoadMoments => 'โหลดโมเมนต์ล้มเหลว';

  @override
  String get noMomentsMatchFilters => 'ไม่มีโมเมนต์ตรงกับตัวกรอง';

  @override
  String get beFirstToShareMoment => 'เป็นคนแรกที่แชร์โมเมนต์!';

  @override
  String get tryDifferentSearch => 'ลองคำค้นหาอื่น';

  @override
  String get tryAdjustingFilters => 'ลองปรับตัวกรอง';

  @override
  String get noSavedMoments => 'ไม่มีโมเมนต์ที่บันทึก';

  @override
  String get tapBookmarkToSave => 'แตะไอคอนบุ๊กมาร์กเพื่อบันทึกโมเมนต์';

  @override
  String get failedToLoadVideo => 'โหลดวิดีโอล้มเหลว';

  @override
  String get titleRequired => 'ต้องระบุชื่อเรื่อง';

  @override
  String titleTooLong(int max) {
    return 'ชื่อเรื่องต้องไม่เกิน $max ตัวอักษร';
  }

  @override
  String get descriptionRequired => 'ต้องระบุคำอธิบาย';

  @override
  String descriptionTooLong(int max) {
    return 'คำอธิบายต้องไม่เกิน $max ตัวอักษร';
  }

  @override
  String get scheduledDateMustBeFuture => 'วันที่กำหนดต้องเป็นอนาคต';

  @override
  String get recent => 'ล่าสุด';

  @override
  String get popular => 'ยอดนิยม';

  @override
  String get trending => 'กำลังมาแรง';

  @override
  String get mostRecent => 'ล่าสุด';

  @override
  String get mostPopular => 'ยอดนิยมที่สุด';

  @override
  String get allTime => 'ทั้งหมด';

  @override
  String get today => 'วันนี้';

  @override
  String get thisWeek => 'สัปดาห์นี้';

  @override
  String get thisMonth => 'เดือนนี้';

  @override
  String replyingTo(String userName) {
    return 'ตอบกลับ $userName';
  }

  @override
  String get listView => 'มุมมองรายการ';

  @override
  String get quickMatch => 'จับคู่ด่วน';

  @override
  String get onlineNow => 'ออนไลน์อยู่';

  @override
  String speaksLanguage(String language) {
    return 'พูด$language';
  }

  @override
  String learningLanguage(String language) {
    return 'กำลังเรียน$language';
  }

  @override
  String get noPartnersFound => 'ไม่พบคู่หู';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return 'ไม่พบผู้ใช้ที่พูด$learningเป็นภาษาแม่หรือต้องการเรียน$native';
  }

  @override
  String get removeAllFilters => 'ลบตัวกรองทั้งหมด';

  @override
  String get browseAllUsers => 'ดูผู้ใช้ทั้งหมด';

  @override
  String get allCaughtUp => 'ดูหมดแล้ว!';

  @override
  String get loadingMore => 'กำลังโหลดเพิ่ม...';

  @override
  String get findingMorePartners => 'กำลังค้นหาคู่หูเพิ่ม...';

  @override
  String get seenAllPartners => 'คุณดูคู่หูทั้งหมดแล้ว';

  @override
  String get startOver => 'เริ่มใหม่';

  @override
  String get changeFilters => 'เปลี่ยนตัวกรอง';

  @override
  String get findingPartners => 'กำลังค้นหาคู่หู...';

  @override
  String get setLocationReminder => 'ตั้งค่าตำแหน่งเพื่อค้นหาคู่หูใกล้เคียง';

  @override
  String get updateLocationReminder => 'อัปเดตตำแหน่งเพื่อผลลัพธ์ที่ดีขึ้น';

  @override
  String get male => 'ชาย';

  @override
  String get female => 'หญิง';

  @override
  String get other => 'อื่นๆ';

  @override
  String get browseMen => 'ดูผู้ชาย';

  @override
  String get browseWomen => 'ดูผู้หญิง';

  @override
  String get noMaleUsersFound => 'ไม่พบผู้ใช้ชาย';

  @override
  String get noFemaleUsersFound => 'ไม่พบผู้ใช้หญิง';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => 'เฉพาะผู้ใช้ใหม่';

  @override
  String get showNewUsers => 'แสดงผู้ใช้ใหม่';

  @override
  String get prioritizeNearby => 'ให้ความสำคัญกับคนใกล้เคียง';

  @override
  String get showNearbyFirst => 'แสดงคนใกล้เคียงก่อน';

  @override
  String get setLocationToEnable => 'ตั้งค่าตำแหน่งเพื่อเปิดใช้งาน';

  @override
  String get radius => 'รัศมี';

  @override
  String get findingYourLocation => 'กำลังค้นหาตำแหน่งของคุณ...';

  @override
  String get enableLocationForDistance => 'เปิดใช้งานตำแหน่งสำหรับระยะทาง';

  @override
  String get enableLocationDescription => 'เปิดใช้บริการตำแหน่งเพื่อค้นหาคู่หูแลกเปลี่ยนภาษาใกล้เคียง';

  @override
  String get enableGps => 'เปิด GPS';

  @override
  String get browseByCityCountry => 'ค้นหาตามเมือง/ประเทศ';

  @override
  String get peopleNearby => 'คนใกล้เคียง';

  @override
  String get noNearbyUsersFound => 'ไม่พบผู้ใช้ใกล้เคียง';

  @override
  String get tryExpandingSearch => 'ลองขยายการค้นหา';

  @override
  String get exploreByCity => 'สำรวจตามเมือง';

  @override
  String get exploreByCurrentCity => 'สำรวจตามเมืองปัจจุบัน';

  @override
  String get interactiveWorldMap => 'แผนที่โลกแบบโต้ตอบ';

  @override
  String get searchByCityName => 'ค้นหาตามชื่อเมือง';

  @override
  String get seeUserCountsPerCountry => 'ดูจำนวนผู้ใช้ต่อประเทศ';

  @override
  String get upgradeToVip => 'อัปเกรดเป็น VIP';

  @override
  String get searchByCity => 'ค้นหาตามเมือง';

  @override
  String usersWorldwide(String count) {
    return '$count ผู้ใช้ทั่วโลก';
  }

  @override
  String get noUsersFound => 'ไม่พบผู้ใช้';

  @override
  String get tryDifferentCity => 'ลองเมืองอื่น';

  @override
  String usersCount(String count) {
    return '$count ผู้ใช้';
  }

  @override
  String get searchCountry => 'ค้นหาประเทศ...';

  @override
  String get wave => 'โบกมือ';

  @override
  String get newUser => 'ผู้ใช้ใหม่';

  @override
  String get warningPermanent => 'คำเตือน: การกระทำนี้ถาวร!';

  @override
  String get deleteAccountWarning => 'การลบบัญชีของคุณจะลบอย่างถาวร:\n\n• โปรไฟล์และข้อมูลส่วนตัวทั้งหมดของคุณ\n• ข้อความและการสนทนาทั้งหมดของคุณ\n• โมเมนต์และสตอรี่ทั้งหมดของคุณ\n• การสมัคร VIP ของคุณ (ไม่คืนเงิน)\n• การเชื่อมต่อและผู้ติดตามทั้งหมดของคุณ\n\nการกระทำนี้ไม่สามารถยกเลิกได้';

  @override
  String get requiredForEmailOnly => 'จำเป็นสำหรับบัญชีอีเมลเท่านั้น';

  @override
  String get pleaseEnterPassword => 'กรุณาป้อนรหัสผ่านของคุณ';

  @override
  String get typeDELETE => 'พิมพ์ DELETE';

  @override
  String get mustTypeDELETE => 'คุณต้องพิมพ์ DELETE เพื่อดำเนินการต่อ';

  @override
  String get deletingAccount => 'กำลังลบบัญชี...';

  @override
  String get deleteMyAccountPermanently => 'ลบบัญชีของฉันอย่างถาวร';

  @override
  String get whatsYourNativeLanguage => 'ภาษาแม่ของคุณคืออะไร?';

  @override
  String get helpsMatchWithLearners => 'ช่วยจับคู่กับผู้เรียน';

  @override
  String get whatAreYouLearning => 'คุณกำลังเรียนอะไร?';

  @override
  String get connectWithNativeSpeakers => 'เชื่อมต่อกับเจ้าของภาษา';

  @override
  String get selectLearningLanguage => 'เลือกภาษาที่จะเรียน';

  @override
  String get selectCurrentLevel => 'เลือกระดับปัจจุบัน';

  @override
  String get beginner => 'เริ่มต้น';

  @override
  String get elementary => 'พื้นฐาน';

  @override
  String get intermediate => 'ระดับกลาง';

  @override
  String get upperIntermediate => 'ระดับกลางขั้นสูง';

  @override
  String get advanced => 'ขั้นสูง';

  @override
  String get proficient => 'เชี่ยวชาญ';

  @override
  String get showingPartnersByDistance => 'แสดงคู่หูตามระยะทาง';

  @override
  String get enableLocationForResults => 'เปิดใช้งานตำแหน่งเพื่อผลลัพธ์ที่ดีขึ้น';

  @override
  String get enable => 'เปิดใช้งาน';

  @override
  String get locationNotSet => 'ยังไม่ได้ตั้งค่าตำแหน่ง';

  @override
  String get tellUsAboutYourself => 'บอกเราเกี่ยวกับตัวคุณ';

  @override
  String get justACoupleQuickThings => 'แค่สองสามอย่างสั้นๆ';

  @override
  String get gender => 'เพศ';

  @override
  String get birthDate => 'วันเกิด';

  @override
  String get selectYourBirthDate => 'เลือกวันเกิดของคุณ';

  @override
  String get continueButton => 'ดำเนินการต่อ';

  @override
  String get pleaseSelectGender => 'กรุณาเลือกเพศของคุณ';

  @override
  String get pleaseSelectBirthDate => 'กรุณาเลือกวันเกิดของคุณ';

  @override
  String get mustBe18 => 'คุณต้องมีอายุอย่างน้อย 18 ปี';

  @override
  String get invalidDate => 'วันที่ไม่ถูกต้อง';

  @override
  String get almostDone => 'เกือบเสร็จแล้ว!';

  @override
  String get addPhotoLocationForMatches => 'เพิ่มรูปภาพและตำแหน่งเพื่อการจับคู่ที่ดีขึ้น';

  @override
  String get addProfilePhoto => 'เพิ่มรูปโปรไฟล์';

  @override
  String get optionalUpTo6Photos => 'ไม่บังคับ - สูงสุด 6 รูป';

  @override
  String get requiredUpTo6Photos => 'จำเป็น — สูงสุด 6 รูป';

  @override
  String get profilePhotoRequired => 'กรุณาเพิ่มรูปโปรไฟล์อย่างน้อย 1 รูป';

  @override
  String get locationOptional => 'ตำแหน่งที่ตั้งเป็นตัวเลือก — สามารถเพิ่มภายหลังได้';

  @override
  String get maximum6Photos => 'สูงสุด 6 รูป';

  @override
  String get tapToDetectLocation => 'แตะเพื่อตรวจหาตำแหน่ง';

  @override
  String get optionalHelpsNearbyPartners => 'ไม่บังคับ - ช่วยค้นหาคู่หูใกล้เคียง';

  @override
  String get startLearning => 'เริ่มเรียน';

  @override
  String get photoLocationOptional => 'รูปภาพและตำแหน่งเป็นทางเลือก';

  @override
  String get pleaseAcceptTerms => 'กรุณายอมรับข้อกำหนดการใช้บริการ';

  @override
  String get iAgreeToThe => 'ฉันยอมรับ';

  @override
  String get termsOfService => 'ข้อกำหนดการใช้บริการ';

  @override
  String get tapToSelectLanguage => 'แตะเพื่อเลือกภาษา';

  @override
  String yourLevelIn(String language) {
    return 'ระดับของคุณใน$language (ไม่บังคับ)';
  }

  @override
  String get yourCurrentLevel => 'ระดับปัจจุบันของคุณ';

  @override
  String get nativeCannotBeSameAsLearning => 'ภาษาแม่ต้องไม่เหมือนกับภาษาที่กำลังเรียน';

  @override
  String get learningCannotBeSameAsNative => 'ภาษาที่กำลังเรียนต้องไม่เหมือนกับภาษาแม่';

  @override
  String stepOf(String current, String total) {
    return 'ขั้นตอนที่ $current จาก $total';
  }

  @override
  String get continueWithGoogle => 'ดำเนินการต่อด้วย Google';

  @override
  String get registerLink => 'ลงทะเบียน';

  @override
  String get pleaseEnterBothEmailAndPassword => 'กรุณากรอกอีเมลและรหัสผ่าน';

  @override
  String get pleaseEnterValidEmail => 'กรุณากรอกอีเมลที่ถูกต้อง';

  @override
  String get loginSuccessful => 'เข้าสู่ระบบสำเร็จ!';

  @override
  String get stepOneOfTwo => 'ขั้นตอนที่ 1 จาก 2';

  @override
  String get createYourAccount => 'สร้างบัญชีของคุณ';

  @override
  String get basicInfoToGetStarted => 'ข้อมูลพื้นฐานเพื่อเริ่มต้น';

  @override
  String get emailVerifiedLabel => 'อีเมล (ยืนยันแล้ว)';

  @override
  String get nameLabel => 'ชื่อ';

  @override
  String get yourDisplayName => 'ชื่อที่แสดง';

  @override
  String get atLeast8Characters => 'อย่างน้อย 8 ตัวอักษร';

  @override
  String get confirmPasswordHint => 'ยืนยันรหัสผ่าน';

  @override
  String get nextButton => 'ถัดไป';

  @override
  String get pleaseEnterYourName => 'กรุณากรอกชื่อ';

  @override
  String get pleaseEnterAPassword => 'กรุณากรอกรหัสผ่าน';

  @override
  String get passwordsDoNotMatch => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get otherGender => 'อื่นๆ';

  @override
  String get continueWithGoogleAccount => 'ดำเนินการต่อด้วยบัญชี Google\nเพื่อประสบการณ์ที่ราบรื่น';

  @override
  String get signingYouIn => 'กำลังเข้าสู่ระบบ...';

  @override
  String get backToSignInMethods => 'กลับไปวิธีเข้าสู่ระบบ';

  @override
  String get securedByGoogle => 'รักษาความปลอดภัยโดย Google';

  @override
  String get dataProtectedEncryption => 'ข้อมูลของคุณได้รับการปกป้องด้วยการเข้ารหัสมาตรฐาน';

  @override
  String get welcomeCompleteProfile => 'ยินดีต้อนรับ! กรุณากรอกโปรไฟล์';

  @override
  String welcomeBackName(String name) {
    return 'ยินดีต้อนรับกลับ $name!';
  }

  @override
  String get continueWithAppleId => 'ดำเนินการต่อด้วย Apple ID\nเพื่อประสบการณ์ที่ปลอดภัย';

  @override
  String get continueWithApple => 'ดำเนินการต่อด้วย Apple';

  @override
  String get securedByApple => 'รักษาความปลอดภัยโดย Apple';

  @override
  String get privacyProtectedApple => 'ความเป็นส่วนตัวของคุณได้รับการปกป้องด้วย Apple Sign-In';

  @override
  String get createAccount => 'สร้างบัญชี';

  @override
  String get enterEmailToGetStarted => 'กรอกอีเมลเพื่อเริ่มต้น';

  @override
  String get continueText => 'ดำเนินการต่อ';

  @override
  String get pleaseEnterEmailAddress => 'กรุณากรอกที่อยู่อีเมล';

  @override
  String get verificationCodeSent => 'ส่งรหัสยืนยันแล้ว!';

  @override
  String get forgotPasswordTitle => 'ลืมรหัสผ่าน';

  @override
  String get resetPasswordTitle => 'รีเซ็ตรหัสผ่าน';

  @override
  String get enterEmailForResetCode => 'กรอกอีเมลและเราจะส่งรหัสรีเซ็ตให้คุณ';

  @override
  String get sendResetCode => 'ส่งรหัสรีเซ็ต';

  @override
  String get resetCodeSent => 'ส่งรหัสรีเซ็ตแล้ว!';

  @override
  String get rememberYourPassword => 'จำรหัสผ่านได้?';

  @override
  String get verifyCode => 'ตรวจสอบรหัส';

  @override
  String get enterResetCode => 'กรอกรหัสรีเซ็ต';

  @override
  String get weSentCodeTo => 'เราส่งรหัส 6 หลักไปที่';

  @override
  String get pleaseEnterAll6Digits => 'กรุณากรอกตัวเลข 6 หลัก';

  @override
  String get codeVerifiedCreatePassword => 'ยืนยันรหัสแล้ว! สร้างรหัสผ่านใหม่';

  @override
  String get verify => 'ยืนยัน';

  @override
  String get didntReceiveCode => 'ไม่ได้รับรหัส?';

  @override
  String get resend => 'ส่งอีกครั้ง';

  @override
  String resendWithTimer(String timer) {
    return 'ส่งอีกครั้ง ($timerว)';
  }

  @override
  String get resetCodeResent => 'ส่งรหัสรีเซ็ตอีกครั้งแล้ว!';

  @override
  String get verifyEmail => 'ยืนยันอีเมล';

  @override
  String get verifyYourEmail => 'ยืนยันอีเมลของคุณ';

  @override
  String get emailVerifiedSuccessfully => 'ยืนยันอีเมลสำเร็จ!';

  @override
  String get verificationCodeResent => 'ส่งรหัสยืนยันอีกครั้งแล้ว!';

  @override
  String get createNewPassword => 'สร้างรหัสผ่านใหม่';

  @override
  String get enterNewPasswordBelow => 'กรอกรหัสผ่านใหม่ด้านล่าง';

  @override
  String get newPassword => 'รหัสผ่านใหม่';

  @override
  String get confirmPasswordLabel => 'ยืนยันรหัสผ่าน';

  @override
  String get pleaseFillAllFields => 'กรุณากรอกข้อมูลทุกช่อง';

  @override
  String get passwordResetSuccessful => 'รีเซ็ตรหัสผ่านสำเร็จ! เข้าสู่ระบบด้วยรหัสผ่านใหม่';

  @override
  String get privacyTitle => 'ความเป็นส่วนตัว';

  @override
  String get profileVisibility => 'การแสดงโปรไฟล์';

  @override
  String get showCountryRegion => 'แสดงประเทศ/ภูมิภาค';

  @override
  String get showCountryRegionDesc => 'แสดงประเทศของคุณในโปรไฟล์';

  @override
  String get showCity => 'แสดงเมือง';

  @override
  String get showCityDesc => 'แสดงเมืองของคุณในโปรไฟล์';

  @override
  String get showAge => 'แสดงอายุ';

  @override
  String get showAgeDesc => 'แสดงอายุของคุณในโปรไฟล์';

  @override
  String get showZodiacSign => 'แสดงราศี';

  @override
  String get showZodiacSignDesc => 'แสดงราศีของคุณในโปรไฟล์';

  @override
  String get onlineStatusSection => 'สถานะออนไลน์';

  @override
  String get showOnlineStatus => 'แสดงสถานะออนไลน์';

  @override
  String get showOnlineStatusDesc => 'ให้ผู้อื่นเห็นเมื่อคุณออนไลน์';

  @override
  String get otherSettings => 'การตั้งค่าอื่นๆ';

  @override
  String get showGiftingLevel => 'แสดงระดับของขวัญ';

  @override
  String get showGiftingLevelDesc => 'แสดงตราระดับของขวัญ';

  @override
  String get birthdayNotifications => 'การแจ้งเตือนวันเกิด';

  @override
  String get birthdayNotificationsDesc => 'รับการแจ้งเตือนในวันเกิดของคุณ';

  @override
  String get personalizedAds => 'โฆษณาส่วนบุคคล';

  @override
  String get personalizedAdsDesc => 'อนุญาตโฆษณาส่วนบุคคล';

  @override
  String get saveChanges => 'บันทึกการเปลี่ยนแปลง';

  @override
  String get privacySettingsSaved => 'บันทึกการตั้งค่าความเป็นส่วนตัวแล้ว';

  @override
  String get locationSection => 'ตำแหน่ง';

  @override
  String get updateLocation => 'อัปเดตตำแหน่ง';

  @override
  String get updateLocationDesc => 'รีเฟรชตำแหน่งปัจจุบัน';

  @override
  String get currentLocation => 'ตำแหน่งปัจจุบัน';

  @override
  String get locationNotAvailable => 'ไม่มีตำแหน่ง';

  @override
  String get locationUpdated => 'อัปเดตตำแหน่งสำเร็จ';

  @override
  String get locationPermissionDenied => 'ไม่อนุญาตตำแหน่ง กรุณาเปิดในการตั้งค่า';

  @override
  String get locationServiceDisabled => 'บริการตำแหน่งถูกปิด กรุณาเปิดใช้งาน';

  @override
  String get updatingLocation => 'กำลังอัปเดตตำแหน่ง...';

  @override
  String get locationCouldNotBeUpdated => 'ไม่สามารถอัปเดตตำแหน่งได้';

  @override
  String get incomingAudioCall => 'สายเรียกเข้าเสียง';

  @override
  String get incomingVideoCall => 'สายเรียกเข้าวิดีโอ';

  @override
  String get outgoingCall => 'กำลังโทร...';

  @override
  String get callRinging => 'กำลังเรียก...';

  @override
  String get callConnecting => 'กำลังเชื่อมต่อ...';

  @override
  String get callConnected => 'เชื่อมต่อแล้ว';

  @override
  String get callReconnecting => 'กำลังเชื่อมต่อใหม่...';

  @override
  String get callEnded => 'สายสิ้นสุด';

  @override
  String get callFailed => 'โทรไม่สำเร็จ';

  @override
  String get callMissed => 'สายที่ไม่ได้รับ';

  @override
  String get callDeclined => 'ปฏิเสธสาย';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => 'รับสาย';

  @override
  String get declineCall => 'ปฏิเสธ';

  @override
  String get endCall => 'วางสาย';

  @override
  String get muteCall => 'ปิดเสียง';

  @override
  String get unmuteCall => 'เปิดเสียง';

  @override
  String get speakerOn => 'ลำโพง';

  @override
  String get speakerOff => 'หูฟัง';

  @override
  String get videoOn => 'เปิดวิดีโอ';

  @override
  String get videoOff => 'ปิดวิดีโอ';

  @override
  String get switchCamera => 'สลับกล้อง';

  @override
  String get callPermissionDenied => 'ต้องการสิทธิ์ไมโครโฟนสำหรับการโทร';

  @override
  String get cameraPermissionDenied => 'ต้องการสิทธิ์กล้องสำหรับวิดีโอคอล';

  @override
  String get callConnectionFailed => 'ไม่สามารถเชื่อมต่อได้ กรุณาลองใหม่';

  @override
  String get userBusy => 'ผู้ใช้ไม่ว่าง';

  @override
  String get userOffline => 'ผู้ใช้ออฟไลน์';

  @override
  String get callHistory => 'ประวัติการโทร';

  @override
  String get noCallHistory => 'ไม่มีประวัติการโทร';

  @override
  String get missedCalls => 'สายที่ไม่ได้รับ';

  @override
  String get allCalls => 'ทุกสาย';

  @override
  String get callBack => 'โทรกลับ';

  @override
  String callAt(String time) {
    return 'โทรเวลา $time';
  }

  @override
  String get audioCall => 'สายเสียง';

  @override
  String get voiceRoom => 'ห้องเสียง';

  @override
  String get noVoiceRooms => 'ไม่มีห้องเสียงที่ใช้งานอยู่';

  @override
  String get createVoiceRoom => 'สร้างห้องเสียง';

  @override
  String get joinRoom => 'เข้าร่วมห้อง';

  @override
  String get leaveRoomConfirm => 'ออกจากห้อง?';

  @override
  String get leaveRoomMessage => 'คุณแน่ใจหรือไม่ว่าต้องการออกจากห้องนี้?';

  @override
  String get roomTitle => 'ชื่อห้อง';

  @override
  String get roomTitleHint => 'ป้อนชื่อห้อง';

  @override
  String get roomTopic => 'หัวข้อ';

  @override
  String get roomLanguage => 'ภาษา';

  @override
  String get roomHost => 'โฮสต์';

  @override
  String roomParticipants(int count) {
    return '$count ผู้เข้าร่วม';
  }

  @override
  String roomMaxParticipants(int count) {
    return 'สูงสุด $count ผู้เข้าร่วม';
  }

  @override
  String get selectTopic => 'เลือกหัวข้อ';

  @override
  String get raiseHand => 'ยกมือ';

  @override
  String get lowerHand => 'ลดมือ';

  @override
  String get handRaisedNotification => 'ยกมือแล้ว! โฮสต์จะเห็นคำขอของคุณ';

  @override
  String get handLoweredNotification => 'ลดมือแล้ว';

  @override
  String get muteParticipant => 'ปิดเสียงผู้เข้าร่วม';

  @override
  String get kickParticipant => 'นำออกจากห้อง';

  @override
  String get promoteToCoHost => 'เลื่อนเป็นโค-โฮสต์';

  @override
  String get endRoomConfirm => 'สิ้นสุดห้อง?';

  @override
  String get endRoomMessage => 'นี่จะสิ้นสุดห้องสำหรับผู้เข้าร่วมทุกคน';

  @override
  String get roomEnded => 'ห้องสิ้นสุดโดยโฮสต์';

  @override
  String get youWereRemoved => 'คุณถูกนำออกจากห้อง';

  @override
  String get roomIsFull => 'ห้องเต็ม';

  @override
  String get roomChat => 'แชทห้อง';

  @override
  String get noMessages => 'ยังไม่มีข้อความ';

  @override
  String get typeMessage => 'พิมพ์ข้อความ...';

  @override
  String get voiceRoomsDescription => 'เข้าร่วมการสนทนาสดและฝึกพูด';

  @override
  String liveRoomsCount(int count) {
    return '$count สด';
  }

  @override
  String get noActiveRooms => 'ไม่มีห้องที่ใช้งานอยู่';

  @override
  String get noActiveRoomsDescription => 'เป็นคนแรกที่เริ่มห้องเสียงและฝึกพูดกับคนอื่น!';

  @override
  String get startRoom => 'เริ่มห้อง';

  @override
  String get createRoom => 'สร้างห้อง';

  @override
  String get roomCreated => 'สร้างห้องสำเร็จ!';

  @override
  String get failedToCreateRoom => 'สร้างห้องไม่สำเร็จ';

  @override
  String get errorLoadingRooms => 'เกิดข้อผิดพลาดในการโหลดห้อง';

  @override
  String get pleaseEnterRoomTitle => 'กรุณาป้อนชื่อห้อง';

  @override
  String get startLiveConversation => 'เริ่มการสนทนาสด';

  @override
  String get maxParticipants => 'ผู้เข้าร่วมสูงสุด';

  @override
  String nPeople(int count) {
    return '$count คน';
  }

  @override
  String hostedBy(String name) {
    return 'โฮสต์โดย $name';
  }

  @override
  String get liveLabel => 'สด';

  @override
  String get joinLabel => 'เข้าร่วม';

  @override
  String get fullLabel => 'เต็ม';

  @override
  String get justStarted => 'เพิ่งเริ่ม';

  @override
  String get allLanguages => 'ทุกภาษา';

  @override
  String get allTopics => 'ทุกหัวข้อ';

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
  String get you => 'คุณ';

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
  String get dataAndStorage => 'ข้อมูลและพื้นที่จัดเก็บ';

  @override
  String get manageStorageAndDownloads => 'จัดการพื้นที่จัดเก็บและการดาวน์โหลด';

  @override
  String get storageUsage => 'การใช้พื้นที่จัดเก็บ';

  @override
  String get totalCacheSize => 'ขนาดแคชทั้งหมด';

  @override
  String get imageCache => 'แคชรูปภาพ';

  @override
  String get voiceMessagesCache => 'ข้อความเสียง';

  @override
  String get videoCache => 'แคชวิดีโอ';

  @override
  String get otherCache => 'แคชอื่นๆ';

  @override
  String get autoDownloadMedia => 'ดาวน์โหลดสื่ออัตโนมัติ';

  @override
  String get currentNetwork => 'เครือข่ายปัจจุบัน';

  @override
  String get images => 'รูปภาพ';

  @override
  String get videos => 'วิดีโอ';

  @override
  String get voiceMessagesShort => 'ข้อความเสียง';

  @override
  String get documentsLabel => 'เอกสาร';

  @override
  String get wifiOnly => 'WiFi เท่านั้น';

  @override
  String get never => 'ไม่เลย';

  @override
  String get clearAllCache => 'ล้างแคชทั้งหมด';

  @override
  String get allCache => 'แคชทั้งหมด';

  @override
  String get clearAllCacheConfirmation => 'การดำเนินการนี้จะลบรูปภาพ ข้อความเสียง วิดีโอ และไฟล์อื่นๆ ที่แคชไว้ทั้งหมด แอปอาจโหลดเนื้อหาช้าลงชั่วคราว';

  @override
  String clearCacheConfirmationFor(String category) {
    return 'ล้าง$category?';
  }

  @override
  String storageToFree(String size) {
    return '$size จะถูกปลดปล่อย';
  }

  @override
  String get calculating => 'กำลังคำนวณ...';

  @override
  String get noDataToShow => 'ไม่มีข้อมูลที่จะแสดง';

  @override
  String get profileCompletion => 'ความสมบูรณ์ของโปรไฟล์';

  @override
  String get justGettingStarted => 'เพิ่งเริ่มต้น';

  @override
  String get lookingGood => 'ดูดี!';

  @override
  String get almostThere => 'เกือบเสร็จแล้ว!';

  @override
  String addMissingFields(String fields, Object field) {
    return 'เพิ่ม $field เพื่อให้โปรไฟล์สมบูรณ์';
  }

  @override
  String get profilePicture => 'รูปโปรไฟล์';

  @override
  String get nativeSpeaker => 'เจ้าของภาษา';

  @override
  String peopleInterestedInTopic(Object count) {
    return '$count คนสนใจ';
  }

  @override
  String get beFirstToAddTopic => 'เป็นคนแรกที่เพิ่มหัวข้อนี้!';

  @override
  String get recentMoments => 'โมเมนต์ล่าสุด';

  @override
  String get seeAll => 'ดูทั้งหมด';

  @override
  String get study => 'เรียน';

  @override
  String get followerMoments => 'โมเมนต์จากผู้ติดตาม';

  @override
  String get whenPeopleYouFollowPost => 'เมื่อคนที่คุณติดตามโพสต์โมเมนต์ใหม่';

  @override
  String get noNotificationsYet => 'ยังไม่มีการแจ้งเตือน';

  @override
  String get whenYouGetNotifications => 'เมื่อคุณได้รับการแจ้งเตือน จะแสดงที่นี่';

  @override
  String get failedToLoadNotifications => 'โหลดการแจ้งเตือนไม่สำเร็จ';

  @override
  String get clearAllNotificationsConfirm => 'คุณแน่ใจหรือไม่ว่าต้องการลบการแจ้งเตือนทั้งหมด? การดำเนินการนี้ไม่สามารถยกเลิกได้';

  @override
  String get tapToChange => 'แตะเพื่อเปลี่ยน';

  @override
  String get noPictureSet => 'ไม่มีรูปภาพ';

  @override
  String get nameAndGender => 'ชื่อและเพศ';

  @override
  String get languageLevel => 'ระดับภาษา';

  @override
  String get personalInformation => 'ข้อมูลส่วนตัว';

  @override
  String get mbti => 'MBTI';

  @override
  String get topicsOfInterest => 'หัวข้อที่สนใจ';

  @override
  String get levelBeginner => 'เริ่มต้น';

  @override
  String get levelElementary => 'พื้นฐาน';

  @override
  String get levelIntermediate => 'ปานกลาง';

  @override
  String get levelUpperIntermediate => 'ปานกลางสูง';

  @override
  String get levelAdvanced => 'ขั้นสูง';

  @override
  String get levelProficient => 'เชี่ยวชาญ';

  @override
  String get selectYourLevel => 'เลือกระดับของคุณ';

  @override
  String howWellDoYouSpeak(String language) {
    return 'คุณพูด$languageได้ดีแค่ไหน?';
  }

  @override
  String get theLanguage => 'ภาษา';

  @override
  String languageLevelSetTo(String level) {
    return 'ระดับภาษาตั้งเป็น $level';
  }

  @override
  String get failedToUpdate => 'อัปเดตไม่สำเร็จ';

  @override
  String get profileUpdatedSuccessfully => 'อัปเดตโปรไฟล์สำเร็จ';

  @override
  String get genderRequired => 'เพศ (จำเป็น)';

  @override
  String get editHometown => 'แก้ไขบ้านเกิด';

  @override
  String get useCurrentLocation => 'ใช้ตำแหน่งปัจจุบัน';

  @override
  String get detecting => 'กำลังตรวจจับ...';

  @override
  String get getCurrentLocation => 'รับตำแหน่งปัจจุบัน';

  @override
  String get country => 'ประเทศ';

  @override
  String get city => 'เมือง';

  @override
  String get coordinates => 'พิกัด';

  @override
  String get noLocationDetectedYet => 'ยังไม่พบตำแหน่ง';

  @override
  String get detected => 'ตรวจพบ';

  @override
  String get savedHometown => 'บันทึกบ้านเกิดแล้ว';

  @override
  String get locationServicesDisabled => 'บริการตำแหน่งถูกปิด';

  @override
  String get locationPermissionPermanentlyDenied => 'สิทธิ์ตำแหน่งถูกปฏิเสธ';

  @override
  String get unknown => 'ไม่ทราบ';

  @override
  String get editBio => 'แก้ไขประวัติ';

  @override
  String get bioUpdatedSuccessfully => 'อัปเดตประวัติสำเร็จ';

  @override
  String get tellOthersAboutYourself => 'บอกเล่าเกี่ยวกับตัวคุณ...';

  @override
  String charactersCount(int count) {
    return '$count/500 ตัวอักษร';
  }

  @override
  String get selectYourMbti => 'เลือก MBTI ของคุณ';

  @override
  String get myBloodType => 'กรุ๊ปเลือดของฉัน';

  @override
  String get pleaseSelectABloodType => 'กรุณาเลือกกรุ๊ปเลือด';

  @override
  String get bloodTypeSavedSuccessfully => 'บันทึกกรุ๊ปเลือดสำเร็จ';

  @override
  String get hometownSavedSuccessfully => 'บันทึกบ้านเกิดสำเร็จ';

  @override
  String get nativeLanguageRequired => 'ภาษาแม่ (จำเป็น)';

  @override
  String get languageToLearnRequired => 'ภาษาที่เรียน (จำเป็น)';

  @override
  String get nativeLanguageCannotBeSame => 'ภาษาแม่ไม่สามารถเหมือนภาษาที่เรียน';

  @override
  String get learningLanguageCannotBeSame => 'ภาษาที่เรียนไม่สามารถเหมือนภาษาแม่';

  @override
  String get pleaseSelectALanguage => 'กรุณาเลือกภาษา';

  @override
  String get editInterests => 'แก้ไขความสนใจ';

  @override
  String maxTopicsAllowed(int count) {
    return 'สูงสุด $count หัวข้อ';
  }

  @override
  String get topicsUpdatedSuccessfully => 'อัปเดตหัวข้อสำเร็จ!';

  @override
  String get failedToUpdateTopics => 'อัปเดตหัวข้อไม่สำเร็จ';

  @override
  String selectedCount(int count, int max) {
    return '$count/$max ที่เลือก';
  }

  @override
  String get profilePictures => 'รูปโปรไฟล์';

  @override
  String get addImages => 'เพิ่มรูปภาพ';

  @override
  String get selectUpToImages => 'เลือกได้สูงสุด 5 รูป';

  @override
  String get takeAPhoto => 'ถ่ายรูป';

  @override
  String get removeImage => 'ลบรูปภาพ';

  @override
  String get removeImageConfirm => 'ลบรูปนี้?';

  @override
  String get removeAll => 'ลบทั้งหมด';

  @override
  String get removeAllSelectedImages => 'ลบรูปที่เลือกทั้งหมด';

  @override
  String get removeAllSelectedImagesConfirm => 'ลบรูปที่เลือกทั้งหมด?';

  @override
  String get yourProfilePictureWillBeKept => 'รูปโปรไฟล์ปัจจุบันจะถูกเก็บไว้';

  @override
  String get removeAllImages => 'ลบรูปทั้งหมด';

  @override
  String get removeAllImagesConfirm => 'ลบรูปโปรไฟล์ทั้งหมด?';

  @override
  String get currentImages => 'รูปปัจจุบัน';

  @override
  String get newImages => 'รูปใหม่';

  @override
  String get addMoreImages => 'เพิ่มรูปเพิ่มเติม';

  @override
  String uploadImages(int count) {
    return 'อัปโหลด $count รูป';
  }

  @override
  String get imageRemovedSuccessfully => 'ลบรูปสำเร็จ';

  @override
  String get imagesUploadedSuccessfully => 'อัปโหลดรูปสำเร็จ';

  @override
  String get selectedImagesCleared => 'ล้างรูปที่เลือกแล้ว';

  @override
  String get extraImagesRemovedSuccessfully => 'ลบรูปเพิ่มเติมสำเร็จ';

  @override
  String get mustKeepAtLeastOneProfilePicture => 'ต้องเก็บรูปโปรไฟล์อย่างน้อย 1 รูป';

  @override
  String get noProfilePicturesToRemove => 'ไม่มีรูปโปรไฟล์ให้ลบ';

  @override
  String get authenticationTokenNotFound => 'ไม่พบโทเค็น';

  @override
  String get saveChangesQuestion => 'บันทึกการเปลี่ยนแปลง?';

  @override
  String youHaveUnuploadedImages(int count) {
    return '$count รูปยังไม่ได้อัปโหลด อัปโหลดเลย?';
  }

  @override
  String get discard => 'ยกเลิก';

  @override
  String get upload => 'อัปโหลด';

  @override
  String maxImagesInfo(int max, int current) {
    return 'สูงสุด $max รูป ปัจจุบัน: $current/$max';
  }

  @override
  String canOnlyAddMoreImages(int count, int max) {
    return 'เพิ่มได้อีก $count รูป สูงสุด $max';
  }

  @override
  String get maxImagesPerUpload => 'สูงสุด 5 รูปต่อครั้ง';

  @override
  String canOnlyHaveMaxImages(int max) {
    return 'สูงสุด $max รูป';
  }

  @override
  String get imageSizeExceedsLimit => 'ขนาดเกิน 10MB';

  @override
  String get unsupportedImageFormat => 'รูปแบบไม่รองรับ';

  @override
  String get pleaseSelectAtLeastOneImage => 'กรุณาเลือกอย่างน้อย 1 รูป';

  @override
  String get basicInformation => 'ข้อมูลพื้นฐาน';

  @override
  String get languageToLearn => 'ภาษาที่เรียน';

  @override
  String get hometown => 'บ้านเกิด';

  @override
  String get characters => 'ตัวอักษร';

  @override
  String get failedToLoadLanguages => 'โหลดภาษาไม่สำเร็จ';

  @override
  String get studyHub => 'ศูนย์การเรียนรู้';

  @override
  String get dailyLearningJourney => 'เส้นทางการเรียนรู้ประจำวันของคุณ';

  @override
  String get learnTab => 'เรียน';

  @override
  String get aiTools => 'เครื่องมือ AI';

  @override
  String get streak => 'ความต่อเนื่อง';

  @override
  String get lessons => 'บทเรียน';

  @override
  String get words => 'คำศัพท์';

  @override
  String get quickActions => 'การดำเนินการด่วน';

  @override
  String get review => 'ทบทวน';

  @override
  String wordsDue(int count) {
    return '$count คำที่ต้องทบทวน';
  }

  @override
  String get addWords => 'เพิ่มคำศัพท์';

  @override
  String get buildVocabulary => 'สร้างคลังคำศัพท์';

  @override
  String get practiceWithAI => 'ฝึกกับ AI';

  @override
  String get aiPracticeDescription => 'แชท ควิซ ไวยากรณ์ และการออกเสียง';

  @override
  String get dailyChallenges => 'ความท้าทายประจำวัน';

  @override
  String get allChallengesCompleted => 'ทำความท้าทายครบทุกข้อแล้ว!';

  @override
  String get continueLearning => 'เรียนต่อ';

  @override
  String get structuredLearningPath => 'เส้นทางการเรียนรู้ที่มีโครงสร้าง';

  @override
  String get vocabulary => 'คำศัพท์';

  @override
  String get yourWordCollection => 'คอลเลกชันคำศัพท์ของคุณ';

  @override
  String get achievements => 'ความสำเร็จ';

  @override
  String get badgesAndMilestones => 'เหรียญและเหตุการณ์สำคัญ';

  @override
  String get failedToLoadLearningData => 'โหลดข้อมูลการเรียนรู้ไม่สำเร็จ';

  @override
  String get startYourJourney => 'เริ่มต้นการเดินทางของคุณ!';

  @override
  String get startJourneyDescription => 'ทำบทเรียนให้เสร็จ สร้างคลังคำศัพท์\nและติดตามความก้าวหน้าของคุณ';

  @override
  String levelN(int level) {
    return 'ระดับ $level';
  }

  @override
  String xpEarned(int xp) {
    return 'ได้รับ $xp XP';
  }

  @override
  String nextLevel(int level) {
    return 'ถัดไป: ระดับ $level';
  }

  @override
  String xpToGo(int xp) {
    return 'เหลืออีก $xp XP';
  }

  @override
  String get aiConversationPartner => 'เพื่อนคู่สนทนา AI';

  @override
  String get practiceWithAITutor => 'ฝึกพูดกับครูสอน AI ของคุณ';

  @override
  String get startConversation => 'เริ่มการสนทนา';

  @override
  String get aiFeatures => 'ฟีเจอร์ AI';

  @override
  String get aiLessons => 'บทเรียน AI';

  @override
  String get learnWithAI => 'เรียนกับ AI';

  @override
  String get grammar => 'ไวยากรณ์';

  @override
  String get checkWriting => 'ตรวจการเขียน';

  @override
  String get pronunciation => 'การออกเสียง';

  @override
  String get improveSpeaking => 'พัฒนาการพูด';

  @override
  String get translation => 'การแปล';

  @override
  String get smartTranslate => 'แปลอัจฉริยะ';

  @override
  String get aiQuizzes => 'ควิซ AI';

  @override
  String get testKnowledge => 'ทดสอบความรู้';

  @override
  String get lessonBuilder => 'สร้างบทเรียน';

  @override
  String get customLessons => 'บทเรียนที่กำหนดเอง';

  @override
  String get yourAIProgress => 'ความก้าวหน้า AI ของคุณ';

  @override
  String get quizzes => 'ควิซ';

  @override
  String get avgScore => 'คะแนนเฉลี่ย';

  @override
  String get focusAreas => 'พื้นที่ที่ต้องเน้น';

  @override
  String accuracyPercent(String accuracy) {
    return 'ความแม่นยำ $accuracy%';
  }

  @override
  String get practice => 'ฝึกฝน';

  @override
  String get browse => 'เรียกดู';

  @override
  String get noRecommendedLessons => 'ไม่มีบทเรียนที่แนะนำ';

  @override
  String get noLessonsFound => 'ไม่พบบทเรียน';

  @override
  String get createCustomLessonDescription => 'สร้างบทเรียนที่กำหนดเองด้วย AI';

  @override
  String get createLessonWithAI => 'สร้างบทเรียนด้วย AI';

  @override
  String get allLevels => 'ทุกระดับ';

  @override
  String get levelA1 => 'A1 ผู้เริ่มต้น';

  @override
  String get levelA2 => 'A2 ขั้นต้น';

  @override
  String get levelB1 => 'B1 ระดับกลาง';

  @override
  String get levelB2 => 'B2 กลาง-สูง';

  @override
  String get levelC1 => 'C1 ขั้นสูง';

  @override
  String get levelC2 => 'C2 เชี่ยวชาญ';

  @override
  String get failedToLoadLessons => 'โหลดบทเรียนไม่สำเร็จ';

  @override
  String get pin => 'ปักหมุด';

  @override
  String get unpin => 'เลิกปักหมุด';

  @override
  String get editMessage => 'แก้ไขข้อความ';

  @override
  String get enterMessage => 'พิมพ์ข้อความ...';

  @override
  String get deleteMessageTitle => 'ลบข้อความ';

  @override
  String get actionCannotBeUndone => 'การดำเนินการนี้ไม่สามารถยกเลิกได้';

  @override
  String get onlyRemovesFromDevice => 'ลบจากอุปกรณ์ของคุณเท่านั้น';

  @override
  String get availableWithinOneHour => 'ใช้ได้ภายใน 1 ชั่วโมงเท่านั้น';

  @override
  String get available => 'พร้อมใช้งาน';

  @override
  String get forwardMessage => 'ส่งต่อข้อความ';

  @override
  String get selectUsersToForward => 'เลือกผู้ใช้ที่จะส่งต่อ:';

  @override
  String forwardCount(int count) {
    return 'ส่งต่อ ($count)';
  }

  @override
  String get pinnedMessage => 'ข้อความที่ปักหมุด';

  @override
  String get photoMedia => 'รูปภาพ';

  @override
  String get videoMedia => 'วิดีโอ';

  @override
  String get voiceMessageMedia => 'ข้อความเสียง';

  @override
  String get documentMedia => 'เอกสาร';

  @override
  String get locationMedia => 'ตำแหน่ง';

  @override
  String get stickerMedia => 'สติกเกอร์';

  @override
  String get smileys => 'สไมลี่';

  @override
  String get emotions => 'อารมณ์';

  @override
  String get handGestures => 'ท่ามือ';

  @override
  String get hearts => 'หัวใจ';

  @override
  String get tapToSayHi => 'แตะเพื่อทักทาย!';

  @override
  String get sendWaveToStart => 'ส่งการทักทายเพื่อเริ่มแชท';

  @override
  String get documentMustBeUnder50MB => 'เอกสารต้องมีขนาดไม่เกิน 50MB';

  @override
  String get editWithin15Minutes => 'แก้ไขข้อความได้ภายใน 15 นาทีเท่านั้น';

  @override
  String messageForwardedTo(int count) {
    return 'ส่งต่อข้อความไปยัง $count ผู้ใช้';
  }

  @override
  String get failedToLoadUsers => 'โหลดผู้ใช้ไม่สำเร็จ';

  @override
  String get voice => 'เสียง';

  @override
  String get searchGifs => 'ค้นหา GIF...';

  @override
  String get trendingGifs => 'กำลังมาแรง';

  @override
  String get poweredByGiphy => 'Powered by GIPHY';

  @override
  String get gif => 'GIF';

  @override
  String get noGifsFound => 'ไม่พบ GIF';

  @override
  String get failedToLoadGifs => 'โหลด GIF ไม่สำเร็จ';

  @override
  String get gifSent => 'GIF';

  @override
  String get filterCommunities => 'กรอง';

  @override
  String get reset => 'รีเซ็ต';

  @override
  String get findYourPerfect => 'ค้นหา';

  @override
  String get languagePartner => 'คู่ฝึกภาษาที่สมบูรณ์แบบ';

  @override
  String get learningLanguageLabel => 'ภาษาที่กำลังเรียน';

  @override
  String get ageRange => 'ช่วงอายุ';

  @override
  String get genderPreference => 'ความต้องการเพศ';

  @override
  String get any => 'ทั้งหมด';

  @override
  String get showNewUsersSubtitle => 'แสดงผู้ใช้ที่เข้าร่วมใน 6 วันที่ผ่านมา';

  @override
  String get autoDetectLocation => 'ตรวจจับตำแหน่งของฉันอัตโนมัติ';

  @override
  String get selectCountry => 'เลือกประเทศ';

  @override
  String get anyCountry => 'ทุกประเทศ';

  @override
  String get loadingLanguages => 'กำลังโหลดภาษา...';

  @override
  String minAge(int age) {
    return 'ต่ำสุด: $age';
  }

  @override
  String maxAge(int age) {
    return 'สูงสุด: $age';
  }

  @override
  String get captionRequired => 'จำเป็นต้องมีคำบรรยาย';

  @override
  String captionTooLong(int maxLength) {
    return 'คำบรรยายต้องมี $maxLength ตัวอักษรหรือน้อยกว่า';
  }

  @override
  String get maximumImagesReached => 'ถึงจำนวนรูปภาพสูงสุดแล้ว';

  @override
  String maximumImagesReachedDescription(int maxImages) {
    return 'คุณสามารถอัปโหลดได้สูงสุด $maxImages รูปต่อโมเมนต์';
  }

  @override
  String maximumImagesAddedPartial(int maxImages, int added) {
    return 'สูงสุด $maxImages รูป เพิ่มได้เพียง $added รูปเท่านั้น';
  }

  @override
  String get locationAccessRestricted => 'การเข้าถึงตำแหน่งถูกจำกัด';

  @override
  String get locationPermissionNeeded => 'ต้องการสิทธิ์การเข้าถึงตำแหน่ง';

  @override
  String get addToYourMoment => 'เพิ่มในโมเมนต์ของคุณ';

  @override
  String get categoryLabel => 'หมวดหมู่';

  @override
  String get languageLabel => 'ภาษา';

  @override
  String get scheduleOptional => 'กำหนดเวลา (ไม่บังคับ)';

  @override
  String get scheduleForLater => 'กำหนดเวลาสำหรับภายหลัง';

  @override
  String get addMore => 'เพิ่มเติม';

  @override
  String get howAreYouFeeling => 'คุณรู้สึกอย่างไร?';

  @override
  String get pleaseWaitOptimizingVideo => 'กรุณารอสักครู่ขณะเราปรับปรุงวิดีโอของคุณ';

  @override
  String unsupportedVideoFormat(String formats) {
    return 'รูปแบบไม่รองรับ ใช้: $formats';
  }

  @override
  String get chooseBackground => 'เลือกพื้นหลัง';

  @override
  String likedByXPeople(int count) {
    return 'ถูกใจโดย $count คน';
  }

  @override
  String xComments(int count) {
    return '$count ความคิดเห็น';
  }

  @override
  String get oneComment => '1 ความคิดเห็น';

  @override
  String get addAComment => 'เพิ่มความคิดเห็น...';

  @override
  String viewXReplies(int count) {
    return 'ดู $count การตอบกลับ';
  }

  @override
  String seenByX(int count) {
    return 'เห็นโดย $count';
  }

  @override
  String xHoursAgo(int count) {
    return '$count ชม.ที่แล้ว';
  }

  @override
  String xMinutesAgo(int count) {
    return '$count นาทีที่แล้ว';
  }

  @override
  String get repliedToYourStory => 'ตอบกลับสตอรี่ของคุณ';

  @override
  String mentionedYouInComment(String name) {
    return '$name กล่าวถึงคุณในความคิดเห็น';
  }

  @override
  String repliedToYourComment(String name) {
    return '$name ตอบกลับความคิดเห็นของคุณ';
  }

  @override
  String reactedToYourComment(String name) {
    return '$name รีแอคชันความคิดเห็นของคุณ';
  }

  @override
  String get addReaction => 'เพิ่มรีแอคชัน';

  @override
  String get attachImage => 'แนบรูปภาพ';

  @override
  String get pickGif => 'เลือก GIF';

  @override
  String get textStory => 'ข้อความ';

  @override
  String get typeYourStory => 'เขียนสตอรี่ของคุณ...';

  @override
  String get selectBackground => 'เลือกพื้นหลัง';

  @override
  String get highlightsTitle => 'ไฮไลท์';

  @override
  String get highlightTitle => 'ชื่อไฮไลท์';

  @override
  String get createNewHighlight => 'สร้างใหม่';

  @override
  String get selectStories => 'เลือกสตอรี่';

  @override
  String get selectCover => 'เลือกปก';

  @override
  String get addText => 'เพิ่มข้อความ';

  @override
  String get fontStyleLabel => 'รูปแบบตัวอักษร';

  @override
  String get textColorLabel => 'สีข้อความ';

  @override
  String get dragToDelete => 'ลากมาที่นี่เพื่อลบ';

  @override
  String get noBlockedUsers => 'No blocked users';

  @override
  String get usersYouBlockWillAppearHere => 'Users you block will appear here';

  @override
  String unblockConfirm(String name) {
    return 'Are you sure you want to unblock $name?';
  }

  @override
  String reasonLabel(String reason) {
    return 'Reason: $reason';
  }

  @override
  String blockedAgo(String time) {
    return 'Blocked $time';
  }

  @override
  String errorLoadingBlockedUsers(String error) {
    return 'Error loading blocked users: $error';
  }

  @override
  String get logoutConfirmMessage => 'Are you sure you want to logout from BanaTalk?';

  @override
  String get loggingOut => 'Logging out...';

  @override
  String get quietHours => 'Quiet Hours';

  @override
  String get quietHoursEnable => 'Enable Quiet Hours';

  @override
  String get quietHoursSubtitle => 'Pause non-urgent notifications during a time window';

  @override
  String get quietHoursStart => 'Start time';

  @override
  String get quietHoursEnd => 'End time';

  @override
  String get quietHoursAllowUrgent => 'Allow urgent notifications';

  @override
  String get quietHoursAllowUrgentSubtitle => 'Calls and messages from VIP partners can still come through';

  @override
  String get silencedByQuietHours => 'Silenced by Quiet Hours';

  @override
  String get silencedByCap => 'Silenced by daily limit';

  @override
  String get momentUpdatedSuccessfully => 'อัปเดตโมเมนต์สำเร็จ';

  @override
  String get failedToDeleteMoment => 'ลบโมเมนต์ไม่สำเร็จ';

  @override
  String get failedToUpdateMoment => 'อัปเดตโมเมนต์ไม่สำเร็จ';

  @override
  String get mbtiUpdatedSuccessfully => 'อัปเดต MBTI สำเร็จ';

  @override
  String get pleaseSelectMbti => 'กรุณาเลือกประเภท MBTI';

  @override
  String get languageUpdatedSuccessfully => 'อัปเดตภาษาสำเร็จ';

  @override
  String get bioHintCard => 'ประวัติที่ดีช่วยให้ผู้อื่นเชื่อมต่อกับคุณได้ แบ่งปันความสนใจ ภาษา หรือสิ่งที่คุณกำลังมองหา';

  @override
  String get bioCounterStartWriting => 'เริ่มเขียน...';

  @override
  String get bioCounterABitMore => 'เขียนเพิ่มอีกนิดจะดีมาก';

  @override
  String get bioCounterAlmostAtLimit => 'ใกล้ถึงขีดจำกัดแล้ว';

  @override
  String get bioCounterTooLong => 'ยาวเกินไป';

  @override
  String get bioQuickStarters => 'เริ่มต้นอย่างรวดเร็ว';

  @override
  String get rhPositive => 'Rh บวก';

  @override
  String get rhNegative => 'Rh ลบ';

  @override
  String get rhPositiveDesc => 'พบมากที่สุด';

  @override
  String get rhNegativeDesc => 'ผู้บริจาคสากล / หายาก';

  @override
  String get yourBloodType => 'หมู่เลือดของคุณ';

  @override
  String get noBloodTypeSelected => 'ยังไม่ได้เลือกหมู่เลือด';

  @override
  String get tapTypeBelow => 'แตะประเภทด้านล่าง';

  @override
  String get tapButtonToDetectLocation => 'แตะปุ่มด้านล่างเพื่อตรวจจับตำแหน่งปัจจุบันของคุณ';

  @override
  String currentAddressLabel(String address) {
    return 'ปัจจุบัน: $address';
  }

  @override
  String get onlyCityCountryShown => 'ผู้อื่นเห็นเพียงเมืองและประเทศของคุณ พิกัดที่แน่นอนจะยังคงเป็นความลับ';

  @override
  String get updateLocationCta => 'อัปเดตตำแหน่ง';

  @override
  String get enterYourName => 'กรอกชื่อของคุณ';

  @override
  String get unsavedChanges => 'คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก';
}
