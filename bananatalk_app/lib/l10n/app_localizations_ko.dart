// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'BananaTalk';

  @override
  String get login => '로그인';

  @override
  String get signUp => '회원가입';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get or => '또는';

  @override
  String get signInWithGoogle => 'Google로 로그인';

  @override
  String get signInWithApple => 'Apple로 로그인';

  @override
  String get signInWithFacebook => 'Facebook으로 로그인';

  @override
  String get welcome => '환영합니다';

  @override
  String get home => '홈';

  @override
  String get messages => '메시지';

  @override
  String get moments => '모멘트';

  @override
  String get profile => '프로필';

  @override
  String get settings => '설정';

  @override
  String get logout => '로그아웃';

  @override
  String get language => '언어';

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get autoTranslate => '자동 번역';

  @override
  String get autoTranslateMessages => '메시지 자동 번역';

  @override
  String get autoTranslateMoments => '모멘트 자동 번역';

  @override
  String get autoTranslateComments => '댓글 자동 번역';

  @override
  String get translate => '번역';

  @override
  String get translated => '번역됨';

  @override
  String get showOriginal => '원문 보기';

  @override
  String get showTranslation => '번역 보기';

  @override
  String get translating => '번역 중...';

  @override
  String get translationFailed => '번역 실패';

  @override
  String get noTranslationAvailable => '번역을 사용할 수 없습니다';

  @override
  String translatedFrom(String language) {
    return '$language에서 번역됨';
  }

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get edit => '편집';

  @override
  String get share => '공유';

  @override
  String get like => '좋아요';

  @override
  String get comment => '댓글';

  @override
  String get send => '보내기';

  @override
  String get search => '검색';

  @override
  String get notifications => '알림';

  @override
  String get followers => '팔로워';

  @override
  String get following => '팔로잉';

  @override
  String get posts => '게시물';

  @override
  String get visitors => '방문자';

  @override
  String get loading => '로딩 중...';

  @override
  String get error => '오류';

  @override
  String get success => '성공';

  @override
  String get tryAgain => '다시 시도';

  @override
  String get networkError => '네트워크 오류입니다. 연결을 확인하세요.';

  @override
  String get somethingWentWrong => '문제가 발생했습니다';

  @override
  String get ok => '확인';

  @override
  String get yes => '예';

  @override
  String get no => '아니오';

  @override
  String get languageSettings => '언어 설정';

  @override
  String get deviceLanguage => '기기 언어';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return '현재 기기 언어: $flag $name';
  }

  @override
  String get youCanOverride => '아래에서 앱 언어를 변경할 수 있습니다.';

  @override
  String languageChangedTo(String name) {
    return '언어가 $name로 변경되었습니다';
  }

  @override
  String get errorChangingLanguage => '언어 변경 중 오류 발생';

  @override
  String get autoTranslateSettings => '자동 번역 설정';

  @override
  String get automaticallyTranslateIncomingMessages => '받은 메시지 자동 번역';

  @override
  String get automaticallyTranslateMomentsInFeed => '피드의 모멘트 자동 번역';

  @override
  String get automaticallyTranslateComments => '댓글 자동 번역';

  @override
  String get translationServiceBeingConfigured => '번역 서비스가 구성 중입니다. 나중에 다시 시도해 주세요.';

  @override
  String get translationUnavailable => '번역을 사용할 수 없습니다';

  @override
  String get showLess => '간략히 보기';

  @override
  String get showMore => '더 보기';

  @override
  String get comments => '댓글';

  @override
  String get beTheFirstToComment => '첫 번째 댓글을 작성하세요.';

  @override
  String get writeAComment => '댓글 작성...';

  @override
  String get report => '신고';

  @override
  String get reportMoment => '모멘트 신고';

  @override
  String get reportUser => '사용자 신고';

  @override
  String get deleteMoment => '모멘트를 삭제하시겠습니까?';

  @override
  String get thisActionCannotBeUndone => '이 작업은 취소할 수 없습니다.';

  @override
  String get momentDeleted => '모멘트가 삭제되었습니다';

  @override
  String get editFeatureComingSoon => '편집 기능이 곧 제공됩니다';

  @override
  String get userNotFound => '사용자를 찾을 수 없습니다';

  @override
  String get cannotReportYourOwnComment => '자신의 댓글은 신고할 수 없습니다';

  @override
  String get profileSettings => '프로필 설정';

  @override
  String get editYourProfileInformation => '프로필 정보 편집';

  @override
  String get blockedUsers => '차단된 사용자';

  @override
  String get manageBlockedUsers => '차단된 사용자 관리';

  @override
  String get manageNotificationSettings => '알림 설정 관리';

  @override
  String get privacySecurity => '개인정보 보호 및 보안';

  @override
  String get controlYourPrivacy => '개인정보 보호 제어';

  @override
  String get changeAppLanguage => '앱 언어 변경';

  @override
  String get appearance => '화면';

  @override
  String get themeAndDisplaySettings => '테마 및 화면 설정';

  @override
  String get myReports => '내 신고';

  @override
  String get viewYourSubmittedReports => '제출한 신고 보기';

  @override
  String get reportsManagement => '신고 관리';

  @override
  String get manageAllReportsAdmin => '모든 신고 관리 (관리자)';

  @override
  String get legalPrivacy => '법률 및 개인정보 보호';

  @override
  String get termsPrivacySubscriptionInfo => '약관, 개인정보 보호 및 구독 정보';

  @override
  String get helpCenter => '고객센터';

  @override
  String get getHelpAndSupport => '도움말 및 지원 받기';

  @override
  String get aboutBanaTalk => 'BanaTalk 정보';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get permanentlyDeleteYourAccount => '계정을 영구적으로 삭제';

  @override
  String get loggedOutSuccessfully => '성공적으로 로그아웃되었습니다';

  @override
  String get retry => '다시 시도';

  @override
  String get giftsLikes => '선물/좋아요';

  @override
  String get details => '세부정보';

  @override
  String get to => '로';

  @override
  String get banaTalk => 'BanaTalk';

  @override
  String get community => '커뮤니티';

  @override
  String get editProfile => '프로필 편집';

  @override
  String yearsOld(String age) {
    return '$age세';
  }

  @override
  String get searchConversations => '대화 검색...';

  @override
  String get visitorTrackingNotAvailable => '방문자 추적 기능이 아직 사용할 수 없습니다. 백엔드 업데이트가 필요합니다.';

  @override
  String get chatList => '채팅 목록';

  @override
  String get languageExchange => '언어 교환';

  @override
  String get nativeLanguage => '모국어';

  @override
  String get learning => '학습';

  @override
  String get notSet => '설정 안 됨';

  @override
  String get about => '정보';

  @override
  String get aboutMe => '자기소개';

  @override
  String get bloodType => '혈액형';

  @override
  String get photos => '사진';

  @override
  String get camera => '카메라';

  @override
  String get createMoment => '모멘트 만들기';

  @override
  String get addATitle => '제목 추가...';

  @override
  String get whatsOnYourMind => '무슨 생각을 하고 있나요?';

  @override
  String get addTags => '태그 추가';

  @override
  String get done => '완료';

  @override
  String get add => '추가';

  @override
  String get enterTag => '태그 입력';

  @override
  String get post => '게시';

  @override
  String get commentAddedSuccessfully => '댓글이 성공적으로 추가되었습니다';

  @override
  String get clearFilters => '필터 지우기';

  @override
  String get notificationSettings => '알림 설정';

  @override
  String get enableNotifications => '알림 사용';

  @override
  String get turnAllNotificationsOnOrOff => '모든 알림 켜기 또는 끄기';

  @override
  String get notificationTypes => '알림 유형';

  @override
  String get chatMessages => '채팅 메시지';

  @override
  String get getNotifiedWhenYouReceiveMessages => '메시지를 받을 때 알림 받기';

  @override
  String get likesAndCommentsOnYourMoments => '모멘트에 대한 좋아요 및 댓글';

  @override
  String get whenPeopleYouFollowPostMoments => '팔로우하는 사람이 모멘트를 게시할 때';

  @override
  String get friendRequests => '친구 요청';

  @override
  String get whenSomeoneFollowsYou => '누군가 당신을 팔로우할 때';

  @override
  String get profileVisits => '프로필 방문';

  @override
  String get whenSomeoneViewsYourProfileVIP => '누군가 내 프로필을 볼 때 (VIP)';

  @override
  String get marketing => '마케팅';

  @override
  String get updatesAndPromotionalMessages => '업데이트 및 프로모션 메시지';

  @override
  String get notificationPreferences => '알림 환경설정';

  @override
  String get sound => '소리';

  @override
  String get playNotificationSounds => '알림 소리 재생';

  @override
  String get vibration => '진동';

  @override
  String get vibrateOnNotifications => '알림 시 진동';

  @override
  String get showPreview => '미리보기 표시';

  @override
  String get showMessagePreviewInNotifications => '알림에 메시지 미리보기 표시';

  @override
  String get mutedConversations => '음소거된 대화';

  @override
  String get conversation => '대화';

  @override
  String get unmute => '음소거 해제';

  @override
  String get systemNotificationSettings => '시스템 알림 설정';

  @override
  String get manageNotificationsInSystemSettings => '시스템 설정에서 알림 관리';

  @override
  String get errorLoadingSettings => '설정 로드 중 오류';

  @override
  String get unblockUser => '차단 해제';

  @override
  String get unblock => '차단 해제';

  @override
  String get goBack => '돌아가기';

  @override
  String get messageSendTimeout => '메시지 전송 시간 초과. 연결을 확인하세요.';

  @override
  String get failedToSendMessage => '메시지 전송 실패';

  @override
  String get dailyMessageLimitExceeded => '일일 메시지 한도 초과. 무제한 메시지를 위해 VIP로 업그레이드하세요.';

  @override
  String get cannotSendMessageUserMayBeBlocked => '메시지를 보낼 수 없습니다. 사용자가 차단되었을 수 있습니다.';

  @override
  String get sessionExpired => '세션이 만료되었습니다. 다시 로그인하세요.';

  @override
  String get sendThisSticker => '이 스티커를 보내시겠습니까?';

  @override
  String get chooseHowYouWantToDeleteThisMessage => '이 메시지를 삭제하는 방법을 선택하세요:';

  @override
  String get deleteForEveryone => '모두에게 삭제';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => '나와 상대방 모두에게서 메시지가 삭제됩니다';

  @override
  String get deleteForMe => '나에게만 삭제';

  @override
  String get removesTheMessageOnlyFromYourChat => '내 채팅에서만 메시지가 삭제됩니다';

  @override
  String get copy => '복사';

  @override
  String get reply => '답장';

  @override
  String get forward => '전달';

  @override
  String get moreOptions => '더 많은 옵션';

  @override
  String get noUsersAvailableToForwardTo => '전달할 사용자가 없습니다';

  @override
  String get searchMoments => '모멘트 검색...';

  @override
  String searchInChatWith(String name) {
    return '$name과(와)의 채팅에서 검색';
  }

  @override
  String get typeAMessage => '메시지 입력...';

  @override
  String get enterYourMessage => '메시지 입력';

  @override
  String get detectYourLocation => '위치 확인';

  @override
  String get tapToUpdateLocation => '탭하여 위치 업데이트';

  @override
  String get helpOthersFindYouNearby => '주변 사람들이 나를 찾을 수 있어요';

  @override
  String get selectYourNativeLanguage => '모국어 선택';

  @override
  String get whichLanguageDoYouWantToLearn => '어떤 언어를 배우고 싶으신가요?';

  @override
  String get selectYourGender => '성별 선택';

  @override
  String get addACaption => '캡션 추가...';

  @override
  String get typeSomething => '무언가 입력...';

  @override
  String get gallery => '갤러리';

  @override
  String get video => '비디오';

  @override
  String get text => '텍스트';

  @override
  String get provideMoreInformation => '추가 정보 제공...';

  @override
  String get searchByNameLanguageOrInterests => '이름, 언어 또는 관심사로 검색...';

  @override
  String get addTagAndPressEnter => '태그를 추가하고 Enter를 누르세요';

  @override
  String replyTo(String name) {
    return '$name에게 답장...';
  }

  @override
  String get highlightName => '하이라이트 이름';

  @override
  String get searchCloseFriends => '친한 친구 검색...';

  @override
  String get askAQuestion => '질문하기...';

  @override
  String option(String number) {
    return '옵션 $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return '이 $type을(를) 신고하는 이유는 무엇입니까?';
  }

  @override
  String get additionalDetailsOptional => '추가 세부 정보 (선택 사항)';

  @override
  String get warningThisActionIsPermanent => '경고: 이 작업은 영구적입니다!';

  @override
  String get deletingYourAccountWillPermanentlyRemove => '계정을 삭제하면 다음 항목이 영구적으로 삭제됩니다:\n\n• 프로필 및 모든 개인 정보\n• 모든 메시지와 대화\n• 모든 모멘트와 스토리\n• VIP 구독 (환불 불가)\n• 모든 팔로워와 팔로잉\n\n이 작업은 되돌릴 수 없습니다.';

  @override
  String get clearAllNotifications => '모든 알림을 지우시겠습니까?';

  @override
  String get clearAll => '모두 지우기';

  @override
  String get notificationDebug => '알림 디버그';

  @override
  String get markAllRead => '모두 읽음으로 표시';

  @override
  String get clearAll2 => '모두 지우기';

  @override
  String get emailAddress => '이메일 주소';

  @override
  String get username => '사용자 이름';

  @override
  String get alreadyHaveAnAccount => '이미 계정이 있으신가요?';

  @override
  String get login2 => '로그인';

  @override
  String get selectYourNativeLanguage2 => '모국어 선택';

  @override
  String get whichLanguageDoYouWantToLearn2 => '어떤 언어를 배우고 싶으신가요?';

  @override
  String get selectYourGender2 => '성별 선택';

  @override
  String get dateFormat => 'YYYY.MM.DD';

  @override
  String get detectYourLocation2 => '위치 확인';

  @override
  String get tapToUpdateLocation2 => '탭하여 위치 업데이트';

  @override
  String get helpOthersFindYouNearby2 => '주변 사람들이 나를 찾을 수 있어요';

  @override
  String get couldNotOpenLink => '링크를 열 수 없습니다';

  @override
  String get legalPrivacy2 => '법률 및 개인정보';

  @override
  String get termsOfUseEULA => '이용 약관 (EULA)';

  @override
  String get viewOurTermsAndConditions => '약관 및 조건 보기';

  @override
  String get privacyPolicy => '개인정보 보호정책';

  @override
  String get howWeHandleYourData => '데이터 처리 방법';

  @override
  String get emailNotifications => '이메일 알림';

  @override
  String get receiveEmailNotificationsFromBananaTalk => 'BananaTalk에서 이메일 알림 받기';

  @override
  String get weeklySummary => '주간 요약';

  @override
  String get activityRecapEverySunday => '매주 일요일 활동 요약';

  @override
  String get newMessages => '새 메시지';

  @override
  String get whenYoureAwayFor24PlusHours => '24시간 이상 자리를 비울 때';

  @override
  String get newFollowers => '새 팔로워';

  @override
  String get whenSomeoneFollowsYou2 => '누군가 당신을 팔로우할 때';

  @override
  String get securityAlerts => '보안 알림';

  @override
  String get passwordLoginAlerts => '비밀번호 및 로그인 알림';

  @override
  String get unblockUser2 => '사용자 차단 해제';

  @override
  String get blockedUsers2 => '차단된 사용자';

  @override
  String get finalWarning => '⚠️ 최종 경고';

  @override
  String get deleteForever => '영구 삭제';

  @override
  String get deleteAccount2 => '계정 삭제';

  @override
  String get enterYourPassword => '비밀번호를 입력하세요';

  @override
  String get yourPassword => '비밀번호';

  @override
  String get typeDELETEToConfirm => '확인하려면 DELETE 입력';

  @override
  String get typeDELETEInCapitalLetters => '대문자로 DELETE 입력';

  @override
  String sent(String emoji) {
    return '전송됨!';
  }

  @override
  String get replySent => '답장 전송됨!';

  @override
  String get deleteStory => '스토리를 삭제하시겠습니까?';

  @override
  String get thisStoryWillBeRemovedPermanently => '이 스토리는 영구적으로 제거됩니다.';

  @override
  String get noStories => '스토리 없음';

  @override
  String views(String count) {
    return '$count 조회';
  }

  @override
  String get reportStory => '스토리 신고';

  @override
  String get reply2 => '답장...';

  @override
  String get failedToPickImage => '이미지 선택 실패';

  @override
  String get failedToTakePhoto => '사진 촬영 실패';

  @override
  String get failedToPickVideo => '비디오 선택 실패';

  @override
  String get pleaseEnterSomeText => '텍스트를 입력하세요';

  @override
  String get pleaseSelectMedia => '미디어를 선택하세요';

  @override
  String get storyPosted => '스토리 게시됨!';

  @override
  String get textOnlyStoriesRequireAnImage => '텍스트 전용 스토리는 이미지가 필요합니다';

  @override
  String get createStory => '스토리 만들기';

  @override
  String get change => '변경';

  @override
  String get userIdNotFound => '사용자 ID를 찾을 수 없습니다. 다시 로그인하세요.';

  @override
  String get pleaseSelectAPaymentMethod => '결제 방법을 선택하세요';

  @override
  String get startExploring => '탐색 시작';

  @override
  String get close => '닫기';

  @override
  String get payment => '결제';

  @override
  String get upgradeToVIP => 'VIP로 업그레이드';

  @override
  String get errorLoadingProducts => '제품 로드 중 오류';

  @override
  String get cancelVIPSubscription => 'VIP 구독 취소';

  @override
  String get keepVIP => 'VIP 유지';

  @override
  String get cancelSubscription => '구독 취소';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'VIP 구독이 성공적으로 취소되었습니다';

  @override
  String get vipStatus => 'VIP 상태';

  @override
  String get noActiveVIPSubscription => '활성 VIP 구독 없음';

  @override
  String get subscriptionExpired => '구독 만료됨';

  @override
  String get vipExpiredMessage => 'VIP 구독이 만료되었습니다. 지금 갱신하여 무제한 기능을 계속 이용하세요!';

  @override
  String get expiredOn => '만료일';

  @override
  String get renewVIP => 'VIP 갱신';

  @override
  String get whatYoureMissing => '놓치고 있는 혜택';

  @override
  String get manageInAppStore => '앱스토어에서 관리';

  @override
  String get becomeVIP => 'VIP 되기';

  @override
  String get unlimitedMessages => '무제한 메시지';

  @override
  String get unlimitedProfileViews => '무제한 프로필 조회';

  @override
  String get prioritySupport => '우선 지원';

  @override
  String get advancedSearch => '고급 검색';

  @override
  String get profileBoost => '프로필 부스트';

  @override
  String get adFreeExperience => '광고 없는 경험';

  @override
  String get upgradeYourAccount => '계정 업그레이드';

  @override
  String get moreMessages => '더 많은 메시지';

  @override
  String get moreProfileViews => '더 많은 프로필 조회';

  @override
  String get connectWithFriends => '친구와 연결';

  @override
  String get reviewStarted => '검토 시작됨';

  @override
  String get reportResolved => '신고 해결됨';

  @override
  String get reportDismissed => '신고 기각됨';

  @override
  String get selectAction => '작업 선택';

  @override
  String get noViolation => '위반 없음';

  @override
  String get contentRemoved => '콘텐츠 제거됨';

  @override
  String get userWarned => '사용자 경고됨';

  @override
  String get userSuspended => '사용자 일시 정지됨';

  @override
  String get userBanned => '사용자 차단됨';

  @override
  String get addNotesOptional => '메모 추가 (선택 사항)';

  @override
  String get enterModeratorNotes => '관리자 메모 입력...';

  @override
  String get skip => '건너뛰기';

  @override
  String get startReview => '검토 시작';

  @override
  String get resolve => '해결';

  @override
  String get dismiss => '기각';

  @override
  String get filterReports => '신고 필터링';

  @override
  String get all => '전체';

  @override
  String get clear => '지우기';

  @override
  String get apply => '적용';

  @override
  String get myReports2 => '내 신고';

  @override
  String get blockUser => '사용자 차단';

  @override
  String get block => '차단';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => '이 사용자도 차단하시겠습니까?';

  @override
  String get noThanks => '아니요, 괜찮습니다';

  @override
  String get yesBlockThem => '예, 차단합니다';

  @override
  String get reportUser2 => '사용자 신고';

  @override
  String get submitReport => '신고 제출';

  @override
  String get addAQuestionAndAtLeast2Options => '질문과 최소 2개의 옵션 추가';

  @override
  String get addOption => '옵션 추가';

  @override
  String get anonymousVoting => '익명 투표';

  @override
  String get create => '만들기';

  @override
  String get typeYourAnswer => '답변 입력...';

  @override
  String get send2 => '보내기';

  @override
  String get yourPrompt => '내용을 입력하세요...';

  @override
  String get add2 => '추가';

  @override
  String get contentNotAvailable => '콘텐츠를 사용할 수 없음';

  @override
  String get profileNotAvailable => '프로필을 사용할 수 없음';

  @override
  String get noMomentsToShow => '표시할 모멘트 없음';

  @override
  String get storiesNotAvailable => '스토리를 사용할 수 없음';

  @override
  String get cantMessageThisUser => '이 사용자에게 메시지를 보낼 수 없음';

  @override
  String get pleaseSelectAReason => '이유를 선택하세요';

  @override
  String get reportSubmitted => '신고가 제출되었습니다. 커뮤니티를 안전하게 유지하는 데 도움을 주셔서 감사합니다.';

  @override
  String get youHaveAlreadyReportedThisMoment => '이미 이 모멘트를 신고하셨습니다';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => '이를 신고하는 이유에 대해 더 자세히 알려주세요';

  @override
  String get errorSharing => '공유 중 오류';

  @override
  String get deviceInfo => '장치 정보';

  @override
  String get recommended => '추천';

  @override
  String get anyLanguage => '모든 언어';

  @override
  String get noLanguagesFound => '언어를 찾을 수 없습니다';

  @override
  String get selectALanguage => '언어 선택';

  @override
  String get languagesAreStillLoading => '언어를 불러오는 중...';

  @override
  String get selectNativeLanguage => '모국어 선택';

  @override
  String get subscriptionDetails => '구독 상세정보';

  @override
  String get activeFeatures => '활성 기능';

  @override
  String get legalInformation => '법적 정보';

  @override
  String get termsOfUse => '이용 약관';

  @override
  String get manageSubscription => '구독 관리';

  @override
  String get manageSubscriptionInSettings => '구독을 취소하려면 기기의 설정 > [사용자 이름] > 구독으로 이동하세요.';

  @override
  String get contactSupportToCancel => '구독을 취소하려면 지원팀에 문의하세요.';

  @override
  String get status => '상태';

  @override
  String get active => '활성';

  @override
  String get plan => '플랜';

  @override
  String get startDate => '시작 날짜';

  @override
  String get endDate => '종료 날짜';

  @override
  String get nextBillingDate => '다음 결제 날짜';

  @override
  String get autoRenew => '자동 갱신';

  @override
  String get pleaseLogInToContinue => '계속하려면 로그인하세요';

  @override
  String get purchaseCanceledOrFailed => '구매가 취소되었거나 실패했습니다. 다시 시도해주세요.';

  @override
  String get maximumTagsAllowed => '최대 5개의 태그만 허용됩니다';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => '비디오를 추가하려면 먼저 이미지를 제거하세요';

  @override
  String get unsupportedFormat => '지원되지 않는 형식';

  @override
  String get errorProcessingVideo => '비디오 처리 중 오류';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => '비디오를 녹화하려면 먼저 이미지를 제거하세요';

  @override
  String get locationAdded => '위치가 추가되었습니다';

  @override
  String get failedToGetLocation => '위치를 가져오지 못했습니다';

  @override
  String get notNow => '나중에';

  @override
  String get videoUploadFailed => '비디오 업로드 실패';

  @override
  String get skipVideo => '비디오 건너뛰기';

  @override
  String get retryUpload => '다시 업로드';

  @override
  String get momentCreatedSuccessfully => '모멘트가 성공적으로 생성되었습니다';

  @override
  String get uploadingMomentInBackground => '백그라운드에서 모멘트 업로드 중...';

  @override
  String get failedToQueueUpload => '업로드 대기열에 추가하지 못했습니다';

  @override
  String get viewProfile => '프로필 보기';

  @override
  String get mediaLinksAndDocs => '미디어, 링크 및 문서';

  @override
  String get wallpaper => '배경화면';

  @override
  String get userIdNotAvailable => '사용자 ID를 사용할 수 없습니다';

  @override
  String get cannotBlockYourself => '자신을 차단할 수 없습니다';

  @override
  String get chatWallpaper => '채팅 배경화면';

  @override
  String get wallpaperSavedLocally => '배경화면이 로컬에 저장되었습니다';

  @override
  String get messageCopied => '메시지가 복사되었습니다';

  @override
  String get forwardFeatureComingSoon => '전달 기능이 곧 제공됩니다';

  @override
  String get momentUnsaved => '모멘트 저장 취소됨';

  @override
  String get documentPickerComingSoon => '문서 선택기가 곧 제공됩니다';

  @override
  String get contactSharingComingSoon => '연락처 공유가 곧 제공됩니다';

  @override
  String get featureComingSoon => '기능이 곧 제공됩니다';

  @override
  String get answerSent => '답변이 전송되었습니다!';

  @override
  String get noImagesAvailable => '사용 가능한 이미지가 없습니다';

  @override
  String get mentionPickerComingSoon => '멘션 선택기가 곧 제공됩니다';

  @override
  String get musicPickerComingSoon => '음악 선택기가 곧 제공됩니다';

  @override
  String get repostFeatureComingSoon => '재게시 기능이 곧 제공됩니다';

  @override
  String get addFriendsFromYourProfile => '프로필에서 친구 추가';

  @override
  String get quickReplyAdded => '빠른 답장이 추가되었습니다';

  @override
  String get quickReplyDeleted => '빠른 답장이 삭제되었습니다';

  @override
  String get linkCopied => '링크가 복사되었습니다!';

  @override
  String get maximumOptionsAllowed => '최대 10개의 옵션만 허용됩니다';

  @override
  String get minimumOptionsRequired => '최소 2개의 옵션이 필요합니다';

  @override
  String get pleaseEnterAQuestion => '질문을 입력하세요';

  @override
  String get pleaseAddAtLeast2Options => '최소 2개의 옵션을 추가하세요';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => '퀴즈의 정답을 선택하세요';

  @override
  String get correctionSent => '수정이 전송되었습니다!';

  @override
  String get sort => '정렬';

  @override
  String get savedMoments => '저장된 모멘트';

  @override
  String get unsave => '저장 취소';

  @override
  String get playingAudio => '오디오 재생 중...';

  @override
  String get failedToGenerateQuiz => '퀴즈 생성 실패';

  @override
  String get failedToAddComment => '댓글 추가 실패';

  @override
  String get hello => '안녕하세요!';

  @override
  String get howAreYou => '어떻게 지내세요?';

  @override
  String get cannotOpen => '열 수 없음';

  @override
  String get errorOpeningLink => '링크를 여는 중 오류 발생';

  @override
  String get saved => '저장됨';

  @override
  String get follow => '팔로우';

  @override
  String get unfollow => '언팔로우';

  @override
  String get mute => '음소거';

  @override
  String get online => '온라인';

  @override
  String get offline => '오프라인';

  @override
  String get lastSeen => '마지막 접속';

  @override
  String get justNow => '방금';

  @override
  String minutesAgo(String count) {
    return '$count분 전';
  }

  @override
  String hoursAgo(String count) {
    return '$count시간 전';
  }

  @override
  String get yesterday => '어제';

  @override
  String get signInWithEmail => '이메일로 로그인';

  @override
  String get partners => '파트너';

  @override
  String get nearby => '주변';

  @override
  String get topics => '토픽';

  @override
  String get waves => '인사';

  @override
  String get voiceRooms => '보이스';

  @override
  String get filters => '필터';

  @override
  String get searchCommunity => '이름, 언어 또는 관심사로 검색...';

  @override
  String get bio => '소개';

  @override
  String get noBioYet => '아직 소개글이 없습니다.';

  @override
  String get languages => '언어';

  @override
  String get native => '모국어';

  @override
  String get interests => '관심사';

  @override
  String get noMomentsYet => '아직 모멘트가 없습니다';

  @override
  String get unableToLoadMoments => '모멘트를 불러올 수 없습니다';

  @override
  String get map => '지도';

  @override
  String get mapUnavailable => '지도를 사용할 수 없습니다';

  @override
  String get location => '위치';

  @override
  String get unknownLocation => '알 수 없는 위치';

  @override
  String get noImagesAvailable2 => '이미지가 없습니다';

  @override
  String get permissionsRequired => '권한 필요';

  @override
  String get openSettings => '설정 열기';

  @override
  String get refresh => '새로고침';

  @override
  String get videoCall => '영상통화';

  @override
  String get voiceCall => '음성통화';

  @override
  String get message => '메시지';

  @override
  String get pleaseLoginToFollow => '팔로우하려면 로그인하세요';

  @override
  String get pleaseLoginToCall => '전화하려면 로그인하세요';

  @override
  String get cannotCallYourself => '자신에게 전화할 수 없습니다';

  @override
  String get failedToFollowUser => '팔로우에 실패했습니다';

  @override
  String get failedToUnfollowUser => '언팔로우에 실패했습니다';

  @override
  String get areYouSureUnfollow => '이 사용자를 언팔로우하시겠습니까?';

  @override
  String get areYouSureUnblock => '이 사용자의 차단을 해제하시겠습니까?';

  @override
  String get youFollowed => '팔로우했습니다';

  @override
  String get youUnfollowed => '언팔로우했습니다';

  @override
  String get alreadyFollowing => '이미 팔로우 중입니다';

  @override
  String get soon => '곧';

  @override
  String comingSoon(String feature) {
    return '$feature 곧 출시됩니다!';
  }

  @override
  String get muteNotifications => '알림 음소거';

  @override
  String get unmuteNotifications => '알림 켜기';

  @override
  String get operationCompleted => '작업 완료';

  @override
  String get couldNotOpenMaps => '지도를 열 수 없습니다';

  @override
  String hasntSharedMoments(Object name) {
    return '$name님이 아직 순간을 공유하지 않았습니다';
  }

  @override
  String messageUser(String name) {
    return '$name에게 메시지';
  }

  @override
  String notFollowingUser(String name) {
    return '$name님을 팔로우하고 있지 않았습니다';
  }

  @override
  String youFollowedUser(String name) {
    return '$name님을 팔로우했습니다';
  }

  @override
  String youUnfollowedUser(String name) {
    return '$name님을 언팔로우했습니다';
  }

  @override
  String unfollowUser(String name) {
    return '$name 언팔로우';
  }

  @override
  String get typing => '입력 중';

  @override
  String get connecting => '연결 중...';

  @override
  String daysAgo(int count) {
    return '$count일 전';
  }

  @override
  String get maxTagsAllowed => '최대 5개의 태그만 허용됩니다';

  @override
  String maxImagesAllowed(int count) {
    return '최대 $count개의 이미지만 허용됩니다';
  }

  @override
  String get pleaseRemoveImagesFirst => '비디오를 추가하려면 먼저 이미지를 제거하세요';

  @override
  String get exchange3MessagesBeforeCall => '이 사용자에게 전화하려면 최소 3개의 메시지를 교환해야 합니다';

  @override
  String mediaWithUser(String name) {
    return '$name과의 미디어';
  }

  @override
  String get errorLoadingMedia => '미디어 로드 오류';

  @override
  String get savedMomentsTitle => '저장된 모멘트';

  @override
  String get removeBookmark => '북마크를 삭제하시겠습니까?';

  @override
  String get thisWillRemoveBookmark => '이 메시지가 북마크에서 제거됩니다.';

  @override
  String get remove => '제거';

  @override
  String get bookmarkRemoved => '북마크가 삭제되었습니다';

  @override
  String get bookmarkedMessages => '북마크된 메시지';

  @override
  String get wallpaperSaved => '배경화면이 로컬에 저장되었습니다';

  @override
  String get typeDeleteToConfirm => '확인하려면 DELETE를 입력하세요';

  @override
  String get storyArchive => '스토리 보관함';

  @override
  String get newHighlight => '새 하이라이트';

  @override
  String get addToHighlight => '하이라이트에 추가';

  @override
  String get repost => '재게시';

  @override
  String get repostFeatureSoon => '재게시 기능이 곧 제공됩니다';

  @override
  String get closeFriends => '친한 친구';

  @override
  String get addFriends => '친구 추가';

  @override
  String get highlights => '하이라이트';

  @override
  String get createHighlight => '하이라이트 만들기';

  @override
  String get deleteHighlight => '하이라이트를 삭제하시겠습니까?';

  @override
  String get editHighlight => '하이라이트 수정';

  @override
  String get addMoreToStory => '스토리에 더 추가하기';

  @override
  String get noViewersYet => '아직 시청자가 없습니다';

  @override
  String get noReactionsYet => '아직 반응이 없습니다';

  @override
  String get leaveRoom => '방을 나가시겠습니까?';

  @override
  String get areYouSureLeaveRoom => '이 음성 방을 나가시겠습니까?';

  @override
  String get stay => '머무르기';

  @override
  String get leave => '나가기';

  @override
  String get enableGPS => 'GPS 활성화';

  @override
  String wavedToUser(String name) {
    return '$name에게 인사했습니다!';
  }

  @override
  String get areYouSureFollow => '팔로우하시겠습니까';

  @override
  String get failedToLoadProfile => '프로필을 불러오지 못했습니다';

  @override
  String get noFollowersYet => '아직 팔로워가 없습니다';

  @override
  String get noFollowingYet => '아직 팔로잉하는 사람이 없습니다';

  @override
  String get searchUsers => '사용자 검색...';

  @override
  String get noResultsFound => '결과를 찾을 수 없습니다';

  @override
  String get loadingFailed => '로딩 실패';

  @override
  String get copyLink => '링크 복사';

  @override
  String get shareStory => '스토리 공유';

  @override
  String get thisWillDeleteStory => '이 스토리가 영구적으로 삭제됩니다.';

  @override
  String get storyDeleted => '스토리가 삭제되었습니다';

  @override
  String get addCaption => '캡션 추가...';

  @override
  String get yourStory => '내 스토리';

  @override
  String get sendMessage => '메시지 보내기';

  @override
  String get replyToStory => '스토리에 답장...';

  @override
  String get viewAllReplies => '모든 답장 보기';

  @override
  String get preparingVideo => '비디오 준비 중...';

  @override
  String videoOptimized(String size, String savings) {
    return '비디오 최적화: ${size}MB ($savings% 절약)';
  }

  @override
  String get failedToProcessVideo => '비디오 처리 실패';

  @override
  String get optimizingForBestExperience => '최상의 스토리 경험을 위해 최적화 중';

  @override
  String get pleaseSelectImageOrVideo => '스토리에 사용할 이미지나 비디오를 선택하세요';

  @override
  String get storyCreatedSuccessfully => '스토리가 성공적으로 만들어졌습니다!';

  @override
  String get uploadingStoryInBackground => '백그라운드에서 스토리 업로드 중...';

  @override
  String get storyCreationFailed => '스토리 생성 실패';

  @override
  String get pleaseCheckConnection => '연결을 확인하고 다시 시도하세요.';

  @override
  String get uploadFailed => '업로드 실패';

  @override
  String get tryShorterVideo => '더 짧은 비디오를 사용하거나 나중에 다시 시도하세요.';

  @override
  String get shareMomentsThatDisappear => '24시간 후 사라지는 순간을 공유하세요';

  @override
  String get photo => '사진';

  @override
  String get record => '녹화';

  @override
  String get addSticker => '스티커 추가';

  @override
  String get poll => '투표';

  @override
  String get question => '질문';

  @override
  String get mention => '멘션';

  @override
  String get music => '음악';

  @override
  String get hashtag => '해시태그';

  @override
  String get whoCanSeeThis => '누가 이것을 볼 수 있나요?';

  @override
  String get everyone => '모든 사람';

  @override
  String get anyoneCanSeeStory => '누구나 이 스토리를 볼 수 있습니다';

  @override
  String get friendsOnly => '친구만';

  @override
  String get onlyFollowersCanSee => '팔로워만 볼 수 있습니다';

  @override
  String get onlyCloseFriendsCanSee => '친한 친구만 볼 수 있습니다';

  @override
  String get backgroundColor => '배경색';

  @override
  String get fontStyle => '글꼴 스타일';

  @override
  String get normal => '일반';

  @override
  String get bold => '굵게';

  @override
  String get italic => '기울임꼴';

  @override
  String get handwriting => '필기체';

  @override
  String get addLocation => '위치 추가';

  @override
  String get enterLocationName => '위치 이름 입력';

  @override
  String get addLink => '링크 추가';

  @override
  String get buttonText => '버튼 텍스트';

  @override
  String get learnMore => '자세히 보기';

  @override
  String get addHashtags => '해시태그 추가';

  @override
  String get addHashtag => '해시태그 추가';

  @override
  String get sendAsMessage => '메시지로 보내기';

  @override
  String get shareExternally => '외부로 공유';

  @override
  String get checkOutStory => 'BananaTalk에서 이 스토리를 확인하세요!';

  @override
  String viewsTab(String count) {
    return '조회수 ($count)';
  }

  @override
  String reactionsTab(String count) {
    return '반응 ($count)';
  }

  @override
  String get processingVideo => '비디오 처리 중...';

  @override
  String get link => '링크';

  @override
  String unmuteUser(String name) {
    return '$name의 알림을 해제하시겠습니까?';
  }

  @override
  String get willReceiveNotifications => '새 메시지 알림을 받게 됩니다.';

  @override
  String muteNotificationsFor(String name) {
    return '$name의 알림 음소거';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return '$name의 알림이 해제되었습니다';
  }

  @override
  String notificationsMutedFor(String name) {
    return '$name의 알림이 음소거되었습니다';
  }

  @override
  String get failedToUpdateMuteSettings => '음소거 설정 업데이트 실패';

  @override
  String get oneHour => '1시간';

  @override
  String get eightHours => '8시간';

  @override
  String get oneWeek => '1주';

  @override
  String get always => '항상';

  @override
  String get failedToLoadBookmarks => '북마크를 불러오지 못했습니다';

  @override
  String get noBookmarkedMessages => '북마크된 메시지가 없습니다';

  @override
  String get longPressToBookmark => '메시지를 길게 눌러 북마크하세요';

  @override
  String get thisWillRemoveFromBookmarks => '메시지가 북마크에서 삭제됩니다.';

  @override
  String navigateToMessage(String name) {
    return '$name과의 대화에서 메시지로 이동';
  }

  @override
  String bookmarkedOn(String date) {
    return '$date에 북마크됨';
  }

  @override
  String get voiceMessage => '음성 메시지';

  @override
  String get document => '문서';

  @override
  String get attachment => '첨부 파일';

  @override
  String get sendMeAMessage => '메시지 보내기';

  @override
  String get shareWithFriends => '친구와 공유';

  @override
  String get shareAnywhere => '어디서나 공유';

  @override
  String get emailPreferences => '이메일 설정';

  @override
  String get receiveEmailNotifications => 'BananaTalk에서 이메일 알림 받기';

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
  String get category => '카테고리';

  @override
  String get mood => '기분';

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
  String get applyFilters => '필터 적용';

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
