// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Bananatalk';

  @override
  String get aiStudyPromoTitle => 'AI 시나리오로 연습하세요';

  @override
  String get aiStudyPromoBody => 'AI 튜터와 실제 대화를 롤플레이하며 말하기 자신감을 키워보세요.';

  @override
  String get aiStudyPromoCTA => '시나리오 체험하기';

  @override
  String get aiStudyPromoDismiss => '나중에';

  @override
  String get promoSpotlightCoinsHeadline => '대화 중에 코인이 떨어질 걱정은 이제 그만';

  @override
  String get promoSpotlightCoinsSubtitle => '일일 한도에 도달할 때마다 코인으로 추가 번역, 튜터 채팅, 모먼트를 잠금 해제하세요.';

  @override
  String get promoSpotlightRoomsHeadline => '주제별 방에 참여하세요';

  @override
  String get promoSpotlightRoomsSubtitle => '실시간 텍스트 방에 들어가서 관심 있는 주제로 이야기하는 학습자들과 연습해보세요.';

  @override
  String get promoSpotlightVoiceHeadline => '보이스룸에 참여하세요';

  @override
  String get promoSpotlightVoiceSubtitle => '다른 학습자들과 실시간으로 대화하며 한 번의 대화마다 진짜 말하기 자신감을 쌓아보세요.';

  @override
  String get promoSpotlightTryIt => '체험해보기';

  @override
  String get promoSpotlightMaybeLater => '나중에 할게요';

  @override
  String get promoSpotlightDontShowAgain => '다시 보지 않기';

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
  String get loadMoreComments => '댓글 더 보기';

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
  String get deleteComment => '댓글을 삭제하시겠습니까?';

  @override
  String get commentDeleted => '댓글이 삭제되었습니다';

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
  String get aiTutorChangePersona => 'AI 튜터 변경';

  @override
  String get aiTutorChangePersonaSubtitle => 'Nana, Sensei 또는 Riko로 전환';

  @override
  String aiTutorHeroTitleSet(String name) {
    return 'AI 튜터 · $name';
  }

  @override
  String get aiTutorHeroTitleNew => 'AI 튜터를 만나보세요';

  @override
  String get aiTutorHeroSubtitleSet => '탭하여 대화하거나 오늘의 학습 계획 보기';

  @override
  String aiTutorHeroSubtitleLast(String summary) {
    return '지난번: $summary';
  }

  @override
  String get aiTutorHeroSubtitleNew => '캐릭터를 선택하세요 — Nana, Sensei, Riko';

  @override
  String get aiTutorChipChat => '채팅';

  @override
  String get aiTutorChipRoleplay => '역할극';

  @override
  String get aiTutorChipStory => '스토리';

  @override
  String get aiTutorChipPhoto => '사진';

  @override
  String get aiToolsMoreSection => '더 많은 AI 도구';

  @override
  String get aiConversationPartnerTile => 'AI 대화';

  @override
  String get aiConversationPartnerTileSubtitle => 'AI 파트너와 연습하기';

  @override
  String get aiTutorPickerTitle => 'AI 튜터를 선택하세요';

  @override
  String get aiTutorPickerHeader => '누구와 함께 배우고 싶으세요?';

  @override
  String get aiTutorPickerSubtitle => '언제든 설정에서 변경할 수 있어요.';

  @override
  String get aiTutorPersonaNanaTagline => '따뜻함 + 격려';

  @override
  String get aiTutorPersonaNanaSample => '부담 없이 응원해 줄게요.';

  @override
  String get aiTutorPersonaSenseiTagline => '정확함 + 시험 중심';

  @override
  String get aiTutorPersonaSenseiSample => '규칙을 마스터해 봅시다.';

  @override
  String get aiTutorPersonaRikoTagline => '장난스러움 + 슬랭';

  @override
  String get aiTutorPersonaRikoSample => 'ㅎㅎ 즐겁게 배워보자';

  @override
  String aiTutorPickerSaveError(String error) {
    return '저장할 수 없습니다: $error';
  }

  @override
  String get aiTutorHomeTitle => 'AI 튜터';

  @override
  String get aiTutorHomeChangeTutor => '튜터 변경';

  @override
  String get aiTutorHomeGreetingDefault => '안녕! 함께 배울 준비됐어?';

  @override
  String get aiTutorHomeTodaysPlan => '오늘의 계획';

  @override
  String get aiTutorHomePlanEmpty => '오늘 계획이 없습니다 — 채팅을 시작해 보세요.';

  @override
  String get aiTutorHomeStartChat => '채팅 시작';

  @override
  String get aiTutorHomeRecent => '최근';

  @override
  String get aiTutorHomePracticeScenarios => '연습 시나리오';

  @override
  String get aiTutorHomePracticeScenariosSubtitle => '실제 대화를 롤플레이 — 식당, 면접, 호텔…';

  @override
  String get aiTutorHomeReadStory => '이야기 읽기';

  @override
  String get aiTutorHomeReadStorySubtitle => 'AI가 당신의 단어로 짧은 이야기를 쓰고 — 빠른 이해 질문을 합니다.';

  @override
  String get aiTutorHomeDescribePhoto => '사진 묘사하기';

  @override
  String get aiTutorHomeDescribePhotoSubtitle => '사진을 찍고 묘사하세요 — AI가 단어와 문법을 평가합니다.';

  @override
  String get aiTutorChatTitle => '튜터와 채팅';

  @override
  String get aiTutorChatVoiceOn => '음성 켜기';

  @override
  String get aiTutorChatVoiceOff => '음성 끄기';

  @override
  String get aiTutorChatStopRecording => '녹음 중지';

  @override
  String get aiTutorChatHoldToTalk => '길게 눌러 말하기';

  @override
  String get aiTutorChatTranscribing => '전사 중…';

  @override
  String get aiTutorChatListening => '듣는 중…';

  @override
  String get aiTutorChatInputHint => '메시지 입력…';

  @override
  String get aiTutorChatTypeReplyHint => '답장 입력…';

  @override
  String get aiTutorChatMicPermissionDenied => '음성 모드에 마이크 권한이 필요합니다.';

  @override
  String get aiTutorChatTranscribeFailed => '잘 못 들었어요 — 다시 시도하세요.';

  @override
  String aiTutorChatStartFailed(String error) {
    return '시작할 수 없습니다: $error';
  }

  @override
  String get aiTutorRoleplayEnd => '종료';

  @override
  String aiTutorRoleplayEndFailed(String error) {
    return '종료 실패: $error';
  }

  @override
  String get aiTutorRoleplayDone => '완료';

  @override
  String get aiTutorStoryTitle => '이야기 읽기';

  @override
  String get aiTutorStoryLength => '길이';

  @override
  String get aiTutorStoryTheme => '주제';

  @override
  String aiTutorStoryWordCount(int count) {
    return '$count개 단어';
  }

  @override
  String get aiTutorStoryWriting => '작성 중…';

  @override
  String get aiTutorStoryGenerate => '이야기 생성';

  @override
  String aiTutorStoryGenerateFailed(String error) {
    return '생성할 수 없습니다: $error';
  }

  @override
  String aiTutorStoryWordCountHint(int n) {
    return 'AI는 당신의 단어장에서 최대 $n개 단어를 사용합니다.';
  }

  @override
  String get aiTutorStoryThemeFree => '자유';

  @override
  String get aiTutorStoryThemeAdventure => '모험';

  @override
  String get aiTutorStoryThemeMystery => '미스터리';

  @override
  String get aiTutorStoryThemeRomance => '로맨스';

  @override
  String get aiTutorStoryThemeSciFi => 'SF';

  @override
  String get aiTutorStoryThemeSliceOfLife => '일상';

  @override
  String get aiTutorStoryReaderTitle => '이야기';

  @override
  String get aiTutorStoryReaderVocab => '단어';

  @override
  String get aiTutorStoryReaderVocabUsed => '사용된 단어';

  @override
  String aiTutorStoryReaderPart(int n) {
    return '$n부';
  }

  @override
  String get aiTutorStoryReaderWrongHint => '아쉽네요 — 계속 진행';

  @override
  String get aiTutorStoryReaderNiceWork => '잘했어요!';

  @override
  String aiTutorStoryReaderScore(int correct, int total) {
    return '이해 문제 $correct/$total개를 맞혔어요.';
  }

  @override
  String get aiTutorStoryReaderDone => '완료';

  @override
  String get aiTutorImageVocabTitle => '사진 묘사하기';

  @override
  String get aiTutorImagePickHeader => '묘사할 사진을 선택하세요';

  @override
  String get aiTutorImagePickSubtitle => 'AI가 목표 언어로 프롬프트를 주고, 당신의 묘사를 평가합니다.';

  @override
  String get aiTutorImagePickCamera => '카메라';

  @override
  String get aiTutorImagePickGallery => '갤러리';

  @override
  String aiTutorImagePickError(String error) {
    return '이미지를 열 수 없습니다: $error';
  }

  @override
  String get aiTutorImageDescriptionHint => '묘사를 입력하세요…';

  @override
  String get aiTutorImageDifferentPhoto => '다른 사진';

  @override
  String get aiTutorImageSubmit => '제출';

  @override
  String get aiTutorImageGrammarNotes => '문법 노트';

  @override
  String get aiTutorImageThingsYouMissed => '놓친 부분';

  @override
  String get aiTutorImageTryAnother => '다른 사진 시도';

  @override
  String get aiTutorCardQuiz => '퀴즈';

  @override
  String get aiTutorCardVocab => '단어';

  @override
  String get aiTutorCardGrammar => '문법';

  @override
  String get aiTutorCardReviewDue => '복습 예정';

  @override
  String get aiTutorCardMiniLesson => '미니 레슨';

  @override
  String get aiTutorCardAddToVocab => '단어에 추가';

  @override
  String get aiTutorCardAddedToVocab => '추가됨';

  @override
  String get aiTutorCardAdding => '추가 중…';

  @override
  String aiTutorCardReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count장의 카드가 기다리고 있어요',
      one: '$count장의 카드가 기다리고 있어요',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorCardReviewNow => '지금 복습';

  @override
  String get aiTutorCardReviewStarting => '시작 중…';

  @override
  String get aiTutorCardTryIt => '해 보기';

  @override
  String get aiTutorCardPracticing => '연습 중…';

  @override
  String aiTutorPlanSrsReview(int count, int done) {
    return 'SRS 카드 $count장 복습 ($done장 완료)';
  }

  @override
  String aiTutorPlanGrammar(String topic) {
    return '연습: $topic';
  }

  @override
  String aiTutorPlanChat(int min, int done) {
    return '$min분 채팅 (지금까지 $done분)';
  }

  @override
  String get aboutBananatalk => 'Bananatalk 정보';

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
  String get banaTalk => 'Bananatalk';

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
  String get conversationHistory => '대화 기록';

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
  String get goBack => '뒤로';

  @override
  String get messageSendTimeout => '메시지 전송 시간 초과. 연결을 확인하세요.';

  @override
  String get failedToSendMessage => '메시지 전송 실패';

  @override
  String get chatSendTooFast => '메시지를 너무 빨리 보내고 있어요. 잠시 후 다시 시도해 주세요.';

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
  String get receiveEmailNotificationsFromBananatalk => 'Bananatalk에서 이메일 알림 받기';

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
  String get languagesStepTitle => '내 언어';

  @override
  String get languagesStepSubtitle => '반대로 배우는 사람과 매칭해 드려요';

  @override
  String get languagesISpeak => '사용 언어';

  @override
  String get languagesImLearning => '배우는 언어';

  @override
  String get languagesSwap => '서로 바꾸기';

  @override
  String get languagesChoose => '언어 선택';

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
  String get communityTabRooms => '룸';

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
  String get noForYouMomentsTitle => '아직 모먼트가 없습니다';

  @override
  String get noForYouMomentsBody => '오늘의 주제에 답하고 대화를 시작해 보세요.';

  @override
  String get noFollowingMomentsTitle => '아직 아무것도 없습니다';

  @override
  String get noFollowingMomentsBody => '커뮤니티에서 사람들을 팔로우하면 이곳에서 그들의 모먼트를 볼 수 있습니다.';

  @override
  String get goToCommunity => '커뮤니티로 이동';

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
  String get exchange3MessagesBeforeCall => '이 사용자에게 전화하려면 최소 5개의 메시지를 교환해야 합니다';

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
  String get checkOutStory => 'Bananatalk에서 이 스토리를 확인하세요!';

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
  String get receiveEmailNotifications => 'Bananatalk에서 이메일 알림 받기';

  @override
  String get whenAwayFor24Hours => '24시간 이상 자리를 비웠을 때';

  @override
  String get passwordAndLoginAlerts => '비밀번호 및 로그인 알림';

  @override
  String get failedToLoadPreferences => '환경설정을 불러오지 못했습니다';

  @override
  String get failedToUpdateSetting => '설정을 업데이트하지 못했습니다';

  @override
  String get securityAlertsRecommended => '중요한 계정 활동을 계속 확인할 수 있도록 보안 알림을 켜두는 것을 권장합니다.';

  @override
  String chatWallpaperFor(String name) {
    return '$name님과의 채팅 배경화면';
  }

  @override
  String get solidColors => '단색';

  @override
  String get gradients => '그라데이션';

  @override
  String get customImage => '사용자 지정 이미지';

  @override
  String get chooseFromGallery => '갤러리에서 선택';

  @override
  String get preview => '미리보기';

  @override
  String get wallpaperUpdated => '배경화면이 업데이트되었습니다';

  @override
  String get category => '카테고리';

  @override
  String get mood => '기분';

  @override
  String get sortBy => '정렬 기준';

  @override
  String get timePeriod => '기간';

  @override
  String get searchLanguages => '언어 검색...';

  @override
  String get selected => '선택됨';

  @override
  String get categories => '카테고리';

  @override
  String get moods => '기분';

  @override
  String get applyFilters => '필터 적용';

  @override
  String applyNFilters(int count) {
    return '필터 $count개 적용';
  }

  @override
  String get videoMustBeUnder1GB => '동영상은 1GB 미만이어야 합니다.';

  @override
  String get failedToRecordVideo => '동영상 녹화에 실패했습니다';

  @override
  String get errorSendingVideo => '동영상 전송 오류';

  @override
  String get errorSendingVoiceMessage => '음성 메시지 전송 오류';

  @override
  String get errorSendingMedia => '미디어 전송 오류';

  @override
  String get cameraPermissionRequired => '동영상을 녹화하려면 카메라와 마이크 권한이 필요합니다.';

  @override
  String get locationPermissionRequired => '위치를 공유하려면 위치 권한이 필요합니다.';

  @override
  String get noInternetConnection => '인터넷 연결이 없습니다';

  @override
  String get tryAgainLater => '나중에 다시 시도해 주세요';

  @override
  String get messageSent => '메시지가 전송되었습니다';

  @override
  String get messageDeleted => '메시지가 삭제되었습니다';

  @override
  String get messageEdited => '메시지가 수정되었습니다';

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
  String get checkOutMoment => 'Bananatalk에서 이 모멘트를 확인해보세요!';

  @override
  String get checkOutProfile => 'Bananatalk에서 이 프로필을 확인해 보세요!';

  @override
  String get checkOutCommunity => 'Bananatalk에서 이 멤버를 확인해 보세요!';

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
  String get deletionReasonTitle => '떠나시기 전에 — 이유를 알려주세요';

  @override
  String get deletionReasonOptional => '선택 사항입니다. 개선에 도움이 됩니다.';

  @override
  String get deletionReasonNoPeople => '대화할 사람을 찾지 못했어요';

  @override
  String get deletionReasonNoContent => '제 언어로 된 학습 자료가 없어요';

  @override
  String get deletionReasonNotUseful => '기대했던 것과 달랐어요';

  @override
  String get deletionReasonBugs => '앱이 제대로 작동하지 않았어요';

  @override
  String get deletionReasonNotifications => '알림이 너무 많았어요';

  @override
  String get deletionReasonPrivacy => '개인정보가 걱정돼요';

  @override
  String get deletionReasonOther => '기타';

  @override
  String get deletionReasonHint => '자세히 알려주세요 (선택)';

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
  String get locationOptional => '계속하려면 위치를 설정해 주세요';

  @override
  String get maximum6Photos => '최대 6장';

  @override
  String get tapToDetectLocation => '탭하여 위치 감지';

  @override
  String get optionalHelpsNearbyPartners => '필수 — 근처 파트너 매칭에 도움됩니다';

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
  String get confirmPasswordHint => '새 비밀번호를 다시 입력하세요';

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
  String get dataProtectedEncryption => '데이터는 업계 표준 암호화로 보호됩니다';

  @override
  String get welcomeCompleteProfile => '환영합니다! 프로필을 완성해 주세요';

  @override
  String get authWelcomeTagline => '만나다 · 대화하다 · 연결하다';

  @override
  String get authWelcomeCtaTitle => 'Bananatalk에서 전 세계 친구를 만들어보세요';

  @override
  String get authWelcomeCtaSubtitle => '지금 수백만 명의 언어 학습자와 함께하세요';

  @override
  String get authWelcomeFeatureConnectTitle => '연결';

  @override
  String get authWelcomeFeatureConnectSubtitle => '전 세계 150개 이상의 국가에서 언어 파트너를 만나보세요';

  @override
  String get authWelcomeFeatureLearnTitle => '학습';

  @override
  String get authWelcomeFeatureLearnSubtitle => 'AI 튜터, 퀴즈, 발음 훈련까지 — 하나의 앱에서';

  @override
  String get authWelcomeFeatureGrowTitle => '성장';

  @override
  String get authWelcomeFeatureGrowSubtitle => '매일의 대화와 커뮤니티를 통해 진짜 유창함을 키워보세요';

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
  String get allCategories => '모든 카테고리';

  @override
  String get leaderboard => '리더보드';

  @override
  String get competeWithLearners => '다른 학습자들과 경쟁해 보세요!';

  @override
  String get xpRankings => 'XP 순위';

  @override
  String get streaks => '연속 기록';

  @override
  String get friends => '친구';

  @override
  String get myRanks => '내 랭킹';

  @override
  String get currentStreak => '현재 연속 기록';

  @override
  String get longestStreak => '최장 연속 기록';

  @override
  String get weekly => '주간';

  @override
  String get monthly => '월간';

  @override
  String get yourRank => '내 순위';

  @override
  String outOf(int total) {
    return '$total명 중';
  }

  @override
  String topPercent(String percent) {
    return '상위 $percent%';
  }

  @override
  String get xpRank => 'XP 랭크';

  @override
  String get streakRank => '연속 기록 순위';

  @override
  String get days => '일';

  @override
  String get learningStats => '학습 통계';

  @override
  String get totalXp => '총 XP';

  @override
  String get lessonsCompleted => '완료한 레슨';

  @override
  String get rankings => '순위';

  @override
  String get yourPosition => '내 위치';

  @override
  String get keepLearning => '계속 학습해서 순위를 올려보세요!';

  @override
  String get noRankingsYet => '아직 순위가 없습니다';

  @override
  String get startLearningToAppear => '학습을 시작하면 리더보드에 나타납니다!';

  @override
  String get noFriendsYet => '아직 친구가 없습니다';

  @override
  String get addFriendsToCompete => '친구를 추가해서 경쟁해 보세요!';

  @override
  String get failedToLoadLeaderboard => '리더보드를 불러오지 못했습니다';

  @override
  String get you => '나';

  @override
  String get findPartners => '파트너 찾기';

  @override
  String get discoverLanguagePartners => '언어 파트너 찾아보기';

  @override
  String get byLanguage => '언어별';

  @override
  String get match => '매치';

  @override
  String get matchScore => '매치 점수';

  @override
  String get noMatchesFound => '일치하는 결과가 없습니다';

  @override
  String get noUsersOnline => '온라인 사용자가 없습니다';

  @override
  String get checkBackLater => '나중에 다시 확인해 주세요';

  @override
  String get selectLanguagePrompt => '언어를 선택하세요';

  @override
  String get findPartnersByLanguage => '이 언어를 사용하거나 배우는 파트너 찾기';

  @override
  String noPartnersForLanguage(String language) {
    return '$language에 대한 파트너가 없습니다';
  }

  @override
  String get tryAnotherLanguage => '다른 언어를 선택해 보세요';

  @override
  String get failedToLoadMatches => '매치 정보를 불러오지 못했습니다';

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
  String get profileUpdatedSuccessfully => '프로필이 성공적으로 업데이트되었습니다';

  @override
  String get genderRequired => '성별 (필수)';

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
  String get bloodTypeSavedSuccessfully => '혈액형이 성공적으로 저장되었습니다';

  @override
  String get hometownSavedSuccessfully => '고향이 성공적으로 저장되었습니다';

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
  String get aiTools => '연습';

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
  String get loadingLanguages => '언어를 불러오는 중...';

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
  String get noBlockedUsers => '차단된 사용자가 없습니다';

  @override
  String get usersYouBlockWillAppearHere => '차단한 사용자가 여기에 표시됩니다';

  @override
  String unblockConfirm(String name) {
    return '$name님을 차단 해제하시겠습니까?';
  }

  @override
  String reasonLabel(String reason) {
    return '사유: $reason';
  }

  @override
  String blockedAgo(String time) {
    return '$time 차단됨';
  }

  @override
  String errorLoadingBlockedUsers(String error) {
    return '차단된 사용자를 불러오는 중 오류 발생: $error';
  }

  @override
  String get logoutConfirmMessage => 'Bananatalk에서 로그아웃하시겠습니까?';

  @override
  String get loggingOut => '로그아웃 중...';

  @override
  String get quietHours => '방해 금지 시간';

  @override
  String get quietHoursEnable => '방해 금지 시간 사용';

  @override
  String get quietHoursSubtitle => '지정한 시간 동안 긴급하지 않은 알림을 일시 중지합니다';

  @override
  String get quietHoursStart => '시작 시간';

  @override
  String get quietHoursEnd => '종료 시간';

  @override
  String get quietHoursAllowUrgent => '긴급 알림 허용';

  @override
  String get quietHoursAllowUrgentSubtitle => 'VIP 파트너의 전화와 메시지는 계속 수신됩니다';

  @override
  String get silencedByQuietHours => '방해 금지 시간으로 인해 무음 처리됨';

  @override
  String get silencedByCap => '일일 한도로 인해 무음 처리됨';

  @override
  String get momentUpdatedSuccessfully => '모멘트가 성공적으로 업데이트되었습니다';

  @override
  String get failedToDeleteMoment => '모멘트 삭제에 실패했습니다';

  @override
  String get failedToUpdateMoment => '모멘트 업데이트에 실패했습니다';

  @override
  String get mbtiUpdatedSuccessfully => 'MBTI가 성공적으로 업데이트되었습니다';

  @override
  String get pleaseSelectMbti => 'MBTI 유형을 선택해 주세요';

  @override
  String get languageUpdatedSuccessfully => '언어가 성공적으로 업데이트되었습니다';

  @override
  String get bioHintCard => '좋은 자기소개는 다른 사람들이 나와 연결하는 데 도움이 됩니다. 관심사, 사용 언어, 또는 찾고 있는 것을 공유해 보세요.';

  @override
  String get bioCounterStartWriting => '작성을 시작하세요...';

  @override
  String get bioCounterABitMore => '조금 더 작성하면 좋겠어요';

  @override
  String get bioCounterAlmostAtLimit => '거의 한도에 달했어요';

  @override
  String get bioCounterTooLong => '너무 길어요';

  @override
  String get bioQuickStarters => '빠른 시작';

  @override
  String get rhPositive => 'Rh 양성';

  @override
  String get rhNegative => 'Rh 음성';

  @override
  String get rhPositiveDesc => '가장 흔한 혈액형';

  @override
  String get rhNegativeDesc => '만능 공혈자 / 희귀';

  @override
  String get yourBloodType => '혈액형';

  @override
  String get noBloodTypeSelected => '혈액형이 선택되지 않았습니다';

  @override
  String get tapTypeBelow => '아래에서 혈액형을 선택하세요';

  @override
  String get tapButtonToDetectLocation => '아래 버튼을 눌러 현재 위치를 감지하세요';

  @override
  String currentAddressLabel(String address) {
    return '현재: $address';
  }

  @override
  String get onlyCityCountryShown => '다른 사람들에게는 도시와 국가만 표시됩니다. 정확한 좌표는 비공개로 유지됩니다.';

  @override
  String get updateLocationCta => '위치 업데이트';

  @override
  String get enterYourName => '이름을 입력하세요';

  @override
  String get unsavedChanges => '저장되지 않은 변경 사항이 있습니다';

  @override
  String tapBelowToBrowseLanguages(int count) {
    return '아래를 탭하여 $count개 언어 중 선택';
  }

  @override
  String get changeLanguage => '언어 변경';

  @override
  String get browseLanguages => '언어 찾기';

  @override
  String get yourLearningLanguageIsPrefix => '학습 중인 언어: ';

  @override
  String get yourNativeLanguageIsPrefix => '모국어: ';

  @override
  String get profileCompleteProgress => '완료';

  @override
  String get drawerPreferences => '환경설정';

  @override
  String get drawerStorage => '저장공간';

  @override
  String get drawerReports => '신고';

  @override
  String get drawerSupport => '고객지원';

  @override
  String get drawerAccount => '계정';

  @override
  String get logoutConfirmBody => 'Bananatalk에서 로그아웃하시겠습니까?';

  @override
  String get helpEmailSupport => '이메일 지원';

  @override
  String get helpEmailSupportSubtitle => 'support@bananatalk.com';

  @override
  String get helpReportBug => '버그 신고';

  @override
  String get helpReportBugSubtitle => 'Bananatalk 개선에 도움을 주세요';

  @override
  String get helpFaqs => '자주 묻는 질문';

  @override
  String get helpFaqsSubtitle => '자주 하는 질문들';

  @override
  String get aboutDialogClose => '닫기';

  @override
  String get aboutBananatalkTagline => '전 세계 언어 학습자와 연결하고 실제 대화를 통해 실력을 키워보세요.';

  @override
  String get aboutCopyright => '© 2024 Bananatalk. 무단 전재 금지.';

  @override
  String get logoutFailedPrefix => '로그아웃 실패';

  @override
  String get profileVisitorsTitle => '프로필 방문자';

  @override
  String get visitorStatistics => '방문자 통계';

  @override
  String get visitorsTotalVisits => '총 방문 수';

  @override
  String get visitorsUniqueVisitors => '고유 방문자';

  @override
  String get visitorsToday => '오늘';

  @override
  String get visitorsThisWeek => '이번 주';

  @override
  String get noVisitorsYet => '아직 방문자가 없습니다';

  @override
  String get noVisitorsYetSubtitle => '누군가 프로필을 방문하면\n여기에 표시됩니다';

  @override
  String get visitedViaSearch => '검색을 통해';

  @override
  String get visitedViaMoments => '모멘트를 통해';

  @override
  String get visitedViaChat => '채팅을 통해';

  @override
  String get visitedDirect => '직접 방문';

  @override
  String get visitorTrackingUnavailable => '방문자 추적 기능을 사용할 수 없습니다. 백엔드를 업데이트해 주세요.';

  @override
  String get visitorTrackingNotAvailableYet => '방문자 추적은 아직 사용할 수 없습니다';

  @override
  String get noFollowersYetSubtitle => '다른 사람들과 연결을 시작하세요!';

  @override
  String get partnerButton => '파트너';

  @override
  String get notFollowingAnyoneYetSubtitle => '팔로우하여 업데이트를 확인하세요!';

  @override
  String get unfollowButton => '언팔로우';

  @override
  String get profileThemeTitle => '프로필 테마';

  @override
  String get themeAutoSwitch => '자동 전환 (시스템 테마)';

  @override
  String get themeSystemHint => '활성화하면 앱이 시스템 테마 설정을 따릅니다';

  @override
  String get themeLightMode => '라이트 모드';

  @override
  String get themeDarkMode => '다크 모드';

  @override
  String get myMoments => '내 모멘트';

  @override
  String get momentListView => '목록 보기';

  @override
  String get momentGridView => '그리드 보기';

  @override
  String get shareLanguageLearningJourney => '언어 학습 여정을 공유하세요!';

  @override
  String get deleteHighlightTitle => '하이라이트 삭제';

  @override
  String deleteHighlightConfirm(String title) {
    return '\"$title\"을(를) 삭제할까요? 안에 있는 스토리는 삭제되지 않습니다.';
  }

  @override
  String get highlightDeletedSuccess => '하이라이트가 삭제되었습니다';

  @override
  String get highlightNewBadge => '새로운';

  @override
  String get editMoment => '모멘트 편집';

  @override
  String get momentDescriptionLabel => '설명';

  @override
  String get momentImagesLabel => '이미지';

  @override
  String get noImagesYet => '아직 이미지가 없습니다';

  @override
  String get momentEnterDescription => '설명을 입력해 주세요';

  @override
  String get momentUpdatedImageFailed => '모멘트는 업데이트되었지만 이미지 업로드에 실패했습니다';

  @override
  String get updateRequiredTitle => '업데이트 필요';

  @override
  String get updateAvailableTitle => '업데이트 가능';

  @override
  String get updateRequiredBody => '이 버전의 Bananatalk는 더 이상 지원되지 않습니다. 계속하려면 업데이트하세요.';

  @override
  String get updateAvailableBody => '개선 사항 및 버그 수정이 포함된 Bananatalk의 새 버전이 출시되었습니다.';

  @override
  String get updateNow => '지금 업데이트';

  @override
  String get updateLater => '나중에';

  @override
  String get updateOpenStoreFailed => '스토어를 열 수 없습니다. App Store 또는 Play Store에서 업데이트하세요.';

  @override
  String get rememberMe => '자동 로그인';

  @override
  String get passwordWeak => '약함';

  @override
  String get passwordFair => '보통';

  @override
  String get passwordStrong => '강함';

  @override
  String get passwordVeryStrong => '매우 강함';

  @override
  String get showPassword => '비밀번호 표시';

  @override
  String get hidePassword => '비밀번호 숨기기';

  @override
  String stepProgress(int current, int total) {
    return '단계 $current / $total';
  }

  @override
  String get usernameOptional => '사용자 이름 (선택사항)';

  @override
  String get usernameAvailable => '사용 가능';

  @override
  String get usernameTaken => '이미 사용 중';

  @override
  String get usernameNotAvailable => '사용할 수 없음';

  @override
  String get usernameInvalidFormat => '3~20자, 영문/숫자/밑줄';

  @override
  String get usernameHint => '@사용자이름';

  @override
  String get enableBiometricTitle => '다음에 Face ID로 로그인할까요?';

  @override
  String get enableBiometricBody => '생체 인증으로 비밀번호 입력 없이 로그인할 수 있습니다.';

  @override
  String get enableBiometricCta => '사용 설정';

  @override
  String get biometricSignInPrompt => 'Bananatalk에 로그인하려면 인증하세요';

  @override
  String get biometricNotAvailable => '이 기기에서는 생체 인증 로그인을 사용할 수 없어요. 비밀번호로 로그인해 주세요.';

  @override
  String get biometricNotEnrolled => '이 기기에 Face ID나 지문이 등록되어 있지 않아요. 설정에서 등록하거나 비밀번호로 로그인해 주세요.';

  @override
  String get biometricLockedOut => '시도 횟수가 너무 많아요. 생체 인증이 잠시 잠겼어요. 나중에 다시 시도하거나 비밀번호로 로그인해 주세요.';

  @override
  String get biometricPermanentlyLockedOut => '생체 인증이 잠겼어요. 기기 암호로 잠금을 해제한 뒤 다시 시도해 주세요.';

  @override
  String get biometricPasscodeNotSet => '생체 인증 로그인을 사용하려면 기기 암호를 설정해 주세요.';

  @override
  String continueAs(String name) {
    return '$name(으)로 계속';
  }

  @override
  String get addProfilePhotoTitle => '프로필 사진 추가';

  @override
  String get addProfilePhotoSkip => '건너뛰기';

  @override
  String get wavesTab => '웨이브';

  @override
  String get sendWave => '웨이브 보내기';

  @override
  String sendWaveTo(String name) {
    return '$name에게 웨이브 보내기';
  }

  @override
  String waveSent(String name) {
    return '$name에게 웨이브를 보냈어요';
  }

  @override
  String waveCooldown(String name, String time) {
    return '$time 후에 $name에게 다시 웨이브를 보낼 수 있어요';
  }

  @override
  String get waveCouldntSend => '웨이브를 보낼 수 없어요';

  @override
  String get itsAMatch => '매칭 성공!';

  @override
  String itsAMatchSubtitle(String name) {
    return '$name님과 서로 웨이브를 보냈어요';
  }

  @override
  String get sendAMessage => '메시지 보내기';

  @override
  String get waveQuickReplyHi => '안녕!';

  @override
  String get waveQuickReplyCool => '멋져 보여요';

  @override
  String get waveQuickReplyHey => '안녕하세요';

  @override
  String get waveQuickReplyChat => '대화해요';

  @override
  String get waveQuickReplyHello => '반가워요';

  @override
  String waveQuickReplyFromCountry(String country) {
    return '$country에서 안녕!';
  }

  @override
  String get waveCustomMessage => '직접 메시지를 작성해 보세요…';

  @override
  String get voiceRoomChat => '채팅';

  @override
  String get voiceRoomChatPlaceholder => '메시지 보내기…';

  @override
  String get voiceRoomChatEmpty => '아직 메시지가 없어요 — 인사해 보세요';

  @override
  String get voiceRoomChatSend => '보내기';

  @override
  String voiceRoomChatNewBadge(int n) {
    return '$n';
  }

  @override
  String get voiceRoomEnd => '방 종료';

  @override
  String get voiceRoomEndConfirm => '이 방을 종료할까요?';

  @override
  String get voiceRoomEndConfirmBody => '모든 참가자가 연결이 끊깁니다.';

  @override
  String get voiceRoomKick => '방에서 내보내기';

  @override
  String voiceRoomKickConfirm(String name) {
    return '$name님을 내보낼까요?';
  }

  @override
  String get voiceRoomKicked => '내보내졌습니다';

  @override
  String get voiceRoomYouAreHostNow => '이제 호스트가 되었어요';

  @override
  String voiceRoomHostChanged(String name) {
    return '$name님이 호스트가 되었어요';
  }

  @override
  String get voiceRoomHostMenuTitle => '방 관리';

  @override
  String get voiceRoomViewProfile => '프로필 보기';

  @override
  String get voiceRoomReconnecting => '재연결 중…';

  @override
  String get voiceRoomReconnected => '재연결되었습니다';

  @override
  String get voiceRoomEnded => '방이 종료되었습니다';

  @override
  String get voiceRoomReconnectRetry => '다시 시도';

  @override
  String get mutualInterests => '공통 관심사';

  @override
  String interestsInCommon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '공통 관심사 $count개',
      one: '공통 관심사 1개',
      zero: '아직 공통 관심사가 없어요',
    );
    return '$_temp0';
  }

  @override
  String get interestsInCommonSeeAll => '모두 보기';

  @override
  String get interestsInCommonAddCta => '주제 추가';

  @override
  String get interestsInCommonAddSubtitle => '프로필에 주제를 추가해 공통점을 찾아보세요';

  @override
  String activeAgo(String time) {
    return '$time 전에 활동';
  }

  @override
  String get filterOnlineNow => '지금 온라인';

  @override
  String get filterAge => '나이';

  @override
  String get filterGender => '성별';

  @override
  String get filterLanguages => '언어';

  @override
  String get filterCountry => '국가';

  @override
  String get filterTopics => '주제';

  @override
  String get filterLevel => '언어 수준';

  @override
  String get filterToggles => '기타';

  @override
  String filterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '파트너 $count명 일치',
      one: '파트너 1명 일치',
      zero: '일치하는 파트너 없음',
    );
    return '$_temp0';
  }

  @override
  String get filterClearAll => '전체 지우기';

  @override
  String get filterReset => '초기화';

  @override
  String get filterApply => '적용';

  @override
  String get filterNewUsers => '신규 사용자만';

  @override
  String get filterPrioritizeNearby => '근처 우선';

  @override
  String get filterSheetTitle => '필터';

  @override
  String get notificationPreferencesTitle => '알림';

  @override
  String get notificationPreferencesSubtitle => '받을 알림을 선택하세요';

  @override
  String get notifPrefChat => '새 메시지';

  @override
  String get notifPrefWave => '웨이브';

  @override
  String get notifPrefVoiceRoomStart => '음성 방 초대';

  @override
  String get notifPrefScheduledRoomReminder => '예정된 방 알림';

  @override
  String get notifPrefFollowerMoment => '팔로우한 사람들의 새 모멘트';

  @override
  String get notifPrefVisitorAlert => '프로필 방문자';

  @override
  String get notifPrefMatchAlert => '서로 웨이브';

  @override
  String get notifResetToDefaults => '기본값으로 재설정';

  @override
  String get themeMode => '테마';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get themeSystem => '시스템';

  @override
  String get languageSettingsRow => '언어';

  @override
  String get waveDailySummaryTitle => '새로운 웨이브가 있습니다';

  @override
  String waveDailySummaryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count명이 웨이브를 보냈습니다',
      one: '1명이 웨이브를 보냈습니다',
    );
    return '$_temp0';
  }

  @override
  String get filterTopicsTitle => '주제';

  @override
  String get filterTopicsEmpty => '선택된 주제가 없습니다';

  @override
  String get storiesEmpty => '아직 스토리가 없습니다';

  @override
  String get storiesLoadError => '스토리를 불러올 수 없습니다';

  @override
  String get storiesRetry => '다시 시도';

  @override
  String get storiesNoMore => '모두 확인하셨습니다';

  @override
  String get createTextStoryTab => '텍스트';

  @override
  String get createImageStoryTab => '사진';

  @override
  String get createVideoStoryTab => '동영상';

  @override
  String get enterTextHint => '탭하여 입력';

  @override
  String get pickBackground => '배경';

  @override
  String get pickFontStyle => '글꼴';

  @override
  String get pickTextColor => '색상';

  @override
  String get addEmoji => '이모지 추가';

  @override
  String get chooseFont => '글꼴 선택';

  @override
  String get chooseColor => '색상 선택';

  @override
  String get dragToMove => '드래그하여 이동';

  @override
  String get pinchToScale => '핀치하여 크기 조정';

  @override
  String get removeFromHighlight => '하이라이트에서 제거';

  @override
  String get highlightDeleted => '하이라이트가 삭제되었습니다';

  @override
  String get storySaved => '내 스토리에 저장되었습니다';

  @override
  String get storyTooLong => '텍스트가 너무 깁니다';

  @override
  String get storyPostFailed => '스토리를 게시할 수 없습니다';

  @override
  String get fontNormal => '보통';

  @override
  String get fontBold => '굵게';

  @override
  String get fontItalic => '기울임';

  @override
  String get fontHandwriting => '손글씨';

  @override
  String get pickDate => '날짜 선택';

  @override
  String get pickTime => '시간 선택';

  @override
  String get upcomingRooms => '예정된';

  @override
  String inHours(int h, int m) {
    return '$h시간 $m분 후';
  }

  @override
  String inMinutes(int m) {
    return '$m분 후';
  }

  @override
  String get startsNow => '지금 시작';

  @override
  String get iWillBeThere => '참여할게요';

  @override
  String get cantMakeIt => '참여하기 어렵습니다';

  @override
  String rsvpCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count명 참여',
      one: '1명 참여',
      zero: '참여 없음',
    );
    return '$_temp0';
  }

  @override
  String roomStartsIn1h(String title) {
    return '$title이(가) 1시간 후에 시작합니다';
  }

  @override
  String roomStartsIn15min(String title) {
    return '$title이(가) 15분 후에 시작합니다';
  }

  @override
  String roomStarted(String title) {
    return '$title이(가) 지금 시작합니다';
  }

  @override
  String get cancelRoom => '방 취소';

  @override
  String get muteAll => '전체 음소거';

  @override
  String get mutedByHost => '호스트가 모두를 음소거했습니다';

  @override
  String get muteAllConfirm => '방의 모든 참가자를 음소거할까요?';

  @override
  String get categoryCasual => '캐주얼';

  @override
  String get categoryLanguagePractice => '언어 연습';

  @override
  String get categoryTopic => '주제';

  @override
  String get categoryQA => 'Q&A';

  @override
  String get pickCategory => '카테고리';

  @override
  String get sortRecentlyActive => '최근 활동순';

  @override
  String visitedYourProfile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count명이 내 프로필을 방문했습니다',
      one: '1명이 내 프로필을 방문했습니다',
    );
    return '$_temp0';
  }

  @override
  String get noRecentVisitors => '최근 방문자가 없습니다';

  @override
  String get viewArchive => '아카이브 보기';

  @override
  String get archivedWaves => '보관된 Wave';

  @override
  String get noArchivedWaves => '보관된 Wave 없음';

  @override
  String get mutualInterestsMin => '공통 관심사 (최소)';

  @override
  String atLeastNTopics(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '최소 $n개 공통 주제',
      one: '최소 1개 공통 주제',
      zero: '상관없음',
    );
    return '$_temp0';
  }

  @override
  String get starterAskMoment => '최근 기억에 남는 순간 물어보기';

  @override
  String get starterSayHi => '상대방 언어로 인사하기';

  @override
  String get starterCurious => '무엇이 궁금한가요?';

  @override
  String starterFromCountry(String country) {
    return '$country에서 안녕하세요!';
  }

  @override
  String starterPracticeLang(String language) {
    return '$language 연습을 도와드릴게요!';
  }

  @override
  String get momentsLoadError => '모먼트를 불러올 수 없습니다';

  @override
  String get momentsRetry => '다시 시도';

  @override
  String get recentTags => '최근 태그';

  @override
  String get noRecentTags => '최근 태그가 없습니다';

  @override
  String get hideMomentsFromUser => '이 사용자의 모먼트 숨기기';

  @override
  String get momentsHidden => '이 사용자의 모먼트가 숨겨집니다';

  @override
  String get unhideMoments => '이 사용자의 모먼트 다시 표시';

  @override
  String momentsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사용자 $count명 숨김',
      one: '사용자 1명 숨김',
      zero: '숨긴 사용자 없음',
    );
    return '$_temp0';
  }

  @override
  String get momentSaveFailed => '모먼트를 저장할 수 없습니다';

  @override
  String get tagAlreadyAdded => '이미 추가된 태그입니다';

  @override
  String get tagLimitReached => '최대 태그 수에 도달했습니다';

  @override
  String get hideThisUser => '이 사용자의 게시물 숨기기';

  @override
  String get transcribeMessage => '텍스트로 변환';

  @override
  String get transcribing => '변환 중…';

  @override
  String get transcriptionFailed => '음성을 변환할 수 없습니다';

  @override
  String saveToVocabulary(String word) {
    return '\'$word\'을(를) 단어장에 저장';
  }

  @override
  String get addedToVocabulary => '단어장에 추가되었습니다';

  @override
  String get alreadyInVocabulary => '이미 단어장에 있습니다';

  @override
  String get tapWordToSave => '단어를 길게 눌러 저장하세요';

  @override
  String get autoTranslateChatHint => '수신 메시지가 자동으로 번역됩니다';

  @override
  String get noConversationsYet => '아직 대화가 없습니다';

  @override
  String get chatRetry => '다시 시도';

  @override
  String get learningHubTitle => '학습';

  @override
  String get learningCommonRetry => '다시 시도';

  @override
  String get learningCommonContinue => '계속';

  @override
  String get learningCommonAwesome => '대단해요!';

  @override
  String get learningErrorGeneric => '문제가 발생했습니다';

  @override
  String get learningStreakCurrent => '현재 스트릭';

  @override
  String get learningStreakLongest => '최장 스트릭';

  @override
  String learningStreakDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
    );
    return '$_temp0';
  }

  @override
  String learningStreakFreezeAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 프리즈 사용 가능',
      zero: '사용 가능한 프리즈 없음',
    );
    return '$_temp0';
  }

  @override
  String get learningStreakFreezeUse => '동결 사용';

  @override
  String get learningStreakFreezeDescription => '프리즈는 하루를 놓쳐도 스트릭을 보호합니다.';

  @override
  String get learningStreakFreezeProtected => '스트릭 보호됨!';

  @override
  String get learningStreakMilestone7 => '7일 스트릭!';

  @override
  String get learningStreakMilestone30 => '30일 스트릭!';

  @override
  String get learningStreakMilestone100 => '100일 스트릭!';

  @override
  String get learningStreakMilestone365 => '365일 스트릭!';

  @override
  String get learningWeeklyDigestTitle => '이번 주';

  @override
  String learningWeeklyDigestXp(int xp) {
    return '$xp XP 획득';
  }

  @override
  String learningWeeklyDigestLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 수업',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestVocab(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 단어 학습',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestDaysActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 활동',
    );
    return '$_temp0';
  }

  @override
  String get learningWeeklyDigestTopAchievement => '최고 업적';

  @override
  String learningWeeklyDigestTrendUp(int pct) {
    return '지난주보다 $pct% 증가';
  }

  @override
  String learningWeeklyDigestTrendDown(int pct) {
    return '지난주보다 $pct% 감소';
  }

  @override
  String get learningWeeklyDigestTrendFlat => '지난주와 동일';

  @override
  String get learningSrsDashboardTitle => '매일 복습';

  @override
  String learningSrsDueToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오늘 $count장',
      zero: '오늘 카드 없음',
    );
    return '$_temp0';
  }

  @override
  String learningSrsDueTomorrow(int count) {
    return '내일 $count장';
  }

  @override
  String learningSrsDueThisWeek(int count) {
    return '이번 주 $count장';
  }

  @override
  String get learningSrsStartReview => '복습 시작';

  @override
  String get learningSrsAllCaughtUp => '모두 완료했습니다!';

  @override
  String get learningSrsKeepGoing => '계속 하세요';

  @override
  String get learningLeaderboardXpTab => 'XP';

  @override
  String get learningLeaderboardStreakTab => '스트릭';

  @override
  String get learningLeaderboardLanguageTab => '언어';

  @override
  String get learningLeaderboardFriendsTab => '친구';

  @override
  String get learningLeaderboardEmpty => '아직 순위 없음';

  @override
  String get learningLeaderboardYouLabel => '나';

  @override
  String get learningLeaderboardFriendBadge => '친구';

  @override
  String get learningEmptyVocab => '기억하고 싶은 단어를 추가하세요';

  @override
  String get learningEmptyLessons => '아직 수업이 없습니다';

  @override
  String get learningEmptyQuizzes => '퀴즈가 없습니다';

  @override
  String get learningEmptyChallenges => '내일 다시 확인하세요';

  @override
  String get learningEmptyAchievements => '첫 번째 업적을 획득하세요';

  @override
  String get learningEmptySearchResults => '결과를 찾을 수 없습니다';

  @override
  String learningXpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String get learningLevelUp => '레벨 업!';

  @override
  String learningLevelReached(String level) {
    return '$level에 도달했습니다';
  }

  @override
  String get learningAchievementUnlocked => '업적 달성';

  @override
  String get learningVocabularySearchHint => '단어 검색';

  @override
  String get learningVocabularyFilterAll => '전체';

  @override
  String get learningVocabularyFilterNew => '새로운';

  @override
  String get learningVocabularyFilterLearning => '학습 중';

  @override
  String get learningVocabularyFilterMastered => '완숙';

  @override
  String get learningVocabularySortRecent => '최근';

  @override
  String get learningVocabularySortAlphabetical => '알파벳순';

  @override
  String get learningVocabularySortMastery => '숙련도';

  @override
  String get learningVocabularyMasteryNew => '새로운';

  @override
  String get learningVocabularyMasteryLearning => '학습 중';

  @override
  String get learningVocabularyMasteryMastered => '완숙';

  @override
  String get learningProgressLevelLabel => '레벨';

  @override
  String learningProgressXpToNextLevel(int xp) {
    return '다음 레벨까지 $xp XP';
  }

  @override
  String get learningProgressWeeklyChartTitle => '최근 7일';

  @override
  String get aiTutorPronounceLoading => '문장을 고르고 있어요…';

  @override
  String get aiTutorPronounceTapToRecord => '녹음하려면 누르세요';

  @override
  String get aiTutorPronounceTapToStop => '중지하려면 누르세요';

  @override
  String get aiTutorPronounceTranscribing => '듣는 중…';

  @override
  String get aiTutorPronounceTryAgain => '다시 시도';

  @override
  String get aiTutorPronounceNext => '다음';

  @override
  String get aiTutorPronounceUseYourOwn => '내 문장 ✏️';

  @override
  String get aiTutorPronounceCustomHint => '연습하고 싶은 문장을 입력';

  @override
  String get aiTutorPronounceCustomCancel => '취소';

  @override
  String get aiTutorPronounceCustomUse => '사용';

  @override
  String get aiTutorPronounceQuitConfirm => '드릴을 종료할까요? 진행 상황이 저장되지 않습니다.';

  @override
  String get aiTutorPronounceQuitYes => '예';

  @override
  String get aiTutorPronounceQuitNo => '아니오';

  @override
  String aiTutorPronounceSentenceOf(int current, int total) {
    return '$total개 중 $current번째 문장';
  }

  @override
  String get aiTutorPronounceSummaryTitle => '드릴 완료';

  @override
  String get aiTutorPronounceSummaryAvg => '평균 점수';

  @override
  String get aiTutorPronounceSummaryWeak => '연습할 단어';

  @override
  String get aiTutorPronounceSaveClose => '저장 및 닫기';

  @override
  String get aiTutorPronounceSaving => '저장 중…';

  @override
  String get aiTutorChipPronounce => '발음';

  @override
  String aiTutorPlanPronunciation(int count, int completed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '발음 드릴 ($completed/$count)',
      one: '발음 드릴 ($completed/1)',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorPronounceStartHeadline => '어떻게 연습할까요?';

  @override
  String get aiTutorPronounceStartSubhead => '5문장 드릴을 시작하려면 하나 선택하세요.';

  @override
  String get aiTutorPronounceStartAITitle => 'AI가 문장 생성';

  @override
  String get aiTutorPronounceStartAISubtitle => '레벨에 맞춤, 어려운 단어 위주';

  @override
  String get aiTutorPronounceStartCustomTitle => '내 문장 사용';

  @override
  String get aiTutorPronounceStartCustomSubtitle => '마스터하고 싶은 문구를 입력하거나 붙여넣으세요';

  @override
  String aiTutorQuotaRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오늘 $count회 남음',
      one: '오늘 1회 남음',
    );
    return '$_temp0';
  }

  @override
  String get submit => '제출';

  @override
  String get exit => '종료';

  @override
  String get previous => '이전';

  @override
  String get aiDailyPracticeTitle => '매일 연습';

  @override
  String get aiDailyPracticeTranslateThis => '이것을 번역하세요:';

  @override
  String get aiDailyPracticeSuggested => '제안:';

  @override
  String get aiDailyPracticeHint => '당신의 번역';

  @override
  String get aiLanguagesLoading => '언어 로딩 중...';

  @override
  String get aiCopiedToClipboard => '클립보드에 복사됨';

  @override
  String get aiGrammarHint => '분석할 텍스트 입력...';

  @override
  String get aiGrammarSectionOriginal => '원문';

  @override
  String get aiGrammarSectionCorrected => '교정된 문장';

  @override
  String aiGrammarSectionIssues(int count) {
    return '발견된 문제 ($count)';
  }

  @override
  String get aiGrammarSectionWell => '잘한 점';

  @override
  String get aiGrammarSectionSuggestions => '제안';

  @override
  String get aiGrammarSectionSummary => '요약';

  @override
  String get aiLessonBuilderLabelLanguage => '언어';

  @override
  String get aiLessonBuilderLabelLevel => '레벨';

  @override
  String get aiLessonBuilderTopicHint => '주제 입력 (예: \"음식과 식사\")';

  @override
  String aiLessonBuilderSaved(String title) {
    return '레슨 \"$title\"이(가) 저장되었습니다!';
  }

  @override
  String get aiLessonBuilderBackToLessons => '레슨으로 돌아가기';

  @override
  String get aiTranslationHint => '번역할 텍스트 입력...';

  @override
  String get aiTranslationSavedToVocab => '단어장에 저장됨';

  @override
  String aiTranslationCouldNotSave(String error) {
    return '저장할 수 없습니다: $error';
  }

  @override
  String get aiQuizTitle => '퀴즈';

  @override
  String get aiQuizFailedToGenerate => '퀴즈 생성 실패';

  @override
  String get aiQuizSubmitTitle => '퀴즈를 제출하시겠어요?';

  @override
  String get aiQuizSubmitBody => '답안을 제출하시겠습니까?';

  @override
  String get aiQuizExitTitle => '퀴즈를 나가시겠어요?';

  @override
  String get aiQuizExitBody => '진행 상황이 사라집니다.';

  @override
  String get aiQuizAnswerHint => '답을 입력하세요...';

  @override
  String get aiQuizTranslationHint => '번역을 입력하세요...';

  @override
  String get aiPronunciationPlayingAudio => '오디오 재생 중...';

  @override
  String get aiPronunciationListenFirst => '먼저 듣기';

  @override
  String get aiPronunciationHint => '연습할 텍스트 입력...';

  @override
  String aiTutorCouldNotLoad(String error) {
    return '튜터를 불러올 수 없습니다: $error';
  }

  @override
  String aiTutorPlanUnavailable(String error) {
    return '플랜을 사용할 수 없습니다: $error';
  }

  @override
  String get aiTutorReplay => '다시 재생';

  @override
  String get aiScenariosTitle => '연습 시나리오';

  @override
  String aiScenariosCouldNotLoad(String error) {
    return '시나리오를 불러올 수 없습니다: $error';
  }

  @override
  String get aiScenariosNoneAvailable => '아직 시나리오가 없습니다.';

  @override
  String aiScenariosCouldNotStart(String error) {
    return '시작할 수 없습니다: $error';
  }

  @override
  String aiScenariosForYourLevel(String level) {
    return '내 레벨용 ($level)';
  }

  @override
  String get aiScenariosEasier => '쉬움 — 워밍업';

  @override
  String get aiScenariosHarder => '어려움 — 도전';

  @override
  String get aiRoleplayStillStarting => '시나리오를 시작 중입니다 — 잠시 후 다시 시도하세요.';

  @override
  String aiRoleplaySendFailed(String error) {
    return '전송 실패: $error';
  }

  @override
  String get aiRoleplayCouldNotGrade => '이번에는 채점할 수 없었어요 — 다음에 다시 시도하세요.';

  @override
  String get aiConversationHistoryCompleted => '완료';

  @override
  String get aiConversationHistoryInProgress => '진행 중';

  @override
  String get aiConversationMessageHint => '메시지 입력...';

  @override
  String get aiConversationTopicSpeak => '내 언어';

  @override
  String get aiConversationTopicPractice => '연습';

  @override
  String aiToolsVipUpgradeDescription(String feature) {
    return 'VIP로 업그레이드하여 $feature을(를) 잠금 해제하세요!';
  }

  @override
  String get aiToolsVipBadge => 'VIP';

  @override
  String aiScenariosBannerPracticingIn(String language) {
    return '$language로 연습 중';
  }

  @override
  String get aiScenariosBannerSubhead => '자기 레벨의 시나리오를 고르거나, 한 단계 위로 도전해 보세요.';

  @override
  String get chatListSearchHint => '검색 또는 @사용자명 입력';

  @override
  String get chatListFilterAll => '전체';

  @override
  String get chatListFilterUnread => '안 읽음';

  @override
  String get chatListFilterOnline => '온라인';

  @override
  String get chatListNewChat => '새 채팅';

  @override
  String get chatListNewChatByUsernameTooltip => '사용자명으로 새 채팅';

  @override
  String get chatListFindUser => '사용자 찾기';

  @override
  String chatListFindUserSearchTerm(String term) {
    return '@$term 찾기';
  }

  @override
  String get chatListDeleteConversation => '대화 삭제';

  @override
  String chatListMediaTitle(String name) {
    return '$name와의 미디어';
  }

  @override
  String get chatListMediaError => '미디어 로드 오류';

  @override
  String get chatDetailViewFullProfile => '전체 프로필 보기';

  @override
  String get chatMessageReply => '답장';

  @override
  String get chatMessageCopy => '복사';

  @override
  String get chatMessageCorrect => '교정';

  @override
  String get chatMessageTranslate => '번역';

  @override
  String get chatMessageSavePhrase => '문구 저장';

  @override
  String get chatMessageEdit => '편집';

  @override
  String get chatMessageDelete => '삭제';

  @override
  String get chatMessageRetrySubtitle => '이 메시지를 다시 보내세요';

  @override
  String get chatMessageRemoveSubtitle => '이 메시지를 제거';

  @override
  String get chatWallpaperPreviewHello => '안녕! 👋';

  @override
  String get chatWallpaperPreviewHow => '어떻게 지내?';

  @override
  String get chatGifSearchHint => 'GIF 검색...';

  @override
  String get communitySearchHint => '검색 또는 @사용자명 입력';

  @override
  String communityUserNotFound(String name) {
    return '@$name 사용자를 찾을 수 없습니다';
  }

  @override
  String get communityTabAll => '전체';

  @override
  String get communityTabGender => '성별';

  @override
  String get communityTabCity => '도시';

  @override
  String get communityRefresh => '새로고침';

  @override
  String get communityNoUsersFound => '사용자가 없습니다';

  @override
  String communityUnblockConfirm(String name) {
    return '정말 $name을(를) 차단 해제하시겠어요?';
  }

  @override
  String get communityUsernameCopied => '사용자명이 복사되었습니다!';

  @override
  String communityLocationDetected(String country) {
    return '위치: $country';
  }

  @override
  String get communityWaveLater => '나중에';

  @override
  String get communityAboutMBTI => 'MBTI';

  @override
  String get voiceRoomReactTooltip => '리액션';

  @override
  String get momentsCancel => '취소';

  @override
  String get momentsNotNow => '나중에';

  @override
  String get commonOK => '확인';

  @override
  String commonError(String error) {
    return '오류: $error';
  }

  @override
  String get chatActiveJustNow => '방금 활동';

  @override
  String chatActiveMinAgo(int min) {
    return '$min분 전 활동';
  }

  @override
  String get chatActiveHourAgo => '1시간 전 활동';

  @override
  String chatActiveHoursAgo(int hours) {
    return '$hours시간 전 활동';
  }

  @override
  String get chatActiveYesterday => '어제 활동';

  @override
  String chatActiveDaysAgo(int days) {
    return '$days일 전 활동';
  }

  @override
  String get chatSayHiPrompt => '인사하고 대화를 시작해 보세요!';

  @override
  String get communityConversationStartersTitle => '대화 시작 팁';

  @override
  String communityConversationStartersTopic(String topic) {
    return '둘 다 $topic을(를) 좋아해요 — 좋아하는 것을 물어보세요!';
  }

  @override
  String get communityConversationStartersDefault => '인사하고 자신을 소개해 보세요!';

  @override
  String get communityConversationChatAction => '채팅';

  @override
  String get communityConversationMessageCopied => '메시지가 복사되었습니다! 붙여넣어 보내세요.';

  @override
  String get communityConversationCopiedToast => '복사됨!';

  @override
  String get communityLanguageMatchTitle => '언어 매치';

  @override
  String get communityLanguageMatchNative => '모국어';

  @override
  String get communityLanguageMatchLearning => '학습 중';

  @override
  String get communityLanguageMatchPerfect => '완벽한 언어 교환 매치!';

  @override
  String get communityLanguageMatchSameNative => '같은 모국어를 사용해요';

  @override
  String get momentsFilterApply => '적용';

  @override
  String get momentsCreateAddTo => '내 모먼트에 추가';

  @override
  String get momentsCreateCategory => '카테고리';

  @override
  String get momentsCreateLanguage => '언어';

  @override
  String get momentsCreateSchedule => '예약 (선택)';

  @override
  String get momentsCreateScheduleForLater => '나중에 예약';

  @override
  String get momentsPrivacyPublic => '공개';

  @override
  String get momentsPrivacyFriends => '친구';

  @override
  String get momentsPrivacyPrivate => '비공개';

  @override
  String get splashTagline => '학습 · 대화 · 만남';

  @override
  String get splashLoading => '로딩 중…';

  @override
  String get supportSheetGreeting => '안녕하세요, 저는 피르다우스입니다 👋';

  @override
  String get supportSheetStory => 'Bananatalk는 제가 혼자서 만들었습니다 — 모든 화면, 모든 기능, 밤새 했던 모든 버그 수정까지요. 전 세계의 언어 학습자들이 서로 연결되고 성장할 수 있도록 돕는 것이 제 목표이며, 계속해서 새로운 기능을 추가하고 있습니다.\n\nBananatalk가 조금이라도 도움이 되었다면, 작은 커피 한 잔이 저를 계속 개발할 수 있게 해주는 큰 힘이 됩니다. 솔로 개발자에게 여러분의 기여는 정말 큰 의미가 있습니다. 🙏';

  @override
  String get supportSheetDonateButton => 'PayPal로 후원하기';

  @override
  String get supportSheetWatchAd => '광고 보고 응원하기';

  @override
  String get occupation => '직업';

  @override
  String get school => '학교';

  @override
  String get occupationSearchHint => '직업 검색';

  @override
  String get occupationSelectedLabel => '선택됨';

  @override
  String get occupationCustomLabel => '직접 입력';

  @override
  String get occupationNoMatches => '목록에 일치하는 항목이 없습니다';

  @override
  String get occupationCatTech => '기술 및 소프트웨어';

  @override
  String get occupationCatHealthcare => '의료 및 보건';

  @override
  String get occupationCatEducation => '교육 및 학계';

  @override
  String get occupationCatBusiness => '비즈니스 및 금융';

  @override
  String get occupationCatCreative => '창작 및 디자인';

  @override
  String get occupationCatMedia => '미디어 및 커뮤니케이션';

  @override
  String get occupationCatEngineering => '엔지니어링';

  @override
  String get occupationCatScience => '과학 및 연구';

  @override
  String get occupationCatLegal => '법률';

  @override
  String get occupationCatHospitality => '호텔 및 외식업';

  @override
  String get occupationCatTrades => '기술직';

  @override
  String get occupationCatTransport => '운송 및 물류';

  @override
  String get occupationCatGovernment => '공공기관 및 정부';

  @override
  String get occupationCatRetail => '소매 및 고객 서비스';

  @override
  String get occupationCatAgriculture => '농업 및 환경';

  @override
  String get occupationCatSports => '스포츠 및 피트니스';

  @override
  String get occupationCatBeauty => '뷰티 및 개인 관리';

  @override
  String get occupationCatRealEstate => '부동산 및 건설';

  @override
  String get occupationCatReligion => '종교 및 영성';

  @override
  String get occupationCatStudent => '학생';

  @override
  String get occupationCatOther => '기타';

  @override
  String get schoolHint => '예: 서울대학교, 링컨 고등학교';

  @override
  String get birthdate => '생년월일';

  @override
  String get birthdateSelectHelp => '생년월일을 선택하세요';

  @override
  String get birthdateSelectPlaceholder => '날짜 선택';

  @override
  String birthdateMinAgeError(int age) {
    return '최소 $age세 이상이어야 합니다.';
  }

  @override
  String birthdateQuotaRemaining(int remaining, int max) {
    return '앞으로 60일 동안 생년월일을 $max번 중 $remaining번 더 변경할 수 있습니다.';
  }

  @override
  String birthdateQuotaLocked(int max) {
    return '이번 60일 동안 생년월일 변경 횟수 $max회를 모두 사용했습니다.';
  }

  @override
  String birthdateNextChangeOn(String date) {
    return '다음 변경 가능일: $date';
  }

  @override
  String get birthdateRateLimited => '생년월일은 60일에 최대 3회만 변경할 수 있습니다.';

  @override
  String birthdateRateLimitedUntil(String date) {
    return '생년월일은 60일에 최대 3회만 변경할 수 있습니다. $date에 다시 시도하세요.';
  }

  @override
  String get changePassword => '비밀번호 변경';

  @override
  String get currentPassword => '현재 비밀번호';

  @override
  String get newPasswordLabel => '새 비밀번호';

  @override
  String get confirmNewPassword => '새 비밀번호 확인';

  @override
  String get currentPasswordHint => '현재 비밀번호를 입력하세요';

  @override
  String get newPasswordHint => '최소 8자, A-Z, a-z, 0-9';

  @override
  String get passwordsDontMatch => '비밀번호가 일치하지 않습니다.';

  @override
  String get newPasswordSameAsCurrent => '새 비밀번호는 현재 비밀번호와 달라야 합니다.';

  @override
  String get passwordChangedSuccess => '비밀번호가 성공적으로 변경되었습니다';

  @override
  String get passwordRule8Chars => '최소 8자';

  @override
  String get passwordRuleLowercase => '소문자 1자';

  @override
  String get passwordRuleUppercase => '대문자 1자';

  @override
  String get passwordRuleNumber => '숫자 1자';

  @override
  String get settingsAccountSection => '계정';

  @override
  String get changePasswordTileSubtitle => '계정 비밀번호를 변경합니다';

  @override
  String get occupationCustomTab => '직접 입력';

  @override
  String get occupationCustomTabHint => '직업을 찾을 수 없나요? 여기에 입력하세요.';

  @override
  String get occupationCustomInputHint => '예: 해양 생물학자, 성우';

  @override
  String get occupationCustomSaveCTA => '내 직업으로 사용';

  @override
  String get vipSelectPlan => '플랜 선택';

  @override
  String get vipBenefits => '혜택';

  @override
  String get vipBestValue => '최고의 혜택';

  @override
  String get vipPlanMonth => '1개월';

  @override
  String get vipPlanThreeMonths => '3개월';

  @override
  String get vipPlanTwelveMonths => '12개월';

  @override
  String get vipOneTime => '1회 결제';

  @override
  String get vipNonVip => '일반 회원';

  @override
  String get vipBenefitDailyTranslations => '일일 번역';

  @override
  String get vipBenefitTranslationsLimit => '하루 5회';

  @override
  String get vipBenefitUnlimited => '무제한';

  @override
  String get vipBenefitAdvancedFilters => '고급 필터';

  @override
  String get vipBenefitAdFree => '광고 제거';

  @override
  String get vipBenefitVipBadge => '프로필 VIP 배지';

  @override
  String get vipBenefitPrioritySupport => '우선 고객 지원';

  @override
  String get vipBrandTitle => 'BananaTalk VIP';

  @override
  String get vipTagline => '전 세계와의 연결, 진솔한 대화, 오래가는 친구를 위한 패스포트.';

  @override
  String get vipDisclosure => '기간 종료 24시간 전까지 해지하지 않으면 자동으로 갱신됩니다. 결제는 iTunes 또는 Google Play 계정으로 청구됩니다.';

  @override
  String get vipLoginRequired => '계속하려면 로그인해 주세요';

  @override
  String get chatListMenu => 'Menu';

  @override
  String get chatListNewMessageAlertsTitle => '새 메시지 알림';

  @override
  String get chatListNewMessageAlertsBody => '눌러서 알림을 켜면 메시지를 놓치지 않아요';

  @override
  String get chatListFilterMyTurn => '내 차례';

  @override
  String get partnerTagActiveNow => '지금 활동 중';

  @override
  String get partnerTagVeryResponsive => '응답이 아주 좋아요';

  @override
  String get partnerTagQuickToReply => '답장이 빨라요';

  @override
  String vipSavePercent(int pct) {
    return '$pct% 할인';
  }

  @override
  String vipPerMonth(String price) {
    return '월 $price';
  }

  @override
  String partnerTagBothLike(String topic) {
    return '둘 다 $topic을(를) 좋아해요';
  }

  @override
  String partnerTagSpeaks(String language) {
    return '$language 사용';
  }

  @override
  String partnerTagLearning(String language) {
    return '$language 학습 중';
  }

  @override
  String partnerTagJoinedDaysAgo(int days) {
    return '$days일 전 가입';
  }

  @override
  String get vipPaymentPlanSummary => '플랜 요약';

  @override
  String get vipPaymentSelectMethod => '결제 수단 선택';

  @override
  String get vipPaymentPurchaseAppStore => 'App Store에서 구매';

  @override
  String get vipPaymentPurchaseGooglePlay => 'Google Play에서 구매';

  @override
  String get vipPaymentSecureAppStore => '구매는 App Store를 통해 안전하게 처리됩니다.';

  @override
  String get vipPaymentSecureGooglePlay => '구매는 Google Play를 통해 안전하게 처리됩니다.';

  @override
  String get vipPaymentSubscriptionInfo => '구독 정보';

  @override
  String get vipPaymentInfoLabelTitle => '제목';

  @override
  String get vipPaymentInfoLabelLength => '기간';

  @override
  String get vipPaymentInfoLabelPrice => '가격';

  @override
  String get vipPaymentDisclosure => '구매를 완료하면 이용약관 및 개인정보처리방침에 동의하는 것으로 간주됩니다. 현재 결제 기간 종료 24시간 전까지 해지하지 않으면 구독은 자동으로 갱신됩니다.';

  @override
  String get vipSuccessTitle => 'VIP에 오신 것을 환영합니다!';

  @override
  String get vipSuccessBody => 'VIP 구독이 활성화되었습니다. 모든 프리미엄 기능을 즐겨보세요!';

  @override
  String get vipPendingTitle => '거의 다 되었습니다';

  @override
  String get vipPendingBody => '구독이 처리 중입니다. 잠시 후 새로고침해 주세요.';

  @override
  String get vipErrorPaymentTitle => '결제 오류';

  @override
  String get vipErrorPurchaseTitle => '구매 오류';

  @override
  String get vipErrorVerifyTitle => '구매 확인 실패';

  @override
  String get vipErrorPaymentFailed => '결제 실패';

  @override
  String get vipErrorBodyPrefix => '결제를 처리하는 동안 오류가 발생했습니다:';

  @override
  String get vipErrorPurchaseCanceled => '구매가 취소되었거나 실패했습니다. 다시 시도해 주세요.';

  @override
  String get vipErrorVerifyServer => '서버에서 구매를 확인할 수 없습니다. 고객 지원에 문의해 주세요.';

  @override
  String get vipPlanLengthOneMonth => '1개월';

  @override
  String get vipPlanLengthThreeMonths => '3개월';

  @override
  String get vipPlanLengthOneYear => '1년';

  @override
  String vipPaymentPayPrice(String price) {
    return '$price 결제';
  }

  @override
  String get vipExpired => 'VIP 만료';

  @override
  String get vipMember => 'VIP 회원';

  @override
  String get chatPhrasesMostUsed => '자주 쓰는 말';

  @override
  String get chatPhrasesTopics => '주제';

  @override
  String get chatPhrasesAddPhrase => '문장 추가';

  @override
  String get chatPhrasesChange => '변경';

  @override
  String get chatPhrasesAddTitle => '문장 추가';

  @override
  String get chatPhrasesAddHint => '자주 사용하는 문장을 입력하세요';

  @override
  String get chatPhrasesEmptyMostUsed => '저장된 문장이 없습니다. + 버튼을 눌러 추가하세요.';

  @override
  String get chatPhrasesDeleteTitle => '이 문장을 삭제할까요?';

  @override
  String get filterVipPromoTitle => '더 빠르게 완벽한 상대 찾기';

  @override
  String get filterVipPromoSubtitle => 'VIP로 우선 탐색·고급 필터·광고 없는 채팅을 이용하세요.';

  @override
  String get filterVipPromoCta => 'VIP 시작';

  @override
  String get examStudy => '시험 공부';

  @override
  String get examStudyChooseLanguage => '공부할 언어 선택';

  @override
  String get examStudyChooseLanguageSubtitle => '시험을 준비할 언어를 고르세요.';

  @override
  String get examStudyLoading => 'Loading…';

  @override
  String get examStudyEmptyLanguages => '아직 이용할 수 있는 학습 언어가 없어요.';

  @override
  String get examStudyError => '불러오지 못했어요. 다시 시도해 주세요.';

  @override
  String get examStudyRetry => 'Retry';

  @override
  String get examPickExam => '시험 선택';

  @override
  String get examPickExamSubtitle => '준비하려는 시험을 고르세요.';

  @override
  String get examPickEmpty => '이 언어로 된 시험이 아직 없어요.';

  @override
  String get examDashboardSections => 'Sections';

  @override
  String get examDashboardEmptySections => '아직 연습할 섹션이 없어요.';

  @override
  String get examDashboardContinue => '계속 연습하기';

  @override
  String get examDashboardStartStudyPlan => '학습 계획 시작';

  @override
  String get examDashboardViewProgress => '진행 상황 보기';

  @override
  String examMetaDuration(int minutes) {
    return '$minutes분';
  }

  @override
  String examMetaMaxScore(String score) {
    return '최고 $score점';
  }

  @override
  String examMetaSections(int count) {
    return '$count개 섹션';
  }

  @override
  String get examSectionNotStarted => '시작 전';

  @override
  String examSectionProgress(int done, int total) {
    return '$done/$total 완료';
  }

  @override
  String get examQuestionSubmit => '답안 제출';

  @override
  String get examQuestionNext => '다음 문제';

  @override
  String get examQuestionCorrect => 'Correct!';

  @override
  String get examQuestionIncorrect => '오답';

  @override
  String get examQuestionExplanation => '해설';

  @override
  String get examQuestionNoQuestions => '이 섹션에는 아직 문제가 없어요.';

  @override
  String get examQuestionEssayComingSoon => '작문 평가는 곧 추가돼요. 지금은 독해 섹션을 해보세요.';

  @override
  String get examQuestionUnsupported => '아직 지원하지 않는 문제 유형이에요.';

  @override
  String get examPracticeFinishedTitle => '섹션 완료';

  @override
  String get examPracticeFinishedBody => '잘했어요 — 이 섹션의 모든 문제를 끝냈어요.';

  @override
  String get examPracticeBackToDashboard => '대시보드로 돌아가기';

  @override
  String examPracticeProgress(int current, int total) {
    return '$total문제 중 $current번째';
  }

  @override
  String get examEssayPrompt => '작문을 써 보세요';

  @override
  String examEssayMinChars(int min) {
    return '작문은 최소 $min자 이상이어야 해요';
  }

  @override
  String examEssayMaxChars(int max) {
    return '작문은 $max자를 넘을 수 없어요';
  }

  @override
  String examEssayWordCount(int count) {
    return '$count단어';
  }

  @override
  String examEssayCharCount(int count) {
    return '$count자';
  }

  @override
  String get examEssaySubmit => '작문 제출';

  @override
  String get examEssayEvaluating => '작문을 채점하는 중…';

  @override
  String get examEssayEvaluatingHint => '보통 10~30초 걸려요. 이 화면을 나가도 백그라운드에서 계속 채점해요.';

  @override
  String get examEssayResultTitle => '평가';

  @override
  String get examEssayResultStrengths => '잘한 점';

  @override
  String get examEssayResultImprovements => '개선 제안';

  @override
  String get examEssayResultScore => 'Score';

  @override
  String get examEssayResultFailed => '이 작문을 채점하지 못했어요.';

  @override
  String get examEssayResultRetry => '다시 시도';

  @override
  String get examEssayResultDone => 'Done';

  @override
  String get examEssayPollTimeout => '아직 채점 중이에요 — 1분 뒤에 다시 확인해 주세요.';

  @override
  String get examEssayPollRefresh => '다시 확인';

  @override
  String examEssayQuotaUsed(int used, int limit) {
    return '오늘의 작문 채점: $used/$limit';
  }

  @override
  String get examEssayQuotaExhausted => '오늘의 무료 작문 채점을 다 썼어요. VIP면 무제한이에요.';

  @override
  String get examEssayQuotaUpgrade => 'VIP로 업그레이드';

  @override
  String get examEssayDraftRestored => '임시저장본을 불러왔어요';

  @override
  String get examProgressTitle => 'Progress';

  @override
  String get examProgressOverall => '종합 점수';

  @override
  String get examProgressNotStartedTitle => '아직 연습 기록이 없어요';

  @override
  String get examProgressNotStartedBody => '아무 섹션에서나 몇 문제 풀면 여기에 진행 상황이 보여요.';

  @override
  String get examProgressFocusAreas => '집중할 영역';

  @override
  String examProgressSectionAttempts(int done, int total) {
    return '$total개 중 $done개 시도';
  }

  @override
  String get examProgressNoFocusAreas => '모든 섹션에서 잘하고 있어요 — 계속 연습해요!';

  @override
  String get examPlanSetupTitle => '학습 계획 시작';

  @override
  String get examPlanTargetScore => '목표 점수';

  @override
  String get examPlanExamDate => '시험 날짜';

  @override
  String get examPlanPickDate => '날짜 선택';

  @override
  String get examPlanGenerate => '계획 만들기';

  @override
  String get examPlanGenerating => '계획을 만드는 중…';

  @override
  String get examPlanInvalidDate => '미래의 시험 날짜를 골라 주세요.';

  @override
  String get examPlanInvalidScore => '올바른 목표 점수를 입력해 주세요.';

  @override
  String get examPlanTitle => '학습 계획';

  @override
  String get examPlanEmptyTitle => '진행 중인 계획이 없어요';

  @override
  String get examPlanEmptyBody => '약점에 맞춘 주간 목표를 받으려면 계획을 만들어 보세요.';

  @override
  String get examPlanRegenerate => '계획 다시 만들기';

  @override
  String examPlanWeek(int n) {
    return '$n주차';
  }

  @override
  String examPlanWeekEstimate(String hours) {
    return '${hours}h';
  }

  @override
  String examPlanTotalHours(int hours) {
    return '총 $hours시간';
  }

  @override
  String get examPlanDailyHeading => '추천 데일리 학습';

  @override
  String examPlanLessonMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String get examTopicPickerTitle => '주제 선택';

  @override
  String get examTopicPickerSubtitle => '특정 주제로 연습하거나 전체 문제로 바로 가세요.';

  @override
  String get examTopicAllTopics => '전체 주제';

  @override
  String get examTopicAllTopicsDescription => '가능한 모든 주제에서 출제';

  @override
  String get examTopicEmpty => 'No topical content yet. Tap All topics to start practicing.';

  @override
  String examTopicQuestionCount(int count) {
    return '$count문제';
  }

  @override
  String get examTopicOneQuestion => '1문제';

  @override
  String get examSpeakingPrompt => '답을 말해 보세요';

  @override
  String get examSpeakingListenToPrompt => 'Listen to prompt';

  @override
  String get examSpeakingTapToRecord => '눌러서 답을 녹음하세요';

  @override
  String get examSpeakingTranscriptHeading => '이렇게 들렸어요';

  @override
  String get examSpeakingPart1 => 'Speaking — Part 1';

  @override
  String get examSpeakingPart2 => 'Speaking — Part 2';

  @override
  String get examSpeakingPart3 => 'Speaking — Part 3';

  @override
  String get examSpeakingSubmit => '녹음 제출';

  @override
  String get examSpeakingUploading => '업로드 중…';

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
      other: '$count개 과제',
      one: '1개 과제',
    );
    return '$_temp0';
  }

  @override
  String examGroupSpeakingSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 파트',
      one: '1개 파트',
    );
    return '$_temp0';
  }

  @override
  String get examVocabLevelPickerTitle => '레벨 선택';

  @override
  String get examVocabLevelPickerSubtitle => 'CEFR 레벨별로 단어와 연습 퀴즈를 둘러보세요.';

  @override
  String get examVocabTopicPickerTitle => '주제 선택';

  @override
  String get examVocabAllTopics => '전체 주제';

  @override
  String get examVocabBrowse => 'Browse';

  @override
  String get examVocabPractice => 'Practice';

  @override
  String get examVocabEmptyList => '이 레벨과 주제에는 아직 단어가 없어요.';

  @override
  String get examVocabQuizComplete => '퀴즈 완료';

  @override
  String examVocabQuizScore(int correct, int total) {
    return '$total문제 중 $correct문제를 맞혔어요';
  }

  @override
  String get examVocabQuizYourAnswer => '내 답';

  @override
  String get examVocabQuizCorrectAnswer => '정답';

  @override
  String get examVocabQuizSubmit => 'Submit';

  @override
  String get examVocabQuizSubmitting => '제출 중…';

  @override
  String get examVocabQuizNext => 'Next';

  @override
  String get examVocabQuizPrev => 'Back';

  @override
  String get examVocabQuizRestart => 'Restart';

  @override
  String get examVocabQuizEmpty => '문제를 만들지 못했어요. 다른 주제나 레벨을 시도해 보세요.';

  @override
  String get examVocabQuizNotEnough => '이 레벨과 주제에는 퀴즈를 만들 만큼 단어가 충분하지 않아요.';

  @override
  String get examVocabQuizExpiredTitle => '퀴즈 만료';

  @override
  String get examVocabQuizExpiredBody => '이 퀴즈가 너무 오래 멈춰 있었어요. 다시 시작하면 새 퀴즈를 받아요.';

  @override
  String get examVocabTranslate => '번역';

  @override
  String get examVocabTranslateFailed => '번역을 사용할 수 없어요. 나중에 다시 시도해 주세요.';

  @override
  String get examDashboardTips => 'Tips';

  @override
  String get examTipsTitle => '팁 & 전략';

  @override
  String examTipsSubtitle(String examName) {
    return '$examName을(를) 위한 엄선된 전략 노트.';
  }

  @override
  String get examTipsEmpty => '이 시험의 팁은 아직 없어요.';

  @override
  String get examTipsCategoryStrategy => 'Strategy';

  @override
  String get examTipsCategoryGrammar => 'Grammar';

  @override
  String get examTipsCategoryVocabulary => '어휘';

  @override
  String get examTipsCategoryTimeManagement => '시간 관리';

  @override
  String get examTipsCategoryCommonMistakes => '자주 하는 실수';

  @override
  String get examTipsCategoryBandBooster => '점수 올리기';

  @override
  String get examTipsCategoryCulturalNotes => '문화 노트';

  @override
  String get examTipsCategoryPronunciation => '발음';

  @override
  String get examTipsCategoryFluency => 'Fluency';

  @override
  String get roomsNewRoom => '새 방';

  @override
  String get roomsCouldNotLoad => '방을 불러올 수 없습니다';

  @override
  String get roomsEmptyTitle => '아직 언어 방이 없습니다';

  @override
  String get roomsEmptySubtitle => '곧 다시 확인해 주세요 — 허브를 준비 중입니다.';

  @override
  String get roomCreateTitle => '새 주제 방';

  @override
  String get roomCreateSubtitle => '언어별로 집중 채팅을 시작하세요';

  @override
  String get roomNameLabel => '방 이름';

  @override
  String get roomNameHint => '예: 매일 대화 연습';

  @override
  String get roomDescriptionLabel => '설명 (선택 사항)';

  @override
  String get roomDescriptionHint => '이 방은 무엇에 관한 건가요?';

  @override
  String get roomCreateSubmit => '방 만들기';

  @override
  String get roomNameRequired => '방 이름을 입력해 주세요';

  @override
  String get roomCreateError => '방을 만들 수 없습니다. 다시 시도해 주세요.';

  @override
  String get roomUsEnglish => '미국식 영어';

  @override
  String get roomUkEnglish => '영국식 영어';

  @override
  String get roomFailedLoadMessages => '메시지를 불러오지 못했습니다';

  @override
  String get roomReportMessageTitle => '메시지 신고';

  @override
  String get reportReasonSpam => '스팸';

  @override
  String get reportReasonHarassment => '괴롭힘 또는 따돌림';

  @override
  String get reportReasonHateSpeech => '혐오 발언';

  @override
  String get reportReasonViolence => '폭력 또는 위협';

  @override
  String get reportReasonNudity => '나체 또는 성적인 콘텐츠';

  @override
  String get reportReasonFalseInformation => '허위 정보';

  @override
  String get roomReportSubmitted => '신고가 접수되었습니다';

  @override
  String get roomReportSubmitFailed => '신고를 제출하지 못했습니다';

  @override
  String get roomLeaveHubTitle => '허브를 나가시겠습니까?';

  @override
  String roomLeaveHubMessage(String title) {
    return '나중에 방 디렉터리에서 $title에 다시 참여할 수 있습니다.';
  }

  @override
  String get roomLeaveHubFailed => '허브 나가기에 실패했습니다';

  @override
  String get roomJoinRequestSent => '요청이 전송되었습니다 — 승인되면 알림을 받습니다';

  @override
  String get roomJoinRequestFailed => '요청 전송에 실패했습니다';

  @override
  String roomRequestsMenuItem(int count) {
    return '요청 ($count)';
  }

  @override
  String get roomViewMembers => '멤버 보기';

  @override
  String get roomLeaveHubMenuItem => '허브 나가기';

  @override
  String roomMemberOnlineCount(int members, int online) {
    return '멤버 $members명 · $online명 온라인';
  }

  @override
  String get roomBannedRequestMessage => '이 방에서 제외되었습니다. 다시 참여하려면 요청을 보내세요 — 방장의 승인이 필요합니다.';

  @override
  String get roomModeratedRequestMessage => '이 방은 운영진이 관리하는 방입니다. 채팅을 시작하려면 참여를 요청하세요.';

  @override
  String get roomRequestPending => '요청 대기 중';

  @override
  String get roomRequestToJoin => '참여 요청';

  @override
  String get roomDailyPromptLabel => '오늘의 주제';

  @override
  String get roomSomeoneFallback => '누군가';

  @override
  String get roomRequestsLoadError => '참여 요청을 불러올 수 없습니다';

  @override
  String get roomRequestApproved => '요청이 승인되었습니다';

  @override
  String get roomRequestDenied => '요청이 거절되었습니다';

  @override
  String get roomRequestApproveFailed => '요청 승인에 실패했습니다';

  @override
  String get roomRequestDenyFailed => '요청 거절에 실패했습니다';

  @override
  String roomRequestsAppBarTitle(String title) {
    return '$title · 요청';
  }

  @override
  String get roomRequestsEmpty => '대기 중인 요청이 없습니다';

  @override
  String get roomRequestDeny => '거절';

  @override
  String get roomRequestApprove => '승인';

  @override
  String get roomMembersLoadError => '멤버를 불러올 수 없습니다';

  @override
  String get roomRemoveBanTitle => '멤버를 제거하고 차단하시겠습니까?';

  @override
  String get roomRemoveTitle => '멤버를 제거하시겠습니까?';

  @override
  String roomRemoveBanConfirm(String name) {
    return '$name님을 제거하고 차단하시겠습니까? 요청을 승인하지 않는 한 다시 참여할 수 없습니다.';
  }

  @override
  String roomRemoveConfirm(String name, String title) {
    return '$title에서 $name님을 제거하시겠습니까?';
  }

  @override
  String get roomRemoveBanButton => '제거 및 차단';

  @override
  String get roomRemoveButton => '제거';

  @override
  String get roomMemberRemovedBanned => '멤버를 제거하고 차단했습니다';

  @override
  String get roomMemberRemoved => '멤버를 제거했습니다';

  @override
  String get roomMemberRemoveFailed => '멤버 제거에 실패했습니다';

  @override
  String get roomMemberMuted => '멤버를 음소거했습니다';

  @override
  String get roomMemberUnmuted => '멤버 음소거를 해제했습니다';

  @override
  String get roomMemberMuteFailed => '음소거 상태 업데이트에 실패했습니다';

  @override
  String roomMembersAppBarTitle(String title) {
    return '$title · 멤버';
  }

  @override
  String get roomMembersEmpty => '표시할 멤버가 없습니다';

  @override
  String get roomMemberMutedLabel => '음소거됨';

  @override
  String get roomMemberFallbackName => '멤버';

  @override
  String get roomYourHub => '내 허브';

  @override
  String roomOnlineCount(int count) {
    return '$count명 온라인';
  }

  @override
  String get roomNotAvailable => '이 방은 더 이상 이용할 수 없습니다.';

  @override
  String get roomGoToRooms => '방 목록으로 이동';

  @override
  String get todayTab => '오늘';

  @override
  String get todaysGrammar => '오늘의 문법';

  @override
  String get todaysVocabulary => '오늘의 어휘';

  @override
  String todayMinutes(int count) {
    return '$count분';
  }

  @override
  String get todayPickLanguage => '무엇을 배우고 있나요?';

  @override
  String todayLevelFallback(String served, String requested) {
    return '$served 표시 중 — $requested 콘텐츠가 아직 없습니다';
  }

  @override
  String get packTakePlacement => '내 레벨 찾기';

  @override
  String todayContentLanguage(String language) {
    return '오늘의 학습은 $language로 제공됩니다';
  }

  @override
  String get dailyCheck => '확인';

  @override
  String get dailyTooEasy => '너무 쉬움';

  @override
  String get dailyTooHard => '너무 어려움';

  @override
  String dailyScore(int score, int total) {
    return '$score/$total';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 연속',
    );
    return '$_temp0';
  }

  @override
  String dailyXpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String get todayEmpty => '오늘의 학습 항목을 준비하고 있어요. 곧 다시 확인해 주세요.';

  @override
  String todayLanguageUnsupported(String language) {
    return '$language은(는) 아직 데일리 학습을 지원하지 않아요.';
  }

  @override
  String get packContinue => '계속';

  @override
  String get packGotIt => '이해했어요';

  @override
  String get packSubmitFailed => '저장하지 못했어요. 연결을 확인하고 다시 시도해 주세요.';

  @override
  String packWordProgress(int current, int total) {
    return '$total개 중 $current번째 단어';
  }

  @override
  String packGrammarUnit(int unit) {
    return '$unit단원';
  }

  @override
  String get packListeningPrompt => '어떤 단어가 들렸나요?';

  @override
  String packPlayClip(int number) {
    return '$number번 음성 재생';
  }

  @override
  String get packReveal => '정답 보기';

  @override
  String get packKnewIt => '알고 있었어요';

  @override
  String get packMissed => '몰랐어요';

  @override
  String get packTranslatePrompt => '이 문장을 번역하세요';

  @override
  String get packTranslateHint => '번역을 입력하세요';

  @override
  String get packDone => '완료';

  @override
  String packTomorrowTeaser(String topic) {
    return '내일: $topic 계속';
  }

  @override
  String packContinueTo(String station) {
    return '계속 · $station';
  }

  @override
  String get packDoneForToday => '오늘은 완료';

  @override
  String get packStationVocabulary => '어휘';

  @override
  String get packStationGrammar => '문법';

  @override
  String get packStationListening => '듣기';

  @override
  String get packStationReview => '복습';

  @override
  String get packStationWrap => '주간 퀴즈';

  @override
  String get packStationTranslate => '번역';

  @override
  String get masteryTitle => '나의 진행 상황';

  @override
  String get masteryEmpty => '하루 학습을 마치면 여기에 진행 상황이 표시돼요.';

  @override
  String get masteryYourLevel => '내 레벨';

  @override
  String get masteryRetake => '다시 하기';

  @override
  String get masteryVocabulary => '어휘';

  @override
  String get masteryGrammar => '문법';

  @override
  String get masteryListening => '듣기';

  @override
  String get masteryTranslate => '번역';

  @override
  String get masteryNotStarted => '아직 시작하지 않음';

  @override
  String masteryVocabularyCaption(int mastered, int learning, int due) {
    return '완성 $mastered · 학습 중 $learning · 복습 $due';
  }

  @override
  String masteryGrammarCaption(int mastered, int total) {
    return '$total단원 중 $mastered단원';
  }

  @override
  String masteryAccuracyCaption(int percent, int samples) {
    return '$samples회 중 $percent%';
  }

  @override
  String get masteryConsistency => '지난 30일';

  @override
  String masteryDueCta(int count) {
    return '$count개 단어 지금 복습';
  }

  @override
  String get placementTitle => '레벨 찾기';

  @override
  String get placementSkip => '건너뛰기';

  @override
  String placementProgress(int current, int total) {
    return '$total문항 중 $current번';
  }

  @override
  String get placementResult => '여기서 시작해요. 언제든 바꿀 수 있어요.';

  @override
  String get placementStart => '학습 시작';

  @override
  String get packNotGraded => '저장했어요 — 지금은 채점할 수 없었어요.';

  @override
  String packSuggestedTranslation(String translation) {
    return '제안: $translation';
  }

  @override
  String get weeklyReportTitle => '이번 주 기록';

  @override
  String weeklyReportRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get weeklyReportDays => '학습한 날';

  @override
  String get weeklyReportStations => '완료한 스테이션';

  @override
  String get weeklyReportUnits => '익힌 문법 단원';

  @override
  String get weeklyReportWords => '새로운 단어';

  @override
  String get weeklyReportAccuracy => '정답률';

  @override
  String weeklyReportBestDay(String day, int count) {
    return '가장 잘한 날은 $day — 스테이션 $count개 완료';
  }

  @override
  String get weeklyReportEmpty => '이번 주엔 아직 학습이 없어요. 하루면 시작하기 충분해요.';

  @override
  String get weeklyReportStart => '오늘의 팩 시작하기';

  @override
  String get gatheringsTabLabel => '모임';

  @override
  String get gatheringClubs => '클럽';

  @override
  String get gatheringNewClub => '새 클럽';

  @override
  String get gatheringStartingSoon => '곧 시작';

  @override
  String get gatheringCreateShort => '새로 만들기';

  @override
  String get gatheringLoadFailed => '모임을 불러오지 못했습니다';

  @override
  String get gatheringEmptyTitle => '첫 모임을 열어보세요';

  @override
  String get gatheringEmptyBody => '아직 예정된 모임이 없어요. 시간을 정해서 올려보세요 — 사람들은 호스트가 있는 모임에 참여합니다.';

  @override
  String get gatheringStartAClub => '대신 클럽 만들기';

  @override
  String get gatheringToday => '오늘';

  @override
  String get gatheringTomorrow => '내일';

  @override
  String get gatheringHappeningNow => '지금 진행 중';

  @override
  String gatheringStartsIn(int minutes) {
    return '$minutes분 후 시작';
  }

  @override
  String gatheringHostZone(String zone) {
    return '호스트 시간대: $zone';
  }

  @override
  String gatheringHostedBy(String name) {
    return '호스트: $name';
  }

  @override
  String gatheringQuorumNeeded(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '확정까지 $countLabel명 더 필요',
      zero: '확정 준비 완료',
    );
    return '$_temp0';
  }

  @override
  String gatheringConfirmed(int count) {
    return '확정 · $count명 참여';
  }

  @override
  String get gatheringYouHost => '내가 호스트';

  @override
  String get gatheringGoingYou => '참여 중';

  @override
  String get gatheringFull => '마감';

  @override
  String get gatheringJoin => '참여하기';

  @override
  String get gatheringAskToJoin => '참여 요청';

  @override
  String get gatheringRequested => '참여를 요청했어요 — 호스트가 결정합니다';

  @override
  String get gatheringCreateTitle => '새 모임';

  @override
  String get gatheringCreateSubtitle => '시간, 언어, 그리고 몇 자리. 나머지는 선택 사항입니다.';

  @override
  String gatheringDefaultTitle(String language) {
    return '$language 연습';
  }

  @override
  String get gatheringTitleLabel => '무엇을 하나요?';

  @override
  String get gatheringLanguageLabel => '언어';

  @override
  String get gatheringWhenLabel => '언제';

  @override
  String get gatheringSeatsLabel => '정원';

  @override
  String get gatheringQuorumLabel => '확정 인원';

  @override
  String get gatheringQuorumExplainer => '호스트인 나도 참여 인원에 포함됩니다. 이 인원이 모이면 모임이 확정돼요.';

  @override
  String get gatheringPost => '올리기';

  @override
  String get gatheringPosted => '올렸어요 — 이제 알려보세요';

  @override
  String get gatheringNeedsTitle => '먼저 이름을 정해주세요';

  @override
  String get gatheringNeedsLanguage => '먼저 언어를 선택해주세요';

  @override
  String get gatheringNeedsFuture => '미래의 시간을 선택해주세요';

  @override
  String get gatheringDetailTitle => '모임';

  @override
  String get gatheringNotFound => '이 모임은 더 이상 볼 수 없습니다';

  @override
  String gatheringDuration(int minutes) {
    return '$minutes분';
  }

  @override
  String gatheringSeatsTaken(int going, int capacity) {
    return '$capacity자리 중 $going자리 참여';
  }

  @override
  String get gatheringCancelled => '취소됨';

  @override
  String get gatheringEnded => '종료된 모임입니다';

  @override
  String get gatheringCancelRsvp => '참여 취소';

  @override
  String gatheringHostDecision(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '지금까지 $countLabel명만 참여해요. 그래도 진행할까요, 아니면 취소할까요?',
    );
    return '$_temp0';
  }

  @override
  String get gatheringHostDecisionAlone => '지금은 나만 참여해요. 그래도 진행할까요, 아니면 취소할까요?';

  @override
  String get gatheringRunAnyway => '그래도 진행';

  @override
  String get gatheringCallItOff => '취소하기';

  @override
  String get gatheringEnd => '모임 종료';

  @override
  String get gatheringEndedThanks => '종료했어요 — 만난 사람에게 무료로 메시지를 보낼 수 있어요';

  @override
  String get gatheringCancelIt => '모임 취소';

  @override
  String get gatheringKeepIt => '유지하기';

  @override
  String gatheringCancelConfirm(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countLabel명이 이 모임을 기다리고 있어요. 취소되었다고 알려드립니다.',
      one: '1명이 이 모임을 기다리고 있어요. 취소되었다고 알려드립니다.',
    );
    return '$_temp0';
  }

  @override
  String get clubDetailTitle => '클럽';

  @override
  String get clubNotFound => '이 클럽은 더 이상 볼 수 없습니다';

  @override
  String clubMembers(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '멤버 $countLabel명',
    );
    return '$_temp0';
  }

  @override
  String get clubJoin => '클럽 가입';

  @override
  String get clubLeave => '클럽 탈퇴';

  @override
  String get clubUpcoming => '예정된 모임';

  @override
  String get clubNothingScheduled => '아직 예정된 모임이 없어요.';

  @override
  String get clubHostGathering => '모임 열기';

  @override
  String get clubCreateTitle => '새 클럽';

  @override
  String get clubCreateSubtitle => '클럽은 모임과 모임 사이에도 사람들을 이어줍니다. 실제로 함께 할 일로 이름을 지어보세요.';

  @override
  String get clubNameLabel => '클럽 이름';

  @override
  String get clubInterestLabel => '관심사';

  @override
  String get clubInterestHint => '선택 사항 — 러닝, K-pop, HSK4';

  @override
  String get clubDescriptionLabel => '소개';

  @override
  String get clubCreate => '클럽 만들기';

  @override
  String get clubNeedsName => '먼저 클럽 이름을 정해주세요';

  @override
  String gatheringRequests(int count) {
    return '참가 대기 $count명';
  }

  @override
  String get gatheringAdmit => '수락';

  @override
  String get gatheringDeny => '거절';

  @override
  String get gatheringsMine => '내 모임';

  @override
  String get gatheringsMineEmpty => '아직 없습니다. 주최하거나 참가한 모임이 여기에 표시됩니다.';

  @override
  String get gatheringsMineSubtitle => '내가 주최하거나 참가한 모임';

  @override
  String get gatheringSave => '저장';

  @override
  String get gatheringSaved => '변경사항이 저장되었습니다';

  @override
  String get gatheringEditIt => '수정';

  @override
  String get intentSectionTitle => '여기 온 이유';

  @override
  String get intentLearn => '배우러 왔어요';

  @override
  String get intentMeet => '사람들을 만나고 싶어요';

  @override
  String get intentDate => '데이트에 열려 있어요';

  @override
  String get intentPrivacyNote => '선택한 항목이 표시됩니다. 데이트는 비공개로 유지됩니다.';

  @override
  String get gatheringNoClubsYet => '아직 클럽이 없어요. 하나 만들면 모임이 머물 곳이 생깁니다.';

  @override
  String get topicConversation => '자유 대화';

  @override
  String get topicExamPrep => '시험 대비';

  @override
  String get topicGrammar => '문법';

  @override
  String get topicPronunciation => '발음';

  @override
  String get topicCulture => '문화';

  @override
  String get topicMedia => '음악·영화';

  @override
  String get topicGames => '게임';

  @override
  String get topicBusiness => '비즈니스';

  @override
  String get topicTravel => '여행';

  @override
  String get filterThisWeek => '이번 주';

  @override
  String get filterThisWeekend => '이번 주말';

  @override
  String get filterHasSeat => '자리 있음';

  @override
  String filterClear(int count) {
    return '$count개 해제';
  }

  @override
  String get filterNoMatches => '조건에 맞는 모임이 아직 없어요.';

  @override
  String get gatheringTopicLabel => '주제 (선택)';

  @override
  String get avatarViewStory => '스토리 보기';

  @override
  String get avatarViewPhoto => '프로필 사진 보기';

  @override
  String get composerNext => '다음';

  @override
  String get notifyRepliesTitle => '답장이 오면 알려드릴게요';

  @override
  String get notifyRepliesBody => '새 메시지와 매일 학습 알림을 보내드려요. 언제든지 각각 끌 수 있어요.';

  @override
  String get notifyRepliesEnable => '켜기';

  @override
  String get notifyRepliesLater => '나중에';

  @override
  String get notificationsOffTitle => '알림이 꺼져 있어요';

  @override
  String get notificationsOffBody => '기기에서 BananaTalk 알림을 차단하고 있어 리마인더와 메시지를 받을 수 없어요. 켜기 전까지 아래 설정은 적용되지 않아요.';

  @override
  String get notificationsOffOpen => '설정 열기';

  @override
  String get reportGathering => '모임 신고';

  @override
  String get reportClub => '클럽 신고';

  @override
  String get finishProfileTitle => '프로필 설정을 마쳐주세요';

  @override
  String get finishProfileBody => '모두가 안전하게 이용할 수 있도록 생년월일이 필요해요. 계속하지 않으시려면 로그아웃할 수 있어요.';

  @override
  String get finishProfileContinue => '계속하기';

  @override
  String get finishProfileSignOut => '로그아웃';

  @override
  String packReviewProgress(int current, int total) {
    return '복습 $current / $total';
  }

  @override
  String get packReviewRecall => '이 단어 기억나세요?';

  @override
  String get clubOrganizers => '운영진';

  @override
  String get clubMembersLabel => '멤버';

  @override
  String clubMeetsIn(String city) {
    return '$city에서 모임';
  }

  @override
  String clubEventsHeld(int count) {
    return '지난 모임 $count회';
  }

  @override
  String get clubEdit => '클럽 수정';

  @override
  String get clubDelete => '클럽 삭제';

  @override
  String get clubDeleteConfirmTitle => '이 클럽을 삭제할까요?';

  @override
  String get clubDeleteConfirmBody => '예정된 모임은 유지돼요 — 이미 참석하겠다고 한 분들이 있어요. 클럽만 삭제됩니다.';

  @override
  String get clubRemoveMember => '클럽에서 내보내기';

  @override
  String get clubMakeOrganizer => '운영진으로 지정';

  @override
  String get clubRemoveOrganizer => '운영진 해제';

  @override
  String clubSince(String date) {
    return '$date에 개설';
  }

  @override
  String get clubNoEventsHeld => '아직 진행한 모임이 없어요';

  @override
  String get clubPlaceLabel => '주로 만나는 장소';

  @override
  String get groupCoverChange => '사진 변경';

  @override
  String get groupCoverFromLibrary => '앨범에서 선택';

  @override
  String get groupCoverTakePhoto => '사진 촬영';

  @override
  String get groupCoverRemove => '사진 삭제';

  @override
  String get groupCoverAddOptional => '사진 추가 (선택)';

  @override
  String get clubsMine => '내 클럽';

  @override
  String get clubsMineEmpty => '아직 가입한 클럽이 없어요';

  @override
  String get storyLink => '링크';

  @override
  String get storyLinkSubtitle => '보는 사람을 페이지로 보내기';

  @override
  String get storyLinkAdd => '링크 추가';

  @override
  String get storyLinkUrlLabel => '링크 주소';

  @override
  String get storyLinkButtonLabel => '버튼 문구';

  @override
  String get storyLinkButtonDefault => '지금 보기';

  @override
  String storyLinkOpensHost(String host) {
    return '$host 열기';
  }

  @override
  String get storyLinkInvalid => '올바른 http 또는 https 주소를 입력하세요';

  @override
  String get storyStickerPoll => '투표';

  @override
  String get storyStickerPollSubtitle => '선택지가 있는 질문하기';

  @override
  String get storyStickerQuestion => '질문';

  @override
  String get storyStickerQuestionSubtitle => '보는 사람이 답을 보낼 수 있어요';

  @override
  String get storyStickerLocation => '위치';

  @override
  String get storyStickerLocationSubtitle => '이 스토리를 찍은 장소 태그';

  @override
  String get storyStickerMention => '멘션';

  @override
  String get storyStickerMentionSubtitle => '팔로우하는 사람 태그';

  @override
  String get storyToolDraw => '그리기';

  @override
  String get momentsTabForYou => '추천';

  @override
  String get momentsTabReels => '릴스';

  @override
  String get storyArchiveTitle => '보관함';

  @override
  String get storyArchiveSubtitle => '만료된 스토리, 나만 볼 수 있어요';

  @override
  String get storyArchiveEmpty => '아직 보관된 스토리가 없어요';

  @override
  String get storyArchiveEmptyBody => '스토리는 24시간 후 여기로 옮겨져요. 하이라이트에 추가하면 프로필에 계속 남아요.';

  @override
  String get storyArchiveAddHighlight => '하이라이트에 추가';

  @override
  String get storyArchiveAdded => '하이라이트에 추가됨';

  @override
  String get doneAction => '완료';

  @override
  String get noneOption => '없음';

  @override
  String get stopAction => '정지';

  @override
  String get selectPlaceholder => '선택...';

  @override
  String get goVip => 'VIP 가입';

  @override
  String get logoutFailed => '로그아웃 실패';

  @override
  String get vocabularyPacks => '단어 팩';

  @override
  String get noVocabPacksYet => '아직 사용할 수 있는 팩이 없습니다.';

  @override
  String get addWord => '단어 추가';

  @override
  String get deleteWord => '단어 삭제';

  @override
  String get shuffleAction => '섞기';

  @override
  String get exitLessonTitle => '수업을 나가시겠어요?';

  @override
  String get exitQuizTitle => '퀴즈를 나가시겠어요?';

  @override
  String get quizNotFound => '퀴즈를 찾을 수 없습니다';

  @override
  String get vocabPackAddFailed => '팩을 추가할 수 없습니다';

  @override
  String get vocabPackLoadFailed => '팩을 불러올 수 없습니다';

  @override
  String get addToMyVocab => '내 단어장에 추가';

  @override
  String get viewAiSummary => 'AI 요약 보기';

  @override
  String get reRecord => '다시 녹음';

  @override
  String get practiceComplete => '연습 완료';

  @override
  String get micPermissionNeeded => '마이크 권한이 필요합니다';

  @override
  String get thanksForParticipating => '참여해 주셔서 감사합니다! +10 XP 🎉';

  @override
  String deleteWordConfirm(String word) {
    return '단어장에서 “$word”을(를) 삭제할까요?';
  }

  @override
  String get wordDeleted => '단어를 삭제했어요';

  @override
  String get vocabularyLoadFailed => '단어장을 불러올 수 없습니다';

  @override
  String get savedTitle => '저장됨';

  @override
  String get savedSubtitle => '북마크한 릴스와 모먼트';

  @override
  String get introRequests => '인사 요청';

  @override
  String get icebreakerWhyLearn => '새로운 언어를 배우기 시작한 계기가 뭐예요?';

  @override
  String get icebreakerCanHelp => '안녕하세요! 연습 도와드릴게요 😊';

  @override
  String get icebreakerFavoriteWord => '당신의 언어에서 가장 좋아하는 단어는 뭐예요?';

  @override
  String get icebreakerCoffeeChat => '언제 커피 한잔하며 얘기할까요?';

  @override
  String get icebreakerHowsWeek => '이번 주는 어떻게 보내고 있어요?';

  @override
  String get failedToLoadReels => '릴스를 불러올 수 없습니다';

  @override
  String get failedToLoadSavedMoments => '저장한 항목을 불러올 수 없습니다';

  @override
  String get adNotReady => '광고가 아직 준비되지 않았어요. 잠시 후 다시 시도해 주세요';

  @override
  String get addQuickReply => '빠른 답장 추가';

  @override
  String get pollNeedQuestionAndOptions => '질문과 최소 2개의 선택지를 추가하세요';

  @override
  String get addOne => '추가하기';

  @override
  String get addScreenshotsOrPhotos => '스크린샷이나 사진 추가';

  @override
  String get allowMultipleVotes => '복수 투표 허용';

  @override
  String get attachImageOrTxt => '이미지 또는 .txt 파일 첨부';

  @override
  String get audioUploadFailed => '오디오 업로드 실패';

  @override
  String get browseFiles => '파일 찾아보기';

  @override
  String get clearCompleted => '완료 항목 지우기';

  @override
  String get closePollTitle => '투표를 마감할까요?';

  @override
  String get coinHistory => '코인 내역';

  @override
  String get coinShop => '코인 상점';

  @override
  String get conversationSummary => '대화 요약';

  @override
  String get couldNotLoadFollowings => '팔로잉을 불러올 수 없습니다';

  @override
  String get couldNotLoadMoreHistory => '더 많은 기록을 불러올 수 없습니다.';

  @override
  String get couldNotLoadChats => '대화를 불러올 수 없습니다';

  @override
  String get decline => '거절';

  @override
  String get endConversationTitle => '대화를 종료할까요?';

  @override
  String get explainAction => '설명';

  @override
  String get failedToPlayAudio => '오디오를 재생할 수 없습니다';

  @override
  String get failedToSavePhrase => '문구를 저장하지 못했습니다';

  @override
  String get freeRetryUnlocked => '무료 재시도가 열렸어요! 🎉';

  @override
  String get getAnotherHint => '힌트 더 보기';

  @override
  String get hideWhoVoted => '각 선택지에 누가 투표했는지 숨기기';

  @override
  String get invalidQrCode => '잘못된 QR 코드';

  @override
  String get linkCopiedToClipboard => '링크를 클립보드에 복사했어요';

  @override
  String get loadMore => '더 보기';

  @override
  String get manage => '관리';

  @override
  String get maxTenOptions => '최대 10개까지 선택지를 넣을 수 있어요';

  @override
  String get maybeLater => '나중에';

  @override
  String get minTwoOptions => '최소 2개의 선택지가 필요해요';

  @override
  String get noMoreVotesAfterClosing => '마감 후에는 더 이상 투표할 수 없어요.';

  @override
  String get noOneToMention => '아직 멘션할 사람이 없어요';

  @override
  String get noRecentChatsToSendTo => '보낼 최근 대화가 없어요';

  @override
  String get notEnoughCoins => '코인이 부족해요.';

  @override
  String get oneOptionIsCorrect => '한 선택지가 정답이에요';

  @override
  String get photoLibrary => '사진 보관함';

  @override
  String get phraseSavedToStudyQueue => '학습 목록에 문구를 저장했어요';

  @override
  String get pleaseAddTwoOptions => '선택지를 최소 2개 추가해 주세요';

  @override
  String get pleaseAttachEvidence => '증거로 파일을 최소 1개 첨부해 주세요';

  @override
  String get pleaseEnterQuestion => '질문을 입력해 주세요';

  @override
  String get pleaseSelectReportReason => '신고 사유를 선택해 주세요';

  @override
  String get pleaseSelectCorrectAnswer => '퀴즈의 정답을 선택해 주세요';

  @override
  String get pollExpires => '투표 마감';

  @override
  String get quizMode => '퀴즈 모드';

  @override
  String get recordAReel => '릴스 촬영';

  @override
  String get reelsContentGuidelines => '릴스 콘텐츠 가이드라인';

  @override
  String get reportTypeMissing => '신고 유형이 없습니다';

  @override
  String get reportedContentIdMissing => '신고된 콘텐츠 ID가 없습니다';

  @override
  String get reportedUserIdMissing => '신고된 사용자 ID가 없습니다';

  @override
  String get retryAll => '모두 다시 시도';

  @override
  String get savedToVocabulary => '단어장에 저장했어요!';

  @override
  String get savedFindInProfile => '저장했어요. 프로필 → 저장됨에서 볼 수 있어요.';

  @override
  String get shareVia => '공유하기...';

  @override
  String get shareYourLocation => '위치를 공유할까요?';

  @override
  String get suggestACorrection => '교정 제안하기';

  @override
  String get translationCopied => '번역을 복사했어요';

  @override
  String get unlock => '잠금 해제';

  @override
  String get unlockPremiumWallpapers => '프리미엄 배경화면 잠금 해제';

  @override
  String get uploadQueue => '업로드 대기열';

  @override
  String get usersCanVoteMultiple => '여러 선택지에 투표할 수 있어요';

  @override
  String get watchAd => '광고 보기';

  @override
  String get matchReasonReciprocal => '서로의 언어를 배우고 있어요';

  @override
  String matchReasonSameTarget(String language) {
    return '$language도 배우는 중';
  }

  @override
  String matchReasonSharedTopic(String topic) {
    return '공통 관심사: $topic';
  }

  @override
  String get matchReasonActiveToday => '오늘 활동';

  @override
  String get matchReasonSameCity => '같은 도시에 살아요';

  @override
  String get matchRepliesFast => '답장이 빨라요';

  @override
  String matchesTodayTitle(int count) {
    return '오늘의 매치 $count명';
  }

  @override
  String matchesRefreshHint(String time) {
    return '$time에 갱신';
  }

  @override
  String get matchesRefreshHintFallback => '자정에 갱신';

  @override
  String get matchesEmptyTitle => '오늘은 여기까지예요';

  @override
  String get matchesEmptyBody => '새 매치는 내일. 그동안 전체 파트너를 둘러보세요.';

  @override
  String get matchesEmptyCta => '파트너 둘러보기';

  @override
  String get matchSayHi => '인사하기';

  @override
  String get communityTabMatches => 'Matches';

  @override
  String get communityTabPartners => 'Partners';

  @override
  String get segmentAll => 'All';

  @override
  String get segmentSerious => '열심히 하는 학습자';

  @override
  String get segmentNew => '새 회원';

  @override
  String get segmentSeriousHint => '프로필 완성 · 이번 주 활동';

  @override
  String get segmentNewHint => '최근 7일 이내 가입';

  @override
  String openerReciprocal(String theirLanguage, String myLanguage) {
    return '메시지를 반은 $theirLanguage, 반은 $myLanguage로 써볼까요? 서로 고쳐주기로 해요 😄';
  }

  @override
  String openerSharedTopic(String topic) {
    return '$topic 좋아하시는군요 — 어떻게 시작하셨어요?';
  }

  @override
  String openerGeneric(String name, String language) {
    return '안녕하세요 $name님! $language 배우는 중인데 팁 있을까요? 👋';
  }

  @override
  String get openerChipsTitle => '대화 첫마디 — 눌러서 고친 뒤 보내세요';

  @override
  String stallRescueTitle(String name) {
    return '$name님이 뭔가 물어봤어요 👀';
  }

  @override
  String get stallRescueHint => '답장이 늦어서 미안해요! 계속 얘기할까요? 😊';

  @override
  String get referralTitle => '친구 초대';

  @override
  String get referralSubtitle => '친구가 가입하면 코인을 받아요';

  @override
  String get referralYourCode => '내 초대 코드';

  @override
  String referralInvitedCount(int count) {
    return '초대한 친구: $count명';
  }

  @override
  String referralShareText(String code, String link) {
    return 'BananaTalk에서 함께해요 — 실제 사람들과 언어를 연습할 수 있어요. 내 초대 코드 $code를 입력하세요: $link';
  }

  @override
  String get referralCopy => '복사';

  @override
  String get referralShare => '공유';

  @override
  String get referralCopied => '복사됨';

  @override
  String referralClaimed(int coins) {
    return '$coins 코인을 받았어요!';
  }

  @override
  String get referralHowItWorks => '친구가 내 코드로 가입하고 프로필을 완성하면 둘 다 코인을 받아요.';

  @override
  String get boostTitle => '내 프로필 부스트';

  @override
  String get boostSubtitle => '24시간 동안 더 많은 파트너에게 노출돼요';

  @override
  String get boostFromMatches => '더 많은 사람에게 노출되기';

  @override
  String get boostedChip => '부스트됨';

  @override
  String get boostCapacityFull => '지금은 부스트 슬롯이 모두 찼어요 — 몇 시간 뒤에 다시 시도해 주세요';

  @override
  String extraMatchesCta(int cost) {
    return '+3명 더 매칭 — $cost 코인';
  }

  @override
  String get boostExplain => '언어가 맞는 모든 사람에게 24시간 동안 여섯 번째 매치로 보여요.';

  @override
  String boostCostLine(int cost) {
    return '비용: $cost 코인';
  }

  @override
  String boostBalanceLine(int balance) {
    return '내 잔액: $balance 코인';
  }

  @override
  String get boostConfirm => '부스트 확인';

  @override
  String get boostActiveTitle => '부스트가 진행 중이에요';

  @override
  String boostTimeLeft(String time) {
    return '$time 남음';
  }

  @override
  String boostSeenBy(int count) {
    return '지금까지 $count명이 봤어요';
  }

  @override
  String get boostFailed => '부스트를 시작하지 못했어요. 다시 시도해 주세요.';

  @override
  String get rewardedLimitReached => '오늘의 무료 잠금 해제를 모두 사용했어요 — 내일 다시 시도해 주세요';

  @override
  String get wavesMaskedTitle => '누군가 당신에게 손을 흔들었어요';

  @override
  String wavesMaskedBody(int cost) {
    return '$cost 코인으로 누구인지 확인하거나 VIP가 되세요';
  }

  @override
  String get wavesMaskedBodyVip => 'VIP가 되면 누가 손을 흔들었는지 볼 수 있어요';

  @override
  String get perkAdFree => '광고 없음';

  @override
  String get perkUnlimitedMatches => '하루 매칭 무제한';

  @override
  String get perkRevealWaves => '나에게 손 흔든 사람과 프로필을 본 사람 보기';

  @override
  String get perkUnlimitedWaves => '손 흔들기 무제한';

  @override
  String get perkAdvancedFilters => '고급 파트너 필터';

  @override
  String get vipFromMatches => 'VIP: 매칭 무제한';

  @override
  String get vipRemoveAds => '광고 제거';

  @override
  String get limitUnlockedRetry => '잠금 해제됨 — 다시 보내는 중';

  @override
  String get rewardedUnlockSuccess => '잠금 해제됨! 이제 다시 시도할 수 있어요.';

  @override
  String get extraMatchesMaxed => '오늘 추가 매칭을 이미 최대로 받았어요';

  @override
  String wavesMaskedTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count명이 당신에게 손을 흔들었어요',
      one: '누군가 당신에게 손을 흔들었어요',
    );
    return '$_temp0';
  }

  @override
  String visitorsMaskedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count명이 당신의 프로필을 봤어요',
      one: '누군가 당신의 프로필을 봤어요',
    );
    return '$_temp0';
  }

  @override
  String visitorsMaskedBody(int cost) {
    return '$cost 코인으로 누구인지 확인하거나 VIP가 되세요';
  }

  @override
  String get visitorsMaskedBodyVip => 'VIP가 되면 누가 프로필을 봤는지 볼 수 있어요';

  @override
  String boostDurationHm(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String boostDurationM(int minutes) {
    return '$minutes분';
  }

  @override
  String get boostEndingSoon => '곧 종료';

  @override
  String coinAmount(int cost) {
    return '💎$cost';
  }

  @override
  String unlockedMore(int count) {
    return '$count개 더 잠금 해제!';
  }

  @override
  String get getMoreCoins => '코인 더 받기';

  @override
  String get unlockFailed => '지금은 잠금 해제할 수 없어요.';

  @override
  String unlockGrantForCoins(int count, int cost) {
    return '💎$cost로 $count개 잠금 해제';
  }

  @override
  String get waveLimitTitle => '오늘의 웨이브를 모두 사용했어요';

  @override
  String get waveLimitBody => '지금 웨이브를 하나 더 받거나 내일 다시 오세요.';

  @override
  String get limitDailyReachedTitle => '일일 한도 도달';

  @override
  String get limitLabelMessages => '메시지';

  @override
  String get limitLabelMoments => '모먼트';

  @override
  String get limitLabelStories => '스토리';

  @override
  String get limitLabelComments => '댓글';

  @override
  String get limitLabelProfileViews => '프로필 조회';

  @override
  String get limitLabelWaves => '웨이브';

  @override
  String limitUsedLabel(String label) {
    return '$label 사용량';
  }

  @override
  String get limitDescMessages => '오늘의 메시지 한도에 도달했어요. VIP로 업그레이드하면 무제한으로 메시지를 보낼 수 있어요!';

  @override
  String get limitDescMoments => '오늘의 모먼트 작성 한도에 도달했어요. VIP로 업그레이드하면 모먼트를 무제한으로 올릴 수 있어요!';

  @override
  String get limitDescStories => '오늘의 스토리 작성 한도에 도달했어요. VIP로 업그레이드하면 스토리를 무제한으로 올릴 수 있어요!';

  @override
  String get limitDescComments => '오늘의 댓글 한도에 도달했어요. VIP로 업그레이드하면 댓글을 무제한으로 달 수 있어요!';

  @override
  String get limitDescProfileViews => '오늘의 프로필 조회 한도에 도달했어요. VIP로 업그레이드하면 프로필을 무제한으로 볼 수 있어요!';

  @override
  String get limitDescDefault => '오늘의 한도에 도달했어요. VIP로 업그레이드하면 무제한으로 이용할 수 있어요!';

  @override
  String get limitResetsAt => '한도 초기화 시각';

  @override
  String get vipMembersGet => 'VIP 회원 혜택';

  @override
  String get vipBenefitUnlimitedMessages => '무제한 메시지';

  @override
  String get vipBenefitUnlimitedProfileViews => '무제한 프로필 조회';

  @override
  String get vipBenefitAiStudyTools => 'AI 학습 도구';

  @override
  String chatBonusMessagesUnlocked(int count) {
    return '보너스 메시지 $count개를 받았어요! 계속 대화하세요.';
  }

  @override
  String callLabelOutgoing(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': '영상 발신 통화',
        'other': '음성 발신 통화',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelIncoming(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': '영상 수신 통화',
        'other': '음성 수신 통화',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelNoAnswer(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': '영상 통화 · 응답 없음',
        'other': '음성 통화 · 응답 없음',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelMissed(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': '부재중 영상 통화',
        'other': '부재중 음성 통화',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelCancelled(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': '취소된 영상 통화',
        'other': '취소된 음성 통화',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelDeclinedOutgoing(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': '영상 통화 거절됨',
        'other': '음성 통화 거절됨',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelDeclinedIncoming(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': '거절한 영상 통화',
        'other': '거절한 음성 통화',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelBusy(String name) {
    return '$name님은 다른 통화 중이었습니다';
  }

  @override
  String get callsTitle => '통화';

  @override
  String get callsEmpty => '아직 통화 기록이 없습니다';

  @override
  String get callCameraPaused => '카메라 일시 중지됨';

  @override
  String get callFullScreenIntentTitle => '잠금 화면에 전화 표시';

  @override
  String get callFullScreenIntentBody => '휴대폰이 잠겨 있어도 전화를 놓치지 않도록 BananaTalk가 수신 전화를 전체 화면으로 표시하도록 허용하세요.';

  @override
  String get callForegroundTitle => '통화 중';

  @override
  String get callForegroundBody => '탭하여 통화로 돌아가기';

  @override
  String get callServiceChannelName => '진행 중인 통화';

  @override
  String get callServiceChannelDescription => 'BananaTalk이 백그라운드에 있어도 통화가 계속되도록 합니다';

  @override
  String firstSessionMatchesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오늘 회원님을 위해 $count명을 골랐어요',
      one: '오늘 회원님을 위해 1명을 골랐어요',
    );
    return '$_temp0';
  }

  @override
  String get firstSessionMatchesBody => '인사해 보세요. 첫 메시지 하나면 충분해요.';

  @override
  String get guideAiStudyTitle => '필요해지기 전에 연습하세요';

  @override
  String get guideAiStudyBody => 'AI 튜터와 연습하거나 실제 시험을 준비하세요. 2분이면 한 세션이에요.';

  @override
  String get guideAiStudyCta => 'AI 도구 열기';

  @override
  String get guideChatsTitle => '대화는 여기에 쌓여요';

  @override
  String get guideChatsBody => '아직 없어요. 오늘의 매치에게 인사하면 이 목록이 채워져요.';

  @override
  String get guideChatsCta => '상대 찾기';

  @override
  String get guideMomentsTitle => '배우는 언어로 올려 보세요';

  @override
  String get guideMomentsBody => '사진 한 장이나 한 줄이면 충분해요. 원어민이 여기 쓴 글을 고쳐 줘요.';

  @override
  String get guideMomentsCta => '모먼트 올리기';

  @override
  String get guideProfileTitle => '프로필을 완성하세요';

  @override
  String get guideProfileBody => '사진 한 장과 자기소개 한 줄. 반쯤 빈 프로필은 그냥 지나쳐요.';

  @override
  String get guideProfileCta => '프로필 편집';

  @override
  String get conversationEmptyTitle => '아직 메시지가 없어요';

  @override
  String conversationEmptyBody(String name) {
    return '$name님과의 대화를 메시지로 시작해 보세요';
  }

  @override
  String get conversationEmptySayHi => '눌러서 인사하기!';

  @override
  String get momentVideoOptimizing => '동영상을 최적화하는 중이에요. 잠시만 기다려 주세요';

  @override
  String get momentPostedWithoutVoiceNote => '음성 메모 없이 모먼트가 올라갔어요.';

  @override
  String get momentAnsweringPromptOfDay => '오늘의 질문에 답하기';

  @override
  String get momentVideoReady => '동영상 준비 완료';

  @override
  String get momentReadyToUpload => '업로드 준비됨';

  @override
  String get locationServicesDisabledTitle => '위치 서비스가 꺼져 있어요';

  @override
  String get locationServicesDisabledBody => '이 기능을 쓰려면 기기 설정에서 위치 서비스를 켜 주세요.';

  @override
  String get locationPermissionNeededBody => '모먼트에 현재 위치를 넣으려면 Bananatalk에 위치 권한이 필요해요.';

  @override
  String get locationPermissionRequiredTitle => '위치 권한이 필요해요';

  @override
  String get locationPermissionPermanentlyDeniedBody => '위치 권한이 영구적으로 거부되었어요. 모먼트에 위치를 넣으려면 앱 설정에서 켜 주세요.';

  @override
  String get termsSnackAcceptFirst => '계속하려면 서비스 약관에 동의해 주세요';

  @override
  String get termsErrorAccepting => '약관 동의 중 오류가 발생했어요. 다시 시도해 주세요.';

  @override
  String get termsEulaTitle => '최종 사용자 라이선스 계약(EULA)';

  @override
  String get termsWelcomeHeading => 'Bananatalk에 오신 것을 환영해요';

  @override
  String get termsWelcomeBody => 'Bananatalk을 이용하면 본 서비스 약관에 동의하는 것으로 간주됩니다. 서비스를 이용하기 전에 주의 깊게 읽어 주세요.';

  @override
  String get termsZeroToleranceHeading => '무관용 정책';

  @override
  String get termsZeroToleranceIntro => 'Bananatalk은 불쾌한 콘텐츠와 악성 이용자에 대해 무관용 정책을 적용합니다. 다음을 허용하지도, 묵인하지도 않습니다:';

  @override
  String get termsZeroToleranceItem1 => '모든 형태의 괴롭힘, 따돌림, 협박';

  @override
  String get termsZeroToleranceItem2 => '혐오 발언, 차별, 폭력을 조장하는 콘텐츠';

  @override
  String get termsZeroToleranceItem3 => '노골적인 성적 표현, 음란물, 부적절한 콘텐츠';

  @override
  String get termsZeroToleranceItem4 => '스팸, 사기 또는 기만적인 활동';

  @override
  String get termsZeroToleranceItem5 => '사칭 또는 허위 신원';

  @override
  String get termsZeroToleranceItem6 => '관련 법령을 위반하는 모든 콘텐츠';

  @override
  String get termsZeroToleranceEnforcement => '이 정책을 위반한 이용자는 즉시 플랫폼에서 차단됩니다. 당사는 사전 통지 없이 약관을 위반하는 콘텐츠를 삭제하고 해당 계정을 해지할 권리를 보유합니다.';

  @override
  String get termsUgcHeading => '이용자 제작 콘텐츠';

  @override
  String get termsUgcBody => 'Bananatalk에서는 메시지, 게시물, 이미지 등 콘텐츠를 만들고 공유할 수 있습니다. 서비스를 통해 만들거나 업로드하거나 공유한 모든 콘텐츠에 대한 책임은 전적으로 이용자에게 있습니다.';

  @override
  String get termsUgcAgreeIntro => 'Bananatalk을 이용함으로써 다음에 동의합니다:';

  @override
  String get termsUgcItem1 => '불쾌하거나 유해하거나 불법적인 콘텐츠를 올리지 않습니다';

  @override
  String get termsUgcItem2 => '다른 이용자에게 폭력적으로 행동하지 않습니다';

  @override
  String get termsUgcItem3 => '모든 이용자의 권리와 존엄을 존중합니다';

  @override
  String get termsUgcItem4 => '불쾌한 콘텐츠나 악성 이용자를 발견하면 신고합니다';

  @override
  String get termsModerationHeading => '콘텐츠 관리';

  @override
  String get termsModerationBody => 'Bananatalk은 안전하고 서로 존중하는 환경을 유지하기 위해 이용자 콘텐츠를 적극적으로 관리합니다. 자동화 시스템과 사람 모더레이터를 통해 정책을 위반하는 콘텐츠를 검토하고 삭제합니다.';

  @override
  String get termsModerationReport => '불쾌한 콘텐츠나 악성 행위를 발견하면 앱 내 신고 기능으로 즉시 신고해 주세요. 모든 신고를 진지하게 받아들이고 신속히 조사합니다.';

  @override
  String get termsAccountHeading => '계정 책임';

  @override
  String get termsAccountBody => '계정의 보안을 유지할 책임과 계정에서 일어나는 모든 활동에 대한 책임은 이용자에게 있습니다. 계정이 무단으로 사용된 경우 즉시 알려 주셔야 합니다.';

  @override
  String get termsProhibitedHeading => '금지 행위';

  @override
  String get termsProhibitedIntro => '위 무관용 정책에 더해, 다음을 하지 않기로 동의합니다:';

  @override
  String get termsProhibitedItem1 => '적용되는 지역·국가·국제 법률을 위반하는 행위';

  @override
  String get termsProhibitedItem2 => '지식재산권을 포함한 타인의 권리를 침해하는 행위';

  @override
  String get termsProhibitedItem3 => '바이러스, 악성코드 또는 유해 코드를 전송하는 행위';

  @override
  String get termsProhibitedItem4 => '서비스나 타인 계정에 무단으로 접근하려는 행위';

  @override
  String get termsProhibitedItem5 => '허가 없이 상업적 목적으로 서비스를 이용하는 행위';

  @override
  String get termsTerminationHeading => '이용 종료';

  @override
  String get termsTerminationBody => '당사는 불쾌한 콘텐츠 게시나 악성 행위를 포함하여 본 약관을 위반한 경우, 통지 여부와 관계없이 언제든지 계정을 정지하거나 해지할 권리를 보유합니다.';

  @override
  String get termsChangesHeading => '약관 변경';

  @override
  String get termsChangesBody => '당사는 본 약관을 수시로 업데이트할 수 있습니다. 변경 후에도 서비스를 계속 이용하면 수정된 약관에 동의한 것으로 봅니다.';

  @override
  String get termsContactHeading => '문의하기';

  @override
  String get termsContactBody => '본 약관에 대한 문의나 위반 신고가 필요하면 앱의 고객지원 기능을 통해 연락해 주세요.';

  @override
  String get termsAgreeCheckbox => '서비스 약관과 무관용 정책에 동의합니다';

  @override
  String get termsProcessing => '처리 중...';

  @override
  String get termsAcceptAndContinue => '동의하고 계속하기';

  @override
  String termsLastUpdated(int year) {
    return '최종 업데이트: $year년';
  }

  @override
  String get wavesFailedToLoad => '웨이브를 불러오지 못했어요';

  @override
  String get wavesEmptyTitle => '아직 웨이브가 없어요';

  @override
  String get wavesEmptyBody => '누군가 인사하면\n여기에 표시돼요';

  @override
  String get wavesWavedAtYou => '회원님에게 인사했어요';

  @override
  String get lessonYourTranslation => '내 번역:';

  @override
  String get lessonTapWordsToBuild => '아래 단어를 눌러 번역을 만들어 보세요';

  @override
  String get lessonWordBank => '단어 모음:';

  @override
  String get lessonTypeTranslationHint => '여기에 번역을 입력하세요...';

  @override
  String get lessonCorrect => '정답!';

  @override
  String get lessonIncorrect => '오답';

  @override
  String get lessonCheck => '확인';

  @override
  String get lessonTitle => '레슨';

  @override
  String get lessonFailedToLoad => '레슨을 불러오지 못했어요';

  @override
  String get lessonResultCorrect => '정답';

  @override
  String get lessonResultIncorrect => '오답';

  @override
  String get lessonDone => '완료';

  @override
  String get lessonPraiseExcellent => '훌륭해요!';

  @override
  String get lessonPraiseGreat => '잘했어요!';

  @override
  String get lessonPraiseGood => '좋은 시도예요!';

  @override
  String get lessonPraiseKeepPracticing => '계속 연습해요!';

  @override
  String get lessonPraiseTryAgain => '다시 해볼까요!';

  @override
  String get lessonExitWarning => '지금 나가면 진행 상황이 저장되지 않아요.';

  @override
  String get lessonNotFound => '레슨을 찾을 수 없어요';

  @override
  String get lessonMayHaveBeenRemoved => '이 레슨은 삭제되었을 수 있어요';

  @override
  String get lessonNoExercises => '이 레슨에는 아직 문제가 없어요';

  @override
  String get quizTitle => '퀴즈';

  @override
  String get quizFailedToLoad => '퀴즈를 불러오지 못했어요';

  @override
  String get quizSubmit => '제출';

  @override
  String get quizScore => '점수';

  @override
  String get quizCorrect => '정답';

  @override
  String get quizWrong => '오답';

  @override
  String get quizYourLevel => '내 레벨';

  @override
  String get quizPraiseKeepLearning => '계속 배워요!';

  @override
  String get quizExitWarning => '지금 나가면 진행 상황이 사라져요.';

  @override
  String get vocabFailedToLoad => '복습을 불러오지 못했어요';

  @override
  String get vocabNoneDue => '지금은 복습할 단어가 없어요';

  @override
  String get vocabGotIt => '알겠어요!';

  @override
  String get vocabTapToReveal => '카드를 눌러 정답 보기';

  @override
  String get vocabSessionComplete => '세션 완료!';

  @override
  String get wavesEmptyBody2 => '누군가 인사하면\n여기에 표시돼요';

  @override
  String lessonCorrectAnswer(String answer) {
    return '정답: $answer';
  }

  @override
  String quizQuestionOfTotal(int current, int total) {
    return '$total문제 중 $current번';
  }

  @override
  String get vocabXpEarned => '획득 XP';

  @override
  String get vocabWatchAdBonus => '광고 보고 +10 보너스 XP 받기';

  @override
  String get vocabBonusEarned => '+10 보너스 XP 획득! 🎉';

  @override
  String vipBannerIsMember(String userName) {
    return '$userName님은 VIP 회원이에요';
  }

  @override
  String get vipBannerGetBenefits => '회원님도 VIP 혜택을 받아보세요!';

  @override
  String get vipUpgrade => '업그레이드';

  @override
  String get vipUnlockAllFeatures => '모든 기능 잠금 해제';

  @override
  String get chatFailedToLoadUser => '사용자 정보를 불러오지 못했어요';

  @override
  String get chatDailyLimitTitle => '하루 채팅 한도에 도달했어요';

  @override
  String get chatUnlimitedTitle => '무제한 채팅';

  @override
  String get chatUnlimitedBody => '원하는 만큼 많은 사람과 대화하세요! VIP 회원은 하루 대화가 무제한이에요.';

  @override
  String get coinsStoreUnavailable => '코인 구매는 iOS와 Android에서만 가능해요.';

  @override
  String get coinsPurchaseCanceled => '구매가 취소되었거나 시작할 수 없었어요.';

  @override
  String get coinsReceiptUnreadable => '구매 영수증을 읽지 못했어요. 다시 시도해 주세요.';

  @override
  String get coinsAdded => '코인이 추가됐어요! 💎';

  @override
  String get coinsVerifyRetry => '구매를 확인하지 못했어요. 자동으로 다시 시도해요 — 코인이 보이지 않으면 구매 복원을 해보세요.';

  @override
  String get coinsAlreadyClaimed => '오늘은 이미 받았어요 — 내일 다시 오세요!';

  @override
  String get coinsDailyClaimed => '데일리 보상을 받았어요! +10 💎';

  @override
  String get coinsClaimFailed => '데일리 보상을 받지 못했어요.';

  @override
  String get coinsAdThanks => '시청해 주셔서 감사해요! +5 💎';

  @override
  String get coinsAdCreditFailed => '광고 보상을 지급하지 못했어요.';

  @override
  String get coinsGetCoins => '코인 받기';

  @override
  String get coinsGetCoinsSubtitle => '번역, 튜터 대화, 모먼트를 바로 추가로 쓸 수 있어요.';

  @override
  String get coinsYourBalance => '내 잔액';

  @override
  String get coinsEarnFree => '무료 코인 모으기';

  @override
  String get coinsDailyReward => '데일리 보상';

  @override
  String get coinsComeBackTomorrow => '내일 다시 오세요';

  @override
  String get coinsDailyRewardSubtitle => '하루 한 번, 코인 +10';

  @override
  String get coinsClaimed => '받음';

  @override
  String get coinsClaim => '받기';

  @override
  String get coinsWatchAd => '광고 보기';

  @override
  String get coinsAdLimitReached => '오늘 한도에 도달했어요 — 내일 다시 오세요';

  @override
  String get exploreTitle => '탐색';

  @override
  String get exploreNoMoments => '둘러볼 모먼트가 없어요';

  @override
  String get exploreFailedToLoad => '불러오지 못했어요';

  @override
  String get exploreNoTrending => '아직 인기 모먼트가 없어요';

  @override
  String get exploreNoVideos => '아직 동영상이 없어요';

  @override
  String get exploreBeFirstVideo => '첫 동영상을 올려 보세요!';

  @override
  String get exploreFailedVideos => '동영상을 불러오지 못했어요';

  @override
  String get facebookLoginSubtitle => 'Facebook 계정으로 계속해서\n편리하게 이용하세요';

  @override
  String get securedByFacebook => 'Facebook이 보호합니다';

  @override
  String get continueWithEmail => '이메일로 계속하기';

  @override
  String get continueWithFacebook => 'Facebook으로 계속하기';

  @override
  String get suspendedTitle => '계정이 정지되었어요';

  @override
  String get suspendedContact => '착오라고 생각되면 사용자 이름과 함께 appeal@banatalk.com 으로 연락해 주세요.';

  @override
  String get suspendedNoAccess => '이 계정은 더 이상 이용할 수 없어요.';

  @override
  String get suspendedReason => '사유:';

  @override
  String get correctionSuggestTitle => '수정 제안하기';

  @override
  String get correctionOriginal => '원문';

  @override
  String get correctionYours => '내 수정';

  @override
  String get correctionTypeHint => '고친 문장을 입력하세요...';

  @override
  String get correctionChanges => '변경 내용';

  @override
  String get correctionExplanationOptional => '설명 (선택)';

  @override
  String get correctionWhyHint => '왜 이렇게 고쳤나요?';

  @override
  String get correctionSend => '수정 보내기';

  @override
  String get correctionSuggested => '제안된 수정';

  @override
  String get correctionFailedToSend => '수정을 보내지 못했어요';

  @override
  String get ttsUnavailable => '음성 읽기를 사용할 수 없어요';

  @override
  String get translationDailyLimitTitle => '하루 번역 한도에 도달했어요';

  @override
  String get translationDailyLimitBody => '무료 이용자는 하루 5회 번역할 수 있어요.\nVIP면 무제한이에요!';

  @override
  String get ttsListen => '듣기';

  @override
  String correctionOfMessage(String name) {
    return '$name님의 메시지 고치기';
  }

  @override
  String translatedToLanguage(String language) {
    return '$language(으)로 번역됨';
  }

  @override
  String guideProgress(int count) {
    return '시작하기 · 4개 중 $count개';
  }

  @override
  String get guideChatTip => '길게 눌러 번역하거나 교정하세요';

  @override
  String get announcementTitle => '공지';

  @override
  String get announcementUnavailable => '더 이상 볼 수 없는 공지입니다.';

  @override
  String get notifyAnnouncementsTitle => '공지사항';

  @override
  String get notifyAnnouncementsSubtitle => 'BananaTalk 팀의 소식과 업데이트';

  @override
  String chatDailyLimitBody(Object count) {
    return '무료 사용자는 하루에 최대 $count명과 채팅할 수 있습니다.\nVIP로 업그레이드하면 무제한으로 대화할 수 있어요!';
  }

  @override
  String get chatCompressingVideo => '동영상 압축 중...';

  @override
  String chatShareLocationBody(Object name) {
    return '현재 위치를 $name님에게 보냅니다. 신뢰하는 사람에게만 보내세요.';
  }

  @override
  String get chatShareLocationThisChat => '이 채팅';

  @override
  String get chatTranslationLimitReached => '번역 한도에 도달했습니다';

  @override
  String get chatTranslateLimitBody => '이 채팅에서 오늘의 무료 번역을 모두 사용했습니다. 코인으로 즉시 더 잠금 해제하세요.';

  @override
  String chatReplyingTo(Object name) {
    return '$name님에게 답장 중';
  }

  @override
  String get chatReplyingToFallback => '사용자';

  @override
  String chatSendingMedia(Object mediaType) {
    return '$mediaType 보내는 중...';
  }

  @override
  String get chatEnterUsernameStart => '채팅을 시작하려면 사용자 이름을 입력하세요';

  @override
  String chatSearching(Object username) {
    return '@$username 검색 중...';
  }

  @override
  String chatDeleteConversationBody(Object name) {
    return '$name님과의 대화를 삭제할까요? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get chatQrCode => 'QR 코드';

  @override
  String get chatDraft => '임시 저장: ';

  @override
  String get chatTyping => '입력 중...';

  @override
  String get chatPoweredBy => '제공: ';

  @override
  String get chatReconnecting => '채팅에 다시 연결하는 중...';

  @override
  String get chatDailyLimitReached => '일일 메시지 한도에 도달했습니다';

  @override
  String chatMessagesRemainingToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오늘 $count개 남음',
      one: '오늘 1개 남음',
    );
    return '$_temp0';
  }

  @override
  String get chatTranslatePreviewHint => '입력을 시작하면 번역이 표시됩니다';

  @override
  String get chatNoMessagesYet => '아직 메시지가 없습니다';

  @override
  String get chatMediaPhoto => '사진';

  @override
  String get chatMediaVideo => '동영상';

  @override
  String get chatMediaAudio => '오디오';

  @override
  String get chatMediaFile => '파일';

  @override
  String get chatMediaGeneric => '미디어';

  @override
  String get chatMessageFailedToSend => '메시지를 보내지 못했습니다';

  @override
  String get chatSendingEllipsis => '보내는 중...';

  @override
  String get chatFailedTapOptions => '실패 · 탭하여 옵션 보기';

  @override
  String get chatMessageWasDeleted => '삭제된 메시지입니다';

  @override
  String get chatStory => '스토리';

  @override
  String get chatHi => '안녕!';

  @override
  String get chatEdited => '수정됨';

  @override
  String get chatPremium => '프리미엄 ✨';

  @override
  String chatUnlockPremiumWallpapers(Object cost) {
    return '💎$cost 코인으로 모든 프리미엄 ✨ 배경화면을 잠금 해제할까요? 팩 전체가 영구적으로 잠금 해제됩니다.';
  }

  @override
  String chatWallpaperForName(Object userName) {
    return '$userName님과의 채팅 배경화면';
  }

  @override
  String get chatChooseGallery => '갤러리에서 선택';

  @override
  String get chatHiThere => '안녕하세요! 😊';

  @override
  String chatCorrected(Object correctorName) {
    return '$correctorName님이 교정했습니다';
  }

  @override
  String get chatCorrectionAccepted => '교정이 수락되었습니다 ✓';

  @override
  String chatForwarded(Object senderName) {
    return '$senderName님에게서 전달됨';
  }

  @override
  String get chatCached => '캐시됨';

  @override
  String get chatWordBreakdown => '단어 분석';

  @override
  String get chatAlternatives => '대체 표현';

  @override
  String chatTranslationAlso(Object items) {
    return '그 외: $items';
  }

  @override
  String get chatAudioUnavailable => '오디오를 사용할 수 없습니다';

  @override
  String get chatHideTranslation => '번역 숨기기';

  @override
  String get chatStoryExpired => '스토리가 만료되었습니다';

  @override
  String get chatAcceptCorrection => '교정 수락';

  @override
  String get chatAccepting => '수락하는 중…';

  @override
  String get chatSaveToVocabularyAction => '어휘장에 저장';

  @override
  String momentsMore(Object hidden) {
    return '+$hidden개 더보기';
  }

  @override
  String get momentsAllow => '허용';

  @override
  String get momentsCompressed => '압축됨';

  @override
  String get momentsPromptDay => '오늘의 주제';

  @override
  String get momentsAnswer => '답변하기';

  @override
  String get momentsAnswerCamera => '🎥 카메라로 답변하기';

  @override
  String momentsPracticeWriting(Object langName) {
    return '$langName 글쓰기 연습';
  }

  @override
  String get momentsReelPolicyBody => '릴스는 짧은 언어 학습 영상입니다. 주제 답변, 말하기 연습, 원어민 설명, 문화 클립 등이 올라옵니다.\n\nBananatalk는 부적절한 콘텐츠에 무관용 원칙을 적용합니다. 노출, 혐오 발언, 괴롭힘, 폭력, 불법 콘텐츠는 금지됩니다. 신고된 영상은 신고 2건이 접수되면 검토 전까지 자동으로 숨겨지며, 위반 시 콘텐츠가 삭제되거나 계정이 정지될 수 있습니다.\n\n언제든지 모든 릴스에서 신고하거나 차단할 수 있습니다.';

  @override
  String get momentsIAgree => '동의합니다';

  @override
  String get momentsWhyReportingReel => '이 릴스를 신고하는 이유는 무엇인가요?';

  @override
  String get momentsNoReelsYet => '아직 릴스가 없습니다';

  @override
  String get momentsNoReelsBody => '오늘의 주제에 카메라로 가장 먼저 답변하거나 자유로운 언어 학습 클립을 녹화해 보세요.';

  @override
  String get momentsPullDownRefresh => '아래로 당겨 새로고침';

  @override
  String get momentsErrorLoadingVideo => '동영상을 불러오는 중 오류가 발생했습니다';

  @override
  String get momentsLoadingVideo => '동영상 불러오는 중...';

  @override
  String momentsFileSizeMb(Object size) {
    return '${size}MB';
  }

  @override
  String momentsMaxDuration(Object duration) {
    return '최대 $duration';
  }

  @override
  String get momentsReportSubmitted => '신고가 접수되었습니다';

  @override
  String communityLive(Object count) {
    return '$count명 라이브';
  }

  @override
  String get communityFind => '찾기';

  @override
  String communityFinding(Object username) {
    return '@$username 찾는 중...';
  }

  @override
  String get communitySeeAll => '모두 보기';

  @override
  String get communitySeeWhoLikes => '나를 좋아하는 사람 보기';

  @override
  String get communityUnlimitedBrowsingNoAds => '무제한 탐색, 광고 없음, 우선 매칭';

  @override
  String communityMembersCount(Object count) {
    return '멤버 $count명';
  }

  @override
  String communityPeopleCount(Object count) {
    return '$count명';
  }

  @override
  String get communityFailedLoadArchivedWaves => '보관된 웨이브를 불러오지 못했습니다';

  @override
  String get communityGreatChat => '멋진 대화였어요! 🎉';

  @override
  String get communityStayTouchPeopleJust => '방금 대화한 사람들과 계속 연락하세요';

  @override
  String get communityNotNow => '나중에';

  @override
  String get communityPerfect => '완벽함';

  @override
  String communityLv(Object level) {
    return 'Lv.$level';
  }

  @override
  String get communityReact => '반응';

  @override
  String get communityWavedAtYou => '님이 손을 흔들었어요';

  @override
  String get communitySomeone => '누군가';

  @override
  String get communityPeopleInterestedInTopic => '이 주제에 관심 있는 사람들';

  @override
  String get learnThemedWordSetsBuild => '어휘력을 키우는 주제별 단어 세트';

  @override
  String get learnTapStartRecording => '탭하여 녹음 시작';

  @override
  String get learnWordBank => '단어 은행';

  @override
  String learnCorrectAnswer(Object correctAnswer) {
    return '정답: $correctAnswer';
  }

  @override
  String get learnMatchingDataNotAvailable => '매칭 데이터를 사용할 수 없습니다';

  @override
  String get learnExerciseCouldNotLoad => '이 연습의 매칭 짝을 불러오지 못했습니다. 레슨을 다시 생성해 보세요.';

  @override
  String get learnSkipExercise => '연습 건너뛰기';

  @override
  String get learnTapItemLeftThen => '왼쪽 항목을 탭한 다음 오른쪽에서 짝을 탭하세요';

  @override
  String learnMatchedOfTotal(Object count, Object count2) {
    return '$count/$count2 매칭됨';
  }

  @override
  String learnCorrectOfTotal(Object correctCount, Object count) {
    return '$correctCount/$count 정답';
  }

  @override
  String get learnDragDropReorderItems => '항목을 끌어서 순서를 바꾸세요';

  @override
  String learnCorrectOrder(Object order) {
    return '올바른 순서: $order';
  }

  @override
  String learnWordsToReview(int dueCount) {
    String _temp0 = intl.Intl.pluralLogic(
      dueCount,
      locale: localeName,
      other: '복습할 단어 $dueCount개',
    );
    return '$_temp0';
  }

  @override
  String learnScore(Object score) {
    return '점수: $score / 100';
  }

  @override
  String learnGotCorrect(Object correct, Object count) {
    return '$count개 중 $correct개를 맞혔습니다.';
  }

  @override
  String learnQuestionOf(Object number, Object total) {
    return '질문 $number / $total';
  }

  @override
  String get learnMatchEachWordIts => '각 단어를 그 뜻과 연결하세요';

  @override
  String get learnCouldNotLoadPacks => '팩을 불러오지 못했습니다';

  @override
  String learnWordsExercises(Object wordCount, Object exerciseCount) {
    return '단어 $wordCount개 · 연습 $exerciseCount개';
  }

  @override
  String get learnAiAutoFill => 'AI 자동 완성';

  @override
  String get learnPlay => '재생';

  @override
  String get learnFinish => '완료';

  @override
  String get learnNotQuite => '아쉬워요.';

  @override
  String get learnUnsupportedExercise => '지원되지 않는 연습';

  @override
  String get learnFailedLoadAchievements => '업적을 불러오지 못했어요';

  @override
  String learnUnlockedOn(Object date) {
    return '$date에 달성';
  }

  @override
  String get learnChallenges => '챌린지';

  @override
  String get learnFailedLoadChallenges => '챌린지를 불러오지 못했어요';

  @override
  String learnNoChallenges(Object type) {
    return '$type 챌린지가 없어요';
  }

  @override
  String get learnCheckBackLater => '나중에 다시 확인해 주세요!';

  @override
  String learnActiveCount(Object count) {
    return '진행 중 ($count)';
  }

  @override
  String learnCompletedCount(Object count) {
    return '완료 ($count)';
  }

  @override
  String get learnProgress => '진행도';

  @override
  String get learnXpReward => 'XP 보상';

  @override
  String get learnBonus => '보너스';

  @override
  String learnExpires(Object timeRemainingFormatted) {
    return '$timeRemainingFormatted 후 종료';
  }

  @override
  String get learnAchievementUnlocked => '업적 달성!';

  @override
  String get learnTapContinue => '탭하여 계속';

  @override
  String get learnChallengeCompleted => '완료';

  @override
  String get learnDailyGoals => '일일 목표';

  @override
  String learnLessons(Object completedCount, Object lessonsCount) {
    return '$completedCount/$lessonsCount 레슨';
  }

  @override
  String learnLongestDays(Object longestStreak) {
    return '최장: $longestStreak일';
  }

  @override
  String get learnTapReveal => '탭하여 확인';

  @override
  String get learnNoAchievements => '업적이 없어요';

  @override
  String get learnDayStreak => '일 연속';

  @override
  String get learnDueForReview => '복습할 차례예요';

  @override
  String learnNextReview(Object date) {
    return '다음: $date';
  }

  @override
  String get learnChallengeDaily => '일일';

  @override
  String get learnChallengeWeekly => '주간';

  @override
  String get learnChallengeSpecial => '스페셜';

  @override
  String get learnChallengeDailyDesc => '매일 챌린지를 완료하고 XP와 보상을 받으세요!';

  @override
  String get learnChallengeWeeklyDesc => '주간 챌린지는 매주 월요일에 갱신돼요';

  @override
  String get learnChallengeSpecialDesc => '기간 한정 챌린지, 보너스 보상까지!';

  @override
  String get learnDateToday => '오늘';

  @override
  String get learnDateTomorrow => '내일';

  @override
  String learnInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 후',
    );
    return '$_temp0';
  }

  @override
  String learnInWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count주 후',
    );
    return '$_temp0';
  }

  @override
  String learnInMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개월 후',
    );
    return '$_temp0';
  }

  @override
  String get aiGenerateNewQuiz => '새 퀴즈 만들기';

  @override
  String get aiPreviousQuizzes => '이전 퀴즈';

  @override
  String get aiGeneratingQuiz => '퀴즈를 만드는 중…';

  @override
  String aiFocusArea(Object name) {
    return '집중 영역: $name';
  }

  @override
  String get aiQuizType => '퀴즈 유형';

  @override
  String get aiDifficulty => '난이도';

  @override
  String get aiQuestionsLabel => '문제 수:';

  @override
  String get aiGenerateQuiz => '퀴즈 만들기';

  @override
  String aiQuizQuestionCount(int questionCount) {
    String _temp0 = intl.Intl.pluralLogic(
      questionCount,
      locale: localeName,
      other: '$questionCount문제',
      one: '1문제',
    );
    return '$_temp0';
  }

  @override
  String aiCorrectOfTotal(Object correctCount, Object totalQuestions) {
    return '$correctCount/$totalQuestions 정답';
  }

  @override
  String get aiNoQuizzesYet => '아직 퀴즈가 없습니다';

  @override
  String get aiGenerateFirstQuizAbove => '위에서 첫 퀴즈를 만들어 보세요!';

  @override
  String aiCorrectOutOf(Object correctCount, Object totalQuestions) {
    return '$totalQuestions문제 중 $correctCount문제 정답';
  }

  @override
  String get aiBackQuizHub => '퀴즈 허브로 돌아가기';

  @override
  String get aiNoQuestionsAvailable => '사용할 수 있는 문제가 없습니다';

  @override
  String get aiQuizHasNoQuestions => '이 퀴즈에는 표시할 문제가 없습니다.';

  @override
  String aiQuestionOf(Object number, Object count) {
    return '$count문제 중 $number번';
  }

  @override
  String get aiYourAnswerLabel => '내 답:';

  @override
  String get aiBonusXpWatching => '🎉 시청 보너스 +10 XP!';

  @override
  String get aiNotQuiteRight => '아쉬워요';

  @override
  String get aiWhy => '왜 그럴까요?';

  @override
  String get aiGotIt => '알겠어요';

  @override
  String get aiHint => '힌트';

  @override
  String aiLevel(Object hintLevel) {
    return '레벨 $hintLevel/3';
  }

  @override
  String get aiAskQuestion => '질문하기';

  @override
  String get aiAsk => '질문';

  @override
  String get aiAssistantExamples => '예시';

  @override
  String get aiExplainConcept => '개념 설명';

  @override
  String get aiRelatedConcepts => '관련 개념';

  @override
  String get aiGeneratingLessonSummary => '수업 요약을 만드는 중...';

  @override
  String get aiLessonSummary => '수업 요약';

  @override
  String get aiKeyPoints => '핵심 포인트';

  @override
  String get aiVocabularyRemember => '기억해야 할 어휘';

  @override
  String get aiGrammarRules => '문법 규칙';

  @override
  String get aiWhatPracticeNext => '다음에 연습할 것';

  @override
  String get aiPerfectScore => '만점!';

  @override
  String get aiGreatJob => '잘했어요!';

  @override
  String get aiGoodEffort => '수고했어요!';

  @override
  String get aiKeepPracticing => '계속 연습하세요!';

  @override
  String get aiFailedToGetHint => '힌트를 가져오지 못했습니다';

  @override
  String get aiFailedToGetAnswer => '답변을 가져오지 못했습니다';

  @override
  String get aiFailedToExplain => '설명하지 못했습니다';

  @override
  String get aiFailedLoadHistory => '기록을 불러오지 못했습니다';

  @override
  String aiConversationMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '메시지 $count개',
    );
    return '$_temp0';
  }

  @override
  String get aiStartNewConversationSee => '새 대화를 시작하면 여기에 표시됩니다';

  @override
  String get aiLoadingMessages => '메시지를 불러오는 중...';

  @override
  String get aiNoMessagesConversation => '이 대화에 메시지가 없습니다';

  @override
  String get aiDifficultyLevel => '난이도';

  @override
  String get aiScenarios => '시나리오';

  @override
  String get aiGrammarCheck => '문법 검사';

  @override
  String get aiRecentAnalysis => '최근 분석';

  @override
  String get aiCheckGrammar => '문법 검사하기';

  @override
  String get aiLanguageLabel => '언어:';

  @override
  String aiGrammarIssuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오류 $count개 발견',
    );
    return '$_temp0';
  }

  @override
  String get aiPerfect => '완벽해요!';

  @override
  String get aiNoGrammarIssuesFound => '텍스트에서 문법 오류를 찾지 못했습니다.';

  @override
  String aiIssuesFound(Object count) {
    return '발견된 오류 ($count)';
  }

  @override
  String get aiCorrected => '교정됨';

  @override
  String get aiGrammarExamples => '예시:';

  @override
  String get aiImprovedSuggestions => '개선된 제안';

  @override
  String get aiNoAnalysisHistoryYet => '아직 분석 기록이 없습니다';

  @override
  String get aiLessonBuilder => 'AI 레슨 빌더';

  @override
  String get aiGenerateCustomLessons => '맞춤 레슨 만들기';

  @override
  String get aiCreatesPersonalizedLessonsAny => 'AI가 원하는 주제로 맞춤형 레슨을 만들어 드려요';

  @override
  String aiExercises(Object exerciseCount) {
    return '연습 문제: $exerciseCount';
  }

  @override
  String get aiSuggestedTopics => '추천 주제';

  @override
  String get aiCreatingLesson => '레슨을 만드는 중...';

  @override
  String get aiGeneratingExercisesContent => 'AI가 연습 문제와 콘텐츠를 만들고 있어요';

  @override
  String get aiLessonGenerated => '레슨이 만들어졌어요!';

  @override
  String get aiGenerateAnother => '하나 더 만들기';

  @override
  String get aiStartLesson => '레슨 시작';

  @override
  String get aiPronunciationPractice => '발음 연습';

  @override
  String get aiPracticeHistory => '연습 기록';

  @override
  String get aiTextPractice => '연습할 텍스트';

  @override
  String get aiWordAnalysis => '단어 분석';

  @override
  String get aiNoPracticeHistoryYet => '아직 연습 기록이 없습니다';

  @override
  String get aiSmartTranslation => '스마트 번역';

  @override
  String get aiWordBreakdown => '단어별 분석';

  @override
  String get aiAlternativeTranslations => '다른 번역';

  @override
  String get aiGrammarNotes => '문법 노트';

  @override
  String get aiIdiomsExpressions => '관용구 및 표현';

  @override
  String aiLiteral(Object literalTranslation) {
    return '직역: $literalTranslation';
  }

  @override
  String aiMeaning(Object meaning) {
    return '의미: $meaning';
  }

  @override
  String aiEquivalent(Object equivalentIdiom) {
    return '대응 표현: $equivalentIdiom';
  }

  @override
  String get aiCulturalContext => '문화적 맥락';

  @override
  String get aiNoCompletedConversations => '완료된 대화가 없습니다';

  @override
  String get aiNoActiveConversations => '진행 중인 대화가 없습니다';

  @override
  String aiStartInLanguage(Object language) {
    return '$language(으)로 시작';
  }

  @override
  String get aiSelect => '선택';

  @override
  String aiIssuesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오류 $count개',
    );
    return '$_temp0';
  }

  @override
  String get aiGenerateLesson => '레슨 만들기';

  @override
  String get aiGeneratingEllipsis => '생성 중...';

  @override
  String get aiAnalyzing => '분석 중...';

  @override
  String get aiExcellentPronunciation => '훌륭한 발음이에요!';

  @override
  String get aiGoodJob => '잘했어요!';

  @override
  String get profileBuyMeCoffee => '커피 한 잔 사주기';

  @override
  String get profileOr => '또는';

  @override
  String get profileLoadingNotifications => '알림을 불러오는 중...';

  @override
  String get profileLoadingSettings => '설정을 불러오는 중...';

  @override
  String get profileAdmin => '관리자';

  @override
  String get profileSelected => '선택됨';

  @override
  String get profilePrivacyIntro => '다른 사람에게 보일 내용은 직접 정할 수 있어요. 항목을 끄면 공개 프로필에서 숨겨집니다.';

  @override
  String get profileUpdate => '업데이트';

  @override
  String get profileNoTopicsCategory => '이 카테고리에는 주제가 없습니다';

  @override
  String get profileAdminTools => '관리자 도구';

  @override
  String profileCompletionAdd(Object items) {
    return '추가: $items';
  }

  @override
  String get profileActive => '활성';

  @override
  String get profileAutoSaveEnabled => '자동 저장 켜짐';

  @override
  String get profileChangesSavedInstantlyWhen => '토글하면 변경 사항이 즉시 저장됩니다.';

  @override
  String get profileCurrentTheme => '현재 테마';

  @override
  String get profileThemeChangesApplyInstantly => '테마 변경 사항은 앱 전체에 즉시 적용됩니다.';

  @override
  String get profileLoadingVisitors => '방문자를 불러오는 중...';

  @override
  String get profileSeeWhoChecked => '내 프로필을 본 사람 확인하기';

  @override
  String get profileRecentVisitors => '최근 방문자';

  @override
  String get profileNoReportsSubmitted => '제출한 신고가 없습니다';

  @override
  String get profileReportsSubmitWillAppear => '제출한 신고가 여기에 표시됩니다';

  @override
  String profileReportTypeTitle(Object type) {
    return '$type 신고';
  }

  @override
  String profileReportReason(Object reason) {
    return '사유: $reason';
  }

  @override
  String get profileDeleteAccountFinalBody => '모든 데이터가 영구적으로 삭제됩니다.\n\n정말 확실한가요?';

  @override
  String get profileThanksForWatching => '시청해 주셔서 감사합니다! 🙏';

  @override
  String get profileNotificationsOn => '알림 켜짐';

  @override
  String get profileNotificationsOff => '알림 꺼짐';

  @override
  String get profileMaximumReached => '최대 개수에 도달했습니다';

  @override
  String get profilePickYourInterests => '관심사를 골라보세요';

  @override
  String get profileDeselectToChooseAnother => '다른 것을 고르려면 하나를 선택 해제하세요';

  @override
  String get profileTapTopicsMatchVibe => '나와 어울리는 주제를 탭하세요';

  @override
  String get profileEnjoyingPremium => '프리미엄 기능을 누리는 중';

  @override
  String get profileUnlockUnlimited => '무제한 메시지와 AI 도구를 잠금 해제하세요';

  @override
  String get profileBirthYear => '출생 연도';

  @override
  String get profileReportTypeUser => '사용자';

  @override
  String get profileReportTypeMoment => '모멘트';

  @override
  String get profileReportTypeComment => '댓글';

  @override
  String get profileReportTypeMessage => '메시지';

  @override
  String get profileReportTypeStory => '스토리';

  @override
  String get profileReportReasonCopyright => '저작권';

  @override
  String get storyOptimizingBestExperience => '최상의 경험을 위해 최적화 중';

  @override
  String get storyCreate => '스토리 만들기';

  @override
  String get storyAddTags => '태그 추가';

  @override
  String get storyVideoSelected => '비디오 선택됨';

  @override
  String get storyAddPoll => '투표 추가';

  @override
  String get storyOptions => '옵션';

  @override
  String get storyAddQuestion => '질문 추가';

  @override
  String get storyPrompt => '프롬프트';

  @override
  String get storyTapAnywhereAddText => '아무 곳이나 탭하여 텍스트 추가';

  @override
  String storyHighlightStoryCount(int storyCount) {
    String _temp0 = intl.Intl.pluralLogic(
      storyCount,
      locale: localeName,
      other: '스토리 $storyCount개',
    );
    return '$_temp0';
  }

  @override
  String get storySendFriends => '친구에게 보내기';

  @override
  String storySelected(Object count) {
    return '$count개 선택됨';
  }

  @override
  String get storyShareSave => '공유/저장';

  @override
  String storySeenBy(Object viewCount) {
    return '$viewCount명이 봄';
  }

  @override
  String get storyNoViewsYet => '아직 조회수가 없습니다';

  @override
  String get storyEditVideo => '비디오 편집';

  @override
  String storyVotes(Object totalVotes) {
    return '$totalVotes표';
  }

  @override
  String get storyCreatePoll => '투표 만들기';

  @override
  String get storySendAnonymously => '익명으로 보내기';

  @override
  String storyResponseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '답변 $count개',
    );
    return '$_temp0';
  }

  @override
  String get storyViewResponses => '답변 보기';

  @override
  String get storyResponsesTitle => '답변';

  @override
  String get storyNoResponsesYet => '아직 답변이 없습니다';

  @override
  String get storyQuestionBox => '질문 상자';

  @override
  String get storySent => '전송됨!';

  @override
  String get storyProcessing => '처리 중...';

  @override
  String get storyHd => 'HD';

  @override
  String storyVideoMeta(Object duration, Object size) {
    return '$duration | ${size}MB';
  }

  @override
  String get storyUserFallback => '사용자';

  @override
  String storySendCount(int count) {
    return '보내기 ($count)';
  }

  @override
  String get storyFailedToDelete => '스토리 삭제에 실패했습니다';

  @override
  String get storyAnonymous => '익명';

  @override
  String get vipNoCoinActivityYet => '아직 코인 활동이 없습니다';

  @override
  String get vipCoinShopExplainer => '코인은 무료 일일 한도에 도달한 후 번역, AI 튜터 채팅, 모먼트를 추가로 이용하기 위해 사용합니다. 코인을 사용한 후에는 구매를 환불할 수 없습니다.';

  @override
  String get vipLimitReached => '한도 도달';

  @override
  String get vipCoins => '코인';

  @override
  String vipBonusIncluded(Object bonusCoins) {
    return '보너스 $bonusCoins 코인 포함';
  }

  @override
  String get vipVisitorModeLimitReached => '방문자 모드 한도 도달';

  @override
  String get vipWhatGetFreeAccount => '무료 계정으로 얻는 혜택';

  @override
  String get vipCreateFreeAccount => '무료 계정 만들기';

  @override
  String get vipGoUnlimitedAccess => 'VIP로 무제한 이용하기';

  @override
  String get vipContinueAsVisitor => '방문자로 계속하기';

  @override
  String vipResets(Object resetTime) {
    return '초기화 시각: $resetTime';
  }

  @override
  String vipUsedToday(Object currentUsage, Object maxAllowed) {
    return '오늘 $currentUsage / $maxAllowed 사용';
  }

  @override
  String get vipTierVisitor => '방문자';

  @override
  String get vipTierMember => '회원';

  @override
  String get vipAd => '광고';

  @override
  String get promoAdsNoticeTitle => '개발자의 한마디';

  @override
  String get promoAdsNoticeBody => '안녕하세요! 저는 Bananatalk를 혼자 만들고 있는 Firdavs입니다. 앱을 계속 무료로 유지하고 개발 비용을 마련하기 위해 작은 광고를 몇 개 추가했습니다.\n\n광고가 번거로울 수 있다는 것을 알기에 선택 사항으로 만들고 보상도 드립니다. 광고를 보면 추가 메시지, 커뮤니티 필터, 퀴즈 후 보너스 XP 등을 잠금 해제할 수 있습니다.\n\nBananatalk를 이용해 주셔서 감사합니다. 여러분의 응원이 큰 힘이 됩니다. 🙏';

  @override
  String get promoAdsNoticeGotIt => '알겠어요, 감사합니다! 👍';

  @override
  String get vipOnly => 'VIP 전용';

  @override
  String get vipTapUpgrade => '탭하여 업그레이드';

  @override
  String get vipUnlockFeatures => 'VIP 기능 잠금 해제';

  @override
  String get vipUpPillUp => 'UP';

  @override
  String get vipChooseOption => '옵션을 선택하세요:';

  @override
  String get promoWelcomeBackTitle => '다시 오신 것을 환영합니다! 👋';

  @override
  String get promoWelcomeBackBody => '보고 싶었어요. 기다리고 있는 것들이에요:';

  @override
  String get promoWelcomeBackCta => '시작해요! 🚀';

  @override
  String get vipCoinsPerAdInfo => '광고당 +5 코인, 하루 최대 5회';

  @override
  String get vipUpgradeUnlockMore => '업그레이드하고 더 많은 기능과 무제한 이용을 잠금 해제하세요';

  @override
  String get vipUpgradeNow => '지금 업그레이드';

  @override
  String get commonContinueWhereLeftOff => '이전에 하던 곳에서 이어서 할까요?';

  @override
  String get commonLanguageNotProvided => '언어가 지정되지 않았습니다';

  @override
  String get commonExamNotProvided => '시험이 지정되지 않았습니다';

  @override
  String get commonMuted => '음소거됨';

  @override
  String get commonPoorConnection => '연결 상태 불량';

  @override
  String commonBlockUserConfirmBody(Object targetUserName) {
    return '$targetUserName님을 차단하시겠습니까?\n\n상대방의 메시지와 게시물이 더 이상 보이지 않으며, 서로의 검색 결과에도 나타나지 않습니다.';
  }

  @override
  String get commonVideoFile => '동영상 파일';

  @override
  String get commonPointCameraBananatalkQr => '카메라를 Bananatalk QR 코드에 비춰 주세요';

  @override
  String get commonReportSubmittedButSome => '신고가 접수되었지만 일부 증거를 업로드하지 못했습니다';

  @override
  String commonReportTitle(Object typeLabel) {
    return '$typeLabel 신고';
  }

  @override
  String commonWhyReporting(Object typeLabel) {
    return '이 $typeLabel을(를) 신고하는 이유는 무엇인가요?';
  }

  @override
  String get commonAddEvidenceRequired => '증거 추가 (필수)';

  @override
  String get commonUploadScreenshotsTextFiles => '신고를 뒷받침할 스크린샷이나 텍스트 파일을 업로드하세요';

  @override
  String commonAddEvidenceCount(Object count, Object maxFiles) {
    return '증거 추가 ($count/$maxFiles)';
  }

  @override
  String commonReportTotalSize(Object max, Object used) {
    return '합계: $used / $max';
  }

  @override
  String get commonEvidence => '증거';

  @override
  String get commonImageFailed => '이미지 로드 실패';

  @override
  String get commonShowMore => '더 보기';

  @override
  String get commonVoiceRecordingNotAvailable => '음성 녹음을 사용할 수 없음';

  @override
  String get commonVoiceRecordingOnlyAvailable => '음성 녹음은 모바일 기기에서만 사용할 수 있습니다.';

  @override
  String get commonReportSubmittedSuccessfully => '신고가 접수되었습니다';

  @override
  String get commonErrorLoadingFile => '파일 로드 오류';

  @override
  String get commonReportTypeUser => '사용자';

  @override
  String get commonReportTypeMoment => '모멘트';

  @override
  String get commonReportTypeComment => '댓글';

  @override
  String get commonReportTypeMessage => '메시지';

  @override
  String get commonReportTypeStory => '스토리';

  @override
  String get commonReportTypeContent => '콘텐츠';

  @override
  String get commonReportReasonCopyright => '저작권 침해';

  @override
  String get momentsRemoveVoiceNote => '음성 메모 삭제';

  @override
  String get vocabPackLevelProficiency => '숙달';

  @override
  String get aiFailedToLoadFeedback => '피드백을 불러오지 못했습니다';

  @override
  String get aiFailedToLoadSummary => '요약을 불러오지 못했습니다';

  @override
  String get momentFailedToLoad => '모멘트를 불러오지 못했습니다';

  @override
  String get aiPronunciationWatchAdRetry => '광고 보고 무료로 한 번 더 시도하기';

  @override
  String aiErrorLoadingLanguages(Object error) {
    return '언어를 불러오는 중 오류: $error';
  }

  @override
  String get aiSelectSourceTargetLanguages => '원본 언어와 대상 언어를 선택해 주세요';

  @override
  String get aiUnexpectedResponseFormat => '예상하지 못한 응답 형식입니다';

  @override
  String get aiFailedToLoadConversation => '대화를 불러오지 못했습니다';

  @override
  String get aiMicPermissionDeniedSettings => '마이크 권한이 거부되었습니다. 설정에서 허용해 주세요.';

  @override
  String get aiFailedToEvaluatePronunciation => '발음을 평가하지 못했습니다';

  @override
  String get aiFailedToGenerateSpeech => '음성을 생성하지 못했습니다';

  @override
  String get aiFailedToGenerateLesson => '레슨을 생성하지 못했습니다';

  @override
  String get aiLessonTopicRequired => '주제를 입력해 주세요';

  @override
  String get aiFailedToLoadTopics => '주제를 불러오지 못했습니다';

  @override
  String get aiFailedToLoadScenarios => '시나리오를 불러오지 못했습니다';

  @override
  String get aiAnalysisFailed => '분석에 실패했습니다';

  @override
  String get storySearchPlaceHint => '장소 검색…';

  @override
  String get storySearchRecentChatsHint => '최근 채팅 검색…';

  @override
  String get storySearchFollowingHint => '팔로우 중인 사람 검색…';

  @override
  String get storyAddHashtagsHint => '해시태그 추가...';

  @override
  String get storyHighlightCreateFailed => '하이라이트를 만들지 못했습니다';

  @override
  String get storyHighlightRenameFailed => '하이라이트 이름을 바꾸지 못했습니다';

  @override
  String get storyHighlightDeleteFailed => '하이라이트를 삭제하지 못했습니다';

  @override
  String get storyViewersLoadFailed => '조회자를 불러오지 못했습니다';

  @override
  String get storyShareSent => '보냈어요 💛';

  @override
  String storyShareSentPartial(Object names) {
    return '보냈어요 💛 — $names에게는 실패했어요';
  }

  @override
  String get storyVoteFailed => '투표를 제출하지 못했습니다';

  @override
  String get storyAnswerFailed => '답변을 보내지 못했습니다';

  @override
  String get storyAlreadyInHighlight => '이미 하이라이트에 저장되어 있어요';

  @override
  String get storyAddedToHighlight => '하이라이트에 추가했어요';

  @override
  String storyMaxHashtags(int max) {
    return '해시태그는 최대 $max개까지 추가할 수 있어요';
  }

  @override
  String storyMaxMentions(int max) {
    return '최대 $max명까지 멘션할 수 있어요';
  }

  @override
  String get coinHistoryActivity => '코인 활동';

  @override
  String get coinHistoryAdReward => '광고 시청';

  @override
  String get coinHistoryPurchase => '코인 구매';

  @override
  String coinHistoryUnlocked(Object feature) {
    return '$feature 잠금 해제';
  }

  @override
  String get vipVisitorMessagesBenefit => '하루 최대 50개의 메시지 보내기';

  @override
  String get vipVisitorProfilesBenefit => '하루 최대 100개의 프로필 보기';

  @override
  String get vipVisitorFriendsBenefit => '친구를 추가하고 인맥을 넓혀 보세요';

  @override
  String get vipVisitorCommunitiesTitle => '커뮤니티 참여';

  @override
  String get vipVisitorCommunitiesBenefit => '커뮤니티 토론에 참여해 보세요';

  @override
  String get vipVisitorMomentsTitle => '모멘트 공유';

  @override
  String get vipVisitorMomentsBenefit => '내 모멘트를 올리고 공유해 보세요';

  @override
  String get vipUnlimitedEverythingTitle => '모든 것을 무제한으로';

  @override
  String get vipUnlimitedEverythingBenefit => '메시지와 프로필 조회에 일일 제한 없음';

  @override
  String get vipProfileBoostBenefit => '검색 결과에서 더 많이 노출돼요';

  @override
  String get vipAdFreeExperienceBenefit => '광고 없이 앱을 즐겨 보세요';

  @override
  String get featureGateUpgradeToUnlock => '업그레이드하면 이 기능을 사용할 수 있어요';

  @override
  String get featureGateVipOnly => 'VIP 전용 기능';

  @override
  String get adsRewardedButtonLabel => '광고 보고 보너스 받기';

  @override
  String get promoAdsPerkMessages => '보너스 메시지\n+3';

  @override
  String get promoAdsPerkFilters => '필터\n잠금 해제';

  @override
  String get promoAdsPerkXp => '보너스 XP\n+10';

  @override
  String get promoAdsPerkRetry => '무료\n재시도';

  @override
  String get visitorLimitMessagesTitle => '일일 메시지 한도에 도달했어요';

  @override
  String visitorLimitMessagesBody(int count) {
    return '오늘 메시지를 $count개 보냈어요. 업그레이드하고 더 보내 보세요!';
  }

  @override
  String get visitorLimitProfilesTitle => '일일 프로필 조회 한도에 도달했어요';

  @override
  String visitorLimitProfilesBody(int count) {
    return '오늘 프로필을 $count개 봤어요. 업그레이드하고 더 둘러보세요!';
  }

  @override
  String get visitorLimitFreeAccountBenefit => '더 높은 일일 한도';

  @override
  String get visitorLimitVipBenefit => '무제한 이용';

  @override
  String get promoWelcomeBackTutorSubtitle => '대화, 발음, 퀴즈를 연습해 보세요';

  @override
  String get promoWelcomeBackCommunitySubtitle => '내 주변의 언어 파트너를 찾아보세요';

  @override
  String get promoWelcomeBackMomentsSubtitle => '나의 언어 학습 여정을 공유해 보세요';

  @override
  String get myReportsReportedId => '신고 대상 ID';

  @override
  String get myReportsReason => '사유';

  @override
  String get myReportsSubmitted => '제출일';

  @override
  String get myReportsResolved => '해결일';

  @override
  String get myReportsModeratorNotes => '운영자 메모';

  @override
  String get myReportsNotAvailable => '해당 없음';

  @override
  String get myReportsFailedToLoad => '신고 내역을 불러오지 못했습니다';

  @override
  String get voiceRecorderUnavailableDesktop => '데스크톱에서는 음성 녹음을 사용할 수 없습니다';

  @override
  String get adminPageUnavailable => '이 페이지를 사용할 수 없습니다.';

  @override
  String storyShareSendFailedTo(Object names) {
    return '$names에게 보내지 못했어요';
  }

  @override
  String get storyCantReact => '이 스토리에는 반응할 수 없어요';

  @override
  String get storyCantReply => '이 스토리에는 답장할 수 없어요';

  @override
  String get storyNoMediaToSave => '이 스토리에는 저장할 미디어가 없어요';

  @override
  String get coinsAdCrediting => '지급 중…';

  @override
  String get coinsWatchAdReward => '광고 보기 (+5 💎)';

  @override
  String callUnavailable(String name) {
    return '$name님은 지금 통화를 받지 않아요';
  }

  @override
  String get callDeclineWithMessage => '메시지';

  @override
  String get callDeclineSheetTitle => '메시지와 함께 거절';

  @override
  String get callDeclineCannedLater => '지금은 통화할 수 없어요. 나중에 다시 걸게요.';

  @override
  String get callDeclineCannedText => '지금은 통화할 수 없어요. 문자 주세요.';

  @override
  String get callDeclineCustomHint => '메시지를 입력하세요…';

  @override
  String get callDeclineSend => '보내기';

  @override
  String get callBackAction => '다시 전화';

  @override
  String get callMessageAction => '메시지';

  @override
  String get callsAllowTitle => '통화 허용';

  @override
  String get callsAllowSubtitle => '끄면 내게 오는 전화가 울리지 않아요. 발신자에게는 통화를 받지 않는 상태로 표시돼요.';

  @override
  String get callsQuietHoursNote => '‘긴급 알림 허용’이 꺼져 있으면 방해 금지 시간에는 통화도 보류돼요.';

  @override
  String get callTurnOnCamera => '카메라';

  @override
  String get callCameraFailed => '카메라를 켤 수 없습니다';

  @override
  String get callSelfViewLabel => '내 카메라. 드래그해서 이동하세요.';

  @override
  String get callSelfViewSwapHint => '두 번 탭하면 상대방 영상과 바뀝니다';

  @override
  String get studyGroupTalk => '대화';

  @override
  String get studyGroupPractice => '연습';

  @override
  String get studyGroupPrepare => '준비 & 경쟁';

  @override
  String get studyTileTutor => 'AI 튜터';

  @override
  String get studyTileTutorDesc => '무엇이든 이야기해요';

  @override
  String get studyTileRoleplay => '롤플레이';

  @override
  String get studyTileRoleplayDesc => '실생활 상황';

  @override
  String get studyTileStory => '스토리';

  @override
  String get studyTileStoryDesc => '함께 이야기 쓰기';

  @override
  String get studyTilePhoto => '사진';

  @override
  String get studyTilePhotoDesc => '사진으로 단어 배우기';

  @override
  String get studyTileSpeak => '말하기';

  @override
  String get studyTileSpeakDesc => '발음 체크';

  @override
  String get studyTileReview => '복습';

  @override
  String get studyTileReviewDesc => '오늘 복습할 단어';

  @override
  String get studyTileWriting => '쓰기';

  @override
  String get studyTileWritingDesc => '문법 피드백';

  @override
  String get studyTileQuizzes => '퀴즈';

  @override
  String get studyTileQuizzesDesc => '빠른 AI 퀴즈';

  @override
  String get studyTileExam => '시험 준비';

  @override
  String get studyTileExamDesc => 'TOPIK, JLPT, IELTS…';

  @override
  String get studyTileLessons => '레슨';

  @override
  String get studyTileLessonsDesc => '단계별 유닛';

  @override
  String get studyTileChallenges => '챌린지';

  @override
  String get studyTileChallengesDesc => '매일 목표 달성하고 XP 받기';

  @override
  String get studyTileLeaderboard => '리더보드';

  @override
  String get studyTileLeaderboardDesc => '이번 주 순위 보기';

  @override
  String get studyBadgeVip => 'VIP';

  @override
  String studyBadgeLeft(int count) {
    return '$count회 남음';
  }

  @override
  String studyBadgeDue(int count) {
    return '$count개 대기';
  }

  @override
  String get studyBadgeNew => 'NEW';

  @override
  String get studyEnglishOnly => '지금은 영어만 지원해요';

  @override
  String get studyTodayPack => '오늘의 팩';

  @override
  String get studyTodayStart => '시작';

  @override
  String studyRecommended(String name, int percent) {
    return '추천: $name — 정답률 $percent% · 5분 퀴즈';
  }

  @override
  String get studyProgressTitle => '내 학습 현황';

  @override
  String get studyFullReport => '전체 리포트';

  @override
  String studyStreakDays(int count) {
    return '$count일 연속';
  }

  @override
  String studyLevelShort(int level) {
    return 'Lv $level';
  }

  @override
  String studyUpgradeLockedTitle(String feature) {
    return '$feature은(는) VIP 기능이에요';
  }

  @override
  String studyUpgradeExhaustedTitle(String feature) {
    return '오늘의 $feature을(를) 모두 사용했어요';
  }

  @override
  String get studyUpgradeBenefitUnlimited => '매일 무제한 AI 연습';

  @override
  String get studyUpgradeBenefitNoAds => '앱 전체 광고 없음';

  @override
  String get studyUpgradeGetVip => 'VIP 시작하기 — 무제한';

  @override
  String get guideStudyHubTitle => '매일 하는 언어 헬스장';

  @override
  String get guideStudyHubBody => '매일 5분 팩, 그리고 말하고 싶을 때 AI 튜터.';

  @override
  String get guideStudyHubCta => '오늘의 팩 시작하기';

  @override
  String get guideStudyHubSecondary => '모든 기능 보기';

  @override
  String get supportBananaTalkRow => 'BananaTalk 후원하기';

  @override
  String get supportBananaTalkRowSubtitle => '1인 개발자가 계속 만들 수 있도록 도와주세요';

  @override
  String get restorePurchases => '구매 복원';

  @override
  String get restorePurchasesInProgress => '구매를 복원하는 중…';

  @override
  String get restorePurchasesSuccess => '구매가 복원되었습니다. VIP가 활성화되었습니다.';

  @override
  String get restorePurchasesAlreadyActive => 'VIP 구독이 이미 활성화되어 있습니다.';

  @override
  String get restorePurchasesNothing => '복원할 구매 내역이 없습니다.';

  @override
  String get restorePurchasesFailed => '구매를 복원하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get coinsPurchaseLinkedElsewhere => '이 구매는 이미 다른 BananaTalk 계정에 연결되어 있어 여기에는 코인이 추가되지 않았습니다.';

  @override
  String get coinsAlreadyCredited => '이 코인은 이미 계정에 추가되었습니다.';
}
