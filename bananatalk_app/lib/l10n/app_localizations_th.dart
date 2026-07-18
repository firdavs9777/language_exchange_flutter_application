// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appName => 'Bananatalk';

  @override
  String get aiStudyPromoTitle => 'ฝึกฝนด้วยสถานการณ์ AI';

  @override
  String get aiStudyPromoBody => 'สวมบทบาทบทสนทนาในชีวิตจริงกับติวเตอร์ AI และสร้างความมั่นใจในการพูด';

  @override
  String get aiStudyPromoCTA => 'ลองสถานการณ์';

  @override
  String get aiStudyPromoDismiss => 'ไว้ก่อน';

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
  String get loadMoreComments => 'โหลดความคิดเห็นเพิ่มเติม';

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
  String get deleteComment => 'ลบความคิดเห็น?';

  @override
  String get commentDeleted => 'ลบความคิดเห็นแล้ว';

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
  String get aiTutorChangePersona => 'เปลี่ยนติวเตอร์ AI';

  @override
  String get aiTutorChangePersonaSubtitle => 'เปลี่ยนเป็น Nana, Sensei หรือ Riko';

  @override
  String aiTutorHeroTitleSet(String name) {
    return 'ติวเตอร์ AI ของคุณ · $name';
  }

  @override
  String get aiTutorHeroTitleNew => 'พบกับติวเตอร์ AI ของคุณ';

  @override
  String get aiTutorHeroSubtitleSet => 'แตะเพื่อแชทหรือดูแผนวันนี้';

  @override
  String aiTutorHeroSubtitleLast(String summary) {
    return 'ครั้งที่แล้ว: $summary';
  }

  @override
  String get aiTutorHeroSubtitleNew => 'เลือกตัวละคร — Nana, Sensei หรือ Riko';

  @override
  String get aiTutorChipChat => 'แชท';

  @override
  String get aiTutorChipRoleplay => 'เล่นบทบาท';

  @override
  String get aiTutorChipStory => 'เรื่องราว';

  @override
  String get aiTutorChipPhoto => 'รูปภาพ';

  @override
  String get aiToolsMoreSection => 'เครื่องมือ AI เพิ่มเติม';

  @override
  String get aiConversationPartnerTile => 'การสนทนา AI';

  @override
  String get aiConversationPartnerTileSubtitle => 'ฝึกฝนกับคู่หู AI';

  @override
  String get aiTutorPickerTitle => 'เลือกติวเตอร์ AI ของคุณ';

  @override
  String get aiTutorPickerHeader => 'คุณอยากเรียนกับใคร?';

  @override
  String get aiTutorPickerSubtitle => 'คุณสามารถเปลี่ยนได้ตลอดในการตั้งค่า';

  @override
  String get aiTutorPersonaNanaTagline => 'อบอุ่น + ให้กำลังใจ';

  @override
  String get aiTutorPersonaNanaSample => 'ฉันจะคอยเชียร์ ไม่กดดัน';

  @override
  String get aiTutorPersonaSenseiTagline => 'แม่นยำ + เน้นสอบ';

  @override
  String get aiTutorPersonaSenseiSample => 'เราจะเก่งกฎไวยากรณ์';

  @override
  String get aiTutorPersonaRikoTagline => 'ขี้เล่น + กันเอง';

  @override
  String get aiTutorPersonaRikoSample => 'มาสนุกและเรียนกัน';

  @override
  String aiTutorPickerSaveError(String error) {
    return 'บันทึกไม่ได้: $error';
  }

  @override
  String get aiTutorHomeTitle => 'ติวเตอร์ AI';

  @override
  String get aiTutorHomeChangeTutor => 'เปลี่ยนติวเตอร์';

  @override
  String get aiTutorHomeGreetingDefault => 'สวัสดี! พร้อมเรียนด้วยกันไหม?';

  @override
  String get aiTutorHomeTodaysPlan => 'แผนวันนี้';

  @override
  String get aiTutorHomePlanEmpty => 'วันนี้ไม่มีแผน — เริ่มแชทเพื่อเริ่มต้น';

  @override
  String get aiTutorHomeStartChat => 'เริ่มแชท';

  @override
  String get aiTutorHomeRecent => 'ล่าสุด';

  @override
  String get aiTutorHomePracticeScenarios => 'สถานการณ์ฝึก';

  @override
  String get aiTutorHomePracticeScenariosSubtitle => 'สวมบทบาทบทสนทนาจริง — ร้านอาหาร, สัมภาษณ์, โรงแรม…';

  @override
  String get aiTutorHomeReadStory => 'อ่านเรื่อง';

  @override
  String get aiTutorHomeReadStorySubtitle => 'AI เขียนเรื่องสั้นจากคำศัพท์ของคุณ — พร้อมคำถามทำความเข้าใจ';

  @override
  String get aiTutorHomeDescribePhoto => 'อธิบายภาพ';

  @override
  String get aiTutorHomeDescribePhotoSubtitle => 'ถ่ายภาพแล้วอธิบาย — AI ประเมินคำศัพท์ + ไวยากรณ์';

  @override
  String get aiTutorChatTitle => 'แชทกับติวเตอร์';

  @override
  String get aiTutorChatVoiceOn => 'เปิดเสียง';

  @override
  String get aiTutorChatVoiceOff => 'ปิดเสียง';

  @override
  String get aiTutorChatStopRecording => 'หยุดบันทึก';

  @override
  String get aiTutorChatHoldToTalk => 'กดค้างเพื่อพูด';

  @override
  String get aiTutorChatTranscribing => 'กำลังถอดเสียง…';

  @override
  String get aiTutorChatListening => 'กำลังฟัง…';

  @override
  String get aiTutorChatInputHint => 'พิมพ์ข้อความ…';

  @override
  String get aiTutorChatTypeReplyHint => 'พิมพ์คำตอบ…';

  @override
  String get aiTutorChatMicPermissionDenied => 'ต้องอนุญาตไมโครโฟนสำหรับโหมดเสียง';

  @override
  String get aiTutorChatTranscribeFailed => 'ฟังไม่ทัน — ลองใหม่';

  @override
  String aiTutorChatStartFailed(String error) {
    return 'เริ่มไม่ได้: $error';
  }

  @override
  String get aiTutorRoleplayEnd => 'จบ';

  @override
  String aiTutorRoleplayEndFailed(String error) {
    return 'จบไม่ได้: $error';
  }

  @override
  String get aiTutorRoleplayDone => 'เสร็จ';

  @override
  String get aiTutorStoryTitle => 'อ่านเรื่อง';

  @override
  String get aiTutorStoryLength => 'ความยาว';

  @override
  String get aiTutorStoryTheme => 'ธีม';

  @override
  String aiTutorStoryWordCount(int count) {
    return '$count คำ';
  }

  @override
  String get aiTutorStoryWriting => 'กำลังเขียน…';

  @override
  String get aiTutorStoryGenerate => 'สร้างเรื่อง';

  @override
  String aiTutorStoryGenerateFailed(String error) {
    return 'สร้างไม่ได้: $error';
  }

  @override
  String aiTutorStoryWordCountHint(int n) {
    return 'AI จะใช้คำสูงสุด $n คำจากรายการของคุณ';
  }

  @override
  String get aiTutorStoryThemeFree => 'อิสระ';

  @override
  String get aiTutorStoryThemeAdventure => 'ผจญภัย';

  @override
  String get aiTutorStoryThemeMystery => 'ลึกลับ';

  @override
  String get aiTutorStoryThemeRomance => 'โรแมนซ์';

  @override
  String get aiTutorStoryThemeSciFi => 'ไซไฟ';

  @override
  String get aiTutorStoryThemeSliceOfLife => 'ชีวิตประจำวัน';

  @override
  String get aiTutorStoryReaderTitle => 'เรื่องราว';

  @override
  String get aiTutorStoryReaderVocab => 'คำศัพท์';

  @override
  String get aiTutorStoryReaderVocabUsed => 'คำศัพท์ที่ใช้';

  @override
  String aiTutorStoryReaderPart(int n) {
    return 'ส่วนที่ $n';
  }

  @override
  String get aiTutorStoryReaderWrongHint => 'ยังไม่ถูก — ไปต่อ';

  @override
  String get aiTutorStoryReaderNiceWork => 'ทำได้ดี!';

  @override
  String aiTutorStoryReaderScore(int correct, int total) {
    return 'คุณตอบถูก $correct/$total ข้อ';
  }

  @override
  String get aiTutorStoryReaderDone => 'เสร็จ';

  @override
  String get aiTutorImageVocabTitle => 'อธิบายภาพ';

  @override
  String get aiTutorImagePickHeader => 'เลือกภาพเพื่ออธิบาย';

  @override
  String get aiTutorImagePickSubtitle => 'AI จะให้คำชี้แจงในภาษาเป้าหมาย แล้วประเมินคำอธิบายของคุณ';

  @override
  String get aiTutorImagePickCamera => 'กล้อง';

  @override
  String get aiTutorImagePickGallery => 'แกลเลอรี';

  @override
  String aiTutorImagePickError(String error) {
    return 'เปิดรูปไม่ได้: $error';
  }

  @override
  String get aiTutorImageDescriptionHint => 'พิมพ์คำอธิบาย…';

  @override
  String get aiTutorImageDifferentPhoto => 'ภาพอื่น';

  @override
  String get aiTutorImageSubmit => 'ส่ง';

  @override
  String get aiTutorImageGrammarNotes => 'บันทึกไวยากรณ์';

  @override
  String get aiTutorImageThingsYouMissed => 'สิ่งที่พลาดไป';

  @override
  String get aiTutorImageTryAnother => 'ลองภาพอื่น';

  @override
  String get aiTutorCardQuiz => 'แบบทดสอบ';

  @override
  String get aiTutorCardVocab => 'คำศัพท์';

  @override
  String get aiTutorCardGrammar => 'ไวยากรณ์';

  @override
  String get aiTutorCardReviewDue => 'ถึงเวลาทบทวน';

  @override
  String get aiTutorCardMiniLesson => 'บทเรียนสั้น';

  @override
  String get aiTutorCardAddToVocab => 'เพิ่มคำศัพท์';

  @override
  String get aiTutorCardAddedToVocab => 'เพิ่มแล้ว';

  @override
  String get aiTutorCardAdding => 'กำลังเพิ่ม…';

  @override
  String aiTutorCardReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count การ์ดรอคุณ',
      one: '$count การ์ดรอคุณ',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorCardReviewNow => 'ทบทวนตอนนี้';

  @override
  String get aiTutorCardReviewStarting => 'กำลังเริ่ม…';

  @override
  String get aiTutorCardTryIt => 'ลอง';

  @override
  String get aiTutorCardPracticing => 'กำลังฝึก…';

  @override
  String aiTutorPlanSrsReview(int count, int done) {
    return 'ทบทวนการ์ด SRS $count ใบ ($done เสร็จ)';
  }

  @override
  String aiTutorPlanGrammar(String topic) {
    return 'ฝึก: $topic';
  }

  @override
  String aiTutorPlanChat(int min, int done) {
    return 'แชท $min นาที (ทำไป $done)';
  }

  @override
  String get aboutBananatalk => 'เกี่ยวกับ Bananatalk';

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
  String get banaTalk => 'Bananatalk';

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
  String get deletingYourAccountWillPermanentlyRemove => 'การลบบัญชีของคุณจะลบข้อมูลต่อไปนี้อย่างถาวร:\n\n• โปรไฟล์และข้อมูลส่วนตัวทั้งหมดของคุณ\n• ข้อความและบทสนทนาทั้งหมดของคุณ\n• โมเมนต์และสตอรี่ทั้งหมดของคุณ\n• การสมัครสมาชิก VIP ของคุณ (ไม่มีการคืนเงิน)\n• การเชื่อมต่อและผู้ติดตามทั้งหมดของคุณ\n\nไม่สามารถย้อนกลับการกระทำนี้ได้';

  @override
  String get clearAllNotifications => 'ล้างการแจ้งเตือนทั้งหมด?';

  @override
  String get clearAll => 'ล้างทั้งหมด';

  @override
  String get notificationDebug => 'ดีบักการแจ้งเตือน';

  @override
  String get markAllRead => 'ทำเครื่องหมายอ่านทั้งหมด';

  @override
  String get clearAll2 => 'ล้างทั้งหมด';

  @override
  String get emailAddress => 'ที่อยู่อีเมล';

  @override
  String get username => 'ชื่อผู้ใช้';

  @override
  String get alreadyHaveAnAccount => 'มีบัญชีแล้ว?';

  @override
  String get login2 => 'เข้าสู่ระบบ';

  @override
  String get selectYourNativeLanguage2 => 'เลือกภาษาแม่ของคุณ';

  @override
  String get whichLanguageDoYouWantToLearn2 => 'คุณต้องการเรียนภาษาอะไร?';

  @override
  String get selectYourGender2 => 'เลือกเพศของคุณ';

  @override
  String get dateFormat => 'ปปปป.ดด.วว';

  @override
  String get detectYourLocation2 => 'ตรวจจับตำแหน่งของคุณ';

  @override
  String get tapToUpdateLocation2 => 'แตะเพื่ออัปเดตตำแหน่ง';

  @override
  String get helpOthersFindYouNearby2 => 'ช่วยให้คนอื่นพบคุณในบริเวณใกล้เคียง';

  @override
  String get couldNotOpenLink => 'ไม่สามารถเปิดลิงก์';

  @override
  String get legalPrivacy2 => 'กฎหมายและความเป็นส่วนตัว';

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
  String get receiveEmailNotificationsFromBananatalk => 'รับการแจ้งเตือนอีเมลจาก Bananatalk';

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
  String get whenSomeoneFollowsYou2 => 'เมื่อมีคนติดตามคุณ';

  @override
  String get securityAlerts => 'การแจ้งเตือนความปลอดภัย';

  @override
  String get passwordLoginAlerts => 'การแจ้งเตือนรหัสผ่านและการเข้าสู่ระบบ';

  @override
  String get unblockUser2 => 'เลิกบล็อกผู้ใช้';

  @override
  String get blockedUsers2 => 'ผู้ใช้ที่ถูกบล็อก';

  @override
  String get finalWarning => 'คำเตือนสุดท้าย';

  @override
  String get deleteForever => 'ลบถาวร';

  @override
  String get deleteAccount2 => 'ลบบัญชี';

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
  String get reply2 => 'ตอบกลับ...';

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
  String get reviewStarted => 'เริ่มตรวจสอบแล้ว';

  @override
  String get reportResolved => 'รายงานได้รับการแก้ไขแล้ว';

  @override
  String get reportDismissed => 'ยกเลิกรายงานแล้ว';

  @override
  String get selectAction => 'เลือกการดำเนินการ';

  @override
  String get noViolation => 'ไม่มีการละเมิด';

  @override
  String get contentRemoved => 'เนื้อหาถูกลบแล้ว';

  @override
  String get userWarned => 'เตือนผู้ใช้แล้ว';

  @override
  String get userSuspended => 'ระงับผู้ใช้แล้ว';

  @override
  String get userBanned => 'แบนผู้ใช้แล้ว';

  @override
  String get addNotesOptional => 'เพิ่มหมายเหตุ (ไม่บังคับ)';

  @override
  String get enterModeratorNotes => 'ใส่หมายเหตุของผู้ดูแล...';

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
  String get myReports2 => 'รายงานของฉัน';

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
  String get reportUser2 => 'รายงานผู้ใช้';

  @override
  String get submitReport => 'ส่งรายงาน';

  @override
  String get addAQuestionAndAtLeast2Options => 'เพิ่มคำถามและตัวเลือกอย่างน้อย 2 ข้อ';

  @override
  String get addOption => 'เพิ่มตัวเลือก';

  @override
  String get anonymousVoting => 'การลงคะแนนแบบไม่ระบุตัวตน';

  @override
  String get create => 'สร้าง';

  @override
  String get typeYourAnswer => 'พิมพ์คำตอบของคุณ...';

  @override
  String get send2 => 'ส่ง';

  @override
  String get yourPrompt => 'คำถามของคุณ...';

  @override
  String get add2 => 'เพิ่ม';

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
  String get manageSubscriptionInSettings => 'หากต้องการยกเลิกการสมัครสมาชิก ให้ไปที่การตั้งค่า > [ชื่อของคุณ] > การสมัครสมาชิก บนอุปกรณ์ของคุณ';

  @override
  String get contactSupportToCancel => 'หากต้องการยกเลิกการสมัครสมาชิก โปรดติดต่อทีมสนับสนุนของเรา';

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
  String get pleaseRemoveImagesFirstToAddVideo => 'โปรดลบรูปภาพออกก่อนเพื่อเพิ่มวิดีโอ';

  @override
  String get unsupportedFormat => 'รูปแบบไม่รองรับ';

  @override
  String get errorProcessingVideo => 'เกิดข้อผิดพลาดในการประมวลผลวิดีโอ';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'โปรดลบรูปภาพออกก่อนเพื่อบันทึกวิดีโอ';

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
  String get failedToQueueUpload => 'ไม่สามารถจัดคิวการอัปโหลดได้';

  @override
  String get viewProfile => 'ดูโปรไฟล์';

  @override
  String get mediaLinksAndDocs => 'สื่อ ลิงก์ และเอกสาร';

  @override
  String get wallpaper => 'วอลเปเปอร์';

  @override
  String get userIdNotAvailable => 'ไม่มีรหัสผู้ใช้';

  @override
  String get cannotBlockYourself => 'ไม่สามารถบล็อกตัวเองได้';

  @override
  String get chatWallpaper => 'วอลเปเปอร์แชท';

  @override
  String get wallpaperSavedLocally => 'บันทึกวอลเปเปอร์ในเครื่องแล้ว';

  @override
  String get messageCopied => 'คัดลอกข้อความแล้ว';

  @override
  String get forwardFeatureComingSoon => 'ฟีเจอร์ส่งต่อกำลังจะมาเร็วๆ นี้';

  @override
  String get momentUnsaved => 'ลบออกจากที่บันทึกแล้ว';

  @override
  String get documentPickerComingSoon => 'ตัวเลือกเอกสารกำลังจะมาเร็วๆ นี้';

  @override
  String get contactSharingComingSoon => 'การแชร์ผู้ติดต่อกำลังจะมาเร็วๆ นี้';

  @override
  String get featureComingSoon => 'ฟีเจอร์เร็วๆ นี้';

  @override
  String get answerSent => 'ส่งคำตอบแล้ว!';

  @override
  String get noImagesAvailable => 'ไม่มีรูปภาพ';

  @override
  String get mentionPickerComingSoon => 'ตัวเลือกการกล่าวถึงกำลังจะมาเร็วๆ นี้';

  @override
  String get musicPickerComingSoon => 'ตัวเลือกเพลงกำลังจะมาเร็วๆ นี้';

  @override
  String get repostFeatureComingSoon => 'ฟีเจอร์รีโพสต์กำลังจะมาเร็วๆ นี้';

  @override
  String get addFriendsFromYourProfile => 'เพิ่มเพื่อนจากโปรไฟล์ของคุณ';

  @override
  String get quickReplyAdded => 'เพิ่มการตอบกลับด่วนแล้ว';

  @override
  String get quickReplyDeleted => 'ลบการตอบกลับด่วนแล้ว';

  @override
  String get linkCopied => 'คัดลอกลิงก์แล้ว!';

  @override
  String get maximumOptionsAllowed => 'อนุญาตสูงสุด 10 ตัวเลือก';

  @override
  String get minimumOptionsRequired => 'ต้องมีอย่างน้อย 2 ตัวเลือก';

  @override
  String get pleaseEnterAQuestion => 'โปรดใส่คำถาม';

  @override
  String get pleaseAddAtLeast2Options => 'โปรดเพิ่มตัวเลือกอย่างน้อย 2 ข้อ';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => 'โปรดเลือกคำตอบที่ถูกต้องสำหรับแบบทดสอบ';

  @override
  String get correctionSent => 'ส่งการแก้ไขแล้ว!';

  @override
  String get sort => 'เรียงลำดับ';

  @override
  String get savedMoments => 'โมเมนต์ที่บันทึก';

  @override
  String get unsave => 'ยกเลิกบันทึก';

  @override
  String get playingAudio => 'กำลังเล่นเสียง...';

  @override
  String get failedToGenerateQuiz => 'ไม่สามารถสร้างแบบทดสอบได้';

  @override
  String get failedToAddComment => 'ไม่สามารถเพิ่มความคิดเห็นได้';

  @override
  String get hello => 'สวัสดี!';

  @override
  String get howAreYou => 'สบายดีไหม?';

  @override
  String get cannotOpen => 'ไม่สามารถเปิดได้';

  @override
  String get errorOpeningLink => 'เกิดข้อผิดพลาดในการเปิดลิงก์';

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
  String get noForYouMomentsTitle => 'ยังไม่มีโมเมนต์';

  @override
  String get noForYouMomentsBody => 'ตอบคำถามประจำวันนี้เพื่อเริ่มบทสนทนา';

  @override
  String get noFollowingMomentsTitle => 'ยังไม่มีอะไรที่นี่';

  @override
  String get noFollowingMomentsBody => 'ติดตามผู้คนจากคอมมูนิตี้เพื่อดูโมเมนต์ของพวกเขาที่นี่';

  @override
  String get goToCommunity => 'ไปที่คอมมูนิตี้';

  @override
  String get unableToLoadMoments => 'ไม่สามารถโหลดโมเมนต์ได้';

  @override
  String get map => 'แผนที่';

  @override
  String get mapUnavailable => 'แผนที่ไม่พร้อมใช้งาน';

  @override
  String get location => 'ตำแหน่ง';

  @override
  String get unknownLocation => 'ไม่ทราบตำแหน่ง';

  @override
  String get noImagesAvailable2 => 'ไม่มีรูปภาพ';

  @override
  String get permissionsRequired => 'ต้องได้รับสิทธิ์อนุญาต';

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
  String get pleaseLoginToFollow => 'โปรดเข้าสู่ระบบเพื่อติดตามผู้ใช้';

  @override
  String get pleaseLoginToCall => 'โปรดเข้าสู่ระบบเพื่อโทร';

  @override
  String get cannotCallYourself => 'คุณไม่สามารถโทรหาตัวเองได้';

  @override
  String get failedToFollowUser => 'ไม่สามารถติดตามผู้ใช้ได้';

  @override
  String get failedToUnfollowUser => 'ไม่สามารถเลิกติดตามผู้ใช้ได้';

  @override
  String get areYouSureUnfollow => 'คุณแน่ใจหรือไม่ว่าต้องการเลิกติดตามผู้ใช้นี้?';

  @override
  String get areYouSureUnblock => 'คุณแน่ใจหรือไม่ว่าต้องการเลิกบล็อกผู้ใช้นี้?';

  @override
  String get youFollowed => 'คุณติดตาม';

  @override
  String get youUnfollowed => 'คุณเลิกติดตาม';

  @override
  String get alreadyFollowing => 'คุณติดตามอยู่แล้ว';

  @override
  String get soon => 'เร็วๆ นี้';

  @override
  String comingSoon(String feature) {
    return '$feature กำลังจะมาเร็วๆ นี้!';
  }

  @override
  String get muteNotifications => 'ปิดเสียงการแจ้งเตือน';

  @override
  String get unmuteNotifications => 'เปิดเสียงการแจ้งเตือน';

  @override
  String get operationCompleted => 'การดำเนินการเสร็จสมบูรณ์';

  @override
  String get couldNotOpenMaps => 'ไม่สามารถเปิดแผนที่ได้';

  @override
  String hasntSharedMoments(Object name) {
    return '$name ยังไม่ได้แชร์โมเมนต์ใดๆ';
  }

  @override
  String messageUser(String name) {
    return 'ส่งข้อความถึง $name';
  }

  @override
  String notFollowingUser(String name) {
    return 'คุณไม่ได้ติดตาม $name';
  }

  @override
  String youFollowedUser(String name) {
    return 'คุณติดตาม $name แล้ว';
  }

  @override
  String youUnfollowedUser(String name) {
    return 'คุณเลิกติดตาม $name แล้ว';
  }

  @override
  String unfollowUser(String name) {
    return 'เลิกติดตาม $name';
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
  String get maxTagsAllowed => 'อนุญาตสูงสุด 5 แท็ก';

  @override
  String maxImagesAllowed(int count) {
    return 'อนุญาตสูงสุด $count รูปภาพ';
  }

  @override
  String get pleaseRemoveImagesFirst => 'โปรดลบรูปภาพออกก่อนเพื่อเพิ่มวิดีโอ';

  @override
  String get exchange3MessagesBeforeCall => 'แลกเปลี่ยนข้อความอย่างน้อย 5 ข้อความก่อนโทร';

  @override
  String mediaWithUser(String name) {
    return 'สื่อกับ $name';
  }

  @override
  String get errorLoadingMedia => 'เกิดข้อผิดพลาดในการโหลดสื่อ';

  @override
  String get savedMomentsTitle => 'โมเมนต์ที่บันทึกไว้';

  @override
  String get removeBookmark => 'ลบบุ๊กมาร์ก?';

  @override
  String get thisWillRemoveBookmark => 'การดำเนินการนี้จะลบข้อความออกจากบุ๊กมาร์กของคุณ';

  @override
  String get remove => 'ลบ';

  @override
  String get bookmarkRemoved => 'ลบบุ๊กมาร์กแล้ว';

  @override
  String get bookmarkedMessages => 'ข้อความที่บุ๊กมาร์กไว้';

  @override
  String get wallpaperSaved => 'บันทึกวอลเปเปอร์ในเครื่องแล้ว';

  @override
  String get typeDeleteToConfirm => 'พิมพ์ DELETE เพื่อยืนยัน';

  @override
  String get storyArchive => 'คลังสตอรี่';

  @override
  String get newHighlight => 'ไฮไลท์ใหม่';

  @override
  String get addToHighlight => 'เพิ่มไปยังไฮไลท์';

  @override
  String get repost => 'รีโพสต์';

  @override
  String get repostFeatureSoon => 'ฟีเจอร์รีโพสต์กำลังจะมาเร็วๆ นี้';

  @override
  String get closeFriends => 'เพื่อนสนิท';

  @override
  String get addFriends => 'เพิ่มเพื่อน';

  @override
  String get highlights => 'ไฮไลท์';

  @override
  String get createHighlight => 'สร้างไฮไลท์';

  @override
  String get deleteHighlight => 'ลบไฮไลท์';

  @override
  String get editHighlight => 'แก้ไขไฮไลท์';

  @override
  String get addMoreToStory => 'เพิ่มเติมในสตอรี่';

  @override
  String get noViewersYet => 'ยังไม่มีผู้ชม';

  @override
  String get noReactionsYet => 'ยังไม่มีการตอบสนอง';

  @override
  String get leaveRoom => 'ออกจากห้อง';

  @override
  String get areYouSureLeaveRoom => 'คุณแน่ใจหรือไม่ว่าต้องการออกจากห้องเสียงนี้?';

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
  String get areYouSureFollow => 'คุณแน่ใจหรือไม่ว่าต้องการติดตาม';

  @override
  String get failedToLoadProfile => 'ไม่สามารถโหลดโปรไฟล์ได้';

  @override
  String get noFollowersYet => 'ยังไม่มีผู้ติดตาม';

  @override
  String get noFollowingYet => 'ยังไม่ได้ติดตามใครเลย';

  @override
  String get searchUsers => 'ค้นหาผู้ใช้...';

  @override
  String get noResultsFound => 'ไม่พบผลลัพธ์';

  @override
  String get loadingFailed => 'โหลดไม่สำเร็จ';

  @override
  String get copyLink => 'คัดลอกลิงก์';

  @override
  String get shareStory => 'แชร์สตอรี่';

  @override
  String get thisWillDeleteStory => 'การดำเนินการนี้จะลบสตอรี่นี้อย่างถาวร';

  @override
  String get storyDeleted => 'ลบสตอรี่แล้ว';

  @override
  String get addCaption => 'เพิ่มคำบรรยาย...';

  @override
  String get yourStory => 'สตอรี่ของคุณ';

  @override
  String get sendMessage => 'ส่งข้อความ';

  @override
  String get replyToStory => 'ตอบกลับสตอรี่...';

  @override
  String get viewAllReplies => 'ดูการตอบกลับทั้งหมด';

  @override
  String get preparingVideo => 'กำลังเตรียมวิดีโอ...';

  @override
  String videoOptimized(String size, String savings) {
    return 'เพิ่มประสิทธิภาพวิดีโอแล้ว: ${size}MB (ประหยัด $savings%)';
  }

  @override
  String get failedToProcessVideo => 'ไม่สามารถประมวลผลวิดีโอได้';

  @override
  String get optimizingForBestExperience => 'กำลังเพิ่มประสิทธิภาพเพื่อประสบการณ์สตอรี่ที่ดีที่สุด';

  @override
  String get pleaseSelectImageOrVideo => 'โปรดเลือกรูปภาพหรือวิดีโอสำหรับสตอรี่ของคุณ';

  @override
  String get storyCreatedSuccessfully => 'สร้างสตอรี่สำเร็จแล้ว!';

  @override
  String get uploadingStoryInBackground => 'กำลังอัปโหลดสตอรี่ในพื้นหลัง...';

  @override
  String get storyCreationFailed => 'สร้างสตอรี่ไม่สำเร็จ';

  @override
  String get pleaseCheckConnection => 'โปรดตรวจสอบการเชื่อมต่อของคุณแล้วลองใหม่อีกครั้ง';

  @override
  String get uploadFailed => 'อัปโหลดไม่สำเร็จ';

  @override
  String get tryShorterVideo => 'ลองใช้วิดีโอที่สั้นลงหรือลองใหม่อีกครั้งในภายหลัง';

  @override
  String get shareMomentsThatDisappear => 'แชร์โมเมนต์ที่จะหายไปภายใน 24 ชั่วโมง';

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
  String get whoCanSeeThis => 'ใครสามารถดูสิ่งนี้ได้บ้าง?';

  @override
  String get everyone => 'ทุกคน';

  @override
  String get anyoneCanSeeStory => 'ทุกคนสามารถดูสตอรี่นี้ได้';

  @override
  String get friendsOnly => 'เพื่อนเท่านั้น';

  @override
  String get onlyFollowersCanSee => 'เฉพาะผู้ติดตามของคุณเท่านั้นที่ดูได้';

  @override
  String get onlyCloseFriendsCanSee => 'เฉพาะเพื่อนสนิทของคุณเท่านั้นที่ดูได้';

  @override
  String get backgroundColor => 'สีพื้นหลัง';

  @override
  String get fontStyle => 'รูปแบบตัวอักษร';

  @override
  String get normal => 'ปกติ';

  @override
  String get bold => 'ตัวหนา';

  @override
  String get italic => 'ตัวเอียง';

  @override
  String get handwriting => 'ลายมือ';

  @override
  String get addLocation => 'เพิ่มตำแหน่ง';

  @override
  String get enterLocationName => 'ใส่ชื่อสถานที่';

  @override
  String get addLink => 'เพิ่มลิงก์';

  @override
  String get buttonText => 'ข้อความปุ่ม';

  @override
  String get learnMore => 'เรียนรู้เพิ่มเติม';

  @override
  String get addHashtags => 'เพิ่มแฮชแท็ก';

  @override
  String get addHashtag => 'เพิ่มแฮชแท็ก';

  @override
  String get sendAsMessage => 'ส่งเป็นข้อความ';

  @override
  String get shareExternally => 'แชร์ภายนอก';

  @override
  String get checkOutStory => 'มาดูสตอรี่นี้บน Bananatalk สิ!';

  @override
  String viewsTab(String count) {
    return 'การดู ($count)';
  }

  @override
  String reactionsTab(String count) {
    return 'การตอบสนอง ($count)';
  }

  @override
  String get processingVideo => 'กำลังประมวลผลวิดีโอ...';

  @override
  String get link => 'ลิงก์';

  @override
  String unmuteUser(String name) {
    return 'เปิดเสียง $name?';
  }

  @override
  String get willReceiveNotifications => 'คุณจะได้รับการแจ้งเตือนสำหรับข้อความใหม่';

  @override
  String muteNotificationsFor(String name) {
    return 'ปิดเสียงการแจ้งเตือนสำหรับ $name';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return 'เปิดเสียงการแจ้งเตือนสำหรับ $name แล้ว';
  }

  @override
  String notificationsMutedFor(String name) {
    return 'ปิดเสียงการแจ้งเตือนสำหรับ $name แล้ว';
  }

  @override
  String get failedToUpdateMuteSettings => 'ไม่สามารถอัปเดตการตั้งค่าปิดเสียงได้';

  @override
  String get oneHour => '1 ชั่วโมง';

  @override
  String get eightHours => '8 ชั่วโมง';

  @override
  String get oneWeek => '1 สัปดาห์';

  @override
  String get always => 'เสมอ';

  @override
  String get failedToLoadBookmarks => 'ไม่สามารถโหลดบุ๊กมาร์กได้';

  @override
  String get noBookmarkedMessages => 'ไม่มีข้อความที่บุ๊กมาร์กไว้';

  @override
  String get longPressToBookmark => 'กดค้างที่ข้อความเพื่อบุ๊กมาร์ก';

  @override
  String get thisWillRemoveFromBookmarks => 'การดำเนินการนี้จะลบข้อความออกจากบุ๊กมาร์กของคุณ';

  @override
  String navigateToMessage(String name) {
    return 'ไปยังข้อความในแชทกับ $name';
  }

  @override
  String bookmarkedOn(String date) {
    return 'บุ๊กมาร์กเมื่อ $date';
  }

  @override
  String get voiceMessage => 'ข้อความเสียง';

  @override
  String get document => 'เอกสาร';

  @override
  String get attachment => 'ไฟล์แนบ';

  @override
  String get sendMeAMessage => 'ส่งข้อความถึงฉัน';

  @override
  String get shareWithFriends => 'แชร์กับเพื่อน';

  @override
  String get shareAnywhere => 'แชร์ได้ทุกที่';

  @override
  String get emailPreferences => 'การตั้งค่าอีเมล';

  @override
  String get receiveEmailNotifications => 'รับการแจ้งเตือนทางอีเมลจาก Bananatalk';

  @override
  String get whenAwayFor24Hours => 'เมื่อคุณไม่ได้ใช้งานนานกว่า 24 ชั่วโมง';

  @override
  String get passwordAndLoginAlerts => 'การแจ้งเตือนรหัสผ่านและการเข้าสู่ระบบ';

  @override
  String get failedToLoadPreferences => 'ไม่สามารถโหลดการตั้งค่าที่ต้องการได้';

  @override
  String get failedToUpdateSetting => 'ไม่สามารถอัปเดตการตั้งค่าได้';

  @override
  String get securityAlertsRecommended => 'เราขอแนะนำให้เปิดใช้งานการแจ้งเตือนความปลอดภัยไว้ เพื่อให้คุณทราบความเคลื่อนไหวสำคัญของบัญชี';

  @override
  String chatWallpaperFor(String name) {
    return 'วอลเปเปอร์แชทสำหรับ $name';
  }

  @override
  String get solidColors => 'สีพื้น';

  @override
  String get gradients => 'ไล่โทนสี';

  @override
  String get customImage => 'รูปภาพกำหนดเอง';

  @override
  String get chooseFromGallery => 'เลือกจากคลังภาพ';

  @override
  String get preview => 'ดูตัวอย่าง';

  @override
  String get wallpaperUpdated => 'อัปเดตวอลเปเปอร์แล้ว';

  @override
  String get category => 'หมวดหมู่';

  @override
  String get mood => 'อารมณ์';

  @override
  String get sortBy => 'เรียงตาม';

  @override
  String get timePeriod => 'ช่วงเวลา';

  @override
  String get searchLanguages => 'ค้นหาภาษา...';

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
    return 'ใช้ตัวกรอง $count รายการ';
  }

  @override
  String get videoMustBeUnder1GB => 'วิดีโอต้องมีขนาดไม่เกิน 1GB';

  @override
  String get failedToRecordVideo => 'ไม่สามารถบันทึกวิดีโอได้';

  @override
  String get errorSendingVideo => 'เกิดข้อผิดพลาดในการส่งวิดีโอ';

  @override
  String get errorSendingVoiceMessage => 'เกิดข้อผิดพลาดในการส่งข้อความเสียง';

  @override
  String get errorSendingMedia => 'เกิดข้อผิดพลาดในการส่งสื่อ';

  @override
  String get cameraPermissionRequired => 'ต้องได้รับสิทธิ์เข้าถึงกล้องและไมโครโฟนเพื่อบันทึกวิดีโอ';

  @override
  String get locationPermissionRequired => 'ต้องได้รับสิทธิ์เข้าถึงตำแหน่งเพื่อแชร์ตำแหน่งของคุณ';

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
  String get checkOutMoment => 'ดูโมเมนต์นี้บน Bananatalk!';

  @override
  String get checkOutProfile => 'มาดูโปรไฟล์นี้บน Bananatalk สิ!';

  @override
  String get checkOutCommunity => 'มาดูสมาชิกคนนี้บน Bananatalk สิ!';

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
  String get locationOptional => 'กรุณาตั้งค่าตำแหน่งของคุณเพื่อดำเนินการต่อ';

  @override
  String get maximum6Photos => 'สูงสุด 6 รูป';

  @override
  String get tapToDetectLocation => 'แตะเพื่อตรวจหาตำแหน่ง';

  @override
  String get optionalHelpsNearbyPartners => 'จำเป็น — ช่วยจับคู่กับพาร์ทเนอร์ใกล้เคียง';

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
  String get confirmPasswordHint => 'ป้อนรหัสผ่านใหม่อีกครั้ง';

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
  String get authWelcomeTagline => 'MEET  ·  CHAT  ·  CONNECT';

  @override
  String get authWelcomeCtaTitle => 'Make global friends on Bananatalk';

  @override
  String get authWelcomeCtaSubtitle => 'Join millions of language learners today';

  @override
  String get authWelcomeFeatureConnectTitle => 'Connect';

  @override
  String get authWelcomeFeatureConnectSubtitle => 'Meet language partners from 150+ countries around the world';

  @override
  String get authWelcomeFeatureLearnTitle => 'Learn';

  @override
  String get authWelcomeFeatureLearnSubtitle => 'AI tutor, quizzes & pronunciation training — all in one app';

  @override
  String get authWelcomeFeatureGrowTitle => 'Grow';

  @override
  String get authWelcomeFeatureGrowSubtitle => 'Build real fluency through daily conversations and community';

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
  String get allCategories => 'ทุกหมวดหมู่';

  @override
  String get leaderboard => 'กระดานผู้นำ';

  @override
  String get competeWithLearners => 'แข่งขันกับผู้เรียนคนอื่นๆ!';

  @override
  String get xpRankings => 'อันดับ XP';

  @override
  String get streaks => 'สตรีค';

  @override
  String get friends => 'เพื่อน';

  @override
  String get myRanks => 'อันดับของฉัน';

  @override
  String get currentStreak => 'สตรีคปัจจุบัน';

  @override
  String get longestStreak => 'สตรีคที่ยาวนานที่สุด';

  @override
  String get weekly => 'รายสัปดาห์';

  @override
  String get monthly => 'รายเดือน';

  @override
  String get yourRank => 'อันดับของคุณ';

  @override
  String outOf(int total) {
    return 'จาก $total';
  }

  @override
  String topPercent(String percent) {
    return 'ท็อป $percent%';
  }

  @override
  String get xpRank => 'อันดับ XP';

  @override
  String get streakRank => 'อันดับสตรีค';

  @override
  String get days => 'วัน';

  @override
  String get learningStats => 'สถิติการเรียนรู้';

  @override
  String get totalXp => 'XP รวม';

  @override
  String get lessonsCompleted => 'บทเรียนที่เรียนจบ';

  @override
  String get rankings => 'อันดับ';

  @override
  String get yourPosition => 'ตำแหน่งของคุณ';

  @override
  String get keepLearning => 'เรียนต่อไปเพื่อไต่อันดับ!';

  @override
  String get noRankingsYet => 'ยังไม่มีอันดับ';

  @override
  String get startLearningToAppear => 'เริ่มเรียนเพื่อปรากฏบนกระดานผู้นำ!';

  @override
  String get noFriendsYet => 'ยังไม่มีเพื่อน';

  @override
  String get addFriendsToCompete => 'เพิ่มเพื่อนเพื่อแข่งขันกับพวกเขา!';

  @override
  String get failedToLoadLeaderboard => 'ไม่สามารถโหลดกระดานผู้นำได้';

  @override
  String get you => 'คุณ';

  @override
  String get findPartners => 'ค้นหาคู่ฝึกภาษา';

  @override
  String get discoverLanguagePartners => 'ค้นพบคู่ฝึกภาษา';

  @override
  String get byLanguage => 'ตามภาษา';

  @override
  String get match => 'ตรงกัน';

  @override
  String get matchScore => 'คะแนนความเข้ากัน';

  @override
  String get noMatchesFound => 'ไม่พบผลที่ตรงกัน';

  @override
  String get noUsersOnline => 'ไม่มีผู้ใช้ออนไลน์';

  @override
  String get checkBackLater => 'กลับมาตรวจสอบใหม่ภายหลัง';

  @override
  String get selectLanguagePrompt => 'เลือกภาษา';

  @override
  String get findPartnersByLanguage => 'ค้นหาคู่ฝึกที่พูดหรือเรียนภาษานี้';

  @override
  String noPartnersForLanguage(String language) {
    return 'ไม่มีคู่ฝึกสำหรับ $language';
  }

  @override
  String get tryAnotherLanguage => 'ลองเลือกภาษาอื่น';

  @override
  String get failedToLoadMatches => 'ไม่สามารถโหลดผลที่ตรงกันได้';

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
  String get noBlockedUsers => 'ไม่มีผู้ใช้ที่ถูกบล็อก';

  @override
  String get usersYouBlockWillAppearHere => 'ผู้ใช้ที่คุณบล็อกจะปรากฏที่นี่';

  @override
  String unblockConfirm(String name) {
    return 'คุณแน่ใจหรือไม่ว่าต้องการเลิกบล็อก $name?';
  }

  @override
  String reasonLabel(String reason) {
    return 'เหตุผล: $reason';
  }

  @override
  String blockedAgo(String time) {
    return 'บล็อกเมื่อ $time';
  }

  @override
  String errorLoadingBlockedUsers(String error) {
    return 'เกิดข้อผิดพลาดในการโหลดผู้ใช้ที่ถูกบล็อก: $error';
  }

  @override
  String get logoutConfirmMessage => 'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ Bananatalk?';

  @override
  String get loggingOut => 'กำลังออกจากระบบ...';

  @override
  String get quietHours => 'ช่วงเวลาเงียบ';

  @override
  String get quietHoursEnable => 'เปิดใช้งานช่วงเวลาเงียบ';

  @override
  String get quietHoursSubtitle => 'หยุดการแจ้งเตือนที่ไม่เร่งด่วนในช่วงเวลาที่กำหนด';

  @override
  String get quietHoursStart => 'เวลาเริ่มต้น';

  @override
  String get quietHoursEnd => 'เวลาสิ้นสุด';

  @override
  String get quietHoursAllowUrgent => 'อนุญาตการแจ้งเตือนเร่งด่วน';

  @override
  String get quietHoursAllowUrgentSubtitle => 'การโทรและข้อความจากคู่ฝึก VIP ยังคงส่งถึงคุณได้';

  @override
  String get silencedByQuietHours => 'ปิดเสียงโดยช่วงเวลาเงียบ';

  @override
  String get silencedByCap => 'ปิดเสียงโดยขีดจำกัดรายวัน';

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

  @override
  String tapBelowToBrowseLanguages(int count) {
    return 'แตะด้านล่างเพื่อเลือกจาก $count ภาษา';
  }

  @override
  String get changeLanguage => 'เปลี่ยนภาษา';

  @override
  String get browseLanguages => 'เรียกดูภาษา';

  @override
  String get yourLearningLanguageIsPrefix => 'ภาษาที่คุณกำลังเรียนคือ';

  @override
  String get yourNativeLanguageIsPrefix => 'ภาษาแม่ของคุณคือ';

  @override
  String get profileCompleteProgress => 'สมบูรณ์';

  @override
  String get drawerPreferences => 'การตั้งค่า';

  @override
  String get drawerStorage => 'พื้นที่จัดเก็บ';

  @override
  String get drawerReports => 'รายงาน';

  @override
  String get drawerSupport => 'ฝ่ายสนับสนุน';

  @override
  String get drawerAccount => 'บัญชี';

  @override
  String get logoutConfirmBody => 'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ Bananatalk?';

  @override
  String get helpEmailSupport => 'ติดต่อฝ่ายสนับสนุนทางอีเมล';

  @override
  String get helpEmailSupportSubtitle => 'support@bananatalk.com';

  @override
  String get helpReportBug => 'รายงานข้อบกพร่อง';

  @override
  String get helpReportBugSubtitle => 'ช่วยเราปรับปรุง Bananatalk';

  @override
  String get helpFaqs => 'คำถามที่พบบ่อย';

  @override
  String get helpFaqsSubtitle => 'คำถามที่ถามบ่อย';

  @override
  String get aboutDialogClose => 'ปิด';

  @override
  String get aboutBananatalkTagline => 'เชื่อมต่อกับผู้เรียนภาษาทั่วโลกและพัฒนาทักษะผ่านการสนทนาจริง';

  @override
  String get aboutCopyright => '© 2024 Bananatalk. สงวนลิขสิทธิ์ทั้งหมด';

  @override
  String get logoutFailedPrefix => 'ออกจากระบบล้มเหลว';

  @override
  String get profileVisitorsTitle => 'ผู้เยี่ยมชมโปรไฟล์';

  @override
  String get visitorStatistics => 'สถิติผู้เยี่ยมชม';

  @override
  String get visitorsTotalVisits => 'การเยี่ยมชมทั้งหมด';

  @override
  String get visitorsUniqueVisitors => 'ผู้เยี่ยมชมที่ไม่ซ้ำ';

  @override
  String get visitorsToday => 'วันนี้';

  @override
  String get visitorsThisWeek => 'สัปดาห์นี้';

  @override
  String get noVisitorsYet => 'ยังไม่มีผู้เยี่ยมชม';

  @override
  String get noVisitorsYetSubtitle => 'เมื่อมีคนเยี่ยมชมโปรไฟล์ของคุณ\nพวกเขาจะปรากฏที่นี่';

  @override
  String get visitedViaSearch => 'ผ่านการค้นหา';

  @override
  String get visitedViaMoments => 'ผ่านโมเมนต์';

  @override
  String get visitedViaChat => 'ผ่านแชท';

  @override
  String get visitedDirect => 'เยี่ยมชมโดยตรง';

  @override
  String get visitorTrackingUnavailable => 'ฟีเจอร์ติดตามผู้เยี่ยมชมไม่พร้อมใช้งาน กรุณาอัปเดต backend';

  @override
  String get visitorTrackingNotAvailableYet => 'การติดตามผู้เยี่ยมชมยังไม่พร้อมใช้งาน';

  @override
  String get noFollowersYetSubtitle => 'เริ่มเชื่อมต่อกับผู้อื่นได้เลย!';

  @override
  String get partnerButton => 'คู่หู';

  @override
  String get notFollowingAnyoneYetSubtitle => 'เริ่มติดตามผู้คนเพื่อดูการอัปเดตของพวกเขา!';

  @override
  String get unfollowButton => 'เลิกติดตาม';

  @override
  String get profileThemeTitle => 'ธีมโปรไฟล์';

  @override
  String get themeAutoSwitch => 'สลับอัตโนมัติ (ธีมระบบ)';

  @override
  String get themeSystemHint => 'เมื่อเปิดใช้งาน แอปจะปฏิบัติตามการตั้งค่าธีมของระบบ';

  @override
  String get themeLightMode => 'โหมดสว่าง';

  @override
  String get themeDarkMode => 'โหมดมืด';

  @override
  String get myMoments => 'โมเมนต์ของฉัน';

  @override
  String get momentListView => 'มุมมองรายการ';

  @override
  String get momentGridView => 'มุมมองตาราง';

  @override
  String get shareLanguageLearningJourney => 'แชร์การเดินทางการเรียนภาษาของคุณ!';

  @override
  String get deleteHighlightTitle => 'ลบไฮไลต์';

  @override
  String deleteHighlightConfirm(String title) {
    return 'ลบ \"$title\" หรือไม่? สตอรีภายในจะไม่ถูกลบ';
  }

  @override
  String get highlightDeletedSuccess => 'ลบไฮไลต์แล้ว';

  @override
  String get highlightNewBadge => 'ใหม่';

  @override
  String get editMoment => 'แก้ไขโมเมนต์';

  @override
  String get momentDescriptionLabel => 'คำอธิบาย';

  @override
  String get momentImagesLabel => 'รูปภาพ';

  @override
  String get noImagesYet => 'ยังไม่มีรูปภาพ';

  @override
  String get momentEnterDescription => 'กรุณากรอกคำอธิบาย';

  @override
  String get momentUpdatedImageFailed => 'อัปเดตโมเมนต์แล้ว แต่การอัปโหลดรูปภาพล้มเหลว';

  @override
  String get updateRequiredTitle => 'จำเป็นต้องอัปเดต';

  @override
  String get updateAvailableTitle => 'มีการอัปเดต';

  @override
  String get updateRequiredBody => 'Bananatalk เวอร์ชันนี้ไม่ได้รับการรองรับอีกต่อไป กรุณาอัปเดตเพื่อดำเนินการต่อ';

  @override
  String get updateAvailableBody => 'Bananatalk เวอร์ชันใหม่พร้อมการปรับปรุงและแก้ไขข้อผิดพลาดพร้อมให้ใช้งานแล้ว';

  @override
  String get updateNow => 'อัปเดตเดี๋ยวนี้';

  @override
  String get updateLater => 'ภายหลัง';

  @override
  String get updateOpenStoreFailed => 'ไม่สามารถเปิดร้านค้าได้ กรุณาอัปเดตจาก App Store หรือ Play Store';

  @override
  String get rememberMe => 'จดจำฉัน';

  @override
  String get passwordWeak => 'อ่อนแอ';

  @override
  String get passwordFair => 'พอใช้';

  @override
  String get passwordStrong => 'แข็งแรง';

  @override
  String get passwordVeryStrong => 'แข็งแรงมาก';

  @override
  String get showPassword => 'แสดงรหัสผ่าน';

  @override
  String get hidePassword => 'ซ่อนรหัสผ่าน';

  @override
  String stepProgress(int current, int total) {
    return 'ขั้นตอน $current จาก $total';
  }

  @override
  String get usernameOptional => 'ชื่อผู้ใช้ (ไม่บังคับ)';

  @override
  String get usernameAvailable => 'ใช้ได้';

  @override
  String get usernameTaken => 'ถูกใช้ไปแล้ว';

  @override
  String get usernameNotAvailable => 'ใช้ไม่ได้';

  @override
  String get usernameInvalidFormat => '3-20 ตัวอักษร: ตัวอักษร ตัวเลข หรือขีดล่าง';

  @override
  String get usernameHint => '@ชื่อผู้ใช้';

  @override
  String get enableBiometricTitle => 'เข้าสู่ระบบด้วย Face ID ครั้งต่อไปหรือไม่?';

  @override
  String get enableBiometricBody => 'เข้าสู่ระบบด้วยข้อมูลชีวภาพโดยไม่ต้องพิมพ์รหัสผ่าน';

  @override
  String get enableBiometricCta => 'เปิดใช้งาน';

  @override
  String get biometricSignInPrompt => 'ยืนยันตัวตนเพื่อเข้าสู่ระบบ Bananatalk';

  @override
  String continueAs(String name) {
    return 'ดำเนินการต่อในชื่อ $name';
  }

  @override
  String get addProfilePhotoTitle => 'เพิ่มรูปโปรไฟล์';

  @override
  String get addProfilePhotoSkip => 'ข้ามไปก่อน';

  @override
  String get wavesTab => 'ทักทาย';

  @override
  String get sendWave => 'ส่งการทักทาย';

  @override
  String sendWaveTo(String name) {
    return 'ส่งการทักทายถึง $name';
  }

  @override
  String waveSent(String name) {
    return 'ส่งการทักทายถึง $name แล้ว';
  }

  @override
  String waveCooldown(String name, String time) {
    return 'คุณสามารถทักทาย $name อีกครั้งใน $time';
  }

  @override
  String get waveCouldntSend => 'ไม่สามารถส่งการทักทายได้';

  @override
  String get itsAMatch => 'จับคู่สำเร็จ!';

  @override
  String itsAMatchSubtitle(String name) {
    return 'คุณและ $name ทักทายกัน';
  }

  @override
  String get sendAMessage => 'ส่งข้อความ';

  @override
  String get waveQuickReplyHi => 'สวัสดี!';

  @override
  String get waveQuickReplyCool => 'คุณดูดีมาก';

  @override
  String get waveQuickReplyHey => 'เฮ้';

  @override
  String get waveQuickReplyChat => 'มาคุยกันเถอะ';

  @override
  String get waveQuickReplyHello => 'สวัสดีครับ/ค่ะ';

  @override
  String waveQuickReplyFromCountry(String country) {
    return 'สวัสดีจาก $country';
  }

  @override
  String get waveCustomMessage => 'หรือเขียนข้อความของตัวเอง…';

  @override
  String get voiceRoomChat => 'แชท';

  @override
  String get voiceRoomChatPlaceholder => 'ส่งข้อความ…';

  @override
  String get voiceRoomChatEmpty => 'ยังไม่มีข้อความ — พูดสวัสดีสิ';

  @override
  String get voiceRoomChatSend => 'ส่ง';

  @override
  String voiceRoomChatNewBadge(int n) {
    return '$n';
  }

  @override
  String get voiceRoomEnd => 'สิ้นสุดห้อง';

  @override
  String get voiceRoomEndConfirm => 'สิ้นสุดห้องนี้?';

  @override
  String get voiceRoomEndConfirmBody => 'ทุกคนจะถูกตัดการเชื่อมต่อ';

  @override
  String get voiceRoomKick => 'นำออกจากห้อง';

  @override
  String voiceRoomKickConfirm(String name) {
    return 'นำ $name ออก?';
  }

  @override
  String get voiceRoomKicked => 'ถูกนำออกแล้ว';

  @override
  String get voiceRoomYouAreHostNow => 'คุณเป็นเจ้าภาพแล้ว';

  @override
  String voiceRoomHostChanged(String name) {
    return '$name เป็นเจ้าภาพแล้ว';
  }

  @override
  String get voiceRoomHostMenuTitle => 'การจัดการห้อง';

  @override
  String get voiceRoomViewProfile => 'ดูโปรไฟล์';

  @override
  String get voiceRoomReconnecting => 'กำลังเชื่อมต่อใหม่…';

  @override
  String get voiceRoomReconnected => 'เชื่อมต่อใหม่แล้ว';

  @override
  String get voiceRoomEnded => 'ห้องสิ้นสุดแล้ว';

  @override
  String get voiceRoomReconnectRetry => 'ลองใหม่';

  @override
  String get mutualInterests => 'ความสนใจร่วมกัน';

  @override
  String interestsInCommon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ความสนใจร่วมกัน',
      one: '1 ความสนใจร่วมกัน',
      zero: 'ยังไม่มีความสนใจร่วมกัน',
    );
    return '$_temp0';
  }

  @override
  String get interestsInCommonSeeAll => 'ดูทั้งหมด';

  @override
  String get interestsInCommonAddCta => 'เพิ่มหัวข้อ';

  @override
  String get interestsInCommonAddSubtitle => 'เพิ่มหัวข้อในโปรไฟล์เพื่อหาจุดร่วม';

  @override
  String activeAgo(String time) {
    return 'ใช้งานเมื่อ $time ที่แล้ว';
  }

  @override
  String get filterOnlineNow => 'ออนไลน์อยู่';

  @override
  String get filterAge => 'อายุ';

  @override
  String get filterGender => 'เพศ';

  @override
  String get filterLanguages => 'ภาษา';

  @override
  String get filterCountry => 'ประเทศ';

  @override
  String get filterTopics => 'หัวข้อ';

  @override
  String get filterLevel => 'ระดับภาษา';

  @override
  String get filterToggles => 'อื่นๆ';

  @override
  String filterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คนตรงกัน',
      one: '1 คนตรงกัน',
      zero: 'ไม่มีคู่ที่ตรงกัน',
    );
    return '$_temp0';
  }

  @override
  String get filterClearAll => 'ล้างทั้งหมด';

  @override
  String get filterReset => 'รีเซ็ต';

  @override
  String get filterApply => 'ใช้งาน';

  @override
  String get filterNewUsers => 'เฉพาะผู้ใช้ใหม่';

  @override
  String get filterPrioritizeNearby => 'ให้ความสำคัญกับบริเวณใกล้เคียง';

  @override
  String get filterSheetTitle => 'ตัวกรอง';

  @override
  String get notificationPreferencesTitle => 'การแจ้งเตือน';

  @override
  String get notificationPreferencesSubtitle => 'เลือกการแจ้งเตือนที่คุณต้องการรับ';

  @override
  String get notifPrefChat => 'ข้อความใหม่';

  @override
  String get notifPrefWave => 'เวฟ';

  @override
  String get notifPrefVoiceRoomStart => 'คำเชิญห้องเสียง';

  @override
  String get notifPrefScheduledRoomReminder => 'การแจ้งเตือนห้องที่นัดหมาย';

  @override
  String get notifPrefFollowerMoment => 'โมเมนต์ใหม่จากคนที่คุณติดตาม';

  @override
  String get notifPrefVisitorAlert => 'ผู้เยี่ยมชมโปรไฟล์';

  @override
  String get notifPrefMatchAlert => 'เวฟตอบกลับ';

  @override
  String get notifResetToDefaults => 'รีเซ็ตเป็นค่าเริ่มต้น';

  @override
  String get themeMode => 'ธีม';

  @override
  String get themeLight => 'สว่าง';

  @override
  String get themeDark => 'มืด';

  @override
  String get themeSystem => 'ระบบ';

  @override
  String get languageSettingsRow => 'ภาษา';

  @override
  String get waveDailySummaryTitle => 'มีเวฟใหม่รอคุณอยู่';

  @override
  String waveDailySummaryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คนส่งเวฟมาหาคุณ',
      one: '1 คนส่งเวฟมาหาคุณ',
    );
    return '$_temp0';
  }

  @override
  String get filterTopicsTitle => 'หัวข้อ';

  @override
  String get filterTopicsEmpty => 'ยังไม่ได้เลือกหัวข้อ';

  @override
  String get storiesEmpty => 'ยังไม่มีสตอรี่';

  @override
  String get storiesLoadError => 'โหลดสตอรี่ไม่สำเร็จ';

  @override
  String get storiesRetry => 'ลองอีกครั้ง';

  @override
  String get storiesNoMore => 'คุณดูครบแล้ว';

  @override
  String get createTextStoryTab => 'ข้อความ';

  @override
  String get createImageStoryTab => 'รูปภาพ';

  @override
  String get createVideoStoryTab => 'วิดีโอ';

  @override
  String get enterTextHint => 'แตะเพื่อพิมพ์';

  @override
  String get pickBackground => 'พื้นหลัง';

  @override
  String get pickFontStyle => 'ฟอนต์';

  @override
  String get pickTextColor => 'สี';

  @override
  String get addEmoji => 'เพิ่มอีโมจิ';

  @override
  String get chooseFont => 'เลือกฟอนต์';

  @override
  String get chooseColor => 'เลือกสี';

  @override
  String get dragToMove => 'ลากเพื่อย้าย';

  @override
  String get pinchToScale => 'หยิกเพื่อปรับขนาด';

  @override
  String get removeFromHighlight => 'นำออกจากไฮไลต์';

  @override
  String get highlightDeleted => 'ลบไฮไลต์แล้ว';

  @override
  String get storySaved => 'บันทึกในสตอรี่ของคุณแล้ว';

  @override
  String get storyTooLong => 'ข้อความยาวเกินไป';

  @override
  String get storyPostFailed => 'โพสต์สตอรี่ไม่สำเร็จ';

  @override
  String get fontNormal => 'ปกติ';

  @override
  String get fontBold => 'ตัวหนา';

  @override
  String get fontItalic => 'ตัวเอียง';

  @override
  String get fontHandwriting => 'ลายมือ';

  @override
  String get pickDate => 'เลือกวันที่';

  @override
  String get pickTime => 'เลือกเวลา';

  @override
  String get upcomingRooms => 'กำลังจะมาถึง';

  @override
  String inHours(int h, int m) {
    return 'ใน $hชม. $mน.';
  }

  @override
  String inMinutes(int m) {
    return 'ใน $mน.';
  }

  @override
  String get startsNow => 'เริ่มแล้วตอนนี้';

  @override
  String get iWillBeThere => 'ฉันจะไป';

  @override
  String get cantMakeIt => 'ฉันไปไม่ได้';

  @override
  String rsvpCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count การตอบรับ',
      one: '1 การตอบรับ',
      zero: 'ยังไม่มีการตอบรับ',
    );
    return '$_temp0';
  }

  @override
  String roomStartsIn1h(String title) {
    return '$title จะเริ่มใน 1 ชั่วโมง';
  }

  @override
  String roomStartsIn15min(String title) {
    return '$title จะเริ่มใน 15 นาที';
  }

  @override
  String roomStarted(String title) {
    return '$title กำลังเริ่มต้นแล้ว';
  }

  @override
  String get cancelRoom => 'ยกเลิกห้อง';

  @override
  String get muteAll => 'ปิดเสียงทุกคน';

  @override
  String get mutedByHost => 'โฮสต์ปิดเสียงทุกคนแล้ว';

  @override
  String get muteAllConfirm => 'ปิดเสียงทุกคนในห้องใช่ไหม?';

  @override
  String get categoryCasual => 'ทั่วไป';

  @override
  String get categoryLanguagePractice => 'ฝึกภาษา';

  @override
  String get categoryTopic => 'หัวข้อ';

  @override
  String get categoryQA => 'ถาม-ตอบ';

  @override
  String get pickCategory => 'หมวดหมู่';

  @override
  String get sortRecentlyActive => 'เคลื่อนไหวล่าสุด';

  @override
  String visitedYourProfile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คนเยี่ยมชมโปรไฟล์ของคุณ',
      one: '1 คนเยี่ยมชมโปรไฟล์ของคุณ',
    );
    return '$_temp0';
  }

  @override
  String get noRecentVisitors => 'ยังไม่มีผู้เยี่ยมชมล่าสุด';

  @override
  String get viewArchive => 'ดูคลังเก็บถาวร';

  @override
  String get archivedWaves => 'Wave ที่เก็บถาวร';

  @override
  String get noArchivedWaves => 'ไม่มี Wave ที่เก็บถาวร';

  @override
  String get mutualInterestsMin => 'ความสนใจร่วม (ขั้นต่ำ)';

  @override
  String atLeastNTopics(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'อย่างน้อย $n หัวข้อร่วม',
      one: 'อย่างน้อย 1 หัวข้อร่วม',
      zero: 'ทั้งหมด',
    );
    return '$_temp0';
  }

  @override
  String get starterAskMoment => 'ถามเกี่ยวกับช่วงเวลาล่าสุดของพวกเขา';

  @override
  String get starterSayHi => 'ทักทายด้วยภาษาของพวกเขา';

  @override
  String get starterCurious => 'พวกเขาสงสัยเรื่องอะไร?';

  @override
  String starterFromCountry(String country) {
    return 'สวัสดีจาก $country!';
  }

  @override
  String starterPracticeLang(String language) {
    return 'ช่วยพวกเขาฝึก $language!';
  }

  @override
  String get momentsLoadError => 'ไม่สามารถโหลดโมเมนต์ได้';

  @override
  String get momentsRetry => 'ลองอีกครั้ง';

  @override
  String get recentTags => 'แท็กล่าสุด';

  @override
  String get noRecentTags => 'ยังไม่มีแท็กล่าสุด';

  @override
  String get hideMomentsFromUser => 'ซ่อนโมเมนต์ของผู้ใช้นี้';

  @override
  String get momentsHidden => 'โมเมนต์ของผู้ใช้นี้จะถูกซ่อน';

  @override
  String get unhideMoments => 'แสดงโมเมนต์ของผู้ใช้นี้';

  @override
  String momentsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ซ่อนผู้ใช้ $count คน',
      one: 'ซ่อนผู้ใช้ 1 คน',
      zero: 'ไม่มีผู้ใช้ที่ซ่อน',
    );
    return '$_temp0';
  }

  @override
  String get momentSaveFailed => 'ไม่สามารถบันทึกโมเมนต์ได้';

  @override
  String get tagAlreadyAdded => 'เพิ่มแท็กแล้ว';

  @override
  String get tagLimitReached => 'ถึงขีดจำกัดแท็กแล้ว';

  @override
  String get hideThisUser => 'ซ่อนโพสต์ของผู้ใช้นี้';

  @override
  String get transcribeMessage => 'ถอดเสียงเป็นข้อความ';

  @override
  String get transcribing => 'กำลังถอดเสียง…';

  @override
  String get transcriptionFailed => 'ไม่สามารถถอดเสียงข้อความได้';

  @override
  String saveToVocabulary(String word) {
    return 'บันทึก \'$word\' ลงในคำศัพท์';
  }

  @override
  String get addedToVocabulary => 'เพิ่มลงในคำศัพท์ของคุณแล้ว';

  @override
  String get alreadyInVocabulary => 'อยู่ในคำศัพท์ของคุณแล้ว';

  @override
  String get tapWordToSave => 'กดค้างที่คำเพื่อบันทึก';

  @override
  String get autoTranslateChatHint => 'ข้อความที่ได้รับจะถูกแปลโดยอัตโนมัติ';

  @override
  String get noConversationsYet => 'ยังไม่มีการสนทนา';

  @override
  String get chatRetry => 'ลองอีกครั้ง';

  @override
  String get learningHubTitle => 'การเรียนรู้';

  @override
  String get learningCommonRetry => 'ลองอีกครั้ง';

  @override
  String get learningCommonContinue => 'ดำเนินการต่อ';

  @override
  String get learningCommonAwesome => 'ยอดเยี่ยม!';

  @override
  String get learningErrorGeneric => 'เกิดข้อผิดพลาดบางอย่าง';

  @override
  String get learningStreakCurrent => 'สตรีคปัจจุบัน';

  @override
  String get learningStreakLongest => 'สตรีคที่ยาวที่สุด';

  @override
  String learningStreakDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countวัน',
    );
    return '$_temp0';
  }

  @override
  String learningStreakFreezeAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countการหยุดพักพร้อมใช้',
      zero: 'ไม่มีการหยุดพัก',
    );
    return '$_temp0';
  }

  @override
  String get learningStreakFreezeUse => 'ใช้การหยุด';

  @override
  String get learningStreakFreezeDescription => 'การหยุดพักปกป้องสตรีคของคุณเมื่อคุณพลาดวัน';

  @override
  String get learningStreakFreezeProtected => 'สตรีคได้รับการปกป้อง!';

  @override
  String get learningStreakMilestone7 => 'สตรีค 7 วัน!';

  @override
  String get learningStreakMilestone30 => 'สตรีค 30 วัน!';

  @override
  String get learningStreakMilestone100 => 'สตรีค 100 วัน!';

  @override
  String get learningStreakMilestone365 => 'สตรีค 365 วัน!';

  @override
  String get learningWeeklyDigestTitle => 'สัปดาห์นี้';

  @override
  String learningWeeklyDigestXp(int xp) {
    return 'ได้รับ $xp XP';
  }

  @override
  String learningWeeklyDigestLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countบทเรียน',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestVocab(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เรียนรู้ $countคำ',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestDaysActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countวันที่ใช้งาน',
    );
    return '$_temp0';
  }

  @override
  String get learningWeeklyDigestTopAchievement => 'ความสำเร็จสูงสุด';

  @override
  String learningWeeklyDigestTrendUp(int pct) {
    return 'เพิ่มขึ้น $pct% จากสัปดาห์ที่แล้ว';
  }

  @override
  String learningWeeklyDigestTrendDown(int pct) {
    return 'ลดลง $pct% จากสัปดาห์ที่แล้ว';
  }

  @override
  String get learningWeeklyDigestTrendFlat => 'เหมือนสัปดาห์ที่แล้ว';

  @override
  String get learningSrsDashboardTitle => 'ทบทวนประจำวัน';

  @override
  String learningSrsDueToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'วันนี้ $countใบ',
      zero: 'ไม่มีการ์ดวันนี้',
    );
    return '$_temp0';
  }

  @override
  String learningSrsDueTomorrow(int count) {
    return 'พรุ่งนี้ $countใบ';
  }

  @override
  String learningSrsDueThisWeek(int count) {
    return 'สัปดาห์นี้ $countใบ';
  }

  @override
  String get learningSrsStartReview => 'เริ่มทบทวน';

  @override
  String get learningSrsAllCaughtUp => 'คุณทันหมดแล้ว!';

  @override
  String get learningSrsKeepGoing => 'ต่อไปเลย';

  @override
  String get learningLeaderboardXpTab => 'XP';

  @override
  String get learningLeaderboardStreakTab => 'สตรีค';

  @override
  String get learningLeaderboardLanguageTab => 'ภาษา';

  @override
  String get learningLeaderboardFriendsTab => 'เพื่อน';

  @override
  String get learningLeaderboardEmpty => 'ยังไม่มีการจัดอันดับ';

  @override
  String get learningLeaderboardYouLabel => 'คุณ';

  @override
  String get learningLeaderboardFriendBadge => 'เพื่อน';

  @override
  String get learningEmptyVocab => 'เพิ่มคำที่คุณต้องการจำ';

  @override
  String get learningEmptyLessons => 'ยังไม่มีบทเรียน';

  @override
  String get learningEmptyQuizzes => 'ไม่มีแบบทดสอบ';

  @override
  String get learningEmptyChallenges => 'กลับมาตรวจสอบพรุ่งนี้';

  @override
  String get learningEmptyAchievements => 'รับความสำเร็จแรกของคุณ';

  @override
  String get learningEmptySearchResults => 'ไม่พบผลลัพธ์';

  @override
  String learningXpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String get learningLevelUp => 'เลเวลอัพ!';

  @override
  String learningLevelReached(String level) {
    return 'คุณถึง $level';
  }

  @override
  String get learningAchievementUnlocked => 'ปลดล็อกความสำเร็จ';

  @override
  String get learningVocabularySearchHint => 'ค้นหาคำศัพท์';

  @override
  String get learningVocabularyFilterAll => 'ทั้งหมด';

  @override
  String get learningVocabularyFilterNew => 'ใหม่';

  @override
  String get learningVocabularyFilterLearning => 'กำลังเรียน';

  @override
  String get learningVocabularyFilterMastered => 'เชี่ยวชาญ';

  @override
  String get learningVocabularySortRecent => 'ล่าสุด';

  @override
  String get learningVocabularySortAlphabetical => 'ตามตัวอักษร';

  @override
  String get learningVocabularySortMastery => 'ระดับความชำนาญ';

  @override
  String get learningVocabularyMasteryNew => 'ใหม่';

  @override
  String get learningVocabularyMasteryLearning => 'กำลังเรียน';

  @override
  String get learningVocabularyMasteryMastered => 'เชี่ยวชาญ';

  @override
  String get learningProgressLevelLabel => 'เลเวล';

  @override
  String learningProgressXpToNextLevel(int xp) {
    return '$xp XP ถึงเลเวลถัดไป';
  }

  @override
  String get learningProgressWeeklyChartTitle => '7 วันที่ผ่านมา';

  @override
  String get aiTutorPronounceLoading => 'กำลังเลือกประโยคให้คุณ…';

  @override
  String get aiTutorPronounceTapToRecord => 'แตะเพื่อบันทึก';

  @override
  String get aiTutorPronounceTapToStop => 'แตะเพื่อหยุด';

  @override
  String get aiTutorPronounceTranscribing => 'กำลังฟังคุณ…';

  @override
  String get aiTutorPronounceTryAgain => 'ลองอีกครั้ง';

  @override
  String get aiTutorPronounceNext => 'ถัดไป';

  @override
  String get aiTutorPronounceUseYourOwn => 'ใช้ของฉัน ✏️';

  @override
  String get aiTutorPronounceCustomHint => 'พิมพ์ประโยคที่อยากฝึก';

  @override
  String get aiTutorPronounceCustomCancel => 'ยกเลิก';

  @override
  String get aiTutorPronounceCustomUse => 'ใช้';

  @override
  String get aiTutorPronounceQuitConfirm => 'ออกจากการฝึก? ความคืบหน้าจะไม่ถูกบันทึก';

  @override
  String get aiTutorPronounceQuitYes => 'ใช่';

  @override
  String get aiTutorPronounceQuitNo => 'ไม่';

  @override
  String aiTutorPronounceSentenceOf(int current, int total) {
    return 'ประโยค $current จาก $total';
  }

  @override
  String get aiTutorPronounceSummaryTitle => 'ฝึกเสร็จแล้ว';

  @override
  String get aiTutorPronounceSummaryAvg => 'คะแนนเฉลี่ย';

  @override
  String get aiTutorPronounceSummaryWeak => 'คำที่ต้องฝึก';

  @override
  String get aiTutorPronounceSaveClose => 'บันทึกและปิด';

  @override
  String get aiTutorPronounceSaving => 'กำลังบันทึก…';

  @override
  String get aiTutorChipPronounce => 'การออกเสียง';

  @override
  String aiTutorPlanPronunciation(int count, int completed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ฝึกการออกเสียง ($completed/$count)',
      one: 'ฝึกการออกเสียง ($completed/1)',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorPronounceStartHeadline => 'คุณอยากฝึกอย่างไร?';

  @override
  String get aiTutorPronounceStartSubhead => 'เลือกหนึ่งเพื่อเริ่มฝึก 5 ประโยค';

  @override
  String get aiTutorPronounceStartAITitle => 'AI สร้างประโยค';

  @override
  String get aiTutorPronounceStartAISubtitle => 'ปรับตามระดับ เน้นคำที่คุณยากแล้ว';

  @override
  String get aiTutorPronounceStartCustomTitle => 'ใช้ประโยคของตัวเอง';

  @override
  String get aiTutorPronounceStartCustomSubtitle => 'พิมพ์หรือวางประโยคที่อยากฝึกให้คล่อง';

  @override
  String aiTutorQuotaRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เหลือ $count ครั้งวันนี้',
      one: 'เหลือ 1 ครั้งวันนี้',
    );
    return '$_temp0';
  }

  @override
  String get submit => 'ส่ง';

  @override
  String get exit => 'ออก';

  @override
  String get previous => 'ก่อนหน้า';

  @override
  String get aiDailyPracticeTitle => 'การฝึกประจำวัน';

  @override
  String get aiDailyPracticeTranslateThis => 'แปลข้อความนี้:';

  @override
  String get aiDailyPracticeSuggested => 'แนะนำ:';

  @override
  String get aiDailyPracticeHint => 'คำแปลของคุณ';

  @override
  String get aiLanguagesLoading => 'กำลังโหลดภาษา...';

  @override
  String get aiCopiedToClipboard => 'คัดลอกไปยังคลิปบอร์ดแล้ว';

  @override
  String get aiGrammarHint => 'ป้อนข้อความเพื่อวิเคราะห์...';

  @override
  String get aiGrammarSectionOriginal => 'ข้อความต้นฉบับ';

  @override
  String get aiGrammarSectionCorrected => 'ข้อความที่แก้แล้ว';

  @override
  String aiGrammarSectionIssues(int count) {
    return 'พบปัญหา ($count)';
  }

  @override
  String get aiGrammarSectionWell => 'สิ่งที่คุณทำได้ดี';

  @override
  String get aiGrammarSectionSuggestions => 'คำแนะนำ';

  @override
  String get aiGrammarSectionSummary => 'สรุป';

  @override
  String get aiLessonBuilderLabelLanguage => 'ภาษา';

  @override
  String get aiLessonBuilderLabelLevel => 'ระดับ';

  @override
  String get aiLessonBuilderTopicHint => 'ป้อนหัวข้อ (เช่น \"อาหารและร้านอาหาร\")';

  @override
  String aiLessonBuilderSaved(String title) {
    return 'บันทึกบทเรียน \"$title\" แล้ว!';
  }

  @override
  String get aiLessonBuilderBackToLessons => 'กลับไปบทเรียน';

  @override
  String get aiTranslationHint => 'ป้อนข้อความเพื่อแปล...';

  @override
  String get aiTranslationSavedToVocab => 'บันทึกในรายการคำศัพท์ของคุณแล้ว';

  @override
  String aiTranslationCouldNotSave(String error) {
    return 'บันทึกไม่ได้: $error';
  }

  @override
  String get aiQuizTitle => 'แบบทดสอบ';

  @override
  String get aiQuizFailedToGenerate => 'สร้างแบบทดสอบไม่สำเร็จ';

  @override
  String get aiQuizSubmitTitle => 'ส่งแบบทดสอบ?';

  @override
  String get aiQuizSubmitBody => 'แน่ใจว่าต้องการส่งคำตอบ?';

  @override
  String get aiQuizExitTitle => 'ออกจากแบบทดสอบ?';

  @override
  String get aiQuizExitBody => 'ความคืบหน้าของคุณจะหายไป';

  @override
  String get aiQuizAnswerHint => 'พิมพ์คำตอบของคุณ...';

  @override
  String get aiQuizTranslationHint => 'พิมพ์คำแปลของคุณ...';

  @override
  String get aiPronunciationPlayingAudio => 'กำลังเล่นเสียง...';

  @override
  String get aiPronunciationListenFirst => 'ฟังก่อน';

  @override
  String get aiPronunciationHint => 'ป้อนข้อความเพื่อฝึก...';

  @override
  String aiTutorCouldNotLoad(String error) {
    return 'โหลดติวเตอร์ไม่ได้: $error';
  }

  @override
  String aiTutorPlanUnavailable(String error) {
    return 'แผนไม่พร้อมใช้: $error';
  }

  @override
  String get aiTutorReplay => 'เล่นซ้ำ';

  @override
  String get aiScenariosTitle => 'สถานการณ์ฝึก';

  @override
  String aiScenariosCouldNotLoad(String error) {
    return 'โหลดสถานการณ์ไม่ได้: $error';
  }

  @override
  String get aiScenariosNoneAvailable => 'ยังไม่มีสถานการณ์';

  @override
  String aiScenariosCouldNotStart(String error) {
    return 'เริ่มไม่ได้: $error';
  }

  @override
  String aiScenariosForYourLevel(String level) {
    return 'สำหรับระดับของคุณ ($level)';
  }

  @override
  String get aiScenariosEasier => 'ง่ายขึ้น — วอร์มอัป';

  @override
  String get aiScenariosHarder => 'ยากขึ้น — ท้าทาย';

  @override
  String get aiRoleplayStillStarting => 'สถานการณ์กำลังเริ่ม — ลองอีกครั้งสักครู่';

  @override
  String aiRoleplaySendFailed(String error) {
    return 'ส่งล้มเหลว: $error';
  }

  @override
  String get aiRoleplayCouldNotGrade => 'ประเมินไม่ได้ในครั้งนี้ — ลองครั้งหน้า';

  @override
  String get aiConversationHistoryCompleted => 'เสร็จสิ้น';

  @override
  String get aiConversationHistoryInProgress => 'กำลังดำเนินการ';

  @override
  String get aiConversationMessageHint => 'พิมพ์ข้อความ...';

  @override
  String get aiConversationTopicSpeak => 'ฉันพูด';

  @override
  String get aiConversationTopicPractice => 'ฝึก';

  @override
  String aiToolsVipUpgradeDescription(String feature) {
    return 'อัพเกรดเป็น VIP เพื่อปลดล็อก $feature!';
  }

  @override
  String get aiToolsVipBadge => 'VIP';

  @override
  String aiScenariosBannerPracticingIn(String language) {
    return 'ฝึก $language';
  }

  @override
  String get aiScenariosBannerSubhead => 'เลือกสถานการณ์ระดับของคุณ หรือลองสูงขึ้นหนึ่งระดับ';

  @override
  String get chatListSearchHint => 'ค้นหาหรือพิมพ์ @ผู้ใช้';

  @override
  String get chatListFilterAll => 'ทั้งหมด';

  @override
  String get chatListFilterUnread => 'ยังไม่อ่าน';

  @override
  String get chatListFilterOnline => 'ออนไลน์';

  @override
  String get chatListNewChat => 'แชทใหม่';

  @override
  String get chatListNewChatByUsernameTooltip => 'แชทใหม่โดยใช้ชื่อผู้ใช้';

  @override
  String get chatListFindUser => 'ค้นหาผู้ใช้';

  @override
  String chatListFindUserSearchTerm(String term) {
    return 'ค้นหา @$term';
  }

  @override
  String get chatListDeleteConversation => 'ลบบทสนทนา';

  @override
  String chatListMediaTitle(String name) {
    return 'สื่อกับ $name';
  }

  @override
  String get chatListMediaError => 'โหลดสื่อไม่ได้';

  @override
  String get chatDetailViewFullProfile => 'ดูโปรไฟล์เต็ม';

  @override
  String get chatMessageReply => 'ตอบกลับ';

  @override
  String get chatMessageCopy => 'คัดลอก';

  @override
  String get chatMessageCorrect => 'แก้ไข';

  @override
  String get chatMessageTranslate => 'แปล';

  @override
  String get chatMessageSavePhrase => 'บันทึกประโยค';

  @override
  String get chatMessageEdit => 'แก้ไข';

  @override
  String get chatMessageDelete => 'ลบ';

  @override
  String get chatMessageRetrySubtitle => 'ลองส่งข้อความนี้อีกครั้ง';

  @override
  String get chatMessageRemoveSubtitle => 'ลบข้อความนี้';

  @override
  String get chatWallpaperPreviewHello => 'สวัสดี! 👋';

  @override
  String get chatWallpaperPreviewHow => 'เป็นไงบ้าง?';

  @override
  String get chatGifSearchHint => 'ค้นหา GIF...';

  @override
  String get communitySearchHint => 'ค้นหาหรือพิมพ์ @ผู้ใช้';

  @override
  String communityUserNotFound(String name) {
    return 'ไม่พบผู้ใช้ @$name';
  }

  @override
  String get communityTabAll => 'ทั้งหมด';

  @override
  String get communityTabGender => 'เพศ';

  @override
  String get communityTabCity => 'เมือง';

  @override
  String get communityRefresh => 'รีเฟรช';

  @override
  String get communityNoUsersFound => 'ไม่พบผู้ใช้';

  @override
  String communityUnblockConfirm(String name) {
    return 'แน่ใจหรือว่าต้องการเลิกบล็อก $name?';
  }

  @override
  String get communityUsernameCopied => 'คัดลอกชื่อผู้ใช้แล้ว!';

  @override
  String communityLocationDetected(String country) {
    return 'ตำแหน่ง: $country';
  }

  @override
  String get communityWaveLater => 'ทีหลัง';

  @override
  String get communityAboutMBTI => 'MBTI';

  @override
  String get voiceRoomReactTooltip => 'แสดงปฏิกิริยา';

  @override
  String get momentsCancel => 'ยกเลิก';

  @override
  String get momentsNotNow => 'ไม่ตอนนี้';

  @override
  String get commonOK => 'ตกลง';

  @override
  String commonError(String error) {
    return 'ข้อผิดพลาด: $error';
  }

  @override
  String get chatActiveJustNow => 'ใช้งานเดี๋ยวนี้';

  @override
  String chatActiveMinAgo(int min) {
    return 'ใช้งาน $min นาทีที่แล้ว';
  }

  @override
  String get chatActiveHourAgo => 'ใช้งาน 1 ชม.ที่แล้ว';

  @override
  String chatActiveHoursAgo(int hours) {
    return 'ใช้งาน $hours ชม.ที่แล้ว';
  }

  @override
  String get chatActiveYesterday => 'ใช้งานเมื่อวานนี้';

  @override
  String chatActiveDaysAgo(int days) {
    return 'ใช้งาน $days วันที่แล้ว';
  }

  @override
  String get chatSayHiPrompt => 'ทักทายและเริ่มบทสนทนา!';

  @override
  String get communityConversationStartersTitle => 'คำเริ่มสนทนา';

  @override
  String communityConversationStartersTopic(String topic) {
    return 'พวกคุณทั้งคู่ชอบ $topic — ลองถามอันโปรดของเขา!';
  }

  @override
  String get communityConversationStartersDefault => 'ทักทายและแนะนำตัว!';

  @override
  String get communityConversationChatAction => 'แชท';

  @override
  String get communityConversationMessageCopied => 'คัดลอกข้อความแล้ว! วางเพื่อส่ง';

  @override
  String get communityConversationCopiedToast => 'คัดลอกแล้ว!';

  @override
  String get communityLanguageMatchTitle => 'ภาษาเข้ากัน';

  @override
  String get communityLanguageMatchNative => 'ภาษาแม่';

  @override
  String get communityLanguageMatchLearning => 'กำลังเรียน';

  @override
  String get communityLanguageMatchPerfect => 'แลกภาษากันได้สมบูรณ์แบบ!';

  @override
  String get communityLanguageMatchSameNative => 'คุณใช้ภาษาแม่เดียวกัน';

  @override
  String get momentsFilterApply => 'ใช้';

  @override
  String get momentsCreateAddTo => 'เพิ่มในโมเมนต์ของคุณ';

  @override
  String get momentsCreateCategory => 'หมวดหมู่';

  @override
  String get momentsCreateLanguage => 'ภาษา';

  @override
  String get momentsCreateSchedule => 'กำหนดเวลา (ไม่บังคับ)';

  @override
  String get momentsCreateScheduleForLater => 'กำหนดไว้ภายหลัง';

  @override
  String get momentsPrivacyPublic => 'สาธารณะ';

  @override
  String get momentsPrivacyFriends => 'เพื่อน';

  @override
  String get momentsPrivacyPrivate => 'ส่วนตัว';

  @override
  String get splashTagline => 'เรียนรู้ · สนทนา · พบปะ';

  @override
  String get splashLoading => 'กำลังโหลด…';

  @override
  String get supportSheetGreeting => 'สวัสดี ฉันชื่อฟีร์ดาวส์ 👋';

  @override
  String get supportSheetStory => 'ฉันสร้าง Bananatalk ด้วยตัวเองทั้งหมด — ทุกหน้าจอ ทุกฟีเจอร์ ทุกการแก้ไขบั๊กดึกดื่น เป้าหมายของฉันคือช่วยให้ผู้เรียนภาษาทั่วโลกเชื่อมต่อและเติบโต และฉันก็เพิ่มฟีเจอร์ใหม่อยู่เสมอ\n\nถ้า Bananatalk ช่วยคุณไม่ว่าทางใด แม้แต่กาแฟเล็กน้อยก็ทำให้ฉันมีแรงบันดาลใจในการพัฒนาต่อไป ทุกการสนับสนุนมีความหมายมากสำหรับนักพัฒนาคนเดียว 🙏';

  @override
  String get supportSheetDonateButton => 'บริจาคผ่าน PayPal';

  @override
  String get supportSheetWatchAd => 'ดูโฆษณาเพื่อสนับสนุน';

  @override
  String get occupation => 'อาชีพ';

  @override
  String get school => 'โรงเรียน / มหาวิทยาลัย';

  @override
  String get occupationSearchHint => 'ค้นหาอาชีพ';

  @override
  String get occupationSelectedLabel => 'เลือกแล้ว';

  @override
  String get occupationCustomLabel => 'กำหนดเอง';

  @override
  String get occupationNoMatches => 'ไม่พบในรายการ';

  @override
  String get occupationCatTech => 'เทคโนโลยีและซอฟต์แวร์';

  @override
  String get occupationCatHealthcare => 'การแพทย์และสาธารณสุข';

  @override
  String get occupationCatEducation => 'การศึกษาและวิชาการ';

  @override
  String get occupationCatBusiness => 'ธุรกิจและการเงิน';

  @override
  String get occupationCatCreative => 'งานสร้างสรรค์และดีไซน์';

  @override
  String get occupationCatMedia => 'สื่อและการสื่อสาร';

  @override
  String get occupationCatEngineering => 'วิศวกรรม';

  @override
  String get occupationCatScience => 'วิทยาศาสตร์และงานวิจัย';

  @override
  String get occupationCatLegal => 'กฎหมาย';

  @override
  String get occupationCatHospitality => 'โรงแรมและอาหาร';

  @override
  String get occupationCatTrades => 'งานช่างฝีมือ';

  @override
  String get occupationCatTransport => 'การขนส่งและโลจิสติกส์';

  @override
  String get occupationCatGovernment => 'ราชการและบริการสาธารณะ';

  @override
  String get occupationCatRetail => 'ค้าปลีกและบริการลูกค้า';

  @override
  String get occupationCatAgriculture => 'เกษตรกรรมและสิ่งแวดล้อม';

  @override
  String get occupationCatSports => 'กีฬาและฟิตเนส';

  @override
  String get occupationCatBeauty => 'ความงามและการดูแลตนเอง';

  @override
  String get occupationCatRealEstate => 'อสังหาริมทรัพย์และก่อสร้าง';

  @override
  String get occupationCatReligion => 'ศาสนาและจิตวิญญาณ';

  @override
  String get occupationCatStudent => 'นักเรียน / นักศึกษา';

  @override
  String get occupationCatOther => 'อื่น ๆ';

  @override
  String get schoolHint => 'เช่น จุฬาลงกรณ์มหาวิทยาลัย, โรงเรียนสาธิต';

  @override
  String get birthdate => 'วันเกิด';

  @override
  String get birthdateSelectHelp => 'เลือกวันเกิดของคุณ';

  @override
  String get birthdateSelectPlaceholder => 'เลือกวันที่';

  @override
  String birthdateMinAgeError(int age) {
    return 'คุณต้องมีอายุอย่างน้อย $age ปี';
  }

  @override
  String birthdateQuotaRemaining(int remaining, int max) {
    return 'คุณสามารถเปลี่ยนวันเกิดได้อีก $remaining จาก $max ครั้งใน 60 วันข้างหน้า';
  }

  @override
  String birthdateQuotaLocked(int max) {
    return 'คุณได้ใช้สิทธิ์เปลี่ยนวันเกิด $max ครั้งครบในรอบ 60 วันนี้แล้ว';
  }

  @override
  String birthdateNextChangeOn(String date) {
    return 'เปลี่ยนแปลงครั้งถัดไปได้ในวันที่ $date';
  }

  @override
  String get birthdateRateLimited => 'เปลี่ยนวันเกิดได้สูงสุด 3 ครั้งทุก 60 วัน';

  @override
  String birthdateRateLimitedUntil(String date) {
    return 'เปลี่ยนวันเกิดได้สูงสุด 3 ครั้งทุก 60 วัน โปรดลองอีกครั้งในวันที่ $date';
  }

  @override
  String get changePassword => 'เปลี่ยนรหัสผ่าน';

  @override
  String get currentPassword => 'รหัสผ่านปัจจุบัน';

  @override
  String get newPasswordLabel => 'รหัสผ่านใหม่';

  @override
  String get confirmNewPassword => 'ยืนยันรหัสผ่านใหม่';

  @override
  String get currentPasswordHint => 'ป้อนรหัสผ่านปัจจุบัน';

  @override
  String get newPasswordHint => 'อย่างน้อย 8 ตัวอักษร, A-Z, a-z, 0-9';

  @override
  String get passwordsDontMatch => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get newPasswordSameAsCurrent => 'รหัสผ่านใหม่ต้องต่างจากรหัสผ่านปัจจุบัน';

  @override
  String get passwordChangedSuccess => 'เปลี่ยนรหัสผ่านสำเร็จ';

  @override
  String get passwordRule8Chars => 'อย่างน้อย 8 ตัวอักษร';

  @override
  String get passwordRuleLowercase => 'ตัวพิมพ์เล็ก 1 ตัว';

  @override
  String get passwordRuleUppercase => 'ตัวพิมพ์ใหญ่ 1 ตัว';

  @override
  String get passwordRuleNumber => 'ตัวเลข 1 ตัว';

  @override
  String get settingsAccountSection => 'บัญชี';

  @override
  String get changePasswordTileSubtitle => 'อัปเดตรหัสผ่านบัญชีของคุณ';

  @override
  String get occupationCustomTab => 'กำหนดเอง';

  @override
  String get occupationCustomTabHint => 'ไม่พบอาชีพของคุณใช่ไหม? พิมพ์ที่นี่';

  @override
  String get occupationCustomInputHint => 'เช่น นักชีววิทยาทางทะเล, นักพากย์';

  @override
  String get occupationCustomSaveCTA => 'ใช้สิ่งนี้เป็นอาชีพของฉัน';

  @override
  String get vipSelectPlan => 'เลือกแพ็กเกจ';

  @override
  String get vipBenefits => 'สิทธิประโยชน์';

  @override
  String get vipBestValue => 'คุ้มที่สุด';

  @override
  String get vipPlanMonth => '1 เดือน';

  @override
  String get vipPlanThreeMonths => '3 เดือน';

  @override
  String get vipPlanTwelveMonths => '12 เดือน';

  @override
  String get vipOneTime => 'ชำระครั้งเดียว';

  @override
  String get vipNonVip => 'ไม่ใช่ VIP';

  @override
  String get vipBenefitDailyTranslations => 'การแปลรายวัน';

  @override
  String get vipBenefitTranslationsLimit => '5 / วัน';

  @override
  String get vipBenefitUnlimited => 'ไม่จำกัด';

  @override
  String get vipBenefitAdvancedFilters => 'ตัวกรองขั้นสูง';

  @override
  String get vipBenefitAdFree => 'ไม่มีโฆษณา';

  @override
  String get vipBenefitVipBadge => 'เครื่องหมาย VIP บนโปรไฟล์';

  @override
  String get vipBenefitPrioritySupport => 'ฝ่ายสนับสนุนแบบเร่งด่วน';

  @override
  String get vipBrandTitle => 'BananaTalk VIP';

  @override
  String get vipTagline => 'พาสปอร์ตของคุณสู่การเชื่อมต่อทั่วโลก — บทสนทนาจริงใจ มิตรภาพยาวนาน';

  @override
  String get vipDisclosure => 'ต่ออายุอัตโนมัติ เว้นแต่จะยกเลิกก่อนสิ้นสุดรอบบิล 24 ชม. ระบบจะหักเงินจากบัญชี iTunes หรือ Google Play ของคุณ';

  @override
  String get vipLoginRequired => 'กรุณาเข้าสู่ระบบเพื่อดำเนินการต่อ';

  @override
  String get chatListMenu => 'Menu';

  @override
  String get chatListNewMessageAlertsTitle => 'New Message Alerts';

  @override
  String get chatListNewMessageAlertsBody => 'Tap to turn on notifications and never miss a message';

  @override
  String get chatListFilterMyTurn => 'My turn';

  @override
  String get partnerTagActiveNow => 'Active now';

  @override
  String get partnerTagVeryResponsive => 'Very Responsive';

  @override
  String get partnerTagQuickToReply => 'Quick to Reply';

  @override
  String vipSavePercent(int pct) {
    return 'ประหยัด $pct%';
  }

  @override
  String vipPerMonth(String price) {
    return '$price / เดือน';
  }

  @override
  String partnerTagBothLike(String topic) {
    return 'Both like $topic';
  }

  @override
  String partnerTagSpeaks(String language) {
    return 'Speaks $language';
  }

  @override
  String partnerTagLearning(String language) {
    return 'Learning $language';
  }

  @override
  String partnerTagJoinedDaysAgo(int days) {
    return 'Joined ${days}d ago';
  }

  @override
  String get vipPaymentPlanSummary => 'สรุปแพ็กเกจ';

  @override
  String get vipPaymentSelectMethod => 'เลือกวิธีชำระเงิน';

  @override
  String get vipPaymentPurchaseAppStore => 'ซื้อผ่าน App Store';

  @override
  String get vipPaymentPurchaseGooglePlay => 'ซื้อผ่าน Google Play';

  @override
  String get vipPaymentSecureAppStore => 'การซื้อของคุณจะดำเนินการอย่างปลอดภัยผ่าน App Store';

  @override
  String get vipPaymentSecureGooglePlay => 'การซื้อของคุณจะดำเนินการอย่างปลอดภัยผ่าน Google Play';

  @override
  String get vipPaymentSubscriptionInfo => 'ข้อมูลการสมัครสมาชิก';

  @override
  String get vipPaymentInfoLabelTitle => 'ชื่อ';

  @override
  String get vipPaymentInfoLabelLength => 'ระยะเวลา';

  @override
  String get vipPaymentInfoLabelPrice => 'ราคา';

  @override
  String get vipPaymentDisclosure => 'เมื่อทำการซื้อสำเร็จ ถือว่าคุณยอมรับข้อกำหนดการใช้งานและนโยบายความเป็นส่วนตัวของเรา การสมัครสมาชิกจะต่ออายุอัตโนมัติ เว้นแต่จะยกเลิกอย่างน้อย 24 ชั่วโมงก่อนสิ้นสุดรอบปัจจุบัน';

  @override
  String get vipSuccessTitle => 'ยินดีต้อนรับสู่ VIP!';

  @override
  String get vipSuccessBody => 'การสมัครสมาชิก VIP ของคุณเริ่มใช้งานแล้ว เพลิดเพลินกับฟีเจอร์พรีเมียมทั้งหมด!';

  @override
  String get vipPendingTitle => 'ใกล้เสร็จแล้ว';

  @override
  String get vipPendingBody => 'การสมัครสมาชิกของคุณกำลังดำเนินการ — โปรดลองรีเฟรชอีกครั้งในอีกสักครู่';

  @override
  String get vipErrorPaymentTitle => 'ข้อผิดพลาดในการชำระเงิน';

  @override
  String get vipErrorPurchaseTitle => 'ข้อผิดพลาดในการซื้อ';

  @override
  String get vipErrorVerifyTitle => 'ยืนยันการซื้อไม่สำเร็จ';

  @override
  String get vipErrorPaymentFailed => 'ชำระเงินไม่สำเร็จ';

  @override
  String get vipErrorBodyPrefix => 'เกิดข้อผิดพลาดขณะดำเนินการชำระเงิน:';

  @override
  String get vipErrorPurchaseCanceled => 'การซื้อถูกยกเลิกหรือไม่สำเร็จ โปรดลองอีกครั้ง';

  @override
  String get vipErrorVerifyServer => 'ไม่สามารถยืนยันการซื้อกับเซิร์ฟเวอร์ได้ โปรดติดต่อฝ่ายสนับสนุน';

  @override
  String get vipPlanLengthOneMonth => '1 เดือน';

  @override
  String get vipPlanLengthThreeMonths => '3 เดือน';

  @override
  String get vipPlanLengthOneYear => '1 ปี';

  @override
  String vipPaymentPayPrice(String price) {
    return 'ชำระ $price';
  }

  @override
  String get vipExpired => 'VIP หมดอายุ';

  @override
  String get vipMember => 'สมาชิก VIP';

  @override
  String get chatPhrasesMostUsed => 'ใช้บ่อย';

  @override
  String get chatPhrasesTopics => 'หัวข้อ';

  @override
  String get chatPhrasesAddPhrase => 'เพิ่มประโยค';

  @override
  String get chatPhrasesChange => 'เปลี่ยน';

  @override
  String get chatPhrasesAddTitle => 'เพิ่มประโยค';

  @override
  String get chatPhrasesAddHint => 'พิมพ์ประโยคที่คุณใช้บ่อย';

  @override
  String get chatPhrasesEmptyMostUsed => 'ยังไม่มีประโยคที่บันทึกไว้ แตะ + เพื่อเพิ่ม';

  @override
  String get chatPhrasesDeleteTitle => 'ลบประโยคนี้?';

  @override
  String get filterVipPromoTitle => 'เจอคู่ที่ใช่ได้เร็วขึ้น';

  @override
  String get filterVipPromoSubtitle => 'ปลดล็อกการค้นหาแบบเร่งด่วน ตัวกรองขั้นสูง และแชทไร้โฆษณาด้วย VIP';

  @override
  String get filterVipPromoCta => 'สมัคร VIP';

  @override
  String get examStudy => 'Exam Study';

  @override
  String get examStudyChooseLanguage => 'Choose your study language';

  @override
  String get examStudyChooseLanguageSubtitle => 'Pick the language you want to prepare an exam in.';

  @override
  String get examStudyLoading => 'Loading…';

  @override
  String get examStudyEmptyLanguages => 'No study languages available yet.';

  @override
  String get examStudyError => 'Couldn\'t load — please try again.';

  @override
  String get examStudyRetry => 'Retry';

  @override
  String get examPickExam => 'Choose an exam';

  @override
  String get examPickExamSubtitle => 'Pick the exam you want to prepare for.';

  @override
  String get examPickEmpty => 'No exams available for this language yet.';

  @override
  String get examDashboardSections => 'Sections';

  @override
  String get examDashboardEmptySections => 'No sections to practice yet.';

  @override
  String get examDashboardContinue => 'Continue practice';

  @override
  String get examDashboardStartStudyPlan => 'Start study plan';

  @override
  String get examDashboardViewProgress => 'View progress';

  @override
  String examMetaDuration(int minutes) {
    return '$minutes min';
  }

  @override
  String examMetaMaxScore(String score) {
    return 'Max $score';
  }

  @override
  String examMetaSections(int count) {
    return '$count sections';
  }

  @override
  String get examSectionNotStarted => 'Not started';

  @override
  String examSectionProgress(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get examQuestionSubmit => 'Submit answer';

  @override
  String get examQuestionNext => 'Next question';

  @override
  String get examQuestionCorrect => 'Correct!';

  @override
  String get examQuestionIncorrect => 'Incorrect';

  @override
  String get examQuestionExplanation => 'Explanation';

  @override
  String get examQuestionNoQuestions => 'No questions in this section yet.';

  @override
  String get examQuestionEssayComingSoon => 'Essay evaluation is coming soon. Try a reading section for now.';

  @override
  String get examQuestionUnsupported => 'This question type isn\'t supported yet.';

  @override
  String get examPracticeFinishedTitle => 'Section complete';

  @override
  String get examPracticeFinishedBody => 'Nice work — you\'ve completed every question in this section.';

  @override
  String get examPracticeBackToDashboard => 'Back to dashboard';

  @override
  String examPracticeProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get examEssayPrompt => 'Write your essay';

  @override
  String examEssayMinChars(int min) {
    return 'Essay must be at least $min characters';
  }

  @override
  String examEssayMaxChars(int max) {
    return 'Essay must not exceed $max characters';
  }

  @override
  String examEssayWordCount(int count) {
    return '$count words';
  }

  @override
  String examEssayCharCount(int count) {
    return '$count characters';
  }

  @override
  String get examEssaySubmit => 'Submit essay';

  @override
  String get examEssayEvaluating => 'Evaluating your essay…';

  @override
  String get examEssayEvaluatingHint => 'This usually takes 10–30 seconds. You can leave this screen — we\'ll keep evaluating in the background.';

  @override
  String get examEssayResultTitle => 'Evaluation';

  @override
  String get examEssayResultStrengths => 'Strengths';

  @override
  String get examEssayResultImprovements => 'Suggestions';

  @override
  String get examEssayResultScore => 'Score';

  @override
  String get examEssayResultFailed => 'Couldn\'t evaluate this essay.';

  @override
  String get examEssayResultRetry => 'Try again';

  @override
  String get examEssayResultDone => 'Done';

  @override
  String get examEssayPollTimeout => 'Still evaluating — check back in a minute.';

  @override
  String get examEssayPollRefresh => 'Check again';

  @override
  String examEssayQuotaUsed(int used, int limit) {
    return 'Daily essay evaluations: $used/$limit';
  }

  @override
  String get examEssayQuotaExhausted => 'You\'ve used today\'s free essay evaluations. Upgrade to VIP for unlimited.';

  @override
  String get examEssayQuotaUpgrade => 'Upgrade to VIP';

  @override
  String get examEssayDraftRestored => 'Draft restored';

  @override
  String get examProgressTitle => 'Progress';

  @override
  String get examProgressOverall => 'Overall score';

  @override
  String get examProgressNotStartedTitle => 'No practice yet';

  @override
  String get examProgressNotStartedBody => 'Answer a few questions in any section to see your progress here.';

  @override
  String get examProgressFocusAreas => 'Focus areas';

  @override
  String examProgressSectionAttempts(int done, int total) {
    return '$done of $total attempted';
  }

  @override
  String get examProgressNoFocusAreas => 'You\'re doing well across every section — keep practicing!';

  @override
  String get examPlanSetupTitle => 'Start study plan';

  @override
  String get examPlanTargetScore => 'Target score';

  @override
  String get examPlanExamDate => 'Exam date';

  @override
  String get examPlanPickDate => 'Pick a date';

  @override
  String get examPlanGenerate => 'Generate plan';

  @override
  String get examPlanGenerating => 'Generating your plan…';

  @override
  String get examPlanInvalidDate => 'Please pick a future exam date.';

  @override
  String get examPlanInvalidScore => 'Please enter a valid target score.';

  @override
  String get examPlanTitle => 'Study plan';

  @override
  String get examPlanEmptyTitle => 'No active plan';

  @override
  String get examPlanEmptyBody => 'Generate a plan to get weekly milestones tailored to your weak areas.';

  @override
  String get examPlanRegenerate => 'Regenerate plan';

  @override
  String examPlanWeek(int n) {
    return 'Week $n';
  }

  @override
  String examPlanWeekEstimate(String hours) {
    return '${hours}h';
  }

  @override
  String examPlanTotalHours(int hours) {
    return '$hours hours total';
  }

  @override
  String get examPlanDailyHeading => 'Suggested daily lessons';

  @override
  String examPlanLessonMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get examTopicPickerTitle => 'Pick a topic';

  @override
  String get examTopicPickerSubtitle => 'Practice questions on a specific subject, or jump into all questions.';

  @override
  String get examTopicAllTopics => 'All topics';

  @override
  String get examTopicAllTopicsDescription => 'Mix from every available topic';

  @override
  String get examTopicEmpty => 'No topical content yet. Tap All topics to start practicing.';

  @override
  String examTopicQuestionCount(int count) {
    return '$count questions';
  }

  @override
  String get examTopicOneQuestion => '1 question';

  @override
  String get examSpeakingPrompt => 'Speak your answer';

  @override
  String get examSpeakingListenToPrompt => 'Listen to prompt';

  @override
  String get examSpeakingTapToRecord => 'Tap to record your answer';

  @override
  String get examSpeakingTranscriptHeading => 'What we heard';

  @override
  String get examSpeakingPart1 => 'Speaking — Part 1';

  @override
  String get examSpeakingPart2 => 'Speaking — Part 2';

  @override
  String get examSpeakingPart3 => 'Speaking — Part 3';

  @override
  String get examSpeakingSubmit => 'Submit recording';

  @override
  String get examSpeakingUploading => 'Uploading…';

  @override
  String get examSpeakingTooShort => 'Recording is too short. Please speak for at least a few seconds.';

  @override
  String get examGroupWriting => 'Writing';

  @override
  String get examGroupSpeaking => 'Speaking';

  @override
  String examGroupWritingSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String examGroupSpeakingSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parts',
      one: '1 part',
    );
    return '$_temp0';
  }

  @override
  String get examVocabLevelPickerTitle => 'Pick a level';

  @override
  String get examVocabLevelPickerSubtitle => 'Browse words and practice quizzes by CEFR level.';

  @override
  String get examVocabTopicPickerTitle => 'Pick a topic';

  @override
  String get examVocabAllTopics => 'All topics';

  @override
  String get examVocabBrowse => 'Browse';

  @override
  String get examVocabPractice => 'Practice';

  @override
  String get examVocabEmptyList => 'No words yet for this level and topic.';

  @override
  String get examVocabQuizComplete => 'Quiz complete';

  @override
  String examVocabQuizScore(int correct, int total) {
    return 'You answered $correct of $total correctly';
  }

  @override
  String get examVocabQuizYourAnswer => 'Your answer';

  @override
  String get examVocabQuizCorrectAnswer => 'Correct answer';

  @override
  String get examVocabQuizSubmit => 'Submit';

  @override
  String get examVocabQuizSubmitting => 'Submitting…';

  @override
  String get examVocabQuizNext => 'Next';

  @override
  String get examVocabQuizPrev => 'Back';

  @override
  String get examVocabQuizRestart => 'Restart';

  @override
  String get examVocabQuizEmpty => 'No questions could be generated. Try another topic or level.';

  @override
  String get examVocabQuizNotEnough => 'Not enough words at this level and topic to build a quiz.';

  @override
  String get examVocabQuizExpiredTitle => 'Quiz expired';

  @override
  String get examVocabQuizExpiredBody => 'This quiz has been idle too long. Restart to get a fresh one.';

  @override
  String get examVocabTranslate => 'Translate';

  @override
  String get examVocabTranslateFailed => 'Translation unavailable. Try again later.';

  @override
  String get examDashboardTips => 'Tips';

  @override
  String get examTipsTitle => 'Tips & Techniques';

  @override
  String examTipsSubtitle(String examName) {
    return 'Curated strategy notes for $examName.';
  }

  @override
  String get examTipsEmpty => 'No tips have been published for this exam yet.';

  @override
  String get examTipsCategoryStrategy => 'Strategy';

  @override
  String get examTipsCategoryGrammar => 'Grammar';

  @override
  String get examTipsCategoryVocabulary => 'Vocabulary';

  @override
  String get examTipsCategoryTimeManagement => 'Time Management';

  @override
  String get examTipsCategoryCommonMistakes => 'Common Mistakes';

  @override
  String get examTipsCategoryBandBooster => 'Band Boosters';

  @override
  String get examTipsCategoryCulturalNotes => 'Cultural Notes';

  @override
  String get examTipsCategoryPronunciation => 'Pronunciation';

  @override
  String get examTipsCategoryFluency => 'Fluency';

  @override
  String get roomsNewRoom => 'ห้องใหม่';

  @override
  String get roomsCouldNotLoad => 'ไม่สามารถโหลดห้องได้';

  @override
  String get roomsEmptyTitle => 'ยังไม่มีห้องภาษา';

  @override
  String get roomsEmptySubtitle => 'กลับมาดูใหม่เร็ว ๆ นี้ — กำลังจัดเตรียมฮับอยู่';

  @override
  String get roomCreateTitle => 'สร้างห้องหัวข้อใหม่';

  @override
  String get roomCreateSubtitle => 'เริ่มแชทเฉพาะทางภายใต้ภาษาหนึ่ง';

  @override
  String get roomNameLabel => 'ชื่อห้อง';

  @override
  String get roomNameHint => 'เช่น ฝึกสนทนาประจำวัน';

  @override
  String get roomDescriptionLabel => 'คำอธิบาย (ไม่บังคับ)';

  @override
  String get roomDescriptionHint => 'ห้องนี้เกี่ยวกับอะไร?';

  @override
  String get roomCreateSubmit => 'สร้างห้อง';

  @override
  String get roomNameRequired => 'กรุณากรอกชื่อห้อง';

  @override
  String get roomCreateError => 'ไม่สามารถสร้างห้องได้ กรุณาลองใหม่อีกครั้ง';

  @override
  String get roomUsEnglish => 'ภาษาอังกฤษ (สหรัฐฯ)';

  @override
  String get roomUkEnglish => 'ภาษาอังกฤษ (สหราชอาณาจักร)';

  @override
  String get roomFailedLoadMessages => 'โหลดข้อความไม่สำเร็จ';

  @override
  String get roomReportMessageTitle => 'รายงานข้อความ';

  @override
  String get reportReasonSpam => 'สแปม';

  @override
  String get reportReasonHarassment => 'การคุกคามหรือกลั่นแกล้ง';

  @override
  String get reportReasonHateSpeech => 'วาจาสร้างความเกลียดชัง';

  @override
  String get reportReasonViolence => 'ความรุนแรงหรือการข่มขู่';

  @override
  String get reportReasonNudity => 'ภาพโป๊เปลือยหรือเนื้อหาทางเพศ';

  @override
  String get reportReasonFalseInformation => 'ข้อมูลเท็จ';

  @override
  String get roomReportSubmitted => 'ส่งรายงานแล้ว';

  @override
  String get roomReportSubmitFailed => 'ส่งรายงานไม่สำเร็จ';

  @override
  String get roomLeaveHubTitle => 'ออกจากฮับ?';

  @override
  String roomLeaveHubMessage(String title) {
    return 'คุณสามารถเข้าร่วม $title อีกครั้งได้ภายหลังจากไดเรกทอรีห้อง';
  }

  @override
  String get roomLeaveHubFailed => 'ออกจากฮับไม่สำเร็จ';

  @override
  String get roomJoinRequestSent => 'ส่งคำขอแล้ว — คุณจะได้รับการแจ้งเตือนหากได้รับการอนุมัติ';

  @override
  String get roomJoinRequestFailed => 'ส่งคำขอไม่สำเร็จ';

  @override
  String roomRequestsMenuItem(int count) {
    return 'คำขอ ($count)';
  }

  @override
  String get roomViewMembers => 'ดูสมาชิก';

  @override
  String get roomLeaveHubMenuItem => 'ออกจากฮับ';

  @override
  String roomMemberOnlineCount(int members, int online) {
    return 'สมาชิก $members คน · ออนไลน์ $online คน';
  }

  @override
  String get roomBannedRequestMessage => 'คุณถูกนำออกจากห้องนี้แล้ว ส่งคำขอเพื่อเข้าร่วมอีกครั้ง — เจ้าของห้องต้องอนุมัติ';

  @override
  String get roomModeratedRequestMessage => 'ห้องนี้มีการควบคุมดูแล ส่งคำขอเพื่อเข้าร่วมและเริ่มแชท';

  @override
  String get roomRequestPending => 'คำขอรอดำเนินการ';

  @override
  String get roomRequestToJoin => 'ขอเข้าร่วม';

  @override
  String get roomDailyPromptLabel => 'หัวข้อวันนี้';

  @override
  String get roomSomeoneFallback => 'บางคน';

  @override
  String get roomRequestsLoadError => 'ไม่สามารถโหลดคำขอเข้าร่วมได้';

  @override
  String get roomRequestApproved => 'อนุมัติคำขอแล้ว';

  @override
  String get roomRequestDenied => 'ปฏิเสธคำขอแล้ว';

  @override
  String get roomRequestApproveFailed => 'อนุมัติคำขอไม่สำเร็จ';

  @override
  String get roomRequestDenyFailed => 'ปฏิเสธคำขอไม่สำเร็จ';

  @override
  String roomRequestsAppBarTitle(String title) {
    return '$title · คำขอ';
  }

  @override
  String get roomRequestsEmpty => 'ไม่มีคำขอที่รอดำเนินการ';

  @override
  String get roomRequestDeny => 'ปฏิเสธ';

  @override
  String get roomRequestApprove => 'อนุมัติ';

  @override
  String get roomMembersLoadError => 'ไม่สามารถโหลดสมาชิกได้';

  @override
  String get roomRemoveBanTitle => 'นำออกและแบนสมาชิก?';

  @override
  String get roomRemoveTitle => 'นำสมาชิกออก?';

  @override
  String roomRemoveBanConfirm(String name) {
    return 'นำออกและแบน $name? พวกเขาจะไม่สามารถเข้าร่วมอีกได้ เว้นแต่คุณจะอนุมัติคำขอ';
  }

  @override
  String roomRemoveConfirm(String name, String title) {
    return 'นำ $name ออกจาก $title?';
  }

  @override
  String get roomRemoveBanButton => 'นำออกและแบน';

  @override
  String get roomRemoveButton => 'นำออก';

  @override
  String get roomMemberRemovedBanned => 'นำสมาชิกออกและแบนแล้ว';

  @override
  String get roomMemberRemoved => 'นำสมาชิกออกแล้ว';

  @override
  String get roomMemberRemoveFailed => 'นำสมาชิกออกไม่สำเร็จ';

  @override
  String get roomMemberMuted => 'ปิดเสียงสมาชิกแล้ว';

  @override
  String get roomMemberUnmuted => 'เปิดเสียงสมาชิกแล้ว';

  @override
  String get roomMemberMuteFailed => 'อัปเดตสถานะปิดเสียงไม่สำเร็จ';

  @override
  String roomMembersAppBarTitle(String title) {
    return '$title · สมาชิก';
  }

  @override
  String get roomMembersEmpty => 'ยังไม่มีสมาชิกให้แสดง';

  @override
  String get roomMemberMutedLabel => 'ปิดเสียงแล้ว';

  @override
  String get roomMemberFallbackName => 'สมาชิก';

  @override
  String get roomYourHub => 'ฮับของคุณ';

  @override
  String roomOnlineCount(int count) {
    return 'ออนไลน์ $count คน';
  }

  @override
  String get roomNotAvailable => 'ห้องนี้ไม่พร้อมใช้งานอีกต่อไป';

  @override
  String get roomGoToRooms => 'ไปที่ห้อง';
}
