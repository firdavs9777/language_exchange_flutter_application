// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Bananatalk';

  @override
  String get aiStudyPromoTitle => 'AI senaryolarıyla pratik yap';

  @override
  String get aiStudyPromoBody => 'AI öğretmeninle gerçek hayat konuşmalarını canlandır ve konuşma özgüvenini geliştir.';

  @override
  String get aiStudyPromoCTA => 'Bir senaryo dene';

  @override
  String get aiStudyPromoDismiss => 'Belki sonra';

  @override
  String get login => 'Giriş Yap';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get forgotPassword => 'Şifremi Unuttum?';

  @override
  String get or => 'VEYA';

  @override
  String get more => 'daha fazla';

  @override
  String get signInWithGoogle => 'Google ile giriş yap';

  @override
  String get signInWithApple => 'Apple ile giriş yap';

  @override
  String get signInWithFacebook => 'Facebook ile giriş yap';

  @override
  String get welcome => 'Hoş Geldiniz';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get messages => 'Mesajlar';

  @override
  String get moments => 'Anlar';

  @override
  String get overview => 'Genel Bakış';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Ayarlar';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get language => 'Dil';

  @override
  String get selectLanguage => 'Dil Seç';

  @override
  String get autoTranslate => 'Otomatik Çeviri';

  @override
  String get autoTranslateMessages => 'Mesajları Otomatik Çevir';

  @override
  String get autoTranslateMoments => 'Anları Otomatik Çevir';

  @override
  String get autoTranslateComments => 'Yorumları Otomatik Çevir';

  @override
  String get translate => 'Çevir';

  @override
  String get translated => 'Çevrildi';

  @override
  String get showOriginal => 'Orijinali Göster';

  @override
  String get showTranslation => 'Çeviriyi Göster';

  @override
  String get translating => 'Çevriliyor...';

  @override
  String get translationFailed => 'Çeviri başarısız';

  @override
  String get noTranslationAvailable => 'Çeviri mevcut değil';

  @override
  String translatedFrom(String language) {
    return '$language dilinden çevrildi';
  }

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get delete => 'Sil';

  @override
  String get edit => 'Düzenle';

  @override
  String get share => 'Paylaş';

  @override
  String get like => 'Beğen';

  @override
  String get comment => 'Yorum';

  @override
  String get send => 'Gönder';

  @override
  String get search => 'Ara';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get followers => 'Takipçiler';

  @override
  String get following => 'Takip Edilenler';

  @override
  String get posts => 'Gönderiler';

  @override
  String get visitors => 'Ziyaretçiler';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get error => 'Hata';

  @override
  String get success => 'Başarılı';

  @override
  String get tryAgain => 'Tekrar Dene';

  @override
  String get networkError => 'Ağ hatası. Lütfen bağlantınızı kontrol edin.';

  @override
  String get somethingWentWrong => 'Bir şeyler ters gitti';

  @override
  String get ok => 'Tamam';

  @override
  String get yes => 'Evet';

  @override
  String get no => 'Hayır';

  @override
  String get languageSettings => 'Dil Ayarları';

  @override
  String get deviceLanguage => 'Cihaz Dili';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return 'Cihazınız şu dile ayarlı: $flag $name';
  }

  @override
  String get youCanOverride => 'Aşağıdan cihaz dilini değiştirebilirsiniz.';

  @override
  String languageChangedTo(String name) {
    return 'Dil $name olarak değiştirildi';
  }

  @override
  String get errorChangingLanguage => 'Dil değiştirme hatası';

  @override
  String get autoTranslateSettings => 'Otomatik Çeviri Ayarları';

  @override
  String get automaticallyTranslateIncomingMessages => 'Gelen mesajları otomatik çevir';

  @override
  String get automaticallyTranslateMomentsInFeed => 'Akıştaki anları otomatik çevir';

  @override
  String get automaticallyTranslateComments => 'Yorumları otomatik çevir';

  @override
  String get translationServiceBeingConfigured => 'Çeviri hizmeti yapılandırılıyor. Lütfen daha sonra tekrar deneyin.';

  @override
  String get translationUnavailable => 'Çeviri mevcut değil';

  @override
  String get showLess => 'daha az göster';

  @override
  String get showMore => 'daha fazla göster';

  @override
  String get comments => 'Yorumlar';

  @override
  String get beTheFirstToComment => 'İlk yorumu siz yapın.';

  @override
  String get writeAComment => 'Bir yorum yazın...';

  @override
  String get report => 'Bildir';

  @override
  String get reportMoment => 'Anı Bildir';

  @override
  String get reportUser => 'Kullanıcıyı Bildir';

  @override
  String get deleteMoment => 'An silinsin mi?';

  @override
  String get thisActionCannotBeUndone => 'Bu işlem geri alınamaz.';

  @override
  String get momentDeleted => 'An silindi';

  @override
  String get deleteComment => 'Delete Comment?';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get editFeatureComingSoon => 'Düzenleme özelliği yakında';

  @override
  String get userNotFound => 'Kullanıcı bulunamadı';

  @override
  String get cannotReportYourOwnComment => 'Kendi yorumunuzu bildiremezsiniz';

  @override
  String get profileSettings => 'Profil Ayarları';

  @override
  String get editYourProfileInformation => 'Profil bilgilerinizi düzenleyin';

  @override
  String get blockedUsers => 'Engellenen Kullanıcılar';

  @override
  String get manageBlockedUsers => 'Engellenen kullanıcıları yönet';

  @override
  String get manageNotificationSettings => 'Bildirim ayarlarını yönet';

  @override
  String get privacySecurity => 'Gizlilik ve Güvenlik';

  @override
  String get controlYourPrivacy => 'Gizliliğinizi kontrol edin';

  @override
  String get changeAppLanguage => 'Uygulama dilini değiştir';

  @override
  String get appearance => 'Görünüm';

  @override
  String get themeAndDisplaySettings => 'Tema ve görüntüleme ayarları';

  @override
  String get clearCache => 'Önbelleği Temizle';

  @override
  String get clearCacheSubtitle => 'Depolama alanı aç';

  @override
  String get clearCacheDescription => 'Bu, önbelleğe alınmış tüm görüntüleri, videoları ve ses dosyalarını temizleyecektir. Uygulama, medyayı yeniden indirirken içeriği geçici olarak daha yavaş yükleyebilir.';

  @override
  String get clearCacheHint => 'Görüntüler veya ses düzgün yüklenmiyorsa bunu kullanın.';

  @override
  String get clearingCache => 'Önbellek temizleniyor...';

  @override
  String get cacheCleared => 'Önbellek başarıyla temizlendi! Görüntüler yeniden yüklenecek.';

  @override
  String get clearCacheFailed => 'Önbellek temizlenemedi';

  @override
  String get myReports => 'Bildirilerim';

  @override
  String get viewYourSubmittedReports => 'Gönderdiğiniz bildirimleri görüntüleyin';

  @override
  String get reportsManagement => 'Bildirim Yönetimi';

  @override
  String get manageAllReportsAdmin => 'Tüm bildirimleri yönet (Admin)';

  @override
  String get legalPrivacy => 'Yasal ve Gizlilik';

  @override
  String get termsPrivacySubscriptionInfo => 'Şartlar, Gizlilik ve Abonelik bilgisi';

  @override
  String get helpCenter => 'Yardım Merkezi';

  @override
  String get getHelpAndSupport => 'Yardım ve destek alın';

  @override
  String get aiTutorChangePersona => 'AI öğretmenini değiştir';

  @override
  String get aiTutorChangePersonaSubtitle => 'Nana, Sensei veya Riko\'ya geç';

  @override
  String aiTutorHeroTitleSet(String name) {
    return 'AI Öğretmenin · $name';
  }

  @override
  String get aiTutorHeroTitleNew => 'AI Öğretmeninle tanış';

  @override
  String get aiTutorHeroSubtitleSet => 'Sohbet etmek veya bugünkü planı görmek için dokun';

  @override
  String aiTutorHeroSubtitleLast(String summary) {
    return 'Geçen sefer: $summary';
  }

  @override
  String get aiTutorHeroSubtitleNew => 'Bir karakter seç — Nana, Sensei veya Riko';

  @override
  String get aiTutorChipChat => 'Sohbet';

  @override
  String get aiTutorChipRoleplay => 'Rol oynama';

  @override
  String get aiTutorChipStory => 'Hikaye';

  @override
  String get aiTutorChipPhoto => 'Fotoğraf';

  @override
  String get aiToolsMoreSection => 'More AI tools';

  @override
  String get aiConversationPartnerTile => 'AI Sohbeti';

  @override
  String get aiConversationPartnerTileSubtitle => 'AI partneriyle pratik yap';

  @override
  String get aiTutorPickerTitle => 'AI öğretmenini seç';

  @override
  String get aiTutorPickerHeader => 'Kiminle öğrenmek istiyorsun?';

  @override
  String get aiTutorPickerSubtitle => 'Bunu ayarlardan istediğin zaman değiştirebilirsin.';

  @override
  String get aiTutorPersonaNanaTagline => 'Sıcak + cesaretlendirici';

  @override
  String get aiTutorPersonaNanaSample => 'Baskısız, seni destekleyeceğim.';

  @override
  String get aiTutorPersonaSenseiTagline => 'Hassas + sınav odaklı';

  @override
  String get aiTutorPersonaSenseiSample => 'Kuralları ustalaşacağız.';

  @override
  String get aiTutorPersonaRikoTagline => 'Eğlenceli + samimi';

  @override
  String get aiTutorPersonaRikoSample => 'hadi eğlenelim ve öğrenelim';

  @override
  String aiTutorPickerSaveError(String error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String get aiTutorHomeTitle => 'AI Öğretmen';

  @override
  String get aiTutorHomeChangeTutor => 'Öğretmeni değiştir';

  @override
  String get aiTutorHomeGreetingDefault => 'Selam! Birlikte öğrenmeye hazır mısın?';

  @override
  String get aiTutorHomeTodaysPlan => 'Bugünkü plan';

  @override
  String get aiTutorHomePlanEmpty => 'Bugün için plan yok — başlamak için bir sohbet aç.';

  @override
  String get aiTutorHomeStartChat => 'Sohbete başla';

  @override
  String get aiTutorHomeRecent => 'Son';

  @override
  String get aiTutorHomePracticeScenarios => 'Pratik senaryoları';

  @override
  String get aiTutorHomePracticeScenariosSubtitle => 'Gerçek konuşmaları canlandır — restoran, mülakat, otel…';

  @override
  String get aiTutorHomeReadStory => 'Hikaye oku';

  @override
  String get aiTutorHomeReadStorySubtitle => 'AI senin kelimelerinle kısa bir hikaye yazar — hızlı anlama soruları ile.';

  @override
  String get aiTutorHomeDescribePhoto => 'Bir fotoğrafı tanımla';

  @override
  String get aiTutorHomeDescribePhotoSubtitle => 'Bir fotoğraf çek ve tanımla — AI kelime + dilbilgisini puanlar.';

  @override
  String get aiTutorChatTitle => 'Öğretmenle sohbet';

  @override
  String get aiTutorChatVoiceOn => 'Ses açık';

  @override
  String get aiTutorChatVoiceOff => 'Ses kapalı';

  @override
  String get aiTutorChatStopRecording => 'Kaydı durdur';

  @override
  String get aiTutorChatHoldToTalk => 'Konuşmak için basılı tut';

  @override
  String get aiTutorChatTranscribing => 'Yazıya dökülüyor…';

  @override
  String get aiTutorChatListening => 'Dinleniyor…';

  @override
  String get aiTutorChatInputHint => 'Mesaj yaz…';

  @override
  String get aiTutorChatTypeReplyHint => 'Yanıtını yaz…';

  @override
  String get aiTutorChatMicPermissionDenied => 'Ses modu için mikrofon izni gerekli.';

  @override
  String get aiTutorChatTranscribeFailed => 'Anlayamadım — tekrar dene.';

  @override
  String aiTutorChatStartFailed(String error) {
    return 'Başlatılamadı: $error';
  }

  @override
  String get aiTutorRoleplayEnd => 'Bitir';

  @override
  String aiTutorRoleplayEndFailed(String error) {
    return 'Bitirilemedi: $error';
  }

  @override
  String get aiTutorRoleplayDone => 'Tamam';

  @override
  String get aiTutorStoryTitle => 'Bir hikaye oku';

  @override
  String get aiTutorStoryLength => 'Uzunluk';

  @override
  String get aiTutorStoryTheme => 'Tema';

  @override
  String aiTutorStoryWordCount(int count) {
    return '$count kelime';
  }

  @override
  String get aiTutorStoryWriting => 'Yazılıyor…';

  @override
  String get aiTutorStoryGenerate => 'Hikaye oluştur';

  @override
  String aiTutorStoryGenerateFailed(String error) {
    return 'Oluşturulamadı: $error';
  }

  @override
  String aiTutorStoryWordCountHint(int n) {
    return 'AI, listende $n kelimeye kadar kullanacak.';
  }

  @override
  String get aiTutorStoryThemeFree => 'Serbest';

  @override
  String get aiTutorStoryThemeAdventure => 'Macera';

  @override
  String get aiTutorStoryThemeMystery => 'Gizem';

  @override
  String get aiTutorStoryThemeRomance => 'Romantik';

  @override
  String get aiTutorStoryThemeSciFi => 'Bilim kurgu';

  @override
  String get aiTutorStoryThemeSliceOfLife => 'Günlük hayat';

  @override
  String get aiTutorStoryReaderTitle => 'Hikaye';

  @override
  String get aiTutorStoryReaderVocab => 'Kelime';

  @override
  String get aiTutorStoryReaderVocabUsed => 'Kullanılan kelimeler';

  @override
  String aiTutorStoryReaderPart(int n) {
    return '$n. bölüm';
  }

  @override
  String get aiTutorStoryReaderWrongHint => 'Tam olarak değil — devam';

  @override
  String get aiTutorStoryReaderNiceWork => 'Harika!';

  @override
  String aiTutorStoryReaderScore(int correct, int total) {
    return '$correct/$total anlama sorusunu doğru cevapladın.';
  }

  @override
  String get aiTutorStoryReaderDone => 'Tamam';

  @override
  String get aiTutorImageVocabTitle => 'Bir fotoğrafı tanımla';

  @override
  String get aiTutorImagePickHeader => 'Tanımlayacak bir fotoğraf seç';

  @override
  String get aiTutorImagePickSubtitle => 'AI hedef dilinde bir komut verir, sonra senin tanımını puanlar.';

  @override
  String get aiTutorImagePickCamera => 'Kamera';

  @override
  String get aiTutorImagePickGallery => 'Galeri';

  @override
  String aiTutorImagePickError(String error) {
    return 'Resim açılamadı: $error';
  }

  @override
  String get aiTutorImageDescriptionHint => 'Tanımını yaz…';

  @override
  String get aiTutorImageDifferentPhoto => 'Başka fotoğraf';

  @override
  String get aiTutorImageSubmit => 'Gönder';

  @override
  String get aiTutorImageGrammarNotes => 'Dilbilgisi notları';

  @override
  String get aiTutorImageThingsYouMissed => 'Kaçırdıkların';

  @override
  String get aiTutorImageTryAnother => 'Başka fotoğraf dene';

  @override
  String get aiTutorCardQuiz => 'Test';

  @override
  String get aiTutorCardVocab => 'Kelime';

  @override
  String get aiTutorCardGrammar => 'Dilbilgisi';

  @override
  String get aiTutorCardReviewDue => 'Tekrar zamanı';

  @override
  String get aiTutorCardMiniLesson => 'Mini ders';

  @override
  String get aiTutorCardAddToVocab => 'Kelimeye ekle';

  @override
  String get aiTutorCardAddedToVocab => 'Eklendi';

  @override
  String get aiTutorCardAdding => 'Ekleniyor…';

  @override
  String aiTutorCardReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kart seni bekliyor',
      one: '$count kart seni bekliyor',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorCardReviewNow => 'Şimdi tekrarla';

  @override
  String get aiTutorCardReviewStarting => 'Başlıyor…';

  @override
  String get aiTutorCardTryIt => 'Dene';

  @override
  String get aiTutorCardPracticing => 'Pratik yapılıyor…';

  @override
  String aiTutorPlanSrsReview(int count, int done) {
    return '$count SRS kart tekrarla ($done bitti)';
  }

  @override
  String aiTutorPlanGrammar(String topic) {
    return 'Pratik: $topic';
  }

  @override
  String aiTutorPlanChat(int min, int done) {
    return '$min dk sohbet ($done şimdiye dek)';
  }

  @override
  String get aboutBananatalk => 'Bananatalk Hakkında';

  @override
  String get deleteAccount => 'Hesabı Sil';

  @override
  String get permanentlyDeleteYourAccount => 'Hesabınızı kalıcı olarak silin';

  @override
  String get loggedOutSuccessfully => 'Başarıyla çıkış yapıldı';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get giftsLikes => 'Hediyeler/Beğeniler';

  @override
  String get details => 'Detaylar';

  @override
  String get to => 'kime';

  @override
  String get banaTalk => 'Bananatalk';

  @override
  String get chats => 'Sohbetler';

  @override
  String get community => 'Topluluk';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String yearsOld(String age) {
    return '$age yaşında';
  }

  @override
  String get searchConversations => 'Sohbetleri ara...';

  @override
  String get visitorTrackingNotAvailable => 'Ziyaretçi takibi henüz mevcut değil. Backend güncellemesi gerekli.';

  @override
  String get chatList => 'Sohbet Listesi';

  @override
  String get languageExchange => 'Dil Değişimi';

  @override
  String get nativeLanguage => 'Ana Dil';

  @override
  String get learning => 'Öğreniyor';

  @override
  String get notSet => 'Ayarlanmadı';

  @override
  String get about => 'Hakkında';

  @override
  String get aboutMe => 'Hakkımda';

  @override
  String get bloodType => 'Kan Grubu';

  @override
  String get photos => 'Fotoğraflar';

  @override
  String get camera => 'Kamera';

  @override
  String get createMoment => 'An Oluştur';

  @override
  String get addATitle => 'Başlık ekle...';

  @override
  String get whatsOnYourMind => 'Aklınızdan ne geçiyor?';

  @override
  String get addTags => 'Etiket Ekle';

  @override
  String get done => 'Tamam';

  @override
  String get add => 'Ekle';

  @override
  String get enterTag => 'Etiket girin';

  @override
  String get post => 'Paylaş';

  @override
  String get commentAddedSuccessfully => 'Yorum başarıyla eklendi';

  @override
  String get clearFilters => 'Filtreleri Temizle';

  @override
  String get notificationSettings => 'Bildirim Ayarları';

  @override
  String get enableNotifications => 'Bildirimleri Etkinleştir';

  @override
  String get turnAllNotificationsOnOrOff => 'Tüm bildirimleri aç veya kapat';

  @override
  String get notificationTypes => 'Bildirim Türleri';

  @override
  String get chatMessages => 'Sohbet Mesajları';

  @override
  String get getNotifiedWhenYouReceiveMessages => 'Mesaj aldığınızda bildirim alın';

  @override
  String get likesAndCommentsOnYourMoments => 'Anlarınızdaki beğeniler ve yorumlar';

  @override
  String get whenPeopleYouFollowPostMoments => 'Takip ettiğiniz kişiler an paylaştığında';

  @override
  String get friendRequests => 'Arkadaşlık İstekleri';

  @override
  String get whenSomeoneFollowsYou => 'Biri sizi takip ettiğinde';

  @override
  String get profileVisits => 'Profil Ziyaretleri';

  @override
  String get whenSomeoneViewsYourProfileVIP => 'Biri profilinizi görüntülediğinde (VIP)';

  @override
  String get marketing => 'Pazarlama';

  @override
  String get updatesAndPromotionalMessages => 'Güncellemeler ve promosyon mesajları';

  @override
  String get notificationPreferences => 'Bildirim Tercihleri';

  @override
  String get sound => 'Ses';

  @override
  String get playNotificationSounds => 'Bildirim seslerini çal';

  @override
  String get vibration => 'Titreşim';

  @override
  String get vibrateOnNotifications => 'Bildirimlerde titret';

  @override
  String get showPreview => 'Önizleme Göster';

  @override
  String get showMessagePreviewInNotifications => 'Bildirimlerde mesaj önizlemesi göster';

  @override
  String get mutedConversations => 'Sessize Alınan Sohbetler';

  @override
  String get conversation => 'Sohbet';

  @override
  String get unmute => 'Sesi Aç';

  @override
  String get systemNotificationSettings => 'Sistem Bildirim Ayarları';

  @override
  String get manageNotificationsInSystemSettings => 'Sistem ayarlarında bildirimleri yönet';

  @override
  String get errorLoadingSettings => 'Ayarlar yüklenirken hata';

  @override
  String get unblockUser => 'Kullanıcının Engelini Kaldır';

  @override
  String get unblock => 'Engeli Kaldır';

  @override
  String get goBack => 'Geri';

  @override
  String get messageSendTimeout => 'Mesaj gönderme zaman aşımı. Lütfen bağlantınızı kontrol edin.';

  @override
  String get failedToSendMessage => 'Mesaj gönderilemedi';

  @override
  String get dailyMessageLimitExceeded => 'Günlük mesaj limiti aşıldı. Sınırsız mesaj için VIP\'e yükseltin.';

  @override
  String get cannotSendMessageUserMayBeBlocked => 'Mesaj gönderilemiyor. Kullanıcı engellenmiş olabilir.';

  @override
  String get sessionExpired => 'Oturum süresi doldu. Lütfen tekrar giriş yapın.';

  @override
  String get sendThisSticker => 'Bu çıkartmayı gönder?';

  @override
  String get chooseHowYouWantToDeleteThisMessage => 'Bu mesajı nasıl silmek istediğinizi seçin:';

  @override
  String get deleteForEveryone => 'Herkes için sil';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => 'Mesajı hem sizin hem de alıcının için siler';

  @override
  String get deleteForMe => 'Benim için sil';

  @override
  String get removesTheMessageOnlyFromYourChat => 'Mesajı yalnızca sizin sohbetinizden siler';

  @override
  String get copy => 'Kopyala';

  @override
  String get reply => 'Yanıtla';

  @override
  String get forward => 'İlet';

  @override
  String get moreOptions => 'Daha Fazla Seçenek';

  @override
  String get noUsersAvailableToForwardTo => 'İletilecek kullanıcı yok';

  @override
  String get searchMoments => 'Anları ara...';

  @override
  String searchInChatWith(String name) {
    return '$name ile sohbette ara';
  }

  @override
  String get typeAMessage => 'Mesaj yazın...';

  @override
  String get enterYourMessage => 'Mesajınızı girin';

  @override
  String get detectYourLocation => 'Konumunuzu algıla';

  @override
  String get tapToUpdateLocation => 'Konumu güncellemek için dokunun';

  @override
  String get helpOthersFindYouNearby => 'Başkalarının sizi yakınlarda bulmasına yardımcı olun';

  @override
  String get selectYourNativeLanguage => 'Ana dilinizi seçin';

  @override
  String get whichLanguageDoYouWantToLearn => 'Hangi dili öğrenmek istiyorsunuz?';

  @override
  String get selectYourGender => 'Cinsiyetinizi seçin';

  @override
  String get addACaption => 'Açıklama ekle...';

  @override
  String get typeSomething => 'Bir şeyler yazın...';

  @override
  String get gallery => 'Galeri';

  @override
  String get video => 'Video';

  @override
  String get text => 'Metin';

  @override
  String get provideMoreInformation => 'Daha fazla bilgi verin...';

  @override
  String get searchByNameLanguageOrInterests => 'İsim, dil veya ilgi alanlarına göre ara...';

  @override
  String get addTagAndPressEnter => 'Etiket ekle ve Enter\'a bas';

  @override
  String replyTo(String name) {
    return '$name adlı kişiye yanıt ver...';
  }

  @override
  String get highlightName => 'Öne çıkan adı';

  @override
  String get searchCloseFriends => 'Yakın arkadaşları ara...';

  @override
  String get askAQuestion => 'Soru sor...';

  @override
  String option(String number) {
    return 'Seçenek $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return 'Bu $type neden bildiriyorsunuz?';
  }

  @override
  String get additionalDetailsOptional => 'Ek detaylar (isteğe bağlı)';

  @override
  String get warningThisActionIsPermanent => 'Uyarı: Bu işlem kalıcıdır!';

  @override
  String get deletingYourAccountWillPermanentlyRemove => 'Hesabınızı silmek şunları kalıcı olarak kaldırır:\n\n• Profiliniz ve tüm kişisel verileriniz\n• Tüm mesajlarınız ve sohbetleriniz\n• Tüm anlarınız ve hikayeleriniz\n• VIP aboneliğiniz (iade yok)\n• Tüm bağlantılarınız ve takipçileriniz\n\nBu işlem geri alınamaz.';

  @override
  String get clearAllNotifications => 'Tüm bildirimler silinsin mi?';

  @override
  String get clearAll => 'Tümünü Temizle';

  @override
  String get notificationDebug => 'Bildirim Hata Ayıklama';

  @override
  String get markAllRead => 'Tümünü okundu işaretle';

  @override
  String get clearAll2 => 'Tümünü temizle';

  @override
  String get emailAddress => 'E-posta adresi';

  @override
  String get username => 'Kullanıcı adı';

  @override
  String get alreadyHaveAnAccount => 'Zaten hesabınız var mı?';

  @override
  String get login2 => 'Giriş Yap';

  @override
  String get selectYourNativeLanguage2 => 'Ana dilinizi seçin';

  @override
  String get whichLanguageDoYouWantToLearn2 => 'Hangi dili öğrenmek istiyorsunuz?';

  @override
  String get selectYourGender2 => 'Cinsiyetinizi seçin';

  @override
  String get dateFormat => 'GG.AA.YYYY';

  @override
  String get detectYourLocation2 => 'Konumunuzu algıla';

  @override
  String get tapToUpdateLocation2 => 'Konumu güncellemek için dokunun';

  @override
  String get helpOthersFindYouNearby2 => 'Başkalarının sizi yakınlarda bulmasına yardımcı olun';

  @override
  String get couldNotOpenLink => 'Bağlantı açılamadı';

  @override
  String get legalPrivacy2 => 'Yasal ve Gizlilik';

  @override
  String get termsOfUseEULA => 'Kullanım Şartları (EULA)';

  @override
  String get viewOurTermsAndConditions => 'Şartlar ve koşullarımızı görüntüleyin';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get howWeHandleYourData => 'Verilerinizi nasıl işliyoruz';

  @override
  String get emailNotifications => 'E-posta Bildirimleri';

  @override
  String get receiveEmailNotificationsFromBananatalk => 'Bananatalk\'tan e-posta bildirimleri al';

  @override
  String get weeklySummary => 'Haftalık Özet';

  @override
  String get activityRecapEverySunday => 'Her Pazar etkinlik özeti';

  @override
  String get newMessages => 'Yeni Mesajlar';

  @override
  String get whenYoureAwayFor24PlusHours => '24+ saat uzakta olduğunuzda';

  @override
  String get newFollowers => 'Yeni Takipçiler';

  @override
  String get whenSomeoneFollowsYou2 => 'Biri sizi takip ettiğinde';

  @override
  String get securityAlerts => 'Güvenlik Uyarıları';

  @override
  String get passwordLoginAlerts => 'Şifre ve giriş uyarıları';

  @override
  String get unblockUser2 => 'Kullanıcının Engelini Kaldır';

  @override
  String get blockedUsers2 => 'Engellenen Kullanıcılar';

  @override
  String get finalWarning => 'Son Uyarı';

  @override
  String get deleteForever => 'Kalıcı Olarak Sil';

  @override
  String get deleteAccount2 => 'Hesabı Sil';

  @override
  String get enterYourPassword => 'Şifrenizi girin';

  @override
  String get yourPassword => 'Şifreniz';

  @override
  String get typeDELETEToConfirm => 'Onaylamak için SİL yazın';

  @override
  String get typeDELETEInCapitalLetters => 'Büyük harflerle SİL yazın';

  @override
  String sent(String emoji) {
    return '$emoji gönderildi!';
  }

  @override
  String get replySent => 'Yanıt gönderildi!';

  @override
  String get deleteStory => 'Hikaye silinsin mi?';

  @override
  String get thisStoryWillBeRemovedPermanently => 'Bu hikaye kalıcı olarak kaldırılacak.';

  @override
  String get noStories => 'Hikaye yok';

  @override
  String views(String count) {
    return '$count görüntüleme';
  }

  @override
  String get reportStory => 'Hikayeyi Bildir';

  @override
  String get reply2 => 'Yanıtla...';

  @override
  String get failedToPickImage => 'Resim seçilemedi';

  @override
  String get failedToTakePhoto => 'Fotoğraf çekilemedi';

  @override
  String get failedToPickVideo => 'Video seçilemedi';

  @override
  String get pleaseEnterSomeText => 'Lütfen metin girin';

  @override
  String get pleaseSelectMedia => 'Lütfen medya seçin';

  @override
  String get storyPosted => 'Hikaye paylaşıldı!';

  @override
  String get textOnlyStoriesRequireAnImage => 'Yalnızca metin hikayeleri bir resim gerektirir';

  @override
  String get createStory => 'Hikaye Oluştur';

  @override
  String get change => 'Değiştir';

  @override
  String get userIdNotFound => 'Kullanıcı kimliği bulunamadı. Lütfen tekrar giriş yapın.';

  @override
  String get pleaseSelectAPaymentMethod => 'Lütfen bir ödeme yöntemi seçin';

  @override
  String get startExploring => 'Keşfetmeye Başla';

  @override
  String get close => 'Kapat';

  @override
  String get payment => 'Ödeme';

  @override
  String get upgradeToVIP => 'VIP\'e Yükselt';

  @override
  String get errorLoadingProducts => 'Ürünler yüklenirken hata';

  @override
  String get cancelVIPSubscription => 'VIP Aboneliğini İptal Et';

  @override
  String get keepVIP => 'VIP\'i Koru';

  @override
  String get cancelSubscription => 'Aboneliği İptal Et';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'VIP aboneliği başarıyla iptal edildi';

  @override
  String get vipStatus => 'VIP Durumu';

  @override
  String get noActiveVIPSubscription => 'Aktif VIP aboneliği yok';

  @override
  String get subscriptionExpired => 'Abonelik Süresi Doldu';

  @override
  String get vipExpiredMessage => 'VIP aboneliğinizin süresi doldu. Sınırsız özelliklerden yararlanmaya devam etmek için şimdi yenileyin!';

  @override
  String get expiredOn => 'Sona erme tarihi';

  @override
  String get renewVIP => 'VIP\'i Yenile';

  @override
  String get whatYoureMissing => 'Kaçırdıklarınız';

  @override
  String get manageInAppStore => 'App Store\'da Yönet';

  @override
  String get becomeVIP => 'VIP Ol';

  @override
  String get unlimitedMessages => 'Sınırsız Mesaj';

  @override
  String get unlimitedProfileViews => 'Sınırsız Profil Görüntüleme';

  @override
  String get prioritySupport => 'Öncelikli Destek';

  @override
  String get advancedSearch => 'Gelişmiş Arama';

  @override
  String get profileBoost => 'Profil Öne Çıkarma';

  @override
  String get adFreeExperience => 'Reklamsız Deneyim';

  @override
  String get upgradeYourAccount => 'Hesabınızı Yükseltin';

  @override
  String get moreMessages => 'Daha Fazla Mesaj';

  @override
  String get moreProfileViews => 'Daha Fazla Profil Görüntüleme';

  @override
  String get connectWithFriends => 'Arkadaşlarla Bağlan';

  @override
  String get reviewStarted => 'İnceleme başladı';

  @override
  String get reportResolved => 'Bildirim çözüldü';

  @override
  String get reportDismissed => 'Bildirim reddedildi';

  @override
  String get selectAction => 'İşlem Seç';

  @override
  String get noViolation => 'İhlal Yok';

  @override
  String get contentRemoved => 'İçerik Kaldırıldı';

  @override
  String get userWarned => 'Kullanıcı Uyarıldı';

  @override
  String get userSuspended => 'Kullanıcı Askıya Alındı';

  @override
  String get userBanned => 'Kullanıcı Yasaklandı';

  @override
  String get addNotesOptional => 'Not Ekle (İsteğe Bağlı)';

  @override
  String get enterModeratorNotes => 'Moderatör notlarını girin...';

  @override
  String get skip => 'Atla';

  @override
  String get startReview => 'İncelemeyi Başlat';

  @override
  String get resolve => 'Çöz';

  @override
  String get dismiss => 'Reddet';

  @override
  String get filterReports => 'Bildirimleri Filtrele';

  @override
  String get all => 'Tümü';

  @override
  String get clear => 'Temizle';

  @override
  String get apply => 'Uygula';

  @override
  String get myReports2 => 'Bildirilerim';

  @override
  String get blockUser => 'Kullanıcıyı Engelle';

  @override
  String get block => 'Engelle';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => 'Bu kullanıcıyı da engellemek ister misiniz?';

  @override
  String get noThanks => 'Hayır, teşekkürler';

  @override
  String get yesBlockThem => 'Evet, engelle';

  @override
  String get reportUser2 => 'Kullanıcıyı Bildir';

  @override
  String get submitReport => 'Bildirimi Gönder';

  @override
  String get addAQuestionAndAtLeast2Options => 'Bir soru ve en az 2 seçenek ekleyin';

  @override
  String get addOption => 'Seçenek ekle';

  @override
  String get anonymousVoting => 'Anonim oylama';

  @override
  String get create => 'Oluştur';

  @override
  String get typeYourAnswer => 'Yanıtınızı yazın...';

  @override
  String get send2 => 'Gönder';

  @override
  String get yourPrompt => 'Sorunuz...';

  @override
  String get add2 => 'Ekle';

  @override
  String get contentNotAvailable => 'İçerik mevcut değil';

  @override
  String get profileNotAvailable => 'Profil mevcut değil';

  @override
  String get noMomentsToShow => 'Gösterilecek an yok';

  @override
  String get storiesNotAvailable => 'Hikayeler mevcut değil';

  @override
  String get cantMessageThisUser => 'Bu kullanıcıya mesaj gönderilemiyor';

  @override
  String get pleaseSelectAReason => 'Lütfen bir neden seçin';

  @override
  String get reportSubmitted => 'Bildirim gönderildi. Topluluğumuzu güvende tutmaya yardımcı olduğunuz için teşekkürler.';

  @override
  String get youHaveAlreadyReportedThisMoment => 'Bu anı zaten bildirdiniz';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => 'Bunu neden bildirdiğiniz hakkında daha fazla bilgi verin';

  @override
  String get errorSharing => 'Paylaşım hatası';

  @override
  String get deviceInfo => 'Cihaz Bilgisi';

  @override
  String get recommended => 'Önerilen';

  @override
  String get anyLanguage => 'Herhangi Bir Dil';

  @override
  String get noLanguagesFound => 'Dil bulunamadı';

  @override
  String get selectALanguage => 'Bir dil seçin';

  @override
  String get languagesAreStillLoading => 'Diller hâlâ yükleniyor...';

  @override
  String get selectNativeLanguage => 'Ana dili seçin';

  @override
  String get subscriptionDetails => 'Abonelik Detayları';

  @override
  String get activeFeatures => 'Aktif Özellikler';

  @override
  String get legalInformation => 'Yasal Bilgiler';

  @override
  String get termsOfUse => 'Kullanım Şartları';

  @override
  String get manageSubscription => 'Aboneliği Yönet';

  @override
  String get manageSubscriptionInSettings => 'Aboneliğinizi iptal etmek için cihazınızda Ayarlar > [Adınız] > Abonelikler\'e gidin.';

  @override
  String get contactSupportToCancel => 'Aboneliğinizi iptal etmek için lütfen destek ekibimizle iletişime geçin.';

  @override
  String get status => 'Durum';

  @override
  String get active => 'Aktif';

  @override
  String get plan => 'Plan';

  @override
  String get startDate => 'Başlangıç Tarihi';

  @override
  String get endDate => 'Bitiş Tarihi';

  @override
  String get nextBillingDate => 'Sonraki Fatura Tarihi';

  @override
  String get autoRenew => 'Otomatik Yenileme';

  @override
  String get pleaseLogInToContinue => 'Devam etmek için lütfen giriş yapın';

  @override
  String get purchaseCanceledOrFailed => 'Satın alma iptal edildi veya başarısız oldu. Lütfen tekrar deneyin.';

  @override
  String get maximumTagsAllowed => 'Maksimum 5 etiket izni var';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => 'Video eklemek için lütfen önce resimleri kaldırın';

  @override
  String get unsupportedFormat => 'Desteklenmeyen format';

  @override
  String get errorProcessingVideo => 'Video işlenirken hata';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'Video kaydetmek için lütfen önce resimleri kaldırın';

  @override
  String get locationAdded => 'Konum eklendi';

  @override
  String get failedToGetLocation => 'Konum alınamadı';

  @override
  String get notNow => 'Şimdi Değil';

  @override
  String get videoUploadFailed => 'Video Yükleme Başarısız';

  @override
  String get skipVideo => 'Videoyu Atla';

  @override
  String get retryUpload => 'Yüklemeyi Tekrar Dene';

  @override
  String get momentCreatedSuccessfully => 'An başarıyla oluşturuldu';

  @override
  String get uploadingMomentInBackground => 'An arka planda yükleniyor...';

  @override
  String get failedToQueueUpload => 'Yükleme sıraya alınamadı';

  @override
  String get viewProfile => 'Profili Görüntüle';

  @override
  String get mediaLinksAndDocs => 'Medya, bağlantılar ve belgeler';

  @override
  String get wallpaper => 'Duvar Kağıdı';

  @override
  String get userIdNotAvailable => 'Kullanıcı kimliği mevcut değil';

  @override
  String get cannotBlockYourself => 'Kendinizi engelleyemezsiniz';

  @override
  String get chatWallpaper => 'Sohbet Duvar Kağıdı';

  @override
  String get wallpaperSavedLocally => 'Duvar kağıdı yerel olarak kaydedildi';

  @override
  String get messageCopied => 'Mesaj kopyalandı';

  @override
  String get forwardFeatureComingSoon => 'İletme özelliği yakında';

  @override
  String get momentUnsaved => 'Kaydedilenlerden kaldırıldı';

  @override
  String get documentPickerComingSoon => 'Belge seçici yakında';

  @override
  String get contactSharingComingSoon => 'Kişi paylaşımı yakında';

  @override
  String get featureComingSoon => 'Özellik yakında';

  @override
  String get answerSent => 'Yanıt gönderildi!';

  @override
  String get noImagesAvailable => 'Resim mevcut değil';

  @override
  String get mentionPickerComingSoon => 'Bahsetme seçici yakında';

  @override
  String get musicPickerComingSoon => 'Müzik seçici yakında';

  @override
  String get repostFeatureComingSoon => 'Yeniden paylaşma özelliği yakında';

  @override
  String get addFriendsFromYourProfile => 'Profilinizden arkadaş ekleyin';

  @override
  String get quickReplyAdded => 'Hızlı yanıt eklendi';

  @override
  String get quickReplyDeleted => 'Hızlı yanıt silindi';

  @override
  String get linkCopied => 'Bağlantı kopyalandı!';

  @override
  String get maximumOptionsAllowed => 'Maksimum 10 seçenek izni var';

  @override
  String get minimumOptionsRequired => 'Minimum 2 seçenek gerekli';

  @override
  String get pleaseEnterAQuestion => 'Lütfen bir soru girin';

  @override
  String get pleaseAddAtLeast2Options => 'Lütfen en az 2 seçenek ekleyin';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => 'Lütfen test için doğru cevabı seçin';

  @override
  String get correctionSent => 'Düzeltme gönderildi!';

  @override
  String get sort => 'Sırala';

  @override
  String get savedMoments => 'Kaydedilen Anlar';

  @override
  String get unsave => 'Kaydetme';

  @override
  String get playingAudio => 'Ses oynatılıyor...';

  @override
  String get failedToGenerateQuiz => 'Test oluşturulamadı';

  @override
  String get failedToAddComment => 'Yorum eklenemedi';

  @override
  String get hello => 'Merhaba!';

  @override
  String get howAreYou => 'Nasılsın?';

  @override
  String get cannotOpen => 'Açılamıyor';

  @override
  String get errorOpeningLink => 'Bağlantı açılırken hata';

  @override
  String get saved => 'Kaydedildi';

  @override
  String get follow => 'Takip Et';

  @override
  String get unfollow => 'Takibi Bırak';

  @override
  String get mute => 'Sessiz';

  @override
  String get online => 'Çevrimiçi';

  @override
  String get offline => 'Çevrimdışı';

  @override
  String get lastSeen => 'Son görülme';

  @override
  String get justNow => 'şimdi';

  @override
  String minutesAgo(String count) {
    return '$count dakika önce';
  }

  @override
  String hoursAgo(String count) {
    return '$count saat önce';
  }

  @override
  String get yesterday => 'Dün';

  @override
  String get signInWithEmail => 'E-posta ile giriş yap';

  @override
  String get partners => 'Partnerler';

  @override
  String get nearby => 'Yakınlarda';

  @override
  String get topics => 'Konular';

  @override
  String get waves => 'El Sallama';

  @override
  String get voiceRooms => 'Sesli';

  @override
  String get filters => 'Filtreler';

  @override
  String get searchCommunity => 'İsim, dil veya ilgi alanlarına göre ara...';

  @override
  String get bio => 'Biyografi';

  @override
  String get noBioYet => 'Henüz biyografi yok.';

  @override
  String get languages => 'Diller';

  @override
  String get native => 'Ana Dil';

  @override
  String get interests => 'İlgi Alanları';

  @override
  String get noMomentsYet => 'Henüz an yok';

  @override
  String get unableToLoadMoments => 'Anlar yüklenemedi';

  @override
  String get map => 'Harita';

  @override
  String get mapUnavailable => 'Harita mevcut değil';

  @override
  String get location => 'Konum';

  @override
  String get unknownLocation => 'Bilinmeyen konum';

  @override
  String get noImagesAvailable2 => 'Resim mevcut değil';

  @override
  String get permissionsRequired => 'İzinler Gerekli';

  @override
  String get openSettings => 'Ayarları Aç';

  @override
  String get refresh => 'Yenile';

  @override
  String get videoCall => 'Görüntülü';

  @override
  String get voiceCall => 'Arama';

  @override
  String get message => 'Mesaj';

  @override
  String get pleaseLoginToFollow => 'Kullanıcıları takip etmek için lütfen giriş yapın';

  @override
  String get pleaseLoginToCall => 'Arama yapmak için lütfen giriş yapın';

  @override
  String get cannotCallYourself => 'Kendinizi arayamazsınız';

  @override
  String get failedToFollowUser => 'Kullanıcı takip edilemedi';

  @override
  String get failedToUnfollowUser => 'Takip bırakılamadı';

  @override
  String get areYouSureUnfollow => 'Bu kullanıcının takibini bırakmak istediğinizden emin misiniz?';

  @override
  String get areYouSureUnblock => 'Bu kullanıcının engelini kaldırmak istediğinizden emin misiniz?';

  @override
  String get youFollowed => 'Takip ettiniz';

  @override
  String get youUnfollowed => 'Takibi bıraktınız';

  @override
  String get alreadyFollowing => 'Zaten takip ediyorsunuz';

  @override
  String get soon => 'Yakında';

  @override
  String comingSoon(String feature) {
    return '$feature yakında geliyor!';
  }

  @override
  String get muteNotifications => 'Bildirimleri sessize al';

  @override
  String get unmuteNotifications => 'Bildirimlerin sesini aç';

  @override
  String get operationCompleted => 'İşlem tamamlandı';

  @override
  String get couldNotOpenMaps => 'Haritalar açılamadı';

  @override
  String hasntSharedMoments(Object name) {
    return '$name hiç an paylaşmadı';
  }

  @override
  String messageUser(String name) {
    return '$name adlı kişiye mesaj gönder';
  }

  @override
  String notFollowingUser(String name) {
    return '$name adlı kişiyi takip etmiyordunuz';
  }

  @override
  String youFollowedUser(String name) {
    return '$name adlı kişiyi takip ettiniz';
  }

  @override
  String youUnfollowedUser(String name) {
    return '$name adlı kişinin takibini bıraktınız';
  }

  @override
  String unfollowUser(String name) {
    return '$name adlı kişinin takibini bırak';
  }

  @override
  String get typing => 'yazıyor';

  @override
  String get connecting => 'Bağlanıyor...';

  @override
  String daysAgo(int count) {
    return '${count}g önce';
  }

  @override
  String get maxTagsAllowed => 'Maksimum 5 etiket izni var';

  @override
  String maxImagesAllowed(int count) {
    return 'Maksimum $count resim izni var';
  }

  @override
  String get pleaseRemoveImagesFirst => 'Video eklemek için lütfen önce resimleri kaldırın';

  @override
  String get exchange3MessagesBeforeCall => 'Aramadan önce en az 5 mesaj alışverişinde bulunun';

  @override
  String mediaWithUser(String name) {
    return '$name ile medya';
  }

  @override
  String get errorLoadingMedia => 'Medya yüklenirken hata';

  @override
  String get savedMomentsTitle => 'Kaydedilen Anlar';

  @override
  String get removeBookmark => 'Yer imi kaldırılsın mı?';

  @override
  String get thisWillRemoveBookmark => 'Bu, mesajı yer imlerinizden kaldıracak.';

  @override
  String get remove => 'Kaldır';

  @override
  String get bookmarkRemoved => 'Yer imi kaldırıldı';

  @override
  String get bookmarkedMessages => 'Yer İmli Mesajlar';

  @override
  String get wallpaperSaved => 'Duvar kağıdı yerel olarak kaydedildi';

  @override
  String get typeDeleteToConfirm => 'Type DELETE to confirm';

  @override
  String get storyArchive => 'Hikaye Arşivi';

  @override
  String get newHighlight => 'Yeni Öne Çıkan';

  @override
  String get addToHighlight => 'Öne çıkanlara ekle';

  @override
  String get repost => 'Yeniden Paylaş';

  @override
  String get repostFeatureSoon => 'Yeniden paylaşma özelliği yakında';

  @override
  String get closeFriends => 'Yakın Arkadaşlar';

  @override
  String get addFriends => 'Arkadaş Ekle';

  @override
  String get highlights => 'Öne Çıkanlar';

  @override
  String get createHighlight => 'Öne Çıkan Oluştur';

  @override
  String get deleteHighlight => 'Sil';

  @override
  String get editHighlight => 'Düzenle';

  @override
  String get addMoreToStory => 'Hikayeye daha fazla ekle';

  @override
  String get noViewersYet => 'Henüz izleyici yok';

  @override
  String get noReactionsYet => 'Henüz tepki yok';

  @override
  String get leaveRoom => 'Odadan Ayrıl';

  @override
  String get areYouSureLeaveRoom => 'Bu sesli odadan ayrılmak istediğinizden emin misiniz?';

  @override
  String get stay => 'Kal';

  @override
  String get leave => 'Ayrıl';

  @override
  String get enableGPS => 'GPS\'i Etkinleştir';

  @override
  String wavedToUser(String name) {
    return '$name adlı kişiye el salladınız!';
  }

  @override
  String get areYouSureFollow => 'Takip etmek istediğinizden emin misiniz';

  @override
  String get failedToLoadProfile => 'Profil yüklenemedi';

  @override
  String get noFollowersYet => 'Henüz takipçi yok';

  @override
  String get noFollowingYet => 'Henüz kimseyi takip etmiyor';

  @override
  String get searchUsers => 'Kullanıcı ara...';

  @override
  String get noResultsFound => 'Sonuç bulunamadı';

  @override
  String get loadingFailed => 'Yükleme başarısız';

  @override
  String get copyLink => 'Bağlantıyı Kopyala';

  @override
  String get shareStory => 'Hikayeyi Paylaş';

  @override
  String get thisWillDeleteStory => 'Bu hikaye kalıcı olarak silinecek.';

  @override
  String get storyDeleted => 'Hikaye silindi';

  @override
  String get addCaption => 'Açıklama ekle...';

  @override
  String get yourStory => 'Hikayeniz';

  @override
  String get sendMessage => 'Mesaj Gönder';

  @override
  String get replyToStory => 'Hikayeye yanıt ver...';

  @override
  String get viewAllReplies => 'Tüm yanıtları görüntüle';

  @override
  String get preparingVideo => 'Video hazırlanıyor...';

  @override
  String videoOptimized(String size, String savings) {
    return 'Video optimize edildi: ${size}MB (%$savings tasarruf)';
  }

  @override
  String get failedToProcessVideo => 'Video işlenemedi';

  @override
  String get optimizingForBestExperience => 'En iyi hikaye deneyimi için optimize ediliyor';

  @override
  String get pleaseSelectImageOrVideo => 'Hikayeniz için lütfen bir resim veya video seçin';

  @override
  String get storyCreatedSuccessfully => 'Hikaye başarıyla oluşturuldu!';

  @override
  String get uploadingStoryInBackground => 'Hikaye arka planda yükleniyor...';

  @override
  String get storyCreationFailed => 'Hikaye Oluşturma Başarısız';

  @override
  String get pleaseCheckConnection => 'Lütfen bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get uploadFailed => 'Yükleme Başarısız';

  @override
  String get tryShorterVideo => 'Daha kısa bir video deneyin veya daha sonra tekrar deneyin.';

  @override
  String get shareMomentsThatDisappear => '24 saat içinde kaybolan anlar paylaşın';

  @override
  String get photo => 'Fotoğraf';

  @override
  String get record => 'Kaydet';

  @override
  String get addSticker => 'Çıkartma ekle';

  @override
  String get poll => 'Anket';

  @override
  String get question => 'Soru';

  @override
  String get mention => 'Bahset';

  @override
  String get music => 'Müzik';

  @override
  String get hashtag => 'Hashtag';

  @override
  String get whoCanSeeThis => 'Bunu kim görebilir?';

  @override
  String get everyone => 'Herkes';

  @override
  String get anyoneCanSeeStory => 'Herkes bu hikayeyi görebilir';

  @override
  String get friendsOnly => 'Sadece Arkadaşlar';

  @override
  String get onlyFollowersCanSee => 'Sadece takipçileriniz görebilir';

  @override
  String get onlyCloseFriendsCanSee => 'Sadece yakın arkadaşlarınız görebilir';

  @override
  String get backgroundColor => 'Arka Plan Rengi';

  @override
  String get fontStyle => 'Yazı Tipi Stili';

  @override
  String get normal => 'Normal';

  @override
  String get bold => 'Kalın';

  @override
  String get italic => 'İtalik';

  @override
  String get handwriting => 'El Yazısı';

  @override
  String get addLocation => 'Konum Ekle';

  @override
  String get enterLocationName => 'Konum adını girin';

  @override
  String get addLink => 'Bağlantı Ekle';

  @override
  String get buttonText => 'Düğme metni';

  @override
  String get learnMore => 'Daha Fazla Bilgi';

  @override
  String get addHashtags => 'Hashtag Ekle';

  @override
  String get addHashtag => 'Hashtag ekle';

  @override
  String get sendAsMessage => 'Mesaj Olarak Gönder';

  @override
  String get shareExternally => 'Dışarıda Paylaş';

  @override
  String get checkOutStory => 'Bananatalk\'taki bu hikayeye göz at!';

  @override
  String viewsTab(String count) {
    return 'Görüntüleme ($count)';
  }

  @override
  String reactionsTab(String count) {
    return 'Tepkiler ($count)';
  }

  @override
  String get processingVideo => 'Video işleniyor...';

  @override
  String get link => 'Bağlantı';

  @override
  String unmuteUser(String name) {
    return '$name sesini aç?';
  }

  @override
  String get willReceiveNotifications => 'Yeni mesajlar için bildirim alacaksınız.';

  @override
  String muteNotificationsFor(String name) {
    return '$name için bildirimleri sessize al';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return '$name için bildirimlerin sesi açıldı';
  }

  @override
  String notificationsMutedFor(String name) {
    return '$name için bildirimler sessize alındı';
  }

  @override
  String get failedToUpdateMuteSettings => 'Sessiz ayarları güncellenemedi';

  @override
  String get oneHour => '1 saat';

  @override
  String get eightHours => '8 saat';

  @override
  String get oneWeek => '1 hafta';

  @override
  String get always => 'Her zaman';

  @override
  String get failedToLoadBookmarks => 'Yer imleri yüklenemedi';

  @override
  String get noBookmarkedMessages => 'Yer imli mesaj yok';

  @override
  String get longPressToBookmark => 'Yer imi eklemek için bir mesaja uzun basın';

  @override
  String get thisWillRemoveFromBookmarks => 'Bu, mesajı yer imlerinizden kaldıracak.';

  @override
  String navigateToMessage(String name) {
    return '$name ile sohbetteki mesaja git';
  }

  @override
  String bookmarkedOn(String date) {
    return '$date tarihinde yer imi eklendi';
  }

  @override
  String get voiceMessage => 'Sesli mesaj';

  @override
  String get document => 'Belge';

  @override
  String get attachment => 'Ek';

  @override
  String get sendMeAMessage => 'Bana mesaj gönder';

  @override
  String get shareWithFriends => 'Arkadaşlarla paylaş';

  @override
  String get shareAnywhere => 'Her yerde paylaş';

  @override
  String get emailPreferences => 'E-posta Tercihleri';

  @override
  String get receiveEmailNotifications => 'Bananatalk\'tan e-posta bildirimleri al';

  @override
  String get whenAwayFor24Hours => '24+ saat uzakta olduğunuzda';

  @override
  String get passwordAndLoginAlerts => 'Şifre ve giriş uyarıları';

  @override
  String get failedToLoadPreferences => 'Tercihler yüklenemedi';

  @override
  String get failedToUpdateSetting => 'Ayar güncellenemedi';

  @override
  String get securityAlertsRecommended => 'Önemli hesap etkinlikleri hakkında bilgi sahibi olmak için Güvenlik Uyarılarını etkin tutmanızı öneririz.';

  @override
  String chatWallpaperFor(String name) {
    return '$name için sohbet duvar kağıdı';
  }

  @override
  String get solidColors => 'Düz Renkler';

  @override
  String get gradients => 'Gradyanlar';

  @override
  String get customImage => 'Özel Resim';

  @override
  String get chooseFromGallery => 'Galeriden seç';

  @override
  String get preview => 'Önizleme';

  @override
  String get wallpaperUpdated => 'Duvar kağıdı güncellendi';

  @override
  String get category => 'Kategori';

  @override
  String get mood => 'Ruh Hali';

  @override
  String get sortBy => 'Sırala';

  @override
  String get timePeriod => 'Zaman Dilimi';

  @override
  String get searchLanguages => 'Dil ara...';

  @override
  String get selected => 'Seçili';

  @override
  String get categories => 'Kategoriler';

  @override
  String get moods => 'Ruh Halleri';

  @override
  String get applyFilters => 'Filtreleri Uygula';

  @override
  String applyNFilters(int count) {
    return '$count Filtre Uygula';
  }

  @override
  String get videoMustBeUnder1GB => 'Video 1GB\'den küçük olmalıdır.';

  @override
  String get failedToRecordVideo => 'Video kaydedilemedi';

  @override
  String get errorSendingVideo => 'Video gönderilirken hata';

  @override
  String get errorSendingVoiceMessage => 'Sesli mesaj gönderilirken hata';

  @override
  String get errorSendingMedia => 'Medya gönderilirken hata';

  @override
  String get cameraPermissionRequired => 'Video kaydetmek için kamera ve mikrofon izinleri gereklidir.';

  @override
  String get locationPermissionRequired => 'Konumunuzu paylaşmak için konum izni gereklidir.';

  @override
  String get noInternetConnection => 'İnternet bağlantısı yok';

  @override
  String get tryAgainLater => 'Lütfen daha sonra tekrar deneyin';

  @override
  String get messageSent => 'Mesaj gönderildi';

  @override
  String get messageDeleted => 'Mesaj silindi';

  @override
  String get messageEdited => 'Mesaj düzenlendi';

  @override
  String get edited => '(düzenlendi)';

  @override
  String get now => 'şimdi';

  @override
  String weeksAgo(int count) {
    return '${count}h önce';
  }

  @override
  String viewRepliesCount(int count) {
    return '── $count yanıtı görüntüle';
  }

  @override
  String get hideReplies => '── Yanıtları gizle';

  @override
  String get saveMoment => 'Anı Kaydet';

  @override
  String get removeFromSaved => 'Kaydedilenlerden Kaldır';

  @override
  String get momentSaved => 'Kaydedildi';

  @override
  String get failedToSave => 'Kaydetme başarısız';

  @override
  String get checkOutMoment => 'Bananatalk\'ta bu anıya göz at!';

  @override
  String get failedToLoadMoments => 'Anılar yüklenemedi';

  @override
  String get noMomentsMatchFilters => 'Filtrelerinizle eşleşen anı yok';

  @override
  String get beFirstToShareMoment => 'Bir anı paylaşan ilk kişi olun!';

  @override
  String get tryDifferentSearch => 'Farklı bir arama terimi deneyin';

  @override
  String get tryAdjustingFilters => 'Filtrelerinizi ayarlamayı deneyin';

  @override
  String get noSavedMoments => 'Kaydedilmiş anı yok';

  @override
  String get tapBookmarkToSave => 'Bir anıyı kaydetmek için yer imi simgesine dokunun';

  @override
  String get failedToLoadVideo => 'Video yüklenemedi';

  @override
  String get titleRequired => 'Başlık gerekli';

  @override
  String titleTooLong(int max) {
    return 'Başlık $max karakter veya daha az olmalıdır';
  }

  @override
  String get descriptionRequired => 'Açıklama gerekli';

  @override
  String descriptionTooLong(int max) {
    return 'Açıklama $max karakter veya daha az olmalıdır';
  }

  @override
  String get scheduledDateMustBeFuture => 'Planlanan tarih gelecekte olmalıdır';

  @override
  String get recent => 'Son';

  @override
  String get popular => 'Popüler';

  @override
  String get trending => 'Trend';

  @override
  String get mostRecent => 'En son';

  @override
  String get mostPopular => 'En popüler';

  @override
  String get allTime => 'Tüm Zamanlar';

  @override
  String get today => 'Bugün';

  @override
  String get thisWeek => 'Bu Hafta';

  @override
  String get thisMonth => 'Bu Ay';

  @override
  String replyingTo(String userName) {
    return '$userName adlı kişiye yanıt';
  }

  @override
  String get listView => 'Liste görünümü';

  @override
  String get quickMatch => 'Hızlı eşleşme';

  @override
  String get onlineNow => 'Şimdi çevrimiçi';

  @override
  String speaksLanguage(String language) {
    return '$language konuşuyor';
  }

  @override
  String learningLanguage(String language) {
    return '$language öğreniyor';
  }

  @override
  String get noPartnersFound => 'Partner bulunamadı';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return 'Ana dili $learning olan veya $native öğrenmek isteyen kullanıcı bulunamadı.';
  }

  @override
  String get removeAllFilters => 'Tüm filtreleri kaldır';

  @override
  String get browseAllUsers => 'Tüm kullanıcılara göz at';

  @override
  String get allCaughtUp => 'Hepsini gördünüz!';

  @override
  String get loadingMore => 'Daha fazla yükleniyor...';

  @override
  String get findingMorePartners => 'Daha fazla partner aranıyor...';

  @override
  String get seenAllPartners => 'Tüm partnerleri gördünüz';

  @override
  String get startOver => 'Baştan başla';

  @override
  String get changeFilters => 'Filtreleri değiştir';

  @override
  String get findingPartners => 'Partner aranıyor...';

  @override
  String get setLocationReminder => 'Yakındaki partnerleri bulmak için konumunuzu ayarlayın';

  @override
  String get updateLocationReminder => 'Daha iyi sonuçlar için konumunuzu güncelleyin';

  @override
  String get male => 'Erkek';

  @override
  String get female => 'Kadın';

  @override
  String get other => 'Diğer';

  @override
  String get browseMen => 'Erkeklere göz at';

  @override
  String get browseWomen => 'Kadınlara göz at';

  @override
  String get noMaleUsersFound => 'Erkek kullanıcı bulunamadı';

  @override
  String get noFemaleUsersFound => 'Kadın kullanıcı bulunamadı';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => 'Yalnızca Yeni Kullanıcılar';

  @override
  String get showNewUsers => 'Yeni kullanıcıları göster';

  @override
  String get prioritizeNearby => 'Yakındakilere öncelik ver';

  @override
  String get showNearbyFirst => 'Önce yakındakileri göster';

  @override
  String get setLocationToEnable => 'Etkinleştirmek için konum ayarlayın';

  @override
  String get radius => 'Yarıçap';

  @override
  String get findingYourLocation => 'Konumunuz bulunuyor...';

  @override
  String get enableLocationForDistance => 'Mesafe için konumu etkinleştir';

  @override
  String get enableLocationDescription => 'Yakındaki dil partnerlerini bulmak için konum hizmetlerini etkinleştirin';

  @override
  String get enableGps => 'GPS\'i Etkinleştir';

  @override
  String get browseByCityCountry => 'Şehir/ülkeye göre ara';

  @override
  String get peopleNearby => 'Yakındaki kişiler';

  @override
  String get noNearbyUsersFound => 'Yakında kullanıcı bulunamadı';

  @override
  String get tryExpandingSearch => 'Aramayı genişletmeyi deneyin';

  @override
  String get exploreByCity => 'Şehre göre keşfet';

  @override
  String get exploreByCurrentCity => 'Mevcut şehre göre keşfet';

  @override
  String get interactiveWorldMap => 'İnteraktif dünya haritası';

  @override
  String get searchByCityName => 'Şehir adına göre ara';

  @override
  String get seeUserCountsPerCountry => 'Ülke başına kullanıcı sayısını gör';

  @override
  String get upgradeToVip => 'VIP\'e yükselt';

  @override
  String get searchByCity => 'Şehre göre ara';

  @override
  String usersWorldwide(String count) {
    return 'Dünya genelinde $count kullanıcı';
  }

  @override
  String get noUsersFound => 'Kullanıcı bulunamadı';

  @override
  String get tryDifferentCity => 'Farklı bir şehir deneyin';

  @override
  String usersCount(String count) {
    return '$count kullanıcı';
  }

  @override
  String get searchCountry => 'Ülke ara...';

  @override
  String get wave => 'El salla';

  @override
  String get newUser => 'Yeni kullanıcı';

  @override
  String get warningPermanent => 'Uyarı: Bu işlem kalıcıdır!';

  @override
  String get deleteAccountWarning => 'Hesabınızı silmek şunları kalıcı olarak kaldırır:\n\n• Profiliniz ve tüm kişisel verileriniz\n• Tüm mesajlarınız ve sohbetleriniz\n• Tüm anlarınız ve hikayeleriniz\n• VIP aboneliğiniz (iade yok)\n• Tüm bağlantılarınız ve takipçileriniz\n\nBu işlem geri alınamaz.';

  @override
  String get requiredForEmailOnly => 'Yalnızca e-posta hesapları için gerekli';

  @override
  String get pleaseEnterPassword => 'Lütfen şifrenizi girin';

  @override
  String get typeDELETE => 'DELETE yazın';

  @override
  String get mustTypeDELETE => 'Devam etmek için DELETE yazmalısınız';

  @override
  String get deletingAccount => 'Hesap siliniyor...';

  @override
  String get deleteMyAccountPermanently => 'Hesabımı kalıcı olarak sil';

  @override
  String get whatsYourNativeLanguage => 'Ana diliniz nedir?';

  @override
  String get helpsMatchWithLearners => 'Öğrencilerle eşleşmenize yardımcı olur';

  @override
  String get whatAreYouLearning => 'Ne öğreniyorsunuz?';

  @override
  String get connectWithNativeSpeakers => 'Ana dil konuşanlarıyla bağlanın';

  @override
  String get selectLearningLanguage => 'Öğrenilecek dili seçin';

  @override
  String get selectCurrentLevel => 'Mevcut seviyenizi seçin';

  @override
  String get beginner => 'Başlangıç';

  @override
  String get elementary => 'Temel';

  @override
  String get intermediate => 'Orta';

  @override
  String get upperIntermediate => 'Üst orta';

  @override
  String get advanced => 'İleri';

  @override
  String get proficient => 'Uzman';

  @override
  String get showingPartnersByDistance => 'Partnerler mesafeye göre gösteriliyor';

  @override
  String get enableLocationForResults => 'Daha iyi sonuçlar için konumu etkinleştirin';

  @override
  String get enable => 'Etkinleştir';

  @override
  String get locationNotSet => 'Konum ayarlanmadı';

  @override
  String get tellUsAboutYourself => 'Bize kendinizden bahsedin';

  @override
  String get justACoupleQuickThings => 'Sadece birkaç hızlı şey';

  @override
  String get gender => 'Cinsiyet';

  @override
  String get birthDate => 'Doğum tarihi';

  @override
  String get selectYourBirthDate => 'Doğum tarihinizi seçin';

  @override
  String get continueButton => 'Devam';

  @override
  String get pleaseSelectGender => 'Lütfen cinsiyetinizi seçin';

  @override
  String get pleaseSelectBirthDate => 'Lütfen doğum tarihinizi seçin';

  @override
  String get mustBe18 => 'En az 18 yaşında olmalısınız';

  @override
  String get invalidDate => 'Geçersiz tarih';

  @override
  String get almostDone => 'Neredeyse bitti!';

  @override
  String get addPhotoLocationForMatches => 'Daha iyi eşleşmeler için fotoğraf ve konum ekleyin';

  @override
  String get addProfilePhoto => 'Profil fotoğrafı ekle';

  @override
  String get optionalUpTo6Photos => 'İsteğe bağlı - 6 fotoğrafa kadar';

  @override
  String get requiredUpTo6Photos => 'Zorunlu — en fazla 6 fotoğraf';

  @override
  String get profilePhotoRequired => 'Lütfen en az bir profil fotoğrafı ekleyin';

  @override
  String get locationOptional => 'Devam etmek için lütfen konumunuzu ayarlayın';

  @override
  String get maximum6Photos => 'Maksimum 6 fotoğraf';

  @override
  String get tapToDetectLocation => 'Konumu algılamak için dokunun';

  @override
  String get optionalHelpsNearbyPartners => 'Gerekli — yakındaki ortakları bulmanıza yardımcı olur';

  @override
  String get startLearning => 'Öğrenmeye başla';

  @override
  String get photoLocationOptional => 'Fotoğraf ve konum isteğe bağlıdır';

  @override
  String get pleaseAcceptTerms => 'Lütfen kullanım şartlarını kabul edin';

  @override
  String get iAgreeToThe => 'Kabul ediyorum';

  @override
  String get termsOfService => 'Kullanım Şartları';

  @override
  String get tapToSelectLanguage => 'Dil seçmek için dokunun';

  @override
  String yourLevelIn(String language) {
    return '$language seviyeniz (isteğe bağlı)';
  }

  @override
  String get yourCurrentLevel => 'Mevcut seviyeniz';

  @override
  String get nativeCannotBeSameAsLearning => 'Ana dil öğrenilen dille aynı olamaz';

  @override
  String get learningCannotBeSameAsNative => 'Öğrenilen dil ana dille aynı olamaz';

  @override
  String stepOf(String current, String total) {
    return 'Adım $current / $total';
  }

  @override
  String get continueWithGoogle => 'Google ile devam et';

  @override
  String get registerLink => 'Kayıt ol';

  @override
  String get pleaseEnterBothEmailAndPassword => 'E-posta ve şifre girin';

  @override
  String get pleaseEnterValidEmail => 'Geçerli bir e-posta girin';

  @override
  String get loginSuccessful => 'Giriş başarılı!';

  @override
  String get stepOneOfTwo => 'Adım 1 / 2';

  @override
  String get createYourAccount => 'Hesabını oluştur';

  @override
  String get basicInfoToGetStarted => 'Başlamak için temel bilgiler';

  @override
  String get emailVerifiedLabel => 'E-posta (Doğrulanmış)';

  @override
  String get nameLabel => 'İsim';

  @override
  String get yourDisplayName => 'Görünen adın';

  @override
  String get atLeast8Characters => 'En az 8 karakter';

  @override
  String get confirmPasswordHint => 'Yeni şifreyi tekrar girin';

  @override
  String get nextButton => 'İleri';

  @override
  String get pleaseEnterYourName => 'İsmini gir';

  @override
  String get pleaseEnterAPassword => 'Şifre gir';

  @override
  String get passwordsDoNotMatch => 'Şifreler uyuşmuyor';

  @override
  String get otherGender => 'Diğer';

  @override
  String get continueWithGoogleAccount => 'Google hesabınla devam et\nsorunsuz bir deneyim için';

  @override
  String get signingYouIn => 'Giriş yapılıyor...';

  @override
  String get backToSignInMethods => 'Giriş yöntemlerine dön';

  @override
  String get securedByGoogle => 'Google tarafından korunuyor';

  @override
  String get dataProtectedEncryption => 'Verilerin standart şifreleme ile korunuyor';

  @override
  String get welcomeCompleteProfile => 'Hoş geldin! Profilini tamamla';

  @override
  String welcomeBackName(String name) {
    return 'Tekrar hoş geldin, $name!';
  }

  @override
  String get continueWithAppleId => 'Apple ID ile devam et\ngüvenli bir deneyim için';

  @override
  String get continueWithApple => 'Apple ile devam et';

  @override
  String get securedByApple => 'Apple tarafından korunuyor';

  @override
  String get privacyProtectedApple => 'Gizliliğin Apple Sign-In ile korunuyor';

  @override
  String get createAccount => 'Hesap oluştur';

  @override
  String get enterEmailToGetStarted => 'Başlamak için e-postanı gir';

  @override
  String get continueText => 'Devam et';

  @override
  String get pleaseEnterEmailAddress => 'E-posta adresini gir';

  @override
  String get verificationCodeSent => 'Doğrulama kodu gönderildi!';

  @override
  String get forgotPasswordTitle => 'Şifremi unuttum';

  @override
  String get resetPasswordTitle => 'Şifreyi sıfırla';

  @override
  String get enterEmailForResetCode => 'E-postanı gir, şifre sıfırlama kodu gönderelim';

  @override
  String get sendResetCode => 'Sıfırlama kodu gönder';

  @override
  String get resetCodeSent => 'Sıfırlama kodu gönderildi!';

  @override
  String get rememberYourPassword => 'Şifreni hatırlıyor musun?';

  @override
  String get verifyCode => 'Kodu doğrula';

  @override
  String get enterResetCode => 'Sıfırlama kodunu gir';

  @override
  String get weSentCodeTo => '6 haneli kodu gönderdik';

  @override
  String get pleaseEnterAll6Digits => '6 rakamın hepsini gir';

  @override
  String get codeVerifiedCreatePassword => 'Kod doğrulandı! Yeni şifre oluştur';

  @override
  String get verify => 'Doğrula';

  @override
  String get didntReceiveCode => 'Kodu almadın mı?';

  @override
  String get resend => 'Tekrar gönder';

  @override
  String resendWithTimer(String timer) {
    return 'Tekrar gönder (${timer}sn)';
  }

  @override
  String get resetCodeResent => 'Sıfırlama kodu tekrar gönderildi!';

  @override
  String get verifyEmail => 'E-postayı doğrula';

  @override
  String get verifyYourEmail => 'E-postanı doğrula';

  @override
  String get emailVerifiedSuccessfully => 'E-posta doğrulandı!';

  @override
  String get verificationCodeResent => 'Doğrulama kodu tekrar gönderildi!';

  @override
  String get createNewPassword => 'Yeni şifre oluştur';

  @override
  String get enterNewPasswordBelow => 'Yeni şifreni aşağıya gir';

  @override
  String get newPassword => 'Yeni şifre';

  @override
  String get confirmPasswordLabel => 'Şifreyi onayla';

  @override
  String get pleaseFillAllFields => 'Tüm alanları doldur';

  @override
  String get passwordResetSuccessful => 'Şifre sıfırlandı! Yeni şifrenle giriş yap';

  @override
  String get privacyTitle => 'Gizlilik';

  @override
  String get profileVisibility => 'Profil Görünürlüğü';

  @override
  String get showCountryRegion => 'Ülke/Bölge Göster';

  @override
  String get showCountryRegionDesc => 'Profilinizde ülkenizi gösterin';

  @override
  String get showCity => 'Şehir Göster';

  @override
  String get showCityDesc => 'Profilinizde şehrinizi gösterin';

  @override
  String get showAge => 'Yaş Göster';

  @override
  String get showAgeDesc => 'Profilinizde yaşınızı gösterin';

  @override
  String get showZodiacSign => 'Burç Göster';

  @override
  String get showZodiacSignDesc => 'Profilinizde burcunuzu gösterin';

  @override
  String get onlineStatusSection => 'Çevrimiçi Durumu';

  @override
  String get showOnlineStatus => 'Çevrimiçi Durumu Göster';

  @override
  String get showOnlineStatusDesc => 'Başkalarının çevrimiçi olduğunuzu görmesine izin verin';

  @override
  String get otherSettings => 'Diğer Ayarlar';

  @override
  String get showGiftingLevel => 'Hediye Seviyesini Göster';

  @override
  String get showGiftingLevelDesc => 'Hediye seviyesi rozetinizi gösterin';

  @override
  String get birthdayNotifications => 'Doğum Günü Bildirimleri';

  @override
  String get birthdayNotificationsDesc => 'Doğum gününüzde bildirim alın';

  @override
  String get personalizedAds => 'Kişiselleştirilmiş Reklamlar';

  @override
  String get personalizedAdsDesc => 'Kişiselleştirilmiş reklamlara izin verin';

  @override
  String get saveChanges => 'Değişiklikleri Kaydet';

  @override
  String get privacySettingsSaved => 'Gizlilik ayarları kaydedildi';

  @override
  String get locationSection => 'Konum';

  @override
  String get updateLocation => 'Konumu Güncelle';

  @override
  String get updateLocationDesc => 'Mevcut konumunuzu yenileyin';

  @override
  String get currentLocation => 'Mevcut konum';

  @override
  String get locationNotAvailable => 'Konum mevcut değil';

  @override
  String get locationUpdated => 'Konum başarıyla güncellendi';

  @override
  String get locationPermissionDenied => 'Konum izni reddedildi. Ayarlardan etkinleştirin.';

  @override
  String get locationServiceDisabled => 'Konum hizmetleri devre dışı. Lütfen etkinleştirin.';

  @override
  String get updatingLocation => 'Konum güncelleniyor...';

  @override
  String get locationCouldNotBeUpdated => 'Konum güncellenemedi';

  @override
  String get incomingAudioCall => 'Gelen Sesli Arama';

  @override
  String get incomingVideoCall => 'Gelen Görüntülü Arama';

  @override
  String get outgoingCall => 'Aranıyor...';

  @override
  String get callRinging => 'Çalıyor...';

  @override
  String get callConnecting => 'Bağlanıyor...';

  @override
  String get callConnected => 'Bağlandı';

  @override
  String get callReconnecting => 'Yeniden bağlanıyor...';

  @override
  String get callEnded => 'Arama Sona Erdi';

  @override
  String get callFailed => 'Arama Başarısız';

  @override
  String get callMissed => 'Cevapsız Arama';

  @override
  String get callDeclined => 'Arama Reddedildi';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => 'Kabul Et';

  @override
  String get declineCall => 'Reddet';

  @override
  String get endCall => 'Bitir';

  @override
  String get muteCall => 'Sessiz';

  @override
  String get unmuteCall => 'Sesi Aç';

  @override
  String get speakerOn => 'Hoparlör';

  @override
  String get speakerOff => 'Kulaklık';

  @override
  String get videoOn => 'Video Açık';

  @override
  String get videoOff => 'Video Kapalı';

  @override
  String get switchCamera => 'Kamera Değiştir';

  @override
  String get callPermissionDenied => 'Aramalar için mikrofon izni gerekli';

  @override
  String get cameraPermissionDenied => 'Görüntülü aramalar için kamera izni gerekli';

  @override
  String get callConnectionFailed => 'Bağlanılamadı. Lütfen tekrar deneyin.';

  @override
  String get userBusy => 'Kullanıcı meşgul';

  @override
  String get userOffline => 'Kullanıcı çevrimdışı';

  @override
  String get callHistory => 'Arama Geçmişi';

  @override
  String get noCallHistory => 'Arama geçmişi yok';

  @override
  String get missedCalls => 'Cevapsız Aramalar';

  @override
  String get allCalls => 'Tüm Aramalar';

  @override
  String get callBack => 'Geri Ara';

  @override
  String callAt(String time) {
    return '$time saatinde arama';
  }

  @override
  String get audioCall => 'Sesli Arama';

  @override
  String get voiceRoom => 'Ses Odası';

  @override
  String get noVoiceRooms => 'Aktif ses odası yok';

  @override
  String get createVoiceRoom => 'Ses Odası Oluştur';

  @override
  String get joinRoom => 'Odaya Katıl';

  @override
  String get leaveRoomConfirm => 'Odadan Ayrıl?';

  @override
  String get leaveRoomMessage => 'Bu odadan ayrılmak istediğinizden emin misiniz?';

  @override
  String get roomTitle => 'Oda Başlığı';

  @override
  String get roomTitleHint => 'Oda başlığı girin';

  @override
  String get roomTopic => 'Konu';

  @override
  String get roomLanguage => 'Dil';

  @override
  String get roomHost => 'Ev Sahibi';

  @override
  String roomParticipants(int count) {
    return '$count katılımcı';
  }

  @override
  String roomMaxParticipants(int count) {
    return 'Maks. $count katılımcı';
  }

  @override
  String get selectTopic => 'Konu Seç';

  @override
  String get raiseHand => 'El Kaldır';

  @override
  String get lowerHand => 'El İndir';

  @override
  String get handRaisedNotification => 'El kaldırıldı! Ev sahibi isteğinizi görecek.';

  @override
  String get handLoweredNotification => 'El indirildi';

  @override
  String get muteParticipant => 'Katılımcıyı Sessize Al';

  @override
  String get kickParticipant => 'Odadan Çıkar';

  @override
  String get promoteToCoHost => 'Yardımcı Ev Sahibi Yap';

  @override
  String get endRoomConfirm => 'Odayı Sonlandır?';

  @override
  String get endRoomMessage => 'Bu, tüm katılımcılar için odayı sonlandıracak.';

  @override
  String get roomEnded => 'Oda ev sahibi tarafından sonlandırıldı';

  @override
  String get youWereRemoved => 'Odadan çıkarıldınız';

  @override
  String get roomIsFull => 'Oda dolu';

  @override
  String get roomChat => 'Oda Sohbeti';

  @override
  String get noMessages => 'Henüz mesaj yok';

  @override
  String get typeMessage => 'Mesaj yazın...';

  @override
  String get voiceRoomsDescription => 'Canlı sohbetlere katıl ve konuşma pratiği yap';

  @override
  String liveRoomsCount(int count) {
    return '$count Canlı';
  }

  @override
  String get noActiveRooms => 'Aktif oda yok';

  @override
  String get noActiveRoomsDescription => 'İlk sen bir ses odası başlat ve başkalarıyla konuşma pratiği yap!';

  @override
  String get startRoom => 'Oda Başlat';

  @override
  String get createRoom => 'Oda Oluştur';

  @override
  String get roomCreated => 'Oda başarıyla oluşturuldu!';

  @override
  String get failedToCreateRoom => 'Oda oluşturulamadı';

  @override
  String get errorLoadingRooms => 'Odalar yüklenirken hata';

  @override
  String get pleaseEnterRoomTitle => 'Lütfen bir oda başlığı girin';

  @override
  String get startLiveConversation => 'Canlı sohbet başlat';

  @override
  String get maxParticipants => 'Maks. Katılımcı';

  @override
  String nPeople(int count) {
    return '$count kişi';
  }

  @override
  String hostedBy(String name) {
    return '$name tarafından düzenleniyor';
  }

  @override
  String get liveLabel => 'CANLI';

  @override
  String get joinLabel => 'Katıl';

  @override
  String get fullLabel => 'Dolu';

  @override
  String get justStarted => 'Yeni başladı';

  @override
  String get allLanguages => 'Tüm diller';

  @override
  String get allTopics => 'Tüm konular';

  @override
  String get allCategories => 'Tüm kategoriler';

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
  String get you => 'Sen';

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
  String get dataAndStorage => 'Veri ve Depolama';

  @override
  String get manageStorageAndDownloads => 'Depolama ve indirmeleri yönet';

  @override
  String get storageUsage => 'Depolama Kullanımı';

  @override
  String get totalCacheSize => 'Toplam Önbellek Boyutu';

  @override
  String get imageCache => 'Resim Önbelleği';

  @override
  String get voiceMessagesCache => 'Sesli Mesajlar';

  @override
  String get videoCache => 'Video Önbelleği';

  @override
  String get otherCache => 'Diğer Önbellek';

  @override
  String get autoDownloadMedia => 'Medya Otomatik İndir';

  @override
  String get currentNetwork => 'Mevcut Ağ';

  @override
  String get images => 'Resimler';

  @override
  String get videos => 'Videolar';

  @override
  String get voiceMessagesShort => 'Sesli Mesajlar';

  @override
  String get documentsLabel => 'Belgeler';

  @override
  String get wifiOnly => 'Yalnızca WiFi';

  @override
  String get never => 'Asla';

  @override
  String get clearAllCache => 'Tüm Önbelleği Temizle';

  @override
  String get allCache => 'Tüm Önbellek';

  @override
  String get clearAllCacheConfirmation => 'Bu, önbelleğe alınmış tüm resimleri, sesli mesajları, videoları ve diğer dosyaları silecektir. Uygulama geçici olarak içeriği daha yavaş yükleyebilir.';

  @override
  String clearCacheConfirmationFor(String category) {
    return '$category temizlensin mi?';
  }

  @override
  String storageToFree(String size) {
    return '$size boşaltılacak';
  }

  @override
  String get calculating => 'Hesaplanıyor...';

  @override
  String get noDataToShow => 'Gösterilecek veri yok';

  @override
  String get profileCompletion => 'Profil Tamamlama';

  @override
  String get justGettingStarted => 'Yeni başlıyor';

  @override
  String get lookingGood => 'İyi görünüyor!';

  @override
  String get almostThere => 'Neredeyse bitti!';

  @override
  String addMissingFields(String fields, Object field) {
    return 'Profilinizi tamamlamak için $field ekleyin';
  }

  @override
  String get profilePicture => 'Profil Fotoğrafı';

  @override
  String get nativeSpeaker => 'Ana Dil';

  @override
  String peopleInterestedInTopic(Object count) {
    return '$count kişi ilgileniyor';
  }

  @override
  String get beFirstToAddTopic => 'Bu konuyu ekleyen ilk kişi olun!';

  @override
  String get recentMoments => 'Son Anlar';

  @override
  String get seeAll => 'Tümünü Gör';

  @override
  String get study => 'Çalışma';

  @override
  String get followerMoments => 'Takip Edilen Anlar';

  @override
  String get whenPeopleYouFollowPost => 'Takip ettiğiniz kişiler yeni anlar paylaştığında';

  @override
  String get noNotificationsYet => 'Henüz bildirim yok';

  @override
  String get whenYouGetNotifications => 'Bildirim aldığınızda burada görünecekler';

  @override
  String get failedToLoadNotifications => 'Bildirimler yüklenemedi';

  @override
  String get clearAllNotificationsConfirm => 'Tüm bildirimleri silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get tapToChange => 'Değiştirmek için dokun';

  @override
  String get noPictureSet => 'Fotoğraf ayarlanmadı';

  @override
  String get nameAndGender => 'İsim ve Cinsiyet';

  @override
  String get languageLevel => 'Dil Seviyesi';

  @override
  String get personalInformation => 'Kişisel Bilgiler';

  @override
  String get mbti => 'MBTI';

  @override
  String get topicsOfInterest => 'İlgi Alanları';

  @override
  String get levelBeginner => 'Başlangıç';

  @override
  String get levelElementary => 'Temel';

  @override
  String get levelIntermediate => 'Orta';

  @override
  String get levelUpperIntermediate => 'Orta Üstü';

  @override
  String get levelAdvanced => 'İleri';

  @override
  String get levelProficient => 'Uzman';

  @override
  String get selectYourLevel => 'Seviyenizi seçin';

  @override
  String howWellDoYouSpeak(String language) {
    return '$language ne kadar iyi konuşuyorsunuz?';
  }

  @override
  String get theLanguage => 'dil';

  @override
  String languageLevelSetTo(String level) {
    return 'Dil seviyesi $level olarak ayarlandı';
  }

  @override
  String get failedToUpdate => 'Güncelleme başarısız';

  @override
  String get profileUpdatedSuccessfully => 'Profil başarıyla güncellendi';

  @override
  String get genderRequired => 'Cinsiyet (Zorunlu)';

  @override
  String get editHometown => 'Memleketi Düzenle';

  @override
  String get useCurrentLocation => 'Mevcut Konumu Kullan';

  @override
  String get detecting => 'Algılanıyor...';

  @override
  String get getCurrentLocation => 'Mevcut Konumu Al';

  @override
  String get country => 'Ülke';

  @override
  String get city => 'Şehir';

  @override
  String get coordinates => 'Koordinatlar';

  @override
  String get noLocationDetectedYet => 'Henüz konum algılanmadı';

  @override
  String get detected => 'Algılandı';

  @override
  String get savedHometown => 'Memleket kaydedildi';

  @override
  String get locationServicesDisabled => 'Konum servisleri devre dışı';

  @override
  String get locationPermissionPermanentlyDenied => 'Konum izni kalıcı olarak reddedildi';

  @override
  String get unknown => 'Bilinmiyor';

  @override
  String get editBio => 'Biyografiyi Düzenle';

  @override
  String get bioUpdatedSuccessfully => 'Biyografi güncellendi!';

  @override
  String get tellOthersAboutYourself => 'Kendiniz hakkında bir şeyler yazın';

  @override
  String charactersCount(int count) {
    return '$count/500 karakter';
  }

  @override
  String get selectYourMbti => 'MBTI\'nizi seçin';

  @override
  String get myBloodType => 'Kan Grubum';

  @override
  String get pleaseSelectABloodType => 'Lütfen bir kan grubu seçin';

  @override
  String get bloodTypeSavedSuccessfully => 'Kan grubu başarıyla kaydedildi';

  @override
  String get hometownSavedSuccessfully => 'Memleket başarıyla kaydedildi';

  @override
  String get nativeLanguageRequired => 'Ana dil gerekli';

  @override
  String get languageToLearnRequired => 'Öğrenilecek dil gerekli';

  @override
  String get nativeLanguageCannotBeSame => 'Ana dil öğrenilen dille aynı olamaz';

  @override
  String get learningLanguageCannotBeSame => 'Öğrenilen dil ana dille aynı olamaz';

  @override
  String get pleaseSelectALanguage => 'Lütfen bir dil seçin';

  @override
  String get editInterests => 'İlgi Alanlarını Düzenle';

  @override
  String maxTopicsAllowed(int count) {
    return 'Maksimum $count konu izin verilir';
  }

  @override
  String get topicsUpdatedSuccessfully => 'Konular güncellendi!';

  @override
  String get failedToUpdateTopics => 'Konular güncellenemedi';

  @override
  String selectedCount(int count, int max) {
    return '$count seçildi';
  }

  @override
  String get profilePictures => 'Profil Fotoğrafları';

  @override
  String get addImages => 'Fotoğraf Ekle';

  @override
  String get selectUpToImages => 'null fotoğrafa kadar seçin';

  @override
  String get takeAPhoto => 'Fotoğraf Çek';

  @override
  String get removeImage => 'Fotoğrafı Kaldır';

  @override
  String get removeImageConfirm => 'Bu fotoğrafı kaldırmak istediğinizden emin misiniz?';

  @override
  String get removeAll => 'Remove All';

  @override
  String get removeAllSelectedImages => 'Remove All Selected Images';

  @override
  String get removeAllSelectedImagesConfirm => 'Are you sure you want to remove all selected images?';

  @override
  String get yourProfilePictureWillBeKept => 'Your existing profile picture will be kept';

  @override
  String get removeAllImages => 'Remove All Images';

  @override
  String get removeAllImagesConfirm => 'Are you sure you want to remove all profile pictures?';

  @override
  String get currentImages => 'Current Images';

  @override
  String get newImages => 'New Images';

  @override
  String get addMoreImages => 'Add More Images';

  @override
  String uploadImages(int count) {
    return '$count fotoğraf yükle';
  }

  @override
  String get imageRemovedSuccessfully => 'Fotoğraf kaldırıldı';

  @override
  String get imagesUploadedSuccessfully => 'Fotoğraflar yüklendi';

  @override
  String get selectedImagesCleared => 'Selected images cleared';

  @override
  String get extraImagesRemovedSuccessfully => 'Extra images removed successfully';

  @override
  String get mustKeepAtLeastOneProfilePicture => 'You must keep at least one profile picture';

  @override
  String get noProfilePicturesToRemove => 'No profile pictures to remove';

  @override
  String get authenticationTokenNotFound => 'Authentication token not found';

  @override
  String get saveChangesQuestion => 'Save Changes?';

  @override
  String youHaveUnuploadedImages(int count) {
    return 'You have $count image(s) selected but not uploaded. Do you want to upload them now?';
  }

  @override
  String get discard => 'Discard';

  @override
  String get upload => 'Upload';

  @override
  String maxImagesInfo(int max, int current) {
    return 'You can upload up to $max images. Currently: $current/$max\nMax 5 images per upload.';
  }

  @override
  String canOnlyAddMoreImages(int count, int max) {
    return 'You can only add $count more image(s). Maximum is $max images total.';
  }

  @override
  String get maxImagesPerUpload => 'You can upload maximum 5 images at once. Only first 5 will be added.';

  @override
  String canOnlyHaveMaxImages(int max) {
    return 'You can only have up to $max images';
  }

  @override
  String get imageSizeExceedsLimit => 'Image size exceeds 10MB limit';

  @override
  String get unsupportedImageFormat => 'Unsupported image format';

  @override
  String get pleaseSelectAtLeastOneImage => 'Please select at least one image to upload';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get languageToLearn => 'Language to Learn';

  @override
  String get hometown => 'Hometown';

  @override
  String get characters => 'karakter';

  @override
  String get failedToLoadLanguages => 'Failed to load languages';

  @override
  String get studyHub => 'Çalışma Merkezi';

  @override
  String get dailyLearningJourney => 'Günlük öğrenme yolculuğunuz';

  @override
  String get learnTab => 'Öğren';

  @override
  String get aiTools => 'AI Araçları';

  @override
  String get streak => 'Seri';

  @override
  String get lessons => 'Dersler';

  @override
  String get words => 'Kelimeler';

  @override
  String get quickActions => 'Hızlı İşlemler';

  @override
  String get review => 'Tekrar';

  @override
  String wordsDue(int count) {
    return '$count kelime bekliyor';
  }

  @override
  String get addWords => 'Kelime Ekle';

  @override
  String get buildVocabulary => 'Kelime hazinesi oluştur';

  @override
  String get practiceWithAI => 'AI ile Pratik Yap';

  @override
  String get aiPracticeDescription => 'Sohbet, sınav, dilbilgisi ve telaffuz';

  @override
  String get dailyChallenges => 'Günlük Görevler';

  @override
  String get allChallengesCompleted => 'Tüm görevler tamamlandı!';

  @override
  String get continueLearning => 'Öğrenmeye Devam Et';

  @override
  String get structuredLearningPath => 'Yapılandırılmış öğrenme yolu';

  @override
  String get vocabulary => 'Kelime Hazinesi';

  @override
  String get yourWordCollection => 'Kelime koleksiyonunuz';

  @override
  String get achievements => 'Başarılar';

  @override
  String get badgesAndMilestones => 'Rozetler ve dönüm noktaları';

  @override
  String get failedToLoadLearningData => 'Öğrenme verileri yüklenemedi';

  @override
  String get startYourJourney => 'Yolculuğunuza başlayın!';

  @override
  String get startJourneyDescription => 'Dersleri tamamlayın, kelime hazinesi oluşturun\nve ilerlemenizi takip edin';

  @override
  String levelN(int level) {
    return 'Seviye $level';
  }

  @override
  String xpEarned(int xp) {
    return '$xp XP kazanıldı';
  }

  @override
  String nextLevel(int level) {
    return 'Sonraki: Seviye $level';
  }

  @override
  String xpToGo(int xp) {
    return '$xp XP kaldı';
  }

  @override
  String get aiConversationPartner => 'AI Konuşma Ortağı';

  @override
  String get practiceWithAITutor => 'AI öğretmeninizle konuşma pratiği yapın';

  @override
  String get startConversation => 'Konuşmayı Başlat';

  @override
  String get aiFeatures => 'AI Özellikleri';

  @override
  String get aiLessons => 'AI Dersleri';

  @override
  String get learnWithAI => 'AI ile Öğren';

  @override
  String get grammar => 'Dilbilgisi';

  @override
  String get checkWriting => 'Yazıyı kontrol et';

  @override
  String get pronunciation => 'Telaffuz';

  @override
  String get improveSpeaking => 'Konuşmayı geliştir';

  @override
  String get translation => 'Çeviri';

  @override
  String get smartTranslate => 'Akıllı çeviri';

  @override
  String get aiQuizzes => 'AI Sınavları';

  @override
  String get testKnowledge => 'Bilgiyi sına';

  @override
  String get lessonBuilder => 'Ders Oluşturucu';

  @override
  String get customLessons => 'Özel dersler';

  @override
  String get yourAIProgress => 'AI İlerlemeniz';

  @override
  String get quizzes => 'Sınavlar';

  @override
  String get avgScore => 'Ortalama Puan';

  @override
  String get focusAreas => 'Odak Alanları';

  @override
  String accuracyPercent(String accuracy) {
    return '%$accuracy doğruluk';
  }

  @override
  String get practice => 'Pratik Yap';

  @override
  String get browse => 'Gözat';

  @override
  String get noRecommendedLessons => 'Önerilen ders yok';

  @override
  String get noLessonsFound => 'Ders bulunamadı';

  @override
  String get createCustomLessonDescription => 'AI ile kendi özel dersinizi oluşturun';

  @override
  String get createLessonWithAI => 'AI ile Ders Oluştur';

  @override
  String get allLevels => 'Tüm Seviyeler';

  @override
  String get levelA1 => 'A1 Başlangıç';

  @override
  String get levelA2 => 'A2 Temel';

  @override
  String get levelB1 => 'B1 Orta';

  @override
  String get levelB2 => 'B2 Orta-Üst';

  @override
  String get levelC1 => 'C1 İleri';

  @override
  String get levelC2 => 'C2 Ustalık';

  @override
  String get failedToLoadLessons => 'Dersler yüklenemedi';

  @override
  String get pin => 'Sabitle';

  @override
  String get unpin => 'Sabitlemeyi Kaldır';

  @override
  String get editMessage => 'Mesajı Düzenle';

  @override
  String get enterMessage => 'Mesaj yazın...';

  @override
  String get deleteMessageTitle => 'Mesajı Sil';

  @override
  String get actionCannotBeUndone => 'Bu işlem geri alınamaz.';

  @override
  String get onlyRemovesFromDevice => 'Yalnızca cihazınızdan kaldırır';

  @override
  String get availableWithinOneHour => 'Yalnızca 1 saat içinde kullanılabilir';

  @override
  String get available => 'Kullanılabilir';

  @override
  String get forwardMessage => 'Mesajı İlet';

  @override
  String get selectUsersToForward => 'İletilecek kullanıcıları seçin:';

  @override
  String forwardCount(int count) {
    return 'İlet ($count)';
  }

  @override
  String get pinnedMessage => 'Sabitlenmiş Mesaj';

  @override
  String get photoMedia => 'Fotoğraf';

  @override
  String get videoMedia => 'Video';

  @override
  String get voiceMessageMedia => 'Sesli mesaj';

  @override
  String get documentMedia => 'Belge';

  @override
  String get locationMedia => 'Konum';

  @override
  String get stickerMedia => 'Çıkartma';

  @override
  String get smileys => 'Gülen Yüzler';

  @override
  String get emotions => 'Duygular';

  @override
  String get handGestures => 'El Hareketleri';

  @override
  String get hearts => 'Kalpler';

  @override
  String get tapToSayHi => 'Merhaba demek için dokunun!';

  @override
  String get sendWaveToStart => 'Sohbete başlamak için el sallayın';

  @override
  String get documentMustBeUnder50MB => 'Belge 50MB\'den küçük olmalıdır.';

  @override
  String get editWithin15Minutes => 'Mesajlar yalnızca 15 dakika içinde düzenlenebilir';

  @override
  String messageForwardedTo(int count) {
    return 'Mesaj $count kullanıcıya iletildi';
  }

  @override
  String get failedToLoadUsers => 'Kullanıcılar yüklenemedi';

  @override
  String get voice => 'Ses';

  @override
  String get searchGifs => 'GIF ara...';

  @override
  String get trendingGifs => 'Trend';

  @override
  String get poweredByGiphy => 'Powered by GIPHY';

  @override
  String get gif => 'GIF';

  @override
  String get noGifsFound => 'GIF bulunamadı';

  @override
  String get failedToLoadGifs => 'GIF\'ler yüklenemedi';

  @override
  String get gifSent => 'GIF';

  @override
  String get filterCommunities => 'Filtrele';

  @override
  String get reset => 'Sıfırla';

  @override
  String get findYourPerfect => 'Mükemmel';

  @override
  String get languagePartner => 'Dil Ortağını Bul';

  @override
  String get learningLanguageLabel => 'Öğrenilen Dil';

  @override
  String get ageRange => 'Yaş Aralığı';

  @override
  String get genderPreference => 'Cinsiyet Tercihi';

  @override
  String get any => 'Herhangi';

  @override
  String get showNewUsersSubtitle => 'Son 6 günde katılan kullanıcıları göster';

  @override
  String get autoDetectLocation => 'Konumumu otomatik algıla';

  @override
  String get selectCountry => 'Ülke Seç';

  @override
  String get anyCountry => 'Herhangi Bir Ülke';

  @override
  String get loadingLanguages => 'Diller yükleniyor...';

  @override
  String minAge(int age) {
    return 'Min: $age';
  }

  @override
  String maxAge(int age) {
    return 'Maks: $age';
  }

  @override
  String get captionRequired => 'Açıklama gereklidir';

  @override
  String captionTooLong(int maxLength) {
    return 'Açıklama $maxLength karakter veya daha az olmalıdır';
  }

  @override
  String get maximumImagesReached => 'Maksimum Görsel Sayısına Ulaşıldı';

  @override
  String maximumImagesReachedDescription(int maxImages) {
    return 'Her an için en fazla $maxImages görsel yükleyebilirsiniz.';
  }

  @override
  String maximumImagesAddedPartial(int maxImages, int added) {
    return 'Maksimum $maxImages görsel. Sadece $added görsel eklendi.';
  }

  @override
  String get locationAccessRestricted => 'Konum Erişimi Kısıtlandı';

  @override
  String get locationPermissionNeeded => 'Konum İzni Gerekli';

  @override
  String get addToYourMoment => 'Anına ekle';

  @override
  String get categoryLabel => 'Kategori';

  @override
  String get languageLabel => 'Dil';

  @override
  String get scheduleOptional => 'Zamanla (isteğe bağlı)';

  @override
  String get scheduleForLater => 'Daha sonra için zamanla';

  @override
  String get addMore => 'Daha Fazla Ekle';

  @override
  String get howAreYouFeeling => 'Nasıl hissediyorsun?';

  @override
  String get pleaseWaitOptimizingVideo => 'Videonuzu optimize ederken lütfen bekleyin';

  @override
  String unsupportedVideoFormat(String formats) {
    return 'Desteklenmeyen format. Kullanın: $formats';
  }

  @override
  String get chooseBackground => 'Arka plan seç';

  @override
  String likedByXPeople(int count) {
    return '$count kişi beğendi';
  }

  @override
  String xComments(int count) {
    return '$count yorum';
  }

  @override
  String get oneComment => '1 yorum';

  @override
  String get addAComment => 'Yorum ekle...';

  @override
  String viewXReplies(int count) {
    return '$count yanıtı gör';
  }

  @override
  String seenByX(int count) {
    return '$count kişi gördü';
  }

  @override
  String xHoursAgo(int count) {
    return '${count}s önce';
  }

  @override
  String xMinutesAgo(int count) {
    return '${count}dk önce';
  }

  @override
  String get repliedToYourStory => 'Hikayene yanıt verdi';

  @override
  String mentionedYouInComment(String name) {
    return '$name seni bir yorumda etiketledi';
  }

  @override
  String repliedToYourComment(String name) {
    return '$name yorumuna yanıt verdi';
  }

  @override
  String reactedToYourComment(String name) {
    return '$name yorumuna tepki verdi';
  }

  @override
  String get addReaction => 'Tepki ekle';

  @override
  String get attachImage => 'Resim ekle';

  @override
  String get pickGif => 'GIF seç';

  @override
  String get textStory => 'Metin';

  @override
  String get typeYourStory => 'Hikayeni yaz...';

  @override
  String get selectBackground => 'Arka plan seç';

  @override
  String get highlightsTitle => 'Öne Çıkanlar';

  @override
  String get highlightTitle => 'Başlık';

  @override
  String get createNewHighlight => 'Yeni oluştur';

  @override
  String get selectStories => 'Hikayeleri seç';

  @override
  String get selectCover => 'Kapak seç';

  @override
  String get addText => 'Metin ekle';

  @override
  String get fontStyleLabel => 'Yazı tipi';

  @override
  String get textColorLabel => 'Metin rengi';

  @override
  String get dragToDelete => 'Silmek için buraya sürükle';

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
  String get momentUpdatedSuccessfully => 'An başarıyla güncellendi';

  @override
  String get failedToDeleteMoment => 'An silinemedi';

  @override
  String get failedToUpdateMoment => 'An güncellenemedi';

  @override
  String get mbtiUpdatedSuccessfully => 'MBTI başarıyla güncellendi';

  @override
  String get pleaseSelectMbti => 'Lütfen bir MBTI türü seçin';

  @override
  String get languageUpdatedSuccessfully => 'Dil başarıyla güncellendi';

  @override
  String get bioHintCard => 'İyi bir biyografi, diğerlerinin seninle bağlantı kurmasına yardımcı olur. İlgi alanlarını, dillerini veya ne aradığını paylaş.';

  @override
  String get bioCounterStartWriting => 'Yazmaya başla...';

  @override
  String get bioCounterABitMore => 'Biraz daha yazsan iyi olur';

  @override
  String get bioCounterAlmostAtLimit => 'Limite yaklaşıyorsun';

  @override
  String get bioCounterTooLong => 'Çok uzun';

  @override
  String get bioQuickStarters => 'Hızlı başlangıçlar';

  @override
  String get rhPositive => 'Rh Pozitif';

  @override
  String get rhNegative => 'Rh Negatif';

  @override
  String get rhPositiveDesc => 'En yaygın';

  @override
  String get rhNegativeDesc => 'Evrensel donör / nadir';

  @override
  String get yourBloodType => 'Kan grubunuz';

  @override
  String get noBloodTypeSelected => 'Kan grubu seçilmedi';

  @override
  String get tapTypeBelow => 'Aşağıdan bir tür seçin';

  @override
  String get tapButtonToDetectLocation => 'Mevcut konumunu tespit etmek için aşağıdaki düğmeye dokun';

  @override
  String currentAddressLabel(String address) {
    return 'Mevcut: $address';
  }

  @override
  String get onlyCityCountryShown => 'Diğer kullanıcılara yalnızca şehrin ve ülken gösterilir. Kesin koordinatlar gizli kalır.';

  @override
  String get updateLocationCta => 'Konumu Güncelle';

  @override
  String get enterYourName => 'Adınızı girin';

  @override
  String get unsavedChanges => 'Kaydedilmemiş değişiklikleriniz var';

  @override
  String tapBelowToBrowseLanguages(int count) {
    return '$count dil arasından seçmek için aşağıya dokunun';
  }

  @override
  String get changeLanguage => 'Dili Değiştir';

  @override
  String get browseLanguages => 'Dillere Göz At';

  @override
  String get yourLearningLanguageIsPrefix => 'Öğrendiğiniz dil: ';

  @override
  String get yourNativeLanguageIsPrefix => 'Ana diliniz: ';

  @override
  String get profileCompleteProgress => 'tamamlandı';

  @override
  String get drawerPreferences => 'Tercihler';

  @override
  String get drawerStorage => 'Depolama';

  @override
  String get drawerReports => 'Raporlar';

  @override
  String get drawerSupport => 'Destek';

  @override
  String get drawerAccount => 'Hesap';

  @override
  String get logoutConfirmBody => 'Bananatalk\'tan çıkış yapmak istediğinizden emin misiniz?';

  @override
  String get helpEmailSupport => 'E-posta Desteği';

  @override
  String get helpEmailSupportSubtitle => 'support@bananatalk.com';

  @override
  String get helpReportBug => 'Hata Bildir';

  @override
  String get helpReportBugSubtitle => 'Bananatalk\'ı geliştirmemize yardımcı olun';

  @override
  String get helpFaqs => 'SSS';

  @override
  String get helpFaqsSubtitle => 'Sık sorulan sorular';

  @override
  String get aboutDialogClose => 'Kapat';

  @override
  String get aboutBananatalkTagline => 'Dünya genelindeki dil öğrencileriyle bağlantı kurun ve gerçek sohbetler aracılığıyla becerilerinizi geliştirin.';

  @override
  String get aboutCopyright => '© 2024 Bananatalk. Tüm hakları saklıdır.';

  @override
  String get logoutFailedPrefix => 'Çıkış başarısız';

  @override
  String get profileVisitorsTitle => 'Profil Ziyaretçileri';

  @override
  String get visitorStatistics => 'Ziyaretçi İstatistikleri';

  @override
  String get visitorsTotalVisits => 'Toplam Ziyaret';

  @override
  String get visitorsUniqueVisitors => 'Tekil Ziyaretçi';

  @override
  String get visitorsToday => 'Bugün';

  @override
  String get visitorsThisWeek => 'Bu Hafta';

  @override
  String get noVisitorsYet => 'Henüz ziyaretçi yok';

  @override
  String get noVisitorsYetSubtitle => 'Biri profilinizi ziyaret ettiğinde,\nburada görünecekler';

  @override
  String get visitedViaSearch => 'Arama yoluyla';

  @override
  String get visitedViaMoments => 'Anlar yoluyla';

  @override
  String get visitedViaChat => 'Sohbet yoluyla';

  @override
  String get visitedDirect => 'Doğrudan ziyaret';

  @override
  String get visitorTrackingUnavailable => 'Ziyaretçi takip özelliği kullanılamıyor. Lütfen backend\'i güncelleyin.';

  @override
  String get visitorTrackingNotAvailableYet => 'Ziyaretçi takibi henüz mevcut değil';

  @override
  String get noFollowersYetSubtitle => 'Başkalarıyla bağlantı kurmaya başlayın!';

  @override
  String get partnerButton => 'Ortak';

  @override
  String get notFollowingAnyoneYetSubtitle => 'Güncellemelerini görmek için kişileri takip edin!';

  @override
  String get unfollowButton => 'Takibi Bırak';

  @override
  String get profileThemeTitle => 'Profil Teması';

  @override
  String get themeAutoSwitch => 'Otomatik Geçiş (Sistem Teması)';

  @override
  String get themeSystemHint => 'Etkinleştirildiğinde uygulama sistem teması ayarlarınızı takip eder';

  @override
  String get themeLightMode => 'Açık Mod';

  @override
  String get themeDarkMode => 'Koyu Mod';

  @override
  String get myMoments => 'Anlarım';

  @override
  String get momentListView => 'Liste Görünümü';

  @override
  String get momentGridView => 'Izgara Görünümü';

  @override
  String get shareLanguageLearningJourney => 'Dil öğrenme yolculuğunuzu paylaşın!';

  @override
  String get deleteHighlightTitle => 'Öne Çıkanı Sil';

  @override
  String deleteHighlightConfirm(String title) {
    return '\"$title\" silinsin mi? İçindeki hikayeler silinmeyecek.';
  }

  @override
  String get highlightDeletedSuccess => 'Öne çıkan silindi';

  @override
  String get highlightNewBadge => 'Yeni';

  @override
  String get editMoment => 'Anı Düzenle';

  @override
  String get momentDescriptionLabel => 'Açıklama';

  @override
  String get momentImagesLabel => 'Görseller';

  @override
  String get noImagesYet => 'Henüz görsel yok';

  @override
  String get momentEnterDescription => 'Lütfen bir açıklama girin';

  @override
  String get momentUpdatedImageFailed => 'An güncellendi fakat görsel yükleme başarısız oldu';

  @override
  String get updateRequiredTitle => 'Güncelleme Gerekli';

  @override
  String get updateAvailableTitle => 'Güncelleme Mevcut';

  @override
  String get updateRequiredBody => 'Bananatalk\'ın bu sürümü artık desteklenmiyor. Devam etmek için lütfen güncelleyin.';

  @override
  String get updateAvailableBody => 'İyileştirmeler ve hata düzeltmeleri içeren yeni bir Bananatalk sürümü mevcut.';

  @override
  String get updateNow => 'Şimdi Güncelle';

  @override
  String get updateLater => 'Sonra';

  @override
  String get updateOpenStoreFailed => 'Mağaza açılamadı. Lütfen App Store veya Play Store\'dan güncelleyin.';

  @override
  String get rememberMe => 'Beni hatırla';

  @override
  String get passwordWeak => 'Zayıf';

  @override
  String get passwordFair => 'Orta';

  @override
  String get passwordStrong => 'Güçlü';

  @override
  String get passwordVeryStrong => 'Çok güçlü';

  @override
  String get showPassword => 'Şifreyi göster';

  @override
  String get hidePassword => 'Şifreyi gizle';

  @override
  String stepProgress(int current, int total) {
    return 'Adım $current / $total';
  }

  @override
  String get usernameOptional => 'Kullanıcı adı (isteğe bağlı)';

  @override
  String get usernameAvailable => 'Kullanılabilir';

  @override
  String get usernameTaken => 'Zaten kullanılıyor';

  @override
  String get usernameNotAvailable => 'Kullanılamaz';

  @override
  String get usernameInvalidFormat => '3-20 karakter: harf, rakam veya alt çizgi';

  @override
  String get usernameHint => '@kullaniciadi';

  @override
  String get enableBiometricTitle => 'Bir dahaki sefere Face ID ile giriş yapılsın mı?';

  @override
  String get enableBiometricBody => 'Şifre yazmadan biyometrik ile giriş yapın.';

  @override
  String get enableBiometricCta => 'Etkinleştir';

  @override
  String get biometricSignInPrompt => 'Bananatalk\'a giriş için kimliğinizi doğrulayın';

  @override
  String continueAs(String name) {
    return '$name olarak devam et';
  }

  @override
  String get addProfilePhotoTitle => 'Profil fotoğrafı ekle';

  @override
  String get addProfilePhotoSkip => 'Şimdilik atla';

  @override
  String get wavesTab => 'Dalgalar';

  @override
  String get sendWave => 'El salla';

  @override
  String sendWaveTo(String name) {
    return '$name kişisine el salla';
  }

  @override
  String waveSent(String name) {
    return '$name kişisine el sallandı';
  }

  @override
  String waveCooldown(String name, String time) {
    return '$name kişisine $time sonra tekrar el sallayabilirsin';
  }

  @override
  String get waveCouldntSend => 'El sallama gönderilemedi';

  @override
  String get itsAMatch => 'Eşleşme!';

  @override
  String itsAMatchSubtitle(String name) {
    return 'Sen ve $name birbirinize el salladınız';
  }

  @override
  String get sendAMessage => 'Mesaj gönder';

  @override
  String get waveQuickReplyHi => 'Merhaba!';

  @override
  String get waveQuickReplyCool => 'Harika görünüyorsun';

  @override
  String get waveQuickReplyHey => 'Hey';

  @override
  String get waveQuickReplyChat => 'Sohbet edelim';

  @override
  String get waveQuickReplyHello => 'Selam';

  @override
  String waveQuickReplyFromCountry(String country) {
    return '$country\'dan merhaba';
  }

  @override
  String get waveCustomMessage => 'Ya da kendine ait bir mesaj yaz…';

  @override
  String get voiceRoomChat => 'Sohbet';

  @override
  String get voiceRoomChatPlaceholder => 'Mesaj gönder…';

  @override
  String get voiceRoomChatEmpty => 'Henüz mesaj yok — merhaba de';

  @override
  String get voiceRoomChatSend => 'Gönder';

  @override
  String voiceRoomChatNewBadge(int n) {
    return '$n';
  }

  @override
  String get voiceRoomEnd => 'Odayı bitir';

  @override
  String get voiceRoomEndConfirm => 'Bu odayı bitir?';

  @override
  String get voiceRoomEndConfirmBody => 'Herkesin bağlantısı kesilecek.';

  @override
  String get voiceRoomKick => 'Odadan çıkar';

  @override
  String voiceRoomKickConfirm(String name) {
    return '$name kişisini çıkar?';
  }

  @override
  String get voiceRoomKicked => 'Çıkarıldı';

  @override
  String get voiceRoomYouAreHostNow => 'Artık ev sahibisin';

  @override
  String voiceRoomHostChanged(String name) {
    return '$name artık ev sahibi';
  }

  @override
  String get voiceRoomHostMenuTitle => 'Oda işlemleri';

  @override
  String get voiceRoomViewProfile => 'Profili gör';

  @override
  String get voiceRoomReconnecting => 'Yeniden bağlanıyor…';

  @override
  String get voiceRoomReconnected => 'Yeniden bağlandı';

  @override
  String get voiceRoomEnded => 'Oda sona erdi';

  @override
  String get voiceRoomReconnectRetry => 'Tekrar dene';

  @override
  String get mutualInterests => 'Ortak ilgi alanları';

  @override
  String interestsInCommon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ortak ilgi',
      one: '1 ortak ilgi',
      zero: 'Henüz ortak ilgi yok',
    );
    return '$_temp0';
  }

  @override
  String get interestsInCommonSeeAll => 'Tümünü gör';

  @override
  String get interestsInCommonAddCta => 'Konu ekle';

  @override
  String get interestsInCommonAddSubtitle => 'Ortak nokta bulmak için profiline konu ekle';

  @override
  String activeAgo(String time) {
    return '$time önce aktifti';
  }

  @override
  String get filterOnlineNow => 'Şu an çevrimiçi';

  @override
  String get filterAge => 'Yaş';

  @override
  String get filterGender => 'Cinsiyet';

  @override
  String get filterLanguages => 'Diller';

  @override
  String get filterCountry => 'Ülke';

  @override
  String get filterTopics => 'Konular';

  @override
  String get filterLevel => 'Dil seviyesi';

  @override
  String get filterToggles => 'Diğer';

  @override
  String filterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ortak eşleşiyor',
      one: '1 ortak eşleşiyor',
      zero: 'Eşleşen ortak yok',
    );
    return '$_temp0';
  }

  @override
  String get filterClearAll => 'Tümünü temizle';

  @override
  String get filterReset => 'Sıfırla';

  @override
  String get filterApply => 'Uygula';

  @override
  String get filterNewUsers => 'Yalnızca yeni kullanıcılar';

  @override
  String get filterPrioritizeNearby => 'Yakınları önceliklendir';

  @override
  String get filterSheetTitle => 'Filtreler';

  @override
  String get notificationPreferencesTitle => 'Bildirimler';

  @override
  String get notificationPreferencesSubtitle => 'Hangi uyarıları alacağınızı seçin';

  @override
  String get notifPrefChat => 'Yeni mesajlar';

  @override
  String get notifPrefWave => 'Dalgalar';

  @override
  String get notifPrefVoiceRoomStart => 'Sesli oda davetleri';

  @override
  String get notifPrefScheduledRoomReminder => 'Planlanmış oda hatırlatıcıları';

  @override
  String get notifPrefFollowerMoment => 'Takip ettiğiniz kişilerin yeni anları';

  @override
  String get notifPrefVisitorAlert => 'Profil ziyaretçileri';

  @override
  String get notifPrefMatchAlert => 'Karşılıklı dalgalar';

  @override
  String get notifResetToDefaults => 'Varsayılanlara sıfırla';

  @override
  String get themeMode => 'Tema';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get languageSettingsRow => 'Dil';

  @override
  String get waveDailySummaryTitle => 'Bekleyen yeni dalgalar';

  @override
  String waveDailySummaryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişi size dalga gönderdi',
      one: '1 kişi size dalga gönderdi',
    );
    return '$_temp0';
  }

  @override
  String get filterTopicsTitle => 'Konular';

  @override
  String get filterTopicsEmpty => 'Konu seçilmedi';

  @override
  String get storiesEmpty => 'Henüz hikaye yok';

  @override
  String get storiesLoadError => 'Hikayeler yüklenemedi';

  @override
  String get storiesRetry => 'Tekrar dene';

  @override
  String get storiesNoMore => 'Her şeyi gördünüz';

  @override
  String get createTextStoryTab => 'Metin';

  @override
  String get createImageStoryTab => 'Fotoğraf';

  @override
  String get createVideoStoryTab => 'Video';

  @override
  String get enterTextHint => 'Yazmak için dokunun';

  @override
  String get pickBackground => 'Arka plan';

  @override
  String get pickFontStyle => 'Yazı tipi';

  @override
  String get pickTextColor => 'Renk';

  @override
  String get addEmoji => 'Emoji ekle';

  @override
  String get chooseFont => 'Yazı tipi seç';

  @override
  String get chooseColor => 'Renk seç';

  @override
  String get dragToMove => 'Taşımak için sürükle';

  @override
  String get pinchToScale => 'Ölçeklendirmek için sıkıştır';

  @override
  String get removeFromHighlight => 'Öne çıkarmadan kaldır';

  @override
  String get highlightDeleted => 'Öne çıkarma silindi';

  @override
  String get storySaved => 'Hikayenize kaydedildi';

  @override
  String get storyTooLong => 'Metin çok uzun';

  @override
  String get storyPostFailed => 'Hikaye paylaşılamadı';

  @override
  String get fontNormal => 'Normal';

  @override
  String get fontBold => 'Kalın';

  @override
  String get fontItalic => 'İtalik';

  @override
  String get fontHandwriting => 'El yazısı';

  @override
  String get pickDate => 'Tarih seç';

  @override
  String get pickTime => 'Saat seç';

  @override
  String get upcomingRooms => 'Yaklaşan';

  @override
  String inHours(int h, int m) {
    return '${h}s ${m}dk sonra';
  }

  @override
  String inMinutes(int m) {
    return '${m}dk sonra';
  }

  @override
  String get startsNow => 'Şimdi başlıyor';

  @override
  String get iWillBeThere => 'Orada olacağım';

  @override
  String get cantMakeIt => 'Katılamayacağım';

  @override
  String rsvpCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count RSVP',
      one: '1 RSVP',
      zero: 'RSVP yok',
    );
    return '$_temp0';
  }

  @override
  String roomStartsIn1h(String title) {
    return '$title 1 saat sonra başlıyor';
  }

  @override
  String roomStartsIn15min(String title) {
    return '$title 15 dakika sonra başlıyor';
  }

  @override
  String roomStarted(String title) {
    return '$title şimdi başlıyor';
  }

  @override
  String get cancelRoom => 'Odayı iptal et';

  @override
  String get muteAll => 'Herkesi sustur';

  @override
  String get mutedByHost => 'Ev sahibi herkesi susturdu';

  @override
  String get muteAllConfirm => 'Odadaki herkesi susturmak ister misiniz?';

  @override
  String get categoryCasual => 'Sıradan';

  @override
  String get categoryLanguagePractice => 'Dil pratiği';

  @override
  String get categoryTopic => 'Konu';

  @override
  String get categoryQA => 'Soru-Cevap';

  @override
  String get pickCategory => 'Kategori';

  @override
  String get sortRecentlyActive => 'Son aktif';

  @override
  String visitedYourProfile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişi profilinizi ziyaret etti',
      one: '1 kişi profilinizi ziyaret etti',
    );
    return '$_temp0';
  }

  @override
  String get noRecentVisitors => 'Son ziyaretçi yok';

  @override
  String get viewArchive => 'Arşivi görüntüle';

  @override
  String get archivedWaves => 'Arşivlenmiş Waves';

  @override
  String get noArchivedWaves => 'Arşivlenmiş Wave yok';

  @override
  String get mutualInterestsMin => 'Ortak ilgi alanları (min)';

  @override
  String atLeastNTopics(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'En az $n ortak konu',
      one: 'En az 1 ortak konu',
      zero: 'Herhangi biri',
    );
    return '$_temp0';
  }

  @override
  String get starterAskMoment => 'Son anıları hakkında sor';

  @override
  String get starterSayHi => 'Kendi dillerinde merhaba de';

  @override
  String get starterCurious => 'Ne merak ediyorlar?';

  @override
  String starterFromCountry(String country) {
    return '$country\'dan merhaba!';
  }

  @override
  String starterPracticeLang(String language) {
    return '$language pratiği yapmalarına yardım et!';
  }

  @override
  String get momentsLoadError => 'Anlar yüklenemedi';

  @override
  String get momentsRetry => 'Tekrar dene';

  @override
  String get recentTags => 'Son etiketler';

  @override
  String get noRecentTags => 'Henüz son etiket yok';

  @override
  String get hideMomentsFromUser => 'Bu kullanıcının anlarını gizle';

  @override
  String get momentsHidden => 'Bu kullanıcının anları gizlenecek';

  @override
  String get unhideMoments => 'Bu kullanıcının anlarını göster';

  @override
  String momentsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kullanıcı gizli',
      one: '1 kullanıcı gizli',
      zero: 'Gizli kullanıcı yok',
    );
    return '$_temp0';
  }

  @override
  String get momentSaveFailed => 'An kaydedilemedi';

  @override
  String get tagAlreadyAdded => 'Etiket zaten eklendi';

  @override
  String get tagLimitReached => 'Maksimum etiket sayısına ulaşıldı';

  @override
  String get hideThisUser => 'Bu kullanıcının gönderilerini gizle';

  @override
  String get transcribeMessage => 'Yazıya dök';

  @override
  String get transcribing => 'Yazıya dökülüyor…';

  @override
  String get transcriptionFailed => 'Mesaj yazıya dökülemedi';

  @override
  String saveToVocabulary(String word) {
    return '\'$word\' kelimesini kelime hazinesine kaydet';
  }

  @override
  String get addedToVocabulary => 'Kelime hazinenize eklendi';

  @override
  String get alreadyInVocabulary => 'Zaten kelime hazinenizde';

  @override
  String get tapWordToSave => 'Kaydetmek için kelimeye basılı tutun';

  @override
  String get autoTranslateChatHint => 'Gelen mesajlar otomatik olarak çevrilecek';

  @override
  String get noConversationsYet => 'Henüz konuşma yok';

  @override
  String get chatRetry => 'Tekrar dene';

  @override
  String get learningHubTitle => 'Öğrenme';

  @override
  String get learningCommonRetry => 'Yeniden dene';

  @override
  String get learningCommonContinue => 'Devam et';

  @override
  String get learningCommonAwesome => 'Harika!';

  @override
  String get learningErrorGeneric => 'Bir şeyler yanlış gitti';

  @override
  String get learningStreakCurrent => 'Mevcut seri';

  @override
  String get learningStreakLongest => 'En uzun seri';

  @override
  String learningStreakDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
      one: '1 gün',
      zero: '0 gün',
    );
    return '$_temp0';
  }

  @override
  String learningStreakFreezeAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dondurma mevcut',
      one: '1 dondurma mevcut',
      zero: 'Mevcut dondurma yok',
    );
    return '$_temp0';
  }

  @override
  String get learningStreakFreezeUse => 'Donmayı kullan';

  @override
  String get learningStreakFreezeDescription => 'Dondurma, bir gün kaçırdığınızda serinizi korur.';

  @override
  String get learningStreakFreezeProtected => 'Seri korundu!';

  @override
  String get learningStreakMilestone7 => '7 günlük seri!';

  @override
  String get learningStreakMilestone30 => '30 günlük seri!';

  @override
  String get learningStreakMilestone100 => '100 günlük seri!';

  @override
  String get learningStreakMilestone365 => '365 günlük seri!';

  @override
  String get learningWeeklyDigestTitle => 'Bu hafta';

  @override
  String learningWeeklyDigestXp(int xp) {
    return '$xp XP kazanıldı';
  }

  @override
  String learningWeeklyDigestLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ders',
      one: '1 ders',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestVocab(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kelime öğrenildi',
      one: '1 kelime öğrenildi',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestDaysActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktif gün',
      one: '1 aktif gün',
    );
    return '$_temp0';
  }

  @override
  String get learningWeeklyDigestTopAchievement => 'En iyi başarı';

  @override
  String learningWeeklyDigestTrendUp(int pct) {
    return 'Geçen haftadan $pct% daha fazla';
  }

  @override
  String learningWeeklyDigestTrendDown(int pct) {
    return 'Geçen haftadan $pct% daha az';
  }

  @override
  String get learningWeeklyDigestTrendFlat => 'Geçen haftayla aynı';

  @override
  String get learningSrsDashboardTitle => 'Günlük tekrar';

  @override
  String learningSrsDueToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugün $count kart',
      one: 'Bugün 1 kart',
      zero: 'Bugün kart yok',
    );
    return '$_temp0';
  }

  @override
  String learningSrsDueTomorrow(int count) {
    return 'Yarın $count';
  }

  @override
  String learningSrsDueThisWeek(int count) {
    return 'Bu hafta $count';
  }

  @override
  String get learningSrsStartReview => 'Tekrarı başlat';

  @override
  String get learningSrsAllCaughtUp => 'Her şeyi tamamladınız!';

  @override
  String get learningSrsKeepGoing => 'Devam edin';

  @override
  String get learningLeaderboardXpTab => 'XP';

  @override
  String get learningLeaderboardStreakTab => 'Seri';

  @override
  String get learningLeaderboardLanguageTab => 'Dil';

  @override
  String get learningLeaderboardFriendsTab => 'Arkadaşlar';

  @override
  String get learningLeaderboardEmpty => 'Henüz sıralama yok';

  @override
  String get learningLeaderboardYouLabel => 'Sen';

  @override
  String get learningLeaderboardFriendBadge => 'Arkadaş';

  @override
  String get learningEmptyVocab => 'Hatırlamak istediğin kelimeleri ekle';

  @override
  String get learningEmptyLessons => 'Henüz ders yok';

  @override
  String get learningEmptyQuizzes => 'Quiz mevcut değil';

  @override
  String get learningEmptyChallenges => 'Yarın tekrar kontrol et';

  @override
  String get learningEmptyAchievements => 'İlk başarını kazan';

  @override
  String get learningEmptySearchResults => 'Sonuç bulunamadı';

  @override
  String learningXpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String get learningLevelUp => 'Seviye atladın!';

  @override
  String learningLevelReached(String level) {
    return '$level seviyesine ulaştın';
  }

  @override
  String get learningAchievementUnlocked => 'Başarı kazandın';

  @override
  String get learningVocabularySearchHint => 'Kelime ara';

  @override
  String get learningVocabularyFilterAll => 'Tümü';

  @override
  String get learningVocabularyFilterNew => 'Yeni';

  @override
  String get learningVocabularyFilterLearning => 'Öğreniyorum';

  @override
  String get learningVocabularyFilterMastered => 'Hâkim';

  @override
  String get learningVocabularySortRecent => 'Son';

  @override
  String get learningVocabularySortAlphabetical => 'Alfabetik';

  @override
  String get learningVocabularySortMastery => 'Hâkimiyet';

  @override
  String get learningVocabularyMasteryNew => 'Yeni';

  @override
  String get learningVocabularyMasteryLearning => 'Öğreniyorum';

  @override
  String get learningVocabularyMasteryMastered => 'Hâkim';

  @override
  String get learningProgressLevelLabel => 'Seviye';

  @override
  String learningProgressXpToNextLevel(int xp) {
    return 'Sonraki seviye için $xp XP';
  }

  @override
  String get learningProgressWeeklyChartTitle => 'Son 7 gün';

  @override
  String get aiTutorPronounceLoading => 'Senin için bir cümle seçiliyor…';

  @override
  String get aiTutorPronounceTapToRecord => 'Kaydetmek için dokun';

  @override
  String get aiTutorPronounceTapToStop => 'Durdurmak için dokun';

  @override
  String get aiTutorPronounceTranscribing => 'Seni dinliyorum…';

  @override
  String get aiTutorPronounceTryAgain => 'Tekrar dene';

  @override
  String get aiTutorPronounceNext => 'İleri';

  @override
  String get aiTutorPronounceUseYourOwn => 'Kendi cümlem ✏️';

  @override
  String get aiTutorPronounceCustomHint => 'Pratik yapmak istediğin bir cümle yaz';

  @override
  String get aiTutorPronounceCustomCancel => 'İptal';

  @override
  String get aiTutorPronounceCustomUse => 'Kullan';

  @override
  String get aiTutorPronounceQuitConfirm => 'Alıştırmadan çık? İlerlemen kaydedilmez.';

  @override
  String get aiTutorPronounceQuitYes => 'Evet';

  @override
  String get aiTutorPronounceQuitNo => 'Hayır';

  @override
  String aiTutorPronounceSentenceOf(int current, int total) {
    return 'Cümle $current / $total';
  }

  @override
  String get aiTutorPronounceSummaryTitle => 'Alıştırma tamam';

  @override
  String get aiTutorPronounceSummaryAvg => 'Ortalama skor';

  @override
  String get aiTutorPronounceSummaryWeak => 'Çalışılacak kelimeler';

  @override
  String get aiTutorPronounceSaveClose => 'Kaydet ve kapat';

  @override
  String get aiTutorPronounceSaving => 'Kaydediliyor…';

  @override
  String get aiTutorChipPronounce => 'Telaffuz';

  @override
  String aiTutorPlanPronunciation(int count, int completed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Telaffuz alıştırmaları ($completed/$count)',
      one: 'Telaffuz alıştırması ($completed/1)',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorPronounceStartHeadline => 'Nasıl pratik yapmak istersin?';

  @override
  String get aiTutorPronounceStartSubhead => '5 cümlelik bir alıştırma başlatmak için birini seç.';

  @override
  String get aiTutorPronounceStartAITitle => 'AI cümle üretir';

  @override
  String get aiTutorPronounceStartAISubtitle => 'Seviyene göre, zor kelimelere ağırlık';

  @override
  String get aiTutorPronounceStartCustomTitle => 'Kendi cümleni kullan';

  @override
  String get aiTutorPronounceStartCustomSubtitle => 'Ustalaşmak istediğin bir cümle yaz ya da yapıştır';

  @override
  String aiTutorQuotaRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugün $count kaldı',
      one: 'Bugün 1 kaldı',
    );
    return '$_temp0';
  }

  @override
  String get submit => 'Gönder';

  @override
  String get exit => 'Çık';

  @override
  String get previous => 'Önceki';

  @override
  String get aiDailyPracticeTitle => 'Günlük pratik';

  @override
  String get aiDailyPracticeTranslateThis => 'Bunu çevir:';

  @override
  String get aiDailyPracticeSuggested => 'Önerilen:';

  @override
  String get aiDailyPracticeHint => 'Çevirin';

  @override
  String get aiLanguagesLoading => 'Diller hâlâ yükleniyor...';

  @override
  String get aiCopiedToClipboard => 'Panoya kopyalandı';

  @override
  String get aiGrammarHint => 'Analiz için metin girin...';

  @override
  String get aiGrammarSectionOriginal => 'Orijinal metin';

  @override
  String get aiGrammarSectionCorrected => 'Düzeltilmiş metin';

  @override
  String aiGrammarSectionIssues(int count) {
    return 'Bulunan sorunlar ($count)';
  }

  @override
  String get aiGrammarSectionWell => 'İyi yaptıkların';

  @override
  String get aiGrammarSectionSuggestions => 'Öneriler';

  @override
  String get aiGrammarSectionSummary => 'Özet';

  @override
  String get aiLessonBuilderLabelLanguage => 'Dil';

  @override
  String get aiLessonBuilderLabelLevel => 'Seviye';

  @override
  String get aiLessonBuilderTopicHint => 'Bir konu gir (örn. \"Yemek ve Restoranlar\")';

  @override
  String aiLessonBuilderSaved(String title) {
    return '\"$title\" dersi kaydedildi!';
  }

  @override
  String get aiLessonBuilderBackToLessons => 'Derslere dön';

  @override
  String get aiTranslationHint => 'Çevrilecek metin girin...';

  @override
  String get aiTranslationSavedToVocab => 'Kelime listene kaydedildi';

  @override
  String aiTranslationCouldNotSave(String error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String get aiQuizTitle => 'Test';

  @override
  String get aiQuizFailedToGenerate => 'Test oluşturulamadı';

  @override
  String get aiQuizSubmitTitle => 'Testi gönder?';

  @override
  String get aiQuizSubmitBody => 'Cevaplarını göndermek istediğine emin misin?';

  @override
  String get aiQuizExitTitle => 'Testten çık?';

  @override
  String get aiQuizExitBody => 'İlerlemen kaybolacak.';

  @override
  String get aiQuizAnswerHint => 'Cevabını yaz...';

  @override
  String get aiQuizTranslationHint => 'Çevirini yaz...';

  @override
  String get aiPronunciationPlayingAudio => 'Ses oynatılıyor...';

  @override
  String get aiPronunciationListenFirst => 'Önce dinle';

  @override
  String get aiPronunciationHint => 'Pratik için metin girin...';

  @override
  String aiTutorCouldNotLoad(String error) {
    return 'Öğretmen yüklenemedi: $error';
  }

  @override
  String aiTutorPlanUnavailable(String error) {
    return 'Plan kullanılamıyor: $error';
  }

  @override
  String get aiTutorReplay => 'Tekrar oynat';

  @override
  String get aiScenariosTitle => 'Pratik senaryoları';

  @override
  String aiScenariosCouldNotLoad(String error) {
    return 'Senaryolar yüklenemedi: $error';
  }

  @override
  String get aiScenariosNoneAvailable => 'Henüz senaryo yok.';

  @override
  String aiScenariosCouldNotStart(String error) {
    return 'Başlatılamadı: $error';
  }

  @override
  String aiScenariosForYourLevel(String level) {
    return 'Senin seviyen için ($level)';
  }

  @override
  String get aiScenariosEasier => 'Daha kolay — ısınma';

  @override
  String get aiScenariosHarder => 'Daha zor — zorluk';

  @override
  String get aiRoleplayStillStarting => 'Senaryo hâlâ başlıyor — biraz sonra tekrar dene.';

  @override
  String aiRoleplaySendFailed(String error) {
    return 'Gönderim başarısız: $error';
  }

  @override
  String get aiRoleplayCouldNotGrade => 'Bu kez puanlanamadı — bir dahaki sefere dene.';

  @override
  String get aiConversationHistoryCompleted => 'Tamamlandı';

  @override
  String get aiConversationHistoryInProgress => 'Devam ediyor';

  @override
  String get aiConversationMessageHint => 'Bir mesaj yaz...';

  @override
  String get aiConversationTopicSpeak => 'Konuştuğum dil';

  @override
  String get aiConversationTopicPractice => 'Pratik';

  @override
  String aiToolsVipUpgradeDescription(String feature) {
    return '$feature açmak için VIP\'e geç!';
  }

  @override
  String get aiToolsVipBadge => 'VIP';

  @override
  String aiScenariosBannerPracticingIn(String language) {
    return '$language pratiği';
  }

  @override
  String get aiScenariosBannerSubhead => 'Seviyene uygun bir senaryo seç ya da bir üst seviye dene.';

  @override
  String get chatListSearchHint => 'Ara veya @kullanıcı_adı yaz';

  @override
  String get chatListFilterAll => 'Tümü';

  @override
  String get chatListFilterUnread => 'Okunmamış';

  @override
  String get chatListFilterOnline => 'Çevrimiçi';

  @override
  String get chatListNewChat => 'Yeni sohbet';

  @override
  String get chatListNewChatByUsernameTooltip => 'Kullanıcı adı ile yeni sohbet';

  @override
  String get chatListFindUser => 'Kullanıcı bul';

  @override
  String chatListFindUserSearchTerm(String term) {
    return '@$term bul';
  }

  @override
  String get chatListDeleteConversation => 'Sohbeti sil';

  @override
  String chatListMediaTitle(String name) {
    return '$name ile medya';
  }

  @override
  String get chatListMediaError => 'Medya yüklenirken hata';

  @override
  String get chatDetailViewFullProfile => 'Profili tam görüntüle';

  @override
  String get chatMessageReply => 'Yanıtla';

  @override
  String get chatMessageCopy => 'Kopyala';

  @override
  String get chatMessageCorrect => 'Düzelt';

  @override
  String get chatMessageTranslate => 'Çevir';

  @override
  String get chatMessageSavePhrase => 'İfadeyi kaydet';

  @override
  String get chatMessageEdit => 'Düzenle';

  @override
  String get chatMessageDelete => 'Sil';

  @override
  String get chatMessageRetrySubtitle => 'Bu mesajı tekrar göndermeyi dene';

  @override
  String get chatMessageRemoveSubtitle => 'Bu mesajı kaldır';

  @override
  String get chatWallpaperPreviewHello => 'Merhaba! 👋';

  @override
  String get chatWallpaperPreviewHow => 'Nasılsın?';

  @override
  String get chatGifSearchHint => 'GIF ara...';

  @override
  String get communitySearchHint => 'Ara veya @kullanıcı_adı yaz';

  @override
  String communityUserNotFound(String name) {
    return '@$name bulunamadı';
  }

  @override
  String get communityTabAll => 'Tümü';

  @override
  String get communityTabGender => 'Cinsiyet';

  @override
  String get communityTabCity => 'Şehir';

  @override
  String get communityRefresh => 'Yenile';

  @override
  String get communityNoUsersFound => 'Kullanıcı bulunamadı';

  @override
  String communityUnblockConfirm(String name) {
    return '$name adlı kişinin engelini kaldırmak istediğine emin misin?';
  }

  @override
  String get communityUsernameCopied => 'Kullanıcı adı kopyalandı!';

  @override
  String communityLocationDetected(String country) {
    return 'Konum: $country';
  }

  @override
  String get communityWaveLater => 'Daha sonra';

  @override
  String get communityAboutMBTI => 'MBTI';

  @override
  String get voiceRoomReactTooltip => 'Tepki ver';

  @override
  String get momentsCancel => 'İptal';

  @override
  String get momentsNotNow => 'Şimdi değil';

  @override
  String get commonOK => 'Tamam';

  @override
  String commonError(String error) {
    return 'Hata: $error';
  }

  @override
  String get chatActiveJustNow => 'Şimdi aktif';

  @override
  String chatActiveMinAgo(int min) {
    return '$min dk önce aktif';
  }

  @override
  String get chatActiveHourAgo => '1 saat önce aktif';

  @override
  String chatActiveHoursAgo(int hours) {
    return '$hours saat önce aktif';
  }

  @override
  String get chatActiveYesterday => 'Dün aktif';

  @override
  String chatActiveDaysAgo(int days) {
    return '$days gün önce aktif';
  }

  @override
  String get chatSayHiPrompt => 'Selam ver ve sohbet başlat!';

  @override
  String get communityConversationStartersTitle => 'Sohbet başlatıcıları';

  @override
  String communityConversationStartersTopic(String topic) {
    return 'İkiniz de $topic seviyorsunuz — favorisini sor!';
  }

  @override
  String get communityConversationStartersDefault => 'Selam ver ve kendini tanıt!';

  @override
  String get communityConversationChatAction => 'Sohbet';

  @override
  String get communityConversationMessageCopied => 'Mesaj kopyalandı! Göndermek için yapıştır.';

  @override
  String get communityConversationCopiedToast => 'Kopyalandı!';

  @override
  String get communityLanguageMatchTitle => 'Dil eşleşmesi';

  @override
  String get communityLanguageMatchNative => 'Anadil';

  @override
  String get communityLanguageMatchLearning => 'Öğrenilen';

  @override
  String get communityLanguageMatchPerfect => 'Mükemmel dil değişimi eşleşmesi!';

  @override
  String get communityLanguageMatchSameNative => 'Aynı anadili paylaşıyorsunuz';

  @override
  String get momentsFilterApply => 'Uygula';

  @override
  String get momentsCreateAddTo => 'Anına ekle';

  @override
  String get momentsCreateCategory => 'Kategori';

  @override
  String get momentsCreateLanguage => 'Dil';

  @override
  String get momentsCreateSchedule => 'Zamanla (isteğe bağlı)';

  @override
  String get momentsCreateScheduleForLater => 'Sonraya zamanla';

  @override
  String get momentsPrivacyPublic => 'Herkese açık';

  @override
  String get momentsPrivacyFriends => 'Arkadaşlar';

  @override
  String get momentsPrivacyPrivate => 'Özel';

  @override
  String get splashTagline => 'Öğren · Sohbet et · Tanış';

  @override
  String get splashLoading => 'Yükleniyor…';

  @override
  String get supportSheetGreeting => 'Merhaba, ben Firdavs 👋';

  @override
  String get supportSheetStory => 'Bananatalk\'ı tamamen tek başıma inşa ettim — her ekran, her özellik, her gece geç saatlerde yapılan hata düzeltmesi. Amacım dünyanın dört bir yanındaki dil öğrenenlerinin bağlantı kurmasına ve gelişmesine yardımcı olmak ve bunu gerçekleştirmek için sürekli yeni özellikler ekliyorum.\n\nBananatalk sana herhangi bir şekilde yardımcı olduysa, küçük bir kahve bile beni inşa etmeye devam etmem için motive ediyor. Her katkı, tek başına çalışan bir geliştirici için çok şey ifade ediyor. 🙏';

  @override
  String get supportSheetDonateButton => 'PayPal ile bağış yapın';

  @override
  String get supportSheetWatchAd => 'Destek için reklam izle';

  @override
  String get occupation => 'Meslek';

  @override
  String get school => 'Okul / Üniversite';

  @override
  String get occupationSearchHint => 'Meslek ara';

  @override
  String get occupationSelectedLabel => 'Seçildi';

  @override
  String get occupationCustomLabel => 'Özel seçim';

  @override
  String get occupationNoMatches => 'Listede eşleşme yok';

  @override
  String get occupationCatTech => 'Teknoloji ve yazılım';

  @override
  String get occupationCatHealthcare => 'Sağlık ve tıp';

  @override
  String get occupationCatEducation => 'Eğitim ve akademi';

  @override
  String get occupationCatBusiness => 'İş ve finans';

  @override
  String get occupationCatCreative => 'Yaratıcı ve tasarım';

  @override
  String get occupationCatMedia => 'Medya ve iletişim';

  @override
  String get occupationCatEngineering => 'Mühendislik';

  @override
  String get occupationCatScience => 'Bilim ve araştırma';

  @override
  String get occupationCatLegal => 'Hukuk';

  @override
  String get occupationCatHospitality => 'Otelcilik ve yiyecek hizmeti';

  @override
  String get occupationCatTrades => 'Nitelikli zanaat';

  @override
  String get occupationCatTransport => 'Ulaşım ve lojistik';

  @override
  String get occupationCatGovernment => 'Kamu ve devlet hizmeti';

  @override
  String get occupationCatRetail => 'Perakende ve müşteri hizmetleri';

  @override
  String get occupationCatAgriculture => 'Tarım ve çevre';

  @override
  String get occupationCatSports => 'Spor ve fitness';

  @override
  String get occupationCatBeauty => 'Güzellik ve kişisel bakım';

  @override
  String get occupationCatRealEstate => 'Gayrimenkul ve inşaat';

  @override
  String get occupationCatReligion => 'Din ve maneviyat';

  @override
  String get occupationCatStudent => 'Öğrenci';

  @override
  String get occupationCatOther => 'Diğer';

  @override
  String get schoolHint => 'örn. Boğaziçi Üniversitesi, Galatasaray Lisesi';

  @override
  String get birthdate => 'Doğum tarihi';

  @override
  String get birthdateSelectHelp => 'Doğum tarihini seç';

  @override
  String get birthdateSelectPlaceholder => 'Tarih seç';

  @override
  String birthdateMinAgeError(int age) {
    return 'En az $age yaşında olmalısın.';
  }

  @override
  String birthdateQuotaRemaining(int remaining, int max) {
    return 'Önümüzdeki 60 gün için $max doğum tarihi değişikliğinden $remaining tanesi kaldı.';
  }

  @override
  String birthdateQuotaLocked(int max) {
    return 'Bu 60 günlük dönemde $max doğum tarihi değişikliğinin tamamını kullandın.';
  }

  @override
  String birthdateNextChangeOn(String date) {
    return 'Sonraki değişiklik $date tarihinde kullanılabilir.';
  }

  @override
  String get birthdateRateLimited => 'Doğum tarihi 60 günde en fazla 3 kez değiştirilebilir.';

  @override
  String birthdateRateLimitedUntil(String date) {
    return 'Doğum tarihi 60 günde en fazla 3 kez değiştirilebilir. $date tarihinde tekrar dene.';
  }

  @override
  String get changePassword => 'Şifreyi değiştir';

  @override
  String get currentPassword => 'Mevcut şifre';

  @override
  String get newPasswordLabel => 'Yeni şifre';

  @override
  String get confirmNewPassword => 'Yeni şifreyi onayla';

  @override
  String get currentPasswordHint => 'Mevcut şifrenizi girin';

  @override
  String get newPasswordHint => 'En az 8 karakter, A-Z, a-z, 0-9';

  @override
  String get passwordsDontMatch => 'Şifreler eşleşmiyor.';

  @override
  String get newPasswordSameAsCurrent => 'Yeni şifre mevcut şifreden farklı olmalı.';

  @override
  String get passwordChangedSuccess => 'Şifre başarıyla değiştirildi';

  @override
  String get passwordRule8Chars => 'En az 8 karakter';

  @override
  String get passwordRuleLowercase => 'Bir küçük harf';

  @override
  String get passwordRuleUppercase => 'Bir büyük harf';

  @override
  String get passwordRuleNumber => 'Bir rakam';

  @override
  String get settingsAccountSection => 'Hesap';

  @override
  String get changePasswordTileSubtitle => 'Hesabının şifresini güncelle';

  @override
  String get occupationCustomTab => 'Özel';

  @override
  String get occupationCustomTabHint => 'Mesleğini bulamadın mı? Buraya yaz.';

  @override
  String get occupationCustomInputHint => 'örn. Deniz biyoloğu, Seslendirme sanatçısı';

  @override
  String get occupationCustomSaveCTA => 'Bunu mesleğim olarak kullan';

  @override
  String get vipSelectPlan => 'Plan seç';

  @override
  String get vipBenefits => 'Avantajlar';

  @override
  String get vipBestValue => 'EN AVANTAJLI';

  @override
  String get vipPlanMonth => '1 Ay';

  @override
  String get vipPlanThreeMonths => '3 Ay';

  @override
  String get vipPlanTwelveMonths => '12 Ay';

  @override
  String get vipOneTime => 'Tek seferlik';

  @override
  String get vipNonVip => 'VIP değil';

  @override
  String get vipBenefitDailyTranslations => 'Günlük çeviriler';

  @override
  String get vipBenefitTranslationsLimit => '5 / gün';

  @override
  String get vipBenefitUnlimited => 'Sınırsız';

  @override
  String get vipBenefitAdvancedFilters => 'Gelişmiş filtreler';

  @override
  String get vipBenefitAdFree => 'Reklamsız deneyim';

  @override
  String get vipBenefitVipBadge => 'Profilde VIP rozeti';

  @override
  String get vipBenefitPrioritySupport => 'Öncelikli destek';

  @override
  String get vipBrandTitle => 'BananaTalk VIP';

  @override
  String get vipTagline => 'Küresel bağlantıların pasaportu — gerçek sohbetler, kalıcı dostluklar.';

  @override
  String get vipDisclosure => 'Dönem sona ermeden 24 saat önce iptal edilmezse otomatik yenilenir. Ödeme, iTunes veya Google Play hesabınıza yansıtılır.';

  @override
  String get vipLoginRequired => 'Devam etmek için lütfen giriş yapın';

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
    return '%$pct tasarruf';
  }

  @override
  String vipPerMonth(String price) {
    return '$price / ay';
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
  String get vipPaymentPlanSummary => 'Plan özeti';

  @override
  String get vipPaymentSelectMethod => 'Ödeme yöntemi seç';

  @override
  String get vipPaymentPurchaseAppStore => 'App Store üzerinden satın al';

  @override
  String get vipPaymentPurchaseGooglePlay => 'Google Play üzerinden satın al';

  @override
  String get vipPaymentSecureAppStore => 'Satın alma işleminiz App Store üzerinden güvenli şekilde yapılacaktır.';

  @override
  String get vipPaymentSecureGooglePlay => 'Satın alma işleminiz Google Play üzerinden güvenli şekilde yapılacaktır.';

  @override
  String get vipPaymentSubscriptionInfo => 'Abonelik bilgileri';

  @override
  String get vipPaymentInfoLabelTitle => 'Başlık';

  @override
  String get vipPaymentInfoLabelLength => 'Süre';

  @override
  String get vipPaymentInfoLabelPrice => 'Fiyat';

  @override
  String get vipPaymentDisclosure => 'Bu satın alma işlemini tamamlayarak Kullanım Koşullarımızı ve Gizlilik Politikamızı kabul etmiş olursunuz. Aboneliğiniz, mevcut dönem sona ermeden en az 24 saat önce iptal edilmediği sürece otomatik olarak yenilenir.';

  @override
  String get vipSuccessTitle => 'VIP’e hoş geldiniz!';

  @override
  String get vipSuccessBody => 'VIP aboneliğiniz artık aktif. Tüm premium özelliklerin tadını çıkarın!';

  @override
  String get vipPendingTitle => 'Az kaldı';

  @override
  String get vipPendingBody => 'Aboneliğiniz işleniyor — lütfen bir dakika sonra yenileyin.';

  @override
  String get vipErrorPaymentTitle => 'Ödeme hatası';

  @override
  String get vipErrorPurchaseTitle => 'Satın alma hatası';

  @override
  String get vipErrorVerifyTitle => 'Satın alma doğrulanamadı';

  @override
  String get vipErrorPaymentFailed => 'Ödeme başarısız';

  @override
  String get vipErrorBodyPrefix => 'Ödemeniz işlenirken bir hata oluştu:';

  @override
  String get vipErrorPurchaseCanceled => 'Satın alma iptal edildi veya başarısız oldu. Lütfen tekrar deneyin.';

  @override
  String get vipErrorVerifyServer => 'Satın alma sunucu tarafında doğrulanamadı. Lütfen destek ile iletişime geçin.';

  @override
  String get vipPlanLengthOneMonth => '1 ay';

  @override
  String get vipPlanLengthThreeMonths => '3 ay';

  @override
  String get vipPlanLengthOneYear => '1 yıl';

  @override
  String vipPaymentPayPrice(String price) {
    return '$price öde';
  }

  @override
  String get vipExpired => 'VIP süresi doldu';

  @override
  String get vipMember => 'VIP üye';

  @override
  String get chatPhrasesMostUsed => 'Sık Kullanılan';

  @override
  String get chatPhrasesTopics => 'Konular';

  @override
  String get chatPhrasesAddPhrase => 'Cümle ekle';

  @override
  String get chatPhrasesChange => 'Değiştir';

  @override
  String get chatPhrasesAddTitle => 'Cümle ekle';

  @override
  String get chatPhrasesAddHint => 'Sık kullandığın bir cümle yaz';

  @override
  String get chatPhrasesEmptyMostUsed => 'Henüz kayıtlı cümle yok. Eklemek için + simgesine dokun.';

  @override
  String get chatPhrasesDeleteTitle => 'Bu cümle silinsin mi?';

  @override
  String get filterVipPromoTitle => 'Sana en uygun kişiyi daha hızlı bul';

  @override
  String get filterVipPromoSubtitle => 'VIP ile öncelikli keşif, gelişmiş filtreler ve reklamsız sohbetler.';

  @override
  String get filterVipPromoCta => 'VIP ol';

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
}
