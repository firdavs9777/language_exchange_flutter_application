// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Bananatalk';

  @override
  String get aiStudyPromoTitle => '用 AI 情境练习';

  @override
  String get aiStudyPromoBody => '与 AI 导师角色扮演真实对话，建立开口说话的信心。';

  @override
  String get aiStudyPromoCTA => '试试一个情境';

  @override
  String get aiStudyPromoDismiss => '以后再说';

  @override
  String get login => '登录';

  @override
  String get signUp => '注册';

  @override
  String get email => '电子邮件';

  @override
  String get password => '密码';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get or => '或';

  @override
  String get more => '更多';

  @override
  String get signInWithGoogle => '使用 Google 登录';

  @override
  String get signInWithApple => '使用 Apple 登录';

  @override
  String get signInWithFacebook => '使用 Facebook 登录';

  @override
  String get welcome => '欢迎';

  @override
  String get home => '首页';

  @override
  String get messages => '消息';

  @override
  String get moments => '动态';

  @override
  String get overview => '概览';

  @override
  String get profile => '个人资料';

  @override
  String get settings => '设置';

  @override
  String get logout => '退出登录';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get autoTranslate => '自动翻译';

  @override
  String get autoTranslateMessages => '自动翻译消息';

  @override
  String get autoTranslateMoments => '自动翻译动态';

  @override
  String get autoTranslateComments => '自动翻译评论';

  @override
  String get translate => '翻译';

  @override
  String get translated => '已翻译';

  @override
  String get showOriginal => '显示原文';

  @override
  String get showTranslation => '显示翻译';

  @override
  String get translating => '翻译中...';

  @override
  String get translationFailed => '翻译失败';

  @override
  String get noTranslationAvailable => '无可用翻译';

  @override
  String translatedFrom(String language) {
    return '从 $language 翻译';
  }

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get share => '分享';

  @override
  String get like => '点赞';

  @override
  String get comment => '评论';

  @override
  String get send => '发送';

  @override
  String get search => '搜索';

  @override
  String get notifications => '通知';

  @override
  String get followers => '粉丝';

  @override
  String get following => '关注';

  @override
  String get posts => '帖子';

  @override
  String get visitors => '访客';

  @override
  String get loading => '加载中...';

  @override
  String get error => '错误';

  @override
  String get success => '成功';

  @override
  String get tryAgain => '重试';

  @override
  String get networkError => '网络错误。请检查您的连接。';

  @override
  String get somethingWentWrong => '出了点问题';

  @override
  String get ok => '确定';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get languageSettings => '语言设置';

  @override
  String get deviceLanguage => '设备语言';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return '您的设备设置为：$flag $name';
  }

  @override
  String get youCanOverride => '您可以在下面覆盖设备语言。';

  @override
  String languageChangedTo(String name) {
    return '语言已更改为 $name';
  }

  @override
  String get errorChangingLanguage => '更改语言时出错';

  @override
  String get autoTranslateSettings => '自动翻译设置';

  @override
  String get automaticallyTranslateIncomingMessages => '自动翻译收到的消息';

  @override
  String get automaticallyTranslateMomentsInFeed => '自动翻译动态中的内容';

  @override
  String get automaticallyTranslateComments => '自动翻译评论';

  @override
  String get translationServiceBeingConfigured => '翻译服务正在配置中。请稍后再试。';

  @override
  String get translationUnavailable => '翻译不可用';

  @override
  String get showLess => '显示更少';

  @override
  String get showMore => '显示更多';

  @override
  String get comments => '评论';

  @override
  String get beTheFirstToComment => '成为第一个评论的人。';

  @override
  String get loadMoreComments => '加载更多评论';

  @override
  String get writeAComment => '写评论...';

  @override
  String get report => '举报';

  @override
  String get reportMoment => '举报动态';

  @override
  String get reportUser => '举报用户';

  @override
  String get deleteMoment => '删除动态？';

  @override
  String get thisActionCannotBeUndone => '此操作无法撤销。';

  @override
  String get momentDeleted => '动态已删除';

  @override
  String get deleteComment => '删除评论？';

  @override
  String get commentDeleted => '评论已删除';

  @override
  String get editFeatureComingSoon => '编辑功能即将推出';

  @override
  String get userNotFound => '未找到用户';

  @override
  String get cannotReportYourOwnComment => '无法举报您自己的评论';

  @override
  String get profileSettings => '个人资料设置';

  @override
  String get editYourProfileInformation => '编辑您的个人资料信息';

  @override
  String get blockedUsers => '已屏蔽用户';

  @override
  String get manageBlockedUsers => '管理已屏蔽的用户';

  @override
  String get manageNotificationSettings => '管理通知设置';

  @override
  String get privacySecurity => '隐私和安全';

  @override
  String get controlYourPrivacy => '控制您的隐私';

  @override
  String get changeAppLanguage => '更改应用语言';

  @override
  String get appearance => '外观';

  @override
  String get themeAndDisplaySettings => '主题和显示设置';

  @override
  String get clearCache => '清除缓存';

  @override
  String get clearCacheSubtitle => '释放存储空间';

  @override
  String get clearCacheDescription => '这将清除所有缓存的图片、视频和音频文件。在重新下载媒体内容期间，应用可能会暂时加载较慢。';

  @override
  String get clearCacheHint => '如果图片或音频无法正常加载，请使用此功能。';

  @override
  String get clearingCache => '正在清除缓存...';

  @override
  String get cacheCleared => '缓存已成功清除！图片将重新加载。';

  @override
  String get clearCacheFailed => '清除缓存失败';

  @override
  String get myReports => '我的举报';

  @override
  String get viewYourSubmittedReports => '查看您提交的举报';

  @override
  String get reportsManagement => '报告管理';

  @override
  String get manageAllReportsAdmin => '管理所有举报（管理员）';

  @override
  String get legalPrivacy => '法律和隐私';

  @override
  String get termsPrivacySubscriptionInfo => '条款、隐私和订阅信息';

  @override
  String get helpCenter => '帮助中心';

  @override
  String get getHelpAndSupport => '获取帮助和支持';

  @override
  String get aiTutorChangePersona => '更换 AI 导师';

  @override
  String get aiTutorChangePersonaSubtitle => '切换到 Nana、Sensei 或 Riko';

  @override
  String aiTutorHeroTitleSet(String name) {
    return 'AI 导师 · $name';
  }

  @override
  String get aiTutorHeroTitleNew => '认识你的 AI 导师';

  @override
  String get aiTutorHeroSubtitleSet => '点按聊天或查看今天的计划';

  @override
  String aiTutorHeroSubtitleLast(String summary) {
    return '上次：$summary';
  }

  @override
  String get aiTutorHeroSubtitleNew => '挑选角色 — Nana、Sensei 或 Riko';

  @override
  String get aiTutorChipChat => '聊天';

  @override
  String get aiTutorChipRoleplay => '角色扮演';

  @override
  String get aiTutorChipStory => '故事';

  @override
  String get aiTutorChipPhoto => '照片';

  @override
  String get aiToolsMoreSection => '更多AI工具';

  @override
  String get aiConversationPartnerTile => 'AI 对话';

  @override
  String get aiConversationPartnerTileSubtitle => '与 AI 伙伴练习';

  @override
  String get aiTutorPickerTitle => '挑选你的 AI 导师';

  @override
  String get aiTutorPickerHeader => '你想和谁一起学习？';

  @override
  String get aiTutorPickerSubtitle => '你随时可以在设置中更改。';

  @override
  String get aiTutorPersonaNanaTagline => '温暖 + 鼓励';

  @override
  String get aiTutorPersonaNanaSample => '我会为你加油，没有压力。';

  @override
  String get aiTutorPersonaSenseiTagline => '精准 + 应试';

  @override
  String get aiTutorPersonaSenseiSample => '我们一起掌握规则。';

  @override
  String get aiTutorPersonaRikoTagline => '俏皮 + 口语化';

  @override
  String get aiTutorPersonaRikoSample => '哈哈一起放松学吧';

  @override
  String aiTutorPickerSaveError(String error) {
    return '无法保存: $error';
  }

  @override
  String get aiTutorHomeTitle => 'AI 导师';

  @override
  String get aiTutorHomeChangeTutor => '更换导师';

  @override
  String get aiTutorHomeGreetingDefault => '嗨！准备好一起学习了吗？';

  @override
  String get aiTutorHomeTodaysPlan => '今日计划';

  @override
  String get aiTutorHomePlanEmpty => '今日还没有计划 — 开始聊天来启动吧。';

  @override
  String get aiTutorHomeStartChat => '开始聊天';

  @override
  String get aiTutorHomeRecent => '最近';

  @override
  String get aiTutorHomePracticeScenarios => '练习情境';

  @override
  String get aiTutorHomePracticeScenariosSubtitle => '角色扮演真实对话 — 餐厅、面试、酒店…';

  @override
  String get aiTutorHomeReadStory => '读一个故事';

  @override
  String get aiTutorHomeReadStorySubtitle => 'AI 用你的词汇写一个短故事 — 附带快速理解问答。';

  @override
  String get aiTutorHomeDescribePhoto => '描述一张照片';

  @override
  String get aiTutorHomeDescribePhotoSubtitle => '拍张照片并描述 — AI 评估词汇和语法。';

  @override
  String get aiTutorChatTitle => '与导师聊天';

  @override
  String get aiTutorChatVoiceOn => '语音开';

  @override
  String get aiTutorChatVoiceOff => '语音关';

  @override
  String get aiTutorChatStopRecording => '停止录音';

  @override
  String get aiTutorChatHoldToTalk => '按住说话';

  @override
  String get aiTutorChatTranscribing => '正在转写…';

  @override
  String get aiTutorChatListening => '正在聆听…';

  @override
  String get aiTutorChatInputHint => '输入消息…';

  @override
  String get aiTutorChatTypeReplyHint => '输入你的回复…';

  @override
  String get aiTutorChatMicPermissionDenied => '语音模式需要麦克风权限。';

  @override
  String get aiTutorChatTranscribeFailed => '没听清 — 再试一次。';

  @override
  String aiTutorChatStartFailed(String error) {
    return '启动失败: $error';
  }

  @override
  String get aiTutorRoleplayEnd => '结束';

  @override
  String aiTutorRoleplayEndFailed(String error) {
    return '结束失败: $error';
  }

  @override
  String get aiTutorRoleplayDone => '完成';

  @override
  String get aiTutorStoryTitle => '读一个故事';

  @override
  String get aiTutorStoryLength => '长度';

  @override
  String get aiTutorStoryTheme => '主题';

  @override
  String aiTutorStoryWordCount(int count) {
    return '$count 个词';
  }

  @override
  String get aiTutorStoryWriting => '撰写中…';

  @override
  String get aiTutorStoryGenerate => '生成故事';

  @override
  String aiTutorStoryGenerateFailed(String error) {
    return '无法生成: $error';
  }

  @override
  String aiTutorStoryWordCountHint(int n) {
    return 'AI 会使用你词汇表中最多 $n 个词。';
  }

  @override
  String get aiTutorStoryThemeFree => '自由';

  @override
  String get aiTutorStoryThemeAdventure => '冒险';

  @override
  String get aiTutorStoryThemeMystery => '悬疑';

  @override
  String get aiTutorStoryThemeRomance => '爱情';

  @override
  String get aiTutorStoryThemeSciFi => '科幻';

  @override
  String get aiTutorStoryThemeSliceOfLife => '日常';

  @override
  String get aiTutorStoryReaderTitle => '故事';

  @override
  String get aiTutorStoryReaderVocab => '词汇';

  @override
  String get aiTutorStoryReaderVocabUsed => '使用过的词';

  @override
  String aiTutorStoryReaderPart(int n) {
    return '第 $n 部分';
  }

  @override
  String get aiTutorStoryReaderWrongHint => '差一点 — 继续';

  @override
  String get aiTutorStoryReaderNiceWork => '做得好！';

  @override
  String aiTutorStoryReaderScore(int correct, int total) {
    return '你答对了 $correct/$total 道理解题。';
  }

  @override
  String get aiTutorStoryReaderDone => '完成';

  @override
  String get aiTutorImageVocabTitle => '描述照片';

  @override
  String get aiTutorImagePickHeader => '选择要描述的照片';

  @override
  String get aiTutorImagePickSubtitle => 'AI 会用你的目标语言给出提示，然后评估你的描述。';

  @override
  String get aiTutorImagePickCamera => '相机';

  @override
  String get aiTutorImagePickGallery => '相册';

  @override
  String aiTutorImagePickError(String error) {
    return '无法打开图片: $error';
  }

  @override
  String get aiTutorImageDescriptionHint => '输入描述…';

  @override
  String get aiTutorImageDifferentPhoto => '换一张';

  @override
  String get aiTutorImageSubmit => '提交';

  @override
  String get aiTutorImageGrammarNotes => '语法笔记';

  @override
  String get aiTutorImageThingsYouMissed => '漏掉的内容';

  @override
  String get aiTutorImageTryAnother => '试试另一张';

  @override
  String get aiTutorCardQuiz => '小测验';

  @override
  String get aiTutorCardVocab => '词汇';

  @override
  String get aiTutorCardGrammar => '语法';

  @override
  String get aiTutorCardReviewDue => '复习时间到';

  @override
  String get aiTutorCardMiniLesson => '迷你课';

  @override
  String get aiTutorCardAddToVocab => '添加到词汇';

  @override
  String get aiTutorCardAddedToVocab => '已添加';

  @override
  String get aiTutorCardAdding => '添加中…';

  @override
  String aiTutorCardReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张卡在等你',
      one: '$count 张卡在等你',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorCardReviewNow => '立即复习';

  @override
  String get aiTutorCardReviewStarting => '启动中…';

  @override
  String get aiTutorCardTryIt => '试试';

  @override
  String get aiTutorCardPracticing => '练习中…';

  @override
  String aiTutorPlanSrsReview(int count, int done) {
    return '复习 $count 张 SRS 卡 ($done 完成)';
  }

  @override
  String aiTutorPlanGrammar(String topic) {
    return '练习: $topic';
  }

  @override
  String aiTutorPlanChat(int min, int done) {
    return '聊 $min 分钟 (目前 $done)';
  }

  @override
  String get aboutBananatalk => '关于 Bananatalk';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get permanentlyDeleteYourAccount => '永久删除您的账户';

  @override
  String get loggedOutSuccessfully => '已成功退出登录';

  @override
  String get retry => '重试';

  @override
  String get giftsLikes => '礼物/点赞';

  @override
  String get details => '详情';

  @override
  String get to => '到';

  @override
  String get banaTalk => 'Bananatalk';

  @override
  String get chats => '聊天';

  @override
  String get community => '社区';

  @override
  String get editProfile => '编辑资料';

  @override
  String yearsOld(String age) {
    return '$age 岁';
  }

  @override
  String get searchConversations => '搜索对话...';

  @override
  String get visitorTrackingNotAvailable => '访客跟踪功能尚未可用。需要后端更新。';

  @override
  String get chatList => '聊天列表';

  @override
  String get languageExchange => '语言交流';

  @override
  String get nativeLanguage => '母语';

  @override
  String get learning => '学习';

  @override
  String get notSet => '未设置';

  @override
  String get about => '关于';

  @override
  String get aboutMe => '关于我';

  @override
  String get bloodType => '血型';

  @override
  String get photos => '照片';

  @override
  String get camera => '相机';

  @override
  String get createMoment => '发布动态';

  @override
  String get addATitle => '添加标题...';

  @override
  String get whatsOnYourMind => '你在想什么？';

  @override
  String get addTags => '添加标签';

  @override
  String get done => '完成';

  @override
  String get add => '添加';

  @override
  String get enterTag => '输入标签';

  @override
  String get post => '发布';

  @override
  String get commentAddedSuccessfully => '评论添加成功';

  @override
  String get clearFilters => '清除筛选';

  @override
  String get notificationSettings => '通知设置';

  @override
  String get enableNotifications => '启用通知';

  @override
  String get turnAllNotificationsOnOrOff => '打开或关闭所有通知';

  @override
  String get notificationTypes => '通知类型';

  @override
  String get chatMessages => '聊天消息';

  @override
  String get getNotifiedWhenYouReceiveMessages => '收到消息时通知您';

  @override
  String get likesAndCommentsOnYourMoments => '您的动态收到的点赞和评论';

  @override
  String get whenPeopleYouFollowPostMoments => '您关注的人发布动态时';

  @override
  String get friendRequests => '好友请求';

  @override
  String get whenSomeoneFollowsYou => '有人关注您时';

  @override
  String get profileVisits => '个人资料访问';

  @override
  String get whenSomeoneViewsYourProfileVIP => '有人查看您的个人资料时（VIP）';

  @override
  String get marketing => '营销';

  @override
  String get updatesAndPromotionalMessages => '更新和促销消息';

  @override
  String get notificationPreferences => '通知偏好';

  @override
  String get sound => '声音';

  @override
  String get playNotificationSounds => '播放通知声音';

  @override
  String get vibration => '振动';

  @override
  String get vibrateOnNotifications => '通知时振动';

  @override
  String get showPreview => '显示预览';

  @override
  String get showMessagePreviewInNotifications => '在通知中显示消息预览';

  @override
  String get mutedConversations => '静音对话';

  @override
  String get conversation => '对话';

  @override
  String get unmute => '取消静音';

  @override
  String get systemNotificationSettings => '系统通知设置';

  @override
  String get manageNotificationsInSystemSettings => '在系统设置中管理通知';

  @override
  String get errorLoadingSettings => '加载设置时出错';

  @override
  String get unblockUser => '取消屏蔽用户';

  @override
  String get unblock => '取消屏蔽';

  @override
  String get goBack => '返回';

  @override
  String get messageSendTimeout => '消息发送超时。请检查您的连接。';

  @override
  String get failedToSendMessage => '发送消息失败';

  @override
  String get dailyMessageLimitExceeded => '已达到每日消息限制。升级到VIP可享受无限消息。';

  @override
  String get cannotSendMessageUserMayBeBlocked => '无法发送消息。用户可能已被屏蔽。';

  @override
  String get sessionExpired => '会话已过期，请重新登录。';

  @override
  String get sendThisSticker => '发送此贴纸？';

  @override
  String get chooseHowYouWantToDeleteThisMessage => '选择您要如何删除此消息：';

  @override
  String get deleteForEveryone => '为所有人删除';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => '为您和收件人删除消息';

  @override
  String get deleteForMe => '仅为我删除';

  @override
  String get removesTheMessageOnlyFromYourChat => '仅从您的聊天中删除消息';

  @override
  String get copy => '复制';

  @override
  String get reply => '回复';

  @override
  String get forward => '转发';

  @override
  String get moreOptions => '更多选项';

  @override
  String get noUsersAvailableToForwardTo => '没有可转发的用户';

  @override
  String get searchMoments => '搜索动态...';

  @override
  String searchInChatWith(String name) {
    return '在 $name 的聊天中搜索';
  }

  @override
  String get typeAMessage => '输入消息...';

  @override
  String get enterYourMessage => '输入您的消息';

  @override
  String get detectYourLocation => '检测您的位置';

  @override
  String get tapToUpdateLocation => '点击更新位置';

  @override
  String get helpOthersFindYouNearby => '帮助其他人在附近找到您';

  @override
  String get selectYourNativeLanguage => '选择您的母语';

  @override
  String get whichLanguageDoYouWantToLearn => '您想学习哪种语言？';

  @override
  String get selectYourGender => '选择您的性别';

  @override
  String get addACaption => '添加标题...';

  @override
  String get typeSomething => '输入一些内容...';

  @override
  String get gallery => '图库';

  @override
  String get video => '视频';

  @override
  String get text => '文本';

  @override
  String get provideMoreInformation => '提供更多信息...';

  @override
  String get searchByNameLanguageOrInterests => '按姓名、语言或兴趣搜索...';

  @override
  String get addTagAndPressEnter => '添加标签并按回车';

  @override
  String replyTo(String name) {
    return '回复 $name...';
  }

  @override
  String get highlightName => '高亮名称';

  @override
  String get searchCloseFriends => '搜索密友...';

  @override
  String get askAQuestion => '提问...';

  @override
  String option(String number) {
    return '选项 $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return '您为什么要举报此 $type？';
  }

  @override
  String get additionalDetailsOptional => '附加详细信息（可选）';

  @override
  String get warningThisActionIsPermanent => '警告：此操作是永久性的！';

  @override
  String get deletingYourAccountWillPermanentlyRemove => '删除您的账户将永久删除：\n\n• 您的个人资料和所有个人数据\n• 您的所有消息和对话\n• 您的所有动态和故事\n• 您的VIP订阅（不退款）\n• 您的所有联系人和关注者\n\n此操作无法撤销。';

  @override
  String get clearAllNotifications => '清除所有通知？';

  @override
  String get clearAll => '清除全部';

  @override
  String get notificationDebug => '通知调试';

  @override
  String get markAllRead => '全部标记为已读';

  @override
  String get clearAll2 => '全部清除';

  @override
  String get emailAddress => '电子邮件地址';

  @override
  String get username => '用户名';

  @override
  String get alreadyHaveAnAccount => '已有账户？';

  @override
  String get login2 => '登录';

  @override
  String get selectYourNativeLanguage2 => '选择您的母语';

  @override
  String get whichLanguageDoYouWantToLearn2 => '您想学习哪种语言？';

  @override
  String get selectYourGender2 => '选择您的性别';

  @override
  String get dateFormat => 'YYYY.MM.DD';

  @override
  String get detectYourLocation2 => '检测您的位置';

  @override
  String get tapToUpdateLocation2 => '点击更新位置';

  @override
  String get helpOthersFindYouNearby2 => '帮助其他人在附近找到您';

  @override
  String get couldNotOpenLink => '无法打开链接';

  @override
  String get legalPrivacy2 => '法律和隐私';

  @override
  String get termsOfUseEULA => '使用条款 (EULA)';

  @override
  String get viewOurTermsAndConditions => '查看我们的条款和条件';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get howWeHandleYourData => '我们如何处理您的数据';

  @override
  String get emailNotifications => '邮件通知';

  @override
  String get receiveEmailNotificationsFromBananatalk => '接收来自 Bananatalk 的电子邮件通知';

  @override
  String get weeklySummary => '每周摘要';

  @override
  String get activityRecapEverySunday => '每周日的活动回顾';

  @override
  String get newMessages => '新消息';

  @override
  String get whenYoureAwayFor24PlusHours => '当您离开 24 小时以上时';

  @override
  String get newFollowers => '新关注者';

  @override
  String get whenSomeoneFollowsYou2 => '当有人关注您时';

  @override
  String get securityAlerts => '安全警报';

  @override
  String get passwordLoginAlerts => '密码和登录警报';

  @override
  String get unblockUser2 => '取消屏蔽用户';

  @override
  String get blockedUsers2 => '已屏蔽的用户';

  @override
  String get finalWarning => '⚠️ 最终警告';

  @override
  String get deleteForever => '永久删除';

  @override
  String get deleteAccount2 => '删除账户';

  @override
  String get enterYourPassword => '请输入密码';

  @override
  String get yourPassword => '您的密码';

  @override
  String get typeDELETEToConfirm => '输入 DELETE 以确认';

  @override
  String get typeDELETEInCapitalLetters => '用大写字母输入 DELETE';

  @override
  String sent(String emoji) {
    return '已发送！';
  }

  @override
  String get replySent => '回复已发送！';

  @override
  String get deleteStory => '删除故事？';

  @override
  String get thisStoryWillBeRemovedPermanently => '此故事将被永久删除。';

  @override
  String get noStories => '暂无故事';

  @override
  String views(String count) {
    return '$count 次查看';
  }

  @override
  String get reportStory => '举报故事';

  @override
  String get reply2 => '回复...';

  @override
  String get failedToPickImage => '选择图片失败';

  @override
  String get failedToTakePhoto => '拍照失败';

  @override
  String get failedToPickVideo => '选择视频失败';

  @override
  String get pleaseEnterSomeText => '请输入一些文本';

  @override
  String get pleaseSelectMedia => '请选择媒体';

  @override
  String get storyPosted => '故事已发布！';

  @override
  String get textOnlyStoriesRequireAnImage => '纯文本故事需要图片';

  @override
  String get createStory => '创建故事';

  @override
  String get change => '更改';

  @override
  String get userIdNotFound => '未找到用户 ID。请重新登录。';

  @override
  String get pleaseSelectAPaymentMethod => '请选择付款方式';

  @override
  String get startExploring => '开始探索';

  @override
  String get close => '关闭';

  @override
  String get payment => '付款';

  @override
  String get upgradeToVIP => '升级到 VIP';

  @override
  String get errorLoadingProducts => '加载产品时出错';

  @override
  String get cancelVIPSubscription => '取消 VIP 订阅';

  @override
  String get keepVIP => '保留 VIP';

  @override
  String get cancelSubscription => '取消订阅';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'VIP 订阅已成功取消';

  @override
  String get vipStatus => 'VIP 状态';

  @override
  String get noActiveVIPSubscription => '没有活动的 VIP 订阅';

  @override
  String get subscriptionExpired => '订阅已过期';

  @override
  String get vipExpiredMessage => '您的VIP订阅已过期。立即续订，继续享受无限功能！';

  @override
  String get expiredOn => '过期于';

  @override
  String get renewVIP => '续订VIP';

  @override
  String get whatYoureMissing => '您错过的功能';

  @override
  String get manageInAppStore => '在App Store中管理';

  @override
  String get becomeVIP => '成为VIP';

  @override
  String get unlimitedMessages => '无限消息';

  @override
  String get unlimitedProfileViews => '无限个人资料查看';

  @override
  String get prioritySupport => '优先支持';

  @override
  String get advancedSearch => '高级搜索';

  @override
  String get profileBoost => '个人资料提升';

  @override
  String get adFreeExperience => '无广告体验';

  @override
  String get upgradeYourAccount => '升级您的账户';

  @override
  String get moreMessages => '更多消息';

  @override
  String get moreProfileViews => '更多个人资料查看';

  @override
  String get connectWithFriends => '与朋友联系';

  @override
  String get reviewStarted => '审查已开始';

  @override
  String get reportResolved => '报告已解决';

  @override
  String get reportDismissed => '报告已驳回';

  @override
  String get selectAction => '选择操作';

  @override
  String get noViolation => '无违规';

  @override
  String get contentRemoved => '内容已删除';

  @override
  String get userWarned => '用户已警告';

  @override
  String get userSuspended => '用户已暂停';

  @override
  String get userBanned => '用户已封禁';

  @override
  String get addNotesOptional => '添加备注（可选）';

  @override
  String get enterModeratorNotes => '输入审核员备注...';

  @override
  String get skip => '跳过';

  @override
  String get startReview => '开始审查';

  @override
  String get resolve => '解决';

  @override
  String get dismiss => '驳回';

  @override
  String get filterReports => '筛选报告';

  @override
  String get all => '全部';

  @override
  String get clear => '清除';

  @override
  String get apply => '应用';

  @override
  String get myReports2 => '我的报告';

  @override
  String get blockUser => '屏蔽用户';

  @override
  String get block => '屏蔽';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => '您是否也想屏蔽此用户？';

  @override
  String get noThanks => '不，谢谢';

  @override
  String get yesBlockThem => '是的，屏蔽他们';

  @override
  String get reportUser2 => '举报用户';

  @override
  String get submitReport => '提交报告';

  @override
  String get addAQuestionAndAtLeast2Options => '添加一个问题并至少 2 个选项';

  @override
  String get addOption => '添加选项';

  @override
  String get anonymousVoting => '匿名投票';

  @override
  String get create => '创建';

  @override
  String get typeYourAnswer => '输入您的答案...';

  @override
  String get send2 => '发送';

  @override
  String get yourPrompt => '您的提示...';

  @override
  String get add2 => '添加';

  @override
  String get contentNotAvailable => '内容不可用';

  @override
  String get profileNotAvailable => '个人资料不可用';

  @override
  String get noMomentsToShow => '没有动态可显示';

  @override
  String get storiesNotAvailable => '故事不可用';

  @override
  String get cantMessageThisUser => '无法向此用户发送消息';

  @override
  String get pleaseSelectAReason => '请选择原因';

  @override
  String get reportSubmitted => '举报已提交。感谢您帮助维护社区安全。';

  @override
  String get youHaveAlreadyReportedThisMoment => '您已经举报过这条动态';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => '请告诉我们您举报的原因';

  @override
  String get errorSharing => '分享出错';

  @override
  String get deviceInfo => '设备信息';

  @override
  String get recommended => '推荐';

  @override
  String get anyLanguage => '任何语言';

  @override
  String get noLanguagesFound => '未找到语言';

  @override
  String get selectALanguage => '选择语言';

  @override
  String get languagesAreStillLoading => '正在加载语言...';

  @override
  String get selectNativeLanguage => '选择您的母语';

  @override
  String get subscriptionDetails => '订阅详情';

  @override
  String get activeFeatures => '活跃功能';

  @override
  String get legalInformation => '法律信息';

  @override
  String get termsOfUse => '使用条款';

  @override
  String get manageSubscription => '管理订阅';

  @override
  String get manageSubscriptionInSettings => '要取消订阅，请前往设备上的设置 > [您的姓名] > 订阅。';

  @override
  String get contactSupportToCancel => '要取消订阅，请联系我们的支持团队。';

  @override
  String get status => '状态';

  @override
  String get active => '活跃';

  @override
  String get plan => '套餐';

  @override
  String get startDate => '开始日期';

  @override
  String get endDate => '结束日期';

  @override
  String get nextBillingDate => '下次计费日期';

  @override
  String get autoRenew => '自动续费';

  @override
  String get pleaseLogInToContinue => '请登录以继续';

  @override
  String get purchaseCanceledOrFailed => '购买已取消或失败。请重试。';

  @override
  String get maximumTagsAllowed => '最多允许 5 个标签';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => '请先移除图片再添加视频';

  @override
  String get unsupportedFormat => '不支持的格式';

  @override
  String get errorProcessingVideo => '处理视频时出错';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => '请先移除图片再录制视频';

  @override
  String get locationAdded => '已添加位置';

  @override
  String get failedToGetLocation => '获取位置失败';

  @override
  String get notNow => '暂不';

  @override
  String get videoUploadFailed => '视频上传失败';

  @override
  String get skipVideo => '跳过视频';

  @override
  String get retryUpload => '重试上传';

  @override
  String get momentCreatedSuccessfully => '动态发布成功';

  @override
  String get uploadingMomentInBackground => '正在后台上传动态...';

  @override
  String get failedToQueueUpload => '添加到上传队列失败';

  @override
  String get viewProfile => '查看资料';

  @override
  String get mediaLinksAndDocs => '媒体、链接和文档';

  @override
  String get wallpaper => '壁纸';

  @override
  String get userIdNotAvailable => '用户 ID 不可用';

  @override
  String get cannotBlockYourself => '无法屏蔽自己';

  @override
  String get chatWallpaper => '聊天壁纸';

  @override
  String get wallpaperSavedLocally => '壁纸已本地保存';

  @override
  String get messageCopied => '消息已复制';

  @override
  String get forwardFeatureComingSoon => '转发功能即将推出';

  @override
  String get momentUnsaved => '已从保存中移除';

  @override
  String get documentPickerComingSoon => '文档选择器即将推出';

  @override
  String get contactSharingComingSoon => '联系人分享即将推出';

  @override
  String get featureComingSoon => '功能即将推出';

  @override
  String get answerSent => '回答已发送！';

  @override
  String get noImagesAvailable => '没有可用的图片';

  @override
  String get mentionPickerComingSoon => '提及选择器即将推出';

  @override
  String get musicPickerComingSoon => '音乐选择器即将推出';

  @override
  String get repostFeatureComingSoon => '转发功能即将推出';

  @override
  String get addFriendsFromYourProfile => '从您的个人资料添加好友';

  @override
  String get quickReplyAdded => '快捷回复已添加';

  @override
  String get quickReplyDeleted => '快捷回复已删除';

  @override
  String get linkCopied => '链接已复制！';

  @override
  String get maximumOptionsAllowed => '最多允许 10 个选项';

  @override
  String get minimumOptionsRequired => '至少需要 2 个选项';

  @override
  String get pleaseEnterAQuestion => '请输入问题';

  @override
  String get pleaseAddAtLeast2Options => '请添加至少 2 个选项';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => '请选择测验的正确答案';

  @override
  String get correctionSent => '更正已发送！';

  @override
  String get sort => '排序';

  @override
  String get savedMoments => '已保存的动态';

  @override
  String get unsave => '取消保存';

  @override
  String get playingAudio => '正在播放音频...';

  @override
  String get failedToGenerateQuiz => '生成测验失败';

  @override
  String get failedToAddComment => '添加评论失败';

  @override
  String get hello => '你好！';

  @override
  String get howAreYou => '你好吗？';

  @override
  String get cannotOpen => '无法打开';

  @override
  String get errorOpeningLink => '打开链接时出错';

  @override
  String get saved => '已保存';

  @override
  String get follow => '关注';

  @override
  String get unfollow => '取消关注';

  @override
  String get mute => '静音';

  @override
  String get online => '在线';

  @override
  String get offline => '离线';

  @override
  String get lastSeen => '最后上线';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(String count) {
    return '$count 分钟前';
  }

  @override
  String hoursAgo(String count) {
    return '$count 小时前';
  }

  @override
  String get yesterday => '昨天';

  @override
  String get signInWithEmail => '使用邮箱登录';

  @override
  String get partners => '伙伴';

  @override
  String get nearby => '附近';

  @override
  String get topics => '话题';

  @override
  String get waves => '打招呼';

  @override
  String get voiceRooms => '语音';

  @override
  String get filters => '筛选';

  @override
  String get searchCommunity => '按姓名、语言或兴趣搜索...';

  @override
  String get bio => '简介';

  @override
  String get noBioYet => '暂无简介';

  @override
  String get languages => '语言';

  @override
  String get native => '母语';

  @override
  String get interests => '兴趣';

  @override
  String get noMomentsYet => '暂无动态';

  @override
  String get noForYouMomentsTitle => '暂无动态';

  @override
  String get noForYouMomentsBody => '回答今日话题，开启对话吧。';

  @override
  String get noFollowingMomentsTitle => '这里还没有内容';

  @override
  String get noFollowingMomentsBody => '在社区中关注他人，即可在此查看他们的动态。';

  @override
  String get goToCommunity => '前往社区';

  @override
  String get unableToLoadMoments => '无法加载动态';

  @override
  String get map => '地图';

  @override
  String get mapUnavailable => '地图不可用';

  @override
  String get location => '位置';

  @override
  String get unknownLocation => '未知位置';

  @override
  String get noImagesAvailable2 => '暂无图片';

  @override
  String get permissionsRequired => '需要权限';

  @override
  String get openSettings => '打开设置';

  @override
  String get refresh => '刷新';

  @override
  String get videoCall => '视频';

  @override
  String get voiceCall => '通话';

  @override
  String get message => '消息';

  @override
  String get pleaseLoginToFollow => '请登录后关注用户';

  @override
  String get pleaseLoginToCall => '请登录后拨打电话';

  @override
  String get cannotCallYourself => '不能给自己打电话';

  @override
  String get failedToFollowUser => '关注失败';

  @override
  String get failedToUnfollowUser => '取消关注失败';

  @override
  String get areYouSureUnfollow => '确定要取消关注吗？';

  @override
  String get areYouSureUnblock => '确定要解除屏蔽吗？';

  @override
  String get youFollowed => '已关注';

  @override
  String get youUnfollowed => '已取消关注';

  @override
  String get alreadyFollowing => '已经关注了';

  @override
  String get soon => '即将';

  @override
  String comingSoon(String feature) {
    return '$feature即将推出！';
  }

  @override
  String get muteNotifications => '静音通知';

  @override
  String get unmuteNotifications => '取消静音';

  @override
  String get operationCompleted => '操作完成';

  @override
  String get couldNotOpenMaps => '无法打开地图';

  @override
  String hasntSharedMoments(Object name) {
    return '$name还没有分享任何动态';
  }

  @override
  String messageUser(String name) {
    return '给$name发消息';
  }

  @override
  String notFollowingUser(String name) {
    return '你没有关注$name';
  }

  @override
  String youFollowedUser(String name) {
    return '你关注了$name';
  }

  @override
  String youUnfollowedUser(String name) {
    return '你取消关注了$name';
  }

  @override
  String unfollowUser(String name) {
    return '取消关注$name';
  }

  @override
  String get typing => '正在输入';

  @override
  String get connecting => '连接中...';

  @override
  String daysAgo(int count) {
    return '$count天前';
  }

  @override
  String get maxTagsAllowed => '最多允许5个标签';

  @override
  String maxImagesAllowed(int count) {
    return '最多允许$count张图片';
  }

  @override
  String get pleaseRemoveImagesFirst => '请先删除图片再添加视频';

  @override
  String get exchange3MessagesBeforeCall => '通话前请先互发 5 条以上消息';

  @override
  String mediaWithUser(String name) {
    return '与$name的媒体';
  }

  @override
  String get errorLoadingMedia => '加载媒体出错';

  @override
  String get savedMomentsTitle => '已保存的动态';

  @override
  String get removeBookmark => '删除收藏？';

  @override
  String get thisWillRemoveBookmark => '这将从书签中移除此消息。';

  @override
  String get remove => '移除';

  @override
  String get bookmarkRemoved => '收藏已删除';

  @override
  String get bookmarkedMessages => '收藏的消息';

  @override
  String get wallpaperSaved => '壁纸已保存到本地';

  @override
  String get typeDeleteToConfirm => '输入DELETE确认';

  @override
  String get storyArchive => '故事存档';

  @override
  String get newHighlight => '新精选';

  @override
  String get addToHighlight => '添加到精选';

  @override
  String get repost => '转发';

  @override
  String get repostFeatureSoon => '转发功能即将推出';

  @override
  String get closeFriends => '亲密朋友';

  @override
  String get addFriends => '添加朋友';

  @override
  String get highlights => '精选';

  @override
  String get createHighlight => '创建精选';

  @override
  String get deleteHighlight => '删除精选';

  @override
  String get editHighlight => '编辑精选';

  @override
  String get addMoreToStory => '添加更多到故事';

  @override
  String get noViewersYet => '暂无观看者';

  @override
  String get noReactionsYet => '暂无反应';

  @override
  String get leaveRoom => '离开房间';

  @override
  String get areYouSureLeaveRoom => '确定要离开这个语音房间吗？';

  @override
  String get stay => '留下';

  @override
  String get leave => '离开';

  @override
  String get enableGPS => '启用GPS';

  @override
  String wavedToUser(String name) {
    return '向$name打招呼了！';
  }

  @override
  String get areYouSureFollow => '确定要关注吗';

  @override
  String get failedToLoadProfile => '加载个人资料失败';

  @override
  String get noFollowersYet => '暂无粉丝';

  @override
  String get noFollowingYet => '暂未关注任何人';

  @override
  String get searchUsers => '搜索用户...';

  @override
  String get noResultsFound => '未找到结果';

  @override
  String get loadingFailed => '加载失败';

  @override
  String get copyLink => '复制链接';

  @override
  String get shareStory => '分享故事';

  @override
  String get thisWillDeleteStory => '这将永久删除此故事。';

  @override
  String get storyDeleted => '故事已删除';

  @override
  String get addCaption => '添加说明...';

  @override
  String get yourStory => '我的故事';

  @override
  String get sendMessage => '发送消息';

  @override
  String get replyToStory => '回复故事...';

  @override
  String get viewAllReplies => '查看所有回复';

  @override
  String get preparingVideo => '正在准备视频...';

  @override
  String videoOptimized(String size, String savings) {
    return '视频已优化：${size}MB（节省$savings%）';
  }

  @override
  String get failedToProcessVideo => '视频处理失败';

  @override
  String get optimizingForBestExperience => '正在优化以获得最佳故事体验';

  @override
  String get pleaseSelectImageOrVideo => '请为您的故事选择图片或视频';

  @override
  String get storyCreatedSuccessfully => '故事创建成功！';

  @override
  String get uploadingStoryInBackground => '正在后台上传故事...';

  @override
  String get storyCreationFailed => '故事创建失败';

  @override
  String get pleaseCheckConnection => '请检查您的连接并重试。';

  @override
  String get uploadFailed => '上传失败';

  @override
  String get tryShorterVideo => '请尝试使用较短的视频或稍后重试。';

  @override
  String get shareMomentsThatDisappear => '分享24小时后消失的瞬间';

  @override
  String get photo => '照片';

  @override
  String get record => '录制';

  @override
  String get addSticker => '添加贴纸';

  @override
  String get poll => '投票';

  @override
  String get question => '问题';

  @override
  String get mention => '提及';

  @override
  String get music => '音乐';

  @override
  String get hashtag => '话题标签';

  @override
  String get whoCanSeeThis => '谁可以看到？';

  @override
  String get everyone => '所有人';

  @override
  String get anyoneCanSeeStory => '任何人都可以看到此故事';

  @override
  String get friendsOnly => '仅好友';

  @override
  String get onlyFollowersCanSee => '只有您的粉丝可以看到';

  @override
  String get onlyCloseFriendsCanSee => '只有您的亲密好友可以看到';

  @override
  String get backgroundColor => '背景颜色';

  @override
  String get fontStyle => '字体样式';

  @override
  String get normal => '正常';

  @override
  String get bold => '粗体';

  @override
  String get italic => '斜体';

  @override
  String get handwriting => '手写体';

  @override
  String get addLocation => '添加位置';

  @override
  String get enterLocationName => '输入位置名称';

  @override
  String get addLink => '添加链接';

  @override
  String get buttonText => '按钮文字';

  @override
  String get learnMore => '了解更多';

  @override
  String get addHashtags => '添加话题标签';

  @override
  String get addHashtag => '添加话题标签';

  @override
  String get sendAsMessage => '发送为消息';

  @override
  String get shareExternally => '外部分享';

  @override
  String get checkOutStory => '在Bananatalk查看这个故事！';

  @override
  String viewsTab(String count) {
    return '浏览 ($count)';
  }

  @override
  String reactionsTab(String count) {
    return '反应 ($count)';
  }

  @override
  String get processingVideo => '正在处理视频...';

  @override
  String get link => '链接';

  @override
  String unmuteUser(String name) {
    return '取消静音 $name？';
  }

  @override
  String get willReceiveNotifications => '您将收到新消息通知。';

  @override
  String muteNotificationsFor(String name) {
    return '静音 $name 的通知';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return '已取消 $name 的静音';
  }

  @override
  String notificationsMutedFor(String name) {
    return '已静音 $name 的通知';
  }

  @override
  String get failedToUpdateMuteSettings => '更新静音设置失败';

  @override
  String get oneHour => '1小时';

  @override
  String get eightHours => '8小时';

  @override
  String get oneWeek => '1周';

  @override
  String get always => '始终';

  @override
  String get failedToLoadBookmarks => '加载收藏失败';

  @override
  String get noBookmarkedMessages => '没有收藏的消息';

  @override
  String get longPressToBookmark => '长按消息以收藏';

  @override
  String get thisWillRemoveFromBookmarks => '这将从您的收藏中删除该消息。';

  @override
  String navigateToMessage(String name) {
    return '在与 $name 的聊天中查看消息';
  }

  @override
  String bookmarkedOn(String date) {
    return '收藏于 $date';
  }

  @override
  String get voiceMessage => '语音消息';

  @override
  String get document => '文档';

  @override
  String get attachment => '附件';

  @override
  String get sendMeAMessage => '给我发消息';

  @override
  String get shareWithFriends => '与朋友分享';

  @override
  String get shareAnywhere => '分享到任何地方';

  @override
  String get emailPreferences => '邮件设置';

  @override
  String get receiveEmailNotifications => '接收来自Bananatalk的邮件通知';

  @override
  String get whenAwayFor24Hours => '当你离开超过24小时';

  @override
  String get passwordAndLoginAlerts => '密码与登录提醒';

  @override
  String get failedToLoadPreferences => '加载偏好设置失败';

  @override
  String get failedToUpdateSetting => '更新设置失败';

  @override
  String get securityAlertsRecommended => '我们建议保持开启安全提醒，以便及时了解账户的重要活动。';

  @override
  String chatWallpaperFor(String name) {
    return '$name 的聊天壁纸';
  }

  @override
  String get solidColors => '纯色';

  @override
  String get gradients => '渐变';

  @override
  String get customImage => '自定义图片';

  @override
  String get chooseFromGallery => '从相册选择';

  @override
  String get preview => '预览';

  @override
  String get wallpaperUpdated => '壁纸已更新';

  @override
  String get category => '分类';

  @override
  String get mood => '心情';

  @override
  String get sortBy => '排序方式';

  @override
  String get timePeriod => '时间段';

  @override
  String get searchLanguages => '搜索语言…';

  @override
  String get selected => '已选择';

  @override
  String get categories => '分类';

  @override
  String get moods => '心情';

  @override
  String get applyFilters => '应用筛选';

  @override
  String applyNFilters(int count) {
    return '应用 $count 个筛选条件';
  }

  @override
  String get videoMustBeUnder1GB => '视频必须小于1GB。';

  @override
  String get failedToRecordVideo => '录制视频失败';

  @override
  String get errorSendingVideo => '发送视频出错';

  @override
  String get errorSendingVoiceMessage => '发送语音消息出错';

  @override
  String get errorSendingMedia => '发送媒体文件出错';

  @override
  String get cameraPermissionRequired => '录制视频需要相机和麦克风权限。';

  @override
  String get locationPermissionRequired => '分享位置需要位置权限。';

  @override
  String get noInternetConnection => '无网络连接';

  @override
  String get tryAgainLater => '请稍后重试';

  @override
  String get messageSent => '消息已发送';

  @override
  String get messageDeleted => '消息已删除';

  @override
  String get messageEdited => '消息已编辑';

  @override
  String get edited => '(已编辑)';

  @override
  String get now => '刚刚';

  @override
  String weeksAgo(int count) {
    return '$count周前';
  }

  @override
  String viewRepliesCount(int count) {
    return '── 查看$count条回复';
  }

  @override
  String get hideReplies => '── 隐藏回复';

  @override
  String get saveMoment => '保存动态';

  @override
  String get removeFromSaved => '取消保存';

  @override
  String get momentSaved => '已保存';

  @override
  String get failedToSave => '保存失败';

  @override
  String get checkOutMoment => '在Bananatalk上看看这条动态!';

  @override
  String get checkOutProfile => '快来看看这个 Bananatalk 上的个人主页！';

  @override
  String get checkOutCommunity => '快来看看这位 Bananatalk 成员！';

  @override
  String get failedToLoadMoments => '加载动态失败';

  @override
  String get noMomentsMatchFilters => '没有匹配筛选条件的动态';

  @override
  String get beFirstToShareMoment => '成为第一个分享动态的人！';

  @override
  String get tryDifferentSearch => '试试其他搜索词';

  @override
  String get tryAdjustingFilters => '试试调整筛选条件';

  @override
  String get noSavedMoments => '没有保存的动态';

  @override
  String get tapBookmarkToSave => '点击书签图标保存动态';

  @override
  String get failedToLoadVideo => '视频加载失败';

  @override
  String get titleRequired => '标题不能为空';

  @override
  String titleTooLong(int max) {
    return '标题不能超过$max个字符';
  }

  @override
  String get descriptionRequired => '描述不能为空';

  @override
  String descriptionTooLong(int max) {
    return '描述不能超过$max个字符';
  }

  @override
  String get scheduledDateMustBeFuture => '预约日期必须是将来的日期';

  @override
  String get recent => '最新';

  @override
  String get popular => '热门';

  @override
  String get trending => '趋势';

  @override
  String get mostRecent => '最新';

  @override
  String get mostPopular => '最热门';

  @override
  String get allTime => '全部';

  @override
  String get today => '今天';

  @override
  String get thisWeek => '本周';

  @override
  String get thisMonth => '本月';

  @override
  String replyingTo(String userName) {
    return '回复 $userName';
  }

  @override
  String get listView => '列表';

  @override
  String get quickMatch => '快速匹配';

  @override
  String get onlineNow => '在线';

  @override
  String speaksLanguage(String language) {
    return '说$language';
  }

  @override
  String learningLanguage(String language) {
    return '学习$language';
  }

  @override
  String get noPartnersFound => '未找到语伴';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return '未找到以$learning为母语或正在学习$native的用户。';
  }

  @override
  String get removeAllFilters => '清除所有筛选';

  @override
  String get browseAllUsers => '浏览所有用户';

  @override
  String get allCaughtUp => '已全部查看！';

  @override
  String get loadingMore => '加载更多...';

  @override
  String get findingMorePartners => '正在为你寻找更多语伴...';

  @override
  String get seenAllPartners => '你已查看所有可用语伴。稍后再来看看吧！';

  @override
  String get startOver => '重新开始';

  @override
  String get changeFilters => '更改筛选条件';

  @override
  String get findingPartners => '正在寻找语伴...';

  @override
  String get setLocationReminder => '在个人资料中设置位置，优先查看附近用户。';

  @override
  String get updateLocationReminder => '在 个人资料 > 编辑 中更新位置以获得准确的附近结果。';

  @override
  String get male => '男性';

  @override
  String get female => '女性';

  @override
  String get other => '其他';

  @override
  String get browseMen => '浏览男性';

  @override
  String get browseWomen => '浏览女性';

  @override
  String get noMaleUsersFound => '未找到男性用户';

  @override
  String get noFemaleUsersFound => '未找到女性用户';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => '仅新用户';

  @override
  String get showNewUsers => '显示最近6天内加入的用户';

  @override
  String get prioritizeNearby => '优先附近';

  @override
  String get showNearbyFirst => '优先显示附近用户';

  @override
  String get setLocationToEnable => '设置位置以启用此功能';

  @override
  String get radius => '半径';

  @override
  String get findingYourLocation => '正在定位...';

  @override
  String get enableLocationForDistance => '启用定位查看距离';

  @override
  String get enableLocationDescription => '启用GPS以查看与语伴的精确距离。';

  @override
  String get enableGps => '启用GPS';

  @override
  String get browseByCityCountry => '按城市/国家浏览';

  @override
  String get peopleNearby => '附近的人';

  @override
  String get noNearbyUsersFound => '未找到附近用户';

  @override
  String get tryExpandingSearch => '尝试扩大搜索范围或稍后再试。';

  @override
  String get exploreByCity => '按城市探索';

  @override
  String get exploreByCurrentCity => '在互动地图上浏览用户，发现全球语伴。';

  @override
  String get interactiveWorldMap => '互动世界地图';

  @override
  String get searchByCityName => '按城市名搜索';

  @override
  String get seeUserCountsPerCountry => '查看各国用户数量';

  @override
  String get upgradeToVip => '升级VIP';

  @override
  String get searchByCity => '搜索城市...';

  @override
  String usersWorldwide(String count) {
    return '全球$count人';
  }

  @override
  String get noUsersFound => '未找到用户';

  @override
  String get tryDifferentCity => '试试其他城市或国家';

  @override
  String usersCount(String count) {
    return '$count人';
  }

  @override
  String get searchCountry => '搜索国家...';

  @override
  String get wave => '打招呼';

  @override
  String get newUser => 'NEW';

  @override
  String get warningPermanent => '警告：此操作不可撤销！';

  @override
  String get deleteAccountWarning => '删除账号将永久删除：\n\n• 你的个人资料和所有个人数据\n• 所有消息和对话\n• 所有动态和故事\n• VIP订阅（不退款）\n• 所有关注和粉丝\n\n此操作不可撤销。';

  @override
  String get requiredForEmailOnly => '仅邮箱账号需要';

  @override
  String get pleaseEnterPassword => '请输入密码';

  @override
  String get typeDELETE => '输入DELETE确认';

  @override
  String get mustTypeDELETE => '必须输入DELETE确认';

  @override
  String get deletingAccount => '正在删除账号...';

  @override
  String get deleteMyAccountPermanently => '永久删除我的账号';

  @override
  String get whatsYourNativeLanguage => '你的母语是什么？';

  @override
  String get helpsMatchWithLearners => '帮助我们为你匹配学习者';

  @override
  String get whatAreYouLearning => '你在学什么？';

  @override
  String get connectWithNativeSpeakers => '我们会为你连接母语者';

  @override
  String get selectLearningLanguage => '请选择你正在学习的语言';

  @override
  String get selectCurrentLevel => '请选择你的当前水平';

  @override
  String get beginner => '入门';

  @override
  String get elementary => '初级';

  @override
  String get intermediate => '中级';

  @override
  String get upperIntermediate => '中高级';

  @override
  String get advanced => '高级';

  @override
  String get proficient => '精通';

  @override
  String get showingPartnersByDistance => '按距离排序显示语伴';

  @override
  String get enableLocationForResults => '启用定位以获取基于距离的结果';

  @override
  String get enable => '启用';

  @override
  String get locationNotSet => '未设置位置';

  @override
  String get tellUsAboutYourself => '介绍一下你自己';

  @override
  String get justACoupleQuickThings => '只需几个简单问题';

  @override
  String get gender => '性别';

  @override
  String get birthDate => '出生日期';

  @override
  String get selectYourBirthDate => '选择你的出生日期';

  @override
  String get continueButton => '继续';

  @override
  String get pleaseSelectGender => '请选择你的性别';

  @override
  String get pleaseSelectBirthDate => '请选择你的出生日期';

  @override
  String get mustBe18 => '你必须年满18岁';

  @override
  String get invalidDate => '日期无效';

  @override
  String get almostDone => '快完成了！';

  @override
  String get addPhotoLocationForMatches => '添加照片和位置以获得更多匹配';

  @override
  String get addProfilePhoto => '添加头像';

  @override
  String get optionalUpTo6Photos => '可选 — 最多6张照片';

  @override
  String get requiredUpTo6Photos => '必填 — 最多6张';

  @override
  String get profilePhotoRequired => '请至少添加一张个人头像';

  @override
  String get locationOptional => '请设置您的位置以继续';

  @override
  String get maximum6Photos => '最多6张照片';

  @override
  String get tapToDetectLocation => '点击检测位置';

  @override
  String get optionalHelpsNearbyPartners => '必填 — 帮助匹配附近的伙伴';

  @override
  String get startLearning => '开始学习！';

  @override
  String get photoLocationOptional => '照片和位置是可选的 — 稍后可以添加';

  @override
  String get pleaseAcceptTerms => '请接受服务条款';

  @override
  String get iAgreeToThe => '我同意';

  @override
  String get termsOfService => '服务条款';

  @override
  String get tapToSelectLanguage => '点击选择语言';

  @override
  String yourLevelIn(String language) {
    return '你的$language水平（可选）';
  }

  @override
  String get yourCurrentLevel => '你的当前水平';

  @override
  String get nativeCannotBeSameAsLearning => '母语不能与学习语言相同';

  @override
  String get learningCannotBeSameAsNative => '学习语言不能与母语相同';

  @override
  String stepOf(String current, String total) {
    return '第$current步，共$total步';
  }

  @override
  String get continueWithGoogle => '使用Google继续';

  @override
  String get registerLink => '注册';

  @override
  String get pleaseEnterBothEmailAndPassword => '请输入邮箱和密码';

  @override
  String get pleaseEnterValidEmail => '请输入有效的邮箱地址';

  @override
  String get loginSuccessful => '登录成功！';

  @override
  String get stepOneOfTwo => '第1步，共2步';

  @override
  String get createYourAccount => '创建账号';

  @override
  String get basicInfoToGetStarted => '开始前的基本信息';

  @override
  String get emailVerifiedLabel => '邮箱（已验证）';

  @override
  String get nameLabel => '姓名';

  @override
  String get yourDisplayName => '显示名称';

  @override
  String get atLeast8Characters => '至少8个字符';

  @override
  String get confirmPasswordHint => '再次输入新密码';

  @override
  String get nextButton => '下一步';

  @override
  String get pleaseEnterYourName => '请输入你的姓名';

  @override
  String get pleaseEnterAPassword => '请输入密码';

  @override
  String get passwordsDoNotMatch => '密码不匹配';

  @override
  String get otherGender => '其他';

  @override
  String get continueWithGoogleAccount => '使用Google账号继续\n享受无缝体验';

  @override
  String get signingYouIn => '正在登录...';

  @override
  String get backToSignInMethods => '返回登录方式';

  @override
  String get securedByGoogle => '由Google保障安全';

  @override
  String get dataProtectedEncryption => '你的数据受到行业标准加密保护';

  @override
  String get welcomeCompleteProfile => '欢迎！请完善你的个人资料';

  @override
  String welcomeBackName(String name) {
    return '欢迎回来，$name！';
  }

  @override
  String get continueWithAppleId => '使用Apple ID继续\n享受安全体验';

  @override
  String get continueWithApple => '使用Apple继续';

  @override
  String get securedByApple => '由Apple保障安全';

  @override
  String get privacyProtectedApple => 'Apple登录保护你的隐私';

  @override
  String get createAccount => '创建账号';

  @override
  String get enterEmailToGetStarted => '输入邮箱开始';

  @override
  String get continueText => '继续';

  @override
  String get pleaseEnterEmailAddress => '请输入邮箱地址';

  @override
  String get verificationCodeSent => '验证码已发送到你的邮箱！';

  @override
  String get forgotPasswordTitle => '忘记密码';

  @override
  String get resetPasswordTitle => '重置密码';

  @override
  String get enterEmailForResetCode => '输入你的邮箱地址，我们将发送重置密码的验证码';

  @override
  String get sendResetCode => '发送重置码';

  @override
  String get resetCodeSent => '重置码已发送到你的邮箱！';

  @override
  String get rememberYourPassword => '记得密码？';

  @override
  String get verifyCode => '验证码';

  @override
  String get enterResetCode => '输入重置码';

  @override
  String get weSentCodeTo => '我们发送了6位验证码到';

  @override
  String get pleaseEnterAll6Digits => '请输入所有6位数字';

  @override
  String get codeVerifiedCreatePassword => '验证成功！请创建新密码';

  @override
  String get verify => '验证';

  @override
  String get didntReceiveCode => '没有收到验证码？';

  @override
  String get resend => '重新发送';

  @override
  String resendWithTimer(String timer) {
    return '重新发送（$timer秒）';
  }

  @override
  String get resetCodeResent => '重置码已重新发送！';

  @override
  String get verifyEmail => '验证邮箱';

  @override
  String get verifyYourEmail => '验证你的邮箱';

  @override
  String get emailVerifiedSuccessfully => '邮箱验证成功！';

  @override
  String get verificationCodeResent => '验证码已重新发送！';

  @override
  String get createNewPassword => '创建新密码';

  @override
  String get enterNewPasswordBelow => '在下方输入新密码';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmPasswordLabel => '确认密码';

  @override
  String get pleaseFillAllFields => '请填写所有字段';

  @override
  String get passwordResetSuccessful => '密码重置成功！请使用新密码登录';

  @override
  String get privacyTitle => '隐私';

  @override
  String get profileVisibility => '个人资料可见性';

  @override
  String get showCountryRegion => '显示国家/地区';

  @override
  String get showCountryRegionDesc => '在个人资料中显示您的国家';

  @override
  String get showCity => '显示城市';

  @override
  String get showCityDesc => '在个人资料中显示您的城市';

  @override
  String get showAge => '显示年龄';

  @override
  String get showAgeDesc => '在个人资料中显示您的年龄';

  @override
  String get showZodiacSign => '显示星座';

  @override
  String get showZodiacSignDesc => '在个人资料中显示您的星座';

  @override
  String get onlineStatusSection => '在线状态';

  @override
  String get showOnlineStatus => '显示在线状态';

  @override
  String get showOnlineStatusDesc => '让其他人看到您的在线状态';

  @override
  String get otherSettings => '其他设置';

  @override
  String get showGiftingLevel => '显示礼物等级';

  @override
  String get showGiftingLevelDesc => '显示礼物等级徽章';

  @override
  String get birthdayNotifications => '生日通知';

  @override
  String get birthdayNotificationsDesc => '在生日时接收通知';

  @override
  String get personalizedAds => '个性化广告';

  @override
  String get personalizedAdsDesc => '允许个性化广告';

  @override
  String get saveChanges => '保存更改';

  @override
  String get privacySettingsSaved => '隐私设置已保存';

  @override
  String get locationSection => '位置';

  @override
  String get updateLocation => '更新位置';

  @override
  String get updateLocationDesc => '刷新您的当前位置';

  @override
  String get currentLocation => '当前位置';

  @override
  String get locationNotAvailable => '位置不可用';

  @override
  String get locationUpdated => '位置更新成功';

  @override
  String get locationPermissionDenied => '位置权限被拒绝，请在设置中启用。';

  @override
  String get locationServiceDisabled => '位置服务已禁用，请启用。';

  @override
  String get updatingLocation => '正在更新位置...';

  @override
  String get locationCouldNotBeUpdated => '无法更新位置';

  @override
  String get incomingAudioCall => '来电语音通话';

  @override
  String get incomingVideoCall => '来电视频通话';

  @override
  String get outgoingCall => '呼叫中...';

  @override
  String get callRinging => '响铃中...';

  @override
  String get callConnecting => '连接中...';

  @override
  String get callConnected => '已连接';

  @override
  String get callReconnecting => '重新连接中...';

  @override
  String get callEnded => '通话结束';

  @override
  String get callFailed => '通话失败';

  @override
  String get callMissed => '未接来电';

  @override
  String get callDeclined => '通话已拒绝';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => '接听';

  @override
  String get declineCall => '拒绝';

  @override
  String get endCall => '结束';

  @override
  String get muteCall => '静音';

  @override
  String get unmuteCall => '取消静音';

  @override
  String get speakerOn => '扬声器';

  @override
  String get speakerOff => '听筒';

  @override
  String get videoOn => '开启视频';

  @override
  String get videoOff => '关闭视频';

  @override
  String get switchCamera => '切换摄像头';

  @override
  String get callPermissionDenied => '通话需要麦克风权限';

  @override
  String get cameraPermissionDenied => '视频通话需要摄像头权限';

  @override
  String get callConnectionFailed => '无法连接。请重试。';

  @override
  String get userBusy => '用户忙碌';

  @override
  String get userOffline => '用户离线';

  @override
  String get callHistory => '通话记录';

  @override
  String get noCallHistory => '没有通话记录';

  @override
  String get missedCalls => '未接来电';

  @override
  String get allCalls => '所有通话';

  @override
  String get callBack => '回拨';

  @override
  String callAt(String time) {
    return '$time的通话';
  }

  @override
  String get audioCall => '语音通话';

  @override
  String get voiceRoom => '语音房间';

  @override
  String get noVoiceRooms => '没有活跃的语音房间';

  @override
  String get createVoiceRoom => '创建语音房间';

  @override
  String get joinRoom => '加入房间';

  @override
  String get leaveRoomConfirm => '离开房间？';

  @override
  String get leaveRoomMessage => '确定要离开这个房间吗？';

  @override
  String get roomTitle => '房间标题';

  @override
  String get roomTitleHint => '输入房间标题';

  @override
  String get roomTopic => '话题';

  @override
  String get roomLanguage => '语言';

  @override
  String get roomHost => '房主';

  @override
  String roomParticipants(int count) {
    return '$count位参与者';
  }

  @override
  String roomMaxParticipants(int count) {
    return '最多$count位参与者';
  }

  @override
  String get selectTopic => '选择话题';

  @override
  String get raiseHand => '举手';

  @override
  String get lowerHand => '放下手';

  @override
  String get handRaisedNotification => '已举手！房主将看到您的请求。';

  @override
  String get handLoweredNotification => '已放下手';

  @override
  String get muteParticipant => '将参与者静音';

  @override
  String get kickParticipant => '移出房间';

  @override
  String get promoteToCoHost => '设为副房主';

  @override
  String get endRoomConfirm => '结束房间？';

  @override
  String get endRoomMessage => '这将结束所有参与者的房间。';

  @override
  String get roomEnded => '房主已结束房间';

  @override
  String get youWereRemoved => '您已被移出房间';

  @override
  String get roomIsFull => '房间已满';

  @override
  String get roomChat => '房间聊天';

  @override
  String get noMessages => '暂无消息';

  @override
  String get typeMessage => '输入消息...';

  @override
  String get voiceRoomsDescription => '加入实时对话，练习口语';

  @override
  String liveRoomsCount(int count) {
    return '$count个直播';
  }

  @override
  String get noActiveRooms => '没有活跃房间';

  @override
  String get noActiveRoomsDescription => '成为第一个创建语音房间的人，与他人一起练习口语！';

  @override
  String get startRoom => '开始房间';

  @override
  String get createRoom => '创建房间';

  @override
  String get roomCreated => '房间创建成功！';

  @override
  String get failedToCreateRoom => '创建房间失败';

  @override
  String get errorLoadingRooms => '加载房间出错';

  @override
  String get pleaseEnterRoomTitle => '请输入房间标题';

  @override
  String get startLiveConversation => '开始实时对话';

  @override
  String get maxParticipants => '最大参与者';

  @override
  String nPeople(int count) {
    return '$count人';
  }

  @override
  String hostedBy(String name) {
    return '$name 主持';
  }

  @override
  String get liveLabel => '直播中';

  @override
  String get joinLabel => '加入';

  @override
  String get fullLabel => '已满';

  @override
  String get justStarted => '刚刚开始';

  @override
  String get allLanguages => '所有语言';

  @override
  String get allTopics => '所有话题';

  @override
  String get allCategories => '所有类别';

  @override
  String get leaderboard => '排行榜';

  @override
  String get competeWithLearners => '与其他学习者一较高下！';

  @override
  String get xpRankings => '经验值排名';

  @override
  String get streaks => '连续打卡';

  @override
  String get friends => '好友';

  @override
  String get myRanks => '我的排名';

  @override
  String get currentStreak => '当前连续天数';

  @override
  String get longestStreak => '最长连续天数';

  @override
  String get weekly => '每周';

  @override
  String get monthly => '每月';

  @override
  String get yourRank => '你的排名';

  @override
  String outOf(int total) {
    return '共 $total 名';
  }

  @override
  String topPercent(String percent) {
    return '前 $percent%';
  }

  @override
  String get xpRank => '经验值排名';

  @override
  String get streakRank => '连续打卡排名';

  @override
  String get days => '天';

  @override
  String get learningStats => '学习统计';

  @override
  String get totalXp => '总经验值';

  @override
  String get lessonsCompleted => '已完成课程';

  @override
  String get rankings => '排名';

  @override
  String get yourPosition => '你的位置';

  @override
  String get keepLearning => '继续学习，排名更进一步！';

  @override
  String get noRankingsYet => '暂无排名';

  @override
  String get startLearningToAppear => '开始学习，登上排行榜吧！';

  @override
  String get noFriendsYet => '暂无好友';

  @override
  String get addFriendsToCompete => '添加好友，与他们一较高下！';

  @override
  String get failedToLoadLeaderboard => '加载排行榜失败';

  @override
  String get you => '你';

  @override
  String get findPartners => '寻找语伴';

  @override
  String get discoverLanguagePartners => '发现语言伙伴';

  @override
  String get byLanguage => '按语言';

  @override
  String get match => '匹配';

  @override
  String get matchScore => '匹配度';

  @override
  String get noMatchesFound => '未找到匹配';

  @override
  String get noUsersOnline => '暂无在线用户';

  @override
  String get checkBackLater => '请稍后再来查看';

  @override
  String get selectLanguagePrompt => '选择一种语言';

  @override
  String get findPartnersByLanguage => '寻找说这门语言或正在学习这门语言的伙伴';

  @override
  String noPartnersForLanguage(String language) {
    return '暂无 $language 语伴';
  }

  @override
  String get tryAnotherLanguage => '请尝试选择其他语言';

  @override
  String get failedToLoadMatches => '加载匹配结果失败';

  @override
  String get dataAndStorage => '数据与存储';

  @override
  String get manageStorageAndDownloads => '管理存储和下载';

  @override
  String get storageUsage => '存储使用情况';

  @override
  String get totalCacheSize => '总缓存大小';

  @override
  String get imageCache => '图片缓存';

  @override
  String get voiceMessagesCache => '语音消息';

  @override
  String get videoCache => '视频缓存';

  @override
  String get otherCache => '其他缓存';

  @override
  String get autoDownloadMedia => '自动下载媒体';

  @override
  String get currentNetwork => '当前网络';

  @override
  String get images => '图片';

  @override
  String get videos => '视频';

  @override
  String get voiceMessagesShort => '语音消息';

  @override
  String get documentsLabel => '文档';

  @override
  String get wifiOnly => '仅Wi-Fi';

  @override
  String get never => '从不';

  @override
  String get clearAllCache => '清除所有缓存';

  @override
  String get allCache => '所有缓存';

  @override
  String get clearAllCacheConfirmation => '这将清除所有缓存的图片、语音消息、视频和其他文件。应用可能会暂时加载内容较慢。';

  @override
  String clearCacheConfirmationFor(String category) {
    return '清除$category？';
  }

  @override
  String storageToFree(String size) {
    return '将释放$size';
  }

  @override
  String get calculating => '计算中...';

  @override
  String get noDataToShow => '无数据显示';

  @override
  String get profileCompletion => '资料完成度';

  @override
  String get justGettingStarted => '刚开始';

  @override
  String get lookingGood => '很不错！';

  @override
  String get almostThere => '快完成了！';

  @override
  String addMissingFields(String fields, Object field) {
    return '添加: $fields';
  }

  @override
  String get profilePicture => '头像';

  @override
  String get nativeSpeaker => '母语者';

  @override
  String peopleInterestedInTopic(Object count) {
    return '对此话题感兴趣的人';
  }

  @override
  String get beFirstToAddTopic => '成为第一个添加此话题的人！';

  @override
  String get recentMoments => '最近动态';

  @override
  String get seeAll => '查看全部';

  @override
  String get study => '学习';

  @override
  String get followerMoments => '关注者动态';

  @override
  String get whenPeopleYouFollowPost => '当你关注的人发布新动态时';

  @override
  String get noNotificationsYet => '暂无通知';

  @override
  String get whenYouGetNotifications => '收到通知后将在此显示';

  @override
  String get failedToLoadNotifications => '加载通知失败';

  @override
  String get clearAllNotificationsConfirm => '确定要清除所有通知吗？此操作无法撤销。';

  @override
  String get tapToChange => '点击更改';

  @override
  String get noPictureSet => '未设置照片';

  @override
  String get nameAndGender => '姓名与性别';

  @override
  String get languageLevel => '语言水平';

  @override
  String get personalInformation => '个人信息';

  @override
  String get mbti => 'MBTI';

  @override
  String get topicsOfInterest => '兴趣话题';

  @override
  String get levelBeginner => '入门';

  @override
  String get levelElementary => '初级';

  @override
  String get levelIntermediate => '中级';

  @override
  String get levelUpperIntermediate => '中高级';

  @override
  String get levelAdvanced => '高级';

  @override
  String get levelProficient => '精通';

  @override
  String get selectYourLevel => '选择您的水平';

  @override
  String howWellDoYouSpeak(String language) {
    return '您的$language水平如何？';
  }

  @override
  String get theLanguage => '语言';

  @override
  String languageLevelSetTo(String level) {
    return '语言水平已设置为$level';
  }

  @override
  String get failedToUpdate => '更新失败';

  @override
  String get profileUpdatedSuccessfully => '个人资料已成功更新';

  @override
  String get genderRequired => '性别（必填）';

  @override
  String get editHometown => '编辑家乡';

  @override
  String get useCurrentLocation => '使用当前位置';

  @override
  String get detecting => '检测中...';

  @override
  String get getCurrentLocation => '获取当前位置';

  @override
  String get country => '国家';

  @override
  String get city => '城市';

  @override
  String get coordinates => '坐标';

  @override
  String get noLocationDetectedYet => '尚未检测到位置。';

  @override
  String get detected => '已检测';

  @override
  String get savedHometown => '家乡已保存';

  @override
  String get locationServicesDisabled => '位置服务已禁用。请启用它们。';

  @override
  String get locationPermissionPermanentlyDenied => '位置权限已被永久拒绝。';

  @override
  String get unknown => '未知';

  @override
  String get editBio => '编辑简介';

  @override
  String get bioUpdatedSuccessfully => '简介已成功更新';

  @override
  String get tellOthersAboutYourself => '介绍一下自己...';

  @override
  String charactersCount(int count) {
    return '$count/500字符';
  }

  @override
  String get selectYourMbti => '选择您的MBTI';

  @override
  String get myBloodType => '我的血型';

  @override
  String get pleaseSelectABloodType => '请选择血型';

  @override
  String get bloodTypeSavedSuccessfully => '血型保存成功';

  @override
  String get hometownSavedSuccessfully => '家乡保存成功';

  @override
  String get nativeLanguageRequired => '母语（必填）';

  @override
  String get languageToLearnRequired => '学习语言（必填）';

  @override
  String get nativeLanguageCannotBeSame => '母语不能与正在学习的语言相同';

  @override
  String get learningLanguageCannotBeSame => '学习语言不能与母语相同';

  @override
  String get pleaseSelectALanguage => '请选择语言';

  @override
  String get editInterests => '编辑兴趣';

  @override
  String maxTopicsAllowed(int count) {
    return '最多可选择$count个话题';
  }

  @override
  String get topicsUpdatedSuccessfully => '话题已成功更新！';

  @override
  String get failedToUpdateTopics => '更新话题失败';

  @override
  String selectedCount(int count, int max) {
    return '已选择$count/$max';
  }

  @override
  String get profilePictures => '头像';

  @override
  String get addImages => '添加图片';

  @override
  String get selectUpToImages => '最多选择5张图片';

  @override
  String get takeAPhoto => '拍照';

  @override
  String get removeImage => '删除图片';

  @override
  String get removeImageConfirm => '确定要删除这张图片吗？';

  @override
  String get removeAll => '全部删除';

  @override
  String get removeAllSelectedImages => '删除所有选中的图片';

  @override
  String get removeAllSelectedImagesConfirm => '确定要删除所有选中的图片吗？';

  @override
  String get yourProfilePictureWillBeKept => '您现有的头像将被保留';

  @override
  String get removeAllImages => '删除所有图片';

  @override
  String get removeAllImagesConfirm => '确定要删除所有头像吗？';

  @override
  String get currentImages => '当前图片';

  @override
  String get newImages => '新图片';

  @override
  String get addMoreImages => '添加更多图片';

  @override
  String uploadImages(int count) {
    return '上传$count张图片';
  }

  @override
  String get imageRemovedSuccessfully => '图片已成功删除';

  @override
  String get imagesUploadedSuccessfully => '图片已成功上传';

  @override
  String get selectedImagesCleared => '已清除选中的图片';

  @override
  String get extraImagesRemovedSuccessfully => '多余图片已成功删除';

  @override
  String get mustKeepAtLeastOneProfilePicture => '必须保留至少一张头像';

  @override
  String get noProfilePicturesToRemove => '没有可删除的头像';

  @override
  String get authenticationTokenNotFound => '未找到认证令牌';

  @override
  String get saveChangesQuestion => '保存更改？';

  @override
  String youHaveUnuploadedImages(int count) {
    return '您已选择$count张图片但未上传。是否现在上传？';
  }

  @override
  String get discard => '放弃';

  @override
  String get upload => '上传';

  @override
  String maxImagesInfo(int max, int current) {
    return '最多可上传$max张图片。当前: $current/$max\n每次最多上传5张图片。';
  }

  @override
  String canOnlyAddMoreImages(int count, int max) {
    return '只能再添加$count张图片。最多$max张。';
  }

  @override
  String get maxImagesPerUpload => '每次最多只能上传5张图片。只有前5张会被添加。';

  @override
  String canOnlyHaveMaxImages(int max) {
    return '最多只能有$max张图片';
  }

  @override
  String get imageSizeExceedsLimit => '图片大小超过10MB限制';

  @override
  String get unsupportedImageFormat => '不支持的图片格式';

  @override
  String get pleaseSelectAtLeastOneImage => '请至少选择一张图片上传';

  @override
  String get basicInformation => '基本信息';

  @override
  String get languageToLearn => '学习语言';

  @override
  String get hometown => '家乡';

  @override
  String get characters => '字符';

  @override
  String get failedToLoadLanguages => '加载语言失败';

  @override
  String get studyHub => '学习中心';

  @override
  String get dailyLearningJourney => '您的每日学习之旅';

  @override
  String get learnTab => '学习';

  @override
  String get aiTools => 'AI工具';

  @override
  String get streak => '连续学习';

  @override
  String get lessons => '课程';

  @override
  String get words => '单词';

  @override
  String get quickActions => '快速操作';

  @override
  String get review => '复习';

  @override
  String wordsDue(int count) {
    return '$count个单词待复习';
  }

  @override
  String get addWords => '添加单词';

  @override
  String get buildVocabulary => '积累词汇';

  @override
  String get practiceWithAI => 'AI练习';

  @override
  String get aiPracticeDescription => '聊天、测验、语法和发音';

  @override
  String get dailyChallenges => '每日挑战';

  @override
  String get allChallengesCompleted => '所有挑战已完成！';

  @override
  String get continueLearning => '继续学习';

  @override
  String get structuredLearningPath => '系统学习路径';

  @override
  String get vocabulary => '词汇';

  @override
  String get yourWordCollection => '我的单词集';

  @override
  String get achievements => '成就';

  @override
  String get badgesAndMilestones => '徽章和里程碑';

  @override
  String get failedToLoadLearningData => '加载学习数据失败';

  @override
  String get startYourJourney => '开始你的旅程！';

  @override
  String get startJourneyDescription => '完成课程，积累词汇，\n追踪你的进度';

  @override
  String levelN(int level) {
    return '第$level级';
  }

  @override
  String xpEarned(int xp) {
    return '已获得$xp XP';
  }

  @override
  String nextLevel(int level) {
    return '下一级：第$level级';
  }

  @override
  String xpToGo(int xp) {
    return '还需$xp XP';
  }

  @override
  String get aiConversationPartner => 'AI对话伙伴';

  @override
  String get practiceWithAITutor => '与AI导师练习口语';

  @override
  String get startConversation => '开始对话';

  @override
  String get aiFeatures => 'AI功能';

  @override
  String get aiLessons => 'AI课程';

  @override
  String get learnWithAI => 'AI学习';

  @override
  String get grammar => '语法';

  @override
  String get checkWriting => '检查写作';

  @override
  String get pronunciation => '发音';

  @override
  String get improveSpeaking => '提高口语';

  @override
  String get translation => '翻译';

  @override
  String get smartTranslate => '智能翻译';

  @override
  String get aiQuizzes => 'AI测验';

  @override
  String get testKnowledge => '测试知识';

  @override
  String get lessonBuilder => '课程构建器';

  @override
  String get customLessons => '自定义课程';

  @override
  String get yourAIProgress => '我的AI进度';

  @override
  String get quizzes => '测验';

  @override
  String get avgScore => '平均分';

  @override
  String get focusAreas => '重点领域';

  @override
  String accuracyPercent(String accuracy) {
    return '准确率$accuracy%';
  }

  @override
  String get practice => '练习';

  @override
  String get browse => '浏览';

  @override
  String get noRecommendedLessons => '暂无推荐课程';

  @override
  String get noLessonsFound => '未找到课程';

  @override
  String get createCustomLessonDescription => '用AI创建你的专属课程';

  @override
  String get createLessonWithAI => '用AI创建课程';

  @override
  String get allLevels => '所有级别';

  @override
  String get levelA1 => 'A1 入门';

  @override
  String get levelA2 => 'A2 初级';

  @override
  String get levelB1 => 'B1 中级';

  @override
  String get levelB2 => 'B2 中高级';

  @override
  String get levelC1 => 'C1 高级';

  @override
  String get levelC2 => 'C2 精通';

  @override
  String get failedToLoadLessons => '加载课程失败';

  @override
  String get pin => '置顶';

  @override
  String get unpin => '取消置顶';

  @override
  String get editMessage => '编辑消息';

  @override
  String get enterMessage => '输入消息...';

  @override
  String get deleteMessageTitle => '删除消息';

  @override
  String get actionCannotBeUndone => '此操作无法撤销。';

  @override
  String get onlyRemovesFromDevice => '仅从您的设备中删除';

  @override
  String get availableWithinOneHour => '仅1小时内可用';

  @override
  String get available => '可用';

  @override
  String get forwardMessage => '转发消息';

  @override
  String get selectUsersToForward => '选择要转发的用户：';

  @override
  String forwardCount(int count) {
    return '转发 ($count)';
  }

  @override
  String get pinnedMessage => '置顶消息';

  @override
  String get photoMedia => '照片';

  @override
  String get videoMedia => '视频';

  @override
  String get voiceMessageMedia => '语音消息';

  @override
  String get documentMedia => '文档';

  @override
  String get locationMedia => '位置';

  @override
  String get stickerMedia => '贴纸';

  @override
  String get smileys => '笑脸';

  @override
  String get emotions => '表情';

  @override
  String get handGestures => '手势';

  @override
  String get hearts => '爱心';

  @override
  String get tapToSayHi => '点击打个招呼！';

  @override
  String get sendWaveToStart => '发送问候开始聊天';

  @override
  String get documentMustBeUnder50MB => '文档必须小于50MB。';

  @override
  String get editWithin15Minutes => '消息只能在15分钟内编辑';

  @override
  String messageForwardedTo(int count) {
    return '消息已转发给$count位用户';
  }

  @override
  String get failedToLoadUsers => '加载用户失败';

  @override
  String get voice => '语音';

  @override
  String get searchGifs => '搜索GIF...';

  @override
  String get trendingGifs => '热门';

  @override
  String get poweredByGiphy => 'Powered by GIPHY';

  @override
  String get gif => 'GIF';

  @override
  String get noGifsFound => '未找到GIF';

  @override
  String get failedToLoadGifs => '加载GIF失败';

  @override
  String get gifSent => 'GIF';

  @override
  String get filterCommunities => '筛选';

  @override
  String get reset => '重置';

  @override
  String get findYourPerfect => '找到你的完美';

  @override
  String get languagePartner => '语言伙伴';

  @override
  String get learningLanguageLabel => '学习语言';

  @override
  String get ageRange => '年龄范围';

  @override
  String get genderPreference => '性别偏好';

  @override
  String get any => '任意';

  @override
  String get showNewUsersSubtitle => '显示过去6天内加入的用户';

  @override
  String get autoDetectLocation => '自动检测我的位置';

  @override
  String get selectCountry => '选择国家';

  @override
  String get anyCountry => '任意国家';

  @override
  String get loadingLanguages => '正在加载语言...';

  @override
  String minAge(int age) {
    return '最小: $age';
  }

  @override
  String maxAge(int age) {
    return '最大: $age';
  }

  @override
  String get captionRequired => '描述为必填项';

  @override
  String captionTooLong(int maxLength) {
    return '描述不能超过$maxLength个字符';
  }

  @override
  String get maximumImagesReached => '已达到最大图片数量';

  @override
  String maximumImagesReachedDescription(int maxImages) {
    return '每个动态最多可以上传$maxImages张图片。';
  }

  @override
  String maximumImagesAddedPartial(int maxImages, int added) {
    return '最多$maxImages张图片。仅添加了$added张。';
  }

  @override
  String get locationAccessRestricted => '位置访问受限';

  @override
  String get locationPermissionNeeded => '需要位置权限';

  @override
  String get addToYourMoment => '添加到你的动态';

  @override
  String get categoryLabel => '分类';

  @override
  String get languageLabel => '语言';

  @override
  String get scheduleOptional => '定时发布（可选）';

  @override
  String get scheduleForLater => '稍后发布';

  @override
  String get addMore => '添加更多';

  @override
  String get howAreYouFeeling => '你现在感觉如何？';

  @override
  String get pleaseWaitOptimizingVideo => '请稍候，正在优化您的视频';

  @override
  String unsupportedVideoFormat(String formats) {
    return '不支持的格式。请使用：$formats';
  }

  @override
  String get chooseBackground => '选择背景';

  @override
  String likedByXPeople(int count) {
    return '$count人点赞';
  }

  @override
  String xComments(int count) {
    return '$count条评论';
  }

  @override
  String get oneComment => '1条评论';

  @override
  String get addAComment => '添加评论...';

  @override
  String viewXReplies(int count) {
    return '查看$count条回复';
  }

  @override
  String seenByX(int count) {
    return '$count人已看';
  }

  @override
  String xHoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String xMinutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String get repliedToYourStory => '回复了你的故事';

  @override
  String mentionedYouInComment(String name) {
    return '$name在评论中提到了你';
  }

  @override
  String repliedToYourComment(String name) {
    return '$name回复了你的评论';
  }

  @override
  String reactedToYourComment(String name) {
    return '$name对你的评论做出了反应';
  }

  @override
  String get addReaction => '添加反应';

  @override
  String get attachImage => '附加图片';

  @override
  String get pickGif => '选择GIF';

  @override
  String get textStory => '文字';

  @override
  String get typeYourStory => '写下你的故事...';

  @override
  String get selectBackground => '选择背景';

  @override
  String get highlightsTitle => '精选';

  @override
  String get highlightTitle => '精选标题';

  @override
  String get createNewHighlight => '新建';

  @override
  String get selectStories => '选择故事';

  @override
  String get selectCover => '选择封面';

  @override
  String get addText => '添加文字';

  @override
  String get fontStyleLabel => '字体样式';

  @override
  String get textColorLabel => '文字颜色';

  @override
  String get dragToDelete => '拖到此处删除';

  @override
  String get noBlockedUsers => '暂无屏蔽用户';

  @override
  String get usersYouBlockWillAppearHere => '你屏蔽的用户将显示在这里';

  @override
  String unblockConfirm(String name) {
    return '确定要取消屏蔽 $name 吗？';
  }

  @override
  String reasonLabel(String reason) {
    return '原因：$reason';
  }

  @override
  String blockedAgo(String time) {
    return '$time前屏蔽';
  }

  @override
  String errorLoadingBlockedUsers(String error) {
    return '加载屏蔽用户列表出错：$error';
  }

  @override
  String get logoutConfirmMessage => '确定要退出 Bananatalk 登录吗？';

  @override
  String get loggingOut => '正在退出登录…';

  @override
  String get quietHours => '免打扰时段';

  @override
  String get quietHoursEnable => '启用免打扰时段';

  @override
  String get quietHoursSubtitle => '在设定时段内暂停非紧急通知';

  @override
  String get quietHoursStart => '开始时间';

  @override
  String get quietHoursEnd => '结束时间';

  @override
  String get quietHoursAllowUrgent => '允许紧急通知';

  @override
  String get quietHoursAllowUrgentSubtitle => 'VIP 伙伴的通话和消息仍可送达';

  @override
  String get silencedByQuietHours => '已被免打扰时段静音';

  @override
  String get silencedByCap => '已达每日上限并静音';

  @override
  String get momentUpdatedSuccessfully => '动态更新成功';

  @override
  String get failedToDeleteMoment => '删除动态失败';

  @override
  String get failedToUpdateMoment => '更新动态失败';

  @override
  String get mbtiUpdatedSuccessfully => 'MBTI已成功更新';

  @override
  String get pleaseSelectMbti => '请选择一个MBTI类型';

  @override
  String get languageUpdatedSuccessfully => '语言已成功更新';

  @override
  String get bioHintCard => '精彩的个人简介有助于他人更好地了解你。分享你的兴趣爱好、语言或你正在寻找的内容。';

  @override
  String get bioCounterStartWriting => '开始写作...';

  @override
  String get bioCounterABitMore => '再多写一点会更好';

  @override
  String get bioCounterAlmostAtLimit => '快到字数上限了';

  @override
  String get bioCounterTooLong => '太长了';

  @override
  String get bioQuickStarters => '快速开始';

  @override
  String get rhPositive => 'Rh阳性';

  @override
  String get rhNegative => 'Rh阴性';

  @override
  String get rhPositiveDesc => '最常见';

  @override
  String get rhNegativeDesc => '万能献血者 / 稀有';

  @override
  String get yourBloodType => '你的血型';

  @override
  String get noBloodTypeSelected => '未选择血型';

  @override
  String get tapTypeBelow => '点击下方选择血型';

  @override
  String get tapButtonToDetectLocation => '点击下方按钮检测你的当前位置';

  @override
  String currentAddressLabel(String address) {
    return '当前：$address';
  }

  @override
  String get onlyCityCountryShown => '其他人只能看到你的城市和国家，精确坐标保持私密。';

  @override
  String get updateLocationCta => '更新位置';

  @override
  String get enterYourName => '输入你的名字';

  @override
  String get unsavedChanges => '你有未保存的更改';

  @override
  String tapBelowToBrowseLanguages(int count) {
    return '点击下方浏览 $count 种语言';
  }

  @override
  String get changeLanguage => '更改语言';

  @override
  String get browseLanguages => '浏览语言';

  @override
  String get yourLearningLanguageIsPrefix => '你正在学习的语言是';

  @override
  String get yourNativeLanguageIsPrefix => '你的母语是';

  @override
  String get profileCompleteProgress => '已完成';

  @override
  String get drawerPreferences => '偏好设置';

  @override
  String get drawerStorage => '存储';

  @override
  String get drawerReports => '举报';

  @override
  String get drawerSupport => '支持';

  @override
  String get drawerAccount => '账户';

  @override
  String get logoutConfirmBody => '确定要从 Bananatalk 退出登录吗？';

  @override
  String get helpEmailSupport => '邮件支持';

  @override
  String get helpEmailSupportSubtitle => 'support@bananatalk.com';

  @override
  String get helpReportBug => '报告问题';

  @override
  String get helpReportBugSubtitle => '帮助我们改进 Bananatalk';

  @override
  String get helpFaqs => '常见问题';

  @override
  String get helpFaqsSubtitle => '常见问题解答';

  @override
  String get aboutDialogClose => '关闭';

  @override
  String get aboutBananatalkTagline => '与全球语言学习者连接，通过真实对话提升你的技能。';

  @override
  String get aboutCopyright => '© 2024 Bananatalk. 版权所有。';

  @override
  String get logoutFailedPrefix => '退出失败';

  @override
  String get profileVisitorsTitle => '访客';

  @override
  String get visitorStatistics => '访客统计';

  @override
  String get visitorsTotalVisits => '总访问次数';

  @override
  String get visitorsUniqueVisitors => '独立访客';

  @override
  String get visitorsToday => '今日';

  @override
  String get visitorsThisWeek => '本周';

  @override
  String get noVisitorsYet => '暂无访客';

  @override
  String get noVisitorsYetSubtitle => '当有人访问你的主页时，\n他们将显示在这里';

  @override
  String get visitedViaSearch => '通过搜索';

  @override
  String get visitedViaMoments => '通过动态';

  @override
  String get visitedViaChat => '通过聊天';

  @override
  String get visitedDirect => '直接访问';

  @override
  String get visitorTrackingUnavailable => '访客追踪功能不可用。请更新后端。';

  @override
  String get visitorTrackingNotAvailableYet => '访客追踪功能暂不可用';

  @override
  String get noFollowersYetSubtitle => '开始与他人建立联系吧！';

  @override
  String get partnerButton => '搭档';

  @override
  String get notFollowingAnyoneYetSubtitle => '关注他人以查看他们的动态！';

  @override
  String get unfollowButton => '取消关注';

  @override
  String get profileThemeTitle => '主题';

  @override
  String get themeAutoSwitch => '自动切换（跟随系统）';

  @override
  String get themeSystemHint => '开启后，应用将跟随系统主题设置';

  @override
  String get themeLightMode => '浅色模式';

  @override
  String get themeDarkMode => '深色模式';

  @override
  String get myMoments => '我的动态';

  @override
  String get momentListView => '列表视图';

  @override
  String get momentGridView => '网格视图';

  @override
  String get shareLanguageLearningJourney => '分享你的语言学习之旅！';

  @override
  String get deleteHighlightTitle => '删除精选';

  @override
  String deleteHighlightConfirm(String title) {
    return '删除「$title」？内部的故事不会被删除。';
  }

  @override
  String get highlightDeletedSuccess => '精选已删除';

  @override
  String get highlightNewBadge => '新';

  @override
  String get editMoment => '编辑动态';

  @override
  String get momentDescriptionLabel => '描述';

  @override
  String get momentImagesLabel => '图片';

  @override
  String get noImagesYet => '暂无图片';

  @override
  String get momentEnterDescription => '请输入描述';

  @override
  String get momentUpdatedImageFailed => '动态已更新，但图片上传失败';

  @override
  String get updateRequiredTitle => '需要更新';

  @override
  String get updateAvailableTitle => '有新版本';

  @override
  String get updateRequiredBody => '此版本的Bananatalk已不再受支持，请更新后继续使用。';

  @override
  String get updateAvailableBody => 'Bananatalk新版本已发布，包含改进和错误修复。';

  @override
  String get updateNow => '立即更新';

  @override
  String get updateLater => '稍后';

  @override
  String get updateOpenStoreFailed => '无法打开商店，请从App Store或Play Store进行更新。';

  @override
  String get rememberMe => '记住我';

  @override
  String get passwordWeak => '弱';

  @override
  String get passwordFair => '一般';

  @override
  String get passwordStrong => '强';

  @override
  String get passwordVeryStrong => '非常强';

  @override
  String get showPassword => '显示密码';

  @override
  String get hidePassword => '隐藏密码';

  @override
  String stepProgress(int current, int total) {
    return '第 $current / $total 步';
  }

  @override
  String get usernameOptional => '用户名 (可选)';

  @override
  String get usernameAvailable => '可用';

  @override
  String get usernameTaken => '已被使用';

  @override
  String get usernameNotAvailable => '不可用';

  @override
  String get usernameInvalidFormat => '3-20个字符,字母、数字或下划线';

  @override
  String get usernameHint => '@用户名';

  @override
  String get enableBiometricTitle => '下次使用 Face ID 登录?';

  @override
  String get enableBiometricBody => '使用生物识别登录,无需输入密码。';

  @override
  String get enableBiometricCta => '启用';

  @override
  String get biometricSignInPrompt => '请验证身份以登录 Bananatalk';

  @override
  String continueAs(String name) {
    return '以 $name 继续';
  }

  @override
  String get addProfilePhotoTitle => '添加头像';

  @override
  String get addProfilePhotoSkip => '暂时跳过';

  @override
  String get wavesTab => '招手';

  @override
  String get sendWave => '发送招手';

  @override
  String sendWaveTo(String name) {
    return '向$name发送招手';
  }

  @override
  String waveSent(String name) {
    return '已向$name发送招手';
  }

  @override
  String waveCooldown(String name, String time) {
    return '$time后可以再次向$name招手';
  }

  @override
  String get waveCouldntSend => '无法发送招手';

  @override
  String get itsAMatch => '匹配成功！';

  @override
  String itsAMatchSubtitle(String name) {
    return '你和$name互相招手了';
  }

  @override
  String get sendAMessage => '发送消息';

  @override
  String get waveQuickReplyHi => '嗨！';

  @override
  String get waveQuickReplyCool => '你看起来很酷';

  @override
  String get waveQuickReplyHey => '你好啊';

  @override
  String get waveQuickReplyChat => '一起聊吧';

  @override
  String get waveQuickReplyHello => '你好';

  @override
  String waveQuickReplyFromCountry(String country) {
    return '来自$country的问候！';
  }

  @override
  String get waveCustomMessage => '或者写自己的消息…';

  @override
  String get voiceRoomChat => '聊天';

  @override
  String get voiceRoomChatPlaceholder => '发送消息…';

  @override
  String get voiceRoomChatEmpty => '暂无消息 — 打个招呼吧';

  @override
  String get voiceRoomChatSend => '发送';

  @override
  String voiceRoomChatNewBadge(int n) {
    return '$n';
  }

  @override
  String get voiceRoomEnd => '结束房间';

  @override
  String get voiceRoomEndConfirm => '确定结束此房间？';

  @override
  String get voiceRoomEndConfirmBody => '所有人将断开连接。';

  @override
  String get voiceRoomKick => '移出房间';

  @override
  String voiceRoomKickConfirm(String name) {
    return '移出$name？';
  }

  @override
  String get voiceRoomKicked => '已移出';

  @override
  String get voiceRoomYouAreHostNow => '您现在是主持人';

  @override
  String voiceRoomHostChanged(String name) {
    return '$name现在是主持人';
  }

  @override
  String get voiceRoomHostMenuTitle => '房间操作';

  @override
  String get voiceRoomViewProfile => '查看资料';

  @override
  String get voiceRoomReconnecting => '重新连接中…';

  @override
  String get voiceRoomReconnected => '已重新连接';

  @override
  String get voiceRoomEnded => '房间已结束';

  @override
  String get voiceRoomReconnectRetry => '重试';

  @override
  String get mutualInterests => '共同兴趣';

  @override
  String interestsInCommon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count个共同兴趣',
      one: '1个共同兴趣',
      zero: '暂无共同兴趣',
    );
    return '$_temp0';
  }

  @override
  String get interestsInCommonSeeAll => '查看全部';

  @override
  String get interestsInCommonAddCta => '添加话题';

  @override
  String get interestsInCommonAddSubtitle => '在资料中添加话题，寻找共同点';

  @override
  String activeAgo(String time) {
    return '$time前活跃';
  }

  @override
  String get filterOnlineNow => '当前在线';

  @override
  String get filterAge => '年龄';

  @override
  String get filterGender => '性别';

  @override
  String get filterLanguages => '语言';

  @override
  String get filterCountry => '国家';

  @override
  String get filterTopics => '话题';

  @override
  String get filterLevel => '语言水平';

  @override
  String get filterToggles => '其他';

  @override
  String filterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count位伙伴匹配',
      one: '1位伙伴匹配',
      zero: '无匹配伙伴',
    );
    return '$_temp0';
  }

  @override
  String get filterClearAll => '全部清除';

  @override
  String get filterReset => '重置';

  @override
  String get filterApply => '应用';

  @override
  String get filterNewUsers => '仅新用户';

  @override
  String get filterPrioritizeNearby => '优先附近';

  @override
  String get filterSheetTitle => '筛选';

  @override
  String get notificationPreferencesTitle => '通知';

  @override
  String get notificationPreferencesSubtitle => '选择您希望接收的提醒';

  @override
  String get notifPrefChat => '新消息';

  @override
  String get notifPrefWave => '挥手';

  @override
  String get notifPrefVoiceRoomStart => '语音房间邀请';

  @override
  String get notifPrefScheduledRoomReminder => '预约房间提醒';

  @override
  String get notifPrefFollowerMoment => '您关注的人的新动态';

  @override
  String get notifPrefVisitorAlert => '个人资料访客';

  @override
  String get notifPrefMatchAlert => '互相挥手';

  @override
  String get notifResetToDefaults => '恢复默认设置';

  @override
  String get themeMode => '主题';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get languageSettingsRow => '语言';

  @override
  String get waveDailySummaryTitle => '有新的挥手等待';

  @override
  String waveDailySummaryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人向您挥手',
      one: '1人向您挥手',
    );
    return '$_temp0';
  }

  @override
  String get filterTopicsTitle => '话题';

  @override
  String get filterTopicsEmpty => '未选择任何话题';

  @override
  String get storiesEmpty => '暂无故事';

  @override
  String get storiesLoadError => '无法加载故事';

  @override
  String get storiesRetry => '重试';

  @override
  String get storiesNoMore => '您已全部看完';

  @override
  String get createTextStoryTab => '文字';

  @override
  String get createImageStoryTab => '照片';

  @override
  String get createVideoStoryTab => '视频';

  @override
  String get enterTextHint => '点击输入';

  @override
  String get pickBackground => '背景';

  @override
  String get pickFontStyle => '字体';

  @override
  String get pickTextColor => '颜色';

  @override
  String get addEmoji => '添加表情';

  @override
  String get chooseFont => '选择字体';

  @override
  String get chooseColor => '选择颜色';

  @override
  String get dragToMove => '拖动移位';

  @override
  String get pinchToScale => '捏合缩放';

  @override
  String get removeFromHighlight => '从精选中移除';

  @override
  String get highlightDeleted => '精选已删除';

  @override
  String get storySaved => '已保存到您的故事';

  @override
  String get storyTooLong => '文字太长';

  @override
  String get storyPostFailed => '无法发布故事';

  @override
  String get fontNormal => '常规';

  @override
  String get fontBold => '粗体';

  @override
  String get fontItalic => '斜体';

  @override
  String get fontHandwriting => '手写体';

  @override
  String get pickDate => '选择日期';

  @override
  String get pickTime => '选择时间';

  @override
  String get upcomingRooms => '即将开始';

  @override
  String inHours(int h, int m) {
    return '$h小时$m分钟后';
  }

  @override
  String inMinutes(int m) {
    return '$m分钟后';
  }

  @override
  String get startsNow => '正在开始';

  @override
  String get iWillBeThere => '我会参加';

  @override
  String get cantMakeIt => '我无法参加';

  @override
  String rsvpCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人报名',
      one: '1人报名',
      zero: '暂无报名',
    );
    return '$_temp0';
  }

  @override
  String roomStartsIn1h(String title) {
    return '$title将在1小时后开始';
  }

  @override
  String roomStartsIn15min(String title) {
    return '$title将在15分钟后开始';
  }

  @override
  String roomStarted(String title) {
    return '$title正在开始';
  }

  @override
  String get cancelRoom => '取消房间';

  @override
  String get muteAll => '全员静音';

  @override
  String get mutedByHost => '主持人已将所有人静音';

  @override
  String get muteAllConfirm => '将房间内所有人静音？';

  @override
  String get categoryCasual => '休闲';

  @override
  String get categoryLanguagePractice => '语言练习';

  @override
  String get categoryTopic => '话题';

  @override
  String get categoryQA => '问答';

  @override
  String get pickCategory => '分类';

  @override
  String get sortRecentlyActive => '最近活跃';

  @override
  String visitedYourProfile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人访问了您的主页',
      one: '1人访问了您的主页',
    );
    return '$_temp0';
  }

  @override
  String get noRecentVisitors => '暂无近期访客';

  @override
  String get viewArchive => '查看归档';

  @override
  String get archivedWaves => '已归档的Wave';

  @override
  String get noArchivedWaves => '暂无已归档的Wave';

  @override
  String get mutualInterestsMin => '共同兴趣（最少）';

  @override
  String atLeastNTopics(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '至少$n个共同话题',
      one: '至少1个共同话题',
      zero: '不限',
    );
    return '$_temp0';
  }

  @override
  String get starterAskMoment => '询问他们最近的难忘时刻';

  @override
  String get starterSayHi => '用他们的语言打招呼';

  @override
  String get starterCurious => '他们好奇什么？';

  @override
  String starterFromCountry(String country) {
    return '来自$country的你好！';
  }

  @override
  String starterPracticeLang(String language) {
    return '帮助他们练习$language！';
  }

  @override
  String get momentsLoadError => '无法加载动态';

  @override
  String get momentsRetry => '重试';

  @override
  String get recentTags => '最近的标签';

  @override
  String get noRecentTags => '还没有最近使用的标签';

  @override
  String get hideMomentsFromUser => '隐藏此用户的动态';

  @override
  String get momentsHidden => '此用户的动态将被隐藏';

  @override
  String get unhideMoments => '显示此用户的动态';

  @override
  String momentsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已隐藏 $count 位用户',
      one: '已隐藏 1 位用户',
      zero: '没有隐藏的用户',
    );
    return '$_temp0';
  }

  @override
  String get momentSaveFailed => '无法保存动态';

  @override
  String get tagAlreadyAdded => '标签已添加';

  @override
  String get tagLimitReached => '已达到最大标签数';

  @override
  String get hideThisUser => '隐藏此用户的帖子';

  @override
  String get transcribeMessage => '转写';

  @override
  String get transcribing => '转写中…';

  @override
  String get transcriptionFailed => '无法转写消息';

  @override
  String saveToVocabulary(String word) {
    return '将\'$word\'保存到词汇表';
  }

  @override
  String get addedToVocabulary => '已添加到您的词汇表';

  @override
  String get alreadyInVocabulary => '已在您的词汇表中';

  @override
  String get tapWordToSave => '长按单词以保存';

  @override
  String get autoTranslateChatHint => '传入的消息将自动翻译';

  @override
  String get noConversationsYet => '还没有对话';

  @override
  String get chatRetry => '重试';

  @override
  String get learningHubTitle => '学习';

  @override
  String get learningCommonRetry => '重试';

  @override
  String get learningCommonContinue => '继续';

  @override
  String get learningCommonAwesome => '太棒了！';

  @override
  String get learningErrorGeneric => '出了点问题';

  @override
  String get learningStreakCurrent => '当前连击';

  @override
  String get learningStreakLongest => '最长连击';

  @override
  String learningStreakDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count天',
    );
    return '$_temp0';
  }

  @override
  String learningStreakFreezeAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count个冻结可用',
      zero: '没有可用的冻结',
    );
    return '$_temp0';
  }

  @override
  String get learningStreakFreezeUse => '使用冻结';

  @override
  String get learningStreakFreezeDescription => '冻结在你缺席一天时保护你的连击。';

  @override
  String get learningStreakFreezeProtected => '连击已保护！';

  @override
  String get learningStreakMilestone7 => '7天连击！';

  @override
  String get learningStreakMilestone30 => '30天连击！';

  @override
  String get learningStreakMilestone100 => '100天连击！';

  @override
  String get learningStreakMilestone365 => '365天连击！';

  @override
  String get learningWeeklyDigestTitle => '本周';

  @override
  String learningWeeklyDigestXp(int xp) {
    return '获得 $xp XP';
  }

  @override
  String learningWeeklyDigestLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count节课',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestVocab(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '学习了$count个词',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestDaysActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count天活跃',
    );
    return '$_temp0';
  }

  @override
  String get learningWeeklyDigestTopAchievement => '最佳成就';

  @override
  String learningWeeklyDigestTrendUp(int pct) {
    return '比上周增加$pct%';
  }

  @override
  String learningWeeklyDigestTrendDown(int pct) {
    return '比上周减少$pct%';
  }

  @override
  String get learningWeeklyDigestTrendFlat => '与上周相同';

  @override
  String get learningSrsDashboardTitle => '每日复习';

  @override
  String learningSrsDueToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今天$count张卡片',
      zero: '今天没有卡片',
    );
    return '$_temp0';
  }

  @override
  String learningSrsDueTomorrow(int count) {
    return '明天$count张';
  }

  @override
  String learningSrsDueThisWeek(int count) {
    return '本周$count张';
  }

  @override
  String get learningSrsStartReview => '开始复习';

  @override
  String get learningSrsAllCaughtUp => '你已全部完成！';

  @override
  String get learningSrsKeepGoing => '继续加油';

  @override
  String get learningLeaderboardXpTab => 'XP';

  @override
  String get learningLeaderboardStreakTab => '连击';

  @override
  String get learningLeaderboardLanguageTab => '语言';

  @override
  String get learningLeaderboardFriendsTab => '好友';

  @override
  String get learningLeaderboardEmpty => '暂无排名';

  @override
  String get learningLeaderboardYouLabel => '你';

  @override
  String get learningLeaderboardFriendBadge => '好友';

  @override
  String get learningEmptyVocab => '添加你想记住的单词';

  @override
  String get learningEmptyLessons => '暂无课程';

  @override
  String get learningEmptyQuizzes => '暂无测验';

  @override
  String get learningEmptyChallenges => '明天再来查看';

  @override
  String get learningEmptyAchievements => '获得你的第一个成就';

  @override
  String get learningEmptySearchResults => '未找到结果';

  @override
  String learningXpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String get learningLevelUp => '升级了！';

  @override
  String learningLevelReached(String level) {
    return '你达到了 $level';
  }

  @override
  String get learningAchievementUnlocked => '成就解锁';

  @override
  String get learningVocabularySearchHint => '搜索词汇';

  @override
  String get learningVocabularyFilterAll => '全部';

  @override
  String get learningVocabularyFilterNew => '新词';

  @override
  String get learningVocabularyFilterLearning => '学习中';

  @override
  String get learningVocabularyFilterMastered => '已掌握';

  @override
  String get learningVocabularySortRecent => '最近';

  @override
  String get learningVocabularySortAlphabetical => '按字母';

  @override
  String get learningVocabularySortMastery => '掌握程度';

  @override
  String get learningVocabularyMasteryNew => '新词';

  @override
  String get learningVocabularyMasteryLearning => '学习中';

  @override
  String get learningVocabularyMasteryMastered => '已掌握';

  @override
  String get learningProgressLevelLabel => '等级';

  @override
  String learningProgressXpToNextLevel(int xp) {
    return '距下一等级还需 $xp XP';
  }

  @override
  String get learningProgressWeeklyChartTitle => '最近7天';

  @override
  String get aiTutorPronounceLoading => '为你挑选一个句子…';

  @override
  String get aiTutorPronounceTapToRecord => '点按录音';

  @override
  String get aiTutorPronounceTapToStop => '点按停止';

  @override
  String get aiTutorPronounceTranscribing => '正在听你…';

  @override
  String get aiTutorPronounceTryAgain => '再试一次';

  @override
  String get aiTutorPronounceNext => '下一个';

  @override
  String get aiTutorPronounceUseYourOwn => '用我自己的 ✏️';

  @override
  String get aiTutorPronounceCustomHint => '输入想练习的句子';

  @override
  String get aiTutorPronounceCustomCancel => '取消';

  @override
  String get aiTutorPronounceCustomUse => '使用';

  @override
  String get aiTutorPronounceQuitConfirm => '退出练习？进度不会保存。';

  @override
  String get aiTutorPronounceQuitYes => '是';

  @override
  String get aiTutorPronounceQuitNo => '否';

  @override
  String aiTutorPronounceSentenceOf(int current, int total) {
    return '第 $current 句 / 共 $total 句';
  }

  @override
  String get aiTutorPronounceSummaryTitle => '练习完成';

  @override
  String get aiTutorPronounceSummaryAvg => '平均分';

  @override
  String get aiTutorPronounceSummaryWeak => '需练习的词';

  @override
  String get aiTutorPronounceSaveClose => '保存并关闭';

  @override
  String get aiTutorPronounceSaving => '保存中…';

  @override
  String get aiTutorChipPronounce => '发音';

  @override
  String aiTutorPlanPronunciation(int count, int completed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '发音练习 ($completed/$count)',
      one: '发音练习 ($completed/1)',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorPronounceStartHeadline => '你想怎么练习？';

  @override
  String get aiTutorPronounceStartSubhead => '选一个开始 5 句练习。';

  @override
  String get aiTutorPronounceStartAITitle => 'AI 生成句子';

  @override
  String get aiTutorPronounceStartAISubtitle => '按等级调整，针对你的难词';

  @override
  String get aiTutorPronounceStartCustomTitle => '用自己的句子';

  @override
  String get aiTutorPronounceStartCustomSubtitle => '输入或粘贴你想掌握的句子';

  @override
  String aiTutorQuotaRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今日还剩 $count 次',
      one: '今日还剩 1 次',
    );
    return '$_temp0';
  }

  @override
  String get submit => '提交';

  @override
  String get exit => '退出';

  @override
  String get previous => '上一个';

  @override
  String get aiDailyPracticeTitle => '每日练习';

  @override
  String get aiDailyPracticeTranslateThis => '翻译以下内容:';

  @override
  String get aiDailyPracticeSuggested => '建议:';

  @override
  String get aiDailyPracticeHint => '你的翻译';

  @override
  String get aiLanguagesLoading => '语言仍在加载...';

  @override
  String get aiCopiedToClipboard => '已复制到剪贴板';

  @override
  String get aiGrammarHint => '输入要分析的文本...';

  @override
  String get aiGrammarSectionOriginal => '原文';

  @override
  String get aiGrammarSectionCorrected => '修正后的文本';

  @override
  String aiGrammarSectionIssues(int count) {
    return '发现的问题 ($count)';
  }

  @override
  String get aiGrammarSectionWell => '你做得好的';

  @override
  String get aiGrammarSectionSuggestions => '建议';

  @override
  String get aiGrammarSectionSummary => '摘要';

  @override
  String get aiLessonBuilderLabelLanguage => '语言';

  @override
  String get aiLessonBuilderLabelLevel => '等级';

  @override
  String get aiLessonBuilderTopicHint => '输入主题（例如 \"美食与餐厅\"）';

  @override
  String aiLessonBuilderSaved(String title) {
    return '课程 \"$title\" 已保存！';
  }

  @override
  String get aiLessonBuilderBackToLessons => '返回课程';

  @override
  String get aiTranslationHint => '输入要翻译的文本...';

  @override
  String get aiTranslationSavedToVocab => '已保存到你的词汇表';

  @override
  String aiTranslationCouldNotSave(String error) {
    return '无法保存: $error';
  }

  @override
  String get aiQuizTitle => '小测验';

  @override
  String get aiQuizFailedToGenerate => '生成测验失败';

  @override
  String get aiQuizSubmitTitle => '提交测验？';

  @override
  String get aiQuizSubmitBody => '确定要提交你的答案吗？';

  @override
  String get aiQuizExitTitle => '退出测验？';

  @override
  String get aiQuizExitBody => '你的进度将丢失。';

  @override
  String get aiQuizAnswerHint => '输入你的答案...';

  @override
  String get aiQuizTranslationHint => '输入你的翻译...';

  @override
  String get aiPronunciationPlayingAudio => '正在播放音频...';

  @override
  String get aiPronunciationListenFirst => '先听一遍';

  @override
  String get aiPronunciationHint => '输入要练习的文本...';

  @override
  String aiTutorCouldNotLoad(String error) {
    return '无法加载导师: $error';
  }

  @override
  String aiTutorPlanUnavailable(String error) {
    return '计划不可用: $error';
  }

  @override
  String get aiTutorReplay => '重播';

  @override
  String get aiScenariosTitle => '练习情境';

  @override
  String aiScenariosCouldNotLoad(String error) {
    return '无法加载情境: $error';
  }

  @override
  String get aiScenariosNoneAvailable => '暂无情境';

  @override
  String aiScenariosCouldNotStart(String error) {
    return '无法开始: $error';
  }

  @override
  String aiScenariosForYourLevel(String level) {
    return '适合你的等级 ($level)';
  }

  @override
  String get aiScenariosEasier => '更简单 — 热身';

  @override
  String get aiScenariosHarder => '更难 — 挑战';

  @override
  String get aiRoleplayStillStarting => '情境仍在启动 — 稍后再试。';

  @override
  String aiRoleplaySendFailed(String error) {
    return '发送失败: $error';
  }

  @override
  String get aiRoleplayCouldNotGrade => '这次无法评分 — 下次再试。';

  @override
  String get aiConversationHistoryCompleted => '已完成';

  @override
  String get aiConversationHistoryInProgress => '进行中';

  @override
  String get aiConversationMessageHint => '输入消息...';

  @override
  String get aiConversationTopicSpeak => '我说';

  @override
  String get aiConversationTopicPractice => '练习';

  @override
  String aiToolsVipUpgradeDescription(String feature) {
    return '升级到 VIP 解锁 $feature！';
  }

  @override
  String get aiToolsVipBadge => 'VIP';

  @override
  String aiScenariosBannerPracticingIn(String language) {
    return '正在用$language练习';
  }

  @override
  String get aiScenariosBannerSubhead => '选择符合你等级的情境，或挑战高一级。';

  @override
  String get chatListSearchHint => '搜索或输入 @用户名';

  @override
  String get chatListFilterAll => '全部';

  @override
  String get chatListFilterUnread => '未读';

  @override
  String get chatListFilterOnline => '在线';

  @override
  String get chatListNewChat => '新建聊天';

  @override
  String get chatListNewChatByUsernameTooltip => '通过用户名发起聊天';

  @override
  String get chatListFindUser => '查找用户';

  @override
  String chatListFindUserSearchTerm(String term) {
    return '查找 @$term';
  }

  @override
  String get chatListDeleteConversation => '删除会话';

  @override
  String chatListMediaTitle(String name) {
    return '与 $name 的媒体';
  }

  @override
  String get chatListMediaError => '媒体加载错误';

  @override
  String get chatDetailViewFullProfile => '查看完整资料';

  @override
  String get chatMessageReply => '回复';

  @override
  String get chatMessageCopy => '复制';

  @override
  String get chatMessageCorrect => '纠正';

  @override
  String get chatMessageTranslate => '翻译';

  @override
  String get chatMessageSavePhrase => '保存短语';

  @override
  String get chatMessageEdit => '编辑';

  @override
  String get chatMessageDelete => '删除';

  @override
  String get chatMessageRetrySubtitle => '再次尝试发送';

  @override
  String get chatMessageRemoveSubtitle => '移除该消息';

  @override
  String get chatWallpaperPreviewHello => '你好！👋';

  @override
  String get chatWallpaperPreviewHow => '最近怎样？';

  @override
  String get chatGifSearchHint => '搜索 GIF...';

  @override
  String get communitySearchHint => '搜索或输入 @用户名';

  @override
  String communityUserNotFound(String name) {
    return '找不到用户 @$name';
  }

  @override
  String get communityTabAll => '全部';

  @override
  String get communityTabGender => '性别';

  @override
  String get communityTabCity => '城市';

  @override
  String get communityRefresh => '刷新';

  @override
  String get communityNoUsersFound => '未找到用户';

  @override
  String communityUnblockConfirm(String name) {
    return '确定要取消屏蔽 $name 吗？';
  }

  @override
  String get communityUsernameCopied => '用户名已复制！';

  @override
  String communityLocationDetected(String country) {
    return '位置: $country';
  }

  @override
  String get communityWaveLater => '稍后';

  @override
  String get communityAboutMBTI => 'MBTI';

  @override
  String get voiceRoomReactTooltip => '反应';

  @override
  String get momentsCancel => '取消';

  @override
  String get momentsNotNow => '现在不';

  @override
  String get commonOK => '确定';

  @override
  String commonError(String error) {
    return '错误: $error';
  }

  @override
  String get chatActiveJustNow => '刚刚活跃';

  @override
  String chatActiveMinAgo(int min) {
    return '$min 分钟前活跃';
  }

  @override
  String get chatActiveHourAgo => '1 小时前活跃';

  @override
  String chatActiveHoursAgo(int hours) {
    return '$hours 小时前活跃';
  }

  @override
  String get chatActiveYesterday => '昨天活跃';

  @override
  String chatActiveDaysAgo(int days) {
    return '$days 天前活跃';
  }

  @override
  String get chatSayHiPrompt => '打个招呼，开始聊吧！';

  @override
  String get communityConversationStartersTitle => '破冰话题';

  @override
  String communityConversationStartersTopic(String topic) {
    return '你们都喜欢 $topic — 问问他/她最喜欢的！';
  }

  @override
  String get communityConversationStartersDefault => '打个招呼，介绍一下自己！';

  @override
  String get communityConversationChatAction => '聊天';

  @override
  String get communityConversationMessageCopied => '消息已复制！粘贴即可发送。';

  @override
  String get communityConversationCopiedToast => '已复制！';

  @override
  String get communityLanguageMatchTitle => '语言匹配';

  @override
  String get communityLanguageMatchNative => '母语';

  @override
  String get communityLanguageMatchLearning => '在学';

  @override
  String get communityLanguageMatchPerfect => '完美的语言交换匹配！';

  @override
  String get communityLanguageMatchSameNative => '你们的母语相同';

  @override
  String get momentsFilterApply => '应用';

  @override
  String get momentsCreateAddTo => '添加到你的瞬间';

  @override
  String get momentsCreateCategory => '分类';

  @override
  String get momentsCreateLanguage => '语言';

  @override
  String get momentsCreateSchedule => '定时（可选）';

  @override
  String get momentsCreateScheduleForLater => '稍后发布';

  @override
  String get momentsPrivacyPublic => '公开';

  @override
  String get momentsPrivacyFriends => '朋友';

  @override
  String get momentsPrivacyPrivate => '私密';

  @override
  String get splashTagline => '学习 · 聊天 · 相识';

  @override
  String get splashLoading => '加载中…';

  @override
  String get supportSheetGreeting => '你好，我是 Firdavs 👋';

  @override
  String get supportSheetStory => 'Bananatalk 完全由我一个人开发——每一个页面、每一个功能、每一个深夜的漏洞修复。我的目标是帮助全球语言学习者相互连接和成长，我也在不断添加新功能来实现这一目标。\n\n如果 Bananatalk 对你有所帮助，哪怕是一杯小小的咖啡，也能让我保持动力继续开发。对于一个独立开发者来说，每一份支持都意义重大。 🙏';

  @override
  String get supportSheetDonateButton => '通过 PayPal 捐款';

  @override
  String get supportSheetWatchAd => '观看广告以支持';

  @override
  String get occupation => '职业';

  @override
  String get school => '学校';

  @override
  String get occupationSearchHint => '搜索职业';

  @override
  String get occupationSelectedLabel => '已选择';

  @override
  String get occupationCustomLabel => '自定义';

  @override
  String get occupationNoMatches => '列表中没有匹配项';

  @override
  String get occupationCatTech => '科技与软件';

  @override
  String get occupationCatHealthcare => '医疗与健康';

  @override
  String get occupationCatEducation => '教育与学术';

  @override
  String get occupationCatBusiness => '商业与金融';

  @override
  String get occupationCatCreative => '创意与设计';

  @override
  String get occupationCatMedia => '媒体与传播';

  @override
  String get occupationCatEngineering => '工程';

  @override
  String get occupationCatScience => '科学与研究';

  @override
  String get occupationCatLegal => '法律';

  @override
  String get occupationCatHospitality => '酒店与餐饮';

  @override
  String get occupationCatTrades => '技术工种';

  @override
  String get occupationCatTransport => '运输与物流';

  @override
  String get occupationCatGovernment => '政府与公共服务';

  @override
  String get occupationCatRetail => '零售与客服';

  @override
  String get occupationCatAgriculture => '农业与环境';

  @override
  String get occupationCatSports => '体育与健身';

  @override
  String get occupationCatBeauty => '美容与个人护理';

  @override
  String get occupationCatRealEstate => '房地产与建筑';

  @override
  String get occupationCatReligion => '宗教与灵修';

  @override
  String get occupationCatStudent => '学生';

  @override
  String get occupationCatOther => '其他';

  @override
  String get schoolHint => '例：北京大学、林肯高中';

  @override
  String get birthdate => '生日';

  @override
  String get birthdateSelectHelp => '请选择您的生日';

  @override
  String get birthdateSelectPlaceholder => '选择日期';

  @override
  String birthdateMinAgeError(int age) {
    return '您必须至少$age岁。';
  }

  @override
  String birthdateQuotaRemaining(int remaining, int max) {
    return '未来60天内还可以更改生日 $remaining/$max 次。';
  }

  @override
  String birthdateQuotaLocked(int max) {
    return '您已用完本60天周期内的全部$max次生日修改。';
  }

  @override
  String birthdateNextChangeOn(String date) {
    return '下次可修改时间：$date';
  }

  @override
  String get birthdateRateLimited => '生日在60天内最多只能修改3次。';

  @override
  String birthdateRateLimitedUntil(String date) {
    return '生日在60天内最多只能修改3次。请在$date重试。';
  }

  @override
  String get changePassword => '修改密码';

  @override
  String get currentPassword => '当前密码';

  @override
  String get newPasswordLabel => '新密码';

  @override
  String get confirmNewPassword => '确认新密码';

  @override
  String get currentPasswordHint => '输入当前密码';

  @override
  String get newPasswordHint => '至少8位，A-Z、a-z、0-9';

  @override
  String get passwordsDontMatch => '两次密码不一致。';

  @override
  String get newPasswordSameAsCurrent => '新密码必须与当前密码不同。';

  @override
  String get passwordChangedSuccess => '密码修改成功';

  @override
  String get passwordRule8Chars => '至少8个字符';

  @override
  String get passwordRuleLowercase => '一个小写字母';

  @override
  String get passwordRuleUppercase => '一个大写字母';

  @override
  String get passwordRuleNumber => '一个数字';

  @override
  String get settingsAccountSection => '账户';

  @override
  String get changePasswordTileSubtitle => '更新您的账户密码';

  @override
  String get occupationCustomTab => '自定义';

  @override
  String get occupationCustomTabHint => '找不到您的职业？在这里输入。';

  @override
  String get occupationCustomInputHint => '例如：海洋生物学家、配音演员';

  @override
  String get occupationCustomSaveCTA => '将其用作我的职业';

  @override
  String get vipSelectPlan => '选择套餐';

  @override
  String get vipBenefits => '特权';

  @override
  String get vipBestValue => '超值之选';

  @override
  String get vipPlanMonth => '1个月';

  @override
  String get vipPlanThreeMonths => '3个月';

  @override
  String get vipPlanTwelveMonths => '12个月';

  @override
  String get vipOneTime => '一次性';

  @override
  String get vipNonVip => '非VIP';

  @override
  String get vipBenefitDailyTranslations => '每日翻译次数';

  @override
  String get vipBenefitTranslationsLimit => '每天5次';

  @override
  String get vipBenefitUnlimited => '无限制';

  @override
  String get vipBenefitAdvancedFilters => '高级筛选';

  @override
  String get vipBenefitAdFree => '无广告体验';

  @override
  String get vipBenefitVipBadge => '个人主页VIP徽章';

  @override
  String get vipBenefitPrioritySupport => '优先客服';

  @override
  String get vipBrandTitle => 'BananaTalk VIP';

  @override
  String get vipTagline => '通往全球连接的护照 —— 真实的对话，长久的友谊。';

  @override
  String get vipDisclosure => '如未在订阅期结束前24小时取消，订阅将自动续费。费用将记入您的 iTunes 或 Google Play 账户。';

  @override
  String get vipLoginRequired => '请登录后继续';

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
    return '省$pct%';
  }

  @override
  String vipPerMonth(String price) {
    return '$price/月';
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
  String get vipPaymentPlanSummary => '套餐概览';

  @override
  String get vipPaymentSelectMethod => '选择支付方式';

  @override
  String get vipPaymentPurchaseAppStore => '通过 App Store 购买';

  @override
  String get vipPaymentPurchaseGooglePlay => '通过 Google Play 购买';

  @override
  String get vipPaymentSecureAppStore => '您的购买将通过 App Store 安全处理。';

  @override
  String get vipPaymentSecureGooglePlay => '您的购买将通过 Google Play 安全处理。';

  @override
  String get vipPaymentSubscriptionInfo => '订阅信息';

  @override
  String get vipPaymentInfoLabelTitle => '标题';

  @override
  String get vipPaymentInfoLabelLength => '时长';

  @override
  String get vipPaymentInfoLabelPrice => '价格';

  @override
  String get vipPaymentDisclosure => '完成购买即表示您同意我们的使用条款和隐私政策。如未在当前订阅期结束前至少24小时取消，订阅将自动续费。';

  @override
  String get vipSuccessTitle => '欢迎成为VIP！';

  @override
  String get vipSuccessBody => '您的VIP订阅已生效，尽享所有高级功能！';

  @override
  String get vipPendingTitle => '马上就好';

  @override
  String get vipPendingBody => '您的订阅正在处理中 —— 请稍后刷新重试。';

  @override
  String get vipErrorPaymentTitle => '支付错误';

  @override
  String get vipErrorPurchaseTitle => '购买错误';

  @override
  String get vipErrorVerifyTitle => '购买验证失败';

  @override
  String get vipErrorPaymentFailed => '支付失败';

  @override
  String get vipErrorBodyPrefix => '处理您的支付时出现错误：';

  @override
  String get vipErrorPurchaseCanceled => '购买已取消或失败，请重试。';

  @override
  String get vipErrorVerifyServer => '无法在服务器上验证您的购买。请联系客服。';

  @override
  String get vipPlanLengthOneMonth => '1个月';

  @override
  String get vipPlanLengthThreeMonths => '3个月';

  @override
  String get vipPlanLengthOneYear => '1年';

  @override
  String vipPaymentPayPrice(String price) {
    return '支付 $price';
  }

  @override
  String get vipExpired => 'VIP已过期';

  @override
  String get vipMember => 'VIP会员';

  @override
  String get chatPhrasesMostUsed => '常用';

  @override
  String get chatPhrasesTopics => '话题';

  @override
  String get chatPhrasesAddPhrase => '添加短语';

  @override
  String get chatPhrasesChange => '换一批';

  @override
  String get chatPhrasesAddTitle => '添加短语';

  @override
  String get chatPhrasesAddHint => '输入你常用的短语';

  @override
  String get chatPhrasesEmptyMostUsed => '还没有保存的短语。点击 + 添加一条。';

  @override
  String get chatPhrasesDeleteTitle => '删除这条短语？';

  @override
  String get filterVipPromoTitle => '更快找到合拍的伙伴';

  @override
  String get filterVipPromoSubtitle => '开通 VIP，享受优先匹配、高级筛选与无广告聊天。';

  @override
  String get filterVipPromoCta => '开通 VIP';

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
  String get roomsNewRoom => '新建房间';

  @override
  String get roomsCouldNotLoad => '无法加载房间';

  @override
  String get roomsEmptyTitle => '暂无语言房间';

  @override
  String get roomsEmptySubtitle => '请稍后再来查看 —— 中心正在筹备中。';

  @override
  String get roomCreateTitle => '新建主题房间';

  @override
  String get roomCreateSubtitle => '在某种语言下开启一场专注的聊天';

  @override
  String get roomNameLabel => '房间名称';

  @override
  String get roomNameHint => '例如：每日口语练习';

  @override
  String get roomDescriptionLabel => '描述（可选）';

  @override
  String get roomDescriptionHint => '这个房间是关于什么的？';

  @override
  String get roomCreateSubmit => '创建房间';

  @override
  String get roomNameRequired => '请输入房间名称';

  @override
  String get roomCreateError => '无法创建房间，请重试。';

  @override
  String get roomUsEnglish => '美式英语';

  @override
  String get roomUkEnglish => '英式英语';

  @override
  String get roomFailedLoadMessages => '加载消息失败';

  @override
  String get roomReportMessageTitle => '举报消息';

  @override
  String get reportReasonSpam => '垃圾信息';

  @override
  String get reportReasonHarassment => '骚扰或欺凌';

  @override
  String get reportReasonHateSpeech => '仇恨言论';

  @override
  String get reportReasonViolence => '暴力或威胁';

  @override
  String get reportReasonNudity => '裸露或色情内容';

  @override
  String get reportReasonFalseInformation => '虚假信息';

  @override
  String get roomReportSubmitted => '举报已提交';

  @override
  String get roomReportSubmitFailed => '提交举报失败';

  @override
  String get roomLeaveHubTitle => '离开中心？';

  @override
  String roomLeaveHubMessage(String title) {
    return '之后你可以从房间目录中重新加入 $title。';
  }

  @override
  String get roomLeaveHubFailed => '离开中心失败';

  @override
  String get roomJoinRequestSent => '请求已发送 —— 获得批准后会通知你';

  @override
  String get roomJoinRequestFailed => '发送请求失败';

  @override
  String roomRequestsMenuItem(int count) {
    return '请求（$count）';
  }

  @override
  String get roomViewMembers => '查看成员';

  @override
  String get roomLeaveHubMenuItem => '离开中心';

  @override
  String roomMemberOnlineCount(int members, int online) {
    return '$members 位成员 · $online 人在线';
  }

  @override
  String get roomBannedRequestMessage => '你已被移出此房间。发送请求以重新加入 —— 需要房主批准。';

  @override
  String get roomModeratedRequestMessage => '这是一个受管理的房间。发送加入请求以开始聊天。';

  @override
  String get roomRequestPending => '请求待处理';

  @override
  String get roomRequestToJoin => '请求加入';

  @override
  String get roomDailyPromptLabel => '今日话题';

  @override
  String get roomSomeoneFallback => '某人';

  @override
  String get roomRequestsLoadError => '无法加载加入请求';

  @override
  String get roomRequestApproved => '请求已批准';

  @override
  String get roomRequestDenied => '请求已拒绝';

  @override
  String get roomRequestApproveFailed => '批准请求失败';

  @override
  String get roomRequestDenyFailed => '拒绝请求失败';

  @override
  String roomRequestsAppBarTitle(String title) {
    return '$title · 请求';
  }

  @override
  String get roomRequestsEmpty => '没有待处理的请求';

  @override
  String get roomRequestDeny => '拒绝';

  @override
  String get roomRequestApprove => '批准';

  @override
  String get roomMembersLoadError => '无法加载成员';

  @override
  String get roomRemoveBanTitle => '移除并封禁成员？';

  @override
  String get roomRemoveTitle => '移除成员？';

  @override
  String roomRemoveBanConfirm(String name) {
    return '移除并封禁 $name？除非你批准其请求，否则他们将无法重新加入。';
  }

  @override
  String roomRemoveConfirm(String name, String title) {
    return '将 $name 从 $title 中移除？';
  }

  @override
  String get roomRemoveBanButton => '移除并封禁';

  @override
  String get roomRemoveButton => '移除';

  @override
  String get roomMemberRemovedBanned => '成员已被移除并封禁';

  @override
  String get roomMemberRemoved => '成员已被移除';

  @override
  String get roomMemberRemoveFailed => '移除成员失败';

  @override
  String get roomMemberMuted => '成员已被禁言';

  @override
  String get roomMemberUnmuted => '成员已解除禁言';

  @override
  String get roomMemberMuteFailed => '更新禁言状态失败';

  @override
  String roomMembersAppBarTitle(String title) {
    return '$title · 成员';
  }

  @override
  String get roomMembersEmpty => '暂无成员可显示';

  @override
  String get roomMemberMutedLabel => '已禁言';

  @override
  String get roomMemberFallbackName => '成员';

  @override
  String get roomYourHub => '你的中心';

  @override
  String roomOnlineCount(int count) {
    return '$count 人在线';
  }

  @override
  String get roomNotAvailable => '此房间已不可用。';

  @override
  String get roomGoToRooms => '前往房间';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw(): super('zh_TW');

  @override
  String get appName => 'Bananatalk';

  @override
  String get aiStudyPromoTitle => '用 AI 情境練習';

  @override
  String get aiStudyPromoBody => '與 AI 導師角色扮演真實對話，建立開口說話的信心。';

  @override
  String get aiStudyPromoCTA => '試試一個情境';

  @override
  String get aiStudyPromoDismiss => '以後再說';

  @override
  String get login => '登入';

  @override
  String get signUp => '註冊';

  @override
  String get email => '電子郵件';

  @override
  String get password => '密碼';

  @override
  String get forgotPassword => '忘記密碼？';

  @override
  String get or => '或';

  @override
  String get more => '更多';

  @override
  String get signInWithGoogle => '使用 Google 登入';

  @override
  String get signInWithApple => '使用 Apple 登入';

  @override
  String get signInWithFacebook => '使用 Facebook 登入';

  @override
  String get welcome => '歡迎';

  @override
  String get home => '首頁';

  @override
  String get messages => '訊息';

  @override
  String get moments => '動態';

  @override
  String get overview => '概覽';

  @override
  String get profile => '個人檔案';

  @override
  String get settings => '設定';

  @override
  String get logout => '登出';

  @override
  String get language => '語言';

  @override
  String get selectLanguage => '選擇語言';

  @override
  String get autoTranslate => '自動翻譯';

  @override
  String get autoTranslateMessages => '自動翻譯訊息';

  @override
  String get autoTranslateMoments => '自動翻譯動態';

  @override
  String get autoTranslateComments => '自動翻譯留言';

  @override
  String get translate => '翻譯';

  @override
  String get translated => '已翻譯';

  @override
  String get showOriginal => '顯示原文';

  @override
  String get showTranslation => '顯示翻譯';

  @override
  String get translating => '翻譯中...';

  @override
  String get translationFailed => '翻譯失敗';

  @override
  String get noTranslationAvailable => '無可用翻譯';

  @override
  String translatedFrom(String language) {
    return '翻譯自$language';
  }

  @override
  String get save => '儲存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get edit => '編輯';

  @override
  String get share => '分享';

  @override
  String get like => '讚';

  @override
  String get comment => '留言';

  @override
  String get send => '傳送';

  @override
  String get search => '搜尋';

  @override
  String get notifications => '通知';

  @override
  String get followers => '粉絲';

  @override
  String get following => '追蹤中';

  @override
  String get posts => '貼文';

  @override
  String get visitors => '訪客';

  @override
  String get loading => '載入中...';

  @override
  String get error => '錯誤';

  @override
  String get success => '成功';

  @override
  String get tryAgain => '重試';

  @override
  String get networkError => '網路錯誤。請檢查您的連線。';

  @override
  String get somethingWentWrong => '發生錯誤';

  @override
  String get ok => '確定';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get languageSettings => '語言設定';

  @override
  String get deviceLanguage => '裝置語言';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return '您的裝置設定為：$flag $name';
  }

  @override
  String get youCanOverride => '您可以在下方覆蓋裝置語言。';

  @override
  String languageChangedTo(String name) {
    return '語言已變更為$name';
  }

  @override
  String get errorChangingLanguage => '變更語言時發生錯誤';

  @override
  String get autoTranslateSettings => '自動翻譯設定';

  @override
  String get automaticallyTranslateIncomingMessages => '自動翻譯收到的訊息';

  @override
  String get automaticallyTranslateMomentsInFeed => '自動翻譯動態消息中的內容';

  @override
  String get automaticallyTranslateComments => '自動翻譯留言';

  @override
  String get translationServiceBeingConfigured => '翻譯服務正在設定中。請稍後再試。';

  @override
  String get translationUnavailable => '翻譯不可用';

  @override
  String get showLess => '收起';

  @override
  String get showMore => '展開';

  @override
  String get comments => '留言';

  @override
  String get beTheFirstToComment => '成為第一個留言的人。';

  @override
  String get loadMoreComments => '載入更多留言';

  @override
  String get writeAComment => '寫下留言...';

  @override
  String get report => '檢舉';

  @override
  String get reportMoment => '檢舉動態';

  @override
  String get reportUser => '檢舉用戶';

  @override
  String get deleteMoment => '刪除動態？';

  @override
  String get thisActionCannotBeUndone => '此操作無法復原。';

  @override
  String get momentDeleted => '動態已刪除';

  @override
  String get deleteComment => '刪除留言？';

  @override
  String get commentDeleted => '留言已刪除';

  @override
  String get editFeatureComingSoon => '編輯功能即將推出';

  @override
  String get userNotFound => '找不到用戶';

  @override
  String get cannotReportYourOwnComment => '無法檢舉自己的留言';

  @override
  String get profileSettings => '個人檔案設定';

  @override
  String get editYourProfileInformation => '編輯您的個人資料';

  @override
  String get blockedUsers => '已封鎖的用戶';

  @override
  String get manageBlockedUsers => '管理已封鎖的用戶';

  @override
  String get manageNotificationSettings => '管理通知設定';

  @override
  String get privacySecurity => '隱私與安全';

  @override
  String get controlYourPrivacy => '控制您的隱私';

  @override
  String get changeAppLanguage => '變更應用程式語言';

  @override
  String get appearance => '外觀';

  @override
  String get themeAndDisplaySettings => '主題和顯示設定';

  @override
  String get clearCache => '清除快取';

  @override
  String get clearCacheSubtitle => '釋放儲存空間';

  @override
  String get clearCacheDescription => '這將清除所有快取的圖片、影片和音訊檔案。在重新下載媒體內容期間，應用程式可能會暫時載入較慢。';

  @override
  String get clearCacheHint => '如果圖片或音訊無法正常載入，請使用此功能。';

  @override
  String get clearingCache => '正在清除快取...';

  @override
  String get cacheCleared => '快取已成功清除！圖片將重新載入。';

  @override
  String get clearCacheFailed => '清除快取失敗';

  @override
  String get myReports => '我的檢舉';

  @override
  String get viewYourSubmittedReports => '查看您提交的檢舉';

  @override
  String get reportsManagement => '檢舉管理';

  @override
  String get manageAllReportsAdmin => '管理所有檢舉（管理員）';

  @override
  String get legalPrivacy => '法律與隱私';

  @override
  String get termsPrivacySubscriptionInfo => '條款、隱私和訂閱資訊';

  @override
  String get helpCenter => '幫助中心';

  @override
  String get getHelpAndSupport => '獲取幫助和支援';

  @override
  String get aiTutorChangePersona => '更換 AI 導師';

  @override
  String get aiTutorChangePersonaSubtitle => '切換到 Nana、Sensei 或 Riko';

  @override
  String aiTutorHeroTitleSet(String name) {
    return 'AI 導師 · $name';
  }

  @override
  String get aiTutorHeroTitleNew => '認識你的 AI 導師';

  @override
  String get aiTutorHeroSubtitleSet => '點按聊天或查看今天的計畫';

  @override
  String aiTutorHeroSubtitleLast(String summary) {
    return '上次：$summary';
  }

  @override
  String get aiTutorHeroSubtitleNew => '挑選角色 — Nana、Sensei 或 Riko';

  @override
  String get aiTutorChipChat => '聊天';

  @override
  String get aiTutorChipRoleplay => '角色扮演';

  @override
  String get aiTutorChipStory => '故事';

  @override
  String get aiTutorChipPhoto => '照片';

  @override
  String get aiToolsMoreSection => '更多 AI 工具';

  @override
  String get aiConversationPartnerTile => 'AI 對話';

  @override
  String get aiConversationPartnerTileSubtitle => '與 AI 夥伴練習';

  @override
  String get aiTutorPickerTitle => '挑選你的 AI 導師';

  @override
  String get aiTutorPickerHeader => '你想和誰一起學習？';

  @override
  String get aiTutorPickerSubtitle => '你隨時可以在設定中更改。';

  @override
  String get aiTutorPersonaNanaTagline => '溫暖 + 鼓勵';

  @override
  String get aiTutorPersonaNanaSample => '我會為你加油，沒有壓力。';

  @override
  String get aiTutorPersonaSenseiTagline => '精準 + 應試';

  @override
  String get aiTutorPersonaSenseiSample => '我們一起掌握規則。';

  @override
  String get aiTutorPersonaRikoTagline => '俏皮 + 口語化';

  @override
  String get aiTutorPersonaRikoSample => '哈哈一起放鬆學吧';

  @override
  String aiTutorPickerSaveError(String error) {
    return '無法儲存: $error';
  }

  @override
  String get aiTutorHomeTitle => 'AI 導師';

  @override
  String get aiTutorHomeChangeTutor => '更換導師';

  @override
  String get aiTutorHomeGreetingDefault => '嗨！準備好一起學習了嗎？';

  @override
  String get aiTutorHomeTodaysPlan => '今日計劃';

  @override
  String get aiTutorHomePlanEmpty => '今日還沒有計劃 — 開始聊天來啟動吧。';

  @override
  String get aiTutorHomeStartChat => '開始聊天';

  @override
  String get aiTutorHomeRecent => '最近';

  @override
  String get aiTutorHomePracticeScenarios => '練習情境';

  @override
  String get aiTutorHomePracticeScenariosSubtitle => '角色扮演真實對話 — 餐廳、面試、酒店…';

  @override
  String get aiTutorHomeReadStory => '讀一個故事';

  @override
  String get aiTutorHomeReadStorySubtitle => 'AI 用你的詞彙寫一個短故事 — 附帶快速理解問答。';

  @override
  String get aiTutorHomeDescribePhoto => '描述一張照片';

  @override
  String get aiTutorHomeDescribePhotoSubtitle => '拍張照片並描述 — AI 評估詞彙和語法。';

  @override
  String get aiTutorChatTitle => '與導師聊天';

  @override
  String get aiTutorChatVoiceOn => '語音開';

  @override
  String get aiTutorChatVoiceOff => '語音關';

  @override
  String get aiTutorChatStopRecording => '停止錄音';

  @override
  String get aiTutorChatHoldToTalk => '按住說話';

  @override
  String get aiTutorChatTranscribing => '正在轉寫…';

  @override
  String get aiTutorChatListening => '正在聆聽…';

  @override
  String get aiTutorChatInputHint => '輸入訊息…';

  @override
  String get aiTutorChatTypeReplyHint => '輸入你的回覆…';

  @override
  String get aiTutorChatMicPermissionDenied => '語音模式需要麥克風權限。';

  @override
  String get aiTutorChatTranscribeFailed => '沒聽清 — 再試一次。';

  @override
  String aiTutorChatStartFailed(String error) {
    return '啟動失敗: $error';
  }

  @override
  String get aiTutorRoleplayEnd => '結束';

  @override
  String aiTutorRoleplayEndFailed(String error) {
    return '結束失敗: $error';
  }

  @override
  String get aiTutorRoleplayDone => '完成';

  @override
  String get aiTutorStoryTitle => '讀一個故事';

  @override
  String get aiTutorStoryLength => '長度';

  @override
  String get aiTutorStoryTheme => '主題';

  @override
  String aiTutorStoryWordCount(int count) {
    return '$count 個詞';
  }

  @override
  String get aiTutorStoryWriting => '撰寫中…';

  @override
  String get aiTutorStoryGenerate => '生成故事';

  @override
  String aiTutorStoryGenerateFailed(String error) {
    return '無法生成: $error';
  }

  @override
  String aiTutorStoryWordCountHint(int n) {
    return 'AI 會使用你詞彙表中最多 $n 個詞。';
  }

  @override
  String get aiTutorStoryThemeFree => '自由';

  @override
  String get aiTutorStoryThemeAdventure => '冒險';

  @override
  String get aiTutorStoryThemeMystery => '懸疑';

  @override
  String get aiTutorStoryThemeRomance => '愛情';

  @override
  String get aiTutorStoryThemeSciFi => '科幻';

  @override
  String get aiTutorStoryThemeSliceOfLife => '日常';

  @override
  String get aiTutorStoryReaderTitle => '故事';

  @override
  String get aiTutorStoryReaderVocab => '詞彙';

  @override
  String get aiTutorStoryReaderVocabUsed => '使用過的詞';

  @override
  String aiTutorStoryReaderPart(int n) {
    return '第 $n 部分';
  }

  @override
  String get aiTutorStoryReaderWrongHint => '差一點 — 繼續';

  @override
  String get aiTutorStoryReaderNiceWork => '做得好！';

  @override
  String aiTutorStoryReaderScore(int correct, int total) {
    return '你答對了 $correct/$total 道理解題。';
  }

  @override
  String get aiTutorStoryReaderDone => '完成';

  @override
  String get aiTutorImageVocabTitle => '描述照片';

  @override
  String get aiTutorImagePickHeader => '選擇要描述的照片';

  @override
  String get aiTutorImagePickSubtitle => 'AI 會用你的目標語言給出提示，然後評估你的描述。';

  @override
  String get aiTutorImagePickCamera => '相機';

  @override
  String get aiTutorImagePickGallery => '相簿';

  @override
  String aiTutorImagePickError(String error) {
    return '無法開啟圖片: $error';
  }

  @override
  String get aiTutorImageDescriptionHint => '輸入描述…';

  @override
  String get aiTutorImageDifferentPhoto => '換一張';

  @override
  String get aiTutorImageSubmit => '提交';

  @override
  String get aiTutorImageGrammarNotes => '語法筆記';

  @override
  String get aiTutorImageThingsYouMissed => '漏掉的內容';

  @override
  String get aiTutorImageTryAnother => '試試另一張';

  @override
  String get aiTutorCardQuiz => '小測驗';

  @override
  String get aiTutorCardVocab => '詞彙';

  @override
  String get aiTutorCardGrammar => '語法';

  @override
  String get aiTutorCardReviewDue => '複習時間到';

  @override
  String get aiTutorCardMiniLesson => '迷你課';

  @override
  String get aiTutorCardAddToVocab => '新增到詞彙';

  @override
  String get aiTutorCardAddedToVocab => '已新增';

  @override
  String get aiTutorCardAdding => '新增中…';

  @override
  String aiTutorCardReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 張卡在等你',
      one: '$count 張卡在等你',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorCardReviewNow => '立即複習';

  @override
  String get aiTutorCardReviewStarting => '啟動中…';

  @override
  String get aiTutorCardTryIt => '試試';

  @override
  String get aiTutorCardPracticing => '練習中…';

  @override
  String aiTutorPlanSrsReview(int count, int done) {
    return '複習 $count 張 SRS 卡 ($done 完成)';
  }

  @override
  String aiTutorPlanGrammar(String topic) {
    return '練習: $topic';
  }

  @override
  String aiTutorPlanChat(int min, int done) {
    return '聊 $min 分鐘 (目前 $done)';
  }

  @override
  String get aboutBananatalk => '關於 Bananatalk';

  @override
  String get deleteAccount => '刪除帳戶';

  @override
  String get permanentlyDeleteYourAccount => '永久刪除您的帳戶';

  @override
  String get loggedOutSuccessfully => '已成功登出';

  @override
  String get retry => '重試';

  @override
  String get giftsLikes => '禮物/讚';

  @override
  String get details => '詳情';

  @override
  String get to => '至';

  @override
  String get banaTalk => 'Bananatalk';

  @override
  String get chats => '聊天';

  @override
  String get community => '社群';

  @override
  String get editProfile => '編輯個人檔案';

  @override
  String yearsOld(String age) {
    return '$age歲';
  }

  @override
  String get searchConversations => '搜尋對話...';

  @override
  String get visitorTrackingNotAvailable => '訪客追蹤功能尚未推出。需要後端更新。';

  @override
  String get chatList => '聊天列表';

  @override
  String get languageExchange => '語言交換';

  @override
  String get nativeLanguage => '母語';

  @override
  String get learning => '正在學習';

  @override
  String get notSet => '未設定';

  @override
  String get about => '關於';

  @override
  String get aboutMe => '關於我';

  @override
  String get bloodType => '血型';

  @override
  String get photos => '照片';

  @override
  String get camera => '相機';

  @override
  String get createMoment => '建立動態';

  @override
  String get addATitle => '新增標題...';

  @override
  String get whatsOnYourMind => '在想什麼？';

  @override
  String get addTags => '新增標籤';

  @override
  String get done => '完成';

  @override
  String get add => '新增';

  @override
  String get enterTag => '輸入標籤';

  @override
  String get post => '發佈';

  @override
  String get commentAddedSuccessfully => '留言已成功新增';

  @override
  String get clearFilters => '清除篩選';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get enableNotifications => '啟用通知';

  @override
  String get turnAllNotificationsOnOrOff => '開啟或關閉所有通知';

  @override
  String get notificationTypes => '通知類型';

  @override
  String get chatMessages => '聊天訊息';

  @override
  String get getNotifiedWhenYouReceiveMessages => '收到訊息時獲得通知';

  @override
  String get likesAndCommentsOnYourMoments => '您動態上的讚和留言';

  @override
  String get whenPeopleYouFollowPostMoments => '當您追蹤的人發佈動態時';

  @override
  String get friendRequests => '好友邀請';

  @override
  String get whenSomeoneFollowsYou => '當有人追蹤您時';

  @override
  String get profileVisits => '個人檔案瀏覽';

  @override
  String get whenSomeoneViewsYourProfileVIP => '當有人查看您的個人檔案時（VIP）';

  @override
  String get marketing => '行銷';

  @override
  String get updatesAndPromotionalMessages => '更新和促銷訊息';

  @override
  String get notificationPreferences => '通知偏好設定';

  @override
  String get sound => '聲音';

  @override
  String get playNotificationSounds => '播放通知聲音';

  @override
  String get vibration => '震動';

  @override
  String get vibrateOnNotifications => '通知時震動';

  @override
  String get showPreview => '顯示預覽';

  @override
  String get showMessagePreviewInNotifications => '在通知中顯示訊息預覽';

  @override
  String get mutedConversations => '已靜音的對話';

  @override
  String get conversation => '對話';

  @override
  String get unmute => '取消靜音';

  @override
  String get systemNotificationSettings => '系統通知設定';

  @override
  String get manageNotificationsInSystemSettings => '在系統設定中管理通知';

  @override
  String get errorLoadingSettings => '載入設定時發生錯誤';

  @override
  String get unblockUser => '解除封鎖用戶';

  @override
  String get unblock => '解除封鎖';

  @override
  String get goBack => '返回';

  @override
  String get messageSendTimeout => '訊息傳送逾時。請檢查您的連線。';

  @override
  String get failedToSendMessage => '傳送訊息失敗';

  @override
  String get dailyMessageLimitExceeded => '已超過每日訊息限制。升級為 VIP 以獲得無限訊息。';

  @override
  String get cannotSendMessageUserMayBeBlocked => '無法傳送訊息。用戶可能已被封鎖。';

  @override
  String get sessionExpired => '工作階段已過期，請重新登入。';

  @override
  String get sendThisSticker => '傳送此貼圖？';

  @override
  String get chooseHowYouWantToDeleteThisMessage => '選擇您要如何刪除此訊息：';

  @override
  String get deleteForEveryone => '為所有人刪除';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => '為您和收件人移除訊息';

  @override
  String get deleteForMe => '僅為自己刪除';

  @override
  String get removesTheMessageOnlyFromYourChat => '僅從您的聊天中移除訊息';

  @override
  String get copy => '複製';

  @override
  String get reply => '回覆';

  @override
  String get forward => '轉發';

  @override
  String get moreOptions => '更多選項';

  @override
  String get noUsersAvailableToForwardTo => '沒有可轉發的用戶';

  @override
  String get searchMoments => '搜尋動態...';

  @override
  String searchInChatWith(String name) {
    return '在與$name的聊天中搜尋';
  }

  @override
  String get typeAMessage => '輸入訊息...';

  @override
  String get enterYourMessage => '輸入您的訊息';

  @override
  String get detectYourLocation => '偵測您的位置';

  @override
  String get tapToUpdateLocation => '點擊以更新位置';

  @override
  String get helpOthersFindYouNearby => '幫助其他人在附近找到您';

  @override
  String get selectYourNativeLanguage => '選擇您的母語';

  @override
  String get whichLanguageDoYouWantToLearn => '您想學習哪種語言？';

  @override
  String get selectYourGender => '選擇您的性別';

  @override
  String get addACaption => '新增說明...';

  @override
  String get typeSomething => '輸入內容...';

  @override
  String get gallery => '相簿';

  @override
  String get video => '影片';

  @override
  String get text => '文字';

  @override
  String get provideMoreInformation => '提供更多資訊...';

  @override
  String get searchByNameLanguageOrInterests => '按名稱、語言或興趣搜尋...';

  @override
  String get addTagAndPressEnter => '新增標籤並按 Enter';

  @override
  String replyTo(String name) {
    return '回覆$name...';
  }

  @override
  String get highlightName => '精選名稱';

  @override
  String get searchCloseFriends => '搜尋摯友...';

  @override
  String get askAQuestion => '提出問題...';

  @override
  String option(String number) {
    return '選項 $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return '您為什麼要檢舉此$type？';
  }

  @override
  String get additionalDetailsOptional => '其他詳情（選填）';

  @override
  String get warningThisActionIsPermanent => '警告：此操作為永久性！';

  @override
  String get deletingYourAccountWillPermanentlyRemove => '刪除您的帳戶將永久移除：\n\n• 您的個人檔案和所有個人資料\n• 您的所有訊息和對話\n• 您的所有動態和限時動態\n• 您的 VIP 訂閱（不退款）\n• 您的所有連結和粉絲\n\n此操作無法復原。';

  @override
  String get clearAllNotifications => '清除所有通知？';

  @override
  String get clearAll => '全部清除';

  @override
  String get notificationDebug => '通知除錯';

  @override
  String get markAllRead => '全部標為已讀';

  @override
  String get clearAll2 => '全部清除';

  @override
  String get emailAddress => '電子郵件地址';

  @override
  String get username => '用戶名';

  @override
  String get alreadyHaveAnAccount => '已有帳戶？';

  @override
  String get login2 => '登入';

  @override
  String get selectYourNativeLanguage2 => '選擇您的母語';

  @override
  String get whichLanguageDoYouWantToLearn2 => '您想學習哪種語言？';

  @override
  String get selectYourGender2 => '選擇您的性別';

  @override
  String get dateFormat => '年.月.日';

  @override
  String get detectYourLocation2 => '偵測您的位置';

  @override
  String get tapToUpdateLocation2 => '點擊以更新位置';

  @override
  String get helpOthersFindYouNearby2 => '幫助其他人在附近找到您';

  @override
  String get couldNotOpenLink => '無法開啟連結';

  @override
  String get legalPrivacy2 => '法律與隱私';

  @override
  String get termsOfUseEULA => '使用條款 (EULA)';

  @override
  String get viewOurTermsAndConditions => '查看我們的條款和條件';

  @override
  String get privacyPolicy => '隱私政策';

  @override
  String get howWeHandleYourData => '我們如何處理您的資料';

  @override
  String get emailNotifications => '電子郵件通知';

  @override
  String get receiveEmailNotificationsFromBananatalk => '接收來自 Bananatalk 的電子郵件通知';

  @override
  String get weeklySummary => '每週摘要';

  @override
  String get activityRecapEverySunday => '每週日的活動回顧';

  @override
  String get newMessages => '新訊息';

  @override
  String get whenYoureAwayFor24PlusHours => '當您離開超過 24 小時時';

  @override
  String get newFollowers => '新粉絲';

  @override
  String get whenSomeoneFollowsYou2 => '當有人追蹤您時';

  @override
  String get securityAlerts => '安全警報';

  @override
  String get passwordLoginAlerts => '密碼和登入警報';

  @override
  String get unblockUser2 => '解除封鎖用戶';

  @override
  String get blockedUsers2 => '已封鎖的用戶';

  @override
  String get finalWarning => '最後警告';

  @override
  String get deleteForever => '永久刪除';

  @override
  String get deleteAccount2 => '刪除帳戶';

  @override
  String get enterYourPassword => '輸入您的密碼';

  @override
  String get yourPassword => '您的密碼';

  @override
  String get typeDELETEToConfirm => '輸入「刪除」以確認';

  @override
  String get typeDELETEInCapitalLetters => '以大寫輸入「刪除」';

  @override
  String sent(String emoji) {
    return '$emoji 已傳送！';
  }

  @override
  String get replySent => '回覆已傳送！';

  @override
  String get deleteStory => '刪除限時動態？';

  @override
  String get thisStoryWillBeRemovedPermanently => '此限時動態將被永久移除。';

  @override
  String get noStories => '沒有限時動態';

  @override
  String views(String count) {
    return '$count 次觀看';
  }

  @override
  String get reportStory => '檢舉限時動態';

  @override
  String get reply2 => '回覆...';

  @override
  String get failedToPickImage => '選擇圖片失敗';

  @override
  String get failedToTakePhoto => '拍照失敗';

  @override
  String get failedToPickVideo => '選擇影片失敗';

  @override
  String get pleaseEnterSomeText => '請輸入文字';

  @override
  String get pleaseSelectMedia => '請選擇媒體';

  @override
  String get storyPosted => '限時動態已發佈！';

  @override
  String get textOnlyStoriesRequireAnImage => '純文字限時動態需要圖片';

  @override
  String get createStory => '建立限時動態';

  @override
  String get change => '變更';

  @override
  String get userIdNotFound => '找不到用戶 ID。請重新登入。';

  @override
  String get pleaseSelectAPaymentMethod => '請選擇付款方式';

  @override
  String get startExploring => '開始探索';

  @override
  String get close => '關閉';

  @override
  String get payment => '付款';

  @override
  String get upgradeToVIP => '升級為 VIP';

  @override
  String get errorLoadingProducts => '載入產品時發生錯誤';

  @override
  String get cancelVIPSubscription => '取消 VIP 訂閱';

  @override
  String get keepVIP => '保留 VIP';

  @override
  String get cancelSubscription => '取消訂閱';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'VIP 訂閱已成功取消';

  @override
  String get vipStatus => 'VIP 狀態';

  @override
  String get noActiveVIPSubscription => '沒有有效的 VIP 訂閱';

  @override
  String get subscriptionExpired => '訂閱已過期';

  @override
  String get vipExpiredMessage => '您的 VIP 訂閱已過期。立即續訂以繼續享受無限功能！';

  @override
  String get expiredOn => '過期於';

  @override
  String get renewVIP => '續訂 VIP';

  @override
  String get whatYoureMissing => '您錯過了什麼';

  @override
  String get manageInAppStore => '在 App Store 中管理';

  @override
  String get becomeVIP => '成為 VIP';

  @override
  String get unlimitedMessages => '無限訊息';

  @override
  String get unlimitedProfileViews => '無限個人檔案瀏覽';

  @override
  String get prioritySupport => '優先支援';

  @override
  String get advancedSearch => '進階搜尋';

  @override
  String get profileBoost => '個人檔案提升';

  @override
  String get adFreeExperience => '無廣告體驗';

  @override
  String get upgradeYourAccount => '升級您的帳戶';

  @override
  String get moreMessages => '更多訊息';

  @override
  String get moreProfileViews => '更多個人檔案瀏覽';

  @override
  String get connectWithFriends => '與朋友連結';

  @override
  String get reviewStarted => '審查已開始';

  @override
  String get reportResolved => '檢舉已解決';

  @override
  String get reportDismissed => '檢舉已駁回';

  @override
  String get selectAction => '選擇操作';

  @override
  String get noViolation => '無違規';

  @override
  String get contentRemoved => '內容已移除';

  @override
  String get userWarned => '用戶已收到警告';

  @override
  String get userSuspended => '用戶已停權';

  @override
  String get userBanned => '用戶已被封禁';

  @override
  String get addNotesOptional => '新增備註（選填）';

  @override
  String get enterModeratorNotes => '輸入版主備註...';

  @override
  String get skip => '跳過';

  @override
  String get startReview => '開始審查';

  @override
  String get resolve => '解決';

  @override
  String get dismiss => '駁回';

  @override
  String get filterReports => '篩選檢舉';

  @override
  String get all => '全部';

  @override
  String get clear => '清除';

  @override
  String get apply => '套用';

  @override
  String get myReports2 => '我的檢舉';

  @override
  String get blockUser => '封鎖用戶';

  @override
  String get block => '封鎖';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => '您是否也要封鎖此用戶？';

  @override
  String get noThanks => '不用了，謝謝';

  @override
  String get yesBlockThem => '是的，封鎖他們';

  @override
  String get reportUser2 => '檢舉用戶';

  @override
  String get submitReport => '提交檢舉';

  @override
  String get addAQuestionAndAtLeast2Options => '新增問題和至少 2 個選項';

  @override
  String get addOption => '新增選項';

  @override
  String get anonymousVoting => '匿名投票';

  @override
  String get create => '建立';

  @override
  String get typeYourAnswer => '輸入您的答案...';

  @override
  String get send2 => '傳送';

  @override
  String get yourPrompt => '您的提示...';

  @override
  String get add2 => '新增';

  @override
  String get contentNotAvailable => '內容不可用';

  @override
  String get profileNotAvailable => '個人檔案不可用';

  @override
  String get noMomentsToShow => '沒有動態可顯示';

  @override
  String get storiesNotAvailable => '限時動態不可用';

  @override
  String get cantMessageThisUser => '無法傳送訊息給此用戶';

  @override
  String get pleaseSelectAReason => '請選擇原因';

  @override
  String get reportSubmitted => '檢舉已提交。感謝您幫助維護我們社群的安全。';

  @override
  String get youHaveAlreadyReportedThisMoment => '您已檢舉過此動態';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => '告訴我們更多您檢舉此內容的原因';

  @override
  String get errorSharing => '分享時發生錯誤';

  @override
  String get deviceInfo => '裝置資訊';

  @override
  String get recommended => '推薦';

  @override
  String get anyLanguage => '任何語言';

  @override
  String get noLanguagesFound => '找不到語言';

  @override
  String get selectALanguage => '選擇語言';

  @override
  String get languagesAreStillLoading => '語言仍在載入中...';

  @override
  String get selectNativeLanguage => '選擇母語';

  @override
  String get subscriptionDetails => '訂閱詳情';

  @override
  String get activeFeatures => '有效功能';

  @override
  String get legalInformation => '法律資訊';

  @override
  String get termsOfUse => '使用條款';

  @override
  String get manageSubscription => '管理訂閱';

  @override
  String get manageSubscriptionInSettings => '要取消訂閱，請前往裝置上的設定 > [您的名字] > 訂閱。';

  @override
  String get contactSupportToCancel => '要取消訂閱，請聯繫我們的客服團隊。';

  @override
  String get status => '狀態';

  @override
  String get active => '有效';

  @override
  String get plan => '方案';

  @override
  String get startDate => '開始日期';

  @override
  String get endDate => '結束日期';

  @override
  String get nextBillingDate => '下次帳單日期';

  @override
  String get autoRenew => '自動續訂';

  @override
  String get pleaseLogInToContinue => '請登入以繼續';

  @override
  String get purchaseCanceledOrFailed => '購買已取消或失敗。請重試。';

  @override
  String get maximumTagsAllowed => '最多允許 5 個標籤';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => '請先移除圖片以新增影片';

  @override
  String get unsupportedFormat => '不支援的格式';

  @override
  String get errorProcessingVideo => '處理影片時發生錯誤';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => '請先移除圖片以錄製影片';

  @override
  String get locationAdded => '已新增位置';

  @override
  String get failedToGetLocation => '取得位置失敗';

  @override
  String get notNow => '稍後';

  @override
  String get videoUploadFailed => '影片上傳失敗';

  @override
  String get skipVideo => '跳過影片';

  @override
  String get retryUpload => '重試上傳';

  @override
  String get momentCreatedSuccessfully => '動態已成功建立';

  @override
  String get uploadingMomentInBackground => '正在背景上傳動態...';

  @override
  String get failedToQueueUpload => '無法將上傳加入佇列';

  @override
  String get viewProfile => '查看個人檔案';

  @override
  String get mediaLinksAndDocs => '媒體、連結和文件';

  @override
  String get wallpaper => '桌布';

  @override
  String get userIdNotAvailable => '用戶 ID 不可用';

  @override
  String get cannotBlockYourself => '無法封鎖自己';

  @override
  String get chatWallpaper => '聊天桌布';

  @override
  String get wallpaperSavedLocally => '桌布已儲存至本機';

  @override
  String get messageCopied => '訊息已複製';

  @override
  String get forwardFeatureComingSoon => '轉發功能即將推出';

  @override
  String get momentUnsaved => '已從儲存中移除';

  @override
  String get documentPickerComingSoon => '文件選擇器即將推出';

  @override
  String get contactSharingComingSoon => '聯絡人分享即將推出';

  @override
  String get featureComingSoon => '功能即將推出';

  @override
  String get answerSent => '答案已傳送！';

  @override
  String get noImagesAvailable => '沒有可用的圖片';

  @override
  String get mentionPickerComingSoon => '提及選擇器即將推出';

  @override
  String get musicPickerComingSoon => '音樂選擇器即將推出';

  @override
  String get repostFeatureComingSoon => '轉發功能即將推出';

  @override
  String get addFriendsFromYourProfile => '從您的個人檔案新增好友';

  @override
  String get quickReplyAdded => '已新增快速回覆';

  @override
  String get quickReplyDeleted => '已刪除快速回覆';

  @override
  String get linkCopied => '連結已複製！';

  @override
  String get maximumOptionsAllowed => '最多允許 10 個選項';

  @override
  String get minimumOptionsRequired => '最少需要 2 個選項';

  @override
  String get pleaseEnterAQuestion => '請輸入問題';

  @override
  String get pleaseAddAtLeast2Options => '請新增至少 2 個選項';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => '請選擇測驗的正確答案';

  @override
  String get correctionSent => '更正已傳送！';

  @override
  String get sort => '排序';

  @override
  String get savedMoments => '已儲存的動態';

  @override
  String get unsave => '取消儲存';

  @override
  String get playingAudio => '正在播放音訊...';

  @override
  String get failedToGenerateQuiz => '產生測驗失敗';

  @override
  String get failedToAddComment => '新增留言失敗';

  @override
  String get hello => '你好！';

  @override
  String get howAreYou => '你好嗎？';

  @override
  String get cannotOpen => '無法開啟';

  @override
  String get errorOpeningLink => '開啟連結時發生錯誤';

  @override
  String get saved => '已儲存';

  @override
  String get follow => '追蹤';

  @override
  String get unfollow => '取消追蹤';

  @override
  String get mute => '靜音';

  @override
  String get online => '線上';

  @override
  String get offline => '離線';

  @override
  String get lastSeen => '上次上線';

  @override
  String get justNow => '剛才';

  @override
  String minutesAgo(String count) {
    return '$count 分鐘前';
  }

  @override
  String hoursAgo(String count) {
    return '$count 小時前';
  }

  @override
  String get yesterday => '昨天';

  @override
  String get signInWithEmail => '使用電子郵件登入';

  @override
  String get partners => '夥伴';

  @override
  String get nearby => '附近';

  @override
  String get topics => '主題';

  @override
  String get waves => '招手';

  @override
  String get voiceRooms => '語音';

  @override
  String get filters => '篩選';

  @override
  String get searchCommunity => '按名稱、語言或興趣搜尋...';

  @override
  String get bio => '簡介';

  @override
  String get noBioYet => '尚無簡介。';

  @override
  String get languages => '語言';

  @override
  String get native => '母語';

  @override
  String get interests => '興趣';

  @override
  String get noMomentsYet => '尚無動態';

  @override
  String get noForYouMomentsTitle => '尚無動態';

  @override
  String get noForYouMomentsBody => '回答今天的提示，開始對話吧。';

  @override
  String get noFollowingMomentsTitle => '這裡還沒有內容';

  @override
  String get noFollowingMomentsBody => '追蹤社群中的用戶，即可在這裡看到他們的動態。';

  @override
  String get goToCommunity => '前往社群';

  @override
  String get unableToLoadMoments => '無法載入動態';

  @override
  String get map => '地圖';

  @override
  String get mapUnavailable => '地圖不可用';

  @override
  String get location => '位置';

  @override
  String get unknownLocation => '未知位置';

  @override
  String get noImagesAvailable2 => '沒有可用的圖片';

  @override
  String get permissionsRequired => '需要權限';

  @override
  String get openSettings => '開啟設定';

  @override
  String get refresh => '重新整理';

  @override
  String get videoCall => '視訊';

  @override
  String get voiceCall => '通話';

  @override
  String get message => '訊息';

  @override
  String get pleaseLoginToFollow => '請登入以追蹤用戶';

  @override
  String get pleaseLoginToCall => '請登入以撥打電話';

  @override
  String get cannotCallYourself => '無法打給自己';

  @override
  String get failedToFollowUser => '追蹤用戶失敗';

  @override
  String get failedToUnfollowUser => '取消追蹤用戶失敗';

  @override
  String get areYouSureUnfollow => '您確定要取消追蹤此用戶嗎？';

  @override
  String get areYouSureUnblock => '您確定要解除封鎖此用戶嗎？';

  @override
  String get youFollowed => '您已追蹤';

  @override
  String get youUnfollowed => '您已取消追蹤';

  @override
  String get alreadyFollowing => '您已經在追蹤';

  @override
  String get soon => '即將';

  @override
  String comingSoon(String feature) {
    return '$feature即將推出！';
  }

  @override
  String get muteNotifications => '靜音通知';

  @override
  String get unmuteNotifications => '取消靜音通知';

  @override
  String get operationCompleted => '操作完成';

  @override
  String get couldNotOpenMaps => '無法開啟地圖';

  @override
  String hasntSharedMoments(Object name) {
    return '$name尚未分享任何動態';
  }

  @override
  String messageUser(String name) {
    return '傳送訊息給$name';
  }

  @override
  String notFollowingUser(String name) {
    return '您沒有追蹤$name';
  }

  @override
  String youFollowedUser(String name) {
    return '您已追蹤$name';
  }

  @override
  String youUnfollowedUser(String name) {
    return '您已取消追蹤$name';
  }

  @override
  String unfollowUser(String name) {
    return '取消追蹤$name';
  }

  @override
  String get typing => '正在輸入';

  @override
  String get connecting => '連線中...';

  @override
  String daysAgo(int count) {
    return '$count天前';
  }

  @override
  String get maxTagsAllowed => '最多允許 5 個標籤';

  @override
  String maxImagesAllowed(int count) {
    return '最多允許 $count 張圖片';
  }

  @override
  String get pleaseRemoveImagesFirst => '請先移除圖片以新增影片';

  @override
  String get exchange3MessagesBeforeCall => '通話前請先互傳至少 5 則訊息';

  @override
  String mediaWithUser(String name) {
    return '與$name的媒體';
  }

  @override
  String get errorLoadingMedia => '載入媒體時發生錯誤';

  @override
  String get savedMomentsTitle => '已儲存的動態';

  @override
  String get removeBookmark => '移除書籤？';

  @override
  String get thisWillRemoveBookmark => '這將從您的書籤中移除此訊息。';

  @override
  String get remove => '移除';

  @override
  String get bookmarkRemoved => '書籤已移除';

  @override
  String get bookmarkedMessages => '已加入書籤的訊息';

  @override
  String get wallpaperSaved => '桌布已儲存至本機';

  @override
  String get typeDeleteToConfirm => '輸入DELETE確認';

  @override
  String get storyArchive => '限時動態存檔';

  @override
  String get newHighlight => '新精選';

  @override
  String get addToHighlight => '加入精選';

  @override
  String get repost => '轉發';

  @override
  String get repostFeatureSoon => '轉發功能即將推出';

  @override
  String get closeFriends => '摯友';

  @override
  String get addFriends => '新增好友';

  @override
  String get highlights => '精選';

  @override
  String get createHighlight => '建立精選';

  @override
  String get deleteHighlight => '刪除精選';

  @override
  String get editHighlight => '編輯精選';

  @override
  String get addMoreToStory => '新增更多至限時動態';

  @override
  String get noViewersYet => '尚無觀看者';

  @override
  String get noReactionsYet => '尚無反應';

  @override
  String get leaveRoom => '離開房間';

  @override
  String get areYouSureLeaveRoom => '您確定要離開此語音房間嗎？';

  @override
  String get stay => '留下';

  @override
  String get leave => '離開';

  @override
  String get enableGPS => '啟用 GPS';

  @override
  String wavedToUser(String name) {
    return '您向$name招手了！';
  }

  @override
  String get areYouSureFollow => '您確定要追蹤';

  @override
  String get failedToLoadProfile => '載入個人檔案失敗';

  @override
  String get noFollowersYet => '尚無粉絲';

  @override
  String get noFollowingYet => '尚未追蹤任何人';

  @override
  String get searchUsers => '搜尋使用者...';

  @override
  String get noResultsFound => '找不到結果';

  @override
  String get loadingFailed => '載入失敗';

  @override
  String get copyLink => '複製連結';

  @override
  String get shareStory => '分享限時動態';

  @override
  String get thisWillDeleteStory => '此限時動態將被永久刪除。';

  @override
  String get storyDeleted => '限時動態已刪除';

  @override
  String get addCaption => '新增說明...';

  @override
  String get yourStory => '您的限時動態';

  @override
  String get sendMessage => '傳送訊息';

  @override
  String get replyToStory => '回覆限時動態...';

  @override
  String get viewAllReplies => '查看所有回覆';

  @override
  String get preparingVideo => '準備影片中...';

  @override
  String videoOptimized(String size, String savings) {
    return '影片已優化：${size}MB（節省 $savings%）';
  }

  @override
  String get failedToProcessVideo => '處理影片失敗';

  @override
  String get optimizingForBestExperience => '正在優化以獲得最佳限時動態體驗';

  @override
  String get pleaseSelectImageOrVideo => '請為您的限時動態選擇圖片或影片';

  @override
  String get storyCreatedSuccessfully => '限時動態已成功建立！';

  @override
  String get uploadingStoryInBackground => '正在背景上傳限時動態...';

  @override
  String get storyCreationFailed => '限時動態建立失敗';

  @override
  String get pleaseCheckConnection => '請檢查您的連線並重試。';

  @override
  String get uploadFailed => '上傳失敗';

  @override
  String get tryShorterVideo => '請嘗試較短的影片或稍後重試。';

  @override
  String get shareMomentsThatDisappear => '分享 24 小時後消失的動態';

  @override
  String get photo => '照片';

  @override
  String get record => '錄製';

  @override
  String get addSticker => '新增貼圖';

  @override
  String get poll => '投票';

  @override
  String get question => '問題';

  @override
  String get mention => '提及';

  @override
  String get music => '音樂';

  @override
  String get hashtag => '標籤';

  @override
  String get whoCanSeeThis => '誰可以看到？';

  @override
  String get everyone => '所有人';

  @override
  String get anyoneCanSeeStory => '任何人都可以看到此限時動態';

  @override
  String get friendsOnly => '僅限好友';

  @override
  String get onlyFollowersCanSee => '只有您的粉絲可以看到';

  @override
  String get onlyCloseFriendsCanSee => '只有您的摯友可以看到';

  @override
  String get backgroundColor => '背景顏色';

  @override
  String get fontStyle => '字型樣式';

  @override
  String get normal => '一般';

  @override
  String get bold => '粗體';

  @override
  String get italic => '斜體';

  @override
  String get handwriting => '手寫';

  @override
  String get addLocation => '新增位置';

  @override
  String get enterLocationName => '輸入位置名稱';

  @override
  String get addLink => '新增連結';

  @override
  String get buttonText => '按鈕文字';

  @override
  String get learnMore => '了解更多';

  @override
  String get addHashtags => '新增標籤';

  @override
  String get addHashtag => '新增標籤';

  @override
  String get sendAsMessage => '以訊息傳送';

  @override
  String get shareExternally => '對外分享';

  @override
  String get checkOutStory => '在 Bananatalk 上查看此限時動態！';

  @override
  String viewsTab(String count) {
    return '觀看 ($count)';
  }

  @override
  String reactionsTab(String count) {
    return '反應 ($count)';
  }

  @override
  String get processingVideo => '正在處理影片...';

  @override
  String get link => '連結';

  @override
  String unmuteUser(String name) {
    return '取消靜音$name？';
  }

  @override
  String get willReceiveNotifications => '您將收到新訊息的通知。';

  @override
  String muteNotificationsFor(String name) {
    return '靜音$name的通知';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return '已取消靜音$name的通知';
  }

  @override
  String notificationsMutedFor(String name) {
    return '已靜音$name的通知';
  }

  @override
  String get failedToUpdateMuteSettings => '更新靜音設定失敗';

  @override
  String get oneHour => '1 小時';

  @override
  String get eightHours => '8 小時';

  @override
  String get oneWeek => '1 週';

  @override
  String get always => '永遠';

  @override
  String get failedToLoadBookmarks => '載入書籤失敗';

  @override
  String get noBookmarkedMessages => '沒有已加入書籤的訊息';

  @override
  String get longPressToBookmark => '長按訊息以加入書籤';

  @override
  String get thisWillRemoveFromBookmarks => '這將從您的書籤中移除此訊息。';

  @override
  String navigateToMessage(String name) {
    return '前往與$name聊天中的訊息';
  }

  @override
  String bookmarkedOn(String date) {
    return '已於 $date 加入書籤';
  }

  @override
  String get voiceMessage => '語音訊息';

  @override
  String get document => '文件';

  @override
  String get attachment => '附件';

  @override
  String get sendMeAMessage => '傳送訊息給我';

  @override
  String get shareWithFriends => '與好友分享';

  @override
  String get shareAnywhere => '任意分享';

  @override
  String get emailPreferences => '電子郵件偏好設定';

  @override
  String get receiveEmailNotifications => '接收來自 Bananatalk 的電子郵件通知';

  @override
  String get whenAwayFor24Hours => '當您離開超過 24 小時時';

  @override
  String get passwordAndLoginAlerts => '密碼和登入警報';

  @override
  String get failedToLoadPreferences => '載入偏好設定失敗';

  @override
  String get failedToUpdateSetting => '更新設定失敗';

  @override
  String get securityAlertsRecommended => '我們建議您保持安全警報開啟，以便了解重要的帳戶活動。';

  @override
  String chatWallpaperFor(String name) {
    return '$name的聊天桌布';
  }

  @override
  String get solidColors => '純色';

  @override
  String get gradients => '漸層';

  @override
  String get customImage => '自訂圖片';

  @override
  String get chooseFromGallery => '從相簿選擇';

  @override
  String get preview => '預覽';

  @override
  String get wallpaperUpdated => '桌布已更新';

  @override
  String get category => '類別';

  @override
  String get mood => '心情';

  @override
  String get sortBy => '排序依據';

  @override
  String get timePeriod => '時間段';

  @override
  String get searchLanguages => '搜尋語言...';

  @override
  String get selected => '已選取';

  @override
  String get categories => '類別';

  @override
  String get moods => '心情';

  @override
  String get applyFilters => '套用篩選';

  @override
  String applyNFilters(int count) {
    return '套用 $count 個篩選';
  }

  @override
  String get videoMustBeUnder1GB => '影片必須小於1GB。';

  @override
  String get failedToRecordVideo => '錄製影片失敗';

  @override
  String get errorSendingVideo => '傳送影片時發生錯誤';

  @override
  String get errorSendingVoiceMessage => '傳送語音訊息時發生錯誤';

  @override
  String get errorSendingMedia => '傳送媒體時發生錯誤';

  @override
  String get cameraPermissionRequired => '錄製影片需要相機和麥克風權限。';

  @override
  String get locationPermissionRequired => '分享您的位置需要位置權限。';

  @override
  String get noInternetConnection => '沒有網路連線';

  @override
  String get tryAgainLater => '請稍後再試';

  @override
  String get messageSent => '訊息已傳送';

  @override
  String get messageDeleted => '訊息已刪除';

  @override
  String get messageEdited => '訊息已編輯';

  @override
  String get edited => '(已編輯)';

  @override
  String get now => '剛剛';

  @override
  String weeksAgo(int count) {
    return '$count週前';
  }

  @override
  String viewRepliesCount(int count) {
    return '── 查看$count則回覆';
  }

  @override
  String get hideReplies => '── 隱藏回覆';

  @override
  String get saveMoment => '儲存動態';

  @override
  String get removeFromSaved => '取消儲存';

  @override
  String get momentSaved => '已儲存';

  @override
  String get failedToSave => '儲存失敗';

  @override
  String get checkOutMoment => '在Bananatalk上看看這則動態!';

  @override
  String get checkOutProfile => '來看看我在 Bananatalk 上的個人檔案！';

  @override
  String get checkOutCommunity => '來看看 Bananatalk 上的這位成員！';

  @override
  String get failedToLoadMoments => '載入動態失敗';

  @override
  String get noMomentsMatchFilters => '沒有符合篩選條件的動態';

  @override
  String get beFirstToShareMoment => '成為第一個分享動態的人！';

  @override
  String get tryDifferentSearch => '試試其他搜尋詞';

  @override
  String get tryAdjustingFilters => '試試調整篩選條件';

  @override
  String get noSavedMoments => '沒有儲存的動態';

  @override
  String get tapBookmarkToSave => '點擊書籤圖示儲存動態';

  @override
  String get failedToLoadVideo => '影片載入失敗';

  @override
  String get titleRequired => '標題不能為空';

  @override
  String titleTooLong(int max) {
    return '標題不能超過$max個字元';
  }

  @override
  String get descriptionRequired => '說明不能為空';

  @override
  String descriptionTooLong(int max) {
    return '說明不能超過$max個字元';
  }

  @override
  String get scheduledDateMustBeFuture => '預約日期必須是未來的日期';

  @override
  String get recent => '最新';

  @override
  String get popular => '熱門';

  @override
  String get trending => '趨勢';

  @override
  String get mostRecent => '最新';

  @override
  String get mostPopular => '最熱門';

  @override
  String get allTime => '全部';

  @override
  String get today => '今天';

  @override
  String get thisWeek => '本週';

  @override
  String get thisMonth => '本月';

  @override
  String replyingTo(String userName) {
    return '回覆 $userName';
  }

  @override
  String get listView => '列表';

  @override
  String get quickMatch => '快速配對';

  @override
  String get onlineNow => '在線';

  @override
  String speaksLanguage(String language) {
    return '會說$language';
  }

  @override
  String learningLanguage(String language) {
    return '正在學$language';
  }

  @override
  String get noPartnersFound => '未找到語伴';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return '找不到以$learning為母語或想學$native的用戶。';
  }

  @override
  String get removeAllFilters => '移除所有篩選';

  @override
  String get browseAllUsers => '瀏覽所有用戶';

  @override
  String get allCaughtUp => '已看完所有！';

  @override
  String get loadingMore => '載入更多...';

  @override
  String get findingMorePartners => '正在為您尋找更多語伴...';

  @override
  String get seenAllPartners => '您已瀏覽所有可用的語伴，稍後再來看看！';

  @override
  String get startOver => '重新開始';

  @override
  String get changeFilters => '變更篩選條件';

  @override
  String get findingPartners => '尋找語伴中...';

  @override
  String get setLocationReminder => '在個人資料中設定您的位置，優先顯示附近用戶。';

  @override
  String get updateLocationReminder => '在個人資料 > 編輯中更新位置以獲得準確的附近結果。';

  @override
  String get male => '男性';

  @override
  String get female => '女性';

  @override
  String get other => '其他';

  @override
  String get browseMen => '瀏覽男性';

  @override
  String get browseWomen => '瀏覽女性';

  @override
  String get noMaleUsersFound => '未找到男性用戶';

  @override
  String get noFemaleUsersFound => '未找到女性用戶';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => '僅限新用戶';

  @override
  String get showNewUsers => '顯示最近6天加入的用戶';

  @override
  String get prioritizeNearby => '優先附近';

  @override
  String get showNearbyFirst => '在結果中優先顯示附近用戶';

  @override
  String get setLocationToEnable => '設定您的位置以啟用此功能';

  @override
  String get radius => '半徑';

  @override
  String get findingYourLocation => '正在定位...';

  @override
  String get enableLocationForDistance => '啟用位置以顯示距離';

  @override
  String get enableLocationDescription => '啟用GPS以查看與語伴的精確距離。不開GPS也可以按城市/國家瀏覽。';

  @override
  String get enableGps => '啟用GPS';

  @override
  String get browseByCityCountry => '按城市/國家瀏覽';

  @override
  String get peopleNearby => '附近的人';

  @override
  String get noNearbyUsersFound => '未找到附近用戶';

  @override
  String get tryExpandingSearch => '嘗試擴大搜索範圍或稍後再試。';

  @override
  String get exploreByCity => '按城市探索';

  @override
  String get exploreByCurrentCity => '在互動地圖上瀏覽用戶，發現全球語伴。';

  @override
  String get interactiveWorldMap => '互動世界地圖';

  @override
  String get searchByCityName => '按城市名搜索';

  @override
  String get seeUserCountsPerCountry => '查看各國用戶數量';

  @override
  String get upgradeToVip => '升級VIP';

  @override
  String get searchByCity => '搜索城市...';

  @override
  String usersWorldwide(String count) {
    return '全球$count人';
  }

  @override
  String get noUsersFound => '找不到用戶';

  @override
  String get tryDifferentCity => '試試其他城市或國家';

  @override
  String usersCount(String count) {
    return '$count人';
  }

  @override
  String get searchCountry => '搜尋國家...';

  @override
  String get wave => '打招呼';

  @override
  String get newUser => 'NEW';

  @override
  String get warningPermanent => '警告：此操作不可撤銷！';

  @override
  String get deleteAccountWarning => '刪除帳號將永久刪除：\n\n• 您的個人資料和所有個人數據\n• 所有訊息和對話\n• 所有動態和限時動態\n• VIP訂閱（不退款）\n• 所有關注和粉絲\n\n此操作不可撤銷。';

  @override
  String get requiredForEmailOnly => '僅電子郵件帳號需要';

  @override
  String get pleaseEnterPassword => '請輸入密碼';

  @override
  String get typeDELETE => '輸入DELETE確認';

  @override
  String get mustTypeDELETE => '必須輸入DELETE確認';

  @override
  String get deletingAccount => '正在刪除帳號...';

  @override
  String get deleteMyAccountPermanently => '永久刪除我的帳號';

  @override
  String get whatsYourNativeLanguage => '您的母語是什麼？';

  @override
  String get helpsMatchWithLearners => '幫助我們為您配對學習者';

  @override
  String get whatAreYouLearning => '您在學什麼？';

  @override
  String get connectWithNativeSpeakers => '我們會為您連結母語者';

  @override
  String get selectLearningLanguage => '請選擇您正在學習的語言';

  @override
  String get selectCurrentLevel => '請選擇您的當前程度';

  @override
  String get beginner => '入門';

  @override
  String get elementary => '初級';

  @override
  String get intermediate => '中級';

  @override
  String get upperIntermediate => '中高級';

  @override
  String get advanced => '高級';

  @override
  String get proficient => '精通';

  @override
  String get showingPartnersByDistance => '按距離排序顯示語伴';

  @override
  String get enableLocationForResults => '啟用定位以獲取基於距離的結果';

  @override
  String get enable => '啟用';

  @override
  String get locationNotSet => '未設定位置';

  @override
  String get tellUsAboutYourself => '介紹一下您自己';

  @override
  String get justACoupleQuickThings => '只需幾個簡單問題';

  @override
  String get gender => '性別';

  @override
  String get birthDate => '出生日期';

  @override
  String get selectYourBirthDate => '選擇您的出生日期';

  @override
  String get continueButton => '繼續';

  @override
  String get pleaseSelectGender => '請選擇您的性別';

  @override
  String get pleaseSelectBirthDate => '請選擇您的出生日期';

  @override
  String get mustBe18 => '您必須年滿18歲';

  @override
  String get invalidDate => '日期無效';

  @override
  String get almostDone => '快完成了！';

  @override
  String get addPhotoLocationForMatches => '添加照片和位置以獲得更多配對';

  @override
  String get addProfilePhoto => '添加大頭照';

  @override
  String get optionalUpTo6Photos => '選填 — 最多6張照片';

  @override
  String get requiredUpTo6Photos => '必填 — 最多6張';

  @override
  String get profilePhotoRequired => '請至少新增一張個人頭像';

  @override
  String get locationOptional => '請設定您的位置以繼續';

  @override
  String get maximum6Photos => '最多6張照片';

  @override
  String get tapToDetectLocation => '點擊偵測位置';

  @override
  String get optionalHelpsNearbyPartners => '必填 — 有助於配對附近的夥伴';

  @override
  String get startLearning => '開始學習！';

  @override
  String get photoLocationOptional => '照片和位置為選填 — 稍後可以添加';

  @override
  String get pleaseAcceptTerms => '請接受服務條款';

  @override
  String get iAgreeToThe => '我同意';

  @override
  String get termsOfService => '服務條款';

  @override
  String get tapToSelectLanguage => '點擊選擇語言';

  @override
  String yourLevelIn(String language) {
    return '您的$language程度（選填）';
  }

  @override
  String get yourCurrentLevel => '您的當前程度';

  @override
  String get nativeCannotBeSameAsLearning => '母語不能與學習語言相同';

  @override
  String get learningCannotBeSameAsNative => '學習語言不能與母語相同';

  @override
  String stepOf(String current, String total) {
    return '第$current步，共$total步';
  }

  @override
  String get continueWithGoogle => '使用Google繼續';

  @override
  String get registerLink => '註冊';

  @override
  String get pleaseEnterBothEmailAndPassword => '請輸入電子郵件和密碼';

  @override
  String get pleaseEnterValidEmail => '請輸入有效的電子郵件';

  @override
  String get loginSuccessful => '登入成功！';

  @override
  String get stepOneOfTwo => '第1步，共2步';

  @override
  String get createYourAccount => '建立帳號';

  @override
  String get basicInfoToGetStarted => '開始前的基本資訊';

  @override
  String get emailVerifiedLabel => '電子郵件（已驗證）';

  @override
  String get nameLabel => '姓名';

  @override
  String get yourDisplayName => '顯示名稱';

  @override
  String get atLeast8Characters => '至少8個字元';

  @override
  String get confirmPasswordHint => '再次輸入新密碼';

  @override
  String get nextButton => '下一步';

  @override
  String get pleaseEnterYourName => '請輸入您的姓名';

  @override
  String get pleaseEnterAPassword => '請輸入密碼';

  @override
  String get passwordsDoNotMatch => '密碼不相符';

  @override
  String get otherGender => '其他';

  @override
  String get continueWithGoogleAccount => '使用Google帳號繼續\n享受無縫體驗';

  @override
  String get signingYouIn => '正在登入...';

  @override
  String get backToSignInMethods => '返回登入方式';

  @override
  String get securedByGoogle => '由Google保障安全';

  @override
  String get dataProtectedEncryption => '您的資料受到業界標準加密保護';

  @override
  String get welcomeCompleteProfile => '歡迎！請完善您的個人資料';

  @override
  String welcomeBackName(String name) {
    return '歡迎回來，$name！';
  }

  @override
  String get continueWithAppleId => '使用Apple ID繼續\n享受安全體驗';

  @override
  String get continueWithApple => '使用Apple繼續';

  @override
  String get securedByApple => '由Apple保障安全';

  @override
  String get privacyProtectedApple => 'Apple登入保護您的隱私';

  @override
  String get createAccount => '建立帳號';

  @override
  String get enterEmailToGetStarted => '輸入電子郵件開始';

  @override
  String get continueText => '繼續';

  @override
  String get pleaseEnterEmailAddress => '請輸入電子郵件地址';

  @override
  String get verificationCodeSent => '驗證碼已發送到您的信箱！';

  @override
  String get forgotPasswordTitle => '忘記密碼';

  @override
  String get resetPasswordTitle => '重設密碼';

  @override
  String get enterEmailForResetCode => '輸入您的電子郵件，我們將發送重設密碼的驗證碼';

  @override
  String get sendResetCode => '發送重設碼';

  @override
  String get resetCodeSent => '重設碼已發送！';

  @override
  String get rememberYourPassword => '記得密碼？';

  @override
  String get verifyCode => '驗證碼';

  @override
  String get enterResetCode => '輸入重設碼';

  @override
  String get weSentCodeTo => '我們已發送6位驗證碼到';

  @override
  String get pleaseEnterAll6Digits => '請輸入所有6位數字';

  @override
  String get codeVerifiedCreatePassword => '驗證成功！請建立新密碼';

  @override
  String get verify => '驗證';

  @override
  String get didntReceiveCode => '沒有收到驗證碼？';

  @override
  String get resend => '重新發送';

  @override
  String resendWithTimer(String timer) {
    return '重新發送（$timer秒）';
  }

  @override
  String get resetCodeResent => '重設碼已重新發送！';

  @override
  String get verifyEmail => '驗證信箱';

  @override
  String get verifyYourEmail => '驗證您的電子郵件';

  @override
  String get emailVerifiedSuccessfully => '電子郵件驗證成功！';

  @override
  String get verificationCodeResent => '驗證碼已重新發送！';

  @override
  String get createNewPassword => '建立新密碼';

  @override
  String get enterNewPasswordBelow => '在下方輸入新密碼';

  @override
  String get newPassword => '新密碼';

  @override
  String get confirmPasswordLabel => '確認密碼';

  @override
  String get pleaseFillAllFields => '請填寫所有欄位';

  @override
  String get passwordResetSuccessful => '密碼重設成功！請使用新密碼登入';

  @override
  String get privacyTitle => '隱私';

  @override
  String get profileVisibility => '個人資料可見性';

  @override
  String get showCountryRegion => '顯示國家/地區';

  @override
  String get showCountryRegionDesc => '在個人資料中顯示您的國家';

  @override
  String get showCity => '顯示城市';

  @override
  String get showCityDesc => '在個人資料中顯示您的城市';

  @override
  String get showAge => '顯示年齡';

  @override
  String get showAgeDesc => '在個人資料中顯示您的年齡';

  @override
  String get showZodiacSign => '顯示星座';

  @override
  String get showZodiacSignDesc => '在個人資料中顯示您的星座';

  @override
  String get onlineStatusSection => '線上狀態';

  @override
  String get showOnlineStatus => '顯示線上狀態';

  @override
  String get showOnlineStatusDesc => '讓其他人看到您的線上狀態';

  @override
  String get otherSettings => '其他設定';

  @override
  String get showGiftingLevel => '顯示禮物等級';

  @override
  String get showGiftingLevelDesc => '顯示禮物等級徽章';

  @override
  String get birthdayNotifications => '生日通知';

  @override
  String get birthdayNotificationsDesc => '在生日時接收通知';

  @override
  String get personalizedAds => '個人化廣告';

  @override
  String get personalizedAdsDesc => '允許個人化廣告';

  @override
  String get saveChanges => '儲存變更';

  @override
  String get privacySettingsSaved => '隱私設定已儲存';

  @override
  String get locationSection => '位置';

  @override
  String get updateLocation => '更新位置';

  @override
  String get updateLocationDesc => '重新整理您的目前位置';

  @override
  String get currentLocation => '目前位置';

  @override
  String get locationNotAvailable => '位置不可用';

  @override
  String get locationUpdated => '位置更新成功';

  @override
  String get locationPermissionDenied => '位置權限被拒絕，請在設定中啟用。';

  @override
  String get locationServiceDisabled => '位置服務已停用，請啟用。';

  @override
  String get updatingLocation => '正在更新位置...';

  @override
  String get locationCouldNotBeUpdated => '無法更新位置';

  @override
  String get incomingAudioCall => '來電語音通話';

  @override
  String get incomingVideoCall => '來電視訊通話';

  @override
  String get outgoingCall => '撥打中...';

  @override
  String get callRinging => '響鈴中...';

  @override
  String get callConnecting => '連接中...';

  @override
  String get callConnected => '已連接';

  @override
  String get callReconnecting => '重新連接中...';

  @override
  String get callEnded => '通話結束';

  @override
  String get callFailed => '通話失敗';

  @override
  String get callMissed => '未接來電';

  @override
  String get callDeclined => '通話已拒絕';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => '接聽';

  @override
  String get declineCall => '拒絕';

  @override
  String get endCall => '結束';

  @override
  String get muteCall => '靜音';

  @override
  String get unmuteCall => '取消靜音';

  @override
  String get speakerOn => '擴音器';

  @override
  String get speakerOff => '聽筒';

  @override
  String get videoOn => '開啟視訊';

  @override
  String get videoOff => '關閉視訊';

  @override
  String get switchCamera => '切換鏡頭';

  @override
  String get callPermissionDenied => '通話需要麥克風權限';

  @override
  String get cameraPermissionDenied => '視訊通話需要鏡頭權限';

  @override
  String get callConnectionFailed => '無法連接。請重試。';

  @override
  String get userBusy => '使用者忙碌';

  @override
  String get userOffline => '使用者離線';

  @override
  String get callHistory => '通話記錄';

  @override
  String get noCallHistory => '沒有通話記錄';

  @override
  String get missedCalls => '未接來電';

  @override
  String get allCalls => '所有通話';

  @override
  String get callBack => '回撥';

  @override
  String callAt(String time) {
    return '$time的通話';
  }

  @override
  String get audioCall => '語音通話';

  @override
  String get voiceRoom => '語音房間';

  @override
  String get noVoiceRooms => '沒有活躍的語音房間';

  @override
  String get createVoiceRoom => '建立語音房間';

  @override
  String get joinRoom => '加入房間';

  @override
  String get leaveRoomConfirm => '離開房間？';

  @override
  String get leaveRoomMessage => '確定要離開這個房間嗎？';

  @override
  String get roomTitle => '房間標題';

  @override
  String get roomTitleHint => '輸入房間標題';

  @override
  String get roomTopic => '話題';

  @override
  String get roomLanguage => '語言';

  @override
  String get roomHost => '房主';

  @override
  String roomParticipants(int count) {
    return '$count位參與者';
  }

  @override
  String roomMaxParticipants(int count) {
    return '最多$count位參與者';
  }

  @override
  String get selectTopic => '選擇話題';

  @override
  String get raiseHand => '舉手';

  @override
  String get lowerHand => '放下手';

  @override
  String get handRaisedNotification => '已舉手！房主將看到您的請求。';

  @override
  String get handLoweredNotification => '已放下手';

  @override
  String get muteParticipant => '將參與者靜音';

  @override
  String get kickParticipant => '移出房間';

  @override
  String get promoteToCoHost => '設為副房主';

  @override
  String get endRoomConfirm => '結束房間？';

  @override
  String get endRoomMessage => '這將結束所有參與者的房間。';

  @override
  String get roomEnded => '房主已結束房間';

  @override
  String get youWereRemoved => '您已被移出房間';

  @override
  String get roomIsFull => '房間已滿';

  @override
  String get roomChat => '房間聊天';

  @override
  String get noMessages => '暫無訊息';

  @override
  String get typeMessage => '輸入訊息...';

  @override
  String get voiceRoomsDescription => '加入即時對話，練習口說';

  @override
  String liveRoomsCount(int count) {
    return '$count個直播';
  }

  @override
  String get noActiveRooms => '沒有活躍房間';

  @override
  String get noActiveRoomsDescription => '成為第一個建立語音房間的人，與他人一起練習口說！';

  @override
  String get startRoom => '開始房間';

  @override
  String get createRoom => '建立房間';

  @override
  String get roomCreated => '房間建立成功！';

  @override
  String get failedToCreateRoom => '建立房間失敗';

  @override
  String get errorLoadingRooms => '載入房間出錯';

  @override
  String get pleaseEnterRoomTitle => '請輸入房間標題';

  @override
  String get startLiveConversation => '開始即時對話';

  @override
  String get maxParticipants => '最大參與者';

  @override
  String nPeople(int count) {
    return '$count人';
  }

  @override
  String hostedBy(String name) {
    return '$name 主持';
  }

  @override
  String get liveLabel => '直播中';

  @override
  String get joinLabel => '加入';

  @override
  String get fullLabel => '已滿';

  @override
  String get justStarted => '剛剛開始';

  @override
  String get allLanguages => '所有語言';

  @override
  String get allTopics => '所有話題';

  @override
  String get allCategories => '所有類別';

  @override
  String get leaderboard => '排行榜';

  @override
  String get competeWithLearners => '與其他學習者一較高下！';

  @override
  String get xpRankings => 'XP 排名';

  @override
  String get streaks => '連擊';

  @override
  String get friends => '好友';

  @override
  String get myRanks => '我的排名';

  @override
  String get currentStreak => '目前連擊';

  @override
  String get longestStreak => '最長連擊';

  @override
  String get weekly => '每週';

  @override
  String get monthly => '每月';

  @override
  String get yourRank => '你的排名';

  @override
  String outOf(int total) {
    return '（共 $total 人）';
  }

  @override
  String topPercent(String percent) {
    return '前 $percent%';
  }

  @override
  String get xpRank => 'XP 排名';

  @override
  String get streakRank => '連擊排名';

  @override
  String get days => '天';

  @override
  String get learningStats => '學習統計';

  @override
  String get totalXp => '總 XP';

  @override
  String get lessonsCompleted => '已完成課程數';

  @override
  String get rankings => '排名';

  @override
  String get yourPosition => '你的位置';

  @override
  String get keepLearning => '繼續學習，向上晉升！';

  @override
  String get noRankingsYet => '尚無排名';

  @override
  String get startLearningToAppear => '開始學習即可出現在排行榜上！';

  @override
  String get noFriendsYet => '尚無好友';

  @override
  String get addFriendsToCompete => '新增好友，和他們一較高下！';

  @override
  String get failedToLoadLeaderboard => '載入排行榜失敗';

  @override
  String get you => '你';

  @override
  String get findPartners => '尋找夥伴';

  @override
  String get discoverLanguagePartners => '探索語言夥伴';

  @override
  String get byLanguage => '依語言';

  @override
  String get match => '配對';

  @override
  String get matchScore => '配對分數';

  @override
  String get noMatchesFound => '未找到配對';

  @override
  String get noUsersOnline => '目前沒有使用者上線';

  @override
  String get checkBackLater => '稍後再回來看看';

  @override
  String get selectLanguagePrompt => '選擇一種語言';

  @override
  String get findPartnersByLanguage => '尋找使用或學習這個語言的夥伴';

  @override
  String noPartnersForLanguage(String language) {
    return '沒有適合 $language 的夥伴';
  }

  @override
  String get tryAnotherLanguage => '試試選擇另一種語言';

  @override
  String get failedToLoadMatches => '載入配對失敗';

  @override
  String get dataAndStorage => '數據與儲存';

  @override
  String get manageStorageAndDownloads => '管理儲存和下載';

  @override
  String get storageUsage => '儲存使用情況';

  @override
  String get totalCacheSize => '總快取大小';

  @override
  String get imageCache => '圖片快取';

  @override
  String get voiceMessagesCache => '語音訊息';

  @override
  String get videoCache => '影片快取';

  @override
  String get otherCache => '其他快取';

  @override
  String get autoDownloadMedia => '自動下載媒體';

  @override
  String get currentNetwork => '目前網路';

  @override
  String get images => '圖片';

  @override
  String get videos => '影片';

  @override
  String get voiceMessagesShort => '語音訊息';

  @override
  String get documentsLabel => '文件';

  @override
  String get wifiOnly => '僅Wi-Fi';

  @override
  String get never => '從不';

  @override
  String get clearAllCache => '清除所有快取';

  @override
  String get allCache => '所有快取';

  @override
  String get clearAllCacheConfirmation => '這將清除所有快取的圖片、語音訊息、影片和其他檔案。應用程式可能會暫時載入內容較慢。';

  @override
  String clearCacheConfirmationFor(String category) {
    return '清除$category？';
  }

  @override
  String storageToFree(String size) {
    return '將釋放$size';
  }

  @override
  String get calculating => '計算中...';

  @override
  String get noDataToShow => '無資料顯示';

  @override
  String get profileCompletion => '個人資料完成度';

  @override
  String get justGettingStarted => '剛開始';

  @override
  String get lookingGood => '很不錯！';

  @override
  String get almostThere => '快完成了！';

  @override
  String addMissingFields(String fields, Object field) {
    return '新增: $fields';
  }

  @override
  String get profilePicture => '大頭貼';

  @override
  String get nativeSpeaker => '母語者';

  @override
  String peopleInterestedInTopic(Object count) {
    return '對此話題感興趣的人';
  }

  @override
  String get beFirstToAddTopic => '成為第一個新增此話題的人！';

  @override
  String get recentMoments => '最近動態';

  @override
  String get seeAll => '查看全部';

  @override
  String get study => '學習';

  @override
  String get followerMoments => '追蹤者動態';

  @override
  String get whenPeopleYouFollowPost => '當你追蹤的人發布新動態時';

  @override
  String get noNotificationsYet => '暫無通知';

  @override
  String get whenYouGetNotifications => '收到通知後將在此顯示';

  @override
  String get failedToLoadNotifications => '載入通知失敗';

  @override
  String get clearAllNotificationsConfirm => '確定要清除所有通知嗎？此操作無法復原。';

  @override
  String get tapToChange => '點擊更改';

  @override
  String get noPictureSet => '尚未設定照片';

  @override
  String get nameAndGender => '姓名與性別';

  @override
  String get languageLevel => '語言程度';

  @override
  String get personalInformation => '個人資訊';

  @override
  String get mbti => 'MBTI';

  @override
  String get topicsOfInterest => '感興趣的話題';

  @override
  String get levelBeginner => '入門';

  @override
  String get levelElementary => '初級';

  @override
  String get levelIntermediate => '中級';

  @override
  String get levelUpperIntermediate => '中高級';

  @override
  String get levelAdvanced => '高級';

  @override
  String get levelProficient => '精通';

  @override
  String get selectYourLevel => '選擇您的程度';

  @override
  String howWellDoYouSpeak(String language) {
    return '您的$language程度如何？';
  }

  @override
  String get theLanguage => '語言';

  @override
  String languageLevelSetTo(String level) {
    return '語言程度已設為$level';
  }

  @override
  String get failedToUpdate => '更新失敗';

  @override
  String get profileUpdatedSuccessfully => '個人資料已成功更新';

  @override
  String get genderRequired => '性別（必填）';

  @override
  String get editHometown => '編輯家鄉';

  @override
  String get useCurrentLocation => '使用目前位置';

  @override
  String get detecting => '偵測中...';

  @override
  String get getCurrentLocation => '取得目前位置';

  @override
  String get country => '國家';

  @override
  String get city => '城市';

  @override
  String get coordinates => '座標';

  @override
  String get noLocationDetectedYet => '尚未偵測到位置';

  @override
  String get detected => '已偵測';

  @override
  String get savedHometown => '已儲存家鄉';

  @override
  String get locationServicesDisabled => '位置服務已停用';

  @override
  String get locationPermissionPermanentlyDenied => '位置權限已永久拒絕';

  @override
  String get unknown => '未知';

  @override
  String get editBio => '編輯個人簡介';

  @override
  String get bioUpdatedSuccessfully => '個人簡介已更新！';

  @override
  String get tellOthersAboutYourself => '介紹一下自己';

  @override
  String charactersCount(int count) {
    return '$count/500字';
  }

  @override
  String get selectYourMbti => '選擇您的MBTI';

  @override
  String get myBloodType => '我的血型';

  @override
  String get pleaseSelectABloodType => '請選擇血型';

  @override
  String get bloodTypeSavedSuccessfully => '血型儲存成功';

  @override
  String get hometownSavedSuccessfully => '家鄉儲存成功';

  @override
  String get nativeLanguageRequired => '需要母語';

  @override
  String get languageToLearnRequired => '需要學習語言';

  @override
  String get nativeLanguageCannotBeSame => '母語不能與學習語言相同';

  @override
  String get learningLanguageCannotBeSame => '學習語言不能與母語相同';

  @override
  String get pleaseSelectALanguage => '請選擇語言';

  @override
  String get editInterests => '編輯興趣';

  @override
  String maxTopicsAllowed(int count) {
    return '最多允許$count個話題';
  }

  @override
  String get topicsUpdatedSuccessfully => '話題已更新！';

  @override
  String get failedToUpdateTopics => '話題更新失敗';

  @override
  String selectedCount(int count, int max) {
    return '已選$count個';
  }

  @override
  String get profilePictures => '個人照片';

  @override
  String get addImages => '新增照片';

  @override
  String get selectUpToImages => '選擇最多null張照片';

  @override
  String get takeAPhoto => '拍照';

  @override
  String get removeImage => '移除照片';

  @override
  String get removeImageConfirm => '確定要移除此照片嗎？';

  @override
  String get removeAll => '全部刪除';

  @override
  String get removeAllSelectedImages => '刪除所有選中的圖片';

  @override
  String get removeAllSelectedImagesConfirm => '確定要刪除所有選中的圖片嗎？';

  @override
  String get yourProfilePictureWillBeKept => '您現有的頭像將被保留';

  @override
  String get removeAllImages => '刪除所有圖片';

  @override
  String get removeAllImagesConfirm => '確定要刪除所有頭像嗎？';

  @override
  String get currentImages => '當前圖片';

  @override
  String get newImages => '新圖片';

  @override
  String get addMoreImages => '新增更多圖片';

  @override
  String uploadImages(int count) {
    return '上傳$count張照片';
  }

  @override
  String get imageRemovedSuccessfully => '照片已移除';

  @override
  String get imagesUploadedSuccessfully => '照片已上傳';

  @override
  String get selectedImagesCleared => '已清除選中的圖片';

  @override
  String get extraImagesRemovedSuccessfully => '多餘圖片已成功刪除';

  @override
  String get mustKeepAtLeastOneProfilePicture => '必須保留至少一張頭像';

  @override
  String get noProfilePicturesToRemove => '沒有可刪除的頭像';

  @override
  String get authenticationTokenNotFound => '未找到認證令牌';

  @override
  String get saveChangesQuestion => '儲存更改？';

  @override
  String youHaveUnuploadedImages(int count) {
    return '您已選擇$count張圖片但未上傳。是否現在上傳？';
  }

  @override
  String get discard => '放棄';

  @override
  String get upload => '上傳';

  @override
  String maxImagesInfo(int max, int current) {
    return '最多可上傳$max張圖片。當前: $current/$max\n每次最多上傳5張圖片。';
  }

  @override
  String canOnlyAddMoreImages(int count, int max) {
    return '只能再新增$count張圖片。最多$max張。';
  }

  @override
  String get maxImagesPerUpload => '每次最多隻能上傳5張圖片。只有前5張會被新增。';

  @override
  String canOnlyHaveMaxImages(int max) {
    return '最多只能有$max張圖片';
  }

  @override
  String get imageSizeExceedsLimit => '圖片大小超過10MB限制';

  @override
  String get unsupportedImageFormat => '不支援的圖片格式';

  @override
  String get pleaseSelectAtLeastOneImage => '請至少選擇一張圖片上傳';

  @override
  String get basicInformation => '基本資訊';

  @override
  String get languageToLearn => '學習語言';

  @override
  String get hometown => '家鄉';

  @override
  String get characters => '字';

  @override
  String get failedToLoadLanguages => '載入語言失敗';

  @override
  String get studyHub => '學習中心';

  @override
  String get dailyLearningJourney => '您的每日學習之旅';

  @override
  String get learnTab => '學習';

  @override
  String get aiTools => 'AI工具';

  @override
  String get streak => '連續學習';

  @override
  String get lessons => '課程';

  @override
  String get words => '單詞';

  @override
  String get quickActions => '快速操作';

  @override
  String get review => '複習';

  @override
  String wordsDue(int count) {
    return '$count個單詞待複習';
  }

  @override
  String get addWords => '新增單詞';

  @override
  String get buildVocabulary => '積累詞彙';

  @override
  String get practiceWithAI => 'AI練習';

  @override
  String get aiPracticeDescription => '聊天、測驗、文法和發音';

  @override
  String get dailyChallenges => '每日挑戰';

  @override
  String get allChallengesCompleted => '所有挑戰已完成！';

  @override
  String get continueLearning => '繼續學習';

  @override
  String get structuredLearningPath => '系統學習路徑';

  @override
  String get vocabulary => '詞彙';

  @override
  String get yourWordCollection => '我的單詞集';

  @override
  String get achievements => '成就';

  @override
  String get badgesAndMilestones => '徽章和里程碑';

  @override
  String get failedToLoadLearningData => '載入學習資料失敗';

  @override
  String get startYourJourney => '開始你的旅程！';

  @override
  String get startJourneyDescription => '完成課程，積累詞彙，\n追蹤你的進度';

  @override
  String levelN(int level) {
    return '第$level級';
  }

  @override
  String xpEarned(int xp) {
    return '已獲得$xp XP';
  }

  @override
  String nextLevel(int level) {
    return '下一級：第$level級';
  }

  @override
  String xpToGo(int xp) {
    return '還需$xp XP';
  }

  @override
  String get aiConversationPartner => 'AI對話夥伴';

  @override
  String get practiceWithAITutor => '與AI導師練習口語';

  @override
  String get startConversation => '開始對話';

  @override
  String get aiFeatures => 'AI功能';

  @override
  String get aiLessons => 'AI課程';

  @override
  String get learnWithAI => 'AI學習';

  @override
  String get grammar => '文法';

  @override
  String get checkWriting => '檢查寫作';

  @override
  String get pronunciation => '發音';

  @override
  String get improveSpeaking => '提升口語';

  @override
  String get translation => '翻譯';

  @override
  String get smartTranslate => '智能翻譯';

  @override
  String get aiQuizzes => 'AI測驗';

  @override
  String get testKnowledge => '測試知識';

  @override
  String get lessonBuilder => '課程建構器';

  @override
  String get customLessons => '自訂課程';

  @override
  String get yourAIProgress => '我的AI進度';

  @override
  String get quizzes => '測驗';

  @override
  String get avgScore => '平均分';

  @override
  String get focusAreas => '重點領域';

  @override
  String accuracyPercent(String accuracy) {
    return '準確率$accuracy%';
  }

  @override
  String get practice => '練習';

  @override
  String get browse => '瀏覽';

  @override
  String get noRecommendedLessons => '暫無推薦課程';

  @override
  String get noLessonsFound => '未找到課程';

  @override
  String get createCustomLessonDescription => '用AI建立你的專屬課程';

  @override
  String get createLessonWithAI => '用AI建立課程';

  @override
  String get allLevels => '所有級別';

  @override
  String get levelA1 => 'A1 入門';

  @override
  String get levelA2 => 'A2 初級';

  @override
  String get levelB1 => 'B1 中級';

  @override
  String get levelB2 => 'B2 中高級';

  @override
  String get levelC1 => 'C1 高級';

  @override
  String get levelC2 => 'C2 精通';

  @override
  String get failedToLoadLessons => '載入課程失敗';

  @override
  String get pin => '置頂';

  @override
  String get unpin => '取消置頂';

  @override
  String get editMessage => '編輯訊息';

  @override
  String get enterMessage => '輸入訊息...';

  @override
  String get deleteMessageTitle => '刪除訊息';

  @override
  String get actionCannotBeUndone => '此操作無法撤銷。';

  @override
  String get onlyRemovesFromDevice => '僅從您的裝置中刪除';

  @override
  String get availableWithinOneHour => '僅1小時內可用';

  @override
  String get available => '可用';

  @override
  String get forwardMessage => '轉發訊息';

  @override
  String get selectUsersToForward => '選擇要轉發的使用者：';

  @override
  String forwardCount(int count) {
    return '轉發 ($count)';
  }

  @override
  String get pinnedMessage => '置頂訊息';

  @override
  String get photoMedia => '照片';

  @override
  String get videoMedia => '影片';

  @override
  String get voiceMessageMedia => '語音訊息';

  @override
  String get documentMedia => '文件';

  @override
  String get locationMedia => '位置';

  @override
  String get stickerMedia => '貼圖';

  @override
  String get smileys => '笑臉';

  @override
  String get emotions => '表情';

  @override
  String get handGestures => '手勢';

  @override
  String get hearts => '愛心';

  @override
  String get tapToSayHi => '點擊打個招呼！';

  @override
  String get sendWaveToStart => '發送問候開始聊天';

  @override
  String get documentMustBeUnder50MB => '文件必須小於50MB。';

  @override
  String get editWithin15Minutes => '訊息只能在15分鐘內編輯';

  @override
  String messageForwardedTo(int count) {
    return '訊息已轉發給$count位使用者';
  }

  @override
  String get failedToLoadUsers => '載入使用者失敗';

  @override
  String get voice => '語音';

  @override
  String get searchGifs => '搜尋GIF...';

  @override
  String get trendingGifs => '熱門';

  @override
  String get poweredByGiphy => 'Powered by GIPHY';

  @override
  String get gif => 'GIF';

  @override
  String get noGifsFound => '找不到GIF';

  @override
  String get failedToLoadGifs => '載入GIF失敗';

  @override
  String get gifSent => 'GIF';

  @override
  String get filterCommunities => '篩選';

  @override
  String get reset => '重置';

  @override
  String get findYourPerfect => '找到你的完美';

  @override
  String get languagePartner => '語言夥伴';

  @override
  String get learningLanguageLabel => '學習語言';

  @override
  String get ageRange => '年齡範圍';

  @override
  String get genderPreference => '性別偏好';

  @override
  String get any => '任意';

  @override
  String get showNewUsersSubtitle => '顯示過去6天內加入的用戶';

  @override
  String get autoDetectLocation => '自動偵測我的位置';

  @override
  String get selectCountry => '選擇國家';

  @override
  String get anyCountry => '任意國家';

  @override
  String get loadingLanguages => '正在載入語言...';

  @override
  String minAge(int age) {
    return '最小: $age';
  }

  @override
  String maxAge(int age) {
    return '最大: $age';
  }

  @override
  String get captionRequired => '描述為必填項';

  @override
  String captionTooLong(int maxLength) {
    return '描述不能超過$maxLength個字元';
  }

  @override
  String get maximumImagesReached => '已達到最大圖片數量';

  @override
  String maximumImagesReachedDescription(int maxImages) {
    return '每則動態最多可以上傳$maxImages張圖片。';
  }

  @override
  String maximumImagesAddedPartial(int maxImages, int added) {
    return '最多$maxImages張圖片。僅新增了$added張。';
  }

  @override
  String get locationAccessRestricted => '位置存取受限';

  @override
  String get locationPermissionNeeded => '需要位置權限';

  @override
  String get addToYourMoment => '新增到你的動態';

  @override
  String get categoryLabel => '分類';

  @override
  String get languageLabel => '語言';

  @override
  String get scheduleOptional => '排程（選填）';

  @override
  String get scheduleForLater => '稍後發佈';

  @override
  String get addMore => '新增更多';

  @override
  String get howAreYouFeeling => '你現在感覺如何？';

  @override
  String get pleaseWaitOptimizingVideo => '請稍候，正在最佳化您的影片';

  @override
  String unsupportedVideoFormat(String formats) {
    return '不支援的格式。請使用：$formats';
  }

  @override
  String get chooseBackground => '選擇背景';

  @override
  String likedByXPeople(int count) {
    return '$count人按讚';
  }

  @override
  String xComments(int count) {
    return '$count則留言';
  }

  @override
  String get oneComment => '1則留言';

  @override
  String get addAComment => '新增留言...';

  @override
  String viewXReplies(int count) {
    return '查看$count則回覆';
  }

  @override
  String seenByX(int count) {
    return '$count人已看';
  }

  @override
  String xHoursAgo(int count) {
    return '$count小時前';
  }

  @override
  String xMinutesAgo(int count) {
    return '$count分鐘前';
  }

  @override
  String get repliedToYourStory => '回覆了你的限時動態';

  @override
  String mentionedYouInComment(String name) {
    return '$name在留言中提到了你';
  }

  @override
  String repliedToYourComment(String name) {
    return '$name回覆了你的留言';
  }

  @override
  String reactedToYourComment(String name) {
    return '$name對你的留言做出了反應';
  }

  @override
  String get addReaction => '新增反應';

  @override
  String get attachImage => '附加圖片';

  @override
  String get pickGif => '選擇GIF';

  @override
  String get textStory => '文字';

  @override
  String get typeYourStory => '寫下你的限動...';

  @override
  String get selectBackground => '選擇背景';

  @override
  String get highlightsTitle => '精選';

  @override
  String get highlightTitle => '精選標題';

  @override
  String get createNewHighlight => '新建';

  @override
  String get selectStories => '選擇限動';

  @override
  String get selectCover => '選擇封面';

  @override
  String get addText => '新增文字';

  @override
  String get fontStyleLabel => '字型樣式';

  @override
  String get textColorLabel => '文字顏色';

  @override
  String get dragToDelete => '拖曳至此刪除';

  @override
  String get noBlockedUsers => '沒有已封鎖的用戶';

  @override
  String get usersYouBlockWillAppearHere => '您封鎖的用戶會顯示在這裡';

  @override
  String unblockConfirm(String name) {
    return '您確定要解除封鎖 $name 嗎？';
  }

  @override
  String reasonLabel(String reason) {
    return '原因: $reason';
  }

  @override
  String blockedAgo(String time) {
    return '$time前封鎖';
  }

  @override
  String errorLoadingBlockedUsers(String error) {
    return '載入已封鎖用戶時發生錯誤: $error';
  }

  @override
  String get logoutConfirmMessage => '確定要從 Bananatalk 登出嗎？';

  @override
  String get loggingOut => '登出中…';

  @override
  String get quietHours => '免打擾時段';

  @override
  String get quietHoursEnable => '啟用免打擾時段';

  @override
  String get quietHoursSubtitle => '在特定時段內暫停非緊急通知';

  @override
  String get quietHoursStart => '開始時間';

  @override
  String get quietHoursEnd => '結束時間';

  @override
  String get quietHoursAllowUrgent => '允許緊急通知';

  @override
  String get quietHoursAllowUrgentSubtitle => '來自 VIP 夥伴的通話和訊息仍可送達';

  @override
  String get silencedByQuietHours => '已被免打擾時段靜音';

  @override
  String get silencedByCap => '已達每日上限而靜音';

  @override
  String get momentUpdatedSuccessfully => '動態更新成功';

  @override
  String get failedToDeleteMoment => '刪除動態失敗';

  @override
  String get failedToUpdateMoment => '更新動態失敗';

  @override
  String get mbtiUpdatedSuccessfully => 'MBTI已成功更新';

  @override
  String get pleaseSelectMbti => '請選擇一個MBTI類型';

  @override
  String get languageUpdatedSuccessfully => '語言已成功更新';

  @override
  String get bioHintCard => '精彩的個人簡介有助於他人更好地認識你。分享你的興趣愛好、語言或你正在尋找的內容。';

  @override
  String get bioCounterStartWriting => '開始寫作...';

  @override
  String get bioCounterABitMore => '再多寫一點會更好';

  @override
  String get bioCounterAlmostAtLimit => '快到字數上限了';

  @override
  String get bioCounterTooLong => '太長了';

  @override
  String get bioQuickStarters => '快速開始';

  @override
  String get rhPositive => 'Rh陽性';

  @override
  String get rhNegative => 'Rh陰性';

  @override
  String get rhPositiveDesc => '最常見';

  @override
  String get rhNegativeDesc => '萬能捐血者 / 稀有';

  @override
  String get yourBloodType => '你的血型';

  @override
  String get noBloodTypeSelected => '未選擇血型';

  @override
  String get tapTypeBelow => '點擊下方選擇血型';

  @override
  String get tapButtonToDetectLocation => '點擊下方按鈕偵測你的目前位置';

  @override
  String currentAddressLabel(String address) {
    return '目前：$address';
  }

  @override
  String get onlyCityCountryShown => '其他人只能看到你的城市和國家，確切座標保持私密。';

  @override
  String get updateLocationCta => '更新位置';

  @override
  String get enterYourName => '輸入你的名字';

  @override
  String get unsavedChanges => '你有未儲存的變更';

  @override
  String tapBelowToBrowseLanguages(int count) {
    return '點擊下方瀏覽 $count 種語言';
  }

  @override
  String get changeLanguage => '更改語言';

  @override
  String get browseLanguages => '瀏覽語言';

  @override
  String get yourLearningLanguageIsPrefix => '你正在學習的語言是';

  @override
  String get yourNativeLanguageIsPrefix => '你的母語是';

  @override
  String get profileCompleteProgress => '已完成';

  @override
  String get drawerPreferences => '偏好設定';

  @override
  String get drawerStorage => '儲存空間';

  @override
  String get drawerReports => '檢舉';

  @override
  String get drawerSupport => '支援';

  @override
  String get drawerAccount => '帳號';

  @override
  String get logoutConfirmBody => '確定要從 Bananatalk 登出嗎？';

  @override
  String get helpEmailSupport => '電子郵件支援';

  @override
  String get helpEmailSupportSubtitle => 'support@bananatalk.com';

  @override
  String get helpReportBug => '回報問題';

  @override
  String get helpReportBugSubtitle => '幫助我們改進 Bananatalk';

  @override
  String get helpFaqs => '常見問題';

  @override
  String get helpFaqsSubtitle => '常見問題解答';

  @override
  String get aboutDialogClose => '關閉';

  @override
  String get aboutBananatalkTagline => '與全球語言學習者連結，透過真實對話提升你的技能。';

  @override
  String get aboutCopyright => '© 2024 Bananatalk. 版權所有。';

  @override
  String get logoutFailedPrefix => '登出失敗';

  @override
  String get profileVisitorsTitle => '訪客';

  @override
  String get visitorStatistics => '訪客統計';

  @override
  String get visitorsTotalVisits => '總訪問次數';

  @override
  String get visitorsUniqueVisitors => '不重複訪客';

  @override
  String get visitorsToday => '今日';

  @override
  String get visitorsThisWeek => '本週';

  @override
  String get noVisitorsYet => '目前沒有訪客';

  @override
  String get noVisitorsYetSubtitle => '當有人造訪你的個人頁面時，\n他們將顯示在這裡';

  @override
  String get visitedViaSearch => '透過搜尋';

  @override
  String get visitedViaMoments => '透過動態';

  @override
  String get visitedViaChat => '透過聊天';

  @override
  String get visitedDirect => '直接造訪';

  @override
  String get visitorTrackingUnavailable => '訪客追蹤功能不可用。請更新後端。';

  @override
  String get visitorTrackingNotAvailableYet => '訪客追蹤功能暫不可用';

  @override
  String get noFollowersYetSubtitle => '開始與他人建立聯繫吧！';

  @override
  String get partnerButton => '夥伴';

  @override
  String get notFollowingAnyoneYetSubtitle => '追蹤他人以查看他們的動態！';

  @override
  String get unfollowButton => '取消追蹤';

  @override
  String get profileThemeTitle => '主題';

  @override
  String get themeAutoSwitch => '自動切換（跟隨系統）';

  @override
  String get themeSystemHint => '開啟後，應用程式將跟隨系統主題設定';

  @override
  String get themeLightMode => '淺色模式';

  @override
  String get themeDarkMode => '深色模式';

  @override
  String get myMoments => '我的動態';

  @override
  String get momentListView => '列表檢視';

  @override
  String get momentGridView => '格狀檢視';

  @override
  String get shareLanguageLearningJourney => '分享你的語言學習之旅！';

  @override
  String get deleteHighlightTitle => '刪除精選';

  @override
  String deleteHighlightConfirm(String title) {
    return '刪除「$title」？內部的故事不會被刪除。';
  }

  @override
  String get highlightDeletedSuccess => '精選已刪除';

  @override
  String get highlightNewBadge => '新';

  @override
  String get editMoment => '編輯動態';

  @override
  String get momentDescriptionLabel => '描述';

  @override
  String get momentImagesLabel => '圖片';

  @override
  String get noImagesYet => '目前沒有圖片';

  @override
  String get momentEnterDescription => '請輸入描述';

  @override
  String get momentUpdatedImageFailed => '動態已更新，但圖片上傳失敗';

  @override
  String get updateRequiredTitle => '需要更新';

  @override
  String get updateAvailableTitle => '有新版本';

  @override
  String get updateRequiredBody => '此版本的Bananatalk已不再受支援，請更新後繼續使用。';

  @override
  String get updateAvailableBody => 'Bananatalk新版本已發布，包含改進和錯誤修復。';

  @override
  String get updateNow => '立即更新';

  @override
  String get updateLater => '稍後';

  @override
  String get updateOpenStoreFailed => '無法開啟商店，請從App Store或Play Store進行更新。';

  @override
  String get rememberMe => '記住我';

  @override
  String get passwordWeak => '弱';

  @override
  String get passwordFair => '一般';

  @override
  String get passwordStrong => '強';

  @override
  String get passwordVeryStrong => '非常強';

  @override
  String get showPassword => '顯示密碼';

  @override
  String get hidePassword => '隱藏密碼';

  @override
  String stepProgress(int current, int total) {
    return '第 $current / $total 步';
  }

  @override
  String get usernameOptional => '使用者名稱 (選填)';

  @override
  String get usernameAvailable => '可用';

  @override
  String get usernameTaken => '已被使用';

  @override
  String get usernameNotAvailable => '無法使用';

  @override
  String get usernameInvalidFormat => '3-20個字元,字母、數字或底線';

  @override
  String get usernameHint => '@使用者名稱';

  @override
  String get enableBiometricTitle => '下次使用 Face ID 登入?';

  @override
  String get enableBiometricBody => '使用生物辨識登入,無需輸入密碼。';

  @override
  String get enableBiometricCta => '啟用';

  @override
  String get biometricSignInPrompt => '請驗證身分以登入 Bananatalk';

  @override
  String continueAs(String name) {
    return '以 $name 繼續';
  }

  @override
  String get addProfilePhotoTitle => '新增大頭貼';

  @override
  String get addProfilePhotoSkip => '暫時跳過';

  @override
  String get wavesTab => '招手';

  @override
  String get sendWave => '發送招手';

  @override
  String sendWaveTo(String name) {
    return '向$name發送招手';
  }

  @override
  String waveSent(String name) {
    return '已向$name發送招手';
  }

  @override
  String waveCooldown(String name, String time) {
    return '$time後可以再次向$name招手';
  }

  @override
  String get waveCouldntSend => '無法發送招手';

  @override
  String get itsAMatch => '配對成功！';

  @override
  String itsAMatchSubtitle(String name) {
    return '你和$name互相招手了';
  }

  @override
  String get sendAMessage => '發送訊息';

  @override
  String get waveQuickReplyHi => '嗨！';

  @override
  String get waveQuickReplyCool => '你看起來很酷';

  @override
  String get waveQuickReplyHey => '你好啊';

  @override
  String get waveQuickReplyChat => '一起聊吧';

  @override
  String get waveQuickReplyHello => '你好';

  @override
  String waveQuickReplyFromCountry(String country) {
    return '來自$country的問候！';
  }

  @override
  String get waveCustomMessage => '或者寫自己的訊息…';

  @override
  String get voiceRoomChat => '聊天';

  @override
  String get voiceRoomChatPlaceholder => '發送訊息…';

  @override
  String get voiceRoomChatEmpty => '尚無訊息 — 打個招呼吧';

  @override
  String get voiceRoomChatSend => '發送';

  @override
  String voiceRoomChatNewBadge(int n) {
    return '$n';
  }

  @override
  String get voiceRoomEnd => '結束房間';

  @override
  String get voiceRoomEndConfirm => '確定結束此房間？';

  @override
  String get voiceRoomEndConfirmBody => '所有人將斷開連線。';

  @override
  String get voiceRoomKick => '移出房間';

  @override
  String voiceRoomKickConfirm(String name) {
    return '移出$name？';
  }

  @override
  String get voiceRoomKicked => '已移出';

  @override
  String get voiceRoomYouAreHostNow => '您現在是主持人';

  @override
  String voiceRoomHostChanged(String name) {
    return '$name現在是主持人';
  }

  @override
  String get voiceRoomHostMenuTitle => '房間操作';

  @override
  String get voiceRoomViewProfile => '查看個人資料';

  @override
  String get voiceRoomReconnecting => '重新連線中…';

  @override
  String get voiceRoomReconnected => '已重新連線';

  @override
  String get voiceRoomEnded => '房間已結束';

  @override
  String get voiceRoomReconnectRetry => '重試';

  @override
  String get mutualInterests => '共同興趣';

  @override
  String interestsInCommon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個共同興趣',
      one: '1個共同興趣',
      zero: '尚無共同興趣',
    );
    return '$_temp0';
  }

  @override
  String get interestsInCommonSeeAll => '查看全部';

  @override
  String get interestsInCommonAddCta => '新增話題';

  @override
  String get interestsInCommonAddSubtitle => '在個人資料中新增話題，尋找共同點';

  @override
  String activeAgo(String time) {
    return '$time前活躍';
  }

  @override
  String get filterOnlineNow => '目前上線';

  @override
  String get filterAge => '年齡';

  @override
  String get filterGender => '性別';

  @override
  String get filterLanguages => '語言';

  @override
  String get filterCountry => '國家';

  @override
  String get filterTopics => '話題';

  @override
  String get filterLevel => '語言程度';

  @override
  String get filterToggles => '其他';

  @override
  String filterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count位夥伴匹配',
      one: '1位夥伴匹配',
      zero: '無匹配夥伴',
    );
    return '$_temp0';
  }

  @override
  String get filterClearAll => '全部清除';

  @override
  String get filterReset => '重置';

  @override
  String get filterApply => '套用';

  @override
  String get filterNewUsers => '僅新用戶';

  @override
  String get filterPrioritizeNearby => '優先附近';

  @override
  String get filterSheetTitle => '篩選';

  @override
  String get notificationPreferencesTitle => '通知';

  @override
  String get notificationPreferencesSubtitle => '選擇您希望接收的提醒';

  @override
  String get notifPrefChat => '新訊息';

  @override
  String get notifPrefWave => '揮手';

  @override
  String get notifPrefVoiceRoomStart => '語音房間邀請';

  @override
  String get notifPrefScheduledRoomReminder => '預約房間提醒';

  @override
  String get notifPrefFollowerMoment => '您追蹤的人的新動態';

  @override
  String get notifPrefVisitorAlert => '個人資料訪客';

  @override
  String get notifPrefMatchAlert => '互相揮手';

  @override
  String get notifResetToDefaults => '恢復預設設定';

  @override
  String get themeMode => '主題';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get languageSettingsRow => '語言';

  @override
  String get waveDailySummaryTitle => '有新的揮手等待';

  @override
  String waveDailySummaryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人向您揮手',
      one: '1人向您揮手',
    );
    return '$_temp0';
  }

  @override
  String get filterTopicsTitle => '話題';

  @override
  String get filterTopicsEmpty => '未選擇任何話題';

  @override
  String get storiesEmpty => '尚無故事';

  @override
  String get storiesLoadError => '無法載入故事';

  @override
  String get storiesRetry => '重試';

  @override
  String get storiesNoMore => '您已全部看完';

  @override
  String get createTextStoryTab => '文字';

  @override
  String get createImageStoryTab => '照片';

  @override
  String get createVideoStoryTab => '影片';

  @override
  String get enterTextHint => '點擊輸入';

  @override
  String get pickBackground => '背景';

  @override
  String get pickFontStyle => '字型';

  @override
  String get pickTextColor => '顏色';

  @override
  String get addEmoji => '新增表情符號';

  @override
  String get chooseFont => '選擇字型';

  @override
  String get chooseColor => '選擇顏色';

  @override
  String get dragToMove => '拖曳移位';

  @override
  String get pinchToScale => '捏合縮放';

  @override
  String get removeFromHighlight => '從精選移除';

  @override
  String get highlightDeleted => '精選已刪除';

  @override
  String get storySaved => '已儲存至您的故事';

  @override
  String get storyTooLong => '文字太長';

  @override
  String get storyPostFailed => '無法發佈故事';

  @override
  String get fontNormal => '一般';

  @override
  String get fontBold => '粗體';

  @override
  String get fontItalic => '斜體';

  @override
  String get fontHandwriting => '手寫體';

  @override
  String get pickDate => '選擇日期';

  @override
  String get pickTime => '選擇時間';

  @override
  String get upcomingRooms => '即將開始';

  @override
  String inHours(int h, int m) {
    return '$h小時$m分鐘後';
  }

  @override
  String inMinutes(int m) {
    return '$m分鐘後';
  }

  @override
  String get startsNow => '正在開始';

  @override
  String get iWillBeThere => '我會參加';

  @override
  String get cantMakeIt => '我無法參加';

  @override
  String rsvpCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人報名',
      one: '1人報名',
      zero: '尚無報名',
    );
    return '$_temp0';
  }

  @override
  String roomStartsIn1h(String title) {
    return '$title將在1小時後開始';
  }

  @override
  String roomStartsIn15min(String title) {
    return '$title將在15分鐘後開始';
  }

  @override
  String roomStarted(String title) {
    return '$title正在開始';
  }

  @override
  String get cancelRoom => '取消房間';

  @override
  String get muteAll => '全員靜音';

  @override
  String get mutedByHost => '主持人已將所有人靜音';

  @override
  String get muteAllConfirm => '將房間內所有人靜音？';

  @override
  String get categoryCasual => '輕鬆';

  @override
  String get categoryLanguagePractice => '語言練習';

  @override
  String get categoryTopic => '話題';

  @override
  String get categoryQA => '問答';

  @override
  String get pickCategory => '分類';

  @override
  String get sortRecentlyActive => '最近活躍';

  @override
  String visitedYourProfile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人造訪了您的個人頁面',
      one: '1人造訪了您的個人頁面',
    );
    return '$_temp0';
  }

  @override
  String get noRecentVisitors => '暫無近期訪客';

  @override
  String get viewArchive => '查看封存';

  @override
  String get archivedWaves => '已封存的Wave';

  @override
  String get noArchivedWaves => '暫無已封存的Wave';

  @override
  String get mutualInterestsMin => '共同興趣（最少）';

  @override
  String atLeastNTopics(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '至少$n個共同話題',
      one: '至少1個共同話題',
      zero: '不限',
    );
    return '$_temp0';
  }

  @override
  String get starterAskMoment => '詢問他們最近的難忘時刻';

  @override
  String get starterSayHi => '用他們的語言打招呼';

  @override
  String get starterCurious => '他們對什麼感到好奇？';

  @override
  String starterFromCountry(String country) {
    return '來自$country的您好！';
  }

  @override
  String starterPracticeLang(String language) {
    return '幫助他們練習$language！';
  }

  @override
  String get momentsLoadError => '無法載入動態';

  @override
  String get momentsRetry => '重試';

  @override
  String get recentTags => '最近的標籤';

  @override
  String get noRecentTags => '還沒有最近使用的標籤';

  @override
  String get hideMomentsFromUser => '隱藏此使用者的動態';

  @override
  String get momentsHidden => '此使用者的動態將被隱藏';

  @override
  String get unhideMoments => '顯示此使用者的動態';

  @override
  String momentsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已隱藏 $count 位使用者',
      one: '已隱藏 1 位使用者',
      zero: '沒有隱藏的使用者',
    );
    return '$_temp0';
  }

  @override
  String get momentSaveFailed => '無法儲存動態';

  @override
  String get tagAlreadyAdded => '標籤已新增';

  @override
  String get tagLimitReached => '已達到最大標籤數';

  @override
  String get hideThisUser => '隱藏此使用者的貼文';

  @override
  String get transcribeMessage => '轉寫';

  @override
  String get transcribing => '轉寫中…';

  @override
  String get transcriptionFailed => '無法轉寫訊息';

  @override
  String saveToVocabulary(String word) {
    return '將「$word」儲存到詞彙表';
  }

  @override
  String get addedToVocabulary => '已新增到您的詞彙表';

  @override
  String get alreadyInVocabulary => '已在您的詞彙表中';

  @override
  String get tapWordToSave => '長按單字以儲存';

  @override
  String get autoTranslateChatHint => '傳入的訊息將自動翻譯';

  @override
  String get noConversationsYet => '還沒有對話';

  @override
  String get chatRetry => '重試';

  @override
  String get learningHubTitle => '學習';

  @override
  String get learningCommonRetry => '重試';

  @override
  String get learningCommonContinue => '繼續';

  @override
  String get learningCommonAwesome => '太棒了！';

  @override
  String get learningErrorGeneric => '發生了一些問題';

  @override
  String get learningStreakCurrent => '目前連擊';

  @override
  String get learningStreakLongest => '最長連擊';

  @override
  String learningStreakDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count天',
    );
    return '$_temp0';
  }

  @override
  String learningStreakFreezeAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個凍結可用',
      zero: '沒有可用的凍結',
    );
    return '$_temp0';
  }

  @override
  String get learningStreakFreezeUse => '使用凍結';

  @override
  String get learningStreakFreezeDescription => '凍結在你缺席一天時保護你的連擊。';

  @override
  String get learningStreakFreezeProtected => '連擊已保護！';

  @override
  String get learningStreakMilestone7 => '7天連擊！';

  @override
  String get learningStreakMilestone30 => '30天連擊！';

  @override
  String get learningStreakMilestone100 => '100天連擊！';

  @override
  String get learningStreakMilestone365 => '365天連擊！';

  @override
  String get learningWeeklyDigestTitle => '本週';

  @override
  String learningWeeklyDigestXp(int xp) {
    return '獲得 $xp XP';
  }

  @override
  String learningWeeklyDigestLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count堂課',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestVocab(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '學習了$count個詞',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestDaysActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count天活躍',
    );
    return '$_temp0';
  }

  @override
  String get learningWeeklyDigestTopAchievement => '最佳成就';

  @override
  String learningWeeklyDigestTrendUp(int pct) {
    return '比上週增加$pct%';
  }

  @override
  String learningWeeklyDigestTrendDown(int pct) {
    return '比上週減少$pct%';
  }

  @override
  String get learningWeeklyDigestTrendFlat => '與上週相同';

  @override
  String get learningSrsDashboardTitle => '每日複習';

  @override
  String learningSrsDueToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今天$count張卡片',
      zero: '今天沒有卡片',
    );
    return '$_temp0';
  }

  @override
  String learningSrsDueTomorrow(int count) {
    return '明天$count張';
  }

  @override
  String learningSrsDueThisWeek(int count) {
    return '本週$count張';
  }

  @override
  String get learningSrsStartReview => '開始複習';

  @override
  String get learningSrsAllCaughtUp => '你已全部完成！';

  @override
  String get learningSrsKeepGoing => '繼續加油';

  @override
  String get learningLeaderboardXpTab => 'XP';

  @override
  String get learningLeaderboardStreakTab => '連擊';

  @override
  String get learningLeaderboardLanguageTab => '語言';

  @override
  String get learningLeaderboardFriendsTab => '好友';

  @override
  String get learningLeaderboardEmpty => '暫無排名';

  @override
  String get learningLeaderboardYouLabel => '你';

  @override
  String get learningLeaderboardFriendBadge => '好友';

  @override
  String get learningEmptyVocab => '新增你想記住的單字';

  @override
  String get learningEmptyLessons => '暫無課程';

  @override
  String get learningEmptyQuizzes => '暫無測驗';

  @override
  String get learningEmptyChallenges => '明天再來查看';

  @override
  String get learningEmptyAchievements => '獲得你的第一個成就';

  @override
  String get learningEmptySearchResults => '未找到結果';

  @override
  String learningXpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String get learningLevelUp => '升級了！';

  @override
  String learningLevelReached(String level) {
    return '你達到了 $level';
  }

  @override
  String get learningAchievementUnlocked => '成就解鎖';

  @override
  String get learningVocabularySearchHint => '搜尋詞彙';

  @override
  String get learningVocabularyFilterAll => '全部';

  @override
  String get learningVocabularyFilterNew => '新詞';

  @override
  String get learningVocabularyFilterLearning => '學習中';

  @override
  String get learningVocabularyFilterMastered => '已掌握';

  @override
  String get learningVocabularySortRecent => '最近';

  @override
  String get learningVocabularySortAlphabetical => '按字母';

  @override
  String get learningVocabularySortMastery => '掌握程度';

  @override
  String get learningVocabularyMasteryNew => '新詞';

  @override
  String get learningVocabularyMasteryLearning => '學習中';

  @override
  String get learningVocabularyMasteryMastered => '已掌握';

  @override
  String get learningProgressLevelLabel => '等級';

  @override
  String learningProgressXpToNextLevel(int xp) {
    return '距下一等級還需 $xp XP';
  }

  @override
  String get learningProgressWeeklyChartTitle => '最近7天';

  @override
  String get aiTutorPronounceLoading => '為你挑選一個句子…';

  @override
  String get aiTutorPronounceTapToRecord => '點按錄音';

  @override
  String get aiTutorPronounceTapToStop => '點按停止';

  @override
  String get aiTutorPronounceTranscribing => '正在聽你…';

  @override
  String get aiTutorPronounceTryAgain => '再試一次';

  @override
  String get aiTutorPronounceNext => '下一個';

  @override
  String get aiTutorPronounceUseYourOwn => '用我自己的 ✏️';

  @override
  String get aiTutorPronounceCustomHint => '輸入想練習的句子';

  @override
  String get aiTutorPronounceCustomCancel => '取消';

  @override
  String get aiTutorPronounceCustomUse => '使用';

  @override
  String get aiTutorPronounceQuitConfirm => '退出練習？進度不會儲存。';

  @override
  String get aiTutorPronounceQuitYes => '是';

  @override
  String get aiTutorPronounceQuitNo => '否';

  @override
  String aiTutorPronounceSentenceOf(int current, int total) {
    return '第 $current 句 / 共 $total 句';
  }

  @override
  String get aiTutorPronounceSummaryTitle => '練習完成';

  @override
  String get aiTutorPronounceSummaryAvg => '平均分';

  @override
  String get aiTutorPronounceSummaryWeak => '需練習的詞';

  @override
  String get aiTutorPronounceSaveClose => '儲存並關閉';

  @override
  String get aiTutorPronounceSaving => '儲存中…';

  @override
  String get aiTutorChipPronounce => '發音';

  @override
  String aiTutorPlanPronunciation(int count, int completed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '發音練習 ($completed/$count)',
      one: '發音練習 ($completed/1)',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorPronounceStartHeadline => '你想怎麼練習？';

  @override
  String get aiTutorPronounceStartSubhead => '選一個開始 5 句練習。';

  @override
  String get aiTutorPronounceStartAITitle => 'AI 生成句子';

  @override
  String get aiTutorPronounceStartAISubtitle => '按等級調整，針對你的難詞';

  @override
  String get aiTutorPronounceStartCustomTitle => '用自己的句子';

  @override
  String get aiTutorPronounceStartCustomSubtitle => '輸入或貼上你想掌握的句子';

  @override
  String aiTutorQuotaRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今日還剩 $count 次',
      one: '今日還剩 1 次',
    );
    return '$_temp0';
  }

  @override
  String get submit => '提交';

  @override
  String get exit => '退出';

  @override
  String get previous => '上一個';

  @override
  String get aiDailyPracticeTitle => '每日練習';

  @override
  String get aiDailyPracticeTranslateThis => '翻譯以下內容:';

  @override
  String get aiDailyPracticeSuggested => '建議:';

  @override
  String get aiDailyPracticeHint => '你的翻譯';

  @override
  String get aiLanguagesLoading => '語言仍在載入...';

  @override
  String get aiCopiedToClipboard => '已複製到剪貼簿';

  @override
  String get aiGrammarHint => '輸入要分析的文字...';

  @override
  String get aiGrammarSectionOriginal => '原文';

  @override
  String get aiGrammarSectionCorrected => '修正後的文字';

  @override
  String aiGrammarSectionIssues(int count) {
    return '發現的問題 ($count)';
  }

  @override
  String get aiGrammarSectionWell => '你做得好的';

  @override
  String get aiGrammarSectionSuggestions => '建議';

  @override
  String get aiGrammarSectionSummary => '摘要';

  @override
  String get aiLessonBuilderLabelLanguage => '語言';

  @override
  String get aiLessonBuilderLabelLevel => '等級';

  @override
  String get aiLessonBuilderTopicHint => '輸入主題（例如 \"美食與餐廳\"）';

  @override
  String aiLessonBuilderSaved(String title) {
    return '課程 \"$title\" 已儲存！';
  }

  @override
  String get aiLessonBuilderBackToLessons => '返回課程';

  @override
  String get aiTranslationHint => '輸入要翻譯的文字...';

  @override
  String get aiTranslationSavedToVocab => '已儲存到你的詞彙表';

  @override
  String aiTranslationCouldNotSave(String error) {
    return '無法儲存: $error';
  }

  @override
  String get aiQuizTitle => '小測驗';

  @override
  String get aiQuizFailedToGenerate => '生成測驗失敗';

  @override
  String get aiQuizSubmitTitle => '提交測驗？';

  @override
  String get aiQuizSubmitBody => '確定要提交你的答案嗎？';

  @override
  String get aiQuizExitTitle => '退出測驗？';

  @override
  String get aiQuizExitBody => '你的進度將丟失。';

  @override
  String get aiQuizAnswerHint => '輸入你的答案...';

  @override
  String get aiQuizTranslationHint => '輸入你的翻譯...';

  @override
  String get aiPronunciationPlayingAudio => '正在播放音訊...';

  @override
  String get aiPronunciationListenFirst => '先聽一遍';

  @override
  String get aiPronunciationHint => '輸入要練習的文字...';

  @override
  String aiTutorCouldNotLoad(String error) {
    return '無法載入導師: $error';
  }

  @override
  String aiTutorPlanUnavailable(String error) {
    return '計劃不可用: $error';
  }

  @override
  String get aiTutorReplay => '重播';

  @override
  String get aiScenariosTitle => '練習情境';

  @override
  String aiScenariosCouldNotLoad(String error) {
    return '無法載入情境: $error';
  }

  @override
  String get aiScenariosNoneAvailable => '暫無情境';

  @override
  String aiScenariosCouldNotStart(String error) {
    return '無法開始: $error';
  }

  @override
  String aiScenariosForYourLevel(String level) {
    return '適合你的等級 ($level)';
  }

  @override
  String get aiScenariosEasier => '更簡單 — 熱身';

  @override
  String get aiScenariosHarder => '更難 — 挑戰';

  @override
  String get aiRoleplayStillStarting => '情境仍在啟動 — 稍後再試。';

  @override
  String aiRoleplaySendFailed(String error) {
    return '傳送失敗: $error';
  }

  @override
  String get aiRoleplayCouldNotGrade => '這次無法評分 — 下次再試。';

  @override
  String get aiConversationHistoryCompleted => '已完成';

  @override
  String get aiConversationHistoryInProgress => '進行中';

  @override
  String get aiConversationMessageHint => '輸入訊息...';

  @override
  String get aiConversationTopicSpeak => '我說';

  @override
  String get aiConversationTopicPractice => '練習';

  @override
  String aiToolsVipUpgradeDescription(String feature) {
    return '升級到 VIP 解鎖 $feature！';
  }

  @override
  String get aiToolsVipBadge => 'VIP';

  @override
  String aiScenariosBannerPracticingIn(String language) {
    return '正在用$language練習';
  }

  @override
  String get aiScenariosBannerSubhead => '選擇符合你等級的情境，或挑戰高一級。';

  @override
  String get chatListSearchHint => '搜尋或輸入 @使用者名稱';

  @override
  String get chatListFilterAll => '全部';

  @override
  String get chatListFilterUnread => '未讀';

  @override
  String get chatListFilterOnline => '線上';

  @override
  String get chatListNewChat => '新建聊天';

  @override
  String get chatListNewChatByUsernameTooltip => '透過使用者名稱發起聊天';

  @override
  String get chatListFindUser => '查詢使用者';

  @override
  String chatListFindUserSearchTerm(String term) {
    return '查詢 @$term';
  }

  @override
  String get chatListDeleteConversation => '刪除會話';

  @override
  String chatListMediaTitle(String name) {
    return '與 $name 的媒體';
  }

  @override
  String get chatListMediaError => '媒體載入錯誤';

  @override
  String get chatDetailViewFullProfile => '查看完整個人檔案';

  @override
  String get chatMessageReply => '回覆';

  @override
  String get chatMessageCopy => '複製';

  @override
  String get chatMessageCorrect => '糾正';

  @override
  String get chatMessageTranslate => '翻譯';

  @override
  String get chatMessageSavePhrase => '儲存短語';

  @override
  String get chatMessageEdit => '編輯';

  @override
  String get chatMessageDelete => '刪除';

  @override
  String get chatMessageRetrySubtitle => '再次嘗試傳送';

  @override
  String get chatMessageRemoveSubtitle => '移除該訊息';

  @override
  String get chatWallpaperPreviewHello => '你好！👋';

  @override
  String get chatWallpaperPreviewHow => '最近怎樣？';

  @override
  String get chatGifSearchHint => '搜尋 GIF...';

  @override
  String get communitySearchHint => '搜尋或輸入 @使用者名稱';

  @override
  String communityUserNotFound(String name) {
    return '找不到使用者 @$name';
  }

  @override
  String get communityTabAll => '全部';

  @override
  String get communityTabGender => '性別';

  @override
  String get communityTabCity => '城市';

  @override
  String get communityRefresh => '重新整理';

  @override
  String get communityNoUsersFound => '未找到使用者';

  @override
  String communityUnblockConfirm(String name) {
    return '確定要取消封鎖 $name 嗎？';
  }

  @override
  String get communityUsernameCopied => '使用者名稱已複製！';

  @override
  String communityLocationDetected(String country) {
    return '位置: $country';
  }

  @override
  String get communityWaveLater => '稍後';

  @override
  String get communityAboutMBTI => 'MBTI';

  @override
  String get voiceRoomReactTooltip => '反應';

  @override
  String get momentsCancel => '取消';

  @override
  String get momentsNotNow => '現在不';

  @override
  String get commonOK => '確定';

  @override
  String commonError(String error) {
    return '錯誤: $error';
  }

  @override
  String get chatActiveJustNow => '剛剛活躍';

  @override
  String chatActiveMinAgo(int min) {
    return '$min 分鐘前活躍';
  }

  @override
  String get chatActiveHourAgo => '1 小時前活躍';

  @override
  String chatActiveHoursAgo(int hours) {
    return '$hours 小時前活躍';
  }

  @override
  String get chatActiveYesterday => '昨天活躍';

  @override
  String chatActiveDaysAgo(int days) {
    return '$days 天前活躍';
  }

  @override
  String get chatSayHiPrompt => '打個招呼，開始聊吧！';

  @override
  String get communityConversationStartersTitle => '破冰話題';

  @override
  String communityConversationStartersTopic(String topic) {
    return '你們都喜歡 $topic — 問問他/她最喜歡的！';
  }

  @override
  String get communityConversationStartersDefault => '打個招呼，介紹一下自己！';

  @override
  String get communityConversationChatAction => '聊天';

  @override
  String get communityConversationMessageCopied => '訊息已複製！貼上即可傳送。';

  @override
  String get communityConversationCopiedToast => '已複製！';

  @override
  String get communityLanguageMatchTitle => '語言匹配';

  @override
  String get communityLanguageMatchNative => '母語';

  @override
  String get communityLanguageMatchLearning => '在學';

  @override
  String get communityLanguageMatchPerfect => '完美的語言交換匹配！';

  @override
  String get communityLanguageMatchSameNative => '你們的母語相同';

  @override
  String get momentsFilterApply => '應用';

  @override
  String get momentsCreateAddTo => '新增到你的動態';

  @override
  String get momentsCreateCategory => '分類';

  @override
  String get momentsCreateLanguage => '語言';

  @override
  String get momentsCreateSchedule => '定時（可選）';

  @override
  String get momentsCreateScheduleForLater => '稍後釋出';

  @override
  String get momentsPrivacyPublic => '公開';

  @override
  String get momentsPrivacyFriends => '朋友';

  @override
  String get momentsPrivacyPrivate => '私密';

  @override
  String get splashTagline => '學習 · 聊天 · 相識';

  @override
  String get splashLoading => '載入中…';

  @override
  String get supportSheetGreeting => '你好，我是 Firdavs 👋';

  @override
  String get supportSheetStory => 'Bananatalk 完全由我一個人開發——每一個頁面、每一個功能、每一個深夜的漏洞修復。我的目標是幫助全球語言學習者相互連結和成長，我也不斷地新增功能來實現這個目標。\n\n如果 Bananatalk 對你有所幫助，哪怕是一杯小小的咖啡，也能讓我保持動力繼續開發。對於一個獨立開發者來說，每一份支持都意義重大。 🙏';

  @override
  String get supportSheetDonateButton => '透過 PayPal 捐款';

  @override
  String get supportSheetWatchAd => '觀看廣告以支持';

  @override
  String get occupation => '職業';

  @override
  String get school => '學校';

  @override
  String get occupationSearchHint => '搜尋職業';

  @override
  String get occupationSelectedLabel => '已選擇';

  @override
  String get occupationCustomLabel => '自訂';

  @override
  String get occupationNoMatches => '清單中沒有符合項目';

  @override
  String get occupationCatTech => '科技與軟體';

  @override
  String get occupationCatHealthcare => '醫療與健康';

  @override
  String get occupationCatEducation => '教育與學術';

  @override
  String get occupationCatBusiness => '商業與金融';

  @override
  String get occupationCatCreative => '創意與設計';

  @override
  String get occupationCatMedia => '媒體與傳播';

  @override
  String get occupationCatEngineering => '工程';

  @override
  String get occupationCatScience => '科學與研究';

  @override
  String get occupationCatLegal => '法律';

  @override
  String get occupationCatHospitality => '飯店與餐飲';

  @override
  String get occupationCatTrades => '技術工種';

  @override
  String get occupationCatTransport => '運輸與物流';

  @override
  String get occupationCatGovernment => '政府與公共服務';

  @override
  String get occupationCatRetail => '零售與客服';

  @override
  String get occupationCatAgriculture => '農業與環境';

  @override
  String get occupationCatSports => '運動與健身';

  @override
  String get occupationCatBeauty => '美容與個人護理';

  @override
  String get occupationCatRealEstate => '房地產與建築';

  @override
  String get occupationCatReligion => '宗教與靈性';

  @override
  String get occupationCatStudent => '學生';

  @override
  String get occupationCatOther => '其他';

  @override
  String get schoolHint => '例：國立臺灣大學、林肯高中';

  @override
  String get birthdate => '生日';

  @override
  String get birthdateSelectHelp => '請選擇您的生日';

  @override
  String get birthdateSelectPlaceholder => '選擇日期';

  @override
  String birthdateMinAgeError(int age) {
    return '您必須至少$age歲。';
  }

  @override
  String birthdateQuotaRemaining(int remaining, int max) {
    return '未來60天內還可以更改生日 $remaining/$max 次。';
  }

  @override
  String birthdateQuotaLocked(int max) {
    return '您已用完本60天週期內的全部$max次生日修改。';
  }

  @override
  String birthdateNextChangeOn(String date) {
    return '下次可修改時間：$date';
  }

  @override
  String get birthdateRateLimited => '生日在60天內最多只能修改3次。';

  @override
  String birthdateRateLimitedUntil(String date) {
    return '生日在60天內最多只能修改3次。請在$date重試。';
  }

  @override
  String get changePassword => '修改密碼';

  @override
  String get currentPassword => '目前密碼';

  @override
  String get newPasswordLabel => '新密碼';

  @override
  String get confirmNewPassword => '確認新密碼';

  @override
  String get currentPasswordHint => '輸入目前密碼';

  @override
  String get newPasswordHint => '至少8位，A-Z、a-z、0-9';

  @override
  String get passwordsDontMatch => '兩次密碼不一致。';

  @override
  String get newPasswordSameAsCurrent => '新密碼必須與目前密碼不同。';

  @override
  String get passwordChangedSuccess => '密碼修改成功';

  @override
  String get passwordRule8Chars => '至少8個字元';

  @override
  String get passwordRuleLowercase => '一個小寫字母';

  @override
  String get passwordRuleUppercase => '一個大寫字母';

  @override
  String get passwordRuleNumber => '一個數字';

  @override
  String get settingsAccountSection => '帳戶';

  @override
  String get changePasswordTileSubtitle => '更新您的帳戶密碼';

  @override
  String get occupationCustomTab => '自訂';

  @override
  String get occupationCustomTabHint => '找不到您的職業？請在此輸入。';

  @override
  String get occupationCustomInputHint => '例如：海洋生物學家、配音員';

  @override
  String get occupationCustomSaveCTA => '將此用作我的職業';

  @override
  String get vipSelectPlan => '選擇方案';

  @override
  String get vipBenefits => '權益';

  @override
  String get vipBestValue => '最超值';

  @override
  String get vipPlanMonth => '1個月';

  @override
  String get vipPlanThreeMonths => '3個月';

  @override
  String get vipPlanTwelveMonths => '12個月';

  @override
  String get vipOneTime => '一次性';

  @override
  String get vipNonVip => '非VIP';

  @override
  String get vipBenefitDailyTranslations => '每日翻譯次數';

  @override
  String get vipBenefitTranslationsLimit => '每天5次';

  @override
  String get vipBenefitUnlimited => '無限制';

  @override
  String get vipBenefitAdvancedFilters => '進階篩選';

  @override
  String get vipBenefitAdFree => '無廣告體驗';

  @override
  String get vipBenefitVipBadge => '個人檔案VIP徽章';

  @override
  String get vipBenefitPrioritySupport => '優先客服';

  @override
  String get vipBrandTitle => 'BananaTalk VIP';

  @override
  String get vipTagline => '通往全球連結的護照 —— 真實的對話、長久的友誼。';

  @override
  String get vipDisclosure => '若未在訂閱期結束前24小時取消，訂閱將自動續訂。費用將記入您的 iTunes 或 Google Play 帳戶。';

  @override
  String get vipLoginRequired => '請登入後繼續';

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
    return '省$pct%';
  }

  @override
  String vipPerMonth(String price) {
    return '$price/月';
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
  String get vipPaymentPlanSummary => '方案摘要';

  @override
  String get vipPaymentSelectMethod => '選擇付款方式';

  @override
  String get vipPaymentPurchaseAppStore => '透過 App Store 購買';

  @override
  String get vipPaymentPurchaseGooglePlay => '透過 Google Play 購買';

  @override
  String get vipPaymentSecureAppStore => '您的購買將透過 App Store 安全處理。';

  @override
  String get vipPaymentSecureGooglePlay => '您的購買將透過 Google Play 安全處理。';

  @override
  String get vipPaymentSubscriptionInfo => '訂閱資訊';

  @override
  String get vipPaymentInfoLabelTitle => '標題';

  @override
  String get vipPaymentInfoLabelLength => '期間';

  @override
  String get vipPaymentInfoLabelPrice => '價格';

  @override
  String get vipPaymentDisclosure => '完成購買即表示您同意我們的使用條款與隱私政策。若未在目前訂閱期結束前至少24小時取消，訂閱將自動續訂。';

  @override
  String get vipSuccessTitle => '歡迎成為VIP！';

  @override
  String get vipSuccessBody => '您的VIP訂閱已生效，盡享所有進階功能！';

  @override
  String get vipPendingTitle => '馬上就好';

  @override
  String get vipPendingBody => '您的訂閱正在處理中 —— 請稍候片刻再重新整理。';

  @override
  String get vipErrorPaymentTitle => '付款錯誤';

  @override
  String get vipErrorPurchaseTitle => '購買錯誤';

  @override
  String get vipErrorVerifyTitle => '購買驗證失敗';

  @override
  String get vipErrorPaymentFailed => '付款失敗';

  @override
  String get vipErrorBodyPrefix => '處理您的付款時發生錯誤：';

  @override
  String get vipErrorPurchaseCanceled => '購買已取消或失敗，請再試一次。';

  @override
  String get vipErrorVerifyServer => '無法在伺服器上驗證您的購買。請聯絡客服。';

  @override
  String get vipPlanLengthOneMonth => '1個月';

  @override
  String get vipPlanLengthThreeMonths => '3個月';

  @override
  String get vipPlanLengthOneYear => '1年';

  @override
  String vipPaymentPayPrice(String price) {
    return '支付 $price';
  }

  @override
  String get vipExpired => 'VIP已過期';

  @override
  String get vipMember => 'VIP會員';

  @override
  String get chatPhrasesMostUsed => '常用';

  @override
  String get chatPhrasesTopics => '話題';

  @override
  String get chatPhrasesAddPhrase => '新增短語';

  @override
  String get chatPhrasesChange => '換一批';

  @override
  String get chatPhrasesAddTitle => '新增短語';

  @override
  String get chatPhrasesAddHint => '輸入你常用的短語';

  @override
  String get chatPhrasesEmptyMostUsed => '尚未儲存任何短語。點一下 + 新增一則。';

  @override
  String get chatPhrasesDeleteTitle => '刪除這則短語？';

  @override
  String get filterVipPromoTitle => '更快找到契合的對象';

  @override
  String get filterVipPromoSubtitle => '升級 VIP，享受優先探索、進階篩選與無廣告聊天。';

  @override
  String get filterVipPromoCta => '升級 VIP';

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
  String get roomsNewRoom => '新建房間';

  @override
  String get roomsCouldNotLoad => '無法載入房間';

  @override
  String get roomsEmptyTitle => '尚無語言房間';

  @override
  String get roomsEmptySubtitle => '請稍後再來查看 —— 中心正在籌備中。';

  @override
  String get roomCreateTitle => '新建主題房間';

  @override
  String get roomCreateSubtitle => '在某種語言下開啟一場專注的聊天';

  @override
  String get roomNameLabel => '房間名稱';

  @override
  String get roomNameHint => '例如：每日口說練習';

  @override
  String get roomDescriptionLabel => '描述（選填）';

  @override
  String get roomDescriptionHint => '這個房間是關於什麼的？';

  @override
  String get roomCreateSubmit => '建立房間';

  @override
  String get roomNameRequired => '請輸入房間名稱';

  @override
  String get roomCreateError => '無法建立房間，請重試。';

  @override
  String get roomUsEnglish => '美式英語';

  @override
  String get roomUkEnglish => '英式英語';

  @override
  String get roomFailedLoadMessages => '載入訊息失敗';

  @override
  String get roomReportMessageTitle => '檢舉訊息';

  @override
  String get reportReasonSpam => '垃圾訊息';

  @override
  String get reportReasonHarassment => '騷擾或霸凌';

  @override
  String get reportReasonHateSpeech => '仇恨言論';

  @override
  String get reportReasonViolence => '暴力或威脅';

  @override
  String get reportReasonNudity => '裸露或色情內容';

  @override
  String get reportReasonFalseInformation => '不實資訊';

  @override
  String get roomReportSubmitted => '檢舉已提交';

  @override
  String get roomReportSubmitFailed => '提交檢舉失敗';

  @override
  String get roomLeaveHubTitle => '離開中心？';

  @override
  String roomLeaveHubMessage(String title) {
    return '之後你可以從房間目錄重新加入 $title。';
  }

  @override
  String get roomLeaveHubFailed => '離開中心失敗';

  @override
  String get roomJoinRequestSent => '請求已送出 —— 獲得核准後會通知你';

  @override
  String get roomJoinRequestFailed => '送出請求失敗';

  @override
  String roomRequestsMenuItem(int count) {
    return '請求（$count）';
  }

  @override
  String get roomViewMembers => '查看成員';

  @override
  String get roomLeaveHubMenuItem => '離開中心';

  @override
  String roomMemberOnlineCount(int members, int online) {
    return '$members 位成員 · $online 人在線';
  }

  @override
  String get roomBannedRequestMessage => '你已被移出此房間。送出請求以重新加入 —— 需由房主核准。';

  @override
  String get roomModeratedRequestMessage => '這是一個受管理的房間。送出加入請求以開始聊天。';

  @override
  String get roomRequestPending => '請求待處理';

  @override
  String get roomRequestToJoin => '請求加入';

  @override
  String get roomDailyPromptLabel => '今日話題';

  @override
  String get roomSomeoneFallback => '某人';

  @override
  String get roomRequestsLoadError => '無法載入加入請求';

  @override
  String get roomRequestApproved => '請求已核准';

  @override
  String get roomRequestDenied => '請求已拒絕';

  @override
  String get roomRequestApproveFailed => '核准請求失敗';

  @override
  String get roomRequestDenyFailed => '拒絕請求失敗';

  @override
  String roomRequestsAppBarTitle(String title) {
    return '$title · 請求';
  }

  @override
  String get roomRequestsEmpty => '沒有待處理的請求';

  @override
  String get roomRequestDeny => '拒絕';

  @override
  String get roomRequestApprove => '核准';

  @override
  String get roomMembersLoadError => '無法載入成員';

  @override
  String get roomRemoveBanTitle => '移除並封鎖成員？';

  @override
  String get roomRemoveTitle => '移除成員？';

  @override
  String roomRemoveBanConfirm(String name) {
    return '移除並封鎖 $name？除非你核准其請求，否則他們將無法重新加入。';
  }

  @override
  String roomRemoveConfirm(String name, String title) {
    return '將 $name 從 $title 中移除？';
  }

  @override
  String get roomRemoveBanButton => '移除並封鎖';

  @override
  String get roomRemoveButton => '移除';

  @override
  String get roomMemberRemovedBanned => '成員已被移除並封鎖';

  @override
  String get roomMemberRemoved => '成員已被移除';

  @override
  String get roomMemberRemoveFailed => '移除成員失敗';

  @override
  String get roomMemberMuted => '成員已被靜音';

  @override
  String get roomMemberUnmuted => '成員已解除靜音';

  @override
  String get roomMemberMuteFailed => '更新靜音狀態失敗';

  @override
  String roomMembersAppBarTitle(String title) {
    return '$title · 成員';
  }

  @override
  String get roomMembersEmpty => '尚無成員可顯示';

  @override
  String get roomMemberMutedLabel => '已靜音';

  @override
  String get roomMemberFallbackName => '成員';

  @override
  String get roomYourHub => '你的中心';

  @override
  String roomOnlineCount(int count) {
    return '$count 人在線';
  }

  @override
  String get roomNotAvailable => '此房間已不再可用。';

  @override
  String get roomGoToRooms => '前往房間';
}
