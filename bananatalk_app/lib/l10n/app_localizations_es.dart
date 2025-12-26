// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'BananaTalk';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get or => 'O';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get signInWithApple => 'Iniciar sesión con Apple';

  @override
  String get signInWithFacebook => 'Iniciar sesión con Facebook';

  @override
  String get welcome => 'Bienvenido';

  @override
  String get home => 'Inicio';

  @override
  String get messages => 'Mensajes';

  @override
  String get moments => 'Momentos';

  @override
  String get profile => 'Perfil';

  @override
  String get settings => 'Configuración';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get autoTranslate => 'Traducir automáticamente';

  @override
  String get autoTranslateMessages => 'Traducir mensajes automáticamente';

  @override
  String get autoTranslateMoments => 'Traducir momentos automáticamente';

  @override
  String get autoTranslateComments => 'Traducir comentarios automáticamente';

  @override
  String get translate => 'Traducir';

  @override
  String get translated => 'Traducido';

  @override
  String get showOriginal => 'Mostrar original';

  @override
  String get showTranslation => 'Mostrar traducción';

  @override
  String get translating => 'Traduciendo...';

  @override
  String get translationFailed => 'Error en la traducción';

  @override
  String get noTranslationAvailable => 'Traducción no disponible';

  @override
  String translatedFrom(String language) {
    return 'Traducido de $language';
  }

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get share => 'Compartir';

  @override
  String get like => 'Me gusta';

  @override
  String get comment => 'Comentario';

  @override
  String get send => 'Enviar';

  @override
  String get search => 'Buscar';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get followers => 'Seguidores';

  @override
  String get following => 'Siguiendo';

  @override
  String get posts => 'Publicaciones';

  @override
  String get visitors => 'Visitantes';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get networkError => 'Error de red. Por favor verifica tu conexión.';

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get languageSettings => 'Configuración de idioma';

  @override
  String get deviceLanguage => 'Idioma del dispositivo';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return 'Tu dispositivo está configurado en: $flag $name';
  }

  @override
  String get youCanOverride => 'Puedes anular el idioma del dispositivo a continuación.';

  @override
  String languageChangedTo(String name) {
    return 'Idioma cambiado a $name';
  }

  @override
  String get errorChangingLanguage => 'Error al cambiar el idioma';

  @override
  String get autoTranslateSettings => 'Configuración de traducción automática';

  @override
  String get automaticallyTranslateIncomingMessages => 'Traducir automáticamente los mensajes entrantes';

  @override
  String get automaticallyTranslateMomentsInFeed => 'Traducir automáticamente los momentos en el feed';

  @override
  String get automaticallyTranslateComments => 'Traducir automáticamente los comentarios';

  @override
  String get translationServiceBeingConfigured => 'El servicio de traducción se está configurando. Por favor, inténtalo de nuevo más tarde.';

  @override
  String get translationUnavailable => 'Traducción no disponible';

  @override
  String get showLess => 'mostrar menos';

  @override
  String get showMore => 'mostrar más';

  @override
  String get comments => 'Comentarios';

  @override
  String get beTheFirstToComment => 'Sé el primero en comentar.';

  @override
  String get writeAComment => 'Escribir un comentario...';

  @override
  String get report => 'Reportar';

  @override
  String get reportMoment => 'Reportar momento';

  @override
  String get reportUser => 'Reportar usuario';

  @override
  String get deleteMoment => '¿Eliminar momento?';

  @override
  String get thisActionCannotBeUndone => 'Esta acción no se puede deshacer.';

  @override
  String get momentDeleted => 'Momento eliminado';

  @override
  String get editFeatureComingSoon => 'La función de edición llegará pronto';

  @override
  String get userNotFound => 'Usuario no encontrado';

  @override
  String get cannotReportYourOwnComment => 'No puedes reportar tu propio comentario';

  @override
  String get profileSettings => 'Configuración de perfil';

  @override
  String get editYourProfileInformation => 'Editar la información de tu perfil';

  @override
  String get blockedUsers => 'Usuarios bloqueados';

  @override
  String get manageBlockedUsers => 'Gestionar usuarios bloqueados';

  @override
  String get manageNotificationSettings => 'Gestionar configuración de notificaciones';

  @override
  String get privacySecurity => 'Privacidad y seguridad';

  @override
  String get controlYourPrivacy => 'Controlar tu privacidad';

  @override
  String get changeAppLanguage => 'Cambiar idioma de la aplicación';

  @override
  String get appearance => 'Apariencia';

  @override
  String get themeAndDisplaySettings => 'Configuración de tema y visualización';

  @override
  String get myReports => 'Mis reportes';

  @override
  String get viewYourSubmittedReports => 'Ver tus reportes enviados';

  @override
  String get reportsManagement => 'Gestión de reportes';

  @override
  String get manageAllReportsAdmin => 'Gestionar todos los reportes (Administrador)';

  @override
  String get legalPrivacy => 'Legal y privacidad';

  @override
  String get termsPrivacySubscriptionInfo => 'Términos, privacidad e información de suscripción';

  @override
  String get helpCenter => 'Centro de ayuda';

  @override
  String get getHelpAndSupport => 'Obtener ayuda y soporte';

  @override
  String get aboutBanaTalk => 'Acerca de BanaTalk';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get permanentlyDeleteYourAccount => 'Eliminar permanentemente tu cuenta';

  @override
  String get loggedOutSuccessfully => 'Sesión cerrada exitosamente';

  @override
  String get retry => 'Reintentar';

  @override
  String get giftsLikes => 'Regalos/Me gusta';

  @override
  String get details => 'Detalles';

  @override
  String get to => 'a';

  @override
  String get banaTalk => 'BanaTalk';

  @override
  String get community => 'Comunidad';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String yearsOld(String age) {
    return '$age años';
  }

  @override
  String get searchConversations => 'Buscar conversaciones...';

  @override
  String get visitorTrackingNotAvailable => 'La función de seguimiento de visitantes aún no está disponible. Se requiere actualización del servidor.';

  @override
  String get chatList => 'Lista de chats';

  @override
  String get languageExchange => 'Intercambio de idiomas';

  @override
  String get nativeLanguage => 'Idioma nativo';

  @override
  String get learning => 'Aprendiendo';

  @override
  String get notSet => 'No establecido';

  @override
  String get about => 'Acerca de';

  @override
  String get aboutMe => 'Acerca de mí';

  @override
  String get photos => 'Fotos';

  @override
  String get camera => 'Cámara';

  @override
  String get createMoment => 'Crear momento';

  @override
  String get addATitle => 'Agregar un título...';

  @override
  String get whatsOnYourMind => '¿En qué estás pensando?';

  @override
  String get addTags => 'Agregar etiquetas';

  @override
  String get done => 'Hecho';

  @override
  String get add => 'Agregar';

  @override
  String get enterTag => 'Ingresar etiqueta';

  @override
  String get post => 'Publicar';

  @override
  String get commentAddedSuccessfully => 'Comentario agregado exitosamente';

  @override
  String get clearFilters => 'Limpiar filtros';

  @override
  String get notificationSettings => 'Configuración de notificaciones';

  @override
  String get enableNotifications => 'Habilitar notificaciones';

  @override
  String get turnAllNotificationsOnOrOff => 'Activar o desactivar todas las notificaciones';

  @override
  String get notificationTypes => 'Tipos de notificaciones';

  @override
  String get chatMessages => 'Mensajes de chat';

  @override
  String get getNotifiedWhenYouReceiveMessages => 'Recibir notificaciones cuando recibas mensajes';

  @override
  String get likesAndCommentsOnYourMoments => 'Me gusta y comentarios en tus momentos';

  @override
  String get whenPeopleYouFollowPostMoments => 'Cuando las personas que sigues publican momentos';

  @override
  String get friendRequests => 'Solicitudes de amistad';

  @override
  String get whenSomeoneFollowsYou => 'Cuando alguien te sigue';

  @override
  String get profileVisits => 'Visitas al perfil';

  @override
  String get whenSomeoneViewsYourProfileVIP => 'Cuando alguien ve tu perfil (VIP)';

  @override
  String get marketing => 'Marketing';

  @override
  String get updatesAndPromotionalMessages => 'Actualizaciones y mensajes promocionales';

  @override
  String get notificationPreferences => 'Preferencias de notificaciones';

  @override
  String get sound => 'Sonido';

  @override
  String get playNotificationSounds => 'Reproducir sonidos de notificación';

  @override
  String get vibration => 'Vibración';

  @override
  String get vibrateOnNotifications => 'Vibrar en notificaciones';

  @override
  String get showPreview => 'Mostrar vista previa';

  @override
  String get showMessagePreviewInNotifications => 'Mostrar vista previa del mensaje en notificaciones';

  @override
  String get mutedConversations => 'Conversaciones silenciadas';

  @override
  String get conversation => 'Conversación';

  @override
  String get unmute => 'Activar sonido';

  @override
  String get systemNotificationSettings => 'Configuración de notificaciones del sistema';

  @override
  String get manageNotificationsInSystemSettings => 'Gestionar notificaciones en la configuración del sistema';

  @override
  String get errorLoadingSettings => 'Error al cargar la configuración';

  @override
  String get unblockUser => 'Desbloquear usuario';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get goBack => 'Volver';

  @override
  String get messageSendTimeout => 'Tiempo de espera de envío de mensaje. Por favor verifica tu conexión.';

  @override
  String get failedToSendMessage => 'Error al enviar mensaje';

  @override
  String get dailyMessageLimitExceeded => 'Límite diario de mensajes excedido. Actualiza a VIP para mensajes ilimitados.';

  @override
  String get cannotSendMessageUserMayBeBlocked => 'No se puede enviar mensaje. El usuario puede estar bloqueado.';

  @override
  String get sessionExpired => 'Sesión expirada. Por favor inicia sesión nuevamente.';

  @override
  String get sendThisSticker => '¿Enviar este sticker?';

  @override
  String get chooseHowYouWantToDeleteThisMessage => 'Elige cómo quieres eliminar este mensaje:';

  @override
  String get deleteForEveryone => 'Eliminar para todos';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => 'Elimina el mensaje para ti y el destinatario';

  @override
  String get deleteForMe => 'Eliminar para mí';

  @override
  String get removesTheMessageOnlyFromYourChat => 'Elimina el mensaje solo de tu chat';

  @override
  String get copy => 'Copiar';

  @override
  String get reply => 'Responder';

  @override
  String get forward => 'Reenviar';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get noUsersAvailableToForwardTo => 'No hay usuarios disponibles para reenviar';

  @override
  String get searchMoments => 'Buscar momentos...';

  @override
  String searchInChatWith(String name) {
    return 'Buscar en chat con $name';
  }

  @override
  String get typeAMessage => 'Escribe un mensaje...';

  @override
  String get enterYourMessage => 'Ingresa tu mensaje';

  @override
  String get detectYourLocation => 'Detectar tu ubicación';

  @override
  String get tapToUpdateLocation => 'Toca para actualizar ubicación';

  @override
  String get helpOthersFindYouNearby => 'Ayuda a otros a encontrarte cerca';

  @override
  String get selectYourNativeLanguage => 'Selecciona tu idioma nativo';

  @override
  String get whichLanguageDoYouWantToLearn => '¿Qué idioma quieres aprender?';

  @override
  String get selectYourGender => 'Selecciona tu género';

  @override
  String get addACaption => 'Agregar una leyenda...';

  @override
  String get typeSomething => 'Escribe algo...';

  @override
  String get gallery => 'Galería';

  @override
  String get video => 'Video';

  @override
  String get text => 'Texto';

  @override
  String get provideMoreInformation => 'Proporcionar más información...';

  @override
  String get searchByNameLanguageOrInterests => 'Buscar por nombre, idioma o intereses...';

  @override
  String get addTagAndPressEnter => 'Agrega etiqueta y presiona Enter';

  @override
  String replyTo(String name) {
    return 'Responder a $name...';
  }

  @override
  String get highlightName => 'Nombre del resaltado';

  @override
  String get searchCloseFriends => 'Buscar amigos cercanos...';

  @override
  String get askAQuestion => 'Hacer una pregunta...';

  @override
  String option(String number) {
    return 'Opción $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return '¿Por qué estás reportando este $type?';
  }

  @override
  String get additionalDetailsOptional => 'Detalles adicionales (opcional)';

  @override
  String get warningThisActionIsPermanent => '¡Advertencia: Esta acción es permanente!';

  @override
  String get deletingYourAccountWillPermanentlyRemove => 'Eliminar tu cuenta eliminará permanentemente:\n\n• Tu perfil y todos los datos personales\n• Todos tus mensajes y conversaciones\n• Todos tus momentos e historias\n• Tu suscripción VIP (sin reembolso)\n• Todas tus conexiones y seguidores\n\nEsta acción no se puede deshacer.';

  @override
  String get clearAllNotifications => '¿Eliminar todas las notificaciones?';

  @override
  String get clearAll => 'Eliminar todo';

  @override
  String get notificationDebug => 'Depuración de notificaciones';

  @override
  String get markAllRead => 'Marcar todo como leído';

  @override
  String get clearAll2 => 'Eliminar todo';

  @override
  String get emailAddress => 'Dirección de correo electrónico';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get alreadyHaveAnAccount => '¿Ya tienes una cuenta?';

  @override
  String get login2 => 'Iniciar sesión';

  @override
  String get selectYourNativeLanguage2 => 'Selecciona tu idioma nativo';

  @override
  String get whichLanguageDoYouWantToLearn2 => '¿Qué idioma quieres aprender?';

  @override
  String get selectYourGender2 => 'Selecciona tu género';

  @override
  String get dateFormat => 'YYYY.MM.DD';

  @override
  String get detectYourLocation2 => 'Detectar tu ubicación';

  @override
  String get tapToUpdateLocation2 => 'Toca para actualizar ubicación';

  @override
  String get helpOthersFindYouNearby2 => 'Ayuda a otros a encontrarte cerca';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace';

  @override
  String get legalPrivacy2 => 'Legal y Privacidad';

  @override
  String get termsOfUseEULA => 'Términos de Uso (EULA)';

  @override
  String get viewOurTermsAndConditions => 'Ver nuestros términos y condiciones';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get howWeHandleYourData => 'Cómo manejamos tus datos';

  @override
  String get emailNotifications => 'Notificaciones por correo electrónico';

  @override
  String get receiveEmailNotificationsFromBananaTalk => 'Recibir notificaciones por correo electrónico de BananaTalk';

  @override
  String get weeklySummary => 'Resumen semanal';

  @override
  String get activityRecapEverySunday => 'Resumen de actividad cada domingo';

  @override
  String get newMessages => 'Nuevos mensajes';

  @override
  String get whenYoureAwayFor24PlusHours => 'Cuando estés ausente por 24+ horas';

  @override
  String get newFollowers => 'Nuevos seguidores';

  @override
  String get whenSomeoneFollowsYou2 => 'Cuando alguien te sigue';

  @override
  String get securityAlerts => 'Alertas de seguridad';

  @override
  String get passwordLoginAlerts => 'Alertas de contraseña e inicio de sesión';

  @override
  String get unblockUser2 => 'Desbloquear usuario';

  @override
  String get blockedUsers2 => 'Usuarios bloqueados';

  @override
  String get finalWarning => '⚠️ Advertencia Final';

  @override
  String get deleteForever => 'Eliminar para siempre';

  @override
  String get deleteAccount2 => 'Eliminar cuenta';

  @override
  String get enterYourPassword => 'Ingresa tu contraseña';

  @override
  String get yourPassword => 'Tu contraseña';

  @override
  String get typeDELETEToConfirm => 'Escribe DELETE para confirmar';

  @override
  String get typeDELETEInCapitalLetters => 'Escribe DELETE en mayúsculas';

  @override
  String sent(String emoji) {
    return '¡$emoji enviado!';
  }

  @override
  String get replySent => '¡Respuesta enviada!';

  @override
  String get deleteStory => '¿Eliminar historia?';

  @override
  String get thisStoryWillBeRemovedPermanently => 'Esta historia se eliminará permanentemente.';

  @override
  String get noStories => 'Sin historias';

  @override
  String views(String count) {
    return '$count visualizaciones';
  }

  @override
  String get reportStory => 'Reportar historia';

  @override
  String get reply2 => 'Responder...';

  @override
  String get failedToPickImage => 'Error al seleccionar imagen';

  @override
  String get failedToTakePhoto => 'Error al tomar foto';

  @override
  String get failedToPickVideo => 'Error al seleccionar video';

  @override
  String get pleaseEnterSomeText => 'Por favor ingresa algún texto';

  @override
  String get pleaseSelectMedia => 'Por favor selecciona medios';

  @override
  String get storyPosted => '¡Historia publicada!';

  @override
  String get textOnlyStoriesRequireAnImage => 'Las historias solo de texto requieren una imagen';

  @override
  String get createStory => 'Crear historia';

  @override
  String get change => 'Cambiar';

  @override
  String get userIdNotFound => 'ID de usuario no encontrado. Por favor inicia sesión nuevamente.';

  @override
  String get pleaseSelectAPaymentMethod => 'Por favor selecciona un método de pago';

  @override
  String get startExploring => 'Comenzar a explorar';

  @override
  String get close => 'Cerrar';

  @override
  String get payment => 'Pago';

  @override
  String get upgradeToVIP => 'Actualizar a VIP';

  @override
  String get errorLoadingProducts => 'Error al cargar productos';

  @override
  String get cancelVIPSubscription => 'Cancelar suscripción VIP';

  @override
  String get keepVIP => 'Mantener VIP';

  @override
  String get cancelSubscription => 'Cancelar suscripción';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'Suscripción VIP cancelada exitosamente';

  @override
  String get vipStatus => 'Estado VIP';

  @override
  String get noActiveVIPSubscription => 'No hay suscripción VIP activa';

  @override
  String get unlimitedMessages => 'Mensajes ilimitados';

  @override
  String get unlimitedProfileViews => 'Visualizaciones de perfil ilimitadas';

  @override
  String get prioritySupport => 'Soporte prioritario';

  @override
  String get advancedSearch => 'Búsqueda avanzada';

  @override
  String get profileBoost => 'Impulso de perfil';

  @override
  String get adFreeExperience => 'Experiencia sin anuncios';

  @override
  String get upgradeYourAccount => 'Actualizar tu cuenta';

  @override
  String get moreMessages => 'Más mensajes';

  @override
  String get moreProfileViews => 'Más visualizaciones de perfil';

  @override
  String get connectWithFriends => 'Conectar con amigos';

  @override
  String get reviewStarted => 'Revisión iniciada';

  @override
  String get reportResolved => 'Reporte resuelto';

  @override
  String get reportDismissed => 'Reporte desestimado';

  @override
  String get selectAction => 'Seleccionar acción';

  @override
  String get noViolation => 'Sin violación';

  @override
  String get contentRemoved => 'Contenido eliminado';

  @override
  String get userWarned => 'Usuario advertido';

  @override
  String get userSuspended => 'Usuario suspendido';

  @override
  String get userBanned => 'Usuario bloqueado';

  @override
  String get addNotesOptional => 'Agregar notas (opcional)';

  @override
  String get enterModeratorNotes => 'Ingresa notas del moderador...';

  @override
  String get skip => 'Omitir';

  @override
  String get startReview => 'Iniciar revisión';

  @override
  String get resolve => 'Resolver';

  @override
  String get dismiss => 'Desestimar';

  @override
  String get filterReports => 'Filtrar reportes';

  @override
  String get all => 'Todos';

  @override
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

  @override
  String get myReports2 => 'Mis reportes';

  @override
  String get blockUser => 'Bloquear usuario';

  @override
  String get block => 'Bloquear';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => '¿También te gustaría bloquear a este usuario?';

  @override
  String get noThanks => 'No, gracias';

  @override
  String get yesBlockThem => 'Sí, bloquearlos';

  @override
  String get reportUser2 => 'Reportar usuario';

  @override
  String get submitReport => 'Enviar reporte';

  @override
  String get addAQuestionAndAtLeast2Options => 'Agregar una pregunta y al menos 2 opciones';

  @override
  String get addOption => 'Agregar opción';

  @override
  String get anonymousVoting => 'Votación anónima';

  @override
  String get create => 'Crear';

  @override
  String get typeYourAnswer => 'Escribe tu respuesta...';

  @override
  String get send2 => 'Enviar';

  @override
  String get yourPrompt => 'Tu solicitud...';

  @override
  String get add2 => 'Agregar';

  @override
  String get contentNotAvailable => 'Contenido no disponible';

  @override
  String get profileNotAvailable => 'Perfil no disponible';

  @override
  String get noMomentsToShow => 'No hay momentos para mostrar';

  @override
  String get storiesNotAvailable => 'Historias no disponibles';

  @override
  String get cantMessageThisUser => 'No se puede enviar mensaje a este usuario';

  @override
  String get pleaseSelectAReason => 'Por favor selecciona una razón';

  @override
  String get reportSubmitted => 'Reporte enviado. Gracias por ayudar a mantener segura nuestra comunidad.';

  @override
  String get youHaveAlreadyReportedThisMoment => 'Ya has reportado este momento';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => 'Cuéntanos más sobre por qué estás reportando esto';

  @override
  String get errorSharing => 'Error al compartir';

  @override
  String get deviceInfo => 'Información del dispositivo';
}
