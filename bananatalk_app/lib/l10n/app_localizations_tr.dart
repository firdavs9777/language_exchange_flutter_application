// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'BananaTalk';

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
  String get aboutBanaTalk => 'BanaTalk Hakkında';

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
  String get banaTalk => 'BanaTalk';

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
  String get goBack => 'Geri Dön';

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
  String get receiveEmailNotificationsFromBananaTalk => 'BananaTalk\'tan e-posta bildirimleri al';

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
  String get exchange3MessagesBeforeCall => 'Bu kullanıcıyı aramadan önce en az 3 mesaj alışverişi yapmanız gerekiyor';

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
  String get addToHighlight => 'Öne Çıkanlara Ekle';

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
  String get deleteHighlight => 'Öne çıkan silinsin mi?';

  @override
  String get editHighlight => 'Öne Çıkanı Düzenle';

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
  String get searchUsers => 'Kullanıcıları ara...';

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
  String get addSticker => 'Çıkartma Ekle';

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
  String get checkOutStory => 'BananaTalk\'taki bu hikayeye göz at!';

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
  String get receiveEmailNotifications => 'BananaTalk\'tan e-posta bildirimleri al';

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
  String get videoMustBeUnder1GB => 'Video 1GB\'dan küçük olmalıdır.';

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
  String checkOutMoment(String title) {
    return 'Bu anıya göz at: $title';
  }

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
  String get newUsersOnly => 'Yalnızca yeni kullanıcılar';

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
  String get searchCountry => 'Ülke ara';

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
  String get maximum6Photos => 'Maksimum 6 fotoğraf';

  @override
  String get tapToDetectLocation => 'Konumu algılamak için dokunun';

  @override
  String get optionalHelpsNearbyPartners => 'İsteğe bağlı - yakındaki partnerleri bulmaya yardımcı olur';

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
  String get confirmPasswordHint => 'Şifreyi onayla';

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
  String get you => 'You';

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
}
