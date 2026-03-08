// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'BananaTalk';

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
  String get aboutBanaTalk => 'Về BanaTalk';

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
  String get banaTalk => 'BanaTalk';

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
  String get deletingYourAccountWillPermanentlyRemove => 'Deleting your account will permanently remove:\n\n• Your profile and all personal data\n• All your messages and conversations\n• All your moments and stories\n• Your VIP subscription (no refund)\n• All your connections and followers\n\nThis action cannot be undone.';

  @override
  String get clearAllNotifications => 'Xóa tất cả thông báo?';

  @override
  String get clearAll => 'Xóa tất cả';

  @override
  String get notificationDebug => 'Notification Debug';

  @override
  String get markAllRead => 'Đánh dấu tất cả đã đọc';

  @override
  String get clearAll2 => 'Clear all';

  @override
  String get emailAddress => 'Địa chỉ email';

  @override
  String get username => 'Tên người dùng';

  @override
  String get alreadyHaveAnAccount => 'Đã có tài khoản?';

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
  String get couldNotOpenLink => 'Không thể mở liên kết';

  @override
  String get legalPrivacy2 => 'Legal & Privacy';

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
  String get receiveEmailNotificationsFromBananaTalk => 'Nhận thông báo email từ BananaTalk';

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
  String get whenSomeoneFollowsYou2 => 'When someone follows you';

  @override
  String get securityAlerts => 'Cảnh báo bảo mật';

  @override
  String get passwordLoginAlerts => 'Cảnh báo mật khẩu và đăng nhập';

  @override
  String get unblockUser2 => 'Unblock User';

  @override
  String get blockedUsers2 => 'Blocked Users';

  @override
  String get finalWarning => 'Cảnh báo cuối cùng';

  @override
  String get deleteForever => 'Xóa vĩnh viễn';

  @override
  String get deleteAccount2 => 'Delete Account';

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
  String get reply2 => 'Reply...';

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
  String get myReports2 => 'My Reports';

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
  String get reportUser2 => 'Report User';

  @override
  String get submitReport => 'Gửi báo cáo';

  @override
  String get addAQuestionAndAtLeast2Options => 'Add a question and at least 2 options';

  @override
  String get addOption => 'Thêm tùy chọn';

  @override
  String get anonymousVoting => 'Bỏ phiếu ẩn danh';

  @override
  String get create => 'Tạo';

  @override
  String get typeYourAnswer => 'Nhập câu trả lời của bạn...';

  @override
  String get send2 => 'Send';

  @override
  String get yourPrompt => 'Gợi ý của bạn...';

  @override
  String get add2 => 'Add';

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
  String get manageSubscriptionInSettings => 'To cancel your subscription, go to Settings > [Your Name] > Subscriptions on your device.';

  @override
  String get contactSupportToCancel => 'To cancel your subscription, please contact our support team.';

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
  String get pleaseRemoveImagesFirstToAddVideo => 'Please remove images first to add a video';

  @override
  String get unsupportedFormat => 'Unsupported format';

  @override
  String get errorProcessingVideo => 'Error processing video';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'Please remove images first to record a video';

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
  String get failedToQueueUpload => 'Failed to queue upload';

  @override
  String get viewProfile => 'Xem hồ sơ';

  @override
  String get mediaLinksAndDocs => 'Media, liên kết và tài liệu';

  @override
  String get wallpaper => 'Hình nền';

  @override
  String get userIdNotAvailable => 'User ID not available';

  @override
  String get cannotBlockYourself => 'Cannot block yourself';

  @override
  String get chatWallpaper => 'Hình nền chat';

  @override
  String get wallpaperSavedLocally => 'Đã lưu hình nền cục bộ';

  @override
  String get messageCopied => 'Đã sao chép tin nhắn';

  @override
  String get forwardFeatureComingSoon => 'Forward feature coming soon';

  @override
  String get momentUnsaved => 'Moment unsaved';

  @override
  String get documentPickerComingSoon => 'Document picker coming soon';

  @override
  String get contactSharingComingSoon => 'Contact sharing coming soon';

  @override
  String get featureComingSoon => 'Tính năng sắp ra mắt';

  @override
  String get answerSent => 'Đã gửi câu trả lời!';

  @override
  String get noImagesAvailable => 'Không có ảnh';

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
  String get linkCopied => 'Đã sao chép liên kết!';

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
  String get correctionSent => 'Đã gửi sửa lỗi!';

  @override
  String get sort => 'Sắp xếp';

  @override
  String get savedMoments => 'Khoảnh khắc đã lưu';

  @override
  String get unsave => 'Bỏ lưu';

  @override
  String get playingAudio => 'Playing audio...';

  @override
  String get failedToGenerateQuiz => 'Failed to generate quiz';

  @override
  String get failedToAddComment => 'Failed to add comment';

  @override
  String get hello => 'Xin chào!';

  @override
  String get howAreYou => 'Bạn khỏe không?';

  @override
  String get cannotOpen => 'Cannot open';

  @override
  String get errorOpeningLink => 'Error opening link';

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
  String get unableToLoadMoments => 'Unable to load moments';

  @override
  String get map => 'Bản đồ';

  @override
  String get mapUnavailable => 'Map unavailable';

  @override
  String get location => 'Vị trí';

  @override
  String get unknownLocation => 'Unknown location';

  @override
  String get noImagesAvailable2 => 'No images available';

  @override
  String get permissionsRequired => 'Permissions Required';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get refresh => 'Làm mới';

  @override
  String get videoCall => 'Video';

  @override
  String get voiceCall => 'Gọi';

  @override
  String get message => 'Nhắn tin';

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
  String get youFollowed => 'Bạn đã theo dõi';

  @override
  String get youUnfollowed => 'Bạn đã bỏ theo dõi';

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
  String get typing => 'đang nhập';

  @override
  String get connecting => 'Đang kết nối...';

  @override
  String daysAgo(int count) {
    return '${count}ng trước';
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
  String get closeFriends => 'Bạn thân';

  @override
  String get addFriends => 'Add Friends';

  @override
  String get highlights => 'Highlights';

  @override
  String get createHighlight => 'Tạo Highlight';

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
  String get yourStory => 'Story của bạn';

  @override
  String get sendMessage => 'Gửi tin nhắn';

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
  String get photo => 'Ảnh';

  @override
  String get record => 'Ghi';

  @override
  String get addSticker => 'Add Sticker';

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
  String get whoCanSeeThis => 'Who can see this?';

  @override
  String get everyone => 'Mọi người';

  @override
  String get anyoneCanSeeStory => 'Anyone can see this story';

  @override
  String get friendsOnly => 'Chỉ bạn bè';

  @override
  String get onlyFollowersCanSee => 'Only your followers can see';

  @override
  String get onlyCloseFriendsCanSee => 'Only your close friends can see';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get fontStyle => 'Font Style';

  @override
  String get normal => 'Bình thường';

  @override
  String get bold => 'Đậm';

  @override
  String get italic => 'Nghiêng';

  @override
  String get handwriting => 'Handwriting';

  @override
  String get addLocation => 'Thêm vị trí';

  @override
  String get enterLocationName => 'Enter location name';

  @override
  String get addLink => 'Thêm liên kết';

  @override
  String get buttonText => 'Button text';

  @override
  String get learnMore => 'Tìm hiểu thêm';

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
  String get oneHour => '1 giờ';

  @override
  String get eightHours => '8 giờ';

  @override
  String get oneWeek => '1 tuần';

  @override
  String get always => 'Luôn luôn';

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
  String get voiceMessage => 'Tin nhắn thoại';

  @override
  String get document => 'Tài liệu';

  @override
  String get attachment => 'Đính kèm';

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
  String get preview => 'Xem trước';

  @override
  String get wallpaperUpdated => 'Wallpaper updated';

  @override
  String get category => 'Danh mục';

  @override
  String get mood => 'Tâm trạng';

  @override
  String get sortBy => 'Sắp xếp theo';

  @override
  String get timePeriod => 'Time Period';

  @override
  String get searchLanguages => 'Search languages...';

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
  String get noInternetConnection => 'Không có kết nối internet';

  @override
  String get tryAgainLater => 'Vui lòng thử lại sau';

  @override
  String get messageSent => 'Đã gửi tin nhắn';

  @override
  String get messageDeleted => 'Đã xóa tin nhắn';

  @override
  String get messageEdited => 'Đã sửa tin nhắn';
}
