// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'BananaTalk';

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
  String get aboutBanaTalk => '关于 BanaTalk';

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
  String get banaTalk => 'BanaTalk';

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
  String get bloodType => 'Blood Type';

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
  String get sessionExpired => '会话已过期。请重新登录。';

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
  String get receiveEmailNotificationsFromBananaTalk => '接收来自 BananaTalk 的电子邮件通知';

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
  String get momentUnsaved => '动态已取消保存';

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
  String get exchange3MessagesBeforeCall => '您需要至少交换3条消息才能拨打电话';

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
  String get deleteHighlight => '删除精选？';

  @override
  String get editHighlight => '编辑精选';

  @override
  String get addMoreToStory => '添加更多到故事';

  @override
  String get noViewersYet => '暂无观看者';

  @override
  String get noReactionsYet => '暂无反应';

  @override
  String get leaveRoom => '离开房间？';

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
  String get checkOutStory => '在BananaTalk查看这个故事！';

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
  String get receiveEmailNotifications => '接收来自BananaTalk的邮件通知';

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
  String get category => '分类';

  @override
  String get mood => '心情';

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
  String get applyFilters => '应用筛选';

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

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw(): super('zh_TW');

  @override
  String get appName => 'BananaTalk';

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
  String get aboutBanaTalk => '關於 BanaTalk';

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
  String get banaTalk => 'BanaTalk';

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
  String get sessionExpired => '工作階段已過期。請重新登入。';

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
  String get receiveEmailNotificationsFromBananaTalk => '接收來自 BananaTalk 的電子郵件通知';

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
  String get momentUnsaved => '動態未儲存';

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
  String get exchange3MessagesBeforeCall => '您需要先交換至少 3 條訊息才能撥打電話給此用戶';

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
  String get storyArchive => '限時動態存檔';

  @override
  String get newHighlight => '新精選';

  @override
  String get addToHighlight => '新增至精選';

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
  String get deleteHighlight => '刪除精選？';

  @override
  String get editHighlight => '編輯精選';

  @override
  String get addMoreToStory => '新增更多至限時動態';

  @override
  String get noViewersYet => '尚無觀看者';

  @override
  String get noReactionsYet => '尚無反應';

  @override
  String get leaveRoom => '離開房間？';

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
  String get searchUsers => '搜尋用戶...';

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
  String get checkOutStory => '在 BananaTalk 上查看此限時動態！';

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
  String get receiveEmailNotifications => '接收來自 BananaTalk 的電子郵件通知';

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
  String get videoMustBeUnder1GB => '影片必須小於 1GB。';

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
}
