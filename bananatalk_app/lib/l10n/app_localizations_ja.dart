// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'BananaTalk';

  @override
  String get login => 'ログイン';

  @override
  String get signUp => '新規登録';

  @override
  String get email => 'メール';

  @override
  String get password => 'パスワード';

  @override
  String get forgotPassword => 'パスワードを忘れた？';

  @override
  String get or => 'または';

  @override
  String get signInWithGoogle => 'Googleでサインイン';

  @override
  String get signInWithApple => 'Appleでサインイン';

  @override
  String get signInWithFacebook => 'Facebookでサインイン';

  @override
  String get welcome => 'ようこそ';

  @override
  String get home => 'ホーム';

  @override
  String get messages => 'メッセージ';

  @override
  String get moments => 'モーメント';

  @override
  String get profile => 'プロフィール';

  @override
  String get settings => '設定';

  @override
  String get logout => 'ログアウト';

  @override
  String get language => '言語';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get autoTranslate => '自動翻訳';

  @override
  String get autoTranslateMessages => 'メッセージを自動翻訳';

  @override
  String get autoTranslateMoments => 'モーメントを自動翻訳';

  @override
  String get autoTranslateComments => 'コメントを自動翻訳';

  @override
  String get translate => '翻訳';

  @override
  String get translated => '翻訳済み';

  @override
  String get showOriginal => '原文を表示';

  @override
  String get showTranslation => '翻訳を表示';

  @override
  String get translating => '翻訳中...';

  @override
  String get translationFailed => '翻訳に失敗しました';

  @override
  String get noTranslationAvailable => '翻訳がありません';

  @override
  String translatedFrom(String language) {
    return '$languageから翻訳';
  }

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get share => '共有';

  @override
  String get like => 'いいね';

  @override
  String get comment => 'コメント';

  @override
  String get send => '送信';

  @override
  String get search => '検索';

  @override
  String get notifications => '通知';

  @override
  String get followers => 'フォロワー';

  @override
  String get following => 'フォロー中';

  @override
  String get posts => '投稿';

  @override
  String get visitors => '訪問者';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get success => '成功';

  @override
  String get tryAgain => '再試行';

  @override
  String get networkError => 'ネットワークエラー。接続を確認してください。';

  @override
  String get somethingWentWrong => '問題が発生しました';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get languageSettings => '言語設定';

  @override
  String get deviceLanguage => 'デバイス言語';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return 'お使いのデバイスは次の言語に設定されています：$flag $name';
  }

  @override
  String get youCanOverride => '以下でデバイス言語を上書きできます。';

  @override
  String languageChangedTo(String name) {
    return '言語が$nameに変更されました';
  }

  @override
  String get errorChangingLanguage => '言語の変更エラー';

  @override
  String get autoTranslateSettings => '自動翻訳設定';

  @override
  String get automaticallyTranslateIncomingMessages => '受信メッセージを自動的に翻訳';

  @override
  String get automaticallyTranslateMomentsInFeed => 'フィードのモーメントを自動的に翻訳';

  @override
  String get automaticallyTranslateComments => 'コメントを自動的に翻訳';

  @override
  String get translationServiceBeingConfigured => '翻訳サービスを設定中です。後でもう一度お試しください。';

  @override
  String get translationUnavailable => '翻訳が利用できません';

  @override
  String get showLess => '表示を減らす';

  @override
  String get showMore => 'もっと見る';

  @override
  String get comments => 'コメント';

  @override
  String get beTheFirstToComment => '最初にコメントしてください。';

  @override
  String get writeAComment => 'コメントを書く...';

  @override
  String get report => '報告';

  @override
  String get reportMoment => 'モーメントを報告';

  @override
  String get reportUser => 'ユーザーを報告';

  @override
  String get deleteMoment => 'モーメントを削除？';

  @override
  String get thisActionCannotBeUndone => 'この操作は取り消せません。';

  @override
  String get momentDeleted => 'モーメントが削除されました';

  @override
  String get editFeatureComingSoon => '編集機能は近日公開';

  @override
  String get userNotFound => 'ユーザーが見つかりません';

  @override
  String get cannotReportYourOwnComment => '自分のコメントを報告できません';

  @override
  String get profileSettings => 'プロフィール設定';

  @override
  String get editYourProfileInformation => 'プロフィール情報を編集';

  @override
  String get blockedUsers => 'ブロックしたユーザー';

  @override
  String get manageBlockedUsers => 'ブロックしたユーザーを管理';

  @override
  String get manageNotificationSettings => '通知設定を管理';

  @override
  String get privacySecurity => 'プライバシーとセキュリティ';

  @override
  String get controlYourPrivacy => 'プライバシーを管理';

  @override
  String get changeAppLanguage => 'アプリの言語を変更';

  @override
  String get appearance => '外観';

  @override
  String get themeAndDisplaySettings => 'テーマと表示設定';

  @override
  String get myReports => '私の報告';

  @override
  String get viewYourSubmittedReports => '送信した報告を表示';

  @override
  String get reportsManagement => '報告管理';

  @override
  String get manageAllReportsAdmin => 'すべての報告を管理（管理者）';

  @override
  String get legalPrivacy => '法的情報とプライバシー';

  @override
  String get termsPrivacySubscriptionInfo => '利用規約、プライバシー、サブスクリプション情報';

  @override
  String get helpCenter => 'ヘルプセンター';

  @override
  String get getHelpAndSupport => 'ヘルプとサポートを受ける';

  @override
  String get aboutBanaTalk => 'BanaTalkについて';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get permanentlyDeleteYourAccount => 'アカウントを完全に削除';

  @override
  String get loggedOutSuccessfully => '正常にログアウトしました';

  @override
  String get retry => '再試行';

  @override
  String get giftsLikes => 'ギフト/いいね';

  @override
  String get details => '詳細';

  @override
  String get to => '宛先';

  @override
  String get banaTalk => 'BanaTalk';

  @override
  String get community => 'コミュニティ';

  @override
  String get editProfile => 'プロフィールを編集';

  @override
  String yearsOld(String age) {
    return '$age歳';
  }

  @override
  String get searchConversations => '会話を検索...';

  @override
  String get visitorTrackingNotAvailable => '訪問者追跡機能はまだ利用できません。バックエンドの更新が必要です。';

  @override
  String get chatList => 'チャット一覧';

  @override
  String get languageExchange => '言語交換';

  @override
  String get nativeLanguage => '母国語';

  @override
  String get learning => '学習';

  @override
  String get notSet => '未設定';

  @override
  String get about => '情報';

  @override
  String get aboutMe => '自己紹介';

  @override
  String get photos => '写真';

  @override
  String get camera => 'カメラ';

  @override
  String get createMoment => 'モーメントを作成';

  @override
  String get addATitle => 'タイトルを追加...';

  @override
  String get whatsOnYourMind => '今何を考えていますか？';

  @override
  String get addTags => 'タグを追加';

  @override
  String get done => '完了';

  @override
  String get add => '追加';

  @override
  String get enterTag => 'タグを入力';

  @override
  String get post => '投稿';

  @override
  String get commentAddedSuccessfully => 'コメントが正常に追加されました';

  @override
  String get clearFilters => 'フィルターをクリア';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get enableNotifications => '通知を有効にする';

  @override
  String get turnAllNotificationsOnOrOff => 'すべての通知をオン/オフにする';

  @override
  String get notificationTypes => '通知タイプ';

  @override
  String get chatMessages => 'チャットメッセージ';

  @override
  String get getNotifiedWhenYouReceiveMessages => 'メッセージを受信したときに通知を受ける';

  @override
  String get likesAndCommentsOnYourMoments => 'モーメントへのいいねとコメント';

  @override
  String get whenPeopleYouFollowPostMoments => 'フォローしている人がモーメントを投稿したとき';

  @override
  String get friendRequests => '友達リクエスト';

  @override
  String get whenSomeoneFollowsYou => '誰かがあなたをフォローしたとき';

  @override
  String get profileVisits => 'プロフィール訪問';

  @override
  String get whenSomeoneViewsYourProfileVIP => '誰かがあなたのプロフィールを見たとき（VIP）';

  @override
  String get marketing => 'マーケティング';

  @override
  String get updatesAndPromotionalMessages => 'アップデートとプロモーションメッセージ';

  @override
  String get notificationPreferences => '通知設定';

  @override
  String get sound => 'サウンド';

  @override
  String get playNotificationSounds => '通知音を再生';

  @override
  String get vibration => 'バイブレーション';

  @override
  String get vibrateOnNotifications => '通知時にバイブレーション';

  @override
  String get showPreview => 'プレビューを表示';

  @override
  String get showMessagePreviewInNotifications => '通知にメッセージのプレビューを表示';

  @override
  String get mutedConversations => 'ミュートされた会話';

  @override
  String get conversation => '会話';

  @override
  String get unmute => 'ミュート解除';

  @override
  String get systemNotificationSettings => 'システム通知設定';

  @override
  String get manageNotificationsInSystemSettings => 'システム設定で通知を管理';

  @override
  String get errorLoadingSettings => '設定の読み込みエラー';

  @override
  String get unblockUser => 'ブロック解除';

  @override
  String get unblock => 'ブロック解除';

  @override
  String get goBack => '戻る';

  @override
  String get messageSendTimeout => 'メッセージ送信がタイムアウトしました。接続を確認してください。';

  @override
  String get failedToSendMessage => 'メッセージの送信に失敗しました';

  @override
  String get dailyMessageLimitExceeded => '1日のメッセージ上限を超えました。VIPにアップグレードして無制限のメッセージを。';

  @override
  String get cannotSendMessageUserMayBeBlocked => 'メッセージを送信できません。ユーザーがブロックされている可能性があります。';

  @override
  String get sessionExpired => 'セッションが期限切れです。再度ログインしてください。';

  @override
  String get sendThisSticker => 'このステッカーを送信しますか？';

  @override
  String get chooseHowYouWantToDeleteThisMessage => 'このメッセージの削除方法を選択してください：';

  @override
  String get deleteForEveryone => '全員から削除';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => 'あなたと受信者の両方からメッセージを削除します';

  @override
  String get deleteForMe => '自分のみ削除';

  @override
  String get removesTheMessageOnlyFromYourChat => 'あなたのチャットからのみメッセージを削除します';

  @override
  String get copy => 'コピー';

  @override
  String get reply => '返信';

  @override
  String get forward => '転送';

  @override
  String get moreOptions => 'その他のオプション';

  @override
  String get noUsersAvailableToForwardTo => '転送できるユーザーがいません';

  @override
  String get searchMoments => 'モーメントを検索...';

  @override
  String searchInChatWith(String name) {
    return '$nameとのチャットを検索';
  }

  @override
  String get typeAMessage => 'メッセージを入力...';

  @override
  String get enterYourMessage => 'メッセージを入力してください';

  @override
  String get detectYourLocation => '位置情報を検出';

  @override
  String get tapToUpdateLocation => 'タップして位置情報を更新';

  @override
  String get helpOthersFindYouNearby => '近くの人があなたを見つけやすくする';

  @override
  String get selectYourNativeLanguage => '母国語を選択';

  @override
  String get whichLanguageDoYouWantToLearn => 'どの言語を学びたいですか？';

  @override
  String get selectYourGender => '性別を選択';

  @override
  String get addACaption => 'キャプションを追加...';

  @override
  String get typeSomething => '何か入力...';

  @override
  String get gallery => 'ギャラリー';

  @override
  String get video => 'ビデオ';

  @override
  String get text => 'テキスト';

  @override
  String get provideMoreInformation => '詳細情報を入力...';

  @override
  String get searchByNameLanguageOrInterests => '名前、言語、または興味で検索...';

  @override
  String get addTagAndPressEnter => 'タグを追加してEnterを押す';

  @override
  String replyTo(String name) {
    return '$nameに返信...';
  }

  @override
  String get highlightName => 'ハイライト名';

  @override
  String get searchCloseFriends => '親しい友達を検索...';

  @override
  String get askAQuestion => '質問する...';

  @override
  String option(String number) {
    return 'オプション $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return 'なぜこの$typeを報告していますか？';
  }

  @override
  String get additionalDetailsOptional => '追加の詳細（オプション）';

  @override
  String get warningThisActionIsPermanent => '警告：この操作は永続的です！';

  @override
  String get deletingYourAccountWillPermanentlyRemove => 'アカウントを削除すると、以下が完全に削除されます：\n\n• プロフィールとすべての個人データ\n• すべてのメッセージと会話\n• すべてのモーメントとストーリー\n• VIPサブスクリプション（返金なし）\n• すべての接続とフォロワー\n\nこの操作は取り消せません。';

  @override
  String get clearAllNotifications => 'すべての通知をクリアしますか？';

  @override
  String get clearAll => 'すべてクリア';

  @override
  String get notificationDebug => '通知デバッグ';

  @override
  String get markAllRead => 'すべて既読にする';

  @override
  String get clearAll2 => 'すべてクリア';

  @override
  String get emailAddress => 'メールアドレス';

  @override
  String get username => 'ユーザー名';

  @override
  String get alreadyHaveAnAccount => 'すでにアカウントをお持ちですか？';

  @override
  String get login2 => 'ログイン';

  @override
  String get selectYourNativeLanguage2 => '母国語を選択';

  @override
  String get whichLanguageDoYouWantToLearn2 => 'どの言語を学びたいですか？';

  @override
  String get selectYourGender2 => '性別を選択';

  @override
  String get dateFormat => 'YYYY年MM月DD日';

  @override
  String get detectYourLocation2 => '位置情報を検出';

  @override
  String get tapToUpdateLocation2 => 'タップして位置情報を更新';

  @override
  String get helpOthersFindYouNearby2 => '近くの人があなたを見つけやすくする';

  @override
  String get couldNotOpenLink => 'リンクを開けませんでした';

  @override
  String get legalPrivacy2 => '法的情報とプライバシー';

  @override
  String get termsOfUseEULA => '利用規約（EULA）';

  @override
  String get viewOurTermsAndConditions => '利用規約を表示';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get howWeHandleYourData => 'データの取り扱いについて';

  @override
  String get emailNotifications => 'メール通知';

  @override
  String get receiveEmailNotificationsFromBananaTalk => 'BananaTalkからのメール通知を受け取る';

  @override
  String get weeklySummary => '週間サマリー';

  @override
  String get activityRecapEverySunday => '毎週日曜日のアクティビティまとめ';

  @override
  String get newMessages => '新しいメッセージ';

  @override
  String get whenYoureAwayFor24PlusHours => '24時間以上不在のとき';

  @override
  String get newFollowers => '新しいフォロワー';

  @override
  String get whenSomeoneFollowsYou2 => '誰かがあなたをフォローしたとき';

  @override
  String get securityAlerts => 'セキュリティアラート';

  @override
  String get passwordLoginAlerts => 'パスワードとログインアラート';

  @override
  String get unblockUser2 => 'ユーザーのブロックを解除';

  @override
  String get blockedUsers2 => 'ブロックしたユーザー';

  @override
  String get finalWarning => '⚠️ 最終警告';

  @override
  String get deleteForever => '完全に削除';

  @override
  String get deleteAccount2 => 'アカウントを削除';

  @override
  String get enterYourPassword => 'パスワードを入力してください';

  @override
  String get yourPassword => 'あなたのパスワード';

  @override
  String get typeDELETEToConfirm => 'DELETEと入力して確認';

  @override
  String get typeDELETEInCapitalLetters => '大文字でDELETEと入力';

  @override
  String sent(String emoji) {
    return '送信済み！';
  }

  @override
  String get replySent => '返信を送信しました！';

  @override
  String get deleteStory => 'ストーリーを削除しますか？';

  @override
  String get thisStoryWillBeRemovedPermanently => 'このストーリーは完全に削除されます。';

  @override
  String get noStories => 'ストーリーがありません';

  @override
  String views(String count) {
    return '$count回閲覧';
  }

  @override
  String get reportStory => 'ストーリーを報告';

  @override
  String get reply2 => '返信...';

  @override
  String get failedToPickImage => '画像の選択に失敗しました';

  @override
  String get failedToTakePhoto => '写真の撮影に失敗しました';

  @override
  String get failedToPickVideo => '動画の選択に失敗しました';

  @override
  String get pleaseEnterSomeText => 'テキストを入力してください';

  @override
  String get pleaseSelectMedia => 'メディアを選択してください';

  @override
  String get storyPosted => 'ストーリーを投稿しました！';

  @override
  String get textOnlyStoriesRequireAnImage => 'テキストのみのストーリーには画像が必要です';

  @override
  String get createStory => 'ストーリーを作成';

  @override
  String get change => '変更';

  @override
  String get userIdNotFound => 'ユーザーIDが見つかりません。再度ログインしてください。';

  @override
  String get pleaseSelectAPaymentMethod => '支払い方法を選択してください';

  @override
  String get startExploring => '探索を開始';

  @override
  String get close => '閉じる';

  @override
  String get payment => '支払い';

  @override
  String get upgradeToVIP => 'VIPにアップグレード';

  @override
  String get errorLoadingProducts => '製品の読み込みエラー';

  @override
  String get cancelVIPSubscription => 'VIPサブスクリプションをキャンセル';

  @override
  String get keepVIP => 'VIPを維持';

  @override
  String get cancelSubscription => 'サブスクリプションをキャンセル';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'VIPサブスクリプションが正常にキャンセルされました';

  @override
  String get vipStatus => 'VIPステータス';

  @override
  String get noActiveVIPSubscription => 'アクティブなVIPサブスクリプションがありません';

  @override
  String get subscriptionExpired => 'サブスクリプションの有効期限切れ';

  @override
  String get vipExpiredMessage => 'VIPサブスクリプションの有効期限が切れました。今すぐ更新して無制限の機能を引き続きお楽しみください！';

  @override
  String get expiredOn => '有効期限';

  @override
  String get renewVIP => 'VIPを更新';

  @override
  String get whatYoureMissing => '失っている機能';

  @override
  String get manageInAppStore => 'App Storeで管理';

  @override
  String get becomeVIP => 'VIPになる';

  @override
  String get unlimitedMessages => '無制限メッセージ';

  @override
  String get unlimitedProfileViews => '無制限プロフィール閲覧';

  @override
  String get prioritySupport => '優先サポート';

  @override
  String get advancedSearch => '高度な検索';

  @override
  String get profileBoost => 'プロフィールブースト';

  @override
  String get adFreeExperience => '広告なし体験';

  @override
  String get upgradeYourAccount => 'アカウントをアップグレード';

  @override
  String get moreMessages => 'より多くのメッセージ';

  @override
  String get moreProfileViews => 'より多くのプロフィール閲覧';

  @override
  String get connectWithFriends => '友達とつながる';

  @override
  String get reviewStarted => 'レビューを開始しました';

  @override
  String get reportResolved => '報告が解決されました';

  @override
  String get reportDismissed => '報告が却下されました';

  @override
  String get selectAction => 'アクションを選択';

  @override
  String get noViolation => '違反なし';

  @override
  String get contentRemoved => 'コンテンツが削除されました';

  @override
  String get userWarned => 'ユーザーに警告しました';

  @override
  String get userSuspended => 'ユーザーを停止しました';

  @override
  String get userBanned => 'ユーザーを禁止しました';

  @override
  String get addNotesOptional => 'メモを追加（オプション）';

  @override
  String get enterModeratorNotes => 'モデレーターメモを入力...';

  @override
  String get skip => 'スキップ';

  @override
  String get startReview => 'レビューを開始';

  @override
  String get resolve => '解決';

  @override
  String get dismiss => '却下';

  @override
  String get filterReports => '報告をフィルター';

  @override
  String get all => 'すべて';

  @override
  String get clear => 'クリア';

  @override
  String get apply => '適用';

  @override
  String get myReports2 => '私の報告';

  @override
  String get blockUser => 'ユーザーをブロック';

  @override
  String get block => 'ブロック';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => 'このユーザーもブロックしますか？';

  @override
  String get noThanks => 'いいえ、結構です';

  @override
  String get yesBlockThem => 'はい、ブロックする';

  @override
  String get reportUser2 => 'ユーザーを報告';

  @override
  String get submitReport => '報告を送信';

  @override
  String get addAQuestionAndAtLeast2Options => '質問と少なくとも2つのオプションを追加';

  @override
  String get addOption => 'オプションを追加';

  @override
  String get anonymousVoting => '匿名投票';

  @override
  String get create => '作成';

  @override
  String get typeYourAnswer => '回答を入力...';

  @override
  String get send2 => '送信';

  @override
  String get yourPrompt => 'プロンプト...';

  @override
  String get add2 => '追加';

  @override
  String get contentNotAvailable => 'コンテンツが利用できません';

  @override
  String get profileNotAvailable => 'プロフィールが利用できません';

  @override
  String get noMomentsToShow => '表示するモーメントがありません';

  @override
  String get storiesNotAvailable => 'ストーリーが利用できません';

  @override
  String get cantMessageThisUser => 'このユーザーにメッセージを送信できません';

  @override
  String get pleaseSelectAReason => '理由を選択してください';

  @override
  String get reportSubmitted => '報告が送信されました。コミュニティの安全維持にご協力いただきありがとうございます。';

  @override
  String get youHaveAlreadyReportedThisMoment => 'このモーメントはすでに報告済みです';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => '報告の理由を詳しく教えてください';

  @override
  String get errorSharing => '共有エラー';

  @override
  String get deviceInfo => 'デバイス情報';

  @override
  String get recommended => 'おすすめ';

  @override
  String get anyLanguage => 'すべての言語';

  @override
  String get noLanguagesFound => '言語が見つかりません';

  @override
  String get selectALanguage => '言語を選択';

  @override
  String get languagesAreStillLoading => '言語を読み込み中...';

  @override
  String get selectNativeLanguage => '母国語を選択';

  @override
  String get subscriptionDetails => 'サブスクリプション詳細';

  @override
  String get activeFeatures => 'アクティブな機能';

  @override
  String get legalInformation => '法的情報';

  @override
  String get termsOfUse => '利用規約';

  @override
  String get manageSubscription => 'サブスクリプションを管理';

  @override
  String get manageSubscriptionInSettings => 'サブスクリプションをキャンセルするには、設定 > [お名前] > サブスクリプションに移動してください。';

  @override
  String get contactSupportToCancel => 'サブスクリプションをキャンセルするには、サポートチームにお問い合わせください。';

  @override
  String get status => 'ステータス';

  @override
  String get active => 'アクティブ';

  @override
  String get plan => 'プラン';

  @override
  String get startDate => '開始日';

  @override
  String get endDate => '終了日';

  @override
  String get nextBillingDate => '次回請求日';

  @override
  String get autoRenew => '自動更新';

  @override
  String get pleaseLogInToContinue => '続行するにはログインしてください';

  @override
  String get purchaseCanceledOrFailed => '購入がキャンセルまたは失敗しました。もう一度お試しください。';

  @override
  String get maximumTagsAllowed => 'タグは最大5つまで';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => '動画を追加するには、先に画像を削除してください';

  @override
  String get unsupportedFormat => 'サポートされていない形式';

  @override
  String get errorProcessingVideo => '動画の処理中にエラー';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => '動画を録画するには、先に画像を削除してください';

  @override
  String get locationAdded => '位置情報が追加されました';

  @override
  String get failedToGetLocation => '位置情報の取得に失敗しました';

  @override
  String get notNow => '今はしない';

  @override
  String get videoUploadFailed => '動画のアップロードに失敗';

  @override
  String get skipVideo => '動画をスキップ';

  @override
  String get retryUpload => 'アップロードを再試行';

  @override
  String get momentCreatedSuccessfully => 'モーメントが作成されました';

  @override
  String get uploadingMomentInBackground => 'バックグラウンドでアップロード中...';

  @override
  String get failedToQueueUpload => 'アップロードのキューイングに失敗しました';

  @override
  String get viewProfile => 'プロフィールを見る';

  @override
  String get mediaLinksAndDocs => 'メディア、リンク、ドキュメント';

  @override
  String get wallpaper => '壁紙';

  @override
  String get userIdNotAvailable => 'ユーザーIDが利用できません';

  @override
  String get cannotBlockYourself => '自分自身をブロックすることはできません';

  @override
  String get chatWallpaper => 'チャット壁紙';

  @override
  String get wallpaperSavedLocally => '壁紙がローカルに保存されました';

  @override
  String get messageCopied => 'メッセージがコピーされました';

  @override
  String get forwardFeatureComingSoon => '転送機能は近日公開';

  @override
  String get momentUnsaved => 'モーメントの保存を解除しました';

  @override
  String get documentPickerComingSoon => 'ドキュメント選択は近日公開';

  @override
  String get contactSharingComingSoon => '連絡先共有は近日公開';

  @override
  String get featureComingSoon => '機能は近日公開';

  @override
  String get answerSent => '回答を送信しました！';

  @override
  String get noImagesAvailable => '画像がありません';

  @override
  String get mentionPickerComingSoon => 'メンション選択は近日公開';

  @override
  String get musicPickerComingSoon => '音楽選択は近日公開';

  @override
  String get repostFeatureComingSoon => 'リポスト機能は近日公開';

  @override
  String get addFriendsFromYourProfile => 'プロフィールから友達を追加';

  @override
  String get quickReplyAdded => 'クイック返信が追加されました';

  @override
  String get quickReplyDeleted => 'クイック返信が削除されました';

  @override
  String get linkCopied => 'リンクがコピーされました！';

  @override
  String get maximumOptionsAllowed => 'オプションは最大10個まで';

  @override
  String get minimumOptionsRequired => '最低2つのオプションが必要です';

  @override
  String get pleaseEnterAQuestion => '質問を入力してください';

  @override
  String get pleaseAddAtLeast2Options => '少なくとも2つのオプションを追加してください';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => 'クイズの正解を選択してください';

  @override
  String get correctionSent => '訂正を送信しました！';

  @override
  String get sort => '並べ替え';

  @override
  String get savedMoments => '保存したモーメント';

  @override
  String get unsave => '保存を解除';

  @override
  String get playingAudio => 'オーディオを再生中...';

  @override
  String get failedToGenerateQuiz => 'クイズの生成に失敗しました';

  @override
  String get failedToAddComment => 'コメントの追加に失敗しました';

  @override
  String get hello => 'こんにちは！';

  @override
  String get howAreYou => 'お元気ですか？';

  @override
  String get cannotOpen => '開けません';

  @override
  String get errorOpeningLink => 'リンクを開く際のエラー';

  @override
  String get saved => '保存しました';

  @override
  String get follow => 'フォロー';

  @override
  String get unfollow => 'フォロー解除';

  @override
  String get mute => 'ミュート';

  @override
  String get online => 'オンライン';

  @override
  String get offline => 'オフライン';

  @override
  String get lastSeen => '最終オンライン';

  @override
  String get justNow => 'たった今';

  @override
  String minutesAgo(String count) {
    return '$count分前';
  }

  @override
  String hoursAgo(String count) {
    return '$count時間前';
  }

  @override
  String get yesterday => '昨日';

  @override
  String get signInWithEmail => 'メールでサインイン';

  @override
  String get partners => 'パートナー';

  @override
  String get nearby => '近く';

  @override
  String get topics => 'トピック';

  @override
  String get waves => '挨拶';

  @override
  String get voiceRooms => 'ボイス';

  @override
  String get filters => 'フィルター';

  @override
  String get searchCommunity => '名前、言語、興味で検索...';

  @override
  String get bio => '自己紹介';

  @override
  String get noBioYet => '自己紹介がありません';

  @override
  String get languages => '言語';

  @override
  String get native => '母国語';

  @override
  String get interests => '興味';

  @override
  String get noMomentsYet => 'モーメントがありません';

  @override
  String get unableToLoadMoments => 'モーメントを読み込めません';

  @override
  String get map => '地図';

  @override
  String get mapUnavailable => '地図が利用できません';

  @override
  String get location => '場所';

  @override
  String get unknownLocation => '不明な場所';

  @override
  String get noImagesAvailable2 => '画像がありません';

  @override
  String get permissionsRequired => '権限が必要です';

  @override
  String get openSettings => '設定を開く';

  @override
  String get refresh => '更新';

  @override
  String get videoCall => 'ビデオ';

  @override
  String get voiceCall => '通話';

  @override
  String get message => 'メッセージ';

  @override
  String get pleaseLoginToFollow => 'フォローするにはログインしてください';

  @override
  String get pleaseLoginToCall => '通話するにはログインしてください';

  @override
  String get cannotCallYourself => '自分に電話することはできません';

  @override
  String get failedToFollowUser => 'フォローに失敗しました';

  @override
  String get failedToUnfollowUser => 'フォロー解除に失敗しました';

  @override
  String get areYouSureUnfollow => 'このユーザーのフォローを解除しますか？';

  @override
  String get areYouSureUnblock => 'このユーザーのブロックを解除しますか？';

  @override
  String get youFollowed => 'フォローしました';

  @override
  String get youUnfollowed => 'フォロー解除しました';

  @override
  String get alreadyFollowing => 'すでにフォロー中です';

  @override
  String get soon => '近日';

  @override
  String comingSoon(String feature) {
    return '$featureは近日公開予定です！';
  }

  @override
  String get muteNotifications => '通知をミュート';

  @override
  String get unmuteNotifications => 'ミュート解除';

  @override
  String get operationCompleted => '操作完了';

  @override
  String get couldNotOpenMaps => 'マップを開けません';

  @override
  String hasntSharedMoments(Object name) {
    return '$nameさんはまだモーメントを共有していません';
  }

  @override
  String messageUser(String name) {
    return '$nameにメッセージ';
  }

  @override
  String notFollowingUser(String name) {
    return '$nameさんをフォローしていませんでした';
  }

  @override
  String youFollowedUser(String name) {
    return '$nameさんをフォローしました';
  }

  @override
  String youUnfollowedUser(String name) {
    return '$nameさんのフォローを解除しました';
  }

  @override
  String unfollowUser(String name) {
    return '$nameのフォロー解除';
  }

  @override
  String get typing => '入力中';

  @override
  String get connecting => '接続中...';

  @override
  String daysAgo(int count) {
    return '$count日前';
  }

  @override
  String get maxTagsAllowed => 'タグは最大5個まで';

  @override
  String maxImagesAllowed(int count) {
    return '画像は最大$count枚まで';
  }

  @override
  String get pleaseRemoveImagesFirst => '動画を追加するには先に画像を削除してください';

  @override
  String get exchange3MessagesBeforeCall => '通話するには最低3つのメッセージを交換する必要があります';

  @override
  String mediaWithUser(String name) {
    return '$nameとのメディア';
  }

  @override
  String get errorLoadingMedia => 'メディアの読み込みエラー';

  @override
  String get savedMomentsTitle => '保存したモーメント';

  @override
  String get removeBookmark => 'ブックマークを削除しますか？';

  @override
  String get thisWillRemoveBookmark => 'このメッセージをブックマークから削除します。';

  @override
  String get remove => '削除';

  @override
  String get bookmarkRemoved => 'ブックマークを削除しました';

  @override
  String get bookmarkedMessages => 'ブックマークしたメッセージ';

  @override
  String get wallpaperSaved => '壁紙がローカルに保存されました';

  @override
  String get typeDeleteToConfirm => '確認のためDELETEと入力';

  @override
  String get storyArchive => 'ストーリーアーカイブ';

  @override
  String get newHighlight => '新しいハイライト';

  @override
  String get addToHighlight => 'ハイライトに追加';

  @override
  String get repost => 'リポスト';

  @override
  String get repostFeatureSoon => 'リポスト機能は近日公開予定';

  @override
  String get closeFriends => '親しい友達';

  @override
  String get addFriends => '友達を追加';

  @override
  String get highlights => 'ハイライト';

  @override
  String get createHighlight => 'ハイライトを作成';

  @override
  String get deleteHighlight => 'ハイライトを削除しますか？';

  @override
  String get editHighlight => 'ハイライトを編集';

  @override
  String get addMoreToStory => 'ストーリーに追加';

  @override
  String get noViewersYet => 'まだ閲覧者がいません';

  @override
  String get noReactionsYet => 'まだリアクションがありません';

  @override
  String get leaveRoom => '退出しますか？';

  @override
  String get areYouSureLeaveRoom => 'このボイスルームを退出しますか？';

  @override
  String get stay => '残る';

  @override
  String get leave => '退出';

  @override
  String get enableGPS => 'GPSを有効にする';

  @override
  String wavedToUser(String name) {
    return '$nameに挨拶しました！';
  }

  @override
  String get areYouSureFollow => 'フォローしますか';

  @override
  String get failedToLoadProfile => 'プロフィールの読み込みに失敗しました';

  @override
  String get noFollowersYet => 'まだフォロワーがいません';

  @override
  String get noFollowingYet => 'まだ誰もフォローしていません';

  @override
  String get searchUsers => 'ユーザーを検索...';

  @override
  String get noResultsFound => '結果が見つかりません';

  @override
  String get loadingFailed => '読み込み失敗';

  @override
  String get copyLink => 'リンクをコピー';

  @override
  String get shareStory => 'ストーリーを共有';

  @override
  String get thisWillDeleteStory => 'このストーリーは完全に削除されます。';

  @override
  String get storyDeleted => 'ストーリーが削除されました';

  @override
  String get addCaption => 'キャプションを追加...';

  @override
  String get yourStory => 'あなたのストーリー';

  @override
  String get sendMessage => 'メッセージを送信';

  @override
  String get replyToStory => 'ストーリーに返信...';

  @override
  String get viewAllReplies => 'すべての返信を見る';

  @override
  String get preparingVideo => '動画を準備中...';

  @override
  String videoOptimized(String size, String savings) {
    return '動画最適化完了：${size}MB（$savings%削減）';
  }

  @override
  String get failedToProcessVideo => '動画の処理に失敗しました';

  @override
  String get optimizingForBestExperience => '最高のストーリー体験のために最適化中';

  @override
  String get pleaseSelectImageOrVideo => 'ストーリー用の画像または動画を選択してください';

  @override
  String get storyCreatedSuccessfully => 'ストーリーが正常に作成されました！';

  @override
  String get uploadingStoryInBackground => 'バックグラウンドでストーリーをアップロード中...';

  @override
  String get storyCreationFailed => 'ストーリーの作成に失敗しました';

  @override
  String get pleaseCheckConnection => '接続を確認して再試行してください。';

  @override
  String get uploadFailed => 'アップロード失敗';

  @override
  String get tryShorterVideo => '短い動画を使用するか、後でもう一度お試しください。';

  @override
  String get shareMomentsThatDisappear => '24時間で消える瞬間を共有';

  @override
  String get photo => '写真';

  @override
  String get record => '録画';

  @override
  String get addSticker => 'スタンプを追加';

  @override
  String get poll => '投票';

  @override
  String get question => '質問';

  @override
  String get mention => 'メンション';

  @override
  String get music => '音楽';

  @override
  String get hashtag => 'ハッシュタグ';

  @override
  String get whoCanSeeThis => '誰が見れますか？';

  @override
  String get everyone => '全員';

  @override
  String get anyoneCanSeeStory => '誰でもこのストーリーを見れます';

  @override
  String get friendsOnly => '友達のみ';

  @override
  String get onlyFollowersCanSee => 'フォロワーのみ閲覧可能';

  @override
  String get onlyCloseFriendsCanSee => '親しい友達のみ閲覧可能';

  @override
  String get backgroundColor => '背景色';

  @override
  String get fontStyle => 'フォントスタイル';

  @override
  String get normal => '標準';

  @override
  String get bold => '太字';

  @override
  String get italic => '斜体';

  @override
  String get handwriting => '手書き';

  @override
  String get addLocation => '場所を追加';

  @override
  String get enterLocationName => '場所の名前を入力';

  @override
  String get addLink => 'リンクを追加';

  @override
  String get buttonText => 'ボタンテキスト';

  @override
  String get learnMore => '詳細を見る';

  @override
  String get addHashtags => 'ハッシュタグを追加';

  @override
  String get addHashtag => 'ハッシュタグを追加';

  @override
  String get sendAsMessage => 'メッセージとして送信';

  @override
  String get shareExternally => '外部に共有';

  @override
  String get checkOutStory => 'BananaTalkでこのストーリーをチェック！';

  @override
  String viewsTab(String count) {
    return '閲覧数 ($count)';
  }

  @override
  String reactionsTab(String count) {
    return 'リアクション ($count)';
  }

  @override
  String get processingVideo => '動画を処理中...';

  @override
  String get link => 'リンク';

  @override
  String unmuteUser(String name) {
    return '$nameのミュートを解除しますか？';
  }

  @override
  String get willReceiveNotifications => '新しいメッセージの通知を受け取ります。';

  @override
  String muteNotificationsFor(String name) {
    return '$nameの通知をミュート';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return '$nameのミュートを解除しました';
  }

  @override
  String notificationsMutedFor(String name) {
    return '$nameをミュートしました';
  }

  @override
  String get failedToUpdateMuteSettings => 'ミュート設定の更新に失敗しました';

  @override
  String get oneHour => '1時間';

  @override
  String get eightHours => '8時間';

  @override
  String get oneWeek => '1週間';

  @override
  String get always => '常に';

  @override
  String get failedToLoadBookmarks => 'ブックマークの読み込みに失敗しました';

  @override
  String get noBookmarkedMessages => 'ブックマークしたメッセージがありません';

  @override
  String get longPressToBookmark => 'メッセージを長押ししてブックマーク';

  @override
  String get thisWillRemoveFromBookmarks => 'メッセージがブックマークから削除されます。';

  @override
  String navigateToMessage(String name) {
    return '$nameとのチャットでメッセージを表示';
  }

  @override
  String bookmarkedOn(String date) {
    return '$dateにブックマーク';
  }

  @override
  String get voiceMessage => '音声メッセージ';

  @override
  String get document => 'ドキュメント';

  @override
  String get attachment => '添付ファイル';

  @override
  String get sendMeAMessage => 'メッセージを送る';

  @override
  String get shareWithFriends => '友達と共有';

  @override
  String get shareAnywhere => 'どこでも共有';

  @override
  String get emailPreferences => 'メール設定';

  @override
  String get receiveEmailNotifications => 'BananaTalkからのメール通知を受け取る';

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
  String get category => 'カテゴリー';

  @override
  String get mood => '気分';

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
  String get applyFilters => 'フィルターを適用';

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
