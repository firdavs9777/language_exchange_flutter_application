// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Bananatalk';

  @override
  String get aiStudyPromoTitle => 'Luyện tập với kịch bản AI';

  @override
  String get aiStudyPromoBody => 'Đóng vai các cuộc trò chuyện đời thực cùng gia sư AI và xây dựng sự tự tin khi nói.';

  @override
  String get aiStudyPromoCTA => 'Thử một kịch bản';

  @override
  String get aiStudyPromoDismiss => 'Để sau';

  @override
  String get promoSpotlightCoinsHeadline => 'Đừng bao giờ hết xu giữa cuộc trò chuyện';

  @override
  String get promoSpotlightCoinsSubtitle => 'Nhận xu để mở khóa thêm bản dịch, trò chuyện với gia sư và khoảnh khắc mỗi khi bạn đạt giới hạn hàng ngày.';

  @override
  String get promoSpotlightRoomsHeadline => 'Tham gia một phòng chủ đề';

  @override
  String get promoSpotlightRoomsSubtitle => 'Vào một phòng trò chuyện văn bản trực tiếp và luyện tập cùng những người học đang nói về chủ đề bạn quan tâm.';

  @override
  String get promoSpotlightVoiceHeadline => 'Tham gia một phòng thoại';

  @override
  String get promoSpotlightVoiceSubtitle => 'Trò chuyện trực tiếp với những người học khác và xây dựng sự tự tin nói thật sự, từng cuộc trò chuyện một.';

  @override
  String get promoSpotlightTryIt => 'Thử ngay';

  @override
  String get promoSpotlightMaybeLater => 'Để sau';

  @override
  String get promoSpotlightDontShowAgain => 'Không hiển thị lại';

  @override
  String get login => 'Đăng nhập';

  @override
  String get signUp => 'Đăng ký';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get or => 'HOẶC';

  @override
  String get more => 'thêm';

  @override
  String get signInWithGoogle => 'Đăng nhập với Google';

  @override
  String get signInWithApple => 'Đăng nhập với Apple';

  @override
  String get signInWithFacebook => 'Đăng nhập với Facebook';

  @override
  String get welcome => 'Chào mừng';

  @override
  String get home => 'Trang chủ';

  @override
  String get messages => 'Tin nhắn';

  @override
  String get moments => 'Khoảnh khắc';

  @override
  String get overview => 'Tổng quan';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get settings => 'Cài đặt';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get selectLanguage => 'Chọn ngôn ngữ';

  @override
  String get autoTranslate => 'Tự động dịch';

  @override
  String get autoTranslateMessages => 'Tự động dịch tin nhắn';

  @override
  String get autoTranslateMoments => 'Tự động dịch khoảnh khắc';

  @override
  String get autoTranslateComments => 'Tự động dịch bình luận';

  @override
  String get translate => 'Dịch';

  @override
  String get translated => 'Đã dịch';

  @override
  String get showOriginal => 'Hiển thị bản gốc';

  @override
  String get showTranslation => 'Hiển thị bản dịch';

  @override
  String get translating => 'Đang dịch...';

  @override
  String get translationFailed => 'Dịch thất bại';

  @override
  String get noTranslationAvailable => 'Không có bản dịch';

  @override
  String translatedFrom(String language) {
    return 'Dịch từ $language';
  }

  @override
  String get save => 'Lưu';

  @override
  String get cancel => 'Hủy';

  @override
  String get delete => 'Xóa';

  @override
  String get edit => 'Chỉnh sửa';

  @override
  String get share => 'Chia sẻ';

  @override
  String get like => 'Thích';

  @override
  String get comment => 'Bình luận';

  @override
  String get send => 'Gửi';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get notifications => 'Thông báo';

  @override
  String get followers => 'Người theo dõi';

  @override
  String get following => 'Đang theo dõi';

  @override
  String get posts => 'Bài đăng';

  @override
  String get visitors => 'Khách truy cập';

  @override
  String get loading => 'Đang tải...';

  @override
  String get error => 'Lỗi';

  @override
  String get success => 'Thành công';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get networkError => 'Lỗi mạng. Vui lòng kiểm tra kết nối.';

  @override
  String get somethingWentWrong => 'Đã xảy ra lỗi';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Có';

  @override
  String get no => 'Không';

  @override
  String get languageSettings => 'Cài đặt ngôn ngữ';

  @override
  String get deviceLanguage => 'Ngôn ngữ thiết bị';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return 'Thiết bị của bạn được đặt thành: $flag $name';
  }

  @override
  String get youCanOverride => 'Bạn có thể ghi đè ngôn ngữ thiết bị bên dưới.';

  @override
  String languageChangedTo(String name) {
    return 'Đã đổi ngôn ngữ thành $name';
  }

  @override
  String get errorChangingLanguage => 'Lỗi khi đổi ngôn ngữ';

  @override
  String get autoTranslateSettings => 'Cài đặt tự động dịch';

  @override
  String get automaticallyTranslateIncomingMessages => 'Tự động dịch tin nhắn đến';

  @override
  String get automaticallyTranslateMomentsInFeed => 'Tự động dịch khoảnh khắc trong bảng tin';

  @override
  String get automaticallyTranslateComments => 'Tự động dịch bình luận';

  @override
  String get translationServiceBeingConfigured => 'Dịch vụ dịch đang được cấu hình. Vui lòng thử lại sau.';

  @override
  String get translationUnavailable => 'Không thể dịch';

  @override
  String get showLess => 'thu gọn';

  @override
  String get showMore => 'xem thêm';

  @override
  String get comments => 'Bình luận';

  @override
  String get beTheFirstToComment => 'Hãy là người đầu tiên bình luận.';

  @override
  String get loadMoreComments => 'Xem thêm bình luận';

  @override
  String get writeAComment => 'Viết bình luận...';

  @override
  String get report => 'Báo cáo';

  @override
  String get reportMoment => 'Báo cáo khoảnh khắc';

  @override
  String get reportUser => 'Báo cáo người dùng';

  @override
  String get deleteMoment => 'Xóa khoảnh khắc?';

  @override
  String get thisActionCannotBeUndone => 'Hành động này không thể hoàn tác.';

  @override
  String get momentDeleted => 'Đã xóa khoảnh khắc';

  @override
  String get deleteComment => 'Xóa bình luận?';

  @override
  String get commentDeleted => 'Đã xóa bình luận';

  @override
  String get editFeatureComingSoon => 'Tính năng chỉnh sửa sắp ra mắt';

  @override
  String get userNotFound => 'Không tìm thấy người dùng';

  @override
  String get cannotReportYourOwnComment => 'Không thể báo cáo bình luận của chính bạn';

  @override
  String get profileSettings => 'Cài đặt hồ sơ';

  @override
  String get editYourProfileInformation => 'Chỉnh sửa thông tin hồ sơ';

  @override
  String get blockedUsers => 'Người dùng bị chặn';

  @override
  String get manageBlockedUsers => 'Quản lý người dùng bị chặn';

  @override
  String get manageNotificationSettings => 'Quản lý cài đặt thông báo';

  @override
  String get privacySecurity => 'Quyền riêng tư & Bảo mật';

  @override
  String get controlYourPrivacy => 'Kiểm soát quyền riêng tư';

  @override
  String get changeAppLanguage => 'Đổi ngôn ngữ ứng dụng';

  @override
  String get appearance => 'Giao diện';

  @override
  String get themeAndDisplaySettings => 'Cài đặt chủ đề và hiển thị';

  @override
  String get clearCache => 'Xóa bộ nhớ đệm';

  @override
  String get clearCacheSubtitle => 'Giải phóng dung lượng lưu trữ';

  @override
  String get clearCacheDescription => 'Thao tác này sẽ xóa tất cả hình ảnh, video và file âm thanh đã lưu trong bộ nhớ đệm. Ứng dụng có thể tải nội dung chậm hơn tạm thời khi tải lại phương tiện.';

  @override
  String get clearCacheHint => 'Sử dụng tính năng này nếu hình ảnh hoặc âm thanh không tải đúng cách.';

  @override
  String get clearingCache => 'Đang xóa bộ nhớ đệm...';

  @override
  String get cacheCleared => 'Đã xóa bộ nhớ đệm thành công! Hình ảnh sẽ được tải lại.';

  @override
  String get clearCacheFailed => 'Không thể xóa bộ nhớ đệm';

  @override
  String get myReports => 'Báo cáo của tôi';

  @override
  String get viewYourSubmittedReports => 'Xem các báo cáo đã gửi';

  @override
  String get reportsManagement => 'Quản lý báo cáo';

  @override
  String get manageAllReportsAdmin => 'Quản lý tất cả báo cáo (Admin)';

  @override
  String get legalPrivacy => 'Pháp lý & Quyền riêng tư';

  @override
  String get termsPrivacySubscriptionInfo => 'Điều khoản, Quyền riêng tư & Thông tin đăng ký';

  @override
  String get helpCenter => 'Trung tâm trợ giúp';

  @override
  String get getHelpAndSupport => 'Nhận trợ giúp và hỗ trợ';

  @override
  String get aiTutorChangePersona => 'Đổi gia sư AI';

  @override
  String get aiTutorChangePersonaSubtitle => 'Chuyển sang Nana, Sensei hoặc Riko';

  @override
  String aiTutorHeroTitleSet(String name) {
    return 'Gia sư AI của bạn · $name';
  }

  @override
  String get aiTutorHeroTitleNew => 'Gặp gia sư AI của bạn';

  @override
  String get aiTutorHeroSubtitleSet => 'Chạm để trò chuyện hoặc xem kế hoạch hôm nay';

  @override
  String aiTutorHeroSubtitleLast(String summary) {
    return 'Lần trước: $summary';
  }

  @override
  String get aiTutorHeroSubtitleNew => 'Chọn một nhân vật — Nana, Sensei hoặc Riko';

  @override
  String get aiTutorChipChat => 'Trò chuyện';

  @override
  String get aiTutorChipRoleplay => 'Đóng vai';

  @override
  String get aiTutorChipStory => 'Câu chuyện';

  @override
  String get aiTutorChipPhoto => 'Ảnh';

  @override
  String get aiToolsMoreSection => 'Thêm công cụ AI';

  @override
  String get aiConversationPartnerTile => 'Hội thoại AI';

  @override
  String get aiConversationPartnerTileSubtitle => 'Luyện tập với đối tác AI';

  @override
  String get aiTutorPickerTitle => 'Chọn gia sư AI';

  @override
  String get aiTutorPickerHeader => 'Bạn muốn học cùng ai?';

  @override
  String get aiTutorPickerSubtitle => 'Bạn có thể thay đổi bất kỳ lúc nào trong cài đặt.';

  @override
  String get aiTutorPersonaNanaTagline => 'Ấm áp + khích lệ';

  @override
  String get aiTutorPersonaNanaSample => 'Mình sẽ cổ vũ bạn, không áp lực.';

  @override
  String get aiTutorPersonaSenseiTagline => 'Chính xác + tập trung thi cử';

  @override
  String get aiTutorPersonaSenseiSample => 'Chúng ta sẽ làm chủ các quy tắc.';

  @override
  String get aiTutorPersonaRikoTagline => 'Vui vẻ + thân mật';

  @override
  String get aiTutorPersonaRikoSample => 'nào cùng vui vẻ và học thôi';

  @override
  String aiTutorPickerSaveError(String error) {
    return 'Không lưu được: $error';
  }

  @override
  String get aiTutorHomeTitle => 'Gia sư AI';

  @override
  String get aiTutorHomeChangeTutor => 'Đổi gia sư';

  @override
  String get aiTutorHomeGreetingDefault => 'Chào! Sẵn sàng học cùng nhau chưa?';

  @override
  String get aiTutorHomeTodaysPlan => 'Kế hoạch hôm nay';

  @override
  String get aiTutorHomePlanEmpty => 'Hôm nay chưa có kế hoạch — bắt đầu trò chuyện để bắt đầu.';

  @override
  String get aiTutorHomeStartChat => 'Bắt đầu trò chuyện';

  @override
  String get aiTutorHomeRecent => 'Gần đây';

  @override
  String get aiTutorHomePracticeScenarios => 'Kịch bản luyện tập';

  @override
  String get aiTutorHomePracticeScenariosSubtitle => 'Đóng vai các cuộc trò chuyện thực tế — nhà hàng, phỏng vấn, khách sạn…';

  @override
  String get aiTutorHomeReadStory => 'Đọc truyện';

  @override
  String get aiTutorHomeReadStorySubtitle => 'AI viết truyện ngắn dùng từ vựng của bạn — kèm câu hỏi hiểu nhanh.';

  @override
  String get aiTutorHomeDescribePhoto => 'Mô tả ảnh';

  @override
  String get aiTutorHomeDescribePhotoSubtitle => 'Chụp ảnh và mô tả — AI chấm từ vựng + ngữ pháp.';

  @override
  String get aiTutorChatTitle => 'Trò chuyện với gia sư';

  @override
  String get aiTutorChatVoiceOn => 'Bật tiếng';

  @override
  String get aiTutorChatVoiceOff => 'Tắt tiếng';

  @override
  String get aiTutorChatStopRecording => 'Dừng ghi âm';

  @override
  String get aiTutorChatHoldToTalk => 'Giữ để nói';

  @override
  String get aiTutorChatTranscribing => 'Đang chuyển ngữ…';

  @override
  String get aiTutorChatListening => 'Đang nghe…';

  @override
  String get aiTutorChatInputHint => 'Nhập tin nhắn…';

  @override
  String get aiTutorChatTypeReplyHint => 'Nhập câu trả lời…';

  @override
  String get aiTutorChatMicPermissionDenied => 'Cần quyền micro cho chế độ giọng nói.';

  @override
  String get aiTutorChatTranscribeFailed => 'Không nghe rõ — thử lại.';

  @override
  String aiTutorChatStartFailed(String error) {
    return 'Không khởi động được: $error';
  }

  @override
  String get aiTutorRoleplayEnd => 'Kết thúc';

  @override
  String aiTutorRoleplayEndFailed(String error) {
    return 'Không kết thúc được: $error';
  }

  @override
  String get aiTutorRoleplayDone => 'Xong';

  @override
  String get aiTutorStoryTitle => 'Đọc truyện';

  @override
  String get aiTutorStoryLength => 'Độ dài';

  @override
  String get aiTutorStoryTheme => 'Chủ đề';

  @override
  String aiTutorStoryWordCount(int count) {
    return '$count từ';
  }

  @override
  String get aiTutorStoryWriting => 'Đang viết…';

  @override
  String get aiTutorStoryGenerate => 'Tạo truyện';

  @override
  String aiTutorStoryGenerateFailed(String error) {
    return 'Không tạo được: $error';
  }

  @override
  String aiTutorStoryWordCountHint(int n) {
    return 'AI sẽ sử dụng tối đa $n từ trong danh sách của bạn.';
  }

  @override
  String get aiTutorStoryThemeFree => 'Tự do';

  @override
  String get aiTutorStoryThemeAdventure => 'Phiêu lưu';

  @override
  String get aiTutorStoryThemeMystery => 'Bí ẩn';

  @override
  String get aiTutorStoryThemeRomance => 'Lãng mạn';

  @override
  String get aiTutorStoryThemeSciFi => 'Khoa học viễn tưởng';

  @override
  String get aiTutorStoryThemeSliceOfLife => 'Đời thường';

  @override
  String get aiTutorStoryReaderTitle => 'Truyện';

  @override
  String get aiTutorStoryReaderVocab => 'Từ vựng';

  @override
  String get aiTutorStoryReaderVocabUsed => 'Từ vựng đã dùng';

  @override
  String aiTutorStoryReaderPart(int n) {
    return 'Phần $n';
  }

  @override
  String get aiTutorStoryReaderWrongHint => 'Chưa đúng — đi tiếp';

  @override
  String get aiTutorStoryReaderNiceWork => 'Làm tốt lắm!';

  @override
  String aiTutorStoryReaderScore(int correct, int total) {
    return 'Bạn trả lời đúng $correct/$total câu hỏi hiểu.';
  }

  @override
  String get aiTutorStoryReaderDone => 'Xong';

  @override
  String get aiTutorImageVocabTitle => 'Mô tả ảnh';

  @override
  String get aiTutorImagePickHeader => 'Chọn ảnh để mô tả';

  @override
  String get aiTutorImagePickSubtitle => 'AI sẽ đưa ra gợi ý bằng ngôn ngữ mục tiêu của bạn, rồi chấm điểm mô tả.';

  @override
  String get aiTutorImagePickCamera => 'Máy ảnh';

  @override
  String get aiTutorImagePickGallery => 'Thư viện';

  @override
  String aiTutorImagePickError(String error) {
    return 'Không mở được ảnh: $error';
  }

  @override
  String get aiTutorImageDescriptionHint => 'Nhập mô tả…';

  @override
  String get aiTutorImageDifferentPhoto => 'Ảnh khác';

  @override
  String get aiTutorImageSubmit => 'Gửi';

  @override
  String get aiTutorImageGrammarNotes => 'Ghi chú ngữ pháp';

  @override
  String get aiTutorImageThingsYouMissed => 'Điều bạn bỏ lỡ';

  @override
  String get aiTutorImageTryAnother => 'Thử ảnh khác';

  @override
  String get aiTutorCardQuiz => 'Câu đố';

  @override
  String get aiTutorCardVocab => 'Từ vựng';

  @override
  String get aiTutorCardGrammar => 'Ngữ pháp';

  @override
  String get aiTutorCardReviewDue => 'Đến lúc ôn tập';

  @override
  String get aiTutorCardMiniLesson => 'Bài học ngắn';

  @override
  String get aiTutorCardAddToVocab => 'Thêm vào từ vựng';

  @override
  String get aiTutorCardAddedToVocab => 'Đã thêm';

  @override
  String get aiTutorCardAdding => 'Đang thêm…';

  @override
  String aiTutorCardReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thẻ đang chờ bạn',
      one: '$count thẻ đang chờ bạn',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorCardReviewNow => 'Ôn tập ngay';

  @override
  String get aiTutorCardReviewStarting => 'Đang bắt đầu…';

  @override
  String get aiTutorCardTryIt => 'Thử';

  @override
  String get aiTutorCardPracticing => 'Đang luyện tập…';

  @override
  String aiTutorPlanSrsReview(int count, int done) {
    return 'Ôn $count thẻ SRS ($done xong)';
  }

  @override
  String aiTutorPlanGrammar(String topic) {
    return 'Luyện: $topic';
  }

  @override
  String aiTutorPlanChat(int min, int done) {
    return 'Chat $min phút ($done đến giờ)';
  }

  @override
  String get aboutBananatalk => 'Về Bananatalk';

  @override
  String get deleteAccount => 'Xóa tài khoản';

  @override
  String get permanentlyDeleteYourAccount => 'Xóa vĩnh viễn tài khoản của bạn';

  @override
  String get loggedOutSuccessfully => 'Đăng xuất thành công';

  @override
  String get retry => 'Thử lại';

  @override
  String get giftsLikes => 'Quà tặng/Lượt thích';

  @override
  String get details => 'Chi tiết';

  @override
  String get to => 'đến';

  @override
  String get banaTalk => 'Bananatalk';

  @override
  String get chats => 'Trò chuyện';

  @override
  String get community => 'Cộng đồng';

  @override
  String get editProfile => 'Chỉnh sửa hồ sơ';

  @override
  String yearsOld(String age) {
    return '$age tuổi';
  }

  @override
  String get searchConversations => 'Tìm kiếm cuộc trò chuyện...';

  @override
  String get visitorTrackingNotAvailable => 'Tính năng theo dõi khách truy cập chưa khả dụng.';

  @override
  String get chatList => 'Danh sách chat';

  @override
  String get languageExchange => 'Trao đổi ngôn ngữ';

  @override
  String get nativeLanguage => 'Ngôn ngữ mẹ đẻ';

  @override
  String get learning => 'Đang học';

  @override
  String get notSet => 'Chưa đặt';

  @override
  String get about => 'Giới thiệu';

  @override
  String get aboutMe => 'Về tôi';

  @override
  String get bloodType => 'Nhóm máu';

  @override
  String get photos => 'Ảnh';

  @override
  String get camera => 'Máy ảnh';

  @override
  String get createMoment => 'Tạo khoảnh khắc';

  @override
  String get addATitle => 'Thêm tiêu đề...';

  @override
  String get whatsOnYourMind => 'Bạn đang nghĩ gì?';

  @override
  String get addTags => 'Thêm thẻ';

  @override
  String get done => 'Xong';

  @override
  String get add => 'Thêm';

  @override
  String get enterTag => 'Nhập thẻ';

  @override
  String get post => 'Đăng';

  @override
  String get commentAddedSuccessfully => 'Đã thêm bình luận thành công';

  @override
  String get clearFilters => 'Xóa bộ lọc';

  @override
  String get notificationSettings => 'Cài đặt thông báo';

  @override
  String get enableNotifications => 'Bật thông báo';

  @override
  String get turnAllNotificationsOnOrOff => 'Bật hoặc tắt tất cả thông báo';

  @override
  String get notificationTypes => 'Loại thông báo';

  @override
  String get chatMessages => 'Tin nhắn chat';

  @override
  String get getNotifiedWhenYouReceiveMessages => 'Nhận thông báo khi có tin nhắn mới';

  @override
  String get likesAndCommentsOnYourMoments => 'Lượt thích và bình luận trên khoảnh khắc của bạn';

  @override
  String get whenPeopleYouFollowPostMoments => 'Khi người bạn theo dõi đăng khoảnh khắc';

  @override
  String get friendRequests => 'Lời mời kết bạn';

  @override
  String get whenSomeoneFollowsYou => 'Khi ai đó theo dõi bạn';

  @override
  String get profileVisits => 'Lượt xem hồ sơ';

  @override
  String get whenSomeoneViewsYourProfileVIP => 'Khi ai đó xem hồ sơ của bạn (VIP)';

  @override
  String get marketing => 'Tiếp thị';

  @override
  String get updatesAndPromotionalMessages => 'Cập nhật và tin nhắn quảng cáo';

  @override
  String get notificationPreferences => 'Tùy chọn thông báo';

  @override
  String get sound => 'Âm thanh';

  @override
  String get playNotificationSounds => 'Phát âm thanh thông báo';

  @override
  String get vibration => 'Rung';

  @override
  String get vibrateOnNotifications => 'Rung khi có thông báo';

  @override
  String get showPreview => 'Hiển thị xem trước';

  @override
  String get showMessagePreviewInNotifications => 'Hiển thị xem trước tin nhắn trong thông báo';

  @override
  String get mutedConversations => 'Cuộc trò chuyện đã tắt tiếng';

  @override
  String get conversation => 'Cuộc trò chuyện';

  @override
  String get conversationHistory => 'Lịch sử trò chuyện';

  @override
  String get unmute => 'Bật tiếng';

  @override
  String get systemNotificationSettings => 'Cài đặt thông báo hệ thống';

  @override
  String get manageNotificationsInSystemSettings => 'Quản lý thông báo trong cài đặt hệ thống';

  @override
  String get errorLoadingSettings => 'Lỗi khi tải cài đặt';

  @override
  String get unblockUser => 'Bỏ chặn người dùng';

  @override
  String get unblock => 'Bỏ chặn';

  @override
  String get goBack => 'Quay lại';

  @override
  String get messageSendTimeout => 'Hết thời gian gửi tin nhắn. Vui lòng kiểm tra kết nối.';

  @override
  String get failedToSendMessage => 'Gửi tin nhắn thất bại';

  @override
  String get dailyMessageLimitExceeded => 'Đã vượt quá giới hạn tin nhắn hàng ngày. Nâng cấp VIP để gửi không giới hạn.';

  @override
  String get cannotSendMessageUserMayBeBlocked => 'Không thể gửi tin nhắn. Người dùng có thể đã bị chặn.';

  @override
  String get sessionExpired => 'Phiên đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get sendThisSticker => 'Gửi sticker này?';

  @override
  String get chooseHowYouWantToDeleteThisMessage => 'Chọn cách bạn muốn xóa tin nhắn này:';

  @override
  String get deleteForEveryone => 'Xóa cho tất cả';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => 'Xóa tin nhắn cho cả bạn và người nhận';

  @override
  String get deleteForMe => 'Xóa cho tôi';

  @override
  String get removesTheMessageOnlyFromYourChat => 'Chỉ xóa tin nhắn khỏi chat của bạn';

  @override
  String get copy => 'Sao chép';

  @override
  String get reply => 'Trả lời';

  @override
  String get forward => 'Chuyển tiếp';

  @override
  String get moreOptions => 'Thêm tùy chọn';

  @override
  String get noUsersAvailableToForwardTo => 'Không có người dùng để chuyển tiếp';

  @override
  String get searchMoments => 'Tìm kiếm khoảnh khắc...';

  @override
  String searchInChatWith(String name) {
    return 'Tìm kiếm trong chat với $name';
  }

  @override
  String get typeAMessage => 'Nhập tin nhắn...';

  @override
  String get enterYourMessage => 'Nhập tin nhắn của bạn';

  @override
  String get detectYourLocation => 'Phát hiện vị trí của bạn';

  @override
  String get tapToUpdateLocation => 'Nhấn để cập nhật vị trí';

  @override
  String get helpOthersFindYouNearby => 'Giúp người khác tìm thấy bạn gần đây';

  @override
  String get selectYourNativeLanguage => 'Chọn ngôn ngữ mẹ đẻ của bạn';

  @override
  String get whichLanguageDoYouWantToLearn => 'Bạn muốn học ngôn ngữ nào?';

  @override
  String get selectYourGender => 'Chọn giới tính của bạn';

  @override
  String get addACaption => 'Thêm chú thích...';

  @override
  String get typeSomething => 'Nhập gì đó...';

  @override
  String get gallery => 'Thư viện';

  @override
  String get video => 'Video';

  @override
  String get text => 'Văn bản';

  @override
  String get provideMoreInformation => 'Cung cấp thêm thông tin...';

  @override
  String get searchByNameLanguageOrInterests => 'Tìm theo tên, ngôn ngữ hoặc sở thích...';

  @override
  String get addTagAndPressEnter => 'Thêm thẻ và nhấn enter';

  @override
  String replyTo(String name) {
    return 'Trả lời $name...';
  }

  @override
  String get highlightName => 'Tên highlight';

  @override
  String get searchCloseFriends => 'Tìm bạn thân...';

  @override
  String get askAQuestion => 'Đặt câu hỏi...';

  @override
  String option(String number) {
    return 'Tùy chọn $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return 'Tại sao bạn báo cáo $type này?';
  }

  @override
  String get additionalDetailsOptional => 'Chi tiết bổ sung (tùy chọn)';

  @override
  String get warningThisActionIsPermanent => 'Cảnh báo: Hành động này là vĩnh viễn!';

  @override
  String get deletingYourAccountWillPermanentlyRemove => 'Xóa tài khoản của bạn sẽ vĩnh viễn xóa:\n\n• Hồ sơ và toàn bộ dữ liệu cá nhân của bạn\n• Tất cả tin nhắn và cuộc trò chuyện của bạn\n• Tất cả khoảnh khắc và story của bạn\n• Gói đăng ký VIP của bạn (không hoàn tiền)\n• Tất cả kết nối và người theo dõi của bạn\n\nHành động này không thể hoàn tác.';

  @override
  String get clearAllNotifications => 'Xóa tất cả thông báo?';

  @override
  String get clearAll => 'Xóa tất cả';

  @override
  String get notificationDebug => 'Gỡ lỗi thông báo';

  @override
  String get markAllRead => 'Đánh dấu tất cả đã đọc';

  @override
  String get clearAll2 => 'Xóa tất cả';

  @override
  String get emailAddress => 'Địa chỉ email';

  @override
  String get username => 'Tên người dùng';

  @override
  String get alreadyHaveAnAccount => 'Đã có tài khoản?';

  @override
  String get login2 => 'Đăng nhập';

  @override
  String get selectYourNativeLanguage2 => 'Chọn ngôn ngữ mẹ đẻ của bạn';

  @override
  String get whichLanguageDoYouWantToLearn2 => 'Bạn muốn học ngôn ngữ nào?';

  @override
  String get selectYourGender2 => 'Chọn giới tính của bạn';

  @override
  String get dateFormat => 'DD.MM.YYYY';

  @override
  String get detectYourLocation2 => 'Phát hiện vị trí của bạn';

  @override
  String get tapToUpdateLocation2 => 'Nhấn để cập nhật vị trí';

  @override
  String get helpOthersFindYouNearby2 => 'Giúp người khác tìm thấy bạn gần đây';

  @override
  String get couldNotOpenLink => 'Không thể mở liên kết';

  @override
  String get legalPrivacy2 => 'Pháp lý & Quyền riêng tư';

  @override
  String get termsOfUseEULA => 'Điều khoản sử dụng (EULA)';

  @override
  String get viewOurTermsAndConditions => 'Xem điều khoản và điều kiện';

  @override
  String get privacyPolicy => 'Chính sách bảo mật';

  @override
  String get howWeHandleYourData => 'Cách chúng tôi xử lý dữ liệu của bạn';

  @override
  String get emailNotifications => 'Thông báo email';

  @override
  String get receiveEmailNotificationsFromBananatalk => 'Nhận thông báo email từ Bananatalk';

  @override
  String get weeklySummary => 'Tóm tắt hàng tuần';

  @override
  String get activityRecapEverySunday => 'Tóm tắt hoạt động mỗi Chủ nhật';

  @override
  String get newMessages => 'Tin nhắn mới';

  @override
  String get whenYoureAwayFor24PlusHours => 'Khi bạn vắng mặt hơn 24 giờ';

  @override
  String get newFollowers => 'Người theo dõi mới';

  @override
  String get whenSomeoneFollowsYou2 => 'Khi có người theo dõi bạn';

  @override
  String get securityAlerts => 'Cảnh báo bảo mật';

  @override
  String get passwordLoginAlerts => 'Cảnh báo mật khẩu và đăng nhập';

  @override
  String get unblockUser2 => 'Bỏ chặn người dùng';

  @override
  String get blockedUsers2 => 'Người dùng đã chặn';

  @override
  String get finalWarning => 'Cảnh báo cuối cùng';

  @override
  String get deleteForever => 'Xóa vĩnh viễn';

  @override
  String get deleteAccount2 => 'Xóa tài khoản';

  @override
  String get enterYourPassword => 'Nhập mật khẩu của bạn';

  @override
  String get yourPassword => 'Mật khẩu của bạn';

  @override
  String get typeDELETEToConfirm => 'Nhập DELETE để xác nhận';

  @override
  String get typeDELETEInCapitalLetters => 'Nhập DELETE bằng chữ in hoa';

  @override
  String sent(String emoji) {
    return '$emoji đã gửi!';
  }

  @override
  String get replySent => 'Đã gửi trả lời!';

  @override
  String get deleteStory => 'Xóa story?';

  @override
  String get thisStoryWillBeRemovedPermanently => 'Story này sẽ bị xóa vĩnh viễn.';

  @override
  String get noStories => 'Không có story';

  @override
  String views(String count) {
    return '$count lượt xem';
  }

  @override
  String get reportStory => 'Báo cáo story';

  @override
  String get reply2 => 'Trả lời...';

  @override
  String get failedToPickImage => 'Chọn ảnh thất bại';

  @override
  String get failedToTakePhoto => 'Chụp ảnh thất bại';

  @override
  String get failedToPickVideo => 'Chọn video thất bại';

  @override
  String get pleaseEnterSomeText => 'Vui lòng nhập văn bản';

  @override
  String get pleaseSelectMedia => 'Vui lòng chọn media';

  @override
  String get storyPosted => 'Đã đăng story!';

  @override
  String get textOnlyStoriesRequireAnImage => 'Story chỉ có văn bản cần có ảnh';

  @override
  String get createStory => 'Tạo Story';

  @override
  String get change => 'Thay đổi';

  @override
  String get userIdNotFound => 'Không tìm thấy User ID. Vui lòng đăng nhập lại.';

  @override
  String get pleaseSelectAPaymentMethod => 'Vui lòng chọn phương thức thanh toán';

  @override
  String get startExploring => 'Bắt đầu khám phá';

  @override
  String get close => 'Đóng';

  @override
  String get payment => 'Thanh toán';

  @override
  String get upgradeToVIP => 'Nâng cấp lên VIP';

  @override
  String get errorLoadingProducts => 'Lỗi khi tải sản phẩm';

  @override
  String get cancelVIPSubscription => 'Hủy đăng ký VIP';

  @override
  String get keepVIP => 'Giữ VIP';

  @override
  String get cancelSubscription => 'Hủy đăng ký';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'Đã hủy đăng ký VIP thành công';

  @override
  String get vipStatus => 'Trạng thái VIP';

  @override
  String get noActiveVIPSubscription => 'Không có đăng ký VIP đang hoạt động';

  @override
  String get subscriptionExpired => 'Đăng ký đã hết hạn';

  @override
  String get vipExpiredMessage => 'Đăng ký VIP của bạn đã hết hạn. Gia hạn ngay để tiếp tục tận hưởng các tính năng không giới hạn!';

  @override
  String get expiredOn => 'Hết hạn vào';

  @override
  String get renewVIP => 'Gia hạn VIP';

  @override
  String get whatYoureMissing => 'Những gì bạn đang bỏ lỡ';

  @override
  String get manageInAppStore => 'Quản lý trong App Store';

  @override
  String get becomeVIP => 'Trở thành VIP';

  @override
  String get unlimitedMessages => 'Tin nhắn không giới hạn';

  @override
  String get unlimitedProfileViews => 'Lượt xem hồ sơ không giới hạn';

  @override
  String get prioritySupport => 'Hỗ trợ ưu tiên';

  @override
  String get advancedSearch => 'Tìm kiếm nâng cao';

  @override
  String get profileBoost => 'Tăng cường hồ sơ';

  @override
  String get adFreeExperience => 'Trải nghiệm không quảng cáo';

  @override
  String get upgradeYourAccount => 'Nâng cấp tài khoản';

  @override
  String get moreMessages => 'Thêm tin nhắn';

  @override
  String get moreProfileViews => 'Thêm lượt xem hồ sơ';

  @override
  String get connectWithFriends => 'Kết nối với bạn bè';

  @override
  String get reviewStarted => 'Đã bắt đầu xem xét';

  @override
  String get reportResolved => 'Báo cáo đã được giải quyết';

  @override
  String get reportDismissed => 'Báo cáo đã bị bác bỏ';

  @override
  String get selectAction => 'Chọn hành động';

  @override
  String get noViolation => 'Không vi phạm';

  @override
  String get contentRemoved => 'Nội dung đã bị xóa';

  @override
  String get userWarned => 'Người dùng đã bị cảnh cáo';

  @override
  String get userSuspended => 'Người dùng đã bị đình chỉ';

  @override
  String get userBanned => 'Người dùng đã bị cấm';

  @override
  String get addNotesOptional => 'Thêm ghi chú (Tùy chọn)';

  @override
  String get enterModeratorNotes => 'Nhập ghi chú của người kiểm duyệt...';

  @override
  String get skip => 'Bỏ qua';

  @override
  String get startReview => 'Bắt đầu đánh giá';

  @override
  String get resolve => 'Giải quyết';

  @override
  String get dismiss => 'Bỏ qua';

  @override
  String get filterReports => 'Lọc báo cáo';

  @override
  String get all => 'Tất cả';

  @override
  String get clear => 'Xóa';

  @override
  String get apply => 'Áp dụng';

  @override
  String get myReports2 => 'Báo cáo của tôi';

  @override
  String get blockUser => 'Chặn người dùng';

  @override
  String get block => 'Chặn';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => 'Bạn cũng muốn chặn người dùng này không?';

  @override
  String get noThanks => 'Không, cảm ơn';

  @override
  String get yesBlockThem => 'Có, chặn họ';

  @override
  String get reportUser2 => 'Báo cáo người dùng';

  @override
  String get submitReport => 'Gửi báo cáo';

  @override
  String get addAQuestionAndAtLeast2Options => 'Thêm câu hỏi và ít nhất 2 lựa chọn';

  @override
  String get addOption => 'Thêm tùy chọn';

  @override
  String get anonymousVoting => 'Bỏ phiếu ẩn danh';

  @override
  String get create => 'Tạo';

  @override
  String get typeYourAnswer => 'Nhập câu trả lời của bạn...';

  @override
  String get send2 => 'Gửi';

  @override
  String get yourPrompt => 'Gợi ý của bạn...';

  @override
  String get add2 => 'Thêm';

  @override
  String get contentNotAvailable => 'Nội dung không khả dụng';

  @override
  String get profileNotAvailable => 'Hồ sơ không khả dụng';

  @override
  String get noMomentsToShow => 'Không có khoảnh khắc để hiển thị';

  @override
  String get storiesNotAvailable => 'Story không khả dụng';

  @override
  String get cantMessageThisUser => 'Không thể nhắn tin cho người dùng này';

  @override
  String get pleaseSelectAReason => 'Vui lòng chọn một lý do';

  @override
  String get reportSubmitted => 'Đã gửi báo cáo. Cảm ơn bạn đã giúp giữ cộng đồng an toàn.';

  @override
  String get youHaveAlreadyReportedThisMoment => 'Bạn đã báo cáo khoảnh khắc này rồi';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => 'Cho chúng tôi biết thêm lý do bạn báo cáo điều này';

  @override
  String get errorSharing => 'Lỗi khi chia sẻ';

  @override
  String get deviceInfo => 'Thông tin thiết bị';

  @override
  String get recommended => 'Đề xuất';

  @override
  String get anyLanguage => 'Bất kỳ ngôn ngữ nào';

  @override
  String get noLanguagesFound => 'Không tìm thấy ngôn ngữ';

  @override
  String get selectALanguage => 'Chọn một ngôn ngữ';

  @override
  String get languagesAreStillLoading => 'Ngôn ngữ vẫn đang tải...';

  @override
  String get selectNativeLanguage => 'Chọn ngôn ngữ mẹ đẻ';

  @override
  String get languagesStepTitle => 'Ngôn ngữ của bạn';

  @override
  String get languagesStepSubtitle => 'Chúng tôi ghép bạn với người học chiều ngược lại';

  @override
  String get languagesISpeak => 'Tôi nói';

  @override
  String get languagesImLearning => 'Tôi đang học';

  @override
  String get languagesSwap => 'Hoán đổi';

  @override
  String get languagesChoose => 'Chọn ngôn ngữ';

  @override
  String get subscriptionDetails => 'Chi tiết đăng ký';

  @override
  String get activeFeatures => 'Tính năng đang hoạt động';

  @override
  String get legalInformation => 'Thông tin pháp lý';

  @override
  String get termsOfUse => 'Điều khoản sử dụng';

  @override
  String get manageSubscription => 'Quản lý đăng ký';

  @override
  String get manageSubscriptionInSettings => 'Để hủy gói đăng ký, hãy vào Cài đặt > [Tên của bạn] > Đăng ký trên thiết bị của bạn.';

  @override
  String get contactSupportToCancel => 'Để hủy gói đăng ký, vui lòng liên hệ với đội ngũ hỗ trợ của chúng tôi.';

  @override
  String get status => 'Trạng thái';

  @override
  String get active => 'Đang hoạt động';

  @override
  String get plan => 'Gói';

  @override
  String get startDate => 'Ngày bắt đầu';

  @override
  String get endDate => 'Ngày kết thúc';

  @override
  String get nextBillingDate => 'Ngày thanh toán tiếp theo';

  @override
  String get autoRenew => 'Tự động gia hạn';

  @override
  String get pleaseLogInToContinue => 'Vui lòng đăng nhập để tiếp tục';

  @override
  String get purchaseCanceledOrFailed => 'Giao dịch bị hủy hoặc thất bại. Vui lòng thử lại.';

  @override
  String get maximumTagsAllowed => 'Tối đa 5 thẻ được phép';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => 'Vui lòng xóa ảnh trước khi thêm video';

  @override
  String get unsupportedFormat => 'Định dạng không được hỗ trợ';

  @override
  String get errorProcessingVideo => 'Lỗi khi xử lý video';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'Vui lòng xóa ảnh trước khi quay video';

  @override
  String get locationAdded => 'Đã thêm vị trí';

  @override
  String get failedToGetLocation => 'Lấy vị trí thất bại';

  @override
  String get notNow => 'Không phải bây giờ';

  @override
  String get videoUploadFailed => 'Tải video lên thất bại';

  @override
  String get skipVideo => 'Bỏ qua video';

  @override
  String get retryUpload => 'Thử tải lên lại';

  @override
  String get momentCreatedSuccessfully => 'Đã tạo khoảnh khắc thành công';

  @override
  String get uploadingMomentInBackground => 'Đang tải khoảnh khắc lên ở nền...';

  @override
  String get failedToQueueUpload => 'Không thể xếp hàng tải lên';

  @override
  String get viewProfile => 'Xem hồ sơ';

  @override
  String get mediaLinksAndDocs => 'Media, liên kết và tài liệu';

  @override
  String get wallpaper => 'Hình nền';

  @override
  String get userIdNotAvailable => 'Không có sẵn ID người dùng';

  @override
  String get cannotBlockYourself => 'Không thể tự chặn chính mình';

  @override
  String get chatWallpaper => 'Hình nền chat';

  @override
  String get wallpaperSavedLocally => 'Đã lưu hình nền cục bộ';

  @override
  String get messageCopied => 'Đã sao chép tin nhắn';

  @override
  String get forwardFeatureComingSoon => 'Tính năng chuyển tiếp sắp ra mắt';

  @override
  String get momentUnsaved => 'Đã xóa khỏi đã lưu';

  @override
  String get documentPickerComingSoon => 'Tính năng chọn tài liệu sắp ra mắt';

  @override
  String get contactSharingComingSoon => 'Tính năng chia sẻ liên hệ sắp ra mắt';

  @override
  String get featureComingSoon => 'Tính năng sắp ra mắt';

  @override
  String get answerSent => 'Đã gửi câu trả lời!';

  @override
  String get noImagesAvailable => 'Không có ảnh';

  @override
  String get mentionPickerComingSoon => 'Tính năng nhắc tên sắp ra mắt';

  @override
  String get musicPickerComingSoon => 'Tính năng chọn nhạc sắp ra mắt';

  @override
  String get repostFeatureComingSoon => 'Tính năng đăng lại sắp ra mắt';

  @override
  String get addFriendsFromYourProfile => 'Thêm bạn bè từ hồ sơ của bạn';

  @override
  String get quickReplyAdded => 'Đã thêm trả lời nhanh';

  @override
  String get quickReplyDeleted => 'Đã xóa trả lời nhanh';

  @override
  String get linkCopied => 'Đã sao chép liên kết!';

  @override
  String get maximumOptionsAllowed => 'Tối đa 10 lựa chọn';

  @override
  String get minimumOptionsRequired => 'Cần tối thiểu 2 lựa chọn';

  @override
  String get pleaseEnterAQuestion => 'Vui lòng nhập câu hỏi';

  @override
  String get pleaseAddAtLeast2Options => 'Vui lòng thêm ít nhất 2 lựa chọn';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => 'Vui lòng chọn đáp án đúng cho bài trắc nghiệm';

  @override
  String get correctionSent => 'Đã gửi sửa lỗi!';

  @override
  String get sort => 'Sắp xếp';

  @override
  String get savedMoments => 'Khoảnh khắc đã lưu';

  @override
  String get unsave => 'Bỏ lưu';

  @override
  String get playingAudio => 'Đang phát âm thanh...';

  @override
  String get failedToGenerateQuiz => 'Không thể tạo bài trắc nghiệm';

  @override
  String get failedToAddComment => 'Không thể thêm bình luận';

  @override
  String get hello => 'Xin chào!';

  @override
  String get howAreYou => 'Bạn khỏe không?';

  @override
  String get cannotOpen => 'Không thể mở';

  @override
  String get errorOpeningLink => 'Lỗi khi mở liên kết';

  @override
  String get saved => 'Đã lưu';

  @override
  String get follow => 'Theo dõi';

  @override
  String get unfollow => 'Bỏ theo dõi';

  @override
  String get mute => 'Tắt tiếng';

  @override
  String get online => 'Trực tuyến';

  @override
  String get offline => 'Ngoại tuyến';

  @override
  String get lastSeen => 'Lần cuối trực tuyến';

  @override
  String get justNow => 'vừa xong';

  @override
  String minutesAgo(String count) {
    return '$count phút trước';
  }

  @override
  String hoursAgo(String count) {
    return '$count giờ trước';
  }

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get signInWithEmail => 'Đăng nhập bằng Email';

  @override
  String get partners => 'Đối tác';

  @override
  String get nearby => 'Gần đây';

  @override
  String get topics => 'Chủ đề';

  @override
  String get waves => 'Vẫy tay';

  @override
  String get communityTabRooms => 'Phòng';

  @override
  String get voiceRooms => 'Voice';

  @override
  String get filters => 'Bộ lọc';

  @override
  String get searchCommunity => 'Tìm theo tên, ngôn ngữ hoặc sở thích...';

  @override
  String get bio => 'Tiểu sử';

  @override
  String get noBioYet => 'Chưa có tiểu sử.';

  @override
  String get languages => 'Ngôn ngữ';

  @override
  String get native => 'Bản ngữ';

  @override
  String get interests => 'Sở thích';

  @override
  String get noMomentsYet => 'Chưa có khoảnh khắc';

  @override
  String get noForYouMomentsTitle => 'Chưa có khoảnh khắc nào';

  @override
  String get noForYouMomentsBody => 'Trả lời chủ đề hôm nay để bắt đầu cuộc trò chuyện.';

  @override
  String get noFollowingMomentsTitle => 'Chưa có gì ở đây';

  @override
  String get noFollowingMomentsBody => 'Theo dõi mọi người từ Cộng đồng để xem khoảnh khắc của họ tại đây.';

  @override
  String get goToCommunity => 'Đến Cộng đồng';

  @override
  String get unableToLoadMoments => 'Không thể tải khoảnh khắc';

  @override
  String get map => 'Bản đồ';

  @override
  String get mapUnavailable => 'Bản đồ không khả dụng';

  @override
  String get location => 'Vị trí';

  @override
  String get unknownLocation => 'Vị trí không xác định';

  @override
  String get noImagesAvailable2 => 'Không có ảnh nào';

  @override
  String get permissionsRequired => 'Yêu cầu quyền truy cập';

  @override
  String get openSettings => 'Mở cài đặt';

  @override
  String get refresh => 'Làm mới';

  @override
  String get videoCall => 'Video';

  @override
  String get voiceCall => 'Gọi';

  @override
  String get message => 'Nhắn tin';

  @override
  String get pleaseLoginToFollow => 'Vui lòng đăng nhập để theo dõi người dùng';

  @override
  String get pleaseLoginToCall => 'Vui lòng đăng nhập để thực hiện cuộc gọi';

  @override
  String get cannotCallYourself => 'Bạn không thể gọi cho chính mình';

  @override
  String get failedToFollowUser => 'Không thể theo dõi người dùng';

  @override
  String get failedToUnfollowUser => 'Không thể bỏ theo dõi người dùng';

  @override
  String get areYouSureUnfollow => 'Bạn có chắc muốn bỏ theo dõi người dùng này không?';

  @override
  String get areYouSureUnblock => 'Bạn có chắc muốn bỏ chặn người dùng này không?';

  @override
  String get youFollowed => 'Bạn đã theo dõi';

  @override
  String get youUnfollowed => 'Bạn đã bỏ theo dõi';

  @override
  String get alreadyFollowing => 'Bạn đã theo dõi';

  @override
  String get soon => 'Sắp ra mắt';

  @override
  String comingSoon(String feature) {
    return '$feature sắp ra mắt!';
  }

  @override
  String get muteNotifications => 'Tắt thông báo';

  @override
  String get unmuteNotifications => 'Bật lại thông báo';

  @override
  String get operationCompleted => 'Thao tác hoàn tất';

  @override
  String get couldNotOpenMaps => 'Không thể mở bản đồ';

  @override
  String hasntSharedMoments(Object name) {
    return '$name chưa chia sẻ khoảnh khắc nào';
  }

  @override
  String messageUser(String name) {
    return 'Nhắn tin cho $name';
  }

  @override
  String notFollowingUser(String name) {
    return 'Bạn chưa theo dõi $name';
  }

  @override
  String youFollowedUser(String name) {
    return 'Bạn đã theo dõi $name';
  }

  @override
  String youUnfollowedUser(String name) {
    return 'Bạn đã bỏ theo dõi $name';
  }

  @override
  String unfollowUser(String name) {
    return 'Bỏ theo dõi $name';
  }

  @override
  String get typing => 'đang nhập';

  @override
  String get connecting => 'Đang kết nối...';

  @override
  String daysAgo(int count) {
    return '${count}ng trước';
  }

  @override
  String get maxTagsAllowed => 'Tối đa 5 thẻ được phép';

  @override
  String maxImagesAllowed(int count) {
    return 'Tối đa $count ảnh được phép';
  }

  @override
  String get pleaseRemoveImagesFirst => 'Vui lòng xóa ảnh trước khi thêm video';

  @override
  String get exchange3MessagesBeforeCall => 'Hãy trao đổi ít nhất 5 tin nhắn trước khi gọi';

  @override
  String mediaWithUser(String name) {
    return 'Phương tiện với $name';
  }

  @override
  String get errorLoadingMedia => 'Lỗi khi tải phương tiện';

  @override
  String get savedMomentsTitle => 'Khoảnh khắc đã lưu';

  @override
  String get removeBookmark => 'Xóa dấu trang?';

  @override
  String get thisWillRemoveBookmark => 'Thao tác này sẽ xóa tin nhắn khỏi danh sách dấu trang của bạn.';

  @override
  String get remove => 'Xóa';

  @override
  String get bookmarkRemoved => 'Đã xóa dấu trang';

  @override
  String get bookmarkedMessages => 'Tin nhắn đã đánh dấu';

  @override
  String get wallpaperSaved => 'Đã lưu hình nền vào máy';

  @override
  String get typeDeleteToConfirm => 'Nhập DELETE để xác nhận';

  @override
  String get storyArchive => 'Lưu trữ story';

  @override
  String get newHighlight => 'Nổi bật mới';

  @override
  String get addToHighlight => 'Thêm vào nổi bật';

  @override
  String get repost => 'Đăng lại';

  @override
  String get repostFeatureSoon => 'Tính năng đăng lại sắp ra mắt';

  @override
  String get closeFriends => 'Bạn thân';

  @override
  String get addFriends => 'Thêm bạn bè';

  @override
  String get highlights => 'Highlights';

  @override
  String get createHighlight => 'Tạo Highlight';

  @override
  String get deleteHighlight => 'Xóa';

  @override
  String get editHighlight => 'Chỉnh sửa';

  @override
  String get addMoreToStory => 'Thêm vào story';

  @override
  String get noViewersYet => 'Chưa có người xem';

  @override
  String get noReactionsYet => 'Chưa có phản ứng nào';

  @override
  String get leaveRoom => 'Rời phòng';

  @override
  String get areYouSureLeaveRoom => 'Bạn có chắc muốn rời khỏi phòng thoại này không?';

  @override
  String get stay => 'Ở lại';

  @override
  String get leave => 'Rời đi';

  @override
  String get enableGPS => 'Bật GPS';

  @override
  String wavedToUser(String name) {
    return 'Đã vẫy tay với $name!';
  }

  @override
  String get areYouSureFollow => 'Bạn có chắc muốn theo dõi';

  @override
  String get failedToLoadProfile => 'Không thể tải hồ sơ';

  @override
  String get noFollowersYet => 'Chưa có người theo dõi';

  @override
  String get noFollowingYet => 'Chưa theo dõi ai';

  @override
  String get searchUsers => 'Tìm kiếm người dùng...';

  @override
  String get noResultsFound => 'Không tìm thấy kết quả';

  @override
  String get loadingFailed => 'Tải không thành công';

  @override
  String get copyLink => 'Sao chép liên kết';

  @override
  String get shareStory => 'Chia sẻ story';

  @override
  String get thisWillDeleteStory => 'Thao tác này sẽ xóa vĩnh viễn story này.';

  @override
  String get storyDeleted => 'Đã xóa story';

  @override
  String get addCaption => 'Thêm chú thích...';

  @override
  String get yourStory => 'Story của bạn';

  @override
  String get sendMessage => 'Gửi tin nhắn';

  @override
  String get replyToStory => 'Trả lời story...';

  @override
  String get viewAllReplies => 'Xem tất cả trả lời';

  @override
  String get preparingVideo => 'Đang chuẩn bị video...';

  @override
  String videoOptimized(String size, String savings) {
    return 'Đã tối ưu video: ${size}MB (tiết kiệm $savings%)';
  }

  @override
  String get failedToProcessVideo => 'Không thể xử lý video';

  @override
  String get optimizingForBestExperience => 'Đang tối ưu hóa để có trải nghiệm story tốt nhất';

  @override
  String get pleaseSelectImageOrVideo => 'Vui lòng chọn ảnh hoặc video cho story của bạn';

  @override
  String get storyCreatedSuccessfully => 'Đã tạo story thành công!';

  @override
  String get uploadingStoryInBackground => 'Đang tải story lên trong nền...';

  @override
  String get storyCreationFailed => 'Tạo story không thành công';

  @override
  String get pleaseCheckConnection => 'Vui lòng kiểm tra kết nối và thử lại.';

  @override
  String get uploadFailed => 'Tải lên không thành công';

  @override
  String get tryShorterVideo => 'Hãy thử dùng video ngắn hơn hoặc thử lại sau.';

  @override
  String get shareMomentsThatDisappear => 'Chia sẻ khoảnh khắc biến mất sau 24 giờ';

  @override
  String get photo => 'Ảnh';

  @override
  String get record => 'Ghi';

  @override
  String get addSticker => 'Thêm nhãn dán';

  @override
  String get poll => 'Bình chọn';

  @override
  String get question => 'Câu hỏi';

  @override
  String get mention => 'Đề cập';

  @override
  String get music => 'Âm nhạc';

  @override
  String get hashtag => 'Hashtag';

  @override
  String get whoCanSeeThis => 'Ai có thể xem cái này?';

  @override
  String get everyone => 'Mọi người';

  @override
  String get anyoneCanSeeStory => 'Bất kỳ ai cũng có thể xem story này';

  @override
  String get friendsOnly => 'Chỉ bạn bè';

  @override
  String get onlyFollowersCanSee => 'Chỉ người theo dõi bạn mới có thể xem';

  @override
  String get onlyCloseFriendsCanSee => 'Chỉ bạn thân của bạn mới có thể xem';

  @override
  String get backgroundColor => 'Màu nền';

  @override
  String get fontStyle => 'Kiểu chữ';

  @override
  String get normal => 'Bình thường';

  @override
  String get bold => 'Đậm';

  @override
  String get italic => 'Nghiêng';

  @override
  String get handwriting => 'Chữ viết tay';

  @override
  String get addLocation => 'Thêm vị trí';

  @override
  String get enterLocationName => 'Nhập tên địa điểm';

  @override
  String get addLink => 'Thêm liên kết';

  @override
  String get buttonText => 'Văn bản nút';

  @override
  String get learnMore => 'Tìm hiểu thêm';

  @override
  String get addHashtags => 'Thêm hashtag';

  @override
  String get addHashtag => 'Thêm hashtag';

  @override
  String get sendAsMessage => 'Gửi dưới dạng tin nhắn';

  @override
  String get shareExternally => 'Chia sẻ ra bên ngoài';

  @override
  String get checkOutStory => 'Xem story này trên Bananatalk!';

  @override
  String viewsTab(String count) {
    return 'Lượt xem ($count)';
  }

  @override
  String reactionsTab(String count) {
    return 'Phản ứng ($count)';
  }

  @override
  String get processingVideo => 'Đang xử lý video...';

  @override
  String get link => 'Liên kết';

  @override
  String unmuteUser(String name) {
    return 'Bật lại thông báo cho $name?';
  }

  @override
  String get willReceiveNotifications => 'Bạn sẽ nhận được thông báo cho tin nhắn mới.';

  @override
  String muteNotificationsFor(String name) {
    return 'Tắt thông báo cho $name';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return 'Đã bật lại thông báo cho $name';
  }

  @override
  String notificationsMutedFor(String name) {
    return 'Đã tắt thông báo cho $name';
  }

  @override
  String get failedToUpdateMuteSettings => 'Không thể cập nhật cài đặt tắt thông báo';

  @override
  String get oneHour => '1 giờ';

  @override
  String get eightHours => '8 giờ';

  @override
  String get oneWeek => '1 tuần';

  @override
  String get always => 'Luôn luôn';

  @override
  String get failedToLoadBookmarks => 'Không thể tải dấu trang';

  @override
  String get noBookmarkedMessages => 'Không có tin nhắn được đánh dấu';

  @override
  String get longPressToBookmark => 'Nhấn giữ vào tin nhắn để đánh dấu';

  @override
  String get thisWillRemoveFromBookmarks => 'Thao tác này sẽ xóa tin nhắn khỏi danh sách dấu trang của bạn.';

  @override
  String navigateToMessage(String name) {
    return 'Chuyển đến tin nhắn trong cuộc trò chuyện với $name';
  }

  @override
  String bookmarkedOn(String date) {
    return 'Đã đánh dấu vào $date';
  }

  @override
  String get voiceMessage => 'Tin nhắn thoại';

  @override
  String get document => 'Tài liệu';

  @override
  String get attachment => 'Đính kèm';

  @override
  String get sendMeAMessage => 'Gửi tin nhắn cho tôi';

  @override
  String get shareWithFriends => 'Chia sẻ với bạn bè';

  @override
  String get shareAnywhere => 'Chia sẻ ở bất kỳ đâu';

  @override
  String get emailPreferences => 'Tùy chọn email';

  @override
  String get receiveEmailNotifications => 'Nhận thông báo qua email từ Bananatalk';

  @override
  String get whenAwayFor24Hours => 'Khi bạn vắng mặt hơn 24 giờ';

  @override
  String get passwordAndLoginAlerts => 'Cảnh báo mật khẩu & đăng nhập';

  @override
  String get failedToLoadPreferences => 'Không thể tải tùy chọn';

  @override
  String get failedToUpdateSetting => 'Không thể cập nhật cài đặt';

  @override
  String get securityAlertsRecommended => 'Chúng tôi khuyên bạn nên bật Cảnh báo bảo mật để luôn cập nhật hoạt động quan trọng của tài khoản.';

  @override
  String chatWallpaperFor(String name) {
    return 'Hình nền trò chuyện cho $name';
  }

  @override
  String get solidColors => 'Màu đơn sắc';

  @override
  String get gradients => 'Màu chuyển sắc';

  @override
  String get customImage => 'Ảnh tùy chỉnh';

  @override
  String get chooseFromGallery => 'Chọn từ thư viện';

  @override
  String get preview => 'Xem trước';

  @override
  String get wallpaperUpdated => 'Đã cập nhật hình nền';

  @override
  String get category => 'Danh mục';

  @override
  String get mood => 'Tâm trạng';

  @override
  String get sortBy => 'Sắp xếp theo';

  @override
  String get timePeriod => 'Khoảng thời gian';

  @override
  String get searchLanguages => 'Tìm kiếm ngôn ngữ...';

  @override
  String get selected => 'Đã chọn';

  @override
  String get categories => 'Danh mục';

  @override
  String get moods => 'Tâm trạng';

  @override
  String get applyFilters => 'Áp dụng bộ lọc';

  @override
  String applyNFilters(int count) {
    return 'Áp dụng $count bộ lọc';
  }

  @override
  String get videoMustBeUnder1GB => 'Video phải dưới 1GB.';

  @override
  String get failedToRecordVideo => 'Không thể quay video';

  @override
  String get errorSendingVideo => 'Lỗi khi gửi video';

  @override
  String get errorSendingVoiceMessage => 'Lỗi khi gửi tin nhắn thoại';

  @override
  String get errorSendingMedia => 'Lỗi khi gửi phương tiện';

  @override
  String get cameraPermissionRequired => 'Cần có quyền truy cập camera và micro để quay video.';

  @override
  String get locationPermissionRequired => 'Cần có quyền truy cập vị trí để chia sẻ vị trí của bạn.';

  @override
  String get noInternetConnection => 'Không có kết nối internet';

  @override
  String get tryAgainLater => 'Vui lòng thử lại sau';

  @override
  String get messageSent => 'Đã gửi tin nhắn';

  @override
  String get messageDeleted => 'Đã xóa tin nhắn';

  @override
  String get messageEdited => 'Đã sửa tin nhắn';

  @override
  String get edited => '(đã sửa)';

  @override
  String get now => 'vừa xong';

  @override
  String weeksAgo(int count) {
    return '$count tuần trước';
  }

  @override
  String viewRepliesCount(int count) {
    return '── Xem $count phản hồi';
  }

  @override
  String get hideReplies => '── Ẩn phản hồi';

  @override
  String get saveMoment => 'Lưu khoảnh khắc';

  @override
  String get removeFromSaved => 'Xóa khỏi đã lưu';

  @override
  String get momentSaved => 'Đã lưu';

  @override
  String get failedToSave => 'Lưu thất bại';

  @override
  String get checkOutMoment => 'Xem khoảnh khắc này trên Bananatalk!';

  @override
  String get checkOutProfile => 'Xem hồ sơ này trên Bananatalk!';

  @override
  String get checkOutCommunity => 'Xem thành viên này trên Bananatalk!';

  @override
  String get failedToLoadMoments => 'Không thể tải khoảnh khắc';

  @override
  String get noMomentsMatchFilters => 'Không có khoảnh khắc nào phù hợp với bộ lọc';

  @override
  String get beFirstToShareMoment => 'Hãy là người đầu tiên chia sẻ khoảnh khắc!';

  @override
  String get tryDifferentSearch => 'Thử từ khóa tìm kiếm khác';

  @override
  String get tryAdjustingFilters => 'Thử điều chỉnh bộ lọc';

  @override
  String get noSavedMoments => 'Không có khoảnh khắc đã lưu';

  @override
  String get tapBookmarkToSave => 'Nhấn vào biểu tượng đánh dấu để lưu khoảnh khắc';

  @override
  String get failedToLoadVideo => 'Không thể tải video';

  @override
  String get titleRequired => 'Tiêu đề là bắt buộc';

  @override
  String titleTooLong(int max) {
    return 'Tiêu đề phải có $max ký tự trở xuống';
  }

  @override
  String get descriptionRequired => 'Mô tả là bắt buộc';

  @override
  String descriptionTooLong(int max) {
    return 'Mô tả phải có $max ký tự trở xuống';
  }

  @override
  String get scheduledDateMustBeFuture => 'Ngày hẹn phải ở tương lai';

  @override
  String get recent => 'Gần đây';

  @override
  String get popular => 'Phổ biến';

  @override
  String get trending => 'Xu hướng';

  @override
  String get mostRecent => 'Mới nhất';

  @override
  String get mostPopular => 'Phổ biến nhất';

  @override
  String get allTime => 'Tất cả';

  @override
  String get today => 'Hôm nay';

  @override
  String get thisWeek => 'Tuần này';

  @override
  String get thisMonth => 'Tháng này';

  @override
  String replyingTo(String userName) {
    return 'Đang trả lời $userName';
  }

  @override
  String get listView => 'Dạng danh sách';

  @override
  String get quickMatch => 'Ghép nhanh';

  @override
  String get onlineNow => 'Đang trực tuyến';

  @override
  String speaksLanguage(String language) {
    return 'Nói $language';
  }

  @override
  String learningLanguage(String language) {
    return 'Đang học $language';
  }

  @override
  String get noPartnersFound => 'Không tìm thấy đối tác';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return 'Không tìm thấy người dùng nói $learning bản ngữ hoặc muốn học $native.';
  }

  @override
  String get removeAllFilters => 'Xóa tất cả bộ lọc';

  @override
  String get browseAllUsers => 'Xem tất cả người dùng';

  @override
  String get allCaughtUp => 'Đã xem hết!';

  @override
  String get loadingMore => 'Đang tải thêm...';

  @override
  String get findingMorePartners => 'Đang tìm thêm đối tác...';

  @override
  String get seenAllPartners => 'Bạn đã xem tất cả đối tác';

  @override
  String get startOver => 'Bắt đầu lại';

  @override
  String get changeFilters => 'Thay đổi bộ lọc';

  @override
  String get findingPartners => 'Đang tìm đối tác...';

  @override
  String get setLocationReminder => 'Đặt vị trí để tìm đối tác gần bạn';

  @override
  String get updateLocationReminder => 'Cập nhật vị trí để có kết quả tốt hơn';

  @override
  String get male => 'Nam';

  @override
  String get female => 'Nữ';

  @override
  String get other => 'Khác';

  @override
  String get browseMen => 'Tìm nam';

  @override
  String get browseWomen => 'Tìm nữ';

  @override
  String get noMaleUsersFound => 'Không tìm thấy người dùng nam';

  @override
  String get noFemaleUsersFound => 'Không tìm thấy người dùng nữ';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => 'Chỉ người dùng mới';

  @override
  String get showNewUsers => 'Hiển thị người dùng mới';

  @override
  String get prioritizeNearby => 'Ưu tiên gần đây';

  @override
  String get showNearbyFirst => 'Hiển thị gần đây trước';

  @override
  String get setLocationToEnable => 'Đặt vị trí để kích hoạt';

  @override
  String get radius => 'Bán kính';

  @override
  String get findingYourLocation => 'Đang tìm vị trí của bạn...';

  @override
  String get enableLocationForDistance => 'Bật vị trí để tính khoảng cách';

  @override
  String get enableLocationDescription => 'Bật dịch vụ vị trí để tìm đối tác ngôn ngữ gần bạn';

  @override
  String get enableGps => 'Bật GPS';

  @override
  String get browseByCityCountry => 'Tìm theo thành phố/quốc gia';

  @override
  String get peopleNearby => 'Người gần đây';

  @override
  String get noNearbyUsersFound => 'Không tìm thấy người dùng gần đây';

  @override
  String get tryExpandingSearch => 'Thử mở rộng tìm kiếm';

  @override
  String get exploreByCity => 'Khám phá theo thành phố';

  @override
  String get exploreByCurrentCity => 'Khám phá theo thành phố hiện tại';

  @override
  String get interactiveWorldMap => 'Bản đồ thế giới tương tác';

  @override
  String get searchByCityName => 'Tìm theo tên thành phố';

  @override
  String get seeUserCountsPerCountry => 'Xem số người dùng theo quốc gia';

  @override
  String get upgradeToVip => 'Nâng cấp lên VIP';

  @override
  String get searchByCity => 'Tìm theo thành phố';

  @override
  String usersWorldwide(String count) {
    return '$count người dùng trên toàn thế giới';
  }

  @override
  String get noUsersFound => 'Không tìm thấy người dùng';

  @override
  String get tryDifferentCity => 'Thử thành phố khác';

  @override
  String usersCount(String count) {
    return '$count người dùng';
  }

  @override
  String get searchCountry => 'Tìm kiếm quốc gia...';

  @override
  String get wave => 'Vẫy tay';

  @override
  String get newUser => 'Người dùng mới';

  @override
  String get warningPermanent => 'Cảnh báo: Hành động này là vĩnh viễn!';

  @override
  String get deleteAccountWarning => 'Xóa tài khoản của bạn sẽ xóa vĩnh viễn:\n\n• Hồ sơ và tất cả dữ liệu cá nhân của bạn\n• Tất cả tin nhắn và cuộc trò chuyện của bạn\n• Tất cả khoảnh khắc và story của bạn\n• Đăng ký VIP của bạn (không hoàn tiền)\n• Tất cả kết nối và người theo dõi của bạn\n\nHành động này không thể hoàn tác.';

  @override
  String get deletionReasonTitle => 'Trước khi bạn đi — vì sao?';

  @override
  String get deletionReasonOptional => 'Không bắt buộc. Điều này giúp chúng tôi khắc phục.';

  @override
  String get deletionReasonNoPeople => 'Không tìm được người để trò chuyện';

  @override
  String get deletionReasonNoContent => 'Không có nội dung bằng ngôn ngữ của tôi';

  @override
  String get deletionReasonNotUseful => 'Không như tôi mong đợi';

  @override
  String get deletionReasonBugs => 'Ứng dụng hoạt động không tốt';

  @override
  String get deletionReasonNotifications => 'Quá nhiều thông báo';

  @override
  String get deletionReasonPrivacy => 'Lo ngại về quyền riêng tư';

  @override
  String get deletionReasonOther => 'Lý do khác';

  @override
  String get deletionReasonHint => 'Cho chúng tôi biết thêm (không bắt buộc)';

  @override
  String get requiredForEmailOnly => 'Chỉ bắt buộc cho tài khoản email';

  @override
  String get pleaseEnterPassword => 'Vui lòng nhập mật khẩu của bạn';

  @override
  String get typeDELETE => 'Nhập DELETE';

  @override
  String get mustTypeDELETE => 'Bạn phải nhập DELETE để tiếp tục';

  @override
  String get deletingAccount => 'Đang xóa tài khoản...';

  @override
  String get deleteMyAccountPermanently => 'Xóa vĩnh viễn tài khoản của tôi';

  @override
  String get whatsYourNativeLanguage => 'Ngôn ngữ mẹ đẻ của bạn là gì?';

  @override
  String get helpsMatchWithLearners => 'Giúp ghép đôi với người đang học';

  @override
  String get whatAreYouLearning => 'Bạn đang học gì?';

  @override
  String get connectWithNativeSpeakers => 'Kết nối với người bản ngữ';

  @override
  String get selectLearningLanguage => 'Chọn ngôn ngữ muốn học';

  @override
  String get selectCurrentLevel => 'Chọn trình độ hiện tại';

  @override
  String get beginner => 'Mới bắt đầu';

  @override
  String get elementary => 'Sơ cấp';

  @override
  String get intermediate => 'Trung cấp';

  @override
  String get upperIntermediate => 'Trung cấp cao';

  @override
  String get advanced => 'Nâng cao';

  @override
  String get proficient => 'Thành thạo';

  @override
  String get showingPartnersByDistance => 'Hiển thị đối tác theo khoảng cách';

  @override
  String get enableLocationForResults => 'Bật vị trí để có kết quả tốt hơn';

  @override
  String get enable => 'Bật';

  @override
  String get locationNotSet => 'Chưa đặt vị trí';

  @override
  String get tellUsAboutYourself => 'Cho chúng tôi biết về bạn';

  @override
  String get justACoupleQuickThings => 'Chỉ vài điều nhanh thôi';

  @override
  String get gender => 'Giới tính';

  @override
  String get birthDate => 'Ngày sinh';

  @override
  String get selectYourBirthDate => 'Chọn ngày sinh của bạn';

  @override
  String get continueButton => 'Tiếp tục';

  @override
  String get pleaseSelectGender => 'Vui lòng chọn giới tính';

  @override
  String get pleaseSelectBirthDate => 'Vui lòng chọn ngày sinh';

  @override
  String get mustBe18 => 'Bạn phải đủ 18 tuổi trở lên';

  @override
  String get invalidDate => 'Ngày không hợp lệ';

  @override
  String get almostDone => 'Sắp xong rồi!';

  @override
  String get addPhotoLocationForMatches => 'Thêm ảnh và vị trí để ghép đôi tốt hơn';

  @override
  String get addProfilePhoto => 'Thêm ảnh hồ sơ';

  @override
  String get optionalUpTo6Photos => 'Tùy chọn - tối đa 6 ảnh';

  @override
  String get requiredUpTo6Photos => 'Bắt buộc — tối đa 6 ảnh';

  @override
  String get profilePhotoRequired => 'Vui lòng thêm ít nhất một ảnh đại diện';

  @override
  String get locationOptional => 'Vui lòng đặt vị trí của bạn để tiếp tục';

  @override
  String get maximum6Photos => 'Tối đa 6 ảnh';

  @override
  String get tapToDetectLocation => 'Nhấn để phát hiện vị trí';

  @override
  String get optionalHelpsNearbyPartners => 'Bắt buộc — giúp kết nối với đối tác gần bạn';

  @override
  String get startLearning => 'Bắt đầu học';

  @override
  String get photoLocationOptional => 'Ảnh và vị trí là tùy chọn';

  @override
  String get pleaseAcceptTerms => 'Vui lòng chấp nhận điều khoản dịch vụ';

  @override
  String get iAgreeToThe => 'Tôi đồng ý với';

  @override
  String get termsOfService => 'Điều khoản dịch vụ';

  @override
  String get tapToSelectLanguage => 'Nhấn để chọn ngôn ngữ';

  @override
  String yourLevelIn(String language) {
    return 'Trình độ của bạn trong $language (tùy chọn)';
  }

  @override
  String get yourCurrentLevel => 'Trình độ hiện tại của bạn';

  @override
  String get nativeCannotBeSameAsLearning => 'Ngôn ngữ mẹ đẻ không thể giống ngôn ngữ đang học';

  @override
  String get learningCannotBeSameAsNative => 'Ngôn ngữ đang học không thể giống ngôn ngữ mẹ đẻ';

  @override
  String stepOf(String current, String total) {
    return 'Bước $current / $total';
  }

  @override
  String get continueWithGoogle => 'Tiếp tục với Google';

  @override
  String get registerLink => 'Đăng ký';

  @override
  String get pleaseEnterBothEmailAndPassword => 'Vui lòng nhập email và mật khẩu';

  @override
  String get pleaseEnterValidEmail => 'Vui lòng nhập email hợp lệ';

  @override
  String get loginSuccessful => 'Đăng nhập thành công!';

  @override
  String get stepOneOfTwo => 'Bước 1 / 2';

  @override
  String get createYourAccount => 'Tạo tài khoản';

  @override
  String get basicInfoToGetStarted => 'Thông tin cơ bản để bắt đầu';

  @override
  String get emailVerifiedLabel => 'Email (Đã xác minh)';

  @override
  String get nameLabel => 'Tên';

  @override
  String get yourDisplayName => 'Tên hiển thị';

  @override
  String get atLeast8Characters => 'Ít nhất 8 ký tự';

  @override
  String get confirmPasswordHint => 'Nhập lại mật khẩu mới';

  @override
  String get nextButton => 'Tiếp theo';

  @override
  String get pleaseEnterYourName => 'Vui lòng nhập tên';

  @override
  String get pleaseEnterAPassword => 'Vui lòng nhập mật khẩu';

  @override
  String get passwordsDoNotMatch => 'Mật khẩu không khớp';

  @override
  String get otherGender => 'Khác';

  @override
  String get continueWithGoogleAccount => 'Tiếp tục với tài khoản Google\nđể có trải nghiệm mượt mà';

  @override
  String get signingYouIn => 'Đang đăng nhập...';

  @override
  String get backToSignInMethods => 'Quay lại các cách đăng nhập';

  @override
  String get securedByGoogle => 'Được bảo mật bởi Google';

  @override
  String get dataProtectedEncryption => 'Dữ liệu của bạn được bảo vệ bằng mã hoá theo chuẩn ngành';

  @override
  String get welcomeCompleteProfile => 'Chào mừng! Vui lòng hoàn thiện hồ sơ';

  @override
  String get authWelcomeTagline => 'GẶP GỠ · TRÒ CHUYỆN · KẾT NỐI';

  @override
  String get authWelcomeCtaTitle => 'Kết bạn khắp thế giới trên Bananatalk';

  @override
  String get authWelcomeCtaSubtitle => 'Tham gia cùng hàng triệu người học ngôn ngữ ngay hôm nay';

  @override
  String get authWelcomeFeatureConnectTitle => 'Kết nối';

  @override
  String get authWelcomeFeatureConnectSubtitle => 'Gặp gỡ các đối tác học ngôn ngữ từ hơn 150 quốc gia trên toàn thế giới';

  @override
  String get authWelcomeFeatureLearnTitle => 'Học tập';

  @override
  String get authWelcomeFeatureLearnSubtitle => 'Gia sư AI, câu đố và luyện phát âm — tất cả trong một ứng dụng';

  @override
  String get authWelcomeFeatureGrowTitle => 'Phát triển';

  @override
  String get authWelcomeFeatureGrowSubtitle => 'Xây dựng khả năng nói trôi chảy thực sự qua các cuộc trò chuyện hằng ngày và cộng đồng';

  @override
  String welcomeBackName(String name) {
    return 'Chào mừng trở lại, $name!';
  }

  @override
  String get continueWithAppleId => 'Tiếp tục với Apple ID\nđể có trải nghiệm an toàn';

  @override
  String get continueWithApple => 'Tiếp tục với Apple';

  @override
  String get securedByApple => 'Được bảo mật bởi Apple';

  @override
  String get privacyProtectedApple => 'Quyền riêng tư được bảo vệ với Apple Sign-In';

  @override
  String get createAccount => 'Tạo tài khoản';

  @override
  String get enterEmailToGetStarted => 'Nhập email để bắt đầu';

  @override
  String get continueText => 'Tiếp tục';

  @override
  String get pleaseEnterEmailAddress => 'Vui lòng nhập địa chỉ email';

  @override
  String get verificationCodeSent => 'Mã xác minh đã được gửi!';

  @override
  String get forgotPasswordTitle => 'Quên mật khẩu';

  @override
  String get resetPasswordTitle => 'Đặt lại mật khẩu';

  @override
  String get enterEmailForResetCode => 'Nhập email và chúng tôi sẽ gửi mã đặt lại';

  @override
  String get sendResetCode => 'Gửi mã đặt lại';

  @override
  String get resetCodeSent => 'Mã đặt lại đã được gửi!';

  @override
  String get rememberYourPassword => 'Nhớ mật khẩu?';

  @override
  String get verifyCode => 'Xác minh mã';

  @override
  String get enterResetCode => 'Nhập mã đặt lại';

  @override
  String get weSentCodeTo => 'Chúng tôi đã gửi mã 6 chữ số đến';

  @override
  String get pleaseEnterAll6Digits => 'Vui lòng nhập đủ 6 chữ số';

  @override
  String get codeVerifiedCreatePassword => 'Xác minh thành công! Tạo mật khẩu mới';

  @override
  String get verify => 'Xác minh';

  @override
  String get didntReceiveCode => 'Không nhận được mã?';

  @override
  String get resend => 'Gửi lại';

  @override
  String resendWithTimer(String timer) {
    return 'Gửi lại (${timer}g)';
  }

  @override
  String get resetCodeResent => 'Mã đặt lại đã được gửi lại!';

  @override
  String get verifyEmail => 'Xác minh email';

  @override
  String get verifyYourEmail => 'Xác minh email của bạn';

  @override
  String get emailVerifiedSuccessfully => 'Xác minh email thành công!';

  @override
  String get verificationCodeResent => 'Mã xác minh đã được gửi lại!';

  @override
  String get createNewPassword => 'Tạo mật khẩu mới';

  @override
  String get enterNewPasswordBelow => 'Nhập mật khẩu mới bên dưới';

  @override
  String get newPassword => 'Mật khẩu mới';

  @override
  String get confirmPasswordLabel => 'Xác nhận mật khẩu';

  @override
  String get pleaseFillAllFields => 'Vui lòng điền tất cả các trường';

  @override
  String get passwordResetSuccessful => 'Đặt lại mật khẩu thành công! Đăng nhập bằng mật khẩu mới';

  @override
  String get privacyTitle => 'Quyền riêng tư';

  @override
  String get profileVisibility => 'Hiển thị hồ sơ';

  @override
  String get showCountryRegion => 'Hiển thị quốc gia/khu vực';

  @override
  String get showCountryRegionDesc => 'Hiển thị quốc gia trên hồ sơ';

  @override
  String get showCity => 'Hiển thị thành phố';

  @override
  String get showCityDesc => 'Hiển thị thành phố trên hồ sơ';

  @override
  String get showAge => 'Hiển thị tuổi';

  @override
  String get showAgeDesc => 'Hiển thị tuổi trên hồ sơ';

  @override
  String get showZodiacSign => 'Hiển thị cung hoàng đạo';

  @override
  String get showZodiacSignDesc => 'Hiển thị cung hoàng đạo trên hồ sơ';

  @override
  String get onlineStatusSection => 'Trạng thái trực tuyến';

  @override
  String get showOnlineStatus => 'Hiển thị trạng thái trực tuyến';

  @override
  String get showOnlineStatusDesc => 'Cho phép người khác thấy khi bạn trực tuyến';

  @override
  String get otherSettings => 'Cài đặt khác';

  @override
  String get showGiftingLevel => 'Hiển thị cấp quà tặng';

  @override
  String get showGiftingLevelDesc => 'Hiển thị huy hiệu cấp quà tặng';

  @override
  String get birthdayNotifications => 'Thông báo sinh nhật';

  @override
  String get birthdayNotificationsDesc => 'Nhận thông báo vào ngày sinh nhật';

  @override
  String get personalizedAds => 'Quảng cáo cá nhân hóa';

  @override
  String get personalizedAdsDesc => 'Cho phép quảng cáo cá nhân hóa';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get privacySettingsSaved => 'Đã lưu cài đặt quyền riêng tư';

  @override
  String get locationSection => 'Vị trí';

  @override
  String get updateLocation => 'Cập nhật vị trí';

  @override
  String get updateLocationDesc => 'Làm mới vị trí hiện tại';

  @override
  String get currentLocation => 'Vị trí hiện tại';

  @override
  String get locationNotAvailable => 'Vị trí không khả dụng';

  @override
  String get locationUpdated => 'Cập nhật vị trí thành công';

  @override
  String get locationPermissionDenied => 'Quyền vị trí bị từ chối. Vui lòng bật trong cài đặt.';

  @override
  String get locationServiceDisabled => 'Dịch vụ vị trí đã tắt. Vui lòng bật.';

  @override
  String get updatingLocation => 'Đang cập nhật vị trí...';

  @override
  String get locationCouldNotBeUpdated => 'Không thể cập nhật vị trí';

  @override
  String get incomingAudioCall => 'Cuộc gọi thoại đến';

  @override
  String get incomingVideoCall => 'Cuộc gọi video đến';

  @override
  String get outgoingCall => 'Đang gọi...';

  @override
  String get callRinging => 'Đang đổ chuông...';

  @override
  String get callConnecting => 'Đang kết nối...';

  @override
  String get callConnected => 'Đã kết nối';

  @override
  String get callReconnecting => 'Đang kết nối lại...';

  @override
  String get callEnded => 'Cuộc gọi kết thúc';

  @override
  String get callFailed => 'Cuộc gọi thất bại';

  @override
  String get callMissed => 'Cuộc gọi nhỡ';

  @override
  String get callDeclined => 'Cuộc gọi bị từ chối';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => 'Chấp nhận';

  @override
  String get declineCall => 'Từ chối';

  @override
  String get endCall => 'Kết thúc';

  @override
  String get muteCall => 'Tắt tiếng';

  @override
  String get unmuteCall => 'Bật tiếng';

  @override
  String get speakerOn => 'Loa ngoài';

  @override
  String get speakerOff => 'Tai nghe';

  @override
  String get videoOn => 'Bật video';

  @override
  String get videoOff => 'Tắt video';

  @override
  String get switchCamera => 'Đổi camera';

  @override
  String get callPermissionDenied => 'Cần quyền micro để gọi điện';

  @override
  String get cameraPermissionDenied => 'Cần quyền camera để gọi video';

  @override
  String get callConnectionFailed => 'Không thể kết nối. Vui lòng thử lại.';

  @override
  String get userBusy => 'Người dùng bận';

  @override
  String get userOffline => 'Người dùng ngoại tuyến';

  @override
  String get callHistory => 'Lịch sử cuộc gọi';

  @override
  String get noCallHistory => 'Không có lịch sử cuộc gọi';

  @override
  String get missedCalls => 'Cuộc gọi nhỡ';

  @override
  String get allCalls => 'Tất cả cuộc gọi';

  @override
  String get callBack => 'Gọi lại';

  @override
  String callAt(String time) {
    return 'Cuộc gọi lúc $time';
  }

  @override
  String get audioCall => 'Cuộc gọi thoại';

  @override
  String get voiceRoom => 'Phòng thoại';

  @override
  String get noVoiceRooms => 'Không có phòng thoại đang hoạt động';

  @override
  String get createVoiceRoom => 'Tạo phòng thoại';

  @override
  String get joinRoom => 'Tham gia phòng';

  @override
  String get leaveRoomConfirm => 'Rời phòng?';

  @override
  String get leaveRoomMessage => 'Bạn có chắc muốn rời khỏi phòng này không?';

  @override
  String get roomTitle => 'Tiêu đề phòng';

  @override
  String get roomTitleHint => 'Nhập tiêu đề phòng';

  @override
  String get roomTopic => 'Chủ đề';

  @override
  String get roomLanguage => 'Ngôn ngữ';

  @override
  String get roomHost => 'Chủ phòng';

  @override
  String roomParticipants(int count) {
    return '$count người tham gia';
  }

  @override
  String roomMaxParticipants(int count) {
    return 'Tối đa $count người';
  }

  @override
  String get selectTopic => 'Chọn chủ đề';

  @override
  String get raiseHand => 'Giơ tay';

  @override
  String get lowerHand => 'Hạ tay';

  @override
  String get handRaisedNotification => 'Đã giơ tay! Chủ phòng sẽ thấy yêu cầu của bạn.';

  @override
  String get handLoweredNotification => 'Đã hạ tay';

  @override
  String get muteParticipant => 'Tắt tiếng người tham gia';

  @override
  String get kickParticipant => 'Xóa khỏi phòng';

  @override
  String get promoteToCoHost => 'Nâng lên đồng chủ phòng';

  @override
  String get endRoomConfirm => 'Kết thúc phòng?';

  @override
  String get endRoomMessage => 'Điều này sẽ kết thúc phòng cho tất cả người tham gia.';

  @override
  String get roomEnded => 'Chủ phòng đã kết thúc phòng';

  @override
  String get youWereRemoved => 'Bạn đã bị xóa khỏi phòng';

  @override
  String get roomIsFull => 'Phòng đã đầy';

  @override
  String get roomChat => 'Chat phòng';

  @override
  String get noMessages => 'Chưa có tin nhắn';

  @override
  String get typeMessage => 'Nhập tin nhắn...';

  @override
  String get voiceRoomsDescription => 'Tham gia trò chuyện trực tiếp và luyện nói';

  @override
  String liveRoomsCount(int count) {
    return '$count đang phát';
  }

  @override
  String get noActiveRooms => 'Không có phòng đang hoạt động';

  @override
  String get noActiveRoomsDescription => 'Hãy là người đầu tiên tạo phòng thoại và luyện nói với người khác!';

  @override
  String get startRoom => 'Bắt đầu phòng';

  @override
  String get createRoom => 'Tạo phòng';

  @override
  String get roomCreated => 'Tạo phòng thành công!';

  @override
  String get failedToCreateRoom => 'Tạo phòng thất bại';

  @override
  String get errorLoadingRooms => 'Lỗi tải phòng';

  @override
  String get pleaseEnterRoomTitle => 'Vui lòng nhập tiêu đề phòng';

  @override
  String get startLiveConversation => 'Bắt đầu trò chuyện trực tiếp';

  @override
  String get maxParticipants => 'Số người tối đa';

  @override
  String nPeople(int count) {
    return '$count người';
  }

  @override
  String hostedBy(String name) {
    return 'Tổ chức bởi $name';
  }

  @override
  String get liveLabel => 'TRỰC TIẾP';

  @override
  String get joinLabel => 'Tham gia';

  @override
  String get fullLabel => 'Đã đầy';

  @override
  String get justStarted => 'Vừa bắt đầu';

  @override
  String get allLanguages => 'Tất cả ngôn ngữ';

  @override
  String get allTopics => 'Tất cả chủ đề';

  @override
  String get allCategories => 'Tất cả danh mục';

  @override
  String get leaderboard => 'Bảng xếp hạng';

  @override
  String get competeWithLearners => 'Cạnh tranh với người học khác!';

  @override
  String get xpRankings => 'Xếp hạng XP';

  @override
  String get streaks => 'Chuỗi ngày học';

  @override
  String get friends => 'Bạn bè';

  @override
  String get myRanks => 'Xếp hạng của tôi';

  @override
  String get currentStreak => 'Chuỗi hiện tại';

  @override
  String get longestStreak => 'Chuỗi dài nhất';

  @override
  String get weekly => 'Hàng tuần';

  @override
  String get monthly => 'Hàng tháng';

  @override
  String get yourRank => 'Thứ hạng của bạn';

  @override
  String outOf(int total) {
    return 'trên tổng số $total';
  }

  @override
  String topPercent(String percent) {
    return 'Top $percent%';
  }

  @override
  String get xpRank => 'Xếp hạng XP';

  @override
  String get streakRank => 'Xếp hạng chuỗi ngày';

  @override
  String get days => 'ngày';

  @override
  String get learningStats => 'Thống kê học tập';

  @override
  String get totalXp => 'Tổng XP';

  @override
  String get lessonsCompleted => 'Bài học đã hoàn thành';

  @override
  String get rankings => 'Xếp hạng';

  @override
  String get yourPosition => 'Vị trí của bạn';

  @override
  String get keepLearning => 'Tiếp tục học để thăng hạng!';

  @override
  String get noRankingsYet => 'Chưa có xếp hạng';

  @override
  String get startLearningToAppear => 'Bắt đầu học để xuất hiện trên bảng xếp hạng!';

  @override
  String get noFriendsYet => 'Chưa có bạn bè';

  @override
  String get addFriendsToCompete => 'Thêm bạn bè để cạnh tranh với họ!';

  @override
  String get failedToLoadLeaderboard => 'Không thể tải bảng xếp hạng';

  @override
  String get you => 'Bạn';

  @override
  String get findPartners => 'Tìm bạn học';

  @override
  String get discoverLanguagePartners => 'Khám phá bạn học ngôn ngữ';

  @override
  String get byLanguage => 'Theo ngôn ngữ';

  @override
  String get match => 'phù hợp';

  @override
  String get matchScore => 'Điểm phù hợp';

  @override
  String get noMatchesFound => 'Không tìm thấy kết quả phù hợp';

  @override
  String get noUsersOnline => 'Không có người dùng trực tuyến';

  @override
  String get checkBackLater => 'Quay lại sau nhé';

  @override
  String get selectLanguagePrompt => 'Chọn một ngôn ngữ';

  @override
  String get findPartnersByLanguage => 'Tìm bạn học nói hoặc học ngôn ngữ này';

  @override
  String noPartnersForLanguage(String language) {
    return 'Không có bạn học cho $language';
  }

  @override
  String get tryAnotherLanguage => 'Hãy thử chọn ngôn ngữ khác';

  @override
  String get failedToLoadMatches => 'Không thể tải kết quả phù hợp';

  @override
  String get dataAndStorage => 'Dữ liệu và Bộ nhớ';

  @override
  String get manageStorageAndDownloads => 'Quản lý bộ nhớ và tải xuống';

  @override
  String get storageUsage => 'Sử dụng Bộ nhớ';

  @override
  String get totalCacheSize => 'Tổng Kích thước Cache';

  @override
  String get imageCache => 'Cache Hình ảnh';

  @override
  String get voiceMessagesCache => 'Tin nhắn Thoại';

  @override
  String get videoCache => 'Cache Video';

  @override
  String get otherCache => 'Cache Khác';

  @override
  String get autoDownloadMedia => 'Tự động Tải Phương tiện';

  @override
  String get currentNetwork => 'Mạng Hiện tại';

  @override
  String get images => 'Hình ảnh';

  @override
  String get videos => 'Video';

  @override
  String get voiceMessagesShort => 'Tin nhắn Thoại';

  @override
  String get documentsLabel => 'Tài liệu';

  @override
  String get wifiOnly => 'Chỉ WiFi';

  @override
  String get never => 'Không bao giờ';

  @override
  String get clearAllCache => 'Xóa Toàn bộ Cache';

  @override
  String get allCache => 'Toàn bộ Cache';

  @override
  String get clearAllCacheConfirmation => 'Thao tác này sẽ xóa tất cả hình ảnh, tin nhắn thoại, video và các tệp khác đã lưu trong bộ nhớ đệm. Ứng dụng có thể tải nội dung chậm hơn tạm thời.';

  @override
  String clearCacheConfirmationFor(String category) {
    return 'Xóa $category?';
  }

  @override
  String storageToFree(String size) {
    return '$size sẽ được giải phóng';
  }

  @override
  String get calculating => 'Đang tính toán...';

  @override
  String get noDataToShow => 'Không có dữ liệu để hiển thị';

  @override
  String get profileCompletion => 'Hoàn thành hồ sơ';

  @override
  String get justGettingStarted => 'Mới bắt đầu';

  @override
  String get lookingGood => 'Nhìn tốt!';

  @override
  String get almostThere => 'Sắp xong rồi!';

  @override
  String addMissingFields(String fields, Object field) {
    return 'Thêm $field để hoàn thành hồ sơ';
  }

  @override
  String get profilePicture => 'Ảnh hồ sơ';

  @override
  String get nativeSpeaker => 'Bản ngữ';

  @override
  String peopleInterestedInTopic(Object count) {
    return '$count người quan tâm';
  }

  @override
  String get beFirstToAddTopic => 'Hãy là người đầu tiên thêm chủ đề này!';

  @override
  String get recentMoments => 'Khoảnh khắc gần đây';

  @override
  String get seeAll => 'Xem tất cả';

  @override
  String get study => 'Học tập';

  @override
  String get followerMoments => 'Khoảnh khắc từ người theo dõi';

  @override
  String get whenPeopleYouFollowPost => 'Khi những người bạn theo dõi đăng khoảnh khắc mới';

  @override
  String get noNotificationsYet => 'Chưa có thông báo nào';

  @override
  String get whenYouGetNotifications => 'Khi bạn nhận được thông báo, chúng sẽ hiển thị ở đây';

  @override
  String get failedToLoadNotifications => 'Không thể tải thông báo';

  @override
  String get clearAllNotificationsConfirm => 'Bạn có chắc muốn xóa tất cả thông báo? Hành động này không thể hoàn tác.';

  @override
  String get tapToChange => 'Nhấn để thay đổi';

  @override
  String get noPictureSet => 'Chưa đặt ảnh';

  @override
  String get nameAndGender => 'Tên và Giới tính';

  @override
  String get languageLevel => 'Trình độ ngôn ngữ';

  @override
  String get personalInformation => 'Thông tin Cá nhân';

  @override
  String get mbti => 'MBTI';

  @override
  String get topicsOfInterest => 'Chủ đề Quan tâm';

  @override
  String get levelBeginner => 'Sơ cấp';

  @override
  String get levelElementary => 'Cơ bản';

  @override
  String get levelIntermediate => 'Trung cấp';

  @override
  String get levelUpperIntermediate => 'Trung cấp Cao';

  @override
  String get levelAdvanced => 'Nâng cao';

  @override
  String get levelProficient => 'Thành thạo';

  @override
  String get selectYourLevel => 'Chọn Trình độ';

  @override
  String howWellDoYouSpeak(String language) {
    return 'Bạn nói $language tốt đến đâu?';
  }

  @override
  String get theLanguage => 'ngôn ngữ';

  @override
  String languageLevelSetTo(String level) {
    return 'Trình độ ngôn ngữ đặt là $level';
  }

  @override
  String get failedToUpdate => 'Cập nhật thất bại';

  @override
  String get profileUpdatedSuccessfully => 'Cập nhật hồ sơ thành công';

  @override
  String get genderRequired => 'Giới tính (Bắt buộc)';

  @override
  String get editHometown => 'Sửa Quê quán';

  @override
  String get useCurrentLocation => 'Dùng Vị trí Hiện tại';

  @override
  String get detecting => 'Đang phát hiện...';

  @override
  String get getCurrentLocation => 'Lấy Vị trí Hiện tại';

  @override
  String get country => 'Quốc gia';

  @override
  String get city => 'Thành phố';

  @override
  String get coordinates => 'Tọa độ';

  @override
  String get noLocationDetectedYet => 'Chưa phát hiện vị trí';

  @override
  String get detected => 'Đã phát hiện';

  @override
  String get savedHometown => 'Đã lưu quê quán';

  @override
  String get locationServicesDisabled => 'Dịch vụ vị trí bị tắt';

  @override
  String get locationPermissionPermanentlyDenied => 'Quyền vị trí bị từ chối';

  @override
  String get unknown => 'Không rõ';

  @override
  String get editBio => 'Sửa Tiểu sử';

  @override
  String get bioUpdatedSuccessfully => 'Cập nhật tiểu sử thành công';

  @override
  String get tellOthersAboutYourself => 'Giới thiệu về bạn...';

  @override
  String charactersCount(int count) {
    return '$count/500 ký tự';
  }

  @override
  String get selectYourMbti => 'Chọn MBTI';

  @override
  String get myBloodType => 'Nhóm máu';

  @override
  String get pleaseSelectABloodType => 'Vui lòng chọn nhóm máu';

  @override
  String get bloodTypeSavedSuccessfully => 'Nhóm máu đã được lưu thành công';

  @override
  String get hometownSavedSuccessfully => 'Quê hương đã được lưu thành công';

  @override
  String get nativeLanguageRequired => 'Ngôn ngữ Mẹ đẻ (Bắt buộc)';

  @override
  String get languageToLearnRequired => 'Ngôn ngữ Học (Bắt buộc)';

  @override
  String get nativeLanguageCannotBeSame => 'Ngôn ngữ mẹ đẻ không thể giống ngôn ngữ học';

  @override
  String get learningLanguageCannotBeSame => 'Ngôn ngữ học không thể giống ngôn ngữ mẹ đẻ';

  @override
  String get pleaseSelectALanguage => 'Vui lòng chọn ngôn ngữ';

  @override
  String get editInterests => 'Sửa Sở thích';

  @override
  String maxTopicsAllowed(int count) {
    return 'Tối đa $count chủ đề';
  }

  @override
  String get topicsUpdatedSuccessfully => 'Cập nhật chủ đề thành công!';

  @override
  String get failedToUpdateTopics => 'Cập nhật chủ đề thất bại';

  @override
  String selectedCount(int count, int max) {
    return '$count/$max đã chọn';
  }

  @override
  String get profilePictures => 'Ảnh Hồ sơ';

  @override
  String get addImages => 'Thêm Ảnh';

  @override
  String get selectUpToImages => 'Chọn tối đa 5 ảnh';

  @override
  String get takeAPhoto => 'Chụp Ảnh';

  @override
  String get removeImage => 'Xóa Ảnh';

  @override
  String get removeImageConfirm => 'Xóa ảnh này?';

  @override
  String get removeAll => 'Xóa Tất cả';

  @override
  String get removeAllSelectedImages => 'Xóa Tất cả Ảnh đã Chọn';

  @override
  String get removeAllSelectedImagesConfirm => 'Xóa tất cả ảnh đã chọn?';

  @override
  String get yourProfilePictureWillBeKept => 'Ảnh hồ sơ hiện tại sẽ được giữ';

  @override
  String get removeAllImages => 'Xóa Tất cả Ảnh';

  @override
  String get removeAllImagesConfirm => 'Xóa tất cả ảnh hồ sơ?';

  @override
  String get currentImages => 'Ảnh Hiện tại';

  @override
  String get newImages => 'Ảnh Mới';

  @override
  String get addMoreImages => 'Thêm Ảnh Khác';

  @override
  String uploadImages(int count) {
    return 'Tải lên $count Ảnh';
  }

  @override
  String get imageRemovedSuccessfully => 'Đã xóa ảnh';

  @override
  String get imagesUploadedSuccessfully => 'Tải ảnh thành công';

  @override
  String get selectedImagesCleared => 'Đã xóa ảnh đã chọn';

  @override
  String get extraImagesRemovedSuccessfully => 'Đã xóa ảnh thừa';

  @override
  String get mustKeepAtLeastOneProfilePicture => 'Phải giữ ít nhất 1 ảnh hồ sơ';

  @override
  String get noProfilePicturesToRemove => 'Không có ảnh để xóa';

  @override
  String get authenticationTokenNotFound => 'Không tìm thấy token';

  @override
  String get saveChangesQuestion => 'Lưu Thay đổi?';

  @override
  String youHaveUnuploadedImages(int count) {
    return '$count ảnh chưa tải. Tải ngay?';
  }

  @override
  String get discard => 'Hủy';

  @override
  String get upload => 'Tải lên';

  @override
  String maxImagesInfo(int max, int current) {
    return 'Tối đa $max ảnh. Hiện tại: $current/$max';
  }

  @override
  String canOnlyAddMoreImages(int count, int max) {
    return 'Chỉ thêm được $count ảnh nữa. Tối đa $max.';
  }

  @override
  String get maxImagesPerUpload => 'Tối đa 5 ảnh mỗi lần';

  @override
  String canOnlyHaveMaxImages(int max) {
    return 'Tối đa $max ảnh';
  }

  @override
  String get imageSizeExceedsLimit => 'Kích thước vượt quá 10MB';

  @override
  String get unsupportedImageFormat => 'Định dạng không hỗ trợ';

  @override
  String get pleaseSelectAtLeastOneImage => 'Vui lòng chọn ít nhất 1 ảnh';

  @override
  String get basicInformation => 'Thông tin Cơ bản';

  @override
  String get languageToLearn => 'Ngôn ngữ Học';

  @override
  String get hometown => 'Quê quán';

  @override
  String get characters => 'ký tự';

  @override
  String get failedToLoadLanguages => 'Tải ngôn ngữ thất bại';

  @override
  String get studyHub => 'Trung tâm học tập';

  @override
  String get dailyLearningJourney => 'Hành trình học tập hàng ngày của bạn';

  @override
  String get learnTab => 'Học';

  @override
  String get aiTools => 'Luyện tập';

  @override
  String get streak => 'Chuỗi học';

  @override
  String get lessons => 'Bài học';

  @override
  String get words => 'Từ vựng';

  @override
  String get quickActions => 'Thao tác nhanh';

  @override
  String get review => 'Ôn tập';

  @override
  String wordsDue(int count) {
    return '$count từ cần ôn tập';
  }

  @override
  String get addWords => 'Thêm từ';

  @override
  String get buildVocabulary => 'Xây dựng vốn từ';

  @override
  String get practiceWithAI => 'Luyện tập với AI';

  @override
  String get aiPracticeDescription => 'Chat, bài kiểm tra, ngữ pháp và phát âm';

  @override
  String get dailyChallenges => 'Thử thách hàng ngày';

  @override
  String get allChallengesCompleted => 'Tất cả thử thách đã hoàn thành!';

  @override
  String get continueLearning => 'Tiếp tục học';

  @override
  String get structuredLearningPath => 'Lộ trình học có cấu trúc';

  @override
  String get vocabulary => 'Từ vựng';

  @override
  String get yourWordCollection => 'Bộ sưu tập từ của bạn';

  @override
  String get achievements => 'Thành tích';

  @override
  String get badgesAndMilestones => 'Huy hiệu và cột mốc';

  @override
  String get failedToLoadLearningData => 'Tải dữ liệu học tập thất bại';

  @override
  String get startYourJourney => 'Bắt đầu hành trình của bạn!';

  @override
  String get startJourneyDescription => 'Hoàn thành bài học, xây dựng vốn từ\nvà theo dõi tiến trình của bạn';

  @override
  String levelN(int level) {
    return 'Cấp độ $level';
  }

  @override
  String xpEarned(int xp) {
    return 'Đã kiếm $xp XP';
  }

  @override
  String nextLevel(int level) {
    return 'Tiếp theo: Cấp độ $level';
  }

  @override
  String xpToGo(int xp) {
    return 'Còn $xp XP';
  }

  @override
  String get aiConversationPartner => 'Đối tác hội thoại AI';

  @override
  String get practiceWithAITutor => 'Luyện nói với gia sư AI của bạn';

  @override
  String get startConversation => 'Bắt đầu hội thoại';

  @override
  String get aiFeatures => 'Tính năng AI';

  @override
  String get aiLessons => 'Bài học AI';

  @override
  String get learnWithAI => 'Học với AI';

  @override
  String get grammar => 'Ngữ pháp';

  @override
  String get checkWriting => 'Kiểm tra viết';

  @override
  String get pronunciation => 'Phát âm';

  @override
  String get improveSpeaking => 'Cải thiện nói';

  @override
  String get translation => 'Dịch thuật';

  @override
  String get smartTranslate => 'Dịch thông minh';

  @override
  String get aiQuizzes => 'Bài kiểm tra AI';

  @override
  String get testKnowledge => 'Kiểm tra kiến thức';

  @override
  String get lessonBuilder => 'Trình tạo bài học';

  @override
  String get customLessons => 'Bài học tùy chỉnh';

  @override
  String get yourAIProgress => 'Tiến trình AI của bạn';

  @override
  String get quizzes => 'Bài kiểm tra';

  @override
  String get avgScore => 'Điểm trung bình';

  @override
  String get focusAreas => 'Khu vực trọng tâm';

  @override
  String accuracyPercent(String accuracy) {
    return 'Độ chính xác $accuracy%';
  }

  @override
  String get practice => 'Luyện tập';

  @override
  String get browse => 'Duyệt';

  @override
  String get noRecommendedLessons => 'Không có bài học được đề xuất';

  @override
  String get noLessonsFound => 'Không tìm thấy bài học';

  @override
  String get createCustomLessonDescription => 'Tạo bài học tùy chỉnh của riêng bạn với AI';

  @override
  String get createLessonWithAI => 'Tạo bài học với AI';

  @override
  String get allLevels => 'Tất cả cấp độ';

  @override
  String get levelA1 => 'A1 Người mới bắt đầu';

  @override
  String get levelA2 => 'A2 Cơ bản';

  @override
  String get levelB1 => 'B1 Trung cấp';

  @override
  String get levelB2 => 'B2 Trung-Cao';

  @override
  String get levelC1 => 'C1 Nâng cao';

  @override
  String get levelC2 => 'C2 Thành thạo';

  @override
  String get failedToLoadLessons => 'Tải bài học thất bại';

  @override
  String get pin => 'Ghim';

  @override
  String get unpin => 'Bỏ ghim';

  @override
  String get editMessage => 'Chỉnh sửa tin nhắn';

  @override
  String get enterMessage => 'Nhập tin nhắn...';

  @override
  String get deleteMessageTitle => 'Xóa tin nhắn';

  @override
  String get actionCannotBeUndone => 'Hành động này không thể hoàn tác.';

  @override
  String get onlyRemovesFromDevice => 'Chỉ xóa khỏi thiết bị của bạn';

  @override
  String get availableWithinOneHour => 'Chỉ khả dụng trong 1 giờ';

  @override
  String get available => 'Khả dụng';

  @override
  String get forwardMessage => 'Chuyển tiếp tin nhắn';

  @override
  String get selectUsersToForward => 'Chọn người dùng để chuyển tiếp:';

  @override
  String forwardCount(int count) {
    return 'Chuyển tiếp ($count)';
  }

  @override
  String get pinnedMessage => 'Tin nhắn đã ghim';

  @override
  String get photoMedia => 'Ảnh';

  @override
  String get videoMedia => 'Video';

  @override
  String get voiceMessageMedia => 'Tin nhắn thoại';

  @override
  String get documentMedia => 'Tài liệu';

  @override
  String get locationMedia => 'Vị trí';

  @override
  String get stickerMedia => 'Nhãn dán';

  @override
  String get smileys => 'Mặt cười';

  @override
  String get emotions => 'Cảm xúc';

  @override
  String get handGestures => 'Cử chỉ tay';

  @override
  String get hearts => 'Trái tim';

  @override
  String get tapToSayHi => 'Nhấn để chào!';

  @override
  String get sendWaveToStart => 'Gửi lời chào để bắt đầu trò chuyện';

  @override
  String get documentMustBeUnder50MB => 'Tài liệu phải dưới 50MB.';

  @override
  String get editWithin15Minutes => 'Tin nhắn chỉ có thể chỉnh sửa trong 15 phút';

  @override
  String messageForwardedTo(int count) {
    return 'Tin nhắn đã chuyển tiếp đến $count người dùng';
  }

  @override
  String get failedToLoadUsers => 'Không thể tải người dùng';

  @override
  String get voice => 'Giọng nói';

  @override
  String get searchGifs => 'Tìm kiếm GIF...';

  @override
  String get trendingGifs => 'Thịnh hành';

  @override
  String get poweredByGiphy => 'Powered by GIPHY';

  @override
  String get gif => 'GIF';

  @override
  String get noGifsFound => 'Không tìm thấy GIF';

  @override
  String get failedToLoadGifs => 'Không thể tải GIF';

  @override
  String get gifSent => 'GIF';

  @override
  String get filterCommunities => 'Lọc';

  @override
  String get reset => 'Đặt lại';

  @override
  String get findYourPerfect => 'Tìm người bạn';

  @override
  String get languagePartner => 'học ngôn ngữ hoàn hảo';

  @override
  String get learningLanguageLabel => 'Ngôn ngữ đang học';

  @override
  String get ageRange => 'Khoảng tuổi';

  @override
  String get genderPreference => 'Sở thích giới tính';

  @override
  String get any => 'Bất kỳ';

  @override
  String get showNewUsersSubtitle => 'Hiển thị người dùng đã tham gia trong 6 ngày qua';

  @override
  String get autoDetectLocation => 'Tự động phát hiện vị trí của tôi';

  @override
  String get selectCountry => 'Chọn quốc gia';

  @override
  String get anyCountry => 'Bất kỳ quốc gia nào';

  @override
  String get loadingLanguages => 'Đang tải ngôn ngữ...';

  @override
  String minAge(int age) {
    return 'Tối thiểu: $age';
  }

  @override
  String maxAge(int age) {
    return 'Tối đa: $age';
  }

  @override
  String get captionRequired => 'Chú thích là bắt buộc';

  @override
  String captionTooLong(int maxLength) {
    return 'Chú thích phải có $maxLength ký tự trở xuống';
  }

  @override
  String get maximumImagesReached => 'Đã đạt giới hạn hình ảnh';

  @override
  String maximumImagesReachedDescription(int maxImages) {
    return 'Bạn chỉ có thể tải lên tối đa $maxImages hình ảnh mỗi khoảnh khắc.';
  }

  @override
  String maximumImagesAddedPartial(int maxImages, int added) {
    return 'Tối đa $maxImages hình ảnh. Chỉ thêm được $added hình.';
  }

  @override
  String get locationAccessRestricted => 'Quyền truy cập vị trí bị hạn chế';

  @override
  String get locationPermissionNeeded => 'Cần quyền truy cập vị trí';

  @override
  String get addToYourMoment => 'Thêm vào khoảnh khắc của bạn';

  @override
  String get categoryLabel => 'Danh mục';

  @override
  String get languageLabel => 'Ngôn ngữ';

  @override
  String get scheduleOptional => 'Lên lịch (tùy chọn)';

  @override
  String get scheduleForLater => 'Lên lịch cho sau';

  @override
  String get addMore => 'Thêm nữa';

  @override
  String get howAreYouFeeling => 'Bạn đang cảm thấy thế nào?';

  @override
  String get pleaseWaitOptimizingVideo => 'Vui lòng đợi trong khi chúng tôi tối ưu hóa video của bạn';

  @override
  String unsupportedVideoFormat(String formats) {
    return 'Định dạng không được hỗ trợ. Sử dụng: $formats';
  }

  @override
  String get chooseBackground => 'Chọn hình nền';

  @override
  String likedByXPeople(int count) {
    return '$count người đã thích';
  }

  @override
  String xComments(int count) {
    return '$count bình luận';
  }

  @override
  String get oneComment => '1 bình luận';

  @override
  String get addAComment => 'Thêm bình luận...';

  @override
  String viewXReplies(int count) {
    return 'Xem $count phản hồi';
  }

  @override
  String seenByX(int count) {
    return 'Đã xem bởi $count';
  }

  @override
  String xHoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String xMinutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String get repliedToYourStory => 'Đã trả lời tin của bạn';

  @override
  String mentionedYouInComment(String name) {
    return '$name đã nhắc đến bạn trong bình luận';
  }

  @override
  String repliedToYourComment(String name) {
    return '$name đã trả lời bình luận của bạn';
  }

  @override
  String reactedToYourComment(String name) {
    return '$name đã phản ứng bình luận của bạn';
  }

  @override
  String get addReaction => 'Thêm phản ứng';

  @override
  String get attachImage => 'Đính kèm ảnh';

  @override
  String get pickGif => 'Chọn GIF';

  @override
  String get textStory => 'Văn bản';

  @override
  String get typeYourStory => 'Viết tin của bạn...';

  @override
  String get selectBackground => 'Chọn nền';

  @override
  String get highlightsTitle => 'Nổi bật';

  @override
  String get highlightTitle => 'Tiêu đề';

  @override
  String get createNewHighlight => 'Tạo mới';

  @override
  String get selectStories => 'Chọn tin';

  @override
  String get selectCover => 'Chọn ảnh bìa';

  @override
  String get addText => 'Thêm văn bản';

  @override
  String get fontStyleLabel => 'Kiểu chữ';

  @override
  String get textColorLabel => 'Màu chữ';

  @override
  String get dragToDelete => 'Kéo vào đây để xóa';

  @override
  String get noBlockedUsers => 'Không có người dùng bị chặn';

  @override
  String get usersYouBlockWillAppearHere => 'Người dùng bạn chặn sẽ xuất hiện ở đây';

  @override
  String unblockConfirm(String name) {
    return 'Bạn có chắc muốn bỏ chặn $name không?';
  }

  @override
  String reasonLabel(String reason) {
    return 'Lý do: $reason';
  }

  @override
  String blockedAgo(String time) {
    return 'Đã chặn $time';
  }

  @override
  String errorLoadingBlockedUsers(String error) {
    return 'Lỗi khi tải danh sách người dùng bị chặn: $error';
  }

  @override
  String get logoutConfirmMessage => 'Bạn có chắc muốn đăng xuất khỏi Bananatalk không?';

  @override
  String get loggingOut => 'Đang đăng xuất...';

  @override
  String get quietHours => 'Giờ yên tĩnh';

  @override
  String get quietHoursEnable => 'Bật giờ yên tĩnh';

  @override
  String get quietHoursSubtitle => 'Tạm dừng thông báo không khẩn cấp trong một khoảng thời gian';

  @override
  String get quietHoursStart => 'Giờ bắt đầu';

  @override
  String get quietHoursEnd => 'Giờ kết thúc';

  @override
  String get quietHoursAllowUrgent => 'Cho phép thông báo khẩn cấp';

  @override
  String get quietHoursAllowUrgentSubtitle => 'Cuộc gọi và tin nhắn từ đối tác VIP vẫn có thể được gửi đến';

  @override
  String get silencedByQuietHours => 'Đã tắt tiếng bởi giờ yên tĩnh';

  @override
  String get silencedByCap => 'Đã tắt tiếng do giới hạn hàng ngày';

  @override
  String get momentUpdatedSuccessfully => 'Khoảnh khắc đã được cập nhật thành công';

  @override
  String get failedToDeleteMoment => 'Xóa khoảnh khắc thất bại';

  @override
  String get failedToUpdateMoment => 'Cập nhật khoảnh khắc thất bại';

  @override
  String get mbtiUpdatedSuccessfully => 'Cập nhật MBTI thành công';

  @override
  String get pleaseSelectMbti => 'Vui lòng chọn loại MBTI';

  @override
  String get languageUpdatedSuccessfully => 'Cập nhật ngôn ngữ thành công';

  @override
  String get bioHintCard => 'Một tiểu sử hay giúp người khác kết nối với bạn hơn. Hãy chia sẻ sở thích, ngôn ngữ hoặc điều bạn đang tìm kiếm.';

  @override
  String get bioCounterStartWriting => 'Bắt đầu viết...';

  @override
  String get bioCounterABitMore => 'Thêm một chút nữa sẽ tốt hơn';

  @override
  String get bioCounterAlmostAtLimit => 'Gần đến giới hạn';

  @override
  String get bioCounterTooLong => 'Quá dài';

  @override
  String get bioQuickStarters => 'Gợi ý nhanh';

  @override
  String get rhPositive => 'Rh Dương';

  @override
  String get rhNegative => 'Rh Âm';

  @override
  String get rhPositiveDesc => 'Phổ biến nhất';

  @override
  String get rhNegativeDesc => 'Người hiến máu toàn phần / hiếm';

  @override
  String get yourBloodType => 'Nhóm máu của bạn';

  @override
  String get noBloodTypeSelected => 'Chưa chọn nhóm máu';

  @override
  String get tapTypeBelow => 'Chọn nhóm máu bên dưới';

  @override
  String get tapButtonToDetectLocation => 'Nhấn nút bên dưới để xác định vị trí hiện tại của bạn';

  @override
  String currentAddressLabel(String address) {
    return 'Hiện tại: $address';
  }

  @override
  String get onlyCityCountryShown => 'Chỉ thành phố và quốc gia của bạn được hiển thị cho người khác. Tọa độ chính xác vẫn được giữ bí mật.';

  @override
  String get updateLocationCta => 'Cập nhật vị trí';

  @override
  String get enterYourName => 'Nhập tên của bạn';

  @override
  String get unsavedChanges => 'Bạn có những thay đổi chưa được lưu';

  @override
  String tapBelowToBrowseLanguages(int count) {
    return 'Nhấn bên dưới để duyệt $count ngôn ngữ';
  }

  @override
  String get changeLanguage => 'Thay đổi ngôn ngữ';

  @override
  String get browseLanguages => 'Xem các ngôn ngữ';

  @override
  String get yourLearningLanguageIsPrefix => 'Ngôn ngữ bạn đang học là ';

  @override
  String get yourNativeLanguageIsPrefix => 'Ngôn ngữ mẹ đẻ của bạn là ';

  @override
  String get profileCompleteProgress => 'hoàn thành';

  @override
  String get drawerPreferences => 'Tùy chọn';

  @override
  String get drawerStorage => 'Bộ nhớ';

  @override
  String get drawerReports => 'Báo cáo';

  @override
  String get drawerSupport => 'Hỗ trợ';

  @override
  String get drawerAccount => 'Tài khoản';

  @override
  String get logoutConfirmBody => 'Bạn có chắc chắn muốn đăng xuất khỏi Bananatalk không?';

  @override
  String get helpEmailSupport => 'Hỗ trợ qua email';

  @override
  String get helpEmailSupportSubtitle => 'support@bananatalk.com';

  @override
  String get helpReportBug => 'Báo cáo lỗi';

  @override
  String get helpReportBugSubtitle => 'Giúp chúng tôi cải thiện Bananatalk';

  @override
  String get helpFaqs => 'Câu hỏi thường gặp';

  @override
  String get helpFaqsSubtitle => 'Các câu hỏi phổ biến';

  @override
  String get aboutDialogClose => 'Đóng';

  @override
  String get aboutBananatalkTagline => 'Kết nối với những người học ngôn ngữ trên toàn thế giới và nâng cao kỹ năng qua các cuộc hội thoại thực tế.';

  @override
  String get aboutCopyright => '© 2024 Bananatalk. Tất cả các quyền được bảo lưu.';

  @override
  String get logoutFailedPrefix => 'Đăng xuất thất bại';

  @override
  String get profileVisitorsTitle => 'Người xem hồ sơ';

  @override
  String get visitorStatistics => 'Thống kê lượt xem';

  @override
  String get visitorsTotalVisits => 'Tổng lượt xem';

  @override
  String get visitorsUniqueVisitors => 'Người xem duy nhất';

  @override
  String get visitorsToday => 'Hôm nay';

  @override
  String get visitorsThisWeek => 'Tuần này';

  @override
  String get noVisitorsYet => 'Chưa có người xem';

  @override
  String get noVisitorsYetSubtitle => 'Khi có người xem hồ sơ của bạn,\nhọ sẽ xuất hiện ở đây';

  @override
  String get visitedViaSearch => 'qua Tìm kiếm';

  @override
  String get visitedViaMoments => 'qua Khoảnh khắc';

  @override
  String get visitedViaChat => 'qua Trò chuyện';

  @override
  String get visitedDirect => 'Truy cập trực tiếp';

  @override
  String get visitorTrackingUnavailable => 'Tính năng theo dõi người xem không khả dụng. Vui lòng cập nhật backend.';

  @override
  String get visitorTrackingNotAvailableYet => 'Theo dõi người xem chưa khả dụng';

  @override
  String get noFollowersYetSubtitle => 'Hãy bắt đầu kết nối với người khác!';

  @override
  String get partnerButton => 'Đối tác';

  @override
  String get notFollowingAnyoneYetSubtitle => 'Bắt đầu theo dõi mọi người để xem cập nhật của họ!';

  @override
  String get unfollowButton => 'Bỏ theo dõi';

  @override
  String get profileThemeTitle => 'Giao diện hồ sơ';

  @override
  String get themeAutoSwitch => 'Tự động chuyển (Giao diện hệ thống)';

  @override
  String get themeSystemHint => 'Khi bật, ứng dụng sẽ theo cài đặt giao diện hệ thống của bạn';

  @override
  String get themeLightMode => 'Chế độ sáng';

  @override
  String get themeDarkMode => 'Chế độ tối';

  @override
  String get myMoments => 'Khoảnh khắc của tôi';

  @override
  String get momentListView => 'Xem danh sách';

  @override
  String get momentGridView => 'Xem lưới';

  @override
  String get shareLanguageLearningJourney => 'Chia sẻ hành trình học ngôn ngữ của bạn!';

  @override
  String get deleteHighlightTitle => 'Xóa nổi bật';

  @override
  String deleteHighlightConfirm(String title) {
    return 'Xóa \"$title\"? Các câu chuyện bên trong sẽ không bị xóa.';
  }

  @override
  String get highlightDeletedSuccess => 'Đã xóa nổi bật';

  @override
  String get highlightNewBadge => 'Mới';

  @override
  String get editMoment => 'Chỉnh sửa khoảnh khắc';

  @override
  String get momentDescriptionLabel => 'Mô tả';

  @override
  String get momentImagesLabel => 'Hình ảnh';

  @override
  String get noImagesYet => 'Chưa có hình ảnh';

  @override
  String get momentEnterDescription => 'Vui lòng nhập mô tả';

  @override
  String get momentUpdatedImageFailed => 'Khoảnh khắc đã được cập nhật nhưng tải ảnh lên thất bại';

  @override
  String get updateRequiredTitle => 'Cần cập nhật';

  @override
  String get updateAvailableTitle => 'Có bản cập nhật';

  @override
  String get updateRequiredBody => 'Phiên bản Bananatalk này không còn được hỗ trợ. Vui lòng cập nhật để tiếp tục.';

  @override
  String get updateAvailableBody => 'Có phiên bản Bananatalk mới với các cải tiến và sửa lỗi.';

  @override
  String get updateNow => 'Cập nhật ngay';

  @override
  String get updateLater => 'Để sau';

  @override
  String get updateOpenStoreFailed => 'Không thể mở cửa hàng. Vui lòng cập nhật từ App Store hoặc Play Store.';

  @override
  String get rememberMe => 'Ghi nhớ tôi';

  @override
  String get passwordWeak => 'Yếu';

  @override
  String get passwordFair => 'Khá';

  @override
  String get passwordStrong => 'Mạnh';

  @override
  String get passwordVeryStrong => 'Rất mạnh';

  @override
  String get showPassword => 'Hiện mật khẩu';

  @override
  String get hidePassword => 'Ẩn mật khẩu';

  @override
  String stepProgress(int current, int total) {
    return 'Bước $current / $total';
  }

  @override
  String get usernameOptional => 'Tên người dùng (tùy chọn)';

  @override
  String get usernameAvailable => 'Có sẵn';

  @override
  String get usernameTaken => 'Đã được sử dụng';

  @override
  String get usernameNotAvailable => 'Không khả dụng';

  @override
  String get usernameInvalidFormat => '3-20 ký tự: chữ, số hoặc gạch dưới';

  @override
  String get usernameHint => '@tennguoidung';

  @override
  String get enableBiometricTitle => 'Dùng Face ID để đăng nhập lần sau?';

  @override
  String get enableBiometricBody => 'Đăng nhập bằng sinh trắc học mà không cần nhập mật khẩu.';

  @override
  String get enableBiometricCta => 'Bật';

  @override
  String get biometricSignInPrompt => 'Xác thực để đăng nhập vào Bananatalk';

  @override
  String get biometricNotAvailable => 'Thiết bị này không hỗ trợ đăng nhập sinh trắc học. Vui lòng đăng nhập bằng mật khẩu.';

  @override
  String get biometricNotEnrolled => 'Thiết bị này chưa thiết lập Face ID hoặc vân tay. Hãy thêm trong Cài đặt hoặc đăng nhập bằng mật khẩu.';

  @override
  String get biometricLockedOut => 'Quá nhiều lần thử. Sinh trắc học tạm thời bị khóa. Hãy thử lại sau hoặc đăng nhập bằng mật khẩu.';

  @override
  String get biometricPermanentlyLockedOut => 'Sinh trắc học đã bị khóa. Mở khóa thiết bị bằng mật mã rồi thử lại.';

  @override
  String get biometricPasscodeNotSet => 'Hãy đặt mật mã cho thiết bị để dùng đăng nhập sinh trắc học.';

  @override
  String continueAs(String name) {
    return 'Tiếp tục với tên $name';
  }

  @override
  String get addProfilePhotoTitle => 'Thêm ảnh đại diện';

  @override
  String get addProfilePhotoSkip => 'Bỏ qua ngay';

  @override
  String get wavesTab => 'Chào hỏi';

  @override
  String get sendWave => 'Gửi lời chào';

  @override
  String sendWaveTo(String name) {
    return 'Gửi lời chào đến $name';
  }

  @override
  String waveSent(String name) {
    return 'Đã gửi lời chào đến $name';
  }

  @override
  String waveCooldown(String name, String time) {
    return 'Bạn có thể chào $name lại sau $time';
  }

  @override
  String get waveCouldntSend => 'Không thể gửi lời chào';

  @override
  String get itsAMatch => 'Kết đôi thành công!';

  @override
  String itsAMatchSubtitle(String name) {
    return 'Bạn và $name đã chào nhau';
  }

  @override
  String get sendAMessage => 'Gửi tin nhắn';

  @override
  String get waveQuickReplyHi => 'Xin chào!';

  @override
  String get waveQuickReplyCool => 'Bạn có vẻ thú vị';

  @override
  String get waveQuickReplyHey => 'Này';

  @override
  String get waveQuickReplyChat => 'Cùng trò chuyện nhé';

  @override
  String get waveQuickReplyHello => 'Chào bạn';

  @override
  String waveQuickReplyFromCountry(String country) {
    return 'Xin chào từ $country';
  }

  @override
  String get waveCustomMessage => 'Hoặc tự viết tin nhắn của bạn…';

  @override
  String get voiceRoomChat => 'Trò chuyện';

  @override
  String get voiceRoomChatPlaceholder => 'Gửi tin nhắn…';

  @override
  String get voiceRoomChatEmpty => 'Chưa có tin nhắn — hãy chào hỏi';

  @override
  String get voiceRoomChatSend => 'Gửi';

  @override
  String voiceRoomChatNewBadge(int n) {
    return '$n';
  }

  @override
  String get voiceRoomEnd => 'Kết thúc phòng';

  @override
  String get voiceRoomEndConfirm => 'Kết thúc phòng này?';

  @override
  String get voiceRoomEndConfirmBody => 'Tất cả mọi người sẽ bị ngắt kết nối.';

  @override
  String get voiceRoomKick => 'Xóa khỏi phòng';

  @override
  String voiceRoomKickConfirm(String name) {
    return 'Xóa $name?';
  }

  @override
  String get voiceRoomKicked => 'Đã xóa';

  @override
  String get voiceRoomYouAreHostNow => 'Bạn hiện là chủ phòng';

  @override
  String voiceRoomHostChanged(String name) {
    return '$name hiện là chủ phòng';
  }

  @override
  String get voiceRoomHostMenuTitle => 'Quản lý phòng';

  @override
  String get voiceRoomViewProfile => 'Xem hồ sơ';

  @override
  String get voiceRoomReconnecting => 'Đang kết nối lại…';

  @override
  String get voiceRoomReconnected => 'Đã kết nối lại';

  @override
  String get voiceRoomEnded => 'Phòng đã kết thúc';

  @override
  String get voiceRoomReconnectRetry => 'Thử lại';

  @override
  String get mutualInterests => 'Sở thích chung';

  @override
  String interestsInCommon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sở thích chung',
      one: '1 sở thích chung',
      zero: 'Chưa có sở thích chung',
    );
    return '$_temp0';
  }

  @override
  String get interestsInCommonSeeAll => 'Xem tất cả';

  @override
  String get interestsInCommonAddCta => 'Thêm chủ đề';

  @override
  String get interestsInCommonAddSubtitle => 'Thêm chủ đề vào hồ sơ để tìm điểm chung';

  @override
  String activeAgo(String time) {
    return 'Hoạt động $time trước';
  }

  @override
  String get filterOnlineNow => 'Đang trực tuyến';

  @override
  String get filterAge => 'Tuổi';

  @override
  String get filterGender => 'Giới tính';

  @override
  String get filterLanguages => 'Ngôn ngữ';

  @override
  String get filterCountry => 'Quốc gia';

  @override
  String get filterTopics => 'Chủ đề';

  @override
  String get filterLevel => 'Trình độ ngôn ngữ';

  @override
  String get filterToggles => 'Khác';

  @override
  String filterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count đối tác phù hợp',
      one: '1 đối tác phù hợp',
      zero: 'Không có đối tác phù hợp',
    );
    return '$_temp0';
  }

  @override
  String get filterClearAll => 'Xóa tất cả';

  @override
  String get filterReset => 'Đặt lại';

  @override
  String get filterApply => 'Áp dụng';

  @override
  String get filterNewUsers => 'Chỉ người dùng mới';

  @override
  String get filterPrioritizeNearby => 'Ưu tiên gần đây';

  @override
  String get filterSheetTitle => 'Bộ lọc';

  @override
  String get notificationPreferencesTitle => 'Thông báo';

  @override
  String get notificationPreferencesSubtitle => 'Chọn những cảnh báo bạn muốn nhận';

  @override
  String get notifPrefChat => 'Tin nhắn mới';

  @override
  String get notifPrefWave => 'Vẫy tay';

  @override
  String get notifPrefVoiceRoomStart => 'Lời mời phòng thoại';

  @override
  String get notifPrefScheduledRoomReminder => 'Nhắc nhở phòng đã lên lịch';

  @override
  String get notifPrefFollowerMoment => 'Khoảnh khắc mới từ người bạn theo dõi';

  @override
  String get notifPrefVisitorAlert => 'Khách thăm hồ sơ';

  @override
  String get notifPrefMatchAlert => 'Vẫy tay qua lại';

  @override
  String get notifResetToDefaults => 'Đặt lại về mặc định';

  @override
  String get themeMode => 'Giao diện';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get themeSystem => 'Hệ thống';

  @override
  String get languageSettingsRow => 'Ngôn ngữ';

  @override
  String get waveDailySummaryTitle => 'Có vẫy tay mới đang chờ';

  @override
  String waveDailySummaryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count người đã vẫy tay với bạn',
      one: '1 người đã vẫy tay với bạn',
    );
    return '$_temp0';
  }

  @override
  String get filterTopicsTitle => 'Chủ đề';

  @override
  String get filterTopicsEmpty => 'Chưa chọn chủ đề nào';

  @override
  String get storiesEmpty => 'Chưa có tin nào';

  @override
  String get storiesLoadError => 'Không thể tải tin';

  @override
  String get storiesRetry => 'Thử lại';

  @override
  String get storiesNoMore => 'Bạn đã xem hết rồi';

  @override
  String get createTextStoryTab => 'Văn bản';

  @override
  String get createImageStoryTab => 'Ảnh';

  @override
  String get createVideoStoryTab => 'Video';

  @override
  String get enterTextHint => 'Nhấn để nhập';

  @override
  String get pickBackground => 'Nền';

  @override
  String get pickFontStyle => 'Phông chữ';

  @override
  String get pickTextColor => 'Màu sắc';

  @override
  String get addEmoji => 'Thêm biểu tượng cảm xúc';

  @override
  String get chooseFont => 'Chọn phông chữ';

  @override
  String get chooseColor => 'Chọn màu sắc';

  @override
  String get dragToMove => 'Kéo để di chuyển';

  @override
  String get pinchToScale => 'Chụm để thu phóng';

  @override
  String get removeFromHighlight => 'Xóa khỏi nổi bật';

  @override
  String get highlightDeleted => 'Đã xóa nổi bật';

  @override
  String get storySaved => 'Đã lưu vào tin của bạn';

  @override
  String get storyTooLong => 'Văn bản quá dài';

  @override
  String get storyPostFailed => 'Không thể đăng tin';

  @override
  String get fontNormal => 'Thường';

  @override
  String get fontBold => 'Đậm';

  @override
  String get fontItalic => 'Nghiêng';

  @override
  String get fontHandwriting => 'Chữ viết tay';

  @override
  String get pickDate => 'Chọn ngày';

  @override
  String get pickTime => 'Chọn giờ';

  @override
  String get upcomingRooms => 'Sắp diễn ra';

  @override
  String inHours(int h, int m) {
    return 'sau ${h}g ${m}ph';
  }

  @override
  String inMinutes(int m) {
    return 'sau ${m}ph';
  }

  @override
  String get startsNow => 'Đang bắt đầu';

  @override
  String get iWillBeThere => 'Tôi sẽ tham gia';

  @override
  String get cantMakeIt => 'Tôi không thể tham gia';

  @override
  String rsvpCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count xác nhận',
      one: '1 xác nhận',
      zero: 'Chưa có xác nhận',
    );
    return '$_temp0';
  }

  @override
  String roomStartsIn1h(String title) {
    return '$title bắt đầu sau 1 giờ';
  }

  @override
  String roomStartsIn15min(String title) {
    return '$title bắt đầu sau 15 phút';
  }

  @override
  String roomStarted(String title) {
    return '$title đang bắt đầu ngay bây giờ';
  }

  @override
  String get cancelRoom => 'Huỷ phòng';

  @override
  String get muteAll => 'Tắt tiếng tất cả';

  @override
  String get mutedByHost => 'Chủ phòng đã tắt tiếng mọi người';

  @override
  String get muteAllConfirm => 'Tắt tiếng tất cả trong phòng?';

  @override
  String get categoryCasual => 'Thông thường';

  @override
  String get categoryLanguagePractice => 'Luyện ngôn ngữ';

  @override
  String get categoryTopic => 'Chủ đề';

  @override
  String get categoryQA => 'Hỏi đáp';

  @override
  String get pickCategory => 'Danh mục';

  @override
  String get sortRecentlyActive => 'Hoạt động gần đây';

  @override
  String visitedYourProfile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count người đã xem hồ sơ của bạn',
      one: '1 người đã xem hồ sơ của bạn',
    );
    return '$_temp0';
  }

  @override
  String get noRecentVisitors => 'Không có người xem gần đây';

  @override
  String get viewArchive => 'Xem kho lưu trữ';

  @override
  String get archivedWaves => 'Wave đã lưu trữ';

  @override
  String get noArchivedWaves => 'Không có Wave đã lưu trữ';

  @override
  String get mutualInterestsMin => 'Sở thích chung (tối thiểu)';

  @override
  String atLeastNTopics(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ít nhất $n chủ đề chung',
      one: 'Ít nhất 1 chủ đề chung',
      zero: 'Bất kỳ',
    );
    return '$_temp0';
  }

  @override
  String get starterAskMoment => 'Hỏi về khoảnh khắc gần nhất của họ';

  @override
  String get starterSayHi => 'Chào hỏi bằng ngôn ngữ của họ';

  @override
  String get starterCurious => 'Họ đang tò mò về điều gì?';

  @override
  String starterFromCountry(String country) {
    return 'Xin chào từ $country!';
  }

  @override
  String starterPracticeLang(String language) {
    return 'Giúp họ luyện tập $language!';
  }

  @override
  String get momentsLoadError => 'Không thể tải các khoảnh khắc';

  @override
  String get momentsRetry => 'Thử lại';

  @override
  String get recentTags => 'Thẻ gần đây';

  @override
  String get noRecentTags => 'Chưa có thẻ gần đây';

  @override
  String get hideMomentsFromUser => 'Ẩn khoảnh khắc của người dùng này';

  @override
  String get momentsHidden => 'Khoảnh khắc của người dùng này sẽ được ẩn';

  @override
  String get unhideMoments => 'Hiển thị khoảnh khắc của người dùng này';

  @override
  String momentsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã ẩn $count người dùng',
      one: 'Đã ẩn 1 người dùng',
      zero: 'Không có người dùng nào bị ẩn',
    );
    return '$_temp0';
  }

  @override
  String get momentSaveFailed => 'Không thể lưu khoảnh khắc';

  @override
  String get tagAlreadyAdded => 'Đã thêm thẻ này';

  @override
  String get tagLimitReached => 'Đã đạt số lượng thẻ tối đa';

  @override
  String get hideThisUser => 'Ẩn bài đăng của người dùng này';

  @override
  String get transcribeMessage => 'Phiên âm';

  @override
  String get transcribing => 'Đang phiên âm…';

  @override
  String get transcriptionFailed => 'Không thể phiên âm tin nhắn';

  @override
  String saveToVocabulary(String word) {
    return 'Lưu \'$word\' vào từ vựng';
  }

  @override
  String get addedToVocabulary => 'Đã thêm vào từ vựng của bạn';

  @override
  String get alreadyInVocabulary => 'Đã có trong từ vựng của bạn';

  @override
  String get tapWordToSave => 'Nhấn và giữ một từ để lưu';

  @override
  String get autoTranslateChatHint => 'Tin nhắn đến sẽ được dịch tự động';

  @override
  String get noConversationsYet => 'Chưa có cuộc trò chuyện';

  @override
  String get chatRetry => 'Thử lại';

  @override
  String get learningHubTitle => 'Học tập';

  @override
  String get learningCommonRetry => 'Thử lại';

  @override
  String get learningCommonContinue => 'Tiếp tục';

  @override
  String get learningCommonAwesome => 'Tuyệt vời!';

  @override
  String get learningErrorGeneric => 'Đã xảy ra lỗi';

  @override
  String get learningStreakCurrent => 'Chuỗi hiện tại';

  @override
  String get learningStreakLongest => 'Chuỗi dài nhất';

  @override
  String learningStreakDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
    );
    return '$_temp0';
  }

  @override
  String learningStreakFreezeAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count freeze khả dụng',
      zero: 'Không có freeze',
    );
    return '$_temp0';
  }

  @override
  String get learningStreakFreezeUse => 'Dùng đóng băng';

  @override
  String get learningStreakFreezeDescription => 'Freeze bảo vệ chuỗi của bạn khi bỏ lỡ một ngày.';

  @override
  String get learningStreakFreezeProtected => 'Chuỗi được bảo vệ!';

  @override
  String get learningStreakMilestone7 => 'Chuỗi 7 ngày!';

  @override
  String get learningStreakMilestone30 => 'Chuỗi 30 ngày!';

  @override
  String get learningStreakMilestone100 => 'Chuỗi 100 ngày!';

  @override
  String get learningStreakMilestone365 => 'Chuỗi 365 ngày!';

  @override
  String get learningWeeklyDigestTitle => 'Tuần này';

  @override
  String learningWeeklyDigestXp(int xp) {
    return 'Đã nhận $xp XP';
  }

  @override
  String learningWeeklyDigestLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài học',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestVocab(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'đã học $count từ',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestDaysActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày hoạt động',
    );
    return '$_temp0';
  }

  @override
  String get learningWeeklyDigestTopAchievement => 'Thành tích hàng đầu';

  @override
  String learningWeeklyDigestTrendUp(int pct) {
    return 'Tăng $pct% so với tuần trước';
  }

  @override
  String learningWeeklyDigestTrendDown(int pct) {
    return 'Giảm $pct% so với tuần trước';
  }

  @override
  String get learningWeeklyDigestTrendFlat => 'Bằng tuần trước';

  @override
  String get learningSrsDashboardTitle => 'Ôn tập hàng ngày';

  @override
  String learningSrsDueToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hôm nay $count thẻ',
      zero: 'Không có thẻ hôm nay',
    );
    return '$_temp0';
  }

  @override
  String learningSrsDueTomorrow(int count) {
    return '$count ngày mai';
  }

  @override
  String learningSrsDueThisWeek(int count) {
    return '$count tuần này';
  }

  @override
  String get learningSrsStartReview => 'Bắt đầu ôn tập';

  @override
  String get learningSrsAllCaughtUp => 'Bạn đã hoàn thành tất cả!';

  @override
  String get learningSrsKeepGoing => 'Tiếp tục nào';

  @override
  String get learningLeaderboardXpTab => 'XP';

  @override
  String get learningLeaderboardStreakTab => 'Chuỗi';

  @override
  String get learningLeaderboardLanguageTab => 'Ngôn ngữ';

  @override
  String get learningLeaderboardFriendsTab => 'Bạn bè';

  @override
  String get learningLeaderboardEmpty => 'Chưa có bảng xếp hạng';

  @override
  String get learningLeaderboardYouLabel => 'Bạn';

  @override
  String get learningLeaderboardFriendBadge => 'Bạn bè';

  @override
  String get learningEmptyVocab => 'Thêm các từ bạn muốn ghi nhớ';

  @override
  String get learningEmptyLessons => 'Chưa có bài học nào';

  @override
  String get learningEmptyQuizzes => 'Không có câu hỏi kiểm tra';

  @override
  String get learningEmptyChallenges => 'Quay lại vào ngày mai';

  @override
  String get learningEmptyAchievements => 'Hãy đạt được thành tích đầu tiên';

  @override
  String get learningEmptySearchResults => 'Không tìm thấy kết quả';

  @override
  String learningXpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String get learningLevelUp => 'Lên cấp!';

  @override
  String learningLevelReached(String level) {
    return 'Bạn đã đạt $level';
  }

  @override
  String get learningAchievementUnlocked => 'Mở khóa thành tựu';

  @override
  String get learningVocabularySearchHint => 'Tìm kiếm từ vựng';

  @override
  String get learningVocabularyFilterAll => 'Tất cả';

  @override
  String get learningVocabularyFilterNew => 'Mới';

  @override
  String get learningVocabularyFilterLearning => 'Đang học';

  @override
  String get learningVocabularyFilterMastered => 'Đã thành thạo';

  @override
  String get learningVocabularySortRecent => 'Gần đây';

  @override
  String get learningVocabularySortAlphabetical => 'Theo bảng chữ cái';

  @override
  String get learningVocabularySortMastery => 'Độ thành thạo';

  @override
  String get learningVocabularyMasteryNew => 'Mới';

  @override
  String get learningVocabularyMasteryLearning => 'Đang học';

  @override
  String get learningVocabularyMasteryMastered => 'Đã thành thạo';

  @override
  String get learningProgressLevelLabel => 'Cấp độ';

  @override
  String learningProgressXpToNextLevel(int xp) {
    return '$xp XP đến cấp tiếp theo';
  }

  @override
  String get learningProgressWeeklyChartTitle => '7 ngày qua';

  @override
  String get aiTutorPronounceLoading => 'Đang chọn câu cho bạn…';

  @override
  String get aiTutorPronounceTapToRecord => 'Chạm để ghi âm';

  @override
  String get aiTutorPronounceTapToStop => 'Chạm để dừng';

  @override
  String get aiTutorPronounceTranscribing => 'Đang nghe bạn…';

  @override
  String get aiTutorPronounceTryAgain => 'Thử lại';

  @override
  String get aiTutorPronounceNext => 'Tiếp';

  @override
  String get aiTutorPronounceUseYourOwn => 'Câu của tôi ✏️';

  @override
  String get aiTutorPronounceCustomHint => 'Nhập câu bạn muốn luyện';

  @override
  String get aiTutorPronounceCustomCancel => 'Huỷ';

  @override
  String get aiTutorPronounceCustomUse => 'Dùng';

  @override
  String get aiTutorPronounceQuitConfirm => 'Thoát bài tập? Tiến trình sẽ không được lưu.';

  @override
  String get aiTutorPronounceQuitYes => 'Có';

  @override
  String get aiTutorPronounceQuitNo => 'Không';

  @override
  String aiTutorPronounceSentenceOf(int current, int total) {
    return 'Câu $current / $total';
  }

  @override
  String get aiTutorPronounceSummaryTitle => 'Đã hoàn thành';

  @override
  String get aiTutorPronounceSummaryAvg => 'Điểm trung bình';

  @override
  String get aiTutorPronounceSummaryWeak => 'Từ cần luyện';

  @override
  String get aiTutorPronounceSaveClose => 'Lưu & đóng';

  @override
  String get aiTutorPronounceSaving => 'Đang lưu…';

  @override
  String get aiTutorChipPronounce => 'Phát âm';

  @override
  String aiTutorPlanPronunciation(int count, int completed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bài luyện phát âm ($completed/$count)',
      one: 'Bài luyện phát âm ($completed/1)',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorPronounceStartHeadline => 'Bạn muốn luyện thế nào?';

  @override
  String get aiTutorPronounceStartSubhead => 'Chọn một để bắt đầu bài 5 câu.';

  @override
  String get aiTutorPronounceStartAITitle => 'AI tạo câu';

  @override
  String get aiTutorPronounceStartAISubtitle => 'Theo cấp độ, tập trung vào các từ khó của bạn';

  @override
  String get aiTutorPronounceStartCustomTitle => 'Dùng câu của riêng tôi';

  @override
  String get aiTutorPronounceStartCustomSubtitle => 'Nhập hoặc dán câu bạn muốn thành thạo';

  @override
  String aiTutorQuotaRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hôm nay còn $count',
      one: 'Hôm nay còn 1',
    );
    return '$_temp0';
  }

  @override
  String get submit => 'Gửi';

  @override
  String get exit => 'Thoát';

  @override
  String get previous => 'Trước';

  @override
  String get aiDailyPracticeTitle => 'Luyện tập hằng ngày';

  @override
  String get aiDailyPracticeTranslateThis => 'Dịch câu này:';

  @override
  String get aiDailyPracticeSuggested => 'Gợi ý:';

  @override
  String get aiDailyPracticeHint => 'Bản dịch của bạn';

  @override
  String get aiLanguagesLoading => 'Đang tải các ngôn ngữ...';

  @override
  String get aiCopiedToClipboard => 'Đã sao chép vào bộ nhớ tạm';

  @override
  String get aiGrammarHint => 'Nhập văn bản để phân tích...';

  @override
  String get aiGrammarSectionOriginal => 'Văn bản gốc';

  @override
  String get aiGrammarSectionCorrected => 'Văn bản đã sửa';

  @override
  String aiGrammarSectionIssues(int count) {
    return 'Vấn đề tìm thấy ($count)';
  }

  @override
  String get aiGrammarSectionWell => 'Điều bạn làm tốt';

  @override
  String get aiGrammarSectionSuggestions => 'Gợi ý';

  @override
  String get aiGrammarSectionSummary => 'Tóm tắt';

  @override
  String get aiLessonBuilderLabelLanguage => 'Ngôn ngữ';

  @override
  String get aiLessonBuilderLabelLevel => 'Cấp độ';

  @override
  String get aiLessonBuilderTopicHint => 'Nhập chủ đề (ví dụ: \"Đồ ăn và nhà hàng\")';

  @override
  String aiLessonBuilderSaved(String title) {
    return 'Đã lưu bài học \"$title\"!';
  }

  @override
  String get aiLessonBuilderBackToLessons => 'Quay lại bài học';

  @override
  String get aiTranslationHint => 'Nhập văn bản để dịch...';

  @override
  String get aiTranslationSavedToVocab => 'Đã lưu vào danh sách từ vựng';

  @override
  String aiTranslationCouldNotSave(String error) {
    return 'Không lưu được: $error';
  }

  @override
  String get aiQuizTitle => 'Câu đố';

  @override
  String get aiQuizFailedToGenerate => 'Không tạo được câu đố';

  @override
  String get aiQuizSubmitTitle => 'Nộp bài?';

  @override
  String get aiQuizSubmitBody => 'Bạn có chắc muốn nộp đáp án?';

  @override
  String get aiQuizExitTitle => 'Thoát khỏi câu đố?';

  @override
  String get aiQuizExitBody => 'Tiến trình sẽ bị mất.';

  @override
  String get aiQuizAnswerHint => 'Nhập câu trả lời...';

  @override
  String get aiQuizTranslationHint => 'Nhập bản dịch...';

  @override
  String get aiPronunciationPlayingAudio => 'Đang phát âm thanh...';

  @override
  String get aiPronunciationListenFirst => 'Nghe trước';

  @override
  String get aiPronunciationHint => 'Nhập văn bản để luyện tập...';

  @override
  String aiTutorCouldNotLoad(String error) {
    return 'Không tải được gia sư: $error';
  }

  @override
  String aiTutorPlanUnavailable(String error) {
    return 'Kế hoạch không khả dụng: $error';
  }

  @override
  String get aiTutorReplay => 'Phát lại';

  @override
  String get aiScenariosTitle => 'Kịch bản luyện tập';

  @override
  String aiScenariosCouldNotLoad(String error) {
    return 'Không tải được kịch bản: $error';
  }

  @override
  String get aiScenariosNoneAvailable => 'Chưa có kịch bản nào.';

  @override
  String aiScenariosCouldNotStart(String error) {
    return 'Không bắt đầu được: $error';
  }

  @override
  String aiScenariosForYourLevel(String level) {
    return 'Cho cấp độ của bạn ($level)';
  }

  @override
  String get aiScenariosEasier => 'Dễ hơn — khởi động';

  @override
  String get aiScenariosHarder => 'Khó hơn — thử thách';

  @override
  String get aiRoleplayStillStarting => 'Kịch bản vẫn đang khởi động — thử lại trong giây lát.';

  @override
  String aiRoleplaySendFailed(String error) {
    return 'Gửi thất bại: $error';
  }

  @override
  String get aiRoleplayCouldNotGrade => 'Không chấm điểm được lần này — thử lại lần sau.';

  @override
  String get aiConversationHistoryCompleted => 'Hoàn tất';

  @override
  String get aiConversationHistoryInProgress => 'Đang tiến hành';

  @override
  String get aiConversationMessageHint => 'Nhập tin nhắn...';

  @override
  String get aiConversationTopicSpeak => 'Tôi nói';

  @override
  String get aiConversationTopicPractice => 'Luyện tập';

  @override
  String aiToolsVipUpgradeDescription(String feature) {
    return 'Nâng cấp VIP để mở khóa $feature!';
  }

  @override
  String get aiToolsVipBadge => 'VIP';

  @override
  String aiScenariosBannerPracticingIn(String language) {
    return 'Luyện tập bằng $language';
  }

  @override
  String get aiScenariosBannerSubhead => 'Chọn kịch bản theo trình độ của bạn, hoặc thử cao hơn một mức.';

  @override
  String get chatListSearchHint => 'Tìm hoặc nhập @tên_dùng';

  @override
  String get chatListFilterAll => 'Tất cả';

  @override
  String get chatListFilterUnread => 'Chưa đọc';

  @override
  String get chatListFilterOnline => 'Trực tuyến';

  @override
  String get chatListNewChat => 'Chat mới';

  @override
  String get chatListNewChatByUsernameTooltip => 'Chat mới qua tên người dùng';

  @override
  String get chatListFindUser => 'Tìm người dùng';

  @override
  String chatListFindUserSearchTerm(String term) {
    return 'Tìm @$term';
  }

  @override
  String get chatListDeleteConversation => 'Xoá cuộc trò chuyện';

  @override
  String chatListMediaTitle(String name) {
    return 'Phương tiện với $name';
  }

  @override
  String get chatListMediaError => 'Lỗi tải phương tiện';

  @override
  String get chatDetailViewFullProfile => 'Xem hồ sơ đầy đủ';

  @override
  String get chatMessageReply => 'Trả lời';

  @override
  String get chatMessageCopy => 'Sao chép';

  @override
  String get chatMessageCorrect => 'Sửa';

  @override
  String get chatMessageTranslate => 'Dịch';

  @override
  String get chatMessageSavePhrase => 'Lưu cụm';

  @override
  String get chatMessageEdit => 'Chỉnh sửa';

  @override
  String get chatMessageDelete => 'Xoá';

  @override
  String get chatMessageRetrySubtitle => 'Thử gửi lại tin nhắn này';

  @override
  String get chatMessageRemoveSubtitle => 'Gỡ tin nhắn này';

  @override
  String get chatWallpaperPreviewHello => 'Xin chào! 👋';

  @override
  String get chatWallpaperPreviewHow => 'Bạn khoẻ không?';

  @override
  String get chatGifSearchHint => 'Tìm GIF...';

  @override
  String get communitySearchHint => 'Tìm hoặc nhập @tên_dùng';

  @override
  String communityUserNotFound(String name) {
    return 'Không tìm thấy @$name';
  }

  @override
  String get communityTabAll => 'Tất cả';

  @override
  String get communityTabGender => 'Giới tính';

  @override
  String get communityTabCity => 'Thành phố';

  @override
  String get communityRefresh => 'Làm mới';

  @override
  String get communityNoUsersFound => 'Không tìm thấy người dùng';

  @override
  String communityUnblockConfirm(String name) {
    return 'Bạn chắc muốn bỏ chặn $name?';
  }

  @override
  String get communityUsernameCopied => 'Đã sao chép tên người dùng!';

  @override
  String communityLocationDetected(String country) {
    return 'Vị trí: $country';
  }

  @override
  String get communityWaveLater => 'Sau';

  @override
  String get communityAboutMBTI => 'MBTI';

  @override
  String get voiceRoomReactTooltip => 'Phản ứng';

  @override
  String get momentsCancel => 'Huỷ';

  @override
  String get momentsNotNow => 'Không phải bây giờ';

  @override
  String get commonOK => 'OK';

  @override
  String commonError(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get chatActiveJustNow => 'Hoạt động vừa xong';

  @override
  String chatActiveMinAgo(int min) {
    return 'Hoạt động $min phút trước';
  }

  @override
  String get chatActiveHourAgo => 'Hoạt động 1 giờ trước';

  @override
  String chatActiveHoursAgo(int hours) {
    return 'Hoạt động $hours giờ trước';
  }

  @override
  String get chatActiveYesterday => 'Hoạt động hôm qua';

  @override
  String chatActiveDaysAgo(int days) {
    return 'Hoạt động $days ngày trước';
  }

  @override
  String get chatSayHiPrompt => 'Chào và bắt đầu trò chuyện!';

  @override
  String get communityConversationStartersTitle => 'Gợi mở câu chuyện';

  @override
  String communityConversationStartersTopic(String topic) {
    return 'Cả hai đều thích $topic — hỏi sở thích của họ!';
  }

  @override
  String get communityConversationStartersDefault => 'Chào và giới thiệu bản thân!';

  @override
  String get communityConversationChatAction => 'Chat';

  @override
  String get communityConversationMessageCopied => 'Đã sao chép tin nhắn! Dán để gửi.';

  @override
  String get communityConversationCopiedToast => 'Đã sao chép!';

  @override
  String get communityLanguageMatchTitle => 'Tương hợp ngôn ngữ';

  @override
  String get communityLanguageMatchNative => 'Bản ngữ';

  @override
  String get communityLanguageMatchLearning => 'Đang học';

  @override
  String get communityLanguageMatchPerfect => 'Trao đổi ngôn ngữ hoàn hảo!';

  @override
  String get communityLanguageMatchSameNative => 'Bạn cùng tiếng mẹ đẻ';

  @override
  String get momentsFilterApply => 'Áp dụng';

  @override
  String get momentsCreateAddTo => 'Thêm vào khoảnh khắc';

  @override
  String get momentsCreateCategory => 'Danh mục';

  @override
  String get momentsCreateLanguage => 'Ngôn ngữ';

  @override
  String get momentsCreateSchedule => 'Lên lịch (tuỳ chọn)';

  @override
  String get momentsCreateScheduleForLater => 'Lên lịch sau';

  @override
  String get momentsPrivacyPublic => 'Công khai';

  @override
  String get momentsPrivacyFriends => 'Bạn bè';

  @override
  String get momentsPrivacyPrivate => 'Riêng tư';

  @override
  String get splashTagline => 'Học · Trò chuyện · Gặp gỡ';

  @override
  String get splashLoading => 'Đang tải…';

  @override
  String get supportSheetGreeting => 'Xin chào, tôi là Firdavs 👋';

  @override
  String get supportSheetStory => 'Tôi đã xây dựng Bananatalk hoàn toàn một mình — từng màn hình, từng tính năng, từng lần sửa lỗi lúc nửa đêm. Mục tiêu của tôi là giúp người học ngôn ngữ trên toàn thế giới kết nối và phát triển, và tôi liên tục thêm các tính năng mới.\n\nNếu Bananatalk đã giúp bạn theo bất kỳ cách nào, dù chỉ một ly cà phê nhỏ cũng giúp tôi duy trì động lực để tiếp tục xây dựng. Mỗi đóng góp đều rất có ý nghĩa với một nhà phát triển đơn độc. 🙏';

  @override
  String get supportSheetDonateButton => 'Quyên góp qua PayPal';

  @override
  String get supportSheetWatchAd => 'Xem quảng cáo để ủng hộ';

  @override
  String get occupation => 'Nghề nghiệp';

  @override
  String get school => 'Trường học';

  @override
  String get occupationSearchHint => 'Tìm kiếm nghề nghiệp';

  @override
  String get occupationSelectedLabel => 'Đã chọn';

  @override
  String get occupationCustomLabel => 'Tùy chỉnh';

  @override
  String get occupationNoMatches => 'Không có kết quả trong danh sách';

  @override
  String get occupationCatTech => 'Công nghệ và phần mềm';

  @override
  String get occupationCatHealthcare => 'Y tế và sức khỏe';

  @override
  String get occupationCatEducation => 'Giáo dục và học thuật';

  @override
  String get occupationCatBusiness => 'Kinh doanh và tài chính';

  @override
  String get occupationCatCreative => 'Sáng tạo và thiết kế';

  @override
  String get occupationCatMedia => 'Truyền thông';

  @override
  String get occupationCatEngineering => 'Kỹ thuật';

  @override
  String get occupationCatScience => 'Khoa học và nghiên cứu';

  @override
  String get occupationCatLegal => 'Pháp lý';

  @override
  String get occupationCatHospitality => 'Khách sạn và ẩm thực';

  @override
  String get occupationCatTrades => 'Nghề thủ công';

  @override
  String get occupationCatTransport => 'Vận tải và logistics';

  @override
  String get occupationCatGovernment => 'Chính phủ và dịch vụ công';

  @override
  String get occupationCatRetail => 'Bán lẻ và chăm sóc khách hàng';

  @override
  String get occupationCatAgriculture => 'Nông nghiệp và môi trường';

  @override
  String get occupationCatSports => 'Thể thao và thể hình';

  @override
  String get occupationCatBeauty => 'Làm đẹp và chăm sóc cá nhân';

  @override
  String get occupationCatRealEstate => 'Bất động sản và xây dựng';

  @override
  String get occupationCatReligion => 'Tôn giáo và tâm linh';

  @override
  String get occupationCatStudent => 'Học sinh / Sinh viên';

  @override
  String get occupationCatOther => 'Khác';

  @override
  String get schoolHint => 'ví dụ: Đại học Quốc gia Hà Nội, THPT Chuyên';

  @override
  String get birthdate => 'Ngày sinh';

  @override
  String get birthdateSelectHelp => 'Chọn ngày sinh của bạn';

  @override
  String get birthdateSelectPlaceholder => 'Chọn ngày';

  @override
  String birthdateMinAgeError(int age) {
    return 'Bạn phải ít nhất $age tuổi.';
  }

  @override
  String birthdateQuotaRemaining(int remaining, int max) {
    return 'Bạn còn $remaining/$max lần thay đổi ngày sinh trong 60 ngày tới.';
  }

  @override
  String birthdateQuotaLocked(int max) {
    return 'Bạn đã dùng hết $max lần thay đổi ngày sinh trong chu kỳ 60 ngày này.';
  }

  @override
  String birthdateNextChangeOn(String date) {
    return 'Lần thay đổi tiếp theo khả dụng vào $date.';
  }

  @override
  String get birthdateRateLimited => 'Ngày sinh chỉ có thể thay đổi tối đa 3 lần trong 60 ngày.';

  @override
  String birthdateRateLimitedUntil(String date) {
    return 'Ngày sinh chỉ có thể thay đổi tối đa 3 lần trong 60 ngày. Hãy thử lại vào $date.';
  }

  @override
  String get changePassword => 'Đổi mật khẩu';

  @override
  String get currentPassword => 'Mật khẩu hiện tại';

  @override
  String get newPasswordLabel => 'Mật khẩu mới';

  @override
  String get confirmNewPassword => 'Xác nhận mật khẩu mới';

  @override
  String get currentPasswordHint => 'Nhập mật khẩu hiện tại';

  @override
  String get newPasswordHint => 'Tối thiểu 8 ký tự, A-Z, a-z, 0-9';

  @override
  String get passwordsDontMatch => 'Mật khẩu không khớp.';

  @override
  String get newPasswordSameAsCurrent => 'Mật khẩu mới phải khác mật khẩu hiện tại.';

  @override
  String get passwordChangedSuccess => 'Đã đổi mật khẩu thành công';

  @override
  String get passwordRule8Chars => 'Tối thiểu 8 ký tự';

  @override
  String get passwordRuleLowercase => 'Một chữ thường';

  @override
  String get passwordRuleUppercase => 'Một chữ hoa';

  @override
  String get passwordRuleNumber => 'Một chữ số';

  @override
  String get settingsAccountSection => 'Tài khoản';

  @override
  String get changePasswordTileSubtitle => 'Cập nhật mật khẩu tài khoản';

  @override
  String get occupationCustomTab => 'Tùy chỉnh';

  @override
  String get occupationCustomTabHint => 'Không thấy nghề của bạn? Nhập vào đây.';

  @override
  String get occupationCustomInputHint => 'ví dụ: Nhà sinh vật biển, Diễn viên lồng tiếng';

  @override
  String get occupationCustomSaveCTA => 'Dùng làm nghề của tôi';

  @override
  String get vipSelectPlan => 'Chọn gói';

  @override
  String get vipBenefits => 'Quyền lợi';

  @override
  String get vipBestValue => 'TỐT NHẤT';

  @override
  String get vipPlanMonth => '1 tháng';

  @override
  String get vipPlanThreeMonths => '3 tháng';

  @override
  String get vipPlanTwelveMonths => '12 tháng';

  @override
  String get vipOneTime => 'Một lần';

  @override
  String get vipNonVip => 'Không VIP';

  @override
  String get vipBenefitDailyTranslations => 'Bản dịch hàng ngày';

  @override
  String get vipBenefitTranslationsLimit => '5 / ngày';

  @override
  String get vipBenefitUnlimited => 'Không giới hạn';

  @override
  String get vipBenefitAdvancedFilters => 'Bộ lọc nâng cao';

  @override
  String get vipBenefitAdFree => 'Không quảng cáo';

  @override
  String get vipBenefitVipBadge => 'Huy hiệu VIP trên hồ sơ';

  @override
  String get vipBenefitPrioritySupport => 'Hỗ trợ ưu tiên';

  @override
  String get vipBrandTitle => 'BananaTalk VIP';

  @override
  String get vipTagline => 'Tấm hộ chiếu đến kết nối toàn cầu — những cuộc trò chuyện chân thật, tình bạn lâu dài.';

  @override
  String get vipDisclosure => 'Tự động gia hạn trừ khi bạn huỷ trước 24 giờ kết thúc kỳ. Khoản thanh toán sẽ được tính vào tài khoản iTunes hoặc Google Play của bạn.';

  @override
  String get vipLoginRequired => 'Vui lòng đăng nhập để tiếp tục';

  @override
  String get chatListMenu => 'Menu';

  @override
  String get chatListNewMessageAlertsTitle => 'Thông báo tin nhắn mới';

  @override
  String get chatListNewMessageAlertsBody => 'Chạm để bật thông báo, đừng bỏ lỡ tin nhắn nào';

  @override
  String get chatListFilterMyTurn => 'Lượt mình';

  @override
  String get partnerTagActiveNow => 'Đang hoạt động';

  @override
  String get partnerTagVeryResponsive => 'Phản hồi rất tốt';

  @override
  String get partnerTagQuickToReply => 'Trả lời nhanh';

  @override
  String vipSavePercent(int pct) {
    return 'Tiết kiệm $pct%';
  }

  @override
  String vipPerMonth(String price) {
    return '$price / tháng';
  }

  @override
  String partnerTagBothLike(String topic) {
    return 'Cả hai cùng thích $topic';
  }

  @override
  String partnerTagSpeaks(String language) {
    return 'Nói $language';
  }

  @override
  String partnerTagLearning(String language) {
    return 'Đang học $language';
  }

  @override
  String partnerTagJoinedDaysAgo(int days) {
    return 'Tham gia $days ngày trước';
  }

  @override
  String get vipPaymentPlanSummary => 'Tóm tắt gói';

  @override
  String get vipPaymentSelectMethod => 'Chọn phương thức thanh toán';

  @override
  String get vipPaymentPurchaseAppStore => 'Mua qua App Store';

  @override
  String get vipPaymentPurchaseGooglePlay => 'Mua qua Google Play';

  @override
  String get vipPaymentSecureAppStore => 'Giao dịch của bạn sẽ được xử lý an toàn qua App Store.';

  @override
  String get vipPaymentSecureGooglePlay => 'Giao dịch của bạn sẽ được xử lý an toàn qua Google Play.';

  @override
  String get vipPaymentSubscriptionInfo => 'Thông tin đăng ký';

  @override
  String get vipPaymentInfoLabelTitle => 'Tiêu đề';

  @override
  String get vipPaymentInfoLabelLength => 'Thời hạn';

  @override
  String get vipPaymentInfoLabelPrice => 'Giá';

  @override
  String get vipPaymentDisclosure => 'Bằng việc hoàn tất giao dịch, bạn đồng ý với Điều khoản sử dụng và Chính sách bảo mật của chúng tôi. Gói đăng ký sẽ tự động gia hạn trừ khi bạn huỷ ít nhất 24 giờ trước khi kỳ hiện tại kết thúc.';

  @override
  String get vipSuccessTitle => 'Chào mừng đến với VIP!';

  @override
  String get vipSuccessBody => 'Gói VIP của bạn đã được kích hoạt. Tận hưởng mọi tính năng cao cấp!';

  @override
  String get vipPendingTitle => 'Sắp xong';

  @override
  String get vipPendingBody => 'Đăng ký của bạn đang được xử lý — vui lòng làm mới lại sau một phút.';

  @override
  String get vipErrorPaymentTitle => 'Lỗi thanh toán';

  @override
  String get vipErrorPurchaseTitle => 'Lỗi giao dịch';

  @override
  String get vipErrorVerifyTitle => 'Xác minh giao dịch thất bại';

  @override
  String get vipErrorPaymentFailed => 'Thanh toán thất bại';

  @override
  String get vipErrorBodyPrefix => 'Đã xảy ra lỗi khi xử lý thanh toán của bạn:';

  @override
  String get vipErrorPurchaseCanceled => 'Giao dịch đã bị huỷ hoặc thất bại. Vui lòng thử lại.';

  @override
  String get vipErrorVerifyServer => 'Không thể xác minh giao dịch trên máy chủ. Vui lòng liên hệ hỗ trợ.';

  @override
  String get vipPlanLengthOneMonth => '1 tháng';

  @override
  String get vipPlanLengthThreeMonths => '3 tháng';

  @override
  String get vipPlanLengthOneYear => '1 năm';

  @override
  String vipPaymentPayPrice(String price) {
    return 'Thanh toán $price';
  }

  @override
  String get vipExpired => 'VIP đã hết hạn';

  @override
  String get vipMember => 'Thành viên VIP';

  @override
  String get chatPhrasesMostUsed => 'Hay dùng';

  @override
  String get chatPhrasesTopics => 'Chủ đề';

  @override
  String get chatPhrasesAddPhrase => 'Thêm cụm từ';

  @override
  String get chatPhrasesChange => 'Đổi';

  @override
  String get chatPhrasesAddTitle => 'Thêm cụm từ';

  @override
  String get chatPhrasesAddHint => 'Nhập cụm từ bạn hay dùng';

  @override
  String get chatPhrasesEmptyMostUsed => 'Chưa có cụm từ nào. Nhấn + để thêm.';

  @override
  String get chatPhrasesDeleteTitle => 'Xoá cụm từ này?';

  @override
  String get filterVipPromoTitle => 'Tìm người phù hợp nhanh hơn';

  @override
  String get filterVipPromoSubtitle => 'Mở khoá khám phá ưu tiên, bộ lọc nâng cao và trò chuyện không quảng cáo cùng VIP.';

  @override
  String get filterVipPromoCta => 'Lên VIP';

  @override
  String get examStudy => 'Luyện thi';

  @override
  String get examStudyChooseLanguage => 'Chọn ngôn ngữ học';

  @override
  String get examStudyChooseLanguageSubtitle => 'Chọn ngôn ngữ bạn muốn luyện thi.';

  @override
  String get examStudyLoading => 'Loading…';

  @override
  String get examStudyEmptyLanguages => 'Chưa có ngôn ngữ học nào.';

  @override
  String get examStudyError => 'Không tải được — hãy thử lại.';

  @override
  String get examStudyRetry => 'Retry';

  @override
  String get examPickExam => 'Chọn kỳ thi';

  @override
  String get examPickExamSubtitle => 'Chọn kỳ thi bạn muốn chuẩn bị.';

  @override
  String get examPickEmpty => 'Chưa có kỳ thi nào cho ngôn ngữ này.';

  @override
  String get examDashboardSections => 'Sections';

  @override
  String get examDashboardEmptySections => 'Chưa có phần nào để luyện.';

  @override
  String get examDashboardContinue => 'Tiếp tục luyện tập';

  @override
  String get examDashboardStartStudyPlan => 'Bắt đầu kế hoạch học';

  @override
  String get examDashboardViewProgress => 'Xem tiến độ';

  @override
  String examMetaDuration(int minutes) {
    return '$minutes phút';
  }

  @override
  String examMetaMaxScore(String score) {
    return 'Tối đa $score';
  }

  @override
  String examMetaSections(int count) {
    return '$count phần';
  }

  @override
  String get examSectionNotStarted => 'Chưa bắt đầu';

  @override
  String examSectionProgress(int done, int total) {
    return 'Đã làm $done/$total';
  }

  @override
  String get examQuestionSubmit => 'Nộp câu trả lời';

  @override
  String get examQuestionNext => 'Câu tiếp theo';

  @override
  String get examQuestionCorrect => 'Correct!';

  @override
  String get examQuestionIncorrect => 'Sai';

  @override
  String get examQuestionExplanation => 'Giải thích';

  @override
  String get examQuestionNoQuestions => 'Phần này chưa có câu hỏi.';

  @override
  String get examQuestionEssayComingSoon => 'Chấm bài viết sắp ra mắt. Hãy thử phần đọc trước.';

  @override
  String get examQuestionUnsupported => 'Loại câu hỏi này chưa được hỗ trợ.';

  @override
  String get examPracticeFinishedTitle => 'Hoàn thành phần này';

  @override
  String get examPracticeFinishedBody => 'Làm tốt lắm — bạn đã xong mọi câu hỏi trong phần này.';

  @override
  String get examPracticeBackToDashboard => 'Về bảng điều khiển';

  @override
  String examPracticeProgress(int current, int total) {
    return '$current trên $total';
  }

  @override
  String get examEssayPrompt => 'Viết bài luận của bạn';

  @override
  String examEssayMinChars(int min) {
    return 'Bài luận phải có ít nhất $min ký tự';
  }

  @override
  String examEssayMaxChars(int max) {
    return 'Bài luận không được vượt quá $max ký tự';
  }

  @override
  String examEssayWordCount(int count) {
    return '$count từ';
  }

  @override
  String examEssayCharCount(int count) {
    return '$count ký tự';
  }

  @override
  String get examEssaySubmit => 'Nộp bài luận';

  @override
  String get examEssayEvaluating => 'Đang chấm bài luận của bạn…';

  @override
  String get examEssayEvaluatingHint => 'Thường mất 10–30 giây. Bạn có thể rời màn hình này — chúng tôi vẫn chấm ở nền.';

  @override
  String get examEssayResultTitle => 'Đánh giá';

  @override
  String get examEssayResultStrengths => 'Điểm mạnh';

  @override
  String get examEssayResultImprovements => 'Gợi ý';

  @override
  String get examEssayResultScore => 'Score';

  @override
  String get examEssayResultFailed => 'Không chấm được bài luận này.';

  @override
  String get examEssayResultRetry => 'Thử lại';

  @override
  String get examEssayResultDone => 'Done';

  @override
  String get examEssayPollTimeout => 'Vẫn đang chấm — quay lại sau một phút nhé.';

  @override
  String get examEssayPollRefresh => 'Kiểm tra lại';

  @override
  String examEssayQuotaUsed(int used, int limit) {
    return 'Lượt chấm bài hôm nay: $used/$limit';
  }

  @override
  String get examEssayQuotaExhausted => 'Bạn đã dùng hết lượt chấm miễn phí hôm nay. Nâng cấp VIP để không giới hạn.';

  @override
  String get examEssayQuotaUpgrade => 'Nâng cấp VIP';

  @override
  String get examEssayDraftRestored => 'Đã khôi phục bản nháp';

  @override
  String get examProgressTitle => 'Progress';

  @override
  String get examProgressOverall => 'Điểm tổng';

  @override
  String get examProgressNotStartedTitle => 'Chưa luyện tập';

  @override
  String get examProgressNotStartedBody => 'Trả lời vài câu ở bất kỳ phần nào để thấy tiến độ ở đây.';

  @override
  String get examProgressFocusAreas => 'Phần cần tập trung';

  @override
  String examProgressSectionAttempts(int done, int total) {
    return 'Đã thử $done trên $total';
  }

  @override
  String get examProgressNoFocusAreas => 'Bạn đang làm tốt ở mọi phần — cứ tiếp tục nhé!';

  @override
  String get examPlanSetupTitle => 'Bắt đầu kế hoạch học';

  @override
  String get examPlanTargetScore => 'Điểm mục tiêu';

  @override
  String get examPlanExamDate => 'Ngày thi';

  @override
  String get examPlanPickDate => 'Chọn ngày';

  @override
  String get examPlanGenerate => 'Tạo kế hoạch';

  @override
  String get examPlanGenerating => 'Đang tạo kế hoạch của bạn…';

  @override
  String get examPlanInvalidDate => 'Hãy chọn ngày thi trong tương lai.';

  @override
  String get examPlanInvalidScore => 'Hãy nhập điểm mục tiêu hợp lệ.';

  @override
  String get examPlanTitle => 'Kế hoạch học';

  @override
  String get examPlanEmptyTitle => 'Chưa có kế hoạch nào';

  @override
  String get examPlanEmptyBody => 'Tạo kế hoạch để nhận mục tiêu hằng tuần phù hợp với điểm yếu của bạn.';

  @override
  String get examPlanRegenerate => 'Tạo lại kế hoạch';

  @override
  String examPlanWeek(int n) {
    return 'Tuần $n';
  }

  @override
  String examPlanWeekEstimate(String hours) {
    return '${hours}h';
  }

  @override
  String examPlanTotalHours(int hours) {
    return 'tổng $hours giờ';
  }

  @override
  String get examPlanDailyHeading => 'Bài học hằng ngày được gợi ý';

  @override
  String examPlanLessonMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String get examTopicPickerTitle => 'Chọn chủ đề';

  @override
  String get examTopicPickerSubtitle => 'Luyện câu hỏi theo một chủ đề, hoặc vào tất cả câu hỏi.';

  @override
  String get examTopicAllTopics => 'Tất cả chủ đề';

  @override
  String get examTopicAllTopicsDescription => 'Trộn từ mọi chủ đề hiện có';

  @override
  String get examTopicEmpty => 'No topical content yet. Tap All topics to start practicing.';

  @override
  String examTopicQuestionCount(int count) {
    return '$count câu hỏi';
  }

  @override
  String get examTopicOneQuestion => '1 câu hỏi';

  @override
  String get examSpeakingPrompt => 'Nói câu trả lời của bạn';

  @override
  String get examSpeakingListenToPrompt => 'Listen to prompt';

  @override
  String get examSpeakingTapToRecord => 'Chạm để ghi âm câu trả lời';

  @override
  String get examSpeakingTranscriptHeading => 'Chúng tôi nghe được';

  @override
  String get examSpeakingPart1 => 'Speaking — Part 1';

  @override
  String get examSpeakingPart2 => 'Speaking — Part 2';

  @override
  String get examSpeakingPart3 => 'Speaking — Part 3';

  @override
  String get examSpeakingSubmit => 'Gửi bản ghi âm';

  @override
  String get examSpeakingUploading => 'Đang tải lên…';

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
      other: '$count bài',
      one: '1 bài',
    );
    return '$_temp0';
  }

  @override
  String examGroupSpeakingSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phần',
      one: '1 phần',
    );
    return '$_temp0';
  }

  @override
  String get examVocabLevelPickerTitle => 'Chọn cấp độ';

  @override
  String get examVocabLevelPickerSubtitle => 'Xem từ vựng và bài luyện theo cấp độ CEFR.';

  @override
  String get examVocabTopicPickerTitle => 'Chọn chủ đề';

  @override
  String get examVocabAllTopics => 'Tất cả chủ đề';

  @override
  String get examVocabBrowse => 'Browse';

  @override
  String get examVocabPractice => 'Practice';

  @override
  String get examVocabEmptyList => 'Chưa có từ nào cho cấp độ và chủ đề này.';

  @override
  String get examVocabQuizComplete => 'Hoàn thành bài kiểm tra';

  @override
  String examVocabQuizScore(int correct, int total) {
    return 'Bạn trả lời đúng $correct trên $total';
  }

  @override
  String get examVocabQuizYourAnswer => 'Câu trả lời của bạn';

  @override
  String get examVocabQuizCorrectAnswer => 'Đáp án đúng';

  @override
  String get examVocabQuizSubmit => 'Submit';

  @override
  String get examVocabQuizSubmitting => 'Đang gửi…';

  @override
  String get examVocabQuizNext => 'Next';

  @override
  String get examVocabQuizPrev => 'Back';

  @override
  String get examVocabQuizRestart => 'Restart';

  @override
  String get examVocabQuizEmpty => 'Không tạo được câu hỏi. Hãy thử chủ đề hoặc cấp độ khác.';

  @override
  String get examVocabQuizNotEnough => 'Không đủ từ ở cấp độ và chủ đề này để tạo bài kiểm tra.';

  @override
  String get examVocabQuizExpiredTitle => 'Bài kiểm tra đã hết hạn';

  @override
  String get examVocabQuizExpiredBody => 'Bài này để không quá lâu. Hãy bắt đầu lại để có bài mới.';

  @override
  String get examVocabTranslate => 'Dịch';

  @override
  String get examVocabTranslateFailed => 'Không dùng được bản dịch. Hãy thử lại sau.';

  @override
  String get examDashboardTips => 'Tips';

  @override
  String get examTipsTitle => 'Mẹo và kỹ thuật';

  @override
  String examTipsSubtitle(String examName) {
    return 'Ghi chú chiến lược chọn lọc cho $examName.';
  }

  @override
  String get examTipsEmpty => 'Chưa có mẹo nào cho kỳ thi này.';

  @override
  String get examTipsCategoryStrategy => 'Strategy';

  @override
  String get examTipsCategoryGrammar => 'Grammar';

  @override
  String get examTipsCategoryVocabulary => 'Từ vựng';

  @override
  String get examTipsCategoryTimeManagement => 'Quản lý thời gian';

  @override
  String get examTipsCategoryCommonMistakes => 'Lỗi thường gặp';

  @override
  String get examTipsCategoryBandBooster => 'Tăng điểm';

  @override
  String get examTipsCategoryCulturalNotes => 'Ghi chú văn hoá';

  @override
  String get examTipsCategoryPronunciation => 'Phát âm';

  @override
  String get examTipsCategoryFluency => 'Fluency';

  @override
  String get roomsNewRoom => 'Phòng mới';

  @override
  String get roomsCouldNotLoad => 'Không thể tải phòng';

  @override
  String get roomsEmptyTitle => 'Chưa có phòng ngôn ngữ nào';

  @override
  String get roomsEmptySubtitle => 'Hãy quay lại sau — các hub đang được thiết lập.';

  @override
  String get roomCreateTitle => 'Phòng Chủ đề Mới';

  @override
  String get roomCreateSubtitle => 'Bắt đầu một cuộc trò chuyện tập trung theo một ngôn ngữ';

  @override
  String get roomNameLabel => 'Tên phòng';

  @override
  String get roomNameHint => 'ví dụ: Luyện hội thoại hàng ngày';

  @override
  String get roomDescriptionLabel => 'Mô tả (không bắt buộc)';

  @override
  String get roomDescriptionHint => 'Phòng này nói về điều gì?';

  @override
  String get roomCreateSubmit => 'Tạo phòng';

  @override
  String get roomNameRequired => 'Vui lòng nhập tên phòng';

  @override
  String get roomCreateError => 'Không thể tạo phòng. Vui lòng thử lại.';

  @override
  String get roomUsEnglish => 'Tiếng Anh (Mỹ)';

  @override
  String get roomUkEnglish => 'Tiếng Anh (Anh)';

  @override
  String get roomFailedLoadMessages => 'Không thể tải tin nhắn';

  @override
  String get roomReportMessageTitle => 'Báo cáo tin nhắn';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Quấy rối hoặc Bắt nạt';

  @override
  String get reportReasonHateSpeech => 'Phát ngôn thù ghét';

  @override
  String get reportReasonViolence => 'Bạo lực hoặc Đe dọa';

  @override
  String get reportReasonNudity => 'Khỏa thân hoặc Nội dung khiêu dâm';

  @override
  String get reportReasonFalseInformation => 'Thông tin sai lệch';

  @override
  String get roomReportSubmitted => 'Đã gửi báo cáo';

  @override
  String get roomReportSubmitFailed => 'Gửi báo cáo không thành công';

  @override
  String get roomLeaveHubTitle => 'Rời khỏi hub?';

  @override
  String roomLeaveHubMessage(String title) {
    return 'Bạn có thể tham gia lại $title sau này từ danh mục Phòng.';
  }

  @override
  String get roomLeaveHubFailed => 'Rời khỏi hub không thành công';

  @override
  String get roomJoinRequestSent => 'Đã gửi yêu cầu — bạn sẽ được thông báo nếu được chấp thuận';

  @override
  String get roomJoinRequestFailed => 'Gửi yêu cầu không thành công';

  @override
  String roomRequestsMenuItem(int count) {
    return 'Yêu cầu ($count)';
  }

  @override
  String get roomViewMembers => 'Xem thành viên';

  @override
  String get roomLeaveHubMenuItem => 'Rời khỏi hub';

  @override
  String roomMemberOnlineCount(int members, int online) {
    return '$members thành viên · $online đang trực tuyến';
  }

  @override
  String get roomBannedRequestMessage => 'Bạn đã bị xóa khỏi phòng này. Gửi yêu cầu để tham gia lại — chủ phòng cần phê duyệt.';

  @override
  String get roomModeratedRequestMessage => 'Đây là phòng được kiểm duyệt. Gửi yêu cầu tham gia để bắt đầu trò chuyện.';

  @override
  String get roomRequestPending => 'Yêu cầu đang chờ xử lý';

  @override
  String get roomRequestToJoin => 'Yêu cầu tham gia';

  @override
  String get roomDailyPromptLabel => 'Chủ đề hôm nay';

  @override
  String get roomSomeoneFallback => 'Ai đó';

  @override
  String get roomRequestsLoadError => 'Không thể tải yêu cầu tham gia';

  @override
  String get roomRequestApproved => 'Yêu cầu đã được chấp thuận';

  @override
  String get roomRequestDenied => 'Yêu cầu đã bị từ chối';

  @override
  String get roomRequestApproveFailed => 'Chấp thuận yêu cầu không thành công';

  @override
  String get roomRequestDenyFailed => 'Từ chối yêu cầu không thành công';

  @override
  String roomRequestsAppBarTitle(String title) {
    return '$title · Yêu cầu';
  }

  @override
  String get roomRequestsEmpty => 'Không có yêu cầu đang chờ';

  @override
  String get roomRequestDeny => 'Từ chối';

  @override
  String get roomRequestApprove => 'Chấp thuận';

  @override
  String get roomMembersLoadError => 'Không thể tải thành viên';

  @override
  String get roomRemoveBanTitle => 'Xóa và cấm thành viên?';

  @override
  String get roomRemoveTitle => 'Xóa thành viên?';

  @override
  String roomRemoveBanConfirm(String name) {
    return 'Xóa và cấm $name? Họ sẽ không thể tham gia lại trừ khi bạn chấp thuận một yêu cầu.';
  }

  @override
  String roomRemoveConfirm(String name, String title) {
    return 'Xóa $name khỏi $title?';
  }

  @override
  String get roomRemoveBanButton => 'Xóa & cấm';

  @override
  String get roomRemoveButton => 'Xóa';

  @override
  String get roomMemberRemovedBanned => 'Đã xóa và cấm thành viên';

  @override
  String get roomMemberRemoved => 'Đã xóa thành viên';

  @override
  String get roomMemberRemoveFailed => 'Xóa thành viên không thành công';

  @override
  String get roomMemberMuted => 'Đã tắt tiếng thành viên';

  @override
  String get roomMemberUnmuted => 'Đã bật tiếng thành viên';

  @override
  String get roomMemberMuteFailed => 'Cập nhật trạng thái tắt tiếng không thành công';

  @override
  String roomMembersAppBarTitle(String title) {
    return '$title · Thành viên';
  }

  @override
  String get roomMembersEmpty => 'Chưa có thành viên nào để hiển thị';

  @override
  String get roomMemberMutedLabel => 'Đã tắt tiếng';

  @override
  String get roomMemberFallbackName => 'Thành viên';

  @override
  String get roomYourHub => 'Hub của bạn';

  @override
  String roomOnlineCount(int count) {
    return '$count đang trực tuyến';
  }

  @override
  String get roomNotAvailable => 'Phòng này không còn khả dụng.';

  @override
  String get roomGoToRooms => 'Đi đến Phòng';

  @override
  String get todayTab => 'Hôm nay';

  @override
  String get todaysGrammar => 'Ngữ pháp hôm nay';

  @override
  String get todaysVocabulary => 'Từ vựng hôm nay';

  @override
  String todayMinutes(int count) {
    return '$count phút';
  }

  @override
  String get todayPickLanguage => 'Bạn đang học gì?';

  @override
  String todayLevelFallback(String served, String requested) {
    return 'Đang hiển thị $served — chưa có nội dung cho $requested';
  }

  @override
  String get packTakePlacement => 'Tìm trình độ của bạn';

  @override
  String todayContentLanguage(String language) {
    return 'Bài học hôm nay bằng tiếng $language';
  }

  @override
  String get dailyCheck => 'Kiểm tra';

  @override
  String get dailyTooEasy => 'Quá dễ';

  @override
  String get dailyTooHard => 'Quá khó';

  @override
  String dailyScore(int score, int total) {
    return '$score/$total';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chuỗi $count ngày',
    );
    return '$_temp0';
  }

  @override
  String dailyXpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String get todayEmpty => 'Nội dung hôm nay đang được chuẩn bị. Hãy quay lại sau.';

  @override
  String todayLanguageUnsupported(String language) {
    return 'Chưa có bài học hằng ngày cho $language.';
  }

  @override
  String get packContinue => 'Tiếp tục';

  @override
  String get packGotIt => 'Đã hiểu';

  @override
  String get packSubmitFailed => 'Không lưu được — hãy kiểm tra kết nối và thử lại.';

  @override
  String packWordProgress(int current, int total) {
    return 'Từ $current trên $total';
  }

  @override
  String packGrammarUnit(int unit) {
    return 'Bài $unit';
  }

  @override
  String get packListeningPrompt => 'Bạn đã nghe từ nào?';

  @override
  String packPlayClip(int number) {
    return 'Phát đoạn $number';
  }

  @override
  String get packReveal => 'Xem đáp án';

  @override
  String get packKnewIt => 'Tôi đã biết';

  @override
  String get packMissed => 'Tôi chưa biết';

  @override
  String get packTranslatePrompt => 'Dịch câu này';

  @override
  String get packTranslateHint => 'Nhập bản dịch của bạn';

  @override
  String get packDone => 'Xong';

  @override
  String packTomorrowTeaser(String topic) {
    return 'Mai: tiếp tục với $topic';
  }

  @override
  String packContinueTo(String station) {
    return 'Tiếp tục · $station';
  }

  @override
  String get packDoneForToday => 'Xong cho hôm nay';

  @override
  String get packStationVocabulary => 'Từ vựng';

  @override
  String get packStationGrammar => 'Ngữ pháp';

  @override
  String get packStationListening => 'Nghe';

  @override
  String get packStationReview => 'Ôn tập';

  @override
  String get packStationWrap => 'Bài kiểm tra tuần';

  @override
  String get packStationTranslate => 'Dịch';

  @override
  String get masteryTitle => 'Tiến độ của bạn';

  @override
  String get masteryEmpty => 'Hoàn thành một ngày học và tiến độ của bạn sẽ hiện ở đây.';

  @override
  String get masteryYourLevel => 'trình độ của bạn';

  @override
  String get masteryRetake => 'Làm lại';

  @override
  String get masteryVocabulary => 'Từ vựng';

  @override
  String get masteryGrammar => 'Ngữ pháp';

  @override
  String get masteryListening => 'Nghe';

  @override
  String get masteryTranslate => 'Dịch';

  @override
  String get masteryNotStarted => 'Chưa bắt đầu';

  @override
  String masteryVocabularyCaption(int mastered, int learning, int due) {
    return '$mastered đã thuộc · $learning đang học · $due cần ôn';
  }

  @override
  String masteryGrammarCaption(int mastered, int total) {
    return 'Bài $mastered trên $total';
  }

  @override
  String masteryAccuracyCaption(int percent, int samples) {
    return '$percent% qua $samples lượt';
  }

  @override
  String get masteryConsistency => '30 ngày qua';

  @override
  String masteryDueCta(int count) {
    return 'Ôn $count từ ngay';
  }

  @override
  String get placementTitle => 'Tìm trình độ của bạn';

  @override
  String get placementSkip => 'Bỏ qua';

  @override
  String placementProgress(int current, int total) {
    return 'Câu $current trên $total';
  }

  @override
  String get placementResult => 'Chúng tôi sẽ bắt đầu từ đây. Bạn có thể thay đổi bất cứ lúc nào.';

  @override
  String get placementStart => 'Bắt đầu học';

  @override
  String get packNotGraded => 'Đã lưu — hiện chưa chấm được.';

  @override
  String packSuggestedTranslation(String translation) {
    return 'Gợi ý: $translation';
  }

  @override
  String get weeklyReportTitle => 'Tuần của bạn';

  @override
  String weeklyReportRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get weeklyReportDays => 'ngày đã học';

  @override
  String get weeklyReportStations => 'chặng đã hoàn thành';

  @override
  String get weeklyReportUnits => 'bài ngữ pháp đã thuộc';

  @override
  String get weeklyReportWords => 'từ mới';

  @override
  String get weeklyReportAccuracy => 'chính xác';

  @override
  String weeklyReportBestDay(String day, int count) {
    return 'Ngày tốt nhất của bạn là $day — hoàn thành $count chặng';
  }

  @override
  String get weeklyReportEmpty => 'Tuần này bạn chưa học. Chỉ một ngày là đủ để bắt đầu.';

  @override
  String get weeklyReportStart => 'Bắt đầu gói hôm nay';

  @override
  String get gatheringsTabLabel => 'Buổi gặp';

  @override
  String get gatheringClubs => 'Câu lạc bộ';

  @override
  String get gatheringNewClub => 'CLB mới';

  @override
  String get gatheringStartingSoon => 'Sắp bắt đầu';

  @override
  String get gatheringCreateShort => 'Tạo mới';

  @override
  String get gatheringLoadFailed => 'Không tải được các buổi gặp';

  @override
  String get gatheringEmptyTitle => 'Hãy tổ chức buổi đầu tiên';

  @override
  String get gatheringEmptyBody => 'Chưa có gì được lên lịch. Chọn một giờ rồi đăng lên — mọi người tham gia những buổi đã có người đứng ra tổ chức.';

  @override
  String get gatheringStartAClub => 'Tạo câu lạc bộ thay vì vậy';

  @override
  String get gatheringToday => 'Hôm nay';

  @override
  String get gatheringTomorrow => 'Ngày mai';

  @override
  String get gatheringHappeningNow => 'Đang diễn ra';

  @override
  String gatheringStartsIn(int minutes) {
    return 'Bắt đầu sau $minutes phút';
  }

  @override
  String gatheringHostZone(String zone) {
    return 'Múi giờ của người tổ chức: $zone';
  }

  @override
  String gatheringHostedBy(String name) {
    return 'Tổ chức bởi $name';
  }

  @override
  String gatheringQuorumNeeded(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cần thêm $countLabel người để xác nhận',
      zero: 'Sẵn sàng xác nhận',
    );
    return '$_temp0';
  }

  @override
  String gatheringConfirmed(int count) {
    return 'Đã xác nhận · $count người tham gia';
  }

  @override
  String get gatheringYouHost => 'Bạn là người tổ chức';

  @override
  String get gatheringGoingYou => 'Bạn sẽ tham gia';

  @override
  String get gatheringFull => 'Đã đầy';

  @override
  String get gatheringJoin => 'Tham gia';

  @override
  String get gatheringAskToJoin => 'Xin tham gia';

  @override
  String get gatheringRequested => 'Đã gửi yêu cầu — người tổ chức sẽ quyết định';

  @override
  String get gatheringCreateTitle => 'Buổi gặp mới';

  @override
  String get gatheringCreateSubtitle => 'Một giờ hẹn, một ngôn ngữ và vài chỗ ngồi. Còn lại là tùy chọn.';

  @override
  String gatheringDefaultTitle(String language) {
    return 'Luyện $language';
  }

  @override
  String get gatheringTitleLabel => 'Mọi người sẽ làm gì?';

  @override
  String get gatheringLanguageLabel => 'Ngôn ngữ';

  @override
  String get gatheringWhenLabel => 'Khi nào';

  @override
  String get gatheringSeatsLabel => 'Số chỗ';

  @override
  String get gatheringQuorumLabel => 'Xác nhận khi đủ';

  @override
  String get gatheringQuorumExplainer => 'Bạn được tính là người tham gia đầu tiên. Buổi gặp được xác nhận ngay khi đủ số người này.';

  @override
  String get gatheringPost => 'Đăng lên';

  @override
  String get gatheringPosted => 'Đã đăng — giờ thì chia sẻ đi';

  @override
  String get gatheringNeedsTitle => 'Đặt tên trước đã';

  @override
  String get gatheringNeedsLanguage => 'Chọn ngôn ngữ trước đã';

  @override
  String get gatheringNeedsFuture => 'Hãy chọn một thời điểm trong tương lai';

  @override
  String get gatheringDetailTitle => 'Buổi gặp';

  @override
  String get gatheringNotFound => 'Buổi gặp này không còn khả dụng';

  @override
  String gatheringDuration(int minutes) {
    return '$minutes phút';
  }

  @override
  String gatheringSeatsTaken(int going, int capacity) {
    return 'Đã kín $going trong $capacity chỗ';
  }

  @override
  String get gatheringCancelled => 'Đã hủy';

  @override
  String get gatheringEnded => 'Buổi gặp này đã kết thúc';

  @override
  String get gatheringCancelRsvp => 'Hủy tham gia';

  @override
  String gatheringHostDecision(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hiện mới chỉ có $countLabel người. Vẫn tổ chức hay hủy?',
    );
    return '$_temp0';
  }

  @override
  String get gatheringHostDecisionAlone => 'Hiện mới chỉ có mình bạn. Vẫn tổ chức hay hủy?';

  @override
  String get gatheringRunAnyway => 'Vẫn tổ chức';

  @override
  String get gatheringCallItOff => 'Hủy buổi gặp';

  @override
  String get gatheringEnd => 'Kết thúc buổi gặp';

  @override
  String get gatheringEndedThanks => 'Đã kết thúc — nhắn tin cho người bạn vừa gặp là miễn phí';

  @override
  String get gatheringCancelIt => 'Hủy buổi gặp';

  @override
  String get gatheringKeepIt => 'Giữ lại';

  @override
  String gatheringCancelConfirm(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countLabel người đang chờ buổi này. Họ sẽ được báo là đã hủy.',
      one: '$countLabel người đang chờ buổi này. Họ sẽ được báo là đã hủy.',
    );
    return '$_temp0';
  }

  @override
  String get clubDetailTitle => 'Câu lạc bộ';

  @override
  String get clubNotFound => 'Câu lạc bộ này không còn khả dụng';

  @override
  String clubMembers(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countLabel thành viên',
    );
    return '$_temp0';
  }

  @override
  String get clubJoin => 'Tham gia CLB';

  @override
  String get clubLeave => 'Rời CLB';

  @override
  String get clubUpcoming => 'Sắp tới';

  @override
  String get clubNothingScheduled => 'Chưa có gì được lên lịch.';

  @override
  String get clubHostGathering => 'Tổ chức buổi gặp';

  @override
  String get clubCreateTitle => 'Câu lạc bộ mới';

  @override
  String get clubCreateSubtitle => 'Câu lạc bộ giữ mọi người ở lại giữa các buổi gặp. Hãy đặt tên theo điều các bạn thực sự sẽ làm.';

  @override
  String get clubNameLabel => 'Tên câu lạc bộ';

  @override
  String get clubInterestLabel => 'Sở thích';

  @override
  String get clubInterestHint => 'Tùy chọn — chạy bộ, K-pop, HSK4';

  @override
  String get clubDescriptionLabel => 'Giới thiệu';

  @override
  String get clubCreate => 'Tạo câu lạc bộ';

  @override
  String get clubNeedsName => 'Hãy đặt tên cho câu lạc bộ trước';

  @override
  String gatheringRequests(int count) {
    return '$count đang chờ tham gia';
  }

  @override
  String get gatheringAdmit => 'Chấp nhận';

  @override
  String get gatheringDeny => 'Từ chối';

  @override
  String get gatheringsMine => 'Buổi gặp của tôi';

  @override
  String get gatheringsMineEmpty => 'Chưa có gì. Các buổi gặp bạn tổ chức hoặc tham gia sẽ hiện ở đây.';

  @override
  String get gatheringsMineSubtitle => 'Buổi gặp bạn tổ chức hoặc đã tham gia';

  @override
  String get gatheringSave => 'Lưu';

  @override
  String get gatheringSaved => 'Đã lưu thay đổi';

  @override
  String get gatheringEditIt => 'Chỉnh sửa';

  @override
  String get intentSectionTitle => 'Bạn ở đây để làm gì';

  @override
  String get intentLearn => 'Ở đây để học';

  @override
  String get intentMeet => 'Muốn gặp gỡ mọi người';

  @override
  String get intentDate => 'Sẵn sàng hẹn hò';

  @override
  String get intentPrivacyNote => 'Người khác thấy lựa chọn của bạn, trừ hẹn hò — mục đó được giữ riêng tư.';

  @override
  String get gatheringNoClubsYet => 'Chưa có câu lạc bộ — tạo một cái để các buổi gặp có nơi thuộc về.';

  @override
  String get topicConversation => 'Trò chuyện';

  @override
  String get topicExamPrep => 'Luyện thi';

  @override
  String get topicGrammar => 'Ngữ pháp';

  @override
  String get topicPronunciation => 'Phát âm';

  @override
  String get topicCulture => 'Văn hóa';

  @override
  String get topicMedia => 'Âm nhạc & phim';

  @override
  String get topicGames => 'Trò chơi';

  @override
  String get topicBusiness => 'Kinh doanh';

  @override
  String get topicTravel => 'Du lịch';

  @override
  String get filterThisWeek => 'Tuần này';

  @override
  String get filterThisWeekend => 'Cuối tuần này';

  @override
  String get filterHasSeat => 'Còn chỗ';

  @override
  String filterClear(int count) {
    return 'Xóa $count';
  }

  @override
  String get filterNoMatches => 'Chưa có buổi gặp nào khớp bộ lọc.';

  @override
  String get gatheringTopicLabel => 'Chủ đề (tùy chọn)';

  @override
  String get avatarViewStory => 'Xem tin';

  @override
  String get avatarViewPhoto => 'Xem ảnh đại diện';

  @override
  String get composerNext => 'Tiếp theo';

  @override
  String get notifyRepliesTitle => 'Nhận thông báo khi có người trả lời';

  @override
  String get notifyRepliesBody => 'Chúng tôi sẽ báo về tin nhắn mới và lời nhắc học tập hằng ngày. Bạn có thể tắt bất kỳ lúc nào.';

  @override
  String get notifyRepliesEnable => 'Bật';

  @override
  String get notifyRepliesLater => 'Để sau';

  @override
  String get notificationsOffTitle => 'Thông báo đang tắt';

  @override
  String get notificationsOffBody => 'Thiết bị của bạn đang chặn thông báo từ BananaTalk nên lời nhắc và tin nhắn không thể đến với bạn. Các cài đặt bên dưới sẽ chưa có hiệu lực cho đến khi bạn bật lên.';

  @override
  String get notificationsOffOpen => 'Mở cài đặt';

  @override
  String get reportGathering => 'Báo cáo buổi gặp';

  @override
  String get reportClub => 'Báo cáo câu lạc bộ';

  @override
  String get finishProfileTitle => 'Hoàn tất thiết lập hồ sơ';

  @override
  String get finishProfileBody => 'Chúng tôi cần ngày sinh của bạn để giữ BananaTalk an toàn cho mọi người. Bạn có thể đăng xuất nếu không muốn tiếp tục.';

  @override
  String get finishProfileContinue => 'Tiếp tục';

  @override
  String get finishProfileSignOut => 'Đăng xuất';

  @override
  String packReviewProgress(int current, int total) {
    return 'Ôn tập $current trên $total';
  }

  @override
  String get packReviewRecall => 'Bạn còn nhớ từ này không?';

  @override
  String get clubOrganizers => 'Ban tổ chức';

  @override
  String get clubMembersLabel => 'Thành viên';

  @override
  String clubMeetsIn(String city) {
    return 'Gặp nhau tại $city';
  }

  @override
  String clubEventsHeld(int count) {
    return 'Đã tổ chức $count sự kiện';
  }

  @override
  String get clubEdit => 'Sửa câu lạc bộ';

  @override
  String get clubDelete => 'Xóa câu lạc bộ';

  @override
  String get clubDeleteConfirmTitle => 'Xóa câu lạc bộ này?';

  @override
  String get clubDeleteConfirmBody => 'Các buổi đã lên lịch vẫn giữ nguyên — đã có người nhận lời tham gia. Chỉ câu lạc bộ bị xóa.';

  @override
  String get clubRemoveMember => 'Xóa khỏi câu lạc bộ';

  @override
  String get clubMakeOrganizer => 'Đặt làm ban tổ chức';

  @override
  String get clubRemoveOrganizer => 'Bỏ ban tổ chức';

  @override
  String clubSince(String date) {
    return 'Câu lạc bộ từ $date';
  }

  @override
  String get clubNoEventsHeld => 'Chưa tổ chức sự kiện nào';

  @override
  String get clubPlaceLabel => 'Địa điểm thường lệ';

  @override
  String get groupCoverChange => 'Đổi ảnh';

  @override
  String get groupCoverFromLibrary => 'Chọn từ thư viện';

  @override
  String get groupCoverTakePhoto => 'Chụp ảnh';

  @override
  String get groupCoverRemove => 'Xóa ảnh';

  @override
  String get groupCoverAddOptional => 'Thêm ảnh (tùy chọn)';

  @override
  String get clubsMine => 'Câu lạc bộ của tôi';

  @override
  String get clubsMineEmpty => 'Bạn chưa tham gia câu lạc bộ nào';

  @override
  String get storyLink => 'Liên kết';

  @override
  String get storyLinkSubtitle => 'Đưa người xem đến một trang';

  @override
  String get storyLinkAdd => 'Thêm liên kết';

  @override
  String get storyLinkUrlLabel => 'Địa chỉ liên kết';

  @override
  String get storyLinkButtonLabel => 'Chữ trên nút';

  @override
  String get storyLinkButtonDefault => 'Xem ngay';

  @override
  String storyLinkOpensHost(String host) {
    return 'Mở $host';
  }

  @override
  String get storyLinkInvalid => 'Nhập địa chỉ http hoặc https hợp lệ';

  @override
  String get storyStickerPoll => 'Bình chọn';

  @override
  String get storyStickerPollSubtitle => 'Đặt câu hỏi có lựa chọn';

  @override
  String get storyStickerQuestion => 'Câu hỏi';

  @override
  String get storyStickerQuestionSubtitle => 'Để người xem gửi câu trả lời';

  @override
  String get storyStickerLocation => 'Vị trí';

  @override
  String get storyStickerLocationSubtitle => 'Gắn thẻ nơi chụp tin này';

  @override
  String get storyStickerMention => 'Nhắc đến';

  @override
  String get storyStickerMentionSubtitle => 'Gắn thẻ người bạn theo dõi';

  @override
  String get storyToolDraw => 'Vẽ';

  @override
  String get momentsTabForYou => 'Dành cho bạn';

  @override
  String get momentsTabReels => 'Reels';

  @override
  String get storyArchiveTitle => 'Kho lưu trữ';

  @override
  String get storyArchiveSubtitle => 'Tin đã hết hạn, chỉ bạn nhìn thấy';

  @override
  String get storyArchiveEmpty => 'Chưa có gì trong kho';

  @override
  String get storyArchiveEmptyBody => 'Tin sẽ chuyển vào đây sau 24 giờ. Thêm vào tin nổi bật để giữ trên trang cá nhân.';

  @override
  String get storyArchiveAddHighlight => 'Thêm vào tin nổi bật';

  @override
  String get storyArchiveAdded => 'Đã thêm vào tin nổi bật';

  @override
  String get doneAction => 'Xong';

  @override
  String get noneOption => 'Không có';

  @override
  String get stopAction => 'Dừng';

  @override
  String get selectPlaceholder => 'Chọn...';

  @override
  String get goVip => 'Lên VIP';

  @override
  String get logoutFailed => 'Đăng xuất thất bại';

  @override
  String get vocabularyPacks => 'Bộ từ vựng';

  @override
  String get noVocabPacksYet => 'Chưa có bộ từ nào.';

  @override
  String get addWord => 'Thêm từ';

  @override
  String get deleteWord => 'Xóa từ';

  @override
  String get shuffleAction => 'Xáo trộn';

  @override
  String get exitLessonTitle => 'Thoát bài học?';

  @override
  String get exitQuizTitle => 'Thoát bài kiểm tra?';

  @override
  String get quizNotFound => 'Không tìm thấy bài kiểm tra';

  @override
  String get vocabPackAddFailed => 'Không thể thêm bộ từ';

  @override
  String get vocabPackLoadFailed => 'Không thể tải bộ từ';

  @override
  String get addToMyVocab => 'Thêm vào từ vựng của tôi';

  @override
  String get viewAiSummary => 'Xem tóm tắt AI';

  @override
  String get reRecord => 'Ghi lại';

  @override
  String get practiceComplete => 'Hoàn thành luyện tập';

  @override
  String get micPermissionNeeded => 'Cần quyền micro';

  @override
  String get thanksForParticipating => 'Cảm ơn bạn đã tham gia! +10 XP 🎉';

  @override
  String deleteWordConfirm(String word) {
    return 'Xóa “$word” khỏi từ vựng của bạn?';
  }

  @override
  String get wordDeleted => 'Đã xóa từ';

  @override
  String get vocabularyLoadFailed => 'Không thể tải từ vựng của bạn';

  @override
  String get savedTitle => 'Đã lưu';

  @override
  String get savedSubtitle => 'Reels và khoảnh khắc bạn đã lưu';

  @override
  String get introRequests => 'Yêu cầu làm quen';

  @override
  String get icebreakerWhyLearn => 'Điều gì khiến bạn bắt đầu học ngôn ngữ mới?';

  @override
  String get icebreakerCanHelp => 'Chào bạn! Mình có thể giúp bạn luyện tập 😊';

  @override
  String get icebreakerFavoriteWord => 'Từ yêu thích của bạn trong tiếng mẹ đẻ là gì?';

  @override
  String get icebreakerCoffeeChat => 'Trò chuyện lúc nghỉ cà phê nhé?';

  @override
  String get icebreakerHowsWeek => 'Tuần này của bạn thế nào?';

  @override
  String get failedToLoadReels => 'Không thể tải reels';

  @override
  String get failedToLoadSavedMoments => 'Không thể tải mục đã lưu';

  @override
  String get adNotReady => 'Quảng cáo chưa sẵn sàng — thử lại sau giây lát';

  @override
  String get addQuickReply => 'Thêm trả lời nhanh';

  @override
  String get pollNeedQuestionAndOptions => 'Thêm câu hỏi và ít nhất 2 lựa chọn';

  @override
  String get addOne => 'Thêm một';

  @override
  String get addScreenshotsOrPhotos => 'Thêm ảnh chụp màn hình hoặc ảnh';

  @override
  String get allowMultipleVotes => 'Cho phép bình chọn nhiều';

  @override
  String get attachImageOrTxt => 'Đính kèm ảnh hoặc tệp .txt';

  @override
  String get audioUploadFailed => 'Tải âm thanh thất bại';

  @override
  String get browseFiles => 'Duyệt tệp';

  @override
  String get clearCompleted => 'Xóa mục đã xong';

  @override
  String get closePollTitle => 'Đóng bình chọn?';

  @override
  String get coinHistory => 'Lịch sử xu';

  @override
  String get coinShop => 'Cửa hàng xu';

  @override
  String get conversationSummary => 'Tóm tắt hội thoại';

  @override
  String get couldNotLoadFollowings => 'Không thể tải danh sách đang theo dõi';

  @override
  String get couldNotLoadMoreHistory => 'Không thể tải thêm lịch sử.';

  @override
  String get couldNotLoadChats => 'Không thể tải cuộc trò chuyện';

  @override
  String get decline => 'Từ chối';

  @override
  String get endConversationTitle => 'Kết thúc hội thoại?';

  @override
  String get explainAction => 'Giải thích';

  @override
  String get failedToPlayAudio => 'Không phát được âm thanh';

  @override
  String get failedToSavePhrase => 'Không lưu được cụm từ';

  @override
  String get freeRetryUnlocked => 'Đã mở lượt thử lại miễn phí! 🎉';

  @override
  String get getAnotherHint => 'Nhận gợi ý khác';

  @override
  String get hideWhoVoted => 'Ẩn người đã bình chọn từng lựa chọn';

  @override
  String get invalidQrCode => 'Mã QR không hợp lệ';

  @override
  String get linkCopiedToClipboard => 'Đã sao chép liên kết';

  @override
  String get loadMore => 'Tải thêm';

  @override
  String get manage => 'Quản lý';

  @override
  String get maxTenOptions => 'Tối đa 10 lựa chọn';

  @override
  String get maybeLater => 'Để sau';

  @override
  String get minTwoOptions => 'Cần ít nhất 2 lựa chọn';

  @override
  String get noMoreVotesAfterClosing => 'Sau khi đóng sẽ không nhận thêm bình chọn.';

  @override
  String get noOneToMention => 'Chưa có ai để nhắc đến';

  @override
  String get noRecentChatsToSendTo => 'Không có cuộc trò chuyện gần đây để gửi';

  @override
  String get notEnoughCoins => 'Không đủ xu.';

  @override
  String get oneOptionIsCorrect => 'Một lựa chọn là đáp án đúng';

  @override
  String get photoLibrary => 'Thư viện ảnh';

  @override
  String get phraseSavedToStudyQueue => 'Đã lưu cụm từ vào hàng đợi học';

  @override
  String get pleaseAddTwoOptions => 'Vui lòng thêm ít nhất 2 lựa chọn';

  @override
  String get pleaseAttachEvidence => 'Vui lòng đính kèm ít nhất một tệp làm bằng chứng';

  @override
  String get pleaseEnterQuestion => 'Vui lòng nhập câu hỏi';

  @override
  String get pleaseSelectReportReason => 'Vui lòng chọn lý do báo cáo';

  @override
  String get pleaseSelectCorrectAnswer => 'Vui lòng chọn đáp án đúng cho bài kiểm tra';

  @override
  String get pollExpires => 'Bình chọn hết hạn';

  @override
  String get quizMode => 'Chế độ đố vui';

  @override
  String get recordAReel => 'Quay reel';

  @override
  String get reelsContentGuidelines => 'Nguyên tắc nội dung reels';

  @override
  String get reportTypeMissing => 'Thiếu loại báo cáo';

  @override
  String get reportedContentIdMissing => 'Thiếu ID nội dung bị báo cáo';

  @override
  String get reportedUserIdMissing => 'Thiếu ID người dùng bị báo cáo';

  @override
  String get retryAll => 'Thử lại tất cả';

  @override
  String get savedToVocabulary => 'Đã lưu vào từ vựng!';

  @override
  String get savedFindInProfile => 'Đã lưu. Xem trong Hồ sơ → Đã lưu.';

  @override
  String get shareVia => 'Chia sẻ qua...';

  @override
  String get shareYourLocation => 'Chia sẻ vị trí của bạn?';

  @override
  String get suggestACorrection => 'Đề xuất chỉnh sửa';

  @override
  String get translationCopied => 'Đã sao chép bản dịch';

  @override
  String get unlock => 'Mở khóa';

  @override
  String get unlockPremiumWallpapers => 'Mở khóa hình nền premium';

  @override
  String get uploadQueue => 'Hàng đợi tải lên';

  @override
  String get usersCanVoteMultiple => 'Người dùng có thể chọn nhiều lựa chọn';

  @override
  String get watchAd => 'Xem quảng cáo';

  @override
  String get matchReasonReciprocal => 'Hai bạn học ngôn ngữ của nhau';

  @override
  String matchReasonSameTarget(String language) {
    return 'Cũng đang học $language';
  }

  @override
  String matchReasonSharedTopic(String topic) {
    return 'Sở thích chung: $topic';
  }

  @override
  String get matchReasonActiveToday => 'Hoạt động hôm nay';

  @override
  String get matchReasonSameCity => 'Sống cùng thành phố với bạn';

  @override
  String get matchRepliesFast => 'Trả lời nhanh';

  @override
  String matchesTodayTitle(int count) {
    return '$count người ghép hôm nay';
  }

  @override
  String matchesRefreshHint(String time) {
    return 'làm mới lúc $time';
  }

  @override
  String get matchesRefreshHintFallback => 'làm mới lúc nửa đêm';

  @override
  String get matchesEmptyTitle => 'Hôm nay hết rồi';

  @override
  String get matchesEmptyBody => 'Ngày mai có người mới. Trong lúc đó, xem tất cả đối tác.';

  @override
  String get matchesEmptyCta => 'Xem đối tác';

  @override
  String get matchSayHi => 'Chào';

  @override
  String get communityTabMatches => 'Matches';

  @override
  String get communityTabPartners => 'Partners';

  @override
  String get segmentAll => 'All';

  @override
  String get segmentSerious => 'Người học nghiêm túc';

  @override
  String get segmentNew => 'Thành viên mới';

  @override
  String get segmentSeriousHint => 'Hồ sơ đầy đủ · hoạt động tuần này';

  @override
  String get segmentNewHint => 'Tham gia trong 7 ngày qua';

  @override
  String openerReciprocal(String theirLanguage, String myLanguage) {
    return 'Hay là một nửa tin nhắn bằng $theirLanguage, một nửa bằng $myLanguage? Mình sửa cho bạn, bạn sửa cho mình 😄';
  }

  @override
  String openerSharedTopic(String topic) {
    return 'Mình thấy bạn thích $topic — bạn bắt đầu từ đâu vậy?';
  }

  @override
  String openerGeneric(String name, String language) {
    return 'Chào $name! Mình đang học $language — bạn có mẹo nào không? 👋';
  }

  @override
  String get openerChipsTitle => 'Câu mở đầu — chạm để sửa trước khi gửi';

  @override
  String stallRescueTitle(String name) {
    return '$name vừa hỏi bạn một câu 👀';
  }

  @override
  String get stallRescueHint => 'Xin lỗi vì trả lời chậm! Bạn còn muốn trò chuyện không? 😊';

  @override
  String get referralTitle => 'Mời bạn bè';

  @override
  String get referralSubtitle => 'Nhận xu khi bạn bè tham gia';

  @override
  String get referralYourCode => 'Mã mời của bạn';

  @override
  String referralInvitedCount(int count) {
    return 'Đã mời: $count';
  }

  @override
  String referralShareText(String code, String link) {
    return 'Tham gia BananaTalk cùng mình nhé — luyện ngôn ngữ với người thật. Dùng mã mời của mình $code: $link';
  }

  @override
  String get referralCopy => 'Sao chép';

  @override
  String get referralShare => 'Chia sẻ';

  @override
  String get referralCopied => 'Đã sao chép';

  @override
  String referralClaimed(int coins) {
    return 'Bạn đã nhận được $coins xu!';
  }

  @override
  String get referralHowItWorks => 'Khi bạn bè đăng ký bằng mã của bạn và hoàn tất hồ sơ, cả hai đều nhận được xu.';

  @override
  String get boostTitle => 'Đẩy hồ sơ của tôi';

  @override
  String get boostSubtitle => 'Được nhiều bạn học thấy hơn trong 24 giờ';

  @override
  String get boostFromMatches => 'Được nhiều người thấy hơn';

  @override
  String get boostedChip => 'Đã đẩy';

  @override
  String get boostCapacityFull => 'Hiện tại tất cả suất đẩy đã đầy — hãy thử lại sau vài giờ';

  @override
  String extraMatchesCta(int cost) {
    return '+3 lượt ghép nữa — $cost xu';
  }

  @override
  String get boostExplain => 'Trở thành lượt ghép thứ 6 của mọi người có ngôn ngữ phù hợp với bạn trong 24 giờ.';

  @override
  String boostCostLine(int cost) {
    return 'Chi phí: $cost xu';
  }

  @override
  String boostBalanceLine(int balance) {
    return 'Số dư của bạn: $balance xu';
  }

  @override
  String get boostConfirm => 'Xác nhận đẩy hồ sơ';

  @override
  String get boostActiveTitle => 'Lượt đẩy của bạn đang chạy';

  @override
  String boostTimeLeft(String time) {
    return 'Còn $time';
  }

  @override
  String boostSeenBy(int count) {
    return 'Đã có $count người thấy';
  }

  @override
  String get boostFailed => 'Không thể bắt đầu đẩy hồ sơ. Vui lòng thử lại.';

  @override
  String get rewardedLimitReached => 'Bạn đã dùng hết lượt mở khóa miễn phí hôm nay cho mục này — hãy thử lại vào ngày mai';

  @override
  String get wavesMaskedTitle => 'Ai đó đã vẫy tay chào bạn';

  @override
  String wavesMaskedBody(int cost) {
    return 'Xem đó là ai với $cost xu, hoặc nâng cấp VIP';
  }

  @override
  String get wavesMaskedBodyVip => 'Nâng cấp VIP để xem ai đã vẫy tay chào bạn';

  @override
  String get perkAdFree => 'Không quảng cáo';

  @override
  String get perkUnlimitedMatches => 'Ghép đôi hằng ngày không giới hạn';

  @override
  String get perkRevealWaves => 'Xem ai đã vẫy tay và xem hồ sơ của bạn';

  @override
  String get perkUnlimitedWaves => 'Vẫy tay không giới hạn';

  @override
  String get perkAdvancedFilters => 'Bộ lọc đối tác nâng cao';

  @override
  String get vipFromMatches => 'VIP: ghép đôi không giới hạn';

  @override
  String get vipRemoveAds => 'Gỡ quảng cáo';

  @override
  String get limitUnlockedRetry => 'Đã mở khóa — đang gửi lại';

  @override
  String get rewardedUnlockSuccess => 'Đã mở khóa! Bạn có thể thử lại ngay.';

  @override
  String get extraMatchesMaxed => 'Bạn đã có số lượt ghép đôi thêm tối đa cho hôm nay';

  @override
  String wavesMaskedTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count người vẫy tay chào bạn',
      one: 'Có người vẫy tay chào bạn',
    );
    return '$_temp0';
  }

  @override
  String visitorsMaskedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count người đã xem hồ sơ của bạn',
      one: 'Có người đã xem hồ sơ của bạn',
    );
    return '$_temp0';
  }

  @override
  String visitorsMaskedBody(int cost) {
    return 'Xem là ai với $cost xu, hoặc nâng cấp VIP';
  }

  @override
  String get visitorsMaskedBodyVip => 'Nâng cấp VIP để xem ai đã xem hồ sơ của bạn';

  @override
  String boostDurationHm(int hours, int minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String boostDurationM(int minutes) {
    return '$minutes phút';
  }

  @override
  String get boostEndingSoon => 'Sắp kết thúc';

  @override
  String coinAmount(int cost) {
    return '💎$cost';
  }

  @override
  String unlockedMore(int count) {
    return 'Đã mở khóa thêm $count!';
  }

  @override
  String get getMoreCoins => 'Nhận thêm xu';

  @override
  String get unlockFailed => 'Không thể mở khóa lúc này.';

  @override
  String unlockGrantForCoins(int count, int cost) {
    return 'Mở khóa $count với 💎$cost';
  }

  @override
  String get waveLimitTitle => 'Bạn đã dùng hết lượt chào hôm nay';

  @override
  String get waveLimitBody => 'Nhận thêm một lượt chào ngay bây giờ, hoặc quay lại vào ngày mai.';

  @override
  String get limitDailyReachedTitle => 'Đã đạt giới hạn hằng ngày';

  @override
  String get limitLabelMessages => 'Tin nhắn';

  @override
  String get limitLabelMoments => 'Khoảnh khắc';

  @override
  String get limitLabelStories => 'Tin';

  @override
  String get limitLabelComments => 'Bình luận';

  @override
  String get limitLabelProfileViews => 'Lượt xem hồ sơ';

  @override
  String get limitLabelWaves => 'Lượt chào';

  @override
  String limitUsedLabel(String label) {
    return 'Đã dùng $label';
  }

  @override
  String get limitDescMessages => 'Bạn đã đạt giới hạn tin nhắn hằng ngày. Nâng cấp VIP để nhắn tin không giới hạn!';

  @override
  String get limitDescMoments => 'Bạn đã đạt giới hạn đăng khoảnh khắc hằng ngày. Nâng cấp VIP để đăng không giới hạn!';

  @override
  String get limitDescStories => 'Bạn đã đạt giới hạn đăng tin hằng ngày. Nâng cấp VIP để đăng tin không giới hạn!';

  @override
  String get limitDescComments => 'Bạn đã đạt giới hạn bình luận hằng ngày. Nâng cấp VIP để bình luận không giới hạn!';

  @override
  String get limitDescProfileViews => 'Bạn đã đạt giới hạn xem hồ sơ hằng ngày. Nâng cấp VIP để xem hồ sơ không giới hạn!';

  @override
  String get limitDescDefault => 'Bạn đã đạt giới hạn hằng ngày. Nâng cấp VIP để truy cập không giới hạn!';

  @override
  String get limitResetsAt => 'Giới hạn đặt lại lúc';

  @override
  String get vipMembersGet => 'Thành viên VIP nhận được';

  @override
  String get vipBenefitUnlimitedMessages => 'Tin nhắn không giới hạn';

  @override
  String get vipBenefitUnlimitedProfileViews => 'Xem hồ sơ không giới hạn';

  @override
  String get vipBenefitAiStudyTools => 'Công cụ học AI';

  @override
  String chatBonusMessagesUnlocked(int count) {
    return 'Bạn đã mở khóa $count tin nhắn thưởng! Tiếp tục trò chuyện nhé.';
  }

  @override
  String callLabelOutgoing(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Cuộc gọi video đi',
        'other': 'Cuộc gọi thoại đi',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelIncoming(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Cuộc gọi video đến',
        'other': 'Cuộc gọi thoại đến',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelNoAnswer(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Cuộc gọi video · Không trả lời',
        'other': 'Cuộc gọi thoại · Không trả lời',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelMissed(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Cuộc gọi video nhỡ',
        'other': 'Cuộc gọi thoại nhỡ',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelCancelled(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Cuộc gọi video đã hủy',
        'other': 'Cuộc gọi thoại đã hủy',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelDeclinedOutgoing(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Cuộc gọi video bị từ chối',
        'other': 'Cuộc gọi thoại bị từ chối',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelDeclinedIncoming(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Đã từ chối cuộc gọi video',
        'other': 'Đã từ chối cuộc gọi thoại',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelBusy(String name) {
    return '$name đang có cuộc gọi khác';
  }

  @override
  String get callsTitle => 'Cuộc gọi';

  @override
  String get callsEmpty => 'Chưa có cuộc gọi nào';

  @override
  String get callCameraPaused => 'Đã tạm dừng camera';

  @override
  String get callFullScreenIntentTitle => 'Hiển thị cuộc gọi trên màn hình khóa';

  @override
  String get callFullScreenIntentBody => 'Cho phép BananaTalk hiển thị cuộc gọi đến toàn màn hình để bạn không bỏ lỡ khi điện thoại đang khóa.';

  @override
  String get callForegroundTitle => 'Đang trong cuộc gọi';

  @override
  String get callForegroundBody => 'Nhấn để quay lại cuộc gọi';

  @override
  String get callServiceChannelName => 'Cuộc gọi đang diễn ra';

  @override
  String get callServiceChannelDescription => 'Giữ cuộc gọi tiếp tục khi BananaTalk chạy nền';

  @override
  String firstSessionMatchesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hôm nay có $count người được chọn cho bạn',
      one: 'Hôm nay có 1 người được chọn cho bạn',
    );
    return '$_temp0';
  }

  @override
  String get firstSessionMatchesBody => 'Chào một câu — chỉ cần tin nhắn đầu tiên.';

  @override
  String get guideAiStudyTitle => 'Luyện trước khi cần đến';

  @override
  String get guideAiStudyBody => 'Luyện với gia sư AI, hoặc ôn cho một kỳ thi thật. Hai phút là một buổi.';

  @override
  String get guideAiStudyCta => 'Mở công cụ AI';

  @override
  String get guideChatsTitle => 'Các cuộc trò chuyện của bạn nằm ở đây';

  @override
  String get guideChatsBody => 'Chưa có gì. Chào một người trong danh sách ghép hôm nay và danh sách này sẽ đầy lên.';

  @override
  String get guideChatsCta => 'Tìm người trò chuyện';

  @override
  String get guideMomentsTitle => 'Đăng gì đó bằng ngôn ngữ bạn đang học';

  @override
  String get guideMomentsBody => 'Một tấm ảnh hoặc một dòng. Người bản ngữ sẽ sửa những gì bạn viết ở đây.';

  @override
  String get guideMomentsCta => 'Đăng khoảnh khắc';

  @override
  String get guideProfileTitle => 'Hoàn thiện hồ sơ của bạn';

  @override
  String get guideProfileBody => 'Một tấm ảnh và một dòng về bản thân. Hồ sơ bỏ dở thường bị lướt qua.';

  @override
  String get guideProfileCta => 'Chỉnh sửa hồ sơ';

  @override
  String get conversationEmptyTitle => 'Chưa có tin nhắn';

  @override
  String conversationEmptyBody(String name) {
    return 'Gửi một tin nhắn để bắt đầu trò chuyện với $name';
  }

  @override
  String get conversationEmptySayHi => 'Chạm để chào!';

  @override
  String get momentVideoOptimizing => 'Vui lòng đợi trong khi chúng tôi tối ưu video của bạn';

  @override
  String get momentPostedWithoutVoiceNote => 'Khoảnh khắc đã đăng nhưng không có ghi âm.';

  @override
  String get momentAnsweringPromptOfDay => 'Trả lời câu hỏi trong ngày';

  @override
  String get momentVideoReady => 'Video đã sẵn sàng';

  @override
  String get momentReadyToUpload => 'Sẵn sàng tải lên';

  @override
  String get locationServicesDisabledTitle => 'Dịch vụ vị trí đang tắt';

  @override
  String get locationServicesDisabledBody => 'Hãy bật Dịch vụ vị trí trong cài đặt thiết bị để dùng tính năng này.';

  @override
  String get locationPermissionNeededBody => 'Bananatalk cần quyền vị trí để gắn vị trí hiện tại vào khoảnh khắc của bạn.';

  @override
  String get locationPermissionRequiredTitle => 'Cần quyền vị trí';

  @override
  String get locationPermissionPermanentlyDeniedBody => 'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy bật trong cài đặt ứng dụng để gắn vị trí vào khoảnh khắc.';

  @override
  String get termsSnackAcceptFirst => 'Hãy chấp nhận Điều khoản dịch vụ để tiếp tục';

  @override
  String get termsErrorAccepting => 'Lỗi khi chấp nhận điều khoản. Vui lòng thử lại.';

  @override
  String get termsEulaTitle => 'Thỏa thuận cấp phép người dùng cuối (EULA)';

  @override
  String get termsWelcomeHeading => 'Chào mừng đến với Bananatalk';

  @override
  String get termsWelcomeBody => 'Khi dùng Bananatalk, bạn đồng ý chịu ràng buộc bởi Điều khoản dịch vụ này. Vui lòng đọc kỹ trước khi sử dụng dịch vụ của chúng tôi.';

  @override
  String get termsZeroToleranceHeading => 'Chính sách không khoan nhượng';

  @override
  String get termsZeroToleranceIntro => 'Bananatalk áp dụng chính sách KHÔNG KHOAN NHƯỢNG với nội dung phản cảm và người dùng lạm dụng. Chúng tôi không cho phép, không dung túng và không chấp nhận:';

  @override
  String get termsZeroToleranceItem1 => 'Quấy rối, bắt nạt hoặc đe dọa dưới mọi hình thức';

  @override
  String get termsZeroToleranceItem2 => 'Phát ngôn thù ghét, phân biệt đối xử hoặc nội dung cổ xúy bạo lực';

  @override
  String get termsZeroToleranceItem3 => 'Nội dung khiêu dâm, tình dục lộ liễu hoặc không phù hợp';

  @override
  String get termsZeroToleranceItem4 => 'Spam, lừa đảo hoặc hành vi gian lận';

  @override
  String get termsZeroToleranceItem5 => 'Mạo danh hoặc khai báo sai sự thật';

  @override
  String get termsZeroToleranceItem6 => 'Bất kỳ nội dung nào vi phạm pháp luật hoặc quy định hiện hành';

  @override
  String get termsZeroToleranceEnforcement => 'Người dùng vi phạm các chính sách này sẽ bị cấm khỏi nền tảng ngay lập tức. Chúng tôi có quyền gỡ bỏ bất kỳ nội dung nào và chấm dứt bất kỳ tài khoản nào vi phạm các điều khoản này mà không cần báo trước.';

  @override
  String get termsUgcHeading => 'Nội dung do người dùng tạo';

  @override
  String get termsUgcBody => 'Bananatalk cho phép người dùng tạo và chia sẻ nội dung gồm tin nhắn, bài đăng, hình ảnh và các tài liệu khác. Bạn hoàn toàn chịu trách nhiệm về mọi nội dung mình tạo, tải lên hoặc chia sẻ qua dịch vụ.';

  @override
  String get termsUgcAgreeIntro => 'Khi dùng Bananatalk, bạn đồng ý rằng:';

  @override
  String get termsUgcItem1 => 'Bạn sẽ không đăng nội dung phản cảm, có hại hoặc bất hợp pháp';

  @override
  String get termsUgcItem2 => 'Bạn sẽ không có hành vi lạm dụng với người dùng khác';

  @override
  String get termsUgcItem3 => 'Bạn sẽ tôn trọng quyền và phẩm giá của mọi người dùng';

  @override
  String get termsUgcItem4 => 'Bạn sẽ báo cáo nội dung phản cảm hoặc người dùng lạm dụng mà bạn gặp';

  @override
  String get termsModerationHeading => 'Kiểm duyệt nội dung';

  @override
  String get termsModerationBody => 'Bananatalk chủ động kiểm duyệt nội dung người dùng để duy trì môi trường an toàn và tôn trọng. Chúng tôi dùng hệ thống tự động và người kiểm duyệt để xem xét, gỡ bỏ nội dung vi phạm chính sách.';

  @override
  String get termsModerationReport => 'Nếu bạn gặp nội dung phản cảm hoặc hành vi lạm dụng, hãy báo cáo ngay bằng tính năng báo cáo trong ứng dụng. Chúng tôi xem trọng mọi báo cáo và sẽ xử lý nhanh chóng.';

  @override
  String get termsAccountHeading => 'Trách nhiệm với tài khoản';

  @override
  String get termsAccountBody => 'Bạn chịu trách nhiệm bảo mật tài khoản của mình và mọi hoạt động diễn ra trong tài khoản đó. Bạn đồng ý báo cho chúng tôi ngay khi phát hiện việc sử dụng tài khoản trái phép.';

  @override
  String get termsProhibitedHeading => 'Hành vi bị cấm';

  @override
  String get termsProhibitedIntro => 'Ngoài chính sách không khoan nhượng ở trên, bạn đồng ý không:';

  @override
  String get termsProhibitedItem1 => 'Vi phạm bất kỳ luật địa phương, quốc gia hoặc quốc tế hiện hành nào';

  @override
  String get termsProhibitedItem2 => 'Xâm phạm quyền của người khác, kể cả quyền sở hữu trí tuệ';

  @override
  String get termsProhibitedItem3 => 'Phát tán virus, phần mềm độc hại hoặc mã gây hại';

  @override
  String get termsProhibitedItem4 => 'Cố truy cập trái phép vào dịch vụ hoặc tài khoản khác';

  @override
  String get termsProhibitedItem5 => 'Dùng dịch vụ cho mục đích thương mại khi chưa được phép';

  @override
  String get termsTerminationHeading => 'Chấm dứt';

  @override
  String get termsTerminationBody => 'Chúng tôi có quyền tạm ngưng hoặc chấm dứt tài khoản của bạn bất cứ lúc nào, có hoặc không báo trước, với bất kỳ vi phạm nào đối với Điều khoản dịch vụ này, bao gồm nhưng không giới hạn ở việc đăng nội dung phản cảm hoặc có hành vi lạm dụng.';

  @override
  String get termsChangesHeading => 'Thay đổi điều khoản';

  @override
  String get termsChangesBody => 'Chúng tôi có thể cập nhật Điều khoản dịch vụ này theo thời gian. Việc tiếp tục sử dụng dịch vụ sau khi có thay đổi đồng nghĩa bạn chấp nhận các điều khoản đã cập nhật.';

  @override
  String get termsContactHeading => 'Liên hệ';

  @override
  String get termsContactBody => 'Nếu bạn có câu hỏi về Điều khoản dịch vụ này hoặc cần báo cáo vi phạm, vui lòng liên hệ chúng tôi qua các tính năng hỗ trợ trong ứng dụng.';

  @override
  String get termsAgreeCheckbox => 'Tôi đồng ý với Điều khoản dịch vụ và Chính sách không khoan nhượng';

  @override
  String get termsProcessing => 'Đang xử lý...';

  @override
  String get termsAcceptAndContinue => 'Chấp nhận và tiếp tục';

  @override
  String termsLastUpdated(int year) {
    return 'Cập nhật lần cuối: $year';
  }

  @override
  String get wavesFailedToLoad => 'Không tải được lời chào';

  @override
  String get wavesEmptyTitle => 'Chưa có lời chào nào';

  @override
  String get wavesEmptyBody => 'Khi ai đó chào bạn,\nsẽ hiện ở đây';

  @override
  String get wavesWavedAtYou => 'Đã chào bạn';

  @override
  String get lessonYourTranslation => 'Bản dịch của bạn:';

  @override
  String get lessonTapWordsToBuild => 'Chạm vào các từ bên dưới để ghép bản dịch';

  @override
  String get lessonWordBank => 'Kho từ:';

  @override
  String get lessonTypeTranslationHint => 'Nhập bản dịch của bạn ở đây...';

  @override
  String get lessonCorrect => 'Chính xác!';

  @override
  String get lessonIncorrect => 'Sai';

  @override
  String get lessonCheck => 'Kiểm tra';

  @override
  String get lessonTitle => 'Bài học';

  @override
  String get lessonFailedToLoad => 'Không tải được bài học';

  @override
  String get lessonResultCorrect => 'Đúng';

  @override
  String get lessonResultIncorrect => 'Sai';

  @override
  String get lessonDone => 'Xong';

  @override
  String get lessonPraiseExcellent => 'Tuyệt vời!';

  @override
  String get lessonPraiseGreat => 'Làm tốt lắm!';

  @override
  String get lessonPraiseGood => 'Cố gắng tốt!';

  @override
  String get lessonPraiseKeepPracticing => 'Tiếp tục luyện tập!';

  @override
  String get lessonPraiseTryAgain => 'Thử lại nào!';

  @override
  String get lessonExitWarning => 'Tiến độ sẽ không được lưu nếu bạn thoát bây giờ.';

  @override
  String get lessonNotFound => 'Không tìm thấy bài học';

  @override
  String get lessonMayHaveBeenRemoved => 'Bài học này có thể đã bị xoá';

  @override
  String get lessonNoExercises => 'Bài học này chưa có bài tập';

  @override
  String get quizTitle => 'Bài kiểm tra';

  @override
  String get quizFailedToLoad => 'Không tải được bài kiểm tra';

  @override
  String get quizSubmit => 'Nộp';

  @override
  String get quizScore => 'Điểm';

  @override
  String get quizCorrect => 'Đúng';

  @override
  String get quizWrong => 'Sai';

  @override
  String get quizYourLevel => 'Cấp độ của bạn';

  @override
  String get quizPraiseKeepLearning => 'Tiếp tục học nhé!';

  @override
  String get quizExitWarning => 'Bạn sẽ mất tiến độ nếu thoát bây giờ.';

  @override
  String get vocabFailedToLoad => 'Không tải được danh sách ôn tập';

  @override
  String get vocabNoneDue => 'Hiện chưa có từ nào cần ôn';

  @override
  String get vocabGotIt => 'Đã hiểu!';

  @override
  String get vocabTapToReveal => 'Chạm vào thẻ để xem đáp án';

  @override
  String get vocabSessionComplete => 'Hoàn thành phiên học!';

  @override
  String get wavesEmptyBody2 => 'Khi ai đó chào bạn,\nsẽ hiện ở đây';

  @override
  String lessonCorrectAnswer(String answer) {
    return 'Đáp án đúng: $answer';
  }

  @override
  String quizQuestionOfTotal(int current, int total) {
    return 'Câu $current trên $total';
  }

  @override
  String get vocabXpEarned => 'XP nhận được';

  @override
  String get vocabWatchAdBonus => 'Xem quảng cáo nhận +10 XP thưởng';

  @override
  String get vocabBonusEarned => 'Đã nhận +10 XP thưởng! 🎉';

  @override
  String vipBannerIsMember(String userName) {
    return '$userName là thành viên VIP';
  }

  @override
  String get vipBannerGetBenefits => 'Nhận quyền lợi VIP như vậy nhé!';

  @override
  String get vipUpgrade => 'Nâng cấp';

  @override
  String get vipUnlockAllFeatures => 'Mở khoá mọi tính năng';

  @override
  String get chatFailedToLoadUser => 'Không tải được dữ liệu người dùng';

  @override
  String get chatDailyLimitTitle => 'Đã đạt giới hạn trò chuyện mỗi ngày';

  @override
  String get chatUnlimitedTitle => 'Trò chuyện không giới hạn';

  @override
  String get chatUnlimitedBody => 'Trò chuyện với bao nhiêu người tuỳ thích! Thành viên VIP có số cuộc trò chuyện mỗi ngày không giới hạn.';

  @override
  String get coinsStoreUnavailable => 'Mua xu chỉ khả dụng trên iOS và Android.';

  @override
  String get coinsPurchaseCanceled => 'Giao dịch đã bị huỷ hoặc không thể bắt đầu.';

  @override
  String get coinsReceiptUnreadable => 'Không đọc được biên nhận mua hàng. Vui lòng thử lại.';

  @override
  String get coinsAdded => 'Đã cộng xu! 💎';

  @override
  String get coinsVerifyRetry => 'Không xác minh được giao dịch. Hệ thống sẽ tự thử lại — hãy khôi phục giao dịch nếu xu chưa xuất hiện.';

  @override
  String get coinsAlreadyClaimed => 'Hôm nay đã nhận rồi — mai quay lại nhé!';

  @override
  String get coinsDailyClaimed => 'Đã nhận thưởng hằng ngày! +10 💎';

  @override
  String get coinsClaimFailed => 'Không nhận được thưởng hằng ngày.';

  @override
  String get coinsAdThanks => 'Cảm ơn bạn đã xem! +5 💎';

  @override
  String get coinsAdCreditFailed => 'Không cộng được phần thưởng quảng cáo.';

  @override
  String get coinsGetCoins => 'Nhận xu';

  @override
  String get coinsGetCoinsSubtitle => 'Mở khoá ngay thêm lượt dịch, trò chuyện với gia sư và khoảnh khắc.';

  @override
  String get coinsYourBalance => 'Số dư của bạn';

  @override
  String get coinsEarnFree => 'Kiếm xu miễn phí';

  @override
  String get coinsDailyReward => 'Thưởng hằng ngày';

  @override
  String get coinsComeBackTomorrow => 'Mai quay lại';

  @override
  String get coinsDailyRewardSubtitle => '+10 xu, mỗi ngày một lần';

  @override
  String get coinsClaimed => 'Đã nhận';

  @override
  String get coinsClaim => 'Nhận';

  @override
  String get coinsWatchAd => 'Xem quảng cáo';

  @override
  String get coinsAdLimitReached => 'Đã đạt giới hạn hôm nay — mai quay lại';

  @override
  String get exploreTitle => 'Khám phá';

  @override
  String get exploreNoMoments => 'Chưa có khoảnh khắc nào để khám phá';

  @override
  String get exploreFailedToLoad => 'Không tải được';

  @override
  String get exploreNoTrending => 'Chưa có khoảnh khắc nổi bật';

  @override
  String get exploreNoVideos => 'Chưa có video';

  @override
  String get exploreBeFirstVideo => 'Hãy là người đầu tiên chia sẻ video!';

  @override
  String get exploreFailedVideos => 'Không tải được video';

  @override
  String get facebookLoginSubtitle => 'Tiếp tục bằng tài khoản Facebook của bạn\nđể trải nghiệm liền mạch';

  @override
  String get securedByFacebook => 'Được bảo vệ bởi Facebook';

  @override
  String get continueWithEmail => 'Tiếp tục bằng Email';

  @override
  String get continueWithFacebook => 'Tiếp tục bằng Facebook';

  @override
  String get suspendedTitle => 'Tài khoản của bạn đã bị đình chỉ';

  @override
  String get suspendedContact => 'Nếu bạn cho rằng đây là nhầm lẫn, hãy gửi email tới appeal@banatalk.com kèm tên người dùng.';

  @override
  String get suspendedNoAccess => 'Tài khoản của bạn không còn truy cập được.';

  @override
  String get suspendedReason => 'Lý do:';

  @override
  String get correctionSuggestTitle => 'Đề xuất sửa';

  @override
  String get correctionOriginal => 'Bản gốc';

  @override
  String get correctionYours => 'Bản sửa của bạn';

  @override
  String get correctionTypeHint => 'Nhập bản đã sửa...';

  @override
  String get correctionChanges => 'Thay đổi';

  @override
  String get correctionExplanationOptional => 'Giải thích (không bắt buộc)';

  @override
  String get correctionWhyHint => 'Vì sao bạn sửa như vậy?';

  @override
  String get correctionSend => 'Gửi bản sửa';

  @override
  String get correctionSuggested => 'Bản sửa được đề xuất';

  @override
  String get correctionFailedToSend => 'Không gửi được bản sửa';

  @override
  String get ttsUnavailable => 'Không dùng được đọc thành tiếng';

  @override
  String get translationDailyLimitTitle => 'Đã đạt giới hạn dịch mỗi ngày';

  @override
  String get translationDailyLimitBody => 'Người dùng miễn phí được 5 lượt dịch mỗi ngày.\nNâng cấp VIP để dịch không giới hạn!';

  @override
  String get ttsListen => 'Nghe';

  @override
  String correctionOfMessage(String name) {
    return 'Sửa tin nhắn của $name';
  }

  @override
  String translatedToLanguage(String language) {
    return 'Đã dịch sang $language';
  }

  @override
  String guideProgress(int count) {
    return 'Bắt đầu · $count/4';
  }

  @override
  String get guideChatTip => 'Nhấn giữ để dịch hoặc sửa';

  @override
  String get announcementTitle => 'Thông báo';

  @override
  String get announcementUnavailable => 'Thông báo này không còn khả dụng.';

  @override
  String get notifyAnnouncementsTitle => 'Thông báo';

  @override
  String get notifyAnnouncementsSubtitle => 'Tin tức và cập nhật từ đội ngũ BananaTalk';

  @override
  String chatDailyLimitBody(Object count) {
    return 'Người dùng miễn phí có thể trò chuyện với tối đa $count người mỗi ngày.\nNâng cấp lên VIP để trò chuyện không giới hạn!';
  }

  @override
  String get chatCompressingVideo => 'Đang nén video...';

  @override
  String chatShareLocationBody(Object name) {
    return 'Gửi vị trí hiện tại của bạn cho $name. Chỉ làm vậy với những người bạn tin tưởng.';
  }

  @override
  String get chatShareLocationThisChat => 'cuộc trò chuyện này';

  @override
  String get chatTranslationLimitReached => 'Đã đạt giới hạn dịch';

  @override
  String get chatTranslateLimitBody => 'Bạn đã dùng hết lượt dịch miễn phí hôm nay trong cuộc trò chuyện này. Mở khóa thêm ngay bằng xu.';

  @override
  String chatReplyingTo(Object name) {
    return 'Đang trả lời $name';
  }

  @override
  String get chatReplyingToFallback => 'người dùng';

  @override
  String chatSendingMedia(Object mediaType) {
    return 'Đang gửi $mediaType...';
  }

  @override
  String get chatEnterUsernameStart => 'Nhập tên người dùng để bắt đầu trò chuyện';

  @override
  String chatSearching(Object username) {
    return 'Đang tìm @$username...';
  }

  @override
  String chatDeleteConversationBody(Object name) {
    return 'Xóa cuộc trò chuyện của bạn với $name? Không thể hoàn tác thao tác này.';
  }

  @override
  String get chatQrCode => 'Mã QR';

  @override
  String get chatDraft => 'Bản nháp: ';

  @override
  String get chatTyping => 'đang nhập...';

  @override
  String get chatPoweredBy => 'Cung cấp bởi ';

  @override
  String get chatReconnecting => 'Đang kết nối lại với cuộc trò chuyện...';

  @override
  String get chatDailyLimitReached => 'Đã đạt giới hạn tin nhắn hằng ngày';

  @override
  String chatMessagesRemainingToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hôm nay còn $count tin nhắn',
      one: 'Hôm nay còn 1 tin nhắn',
    );
    return '$_temp0';
  }

  @override
  String get chatTranslatePreviewHint => 'Bắt đầu nhập để xem bản dịch';

  @override
  String get chatNoMessagesYet => 'Chưa có tin nhắn nào';

  @override
  String get chatMediaPhoto => 'ảnh';

  @override
  String get chatMediaVideo => 'video';

  @override
  String get chatMediaAudio => 'âm thanh';

  @override
  String get chatMediaFile => 'tệp';

  @override
  String get chatMediaGeneric => 'phương tiện';

  @override
  String get chatMessageFailedToSend => 'Gửi tin nhắn không thành công';

  @override
  String get chatSendingEllipsis => 'Đang gửi...';

  @override
  String get chatFailedTapOptions => 'Thất bại · Nhấn để xem tùy chọn';

  @override
  String get chatMessageWasDeleted => 'Tin nhắn này đã bị xóa';

  @override
  String get chatStory => 'Tin';

  @override
  String get chatHi => 'Chào!';

  @override
  String get chatEdited => 'đã chỉnh sửa';

  @override
  String get chatPremium => 'Cao cấp ✨';

  @override
  String chatUnlockPremiumWallpapers(Object cost) {
    return 'Mở khóa tất cả hình nền Cao cấp ✨ với 💎$cost xu? Thao tác này mở khóa vĩnh viễn toàn bộ gói.';
  }

  @override
  String chatWallpaperForName(Object userName) {
    return 'Hình nền trò chuyện cho $userName';
  }

  @override
  String get chatChooseGallery => 'Chọn từ thư viện';

  @override
  String get chatHiThere => 'Chào bạn! 😊';

  @override
  String chatCorrected(Object correctorName) {
    return '$correctorName đã sửa';
  }

  @override
  String get chatCorrectionAccepted => 'Đã chấp nhận chỉnh sửa ✓';

  @override
  String chatForwarded(Object senderName) {
    return 'Chuyển tiếp từ $senderName';
  }

  @override
  String get chatCached => 'Đã lưu bộ nhớ đệm';

  @override
  String get chatWordBreakdown => 'Phân tích từ';

  @override
  String get chatAlternatives => 'Lựa chọn khác';

  @override
  String chatTranslationAlso(Object items) {
    return 'Cũng có: $items';
  }

  @override
  String get chatAudioUnavailable => 'Âm thanh không khả dụng';

  @override
  String get chatHideTranslation => 'Ẩn bản dịch';

  @override
  String get chatStoryExpired => 'Tin đã hết hạn';

  @override
  String get chatAcceptCorrection => 'Chấp nhận chỉnh sửa';

  @override
  String get chatAccepting => 'Đang chấp nhận…';

  @override
  String get chatSaveToVocabularyAction => 'Lưu vào từ vựng';

  @override
  String momentsMore(Object hidden) {
    return '+$hidden nữa';
  }

  @override
  String get momentsAllow => 'Cho phép';

  @override
  String get momentsCompressed => 'Đã nén';

  @override
  String get momentsPromptDay => 'Chủ đề hôm nay';

  @override
  String get momentsAnswer => 'Trả lời';

  @override
  String get momentsAnswerCamera => '🎥 Trả lời bằng camera';

  @override
  String momentsPracticeWriting(Object langName) {
    return 'Luyện viết bằng $langName';
  }

  @override
  String get momentsReelPolicyBody => 'Reels là các video ngắn học ngôn ngữ — câu trả lời cho chủ đề, luyện nói, giải thích từ người bản xứ và các clip văn hóa.\n\nBananatalk không khoan nhượng với nội dung phản cảm: không khỏa thân, lời lẽ thù ghét, quấy rối, bạo lực hay nội dung bất hợp pháp. Video bị báo cáo sẽ tự động bị ẩn để chờ xem xét sau 2 báo cáo, và vi phạm có thể dẫn đến gỡ nội dung hoặc khóa tài khoản.\n\nBạn có thể báo cáo hoặc chặn từ bất kỳ reel nào vào bất cứ lúc nào.';

  @override
  String get momentsIAgree => 'Tôi đồng ý';

  @override
  String get momentsWhyReportingReel => 'Vì sao bạn báo cáo reel này?';

  @override
  String get momentsNoReelsYet => 'Chưa có reel nào';

  @override
  String get momentsNoReelsBody => 'Hãy là người đầu tiên trả lời chủ đề hôm nay bằng camera, hoặc quay một clip học ngôn ngữ tự do.';

  @override
  String get momentsPullDownRefresh => 'Kéo xuống để làm mới';

  @override
  String get momentsErrorLoadingVideo => 'Lỗi tải video';

  @override
  String get momentsLoadingVideo => 'Đang tải video...';

  @override
  String momentsFileSizeMb(Object size) {
    return '$size MB';
  }

  @override
  String momentsMaxDuration(Object duration) {
    return 'Tối đa $duration';
  }

  @override
  String get momentsReportSubmitted => 'Đã gửi báo cáo';

  @override
  String communityLive(Object count) {
    return '$count trực tiếp';
  }

  @override
  String get communityFind => 'Tìm';

  @override
  String communityFinding(Object username) {
    return 'Đang tìm @$username...';
  }

  @override
  String get communitySeeAll => 'Xem tất cả';

  @override
  String get communitySeeWhoLikes => 'Xem ai thích bạn';

  @override
  String get communityUnlimitedBrowsingNoAds => 'Duyệt không giới hạn, không quảng cáo, ghép đôi ưu tiên';

  @override
  String communityMembersCount(Object count) {
    return '$count thành viên';
  }

  @override
  String communityPeopleCount(Object count) {
    return '$count người';
  }

  @override
  String get communityFailedLoadArchivedWaves => 'Không tải được các lời chào đã lưu trữ';

  @override
  String get communityGreatChat => 'Cuộc trò chuyện tuyệt vời! 🎉';

  @override
  String get communityStayTouchPeopleJust => 'Giữ liên lạc với những người bạn vừa trò chuyện';

  @override
  String get communityNotNow => 'Để sau';

  @override
  String get communityPerfect => 'Hoàn hảo';

  @override
  String communityLv(Object level) {
    return 'Cấp $level';
  }

  @override
  String get communityReact => 'Phản ứng';

  @override
  String get communityWavedAtYou => 'Đã vẫy tay chào bạn';

  @override
  String get communitySomeone => 'Ai đó';

  @override
  String get communityPeopleInterestedInTopic => 'Những người quan tâm đến chủ đề này';

  @override
  String get learnThemedWordSetsBuild => 'Các bộ từ theo chủ đề để xây dựng vốn từ vựng của bạn';

  @override
  String get learnTapStartRecording => 'Chạm để bắt đầu ghi âm';

  @override
  String get learnWordBank => 'Ngân hàng từ';

  @override
  String learnCorrectAnswer(Object correctAnswer) {
    return 'Đáp án đúng: $correctAnswer';
  }

  @override
  String get learnMatchingDataNotAvailable => 'Không có dữ liệu ghép cặp';

  @override
  String get learnExerciseCouldNotLoad => 'Bài tập này không tải được các cặp cần ghép. Vui lòng thử tạo lại bài học.';

  @override
  String get learnSkipExercise => 'Bỏ qua bài tập';

  @override
  String get learnTapItemLeftThen => 'Chạm vào một mục bên trái, rồi chạm vào mục tương ứng bên phải';

  @override
  String learnMatchedOfTotal(Object count, Object count2) {
    return 'Đã ghép $count/$count2';
  }

  @override
  String learnCorrectOfTotal(Object correctCount, Object count) {
    return 'Đúng $correctCount/$count';
  }

  @override
  String get learnDragDropReorderItems => 'Kéo và thả để sắp xếp lại các mục';

  @override
  String learnCorrectOrder(Object order) {
    return 'Thứ tự đúng: $order';
  }

  @override
  String learnWordsToReview(int dueCount) {
    String _temp0 = intl.Intl.pluralLogic(
      dueCount,
      locale: localeName,
      other: '$dueCount từ cần ôn',
    );
    return '$_temp0';
  }

  @override
  String learnScore(Object score) {
    return 'Điểm: $score / 100';
  }

  @override
  String learnGotCorrect(Object correct, Object count) {
    return 'Bạn trả lời đúng $correct trên $count câu.';
  }

  @override
  String learnQuestionOf(Object number, Object total) {
    return 'Câu hỏi $number / $total';
  }

  @override
  String get learnMatchEachWordIts => 'Ghép mỗi từ với nghĩa của nó';

  @override
  String get learnCouldNotLoadPacks => 'Không thể tải các gói';

  @override
  String learnWordsExercises(Object wordCount, Object exerciseCount) {
    return '$wordCount từ · $exerciseCount bài tập';
  }

  @override
  String get learnAiAutoFill => 'Tự động điền bằng AI';

  @override
  String get learnPlay => 'Phát';

  @override
  String get learnFinish => 'Hoàn thành';

  @override
  String get learnNotQuite => 'Chưa đúng.';

  @override
  String get learnUnsupportedExercise => 'Bài tập không được hỗ trợ';

  @override
  String get learnFailedLoadAchievements => 'Không tải được thành tựu';

  @override
  String learnUnlockedOn(Object date) {
    return 'Mở khóa vào $date';
  }

  @override
  String get learnChallenges => 'Thử thách';

  @override
  String get learnFailedLoadChallenges => 'Không tải được thử thách';

  @override
  String learnNoChallenges(Object type) {
    return 'Không có thử thách $type';
  }

  @override
  String get learnCheckBackLater => 'Hãy quay lại sau nhé!';

  @override
  String learnActiveCount(Object count) {
    return 'Đang diễn ra ($count)';
  }

  @override
  String learnCompletedCount(Object count) {
    return 'Đã hoàn thành ($count)';
  }

  @override
  String get learnProgress => 'Tiến độ';

  @override
  String get learnXpReward => 'Thưởng XP';

  @override
  String get learnBonus => 'Thưởng thêm';

  @override
  String learnExpires(Object timeRemainingFormatted) {
    return 'Hết hạn sau $timeRemainingFormatted';
  }

  @override
  String get learnAchievementUnlocked => 'Đã mở khóa thành tựu!';

  @override
  String get learnTapContinue => 'Chạm để tiếp tục';

  @override
  String get learnChallengeCompleted => 'Đã hoàn thành';

  @override
  String get learnDailyGoals => 'Mục tiêu hằng ngày';

  @override
  String learnLessons(Object completedCount, Object lessonsCount) {
    return '$completedCount/$lessonsCount bài học';
  }

  @override
  String learnLongestDays(Object longestStreak) {
    return 'Dài nhất: $longestStreak ngày';
  }

  @override
  String get learnTapReveal => 'Chạm để xem';

  @override
  String get learnNoAchievements => 'Chưa có thành tựu';

  @override
  String get learnDayStreak => 'Chuỗi ngày';

  @override
  String get learnDueForReview => 'Đến hạn ôn tập';

  @override
  String learnNextReview(Object date) {
    return 'Tiếp theo: $date';
  }

  @override
  String get learnChallengeDaily => 'Hằng ngày';

  @override
  String get learnChallengeWeekly => 'Hằng tuần';

  @override
  String get learnChallengeSpecial => 'Đặc biệt';

  @override
  String get learnChallengeDailyDesc => 'Hoàn thành thử thách mỗi ngày để nhận XP và phần thưởng!';

  @override
  String get learnChallengeWeeklyDesc => 'Thử thách hằng tuần làm mới vào mỗi thứ Hai';

  @override
  String get learnChallengeSpecialDesc => 'Thử thách giới hạn thời gian với phần thưởng thêm!';

  @override
  String get learnDateToday => 'Hôm nay';

  @override
  String get learnDateTomorrow => 'Ngày mai';

  @override
  String learnInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sau $count ngày',
    );
    return '$_temp0';
  }

  @override
  String learnInWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sau $count tuần',
    );
    return '$_temp0';
  }

  @override
  String learnInMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sau $count tháng',
    );
    return '$_temp0';
  }

  @override
  String get aiGenerateNewQuiz => 'Tạo bài đố mới';

  @override
  String get aiPreviousQuizzes => 'Các bài đố trước';

  @override
  String get aiGeneratingQuiz => 'Đang tạo bài đố của bạn…';

  @override
  String aiFocusArea(Object name) {
    return 'Lĩnh vực trọng tâm: $name';
  }

  @override
  String get aiQuizType => 'Loại bài đố';

  @override
  String get aiDifficulty => 'Độ khó';

  @override
  String get aiQuestionsLabel => 'Số câu hỏi:';

  @override
  String get aiGenerateQuiz => 'Tạo bài đố';

  @override
  String aiQuizQuestionCount(int questionCount) {
    String _temp0 = intl.Intl.pluralLogic(
      questionCount,
      locale: localeName,
      other: '$questionCount câu hỏi',
      one: '1 câu hỏi',
    );
    return '$_temp0';
  }

  @override
  String aiCorrectOfTotal(Object correctCount, Object totalQuestions) {
    return 'Đúng $correctCount/$totalQuestions';
  }

  @override
  String get aiNoQuizzesYet => 'Chưa có bài đố nào';

  @override
  String get aiGenerateFirstQuizAbove => 'Hãy tạo bài đố đầu tiên của bạn ở trên!';

  @override
  String aiCorrectOutOf(Object correctCount, Object totalQuestions) {
    return 'Đúng $correctCount trên $totalQuestions';
  }

  @override
  String get aiBackQuizHub => 'Quay lại trung tâm bài đố';

  @override
  String get aiNoQuestionsAvailable => 'Không có câu hỏi nào';

  @override
  String get aiQuizHasNoQuestions => 'Bài đố này không có câu hỏi nào để hiển thị.';

  @override
  String aiQuestionOf(Object number, Object count) {
    return 'Câu hỏi $number trên $count';
  }

  @override
  String get aiYourAnswerLabel => 'Câu trả lời của bạn:';

  @override
  String get aiBonusXpWatching => '🎉 +10 XP thưởng khi xem!';

  @override
  String get aiNotQuiteRight => 'Chưa đúng lắm';

  @override
  String get aiWhy => 'Tại sao?';

  @override
  String get aiGotIt => 'Đã hiểu';

  @override
  String get aiHint => 'Gợi ý';

  @override
  String aiLevel(Object hintLevel) {
    return 'Mức $hintLevel/3';
  }

  @override
  String get aiAskQuestion => 'Đặt câu hỏi';

  @override
  String get aiAsk => 'Hỏi';

  @override
  String get aiAssistantExamples => 'Ví dụ';

  @override
  String get aiExplainConcept => 'Giải thích khái niệm';

  @override
  String get aiRelatedConcepts => 'Khái niệm liên quan';

  @override
  String get aiGeneratingLessonSummary => 'Đang tạo bản tóm tắt bài học của bạn...';

  @override
  String get aiLessonSummary => 'Tóm tắt bài học';

  @override
  String get aiKeyPoints => 'Điểm chính';

  @override
  String get aiVocabularyRemember => 'Từ vựng cần nhớ';

  @override
  String get aiGrammarRules => 'Quy tắc ngữ pháp';

  @override
  String get aiWhatPracticeNext => 'Nên luyện tập gì tiếp theo';

  @override
  String get aiPerfectScore => 'Điểm tuyệt đối!';

  @override
  String get aiGreatJob => 'Làm tốt lắm!';

  @override
  String get aiGoodEffort => 'Cố gắng tốt lắm!';

  @override
  String get aiKeepPracticing => 'Hãy tiếp tục luyện tập!';

  @override
  String get aiFailedToGetHint => 'Không thể lấy gợi ý';

  @override
  String get aiFailedToGetAnswer => 'Không thể lấy câu trả lời';

  @override
  String get aiFailedToExplain => 'Không thể giải thích';

  @override
  String get aiFailedLoadHistory => 'Không tải được lịch sử';

  @override
  String aiConversationMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tin nhắn',
    );
    return '$_temp0';
  }

  @override
  String get aiStartNewConversationSee => 'Bắt đầu cuộc trò chuyện mới để xem tại đây';

  @override
  String get aiLoadingMessages => 'Đang tải tin nhắn...';

  @override
  String get aiNoMessagesConversation => 'Không có tin nhắn nào trong cuộc trò chuyện này';

  @override
  String get aiDifficultyLevel => 'Mức độ khó';

  @override
  String get aiScenarios => 'Tình huống';

  @override
  String get aiGrammarCheck => 'Kiểm tra ngữ pháp';

  @override
  String get aiRecentAnalysis => 'Phân tích gần đây';

  @override
  String get aiCheckGrammar => 'Kiểm tra ngữ pháp';

  @override
  String get aiLanguageLabel => 'Ngôn ngữ:';

  @override
  String aiGrammarIssuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tìm thấy $count lỗi',
    );
    return '$_temp0';
  }

  @override
  String get aiPerfect => 'Hoàn hảo!';

  @override
  String get aiNoGrammarIssuesFound => 'Không tìm thấy lỗi ngữ pháp nào trong văn bản của bạn.';

  @override
  String aiIssuesFound(Object count) {
    return 'Lỗi được tìm thấy ($count)';
  }

  @override
  String get aiCorrected => 'Đã sửa';

  @override
  String get aiGrammarExamples => 'Ví dụ:';

  @override
  String get aiImprovedSuggestions => 'Gợi ý cải thiện';

  @override
  String get aiNoAnalysisHistoryYet => 'Chưa có lịch sử phân tích';

  @override
  String get aiLessonBuilder => 'Trình tạo bài học AI';

  @override
  String get aiGenerateCustomLessons => 'Tạo bài học tùy chỉnh';

  @override
  String get aiCreatesPersonalizedLessonsAny => 'AI tạo bài học cá nhân hóa về mọi chủ đề';

  @override
  String aiExercises(Object exerciseCount) {
    return 'Bài tập: $exerciseCount';
  }

  @override
  String get aiSuggestedTopics => 'Chủ đề gợi ý';

  @override
  String get aiCreatingLesson => 'Đang tạo bài học của bạn...';

  @override
  String get aiGeneratingExercisesContent => 'AI đang tạo bài tập và nội dung';

  @override
  String get aiLessonGenerated => 'Đã tạo bài học!';

  @override
  String get aiGenerateAnother => 'Tạo bài khác';

  @override
  String get aiStartLesson => 'Bắt đầu bài học';

  @override
  String get aiPronunciationPractice => 'Luyện phát âm';

  @override
  String get aiPracticeHistory => 'Lịch sử luyện tập';

  @override
  String get aiTextPractice => 'Văn bản để luyện tập';

  @override
  String get aiWordAnalysis => 'Phân tích từ';

  @override
  String get aiNoPracticeHistoryYet => 'Chưa có lịch sử luyện tập';

  @override
  String get aiSmartTranslation => 'Dịch thông minh';

  @override
  String get aiWordBreakdown => 'Phân tích từng từ';

  @override
  String get aiAlternativeTranslations => 'Các bản dịch khác';

  @override
  String get aiGrammarNotes => 'Ghi chú ngữ pháp';

  @override
  String get aiIdiomsExpressions => 'Thành ngữ & cách diễn đạt';

  @override
  String aiLiteral(Object literalTranslation) {
    return 'Nghĩa đen: $literalTranslation';
  }

  @override
  String aiMeaning(Object meaning) {
    return 'Ý nghĩa: $meaning';
  }

  @override
  String aiEquivalent(Object equivalentIdiom) {
    return 'Tương đương: $equivalentIdiom';
  }

  @override
  String get aiCulturalContext => 'Bối cảnh văn hóa';

  @override
  String get aiNoCompletedConversations => 'Không có cuộc trò chuyện đã hoàn thành';

  @override
  String get aiNoActiveConversations => 'Không có cuộc trò chuyện đang hoạt động';

  @override
  String aiStartInLanguage(Object language) {
    return 'Bắt đầu bằng $language';
  }

  @override
  String get aiSelect => 'Chọn';

  @override
  String aiIssuesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lỗi',
    );
    return '$_temp0';
  }

  @override
  String get aiGenerateLesson => 'Tạo bài học';

  @override
  String get aiGeneratingEllipsis => 'Đang tạo...';

  @override
  String get aiAnalyzing => 'Đang phân tích...';

  @override
  String get aiExcellentPronunciation => 'Phát âm xuất sắc!';

  @override
  String get aiGoodJob => 'Làm tốt lắm!';

  @override
  String get profileBuyMeCoffee => 'Mời tôi một ly cà phê';

  @override
  String get profileOr => 'hoặc';

  @override
  String get profileLoadingNotifications => 'Đang tải thông báo...';

  @override
  String get profileLoadingSettings => 'Đang tải cài đặt...';

  @override
  String get profileAdmin => 'QUẢN TRỊ';

  @override
  String get profileSelected => 'ĐÃ CHỌN';

  @override
  String get profilePrivacyIntro => 'Bạn kiểm soát những gì người khác có thể thấy. Tắt các mục để ẩn chúng khỏi hồ sơ công khai của bạn.';

  @override
  String get profileUpdate => 'Cập nhật';

  @override
  String get profileNoTopicsCategory => 'Không có chủ đề nào trong danh mục này';

  @override
  String get profileAdminTools => 'Công cụ quản trị';

  @override
  String profileCompletionAdd(Object items) {
    return 'Thêm: $items';
  }

  @override
  String get profileActive => 'ĐANG HOẠT ĐỘNG';

  @override
  String get profileAutoSaveEnabled => 'Đã bật tự động lưu';

  @override
  String get profileChangesSavedInstantlyWhen => 'Thay đổi được lưu ngay khi bạn bật hoặc tắt.';

  @override
  String get profileCurrentTheme => 'Giao diện hiện tại';

  @override
  String get profileThemeChangesApplyInstantly => 'Thay đổi giao diện được áp dụng ngay trên toàn bộ ứng dụng.';

  @override
  String get profileLoadingVisitors => 'Đang tải người truy cập...';

  @override
  String get profileSeeWhoChecked => 'Xem ai đã xem hồ sơ của bạn';

  @override
  String get profileRecentVisitors => 'Người truy cập gần đây';

  @override
  String get profileNoReportsSubmitted => 'Chưa gửi báo cáo nào';

  @override
  String get profileReportsSubmitWillAppear => 'Các báo cáo bạn gửi sẽ xuất hiện ở đây';

  @override
  String profileReportTypeTitle(Object type) {
    return 'Báo cáo $type';
  }

  @override
  String profileReportReason(Object reason) {
    return 'Lý do: $reason';
  }

  @override
  String get profileDeleteAccountFinalBody => 'Toàn bộ dữ liệu của bạn sẽ bị xóa vĩnh viễn.\n\nBạn có hoàn toàn chắc chắn không?';

  @override
  String get profileThanksForWatching => 'Cảm ơn bạn đã xem! 🙏';

  @override
  String get profileNotificationsOn => 'Thông báo đang bật';

  @override
  String get profileNotificationsOff => 'Thông báo đang tắt';

  @override
  String get profileMaximumReached => 'Đã đạt mức tối đa';

  @override
  String get profilePickYourInterests => 'Chọn sở thích của bạn';

  @override
  String get profileDeselectToChooseAnother => 'Bỏ chọn một mục để chọn mục khác';

  @override
  String get profileTapTopicsMatchVibe => 'Chạm vào các chủ đề hợp với bạn';

  @override
  String get profileEnjoyingPremium => 'Đang tận hưởng các tính năng cao cấp';

  @override
  String get profileUnlockUnlimited => 'Mở khóa tin nhắn không giới hạn và công cụ AI';

  @override
  String get profileBirthYear => 'Năm sinh';

  @override
  String get profileReportTypeUser => 'Người dùng';

  @override
  String get profileReportTypeMoment => 'Khoảnh khắc';

  @override
  String get profileReportTypeComment => 'Bình luận';

  @override
  String get profileReportTypeMessage => 'Tin nhắn';

  @override
  String get profileReportTypeStory => 'Story';

  @override
  String get profileReportReasonCopyright => 'Bản quyền';

  @override
  String get storyOptimizingBestExperience => 'Đang tối ưu hóa để có trải nghiệm tốt nhất';

  @override
  String get storyCreate => 'Tạo tin';

  @override
  String get storyAddTags => 'Thêm thẻ';

  @override
  String get storyVideoSelected => 'Đã chọn video';

  @override
  String get storyAddPoll => 'Thêm bình chọn';

  @override
  String get storyOptions => 'Tùy chọn';

  @override
  String get storyAddQuestion => 'Thêm câu hỏi';

  @override
  String get storyPrompt => 'Gợi ý';

  @override
  String get storyTapAnywhereAddText => 'Chạm vào bất kỳ đâu để thêm văn bản';

  @override
  String storyHighlightStoryCount(int storyCount) {
    String _temp0 = intl.Intl.pluralLogic(
      storyCount,
      locale: localeName,
      other: '$storyCount tin',
    );
    return '$_temp0';
  }

  @override
  String get storySendFriends => 'Gửi cho bạn bè';

  @override
  String storySelected(Object count) {
    return 'Đã chọn $count';
  }

  @override
  String get storyShareSave => 'Chia sẻ/Lưu';

  @override
  String storySeenBy(Object viewCount) {
    return '$viewCount người đã xem';
  }

  @override
  String get storyNoViewsYet => 'Chưa có lượt xem';

  @override
  String get storyEditVideo => 'Chỉnh sửa video';

  @override
  String storyVotes(Object totalVotes) {
    return '$totalVotes phiếu';
  }

  @override
  String get storyCreatePoll => 'Tạo bình chọn';

  @override
  String get storySendAnonymously => 'Gửi ẩn danh';

  @override
  String storyResponseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phản hồi',
    );
    return '$_temp0';
  }

  @override
  String get storyViewResponses => 'Xem phản hồi';

  @override
  String get storyResponsesTitle => 'Phản hồi';

  @override
  String get storyNoResponsesYet => 'Chưa có phản hồi';

  @override
  String get storyQuestionBox => 'Hộp câu hỏi';

  @override
  String get storySent => 'Đã gửi!';

  @override
  String get storyProcessing => 'Đang xử lý...';

  @override
  String get storyHd => 'HD';

  @override
  String storyVideoMeta(Object duration, Object size) {
    return '$duration | $size MB';
  }

  @override
  String get storyUserFallback => 'Người dùng';

  @override
  String storySendCount(int count) {
    return 'Gửi ($count)';
  }

  @override
  String get storyFailedToDelete => 'Không thể xóa tin';

  @override
  String get storyAnonymous => 'Ẩn danh';

  @override
  String get vipNoCoinActivityYet => 'Chưa có hoạt động xu nào';

  @override
  String get vipCoinShopExplainer => 'Xu được dùng để mở khóa thêm lượt dùng bản dịch, trò chuyện với gia sư AI và khoảnh khắc khi bạn đạt giới hạn miễn phí hằng ngày. Các giao dịch mua không được hoàn lại sau khi xu đã được sử dụng.';

  @override
  String get vipLimitReached => 'Đã đạt giới hạn';

  @override
  String get vipCoins => 'xu';

  @override
  String vipBonusIncluded(Object bonusCoins) {
    return 'Đã gồm +$bonusCoins xu thưởng';
  }

  @override
  String get vipVisitorModeLimitReached => 'Đã đạt giới hạn của Chế độ khách';

  @override
  String get vipWhatGetFreeAccount => 'Bạn nhận được gì với tài khoản miễn phí';

  @override
  String get vipCreateFreeAccount => 'Tạo tài khoản miễn phí';

  @override
  String get vipGoUnlimitedAccess => 'Lên VIP để truy cập không giới hạn';

  @override
  String get vipContinueAsVisitor => 'Tiếp tục với tư cách khách';

  @override
  String vipResets(Object resetTime) {
    return 'Đặt lại lúc: $resetTime';
  }

  @override
  String vipUsedToday(Object currentUsage, Object maxAllowed) {
    return 'Hôm nay đã dùng $currentUsage / $maxAllowed';
  }

  @override
  String get vipTierVisitor => 'Khách';

  @override
  String get vipTierMember => 'Thành viên';

  @override
  String get vipAd => 'Quảng cáo';

  @override
  String get promoAdsNoticeTitle => 'Lời nhắn từ nhà phát triển';

  @override
  String get promoAdsNoticeBody => 'Xin chào! Mình là Firdavs, nhà phát triển duy nhất đứng sau Bananatalk. Mình đã thêm một vài quảng cáo nhỏ vào ứng dụng để giúp ứng dụng luôn miễn phí và có kinh phí phát triển lâu dài.\n\nMình biết quảng cáo có thể gây phiền — nên mình đã làm cho chúng tùy chọn và có thưởng. Xem một quảng cáo để mở khóa thêm tin nhắn, bộ lọc cộng đồng, XP thưởng sau bài kiểm tra và nhiều hơn nữa.\n\nCảm ơn bạn đã dùng Bananatalk. Sự ủng hộ của bạn có ý nghĩa rất lớn với mình. 🙏';

  @override
  String get promoAdsNoticeGotIt => 'Đã hiểu, cảm ơn! 👍';

  @override
  String get vipOnly => 'Chỉ dành cho VIP';

  @override
  String get vipTapUpgrade => 'Chạm để nâng cấp';

  @override
  String get vipUnlockFeatures => 'Mở khóa tính năng VIP';

  @override
  String get vipUpPillUp => 'Lên';

  @override
  String get vipChooseOption => 'Chọn một tùy chọn:';

  @override
  String get promoWelcomeBackTitle => 'Chào mừng bạn trở lại! 👋';

  @override
  String get promoWelcomeBackBody => 'Chúng mình nhớ bạn. Đây là những gì đang chờ bạn:';

  @override
  String get promoWelcomeBackCta => 'Bắt đầu thôi! 🚀';

  @override
  String get vipCoinsPerAdInfo => '+5 xu mỗi quảng cáo, tối đa 5 lần mỗi ngày';

  @override
  String get vipUpgradeUnlockMore => 'Nâng cấp để mở khóa thêm tính năng và truy cập không giới hạn';

  @override
  String get vipUpgradeNow => 'Nâng cấp ngay';

  @override
  String get commonContinueWhereLeftOff => 'Tiếp tục từ chỗ bạn đã dừng?';

  @override
  String get commonLanguageNotProvided => 'Chưa cung cấp ngôn ngữ';

  @override
  String get commonExamNotProvided => 'Chưa cung cấp bài thi';

  @override
  String get commonMuted => 'Đã tắt tiếng';

  @override
  String get commonPoorConnection => 'Kết nối kém';

  @override
  String commonBlockUserConfirmBody(Object targetUserName) {
    return 'Bạn có chắc muốn chặn $targetUserName không?\n\nBạn sẽ không còn thấy tin nhắn và bài đăng của họ, và hai bên sẽ không xuất hiện trong kết quả tìm kiếm của nhau.';
  }

  @override
  String get commonVideoFile => 'Tệp video';

  @override
  String get commonPointCameraBananatalkQr => 'Hướng camera vào mã QR Bananatalk';

  @override
  String get commonReportSubmittedButSome => 'Đã gửi báo cáo, nhưng một số bằng chứng tải lên không thành công';

  @override
  String commonReportTitle(Object typeLabel) {
    return 'Báo cáo $typeLabel';
  }

  @override
  String commonWhyReporting(Object typeLabel) {
    return 'Tại sao bạn báo cáo $typeLabel này?';
  }

  @override
  String get commonAddEvidenceRequired => 'Thêm bằng chứng (bắt buộc)';

  @override
  String get commonUploadScreenshotsTextFiles => 'Tải lên ảnh chụp màn hình hoặc tệp văn bản để hỗ trợ báo cáo của bạn';

  @override
  String commonAddEvidenceCount(Object count, Object maxFiles) {
    return 'Thêm bằng chứng ($count/$maxFiles)';
  }

  @override
  String commonReportTotalSize(Object max, Object used) {
    return 'Tổng: $used / $max';
  }

  @override
  String get commonEvidence => 'Bằng chứng';

  @override
  String get commonImageFailed => 'Ảnh bị lỗi';

  @override
  String get commonShowMore => 'Xem thêm';

  @override
  String get commonVoiceRecordingNotAvailable => 'Không thể ghi âm';

  @override
  String get commonVoiceRecordingOnlyAvailable => 'Ghi âm chỉ khả dụng trên thiết bị di động.';

  @override
  String get commonReportSubmittedSuccessfully => 'Đã gửi báo cáo thành công';

  @override
  String get commonErrorLoadingFile => 'Lỗi khi tải tệp';

  @override
  String get commonReportTypeUser => 'người dùng';

  @override
  String get commonReportTypeMoment => 'khoảnh khắc';

  @override
  String get commonReportTypeComment => 'bình luận';

  @override
  String get commonReportTypeMessage => 'tin nhắn';

  @override
  String get commonReportTypeStory => 'story';

  @override
  String get commonReportTypeContent => 'nội dung';

  @override
  String get commonReportReasonCopyright => 'Vi phạm bản quyền';

  @override
  String get momentsRemoveVoiceNote => 'Xóa ghi chú thoại';

  @override
  String get vocabPackLevelProficiency => 'Thành thạo';

  @override
  String get aiFailedToLoadFeedback => 'Không thể tải phản hồi';

  @override
  String get aiFailedToLoadSummary => 'Không thể tải bản tóm tắt';

  @override
  String get momentFailedToLoad => 'Không thể tải khoảnh khắc';

  @override
  String get aiPronunciationWatchAdRetry => 'Xem quảng cáo để có thêm một lượt thử miễn phí';

  @override
  String aiErrorLoadingLanguages(Object error) {
    return 'Lỗi khi tải ngôn ngữ: $error';
  }

  @override
  String get aiSelectSourceTargetLanguages => 'Vui lòng chọn ngôn ngữ nguồn và ngôn ngữ đích';

  @override
  String get aiUnexpectedResponseFormat => 'Định dạng phản hồi không mong đợi';

  @override
  String get aiFailedToLoadConversation => 'Không thể tải cuộc trò chuyện';

  @override
  String get aiMicPermissionDeniedSettings => 'Quyền micrô bị từ chối. Vui lòng bật trong Cài đặt.';

  @override
  String get aiFailedToEvaluatePronunciation => 'Không thể đánh giá phát âm';

  @override
  String get aiFailedToGenerateSpeech => 'Không thể tạo giọng nói';

  @override
  String get aiFailedToGenerateLesson => 'Không thể tạo bài học';

  @override
  String get aiLessonTopicRequired => 'Vui lòng nhập chủ đề';

  @override
  String get aiFailedToLoadTopics => 'Không thể tải các chủ đề';

  @override
  String get aiFailedToLoadScenarios => 'Không thể tải các tình huống';

  @override
  String get aiAnalysisFailed => 'Phân tích thất bại';

  @override
  String get storySearchPlaceHint => 'Tìm một địa điểm…';

  @override
  String get storySearchRecentChatsHint => 'Tìm trong các cuộc trò chuyện gần đây…';

  @override
  String get storySearchFollowingHint => 'Tìm người bạn theo dõi…';

  @override
  String get storyAddHashtagsHint => 'Thêm hashtag...';

  @override
  String get storyHighlightCreateFailed => 'Không thể tạo mục nổi bật';

  @override
  String get storyHighlightRenameFailed => 'Không thể đổi tên mục nổi bật';

  @override
  String get storyHighlightDeleteFailed => 'Không thể xóa mục nổi bật';

  @override
  String get storyViewersLoadFailed => 'Không thể tải danh sách người xem';

  @override
  String get storyShareSent => 'Đã gửi 💛';

  @override
  String storyShareSentPartial(Object names) {
    return 'Đã gửi 💛 — thất bại với $names';
  }

  @override
  String get storyVoteFailed => 'Không thể gửi phiếu bầu';

  @override
  String get storyAnswerFailed => 'Không thể gửi câu trả lời';

  @override
  String get storyAlreadyInHighlight => 'Đã lưu vào một mục nổi bật';

  @override
  String get storyAddedToHighlight => 'Đã thêm vào mục nổi bật';

  @override
  String storyMaxHashtags(int max) {
    return 'Bạn có thể thêm tối đa $max hashtag';
  }

  @override
  String storyMaxMentions(int max) {
    return 'Bạn có thể nhắc đến tối đa $max người';
  }

  @override
  String get coinHistoryActivity => 'Hoạt động xu';

  @override
  String get coinHistoryAdReward => 'Đã xem quảng cáo';

  @override
  String get coinHistoryPurchase => 'Mua xu';

  @override
  String coinHistoryUnlocked(Object feature) {
    return 'Đã mở khóa $feature';
  }

  @override
  String get vipVisitorMessagesBenefit => 'Gửi tối đa 50 tin nhắn mỗi ngày';

  @override
  String get vipVisitorProfilesBenefit => 'Xem tối đa 100 hồ sơ mỗi ngày';

  @override
  String get vipVisitorFriendsBenefit => 'Kết bạn và mở rộng mạng lưới của bạn';

  @override
  String get vipVisitorCommunitiesTitle => 'Tham gia cộng đồng';

  @override
  String get vipVisitorCommunitiesBenefit => 'Tham gia thảo luận cộng đồng';

  @override
  String get vipVisitorMomentsTitle => 'Chia sẻ khoảnh khắc';

  @override
  String get vipVisitorMomentsBenefit => 'Đăng và chia sẻ khoảnh khắc của bạn';

  @override
  String get vipUnlimitedEverythingTitle => 'Mọi thứ không giới hạn';

  @override
  String get vipUnlimitedEverythingBenefit => 'Không giới hạn hằng ngày về tin nhắn hoặc lượt xem hồ sơ';

  @override
  String get vipProfileBoostBenefit => 'Hiển thị nhiều hơn trong kết quả tìm kiếm';

  @override
  String get vipAdFreeExperienceBenefit => 'Tận hưởng ứng dụng không có quảng cáo';

  @override
  String get featureGateUpgradeToUnlock => 'Nâng cấp để mở khóa tính năng này';

  @override
  String get featureGateVipOnly => 'Tính năng chỉ dành cho VIP';

  @override
  String get adsRewardedButtonLabel => 'Xem quảng cáo để nhận thưởng';

  @override
  String get promoAdsPerkMessages => '+3 tin nhắn\nthưởng';

  @override
  String get promoAdsPerkFilters => 'Mở khóa\nbộ lọc';

  @override
  String get promoAdsPerkXp => '+10 XP\nthưởng';

  @override
  String get promoAdsPerkRetry => 'Thử lại\nmiễn phí';

  @override
  String get visitorLimitMessagesTitle => 'Đã đạt giới hạn tin nhắn hằng ngày';

  @override
  String visitorLimitMessagesBody(int count) {
    return 'Hôm nay bạn đã gửi $count tin nhắn. Nâng cấp để gửi thêm!';
  }

  @override
  String get visitorLimitProfilesTitle => 'Đã đạt giới hạn lượt xem hồ sơ hằng ngày';

  @override
  String visitorLimitProfilesBody(int count) {
    return 'Hôm nay bạn đã xem $count hồ sơ. Nâng cấp để xem thêm!';
  }

  @override
  String get visitorLimitFreeAccountBenefit => 'Giới hạn hằng ngày cao hơn';

  @override
  String get visitorLimitVipBenefit => 'Truy cập không giới hạn';

  @override
  String get promoWelcomeBackTutorSubtitle => 'Luyện hội thoại, phát âm và câu đố';

  @override
  String get promoWelcomeBackCommunitySubtitle => 'Tìm bạn học ngôn ngữ gần bạn';

  @override
  String get promoWelcomeBackMomentsSubtitle => 'Chia sẻ hành trình học ngôn ngữ của bạn';

  @override
  String get myReportsReportedId => 'ID bị báo cáo';

  @override
  String get myReportsReason => 'Lý do';

  @override
  String get myReportsSubmitted => 'Đã gửi';

  @override
  String get myReportsResolved => 'Đã giải quyết';

  @override
  String get myReportsModeratorNotes => 'Ghi chú của người kiểm duyệt';

  @override
  String get myReportsNotAvailable => 'Không có';

  @override
  String get myReportsFailedToLoad => 'Không thể tải các báo cáo';

  @override
  String get voiceRecorderUnavailableDesktop => 'Ghi âm giọng nói không khả dụng trên máy tính';

  @override
  String get adminPageUnavailable => 'Trang này không khả dụng.';

  @override
  String storyShareSendFailedTo(Object names) {
    return 'Không thể gửi tới $names';
  }

  @override
  String get storyCantReact => 'Bạn không thể thả cảm xúc cho tin này';

  @override
  String get storyCantReply => 'Bạn không thể trả lời tin này';

  @override
  String get storyNoMediaToSave => 'Tin này không có phương tiện để lưu';

  @override
  String get coinsAdCrediting => 'Đang cộng…';

  @override
  String get coinsWatchAdReward => 'Xem quảng cáo (+5 💎)';

  @override
  String callUnavailable(String name) {
    return '$name hiện không nhận cuộc gọi';
  }

  @override
  String get callDeclineWithMessage => 'Nhắn tin';

  @override
  String get callDeclineSheetTitle => 'Từ chối kèm tin nhắn';

  @override
  String get callDeclineCannedLater => 'Mình chưa nói chuyện được. Mình sẽ gọi lại.';

  @override
  String get callDeclineCannedText => 'Mình chưa nói chuyện được. Nhắn tin cho mình nhé?';

  @override
  String get callDeclineCustomHint => 'Viết tin nhắn…';

  @override
  String get callDeclineSend => 'Gửi';

  @override
  String get callBackAction => 'Gọi lại';

  @override
  String get callMessageAction => 'Nhắn tin';

  @override
  String get callsAllowTitle => 'Cho phép cuộc gọi';

  @override
  String get callsAllowSubtitle => 'Khi tắt, cuộc gọi đến bạn sẽ không đổ chuông. Người gọi sẽ thấy bạn không nhận cuộc gọi.';

  @override
  String get callsQuietHoursNote => 'Khi tắt “Cho phép thông báo khẩn cấp”, cuộc gọi cũng bị giữ lại trong giờ yên tĩnh.';

  @override
  String get callTurnOnCamera => 'Camera';

  @override
  String get callCameraFailed => 'Không thể bật camera';

  @override
  String get callSelfViewLabel => 'Camera của bạn. Kéo để di chuyển.';

  @override
  String get callSelfViewSwapHint => 'Chạm hai lần để đổi chỗ với video còn lại';
}
