// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Bananatalk';

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
  String get more => '他';

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
  String get overview => '概要';

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
  String get deleteComment => 'Delete Comment?';

  @override
  String get commentDeleted => 'Comment deleted';

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
  String get clearCache => 'キャッシュをクリア';

  @override
  String get clearCacheSubtitle => 'ストレージ容量を解放';

  @override
  String get clearCacheDescription => 'キャッシュされたすべての画像、動画、音声ファイルがクリアされます。メディアを再ダウンロードする間、一時的にコンテンツの読み込みが遅くなる場合があります。';

  @override
  String get clearCacheHint => '画像や音声が正しく読み込まれない場合に使用してください。';

  @override
  String get clearingCache => 'キャッシュをクリア中...';

  @override
  String get cacheCleared => 'キャッシュが正常にクリアされました！画像が新しく読み込まれます。';

  @override
  String get clearCacheFailed => 'キャッシュのクリアに失敗しました';

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
  String get aboutBananatalk => 'Bananatalkについて';

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
  String get banaTalk => 'Bananatalk';

  @override
  String get chats => 'チャット';

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
  String get bloodType => 'Blood Type';

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
  String get receiveEmailNotificationsFromBananatalk => 'Bananatalkからのメール通知を受け取る';

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
  String get momentUnsaved => '保存から削除しました';

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
  String get deleteHighlight => 'ハイライトを削除';

  @override
  String get editHighlight => 'ハイライトを編集';

  @override
  String get addMoreToStory => 'ストーリーに追加';

  @override
  String get noViewersYet => 'まだ閲覧者がいません';

  @override
  String get noReactionsYet => 'まだリアクションがありません';

  @override
  String get leaveRoom => 'ルームを退出';

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
  String get checkOutStory => 'Bananatalkでこのストーリーをチェック！';

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
  String get receiveEmailNotifications => 'Bananatalkからのメール通知を受け取る';

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
  String get videoMustBeUnder1GB => '動画は1GB以下にしてください。';

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
  String get edited => '(編集済み)';

  @override
  String get now => '今';

  @override
  String weeksAgo(int count) {
    return '$count週間前';
  }

  @override
  String viewRepliesCount(int count) {
    return '── $count件の返信を表示';
  }

  @override
  String get hideReplies => '── 返信を非表示';

  @override
  String get saveMoment => 'モーメントを保存';

  @override
  String get removeFromSaved => '保存から削除';

  @override
  String get momentSaved => '保存しました';

  @override
  String get failedToSave => '保存に失敗しました';

  @override
  String get checkOutMoment => 'Bananatalkでこのモーメントをチェック!';

  @override
  String get failedToLoadMoments => 'モーメントの読み込みに失敗しました';

  @override
  String get noMomentsMatchFilters => 'フィルターに一致するモーメントがありません';

  @override
  String get beFirstToShareMoment => '最初のモーメントを共有しましょう！';

  @override
  String get tryDifferentSearch => '別の検索語を試してください';

  @override
  String get tryAdjustingFilters => 'フィルターを調整してみてください';

  @override
  String get noSavedMoments => '保存したモーメントはありません';

  @override
  String get tapBookmarkToSave => 'ブックマークアイコンをタップしてモーメントを保存';

  @override
  String get failedToLoadVideo => '動画の読み込みに失敗しました';

  @override
  String get titleRequired => 'タイトルは必須です';

  @override
  String titleTooLong(int max) {
    return 'タイトルは$max文字以下にしてください';
  }

  @override
  String get descriptionRequired => '説明は必須です';

  @override
  String descriptionTooLong(int max) {
    return '説明は$max文字以下にしてください';
  }

  @override
  String get scheduledDateMustBeFuture => '予約日は未来の日付にしてください';

  @override
  String get recent => '最新';

  @override
  String get popular => '人気';

  @override
  String get trending => 'トレンド';

  @override
  String get mostRecent => '最新順';

  @override
  String get mostPopular => '人気順';

  @override
  String get allTime => '全期間';

  @override
  String get today => '今日';

  @override
  String get thisWeek => '今週';

  @override
  String get thisMonth => '今月';

  @override
  String replyingTo(String userName) {
    return '$userNameに返信';
  }

  @override
  String get listView => 'リスト';

  @override
  String get quickMatch => 'クイックマッチ';

  @override
  String get onlineNow => 'オンライン';

  @override
  String speaksLanguage(String language) {
    return '$languageを話す';
  }

  @override
  String learningLanguage(String language) {
    return '$languageを学習中';
  }

  @override
  String get noPartnersFound => 'パートナーが見つかりません';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return '$learningのネイティブや$nativeを学んでいるユーザーが見つかりません。';
  }

  @override
  String get removeAllFilters => 'すべてのフィルターを解除';

  @override
  String get browseAllUsers => 'すべてのユーザーを見る';

  @override
  String get allCaughtUp => 'すべて確認済み！';

  @override
  String get loadingMore => '読み込み中...';

  @override
  String get findingMorePartners => 'もっと言語パートナーを探しています...';

  @override
  String get seenAllPartners => 'すべてのパートナーを確認しました。また後で確認してください！';

  @override
  String get startOver => '最初から';

  @override
  String get changeFilters => 'フィルターを変更';

  @override
  String get findingPartners => 'パートナーを探しています...';

  @override
  String get setLocationReminder => 'プロフィールで位置情報を設定すると、近くのユーザーが優先表示されます。';

  @override
  String get updateLocationReminder => 'プロフィール > 編集から位置情報を更新してください。';

  @override
  String get male => '男性';

  @override
  String get female => '女性';

  @override
  String get other => 'その他';

  @override
  String get browseMen => '男性を見る';

  @override
  String get browseWomen => '女性を見る';

  @override
  String get noMaleUsersFound => '男性ユーザーが見つかりません';

  @override
  String get noFemaleUsersFound => '女性ユーザーが見つかりません';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => '新規ユーザーのみ';

  @override
  String get showNewUsers => '過去6日以内に参加したユーザーを表示';

  @override
  String get prioritizeNearby => '近くを優先';

  @override
  String get showNearbyFirst => '近くのユーザーを優先表示';

  @override
  String get setLocationToEnable => 'この機能を有効にするには位置情報を設定してください';

  @override
  String get radius => '範囲';

  @override
  String get findingYourLocation => '位置を特定中...';

  @override
  String get enableLocationForDistance => '距離を確認するために位置情報を有効にする';

  @override
  String get enableLocationDescription => 'GPSを有効にするとパートナーまでの正確な距離が表示されます。';

  @override
  String get enableGps => 'GPSを有効にする';

  @override
  String get browseByCityCountry => '都市/国で探す';

  @override
  String get peopleNearby => '近くの人';

  @override
  String get noNearbyUsersFound => '近くにユーザーが見つかりません';

  @override
  String get tryExpandingSearch => '検索範囲を広げるか、後でもう一度お試しください。';

  @override
  String get exploreByCity => '都市で探す';

  @override
  String get exploreByCurrentCity => 'インタラクティブマップでユーザーを探し、世界中の言語パートナーを見つけましょう。';

  @override
  String get interactiveWorldMap => 'インタラクティブ世界地図';

  @override
  String get searchByCityName => '都市名で検索';

  @override
  String get seeUserCountsPerCountry => '国別ユーザー数を確認';

  @override
  String get upgradeToVip => 'VIPにアップグレード';

  @override
  String get searchByCity => '都市を検索...';

  @override
  String usersWorldwide(String count) {
    return '世界中の$count人';
  }

  @override
  String get noUsersFound => 'ユーザーが見つかりません';

  @override
  String get tryDifferentCity => '別の都市や国を試してみてください';

  @override
  String usersCount(String count) {
    return '$count人';
  }

  @override
  String get searchCountry => '国を検索...';

  @override
  String get wave => '挨拶';

  @override
  String get newUser => 'NEW';

  @override
  String get warningPermanent => '警告：この操作は元に戻せません！';

  @override
  String get deleteAccountWarning => 'アカウントを削除すると完全に削除されます：\n\n• プロフィールとすべての個人データ\n• すべてのメッセージと会話\n• すべてのモーメントとストーリー\n• VIPサブスクリプション（返金なし）\n• すべてのフォロワーとフォロー\n\nこの操作は元に戻せません。';

  @override
  String get requiredForEmailOnly => 'メールアカウントのみ必要';

  @override
  String get pleaseEnterPassword => 'パスワードを入力してください';

  @override
  String get typeDELETE => 'DELETEと入力して確認';

  @override
  String get mustTypeDELETE => '確認のためDELETEと入力してください';

  @override
  String get deletingAccount => 'アカウント削除中...';

  @override
  String get deleteMyAccountPermanently => 'アカウントを完全に削除';

  @override
  String get whatsYourNativeLanguage => 'あなたの母語は？';

  @override
  String get helpsMatchWithLearners => '学習者とのマッチングに役立ちます';

  @override
  String get whatAreYouLearning => '何を学んでいますか？';

  @override
  String get connectWithNativeSpeakers => 'ネイティブスピーカーとつなげます';

  @override
  String get selectLearningLanguage => '学習中の言語を選択してください';

  @override
  String get selectCurrentLevel => '現在のレベルを選択してください';

  @override
  String get beginner => '入門';

  @override
  String get elementary => '初級';

  @override
  String get intermediate => '中級';

  @override
  String get upperIntermediate => '中上級';

  @override
  String get advanced => '上級';

  @override
  String get proficient => '堪能';

  @override
  String get showingPartnersByDistance => '距離順でパートナーを表示中';

  @override
  String get enableLocationForResults => '距離ベースの結果を得るには位置情報を有効にしてください';

  @override
  String get enable => '有効にする';

  @override
  String get locationNotSet => '位置情報未設定';

  @override
  String get tellUsAboutYourself => '自己紹介をしましょう';

  @override
  String get justACoupleQuickThings => '簡単な質問です';

  @override
  String get gender => '性別';

  @override
  String get birthDate => '生年月日';

  @override
  String get selectYourBirthDate => '生年月日を選択';

  @override
  String get continueButton => '続ける';

  @override
  String get pleaseSelectGender => '性別を選択してください';

  @override
  String get pleaseSelectBirthDate => '生年月日を選択してください';

  @override
  String get mustBe18 => '18歳以上である必要があります';

  @override
  String get invalidDate => '無効な日付';

  @override
  String get almostDone => 'もう少しです！';

  @override
  String get addPhotoLocationForMatches => '写真と位置を追加してマッチングを増やしましょう';

  @override
  String get addProfilePhoto => 'プロフィール写真を追加';

  @override
  String get optionalUpTo6Photos => '任意 — 最大6枚';

  @override
  String get requiredUpTo6Photos => '必須 — 最大6枚';

  @override
  String get profilePhotoRequired => 'プロフィール写真を1枚以上追加してください';

  @override
  String get locationOptional => '位置情報は任意です — 後で追加できます';

  @override
  String get maximum6Photos => '最大6枚まで';

  @override
  String get tapToDetectLocation => 'タップして位置を検出';

  @override
  String get optionalHelpsNearbyPartners => '任意 — 近くのパートナーを見つけるのに役立ちます';

  @override
  String get startLearning => '学習を始めよう！';

  @override
  String get photoLocationOptional => '写真と位置は任意です — 後で追加できます';

  @override
  String get pleaseAcceptTerms => '利用規約に同意してください';

  @override
  String get iAgreeToThe => '同意します：';

  @override
  String get termsOfService => '利用規約';

  @override
  String get tapToSelectLanguage => 'タップして言語を選択';

  @override
  String yourLevelIn(String language) {
    return '$languageのレベル（任意）';
  }

  @override
  String get yourCurrentLevel => '現在のレベル';

  @override
  String get nativeCannotBeSameAsLearning => '母語と学習言語は同じにできません';

  @override
  String get learningCannotBeSameAsNative => '学習言語と母語は同じにできません';

  @override
  String stepOf(String current, String total) {
    return 'ステップ$current/$total';
  }

  @override
  String get continueWithGoogle => 'Googleで続ける';

  @override
  String get registerLink => '登録';

  @override
  String get pleaseEnterBothEmailAndPassword => 'メールアドレスとパスワードを入力してください';

  @override
  String get pleaseEnterValidEmail => '有効なメールアドレスを入力してください';

  @override
  String get loginSuccessful => 'ログイン成功！';

  @override
  String get stepOneOfTwo => 'ステップ1/2';

  @override
  String get createYourAccount => 'アカウント作成';

  @override
  String get basicInfoToGetStarted => '始めるための基本情報';

  @override
  String get emailVerifiedLabel => 'メール（認証済み）';

  @override
  String get nameLabel => '名前';

  @override
  String get yourDisplayName => '表示名';

  @override
  String get atLeast8Characters => '8文字以上';

  @override
  String get confirmPasswordHint => 'パスワード確認';

  @override
  String get nextButton => '次へ';

  @override
  String get pleaseEnterYourName => '名前を入力してください';

  @override
  String get pleaseEnterAPassword => 'パスワードを入力してください';

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get otherGender => 'その他';

  @override
  String get continueWithGoogleAccount => 'Googleアカウントで続けて\nスムーズな体験をお楽しみください';

  @override
  String get signingYouIn => 'サインイン中...';

  @override
  String get backToSignInMethods => 'サインイン方法に戻る';

  @override
  String get securedByGoogle => 'Googleのセキュリティ';

  @override
  String get dataProtectedEncryption => '業界標準の暗号化でデータが保護されています';

  @override
  String get welcomeCompleteProfile => 'ようこそ！プロフィールを完成させてください';

  @override
  String welcomeBackName(String name) {
    return 'おかえりなさい、$nameさん！';
  }

  @override
  String get continueWithAppleId => 'Apple IDで続けて\n安全な体験をお楽しみください';

  @override
  String get continueWithApple => 'Appleで続ける';

  @override
  String get securedByApple => 'Appleのセキュリティ';

  @override
  String get privacyProtectedApple => 'Apple サインインでプライバシーが保護されています';

  @override
  String get createAccount => 'アカウント作成';

  @override
  String get enterEmailToGetStarted => 'メールアドレスを入力して始めましょう';

  @override
  String get continueText => '続ける';

  @override
  String get pleaseEnterEmailAddress => 'メールアドレスを入力してください';

  @override
  String get verificationCodeSent => '認証コードをメールに送信しました！';

  @override
  String get forgotPasswordTitle => 'パスワードを忘れた';

  @override
  String get resetPasswordTitle => 'パスワードリセット';

  @override
  String get enterEmailForResetCode => 'メールアドレスを入力すると、パスワードリセットコードを送信します';

  @override
  String get sendResetCode => 'リセットコード送信';

  @override
  String get resetCodeSent => 'リセットコードをメールに送信しました！';

  @override
  String get rememberYourPassword => 'パスワードを覚えていますか？';

  @override
  String get verifyCode => 'コード確認';

  @override
  String get enterResetCode => 'リセットコード入力';

  @override
  String get weSentCodeTo => '6桁のコードを送信しました';

  @override
  String get pleaseEnterAll6Digits => '6桁すべて入力してください';

  @override
  String get codeVerifiedCreatePassword => 'コード確認完了！新しいパスワードを作成してください';

  @override
  String get verify => '確認';

  @override
  String get didntReceiveCode => 'コードが届きませんでしたか？';

  @override
  String get resend => '再送信';

  @override
  String resendWithTimer(String timer) {
    return '再送信（$timer秒）';
  }

  @override
  String get resetCodeResent => 'リセットコードを再送信しました！';

  @override
  String get verifyEmail => 'メール認証';

  @override
  String get verifyYourEmail => 'メールアドレスを認証';

  @override
  String get emailVerifiedSuccessfully => 'メール認証が完了しました！';

  @override
  String get verificationCodeResent => '認証コードを再送信しました！';

  @override
  String get createNewPassword => '新しいパスワード作成';

  @override
  String get enterNewPasswordBelow => '以下に新しいパスワードを入力してください';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get confirmPasswordLabel => 'パスワード確認';

  @override
  String get pleaseFillAllFields => 'すべてのフィールドを入力してください';

  @override
  String get passwordResetSuccessful => 'パスワードのリセットに成功しました！新しいパスワードでログインしてください';

  @override
  String get privacyTitle => 'プライバシー';

  @override
  String get profileVisibility => 'プロフィール表示設定';

  @override
  String get showCountryRegion => '国/地域を表示';

  @override
  String get showCountryRegionDesc => 'プロフィールに国を表示します';

  @override
  String get showCity => '都市を表示';

  @override
  String get showCityDesc => 'プロフィールに都市を表示します';

  @override
  String get showAge => '年齢を表示';

  @override
  String get showAgeDesc => 'プロフィールに年齢を表示します';

  @override
  String get showZodiacSign => '星座を表示';

  @override
  String get showZodiacSignDesc => 'プロフィールに星座を表示します';

  @override
  String get onlineStatusSection => 'オンライン状態';

  @override
  String get showOnlineStatus => 'オンライン状態を表示';

  @override
  String get showOnlineStatusDesc => 'オンライン時に他のユーザーに表示します';

  @override
  String get otherSettings => 'その他の設定';

  @override
  String get showGiftingLevel => 'ギフトレベルを表示';

  @override
  String get showGiftingLevelDesc => 'ギフトレベルバッジを表示します';

  @override
  String get birthdayNotifications => '誕生日通知';

  @override
  String get birthdayNotificationsDesc => '誕生日に通知を受け取ります';

  @override
  String get personalizedAds => 'パーソナライズ広告';

  @override
  String get personalizedAdsDesc => 'パーソナライズされた広告を許可します';

  @override
  String get saveChanges => '変更を保存';

  @override
  String get privacySettingsSaved => 'プライバシー設定が保存されました';

  @override
  String get locationSection => '位置情報';

  @override
  String get updateLocation => '位置情報を更新';

  @override
  String get updateLocationDesc => '現在の位置情報を更新します';

  @override
  String get currentLocation => '現在の位置';

  @override
  String get locationNotAvailable => '位置情報は利用できません';

  @override
  String get locationUpdated => '位置情報が更新されました';

  @override
  String get locationPermissionDenied => '位置情報の許可が拒否されました。設定で有効にしてください。';

  @override
  String get locationServiceDisabled => '位置情報サービスが無効です。有効にしてください。';

  @override
  String get updatingLocation => '位置情報を更新中...';

  @override
  String get locationCouldNotBeUpdated => '位置情報を更新できませんでした';

  @override
  String get incomingAudioCall => '音声通話着信';

  @override
  String get incomingVideoCall => 'ビデオ通話着信';

  @override
  String get outgoingCall => '発信中...';

  @override
  String get callRinging => '呼び出し中...';

  @override
  String get callConnecting => '接続中...';

  @override
  String get callConnected => '接続済み';

  @override
  String get callReconnecting => '再接続中...';

  @override
  String get callEnded => '通話終了';

  @override
  String get callFailed => '通話失敗';

  @override
  String get callMissed => '不在着信';

  @override
  String get callDeclined => '通話拒否';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => '応答';

  @override
  String get declineCall => '拒否';

  @override
  String get endCall => '終了';

  @override
  String get muteCall => 'ミュート';

  @override
  String get unmuteCall => 'ミュート解除';

  @override
  String get speakerOn => 'スピーカー';

  @override
  String get speakerOff => 'イヤホン';

  @override
  String get videoOn => 'ビデオオン';

  @override
  String get videoOff => 'ビデオオフ';

  @override
  String get switchCamera => 'カメラ切替';

  @override
  String get callPermissionDenied => '通話にはマイクの許可が必要です';

  @override
  String get cameraPermissionDenied => 'ビデオ通話にはカメラの許可が必要です';

  @override
  String get callConnectionFailed => '接続できませんでした。もう一度お試しください。';

  @override
  String get userBusy => '相手は通話中です';

  @override
  String get userOffline => '相手はオフラインです';

  @override
  String get callHistory => '通話履歴';

  @override
  String get noCallHistory => '通話履歴がありません';

  @override
  String get missedCalls => '不在着信';

  @override
  String get allCalls => 'すべての通話';

  @override
  String get callBack => '折り返し';

  @override
  String callAt(String time) {
    return '$timeに通話';
  }

  @override
  String get audioCall => '音声通話';

  @override
  String get voiceRoom => 'ボイスルーム';

  @override
  String get noVoiceRooms => 'アクティブなボイスルームはありません';

  @override
  String get createVoiceRoom => 'ボイスルームを作成';

  @override
  String get joinRoom => 'ルームに参加';

  @override
  String get leaveRoomConfirm => 'ルームを退出しますか？';

  @override
  String get leaveRoomMessage => '本当にこのルームを退出しますか？';

  @override
  String get roomTitle => 'ルームタイトル';

  @override
  String get roomTitleHint => 'ルームタイトルを入力';

  @override
  String get roomTopic => 'トピック';

  @override
  String get roomLanguage => '言語';

  @override
  String get roomHost => 'ホスト';

  @override
  String roomParticipants(int count) {
    return '$count人の参加者';
  }

  @override
  String roomMaxParticipants(int count) {
    return '最大$count人';
  }

  @override
  String get selectTopic => 'トピックを選択';

  @override
  String get raiseHand => '手を挙げる';

  @override
  String get lowerHand => '手を下げる';

  @override
  String get handRaisedNotification => '手を挙げました！ホストにリクエストが表示されます。';

  @override
  String get handLoweredNotification => '手を下げました';

  @override
  String get muteParticipant => '参加者をミュート';

  @override
  String get kickParticipant => 'ルームから削除';

  @override
  String get promoteToCoHost => '共同ホストに昇格';

  @override
  String get endRoomConfirm => 'ルームを終了しますか？';

  @override
  String get endRoomMessage => 'これにより、すべての参加者のルームが終了します。';

  @override
  String get roomEnded => 'ホストがルームを終了しました';

  @override
  String get youWereRemoved => 'ルームから削除されました';

  @override
  String get roomIsFull => 'ルームは満員です';

  @override
  String get roomChat => 'ルームチャット';

  @override
  String get noMessages => 'まだメッセージはありません';

  @override
  String get typeMessage => 'メッセージを入力...';

  @override
  String get voiceRoomsDescription => 'ライブ会話に参加してスピーキングを練習';

  @override
  String liveRoomsCount(int count) {
    return '$countライブ';
  }

  @override
  String get noActiveRooms => 'アクティブなルームはありません';

  @override
  String get noActiveRoomsDescription => '最初にボイスルームを作成して、他の人と話す練習をしましょう！';

  @override
  String get startRoom => 'ルームを開始';

  @override
  String get createRoom => 'ルームを作成';

  @override
  String get roomCreated => 'ルームが正常に作成されました！';

  @override
  String get failedToCreateRoom => 'ルームの作成に失敗しました';

  @override
  String get errorLoadingRooms => 'ルームの読み込みエラー';

  @override
  String get pleaseEnterRoomTitle => 'ルームタイトルを入力してください';

  @override
  String get startLiveConversation => 'ライブ会話を開始';

  @override
  String get maxParticipants => '最大参加者数';

  @override
  String nPeople(int count) {
    return '$count人';
  }

  @override
  String hostedBy(String name) {
    return '$nameがホスト';
  }

  @override
  String get liveLabel => 'ライブ';

  @override
  String get joinLabel => '参加';

  @override
  String get fullLabel => '満員';

  @override
  String get justStarted => '開始したばかり';

  @override
  String get allLanguages => 'すべての言語';

  @override
  String get allTopics => 'すべてのトピック';

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
  String get you => 'あなた';

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
  String get dataAndStorage => 'データとストレージ';

  @override
  String get manageStorageAndDownloads => 'ストレージとダウンロードを管理';

  @override
  String get storageUsage => 'ストレージ使用量';

  @override
  String get totalCacheSize => 'キャッシュ合計サイズ';

  @override
  String get imageCache => '画像キャッシュ';

  @override
  String get voiceMessagesCache => '音声メッセージ';

  @override
  String get videoCache => '動画キャッシュ';

  @override
  String get otherCache => 'その他のキャッシュ';

  @override
  String get autoDownloadMedia => 'メディアの自動ダウンロード';

  @override
  String get currentNetwork => '現在のネットワーク';

  @override
  String get images => '画像';

  @override
  String get videos => '動画';

  @override
  String get voiceMessagesShort => '音声メッセージ';

  @override
  String get documentsLabel => 'ドキュメント';

  @override
  String get wifiOnly => 'Wi-Fiのみ';

  @override
  String get never => 'しない';

  @override
  String get clearAllCache => 'すべてのキャッシュを削除';

  @override
  String get allCache => 'すべてのキャッシュ';

  @override
  String get clearAllCacheConfirmation => 'すべてのキャッシュされた画像、音声メッセージ、動画、その他のファイルが削除されます。アプリは一時的にコンテンツの読み込みが遅くなる場合があります。';

  @override
  String clearCacheConfirmationFor(String category) {
    return '$categoryを削除しますか？';
  }

  @override
  String storageToFree(String size) {
    return '$sizeが解放されます';
  }

  @override
  String get calculating => '計算中...';

  @override
  String get noDataToShow => '表示するデータがありません';

  @override
  String get profileCompletion => 'プロフィール完成度';

  @override
  String get justGettingStarted => '始めたばかり';

  @override
  String get lookingGood => 'いい感じ！';

  @override
  String get almostThere => 'もう少し！';

  @override
  String addMissingFields(String fields, Object field) {
    return '追加: $fields';
  }

  @override
  String get profilePicture => 'プロフィール写真';

  @override
  String get nativeSpeaker => 'ネイティブスピーカー';

  @override
  String peopleInterestedInTopic(Object count) {
    return 'このトピックに興味がある人';
  }

  @override
  String get beFirstToAddTopic => 'このトピックを興味に追加する最初の人になりましょう！';

  @override
  String get recentMoments => '最近のモーメント';

  @override
  String get seeAll => 'すべて見る';

  @override
  String get study => '学習';

  @override
  String get followerMoments => 'フォロワーモーメント';

  @override
  String get whenPeopleYouFollowPost => 'フォロー中の人が新しいモーメントを投稿したとき';

  @override
  String get noNotificationsYet => 'まだ通知がありません';

  @override
  String get whenYouGetNotifications => '通知が届くとここに表示されます';

  @override
  String get failedToLoadNotifications => '通知の読み込みに失敗しました';

  @override
  String get clearAllNotificationsConfirm => 'すべての通知を削除しますか？この操作は元に戻せません。';

  @override
  String get tapToChange => 'タップして変更';

  @override
  String get noPictureSet => '写真未設定';

  @override
  String get nameAndGender => '名前と性別';

  @override
  String get languageLevel => '言語レベル';

  @override
  String get personalInformation => '個人情報';

  @override
  String get mbti => 'MBTI';

  @override
  String get topicsOfInterest => '興味のあるトピック';

  @override
  String get levelBeginner => '入門';

  @override
  String get levelElementary => '初級';

  @override
  String get levelIntermediate => '中級';

  @override
  String get levelUpperIntermediate => '中上級';

  @override
  String get levelAdvanced => '上級';

  @override
  String get levelProficient => '堪能';

  @override
  String get selectYourLevel => 'レベルを選択';

  @override
  String howWellDoYouSpeak(String language) {
    return '$languageをどのくらい話せますか？';
  }

  @override
  String get theLanguage => '言語';

  @override
  String languageLevelSetTo(String level) {
    return '言語レベルが$levelに設定されました';
  }

  @override
  String get failedToUpdate => '更新に失敗しました';

  @override
  String get profileUpdatedSuccessfully => 'プロフィールを正常に更新しました';

  @override
  String get genderRequired => '性別（必須）';

  @override
  String get editHometown => '出身地を編集';

  @override
  String get useCurrentLocation => '現在地を使用';

  @override
  String get detecting => '検出中...';

  @override
  String get getCurrentLocation => '現在地を取得';

  @override
  String get country => '国';

  @override
  String get city => '都市';

  @override
  String get coordinates => '座標';

  @override
  String get noLocationDetectedYet => 'まだ位置が検出されていません。';

  @override
  String get detected => '検出済み';

  @override
  String get savedHometown => '出身地が保存されました';

  @override
  String get locationServicesDisabled => '位置情報サービスが無効です。有効にしてください。';

  @override
  String get locationPermissionPermanentlyDenied => '位置情報の許可が永久に拒否されています。';

  @override
  String get unknown => '不明';

  @override
  String get editBio => '自己紹介を編集';

  @override
  String get bioUpdatedSuccessfully => '自己紹介が正常に更新されました';

  @override
  String get tellOthersAboutYourself => 'あなた自身について教えてください...';

  @override
  String charactersCount(int count) {
    return '$count/500文字';
  }

  @override
  String get selectYourMbti => 'MBTIを選択';

  @override
  String get myBloodType => '私の血液型';

  @override
  String get pleaseSelectABloodType => '血液型を選択してください';

  @override
  String get bloodTypeSavedSuccessfully => '血液型を正常に保存しました';

  @override
  String get hometownSavedSuccessfully => '出身地を正常に保存しました';

  @override
  String get nativeLanguageRequired => '母国語（必須）';

  @override
  String get languageToLearnRequired => '学習言語（必須）';

  @override
  String get nativeLanguageCannotBeSame => '母国語は学習中の言語と同じにできません';

  @override
  String get learningLanguageCannotBeSame => '学習言語は母国語と同じにできません';

  @override
  String get pleaseSelectALanguage => '言語を選択してください';

  @override
  String get editInterests => '興味を編集';

  @override
  String maxTopicsAllowed(int count) {
    return '最大$count個のトピックまで選択可能';
  }

  @override
  String get topicsUpdatedSuccessfully => 'トピックが正常に更新されました！';

  @override
  String get failedToUpdateTopics => 'トピックの更新に失敗しました';

  @override
  String selectedCount(int count, int max) {
    return '$count/$max選択済み';
  }

  @override
  String get profilePictures => 'プロフィール写真';

  @override
  String get addImages => '画像を追加';

  @override
  String get selectUpToImages => '最大5枚の画像を選択';

  @override
  String get takeAPhoto => '写真を撮影';

  @override
  String get removeImage => '画像を削除';

  @override
  String get removeImageConfirm => 'この画像を削除しますか？';

  @override
  String get removeAll => 'すべて削除';

  @override
  String get removeAllSelectedImages => '選択した画像をすべて削除';

  @override
  String get removeAllSelectedImagesConfirm => '選択したすべての画像を削除しますか？';

  @override
  String get yourProfilePictureWillBeKept => '既存のプロフィール写真は保持されます';

  @override
  String get removeAllImages => 'すべての画像を削除';

  @override
  String get removeAllImagesConfirm => 'すべてのプロフィール写真を削除しますか？';

  @override
  String get currentImages => '現在の画像';

  @override
  String get newImages => '新しい画像';

  @override
  String get addMoreImages => '画像をさらに追加';

  @override
  String uploadImages(int count) {
    return '$count枚の画像をアップロード';
  }

  @override
  String get imageRemovedSuccessfully => '画像が正常に削除されました';

  @override
  String get imagesUploadedSuccessfully => '画像が正常にアップロードされました';

  @override
  String get selectedImagesCleared => '選択した画像がクリアされました';

  @override
  String get extraImagesRemovedSuccessfully => '余分な画像が正常に削除されました';

  @override
  String get mustKeepAtLeastOneProfilePicture => 'プロフィール写真は最低1枚必要です';

  @override
  String get noProfilePicturesToRemove => '削除するプロフィール写真がありません';

  @override
  String get authenticationTokenNotFound => '認証トークンが見つかりません';

  @override
  String get saveChangesQuestion => '変更を保存しますか？';

  @override
  String youHaveUnuploadedImages(int count) {
    return '$count枚の画像が選択されていますがアップロードされていません。今すぐアップロードしますか？';
  }

  @override
  String get discard => '破棄';

  @override
  String get upload => 'アップロード';

  @override
  String maxImagesInfo(int max, int current) {
    return '最大$max枚の画像をアップロードできます。現在: $current/$max\n一度に最大5枚の画像。';
  }

  @override
  String canOnlyAddMoreImages(int count, int max) {
    return 'あと$count枚しか追加できません。最大は$max枚です。';
  }

  @override
  String get maxImagesPerUpload => '一度に最大5枚の画像しかアップロードできません。最初の5枚のみが追加されます。';

  @override
  String canOnlyHaveMaxImages(int max) {
    return '最大$max枚の画像のみ持つことができます';
  }

  @override
  String get imageSizeExceedsLimit => '画像サイズが10MBの制限を超えています';

  @override
  String get unsupportedImageFormat => 'サポートされていない画像形式';

  @override
  String get pleaseSelectAtLeastOneImage => 'アップロードする画像を少なくとも1枚選択してください';

  @override
  String get basicInformation => '基本情報';

  @override
  String get languageToLearn => '学習言語';

  @override
  String get hometown => '出身地';

  @override
  String get characters => '文字';

  @override
  String get failedToLoadLanguages => '言語の読み込みに失敗しました';

  @override
  String get studyHub => '学習ハブ';

  @override
  String get dailyLearningJourney => '今日の学習の旅';

  @override
  String get learnTab => '学習';

  @override
  String get aiTools => 'AIツール';

  @override
  String get streak => '連続学習';

  @override
  String get lessons => 'レッスン';

  @override
  String get words => '単語';

  @override
  String get quickActions => 'クイックアクション';

  @override
  String get review => '復習';

  @override
  String wordsDue(int count) {
    return '$count個の単語が予定';
  }

  @override
  String get addWords => '単語を追加';

  @override
  String get buildVocabulary => '語彙を増やす';

  @override
  String get practiceWithAI => 'AIで練習';

  @override
  String get aiPracticeDescription => 'チャット、クイズ、文法・発音';

  @override
  String get dailyChallenges => 'デイリーチャレンジ';

  @override
  String get allChallengesCompleted => 'すべてのチャレンジ完了！';

  @override
  String get continueLearning => '学習を続ける';

  @override
  String get structuredLearningPath => '体系的な学習パス';

  @override
  String get vocabulary => '語彙';

  @override
  String get yourWordCollection => 'あなたの単語コレクション';

  @override
  String get achievements => '実績';

  @override
  String get badgesAndMilestones => 'バッジとマイルストーン';

  @override
  String get failedToLoadLearningData => '学習データの読み込みに失敗しました';

  @override
  String get startYourJourney => '旅を始めよう！';

  @override
  String get startJourneyDescription => 'レッスンを完了し、語彙を増やし、\n進捗を追跡しましょう';

  @override
  String levelN(int level) {
    return 'レベル$level';
  }

  @override
  String xpEarned(int xp) {
    return '$xp XP獲得';
  }

  @override
  String nextLevel(int level) {
    return '次：レベル$level';
  }

  @override
  String xpToGo(int xp) {
    return '残り$xp XP';
  }

  @override
  String get aiConversationPartner => 'AI会話パートナー';

  @override
  String get practiceWithAITutor => 'AIチューターと会話を練習';

  @override
  String get startConversation => '会話を開始';

  @override
  String get aiFeatures => 'AI機能';

  @override
  String get aiLessons => 'AIレッスン';

  @override
  String get learnWithAI => 'AIで学ぶ';

  @override
  String get grammar => '文法';

  @override
  String get checkWriting => '文章を確認';

  @override
  String get pronunciation => '発音';

  @override
  String get improveSpeaking => '話す力を向上';

  @override
  String get translation => '翻訳';

  @override
  String get smartTranslate => 'スマート翻訳';

  @override
  String get aiQuizzes => 'AIクイズ';

  @override
  String get testKnowledge => '知識をテスト';

  @override
  String get lessonBuilder => 'レッスンビルダー';

  @override
  String get customLessons => 'カスタムレッスン';

  @override
  String get yourAIProgress => 'AIの進捗';

  @override
  String get quizzes => 'クイズ';

  @override
  String get avgScore => '平均スコア';

  @override
  String get focusAreas => '重点領域';

  @override
  String accuracyPercent(String accuracy) {
    return '正確度$accuracy%';
  }

  @override
  String get practice => '練習';

  @override
  String get browse => 'ブラウズ';

  @override
  String get noRecommendedLessons => 'おすすめのレッスンはありません';

  @override
  String get noLessonsFound => 'レッスンが見つかりません';

  @override
  String get createCustomLessonDescription => 'AIを使って独自のカスタムレッスンを作成';

  @override
  String get createLessonWithAI => 'AIでレッスンを作成';

  @override
  String get allLevels => '全レベル';

  @override
  String get levelA1 => 'A1 入門';

  @override
  String get levelA2 => 'A2 初級';

  @override
  String get levelB1 => 'B1 中級';

  @override
  String get levelB2 => 'B2 中上級';

  @override
  String get levelC1 => 'C1 上級';

  @override
  String get levelC2 => 'C2 習熟';

  @override
  String get failedToLoadLessons => 'レッスンの読み込みに失敗しました';

  @override
  String get pin => 'ピン留め';

  @override
  String get unpin => 'ピン留め解除';

  @override
  String get editMessage => 'メッセージを編集';

  @override
  String get enterMessage => 'メッセージを入力...';

  @override
  String get deleteMessageTitle => 'メッセージを削除';

  @override
  String get actionCannotBeUndone => 'この操作は取り消せません。';

  @override
  String get onlyRemovesFromDevice => 'お使いのデバイスからのみ削除されます';

  @override
  String get availableWithinOneHour => '1時間以内のみ可能';

  @override
  String get available => '利用可能';

  @override
  String get forwardMessage => 'メッセージを転送';

  @override
  String get selectUsersToForward => '転送先のユーザーを選択:';

  @override
  String forwardCount(int count) {
    return '転送 ($count)';
  }

  @override
  String get pinnedMessage => 'ピン留めメッセージ';

  @override
  String get photoMedia => '写真';

  @override
  String get videoMedia => '動画';

  @override
  String get voiceMessageMedia => '音声メッセージ';

  @override
  String get documentMedia => 'ドキュメント';

  @override
  String get locationMedia => '位置情報';

  @override
  String get stickerMedia => 'スタンプ';

  @override
  String get smileys => 'スマイリー';

  @override
  String get emotions => '感情';

  @override
  String get handGestures => 'ハンドジェスチャー';

  @override
  String get hearts => 'ハート';

  @override
  String get tapToSayHi => 'タップして挨拶しよう！';

  @override
  String get sendWaveToStart => '手を振って会話を始めましょう';

  @override
  String get documentMustBeUnder50MB => 'ドキュメントは50MB以下にしてください。';

  @override
  String get editWithin15Minutes => 'メッセージは15分以内のみ編集できます';

  @override
  String messageForwardedTo(int count) {
    return '$count人のユーザーに転送しました';
  }

  @override
  String get failedToLoadUsers => 'ユーザーの読み込みに失敗しました';

  @override
  String get voice => '音声';

  @override
  String get searchGifs => 'GIFを検索...';

  @override
  String get trendingGifs => 'トレンド';

  @override
  String get poweredByGiphy => 'Powered by GIPHY';

  @override
  String get gif => 'GIF';

  @override
  String get noGifsFound => 'GIFが見つかりませんでした';

  @override
  String get failedToLoadGifs => 'GIFの読み込みに失敗しました';

  @override
  String get gifSent => 'GIF';

  @override
  String get filterCommunities => 'フィルター';

  @override
  String get reset => 'リセット';

  @override
  String get findYourPerfect => '理想の';

  @override
  String get languagePartner => '言語パートナーを見つけよう';

  @override
  String get learningLanguageLabel => '学習言語';

  @override
  String get ageRange => '年齢範囲';

  @override
  String get genderPreference => '性別の好み';

  @override
  String get any => 'すべて';

  @override
  String get showNewUsersSubtitle => '過去6日間に参加したユーザーを表示';

  @override
  String get autoDetectLocation => '現在地を自動検出';

  @override
  String get selectCountry => '国を選択';

  @override
  String get anyCountry => 'すべての国';

  @override
  String get loadingLanguages => '言語を読み込み中...';

  @override
  String minAge(int age) {
    return '最小: $age';
  }

  @override
  String maxAge(int age) {
    return '最大: $age';
  }

  @override
  String get captionRequired => 'キャプションは必須です';

  @override
  String captionTooLong(int maxLength) {
    return 'キャプションは$maxLength文字以内にしてください';
  }

  @override
  String get maximumImagesReached => '画像の上限に達しました';

  @override
  String maximumImagesReachedDescription(int maxImages) {
    return '1つのモーメントにつき最大$maxImages枚の画像をアップロードできます。';
  }

  @override
  String maximumImagesAddedPartial(int maxImages, int added) {
    return '最大$maxImages枚の画像が許可されています。$added枚のみ追加されました。';
  }

  @override
  String get locationAccessRestricted => '位置情報へのアクセスが制限されています';

  @override
  String get locationPermissionNeeded => '位置情報の許可が必要です';

  @override
  String get addToYourMoment => 'モーメントに追加';

  @override
  String get categoryLabel => 'カテゴリ';

  @override
  String get languageLabel => '言語';

  @override
  String get scheduleOptional => 'スケジュール（任意）';

  @override
  String get scheduleForLater => '後でスケジュール';

  @override
  String get addMore => 'さらに追加';

  @override
  String get howAreYouFeeling => '今の気分は？';

  @override
  String get pleaseWaitOptimizingVideo => '動画を最適化しています。お待ちください';

  @override
  String unsupportedVideoFormat(String formats) {
    return 'サポートされていない形式です。使用可能: $formats';
  }

  @override
  String get chooseBackground => '背景を選択';

  @override
  String likedByXPeople(int count) {
    return '$count人がいいねしました';
  }

  @override
  String xComments(int count) {
    return '$count件のコメント';
  }

  @override
  String get oneComment => '1件のコメント';

  @override
  String get addAComment => 'コメントを追加...';

  @override
  String viewXReplies(int count) {
    return '$count件の返信を表示';
  }

  @override
  String seenByX(int count) {
    return '$count人が閲覧';
  }

  @override
  String xHoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String xMinutesAgo(int count) {
    return '$count分前';
  }

  @override
  String get repliedToYourStory => 'ストーリーに返信しました';

  @override
  String mentionedYouInComment(String name) {
    return '$nameがコメントであなたをメンションしました';
  }

  @override
  String repliedToYourComment(String name) {
    return '$nameがコメントに返信しました';
  }

  @override
  String reactedToYourComment(String name) {
    return '$nameがコメントにリアクションしました';
  }

  @override
  String get addReaction => 'リアクションを追加';

  @override
  String get attachImage => '画像を添付';

  @override
  String get pickGif => 'GIFを選択';

  @override
  String get textStory => 'テキスト';

  @override
  String get typeYourStory => 'ストーリーを入力...';

  @override
  String get selectBackground => '背景を選択';

  @override
  String get highlightsTitle => 'ハイライト';

  @override
  String get highlightTitle => 'ハイライトタイトル';

  @override
  String get createNewHighlight => '新規作成';

  @override
  String get selectStories => 'ストーリーを選択';

  @override
  String get selectCover => 'カバーを選択';

  @override
  String get addText => 'テキストを追加';

  @override
  String get fontStyleLabel => 'フォントスタイル';

  @override
  String get textColorLabel => 'テキスト色';

  @override
  String get dragToDelete => 'ここにドラッグして削除';

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
  String get logoutConfirmMessage => 'Are you sure you want to logout from Bananatalk?';

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

  @override
  String get silencedByQuietHours => 'Silenced by Quiet Hours';

  @override
  String get silencedByCap => 'Silenced by daily limit';

  @override
  String get momentUpdatedSuccessfully => 'モーメントが正常に更新されました';

  @override
  String get failedToDeleteMoment => 'モーメントの削除に失敗しました';

  @override
  String get failedToUpdateMoment => 'モーメントの更新に失敗しました';

  @override
  String get mbtiUpdatedSuccessfully => 'MBTIが正常に更新されました';

  @override
  String get pleaseSelectMbti => 'MBTIタイプを選択してください';

  @override
  String get languageUpdatedSuccessfully => '言語が正常に更新されました';

  @override
  String get bioHintCard => '充実した自己紹介は他のユーザーとの出会いを助けます。興味、使用言語、求めているものなどを共有しましょう。';

  @override
  String get bioCounterStartWriting => '書き始めましょう...';

  @override
  String get bioCounterABitMore => 'もう少し書くとよいでしょう';

  @override
  String get bioCounterAlmostAtLimit => '文字数制限に近づいています';

  @override
  String get bioCounterTooLong => '文字数オーバー';

  @override
  String get bioQuickStarters => 'クイックスターター';

  @override
  String get rhPositive => 'Rhプラス';

  @override
  String get rhNegative => 'Rhマイナス';

  @override
  String get rhPositiveDesc => '最も一般的';

  @override
  String get rhNegativeDesc => '万能ドナー / 希少';

  @override
  String get yourBloodType => 'あなたの血液型';

  @override
  String get noBloodTypeSelected => '血液型が選択されていません';

  @override
  String get tapTypeBelow => '下のタイプをタップしてください';

  @override
  String get tapButtonToDetectLocation => '下のボタンをタップして現在地を検出してください';

  @override
  String currentAddressLabel(String address) {
    return '現在地: $address';
  }

  @override
  String get onlyCityCountryShown => '他のユーザーには市区町村と国のみ表示されます。正確な座標は非公開のままです。';

  @override
  String get updateLocationCta => '位置情報を更新';

  @override
  String get enterYourName => '名前を入力してください';

  @override
  String get unsavedChanges => '未保存の変更があります';

  @override
  String tapBelowToBrowseLanguages(int count) {
    return '下をタップして$count言語から選択';
  }

  @override
  String get changeLanguage => '言語を変更';

  @override
  String get browseLanguages => '言語を探す';

  @override
  String get yourLearningLanguageIsPrefix => '学習中の言語：';

  @override
  String get yourNativeLanguageIsPrefix => '母国語：';

  @override
  String get profileCompleteProgress => '完了';

  @override
  String get drawerPreferences => '設定';

  @override
  String get drawerStorage => 'ストレージ';

  @override
  String get drawerReports => 'レポート';

  @override
  String get drawerSupport => 'サポート';

  @override
  String get drawerAccount => 'アカウント';

  @override
  String get logoutConfirmBody => 'Bananatalkからログアウトしますか？';

  @override
  String get helpEmailSupport => 'メールサポート';

  @override
  String get helpEmailSupportSubtitle => 'support@bananatalk.com';

  @override
  String get helpReportBug => 'バグを報告';

  @override
  String get helpReportBugSubtitle => 'Bananatalkの改善にご協力ください';

  @override
  String get helpFaqs => 'よくある質問';

  @override
  String get helpFaqsSubtitle => 'よく寄せられる質問';

  @override
  String get aboutDialogClose => '閉じる';

  @override
  String get aboutBananatalkTagline => '世界中の語学学習者とつながり、実際の会話を通してスキルを向上させましょう。';

  @override
  String get aboutCopyright => '© 2024 Bananatalk. 無断転載禁止。';

  @override
  String get logoutFailedPrefix => 'ログアウト失敗';

  @override
  String get profileVisitorsTitle => 'プロフィール訪問者';

  @override
  String get visitorStatistics => '訪問者統計';

  @override
  String get visitorsTotalVisits => '総訪問数';

  @override
  String get visitorsUniqueVisitors => 'ユニーク訪問者';

  @override
  String get visitorsToday => '今日';

  @override
  String get visitorsThisWeek => '今週';

  @override
  String get noVisitorsYet => 'まだ訪問者がいません';

  @override
  String get noVisitorsYetSubtitle => 'あなたのプロフィールを訪問した人が\nここに表示されます';

  @override
  String get visitedViaSearch => '検索経由';

  @override
  String get visitedViaMoments => 'モーメント経由';

  @override
  String get visitedViaChat => 'チャット経由';

  @override
  String get visitedDirect => '直接訪問';

  @override
  String get visitorTrackingUnavailable => '訪問者追跡機能は利用できません。バックエンドを更新してください。';

  @override
  String get visitorTrackingNotAvailableYet => '訪問者追跡はまだ利用できません';

  @override
  String get noFollowersYetSubtitle => '他のユーザーとつながり始めましょう！';

  @override
  String get partnerButton => 'パートナー';

  @override
  String get notFollowingAnyoneYetSubtitle => 'フォローして更新情報を確認しましょう！';

  @override
  String get unfollowButton => 'フォロー解除';

  @override
  String get profileThemeTitle => 'プロフィールテーマ';

  @override
  String get themeAutoSwitch => '自動切替（システムテーマ）';

  @override
  String get themeSystemHint => '有効にすると、アプリはシステムのテーマ設定に従います';

  @override
  String get themeLightMode => 'ライトモード';

  @override
  String get themeDarkMode => 'ダークモード';

  @override
  String get myMoments => 'マイモーメント';

  @override
  String get momentListView => 'リスト表示';

  @override
  String get momentGridView => 'グリッド表示';

  @override
  String get shareLanguageLearningJourney => '語学学習の旅をシェアしよう！';

  @override
  String get deleteHighlightTitle => 'ハイライトを削除';

  @override
  String deleteHighlightConfirm(String title) {
    return '「$title」を削除しますか？中のストーリーは削除されません。';
  }

  @override
  String get highlightDeletedSuccess => 'ハイライトを削除しました';

  @override
  String get highlightNewBadge => '新着';

  @override
  String get editMoment => 'モーメントを編集';

  @override
  String get momentDescriptionLabel => '説明';

  @override
  String get momentImagesLabel => '画像';

  @override
  String get noImagesYet => '画像がありません';

  @override
  String get momentEnterDescription => '説明を入力してください';

  @override
  String get momentUpdatedImageFailed => 'モーメントは更新されましたが、画像のアップロードに失敗しました';

  @override
  String get updateRequiredTitle => 'アップデートが必要です';

  @override
  String get updateAvailableTitle => 'アップデートが利用可能です';

  @override
  String get updateRequiredBody => 'このバージョンのBananatalkはサポートが終了しました。続けるにはアップデートしてください。';

  @override
  String get updateAvailableBody => '改善とバグ修正を含むBananatalkの新しいバージョンが利用可能です。';

  @override
  String get updateNow => '今すぐアップデート';

  @override
  String get updateLater => '後で';

  @override
  String get updateOpenStoreFailed => 'ストアを開けませんでした。App StoreまたはPlay Storeからアップデートしてください。';
}
