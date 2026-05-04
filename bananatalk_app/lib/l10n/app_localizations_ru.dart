// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'BananaTalk';

  @override
  String get login => 'Войти';

  @override
  String get signUp => 'Регистрация';

  @override
  String get email => 'Электронная почта';

  @override
  String get password => 'Пароль';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get or => 'ИЛИ';

  @override
  String get more => 'ещё';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String get signInWithApple => 'Войти через Apple';

  @override
  String get signInWithFacebook => 'Войти через Facebook';

  @override
  String get welcome => 'Добро пожаловать';

  @override
  String get home => 'Главная';

  @override
  String get messages => 'Сообщения';

  @override
  String get moments => 'Моменты';

  @override
  String get overview => 'Обзор';

  @override
  String get profile => 'Профиль';

  @override
  String get settings => 'Настройки';

  @override
  String get logout => 'Выйти';

  @override
  String get language => 'Язык';

  @override
  String get selectLanguage => 'Выбрать язык';

  @override
  String get autoTranslate => 'Автоматический перевод';

  @override
  String get autoTranslateMessages => 'Автоматически переводить сообщения';

  @override
  String get autoTranslateMoments => 'Автоматически переводить моменты';

  @override
  String get autoTranslateComments => 'Автоматически переводить комментарии';

  @override
  String get translate => 'Перевести';

  @override
  String get translated => 'Переведено';

  @override
  String get showOriginal => 'Показать оригинал';

  @override
  String get showTranslation => 'Показать перевод';

  @override
  String get translating => 'Перевод...';

  @override
  String get translationFailed => 'Ошибка перевода';

  @override
  String get noTranslationAvailable => 'Перевод недоступен';

  @override
  String translatedFrom(String language) {
    return 'Переведено с $language';
  }

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Редактировать';

  @override
  String get share => 'Поделиться';

  @override
  String get like => 'Нравится';

  @override
  String get comment => 'Комментарий';

  @override
  String get send => 'Отправить';

  @override
  String get search => 'Поиск';

  @override
  String get notifications => 'Уведомления';

  @override
  String get followers => 'Подписчики';

  @override
  String get following => 'Подписки';

  @override
  String get posts => 'Публикации';

  @override
  String get visitors => 'Посетители';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get success => 'Успешно';

  @override
  String get tryAgain => 'Повторить';

  @override
  String get networkError => 'Ошибка сети. Проверьте подключение.';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get ok => 'ОК';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get languageSettings => 'Настройки языка';

  @override
  String get deviceLanguage => 'Язык устройства';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return 'Ваше устройство настроено на: $flag $name';
  }

  @override
  String get youCanOverride => 'Вы можете переопределить язык устройства ниже.';

  @override
  String languageChangedTo(String name) {
    return 'Язык изменен на $name';
  }

  @override
  String get errorChangingLanguage => 'Ошибка при изменении языка';

  @override
  String get autoTranslateSettings => 'Настройки автоматического перевода';

  @override
  String get automaticallyTranslateIncomingMessages => 'Автоматически переводить входящие сообщения';

  @override
  String get automaticallyTranslateMomentsInFeed => 'Автоматически переводить моменты в ленте';

  @override
  String get automaticallyTranslateComments => 'Автоматически переводить комментарии';

  @override
  String get translationServiceBeingConfigured => 'Служба перевода настраивается. Пожалуйста, попробуйте позже.';

  @override
  String get translationUnavailable => 'Перевод недоступен';

  @override
  String get showLess => 'показать меньше';

  @override
  String get showMore => 'показать больше';

  @override
  String get comments => 'Комментарии';

  @override
  String get beTheFirstToComment => 'Станьте первым, кто оставит комментарий.';

  @override
  String get writeAComment => 'Написать комментарий...';

  @override
  String get report => 'Пожаловаться';

  @override
  String get reportMoment => 'Пожаловаться на момент';

  @override
  String get reportUser => 'Пожаловаться на пользователя';

  @override
  String get deleteMoment => 'Удалить момент?';

  @override
  String get thisActionCannotBeUndone => 'Это действие нельзя отменить.';

  @override
  String get momentDeleted => 'Момент удален';

  @override
  String get deleteComment => 'Delete Comment?';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get editFeatureComingSoon => 'Функция редактирования скоро появится';

  @override
  String get userNotFound => 'Пользователь не найден';

  @override
  String get cannotReportYourOwnComment => 'Нельзя пожаловаться на свой комментарий';

  @override
  String get profileSettings => 'Настройки профиля';

  @override
  String get editYourProfileInformation => 'Редактировать информацию профиля';

  @override
  String get blockedUsers => 'Заблокированные';

  @override
  String get manageBlockedUsers => 'Управление заблокированными пользователями';

  @override
  String get manageNotificationSettings => 'Управление настройками уведомлений';

  @override
  String get privacySecurity => 'Конфиденциальность и безопасность';

  @override
  String get controlYourPrivacy => 'Контроль конфиденциальности';

  @override
  String get changeAppLanguage => 'Изменить язык приложения';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get themeAndDisplaySettings => 'Настройки темы и отображения';

  @override
  String get clearCache => 'Очистить кэш';

  @override
  String get clearCacheSubtitle => 'Освободить место в хранилище';

  @override
  String get clearCacheDescription => 'Это удалит все кэшированные изображения, видео и аудиофайлы. Приложение может временно загружать контент медленнее, пока повторно загружает медиафайлы.';

  @override
  String get clearCacheHint => 'Используйте это, если изображения или аудио не загружаются правильно.';

  @override
  String get clearingCache => 'Очистка кэша...';

  @override
  String get cacheCleared => 'Кэш успешно очищен! Изображения будут загружены заново.';

  @override
  String get clearCacheFailed => 'Не удалось очистить кэш';

  @override
  String get myReports => 'Мои жалобы';

  @override
  String get viewYourSubmittedReports => 'Просмотр отправленных жалоб';

  @override
  String get reportsManagement => 'Управление жалобами';

  @override
  String get manageAllReportsAdmin => 'Управление всеми жалобами (Администратор)';

  @override
  String get legalPrivacy => 'Юридическая информация и конфиденциальность';

  @override
  String get termsPrivacySubscriptionInfo => 'Условия, конфиденциальность и информация о подписке';

  @override
  String get helpCenter => 'Центр помощи';

  @override
  String get getHelpAndSupport => 'Получить помощь и поддержку';

  @override
  String get aboutBanaTalk => 'О BanaTalk';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get permanentlyDeleteYourAccount => 'Навсегда удалить ваш аккаунт';

  @override
  String get loggedOutSuccessfully => 'Успешно вышли из системы';

  @override
  String get retry => 'Повторить';

  @override
  String get giftsLikes => 'Подарки/Лайки';

  @override
  String get details => 'Детали';

  @override
  String get to => 'на';

  @override
  String get banaTalk => 'BanaTalk';

  @override
  String get chats => 'Чаты';

  @override
  String get community => 'Сообщество';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String yearsOld(String age) {
    return '$age лет';
  }

  @override
  String get searchConversations => 'Поиск разговоров...';

  @override
  String get visitorTrackingNotAvailable => 'Функция отслеживания посетителей пока недоступна. Требуется обновление сервера.';

  @override
  String get chatList => 'Список чатов';

  @override
  String get languageExchange => 'Языковой обмен';

  @override
  String get nativeLanguage => 'Родной язык';

  @override
  String get learning => 'Обучение';

  @override
  String get notSet => 'Не установлено';

  @override
  String get about => 'О';

  @override
  String get aboutMe => 'О себе';

  @override
  String get bloodType => 'Blood Type';

  @override
  String get photos => 'Фото';

  @override
  String get camera => 'Камера';

  @override
  String get createMoment => 'Создать момент';

  @override
  String get addATitle => 'Добавить заголовок...';

  @override
  String get whatsOnYourMind => 'О чем вы думаете?';

  @override
  String get addTags => 'Добавить теги';

  @override
  String get done => 'Готово';

  @override
  String get add => 'Добавить';

  @override
  String get enterTag => 'Введите тег';

  @override
  String get post => 'Опубликовать';

  @override
  String get commentAddedSuccessfully => 'Комментарий успешно добавлен';

  @override
  String get clearFilters => 'Очистить фильтры';

  @override
  String get notificationSettings => 'Настройки уведомлений';

  @override
  String get enableNotifications => 'Включить уведомления';

  @override
  String get turnAllNotificationsOnOrOff => 'Включить или выключить все уведомления';

  @override
  String get notificationTypes => 'Типы уведомлений';

  @override
  String get chatMessages => 'Сообщения чата';

  @override
  String get getNotifiedWhenYouReceiveMessages => 'Получать уведомления при получении сообщений';

  @override
  String get likesAndCommentsOnYourMoments => 'Лайки и комментарии к вашим моментам';

  @override
  String get whenPeopleYouFollowPostMoments => 'Когда люди, на которых вы подписаны, публикуют моменты';

  @override
  String get friendRequests => 'Запросы в друзья';

  @override
  String get whenSomeoneFollowsYou => 'Когда кто-то подписывается на вас';

  @override
  String get profileVisits => 'Посещения профиля';

  @override
  String get whenSomeoneViewsYourProfileVIP => 'Когда кто-то просматривает ваш профиль (VIP)';

  @override
  String get marketing => 'Маркетинг';

  @override
  String get updatesAndPromotionalMessages => 'Обновления и рекламные сообщения';

  @override
  String get notificationPreferences => 'Настройки уведомлений';

  @override
  String get sound => 'Звук';

  @override
  String get playNotificationSounds => 'Воспроизводить звуки уведомлений';

  @override
  String get vibration => 'Вибрация';

  @override
  String get vibrateOnNotifications => 'Вибрация при уведомлениях';

  @override
  String get showPreview => 'Показать предпросмотр';

  @override
  String get showMessagePreviewInNotifications => 'Показывать предпросмотр сообщений в уведомлениях';

  @override
  String get mutedConversations => 'Приглушенные разговоры';

  @override
  String get conversation => 'Разговор';

  @override
  String get unmute => 'Включить звук';

  @override
  String get systemNotificationSettings => 'Настройки системных уведомлений';

  @override
  String get manageNotificationsInSystemSettings => 'Управление уведомлениями в системных настройках';

  @override
  String get errorLoadingSettings => 'Ошибка загрузки настроек';

  @override
  String get unblockUser => 'Разблокировать';

  @override
  String get unblock => 'Разблокировать';

  @override
  String get goBack => 'Назад';

  @override
  String get messageSendTimeout => 'Тайм-аут отправки сообщения. Проверьте подключение.';

  @override
  String get failedToSendMessage => 'Не удалось отправить сообщение';

  @override
  String get dailyMessageLimitExceeded => 'Превышен дневной лимит сообщений. Обновитесь до VIP для неограниченных сообщений.';

  @override
  String get cannotSendMessageUserMayBeBlocked => 'Не удалось отправить сообщение. Пользователь может быть заблокирован.';

  @override
  String get sessionExpired => 'Сессия истекла. Войдите снова.';

  @override
  String get sendThisSticker => 'Отправить этот стикер?';

  @override
  String get chooseHowYouWantToDeleteThisMessage => 'Выберите, как вы хотите удалить это сообщение:';

  @override
  String get deleteForEveryone => 'Удалить для всех';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => 'Удаляет сообщение для вас и получателя';

  @override
  String get deleteForMe => 'Удалить для меня';

  @override
  String get removesTheMessageOnlyFromYourChat => 'Удаляет сообщение только из вашего чата';

  @override
  String get copy => 'Копировать';

  @override
  String get reply => 'Ответить';

  @override
  String get forward => 'Переслать';

  @override
  String get moreOptions => 'Больше опций';

  @override
  String get noUsersAvailableToForwardTo => 'Нет пользователей для пересылки';

  @override
  String get searchMoments => 'Поиск моментов...';

  @override
  String searchInChatWith(String name) {
    return 'Поиск в чате с $name';
  }

  @override
  String get typeAMessage => 'Введите сообщение...';

  @override
  String get enterYourMessage => 'Введите ваше сообщение';

  @override
  String get detectYourLocation => 'Определить ваше местоположение';

  @override
  String get tapToUpdateLocation => 'Нажмите, чтобы обновить местоположение';

  @override
  String get helpOthersFindYouNearby => 'Помогите другим найти вас поблизости';

  @override
  String get selectYourNativeLanguage => 'Выберите ваш родной язык';

  @override
  String get whichLanguageDoYouWantToLearn => 'Какой язык вы хотите изучить?';

  @override
  String get selectYourGender => 'Выберите ваш пол';

  @override
  String get addACaption => 'Добавить подпись...';

  @override
  String get typeSomething => 'Введите что-нибудь...';

  @override
  String get gallery => 'Галерея';

  @override
  String get video => 'Видео';

  @override
  String get text => 'Текст';

  @override
  String get provideMoreInformation => 'Предоставить дополнительную информацию...';

  @override
  String get searchByNameLanguageOrInterests => 'Поиск по имени, языку или интересам...';

  @override
  String get addTagAndPressEnter => 'Добавьте тег и нажмите Enter';

  @override
  String replyTo(String name) {
    return 'Ответить $name...';
  }

  @override
  String get highlightName => 'Название выделения';

  @override
  String get searchCloseFriends => 'Поиск близких друзей...';

  @override
  String get askAQuestion => 'Задать вопрос...';

  @override
  String option(String number) {
    return 'Вариант $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return 'Почему вы сообщаете об этом $type?';
  }

  @override
  String get additionalDetailsOptional => 'Дополнительные детали (необязательно)';

  @override
  String get warningThisActionIsPermanent => 'Предупреждение: это действие необратимо!';

  @override
  String get deletingYourAccountWillPermanentlyRemove => 'Удаление вашего аккаунта навсегда удалит:\n\n• Ваш профиль и все личные данные\n• Все ваши сообщения и разговоры\n• Все ваши моменты и истории\n• Вашу VIP подписку (без возврата средств)\n• Все ваши связи и подписчиков\n\nЭто действие нельзя отменить.';

  @override
  String get clearAllNotifications => 'Очистить все уведомления?';

  @override
  String get clearAll => 'Очистить все';

  @override
  String get notificationDebug => 'Отладка уведомлений';

  @override
  String get markAllRead => 'Отметить все как прочитанные';

  @override
  String get clearAll2 => 'Очистить все';

  @override
  String get emailAddress => 'Адрес электронной почты';

  @override
  String get username => 'Имя пользователя';

  @override
  String get alreadyHaveAnAccount => 'Уже есть аккаунт?';

  @override
  String get login2 => 'Войти';

  @override
  String get selectYourNativeLanguage2 => 'Выберите ваш родной язык';

  @override
  String get whichLanguageDoYouWantToLearn2 => 'Какой язык вы хотите изучить?';

  @override
  String get selectYourGender2 => 'Выберите ваш пол';

  @override
  String get dateFormat => 'YYYY.MM.DD';

  @override
  String get detectYourLocation2 => 'Определить ваше местоположение';

  @override
  String get tapToUpdateLocation2 => 'Нажмите, чтобы обновить местоположение';

  @override
  String get helpOthersFindYouNearby2 => 'Помогите другим найти вас поблизости';

  @override
  String get couldNotOpenLink => 'Не удалось открыть ссылку';

  @override
  String get legalPrivacy2 => 'Юридическая информация и конфиденциальность';

  @override
  String get termsOfUseEULA => 'Условия использования (EULA)';

  @override
  String get viewOurTermsAndConditions => 'Просмотреть наши условия';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get howWeHandleYourData => 'Как мы обрабатываем ваши данные';

  @override
  String get emailNotifications => 'Уведомления по электронной почте';

  @override
  String get receiveEmailNotificationsFromBananaTalk => 'Получать уведомления по электронной почте от BananaTalk';

  @override
  String get weeklySummary => 'Еженедельная сводка';

  @override
  String get activityRecapEverySunday => 'Сводка активности каждое воскресенье';

  @override
  String get newMessages => 'Новые сообщения';

  @override
  String get whenYoureAwayFor24PlusHours => 'Когда вы отсутствуете 24+ часов';

  @override
  String get newFollowers => 'Новые подписчики';

  @override
  String get whenSomeoneFollowsYou2 => 'Когда кто-то подписывается на вас';

  @override
  String get securityAlerts => 'Оповещения безопасности';

  @override
  String get passwordLoginAlerts => 'Оповещения о пароле и входе';

  @override
  String get unblockUser2 => 'Разблокировать пользователя';

  @override
  String get blockedUsers2 => 'Заблокированные пользователи';

  @override
  String get finalWarning => '⚠️ Финальное предупреждение';

  @override
  String get deleteForever => 'Удалить навсегда';

  @override
  String get deleteAccount2 => 'Удалить аккаунт';

  @override
  String get enterYourPassword => 'Введите пароль';

  @override
  String get yourPassword => 'Ваш пароль';

  @override
  String get typeDELETEToConfirm => 'Введите DELETE для подтверждения';

  @override
  String get typeDELETEInCapitalLetters => 'Введите DELETE заглавными буквами';

  @override
  String sent(String emoji) {
    return 'Отправлено!';
  }

  @override
  String get replySent => 'Ответ отправлен!';

  @override
  String get deleteStory => 'Удалить историю?';

  @override
  String get thisStoryWillBeRemovedPermanently => 'Эта история будет удалена навсегда.';

  @override
  String get noStories => 'Нет историй';

  @override
  String views(String count) {
    return '$count просмотров';
  }

  @override
  String get reportStory => 'Сообщить об истории';

  @override
  String get reply2 => 'Ответить...';

  @override
  String get failedToPickImage => 'Не удалось выбрать изображение';

  @override
  String get failedToTakePhoto => 'Не удалось сделать фото';

  @override
  String get failedToPickVideo => 'Не удалось выбрать видео';

  @override
  String get pleaseEnterSomeText => 'Пожалуйста, введите текст';

  @override
  String get pleaseSelectMedia => 'Пожалуйста, выберите медиа';

  @override
  String get storyPosted => 'История опубликована!';

  @override
  String get textOnlyStoriesRequireAnImage => 'Текстовые истории требуют изображения';

  @override
  String get createStory => 'Создать историю';

  @override
  String get change => 'Изменить';

  @override
  String get userIdNotFound => 'ID пользователя не найден. Пожалуйста, войдите снова.';

  @override
  String get pleaseSelectAPaymentMethod => 'Пожалуйста, выберите способ оплаты';

  @override
  String get startExploring => 'Начать изучение';

  @override
  String get close => 'Закрыть';

  @override
  String get payment => 'Оплата';

  @override
  String get upgradeToVIP => 'Обновить до VIP';

  @override
  String get errorLoadingProducts => 'Ошибка загрузки продуктов';

  @override
  String get cancelVIPSubscription => 'Отменить VIP подписку';

  @override
  String get keepVIP => 'Оставить VIP';

  @override
  String get cancelSubscription => 'Отменить подписку';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'VIP подписка успешно отменена';

  @override
  String get vipStatus => 'Статус VIP';

  @override
  String get noActiveVIPSubscription => 'Нет активной VIP подписки';

  @override
  String get subscriptionExpired => 'Подписка истекла';

  @override
  String get vipExpiredMessage => 'Ваша VIP подписка истекла. Продлите сейчас, чтобы продолжить пользоваться безлимитными функциями!';

  @override
  String get expiredOn => 'Истекла';

  @override
  String get renewVIP => 'Продлить VIP';

  @override
  String get whatYoureMissing => 'Что вы упускаете';

  @override
  String get manageInAppStore => 'Управлять в App Store';

  @override
  String get becomeVIP => 'Стать VIP';

  @override
  String get unlimitedMessages => 'Неограниченные сообщения';

  @override
  String get unlimitedProfileViews => 'Неограниченные просмотры профиля';

  @override
  String get prioritySupport => 'Приоритетная поддержка';

  @override
  String get advancedSearch => 'Расширенный поиск';

  @override
  String get profileBoost => 'Усиление профиля';

  @override
  String get adFreeExperience => 'Опыт без рекламы';

  @override
  String get upgradeYourAccount => 'Обновить ваш аккаунт';

  @override
  String get moreMessages => 'Больше сообщений';

  @override
  String get moreProfileViews => 'Больше просмотров профиля';

  @override
  String get connectWithFriends => 'Связаться с друзьями';

  @override
  String get reviewStarted => 'Проверка начата';

  @override
  String get reportResolved => 'Жалоба решена';

  @override
  String get reportDismissed => 'Жалоба отклонена';

  @override
  String get selectAction => 'Выбрать действие';

  @override
  String get noViolation => 'Нет нарушения';

  @override
  String get contentRemoved => 'Контент удален';

  @override
  String get userWarned => 'Пользователь предупрежден';

  @override
  String get userSuspended => 'Пользователь приостановлен';

  @override
  String get userBanned => 'Пользователь заблокирован';

  @override
  String get addNotesOptional => 'Добавить заметки (необязательно)';

  @override
  String get enterModeratorNotes => 'Введите заметки модератора...';

  @override
  String get skip => 'Пропустить';

  @override
  String get startReview => 'Начать проверку';

  @override
  String get resolve => 'Решить';

  @override
  String get dismiss => 'Отклонить';

  @override
  String get filterReports => 'Фильтровать жалобы';

  @override
  String get all => 'Все';

  @override
  String get clear => 'Очистить';

  @override
  String get apply => 'Применить';

  @override
  String get myReports2 => 'Мои жалобы';

  @override
  String get blockUser => 'Заблокировать пользователя';

  @override
  String get block => 'Заблокировать';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => 'Вы также хотите заблокировать этого пользователя?';

  @override
  String get noThanks => 'Нет, спасибо';

  @override
  String get yesBlockThem => 'Да, заблокировать';

  @override
  String get reportUser2 => 'Пожаловаться на пользователя';

  @override
  String get submitReport => 'Отправить жалобу';

  @override
  String get addAQuestionAndAtLeast2Options => 'Добавить вопрос и минимум 2 варианта';

  @override
  String get addOption => 'Добавить вариант';

  @override
  String get anonymousVoting => 'Анонимное голосование';

  @override
  String get create => 'Создать';

  @override
  String get typeYourAnswer => 'Введите ваш ответ...';

  @override
  String get send2 => 'Отправить';

  @override
  String get yourPrompt => 'Ваш запрос...';

  @override
  String get add2 => 'Добавить';

  @override
  String get contentNotAvailable => 'Контент недоступен';

  @override
  String get profileNotAvailable => 'Профиль недоступен';

  @override
  String get noMomentsToShow => 'Нет моментов для отображения';

  @override
  String get storiesNotAvailable => 'Истории недоступны';

  @override
  String get cantMessageThisUser => 'Нельзя отправить сообщение этому пользователю';

  @override
  String get pleaseSelectAReason => 'Пожалуйста, выберите причину';

  @override
  String get reportSubmitted => 'Жалоба отправлена. Спасибо за помощь в поддержании безопасности нашего сообщества.';

  @override
  String get youHaveAlreadyReportedThisMoment => 'Вы уже пожаловались на этот момент';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => 'Расскажите нам больше о том, почему вы жалуетесь на это';

  @override
  String get errorSharing => 'Ошибка при обмене';

  @override
  String get deviceInfo => 'Информация об устройстве';

  @override
  String get recommended => 'Рекомендуемые';

  @override
  String get anyLanguage => 'Любой язык';

  @override
  String get noLanguagesFound => 'Языки не найдены';

  @override
  String get selectALanguage => 'Выберите язык';

  @override
  String get languagesAreStillLoading => 'Загрузка языков...';

  @override
  String get selectNativeLanguage => 'Выберите ваш родной язык';

  @override
  String get subscriptionDetails => 'Детали подписки';

  @override
  String get activeFeatures => 'Активные функции';

  @override
  String get legalInformation => 'Юридическая информация';

  @override
  String get termsOfUse => 'Условия использования';

  @override
  String get manageSubscription => 'Управление подпиской';

  @override
  String get manageSubscriptionInSettings => 'Чтобы отменить подписку, перейдите в Настройки > [Ваше имя] > Подписки на вашем устройстве.';

  @override
  String get contactSupportToCancel => 'Чтобы отменить подписку, пожалуйста, свяжитесь с нашей службой поддержки.';

  @override
  String get status => 'Статус';

  @override
  String get active => 'Активно';

  @override
  String get plan => 'План';

  @override
  String get startDate => 'Дата начала';

  @override
  String get endDate => 'Дата окончания';

  @override
  String get nextBillingDate => 'Следующая дата оплаты';

  @override
  String get autoRenew => 'Автопродление';

  @override
  String get pleaseLogInToContinue => 'Пожалуйста, войдите, чтобы продолжить';

  @override
  String get purchaseCanceledOrFailed => 'Покупка была отменена или не удалась. Пожалуйста, попробуйте снова.';

  @override
  String get maximumTagsAllowed => 'Максимум 5 тегов разрешено';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => 'Сначала удалите изображения, чтобы добавить видео';

  @override
  String get unsupportedFormat => 'Неподдерживаемый формат';

  @override
  String get errorProcessingVideo => 'Ошибка обработки видео';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'Сначала удалите изображения, чтобы записать видео';

  @override
  String get locationAdded => 'Местоположение добавлено';

  @override
  String get failedToGetLocation => 'Не удалось получить местоположение';

  @override
  String get notNow => 'Не сейчас';

  @override
  String get videoUploadFailed => 'Ошибка загрузки видео';

  @override
  String get skipVideo => 'Пропустить видео';

  @override
  String get retryUpload => 'Повторить загрузку';

  @override
  String get momentCreatedSuccessfully => 'Момент успешно создан';

  @override
  String get uploadingMomentInBackground => 'Загрузка момента в фоне...';

  @override
  String get failedToQueueUpload => 'Не удалось добавить в очередь загрузки';

  @override
  String get viewProfile => 'Просмотр профиля';

  @override
  String get mediaLinksAndDocs => 'Медиа, ссылки и документы';

  @override
  String get wallpaper => 'Обои';

  @override
  String get userIdNotAvailable => 'ID пользователя недоступен';

  @override
  String get cannotBlockYourself => 'Нельзя заблокировать себя';

  @override
  String get chatWallpaper => 'Обои чата';

  @override
  String get wallpaperSavedLocally => 'Обои сохранены локально';

  @override
  String get messageCopied => 'Сообщение скопировано';

  @override
  String get forwardFeatureComingSoon => 'Функция пересылки скоро появится';

  @override
  String get momentUnsaved => 'Удалено из сохранённых';

  @override
  String get documentPickerComingSoon => 'Выбор документов скоро появится';

  @override
  String get contactSharingComingSoon => 'Обмен контактами скоро появится';

  @override
  String get featureComingSoon => 'Функция скоро появится';

  @override
  String get answerSent => 'Ответ отправлен!';

  @override
  String get noImagesAvailable => 'Нет доступных изображений';

  @override
  String get mentionPickerComingSoon => 'Выбор упоминаний скоро появится';

  @override
  String get musicPickerComingSoon => 'Выбор музыки скоро появится';

  @override
  String get repostFeatureComingSoon => 'Функция репоста скоро появится';

  @override
  String get addFriendsFromYourProfile => 'Добавьте друзей из своего профиля';

  @override
  String get quickReplyAdded => 'Быстрый ответ добавлен';

  @override
  String get quickReplyDeleted => 'Быстрый ответ удален';

  @override
  String get linkCopied => 'Ссылка скопирована!';

  @override
  String get maximumOptionsAllowed => 'Максимум 10 вариантов разрешено';

  @override
  String get minimumOptionsRequired => 'Минимум 2 варианта требуется';

  @override
  String get pleaseEnterAQuestion => 'Пожалуйста, введите вопрос';

  @override
  String get pleaseAddAtLeast2Options => 'Пожалуйста, добавьте минимум 2 варианта';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => 'Пожалуйста, выберите правильный ответ для викторины';

  @override
  String get correctionSent => 'Исправление отправлено!';

  @override
  String get sort => 'Сортировка';

  @override
  String get savedMoments => 'Сохраненные моменты';

  @override
  String get unsave => 'Удалить из сохраненных';

  @override
  String get playingAudio => 'Воспроизведение аудио...';

  @override
  String get failedToGenerateQuiz => 'Не удалось создать викторину';

  @override
  String get failedToAddComment => 'Не удалось добавить комментарий';

  @override
  String get hello => 'Привет!';

  @override
  String get howAreYou => 'Как дела?';

  @override
  String get cannotOpen => 'Невозможно открыть';

  @override
  String get errorOpeningLink => 'Ошибка при открытии ссылки';

  @override
  String get saved => 'Сохранено';

  @override
  String get follow => 'Подписаться';

  @override
  String get unfollow => 'Отписаться';

  @override
  String get mute => 'Отключить звук';

  @override
  String get online => 'Онлайн';

  @override
  String get offline => 'Офлайн';

  @override
  String get lastSeen => 'Был(а) в сети';

  @override
  String get justNow => 'только что';

  @override
  String minutesAgo(String count) {
    return '$count минут назад';
  }

  @override
  String hoursAgo(String count) {
    return '$count часов назад';
  }

  @override
  String get yesterday => 'Вчера';

  @override
  String get signInWithEmail => 'Войти через почту';

  @override
  String get partners => 'Партнёры';

  @override
  String get nearby => 'Рядом';

  @override
  String get topics => 'Темы';

  @override
  String get waves => 'Приветствия';

  @override
  String get voiceRooms => 'Голос';

  @override
  String get filters => 'Фильтры';

  @override
  String get searchCommunity => 'Поиск по имени, языку или интересам...';

  @override
  String get bio => 'О себе';

  @override
  String get noBioYet => 'Описание пока не добавлено.';

  @override
  String get languages => 'Языки';

  @override
  String get native => 'Родной';

  @override
  String get interests => 'Интересы';

  @override
  String get noMomentsYet => 'Пока нет моментов';

  @override
  String get unableToLoadMoments => 'Не удалось загрузить моменты';

  @override
  String get map => 'Карта';

  @override
  String get mapUnavailable => 'Map unavailable';

  @override
  String get location => 'Location';

  @override
  String get unknownLocation => 'Unknown location';

  @override
  String get noImagesAvailable2 => 'No images available';

  @override
  String get permissionsRequired => 'Permissions Required';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get refresh => 'Refresh';

  @override
  String get videoCall => 'Видео';

  @override
  String get voiceCall => 'Звонок';

  @override
  String get message => 'Сообщение';

  @override
  String get pleaseLoginToFollow => 'Пожалуйста, войдите, чтобы подписаться';

  @override
  String get pleaseLoginToCall => 'Пожалуйста, войдите, чтобы позвонить';

  @override
  String get cannotCallYourself => 'You cannot call yourself';

  @override
  String get failedToFollowUser => 'Failed to follow user';

  @override
  String get failedToUnfollowUser => 'Failed to unfollow user';

  @override
  String get areYouSureUnfollow => 'Are you sure you want to unfollow this user?';

  @override
  String get areYouSureUnblock => 'Are you sure you want to unblock this user?';

  @override
  String get youFollowed => 'You followed';

  @override
  String get youUnfollowed => 'You unfollowed';

  @override
  String get alreadyFollowing => 'You are already following';

  @override
  String get soon => 'Скоро';

  @override
  String comingSoon(String feature) {
    return '$feature скоро!';
  }

  @override
  String get muteNotifications => 'Отключить уведомления';

  @override
  String get unmuteNotifications => 'Включить уведомления';

  @override
  String get operationCompleted => 'Операция завершена';

  @override
  String get couldNotOpenMaps => 'Не удалось открыть карту';

  @override
  String hasntSharedMoments(Object name) {
    return '$name ещё не поделился моментами';
  }

  @override
  String messageUser(String name) {
    return 'Сообщение $name';
  }

  @override
  String notFollowingUser(String name) {
    return 'Вы не подписаны на $name';
  }

  @override
  String youFollowedUser(String name) {
    return 'Вы подписались на $name';
  }

  @override
  String youUnfollowedUser(String name) {
    return 'Вы отписались от $name';
  }

  @override
  String unfollowUser(String name) {
    return 'Отписаться от $name';
  }

  @override
  String get typing => 'печатает';

  @override
  String get connecting => 'Подключение...';

  @override
  String daysAgo(int count) {
    return '$countд назад';
  }

  @override
  String get maxTagsAllowed => 'Максимум 5 тегов';

  @override
  String maxImagesAllowed(int count) {
    return 'Максимум $count изображений';
  }

  @override
  String get pleaseRemoveImagesFirst => 'Сначала удалите изображения';

  @override
  String get exchange3MessagesBeforeCall => 'Для звонка нужно обменяться минимум 3 сообщениями';

  @override
  String mediaWithUser(String name) {
    return 'Медиа с $name';
  }

  @override
  String get errorLoadingMedia => 'Ошибка загрузки медиа';

  @override
  String get savedMomentsTitle => 'Сохранённые моменты';

  @override
  String get removeBookmark => 'Удалить из сохраненных?';

  @override
  String get thisWillRemoveBookmark => 'Сообщение будет удалено из закладок.';

  @override
  String get remove => 'Удалить';

  @override
  String get bookmarkRemoved => 'Удалено из сохраненных';

  @override
  String get bookmarkedMessages => 'Сохраненные сообщения';

  @override
  String get wallpaperSaved => 'Обои сохранены локально';

  @override
  String get typeDeleteToConfirm => 'Введите DELETE для подтверждения';

  @override
  String get storyArchive => 'Архив историй';

  @override
  String get newHighlight => 'Новое актуальное';

  @override
  String get addToHighlight => 'Добавить в актуальное';

  @override
  String get repost => 'Репост';

  @override
  String get repostFeatureSoon => 'Функция репоста скоро';

  @override
  String get closeFriends => 'Близкие друзья';

  @override
  String get addFriends => 'Добавить друзей';

  @override
  String get highlights => 'Актуальное';

  @override
  String get createHighlight => 'Создать актуальное';

  @override
  String get deleteHighlight => 'Удалить';

  @override
  String get editHighlight => 'Редактировать';

  @override
  String get addMoreToStory => 'Добавить в историю';

  @override
  String get noViewersYet => 'Пока нет зрителей';

  @override
  String get noReactionsYet => 'Пока нет реакций';

  @override
  String get leaveRoom => 'Покинуть комнату';

  @override
  String get areYouSureLeaveRoom => 'Вы уверены, что хотите покинуть эту комнату?';

  @override
  String get stay => 'Остаться';

  @override
  String get leave => 'Покинуть';

  @override
  String get enableGPS => 'Включить GPS';

  @override
  String wavedToUser(String name) {
    return 'Вы помахали $name!';
  }

  @override
  String get areYouSureFollow => 'Вы уверены, что хотите подписаться на';

  @override
  String get failedToLoadProfile => 'Не удалось загрузить профиль';

  @override
  String get noFollowersYet => 'Пока нет подписчиков';

  @override
  String get noFollowingYet => 'Пока ни на кого не подписаны';

  @override
  String get searchUsers => 'Поиск пользователей...';

  @override
  String get noResultsFound => 'Ничего не найдено';

  @override
  String get loadingFailed => 'Ошибка загрузки';

  @override
  String get copyLink => 'Копировать ссылку';

  @override
  String get shareStory => 'Поделиться историей';

  @override
  String get thisWillDeleteStory => 'Это навсегда удалит эту историю.';

  @override
  String get storyDeleted => 'История удалена';

  @override
  String get addCaption => 'Добавить описание...';

  @override
  String get yourStory => 'Ваша история';

  @override
  String get sendMessage => 'Отправить сообщение';

  @override
  String get replyToStory => 'Ответить на историю...';

  @override
  String get viewAllReplies => 'Посмотреть все ответы';

  @override
  String get preparingVideo => 'Подготовка видео...';

  @override
  String videoOptimized(String size, String savings) {
    return 'Видео оптимизировано: $sizeМБ (экономия $savings%)';
  }

  @override
  String get failedToProcessVideo => 'Не удалось обработать видео';

  @override
  String get optimizingForBestExperience => 'Оптимизация для лучшего опыта';

  @override
  String get pleaseSelectImageOrVideo => 'Пожалуйста, выберите изображение или видео для истории';

  @override
  String get storyCreatedSuccessfully => 'История успешно создана!';

  @override
  String get uploadingStoryInBackground => 'Загрузка истории в фоновом режиме...';

  @override
  String get storyCreationFailed => 'Не удалось создать историю';

  @override
  String get pleaseCheckConnection => 'Проверьте подключение и попробуйте снова.';

  @override
  String get uploadFailed => 'Ошибка загрузки';

  @override
  String get tryShorterVideo => 'Попробуйте использовать более короткое видео или повторите позже.';

  @override
  String get shareMomentsThatDisappear => 'Делитесь моментами, которые исчезают через 24 часа';

  @override
  String get photo => 'Фото';

  @override
  String get record => 'Запись';

  @override
  String get addSticker => 'Добавить стикер';

  @override
  String get poll => 'Опрос';

  @override
  String get question => 'Вопрос';

  @override
  String get mention => 'Упоминание';

  @override
  String get music => 'Музыка';

  @override
  String get hashtag => 'Хэштег';

  @override
  String get whoCanSeeThis => 'Кто может видеть?';

  @override
  String get everyone => 'Все';

  @override
  String get anyoneCanSeeStory => 'Любой может увидеть эту историю';

  @override
  String get friendsOnly => 'Только друзья';

  @override
  String get onlyFollowersCanSee => 'Только ваши подписчики могут видеть';

  @override
  String get onlyCloseFriendsCanSee => 'Только близкие друзья могут видеть';

  @override
  String get backgroundColor => 'Цвет фона';

  @override
  String get fontStyle => 'Стиль шрифта';

  @override
  String get normal => 'Обычный';

  @override
  String get bold => 'Жирный';

  @override
  String get italic => 'Курсив';

  @override
  String get handwriting => 'Рукописный';

  @override
  String get addLocation => 'Добавить место';

  @override
  String get enterLocationName => 'Введите название места';

  @override
  String get addLink => 'Добавить ссылку';

  @override
  String get buttonText => 'Текст кнопки';

  @override
  String get learnMore => 'Подробнее';

  @override
  String get addHashtags => 'Добавить хэштеги';

  @override
  String get addHashtag => 'Добавить хэштег';

  @override
  String get sendAsMessage => 'Отправить как сообщение';

  @override
  String get shareExternally => 'Поделиться внешне';

  @override
  String get checkOutStory => 'Посмотрите эту историю в BananaTalk!';

  @override
  String viewsTab(String count) {
    return 'Просмотры ($count)';
  }

  @override
  String reactionsTab(String count) {
    return 'Реакции ($count)';
  }

  @override
  String get processingVideo => 'Обработка видео...';

  @override
  String get link => 'Ссылка';

  @override
  String unmuteUser(String name) {
    return 'Включить уведомления от $name?';
  }

  @override
  String get willReceiveNotifications => 'Вы будете получать уведомления о новых сообщениях.';

  @override
  String muteNotificationsFor(String name) {
    return 'Отключить уведомления от $name';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return 'Уведомления от $name включены';
  }

  @override
  String notificationsMutedFor(String name) {
    return 'Уведомления от $name отключены';
  }

  @override
  String get failedToUpdateMuteSettings => 'Не удалось обновить настройки';

  @override
  String get oneHour => '1 час';

  @override
  String get eightHours => '8 часов';

  @override
  String get oneWeek => '1 неделя';

  @override
  String get always => 'Всегда';

  @override
  String get failedToLoadBookmarks => 'Не удалось загрузить сохраненные';

  @override
  String get noBookmarkedMessages => 'Нет сохраненных сообщений';

  @override
  String get longPressToBookmark => 'Удерживайте сообщение, чтобы сохранить';

  @override
  String get thisWillRemoveFromBookmarks => 'Сообщение будет удалено из сохраненных.';

  @override
  String navigateToMessage(String name) {
    return 'Перейти к сообщению в чате с $name';
  }

  @override
  String bookmarkedOn(String date) {
    return 'Сохранено $date';
  }

  @override
  String get voiceMessage => 'Голосовое сообщение';

  @override
  String get document => 'Документ';

  @override
  String get attachment => 'Вложение';

  @override
  String get sendMeAMessage => 'Отправьте мне сообщение';

  @override
  String get shareWithFriends => 'Поделиться с друзьями';

  @override
  String get shareAnywhere => 'Поделиться';

  @override
  String get emailPreferences => 'Настройки почты';

  @override
  String get receiveEmailNotifications => 'Receive email notifications from BananaTalk';

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
  String get category => 'Категория';

  @override
  String get mood => 'Настроение';

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
  String get applyFilters => 'Применить фильтры';

  @override
  String applyNFilters(int count) {
    return 'Apply $count Filters';
  }

  @override
  String get videoMustBeUnder1GB => 'Видео должно быть меньше 1 ГБ.';

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
  String get edited => '(изменено)';

  @override
  String get now => 'сейчас';

  @override
  String weeksAgo(int count) {
    return '$countнед назад';
  }

  @override
  String viewRepliesCount(int count) {
    return '── Показать $count ответов';
  }

  @override
  String get hideReplies => '── Скрыть ответы';

  @override
  String get saveMoment => 'Сохранить момент';

  @override
  String get removeFromSaved => 'Удалить из сохранённых';

  @override
  String get momentSaved => 'Сохранено';

  @override
  String get failedToSave => 'Не удалось сохранить';

  @override
  String get checkOutMoment => 'Посмотрите этот момент на BananaTalk!';

  @override
  String get failedToLoadMoments => 'Не удалось загрузить моменты';

  @override
  String get noMomentsMatchFilters => 'Нет моментов, соответствующих фильтрам';

  @override
  String get beFirstToShareMoment => 'Будьте первым, кто поделится моментом!';

  @override
  String get tryDifferentSearch => 'Попробуйте другой поисковый запрос';

  @override
  String get tryAdjustingFilters => 'Попробуйте изменить фильтры';

  @override
  String get noSavedMoments => 'Нет сохранённых моментов';

  @override
  String get tapBookmarkToSave => 'Нажмите на закладку, чтобы сохранить момент';

  @override
  String get failedToLoadVideo => 'Не удалось загрузить видео';

  @override
  String get titleRequired => 'Заголовок обязателен';

  @override
  String titleTooLong(int max) {
    return 'Заголовок должен быть не более $max символов';
  }

  @override
  String get descriptionRequired => 'Описание обязательно';

  @override
  String descriptionTooLong(int max) {
    return 'Описание должно быть не более $max символов';
  }

  @override
  String get scheduledDateMustBeFuture => 'Запланированная дата должна быть в будущем';

  @override
  String get recent => 'Новые';

  @override
  String get popular => 'Популярные';

  @override
  String get trending => 'В тренде';

  @override
  String get mostRecent => 'Самые новые';

  @override
  String get mostPopular => 'Самые популярные';

  @override
  String get allTime => 'Всё время';

  @override
  String get today => 'Сегодня';

  @override
  String get thisWeek => 'На этой неделе';

  @override
  String get thisMonth => 'В этом месяце';

  @override
  String replyingTo(String userName) {
    return 'Ответ для $userName';
  }

  @override
  String get listView => 'Список';

  @override
  String get quickMatch => 'Быстрый подбор';

  @override
  String get onlineNow => 'Сейчас онлайн';

  @override
  String speaksLanguage(String language) {
    return 'Говорит на $language';
  }

  @override
  String learningLanguage(String language) {
    return 'Изучает $language';
  }

  @override
  String get noPartnersFound => 'Партнёры не найдены';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return 'Не найдено пользователей для $learning и $native';
  }

  @override
  String get removeAllFilters => 'Убрать все фильтры';

  @override
  String get browseAllUsers => 'Просмотреть всех пользователей';

  @override
  String get allCaughtUp => 'Вы всё посмотрели!';

  @override
  String get loadingMore => 'Загружаем ещё...';

  @override
  String get findingMorePartners => 'Ищем ещё партнёров...';

  @override
  String get seenAllPartners => 'Вы видели всех партнёров';

  @override
  String get startOver => 'Начать сначала';

  @override
  String get changeFilters => 'Изменить фильтры';

  @override
  String get findingPartners => 'Поиск партнёров...';

  @override
  String get setLocationReminder => 'Укажите местоположение, чтобы найти партнёров поблизости';

  @override
  String get updateLocationReminder => 'Обновите местоположение для лучших результатов';

  @override
  String get male => 'Мужской';

  @override
  String get female => 'Женский';

  @override
  String get other => 'Другой';

  @override
  String get browseMen => 'Смотреть мужчин';

  @override
  String get browseWomen => 'Смотреть женщин';

  @override
  String get noMaleUsersFound => 'Пользователи мужского пола не найдены';

  @override
  String get noFemaleUsersFound => 'Пользователи женского пола не найдены';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => 'Только новые пользователи';

  @override
  String get showNewUsers => 'Показать новых пользователей';

  @override
  String get prioritizeNearby => 'Приоритет ближайшим';

  @override
  String get showNearbyFirst => 'Показывать ближайших первыми';

  @override
  String get setLocationToEnable => 'Укажите местоположение для активации';

  @override
  String get radius => 'Радиус';

  @override
  String get findingYourLocation => 'Определяем ваше местоположение...';

  @override
  String get enableLocationForDistance => 'Включите геолокацию, чтобы видеть расстояния';

  @override
  String get enableLocationDescription => 'Разрешите доступ к местоположению, чтобы найти языковых партнёров рядом';

  @override
  String get enableGps => 'Включить GPS';

  @override
  String get browseByCityCountry => 'Поиск по городу или стране';

  @override
  String get peopleNearby => 'Люди поблизости';

  @override
  String get noNearbyUsersFound => 'Пользователи поблизости не найдены';

  @override
  String get tryExpandingSearch => 'Попробуйте расширить область поиска';

  @override
  String get exploreByCity => 'Искать по городу';

  @override
  String get exploreByCurrentCity => 'Искать по текущему городу';

  @override
  String get interactiveWorldMap => 'Интерактивная карта мира';

  @override
  String get searchByCityName => 'Поиск по названию города';

  @override
  String get seeUserCountsPerCountry => 'Посмотреть количество пользователей по странам';

  @override
  String get upgradeToVip => 'Перейти на VIP';

  @override
  String get searchByCity => 'Поиск по городу';

  @override
  String usersWorldwide(String count) {
    return '$count пользователей по всему миру';
  }

  @override
  String get noUsersFound => 'Пользователи не найдены';

  @override
  String get tryDifferentCity => 'Попробуйте другой город';

  @override
  String usersCount(String count) {
    return '$count пользователей';
  }

  @override
  String get searchCountry => 'Поиск страны...';

  @override
  String get wave => 'Помахать';

  @override
  String get newUser => 'Новый';

  @override
  String get warningPermanent => 'Внимание: это действие необратимо!';

  @override
  String get deleteAccountWarning => 'Удаление аккаунта навсегда сотрёт все ваши данные, сообщения, моменты и связи. Это действие нельзя отменить.';

  @override
  String get requiredForEmailOnly => 'Требуется только для аккаунтов с электронной почтой';

  @override
  String get pleaseEnterPassword => 'Пожалуйста, введите пароль';

  @override
  String get typeDELETE => 'Введите DELETE';

  @override
  String get mustTypeDELETE => 'Необходимо ввести DELETE для подтверждения';

  @override
  String get deletingAccount => 'Удаление аккаунта...';

  @override
  String get deleteMyAccountPermanently => 'Удалить мой аккаунт навсегда';

  @override
  String get whatsYourNativeLanguage => 'Какой ваш родной язык?';

  @override
  String get helpsMatchWithLearners => 'Поможет найти изучающих ваш язык';

  @override
  String get whatAreYouLearning => 'Что вы изучаете?';

  @override
  String get connectWithNativeSpeakers => 'Общайтесь с носителями языка';

  @override
  String get selectLearningLanguage => 'Выберите изучаемый язык';

  @override
  String get selectCurrentLevel => 'Выберите текущий уровень';

  @override
  String get beginner => 'Начинающий';

  @override
  String get elementary => 'Элементарный';

  @override
  String get intermediate => 'Средний';

  @override
  String get upperIntermediate => 'Выше среднего';

  @override
  String get advanced => 'Продвинутый';

  @override
  String get proficient => 'Свободный';

  @override
  String get showingPartnersByDistance => 'Показ партнёров по расстоянию';

  @override
  String get enableLocationForResults => 'Включите геолокацию для результатов';

  @override
  String get enable => 'Включить';

  @override
  String get locationNotSet => 'Местоположение не указано';

  @override
  String get tellUsAboutYourself => 'Расскажите о себе';

  @override
  String get justACoupleQuickThings => 'Всего пара быстрых вопросов';

  @override
  String get gender => 'Пол';

  @override
  String get birthDate => 'Дата рождения';

  @override
  String get selectYourBirthDate => 'Выберите дату рождения';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get pleaseSelectGender => 'Пожалуйста, выберите пол';

  @override
  String get pleaseSelectBirthDate => 'Пожалуйста, выберите дату рождения';

  @override
  String get mustBe18 => 'Вам должно быть не менее 18 лет';

  @override
  String get invalidDate => 'Неверная дата';

  @override
  String get almostDone => 'Почти готово!';

  @override
  String get addPhotoLocationForMatches => 'Добавьте фото и местоположение для лучших совпадений';

  @override
  String get addProfilePhoto => 'Добавить фото профиля';

  @override
  String get optionalUpTo6Photos => 'Необязательно — до 6 фото';

  @override
  String get requiredUpTo6Photos => 'Обязательно — до 6 фото';

  @override
  String get profilePhotoRequired => 'Добавьте хотя бы одно фото профиля';

  @override
  String get locationOptional => 'Местоположение необязательно — можно добавить позже';

  @override
  String get maximum6Photos => 'Максимум 6 фото';

  @override
  String get tapToDetectLocation => 'Нажмите для определения местоположения';

  @override
  String get optionalHelpsNearbyPartners => 'Необязательно — помогает найти партнёров поблизости';

  @override
  String get startLearning => 'Начать обучение';

  @override
  String get photoLocationOptional => 'Фото и местоположение необязательны';

  @override
  String get pleaseAcceptTerms => 'Пожалуйста, примите условия использования';

  @override
  String get iAgreeToThe => 'Я принимаю';

  @override
  String get termsOfService => 'Условия использования';

  @override
  String get tapToSelectLanguage => 'Нажмите, чтобы выбрать язык';

  @override
  String yourLevelIn(String language) {
    return 'Ваш уровень в $language';
  }

  @override
  String get yourCurrentLevel => 'Ваш текущий уровень';

  @override
  String get nativeCannotBeSameAsLearning => 'Родной язык не может совпадать с изучаемым';

  @override
  String get learningCannotBeSameAsNative => 'Изучаемый язык не может совпадать с родным';

  @override
  String stepOf(String current, String total) {
    return 'Шаг $current из $total';
  }

  @override
  String get continueWithGoogle => 'Продолжить через Google';

  @override
  String get registerLink => 'Регистрация';

  @override
  String get pleaseEnterBothEmailAndPassword => 'Введите email и пароль';

  @override
  String get pleaseEnterValidEmail => 'Введите действительный email';

  @override
  String get loginSuccessful => 'Вход выполнен!';

  @override
  String get stepOneOfTwo => 'Шаг 1 из 2';

  @override
  String get createYourAccount => 'Создайте аккаунт';

  @override
  String get basicInfoToGetStarted => 'Базовая информация для начала';

  @override
  String get emailVerifiedLabel => 'Email (Подтверждён)';

  @override
  String get nameLabel => 'Имя';

  @override
  String get yourDisplayName => 'Отображаемое имя';

  @override
  String get atLeast8Characters => 'Минимум 8 символов';

  @override
  String get confirmPasswordHint => 'Подтвердите пароль';

  @override
  String get nextButton => 'Далее';

  @override
  String get pleaseEnterYourName => 'Введите ваше имя';

  @override
  String get pleaseEnterAPassword => 'Введите пароль';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get otherGender => 'Другой';

  @override
  String get continueWithGoogleAccount => 'Продолжите через Google-аккаунт\nдля удобного входа';

  @override
  String get signingYouIn => 'Выполняется вход...';

  @override
  String get backToSignInMethods => 'Назад к способам входа';

  @override
  String get securedByGoogle => 'Защищено Google';

  @override
  String get dataProtectedEncryption => 'Ваши данные защищены стандартным шифрованием';

  @override
  String get welcomeCompleteProfile => 'Добро пожаловать! Заполните профиль';

  @override
  String welcomeBackName(String name) {
    return 'С возвращением, $name!';
  }

  @override
  String get continueWithAppleId => 'Продолжите через Apple ID\nдля безопасного входа';

  @override
  String get continueWithApple => 'Продолжить через Apple';

  @override
  String get securedByApple => 'Защищено Apple';

  @override
  String get privacyProtectedApple => 'Ваша конфиденциальность защищена Apple Sign-In';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get enterEmailToGetStarted => 'Введите email для начала';

  @override
  String get continueText => 'Продолжить';

  @override
  String get pleaseEnterEmailAddress => 'Введите ваш email';

  @override
  String get verificationCodeSent => 'Код отправлен на ваш email!';

  @override
  String get forgotPasswordTitle => 'Забыли пароль';

  @override
  String get resetPasswordTitle => 'Сброс пароля';

  @override
  String get enterEmailForResetCode => 'Введите email и мы отправим код для сброса пароля';

  @override
  String get sendResetCode => 'Отправить код';

  @override
  String get resetCodeSent => 'Код сброса отправлен!';

  @override
  String get rememberYourPassword => 'Помните пароль?';

  @override
  String get verifyCode => 'Проверить код';

  @override
  String get enterResetCode => 'Введите код';

  @override
  String get weSentCodeTo => 'Мы отправили 6-значный код на';

  @override
  String get pleaseEnterAll6Digits => 'Введите все 6 цифр';

  @override
  String get codeVerifiedCreatePassword => 'Код подтверждён! Создайте новый пароль';

  @override
  String get verify => 'Подтвердить';

  @override
  String get didntReceiveCode => 'Не получили код?';

  @override
  String get resend => 'Отправить повторно';

  @override
  String resendWithTimer(String timer) {
    return 'Повторно ($timerс)';
  }

  @override
  String get resetCodeResent => 'Код отправлен повторно!';

  @override
  String get verifyEmail => 'Подтвердить email';

  @override
  String get verifyYourEmail => 'Подтвердите ваш email';

  @override
  String get emailVerifiedSuccessfully => 'Email подтверждён!';

  @override
  String get verificationCodeResent => 'Код подтверждения отправлен повторно!';

  @override
  String get createNewPassword => 'Создать новый пароль';

  @override
  String get enterNewPasswordBelow => 'Введите новый пароль ниже';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get confirmPasswordLabel => 'Подтвердите пароль';

  @override
  String get pleaseFillAllFields => 'Заполните все поля';

  @override
  String get passwordResetSuccessful => 'Пароль сброшен! Войдите с новым паролем';

  @override
  String get privacyTitle => 'Конфиденциальность';

  @override
  String get profileVisibility => 'Видимость профиля';

  @override
  String get showCountryRegion => 'Показать страну/регион';

  @override
  String get showCountryRegionDesc => 'Отображать вашу страну в профиле';

  @override
  String get showCity => 'Показать город';

  @override
  String get showCityDesc => 'Отображать ваш город в профиле';

  @override
  String get showAge => 'Показать возраст';

  @override
  String get showAgeDesc => 'Отображать ваш возраст в профиле';

  @override
  String get showZodiacSign => 'Показать знак зодиака';

  @override
  String get showZodiacSignDesc => 'Отображать знак зодиака в профиле';

  @override
  String get onlineStatusSection => 'Статус онлайн';

  @override
  String get showOnlineStatus => 'Показать статус онлайн';

  @override
  String get showOnlineStatusDesc => 'Позволить другим видеть, когда вы онлайн';

  @override
  String get otherSettings => 'Другие настройки';

  @override
  String get showGiftingLevel => 'Показать уровень подарков';

  @override
  String get showGiftingLevelDesc => 'Отображать значок уровня подарков';

  @override
  String get birthdayNotifications => 'Уведомления о дне рождения';

  @override
  String get birthdayNotificationsDesc => 'Получать уведомления в день рождения';

  @override
  String get personalizedAds => 'Персонализированная реклама';

  @override
  String get personalizedAdsDesc => 'Разрешить персонализированную рекламу';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get privacySettingsSaved => 'Настройки конфиденциальности сохранены';

  @override
  String get locationSection => 'Местоположение';

  @override
  String get updateLocation => 'Обновить местоположение';

  @override
  String get updateLocationDesc => 'Обновить текущее местоположение';

  @override
  String get currentLocation => 'Текущее местоположение';

  @override
  String get locationNotAvailable => 'Местоположение недоступно';

  @override
  String get locationUpdated => 'Местоположение обновлено';

  @override
  String get locationPermissionDenied => 'Разрешение на определение местоположения отклонено. Включите в настройках.';

  @override
  String get locationServiceDisabled => 'Службы определения местоположения отключены. Пожалуйста, включите их.';

  @override
  String get updatingLocation => 'Обновление местоположения...';

  @override
  String get locationCouldNotBeUpdated => 'Не удалось обновить местоположение';

  @override
  String get incomingAudioCall => 'Входящий аудиозвонок';

  @override
  String get incomingVideoCall => 'Входящий видеозвонок';

  @override
  String get outgoingCall => 'Вызов...';

  @override
  String get callRinging => 'Звонит...';

  @override
  String get callConnecting => 'Подключение...';

  @override
  String get callConnected => 'Подключено';

  @override
  String get callReconnecting => 'Переподключение...';

  @override
  String get callEnded => 'Звонок завершен';

  @override
  String get callFailed => 'Звонок не удался';

  @override
  String get callMissed => 'Пропущенный звонок';

  @override
  String get callDeclined => 'Звонок отклонен';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => 'Принять';

  @override
  String get declineCall => 'Отклонить';

  @override
  String get endCall => 'Завершить';

  @override
  String get muteCall => 'Выкл. звук';

  @override
  String get unmuteCall => 'Вкл. звук';

  @override
  String get speakerOn => 'Динамик';

  @override
  String get speakerOff => 'Наушник';

  @override
  String get videoOn => 'Видео вкл.';

  @override
  String get videoOff => 'Видео выкл.';

  @override
  String get switchCamera => 'Переключить камеру';

  @override
  String get callPermissionDenied => 'Для звонков требуется разрешение микрофона';

  @override
  String get cameraPermissionDenied => 'Для видеозвонков требуется разрешение камеры';

  @override
  String get callConnectionFailed => 'Не удалось подключиться. Попробуйте снова.';

  @override
  String get userBusy => 'Пользователь занят';

  @override
  String get userOffline => 'Пользователь не в сети';

  @override
  String get callHistory => 'История звонков';

  @override
  String get noCallHistory => 'Нет истории звонков';

  @override
  String get missedCalls => 'Пропущенные звонки';

  @override
  String get allCalls => 'Все звонки';

  @override
  String get callBack => 'Перезвонить';

  @override
  String callAt(String time) {
    return 'Звонок в $time';
  }

  @override
  String get audioCall => 'Аудиозвонок';

  @override
  String get voiceRoom => 'Голосовая комната';

  @override
  String get noVoiceRooms => 'Нет активных голосовых комнат';

  @override
  String get createVoiceRoom => 'Создать голосовую комнату';

  @override
  String get joinRoom => 'Присоединиться';

  @override
  String get leaveRoomConfirm => 'Покинуть комнату?';

  @override
  String get leaveRoomMessage => 'Вы уверены, что хотите покинуть эту комнату?';

  @override
  String get roomTitle => 'Название комнаты';

  @override
  String get roomTitleHint => 'Введите название комнаты';

  @override
  String get roomTopic => 'Тема';

  @override
  String get roomLanguage => 'Язык';

  @override
  String get roomHost => 'Ведущий';

  @override
  String roomParticipants(int count) {
    return '$count участников';
  }

  @override
  String roomMaxParticipants(int count) {
    return 'Макс. $count участников';
  }

  @override
  String get selectTopic => 'Выбрать тему';

  @override
  String get raiseHand => 'Поднять руку';

  @override
  String get lowerHand => 'Опустить руку';

  @override
  String get handRaisedNotification => 'Рука поднята! Ведущий увидит ваш запрос.';

  @override
  String get handLoweredNotification => 'Рука опущена';

  @override
  String get muteParticipant => 'Выключить звук участника';

  @override
  String get kickParticipant => 'Удалить из комнаты';

  @override
  String get promoteToCoHost => 'Сделать со-ведущим';

  @override
  String get endRoomConfirm => 'Завершить комнату?';

  @override
  String get endRoomMessage => 'Это завершит комнату для всех участников.';

  @override
  String get roomEnded => 'Комната завершена ведущим';

  @override
  String get youWereRemoved => 'Вас удалили из комнаты';

  @override
  String get roomIsFull => 'Комната заполнена';

  @override
  String get roomChat => 'Чат комнаты';

  @override
  String get noMessages => 'Пока нет сообщений';

  @override
  String get typeMessage => 'Введите сообщение...';

  @override
  String get voiceRoomsDescription => 'Присоединяйтесь к живым разговорам и практикуйте речь';

  @override
  String liveRoomsCount(int count) {
    return '$count онлайн';
  }

  @override
  String get noActiveRooms => 'Нет активных комнат';

  @override
  String get noActiveRoomsDescription => 'Будьте первым, кто создаст голосовую комнату и практикуйтесь с другими!';

  @override
  String get startRoom => 'Начать комнату';

  @override
  String get createRoom => 'Создать комнату';

  @override
  String get roomCreated => 'Комната успешно создана!';

  @override
  String get failedToCreateRoom => 'Не удалось создать комнату';

  @override
  String get errorLoadingRooms => 'Ошибка загрузки комнат';

  @override
  String get pleaseEnterRoomTitle => 'Пожалуйста, введите название комнаты';

  @override
  String get startLiveConversation => 'Начать живой разговор';

  @override
  String get maxParticipants => 'Макс. участников';

  @override
  String nPeople(int count) {
    return '$count человек';
  }

  @override
  String hostedBy(String name) {
    return 'Ведущий: $name';
  }

  @override
  String get liveLabel => 'ПРЯМОЙ ЭФИР';

  @override
  String get joinLabel => 'Войти';

  @override
  String get fullLabel => 'Заполнено';

  @override
  String get justStarted => 'Только что началось';

  @override
  String get allLanguages => 'Все языки';

  @override
  String get allTopics => 'Все темы';

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
  String get you => 'Вы';

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
  String get dataAndStorage => 'Данные и Хранилище';

  @override
  String get manageStorageAndDownloads => 'Управление хранилищем и загрузками';

  @override
  String get storageUsage => 'Использование Хранилища';

  @override
  String get totalCacheSize => 'Общий Размер Кэша';

  @override
  String get imageCache => 'Кэш Изображений';

  @override
  String get voiceMessagesCache => 'Голосовые Сообщения';

  @override
  String get videoCache => 'Кэш Видео';

  @override
  String get otherCache => 'Другой Кэш';

  @override
  String get autoDownloadMedia => 'Автозагрузка Медиа';

  @override
  String get currentNetwork => 'Текущая Сеть';

  @override
  String get images => 'Изображения';

  @override
  String get videos => 'Видео';

  @override
  String get voiceMessagesShort => 'Голосовые Сообщения';

  @override
  String get documentsLabel => 'Документы';

  @override
  String get wifiOnly => 'Только WiFi';

  @override
  String get never => 'Никогда';

  @override
  String get clearAllCache => 'Очистить Весь Кэш';

  @override
  String get allCache => 'Весь Кэш';

  @override
  String get clearAllCacheConfirmation => 'Это удалит все кэшированные изображения, голосовые сообщения, видео и другие файлы. Приложение может временно загружать контент медленнее.';

  @override
  String clearCacheConfirmationFor(String category) {
    return 'Очистить $category?';
  }

  @override
  String storageToFree(String size) {
    return '$size будет освобождено';
  }

  @override
  String get calculating => 'Вычисление...';

  @override
  String get noDataToShow => 'Нет данных для отображения';

  @override
  String get profileCompletion => 'Заполненность профиля';

  @override
  String get justGettingStarted => 'Только начинаем';

  @override
  String get lookingGood => 'Хорошо!';

  @override
  String get almostThere => 'Почти готово!';

  @override
  String addMissingFields(String fields, Object field) {
    return 'Добавить: $fields';
  }

  @override
  String get profilePicture => 'Фото профиля';

  @override
  String get nativeSpeaker => 'Носитель языка';

  @override
  String peopleInterestedInTopic(Object count) {
    return 'Люди, интересующиеся этой темой';
  }

  @override
  String get beFirstToAddTopic => 'Будьте первым, кто добавит эту тему в свои интересы!';

  @override
  String get recentMoments => 'Недавние моменты';

  @override
  String get seeAll => 'Смотреть все';

  @override
  String get study => 'Учиться';

  @override
  String get followerMoments => 'Моменты подписок';

  @override
  String get whenPeopleYouFollowPost => 'Когда люди, на которых вы подписаны, публикуют новые моменты';

  @override
  String get noNotificationsYet => 'Пока нет уведомлений';

  @override
  String get whenYouGetNotifications => 'Когда вы получите уведомления, они появятся здесь';

  @override
  String get failedToLoadNotifications => 'Не удалось загрузить уведомления';

  @override
  String get clearAllNotificationsConfirm => 'Вы уверены, что хотите удалить все уведомления? Это действие нельзя отменить.';

  @override
  String get tapToChange => 'Нажмите для изменения';

  @override
  String get noPictureSet => 'Фото не установлено';

  @override
  String get nameAndGender => 'Имя и Пол';

  @override
  String get languageLevel => 'Уровень языка';

  @override
  String get personalInformation => 'Личная Информация';

  @override
  String get mbti => 'MBTI';

  @override
  String get topicsOfInterest => 'Темы Интересов';

  @override
  String get levelBeginner => 'Начинающий';

  @override
  String get levelElementary => 'Элементарный';

  @override
  String get levelIntermediate => 'Средний';

  @override
  String get levelUpperIntermediate => 'Выше Среднего';

  @override
  String get levelAdvanced => 'Продвинутый';

  @override
  String get levelProficient => 'Свободный';

  @override
  String get selectYourLevel => 'Выберите Ваш Уровень';

  @override
  String howWellDoYouSpeak(String language) {
    return 'Насколько хорошо вы говорите на $language?';
  }

  @override
  String get theLanguage => 'язык';

  @override
  String languageLevelSetTo(String level) {
    return 'Уровень языка установлен на $level';
  }

  @override
  String get failedToUpdate => 'Не удалось обновить';

  @override
  String get editHometown => 'Изменить Родной Город';

  @override
  String get useCurrentLocation => 'Использовать Текущее Местоположение';

  @override
  String get detecting => 'Определяется...';

  @override
  String get getCurrentLocation => 'Получить Текущее Местоположение';

  @override
  String get country => 'Страна';

  @override
  String get city => 'Город';

  @override
  String get coordinates => 'Координаты';

  @override
  String get noLocationDetectedYet => 'Местоположение еще не определено.';

  @override
  String get detected => 'Определено';

  @override
  String get savedHometown => 'Родной город сохранен';

  @override
  String get locationServicesDisabled => 'Службы геолокации отключены. Пожалуйста, включите их.';

  @override
  String get locationPermissionPermanentlyDenied => 'Разрешения на геолокацию постоянно отклонены.';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get editBio => 'Изменить Биографию';

  @override
  String get bioUpdatedSuccessfully => 'Биография успешно обновлена';

  @override
  String get tellOthersAboutYourself => 'Расскажите о себе...';

  @override
  String charactersCount(int count) {
    return '$count/500 символов';
  }

  @override
  String get selectYourMbti => 'Выберите Ваш MBTI';

  @override
  String get myBloodType => 'Моя Группа Крови';

  @override
  String get pleaseSelectABloodType => 'Пожалуйста, выберите группу крови';

  @override
  String get nativeLanguageRequired => 'Родной Язык (Обязательно)';

  @override
  String get languageToLearnRequired => 'Изучаемый Язык (Обязательно)';

  @override
  String get nativeLanguageCannotBeSame => 'Родной язык не может совпадать с изучаемым';

  @override
  String get learningLanguageCannotBeSame => 'Изучаемый язык не может совпадать с родным';

  @override
  String get pleaseSelectALanguage => 'Пожалуйста, выберите язык';

  @override
  String get editInterests => 'Изменить Интересы';

  @override
  String maxTopicsAllowed(int count) {
    return 'Максимум $count тем';
  }

  @override
  String get topicsUpdatedSuccessfully => 'Темы успешно обновлены!';

  @override
  String get failedToUpdateTopics => 'Не удалось обновить темы';

  @override
  String selectedCount(int count, int max) {
    return '$count/$max выбрано';
  }

  @override
  String get profilePictures => 'Фото Профиля';

  @override
  String get addImages => 'Добавить Изображения';

  @override
  String get selectUpToImages => 'Выберите до 5 изображений';

  @override
  String get takeAPhoto => 'Сделать Фото';

  @override
  String get removeImage => 'Удалить Изображение';

  @override
  String get removeImageConfirm => 'Удалить это изображение?';

  @override
  String get removeAll => 'Удалить Все';

  @override
  String get removeAllSelectedImages => 'Удалить Все Выбранные';

  @override
  String get removeAllSelectedImagesConfirm => 'Удалить все выбранные изображения?';

  @override
  String get yourProfilePictureWillBeKept => 'Ваше фото профиля будет сохранено';

  @override
  String get removeAllImages => 'Удалить Все Изображения';

  @override
  String get removeAllImagesConfirm => 'Удалить все фото профиля?';

  @override
  String get currentImages => 'Текущие Изображения';

  @override
  String get newImages => 'Новые Изображения';

  @override
  String get addMoreImages => 'Добавить Еще';

  @override
  String uploadImages(int count) {
    return 'Загрузить $count';
  }

  @override
  String get imageRemovedSuccessfully => 'Изображение удалено';

  @override
  String get imagesUploadedSuccessfully => 'Изображения загружены';

  @override
  String get selectedImagesCleared => 'Выбранные изображения удалены';

  @override
  String get extraImagesRemovedSuccessfully => 'Дополнительные изображения удалены';

  @override
  String get mustKeepAtLeastOneProfilePicture => 'Нужно хотя бы одно фото профиля';

  @override
  String get noProfilePicturesToRemove => 'Нет фото для удаления';

  @override
  String get authenticationTokenNotFound => 'Токен не найден';

  @override
  String get saveChangesQuestion => 'Сохранить Изменения?';

  @override
  String youHaveUnuploadedImages(int count) {
    return '$count изображений не загружено. Загрузить?';
  }

  @override
  String get discard => 'Отменить';

  @override
  String get upload => 'Загрузить';

  @override
  String maxImagesInfo(int max, int current) {
    return 'Максимум $max изображений. Текущее: $current/$max';
  }

  @override
  String canOnlyAddMoreImages(int count, int max) {
    return 'Можно добавить еще $count. Максимум $max.';
  }

  @override
  String get maxImagesPerUpload => 'Максимум 5 изображений за раз';

  @override
  String canOnlyHaveMaxImages(int max) {
    return 'Максимум $max изображений';
  }

  @override
  String get imageSizeExceedsLimit => 'Размер превышает 10МБ';

  @override
  String get unsupportedImageFormat => 'Неподдерживаемый формат';

  @override
  String get pleaseSelectAtLeastOneImage => 'Выберите хотя бы одно изображение';

  @override
  String get basicInformation => 'Основная Информация';

  @override
  String get languageToLearn => 'Изучаемый Язык';

  @override
  String get hometown => 'Родной Город';

  @override
  String get characters => 'символов';

  @override
  String get failedToLoadLanguages => 'Не удалось загрузить языки';

  @override
  String get studyHub => 'Учебный центр';

  @override
  String get dailyLearningJourney => 'Ваш ежедневный путь обучения';

  @override
  String get learnTab => 'Учиться';

  @override
  String get aiTools => 'Инструменты ИИ';

  @override
  String get streak => 'Серия';

  @override
  String get lessons => 'Уроки';

  @override
  String get words => 'Слова';

  @override
  String get quickActions => 'Быстрые действия';

  @override
  String get review => 'Повторение';

  @override
  String wordsDue(int count) {
    return '$count слов к повторению';
  }

  @override
  String get addWords => 'Добавить слова';

  @override
  String get buildVocabulary => 'Пополнить словарь';

  @override
  String get practiceWithAI => 'Практика с ИИ';

  @override
  String get aiPracticeDescription => 'Чат, тесты, грамматика и произношение';

  @override
  String get dailyChallenges => 'Ежедневные задания';

  @override
  String get allChallengesCompleted => 'Все задания выполнены!';

  @override
  String get continueLearning => 'Продолжить обучение';

  @override
  String get structuredLearningPath => 'Структурированный учебный путь';

  @override
  String get vocabulary => 'Словарный запас';

  @override
  String get yourWordCollection => 'Ваша коллекция слов';

  @override
  String get achievements => 'Достижения';

  @override
  String get badgesAndMilestones => 'Значки и вехи';

  @override
  String get failedToLoadLearningData => 'Не удалось загрузить данные об обучении';

  @override
  String get startYourJourney => 'Начните свой путь!';

  @override
  String get startJourneyDescription => 'Проходите уроки, пополняйте словарь\nи отслеживайте прогресс';

  @override
  String levelN(int level) {
    return 'Уровень $level';
  }

  @override
  String xpEarned(int xp) {
    return '$xp XP заработано';
  }

  @override
  String nextLevel(int level) {
    return 'Следующий: Уровень $level';
  }

  @override
  String xpToGo(int xp) {
    return 'Осталось $xp XP';
  }

  @override
  String get aiConversationPartner => 'Партнёр по разговору ИИ';

  @override
  String get practiceWithAITutor => 'Практикуйте разговор с репетитором ИИ';

  @override
  String get startConversation => 'Начать разговор';

  @override
  String get aiFeatures => 'Функции ИИ';

  @override
  String get aiLessons => 'Уроки с ИИ';

  @override
  String get learnWithAI => 'Учиться с ИИ';

  @override
  String get grammar => 'Грамматика';

  @override
  String get checkWriting => 'Проверить письмо';

  @override
  String get pronunciation => 'Произношение';

  @override
  String get improveSpeaking => 'Улучшить речь';

  @override
  String get translation => 'Перевод';

  @override
  String get smartTranslate => 'Умный перевод';

  @override
  String get aiQuizzes => 'Тесты ИИ';

  @override
  String get testKnowledge => 'Проверить знания';

  @override
  String get lessonBuilder => 'Конструктор уроков';

  @override
  String get customLessons => 'Пользовательские уроки';

  @override
  String get yourAIProgress => 'Ваш прогресс с ИИ';

  @override
  String get quizzes => 'Тесты';

  @override
  String get avgScore => 'Средний балл';

  @override
  String get focusAreas => 'Области для работы';

  @override
  String accuracyPercent(String accuracy) {
    return 'Точность $accuracy%';
  }

  @override
  String get practice => 'Практика';

  @override
  String get browse => 'Просмотр';

  @override
  String get noRecommendedLessons => 'Нет рекомендованных уроков';

  @override
  String get noLessonsFound => 'Уроки не найдены';

  @override
  String get createCustomLessonDescription => 'Создайте свой урок с помощью ИИ';

  @override
  String get createLessonWithAI => 'Создать урок с ИИ';

  @override
  String get allLevels => 'Все уровни';

  @override
  String get levelA1 => 'A1 Начинающий';

  @override
  String get levelA2 => 'A2 Элементарный';

  @override
  String get levelB1 => 'B1 Средний';

  @override
  String get levelB2 => 'B2 Выше среднего';

  @override
  String get levelC1 => 'C1 Продвинутый';

  @override
  String get levelC2 => 'C2 Профессиональный';

  @override
  String get failedToLoadLessons => 'Не удалось загрузить уроки';

  @override
  String get pin => 'Закрепить';

  @override
  String get unpin => 'Открепить';

  @override
  String get editMessage => 'Редактировать сообщение';

  @override
  String get enterMessage => 'Введите сообщение...';

  @override
  String get deleteMessageTitle => 'Удалить сообщение';

  @override
  String get actionCannotBeUndone => 'Это действие нельзя отменить.';

  @override
  String get onlyRemovesFromDevice => 'Удаляет только с вашего устройства';

  @override
  String get availableWithinOneHour => 'Доступно только в течение 1 часа';

  @override
  String get available => 'Доступно';

  @override
  String get forwardMessage => 'Переслать сообщение';

  @override
  String get selectUsersToForward => 'Выберите пользователей для пересылки:';

  @override
  String forwardCount(int count) {
    return 'Переслать ($count)';
  }

  @override
  String get pinnedMessage => 'Закреплённое сообщение';

  @override
  String get photoMedia => 'Фото';

  @override
  String get videoMedia => 'Видео';

  @override
  String get voiceMessageMedia => 'Голосовое сообщение';

  @override
  String get documentMedia => 'Документ';

  @override
  String get locationMedia => 'Местоположение';

  @override
  String get stickerMedia => 'Стикер';

  @override
  String get smileys => 'Смайлики';

  @override
  String get emotions => 'Эмоции';

  @override
  String get handGestures => 'Жесты рук';

  @override
  String get hearts => 'Сердечки';

  @override
  String get tapToSayHi => 'Нажмите, чтобы поздороваться!';

  @override
  String get sendWaveToStart => 'Отправьте приветствие, чтобы начать общение';

  @override
  String get documentMustBeUnder50MB => 'Документ должен быть меньше 50 МБ.';

  @override
  String get editWithin15Minutes => 'Сообщения можно редактировать только в течение 15 минут';

  @override
  String messageForwardedTo(int count) {
    return 'Сообщение переслано $count пользователю(ям)';
  }

  @override
  String get failedToLoadUsers => 'Не удалось загрузить пользователей';

  @override
  String get voice => 'Голос';

  @override
  String get searchGifs => 'Поиск GIF...';

  @override
  String get trendingGifs => 'В тренде';

  @override
  String get poweredByGiphy => 'Powered by GIPHY';

  @override
  String get gif => 'GIF';

  @override
  String get noGifsFound => 'GIF не найдены';

  @override
  String get failedToLoadGifs => 'Не удалось загрузить GIF';

  @override
  String get gifSent => 'GIF';

  @override
  String get filterCommunities => 'Фильтр';

  @override
  String get reset => 'Сбросить';

  @override
  String get findYourPerfect => 'Найдите своего идеального';

  @override
  String get languagePartner => 'языкового партнёра';

  @override
  String get learningLanguageLabel => 'Изучаемый язык';

  @override
  String get ageRange => 'Возрастной диапазон';

  @override
  String get genderPreference => 'Предпочтение по полу';

  @override
  String get any => 'Любой';

  @override
  String get showNewUsersSubtitle => 'Показывать пользователей, присоединившихся за последние 6 дней';

  @override
  String get autoDetectLocation => 'Автоматически определить моё местоположение';

  @override
  String get selectCountry => 'Выбрать страну';

  @override
  String get anyCountry => 'Любая страна';

  @override
  String get loadingLanguages => 'Загрузка языков...';

  @override
  String minAge(int age) {
    return 'Мин: $age';
  }

  @override
  String maxAge(int age) {
    return 'Макс: $age';
  }

  @override
  String get captionRequired => 'Подпись обязательна';

  @override
  String captionTooLong(int maxLength) {
    return 'Подпись должна содержать не более $maxLength символов';
  }

  @override
  String get maximumImagesReached => 'Достигнут максимум изображений';

  @override
  String maximumImagesReachedDescription(int maxImages) {
    return 'Вы можете загрузить до $maxImages изображений на один момент.';
  }

  @override
  String maximumImagesAddedPartial(int maxImages, int added) {
    return 'Максимум $maxImages изображений. Добавлено только $added.';
  }

  @override
  String get locationAccessRestricted => 'Доступ к местоположению ограничен';

  @override
  String get locationPermissionNeeded => 'Требуется разрешение на определение местоположения';

  @override
  String get addToYourMoment => 'Добавить к вашему моменту';

  @override
  String get categoryLabel => 'Категория';

  @override
  String get languageLabel => 'Язык';

  @override
  String get scheduleOptional => 'Запланировать (необязательно)';

  @override
  String get scheduleForLater => 'Запланировать на потом';

  @override
  String get addMore => 'Добавить ещё';

  @override
  String get howAreYouFeeling => 'Как вы себя чувствуете?';

  @override
  String get pleaseWaitOptimizingVideo => 'Пожалуйста, подождите, пока мы оптимизируем ваше видео';

  @override
  String unsupportedVideoFormat(String formats) {
    return 'Неподдерживаемый формат. Используйте: $formats';
  }

  @override
  String get chooseBackground => 'Выбрать фон';

  @override
  String likedByXPeople(int count) {
    return 'Понравилось $count людям';
  }

  @override
  String xComments(int count) {
    return '$count комментариев';
  }

  @override
  String get oneComment => '1 комментарий';

  @override
  String get addAComment => 'Добавить комментарий...';

  @override
  String viewXReplies(int count) {
    return 'Показать $count ответов';
  }

  @override
  String seenByX(int count) {
    return 'Просмотрели $count';
  }

  @override
  String xHoursAgo(int count) {
    return '$countч назад';
  }

  @override
  String xMinutesAgo(int count) {
    return '$countм назад';
  }

  @override
  String get repliedToYourStory => 'Ответил на вашу историю';

  @override
  String mentionedYouInComment(String name) {
    return '$name упомянул вас в комментарии';
  }

  @override
  String repliedToYourComment(String name) {
    return '$name ответил на ваш комментарий';
  }

  @override
  String reactedToYourComment(String name) {
    return '$name отреагировал на ваш комментарий';
  }

  @override
  String get addReaction => 'Добавить реакцию';

  @override
  String get attachImage => 'Прикрепить изображение';

  @override
  String get pickGif => 'Выбрать GIF';

  @override
  String get textStory => 'Текст';

  @override
  String get typeYourStory => 'Напишите историю...';

  @override
  String get selectBackground => 'Выбрать фон';

  @override
  String get highlightsTitle => 'Актуальное';

  @override
  String get highlightTitle => 'Название';

  @override
  String get createNewHighlight => 'Создать новое';

  @override
  String get selectStories => 'Выбрать истории';

  @override
  String get selectCover => 'Выбрать обложку';

  @override
  String get addText => 'Добавить текст';

  @override
  String get fontStyleLabel => 'Стиль шрифта';

  @override
  String get textColorLabel => 'Цвет текста';

  @override
  String get dragToDelete => 'Перетащите сюда для удаления';

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
