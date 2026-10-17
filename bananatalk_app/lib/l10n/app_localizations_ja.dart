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
  String get aiStudyPromoTitle => 'AIシナリオで練習しよう';

  @override
  String get aiStudyPromoBody => 'AIチューターと実際の会話をロールプレイして、話す自信をつけよう。';

  @override
  String get aiStudyPromoCTA => 'シナリオを試す';

  @override
  String get aiStudyPromoDismiss => 'あとで';

  @override
  String get promoSpotlightCoinsHeadline => '会話の途中でコイン切れの心配なし';

  @override
  String get promoSpotlightCoinsSubtitle => '1日の上限に達したら、コインを使って追加の翻訳、チューターとのチャット、モーメントを解放しよう。';

  @override
  String get promoSpotlightRoomsHeadline => 'トピックルームに参加しよう';

  @override
  String get promoSpotlightRoomsSubtitle => 'ライブテキストルームに入って、気になるトピックについて話す学習者たちと練習しよう。';

  @override
  String get promoSpotlightVoiceHeadline => 'ボイスルームに参加しよう';

  @override
  String get promoSpotlightVoiceSubtitle => '他の学習者とライブで話して、会話を重ねながら本物の話す自信を身につけよう。';

  @override
  String get promoSpotlightTryIt => '試してみる';

  @override
  String get promoSpotlightMaybeLater => 'また今度';

  @override
  String get promoSpotlightDontShowAgain => '今後表示しない';

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
  String get loadMoreComments => 'コメントをもっと見る';

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
  String get deleteComment => 'コメントを削除しますか？';

  @override
  String get commentDeleted => 'コメントを削除しました';

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
  String get aiTutorChangePersona => 'AIチューターを変更';

  @override
  String get aiTutorChangePersonaSubtitle => 'Nana、Sensei、Rikoに切り替え';

  @override
  String aiTutorHeroTitleSet(String name) {
    return 'AIチューター · $name';
  }

  @override
  String get aiTutorHeroTitleNew => 'AIチューターに会おう';

  @override
  String get aiTutorHeroSubtitleSet => 'タップしてチャットまたは今日のプランを確認';

  @override
  String aiTutorHeroSubtitleLast(String summary) {
    return '前回: $summary';
  }

  @override
  String get aiTutorHeroSubtitleNew => 'キャラクターを選ぼう — Nana、Sensei、Riko';

  @override
  String get aiTutorChipChat => 'チャット';

  @override
  String get aiTutorChipRoleplay => 'ロールプレイ';

  @override
  String get aiTutorChipStory => 'ストーリー';

  @override
  String get aiTutorChipPhoto => '写真';

  @override
  String get aiToolsMoreSection => 'その他のAIツール';

  @override
  String get aiConversationPartnerTile => 'AI会話';

  @override
  String get aiConversationPartnerTileSubtitle => 'AIパートナーと練習';

  @override
  String get aiTutorPickerTitle => 'AIチューターを選ぼう';

  @override
  String get aiTutorPickerHeader => '誰と一緒に学びたい？';

  @override
  String get aiTutorPickerSubtitle => '設定からいつでも変更できます。';

  @override
  String get aiTutorPersonaNanaTagline => '温かい + 励まし';

  @override
  String get aiTutorPersonaNanaSample => 'プレッシャーなしで応援するよ。';

  @override
  String get aiTutorPersonaSenseiTagline => '正確 + 試験対策';

  @override
  String get aiTutorPersonaSenseiSample => 'ルールをマスターしよう。';

  @override
  String get aiTutorPersonaRikoTagline => '陽気 + カジュアル';

  @override
  String get aiTutorPersonaRikoSample => '楽しく学ぼうぜ';

  @override
  String aiTutorPickerSaveError(String error) {
    return '保存できませんでした: $error';
  }

  @override
  String get aiTutorHomeTitle => 'AIチューター';

  @override
  String get aiTutorHomeChangeTutor => 'チューターを変更';

  @override
  String get aiTutorHomeGreetingDefault => 'やあ！一緒に学ぶ準備はいい？';

  @override
  String get aiTutorHomeTodaysPlan => '今日のプラン';

  @override
  String get aiTutorHomePlanEmpty => '今日はプランがありません — チャットを始めましょう。';

  @override
  String get aiTutorHomeStartChat => 'チャット開始';

  @override
  String get aiTutorHomeRecent => '最近';

  @override
  String get aiTutorHomePracticeScenarios => '練習シナリオ';

  @override
  String get aiTutorHomePracticeScenariosSubtitle => '実際の会話をロールプレイ — レストラン、面接、ホテル…';

  @override
  String get aiTutorHomeReadStory => 'ストーリーを読む';

  @override
  String get aiTutorHomeReadStorySubtitle => 'AIがあなたの単語で短いストーリーを書き、簡単な理解問題を出します。';

  @override
  String get aiTutorHomeDescribePhoto => '写真を説明';

  @override
  String get aiTutorHomeDescribePhotoSubtitle => '写真を撮って説明 — AIが単語と文法を評価します。';

  @override
  String get aiTutorChatTitle => 'チューターとチャット';

  @override
  String get aiTutorChatVoiceOn => '音声オン';

  @override
  String get aiTutorChatVoiceOff => '音声オフ';

  @override
  String get aiTutorChatStopRecording => '録音を停止';

  @override
  String get aiTutorChatHoldToTalk => '押しながら話す';

  @override
  String get aiTutorChatTranscribing => '文字起こし中…';

  @override
  String get aiTutorChatListening => '聴いています…';

  @override
  String get aiTutorChatInputHint => 'メッセージを入力…';

  @override
  String get aiTutorChatTypeReplyHint => '返信を入力…';

  @override
  String get aiTutorChatMicPermissionDenied => '音声モードにはマイクの許可が必要です。';

  @override
  String get aiTutorChatTranscribeFailed => '聞き取れませんでした — もう一度試してください。';

  @override
  String aiTutorChatStartFailed(String error) {
    return '開始できませんでした: $error';
  }

  @override
  String get aiTutorRoleplayEnd => '終了';

  @override
  String aiTutorRoleplayEndFailed(String error) {
    return '終了に失敗: $error';
  }

  @override
  String get aiTutorRoleplayDone => '完了';

  @override
  String get aiTutorStoryTitle => 'ストーリーを読む';

  @override
  String get aiTutorStoryLength => '長さ';

  @override
  String get aiTutorStoryTheme => 'テーマ';

  @override
  String aiTutorStoryWordCount(int count) {
    return '$count 単語';
  }

  @override
  String get aiTutorStoryWriting => '執筆中…';

  @override
  String get aiTutorStoryGenerate => 'ストーリーを生成';

  @override
  String aiTutorStoryGenerateFailed(String error) {
    return '生成できませんでした: $error';
  }

  @override
  String aiTutorStoryWordCountHint(int n) {
    return 'AIはあなたの単語リストから最大$n語を使います。';
  }

  @override
  String get aiTutorStoryThemeFree => '自由';

  @override
  String get aiTutorStoryThemeAdventure => '冒険';

  @override
  String get aiTutorStoryThemeMystery => 'ミステリー';

  @override
  String get aiTutorStoryThemeRomance => 'ロマンス';

  @override
  String get aiTutorStoryThemeSciFi => 'SF';

  @override
  String get aiTutorStoryThemeSliceOfLife => '日常';

  @override
  String get aiTutorStoryReaderTitle => 'ストーリー';

  @override
  String get aiTutorStoryReaderVocab => '単語';

  @override
  String get aiTutorStoryReaderVocabUsed => '使用した単語';

  @override
  String aiTutorStoryReaderPart(int n) {
    return '第$n部';
  }

  @override
  String get aiTutorStoryReaderWrongHint => '惜しい — 次へ';

  @override
  String get aiTutorStoryReaderNiceWork => 'いいね！';

  @override
  String aiTutorStoryReaderScore(int correct, int total) {
    return '理解度問題で $correct/$total 正解しました。';
  }

  @override
  String get aiTutorStoryReaderDone => '完了';

  @override
  String get aiTutorImageVocabTitle => '写真を説明';

  @override
  String get aiTutorImagePickHeader => '説明する写真を選ぼう';

  @override
  String get aiTutorImagePickSubtitle => 'AIがターゲット言語でプロンプトを出し、あなたの説明を採点します。';

  @override
  String get aiTutorImagePickCamera => 'カメラ';

  @override
  String get aiTutorImagePickGallery => 'ギャラリー';

  @override
  String aiTutorImagePickError(String error) {
    return '画像を開けませんでした: $error';
  }

  @override
  String get aiTutorImageDescriptionHint => '説明を入力…';

  @override
  String get aiTutorImageDifferentPhoto => '別の写真';

  @override
  String get aiTutorImageSubmit => '送信';

  @override
  String get aiTutorImageGrammarNotes => '文法メモ';

  @override
  String get aiTutorImageThingsYouMissed => '見逃したもの';

  @override
  String get aiTutorImageTryAnother => '別の写真で試す';

  @override
  String get aiTutorCardQuiz => 'クイズ';

  @override
  String get aiTutorCardVocab => '単語';

  @override
  String get aiTutorCardGrammar => '文法';

  @override
  String get aiTutorCardReviewDue => '復習時間';

  @override
  String get aiTutorCardMiniLesson => 'ミニレッスン';

  @override
  String get aiTutorCardAddToVocab => '単語に追加';

  @override
  String get aiTutorCardAddedToVocab => '追加済み';

  @override
  String get aiTutorCardAdding => '追加中…';

  @override
  String aiTutorCardReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count枚のカードが待っています',
      one: '$count枚のカードが待っています',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorCardReviewNow => '今すぐ復習';

  @override
  String get aiTutorCardReviewStarting => '開始中…';

  @override
  String get aiTutorCardTryIt => 'やってみる';

  @override
  String get aiTutorCardPracticing => '練習中…';

  @override
  String aiTutorPlanSrsReview(int count, int done) {
    return '$count枚のSRSカードを復習 ($done完了)';
  }

  @override
  String aiTutorPlanGrammar(String topic) {
    return '練習: $topic';
  }

  @override
  String aiTutorPlanChat(int min, int done) {
    return '$min分チャット (これまで$done)';
  }

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
  String get bloodType => '血液型';

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
  String get conversationHistory => '会話履歴';

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
  String get chatSendTooFast => 'メッセージの送信が速すぎます。少し待ってからもう一度お試しください。';

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
  String views(int count) {
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
  String get languagesStepTitle => 'あなたの言語';

  @override
  String get languagesStepSubtitle => '逆の組み合わせで学ぶ人とマッチングします';

  @override
  String get languagesISpeak => '話せる言語';

  @override
  String get languagesImLearning => '学びたい言語';

  @override
  String get languagesSwap => '入れ替え';

  @override
  String get languagesChoose => '言語を選ぶ';

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
  String minutesAgo(int count) {
    return '$count分前';
  }

  @override
  String hoursAgo(int count) {
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
  String get communityTabRooms => 'ルーム';

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
  String get noForYouMomentsTitle => 'まだモーメントがありません';

  @override
  String get noForYouMomentsBody => '今日のお題に答えて会話を始めましょう。';

  @override
  String get noFollowingMomentsTitle => 'まだここには何もありません';

  @override
  String get noFollowingMomentsBody => 'コミュニティでユーザーをフォローすると、ここにモーメントが表示されます。';

  @override
  String get goToCommunity => 'コミュニティへ移動';

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
  String get exchange3MessagesBeforeCall => '電話をかけるには、まず5件以上のメッセージを交換してください';

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
  String get whenAwayFor24Hours => '24時間以上離れているとき';

  @override
  String get passwordAndLoginAlerts => 'パスワードとログインアラート';

  @override
  String get failedToLoadPreferences => '設定の読み込みに失敗しました';

  @override
  String get failedToUpdateSetting => '設定の更新に失敗しました';

  @override
  String get securityAlertsRecommended => '重要なアカウント活動を把握するため、セキュリティアラートを有効にしておくことをお勧めします。';

  @override
  String chatWallpaperFor(String name) {
    return '$nameのチャット壁紙';
  }

  @override
  String get solidColors => '単色';

  @override
  String get gradients => 'グラデーション';

  @override
  String get customImage => 'カスタム画像';

  @override
  String get chooseFromGallery => 'ギャラリーから選択';

  @override
  String get preview => 'プレビュー';

  @override
  String get wallpaperUpdated => '壁紙を更新しました';

  @override
  String get category => 'カテゴリー';

  @override
  String get mood => '気分';

  @override
  String get sortBy => '並べ替え';

  @override
  String get timePeriod => '期間';

  @override
  String get searchLanguages => '言語を検索...';

  @override
  String get selected => '選択済み';

  @override
  String get categories => 'カテゴリー';

  @override
  String get moods => '気分';

  @override
  String get applyFilters => 'フィルターを適用';

  @override
  String applyNFilters(int count) {
    return '$count件のフィルターを適用';
  }

  @override
  String get videoMustBeUnder1GB => '動画は1GB以下にしてください。';

  @override
  String get failedToRecordVideo => '動画の録画に失敗しました';

  @override
  String get errorSendingVideo => '動画の送信中にエラーが発生しました';

  @override
  String get errorSendingVoiceMessage => 'ボイスメッセージの送信中にエラーが発生しました';

  @override
  String get errorSendingMedia => 'メディアの送信中にエラーが発生しました';

  @override
  String get cameraPermissionRequired => '動画を録画するにはカメラとマイクの許可が必要です。';

  @override
  String get locationPermissionRequired => '位置情報を共有するには位置情報の許可が必要です。';

  @override
  String get noInternetConnection => 'インターネット接続がありません';

  @override
  String get tryAgainLater => '後でもう一度お試しください';

  @override
  String get messageSent => 'メッセージを送信しました';

  @override
  String get messageDeleted => 'メッセージを削除しました';

  @override
  String get messageEdited => 'メッセージを編集しました';

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
  String get checkOutProfile => 'Bananatalkでこのプロフィールをチェック！';

  @override
  String get checkOutCommunity => 'Bananatalkでこのメンバーをチェック！';

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
  String usersWorldwide(int count) {
    return '世界中の$count人';
  }

  @override
  String get noUsersFound => 'ユーザーが見つかりません';

  @override
  String get tryDifferentCity => '別の都市や国を試してみてください';

  @override
  String usersCount(int count) {
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
  String get deletionReasonTitle => '退会の前に — 理由を教えてください';

  @override
  String get deletionReasonOptional => '任意です。改善に役立てます。';

  @override
  String get deletionReasonNoPeople => '話せる相手が見つからなかった';

  @override
  String get deletionReasonNoContent => '自分の言語の教材がない';

  @override
  String get deletionReasonNotUseful => '期待していたものと違った';

  @override
  String get deletionReasonBugs => 'アプリが正しく動かなかった';

  @override
  String get deletionReasonNotifications => '通知が多すぎた';

  @override
  String get deletionReasonPrivacy => 'プライバシーが心配';

  @override
  String get deletionReasonOther => 'その他';

  @override
  String get deletionReasonHint => '詳しく教えてください（任意）';

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
  String get locationOptional => '続行するには位置情報を設定してください';

  @override
  String get maximum6Photos => '最大6枚まで';

  @override
  String get tapToDetectLocation => 'タップして位置を検出';

  @override
  String get optionalHelpsNearbyPartners => '任意 — 近くのパートナーとのマッチングに役立ちます';

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
  String get confirmPasswordHint => '新しいパスワードを再入力';

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
  String get backToSignInMethods => 'ログイン方法に戻る';

  @override
  String get securedByGoogle => 'Googleのセキュリティ';

  @override
  String get dataProtectedEncryption => 'お客様のデータは業界標準の暗号化で保護されています';

  @override
  String get welcomeCompleteProfile => 'ようこそ！プロフィールを完成させてください';

  @override
  String get authWelcomeTagline => '出会う · 話す · つながる';

  @override
  String get authWelcomeCtaTitle => 'Bananatalkで世界中に友達を作ろう';

  @override
  String get authWelcomeCtaSubtitle => '今すぐ何百万人もの言語学習者に仲間入り';

  @override
  String get authWelcomeFeatureConnectTitle => 'つながる';

  @override
  String get authWelcomeFeatureConnectSubtitle => '世界150カ国以上の言語パートナーと出会える';

  @override
  String get authWelcomeFeatureLearnTitle => '学ぶ';

  @override
  String get authWelcomeFeatureLearnSubtitle => 'AIチューター、クイズ、発音トレーニングがすべて1つのアプリに';

  @override
  String get authWelcomeFeatureGrowTitle => '成長する';

  @override
  String get authWelcomeFeatureGrowSubtitle => '毎日の会話とコミュニティで本物の流暢さを身につけよう';

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
  String get allCategories => 'すべてのカテゴリ';

  @override
  String get leaderboard => 'リーダーボード';

  @override
  String get competeWithLearners => '他の学習者と競い合おう！';

  @override
  String get xpRankings => 'XPランキング';

  @override
  String get streaks => '連続記録';

  @override
  String get friends => 'フレンド';

  @override
  String get myRanks => '自分のランク';

  @override
  String get currentStreak => '現在の連続記録';

  @override
  String get longestStreak => '最長連続記録';

  @override
  String get weekly => '週間';

  @override
  String get monthly => '月間';

  @override
  String get yourRank => 'あなたのランク';

  @override
  String outOf(int total) {
    return '$total人中';
  }

  @override
  String topPercent(String percent) {
    return '上位$percent%';
  }

  @override
  String get xpRank => 'XPランク';

  @override
  String get streakRank => '連続記録ランク';

  @override
  String get days => '日';

  @override
  String get learningStats => '学習統計';

  @override
  String get totalXp => '合計XP';

  @override
  String get lessonsCompleted => '完了したレッスン';

  @override
  String get rankings => 'ランキング';

  @override
  String get yourPosition => 'あなたの順位';

  @override
  String get keepLearning => '順位を上げるために学習を続けましょう！';

  @override
  String get noRankingsYet => 'まだランキングがありません';

  @override
  String get startLearningToAppear => 'リーダーボードに表示されるには学習を始めましょう！';

  @override
  String get noFriendsYet => 'まだフレンドがいません';

  @override
  String get addFriendsToCompete => 'フレンドを追加して競い合いましょう！';

  @override
  String get failedToLoadLeaderboard => 'リーダーボードの読み込みに失敗しました';

  @override
  String get you => 'あなた';

  @override
  String get findPartners => 'パートナーを探す';

  @override
  String get discoverLanguagePartners => '言語パートナーを見つける';

  @override
  String get byLanguage => '言語別';

  @override
  String get match => 'マッチ';

  @override
  String get matchScore => 'マッチスコア';

  @override
  String get noMatchesFound => 'マッチが見つかりません';

  @override
  String get noUsersOnline => 'オンラインのユーザーがいません';

  @override
  String get checkBackLater => '後でもう一度確認してください';

  @override
  String get selectLanguagePrompt => '言語を選択してください';

  @override
  String get findPartnersByLanguage => 'この言語を話す、または学んでいるパートナーを探す';

  @override
  String noPartnersForLanguage(String language) {
    return '$languageのパートナーがいません';
  }

  @override
  String get tryAnotherLanguage => '別の言語を選んでみてください';

  @override
  String get failedToLoadMatches => 'マッチの読み込みに失敗しました';

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
  String get aiTools => '練習';

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
  String get noBlockedUsers => 'ブロックしたユーザーはいません';

  @override
  String get usersYouBlockWillAppearHere => 'ブロックしたユーザーはここに表示されます';

  @override
  String unblockConfirm(String name) {
    return '$nameのブロックを解除してもよろしいですか？';
  }

  @override
  String reasonLabel(String reason) {
    return '理由：$reason';
  }

  @override
  String blockedAgo(String time) {
    return '$time前にブロック';
  }

  @override
  String errorLoadingBlockedUsers(String error) {
    return 'ブロックしたユーザーの読み込みエラー：$error';
  }

  @override
  String get logoutConfirmMessage => 'Bananatalkからログアウトしてもよろしいですか？';

  @override
  String get loggingOut => 'ログアウト中...';

  @override
  String get quietHours => 'サイレント時間';

  @override
  String get quietHoursEnable => 'サイレント時間を有効にする';

  @override
  String get quietHoursSubtitle => '指定した時間帯は緊急でない通知を一時停止します';

  @override
  String get quietHoursStart => '開始時刻';

  @override
  String get quietHoursEnd => '終了時刻';

  @override
  String get quietHoursAllowUrgent => '緊急通知を許可する';

  @override
  String get quietHoursAllowUrgentSubtitle => 'VIPパートナーからの通話やメッセージは引き続き届きます';

  @override
  String get silencedByQuietHours => 'サイレント時間によりミュートされました';

  @override
  String get silencedByCap => '1日の上限によりミュートされました';

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
  String get helpEmailSupportSubtitle => 'bananatalkmain@gmail.com';

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

  @override
  String get rememberMe => 'ログイン情報を保存';

  @override
  String get passwordWeak => '弱い';

  @override
  String get passwordFair => '普通';

  @override
  String get passwordStrong => '強い';

  @override
  String get passwordVeryStrong => '非常に強い';

  @override
  String get showPassword => 'パスワードを表示';

  @override
  String get hidePassword => 'パスワードを非表示';

  @override
  String stepProgress(int current, int total) {
    return 'ステップ $current / $total';
  }

  @override
  String get usernameOptional => 'ユーザー名 (任意)';

  @override
  String get usernameAvailable => '利用可能';

  @override
  String get usernameTaken => '既に使用されています';

  @override
  String get usernameNotAvailable => '使用できません';

  @override
  String get usernameInvalidFormat => '3〜20文字、英数字とアンダースコアのみ';

  @override
  String get usernameHint => '@ユーザー名';

  @override
  String get enableBiometricTitle => '次回からFace IDでログインしますか?';

  @override
  String get enableBiometricBody => '生体認証でパスワード入力をスキップできます。';

  @override
  String get enableBiometricCta => '有効にする';

  @override
  String get biometricSignInPrompt => 'Bananatalkにログインするため認証してください';

  @override
  String get biometricNotAvailable => 'このデバイスでは生体認証ログインを利用できません。パスワードでログインしてください。';

  @override
  String get biometricNotEnrolled => 'このデバイスにFace IDまたは指紋が登録されていません。設定で登録するか、パスワードでログインしてください。';

  @override
  String get biometricLockedOut => '試行回数が多すぎます。生体認証が一時的にロックされました。後でもう一度試すか、パスワードでログインしてください。';

  @override
  String get biometricPermanentlyLockedOut => '生体認証がロックされています。パスコードでデバイスのロックを解除してから、もう一度お試しください。';

  @override
  String get biometricPasscodeNotSet => '生体認証ログインを使うには、デバイスのパスコードを設定してください。';

  @override
  String continueAs(String name) {
    return '$nameとしてログイン';
  }

  @override
  String get addProfilePhotoTitle => 'プロフィール写真を追加';

  @override
  String get addProfilePhotoSkip => '後で';

  @override
  String get wavesTab => 'あいさつ';

  @override
  String get sendWave => 'あいさつを送る';

  @override
  String sendWaveTo(String name) {
    return '$nameにあいさつを送る';
  }

  @override
  String waveSent(String name) {
    return '$nameにあいさつを送りました';
  }

  @override
  String waveCooldown(String name, String time) {
    return '$time後に$nameへ再度あいさつできます';
  }

  @override
  String get waveCouldntSend => 'あいさつを送れませんでした';

  @override
  String get itsAMatch => 'マッチしました！';

  @override
  String itsAMatchSubtitle(String name) {
    return '$nameさんとお互いにあいさつしました';
  }

  @override
  String get sendAMessage => 'メッセージを送る';

  @override
  String get waveQuickReplyHi => 'こんにちは！';

  @override
  String get waveQuickReplyCool => '素敵ですね';

  @override
  String get waveQuickReplyHey => 'やあ';

  @override
  String get waveQuickReplyChat => '話しましょう';

  @override
  String get waveQuickReplyHello => 'はじめまして';

  @override
  String waveQuickReplyFromCountry(String country) {
    return '$countryからこんにちは！';
  }

  @override
  String get waveCustomMessage => 'または自分でメッセージを書く…';

  @override
  String get voiceRoomChat => 'チャット';

  @override
  String get voiceRoomChatPlaceholder => 'メッセージを送る…';

  @override
  String get voiceRoomChatEmpty => 'まだメッセージがありません — 挨拶しましょう';

  @override
  String get voiceRoomChatSend => '送信';

  @override
  String voiceRoomChatNewBadge(int n) {
    return '$n';
  }

  @override
  String get voiceRoomEnd => 'ルームを終了';

  @override
  String get voiceRoomEndConfirm => 'このルームを終了しますか？';

  @override
  String get voiceRoomEndConfirmBody => '全員が切断されます。';

  @override
  String get voiceRoomKick => 'ルームから退出させる';

  @override
  String voiceRoomKickConfirm(String name) {
    return '$nameさんを退出させますか？';
  }

  @override
  String get voiceRoomKicked => '退出させました';

  @override
  String get voiceRoomYouAreHostNow => 'あなたがホストになりました';

  @override
  String voiceRoomHostChanged(String name) {
    return '$nameさんがホストになりました';
  }

  @override
  String get voiceRoomHostMenuTitle => 'ルーム操作';

  @override
  String get voiceRoomViewProfile => 'プロフィールを見る';

  @override
  String get voiceRoomReconnecting => '再接続中…';

  @override
  String get voiceRoomReconnected => '再接続しました';

  @override
  String get voiceRoomEnded => 'ルームが終了しました';

  @override
  String get voiceRoomReconnectRetry => '再試行';

  @override
  String get mutualInterests => '共通の趣味';

  @override
  String interestsInCommon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '共通の趣味が$countつ',
      one: '共通の趣味が1つ',
      zero: '共通の趣味はまだありません',
    );
    return '$_temp0';
  }

  @override
  String get interestsInCommonSeeAll => 'すべて見る';

  @override
  String get interestsInCommonAddCta => 'トピックを追加';

  @override
  String get interestsInCommonAddSubtitle => 'プロフィールにトピックを追加して共通点を見つけましょう';

  @override
  String activeAgo(String time) {
    return '$time前にアクティブ';
  }

  @override
  String get filterOnlineNow => '今オンライン';

  @override
  String get filterAge => '年齢';

  @override
  String get filterGender => '性別';

  @override
  String get filterLanguages => '言語';

  @override
  String get filterCountry => '国';

  @override
  String get filterTopics => 'トピック';

  @override
  String get filterLevel => '語学レベル';

  @override
  String get filterToggles => 'その他';

  @override
  String filterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人のパートナーが一致',
      one: '1人のパートナーが一致',
      zero: '一致するパートナーなし',
    );
    return '$_temp0';
  }

  @override
  String get filterClearAll => 'すべてクリア';

  @override
  String get filterReset => 'リセット';

  @override
  String get filterApply => '適用';

  @override
  String get filterNewUsers => '新規ユーザーのみ';

  @override
  String get filterPrioritizeNearby => '近くを優先';

  @override
  String get filterSheetTitle => 'フィルター';

  @override
  String get notificationPreferencesTitle => '通知';

  @override
  String get notificationPreferencesSubtitle => '受け取るアラートを選択してください';

  @override
  String get notifPrefChat => '新しいメッセージ';

  @override
  String get notifPrefWave => 'ウェーブ';

  @override
  String get notifPrefVoiceRoomStart => 'ボイスルームの招待';

  @override
  String get notifPrefScheduledRoomReminder => '予定済みルームのリマインダー';

  @override
  String get notifPrefFollowerMoment => 'フォロー中のユーザーの新しいモーメント';

  @override
  String get notifPrefVisitorAlert => 'プロフィール訪問者';

  @override
  String get notifPrefMatchAlert => '相互ウェーブ';

  @override
  String get notifResetToDefaults => 'デフォルトにリセット';

  @override
  String get themeMode => 'テーマ';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeSystem => 'システム';

  @override
  String get languageSettingsRow => '言語';

  @override
  String get waveDailySummaryTitle => '新しいウェーブが届いています';

  @override
  String waveDailySummaryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人があなたにウェーブしました',
      one: '1人があなたにウェーブしました',
    );
    return '$_temp0';
  }

  @override
  String get filterTopicsTitle => 'トピック';

  @override
  String get filterTopicsEmpty => 'トピックが選択されていません';

  @override
  String get storiesEmpty => 'まだストーリーがありません';

  @override
  String get storiesLoadError => 'ストーリーを読み込めませんでした';

  @override
  String get storiesRetry => 'もう一度試す';

  @override
  String get storiesNoMore => 'すべて確認しました';

  @override
  String get createTextStoryTab => 'テキスト';

  @override
  String get createImageStoryTab => '写真';

  @override
  String get createVideoStoryTab => '動画';

  @override
  String get enterTextHint => 'タップして入力';

  @override
  String get pickBackground => '背景';

  @override
  String get pickFontStyle => 'フォント';

  @override
  String get pickTextColor => 'カラー';

  @override
  String get addEmoji => '絵文字を追加';

  @override
  String get chooseFont => 'フォントを選択';

  @override
  String get chooseColor => 'カラーを選択';

  @override
  String get dragToMove => 'ドラッグして移動';

  @override
  String get pinchToScale => 'ピンチで拡大縮小';

  @override
  String get removeFromHighlight => 'ハイライトから削除';

  @override
  String get highlightDeleted => 'ハイライトが削除されました';

  @override
  String get storySaved => 'ストーリーに保存しました';

  @override
  String get storyTooLong => 'テキストが長すぎます';

  @override
  String get storyPostFailed => 'ストーリーを投稿できませんでした';

  @override
  String get fontNormal => '通常';

  @override
  String get fontBold => '太字';

  @override
  String get fontItalic => '斜体';

  @override
  String get fontHandwriting => '手書き';

  @override
  String get pickDate => '日付を選択';

  @override
  String get pickTime => '時間を選択';

  @override
  String get upcomingRooms => '予定';

  @override
  String inHours(int h, int m) {
    return '$h時間$m分後';
  }

  @override
  String inMinutes(int m) {
    return '$m分後';
  }

  @override
  String get startsNow => '今すぐ開始';

  @override
  String get iWillBeThere => '参加します';

  @override
  String get cantMakeIt => '参加できません';

  @override
  String rsvpCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の参加',
      one: '1件の参加',
      zero: '参加者なし',
    );
    return '$_temp0';
  }

  @override
  String roomStartsIn1h(String title) {
    return '$titleは1時間後に始まります';
  }

  @override
  String roomStartsIn15min(String title) {
    return '$titleは15分後に始まります';
  }

  @override
  String roomStarted(String title) {
    return '$titleが今始まります';
  }

  @override
  String get cancelRoom => 'ルームをキャンセル';

  @override
  String get muteAll => '全員をミュート';

  @override
  String get mutedByHost => 'ホストが全員をミュートしました';

  @override
  String get muteAllConfirm => 'ルーム全員をミュートしますか？';

  @override
  String get categoryCasual => 'カジュアル';

  @override
  String get categoryLanguagePractice => '語学練習';

  @override
  String get categoryTopic => 'トピック';

  @override
  String get categoryQA => 'Q&A';

  @override
  String get pickCategory => 'カテゴリ';

  @override
  String get sortRecentlyActive => '最近アクティブ';

  @override
  String visitedYourProfile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人があなたのプロフィールを訪問しました',
      one: '1人があなたのプロフィールを訪問しました',
    );
    return '$_temp0';
  }

  @override
  String get noRecentVisitors => '最近の訪問者はいません';

  @override
  String get viewArchive => 'アーカイブを見る';

  @override
  String get archivedWaves => 'アーカイブ済みWave';

  @override
  String get noArchivedWaves => 'アーカイブ済みWaveなし';

  @override
  String get mutualInterestsMin => '共通の興味（最低）';

  @override
  String atLeastNTopics(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '少なくとも$nつの共通トピック',
      one: '少なくとも1つの共通トピック',
      zero: '任意',
    );
    return '$_temp0';
  }

  @override
  String get starterAskMoment => '彼らの最近の出来事を聞いてみよう';

  @override
  String get starterSayHi => '彼らの言語で挨拶しよう';

  @override
  String get starterCurious => '彼らが気になっていることは？';

  @override
  String starterFromCountry(String country) {
    return '$countryからこんにちは！';
  }

  @override
  String starterPracticeLang(String language) {
    return '$languageの練習を手伝ってあげよう！';
  }

  @override
  String get momentsLoadError => 'モーメントを読み込めません';

  @override
  String get momentsRetry => '再試行';

  @override
  String get recentTags => '最近のタグ';

  @override
  String get noRecentTags => '最近のタグはまだありません';

  @override
  String get hideMomentsFromUser => 'このユーザーのモーメントを非表示';

  @override
  String get momentsHidden => 'このユーザーのモーメントは非表示になります';

  @override
  String get unhideMoments => 'このユーザーのモーメントを表示';

  @override
  String momentsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人のユーザーを非表示',
      one: '1人のユーザーを非表示',
      zero: '非表示のユーザーなし',
    );
    return '$_temp0';
  }

  @override
  String get momentSaveFailed => 'モーメントを保存できませんでした';

  @override
  String get tagAlreadyAdded => 'タグはすでに追加されています';

  @override
  String get tagLimitReached => 'タグの上限に達しました';

  @override
  String get hideThisUser => 'このユーザーの投稿を非表示';

  @override
  String get transcribeMessage => '文字起こし';

  @override
  String get transcribing => '文字起こし中…';

  @override
  String get transcriptionFailed => '音声を文字起こしできませんでした';

  @override
  String saveToVocabulary(String word) {
    return '「$word」を単語帳に保存';
  }

  @override
  String get addedToVocabulary => '単語帳に追加されました';

  @override
  String get alreadyInVocabulary => 'すでに単語帳にあります';

  @override
  String get tapWordToSave => '長押しして単語を保存';

  @override
  String get autoTranslateChatHint => '受信メッセージが自動的に翻訳されます';

  @override
  String get noConversationsYet => 'まだ会話がありません';

  @override
  String get chatRetry => '再試行';

  @override
  String get learningHubTitle => '学習';

  @override
  String get learningCommonRetry => '再試行';

  @override
  String get learningCommonContinue => '続ける';

  @override
  String get learningCommonAwesome => 'すごい！';

  @override
  String get learningErrorGeneric => '問題が発生しました';

  @override
  String get learningStreakCurrent => '現在のストリーク';

  @override
  String get learningStreakLongest => '最長ストリーク';

  @override
  String learningStreakDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日',
    );
    return '$_temp0';
  }

  @override
  String learningStreakFreezeAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個のフリーズ利用可能',
      zero: 'フリーズなし',
    );
    return '$_temp0';
  }

  @override
  String get learningStreakFreezeUse => 'フリーズを使う';

  @override
  String get learningStreakFreezeDescription => 'フリーズは1日休んでもストリークを守ります。';

  @override
  String get learningStreakFreezeProtected => 'ストリーク保護済み！';

  @override
  String get learningStreakMilestone7 => '7日間ストリーク！';

  @override
  String get learningStreakMilestone30 => '30日間ストリーク！';

  @override
  String get learningStreakMilestone100 => '100日間ストリーク！';

  @override
  String get learningStreakMilestone365 => '365日間ストリーク！';

  @override
  String get learningWeeklyDigestTitle => '今週';

  @override
  String learningWeeklyDigestXp(int xp) {
    return '$xp XP 獲得';
  }

  @override
  String learningWeeklyDigestLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countレッスン',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestVocab(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count単語学習済み',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestDaysActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日アクティブ',
    );
    return '$_temp0';
  }

  @override
  String get learningWeeklyDigestTopAchievement => 'トップ実績';

  @override
  String learningWeeklyDigestTrendUp(int pct) {
    return '先週より$pct%アップ';
  }

  @override
  String learningWeeklyDigestTrendDown(int pct) {
    return '先週より$pct%ダウン';
  }

  @override
  String get learningWeeklyDigestTrendFlat => '先週と同じ';

  @override
  String get learningSrsDashboardTitle => '毎日のレビュー';

  @override
  String learningSrsDueToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今日$count枚',
      zero: '今日のカードなし',
    );
    return '$_temp0';
  }

  @override
  String learningSrsDueTomorrow(int count) {
    return '明日$count枚';
  }

  @override
  String learningSrsDueThisWeek(int count) {
    return '今週$count枚';
  }

  @override
  String get learningSrsStartReview => 'レビュー開始';

  @override
  String get learningSrsAllCaughtUp => 'すべて完了！';

  @override
  String get learningSrsKeepGoing => '続けよう';

  @override
  String get learningLeaderboardXpTab => 'XP';

  @override
  String get learningLeaderboardStreakTab => 'ストリーク';

  @override
  String get learningLeaderboardLanguageTab => '言語';

  @override
  String get learningLeaderboardFriendsTab => '友達';

  @override
  String get learningLeaderboardEmpty => 'まだランキングなし';

  @override
  String get learningLeaderboardYouLabel => 'あなた';

  @override
  String get learningLeaderboardFriendBadge => '友達';

  @override
  String get learningEmptyVocab => '覚えたい単語を追加しよう';

  @override
  String get learningEmptyLessons => 'まだレッスンがありません';

  @override
  String get learningEmptyQuizzes => 'クイズがありません';

  @override
  String get learningEmptyChallenges => '明日また確認しよう';

  @override
  String get learningEmptyAchievements => '最初の実績を獲得しよう';

  @override
  String get learningEmptySearchResults => '結果が見つかりません';

  @override
  String learningXpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String get learningLevelUp => 'レベルアップ！';

  @override
  String learningLevelReached(String level) {
    return '$levelに到達しました';
  }

  @override
  String get learningAchievementUnlocked => '実績解除';

  @override
  String get learningVocabularySearchHint => '単語を検索';

  @override
  String get learningVocabularyFilterAll => 'すべて';

  @override
  String get learningVocabularyFilterNew => '新規';

  @override
  String get learningVocabularyFilterLearning => '学習中';

  @override
  String get learningVocabularyFilterMastered => '習得済み';

  @override
  String get learningVocabularySortRecent => '最近';

  @override
  String get learningVocabularySortAlphabetical => 'アルファベット順';

  @override
  String get learningVocabularySortMastery => '習得度';

  @override
  String get learningVocabularyMasteryNew => '新規';

  @override
  String get learningVocabularyMasteryLearning => '学習中';

  @override
  String get learningVocabularyMasteryMastered => '習得済み';

  @override
  String get learningProgressLevelLabel => 'レベル';

  @override
  String learningProgressXpToNextLevel(int xp) {
    return '次のレベルまで$xp XP';
  }

  @override
  String get learningProgressWeeklyChartTitle => '過去7日間';

  @override
  String get aiTutorPronounceLoading => 'あなたのための文を選んでいます…';

  @override
  String get aiTutorPronounceTapToRecord => 'タップで録音';

  @override
  String get aiTutorPronounceTapToStop => 'タップで停止';

  @override
  String get aiTutorPronounceTranscribing => '聴いています…';

  @override
  String get aiTutorPronounceTryAgain => 'もう一度';

  @override
  String get aiTutorPronounceNext => '次へ';

  @override
  String get aiTutorPronounceUseYourOwn => '自分の文 ✏️';

  @override
  String get aiTutorPronounceCustomHint => '練習したい文を入力';

  @override
  String get aiTutorPronounceCustomCancel => 'キャンセル';

  @override
  String get aiTutorPronounceCustomUse => '使う';

  @override
  String get aiTutorPronounceQuitConfirm => '終了しますか？進行状況は保存されません。';

  @override
  String get aiTutorPronounceQuitYes => 'はい';

  @override
  String get aiTutorPronounceQuitNo => 'いいえ';

  @override
  String aiTutorPronounceSentenceOf(int current, int total) {
    return '文 $current/$total';
  }

  @override
  String get aiTutorPronounceSummaryTitle => '練習完了';

  @override
  String get aiTutorPronounceSummaryAvg => '平均スコア';

  @override
  String get aiTutorPronounceSummaryWeak => '練習すべき単語';

  @override
  String get aiTutorPronounceSaveClose => '保存して閉じる';

  @override
  String get aiTutorPronounceSaving => '保存中…';

  @override
  String get aiTutorChipPronounce => '発音';

  @override
  String aiTutorPlanPronunciation(int count, int completed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '発音練習 ($completed/$count)',
      one: '発音練習 ($completed/1)',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorPronounceStartHeadline => 'どう練習しますか？';

  @override
  String get aiTutorPronounceStartSubhead => '5文の練習を始めるには1つ選んでください。';

  @override
  String get aiTutorPronounceStartAITitle => 'AIが文を生成';

  @override
  String get aiTutorPronounceStartAISubtitle => 'レベルに合わせて、苦手な単語を中心に';

  @override
  String get aiTutorPronounceStartCustomTitle => '自分の文を使う';

  @override
  String get aiTutorPronounceStartCustomSubtitle => 'マスターしたい文を入力または貼り付け';

  @override
  String aiTutorQuotaRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今日あと$count回',
      one: '今日あと1回',
    );
    return '$_temp0';
  }

  @override
  String get submit => '送信';

  @override
  String get exit => '終了';

  @override
  String get previous => '前へ';

  @override
  String get aiDailyPracticeTitle => '毎日の練習';

  @override
  String get aiDailyPracticeTranslateThis => 'これを翻訳:';

  @override
  String get aiDailyPracticeSuggested => '提案:';

  @override
  String get aiDailyPracticeHint => 'あなたの翻訳';

  @override
  String get aiLanguagesLoading => '言語を読み込んでいます...';

  @override
  String get aiCopiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get aiGrammarHint => '分析するテキストを入力...';

  @override
  String get aiGrammarSectionOriginal => '原文';

  @override
  String get aiGrammarSectionCorrected => '修正された文';

  @override
  String aiGrammarSectionIssues(int count) {
    return '見つかった問題 ($count)';
  }

  @override
  String get aiGrammarSectionWell => 'うまくできたこと';

  @override
  String get aiGrammarSectionSuggestions => '提案';

  @override
  String get aiGrammarSectionSummary => 'まとめ';

  @override
  String get aiLessonBuilderLabelLanguage => '言語';

  @override
  String get aiLessonBuilderLabelLevel => 'レベル';

  @override
  String get aiLessonBuilderTopicHint => 'トピックを入力（例：\"食事とレストラン\"）';

  @override
  String aiLessonBuilderSaved(String title) {
    return 'レッスン \"$title\" を保存しました！';
  }

  @override
  String get aiLessonBuilderBackToLessons => 'レッスンに戻る';

  @override
  String get aiTranslationHint => '翻訳するテキストを入力...';

  @override
  String get aiTranslationSavedToVocab => '単語リストに保存しました';

  @override
  String aiTranslationCouldNotSave(String error) {
    return '保存できませんでした: $error';
  }

  @override
  String get aiQuizTitle => 'クイズ';

  @override
  String get aiQuizFailedToGenerate => 'クイズの生成に失敗';

  @override
  String get aiQuizSubmitTitle => 'クイズを送信？';

  @override
  String get aiQuizSubmitBody => '回答を送信してよろしいですか？';

  @override
  String get aiQuizExitTitle => 'クイズを終了？';

  @override
  String get aiQuizExitBody => '進行状況は失われます。';

  @override
  String get aiQuizAnswerHint => '答えを入力...';

  @override
  String get aiQuizTranslationHint => '翻訳を入力...';

  @override
  String get aiPronunciationPlayingAudio => 'オーディオ再生中...';

  @override
  String get aiPronunciationListenFirst => 'まず聴く';

  @override
  String get aiPronunciationHint => '練習するテキストを入力...';

  @override
  String aiTutorCouldNotLoad(String error) {
    return 'チューターを読み込めませんでした: $error';
  }

  @override
  String aiTutorPlanUnavailable(String error) {
    return 'プランが利用できません: $error';
  }

  @override
  String get aiTutorReplay => '再生';

  @override
  String get aiScenariosTitle => '練習シナリオ';

  @override
  String aiScenariosCouldNotLoad(String error) {
    return 'シナリオを読み込めませんでした: $error';
  }

  @override
  String get aiScenariosNoneAvailable => 'まだシナリオはありません。';

  @override
  String aiScenariosCouldNotStart(String error) {
    return '開始できませんでした: $error';
  }

  @override
  String aiScenariosForYourLevel(String level) {
    return 'あなたのレベル向け ($level)';
  }

  @override
  String get aiScenariosEasier => '易しい — ウォームアップ';

  @override
  String get aiScenariosHarder => '難しい — チャレンジ';

  @override
  String get aiRoleplayStillStarting => 'シナリオを準備中です — 少し待って再試行してください。';

  @override
  String aiRoleplaySendFailed(String error) {
    return '送信に失敗: $error';
  }

  @override
  String get aiRoleplayCouldNotGrade => '今回は採点できませんでした — 次回再試行してください。';

  @override
  String get aiConversationHistoryCompleted => '完了';

  @override
  String get aiConversationHistoryInProgress => '進行中';

  @override
  String get aiConversationMessageHint => 'メッセージを入力...';

  @override
  String get aiConversationTopicSpeak => '話せる言語';

  @override
  String get aiConversationTopicPractice => '練習';

  @override
  String aiToolsVipUpgradeDescription(String feature) {
    return 'VIPにアップグレードして $feature を解除！';
  }

  @override
  String get aiToolsVipBadge => 'VIP';

  @override
  String aiScenariosBannerPracticingIn(String language) {
    return '$languageで練習中';
  }

  @override
  String get aiScenariosBannerSubhead => '自分のレベルのシナリオを選ぶか、一段上に挑戦しよう。';

  @override
  String get chatListSearchHint => '検索または @ユーザー名 を入力';

  @override
  String get chatListFilterAll => 'すべて';

  @override
  String get chatListFilterUnread => '未読';

  @override
  String get chatListFilterOnline => 'オンライン';

  @override
  String get chatListNewChat => '新規チャット';

  @override
  String get chatListNewChatByUsernameTooltip => 'ユーザー名で新規チャット';

  @override
  String get chatListFindUser => 'ユーザー検索';

  @override
  String chatListFindUserSearchTerm(String term) {
    return '@$term を探す';
  }

  @override
  String get chatListDeleteConversation => '会話を削除';

  @override
  String chatListMediaTitle(String name) {
    return '$name とのメディア';
  }

  @override
  String get chatListMediaError => 'メディアの読み込みエラー';

  @override
  String get chatDetailViewFullProfile => 'プロフィール全体を表示';

  @override
  String get chatMessageReply => '返信';

  @override
  String get chatMessageCopy => 'コピー';

  @override
  String get chatMessageCorrect => '訂正';

  @override
  String get chatMessageTranslate => '翻訳';

  @override
  String get chatMessageSavePhrase => 'フレーズ保存';

  @override
  String get chatMessageEdit => '編集';

  @override
  String get chatMessageDelete => '削除';

  @override
  String get chatMessageRetrySubtitle => 'このメッセージを再送';

  @override
  String get chatMessageRemoveSubtitle => 'このメッセージを削除';

  @override
  String get chatWallpaperPreviewHello => 'こんにちは！👋';

  @override
  String get chatWallpaperPreviewHow => '元気？';

  @override
  String get chatGifSearchHint => 'GIFを検索...';

  @override
  String get communitySearchHint => '検索または @ユーザー名 を入力';

  @override
  String communityUserNotFound(String name) {
    return 'ユーザー @$name が見つかりません';
  }

  @override
  String get communityTabAll => 'すべて';

  @override
  String get communityTabGender => '性別';

  @override
  String get communityTabCity => '都市';

  @override
  String get communityRefresh => '更新';

  @override
  String get communityNoUsersFound => 'ユーザーが見つかりません';

  @override
  String communityUnblockConfirm(String name) {
    return '$name のブロックを解除しますか？';
  }

  @override
  String get communityUsernameCopied => 'ユーザー名をコピーしました！';

  @override
  String communityLocationDetected(String country) {
    return '場所: $country';
  }

  @override
  String get communityWaveLater => 'あとで';

  @override
  String get communityAboutMBTI => 'MBTI';

  @override
  String get voiceRoomReactTooltip => 'リアクション';

  @override
  String get momentsCancel => 'キャンセル';

  @override
  String get momentsNotNow => '今はしない';

  @override
  String get commonOK => 'OK';

  @override
  String commonError(String error) {
    return 'エラー: $error';
  }

  @override
  String get chatActiveJustNow => '今アクティブ';

  @override
  String chatActiveMinAgo(int min) {
    return '$min分前アクティブ';
  }

  @override
  String get chatActiveHourAgo => '1時間前アクティブ';

  @override
  String chatActiveHoursAgo(int hours) {
    return '$hours時間前アクティブ';
  }

  @override
  String get chatActiveYesterday => '昨日アクティブ';

  @override
  String chatActiveDaysAgo(int days) {
    return '$days日前アクティブ';
  }

  @override
  String get chatSayHiPrompt => '挨拶して会話を始めよう！';

  @override
  String get communityConversationStartersTitle => '会話のきっかけ';

  @override
  String communityConversationStartersTopic(String topic) {
    return '二人とも$topicが好き — お気に入りを聞こう！';
  }

  @override
  String get communityConversationStartersDefault => '挨拶して自己紹介しよう！';

  @override
  String get communityConversationChatAction => 'チャット';

  @override
  String get communityConversationMessageCopied => 'メッセージをコピー！貼り付けて送信。';

  @override
  String get communityConversationCopiedToast => 'コピーしました！';

  @override
  String get communityLanguageMatchTitle => '言語マッチ';

  @override
  String get communityLanguageMatchNative => '母語';

  @override
  String get communityLanguageMatchLearning => '学習中';

  @override
  String get communityLanguageMatchPerfect => '完璧な言語交換マッチ！';

  @override
  String get communityLanguageMatchSameNative => '母語が同じです';

  @override
  String get momentsFilterApply => '適用';

  @override
  String get momentsCreateAddTo => 'モーメントに追加';

  @override
  String get momentsCreateCategory => 'カテゴリ';

  @override
  String get momentsCreateLanguage => '言語';

  @override
  String get momentsCreateSchedule => 'スケジュール（任意）';

  @override
  String get momentsCreateScheduleForLater => '後で投稿';

  @override
  String get momentsPrivacyPublic => '公開';

  @override
  String get momentsPrivacyFriends => '友達';

  @override
  String get momentsPrivacyPrivate => '非公開';

  @override
  String get splashTagline => '学ぶ · 話す · 出会う';

  @override
  String get splashLoading => '読み込み中…';

  @override
  String get supportSheetGreeting => 'こんにちは、フィルダウスです 👋';

  @override
  String get supportSheetStory => 'Bananatalkは一人で作りました — 画面、機能、深夜のバグ修正まで全て。世界中の語学学習者がつながり成長できるよう、常に新機能を追加しています。\n\nBananatalkが少しでもお役に立てたなら、コーヒー一杯分のサポートが開発継続の大きな励みになります。ソロ開発者にとって、あなたの応援は何より嬉しいです。 🙏';

  @override
  String get supportSheetDonateButton => 'PayPalで寄付する';

  @override
  String get supportSheetWatchAd => '広告を見てサポートする';

  @override
  String get occupation => '職業';

  @override
  String get school => '学校';

  @override
  String get occupationSearchHint => '職業を検索';

  @override
  String get occupationSelectedLabel => '選択中';

  @override
  String get occupationCustomLabel => 'カスタム入力';

  @override
  String get occupationNoMatches => '一覧に一致するものがありません';

  @override
  String get occupationCatTech => 'テクノロジー・ソフトウェア';

  @override
  String get occupationCatHealthcare => '医療・ヘルスケア';

  @override
  String get occupationCatEducation => '教育・学術';

  @override
  String get occupationCatBusiness => 'ビジネス・金融';

  @override
  String get occupationCatCreative => 'クリエイティブ・デザイン';

  @override
  String get occupationCatMedia => 'メディア・コミュニケーション';

  @override
  String get occupationCatEngineering => 'エンジニアリング';

  @override
  String get occupationCatScience => '科学・研究';

  @override
  String get occupationCatLegal => '法務';

  @override
  String get occupationCatHospitality => 'ホスピタリティ・飲食';

  @override
  String get occupationCatTrades => '技能職';

  @override
  String get occupationCatTransport => '運輸・物流';

  @override
  String get occupationCatGovernment => '公務・行政';

  @override
  String get occupationCatRetail => '小売・接客';

  @override
  String get occupationCatAgriculture => '農業・環境';

  @override
  String get occupationCatSports => 'スポーツ・フィットネス';

  @override
  String get occupationCatBeauty => '美容・パーソナルケア';

  @override
  String get occupationCatRealEstate => '不動産・建設';

  @override
  String get occupationCatReligion => '宗教・スピリチュアル';

  @override
  String get occupationCatStudent => '学生';

  @override
  String get occupationCatOther => 'その他';

  @override
  String get schoolHint => '例：東京大学、リンカーン高校';

  @override
  String get birthdate => '生年月日';

  @override
  String get birthdateSelectHelp => '生年月日を選択してください';

  @override
  String get birthdateSelectPlaceholder => '日付を選択';

  @override
  String birthdateMinAgeError(int age) {
    return '$age歳以上である必要があります。';
  }

  @override
  String birthdateQuotaRemaining(int remaining, int max) {
    return '今後60日間で生年月日の変更があと$max回中$remaining回残っています。';
  }

  @override
  String birthdateQuotaLocked(int max) {
    return 'この60日間で生年月日の変更を$max回すべて使用しました。';
  }

  @override
  String birthdateNextChangeOn(String date) {
    return '次回の変更可能日：$date';
  }

  @override
  String get birthdateRateLimited => '生年月日は60日間に3回までしか変更できません。';

  @override
  String birthdateRateLimitedUntil(String date) {
    return '生年月日は60日間に3回までしか変更できません。$dateに再度お試しください。';
  }

  @override
  String get changePassword => 'パスワードを変更';

  @override
  String get currentPassword => '現在のパスワード';

  @override
  String get newPasswordLabel => '新しいパスワード';

  @override
  String get confirmNewPassword => '新しいパスワードを確認';

  @override
  String get currentPasswordHint => '現在のパスワードを入力';

  @override
  String get newPasswordHint => '8文字以上、A-Z、a-z、0-9';

  @override
  String get passwordsDontMatch => 'パスワードが一致しません。';

  @override
  String get newPasswordSameAsCurrent => '新しいパスワードは現在のものと異なる必要があります。';

  @override
  String get passwordChangedSuccess => 'パスワードが変更されました';

  @override
  String get passwordRule8Chars => '8文字以上';

  @override
  String get passwordRuleLowercase => '小文字を1つ';

  @override
  String get passwordRuleUppercase => '大文字を1つ';

  @override
  String get passwordRuleNumber => '数字を1つ';

  @override
  String get settingsAccountSection => 'アカウント';

  @override
  String get changePasswordTileSubtitle => 'アカウントのパスワードを更新';

  @override
  String get occupationCustomTab => 'カスタム';

  @override
  String get occupationCustomTabHint => '職業が見つかりませんか？こちらに入力してください。';

  @override
  String get occupationCustomInputHint => '例：海洋生物学者、声優';

  @override
  String get occupationCustomSaveCTA => 'これを職業として使用';

  @override
  String get vipSelectPlan => 'プランを選択';

  @override
  String get vipBenefits => '特典';

  @override
  String get vipBestValue => 'おすすめ';

  @override
  String get vipPlanMonth => '1か月';

  @override
  String get vipPlanThreeMonths => '3か月';

  @override
  String get vipPlanTwelveMonths => '12か月';

  @override
  String get vipOneTime => '買い切り';

  @override
  String get vipNonVip => '一般';

  @override
  String get vipBenefitDailyTranslations => '1日の翻訳数';

  @override
  String get vipBenefitTranslationsLimit => '1日5回';

  @override
  String get vipBenefitUnlimited => '無制限';

  @override
  String get vipBenefitAdvancedFilters => '高度なフィルター';

  @override
  String get vipBenefitAdFree => '広告非表示';

  @override
  String get vipBenefitVipBadge => 'プロフィールにVIPバッジ';

  @override
  String get vipBenefitPrioritySupport => '優先サポート';

  @override
  String get vipBrandTitle => 'BananaTalk VIP';

  @override
  String get vipTagline => '世界とつながるパスポート — 本物の会話、長く続く友情を。';

  @override
  String get vipDisclosure => '期間終了の24時間前までに解約しない限り自動更新されます。お支払いはiTunesまたはGoogle Playアカウントに請求されます。';

  @override
  String get vipLoginRequired => '続行するにはログインしてください';

  @override
  String get chatListMenu => 'Menu';

  @override
  String get chatListNewMessageAlertsTitle => '新着メッセージの通知';

  @override
  String get chatListNewMessageAlertsBody => 'タップして通知をオンにすると、メッセージを見逃しません';

  @override
  String get chatListFilterMyTurn => '自分の番';

  @override
  String get partnerTagActiveNow => '現在アクティブ';

  @override
  String get partnerTagVeryResponsive => 'とても返信が丁寧';

  @override
  String get partnerTagQuickToReply => '返信が早い';

  @override
  String vipSavePercent(int pct) {
    return '$pct%お得';
  }

  @override
  String vipPerMonth(String price) {
    return '月 $price';
  }

  @override
  String partnerTagBothLike(String topic) {
    return '二人とも$topicが好き';
  }

  @override
  String partnerTagSpeaks(String language) {
    return '$languageを話します';
  }

  @override
  String partnerTagLearning(String language) {
    return '$languageを学習中';
  }

  @override
  String partnerTagJoinedDaysAgo(int days) {
    return '$days日前に参加';
  }

  @override
  String get vipPaymentPlanSummary => 'プランの概要';

  @override
  String get vipPaymentSelectMethod => 'お支払い方法を選択';

  @override
  String get vipPaymentPurchaseAppStore => 'App Storeで購入';

  @override
  String get vipPaymentPurchaseGooglePlay => 'Google Playで購入';

  @override
  String get vipPaymentSecureAppStore => 'お支払いはApp Storeを通じて安全に処理されます。';

  @override
  String get vipPaymentSecureGooglePlay => 'お支払いはGoogle Playを通じて安全に処理されます。';

  @override
  String get vipPaymentSubscriptionInfo => 'サブスクリプション情報';

  @override
  String get vipPaymentInfoLabelTitle => 'タイトル';

  @override
  String get vipPaymentInfoLabelLength => '期間';

  @override
  String get vipPaymentInfoLabelPrice => '価格';

  @override
  String get vipPaymentDisclosure => '購入を完了すると、利用規約とプライバシーポリシーに同意したものとみなされます。現在の期間終了の24時間前までに解約しない限り、サブスクリプションは自動で更新されます。';

  @override
  String get vipSuccessTitle => 'VIPへようこそ！';

  @override
  String get vipSuccessBody => 'VIPサブスクリプションが有効になりました。すべてのプレミアム機能をお楽しみください！';

  @override
  String get vipPendingTitle => 'もう少しお待ちください';

  @override
  String get vipPendingBody => 'サブスクリプションを処理中です。少ししてから再読み込みしてください。';

  @override
  String get vipErrorPaymentTitle => 'お支払いエラー';

  @override
  String get vipErrorPurchaseTitle => '購入エラー';

  @override
  String get vipErrorVerifyTitle => '購入の確認に失敗しました';

  @override
  String get vipErrorPaymentFailed => 'お支払いに失敗しました';

  @override
  String get vipErrorBodyPrefix => 'お支払いの処理中にエラーが発生しました:';

  @override
  String get vipErrorPurchaseCanceled => '購入がキャンセルされたか失敗しました。もう一度お試しください。';

  @override
  String get vipErrorVerifyServer => 'サーバーで購入を確認できませんでした。サポートにお問い合わせください。';

  @override
  String get vipPlanLengthOneMonth => '1か月';

  @override
  String get vipPlanLengthThreeMonths => '3か月';

  @override
  String get vipPlanLengthOneYear => '1年';

  @override
  String vipPaymentPayPrice(String price) {
    return '$priceを支払う';
  }

  @override
  String get vipExpired => 'VIP期限切れ';

  @override
  String get vipMember => 'VIP会員';

  @override
  String get chatPhrasesMostUsed => 'よく使う';

  @override
  String get chatPhrasesTopics => 'トピック';

  @override
  String get chatPhrasesAddPhrase => 'フレーズを追加';

  @override
  String get chatPhrasesChange => '変更';

  @override
  String get chatPhrasesAddTitle => 'フレーズを追加';

  @override
  String get chatPhrasesAddHint => 'よく使うフレーズを入力してください';

  @override
  String get chatPhrasesEmptyMostUsed => '保存されたフレーズがありません。+ をタップして追加してください。';

  @override
  String get chatPhrasesDeleteTitle => 'このフレーズを削除しますか？';

  @override
  String get filterVipPromoTitle => '理想の相手をもっと早く見つけよう';

  @override
  String get filterVipPromoSubtitle => 'VIPで優先表示、高度なフィルター、広告非表示のチャットを開放。';

  @override
  String get filterVipPromoCta => 'VIPへ';

  @override
  String get examStudy => '試験対策';

  @override
  String get examStudyChooseLanguage => '学習する言語を選択';

  @override
  String get examStudyChooseLanguageSubtitle => '試験対策をしたい言語を選んでください。';

  @override
  String get examStudyLoading => 'Loading…';

  @override
  String get examStudyEmptyLanguages => '利用できる学習言語はまだありません。';

  @override
  String get examStudyError => '読み込めませんでした。もう一度お試しください。';

  @override
  String get examStudyRetry => 'Retry';

  @override
  String get examPickExam => '試験を選択';

  @override
  String get examPickExamSubtitle => '対策したい試験を選んでください。';

  @override
  String get examPickEmpty => 'この言語の試験はまだありません。';

  @override
  String get examDashboardSections => 'Sections';

  @override
  String get examDashboardEmptySections => '練習できるセクションはまだありません。';

  @override
  String get examDashboardContinue => '練習を続ける';

  @override
  String get examDashboardStartStudyPlan => '学習プランを開始';

  @override
  String get examDashboardViewProgress => '進捗を見る';

  @override
  String examMetaDuration(int minutes) {
    return '$minutes分';
  }

  @override
  String examMetaMaxScore(String score) {
    return '最高$score点';
  }

  @override
  String examMetaSections(int count) {
    return '$countセクション';
  }

  @override
  String get examSectionNotStarted => '未開始';

  @override
  String examSectionProgress(int done, int total) {
    return '$done/$total完了';
  }

  @override
  String get examQuestionSubmit => '回答を送信';

  @override
  String get examQuestionNext => '次の問題';

  @override
  String get examQuestionCorrect => 'Correct!';

  @override
  String get examQuestionIncorrect => '不正解';

  @override
  String get examQuestionExplanation => '解説';

  @override
  String get examQuestionNoQuestions => 'このセクションにはまだ問題がありません。';

  @override
  String get examQuestionEssayComingSoon => '作文の採点は近日公開。今はリーディングを試してみてください。';

  @override
  String get examQuestionUnsupported => 'この問題形式にはまだ対応していません。';

  @override
  String get examPracticeFinishedTitle => 'セクション完了';

  @override
  String get examPracticeFinishedBody => 'お見事 — このセクションの全問題を終えました。';

  @override
  String get examPracticeBackToDashboard => 'ダッシュボードに戻る';

  @override
  String examPracticeProgress(int current, int total) {
    return '$total問中$current問目';
  }

  @override
  String get examEssayPrompt => '作文を書く';

  @override
  String examEssayMinChars(int min) {
    return '作文は$min文字以上必要です';
  }

  @override
  String examEssayMaxChars(int max) {
    return '作文は$max文字以内にしてください';
  }

  @override
  String examEssayWordCount(int count) {
    return '$count語';
  }

  @override
  String examEssayCharCount(int count) {
    return '$count文字';
  }

  @override
  String get examEssaySubmit => '作文を提出';

  @override
  String get examEssayEvaluating => '作文を採点しています…';

  @override
  String get examEssayEvaluatingHint => '通常10〜30秒ほどかかります。この画面を離れても、バックグラウンドで採点を続けます。';

  @override
  String get examEssayResultTitle => '評価';

  @override
  String get examEssayResultStrengths => '良かった点';

  @override
  String get examEssayResultImprovements => '改善の提案';

  @override
  String get examEssayResultScore => 'Score';

  @override
  String get examEssayResultFailed => 'この作文を採点できませんでした。';

  @override
  String get examEssayResultRetry => 'もう一度試す';

  @override
  String get examEssayResultDone => 'Done';

  @override
  String get examEssayPollTimeout => 'まだ採点中です。1分後にもう一度ご確認ください。';

  @override
  String get examEssayPollRefresh => 'もう一度確認';

  @override
  String examEssayQuotaUsed(int used, int limit) {
    return '本日の作文採点：$used/$limit';
  }

  @override
  String get examEssayQuotaExhausted => '本日の無料採点を使い切りました。VIPなら無制限です。';

  @override
  String get examEssayQuotaUpgrade => 'VIPにアップグレード';

  @override
  String get examEssayDraftRestored => '下書きを復元しました';

  @override
  String get examProgressTitle => 'Progress';

  @override
  String get examProgressOverall => '総合スコア';

  @override
  String get examProgressNotStartedTitle => 'まだ練習していません';

  @override
  String get examProgressNotStartedBody => 'どれかのセクションで何問か解くと、ここに進捗が表示されます。';

  @override
  String get examProgressFocusAreas => '重点分野';

  @override
  String examProgressSectionAttempts(int done, int total) {
    return '$total問中$done問に挑戦';
  }

  @override
  String get examProgressNoFocusAreas => 'どのセクションも good です — この調子で続けましょう！';

  @override
  String get examPlanSetupTitle => '学習プランを開始';

  @override
  String get examPlanTargetScore => '目標スコア';

  @override
  String get examPlanExamDate => '試験日';

  @override
  String get examPlanPickDate => '日付を選択';

  @override
  String get examPlanGenerate => 'プランを作成';

  @override
  String get examPlanGenerating => 'プランを作成しています…';

  @override
  String get examPlanInvalidDate => '未来の試験日を選んでください。';

  @override
  String get examPlanInvalidScore => '有効な目標スコアを入力してください。';

  @override
  String get examPlanTitle => '学習プラン';

  @override
  String get examPlanEmptyTitle => '有効なプランがありません';

  @override
  String get examPlanEmptyBody => '弱点に合わせた週ごとの目標を得るには、プランを作成してください。';

  @override
  String get examPlanRegenerate => 'プランを作り直す';

  @override
  String examPlanWeek(int n) {
    return '第$n週';
  }

  @override
  String examPlanWeekEstimate(String hours) {
    return '${hours}h';
  }

  @override
  String examPlanTotalHours(int hours) {
    return '合計$hours時間';
  }

  @override
  String get examPlanDailyHeading => 'おすすめの毎日のレッスン';

  @override
  String examPlanLessonMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get examTopicPickerTitle => 'トピックを選択';

  @override
  String get examTopicPickerSubtitle => '特定のトピックで練習するか、全問題に進みます。';

  @override
  String get examTopicAllTopics => 'すべてのトピック';

  @override
  String get examTopicAllTopicsDescription => '利用できる全トピックから出題';

  @override
  String get examTopicEmpty => 'No topical content yet. Tap All topics to start practicing.';

  @override
  String examTopicQuestionCount(int count) {
    return '$count問';
  }

  @override
  String get examTopicOneQuestion => '1問';

  @override
  String get examSpeakingPrompt => '答えを話してください';

  @override
  String get examSpeakingListenToPrompt => 'Listen to prompt';

  @override
  String get examSpeakingTapToRecord => 'タップして回答を録音';

  @override
  String get examSpeakingTranscriptHeading => '聞き取った内容';

  @override
  String get examSpeakingPart1 => 'Speaking — Part 1';

  @override
  String get examSpeakingPart2 => 'Speaking — Part 2';

  @override
  String get examSpeakingPart3 => 'Speaking — Part 3';

  @override
  String get examSpeakingSubmit => '録音を送信';

  @override
  String get examSpeakingUploading => 'アップロード中…';

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
      other: '$count課題',
      one: '1課題',
    );
    return '$_temp0';
  }

  @override
  String examGroupSpeakingSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countパート',
      one: '1パート',
    );
    return '$_temp0';
  }

  @override
  String get examVocabLevelPickerTitle => 'レベルを選択';

  @override
  String get examVocabLevelPickerSubtitle => 'CEFRレベル別に単語と練習クイズを見る。';

  @override
  String get examVocabTopicPickerTitle => 'トピックを選択';

  @override
  String get examVocabAllTopics => 'すべてのトピック';

  @override
  String get examVocabBrowse => 'Browse';

  @override
  String get examVocabPractice => 'Practice';

  @override
  String get examVocabEmptyList => 'このレベルとトピックの単語はまだありません。';

  @override
  String get examVocabQuizComplete => 'クイズ完了';

  @override
  String examVocabQuizScore(int correct, int total) {
    return '$total問中$correct問正解しました';
  }

  @override
  String get examVocabQuizYourAnswer => 'あなたの回答';

  @override
  String get examVocabQuizCorrectAnswer => '正解';

  @override
  String get examVocabQuizSubmit => 'Submit';

  @override
  String get examVocabQuizSubmitting => '送信中…';

  @override
  String get examVocabQuizNext => 'Next';

  @override
  String get examVocabQuizPrev => 'Back';

  @override
  String get examVocabQuizRestart => 'Restart';

  @override
  String get examVocabQuizEmpty => '問題を生成できませんでした。別のトピックかレベルをお試しください。';

  @override
  String get examVocabQuizNotEnough => 'このレベルとトピックではクイズを作るのに単語が足りません。';

  @override
  String get examVocabQuizExpiredTitle => 'クイズの有効期限切れ';

  @override
  String get examVocabQuizExpiredBody => 'このクイズは長時間放置されました。新しく始めてください。';

  @override
  String get examVocabTranslate => '翻訳';

  @override
  String get examVocabTranslateFailed => '翻訳を利用できません。しばらくしてからお試しください。';

  @override
  String get examDashboardTips => 'Tips';

  @override
  String get examTipsTitle => 'コツとテクニック';

  @override
  String examTipsSubtitle(String examName) {
    return '$examName向けに厳選した攻略メモ。';
  }

  @override
  String get examTipsEmpty => 'この試験のコツはまだ公開されていません。';

  @override
  String get examTipsCategoryStrategy => 'Strategy';

  @override
  String get examTipsCategoryGrammar => 'Grammar';

  @override
  String get examTipsCategoryVocabulary => '語彙';

  @override
  String get examTipsCategoryTimeManagement => '時間配分';

  @override
  String get examTipsCategoryCommonMistakes => 'よくある間違い';

  @override
  String get examTipsCategoryBandBooster => 'スコアアップ';

  @override
  String get examTipsCategoryCulturalNotes => '文化のポイント';

  @override
  String get examTipsCategoryPronunciation => '発音';

  @override
  String get examTipsCategoryFluency => 'Fluency';

  @override
  String get roomsNewRoom => '新しいルーム';

  @override
  String get roomsCouldNotLoad => 'ルームを読み込めませんでした';

  @override
  String get roomsEmptyTitle => '言語ルームはまだありません';

  @override
  String get roomsEmptySubtitle => 'しばらくお待ちください — ハブを準備中です。';

  @override
  String get roomCreateTitle => '新しいトピックルーム';

  @override
  String get roomCreateSubtitle => '言語ごとに集中したチャットを始めましょう';

  @override
  String get roomNameLabel => 'ルーム名';

  @override
  String get roomNameHint => '例：毎日の会話練習';

  @override
  String get roomDescriptionLabel => '説明（任意）';

  @override
  String get roomDescriptionHint => 'このルームは何についてですか？';

  @override
  String get roomCreateSubmit => 'ルームを作成';

  @override
  String get roomNameRequired => 'ルーム名を入力してください';

  @override
  String get roomCreateError => 'ルームを作成できませんでした。もう一度お試しください。';

  @override
  String get roomUsEnglish => 'アメリカ英語';

  @override
  String get roomUkEnglish => 'イギリス英語';

  @override
  String get roomFailedLoadMessages => 'メッセージを読み込めませんでした';

  @override
  String get roomReportMessageTitle => 'メッセージを報告';

  @override
  String get reportReasonSpam => 'スパム';

  @override
  String get reportReasonHarassment => 'ハラスメントまたはいじめ';

  @override
  String get reportReasonHateSpeech => 'ヘイトスピーチ';

  @override
  String get reportReasonViolence => '暴力または脅迫';

  @override
  String get reportReasonNudity => 'ヌードまたは性的なコンテンツ';

  @override
  String get reportReasonFalseInformation => '誤った情報';

  @override
  String get roomReportSubmitted => '報告を送信しました';

  @override
  String get roomReportSubmitFailed => '報告の送信に失敗しました';

  @override
  String get roomLeaveHubTitle => 'ハブを退出しますか？';

  @override
  String roomLeaveHubMessage(String title) {
    return '後で「ルーム」ディレクトリから$titleに再参加できます。';
  }

  @override
  String get roomLeaveHubFailed => 'ハブの退出に失敗しました';

  @override
  String get roomJoinRequestSent => 'リクエストを送信しました — 承認されると通知されます';

  @override
  String get roomJoinRequestFailed => 'リクエストの送信に失敗しました';

  @override
  String roomRequestsMenuItem(int count) {
    return 'リクエスト（$count）';
  }

  @override
  String get roomViewMembers => 'メンバーを見る';

  @override
  String get roomLeaveHubMenuItem => 'ハブを退出';

  @override
  String roomMemberOnlineCount(int members, int online) {
    return '$members人のメンバー・$online人がオンライン';
  }

  @override
  String get roomBannedRequestMessage => 'このルームから削除されました。再参加するにはリクエストを送信してください。オーナーの承認が必要です。';

  @override
  String get roomModeratedRequestMessage => 'これはモデレートされたルームです。参加するにはリクエストを送信してください。';

  @override
  String get roomRequestPending => 'リクエスト保留中';

  @override
  String get roomRequestToJoin => '参加をリクエスト';

  @override
  String get roomDailyPromptLabel => '今日のお題';

  @override
  String get roomSomeoneFallback => '誰か';

  @override
  String get roomRequestsLoadError => '参加リクエストを読み込めませんでした';

  @override
  String get roomRequestApproved => 'リクエストが承認されました';

  @override
  String get roomRequestDenied => 'リクエストが拒否されました';

  @override
  String get roomRequestApproveFailed => 'リクエストの承認に失敗しました';

  @override
  String get roomRequestDenyFailed => 'リクエストの拒否に失敗しました';

  @override
  String roomRequestsAppBarTitle(String title) {
    return '$title・リクエスト';
  }

  @override
  String get roomRequestsEmpty => '保留中のリクエストはありません';

  @override
  String get roomRequestDeny => '拒否';

  @override
  String get roomRequestApprove => '承認';

  @override
  String get roomMembersLoadError => 'メンバーを読み込めませんでした';

  @override
  String get roomRemoveBanTitle => 'メンバーを削除してBANしますか？';

  @override
  String get roomRemoveTitle => 'メンバーを削除しますか？';

  @override
  String roomRemoveBanConfirm(String name) {
    return '$nameを削除してBANしますか？リクエストを承認しない限り再参加できなくなります。';
  }

  @override
  String roomRemoveConfirm(String name, String title) {
    return '$nameを$titleから削除しますか？';
  }

  @override
  String get roomRemoveBanButton => '削除してBAN';

  @override
  String get roomRemoveButton => '削除';

  @override
  String get roomMemberRemovedBanned => 'メンバーを削除してBANしました';

  @override
  String get roomMemberRemoved => 'メンバーを削除しました';

  @override
  String get roomMemberRemoveFailed => 'メンバーの削除に失敗しました';

  @override
  String get roomMemberMuted => 'メンバーをミュートしました';

  @override
  String get roomMemberUnmuted => 'メンバーのミュートを解除しました';

  @override
  String get roomMemberMuteFailed => 'ミュート状態の更新に失敗しました';

  @override
  String roomMembersAppBarTitle(String title) {
    return '$title・メンバー';
  }

  @override
  String get roomMembersEmpty => '表示できるメンバーがいません';

  @override
  String get roomMemberMutedLabel => 'ミュート中';

  @override
  String get roomMemberFallbackName => 'メンバー';

  @override
  String get roomYourHub => 'あなたのハブ';

  @override
  String roomOnlineCount(int count) {
    return '$count人がオンライン';
  }

  @override
  String get roomNotAvailable => 'このルームはもう利用できません。';

  @override
  String get roomGoToRooms => 'ルーム一覧へ';

  @override
  String get todayTab => '今日';

  @override
  String get todaysGrammar => '今日の文法';

  @override
  String get todaysVocabulary => '今日の単語';

  @override
  String todayMinutes(int count) {
    return '$count分';
  }

  @override
  String get todayPickLanguage => '何を学んでいますか？';

  @override
  String todayLevelFallback(String served, String requested) {
    return '$servedを表示中 — $requestedのコンテンツはまだありません';
  }

  @override
  String get packTakePlacement => 'レベルを判定する';

  @override
  String todayContentLanguage(String language) {
    return '今日のレッスンは$languageです';
  }

  @override
  String get dailyCheck => '確認';

  @override
  String get dailyTooEasy => '簡単すぎる';

  @override
  String get dailyTooHard => '難しすぎる';

  @override
  String dailyScore(int score, int total) {
    return '$score/$total';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日連続',
    );
    return '$_temp0';
  }

  @override
  String dailyXpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String get todayEmpty => '今日の学習内容を準備中です。しばらくしてからご確認ください。';

  @override
  String todayLanguageUnsupported(String language) {
    return '$languageのデイリー学習はまだ利用できません。';
  }

  @override
  String get packContinue => '続ける';

  @override
  String get packGotIt => 'わかった';

  @override
  String get packSubmitFailed => '保存できませんでした。接続を確認してもう一度お試しください。';

  @override
  String packWordProgress(int current, int total) {
    return '$total 語中 $current 語目';
  }

  @override
  String packGrammarUnit(int unit) {
    return 'ユニット $unit';
  }

  @override
  String get packListeningPrompt => 'どの単語が聞こえましたか？';

  @override
  String packPlayClip(int number) {
    return '音声 $number を再生';
  }

  @override
  String get packReveal => '答えを見る';

  @override
  String get packKnewIt => 'わかった';

  @override
  String get packMissed => 'わからなかった';

  @override
  String get packTranslatePrompt => 'この文を訳してください';

  @override
  String get packTranslateHint => '訳を入力';

  @override
  String get packDone => '完了';

  @override
  String packTomorrowTeaser(String topic) {
    return '明日は「$topic」の続き';
  }

  @override
  String packContinueTo(String station) {
    return '続ける · $station';
  }

  @override
  String get packDoneForToday => '今日の分は完了';

  @override
  String get packStationVocabulary => '単語';

  @override
  String get packStationGrammar => '文法';

  @override
  String get packStationListening => 'リスニング';

  @override
  String get packStationReview => '復習';

  @override
  String get packStationWrap => '週のまとめテスト';

  @override
  String get packStationTranslate => '翻訳';

  @override
  String get masteryTitle => '学習の進み具合';

  @override
  String get masteryEmpty => '1 日分の学習を終えると、ここに進み具合が表示されます。';

  @override
  String get masteryYourLevel => 'あなたのレベル';

  @override
  String get masteryRetake => 'もう一度';

  @override
  String get masteryVocabulary => '単語';

  @override
  String get masteryGrammar => '文法';

  @override
  String get masteryListening => 'リスニング';

  @override
  String get masteryTranslate => '翻訳';

  @override
  String get masteryNotStarted => 'まだ始めていません';

  @override
  String masteryVocabularyCaption(int mastered, int learning, int due) {
    return '習得 $mastered · 学習中 $learning · 復習 $due';
  }

  @override
  String masteryGrammarCaption(int mastered, int total) {
    return '$total ユニット中 $mastered';
  }

  @override
  String masteryAccuracyCaption(int percent, int samples) {
    return '$samples 回で $percent%';
  }

  @override
  String get masteryConsistency => '過去 30 日';

  @override
  String masteryDueCta(int count) {
    return '$count 語を今すぐ復習';
  }

  @override
  String get placementTitle => 'レベル診断';

  @override
  String get placementSkip => 'スキップ';

  @override
  String placementProgress(int current, int total) {
    return '$total 問中 $current 問目';
  }

  @override
  String get placementResult => 'ここから始めます。いつでも変更できます。';

  @override
  String get placementStart => '学習を始める';

  @override
  String placementScore(int correct, int total) {
    return '$total問中$correct問正解';
  }

  @override
  String get placementReviewTitle => 'あなたの回答';

  @override
  String get placementFocusTitle => '次に取り組むこと';

  @override
  String get placementAllCorrect => 'すべて正解でした。このテストはB2までなので、レッスンは進めながら調整されます。';

  @override
  String get placementNotAnswered => '未回答';

  @override
  String get placementUnavailable => '学習中の言語にはまだレベルテストがありません。プロフィールで自分のレベルを設定できます。';

  @override
  String get placementPreparing => 'テストを準備しています…';

  @override
  String get packNotGraded => '保存しました。今は採点できませんでした。';

  @override
  String packSuggestedTranslation(String translation) {
    return '参考訳：$translation';
  }

  @override
  String get weeklyReportTitle => '今週の記録';

  @override
  String weeklyReportRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get weeklyReportDays => '学習した日数';

  @override
  String get weeklyReportStations => '終えたステーション';

  @override
  String get weeklyReportUnits => '習得した文法ユニット';

  @override
  String get weeklyReportWords => '新しい単語';

  @override
  String get weeklyReportAccuracy => '正解';

  @override
  String weeklyReportBestDay(String day, int count) {
    return '一番できた日は $day。$count ステーション完了';
  }

  @override
  String get weeklyReportEmpty => '今週はまだ学習がありません。1 日から始めましょう。';

  @override
  String get weeklyReportStart => '今日のパックを始める';

  @override
  String get gatheringsTabLabel => '集まり';

  @override
  String get gatheringClubs => 'クラブ';

  @override
  String get gatheringNewClub => '新しいクラブ';

  @override
  String get gatheringStartingSoon => 'まもなく開始';

  @override
  String get gatheringCreateShort => '新規';

  @override
  String get gatheringLoadFailed => '集まりを読み込めませんでした';

  @override
  String get gatheringEmptyTitle => '最初の一つを開きましょう';

  @override
  String get gatheringEmptyBody => 'まだ予定がありません。時間を決めて投稿してみてください — ホストがいる集まりには人が集まります。';

  @override
  String get gatheringStartAClub => '代わりにクラブを作る';

  @override
  String get gatheringToday => '今日';

  @override
  String get gatheringTomorrow => '明日';

  @override
  String get gatheringHappeningNow => '開催中';

  @override
  String gatheringStartsIn(int minutes) {
    return 'あと$minutes分で開始';
  }

  @override
  String gatheringHostZone(String zone) {
    return 'ホストのタイムゾーン: $zone';
  }

  @override
  String gatheringHostedBy(String name) {
    return 'ホスト: $name';
  }

  @override
  String gatheringQuorumNeeded(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '確定まであと$countLabel人',
      zero: '確定できます',
    );
    return '$_temp0';
  }

  @override
  String gatheringConfirmed(int count) {
    return '確定 · $count人が参加';
  }

  @override
  String get gatheringYouHost => 'あなたがホスト';

  @override
  String get gatheringGoingYou => '参加予定';

  @override
  String get gatheringFull => '満席';

  @override
  String get gatheringJoin => '参加する';

  @override
  String get gatheringAskToJoin => '参加を申請';

  @override
  String get gatheringRequested => '参加を申請しました — ホストが判断します';

  @override
  String get gatheringCreateTitle => '新しい集まり';

  @override
  String get gatheringCreateSubtitle => '時間と言語、そしていくつかの席。あとは任意です。';

  @override
  String gatheringDefaultTitle(String language) {
    return '$languageの練習';
  }

  @override
  String get gatheringTitleLabel => '何をしますか？';

  @override
  String get gatheringLanguageLabel => '言語';

  @override
  String get gatheringWhenLabel => '日時';

  @override
  String get gatheringSeatsLabel => '定員';

  @override
  String get gatheringQuorumLabel => '確定人数';

  @override
  String get gatheringQuorumExplainer => 'ホストのあなたも参加者に数えられます。この人数が集まると集まりが確定します。';

  @override
  String get gatheringPost => '投稿する';

  @override
  String get gatheringPosted => '投稿しました — 知らせましょう';

  @override
  String get gatheringNeedsTitle => 'まず名前をつけてください';

  @override
  String get gatheringNeedsLanguage => 'まず言語を選んでください';

  @override
  String get gatheringNeedsFuture => '未来の時間を選んでください';

  @override
  String get gatheringDetailTitle => '集まり';

  @override
  String get gatheringNotFound => 'この集まりは表示できなくなりました';

  @override
  String gatheringDuration(int minutes) {
    return '$minutes分';
  }

  @override
  String gatheringSeatsTaken(int going, int capacity) {
    return '$capacity席中$going席が埋まりました';
  }

  @override
  String get gatheringCancelled => '中止されました';

  @override
  String get gatheringEnded => 'この集まりは終了しました';

  @override
  String get gatheringCancelRsvp => '参加を取り消す';

  @override
  String gatheringHostDecision(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今のところ参加は$countLabel人です。開催しますか、中止しますか？',
    );
    return '$_temp0';
  }

  @override
  String get gatheringHostDecisionAlone => '今のところ参加はあなただけです。開催しますか、中止しますか？';

  @override
  String get gatheringRunAnyway => 'それでも開催';

  @override
  String get gatheringCallItOff => '中止する';

  @override
  String get gatheringEnd => '集まりを終了';

  @override
  String get gatheringEndedThanks => '終了しました — 会った人へのメッセージは無料です';

  @override
  String get gatheringCancelIt => '集まりを中止';

  @override
  String get gatheringKeepIt => 'そのままにする';

  @override
  String gatheringCancelConfirm(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countLabel人がこの集まりを待っています。中止を知らせます。',
      one: '1人がこの集まりを待っています。中止を知らせます。',
    );
    return '$_temp0';
  }

  @override
  String get clubDetailTitle => 'クラブ';

  @override
  String get clubNotFound => 'このクラブは表示できなくなりました';

  @override
  String clubMembers(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'メンバー$countLabel人',
    );
    return '$_temp0';
  }

  @override
  String get clubJoin => 'クラブに参加';

  @override
  String get clubLeave => 'クラブを退会';

  @override
  String get clubUpcoming => '今後の予定';

  @override
  String get clubNothingScheduled => 'まだ予定がありません。';

  @override
  String get clubHostGathering => '集まりを開く';

  @override
  String get clubCreateTitle => '新しいクラブ';

  @override
  String get clubCreateSubtitle => 'クラブは集まりと集まりの間も人をつなぎます。実際にやることで名前をつけましょう。';

  @override
  String get clubNameLabel => 'クラブ名';

  @override
  String get clubInterestLabel => '興味・関心';

  @override
  String get clubInterestHint => '任意 — ランニング、K-POP、HSK4';

  @override
  String get clubDescriptionLabel => '紹介';

  @override
  String get clubCreate => 'クラブを作成';

  @override
  String get clubNeedsName => 'まずクラブ名を入力してください';

  @override
  String gatheringRequests(int count) {
    return '参加待ち $count人';
  }

  @override
  String get gatheringAdmit => '承認';

  @override
  String get gatheringDeny => '拒否';

  @override
  String get gatheringsMine => 'マイ集まり';

  @override
  String get gatheringsMineEmpty => 'まだありません。主催または参加した集まりがここに表示されます。';

  @override
  String get gatheringsMineSubtitle => '主催または参加した集まり';

  @override
  String get gatheringSave => '保存';

  @override
  String get gatheringSaved => '変更を保存しました';

  @override
  String get gatheringEditIt => '編集';

  @override
  String get intentSectionTitle => 'ここに来た目的';

  @override
  String get intentLearn => '学びに来ました';

  @override
  String get intentMeet => '人と出会いたい';

  @override
  String get intentDate => 'デートに興味があります';

  @override
  String get intentPrivacyNote => '選んだ内容は表示されます。デートは非公開です。';

  @override
  String get gatheringNoClubsYet => 'まだクラブがありません。作れば集まりの拠点になります。';

  @override
  String get topicConversation => 'フリートーク';

  @override
  String get topicExamPrep => '試験対策';

  @override
  String get topicGrammar => '文法';

  @override
  String get topicPronunciation => '発音';

  @override
  String get topicCulture => '文化';

  @override
  String get topicMedia => '音楽・映画';

  @override
  String get topicGames => 'ゲーム';

  @override
  String get topicBusiness => 'ビジネス';

  @override
  String get topicTravel => '旅行';

  @override
  String get filterThisWeek => '今週';

  @override
  String get filterThisWeekend => '今週末';

  @override
  String get filterHasSeat => '空きあり';

  @override
  String filterClear(int count) {
    return '$count件クリア';
  }

  @override
  String get filterNoMatches => '条件に合う集まりはまだありません。';

  @override
  String get gatheringTopicLabel => 'トピック（任意）';

  @override
  String get avatarViewStory => 'ストーリーを見る';

  @override
  String get avatarViewPhoto => 'プロフィール写真を見る';

  @override
  String get composerNext => '次へ';

  @override
  String get notifyRepliesTitle => '返信が来たらお知らせします';

  @override
  String get notifyRepliesBody => '新しいメッセージと毎日の学習リマインダーをお届けします。どちらもいつでもオフにできます。';

  @override
  String get notifyRepliesEnable => 'オンにする';

  @override
  String get notifyRepliesLater => 'あとで';

  @override
  String get notificationsOffTitle => '通知がオフになっています';

  @override
  String get notificationsOffBody => '端末がBananaTalkの通知をブロックしているため、リマインダーやメッセージが届きません。オンにするまで下の設定は反映されません。';

  @override
  String get notificationsOffOpen => '設定を開く';

  @override
  String get reportGathering => '集まりを報告';

  @override
  String get reportClub => 'クラブを報告';

  @override
  String get finishProfileTitle => 'プロフィールの設定を完了してください';

  @override
  String get finishProfileBody => 'みんなが安全に使えるよう生年月日が必要です。続けない場合はログアウトできます。';

  @override
  String get finishProfileContinue => '続ける';

  @override
  String get finishProfileSignOut => 'ログアウト';

  @override
  String packReviewProgress(int current, int total) {
    return '復習 $current / $total';
  }

  @override
  String get packReviewRecall => 'この単語を覚えていますか？';

  @override
  String get clubOrganizers => '運営メンバー';

  @override
  String get clubMembersLabel => 'メンバー';

  @override
  String clubMeetsIn(String city) {
    return '$cityで開催';
  }

  @override
  String clubEventsHeld(int count) {
    return '開催実績 $count 回';
  }

  @override
  String get clubEdit => 'クラブを編集';

  @override
  String get clubDelete => 'クラブを削除';

  @override
  String get clubDeleteConfirmTitle => 'このクラブを削除しますか？';

  @override
  String get clubDeleteConfirmBody => '予定されている集まりは残ります — すでに参加予定の人がいます。クラブのみ削除されます。';

  @override
  String get clubRemoveMember => 'クラブから削除';

  @override
  String get clubMakeOrganizer => '運営メンバーにする';

  @override
  String get clubRemoveOrganizer => '運営から外す';

  @override
  String clubSince(String date) {
    return '$date に開設';
  }

  @override
  String get clubNoEventsHeld => 'まだ開催実績がありません';

  @override
  String get clubPlaceLabel => 'よく使う場所';

  @override
  String get groupCoverChange => '写真を変更';

  @override
  String get groupCoverFromLibrary => 'ライブラリから選ぶ';

  @override
  String get groupCoverTakePhoto => '写真を撮る';

  @override
  String get groupCoverRemove => '写真を削除';

  @override
  String get groupCoverAddOptional => '写真を追加（任意）';

  @override
  String get clubsMine => 'マイクラブ';

  @override
  String get clubsMineEmpty => 'まだクラブに参加していません';

  @override
  String get storyLink => 'リンク';

  @override
  String get storyLinkSubtitle => '閲覧者をページへ誘導';

  @override
  String get storyLinkAdd => 'リンクを追加';

  @override
  String get storyLinkUrlLabel => 'リンクのアドレス';

  @override
  String get storyLinkButtonLabel => 'ボタンの文言';

  @override
  String get storyLinkButtonDefault => '今すぐ見る';

  @override
  String storyLinkOpensHost(String host) {
    return '$host を開く';
  }

  @override
  String get storyLinkInvalid => '有効な http または https のアドレスを入力してください';

  @override
  String get storyStickerPoll => 'アンケート';

  @override
  String get storyStickerPollSubtitle => '選択肢つきの質問';

  @override
  String get storyStickerQuestion => '質問';

  @override
  String get storyStickerQuestionSubtitle => '閲覧者から回答を受け取る';

  @override
  String get storyStickerLocation => '位置情報';

  @override
  String get storyStickerLocationSubtitle => 'このストーリーの場所をタグ付け';

  @override
  String get storyStickerMention => 'メンション';

  @override
  String get storyStickerMentionSubtitle => 'フォロー中の人をタグ付け';

  @override
  String get storyToolDraw => 'お絵かき';

  @override
  String get momentsTabForYou => 'おすすめ';

  @override
  String get momentsTabReels => 'リール';

  @override
  String get storyArchiveTitle => 'アーカイブ';

  @override
  String get storyArchiveSubtitle => '期限切れのストーリー、自分だけに表示';

  @override
  String get storyArchiveEmpty => 'まだアーカイブはありません';

  @override
  String get storyArchiveEmptyBody => 'ストーリーは24時間後にここへ移ります。ハイライトに追加するとプロフィールに残せます。';

  @override
  String get storyArchiveAddHighlight => 'ハイライトに追加';

  @override
  String get storyArchiveAdded => 'ハイライトに追加しました';

  @override
  String get doneAction => '完了';

  @override
  String get noneOption => 'なし';

  @override
  String get stopAction => '停止';

  @override
  String get selectPlaceholder => '選択...';

  @override
  String get goVip => 'VIPになる';

  @override
  String get logoutFailed => 'ログアウトに失敗しました';

  @override
  String get vocabularyPacks => '単語パック';

  @override
  String get noVocabPacksYet => '利用できるパックはまだありません。';

  @override
  String get addWord => '単語を追加';

  @override
  String get deleteWord => '単語を削除';

  @override
  String get shuffleAction => 'シャッフル';

  @override
  String get exitLessonTitle => 'レッスンを終了しますか？';

  @override
  String get exitQuizTitle => 'クイズを終了しますか？';

  @override
  String get quizNotFound => 'クイズが見つかりません';

  @override
  String get vocabPackAddFailed => 'パックを追加できませんでした';

  @override
  String get vocabPackLoadFailed => 'パックを読み込めませんでした';

  @override
  String get addToMyVocab => '単語帳に追加';

  @override
  String get viewAiSummary => 'AI要約を見る';

  @override
  String get reRecord => '録り直す';

  @override
  String get practiceComplete => '練習完了';

  @override
  String get micPermissionNeeded => 'マイクの許可が必要です';

  @override
  String get thanksForParticipating => 'ご参加ありがとうございます！+10 XP 🎉';

  @override
  String deleteWordConfirm(String word) {
    return '単語帳から「$word」を削除しますか？';
  }

  @override
  String get wordDeleted => '単語を削除しました';

  @override
  String get vocabularyLoadFailed => '単語帳を読み込めませんでした';

  @override
  String get savedTitle => '保存済み';

  @override
  String get savedSubtitle => 'ブックマークしたリールとモーメント';

  @override
  String get introRequests => '紹介リクエスト';

  @override
  String get icebreakerWhyLearn => '新しい言語を学び始めたきっかけは何ですか？';

  @override
  String get icebreakerCanHelp => 'こんにちは！練習を手伝いますよ 😊';

  @override
  String get icebreakerFavoriteWord => 'あなたの言語で一番好きな言葉は何ですか？';

  @override
  String get icebreakerCoffeeChat => 'いつかコーヒー休憩に話しませんか？';

  @override
  String get icebreakerHowsWeek => '今週はどんな感じですか？';

  @override
  String get failedToLoadReels => 'リールを読み込めませんでした';

  @override
  String get failedToLoadSavedMoments => '保存済みの項目を読み込めませんでした';

  @override
  String get adNotReady => '広告の準備がまだです。少し後にもう一度お試しください';

  @override
  String get addQuickReply => 'クイック返信を追加';

  @override
  String get pollNeedQuestionAndOptions => '質問と2つ以上の選択肢を追加してください';

  @override
  String get addOne => '追加する';

  @override
  String get addScreenshotsOrPhotos => 'スクリーンショットや写真を追加';

  @override
  String get allowMultipleVotes => '複数投票を許可';

  @override
  String get attachImageOrTxt => '画像または .txt ファイルを添付';

  @override
  String get audioUploadFailed => '音声のアップロードに失敗しました';

  @override
  String get browseFiles => 'ファイルを参照';

  @override
  String get clearCompleted => '完了済みをクリア';

  @override
  String get closePollTitle => '投票を締め切りますか？';

  @override
  String get coinHistory => 'コイン履歴';

  @override
  String get coinShop => 'コインショップ';

  @override
  String get conversationSummary => '会話の要約';

  @override
  String get couldNotLoadFollowings => 'フォロー中を読み込めませんでした';

  @override
  String get couldNotLoadMoreHistory => 'これ以上の履歴を読み込めませんでした。';

  @override
  String get couldNotLoadChats => 'チャットを読み込めませんでした';

  @override
  String get decline => '辞退する';

  @override
  String get endConversationTitle => '会話を終了しますか？';

  @override
  String get explainAction => '解説';

  @override
  String get failedToPlayAudio => '音声を再生できませんでした';

  @override
  String get failedToSavePhrase => 'フレーズを保存できませんでした';

  @override
  String get freeRetryUnlocked => '無料の再挑戦が解除されました！🎉';

  @override
  String get getAnotherHint => 'ヒントをもう一つ';

  @override
  String get hideWhoVoted => '各選択肢に誰が投票したかを隠す';

  @override
  String get invalidQrCode => '無効なQRコード';

  @override
  String get linkCopiedToClipboard => 'リンクをクリップボードにコピーしました';

  @override
  String get loadMore => 'もっと読み込む';

  @override
  String get manage => '管理';

  @override
  String get maxTenOptions => '選択肢は最大10個までです';

  @override
  String get maybeLater => '後で';

  @override
  String get minTwoOptions => '選択肢は最低2つ必要です';

  @override
  String get noMoreVotesAfterClosing => '締め切り後は投票できなくなります。';

  @override
  String get noOneToMention => 'メンションできる人がまだいません';

  @override
  String get noRecentChatsToSendTo => '送信できる最近のチャットがありません';

  @override
  String get notEnoughCoins => 'コインが足りません。';

  @override
  String get oneOptionIsCorrect => '1つの選択肢が正解です';

  @override
  String get photoLibrary => '写真ライブラリ';

  @override
  String get phraseSavedToStudyQueue => 'フレーズを学習キューに保存しました';

  @override
  String get pleaseAddTwoOptions => '選択肢を2つ以上追加してください';

  @override
  String get pleaseAttachEvidence => '証拠としてファイルを1つ以上添付してください';

  @override
  String get pleaseEnterQuestion => '質問を入力してください';

  @override
  String get pleaseSelectReportReason => '報告の理由を選択してください';

  @override
  String get pleaseSelectCorrectAnswer => 'クイズの正解を選択してください';

  @override
  String get pollExpires => '投票の締め切り';

  @override
  String get quizMode => 'クイズモード';

  @override
  String get recordAReel => 'リールを撮影';

  @override
  String get reelsContentGuidelines => 'リールのコンテンツガイドライン';

  @override
  String get reportTypeMissing => '報告の種類がありません';

  @override
  String get reportedContentIdMissing => '報告されたコンテンツIDがありません';

  @override
  String get reportedUserIdMissing => '報告されたユーザーIDがありません';

  @override
  String get retryAll => 'すべて再試行';

  @override
  String get savedToVocabulary => '単語帳に保存しました！';

  @override
  String get savedFindInProfile => '保存しました。プロフィール → 保存済み で確認できます。';

  @override
  String get shareVia => '共有方法...';

  @override
  String get shareYourLocation => '位置情報を共有しますか？';

  @override
  String get suggestACorrection => '添削を提案';

  @override
  String get translationCopied => '翻訳をコピーしました';

  @override
  String get unlock => 'ロック解除';

  @override
  String get unlockPremiumWallpapers => 'プレミアム壁紙のロックを解除';

  @override
  String get uploadQueue => 'アップロード待ち';

  @override
  String get usersCanVoteMultiple => '複数の選択肢に投票できます';

  @override
  String get watchAd => '広告を見る';

  @override
  String get matchReasonReciprocal => 'お互いの言語を学んでいます';

  @override
  String matchReasonSameTarget(String language) {
    return '$languageも学習中';
  }

  @override
  String matchReasonSharedTopic(String topic) {
    return '共通の関心：$topic';
  }

  @override
  String get matchReasonActiveToday => '今日アクティブ';

  @override
  String get matchReasonSameCity => '同じ街に住んでいます';

  @override
  String get matchRepliesFast => '返信が早い';

  @override
  String matchesTodayTitle(int count) {
    return '今日のマッチ$count人';
  }

  @override
  String matchesRefreshHint(String time) {
    return '$timeに更新';
  }

  @override
  String get matchesRefreshHintFallback => '深夜0時に更新';

  @override
  String get matchesEmptyTitle => '今日はここまで';

  @override
  String get matchesEmptyBody => '新しいマッチは明日。それまでは全パートナーを見てみましょう。';

  @override
  String get matchesEmptyCta => 'パートナーを見る';

  @override
  String get matchSayHi => 'あいさつする';

  @override
  String get communityTabMatches => 'Matches';

  @override
  String get communityTabPartners => 'Partners';

  @override
  String get segmentAll => 'All';

  @override
  String get segmentSerious => '熱心な学習者';

  @override
  String get segmentNew => '新メンバー';

  @override
  String get segmentSeriousHint => 'プロフィール完成 · 今週アクティブ';

  @override
  String get segmentNewHint => '過去7日以内に参加';

  @override
  String openerReciprocal(String theirLanguage, String myLanguage) {
    return 'メッセージを半分$theirLanguage、半分$myLanguageにしませんか？お互いに直し合いましょう 😄';
  }

  @override
  String openerSharedTopic(String topic) {
    return '$topicがお好きなんですね。きっかけは何でしたか？';
  }

  @override
  String openerGeneric(String name, String language) {
    return 'こんにちは、$nameさん！$languageを勉強中です。コツはありますか？ 👋';
  }

  @override
  String get openerChipsTitle => '会話のきっかけ — タップして編集できます';

  @override
  String stallRescueTitle(String name) {
    return '$nameさんから質問が届いています 👀';
  }

  @override
  String get stallRescueHint => '返信が遅くなってごめんなさい！まだお話しできますか？ 😊';

  @override
  String get referralTitle => '友だちを招待';

  @override
  String get referralSubtitle => '友だちが参加するとコインがもらえます';

  @override
  String get referralYourCode => 'あなたの招待コード';

  @override
  String referralInvitedCount(int count) {
    return '招待した人数: $count';
  }

  @override
  String referralShareText(String code, String link) {
    return 'BananaTalkで一緒に話そう — 本物の人と語学を練習できます。招待コード $code を使ってね: $link';
  }

  @override
  String get referralCopy => 'コピー';

  @override
  String get referralShare => 'シェア';

  @override
  String get referralCopied => 'コピーしました';

  @override
  String referralClaimed(int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: '$coinsコインを獲得しました！',
    );
    return '$_temp0';
  }

  @override
  String get referralHowItWorks => '友だちがあなたのコードで登録してプロフィールを完成させると、2人ともコインがもらえます。';

  @override
  String get boostTitle => 'プロフィールをブースト';

  @override
  String get boostSubtitle => '24時間、より多くのパートナーに表示されます';

  @override
  String get boostFromMatches => 'もっと多くの人に見てもらう';

  @override
  String get boostedChip => 'ブースト中';

  @override
  String get boostCapacityFull => '現在ブーストの枠がすべて埋まっています — 数時間後にもう一度お試しください';

  @override
  String extraMatchesCta(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '+3人のマッチ — $costコイン',
    );
    return '$_temp0';
  }

  @override
  String get boostExplain => '言語が合うすべての人に、24時間「6番目のマッチ」として表示されます。';

  @override
  String boostCostLine(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '料金: $costコイン',
    );
    return '$_temp0';
  }

  @override
  String boostBalanceLine(int balance) {
    String _temp0 = intl.Intl.pluralLogic(
      balance,
      locale: localeName,
      other: '残高: $balanceコイン',
    );
    return '$_temp0';
  }

  @override
  String get boostConfirm => 'ブーストを確定';

  @override
  String get boostActiveTitle => 'ブースト実行中';

  @override
  String boostTimeLeft(String time) {
    return '残り $time';
  }

  @override
  String boostSeenBy(int count) {
    return 'これまで$count人に表示されました';
  }

  @override
  String get boostFailed => 'ブーストを開始できませんでした。もう一度お試しください。';

  @override
  String get rewardedLimitReached => '今日の無料アンロックは使い切りました。明日もう一度お試しください';

  @override
  String get wavesMaskedTitle => '誰かがあなたに手を振りました';

  @override
  String wavesMaskedBody(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$costコインで誰か確認、またはVIPに登録',
    );
    return '$_temp0';
  }

  @override
  String get wavesMaskedBodyVip => 'VIPになると誰が手を振ったか分かります';

  @override
  String get perkAdFree => '広告なし';

  @override
  String get perkUnlimitedMatches => '1日のマッチ数が無制限';

  @override
  String get perkRevealWaves => '手を振った人・プロフィールを見た人が分かる';

  @override
  String get perkUnlimitedWaves => '手を振る回数が無制限';

  @override
  String get perkAdvancedFilters => '詳細なパートナー絞り込み';

  @override
  String get vipFromMatches => 'VIP: マッチ無制限';

  @override
  String get vipRemoveAds => '広告を消す';

  @override
  String get limitUnlockedRetry => 'ロック解除しました — 再送信中';

  @override
  String get rewardedUnlockSuccess => 'ロック解除しました！もう一度お試しください。';

  @override
  String get extraMatchesMaxed => '今日の追加マッチはすでに上限に達しています';

  @override
  String wavesMaskedTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人があなたに手を振りました',
      one: '誰かがあなたに手を振りました',
    );
    return '$_temp0';
  }

  @override
  String visitorsMaskedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人があなたのプロフィールを見ました',
      one: '誰かがあなたのプロフィールを見ました',
    );
    return '$_temp0';
  }

  @override
  String visitorsMaskedBody(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '$costコインで誰か確認、またはVIPに',
    );
    return '$_temp0';
  }

  @override
  String get visitorsMaskedBodyVip => 'VIPになってプロフィールを見た人を確認';

  @override
  String boostDurationHm(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String boostDurationM(int minutes) {
    return '$minutes分';
  }

  @override
  String get boostEndingSoon => 'まもなく終了';

  @override
  String coinAmount(int cost) {
    return '💎$cost';
  }

  @override
  String unlockedMore(int count) {
    return 'さらに$count件ロック解除！';
  }

  @override
  String get getMoreCoins => 'コインをもっと入手';

  @override
  String get unlockFailed => '今はロック解除できませんでした。';

  @override
  String unlockGrantForCoins(int count, int cost) {
    return '💎$costで$count件ロック解除';
  }

  @override
  String get waveLimitTitle => '今日のあいさつを使い切りました';

  @override
  String get waveLimitBody => '今すぐあいさつをもう1回手に入れるか、明日また来てください。';

  @override
  String get limitDailyReachedTitle => '1日の上限に達しました';

  @override
  String get limitLabelMessages => 'メッセージ';

  @override
  String get limitLabelMoments => 'モーメント';

  @override
  String get limitLabelStories => 'ストーリー';

  @override
  String get limitLabelComments => 'コメント';

  @override
  String get limitLabelProfileViews => 'プロフィール閲覧';

  @override
  String get limitLabelWaves => 'あいさつ';

  @override
  String limitUsedLabel(String label) {
    return '$labelの使用量';
  }

  @override
  String get limitDescMessages => '本日のメッセージ上限に達しました。VIPにアップグレードするとメッセージが無制限になります！';

  @override
  String get limitDescMoments => '本日のモーメント作成上限に達しました。VIPにアップグレードするとモーメントが無制限になります！';

  @override
  String get limitDescStories => '本日のストーリー作成上限に達しました。VIPにアップグレードするとストーリーが無制限になります！';

  @override
  String get limitDescComments => '本日のコメント上限に達しました。VIPにアップグレードするとコメントが無制限になります！';

  @override
  String get limitDescProfileViews => '本日のプロフィール閲覧上限に達しました。VIPにアップグレードするとプロフィール閲覧が無制限になります！';

  @override
  String get limitDescDefault => '本日の上限に達しました。VIPにアップグレードすると無制限で利用できます！';

  @override
  String get limitResetsAt => '上限リセット時刻';

  @override
  String get vipMembersGet => 'VIP会員の特典';

  @override
  String get vipBenefitUnlimitedMessages => 'メッセージ無制限';

  @override
  String get vipBenefitUnlimitedProfileViews => 'プロフィール閲覧無制限';

  @override
  String get vipBenefitAiStudyTools => 'AI学習ツール';

  @override
  String chatBonusMessagesUnlocked(int count) {
    return 'ボーナスメッセージを$count件獲得しました！会話を続けましょう。';
  }

  @override
  String callLabelOutgoing(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': '発信ビデオ通話',
        'other': '発信音声通話',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelIncoming(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': '着信ビデオ通話',
        'other': '着信音声通話',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelNoAnswer(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'ビデオ通話・応答なし',
        'other': '音声通話・応答なし',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelMissed(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': '不在着信（ビデオ）',
        'other': '不在着信（音声）',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelCancelled(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'キャンセルしたビデオ通話',
        'other': 'キャンセルした音声通話',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelDeclinedOutgoing(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'ビデオ通話が拒否されました',
        'other': '音声通話が拒否されました',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelDeclinedIncoming(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': '拒否したビデオ通話',
        'other': '拒否した音声通話',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelBusy(String name) {
    return '$nameさんは別の通話中でした';
  }

  @override
  String get callsTitle => '通話';

  @override
  String get callsEmpty => 'まだ通話履歴はありません';

  @override
  String get callCameraPaused => 'カメラ一時停止中';

  @override
  String get callFullScreenIntentTitle => 'ロック画面に着信を表示';

  @override
  String get callFullScreenIntentBody => 'スマートフォンがロックされていても着信を見逃さないよう、BananaTalkに全画面での着信表示を許可してください。';

  @override
  String get callForegroundTitle => '通話中';

  @override
  String get callForegroundBody => 'タップして通話に戻る';

  @override
  String get callServiceChannelName => '通話中';

  @override
  String get callServiceChannelDescription => 'BananaTalkがバックグラウンドにあるときも通話を継続します';

  @override
  String firstSessionMatchesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今日あなたのために$count人選びました',
      one: '今日あなたのために1人選びました',
    );
    return '$_temp0';
  }

  @override
  String get firstSessionMatchesBody => 'あいさつしてみましょう。最初の一通で十分です。';

  @override
  String get guideAiStudyTitle => '必要になる前に練習';

  @override
  String get guideAiStudyBody => 'AIチューターと練習、または本番の試験対策。2分で1セッションです。';

  @override
  String get guideAiStudyCta => 'AIツールを開く';

  @override
  String get guideChatsTitle => '会話はここに表示されます';

  @override
  String get guideChatsBody => 'まだありません。今日のマッチにあいさつすると、このリストが埋まります。';

  @override
  String get guideChatsCta => '相手を探す';

  @override
  String get guideMomentsTitle => '学んでいる言語で投稿してみましょう';

  @override
  String get guideMomentsBody => '写真か一言でも大丈夫。ネイティブがここでの書き込みを直してくれます。';

  @override
  String get guideMomentsCta => 'モーメントを投稿';

  @override
  String get guideProfileTitle => 'プロフィールを仕上げましょう';

  @override
  String get guideProfileBody => '写真と自己紹介を一言。半分空のプロフィールは飛ばされます。';

  @override
  String get guideProfileCta => 'プロフィールを編集';

  @override
  String get conversationEmptyTitle => 'まだメッセージはありません';

  @override
  String conversationEmptyBody(String name) {
    return '$nameさんとの会話はメッセージを送ると始まります';
  }

  @override
  String get conversationEmptySayHi => 'タップしてあいさつ！';

  @override
  String get momentVideoOptimizing => '動画を最適化しています。少しお待ちください';

  @override
  String get momentPostedWithoutVoiceNote => 'ボイスメモなしでモーメントを投稿しました。';

  @override
  String get momentAnsweringPromptOfDay => '今日の質問への回答';

  @override
  String get momentVideoReady => '動画の準備ができました';

  @override
  String get momentReadyToUpload => 'アップロードの準備完了';

  @override
  String get locationServicesDisabledTitle => '位置情報サービスがオフです';

  @override
  String get locationServicesDisabledBody => 'この機能を使うには、端末の設定で位置情報サービスをオンにしてください。';

  @override
  String get locationPermissionNeededBody => 'モーメントに現在地を付けるには、Bananatalk に位置情報の許可が必要です。';

  @override
  String get locationPermissionRequiredTitle => '位置情報の許可が必要です';

  @override
  String get locationPermissionPermanentlyDeniedBody => '位置情報の許可が完全に拒否されています。モーメントに位置情報を付けるには、アプリ設定でオンにしてください。';

  @override
  String get termsSnackAcceptFirst => '続けるには利用規約に同意してください';

  @override
  String get termsErrorAccepting => '規約の同意でエラーが発生しました。もう一度お試しください。';

  @override
  String get termsEulaTitle => 'エンドユーザーライセンス契約（EULA）';

  @override
  String get termsWelcomeHeading => 'Bananatalkへようこそ';

  @override
  String get termsWelcomeBody => 'Bananatalkをご利用いただくことで、本利用規約に拘束されることに同意したものとみなされます。ご利用の前に必ずお読みください。';

  @override
  String get termsZeroToleranceHeading => 'ゼロトレランス方針';

  @override
  String get termsZeroToleranceIntro => 'Bananatalkは、不快なコンテンツおよび迷惑行為を行うユーザーに対してゼロトレランス方針をとっています。以下を許可せず、容認もしません：';

  @override
  String get termsZeroToleranceItem1 => 'あらゆる形の嫌がらせ、いじめ、脅迫';

  @override
  String get termsZeroToleranceItem2 => 'ヘイトスピーチ、差別、暴力を助長する内容';

  @override
  String get termsZeroToleranceItem3 => '性的に露骨な、わいせつな、または不適切な内容';

  @override
  String get termsZeroToleranceItem4 => 'スパム、詐欺、不正行為';

  @override
  String get termsZeroToleranceItem5 => 'なりすましや虚偽の表示';

  @override
  String get termsZeroToleranceItem6 => '適用される法令に違反するあらゆる内容';

  @override
  String get termsZeroToleranceEnforcement => 'これらの方針に違反したユーザーは、直ちにプラットフォームから利用停止となります。当社は、本規約に違反するコンテンツを削除し、該当アカウントを事前の通知なく停止する権利を留保します。';

  @override
  String get termsUgcHeading => 'ユーザー作成コンテンツ';

  @override
  String get termsUgcBody => 'Bananatalkでは、メッセージ、投稿、画像その他の素材を作成・共有できます。本サービスを通じて作成、アップロード、共有したすべてのコンテンツについては、ユーザーご自身が全責任を負います。';

  @override
  String get termsUgcAgreeIntro => 'Bananatalkのご利用にあたり、以下に同意いただきます：';

  @override
  String get termsUgcItem1 => '不快、有害、違法な内容を投稿しないこと';

  @override
  String get termsUgcItem2 => '他のユーザーに対して迷惑行為をしないこと';

  @override
  String get termsUgcItem3 => 'すべてのユーザーの権利と尊厳を尊重すること';

  @override
  String get termsUgcItem4 => '不快な内容や迷惑ユーザーを見つけたら報告すること';

  @override
  String get termsModerationHeading => 'コンテンツの管理';

  @override
  String get termsModerationBody => 'Bananatalkは、安全で敬意ある環境を保つため、ユーザー作成コンテンツを積極的に管理しています。自動システムと人によるモデレーターを用いて、方針に違反するコンテンツを確認・削除します。';

  @override
  String get termsModerationReport => '不快なコンテンツや迷惑行為を見つけた場合は、アプリ内の報告機能から直ちにご報告ください。すべての報告を真摯に受け止め、速やかに調査します。';

  @override
  String get termsAccountHeading => 'アカウントの責任';

  @override
  String get termsAccountBody => 'アカウントの安全を保つ責任、およびアカウントで行われたすべての行為の責任はユーザーにあります。不正利用に気づいた場合は、直ちに当社へご連絡ください。';

  @override
  String get termsProhibitedHeading => '禁止される行為';

  @override
  String get termsProhibitedIntro => '上記のゼロトレランス方針に加え、以下を行わないことに同意します：';

  @override
  String get termsProhibitedItem1 => '適用される地域・国内・国際法に違反すること';

  @override
  String get termsProhibitedItem2 => '知的財産権を含む他者の権利を侵害すること';

  @override
  String get termsProhibitedItem3 => 'ウイルス、マルウェア、有害なコードを送信すること';

  @override
  String get termsProhibitedItem4 => '本サービスや他アカウントへ不正にアクセスしようとすること';

  @override
  String get termsProhibitedItem5 => '許可なく商業目的で本サービスを利用すること';

  @override
  String get termsTerminationHeading => '利用の終了';

  @override
  String get termsTerminationBody => '当社は、本利用規約への違反（不快なコンテンツの投稿や迷惑行為を含みますがこれらに限りません）があった場合、通知の有無にかかわらず、いつでもアカウントを停止または終了する権利を留保します。';

  @override
  String get termsChangesHeading => '規約の変更';

  @override
  String get termsChangesBody => '当社は本利用規約を随時更新することがあります。変更後も本サービスの利用を続けた場合、更新後の規約に同意したものとみなされます。';

  @override
  String get termsContactHeading => 'お問い合わせ';

  @override
  String get termsContactBody => '本利用規約に関するご質問、または違反の報告については、アプリ内のサポート機能よりご連絡ください。';

  @override
  String get termsAgreeCheckbox => '利用規約とゼロトレランス方針に同意します';

  @override
  String get termsProcessing => '処理中...';

  @override
  String get termsAcceptAndContinue => '同意して続ける';

  @override
  String termsLastUpdated(int year) {
    return '最終更新：$year年';
  }

  @override
  String get wavesFailedToLoad => 'ウェーブを読み込めませんでした';

  @override
  String get wavesEmptyTitle => 'まだウェーブはありません';

  @override
  String get wavesEmptyBody => '誰かがウェーブすると、\nここに表示されます';

  @override
  String get wavesWavedAtYou => 'ウェーブしました';

  @override
  String get lessonYourTranslation => 'あなたの訳：';

  @override
  String get lessonTapWordsToBuild => '下の単語をタップして訳を作りましょう';

  @override
  String get lessonWordBank => '単語バンク：';

  @override
  String get lessonTypeTranslationHint => 'ここに訳を入力...';

  @override
  String get lessonCorrect => '正解！';

  @override
  String get lessonIncorrect => '不正解';

  @override
  String get lessonCheck => '確認';

  @override
  String get lessonTitle => 'レッスン';

  @override
  String get lessonFailedToLoad => 'レッスンを読み込めませんでした';

  @override
  String get lessonResultCorrect => '正解';

  @override
  String get lessonResultIncorrect => '不正解';

  @override
  String get lessonDone => '完了';

  @override
  String get lessonPraiseExcellent => 'すばらしい！';

  @override
  String get lessonPraiseGreat => 'よくできました！';

  @override
  String get lessonPraiseGood => 'いい調子！';

  @override
  String get lessonPraiseKeepPracticing => '練習を続けよう！';

  @override
  String get lessonPraiseTryAgain => 'もう一度！';

  @override
  String get lessonExitWarning => '今やめると進捗は保存されません。';

  @override
  String get lessonNotFound => 'レッスンが見つかりません';

  @override
  String get lessonMayHaveBeenRemoved => 'このレッスンは削除された可能性があります';

  @override
  String get lessonNoExercises => 'このレッスンにはまだ問題がありません';

  @override
  String get quizTitle => 'クイズ';

  @override
  String get quizFailedToLoad => 'クイズを読み込めませんでした';

  @override
  String get quizSubmit => '送信';

  @override
  String get quizScore => 'スコア';

  @override
  String get quizCorrect => '正解';

  @override
  String get quizWrong => '不正解';

  @override
  String get quizYourLevel => 'あなたのレベル';

  @override
  String get quizPraiseKeepLearning => '学習を続けよう！';

  @override
  String get quizExitWarning => '今やめると進捗が失われます。';

  @override
  String get vocabFailedToLoad => '復習を読み込めませんでした';

  @override
  String get vocabNoneDue => '今は復習する単語がありません';

  @override
  String get vocabGotIt => 'わかった！';

  @override
  String get vocabTapToReveal => 'カードをタップして答えを表示';

  @override
  String get vocabSessionComplete => 'セッション完了！';

  @override
  String get wavesEmptyBody2 => '誰かがウェーブすると、\nここに表示されます';

  @override
  String lessonCorrectAnswer(String answer) {
    return '正解：$answer';
  }

  @override
  String quizQuestionOfTotal(int current, int total) {
    return '問題 $current / $total';
  }

  @override
  String get vocabXpEarned => '獲得XP';

  @override
  String get vocabWatchAdBonus => '広告を見て+10ボーナスXP';

  @override
  String get vocabBonusEarned => '+10ボーナスXP獲得！🎉';

  @override
  String vipBannerIsMember(String userName) {
    return '$userNameさんはVIP会員です';
  }

  @override
  String get vipBannerGetBenefits => 'あなたもVIP特典を手に入れよう！';

  @override
  String get vipUpgrade => 'アップグレード';

  @override
  String get vipUnlockAllFeatures => 'すべての機能を解放';

  @override
  String get chatFailedToLoadUser => 'ユーザー情報を読み込めませんでした';

  @override
  String get chatDailyLimitTitle => '1日のチャット上限に達しました';

  @override
  String get chatUnlimitedTitle => '無制限チャット';

  @override
  String get chatUnlimitedBody => '好きなだけたくさんの人とチャットできます！VIP会員は1日の会話が無制限です。';

  @override
  String get coinsStoreUnavailable => 'コインの購入はiOSとAndroidのみ対応しています。';

  @override
  String get coinsPurchaseCanceled => '購入がキャンセルされたか、開始できませんでした。';

  @override
  String get coinsReceiptUnreadable => '購入レシートを読み取れませんでした。もう一度お試しください。';

  @override
  String get coinsAdded => 'コインを追加しました！💎';

  @override
  String get coinsVerifyRetry => '購入を確認できませんでした。自動で再試行します。コインが反映されない場合は購入の復元をお試しください。';

  @override
  String get coinsAlreadyClaimed => '今日はもう受け取り済みです。また明日！';

  @override
  String get coinsDailyClaimed => 'デイリー報酬を受け取りました！+10 💎';

  @override
  String get coinsClaimFailed => 'デイリー報酬を受け取れませんでした。';

  @override
  String get coinsAdThanks => 'ご視聴ありがとうございます！+5 💎';

  @override
  String get coinsAdCreditFailed => '広告の報酬を付与できませんでした。';

  @override
  String get coinsGetCoins => 'コインを入手';

  @override
  String get coinsGetCoinsSubtitle => '翻訳・チューターとの会話・モーメントの追加利用をすぐに解放。';

  @override
  String get coinsYourBalance => '残高';

  @override
  String get coinsEarnFree => '無料でコインを獲得';

  @override
  String get coinsDailyReward => 'デイリー報酬';

  @override
  String get coinsComeBackTomorrow => 'また明日';

  @override
  String get coinsDailyRewardSubtitle => '1日1回、+10コイン';

  @override
  String get coinsClaimed => '受け取り済み';

  @override
  String get coinsClaim => '受け取る';

  @override
  String get coinsWatchAd => '広告を見る';

  @override
  String get coinsAdLimitReached => '本日の上限に達しました。また明日';

  @override
  String get exploreTitle => 'みつける';

  @override
  String get exploreNoMoments => '表示できるモーメントがありません';

  @override
  String get exploreFailedToLoad => '読み込みに失敗しました';

  @override
  String get exploreNoTrending => '人気のモーメントはまだありません';

  @override
  String get exploreNoVideos => '動画はまだありません';

  @override
  String get exploreBeFirstVideo => '最初の動画を投稿してみましょう！';

  @override
  String get exploreFailedVideos => '動画を読み込めませんでした';

  @override
  String get facebookLoginSubtitle => 'Facebookアカウントで続けて\nスムーズに利用しましょう';

  @override
  String get securedByFacebook => 'Facebookによる保護';

  @override
  String get continueWithEmail => 'メールで続ける';

  @override
  String get continueWithFacebook => 'Facebookで続ける';

  @override
  String get suspendedTitle => 'アカウントが停止されました';

  @override
  String get suspendedContact => '誤りだと思われる場合は、ユーザー名を添えて bananatalkmain@gmail.com までご連絡ください。';

  @override
  String get suspendedNoAccess => 'このアカウントはご利用いただけません。';

  @override
  String get suspendedReason => '理由：';

  @override
  String get correctionSuggestTitle => '修正を提案';

  @override
  String get correctionOriginal => '原文';

  @override
  String get correctionYours => 'あなたの修正';

  @override
  String get correctionTypeHint => '修正した文を入力...';

  @override
  String get correctionChanges => '変更点';

  @override
  String get correctionExplanationOptional => '説明（任意）';

  @override
  String get correctionWhyHint => 'なぜこの修正をしましたか？';

  @override
  String get correctionSend => '修正を送信';

  @override
  String get correctionSuggested => '提案された修正';

  @override
  String get correctionFailedToSend => '修正を送信できませんでした';

  @override
  String get ttsUnavailable => '読み上げを利用できません';

  @override
  String get translationDailyLimitTitle => '1日の翻訳上限に達しました';

  @override
  String get translationDailyLimitBody => '無料ユーザーは1日5回まで翻訳できます。\nVIPなら無制限です！';

  @override
  String get ttsListen => '聞く';

  @override
  String correctionOfMessage(String name) {
    return '$nameさんのメッセージを修正';
  }

  @override
  String translatedToLanguage(String language) {
    return '$languageに翻訳しました';
  }

  @override
  String guideProgress(int count) {
    return 'はじめの一歩 · $count/4';
  }

  @override
  String get guideChatTip => '長押しで翻訳・添削';

  @override
  String get announcementTitle => 'お知らせ';

  @override
  String get announcementUnavailable => 'このお知らせは現在ご覧いただけません。';

  @override
  String get notifyAnnouncementsTitle => 'お知らせ';

  @override
  String get notifyAnnouncementsSubtitle => 'BananaTalkチームからのニュースとアップデート';

  @override
  String chatDailyLimitBody(int count) {
    return '無料ユーザーは1日に最大$count人までチャットできます。\nVIPにアップグレードすると無制限に会話できます!';
  }

  @override
  String get chatCompressingVideo => '動画を圧縮しています...';

  @override
  String chatShareLocationBody(Object name) {
    return '現在地を$nameに送信します。信頼できる相手にのみ送信してください。';
  }

  @override
  String get chatShareLocationThisChat => 'このチャット';

  @override
  String get chatTranslationLimitReached => '翻訳の上限に達しました';

  @override
  String get chatTranslateLimitBody => 'このチャットでの本日の無料翻訳を使い切りました。コインですぐにさらにロック解除できます。';

  @override
  String chatReplyingTo(Object name) {
    return '$nameに返信中';
  }

  @override
  String get chatReplyingToFallback => 'ユーザー';

  @override
  String chatSendingMedia(Object mediaType) {
    return '$mediaTypeを送信中...';
  }

  @override
  String get chatEnterUsernameStart => 'チャットを始めるにはユーザー名を入力してください';

  @override
  String chatSearching(Object username) {
    return '@$usernameを検索中...';
  }

  @override
  String chatDeleteConversationBody(Object name) {
    return '$nameとの会話を削除しますか?この操作は元に戻せません。';
  }

  @override
  String get chatQrCode => 'QRコード';

  @override
  String get chatDraft => '下書き: ';

  @override
  String get chatTyping => '入力中...';

  @override
  String get chatPoweredBy => '提供: ';

  @override
  String get chatReconnecting => 'チャットに再接続中...';

  @override
  String get chatDailyLimitReached => '1日のメッセージ上限に達しました';

  @override
  String chatMessagesRemainingToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '本日あと$count件',
      one: '本日あと1件',
    );
    return '$_temp0';
  }

  @override
  String get chatTranslatePreviewHint => '入力を始めると翻訳が表示されます';

  @override
  String get chatNoMessagesYet => 'まだメッセージはありません';

  @override
  String get chatMediaPhoto => '写真';

  @override
  String get chatMediaVideo => '動画';

  @override
  String get chatMediaAudio => '音声';

  @override
  String get chatMediaFile => 'ファイル';

  @override
  String get chatMediaGeneric => 'メディア';

  @override
  String get chatMessageFailedToSend => 'メッセージを送信できませんでした';

  @override
  String get chatSendingEllipsis => '送信中...';

  @override
  String get chatFailedTapOptions => '失敗 · タップしてオプションを表示';

  @override
  String get chatMessageWasDeleted => 'このメッセージは削除されました';

  @override
  String get chatStory => 'ストーリー';

  @override
  String get chatHi => 'やあ！';

  @override
  String get chatEdited => '編集済み';

  @override
  String get chatPremium => 'プレミアム ✨';

  @override
  String chatUnlockPremiumWallpapers(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '💎$costコインでプレミアム ✨ 壁紙をすべてアンロックしますか？パック全体が永久にアンロックされます。',
    );
    return '$_temp0';
  }

  @override
  String chatWallpaperForName(Object userName) {
    return '$userNameさんとのチャット壁紙';
  }

  @override
  String get chatChooseGallery => 'ギャラリーから選択';

  @override
  String get chatHiThere => 'こんにちは！😊';

  @override
  String chatCorrected(Object correctorName) {
    return '$correctorNameさんが添削しました';
  }

  @override
  String get chatCorrectionAccepted => '添削を承認しました ✓';

  @override
  String chatForwarded(Object senderName) {
    return '$senderNameから転送';
  }

  @override
  String get chatCached => 'キャッシュ済み';

  @override
  String get chatWordBreakdown => '単語の内訳';

  @override
  String get chatAlternatives => '別の表現';

  @override
  String chatTranslationAlso(Object items) {
    return '他にも：$items';
  }

  @override
  String get chatAudioUnavailable => '音声を利用できません';

  @override
  String get chatHideTranslation => '翻訳を非表示';

  @override
  String get chatStoryExpired => 'ストーリーの期限切れ';

  @override
  String get chatAcceptCorrection => '添削を承認';

  @override
  String get chatAccepting => '承認中…';

  @override
  String get chatSaveToVocabularyAction => '単語帳に保存';

  @override
  String momentsMore(Object hidden) {
    return '他$hidden件';
  }

  @override
  String get momentsAllow => '許可';

  @override
  String get momentsCompressed => '圧縮済み';

  @override
  String get momentsPromptDay => '今日のお題';

  @override
  String get momentsAnswer => '回答する';

  @override
  String get momentsAnswerCamera => '🎥 カメラで回答';

  @override
  String momentsPracticeWriting(Object langName) {
    return '$langNameで書く練習をしよう';
  }

  @override
  String get momentsReelPolicyBody => 'リールは語学学習向けの短い動画です。お題への回答、スピーキング練習、ネイティブによる解説、文化クリップなどが投稿されます。\n\nBananatalkは不適切なコンテンツを一切容認しません。ヌード、ヘイトスピーチ、嫌がらせ、暴力、違法なコンテンツは禁止です。報告された動画は2件の報告で審査まで自動的に非表示になり、違反するとコンテンツの削除やアカウントの停止となる場合があります。\n\nどのリールからでもいつでも報告やブロックができます。';

  @override
  String get momentsIAgree => '同意する';

  @override
  String get momentsWhyReportingReel => 'このリールを報告する理由は何ですか？';

  @override
  String get momentsNoReelsYet => 'まだリールがありません';

  @override
  String get momentsNoReelsBody => '今日のお題にカメラで最初に回答するか、自由形式の語学学習クリップを録画しましょう。';

  @override
  String get momentsPullDownRefresh => '下に引っ張って更新';

  @override
  String get momentsErrorLoadingVideo => '動画の読み込みエラー';

  @override
  String get momentsLoadingVideo => '動画を読み込み中...';

  @override
  String momentsFileSizeMb(Object size) {
    return '${size}MB';
  }

  @override
  String momentsMaxDuration(Object duration) {
    return '最大$duration';
  }

  @override
  String get momentsReportSubmitted => '報告を送信しました';

  @override
  String communityLive(Object count) {
    return '$count件ライブ中';
  }

  @override
  String get communityFind => '探す';

  @override
  String communityFinding(Object username) {
    return '@$username を検索中...';
  }

  @override
  String get communitySeeAll => 'すべて見る';

  @override
  String get communitySeeWhoLikes => 'あなたを気に入った人を見る';

  @override
  String get communityUnlimitedBrowsingNoAds => '無制限の閲覧、広告なし、優先マッチング';

  @override
  String communityMembersCount(int count, String countLabel) {
    return 'メンバー $countLabel人';
  }

  @override
  String communityPeopleCount(int count, String countLabel) {
    return '$countLabel人';
  }

  @override
  String get communityFailedLoadArchivedWaves => 'アーカイブしたウェーブを読み込めませんでした';

  @override
  String get communityGreatChat => 'いい会話でした！🎉';

  @override
  String get communityStayTouchPeopleJust => 'さっき話した人とつながり続けましょう';

  @override
  String get communityNotNow => '今はしない';

  @override
  String get communityPerfect => 'ぴったり';

  @override
  String communityLv(Object level) {
    return 'Lv.$level';
  }

  @override
  String get communityReact => 'リアクション';

  @override
  String get communityWavedAtYou => 'があなたにウェーブしました';

  @override
  String get communitySomeone => '誰か';

  @override
  String get communityPeopleInterestedInTopic => 'このトピックに興味がある人';

  @override
  String get learnThemedWordSetsBuild => '語彙を増やすためのテーマ別単語セット';

  @override
  String get learnTapStartRecording => 'タップして録音を開始';

  @override
  String get learnWordBank => '単語バンク';

  @override
  String learnCorrectAnswer(Object correctAnswer) {
    return '正解: $correctAnswer';
  }

  @override
  String get learnMatchingDataNotAvailable => 'マッチングデータがありません';

  @override
  String get learnExerciseCouldNotLoad => 'この問題のマッチングペアを読み込めませんでした。レッスンを再生成してみてください。';

  @override
  String get learnSkipExercise => '問題をスキップ';

  @override
  String get learnTapItemLeftThen => '左の項目をタップし、右の対応する項目をタップしてください';

  @override
  String learnMatchedOfTotal(Object count, Object count2) {
    return '$count/$count2 組マッチ';
  }

  @override
  String learnCorrectOfTotal(Object correctCount, Object count) {
    return '$correctCount/$count 正解';
  }

  @override
  String get learnDragDropReorderItems => 'ドラッグ＆ドロップで項目を並べ替えてください';

  @override
  String learnCorrectOrder(Object order) {
    return '正しい順序: $order';
  }

  @override
  String learnWordsToReview(int dueCount) {
    String _temp0 = intl.Intl.pluralLogic(
      dueCount,
      locale: localeName,
      other: '復習する単語 $dueCount 語',
    );
    return '$_temp0';
  }

  @override
  String learnScore(Object score) {
    return 'スコア: $score / 100';
  }

  @override
  String learnGotCorrect(Object correct, Object count) {
    return '$count問中$correct問正解です。';
  }

  @override
  String learnQuestionOf(Object number, Object total) {
    return '問題 $number / $total';
  }

  @override
  String get learnMatchEachWordIts => '各単語をその意味に結びつけてください';

  @override
  String get learnCouldNotLoadPacks => 'パックを読み込めませんでした';

  @override
  String learnWordsExercises(int wordCount, int exerciseCount) {
    return '$wordCount 語 · $exerciseCount 問';
  }

  @override
  String get learnAiAutoFill => 'AI 自動入力';

  @override
  String get learnPlay => '再生';

  @override
  String get learnFinish => '完了';

  @override
  String get learnNotQuite => '惜しい！';

  @override
  String get learnUnsupportedExercise => '未対応の問題';

  @override
  String get learnFailedLoadAchievements => '実績を読み込めませんでした';

  @override
  String learnUnlockedOn(Object date) {
    return '$dateに解除';
  }

  @override
  String get learnChallenges => 'チャレンジ';

  @override
  String get learnFailedLoadChallenges => 'チャレンジを読み込めませんでした';

  @override
  String learnNoChallenges(Object type) {
    return '$typeチャレンジはありません';
  }

  @override
  String get learnCheckBackLater => '後でもう一度確認してください！';

  @override
  String learnActiveCount(Object count) {
    return '進行中（$count）';
  }

  @override
  String learnCompletedCount(Object count) {
    return '完了（$count）';
  }

  @override
  String get learnProgress => '進捗';

  @override
  String get learnXpReward => 'XP報酬';

  @override
  String get learnBonus => 'ボーナス';

  @override
  String learnExpires(Object timeRemainingFormatted) {
    return 'あと$timeRemainingFormattedで終了';
  }

  @override
  String get learnAchievementUnlocked => '実績を解除しました！';

  @override
  String get learnTapContinue => 'タップして続ける';

  @override
  String get learnChallengeCompleted => '完了';

  @override
  String get learnDailyGoals => 'デイリー目標';

  @override
  String learnLessons(Object completedCount, Object lessonsCount) {
    return '$completedCount/$lessonsCountレッスン';
  }

  @override
  String learnLongestDays(Object longestStreak) {
    return '最長：$longestStreak日';
  }

  @override
  String get learnTapReveal => 'タップして表示';

  @override
  String get learnNoAchievements => '実績はありません';

  @override
  String get learnDayStreak => '日連続';

  @override
  String get learnDueForReview => '復習の時間です';

  @override
  String learnNextReview(Object date) {
    return '次回：$date';
  }

  @override
  String get learnChallengeDaily => 'デイリー';

  @override
  String get learnChallengeWeekly => 'ウィークリー';

  @override
  String get learnChallengeSpecial => 'スペシャル';

  @override
  String get learnChallengeDailyDesc => '毎日チャレンジを完了してXPと報酬をゲットしよう！';

  @override
  String get learnChallengeWeeklyDesc => 'ウィークリーチャレンジは毎週月曜日に更新されます';

  @override
  String get learnChallengeSpecialDesc => '期間限定のチャレンジ、ボーナス報酬付き！';

  @override
  String get learnDateToday => '今日';

  @override
  String get learnDateTomorrow => '明日';

  @override
  String learnInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日後',
    );
    return '$_temp0';
  }

  @override
  String learnInWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count週間後',
    );
    return '$_temp0';
  }

  @override
  String learnInMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countか月後',
    );
    return '$_temp0';
  }

  @override
  String get aiGenerateNewQuiz => '新しいクイズを作成';

  @override
  String get aiPreviousQuizzes => '過去のクイズ';

  @override
  String get aiGeneratingQuiz => 'クイズを作成中…';

  @override
  String aiFocusArea(Object name) {
    return '重点分野：$name';
  }

  @override
  String get aiQuizType => 'クイズの種類';

  @override
  String get aiDifficulty => '難易度';

  @override
  String get aiQuestionsLabel => '問題数：';

  @override
  String get aiGenerateQuiz => 'クイズを作成';

  @override
  String aiQuizQuestionCount(int questionCount) {
    String _temp0 = intl.Intl.pluralLogic(
      questionCount,
      locale: localeName,
      other: '$questionCount問',
      one: '1問',
    );
    return '$_temp0';
  }

  @override
  String aiCorrectOfTotal(Object correctCount, Object totalQuestions) {
    return '$correctCount/$totalQuestions 問正解';
  }

  @override
  String get aiNoQuizzesYet => 'まだクイズがありません';

  @override
  String get aiGenerateFirstQuizAbove => '上で最初のクイズを作成しましょう！';

  @override
  String aiCorrectOutOf(Object correctCount, Object totalQuestions) {
    return '$totalQuestions問中$correctCount問正解';
  }

  @override
  String get aiBackQuizHub => 'クイズハブに戻る';

  @override
  String get aiNoQuestionsAvailable => '利用できる問題がありません';

  @override
  String get aiQuizHasNoQuestions => 'このクイズには表示できる問題がありません。';

  @override
  String aiQuestionOf(Object number, Object count) {
    return '問題 $number / $count';
  }

  @override
  String get aiYourAnswerLabel => 'あなたの回答：';

  @override
  String get aiBonusXpWatching => '🎉 視聴で+10ボーナスXP！';

  @override
  String get aiNotQuiteRight => '惜しい！';

  @override
  String get aiWhy => 'なぜ？';

  @override
  String get aiGotIt => 'わかった';

  @override
  String get aiHint => 'ヒント';

  @override
  String aiLevel(Object hintLevel) {
    return 'レベル $hintLevel/3';
  }

  @override
  String get aiAskQuestion => '質問する';

  @override
  String get aiAsk => '聞く';

  @override
  String get aiAssistantExamples => '例';

  @override
  String get aiExplainConcept => '概念を説明';

  @override
  String get aiRelatedConcepts => '関連する概念';

  @override
  String get aiGeneratingLessonSummary => 'レッスンの要約を作成中...';

  @override
  String get aiLessonSummary => 'レッスンの要約';

  @override
  String get aiKeyPoints => '重要ポイント';

  @override
  String get aiVocabularyRemember => '覚えておきたい語彙';

  @override
  String get aiGrammarRules => '文法ルール';

  @override
  String get aiWhatPracticeNext => '次に練習すること';

  @override
  String get aiPerfectScore => '満点！';

  @override
  String get aiGreatJob => 'よくできました！';

  @override
  String get aiGoodEffort => 'よく頑張りました！';

  @override
  String get aiKeepPracticing => '練習を続けましょう！';

  @override
  String get aiFailedToGetHint => 'ヒントを取得できませんでした';

  @override
  String get aiFailedToGetAnswer => '回答を取得できませんでした';

  @override
  String get aiFailedToExplain => '説明に失敗しました';

  @override
  String get aiFailedLoadHistory => '履歴を読み込めませんでした';

  @override
  String aiConversationMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のメッセージ',
    );
    return '$_temp0';
  }

  @override
  String get aiStartNewConversationSee => '新しい会話を始めるとここに表示されます';

  @override
  String get aiLoadingMessages => 'メッセージを読み込み中...';

  @override
  String get aiNoMessagesConversation => 'この会話にメッセージはありません';

  @override
  String get aiDifficultyLevel => '難易度';

  @override
  String get aiScenarios => 'シナリオ';

  @override
  String get aiGrammarCheck => '文法チェック';

  @override
  String get aiRecentAnalysis => '最近の分析';

  @override
  String get aiCheckGrammar => '文法をチェック';

  @override
  String get aiLanguageLabel => '言語：';

  @override
  String aiGrammarIssuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の誤りが見つかりました',
    );
    return '$_temp0';
  }

  @override
  String get aiPerfect => '完璧です！';

  @override
  String get aiNoGrammarIssuesFound => 'テキストに文法の誤りは見つかりませんでした。';

  @override
  String aiIssuesFound(Object count) {
    return '見つかった誤り（$count）';
  }

  @override
  String get aiCorrected => '修正後';

  @override
  String get aiGrammarExamples => '例：';

  @override
  String get aiImprovedSuggestions => '改善案';

  @override
  String get aiNoAnalysisHistoryYet => '分析履歴はまだありません';

  @override
  String get aiLessonBuilder => 'AIレッスンビルダー';

  @override
  String get aiGenerateCustomLessons => 'カスタムレッスンを作成';

  @override
  String get aiCreatesPersonalizedLessonsAny => 'AIがあらゆるトピックでパーソナライズされたレッスンを作成します';

  @override
  String aiExercises(Object exerciseCount) {
    return '練習問題：$exerciseCount';
  }

  @override
  String get aiSuggestedTopics => 'おすすめトピック';

  @override
  String get aiCreatingLesson => 'レッスンを作成中...';

  @override
  String get aiGeneratingExercisesContent => 'AIが練習問題とコンテンツを生成しています';

  @override
  String get aiLessonGenerated => 'レッスンができました！';

  @override
  String get aiGenerateAnother => 'もう1つ作成';

  @override
  String get aiStartLesson => 'レッスンを始める';

  @override
  String get aiPronunciationPractice => '発音練習';

  @override
  String get aiPracticeHistory => '練習履歴';

  @override
  String get aiTextPractice => '練習するテキスト';

  @override
  String get aiWordAnalysis => '単語分析';

  @override
  String get aiNoPracticeHistoryYet => '練習履歴はまだありません';

  @override
  String get aiSmartTranslation => 'スマート翻訳';

  @override
  String get aiWordBreakdown => '単語ごとの内訳';

  @override
  String get aiAlternativeTranslations => '別の訳';

  @override
  String get aiGrammarNotes => '文法メモ';

  @override
  String get aiIdiomsExpressions => '慣用句と表現';

  @override
  String aiLiteral(Object literalTranslation) {
    return '直訳：$literalTranslation';
  }

  @override
  String aiMeaning(Object meaning) {
    return '意味：$meaning';
  }

  @override
  String aiEquivalent(Object equivalentIdiom) {
    return '同等の表現：$equivalentIdiom';
  }

  @override
  String get aiCulturalContext => '文化的背景';

  @override
  String get aiNoCompletedConversations => '完了した会話はありません';

  @override
  String get aiNoActiveConversations => '進行中の会話はありません';

  @override
  String aiStartInLanguage(Object language) {
    return '$languageで始める';
  }

  @override
  String get aiSelect => '選択';

  @override
  String aiIssuesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の誤り',
    );
    return '$_temp0';
  }

  @override
  String get aiGenerateLesson => 'レッスンを作成';

  @override
  String get aiGeneratingEllipsis => '生成中...';

  @override
  String get aiAnalyzing => '分析中...';

  @override
  String get aiExcellentPronunciation => '素晴らしい発音です！';

  @override
  String get aiGoodJob => 'よくできました！';

  @override
  String get profileBuyMeCoffee => 'コーヒーをおごる';

  @override
  String get profileOr => 'または';

  @override
  String get profileLoadingNotifications => '通知を読み込み中...';

  @override
  String get profileLoadingSettings => '設定を読み込み中...';

  @override
  String get profileAdmin => '管理者';

  @override
  String get profileSelected => '選択中';

  @override
  String get profilePrivacyIntro => '他のユーザーに見せる内容はあなたが決められます。項目をオフにすると公開プロフィールから非表示になります。';

  @override
  String get profileUpdate => '更新';

  @override
  String get profileNoTopicsCategory => 'このカテゴリにトピックはありません';

  @override
  String get profileAdminTools => '管理ツール';

  @override
  String profileCompletionAdd(Object items) {
    return '追加: $items';
  }

  @override
  String get profileActive => 'アクティブ';

  @override
  String get profileAutoSaveEnabled => '自動保存が有効です';

  @override
  String get profileChangesSavedInstantlyWhen => '切り替えると変更はすぐに保存されます。';

  @override
  String get profileCurrentTheme => '現在のテーマ';

  @override
  String get profileThemeChangesApplyInstantly => 'テーマの変更はアプリ全体にすぐに反映されます。';

  @override
  String get profileLoadingVisitors => '訪問者を読み込み中...';

  @override
  String get profileSeeWhoChecked => 'プロフィールを見た人を確認';

  @override
  String get profileRecentVisitors => '最近の訪問者';

  @override
  String get profileNoReportsSubmitted => '送信した報告はありません';

  @override
  String get profileReportsSubmitWillAppear => '送信した報告はここに表示されます';

  @override
  String profileReportTypeTitle(Object type) {
    return '$typeの報告';
  }

  @override
  String profileReportReason(Object reason) {
    return '理由: $reason';
  }

  @override
  String get profileDeleteAccountFinalBody => 'すべてのデータが完全に削除されます。\n\n本当によろしいですか？';

  @override
  String get profileThanksForWatching => 'ご視聴ありがとうございます！🙏';

  @override
  String get profileNotificationsOn => '通知オン';

  @override
  String get profileNotificationsOff => '通知オフ';

  @override
  String get profileMaximumReached => '上限に達しました';

  @override
  String get profilePickYourInterests => '興味のあることを選ぼう';

  @override
  String get profileDeselectToChooseAnother => '別のものを選ぶには1つ選択を解除してください';

  @override
  String get profileTapTopicsMatchVibe => 'あなたらしいトピックをタップしてください';

  @override
  String get profileEnjoyingPremium => 'プレミアム機能をお楽しみ中';

  @override
  String get profileUnlockUnlimited => '無制限のメッセージとAIツールを解放';

  @override
  String get profileBirthYear => '生年';

  @override
  String get profileReportTypeUser => 'ユーザー';

  @override
  String get profileReportTypeMoment => 'モーメント';

  @override
  String get profileReportTypeComment => 'コメント';

  @override
  String get profileReportTypeMessage => 'メッセージ';

  @override
  String get profileReportTypeStory => 'ストーリー';

  @override
  String get profileReportReasonCopyright => '著作権';

  @override
  String get storyOptimizingBestExperience => '最高の体験のために最適化中';

  @override
  String get storyCreate => 'ストーリーを作成';

  @override
  String get storyAddTags => 'タグを追加';

  @override
  String get storyVideoSelected => '動画を選択済み';

  @override
  String get storyAddPoll => '投票を追加';

  @override
  String get storyOptions => '選択肢';

  @override
  String get storyAddQuestion => '質問を追加';

  @override
  String get storyPrompt => 'プロンプト';

  @override
  String get storyTapAnywhereAddText => 'どこでもタップしてテキストを追加';

  @override
  String storyHighlightStoryCount(int storyCount) {
    String _temp0 = intl.Intl.pluralLogic(
      storyCount,
      locale: localeName,
      other: '$storyCount件のストーリー',
    );
    return '$_temp0';
  }

  @override
  String get storySendFriends => '友達に送信';

  @override
  String storySelected(Object count) {
    return '$count件選択中';
  }

  @override
  String get storyShareSave => '共有/保存';

  @override
  String storySeenBy(Object viewCount) {
    return '$viewCount人が閲覧';
  }

  @override
  String get storyNoViewsYet => 'まだ閲覧はありません';

  @override
  String get storyEditVideo => '動画を編集';

  @override
  String storyVotes(Object totalVotes) {
    return '$totalVotes票';
  }

  @override
  String get storyCreatePoll => '投票を作成';

  @override
  String get storySendAnonymously => '匿名で送信';

  @override
  String storyResponseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の回答',
    );
    return '$_temp0';
  }

  @override
  String get storyViewResponses => '回答を見る';

  @override
  String get storyResponsesTitle => '回答';

  @override
  String get storyNoResponsesYet => 'まだ回答はありません';

  @override
  String get storyQuestionBox => '質問ボックス';

  @override
  String get storySent => '送信しました！';

  @override
  String get storyProcessing => '処理中...';

  @override
  String get storyHd => 'HD';

  @override
  String storyVideoMeta(Object duration, Object size) {
    return '$duration | ${size}MB';
  }

  @override
  String get storyUserFallback => 'ユーザー';

  @override
  String storySendCount(int count) {
    return '送信（$count）';
  }

  @override
  String get storyFailedToDelete => 'ストーリーの削除に失敗しました';

  @override
  String get storyAnonymous => '匿名';

  @override
  String get vipNoCoinActivityYet => 'コインのアクティビティはまだありません';

  @override
  String get vipCoinShopExplainer => 'コインは、無料の1日の上限に達した後に、翻訳、AIチューター チャット、モーメントの追加利用を解放するために使います。コインを使用した後の購入は返金できません。';

  @override
  String get vipLimitReached => '上限に達しました';

  @override
  String get vipCoins => 'コイン';

  @override
  String vipBonusIncluded(Object bonusCoins) {
    return 'ボーナス$bonusCoinsコイン付き';
  }

  @override
  String get vipVisitorModeLimitReached => 'ビジターモードの上限に達しました';

  @override
  String get vipWhatGetFreeAccount => '無料アカウントで利用できること';

  @override
  String get vipCreateFreeAccount => '無料アカウントを作成';

  @override
  String get vipGoUnlimitedAccess => 'VIPで無制限にアクセス';

  @override
  String get vipContinueAsVisitor => 'ビジターとして続行';

  @override
  String vipResets(Object resetTime) {
    return 'リセット時刻：$resetTime';
  }

  @override
  String vipUsedToday(Object currentUsage, Object maxAllowed) {
    return '本日$currentUsage / $maxAllowed使用済み';
  }

  @override
  String get vipTierVisitor => 'ビジター';

  @override
  String get vipTierMember => 'メンバー';

  @override
  String get vipAd => '広告';

  @override
  String get promoAdsNoticeTitle => '開発者からのお知らせ';

  @override
  String get promoAdsNoticeBody => 'こんにちは！Bananatalkを一人で開発しているFirdavsです。アプリを無料で維持し、開発を続けるために、小さな広告をいくつか追加しました。\n\n広告が煩わしいことは承知しています。そのため、任意で見られて、見返りもあるようにしました。広告を見ると、追加メッセージ、コミュニティフィルター、クイズ後のボーナスXPなどが解放されます。\n\nBananatalkをご利用いただきありがとうございます。皆さまの応援が何よりの支えです。🙏';

  @override
  String get promoAdsNoticeGotIt => 'わかりました！👍';

  @override
  String get vipOnly => 'VIP限定';

  @override
  String get vipTapUpgrade => 'タップしてアップグレード';

  @override
  String get vipUnlockFeatures => 'VIP機能を解放';

  @override
  String get vipUpPillUp => 'UP';

  @override
  String get vipChooseOption => 'オプションを選択してください：';

  @override
  String get promoWelcomeBackTitle => 'おかえりなさい！👋';

  @override
  String get promoWelcomeBackBody => 'お待ちしていました。こちらが待っています：';

  @override
  String get promoWelcomeBackCta => 'さあ始めよう！🚀';

  @override
  String get vipCoinsPerAdInfo => '広告1回につき+5コイン（1日最大5回）';

  @override
  String get vipUpgradeUnlockMore => 'アップグレードして、さらに多くの機能と無制限アクセスを解放しましょう';

  @override
  String get vipUpgradeNow => '今すぐアップグレード';

  @override
  String get commonContinueWhereLeftOff => '前回の続きから再開しますか？';

  @override
  String get commonLanguageNotProvided => '言語が指定されていません';

  @override
  String get commonExamNotProvided => '試験が指定されていません';

  @override
  String get commonMuted => 'ミュート中';

  @override
  String get commonPoorConnection => '接続が不安定です';

  @override
  String commonBlockUserConfirmBody(Object targetUserName) {
    return '$targetUserNameさんをブロックしてもよろしいですか？\n\n相手のメッセージや投稿は表示されなくなり、お互いの検索にも表示されなくなります。';
  }

  @override
  String get commonVideoFile => '動画ファイル';

  @override
  String get commonPointCameraBananatalkQr => 'Bananatalk の QR コードにカメラを向けてください';

  @override
  String get commonReportSubmittedButSome => '報告を送信しましたが、一部の証拠をアップロードできませんでした';

  @override
  String commonReportTitle(Object typeLabel) {
    return '$typeLabelを報告';
  }

  @override
  String commonWhyReporting(Object typeLabel) {
    return 'この$typeLabelを報告する理由は何ですか？';
  }

  @override
  String get commonAddEvidenceRequired => '証拠を追加（必須）';

  @override
  String get commonUploadScreenshotsTextFiles => '報告を裏付けるスクリーンショットやテキストファイルをアップロードしてください';

  @override
  String commonAddEvidenceCount(Object count, Object maxFiles) {
    return '証拠を追加（$count/$maxFiles）';
  }

  @override
  String commonReportTotalSize(Object max, Object used) {
    return '合計: $used / $max';
  }

  @override
  String get commonEvidence => '証拠';

  @override
  String get commonImageFailed => '画像の読み込みに失敗';

  @override
  String get commonShowMore => 'もっと見る';

  @override
  String get commonVoiceRecordingNotAvailable => '音声録音は利用できません';

  @override
  String get commonVoiceRecordingOnlyAvailable => '音声録音はモバイルデバイスでのみ利用できます。';

  @override
  String get commonReportSubmittedSuccessfully => '報告を送信しました';

  @override
  String get commonErrorLoadingFile => 'ファイルの読み込みエラー';

  @override
  String get commonReportTypeUser => 'ユーザー';

  @override
  String get commonReportTypeMoment => 'モーメント';

  @override
  String get commonReportTypeComment => 'コメント';

  @override
  String get commonReportTypeMessage => 'メッセージ';

  @override
  String get commonReportTypeStory => 'ストーリー';

  @override
  String get commonReportTypeContent => 'コンテンツ';

  @override
  String get commonReportReasonCopyright => '著作権侵害';

  @override
  String get momentsRemoveVoiceNote => 'ボイスノートを削除';

  @override
  String get vocabPackLevelProficiency => '熟達';

  @override
  String get aiFailedToLoadFeedback => 'フィードバックの読み込みに失敗しました';

  @override
  String get aiFailedToLoadSummary => '要約の読み込みに失敗しました';

  @override
  String get momentFailedToLoad => 'モーメントの読み込みに失敗しました';

  @override
  String get aiPronunciationWatchAdRetry => '広告を見てもう1回無料で挑戦';

  @override
  String aiErrorLoadingLanguages(Object error) {
    return '言語の読み込みエラー: $error';
  }

  @override
  String get aiSelectSourceTargetLanguages => '翻訳元と翻訳先の言語を選択してください';

  @override
  String get aiUnexpectedResponseFormat => '予期しない応答形式です';

  @override
  String get aiFailedToLoadConversation => '会話の読み込みに失敗しました';

  @override
  String get aiMicPermissionDeniedSettings => 'マイクの権限が拒否されました。設定で有効にしてください。';

  @override
  String get aiFailedToEvaluatePronunciation => '発音の評価に失敗しました';

  @override
  String get aiFailedToGenerateSpeech => '音声の生成に失敗しました';

  @override
  String get aiFailedToGenerateLesson => 'レッスンの生成に失敗しました';

  @override
  String get aiLessonTopicRequired => 'トピックを入力してください';

  @override
  String get aiFailedToLoadTopics => 'トピックの読み込みに失敗しました';

  @override
  String get aiFailedToLoadScenarios => 'シナリオの読み込みに失敗しました';

  @override
  String get aiAnalysisFailed => '分析に失敗しました';

  @override
  String get storySearchPlaceHint => '場所を検索…';

  @override
  String get storySearchRecentChatsHint => '最近のチャットを検索…';

  @override
  String get storySearchFollowingHint => 'フォロー中のユーザーを検索…';

  @override
  String get storyAddHashtagsHint => 'ハッシュタグを追加...';

  @override
  String get storyHighlightCreateFailed => 'ハイライトの作成に失敗しました';

  @override
  String get storyHighlightRenameFailed => 'ハイライト名の変更に失敗しました';

  @override
  String get storyHighlightDeleteFailed => 'ハイライトの削除に失敗しました';

  @override
  String get storyViewersLoadFailed => '閲覧者の読み込みに失敗しました';

  @override
  String get storyShareSent => '送信しました 💛';

  @override
  String storyShareSentPartial(Object names) {
    return '送信しました 💛 — $names への送信に失敗';
  }

  @override
  String get storyVoteFailed => '投票の送信に失敗しました';

  @override
  String get storyAnswerFailed => '回答の送信に失敗しました';

  @override
  String get storyAlreadyInHighlight => 'すでにハイライトに保存されています';

  @override
  String get storyAddedToHighlight => 'ハイライトに追加しました';

  @override
  String storyMaxHashtags(int max) {
    return 'ハッシュタグは最大$max個まで追加できます';
  }

  @override
  String storyMaxMentions(int max) {
    return 'メンションできるのは最大$max人までです';
  }

  @override
  String get coinHistoryActivity => 'コインのアクティビティ';

  @override
  String get coinHistoryAdReward => '広告を視聴';

  @override
  String get coinHistoryPurchase => 'コイン購入';

  @override
  String coinHistoryUnlocked(Object feature) {
    return '$featureをアンロック';
  }

  @override
  String get vipVisitorMessagesBenefit => '1日最大50件のメッセージを送信';

  @override
  String get vipVisitorProfilesBenefit => '1日最大100件のプロフィールを閲覧';

  @override
  String get vipVisitorFriendsBenefit => '友達を追加してつながりを広げよう';

  @override
  String get vipVisitorCommunitiesTitle => 'コミュニティに参加';

  @override
  String get vipVisitorCommunitiesBenefit => 'コミュニティのディスカッションに参加';

  @override
  String get vipVisitorMomentsTitle => 'モーメントをシェア';

  @override
  String get vipVisitorMomentsBenefit => 'モーメントを投稿してシェア';

  @override
  String get vipUnlimitedEverythingTitle => 'すべて無制限';

  @override
  String get vipUnlimitedEverythingBenefit => 'メッセージやプロフィール閲覧に1日の上限なし';

  @override
  String get vipProfileBoostBenefit => '検索結果での表示機会が増えます';

  @override
  String get vipAdFreeExperienceBenefit => '広告なしでアプリを楽しめます';

  @override
  String get featureGateUpgradeToUnlock => 'アップグレードしてこの機能を利用しましょう';

  @override
  String get featureGateVipOnly => 'VIP限定の機能';

  @override
  String get adsRewardedButtonLabel => '広告を見てボーナスをもらう';

  @override
  String get promoAdsPerkMessages => '+3 ボーナス\nメッセージ';

  @override
  String get promoAdsPerkFilters => 'フィルターを\n解除';

  @override
  String get promoAdsPerkXp => '+10 ボーナス\nXP';

  @override
  String get promoAdsPerkRetry => '無料で\nもう一度';

  @override
  String get visitorLimitMessagesTitle => '1日のメッセージ上限に達しました';

  @override
  String visitorLimitMessagesBody(int count) {
    return '今日は$count件のメッセージを送信しました。アップグレードしてもっと送信しましょう！';
  }

  @override
  String get visitorLimitProfilesTitle => '1日のプロフィール閲覧上限に達しました';

  @override
  String visitorLimitProfilesBody(int count) {
    return '今日は$count件のプロフィールを閲覧しました。アップグレードしてもっと見ましょう！';
  }

  @override
  String get visitorLimitFreeAccountBenefit => '1日の上限が増えます';

  @override
  String get visitorLimitVipBenefit => '無制限のアクセス';

  @override
  String get promoWelcomeBackTutorSubtitle => '会話・発音・クイズを練習';

  @override
  String get promoWelcomeBackCommunitySubtitle => '近くの言語パートナーを見つけよう';

  @override
  String get promoWelcomeBackMomentsSubtitle => '語学学習の歩みをシェアしよう';

  @override
  String get myReportsReportedId => '報告対象のID';

  @override
  String get myReportsReason => '理由';

  @override
  String get myReportsSubmitted => '送信日時';

  @override
  String get myReportsResolved => '解決日時';

  @override
  String get myReportsModeratorNotes => 'モデレーターのメモ';

  @override
  String get myReportsNotAvailable => 'なし';

  @override
  String get myReportsFailedToLoad => '報告の読み込みに失敗しました';

  @override
  String get voiceRecorderUnavailableDesktop => 'デスクトップでは音声録音は利用できません';

  @override
  String get adminPageUnavailable => 'このページは利用できません。';

  @override
  String storyShareSendFailedTo(Object names) {
    return '$names に送信できませんでした';
  }

  @override
  String get storyCantReact => 'このストーリーにはリアクションできません';

  @override
  String get storyCantReply => 'このストーリーには返信できません';

  @override
  String get storyNoMediaToSave => 'このストーリーには保存できるメディアがありません';

  @override
  String get coinsAdCrediting => '付与中…';

  @override
  String get coinsWatchAdReward => '広告を見る（+5 💎）';

  @override
  String callUnavailable(String name) {
    return '$nameさんは現在通話を受け付けていません';
  }

  @override
  String get callDeclineWithMessage => 'メッセージ';

  @override
  String get callDeclineSheetTitle => 'メッセージを添えて拒否';

  @override
  String get callDeclineCannedLater => '今は話せません。あとで折り返します。';

  @override
  String get callDeclineCannedText => '今は話せません。メッセージください。';

  @override
  String get callDeclineCustomHint => 'メッセージを入力…';

  @override
  String get callDeclineSend => '送信';

  @override
  String get callBackAction => 'かけ直す';

  @override
  String get callMessageAction => 'メッセージ';

  @override
  String get callsAllowTitle => '通話を許可';

  @override
  String get callsAllowSubtitle => 'オフにすると、あなたへの着信は鳴りません。発信者にはあなたが通話を受け付けていないことが表示されます。';

  @override
  String get callsQuietHoursNote => '「緊急通知を許可する」がオフの場合、サイレント時間中は着信も保留されます。';

  @override
  String get callTurnOnCamera => 'カメラ';

  @override
  String get callCameraFailed => 'カメラをオンにできませんでした';

  @override
  String get callSelfViewLabel => 'あなたのカメラ。ドラッグで移動できます。';

  @override
  String get callSelfViewSwapHint => 'ダブルタップで相手の映像と入れ替えます';

  @override
  String get studyGroupTalk => '話す';

  @override
  String get studyGroupPractice => '練習';

  @override
  String get studyGroupPrepare => '準備＆挑戦';

  @override
  String get studyTileTutor => 'AIチューター';

  @override
  String get studyTileTutorDesc => '何でも話そう';

  @override
  String get studyTileRoleplay => 'ロールプレイ';

  @override
  String get studyTileRoleplayDesc => '実生活の場面';

  @override
  String get studyTileStory => 'ストーリー';

  @override
  String get studyTileStoryDesc => '一緒に物語を作ろう';

  @override
  String get studyTilePhoto => '写真';

  @override
  String get studyTilePhotoDesc => '写真から単語を学ぶ';

  @override
  String get studyTileSpeak => 'スピーキング';

  @override
  String get studyTileSpeakDesc => '発音チェック';

  @override
  String get studyTileReview => '復習';

  @override
  String get studyTileReviewDesc => '今日の単語';

  @override
  String get studyTileWriting => 'ライティング';

  @override
  String get studyTileWritingDesc => '文法フィードバック';

  @override
  String get studyTileQuizzes => 'クイズ';

  @override
  String get studyTileQuizzesDesc => 'サクッとAIクイズ';

  @override
  String get studyTileExam => '試験対策';

  @override
  String get studyTileExamDesc => 'TOPIK, JLPT, IELTS…';

  @override
  String get studyTileLessons => 'レッスン';

  @override
  String get studyTileLessonsDesc => 'ステップごとのユニット';

  @override
  String get studyTileChallenges => 'チャレンジ';

  @override
  String get studyTileChallengesDesc => '毎日の目標でXPを獲得';

  @override
  String get studyTileLeaderboard => 'ランキング';

  @override
  String get studyTileLeaderboardDesc => '今週の順位を見る';

  @override
  String get studyBadgeVip => 'VIP';

  @override
  String studyBadgeLeft(int count) {
    return '残り$count';
  }

  @override
  String studyBadgeDue(int count) {
    return '$count件';
  }

  @override
  String get studyBadgeNew => 'NEW';

  @override
  String get studyEnglishOnly => '今は英語のみ';

  @override
  String get studyTodayPack => '今日のパック';

  @override
  String get studyTodayStart => 'スタート';

  @override
  String studyRecommended(String name, int percent) {
    return 'あなたへ：$name — 正答率$percent% · 5分クイズ';
  }

  @override
  String get studyProgressTitle => '学習の進捗';

  @override
  String get studyFullReport => '詳しいレポート';

  @override
  String studyStreakDays(int count) {
    return '$count日連続';
  }

  @override
  String studyLevelShort(int level) {
    return 'Lv $level';
  }

  @override
  String studyUpgradeLockedTitle(String feature) {
    return '$featureはVIP機能です';
  }

  @override
  String studyUpgradeExhaustedTitle(String feature) {
    return '今日の$featureを使い切りました';
  }

  @override
  String get studyUpgradeBenefitUnlimited => '毎日AI練習が無制限';

  @override
  String get studyUpgradeBenefitNoAds => 'アプリ内の広告なし';

  @override
  String get studyUpgradeGetVip => 'VIPになる — 無制限';

  @override
  String get guideStudyHubTitle => '毎日の語学ジム';

  @override
  String get guideStudyHubBody => '毎日5分のパックと、話したいときのAIチューター。';

  @override
  String get guideStudyHubCta => '今日のパックを始める';

  @override
  String get guideStudyHubSecondary => 'すべての機能を見る';

  @override
  String get supportBananaTalkRow => 'BananaTalkを応援';

  @override
  String get supportBananaTalkRowSubtitle => '個人開発者の開発を支えてください';

  @override
  String get restorePurchases => '購入を復元';

  @override
  String get restorePurchasesInProgress => '購入を復元しています…';

  @override
  String get restorePurchasesSuccess => '購入を復元しました。VIPが有効になりました。';

  @override
  String get restorePurchasesAlreadyActive => 'VIPサブスクリプションはすでに有効です。';

  @override
  String get restorePurchasesNothing => '復元できる購入はありません。';

  @override
  String get restorePurchasesFailed => '購入を復元できませんでした。もう一度お試しください。';

  @override
  String get callVoiceCallButton => '音声通話';

  @override
  String get callVideoCallButton => 'ビデオ通話';

  @override
  String get callPermissionMicSettings => '通話するには、設定でマイクへのアクセスを許可してください。';

  @override
  String get callPermissionCameraSettings => 'ビデオ通話をするには、設定でカメラへのアクセスを許可してください。';

  @override
  String get callPermissionMicCameraSettings => 'ビデオ通話をするには、設定でマイクとカメラへのアクセスを許可してください。';

  @override
  String get callQualityExcellent => '通話品質：非常に良好';

  @override
  String get callQualityGood => '通話品質：良好';

  @override
  String get callConnectionLost => '接続が切れました';

  @override
  String get biometricLoginSetting => 'Face ID / 指紋でサインイン';

  @override
  String get biometricLoginSettingDesc => 'ログアウト後、ログイン画面に「〜として続行」を表示します';

  @override
  String get personaUpgradeNana => 'ナナともっと話したい？🐻\nアップグレードで無制限に。';

  @override
  String get personaUpgradeSensei => 'センセイとトレーニングを続けよう。🤖\nアップグレードで制限なく練習できます。';

  @override
  String get personaUpgradeRiko => 'リコはまだウォーミングアップ中！🐙\nアップグレードして続けよう。';

  @override
  String get personaUpgradeGeneric => 'もっと続けたい？\nアップグレードでAI学習が無制限に。';

  @override
  String get chatListConversationPinned => '会話をピン留めしました';

  @override
  String get chatListConversationUnpinned => '会話のピン留めを解除しました';

  @override
  String get chatListConversationDeleted => '会話を削除しました';

  @override
  String get chatListConversationActionFailed => 'この会話を更新できませんでした。もう一度お試しください。';

  @override
  String get coinsPurchaseLinkedElsewhere => 'この購入はすでに別のBananaTalkアカウントに紐付けられているため、ここではコインは追加されませんでした。';

  @override
  String get coinsAlreadyCredited => 'このコインはすでにアカウントに追加されています。';

  @override
  String get pleaseRemoveImagesFirstToAddVoiceNote => 'ボイスメモを追加するには、先に画像を削除してください';

  @override
  String get authLockedTitle => 'アカウントが一時的にロックされています';

  @override
  String authLockedBodyMinutes(Object minutes) {
    return '失敗した試行が多すぎます。$minutes分後にもう一度お試しください。';
  }

  @override
  String get authLockedBodyLater => '失敗した試行が多すぎます。後でもう一度お試しください。';

  @override
  String get authRateLimitedTitle => '少しお待ちください';

  @override
  String authRateLimitedBodySeconds(Object seconds) {
    return '試行回数が多すぎます。$seconds秒後にもう一度お試しください。';
  }

  @override
  String get authRateLimitedBodyShortly => '試行回数が多すぎます。しばらくしてからもう一度お試しください。';

  @override
  String get passwordErrorLength => 'パスワードは8文字以上にしてください';

  @override
  String get passwordErrorUppercase => 'パスワードには大文字を1文字以上含めてください';

  @override
  String get passwordErrorLowercase => 'パスワードには小文字を1文字以上含めてください';

  @override
  String get passwordErrorNumber => 'パスワードには数字を1文字以上含めてください';

  @override
  String get authCodeExpired => 'このコードは有効期限が切れています。新しいコードをリクエストしてください。';

  @override
  String get authCodeIncorrect => 'コードが正しくありません。もう一度お試しください。';

  @override
  String get authVerificationFailed => '認証に失敗しました';

  @override
  String get authResendCodeFailed => 'コードを再送信できませんでした';

  @override
  String get authSendResetCodeFailed => 'リセットコードを送信できませんでした';

  @override
  String get authResetPasswordFailed => 'パスワードをリセットできませんでした';

  @override
  String get enableBiometricTitleAndroid => '次回から指紋認証または顔認証でログインしますか？';

  @override
  String chatLastSeenDate(Object date) {
    return '最終オンライン $date';
  }

  @override
  String get chatLastSeenRecently => '最近オンライン';

  @override
  String chatMediaTabMedia(Object count) {
    return 'メディア ($count)';
  }

  @override
  String chatMediaTabLinks(Object count) {
    return 'リンク ($count)';
  }

  @override
  String chatMediaTabDocs(Object count) {
    return 'ドキュメント ($count)';
  }

  @override
  String get chatMediaNoMedia => 'まだ写真や動画は共有されていません';

  @override
  String get chatMediaNoLinks => 'まだリンクは共有されていません';

  @override
  String get chatMediaNoDocs => 'まだドキュメントは共有されていません';

  @override
  String get chatMediaUnknownSize => 'サイズ不明';

  @override
  String chatDeleteMinutesLeft(Object minutes) {
    return '残り$minutes分';
  }

  @override
  String chatDeleteRemovesForBoth(Object name) {
    return 'あなたと$nameの両方から削除されます';
  }

  @override
  String get chatUnsupportedMessageType => 'サポートされていないメッセージ形式です';

  @override
  String get chatStoryUnavailable => 'このストーリーはもう表示できません';

  @override
  String get chatWallpapersUnlocked => 'プレミアム壁紙のロックを解除しました！';

  @override
  String get chatEditFailed => 'メッセージを編集できませんでした';

  @override
  String get chatPinFailed => 'ピン留めを更新できませんでした';

  @override
  String get chatMessagePinned => 'メッセージをピン留めしました';

  @override
  String get chatMessageUnpinned => 'メッセージのピン留めを解除しました';

  @override
  String get chatForwardFailed => 'メッセージを転送できませんでした';

  @override
  String get chatShareLocationFailed => '位置情報を共有できませんでした';

  @override
  String chatFileTooLarge(Object size) {
    return 'このファイルは大きすぎます。上限は${size}MBです。';
  }

  @override
  String get chatSendMediaFailed => 'メディアを送信できませんでした';

  @override
  String get chatSendVideoFailed => '動画を送信できませんでした';

  @override
  String get chatVideoTooLong => '動画は10分未満にしてください';

  @override
  String get chatVideoTooLarge => '動画は1GB未満にしてください。圧縮してください。';

  @override
  String get chatSendVoiceFailed => 'ボイスメッセージを送信できませんでした';

  @override
  String get chatVoiceTooLong => 'ボイスメッセージは5分未満にしてください';

  @override
  String get chatVoiceTooLarge => 'ボイスメッセージのファイルが大きすぎます';

  @override
  String get voiceRecorderInitFailed => '録音を準備できませんでした';

  @override
  String get voiceRecorderStartFailed => '録音を開始できませんでした';

  @override
  String get voiceRecorderFileMissing => '録音ファイルが見つかりません';

  @override
  String get voiceRecorderTooShort => '録音が短すぎます（最低1秒）';

  @override
  String get voiceRecorderResume => '再開';

  @override
  String get voiceRecorderPause => '一時停止';

  @override
  String get voiceRecorderPaused => '録音を一時停止中 - 再生をタップして続ける';

  @override
  String get voiceRecorderRecording => '録音中… 終わったら一時停止か送信をタップ';

  @override
  String get voiceRecorderInitializing => '準備中…';

  @override
  String get chatGifSearchFailed => '検索に失敗しました。もう一度お試しください。';

  @override
  String chatGifResultsFor(Object query) {
    return '「$query」の結果';
  }

  @override
  String get chatYouSharedStory => 'ストーリーをシェアしました';

  @override
  String chatUserSharedStory(Object name) {
    return '$nameさんがストーリーをシェアしました';
  }

  @override
  String chatUserNotInChats(Object name) {
    return '@$name はチャットにいません';
  }

  @override
  String get chatDeleteMessageFailed => 'メッセージを削除できませんでした';

  @override
  String get themeAutomatic => '自動';

  @override
  String get themeManual => '手動';

  @override
  String get themeFollowingSystem => 'システムに従う';

  @override
  String get profileAdminToolsSubtitle => '通報・ユーザー・監査ログ';

  @override
  String appVersionLabel(Object version) {
    return 'バージョン $version';
  }

  @override
  String get privacyVisitAnonymously => '匿名でプロフィールを閲覧';

  @override
  String get privacyVisitAnonymouslyDesc => '訪問した相手の最近の訪問者リストにあなたの名前は表示されません。';

  @override
  String get profilePhotoUploading => 'アップロード中…';

  @override
  String get profilePhotoRemoving => '削除中…';

  @override
  String get profileCropPhoto => '写真を切り抜く';

  @override
  String get networkWifi => 'Wi-Fi';

  @override
  String get networkMobileData => 'モバイルデータ';

  @override
  String get networkEthernet => 'イーサネット';

  @override
  String get notifPrefResetFailed => '設定をリセットできませんでした';

  @override
  String get notifPrefNewFollower => '新しいフォロワー';

  @override
  String get notifPrefVipRenewalWarning => 'VIP更新のリマインダー';

  @override
  String get accountDeletedSuccess => 'アカウントを削除しました';

  @override
  String get accountDeleteFailed => 'アカウントを削除できませんでした';

  @override
  String get coinHistoryLoadFailed => 'コイン履歴を読み込めませんでした。';

  @override
  String get waveAlreadySentTooltip => '手を振り済み — メッセージを送りましょう';

  @override
  String waveAlreadySentTo(Object name) {
    return '$nameさんにはすでに手を振りました。メッセージを送りましょう。';
  }

  @override
  String get waveAlreadyWaved => '手を振り済み';

  @override
  String get communityCountryDetectFailed => '国を検出できませんでした';

  @override
  String get roomPickCategoryError => 'カテゴリを選んでください';

  @override
  String get blockUserSuccess => 'ユーザーをブロックしました';

  @override
  String get blockUserFailed => 'このユーザーをブロックできませんでした';

  @override
  String get unblockUserSuccess => 'ブロックを解除しました';

  @override
  String get unblockUserFailed => 'ブロックを解除できませんでした';

  @override
  String get clubDeleteFailed => 'クラブを削除できませんでした';

  @override
  String get clubMemberUpdateFailed => 'このメンバーを更新できませんでした';

  @override
  String get groupCoverUploadFailed => '写真をアップロードできませんでした';

  @override
  String get groupCoverRemoveFailed => '写真を削除できませんでした';

  @override
  String get clubStatusArchived => 'アーカイブ済み';

  @override
  String get matchTagSimilarAge => '同年代';

  @override
  String matchTagBothLike(Object topic) {
    return '共通の趣味: $topic';
  }

  @override
  String get topicNameCooking => '料理';

  @override
  String get topicNameCoffee => 'コーヒー＆紅茶';

  @override
  String get topicNameEatingOut => '外食';

  @override
  String get topicNameBaking => 'お菓子作り';

  @override
  String get topicNameDrinking => 'お酒';

  @override
  String get topicNameStreetFood => '屋台グルメ';

  @override
  String get topicNameTravel => '旅行';

  @override
  String get topicNameBackpacking => 'バックパッカー';

  @override
  String get topicNameBeaches => 'ビーチ';

  @override
  String get topicNameMountains => '山';

  @override
  String get topicNameCamping => 'キャンプ';

  @override
  String get topicNameGym => 'ジム';

  @override
  String get topicNameRunning => 'ランニング';

  @override
  String get topicNameYoga => 'ヨガ';

  @override
  String get topicNameFootball => 'サッカー';

  @override
  String get topicNameBasketball => 'バスケットボール';

  @override
  String get topicNameHiking => 'ハイキング';

  @override
  String get topicNameCycling => 'サイクリング';

  @override
  String get topicNameDancing => 'ダンス';

  @override
  String get topicNameSwimming => '水泳';

  @override
  String get topicNameMovies => '映画';

  @override
  String get topicNameTvShows => 'テレビ番組';

  @override
  String get topicNameMusic => '音楽';

  @override
  String get topicNameGaming => 'ゲーム';

  @override
  String get topicNameAnime => 'アニメ・マンガ';

  @override
  String get topicNameKpop => 'K-POP';

  @override
  String get topicNameKdrama => '韓国ドラマ';

  @override
  String get topicNamePodcasts => 'ポッドキャスト';

  @override
  String get topicNameArt => 'アート';

  @override
  String get topicNamePhotography => '写真';

  @override
  String get topicNameBooks => '本';

  @override
  String get topicNameWriting => '執筆';

  @override
  String get topicNameHistory => '歴史';

  @override
  String get topicNameDesign => 'デザイン';

  @override
  String get topicNameFashion => 'ファッション';

  @override
  String get topicNameBeauty => '美容・スキンケア';

  @override
  String get topicNameShopping => 'ショッピング';

  @override
  String get topicNameGardening => 'ガーデニング';

  @override
  String get topicNameDiy => 'DIY';

  @override
  String get topicNameDogs => '犬';

  @override
  String get topicNameCats => '猫';

  @override
  String get topicNameNature => '自然';

  @override
  String get topicNameAnimals => '動物';

  @override
  String get topicNameLanguageExchange => '言語交換';

  @override
  String get topicNameStudyAbroad => '留学';

  @override
  String get topicNameTechnology => 'テクノロジー';

  @override
  String get topicNameProgramming => 'プログラミング';

  @override
  String get topicNameBusiness => 'ビジネス';

  @override
  String get topicNameScience => '科学';

  @override
  String get topicNameDailyLife => '日常生活';

  @override
  String get topicNameMakingFriends => '友達づくり';

  @override
  String get topicNameRelationships => '恋愛・人間関係';

  @override
  String get topicNameFamily => '家族';

  @override
  String get topicNameNightlife => 'ナイトライフ';

  @override
  String get topicNameMentalHealth => 'メンタルヘルス';

  @override
  String get topicNameMeditation => '瞑想';

  @override
  String get topicNameNutrition => '栄養';

  @override
  String get topicNameSelfImprovement => '自己成長';

  @override
  String get topicCategoryFoodDrink => '食べ物・飲み物';

  @override
  String get topicCategoryTravel => '旅行・アドベンチャー';

  @override
  String get topicCategorySports => 'スポーツ・フィットネス';

  @override
  String get topicCategoryEntertainment => 'エンタメ・音楽';

  @override
  String get topicCategoryArts => 'アート・文化';

  @override
  String get topicCategoryLifestyle => 'ライフスタイル';

  @override
  String get topicCategoryPetsNature => 'ペット・自然';

  @override
  String get topicCategoryLearning => '学び・キャリア';

  @override
  String get topicCategorySocial => '交流';

  @override
  String get topicCategoryHealth => '健康・ウェルネス';

  @override
  String get waveTooMany => '手を振りすぎです。少しペースを落としてください！';

  @override
  String get aiTutorNoSummary => '（要約なし）';

  @override
  String vocabPackAllSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count語すべてが単語帳に登録済みです',
    );
    return '$_temp0';
  }

  @override
  String vocabPackAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '単語帳に$count語を追加しました',
    );
    return '$_temp0';
  }

  @override
  String vocabPackAddedSomeSaved(int count, int saved) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '単語帳に$count語を追加しました（$saved語は登録済み）',
    );
    return '$_temp0';
  }

  @override
  String get vocabPackNoExercises => '練習問題なし';

  @override
  String vocabPackPractice(int count) {
    return '練習する ($count)';
  }

  @override
  String get aiQuizPlayAgain => 'もう一度プレイ';

  @override
  String get aiLessonAskHint => 'このレッスンについて何でも質問してください…';

  @override
  String get aiLessonConceptHint => '説明してほしい概念は何ですか？';

  @override
  String examTargetScoreHint(Object score) {
    return '例: $score';
  }

  @override
  String get vocabWordAdded => '単語を追加しました！';

  @override
  String get vocabWordAddFailed => '単語を追加できませんでした';

  @override
  String get vocabEnterWordFirst => 'まず単語を入力してください';

  @override
  String get vocabAiFilled => 'AIが入力しました！';

  @override
  String get vocabAiFillFailed => 'AIの入力に失敗しました。もう一度お試しください。';

  @override
  String get authSendCodeFailed => '認証コードを送信できませんでした';

  @override
  String get authServerConfigError => 'サーバー設定エラーです。サポートにお問い合わせください。';

  @override
  String get authAppleTokenFailed => 'Appleでサインインできませんでした。もう一度お試しください。';

  @override
  String get authRegistrationFailed => '登録に失敗しました';

  @override
  String get authEmailAlreadyExists => 'このメールアドレスは既に使われています。別のアドレスを使ってください。';

  @override
  String get reportEvidenceAddFailed => '写真を追加できませんでした';

  @override
  String reportEvidenceMaxFiles(int count) {
    return '1件の通報につき最大$countファイル';
  }

  @override
  String reportEvidenceFileTooLarge(Object name) {
    return '$nameは大きすぎます（最大5MB）';
  }

  @override
  String get reportEvidenceTotalTooLarge => '合計サイズが25MBを超えます';

  @override
  String get blockedContentUnavailableToYou => 'このコンテンツは表示できません。';

  @override
  String blockedCantViewUserContent(Object name) {
    return '$nameさんのコンテンツは表示できません。';
  }

  @override
  String get blockedCantViewThisUserContent => 'このユーザーのコンテンツは表示できません。';

  @override
  String blockedCantViewUserProfile(Object name) {
    return '$nameさんのプロフィールは表示できません。';
  }

  @override
  String get blockedProfileUnavailable => 'このプロフィールは表示できません。';

  @override
  String get blockedContentUnavailable => 'このコンテンツは表示できません。';

  @override
  String get blockedCantViewStories => 'これらのストーリーは表示できません。';

  @override
  String blockedCantMessageUser(Object name) {
    return '$nameさんにはメッセージを送れません。';
  }

  @override
  String get blockedCantMessageThisUser => 'このユーザーにはメッセージを送れません。';

  @override
  String get blockedActionNotAllowed => 'この操作はできません';

  @override
  String get blockedCantLike => 'このコンテンツにはいいねできません';

  @override
  String get blockedCantComment => 'このコンテンツにはコメントできません';

  @override
  String get imageViewerRotate => '回転';

  @override
  String get momentNotFound => 'モーメントが見つかりません';

  @override
  String get momentRecordingCapped => '録音は60秒までに制限されました';

  @override
  String get momentVoiceNoteUploaded => 'ボイスメモをアップロードしました';

  @override
  String get momentUploadDidNotComplete => 'アップロードが完了しませんでした。';

  @override
  String get momentUploadGiveUp => 'これが最後の試行でした。ファイルではなく通信状況が原因の可能性があります。モーメントはすでに投稿済みです。後で編集してボイスメモを追加できます。';

  @override
  String momentUploadTriesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '残り$count回です。',
    );
    return '$_temp0';
  }

  @override
  String get wallpaperPresetDefault => 'デフォルト';

  @override
  String get wallpaperPresetDark => 'ダーク';

  @override
  String get wallpaperPresetMidnight => 'ミッドナイト';

  @override
  String get wallpaperPresetCharcoal => 'チャコール';

  @override
  String get wallpaperPresetNavy => 'ネイビー';

  @override
  String get wallpaperPresetOcean => 'オーシャン';

  @override
  String get wallpaperPresetTeal => 'ティール';

  @override
  String get wallpaperPresetForest => 'フォレスト';

  @override
  String get wallpaperPresetSage => 'セージ';

  @override
  String get wallpaperPresetWine => 'ワイン';

  @override
  String get wallpaperPresetPlum => 'プラム';

  @override
  String get wallpaperPresetRose => 'ローズ';

  @override
  String get wallpaperPresetMocha => 'モカ';

  @override
  String get wallpaperPresetSlate => 'スレート';

  @override
  String get wallpaperPresetEmber => 'エンバー';

  @override
  String get wallpaperPresetDeepSea => 'ディープシー';

  @override
  String get wallpaperPresetCream => 'クリーム';

  @override
  String get wallpaperPresetBlush => 'ブラッシュ';

  @override
  String get wallpaperPresetPeach => 'ピーチ';

  @override
  String get wallpaperPresetSunset => 'サンセット';

  @override
  String get wallpaperPresetAurora => 'オーロラ';

  @override
  String get wallpaperPresetCosmic => 'コズミック';

  @override
  String get wallpaperPresetRoseGold => 'ローズゴールド';

  @override
  String get wallpaperPresetCandy => 'キャンディ';

  @override
  String get wallpaperPresetNeon => 'ネオン';

  @override
  String get wallpaperPresetFire => 'ファイア';

  @override
  String get wallpaperPresetWinter => 'ウィンター';

  @override
  String get wallpaperPresetLavender => 'ラベンダー';

  @override
  String get wallpaperPresetAuroraBorealis => 'オーロラ・ボレアリス';

  @override
  String get wallpaperPresetGoldenHour => 'ゴールデンアワー';

  @override
  String get wallpaperPresetGalaxy => 'ギャラクシー';

  @override
  String get wallpaperPresetEmeraldLuxe => 'エメラルドリュクス';

  @override
  String get wallpaperPresetRoyalVelvet => 'ロイヤルベルベット';

  @override
  String get wallpaperPresetDiamondShine => 'ダイヤモンドシャイン';

  @override
  String get communityWorldwide => '世界中';

  @override
  String communitySearchTitle(String query) {
    return '検索: $query';
  }

  @override
  String get communityFilterNew => '新規';

  @override
  String get vipSwitchPlan => 'プランを変更';

  @override
  String get vipCurrentPlan => '現在のプラン';

  @override
  String get vipSwitchPlanUnavailable => 'このアカウントで変更できる Google Play の定期購入が見つかりません。Google Play で定期購入を管理してください。';

  @override
  String get vipSwitchScheduledTitle => 'プラン変更を予約しました';

  @override
  String get vipSwitchScheduledBody => '新しいプランは現在のプランの終了時に始まります。それまで VIP のままです。';

  @override
  String videoTooLongMax(int seconds) {
    return 'この動画は長すぎます。上限は$seconds秒です。';
  }

  @override
  String momentAnsweringPrompt(String prompt) {
    return 'お題への回答: $prompt';
  }

  @override
  String get referralHaveCode => '招待コードをお持ちですか？';

  @override
  String get referralEnterCodeHint => '招待コード';

  @override
  String get referralApply => '適用';

  @override
  String get referralCodeUnknown => 'その招待コードは存在しません。確認してもう一度お試しください。';

  @override
  String get referralCodeNotAccepted => 'この招待コードはお使いのアカウントでは使用できません。';

  @override
  String get rateBananaTalkRow => 'BananaTalkを評価';

  @override
  String get rateBananaTalkRowSubtitle => 'ストアでレビューを書く';
}
