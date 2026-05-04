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
  String get more => '더보기';

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
  String get overview => '개요';

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
  String get deleteComment => 'Delete Comment?';

  @override
  String get commentDeleted => 'Comment deleted';

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
  String get clearCache => '캐시 삭제';

  @override
  String get clearCacheSubtitle => '저장 공간 확보';

  @override
  String get clearCacheDescription => '모든 캐시된 이미지, 동영상 및 오디오 파일이 삭제됩니다. 미디어를 다시 다운로드하는 동안 일시적으로 콘텐츠 로딩이 느려질 수 있습니다.';

  @override
  String get clearCacheHint => '이미지나 오디오가 제대로 로드되지 않을 때 사용하세요.';

  @override
  String get clearingCache => '캐시 삭제 중...';

  @override
  String get cacheCleared => '캐시가 성공적으로 삭제되었습니다! 이미지가 새로 로드됩니다.';

  @override
  String get clearCacheFailed => '캐시 삭제 실패';

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
  String get chats => '채팅';

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
  String get momentUnsaved => '저장에서 삭제됨';

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
  String get deleteHighlight => '하이라이트 삭제';

  @override
  String get editHighlight => '하이라이트 편집';

  @override
  String get addMoreToStory => '스토리에 더 추가하기';

  @override
  String get noViewersYet => '아직 시청자가 없습니다';

  @override
  String get noReactionsYet => '아직 반응이 없습니다';

  @override
  String get leaveRoom => '방 나가기';

  @override
  String get areYouSureLeaveRoom => '이 음성 방을 나가시겠습니까?';

  @override
  String get stay => '머물기';

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
  String get chooseFromGallery => 'Choose from Gallery';

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
  String get videoMustBeUnder1GB => '동영상은 1GB 미만이어야 합니다.';

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
  String get edited => '(수정됨)';

  @override
  String get now => '지금';

  @override
  String weeksAgo(int count) {
    return '$count주 전';
  }

  @override
  String viewRepliesCount(int count) {
    return '── $count개 답글 보기';
  }

  @override
  String get hideReplies => '── 답글 숨기기';

  @override
  String get saveMoment => '모멘트 저장';

  @override
  String get removeFromSaved => '저장 취소';

  @override
  String get momentSaved => '저장됨';

  @override
  String get failedToSave => '저장 실패';

  @override
  String get checkOutMoment => 'BananaTalk에서 이 모멘트를 확인해보세요!';

  @override
  String get failedToLoadMoments => '모멘트를 불러오지 못했습니다';

  @override
  String get noMomentsMatchFilters => '필터에 맞는 모멘트가 없습니다';

  @override
  String get beFirstToShareMoment => '첫 번째 모멘트를 공유해보세요!';

  @override
  String get tryDifferentSearch => '다른 검색어를 시도해보세요';

  @override
  String get tryAdjustingFilters => '필터를 조정해보세요';

  @override
  String get noSavedMoments => '저장된 모멘트 없음';

  @override
  String get tapBookmarkToSave => '북마크 아이콘을 탭하여 모멘트를 저장하세요';

  @override
  String get failedToLoadVideo => '동영상 로드 실패';

  @override
  String get titleRequired => '제목을 입력해주세요';

  @override
  String titleTooLong(int max) {
    return '제목은 $max자 이하여야 합니다';
  }

  @override
  String get descriptionRequired => '설명을 입력해주세요';

  @override
  String descriptionTooLong(int max) {
    return '설명은 $max자 이하여야 합니다';
  }

  @override
  String get scheduledDateMustBeFuture => '예약 날짜는 미래여야 합니다';

  @override
  String get recent => '최신';

  @override
  String get popular => '인기';

  @override
  String get trending => '트렌딩';

  @override
  String get mostRecent => '최신순';

  @override
  String get mostPopular => '인기순';

  @override
  String get allTime => '전체';

  @override
  String get today => '오늘';

  @override
  String get thisWeek => '이번 주';

  @override
  String get thisMonth => '이번 달';

  @override
  String replyingTo(String userName) {
    return '답글 대상: $userName';
  }

  @override
  String get listView => '목록';

  @override
  String get quickMatch => '퀵 매칭';

  @override
  String get onlineNow => '온라인';

  @override
  String speaksLanguage(String language) {
    return '$language 사용자';
  }

  @override
  String learningLanguage(String language) {
    return '$language 학습자';
  }

  @override
  String get noPartnersFound => '파트너를 찾을 수 없습니다';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return '$learning 원어민이나 $native를 배우는 사용자를 찾을 수 없습니다.';
  }

  @override
  String get removeAllFilters => '모든 필터 제거';

  @override
  String get browseAllUsers => '모든 사용자 보기';

  @override
  String get allCaughtUp => '모두 확인했어요!';

  @override
  String get loadingMore => '더 불러오는 중...';

  @override
  String get findingMorePartners => '더 많은 언어 파트너를 찾고 있어요...';

  @override
  String get seenAllPartners => '모든 파트너를 확인했습니다. 나중에 다시 확인해 보세요!';

  @override
  String get startOver => '처음부터';

  @override
  String get changeFilters => '필터 변경';

  @override
  String get findingPartners => '파트너 찾는 중...';

  @override
  String get setLocationReminder => '내 위치를 설정하면 근처 사용자를 먼저 볼 수 있어요.';

  @override
  String get updateLocationReminder => '프로필 > 편집에서 위치를 업데이트하세요.';

  @override
  String get male => '남성';

  @override
  String get female => '여성';

  @override
  String get other => '기타';

  @override
  String get browseMen => '남성 탐색';

  @override
  String get browseWomen => '여성 탐색';

  @override
  String get noMaleUsersFound => '남성 사용자를 찾을 수 없습니다';

  @override
  String get noFemaleUsersFound => '여성 사용자를 찾을 수 없습니다';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => '신규 사용자만';

  @override
  String get showNewUsers => '최근 6일 내 가입한 사용자 표시';

  @override
  String get prioritizeNearby => '근처 우선';

  @override
  String get showNearbyFirst => '근처 사용자를 먼저 표시';

  @override
  String get setLocationToEnable => '이 기능을 사용하려면 위치를 설정하세요';

  @override
  String get radius => '반경';

  @override
  String get findingYourLocation => '위치 찾는 중...';

  @override
  String get enableLocationForDistance => '거리 확인을 위해 위치 활성화';

  @override
  String get enableLocationDescription => 'GPS를 활성화하면 파트너까지의 정확한 거리를 볼 수 있습니다.';

  @override
  String get enableGps => 'GPS 활성화';

  @override
  String get browseByCityCountry => '도시/국가별 탐색';

  @override
  String get peopleNearby => '근처 사람들';

  @override
  String get noNearbyUsersFound => '근처 사용자를 찾을 수 없습니다';

  @override
  String get tryExpandingSearch => '검색 범위를 넓히거나 나중에 다시 확인해 보세요.';

  @override
  String get exploreByCity => '도시별 탐색';

  @override
  String get exploreByCurrentCity => '인터랙티브 지도에서 사용자를 탐색하고 전 세계 언어 파트너를 찾아보세요.';

  @override
  String get interactiveWorldMap => '인터랙티브 세계 지도';

  @override
  String get searchByCityName => '도시 이름으로 검색';

  @override
  String get seeUserCountsPerCountry => '국가별 사용자 수 확인';

  @override
  String get upgradeToVip => 'VIP 업그레이드';

  @override
  String get searchByCity => '도시 검색...';

  @override
  String usersWorldwide(String count) {
    return '전 세계 $count명';
  }

  @override
  String get noUsersFound => '사용자를 찾을 수 없습니다';

  @override
  String get tryDifferentCity => '다른 도시나 국가를 검색해 보세요';

  @override
  String usersCount(String count) {
    return '$count명';
  }

  @override
  String get searchCountry => '국가 검색...';

  @override
  String get wave => '인사';

  @override
  String get newUser => 'NEW';

  @override
  String get warningPermanent => '경고: 이 작업은 되돌릴 수 없습니다!';

  @override
  String get deleteAccountWarning => '계정을 삭제하면 영구적으로 삭제됩니다:\n\n• 프로필 및 모든 개인 데이터\n• 모든 메시지 및 대화\n• 모든 모먼트 및 스토리\n• VIP 구독 (환불 불가)\n• 모든 연결 및 팔로워\n\n이 작업은 되돌릴 수 없습니다.';

  @override
  String get requiredForEmailOnly => '이메일 계정에만 필요합니다';

  @override
  String get pleaseEnterPassword => '비밀번호를 입력해 주세요';

  @override
  String get typeDELETE => 'DELETE를 입력하여 확인';

  @override
  String get mustTypeDELETE => '확인을 위해 DELETE를 입력해야 합니다';

  @override
  String get deletingAccount => '계정 삭제 중...';

  @override
  String get deleteMyAccountPermanently => '내 계정 영구 삭제';

  @override
  String get whatsYourNativeLanguage => '모국어는 무엇인가요?';

  @override
  String get helpsMatchWithLearners => '학습자와 매칭하는 데 도움이 됩니다';

  @override
  String get whatAreYouLearning => '무엇을 배우고 있나요?';

  @override
  String get connectWithNativeSpeakers => '원어민과 연결해 드립니다';

  @override
  String get selectLearningLanguage => '배우는 언어를 선택해 주세요';

  @override
  String get selectCurrentLevel => '현재 레벨을 선택해 주세요';

  @override
  String get beginner => '입문';

  @override
  String get elementary => '초급';

  @override
  String get intermediate => '중급';

  @override
  String get upperIntermediate => '중상급';

  @override
  String get advanced => '고급';

  @override
  String get proficient => '능숙';

  @override
  String get showingPartnersByDistance => '거리순으로 파트너 표시 중';

  @override
  String get enableLocationForResults => '거리 기반 결과를 위해 위치를 활성화하세요';

  @override
  String get enable => '활성화';

  @override
  String get locationNotSet => '위치 미설정';

  @override
  String get tellUsAboutYourself => '자기소개를 해주세요';

  @override
  String get justACoupleQuickThings => '간단한 질문 몇 가지';

  @override
  String get gender => '성별';

  @override
  String get birthDate => '생년월일';

  @override
  String get selectYourBirthDate => '생년월일을 선택하세요';

  @override
  String get continueButton => '계속';

  @override
  String get pleaseSelectGender => '성별을 선택해 주세요';

  @override
  String get pleaseSelectBirthDate => '생년월일을 선택해 주세요';

  @override
  String get mustBe18 => '18세 이상이어야 합니다';

  @override
  String get invalidDate => '잘못된 날짜';

  @override
  String get almostDone => '거의 다 됐어요!';

  @override
  String get addPhotoLocationForMatches => '사진과 위치를 추가하여 더 많은 매칭을 받으세요';

  @override
  String get addProfilePhoto => '프로필 사진 추가';

  @override
  String get optionalUpTo6Photos => '선택 사항 — 최대 6장';

  @override
  String get requiredUpTo6Photos => '필수 — 최대 6장';

  @override
  String get profilePhotoRequired => '프로필 사진을 최소 1장 추가해 주세요';

  @override
  String get locationOptional => '위치는 선택사항입니다 — 나중에 추가할 수 있어요';

  @override
  String get maximum6Photos => '최대 6장';

  @override
  String get tapToDetectLocation => '탭하여 위치 감지';

  @override
  String get optionalHelpsNearbyPartners => '선택 사항 — 근처 파트너 찾기에 도움됩니다';

  @override
  String get startLearning => '학습 시작!';

  @override
  String get photoLocationOptional => '사진과 위치는 선택 사항입니다 — 나중에 추가할 수 있어요';

  @override
  String get pleaseAcceptTerms => '서비스 이용약관에 동의해 주세요';

  @override
  String get iAgreeToThe => '동의합니다: ';

  @override
  String get termsOfService => '서비스 이용약관';

  @override
  String get tapToSelectLanguage => '탭하여 언어 선택';

  @override
  String yourLevelIn(String language) {
    return '$language 레벨 (선택 사항)';
  }

  @override
  String get yourCurrentLevel => '현재 레벨';

  @override
  String get nativeCannotBeSameAsLearning => '모국어와 학습 언어가 같을 수 없습니다';

  @override
  String get learningCannotBeSameAsNative => '학습 언어와 모국어가 같을 수 없습니다';

  @override
  String stepOf(String current, String total) {
    return '$total단계 중 $current단계';
  }

  @override
  String get continueWithGoogle => 'Google로 계속하기';

  @override
  String get registerLink => '회원가입';

  @override
  String get pleaseEnterBothEmailAndPassword => '이메일과 비밀번호를 모두 입력하세요';

  @override
  String get pleaseEnterValidEmail => '유효한 이메일 주소를 입력하세요';

  @override
  String get loginSuccessful => '로그인 성공!';

  @override
  String get stepOneOfTwo => '1단계 / 2단계';

  @override
  String get createYourAccount => '계정 만들기';

  @override
  String get basicInfoToGetStarted => '시작을 위한 기본 정보';

  @override
  String get emailVerifiedLabel => '이메일 (인증됨)';

  @override
  String get nameLabel => '이름';

  @override
  String get yourDisplayName => '표시 이름';

  @override
  String get atLeast8Characters => '8자 이상';

  @override
  String get confirmPasswordHint => '비밀번호 확인';

  @override
  String get nextButton => '다음';

  @override
  String get pleaseEnterYourName => '이름을 입력하세요';

  @override
  String get pleaseEnterAPassword => '비밀번호를 입력하세요';

  @override
  String get passwordsDoNotMatch => '비밀번호가 일치하지 않습니다';

  @override
  String get otherGender => '기타';

  @override
  String get continueWithGoogleAccount => 'Google 계정으로 계속하여\n원활한 경험을 즐기세요';

  @override
  String get signingYouIn => '로그인 중...';

  @override
  String get backToSignInMethods => '로그인 방법으로 돌아가기';

  @override
  String get securedByGoogle => 'Google 보안';

  @override
  String get dataProtectedEncryption => '업계 표준 암호화로 데이터가 보호됩니다';

  @override
  String get welcomeCompleteProfile => '환영합니다! 프로필을 완성해 주세요';

  @override
  String welcomeBackName(String name) {
    return '다시 오신 것을 환영합니다, $name!';
  }

  @override
  String get continueWithAppleId => 'Apple ID로 계속하여\n안전한 경험을 즐기세요';

  @override
  String get continueWithApple => 'Apple로 계속하기';

  @override
  String get securedByApple => 'Apple 보안';

  @override
  String get privacyProtectedApple => 'Apple 로그인으로 개인정보가 보호됩니다';

  @override
  String get createAccount => '계정 만들기';

  @override
  String get enterEmailToGetStarted => '시작하려면 이메일을 입력하세요';

  @override
  String get continueText => '계속';

  @override
  String get pleaseEnterEmailAddress => '이메일 주소를 입력하세요';

  @override
  String get verificationCodeSent => '인증 코드가 이메일로 전송되었습니다!';

  @override
  String get forgotPasswordTitle => '비밀번호 찾기';

  @override
  String get resetPasswordTitle => '비밀번호 재설정';

  @override
  String get enterEmailForResetCode => '이메일 주소를 입력하면 비밀번호 재설정 코드를 보내드립니다';

  @override
  String get sendResetCode => '재설정 코드 보내기';

  @override
  String get resetCodeSent => '재설정 코드가 이메일로 전송되었습니다!';

  @override
  String get rememberYourPassword => '비밀번호가 기억나시나요?';

  @override
  String get verifyCode => '코드 확인';

  @override
  String get enterResetCode => '재설정 코드 입력';

  @override
  String get weSentCodeTo => '6자리 코드를 보냈습니다';

  @override
  String get pleaseEnterAll6Digits => '6자리를 모두 입력하세요';

  @override
  String get codeVerifiedCreatePassword => '코드 확인 완료! 새 비밀번호를 만드세요';

  @override
  String get verify => '확인';

  @override
  String get didntReceiveCode => '코드를 받지 못하셨나요?';

  @override
  String get resend => '재전송';

  @override
  String resendWithTimer(String timer) {
    return '재전송 ($timer초)';
  }

  @override
  String get resetCodeResent => '재설정 코드가 재전송되었습니다!';

  @override
  String get verifyEmail => '이메일 인증';

  @override
  String get verifyYourEmail => '이메일을 인증하세요';

  @override
  String get emailVerifiedSuccessfully => '이메일이 성공적으로 인증되었습니다!';

  @override
  String get verificationCodeResent => '인증 코드가 재전송되었습니다!';

  @override
  String get createNewPassword => '새 비밀번호 만들기';

  @override
  String get enterNewPasswordBelow => '아래에 새 비밀번호를 입력하세요';

  @override
  String get newPassword => '새 비밀번호';

  @override
  String get confirmPasswordLabel => '비밀번호 확인';

  @override
  String get pleaseFillAllFields => '모든 필드를 입력하세요';

  @override
  String get passwordResetSuccessful => '비밀번호가 성공적으로 재설정되었습니다! 새 비밀번호로 로그인하세요';

  @override
  String get privacyTitle => '개인정보';

  @override
  String get profileVisibility => '프로필 공개 설정';

  @override
  String get showCountryRegion => '국가/지역 표시';

  @override
  String get showCountryRegionDesc => '프로필에 국가를 표시합니다';

  @override
  String get showCity => '도시 표시';

  @override
  String get showCityDesc => '프로필에 도시를 표시합니다';

  @override
  String get showAge => '나이 표시';

  @override
  String get showAgeDesc => '프로필에 나이를 표시합니다';

  @override
  String get showZodiacSign => '별자리 표시';

  @override
  String get showZodiacSignDesc => '프로필에 별자리를 표시합니다';

  @override
  String get onlineStatusSection => '온라인 상태';

  @override
  String get showOnlineStatus => '온라인 상태 표시';

  @override
  String get showOnlineStatusDesc => '다른 사용자에게 온라인 상태를 표시합니다';

  @override
  String get otherSettings => '기타 설정';

  @override
  String get showGiftingLevel => '선물 레벨 표시';

  @override
  String get showGiftingLevelDesc => '선물 레벨 배지를 표시합니다';

  @override
  String get birthdayNotifications => '생일 알림';

  @override
  String get birthdayNotificationsDesc => '생일에 알림을 받습니다';

  @override
  String get personalizedAds => '맞춤 광고';

  @override
  String get personalizedAdsDesc => '맞춤 광고를 허용합니다';

  @override
  String get saveChanges => '변경사항 저장';

  @override
  String get privacySettingsSaved => '개인정보 설정이 저장되었습니다';

  @override
  String get locationSection => '위치';

  @override
  String get updateLocation => '위치 업데이트';

  @override
  String get updateLocationDesc => '현재 위치를 새로고침합니다';

  @override
  String get currentLocation => '현재 위치';

  @override
  String get locationNotAvailable => '위치를 사용할 수 없습니다';

  @override
  String get locationUpdated => '위치가 업데이트되었습니다';

  @override
  String get locationPermissionDenied => '위치 권한이 거부되었습니다. 설정에서 활성화해주세요.';

  @override
  String get locationServiceDisabled => '위치 서비스가 비활성화되어 있습니다. 활성화해주세요.';

  @override
  String get updatingLocation => '위치 업데이트 중...';

  @override
  String get locationCouldNotBeUpdated => '위치를 업데이트할 수 없습니다';

  @override
  String get incomingAudioCall => '음성 통화 수신';

  @override
  String get incomingVideoCall => '영상 통화 수신';

  @override
  String get outgoingCall => '전화 거는 중...';

  @override
  String get callRinging => '벨 울리는 중...';

  @override
  String get callConnecting => '연결 중...';

  @override
  String get callConnected => '연결됨';

  @override
  String get callReconnecting => '재연결 중...';

  @override
  String get callEnded => '통화 종료';

  @override
  String get callFailed => '통화 실패';

  @override
  String get callMissed => '부재중 전화';

  @override
  String get callDeclined => '통화 거절됨';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => '받기';

  @override
  String get declineCall => '거절';

  @override
  String get endCall => '종료';

  @override
  String get muteCall => '음소거';

  @override
  String get unmuteCall => '음소거 해제';

  @override
  String get speakerOn => '스피커';

  @override
  String get speakerOff => '이어폰';

  @override
  String get videoOn => '비디오 켜기';

  @override
  String get videoOff => '비디오 끄기';

  @override
  String get switchCamera => '카메라 전환';

  @override
  String get callPermissionDenied => '통화에는 마이크 권한이 필요합니다';

  @override
  String get cameraPermissionDenied => '영상 통화에는 카메라 권한이 필요합니다';

  @override
  String get callConnectionFailed => '연결할 수 없습니다. 다시 시도해 주세요.';

  @override
  String get userBusy => '사용자가 통화 중입니다';

  @override
  String get userOffline => '사용자가 오프라인입니다';

  @override
  String get callHistory => '통화 기록';

  @override
  String get noCallHistory => '통화 기록 없음';

  @override
  String get missedCalls => '부재중 전화';

  @override
  String get allCalls => '모든 통화';

  @override
  String get callBack => '다시 전화';

  @override
  String callAt(String time) {
    return '$time에 통화';
  }

  @override
  String get audioCall => '음성 통화';

  @override
  String get voiceRoom => '음성 채팅방';

  @override
  String get noVoiceRooms => '활성화된 음성 채팅방 없음';

  @override
  String get createVoiceRoom => '음성 채팅방 만들기';

  @override
  String get joinRoom => '방 참여';

  @override
  String get leaveRoomConfirm => '방을 나가시겠습니까?';

  @override
  String get leaveRoomMessage => '정말 이 방을 나가시겠습니까?';

  @override
  String get roomTitle => '방 제목';

  @override
  String get roomTitleHint => '방 제목 입력';

  @override
  String get roomTopic => '주제';

  @override
  String get roomLanguage => '언어';

  @override
  String get roomHost => '호스트';

  @override
  String roomParticipants(int count) {
    return '$count명 참여';
  }

  @override
  String roomMaxParticipants(int count) {
    return '최대 $count명';
  }

  @override
  String get selectTopic => '주제 선택';

  @override
  String get raiseHand => '손 들기';

  @override
  String get lowerHand => '손 내리기';

  @override
  String get handRaisedNotification => '손을 들었습니다! 호스트가 요청을 확인합니다.';

  @override
  String get handLoweredNotification => '손을 내렸습니다';

  @override
  String get muteParticipant => '참여자 음소거';

  @override
  String get kickParticipant => '방에서 내보내기';

  @override
  String get promoteToCoHost => '공동 호스트로 승격';

  @override
  String get endRoomConfirm => '방을 종료하시겠습니까?';

  @override
  String get endRoomMessage => '모든 참여자의 방이 종료됩니다.';

  @override
  String get roomEnded => '호스트가 방을 종료했습니다';

  @override
  String get youWereRemoved => '방에서 내보내졌습니다';

  @override
  String get roomIsFull => '방이 가득 찼습니다';

  @override
  String get roomChat => '방 채팅';

  @override
  String get noMessages => '아직 메시지가 없습니다';

  @override
  String get typeMessage => '메시지 입력...';

  @override
  String get voiceRoomsDescription => '라이브 대화에 참여하고 말하기 연습하세요';

  @override
  String liveRoomsCount(int count) {
    return '$count개 라이브';
  }

  @override
  String get noActiveRooms => '활성화된 방 없음';

  @override
  String get noActiveRoomsDescription => '첫 번째로 음성 채팅방을 시작하고 다른 사람들과 말하기 연습하세요!';

  @override
  String get startRoom => '방 시작';

  @override
  String get createRoom => '방 만들기';

  @override
  String get roomCreated => '방이 생성되었습니다!';

  @override
  String get failedToCreateRoom => '방 생성 실패';

  @override
  String get errorLoadingRooms => '방 로드 오류';

  @override
  String get pleaseEnterRoomTitle => '방 제목을 입력해 주세요';

  @override
  String get startLiveConversation => '라이브 대화 시작';

  @override
  String get maxParticipants => '최대 참여자';

  @override
  String nPeople(int count) {
    return '$count명';
  }

  @override
  String hostedBy(String name) {
    return '$name님이 호스팅';
  }

  @override
  String get liveLabel => '라이브';

  @override
  String get joinLabel => '참여';

  @override
  String get fullLabel => '가득 참';

  @override
  String get justStarted => '방금 시작됨';

  @override
  String get allLanguages => '모든 언어';

  @override
  String get allTopics => '모든 주제';

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
  String get you => '나';

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
  String get dataAndStorage => '데이터 및 저장공간';

  @override
  String get manageStorageAndDownloads => '저장공간 및 다운로드 관리';

  @override
  String get storageUsage => '저장공간 사용량';

  @override
  String get totalCacheSize => '총 캐시 크기';

  @override
  String get imageCache => '이미지 캐시';

  @override
  String get voiceMessagesCache => '음성 메시지';

  @override
  String get videoCache => '동영상 캐시';

  @override
  String get otherCache => '기타 캐시';

  @override
  String get autoDownloadMedia => '미디어 자동 다운로드';

  @override
  String get currentNetwork => '현재 네트워크';

  @override
  String get images => '이미지';

  @override
  String get videos => '동영상';

  @override
  String get voiceMessagesShort => '음성 메시지';

  @override
  String get documentsLabel => '문서';

  @override
  String get wifiOnly => 'Wi-Fi에서만';

  @override
  String get never => '안 함';

  @override
  String get clearAllCache => '모든 캐시 삭제';

  @override
  String get allCache => '모든 캐시';

  @override
  String get clearAllCacheConfirmation => '모든 캐시된 이미지, 음성 메시지, 동영상 및 기타 파일이 삭제됩니다. 앱이 일시적으로 콘텐츠를 느리게 로드할 수 있습니다.';

  @override
  String clearCacheConfirmationFor(String category) {
    return '$category 삭제?';
  }

  @override
  String storageToFree(String size) {
    return '$size이(가) 확보됩니다';
  }

  @override
  String get calculating => '계산 중...';

  @override
  String get noDataToShow => '표시할 데이터가 없습니다';

  @override
  String get profileCompletion => '프로필 완성도';

  @override
  String get justGettingStarted => '시작하는 중';

  @override
  String get lookingGood => '잘하고 있어요!';

  @override
  String get almostThere => '거의 다 됐어요!';

  @override
  String addMissingFields(String fields, Object field) {
    return '추가하기: $fields';
  }

  @override
  String get profilePicture => '프로필 사진';

  @override
  String get nativeSpeaker => '원어민';

  @override
  String peopleInterestedInTopic(Object count) {
    return '이 주제에 관심 있는 사람들';
  }

  @override
  String get beFirstToAddTopic => '이 주제를 관심사에 추가하는 첫 번째가 되세요!';

  @override
  String get recentMoments => '최근 모먼트';

  @override
  String get seeAll => '모두 보기';

  @override
  String get study => '학습';

  @override
  String get followerMoments => '팔로워 모먼트';

  @override
  String get whenPeopleYouFollowPost => '팔로우하는 사람이 새 모먼트를 게시할 때';

  @override
  String get noNotificationsYet => '아직 알림이 없습니다';

  @override
  String get whenYouGetNotifications => '알림이 오면 여기에 표시됩니다';

  @override
  String get failedToLoadNotifications => '알림을 불러오지 못했습니다';

  @override
  String get clearAllNotificationsConfirm => '모든 알림을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.';

  @override
  String get tapToChange => '탭하여 변경';

  @override
  String get noPictureSet => '사진 미설정';

  @override
  String get nameAndGender => '이름 및 성별';

  @override
  String get languageLevel => '언어 수준';

  @override
  String get personalInformation => '개인 정보';

  @override
  String get mbti => 'MBTI';

  @override
  String get topicsOfInterest => '관심 주제';

  @override
  String get levelBeginner => '입문';

  @override
  String get levelElementary => '초급';

  @override
  String get levelIntermediate => '중급';

  @override
  String get levelUpperIntermediate => '중상급';

  @override
  String get levelAdvanced => '고급';

  @override
  String get levelProficient => '능숙';

  @override
  String get selectYourLevel => '레벨 선택';

  @override
  String howWellDoYouSpeak(String language) {
    return '$language 실력이 어느 정도인가요?';
  }

  @override
  String get theLanguage => '언어';

  @override
  String languageLevelSetTo(String level) {
    return '언어 수준이 $level(으)로 설정되었습니다';
  }

  @override
  String get failedToUpdate => '업데이트 실패';

  @override
  String get editHometown => '고향 편집';

  @override
  String get useCurrentLocation => '현재 위치 사용';

  @override
  String get detecting => '감지 중...';

  @override
  String get getCurrentLocation => '현재 위치 가져오기';

  @override
  String get country => '국가';

  @override
  String get city => '도시';

  @override
  String get coordinates => '좌표';

  @override
  String get noLocationDetectedYet => '아직 감지된 위치가 없습니다.';

  @override
  String get detected => '감지됨';

  @override
  String get savedHometown => '고향이 저장되었습니다';

  @override
  String get locationServicesDisabled => '위치 서비스가 비활성화되어 있습니다. 활성화해주세요.';

  @override
  String get locationPermissionPermanentlyDenied => '위치 권한이 영구적으로 거부되었습니다.';

  @override
  String get unknown => '알 수 없음';

  @override
  String get editBio => '소개글 편집';

  @override
  String get bioUpdatedSuccessfully => '소개글이 성공적으로 업데이트되었습니다';

  @override
  String get tellOthersAboutYourself => '자신에 대해 알려주세요...';

  @override
  String charactersCount(int count) {
    return '$count/500자';
  }

  @override
  String get selectYourMbti => 'MBTI 선택';

  @override
  String get myBloodType => '내 혈액형';

  @override
  String get pleaseSelectABloodType => '혈액형을 선택해주세요';

  @override
  String get nativeLanguageRequired => '모국어 (필수)';

  @override
  String get languageToLearnRequired => '배울 언어 (필수)';

  @override
  String get nativeLanguageCannotBeSame => '모국어는 배우는 언어와 같을 수 없습니다';

  @override
  String get learningLanguageCannotBeSame => '배우는 언어는 모국어와 같을 수 없습니다';

  @override
  String get pleaseSelectALanguage => '언어를 선택해주세요';

  @override
  String get editInterests => '관심사 편집';

  @override
  String maxTopicsAllowed(int count) {
    return '최대 $count개 주제까지 선택 가능';
  }

  @override
  String get topicsUpdatedSuccessfully => '관심 주제가 성공적으로 업데이트되었습니다!';

  @override
  String get failedToUpdateTopics => '관심 주제 업데이트 실패';

  @override
  String selectedCount(int count, int max) {
    return '$count/$max 선택됨';
  }

  @override
  String get profilePictures => '프로필 사진';

  @override
  String get addImages => '이미지 추가';

  @override
  String get selectUpToImages => '최대 5개 이미지 선택';

  @override
  String get takeAPhoto => '사진 촬영';

  @override
  String get removeImage => '이미지 제거';

  @override
  String get removeImageConfirm => '이 이미지를 제거하시겠습니까?';

  @override
  String get removeAll => '전체 제거';

  @override
  String get removeAllSelectedImages => '선택한 이미지 전체 제거';

  @override
  String get removeAllSelectedImagesConfirm => '선택한 모든 이미지를 제거하시겠습니까?';

  @override
  String get yourProfilePictureWillBeKept => '기존 프로필 사진은 유지됩니다';

  @override
  String get removeAllImages => '모든 이미지 제거';

  @override
  String get removeAllImagesConfirm => '모든 프로필 사진을 제거하시겠습니까?';

  @override
  String get currentImages => '현재 이미지';

  @override
  String get newImages => '새 이미지';

  @override
  String get addMoreImages => '이미지 더 추가';

  @override
  String uploadImages(int count) {
    return '$count개 이미지 업로드';
  }

  @override
  String get imageRemovedSuccessfully => '이미지가 성공적으로 제거되었습니다';

  @override
  String get imagesUploadedSuccessfully => '이미지가 성공적으로 업로드되었습니다';

  @override
  String get selectedImagesCleared => '선택한 이미지가 삭제되었습니다';

  @override
  String get extraImagesRemovedSuccessfully => '추가 이미지가 성공적으로 제거되었습니다';

  @override
  String get mustKeepAtLeastOneProfilePicture => '최소 1개의 프로필 사진은 유지해야 합니다';

  @override
  String get noProfilePicturesToRemove => '제거할 프로필 사진이 없습니다';

  @override
  String get authenticationTokenNotFound => '인증 토큰을 찾을 수 없습니다';

  @override
  String get saveChangesQuestion => '변경사항을 저장하시겠습니까?';

  @override
  String youHaveUnuploadedImages(int count) {
    return '$count개의 이미지가 선택되었지만 업로드되지 않았습니다. 지금 업로드하시겠습니까?';
  }

  @override
  String get discard => '취소';

  @override
  String get upload => '업로드';

  @override
  String maxImagesInfo(int max, int current) {
    return '최대 $max개 이미지 업로드 가능. 현재: $current/$max\n한 번에 최대 5개 이미지.';
  }

  @override
  String canOnlyAddMoreImages(int count, int max) {
    return '$count개의 이미지만 더 추가할 수 있습니다. 최대 $max개입니다.';
  }

  @override
  String get maxImagesPerUpload => '한 번에 최대 5개 이미지만 업로드할 수 있습니다. 처음 5개만 추가됩니다.';

  @override
  String canOnlyHaveMaxImages(int max) {
    return '최대 $max개 이미지만 가질 수 있습니다';
  }

  @override
  String get imageSizeExceedsLimit => '이미지 크기가 10MB 제한을 초과합니다';

  @override
  String get unsupportedImageFormat => '지원되지 않는 이미지 형식';

  @override
  String get pleaseSelectAtLeastOneImage => '업로드할 이미지를 최소 1개 선택해주세요';

  @override
  String get basicInformation => '기본 정보';

  @override
  String get languageToLearn => '배울 언어';

  @override
  String get hometown => '고향';

  @override
  String get characters => '자';

  @override
  String get failedToLoadLanguages => '언어 목록을 불러오지 못했습니다';

  @override
  String get studyHub => '학습 허브';

  @override
  String get dailyLearningJourney => '오늘의 학습 여정';

  @override
  String get learnTab => '학습';

  @override
  String get aiTools => 'AI 도구';

  @override
  String get streak => '연속 학습';

  @override
  String get lessons => '레슨';

  @override
  String get words => '단어';

  @override
  String get quickActions => '빠른 실행';

  @override
  String get review => '복습';

  @override
  String wordsDue(int count) {
    return '$count개 단어 예정';
  }

  @override
  String get addWords => '단어 추가';

  @override
  String get buildVocabulary => '어휘 쌓기';

  @override
  String get practiceWithAI => 'AI로 연습';

  @override
  String get aiPracticeDescription => '채팅, 퀴즈, 문법 및 발음';

  @override
  String get dailyChallenges => '일일 도전';

  @override
  String get allChallengesCompleted => '모든 도전 완료!';

  @override
  String get continueLearning => '계속 학습';

  @override
  String get structuredLearningPath => '구조화된 학습 경로';

  @override
  String get vocabulary => '어휘';

  @override
  String get yourWordCollection => '나의 단어 컬렉션';

  @override
  String get achievements => '업적';

  @override
  String get badgesAndMilestones => '배지 및 마일스톤';

  @override
  String get failedToLoadLearningData => '학습 데이터를 불러오지 못했습니다';

  @override
  String get startYourJourney => '여정을 시작하세요!';

  @override
  String get startJourneyDescription => '레슨을 완료하고, 어휘를 쌓고,\n진도를 추적하세요';

  @override
  String levelN(int level) {
    return '$level레벨';
  }

  @override
  String xpEarned(int xp) {
    return '$xp XP 획득';
  }

  @override
  String nextLevel(int level) {
    return '다음: $level레벨';
  }

  @override
  String xpToGo(int xp) {
    return '$xp XP 남음';
  }

  @override
  String get aiConversationPartner => 'AI 대화 파트너';

  @override
  String get practiceWithAITutor => 'AI 튜터와 말하기 연습';

  @override
  String get startConversation => '대화 시작';

  @override
  String get aiFeatures => 'AI 기능';

  @override
  String get aiLessons => 'AI 레슨';

  @override
  String get learnWithAI => 'AI로 학습';

  @override
  String get grammar => '문법';

  @override
  String get checkWriting => '글 교정';

  @override
  String get pronunciation => '발음';

  @override
  String get improveSpeaking => '말하기 향상';

  @override
  String get translation => '번역';

  @override
  String get smartTranslate => '스마트 번역';

  @override
  String get aiQuizzes => 'AI 퀴즈';

  @override
  String get testKnowledge => '지식 테스트';

  @override
  String get lessonBuilder => '레슨 빌더';

  @override
  String get customLessons => '맞춤 레슨';

  @override
  String get yourAIProgress => '나의 AI 진도';

  @override
  String get quizzes => '퀴즈';

  @override
  String get avgScore => '평균 점수';

  @override
  String get focusAreas => '집중 영역';

  @override
  String accuracyPercent(String accuracy) {
    return '$accuracy% 정확도';
  }

  @override
  String get practice => '연습';

  @override
  String get browse => '탐색';

  @override
  String get noRecommendedLessons => '추천 레슨이 없습니다';

  @override
  String get noLessonsFound => '레슨을 찾을 수 없습니다';

  @override
  String get createCustomLessonDescription => 'AI로 나만의 맞춤 레슨 만들기';

  @override
  String get createLessonWithAI => 'AI로 레슨 만들기';

  @override
  String get allLevels => '모든 수준';

  @override
  String get levelA1 => 'A1 입문';

  @override
  String get levelA2 => 'A2 초급';

  @override
  String get levelB1 => 'B1 중급';

  @override
  String get levelB2 => 'B2 중상급';

  @override
  String get levelC1 => 'C1 고급';

  @override
  String get levelC2 => 'C2 숙련';

  @override
  String get failedToLoadLessons => '레슨을 불러오지 못했습니다';

  @override
  String get pin => '고정';

  @override
  String get unpin => '고정 해제';

  @override
  String get editMessage => '메시지 수정';

  @override
  String get enterMessage => '메시지 입력...';

  @override
  String get deleteMessageTitle => '메시지 삭제';

  @override
  String get actionCannotBeUndone => '이 작업은 취소할 수 없습니다.';

  @override
  String get onlyRemovesFromDevice => '기기에서만 삭제됩니다';

  @override
  String get availableWithinOneHour => '1시간 이내만 가능';

  @override
  String get available => '사용 가능';

  @override
  String get forwardMessage => '메시지 전달';

  @override
  String get selectUsersToForward => '전달할 사용자를 선택하세요:';

  @override
  String forwardCount(int count) {
    return '전달 ($count)';
  }

  @override
  String get pinnedMessage => '고정된 메시지';

  @override
  String get photoMedia => '사진';

  @override
  String get videoMedia => '동영상';

  @override
  String get voiceMessageMedia => '음성 메시지';

  @override
  String get documentMedia => '문서';

  @override
  String get locationMedia => '위치';

  @override
  String get stickerMedia => '스티커';

  @override
  String get smileys => '웃는 얼굴';

  @override
  String get emotions => '감정';

  @override
  String get handGestures => '손 제스처';

  @override
  String get hearts => '하트';

  @override
  String get tapToSayHi => '탭하여 인사하세요!';

  @override
  String get sendWaveToStart => '인사를 보내 대화를 시작하세요';

  @override
  String get documentMustBeUnder50MB => '문서는 50MB 미만이어야 합니다.';

  @override
  String get editWithin15Minutes => '메시지는 15분 이내에만 수정할 수 있습니다';

  @override
  String messageForwardedTo(int count) {
    return '$count명의 사용자에게 메시지가 전달되었습니다';
  }

  @override
  String get failedToLoadUsers => '사용자를 불러오지 못했습니다';

  @override
  String get voice => '음성';

  @override
  String get searchGifs => 'GIF 검색...';

  @override
  String get trendingGifs => '인기';

  @override
  String get poweredByGiphy => 'Powered by GIPHY';

  @override
  String get gif => 'GIF';

  @override
  String get noGifsFound => 'GIF를 찾을 수 없습니다';

  @override
  String get failedToLoadGifs => 'GIF를 불러오지 못했습니다';

  @override
  String get gifSent => 'GIF';

  @override
  String get filterCommunities => '필터';

  @override
  String get reset => '초기화';

  @override
  String get findYourPerfect => '이상적인';

  @override
  String get languagePartner => '언어 파트너 찾기';

  @override
  String get learningLanguageLabel => '학습 언어';

  @override
  String get ageRange => '나이 범위';

  @override
  String get genderPreference => '성별 선호';

  @override
  String get any => '모두';

  @override
  String get showNewUsersSubtitle => '지난 6일 이내에 가입한 사용자 표시';

  @override
  String get autoDetectLocation => '내 위치 자동 감지';

  @override
  String get selectCountry => '국가 선택';

  @override
  String get anyCountry => '모든 국가';

  @override
  String get loadingLanguages => '언어 로딩 중...';

  @override
  String minAge(int age) {
    return '최소: $age';
  }

  @override
  String maxAge(int age) {
    return '최대: $age';
  }

  @override
  String get captionRequired => '캡션은 필수입니다';

  @override
  String captionTooLong(int maxLength) {
    return '캡션은 $maxLength자 이하여야 합니다';
  }

  @override
  String get maximumImagesReached => '최대 이미지 수에 도달했습니다';

  @override
  String maximumImagesReachedDescription(int maxImages) {
    return '모멘트당 최대 $maxImages개의 이미지를 업로드할 수 있습니다.';
  }

  @override
  String maximumImagesAddedPartial(int maxImages, int added) {
    return '최대 $maxImages개 이미지 허용. $added개만 추가되었습니다.';
  }

  @override
  String get locationAccessRestricted => '위치 접근 제한됨';

  @override
  String get locationPermissionNeeded => '위치 권한이 필요합니다';

  @override
  String get addToYourMoment => '모멘트에 추가';

  @override
  String get categoryLabel => '카테고리';

  @override
  String get languageLabel => '언어';

  @override
  String get scheduleOptional => '예약 (선택사항)';

  @override
  String get scheduleForLater => '나중으로 예약';

  @override
  String get addMore => '더 추가';

  @override
  String get howAreYouFeeling => '기분이 어떠세요?';

  @override
  String get pleaseWaitOptimizingVideo => '동영상을 최적화하는 중입니다. 잠시 기다려 주세요';

  @override
  String unsupportedVideoFormat(String formats) {
    return '지원되지 않는 형식입니다. 사용 가능: $formats';
  }

  @override
  String get chooseBackground => '배경 선택';

  @override
  String likedByXPeople(int count) {
    return '$count명이 좋아합니다';
  }

  @override
  String xComments(int count) {
    return '댓글 $count개';
  }

  @override
  String get oneComment => '댓글 1개';

  @override
  String get addAComment => '댓글 달기...';

  @override
  String viewXReplies(int count) {
    return '답글 $count개 보기';
  }

  @override
  String seenByX(int count) {
    return '$count명이 봄';
  }

  @override
  String xHoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String xMinutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String get repliedToYourStory => '스토리에 답장함';

  @override
  String mentionedYouInComment(String name) {
    return '$name님이 댓글에서 회원님을 언급했습니다';
  }

  @override
  String repliedToYourComment(String name) {
    return '$name님이 댓글에 답글을 달았습니다';
  }

  @override
  String reactedToYourComment(String name) {
    return '$name님이 댓글에 반응했습니다';
  }

  @override
  String get addReaction => '반응 추가';

  @override
  String get attachImage => '이미지 첨부';

  @override
  String get pickGif => 'GIF 선택';

  @override
  String get textStory => '텍스트';

  @override
  String get typeYourStory => '스토리를 입력하세요...';

  @override
  String get selectBackground => '배경 선택';

  @override
  String get highlightsTitle => '하이라이트';

  @override
  String get highlightTitle => '하이라이트 제목';

  @override
  String get createNewHighlight => '새로 만들기';

  @override
  String get selectStories => '스토리 선택';

  @override
  String get selectCover => '커버 선택';

  @override
  String get addText => '텍스트 추가';

  @override
  String get fontStyleLabel => '글꼴 스타일';

  @override
  String get textColorLabel => '텍스트 색상';

  @override
  String get dragToDelete => '여기로 끌어서 삭제';

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
}
