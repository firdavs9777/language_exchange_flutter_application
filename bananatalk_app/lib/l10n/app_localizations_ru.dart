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
  String get tryAgain => 'Попробовать снова';

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
  String get blockedUsers => 'Заблокированные пользователи';

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
  String get learning => 'Изучение';

  @override
  String get notSet => 'Не установлено';

  @override
  String get about => 'О';

  @override
  String get aboutMe => 'О себе';

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
  String get unblockUser => 'Разблокировать пользователя';

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
  String get sessionExpired => 'Сеанс истек. Пожалуйста, войдите снова.';

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
  String get enterYourPassword => 'Введите ваш пароль';

  @override
  String get yourPassword => 'Ваш пароль';

  @override
  String get typeDELETEToConfirm => 'Введите DELETE для подтверждения';

  @override
  String get typeDELETEInCapitalLetters => 'Введите DELETE заглавными буквами';

  @override
  String sent(String emoji) {
    return '$emoji отправлено!';
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
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

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
}
