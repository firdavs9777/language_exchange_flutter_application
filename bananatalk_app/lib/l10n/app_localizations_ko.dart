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
    return '기기가 $flag $name로 설정되어 있습니다';
  }

  @override
  String get youCanOverride => '아래에서 기기 언어를 재정의할 수 있습니다.';

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
  String get appearance => '모양';

  @override
  String get themeAndDisplaySettings => '테마 및 표시 설정';

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
  String get photos => '사진';

  @override
  String get camera => '카메라';

  @override
  String get createMoment => '모멘트 만들기';

  @override
  String get addATitle => '제목 추가...';

  @override
  String get whatsOnYourMind => '무슨 생각을 하고 계신가요?';

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
  String get whenSomeoneViewsYourProfileVIP => '누군가 귀하의 프로필을 볼 때 (VIP)';

  @override
  String get marketing => '마케팅';

  @override
  String get updatesAndPromotionalMessages => '업데이트 및 프로모션 메시지';

  @override
  String get notificationPreferences => '알림 기본 설정';

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
  String get unblockUser => '사용자 차단 해제';

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
  String get removesTheMessageForBothYouAndTheRecipient => '귀하와 수신자 모두에게서 메시지 제거';

  @override
  String get deleteForMe => '나에게만 삭제';

  @override
  String get removesTheMessageOnlyFromYourChat => '귀하의 채팅에서만 메시지 제거';

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
  String get detectYourLocation => '위치 감지';

  @override
  String get tapToUpdateLocation => '위치 업데이트하려면 탭';

  @override
  String get helpOthersFindYouNearby => '다른 사람들이 근처에서 당신을 찾을 수 있도록 도와주세요';

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
  String get deletingYourAccountWillPermanentlyRemove => '계정을 삭제하면 다음이 영구적으로 제거됩니다:\n\n• 귀하의 프로필 및 모든 개인 데이터\n• 모든 메시지 및 대화\n• 모든 모멘트 및 스토리\n• VIP 구독 (환불 없음)\n• 모든 연결 및 팔로워\n\n이 작업은 취소할 수 없습니다.';

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
  String get detectYourLocation2 => '위치 감지';

  @override
  String get tapToUpdateLocation2 => '위치 업데이트하려면 탭';

  @override
  String get helpOthersFindYouNearby2 => '다른 사람들이 근처에서 당신을 찾을 수 있도록 도와주세요';

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
  String get enterYourPassword => '비밀번호 입력';

  @override
  String get yourPassword => '비밀번호';

  @override
  String get typeDELETEToConfirm => '확인하려면 DELETE 입력';

  @override
  String get typeDELETEInCapitalLetters => '대문자로 DELETE 입력';

  @override
  String sent(String emoji) {
    return '$emoji 전송됨!';
  }

  @override
  String get replySent => '답장 전송됨!';

  @override
  String get deleteStory => '스토리 삭제?';

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
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

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
  String get yourPrompt => '프롬프트...';

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
}
