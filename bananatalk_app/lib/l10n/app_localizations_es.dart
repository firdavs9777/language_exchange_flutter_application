// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Bananatalk';

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
  String get more => 'más';

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
  String get overview => 'Resumen';

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
  String get tryAgain => 'Reintentar';

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
  String get deleteComment => 'Delete Comment?';

  @override
  String get commentDeleted => 'Comment deleted';

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
  String get clearCache => 'Borrar caché';

  @override
  String get clearCacheSubtitle => 'Liberar espacio de almacenamiento';

  @override
  String get clearCacheDescription => 'Esto borrará todas las imágenes, videos y archivos de audio en caché. La aplicación puede cargar contenido más lento temporalmente mientras vuelve a descargar los medios.';

  @override
  String get clearCacheHint => 'Usa esto si las imágenes o el audio no se cargan correctamente.';

  @override
  String get clearingCache => 'Borrando caché...';

  @override
  String get cacheCleared => '¡Caché borrado exitosamente! Las imágenes se recargarán.';

  @override
  String get clearCacheFailed => 'Error al borrar la caché';

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
  String get aboutBananatalk => 'Acerca de Bananatalk';

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
  String get banaTalk => 'Bananatalk';

  @override
  String get chats => 'Chats';

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
  String get learning => 'Aprendizaje';

  @override
  String get notSet => 'No establecido';

  @override
  String get about => 'Acerca de';

  @override
  String get aboutMe => 'Acerca de mí';

  @override
  String get bloodType => 'Blood Type';

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
  String get sessionExpired => 'La sesión ha expirado. Por favor inicia sesión de nuevo.';

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
  String get clearAll => 'Borrar todo';

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
  String get emailNotifications => 'Notificaciones por correo';

  @override
  String get receiveEmailNotificationsFromBananatalk => 'Recibir notificaciones por correo electrónico de Bananatalk';

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
    return '¡Enviado!';
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
  String get subscriptionExpired => 'Suscripción expirada';

  @override
  String get vipExpiredMessage => 'Tu suscripción VIP ha expirado. ¡Renueva ahora para seguir disfrutando de funciones ilimitadas!';

  @override
  String get expiredOn => 'Expiró el';

  @override
  String get renewVIP => 'Renovar VIP';

  @override
  String get whatYoureMissing => 'Lo que te estás perdiendo';

  @override
  String get manageInAppStore => 'Administrar en App Store';

  @override
  String get becomeVIP => 'Ser VIP';

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
  String get clear => 'Limpiar';

  @override
  String get apply => 'Aplicar';

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

  @override
  String get recommended => 'Recomendado';

  @override
  String get anyLanguage => 'Cualquier idioma';

  @override
  String get noLanguagesFound => 'No se encontraron idiomas';

  @override
  String get selectALanguage => 'Selecciona un idioma';

  @override
  String get languagesAreStillLoading => 'Cargando idiomas...';

  @override
  String get selectNativeLanguage => 'Selecciona tu idioma nativo';

  @override
  String get subscriptionDetails => 'Detalles de suscripción';

  @override
  String get activeFeatures => 'Funciones activas';

  @override
  String get legalInformation => 'Información legal';

  @override
  String get termsOfUse => 'Términos de uso';

  @override
  String get manageSubscription => 'Gestionar suscripción';

  @override
  String get manageSubscriptionInSettings => 'Para cancelar tu suscripción, ve a Configuración > [Tu nombre] > Suscripciones en tu dispositivo.';

  @override
  String get contactSupportToCancel => 'Para cancelar tu suscripción, contacta a nuestro equipo de soporte.';

  @override
  String get status => 'Estado';

  @override
  String get active => 'Activo';

  @override
  String get plan => 'Plan';

  @override
  String get startDate => 'Fecha de inicio';

  @override
  String get endDate => 'Fecha de fin';

  @override
  String get nextBillingDate => 'Próxima fecha de facturación';

  @override
  String get autoRenew => 'Renovación automática';

  @override
  String get pleaseLogInToContinue => 'Por favor inicia sesión para continuar';

  @override
  String get purchaseCanceledOrFailed => 'La compra fue cancelada o falló. Por favor intenta de nuevo.';

  @override
  String get maximumTagsAllowed => 'Máximo 5 etiquetas permitidas';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => 'Por favor elimina las imágenes primero para agregar un video';

  @override
  String get unsupportedFormat => 'Formato no soportado';

  @override
  String get errorProcessingVideo => 'Error al procesar video';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'Por favor elimina las imágenes primero para grabar un video';

  @override
  String get locationAdded => 'Ubicación agregada';

  @override
  String get failedToGetLocation => 'Error al obtener ubicación';

  @override
  String get notNow => 'Ahora no';

  @override
  String get videoUploadFailed => 'Error al subir video';

  @override
  String get skipVideo => 'Omitir video';

  @override
  String get retryUpload => 'Reintentar subida';

  @override
  String get momentCreatedSuccessfully => 'Momento creado con éxito';

  @override
  String get uploadingMomentInBackground => 'Subiendo momento en segundo plano...';

  @override
  String get failedToQueueUpload => 'Error al agregar a la cola de subida';

  @override
  String get viewProfile => 'Ver perfil';

  @override
  String get mediaLinksAndDocs => 'Medios, enlaces y documentos';

  @override
  String get wallpaper => 'Fondo de pantalla';

  @override
  String get userIdNotAvailable => 'ID de usuario no disponible';

  @override
  String get cannotBlockYourself => 'No puedes bloquearte a ti mismo';

  @override
  String get chatWallpaper => 'Fondo de chat';

  @override
  String get wallpaperSavedLocally => 'Fondo guardado localmente';

  @override
  String get messageCopied => 'Mensaje copiado';

  @override
  String get forwardFeatureComingSoon => 'La función de reenvío llegará pronto';

  @override
  String get momentUnsaved => 'Eliminado de guardados';

  @override
  String get documentPickerComingSoon => 'Selector de documentos llegará pronto';

  @override
  String get contactSharingComingSoon => 'Compartir contactos llegará pronto';

  @override
  String get featureComingSoon => 'Función llegará pronto';

  @override
  String get answerSent => '¡Respuesta enviada!';

  @override
  String get noImagesAvailable => 'No hay imágenes disponibles';

  @override
  String get mentionPickerComingSoon => 'Selector de menciones llegará pronto';

  @override
  String get musicPickerComingSoon => 'Selector de música llegará pronto';

  @override
  String get repostFeatureComingSoon => 'Función de republicar llegará pronto';

  @override
  String get addFriendsFromYourProfile => 'Agrega amigos desde tu perfil';

  @override
  String get quickReplyAdded => 'Respuesta rápida agregada';

  @override
  String get quickReplyDeleted => 'Respuesta rápida eliminada';

  @override
  String get linkCopied => '¡Enlace copiado!';

  @override
  String get maximumOptionsAllowed => 'Máximo 10 opciones permitidas';

  @override
  String get minimumOptionsRequired => 'Mínimo 2 opciones requeridas';

  @override
  String get pleaseEnterAQuestion => 'Por favor ingresa una pregunta';

  @override
  String get pleaseAddAtLeast2Options => 'Por favor agrega al menos 2 opciones';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => 'Por favor selecciona la respuesta correcta para el cuestionario';

  @override
  String get correctionSent => '¡Corrección enviada!';

  @override
  String get sort => 'Ordenar';

  @override
  String get savedMoments => 'Momentos guardados';

  @override
  String get unsave => 'Eliminar de guardados';

  @override
  String get playingAudio => 'Reproduciendo audio...';

  @override
  String get failedToGenerateQuiz => 'Error al generar cuestionario';

  @override
  String get failedToAddComment => 'Error al agregar comentario';

  @override
  String get hello => '¡Hola!';

  @override
  String get howAreYou => '¿Cómo estás?';

  @override
  String get cannotOpen => 'No se puede abrir';

  @override
  String get errorOpeningLink => 'Error al abrir enlace';

  @override
  String get saved => 'Guardado';

  @override
  String get follow => 'Seguir';

  @override
  String get unfollow => 'Dejar de seguir';

  @override
  String get mute => 'Silenciar';

  @override
  String get online => 'En línea';

  @override
  String get offline => 'Desconectado';

  @override
  String get lastSeen => 'Última vez';

  @override
  String get justNow => 'ahora mismo';

  @override
  String minutesAgo(String count) {
    return 'hace $count minutos';
  }

  @override
  String hoursAgo(String count) {
    return 'hace $count horas';
  }

  @override
  String get yesterday => 'Ayer';

  @override
  String get signInWithEmail => 'Iniciar sesión con correo';

  @override
  String get partners => 'Compañeros';

  @override
  String get nearby => 'Cercanos';

  @override
  String get topics => 'Temas';

  @override
  String get waves => 'Saludos';

  @override
  String get voiceRooms => 'Voz';

  @override
  String get filters => 'Filtros';

  @override
  String get searchCommunity => 'Buscar por nombre, idioma o intereses...';

  @override
  String get bio => 'Biografía';

  @override
  String get noBioYet => 'Sin biografía disponible aún.';

  @override
  String get languages => 'Idiomas';

  @override
  String get native => 'Nativo';

  @override
  String get interests => 'Intereses';

  @override
  String get noMomentsYet => 'Sin momentos aún';

  @override
  String get unableToLoadMoments => 'No se pueden cargar los momentos';

  @override
  String get map => 'Mapa';

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
  String get openSettings => 'Abrir ajustes';

  @override
  String get refresh => 'Refresh';

  @override
  String get videoCall => 'Video';

  @override
  String get voiceCall => 'Llamar';

  @override
  String get message => 'Mensaje';

  @override
  String get pleaseLoginToFollow => 'Por favor inicia sesión para seguir usuarios';

  @override
  String get pleaseLoginToCall => 'Por favor inicia sesión para hacer una llamada';

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
  String get soon => 'Pronto';

  @override
  String comingSoon(String feature) {
    return '¡$feature próximamente!';
  }

  @override
  String get muteNotifications => 'Silenciar notificaciones';

  @override
  String get unmuteNotifications => 'Activar notificaciones';

  @override
  String get operationCompleted => 'Operación completada';

  @override
  String get couldNotOpenMaps => 'No se pudo abrir el mapa';

  @override
  String hasntSharedMoments(Object name) {
    return '$name no ha compartido momentos aún';
  }

  @override
  String messageUser(String name) {
    return 'Mensaje a $name';
  }

  @override
  String notFollowingUser(String name) {
    return 'No estabas siguiendo a $name';
  }

  @override
  String youFollowedUser(String name) {
    return 'Seguiste a $name';
  }

  @override
  String youUnfollowedUser(String name) {
    return 'Dejaste de seguir a $name';
  }

  @override
  String unfollowUser(String name) {
    return 'Dejar de seguir a $name';
  }

  @override
  String get typing => 'escribiendo';

  @override
  String get connecting => 'Conectando...';

  @override
  String daysAgo(int count) {
    return 'hace ${count}d';
  }

  @override
  String get maxTagsAllowed => 'Máximo 5 etiquetas permitidas';

  @override
  String maxImagesAllowed(int count) {
    return 'Máximo $count imágenes permitidas';
  }

  @override
  String get pleaseRemoveImagesFirst => 'Por favor elimina las imágenes primero';

  @override
  String get exchange3MessagesBeforeCall => 'Necesitas intercambiar al menos 3 mensajes antes de llamar';

  @override
  String mediaWithUser(String name) {
    return 'Media con $name';
  }

  @override
  String get errorLoadingMedia => 'Error al cargar media';

  @override
  String get savedMomentsTitle => 'Momentos guardados';

  @override
  String get removeBookmark => '¿Eliminar de guardados?';

  @override
  String get thisWillRemoveBookmark => 'Esto eliminará el mensaje de tus marcadores.';

  @override
  String get remove => 'Eliminar';

  @override
  String get bookmarkRemoved => 'Guardado eliminado';

  @override
  String get bookmarkedMessages => 'Mensajes guardados';

  @override
  String get wallpaperSaved => 'Fondo guardado localmente';

  @override
  String get typeDeleteToConfirm => 'Escribe DELETE para confirmar';

  @override
  String get storyArchive => 'Archivo de historias';

  @override
  String get newHighlight => 'Nuevo destacado';

  @override
  String get addToHighlight => 'Añadir a destacados';

  @override
  String get repost => 'Republicar';

  @override
  String get repostFeatureSoon => 'Función de republicar próximamente';

  @override
  String get closeFriends => 'Amigos cercanos';

  @override
  String get addFriends => 'Agregar amigos';

  @override
  String get highlights => 'Destacados';

  @override
  String get createHighlight => 'Crear destacado';

  @override
  String get deleteHighlight => 'Eliminar destacado';

  @override
  String get editHighlight => 'Editar destacado';

  @override
  String get addMoreToStory => 'Agregar más a la historia';

  @override
  String get noViewersYet => 'Aún no hay espectadores';

  @override
  String get noReactionsYet => 'Aún no hay reacciones';

  @override
  String get leaveRoom => 'Salir de sala';

  @override
  String get areYouSureLeaveRoom => '¿Estás seguro de que quieres salir?';

  @override
  String get stay => 'Quedarse';

  @override
  String get leave => 'Salir';

  @override
  String get enableGPS => 'Habilitar GPS';

  @override
  String wavedToUser(String name) {
    return '¡Saludaste a $name!';
  }

  @override
  String get areYouSureFollow => '¿Estás seguro de que quieres seguir a';

  @override
  String get failedToLoadProfile => 'Error al cargar el perfil';

  @override
  String get noFollowersYet => 'Aún no hay seguidores';

  @override
  String get noFollowingYet => 'Aún no sigues a nadie';

  @override
  String get searchUsers => 'Buscar usuarios...';

  @override
  String get noResultsFound => 'No se encontraron resultados';

  @override
  String get loadingFailed => 'Error de carga';

  @override
  String get copyLink => 'Copiar enlace';

  @override
  String get shareStory => 'Compartir historia';

  @override
  String get thisWillDeleteStory => 'Esto eliminará permanentemente esta historia.';

  @override
  String get storyDeleted => 'Historia eliminada';

  @override
  String get addCaption => 'Añadir descripción...';

  @override
  String get yourStory => 'Tu historia';

  @override
  String get sendMessage => 'Enviar mensaje';

  @override
  String get replyToStory => 'Responder a historia...';

  @override
  String get viewAllReplies => 'Ver todas las respuestas';

  @override
  String get preparingVideo => 'Preparando video...';

  @override
  String videoOptimized(String size, String savings) {
    return 'Video optimizado: ${size}MB (ahorro $savings%)';
  }

  @override
  String get failedToProcessVideo => 'Error al procesar el video';

  @override
  String get optimizingForBestExperience => 'Optimizando para la mejor experiencia';

  @override
  String get pleaseSelectImageOrVideo => 'Por favor selecciona una imagen o video para tu historia';

  @override
  String get storyCreatedSuccessfully => '¡Historia creada exitosamente!';

  @override
  String get uploadingStoryInBackground => 'Subiendo historia en segundo plano...';

  @override
  String get storyCreationFailed => 'Error al crear historia';

  @override
  String get pleaseCheckConnection => 'Por favor verifica tu conexión e intenta de nuevo.';

  @override
  String get uploadFailed => 'Error de subida';

  @override
  String get tryShorterVideo => 'Intenta con un video más corto o inténtalo más tarde.';

  @override
  String get shareMomentsThatDisappear => 'Comparte momentos que desaparecen en 24 horas';

  @override
  String get photo => 'Foto';

  @override
  String get record => 'Grabar';

  @override
  String get addSticker => 'Añadir sticker';

  @override
  String get poll => 'Encuesta';

  @override
  String get question => 'Pregunta';

  @override
  String get mention => 'Mención';

  @override
  String get music => 'Música';

  @override
  String get hashtag => 'Hashtag';

  @override
  String get whoCanSeeThis => '¿Quién puede ver esto?';

  @override
  String get everyone => 'Todos';

  @override
  String get anyoneCanSeeStory => 'Cualquiera puede ver esta historia';

  @override
  String get friendsOnly => 'Solo amigos';

  @override
  String get onlyFollowersCanSee => 'Solo tus seguidores pueden ver';

  @override
  String get onlyCloseFriendsCanSee => 'Solo tus amigos cercanos pueden ver';

  @override
  String get backgroundColor => 'Color de fondo';

  @override
  String get fontStyle => 'Estilo de fuente';

  @override
  String get normal => 'Normal';

  @override
  String get bold => 'Negrita';

  @override
  String get italic => 'Cursiva';

  @override
  String get handwriting => 'Manuscrita';

  @override
  String get addLocation => 'Agregar ubicación';

  @override
  String get enterLocationName => 'Ingresa el nombre del lugar';

  @override
  String get addLink => 'Agregar enlace';

  @override
  String get buttonText => 'Texto del botón';

  @override
  String get learnMore => 'Más información';

  @override
  String get addHashtags => 'Agregar hashtags';

  @override
  String get addHashtag => 'Agregar hashtag';

  @override
  String get sendAsMessage => 'Enviar como mensaje';

  @override
  String get shareExternally => 'Compartir externamente';

  @override
  String get checkOutStory => '¡Mira esta historia en Bananatalk!';

  @override
  String viewsTab(String count) {
    return 'Vistas ($count)';
  }

  @override
  String reactionsTab(String count) {
    return 'Reacciones ($count)';
  }

  @override
  String get processingVideo => 'Procesando video...';

  @override
  String get link => 'Enlace';

  @override
  String unmuteUser(String name) {
    return '¿Desactivar silencio de $name?';
  }

  @override
  String get willReceiveNotifications => 'Recibirás notificaciones de nuevos mensajes.';

  @override
  String muteNotificationsFor(String name) {
    return 'Silenciar notificaciones de $name';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return 'Notificaciones activadas para $name';
  }

  @override
  String notificationsMutedFor(String name) {
    return 'Notificaciones silenciadas para $name';
  }

  @override
  String get failedToUpdateMuteSettings => 'Error al actualizar configuración de silencio';

  @override
  String get oneHour => '1 hora';

  @override
  String get eightHours => '8 horas';

  @override
  String get oneWeek => '1 semana';

  @override
  String get always => 'Siempre';

  @override
  String get failedToLoadBookmarks => 'Error al cargar guardados';

  @override
  String get noBookmarkedMessages => 'No hay mensajes guardados';

  @override
  String get longPressToBookmark => 'Mantén presionado un mensaje para guardarlo';

  @override
  String get thisWillRemoveFromBookmarks => 'Esto eliminará el mensaje de tus guardados.';

  @override
  String navigateToMessage(String name) {
    return 'Ir al mensaje en chat con $name';
  }

  @override
  String bookmarkedOn(String date) {
    return 'Guardado el $date';
  }

  @override
  String get voiceMessage => 'Mensaje de voz';

  @override
  String get document => 'Documento';

  @override
  String get attachment => 'Adjunto';

  @override
  String get sendMeAMessage => 'Envíame un mensaje';

  @override
  String get shareWithFriends => 'Compartir con amigos';

  @override
  String get shareAnywhere => 'Compartir en cualquier lugar';

  @override
  String get emailPreferences => 'Preferencias de correo';

  @override
  String get receiveEmailNotifications => 'Recibir notificaciones por correo de Bananatalk';

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
  String get category => 'Categoría';

  @override
  String get mood => 'Estado de ánimo';

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
  String get applyFilters => 'Aplicar filtros';

  @override
  String applyNFilters(int count) {
    return 'Apply $count Filters';
  }

  @override
  String get videoMustBeUnder1GB => 'El video debe ser menor a 1GB.';

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
  String get edited => '(editado)';

  @override
  String get now => 'ahora';

  @override
  String weeksAgo(int count) {
    return 'hace ${count}sem';
  }

  @override
  String viewRepliesCount(int count) {
    return '── Ver $count respuestas';
  }

  @override
  String get hideReplies => '── Ocultar respuestas';

  @override
  String get saveMoment => 'Guardar momento';

  @override
  String get removeFromSaved => 'Quitar de guardados';

  @override
  String get momentSaved => 'Guardado';

  @override
  String get failedToSave => 'Error al guardar';

  @override
  String get checkOutMoment => '¡Mira este momento en Bananatalk!';

  @override
  String get failedToLoadMoments => 'Error al cargar momentos';

  @override
  String get noMomentsMatchFilters => 'No hay momentos que coincidan con tus filtros';

  @override
  String get beFirstToShareMoment => '¡Sé el primero en compartir un momento!';

  @override
  String get tryDifferentSearch => 'Prueba con otro término de búsqueda';

  @override
  String get tryAdjustingFilters => 'Intenta ajustar tus filtros';

  @override
  String get noSavedMoments => 'No hay momentos guardados';

  @override
  String get tapBookmarkToSave => 'Toca el icono de marcador para guardar un momento';

  @override
  String get failedToLoadVideo => 'Error al cargar el video';

  @override
  String get titleRequired => 'El título es obligatorio';

  @override
  String titleTooLong(int max) {
    return 'El título debe tener $max caracteres o menos';
  }

  @override
  String get descriptionRequired => 'La descripción es obligatoria';

  @override
  String descriptionTooLong(int max) {
    return 'La descripción debe tener $max caracteres o menos';
  }

  @override
  String get scheduledDateMustBeFuture => 'La fecha programada debe ser futura';

  @override
  String get recent => 'Reciente';

  @override
  String get popular => 'Popular';

  @override
  String get trending => 'Tendencia';

  @override
  String get mostRecent => 'Más reciente';

  @override
  String get mostPopular => 'Más popular';

  @override
  String get allTime => 'Todo';

  @override
  String get today => 'Hoy';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get thisMonth => 'Este mes';

  @override
  String replyingTo(String userName) {
    return 'Respondiendo a $userName';
  }

  @override
  String get listView => 'Vista de lista';

  @override
  String get quickMatch => 'Emparejamiento rápido';

  @override
  String get onlineNow => 'En línea ahora';

  @override
  String speaksLanguage(String language) {
    return 'Habla $language';
  }

  @override
  String learningLanguage(String language) {
    return 'Aprende $language';
  }

  @override
  String get noPartnersFound => 'No se encontraron compañeros';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return 'No se encontraron usuarios para $learning y $native';
  }

  @override
  String get removeAllFilters => 'Eliminar todos los filtros';

  @override
  String get browseAllUsers => 'Ver todos los usuarios';

  @override
  String get allCaughtUp => '¡Estás al día!';

  @override
  String get loadingMore => 'Cargando más...';

  @override
  String get findingMorePartners => 'Buscando más compañeros...';

  @override
  String get seenAllPartners => 'Has visto todos los compañeros';

  @override
  String get startOver => 'Empezar de nuevo';

  @override
  String get changeFilters => 'Cambiar filtros';

  @override
  String get findingPartners => 'Buscando compañeros...';

  @override
  String get setLocationReminder => 'Configura tu ubicación para encontrar compañeros cercanos';

  @override
  String get updateLocationReminder => 'Actualiza tu ubicación para mejores resultados';

  @override
  String get male => 'Masculino';

  @override
  String get female => 'Femenino';

  @override
  String get other => 'Otro';

  @override
  String get browseMen => 'Ver hombres';

  @override
  String get browseWomen => 'Ver mujeres';

  @override
  String get noMaleUsersFound => 'No se encontraron usuarios masculinos';

  @override
  String get noFemaleUsersFound => 'No se encontraron usuarios femeninos';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => 'Solo nuevos usuarios';

  @override
  String get showNewUsers => 'Mostrar usuarios nuevos';

  @override
  String get prioritizeNearby => 'Priorizar cercanos';

  @override
  String get showNearbyFirst => 'Mostrar cercanos primero';

  @override
  String get setLocationToEnable => 'Configura tu ubicación para activar';

  @override
  String get radius => 'Radio';

  @override
  String get findingYourLocation => 'Detectando tu ubicación...';

  @override
  String get enableLocationForDistance => 'Activa la ubicación para ver distancias';

  @override
  String get enableLocationDescription => 'Permite el acceso a la ubicación para encontrar compañeros de idiomas cerca de ti';

  @override
  String get enableGps => 'Activar GPS';

  @override
  String get browseByCityCountry => 'Buscar por ciudad o país';

  @override
  String get peopleNearby => 'Personas cerca';

  @override
  String get noNearbyUsersFound => 'No se encontraron usuarios cercanos';

  @override
  String get tryExpandingSearch => 'Intenta ampliar tu búsqueda';

  @override
  String get exploreByCity => 'Explorar por ciudad';

  @override
  String get exploreByCurrentCity => 'Explorar por tu ciudad actual';

  @override
  String get interactiveWorldMap => 'Mapa mundial interactivo';

  @override
  String get searchByCityName => 'Buscar por nombre de ciudad';

  @override
  String get seeUserCountsPerCountry => 'Ver cantidad de usuarios por país';

  @override
  String get upgradeToVip => 'Mejorar a VIP';

  @override
  String get searchByCity => 'Buscar por ciudad';

  @override
  String usersWorldwide(String count) {
    return '$count usuarios en todo el mundo';
  }

  @override
  String get noUsersFound => 'No se encontraron usuarios';

  @override
  String get tryDifferentCity => 'Prueba con otra ciudad';

  @override
  String usersCount(String count) {
    return '$count usuarios';
  }

  @override
  String get searchCountry => 'Buscar país...';

  @override
  String get wave => 'Saludar';

  @override
  String get newUser => 'Nuevo';

  @override
  String get warningPermanent => '¡Advertencia: esta acción es permanente!';

  @override
  String get deleteAccountWarning => 'Eliminar tu cuenta borrará permanentemente todos tus datos, mensajes, momentos y conexiones. Esta acción no se puede deshacer.';

  @override
  String get requiredForEmailOnly => 'Obligatorio solo para cuentas de correo electrónico';

  @override
  String get pleaseEnterPassword => 'Por favor ingresa tu contraseña';

  @override
  String get typeDELETE => 'Escribe DELETE';

  @override
  String get mustTypeDELETE => 'Debes escribir DELETE para confirmar';

  @override
  String get deletingAccount => 'Eliminando cuenta...';

  @override
  String get deleteMyAccountPermanently => 'Eliminar mi cuenta permanentemente';

  @override
  String get whatsYourNativeLanguage => '¿Cuál es tu idioma nativo?';

  @override
  String get helpsMatchWithLearners => 'Ayuda a emparejarte con estudiantes de tu idioma';

  @override
  String get whatAreYouLearning => '¿Qué estás aprendiendo?';

  @override
  String get connectWithNativeSpeakers => 'Conéctate con hablantes nativos';

  @override
  String get selectLearningLanguage => 'Selecciona el idioma que aprendes';

  @override
  String get selectCurrentLevel => 'Selecciona tu nivel actual';

  @override
  String get beginner => 'Principiante';

  @override
  String get elementary => 'Elemental';

  @override
  String get intermediate => 'Intermedio';

  @override
  String get upperIntermediate => 'Intermedio alto';

  @override
  String get advanced => 'Avanzado';

  @override
  String get proficient => 'Competente';

  @override
  String get showingPartnersByDistance => 'Mostrando compañeros por distancia';

  @override
  String get enableLocationForResults => 'Activa la ubicación para obtener resultados';

  @override
  String get enable => 'Activar';

  @override
  String get locationNotSet => 'Ubicación no configurada';

  @override
  String get tellUsAboutYourself => 'Cuéntanos sobre ti';

  @override
  String get justACoupleQuickThings => 'Solo un par de cosas rápidas';

  @override
  String get gender => 'Género';

  @override
  String get birthDate => 'Fecha de nacimiento';

  @override
  String get selectYourBirthDate => 'Selecciona tu fecha de nacimiento';

  @override
  String get continueButton => 'Continuar';

  @override
  String get pleaseSelectGender => 'Por favor selecciona tu género';

  @override
  String get pleaseSelectBirthDate => 'Por favor selecciona tu fecha de nacimiento';

  @override
  String get mustBe18 => 'Debes tener al menos 18 años';

  @override
  String get invalidDate => 'Fecha no válida';

  @override
  String get almostDone => '¡Casi listo!';

  @override
  String get addPhotoLocationForMatches => 'Agrega una foto y ubicación para mejores coincidencias';

  @override
  String get addProfilePhoto => 'Agregar foto de perfil';

  @override
  String get optionalUpTo6Photos => 'Opcional — hasta 6 fotos';

  @override
  String get requiredUpTo6Photos => 'Obligatorio — hasta 6 fotos';

  @override
  String get profilePhotoRequired => 'Agrega al menos una foto de perfil';

  @override
  String get locationOptional => 'La ubicación es opcional — puedes agregarla después';

  @override
  String get maximum6Photos => 'Máximo 6 fotos';

  @override
  String get tapToDetectLocation => 'Toca para detectar ubicación';

  @override
  String get optionalHelpsNearbyPartners => 'Opcional — ayuda a encontrar compañeros cercanos';

  @override
  String get startLearning => 'Empezar a aprender';

  @override
  String get photoLocationOptional => 'La foto y ubicación son opcionales';

  @override
  String get pleaseAcceptTerms => 'Por favor acepta los términos de servicio';

  @override
  String get iAgreeToThe => 'Acepto los';

  @override
  String get termsOfService => 'Términos de servicio';

  @override
  String get tapToSelectLanguage => 'Toca para seleccionar idioma';

  @override
  String yourLevelIn(String language) {
    return 'Tu nivel en $language';
  }

  @override
  String get yourCurrentLevel => 'Tu nivel actual';

  @override
  String get nativeCannotBeSameAsLearning => 'El idioma nativo no puede ser el mismo que el idioma que aprendes';

  @override
  String get learningCannotBeSameAsNative => 'El idioma que aprendes no puede ser el mismo que tu idioma nativo';

  @override
  String stepOf(String current, String total) {
    return 'Paso $current de $total';
  }

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get registerLink => 'Registrarse';

  @override
  String get pleaseEnterBothEmailAndPassword => 'Por favor ingresa tu correo y contraseña';

  @override
  String get pleaseEnterValidEmail => 'Por favor ingresa un correo válido';

  @override
  String get loginSuccessful => '¡Inicio de sesión exitoso!';

  @override
  String get stepOneOfTwo => 'Paso 1 de 2';

  @override
  String get createYourAccount => 'Crea tu cuenta';

  @override
  String get basicInfoToGetStarted => 'Información básica para comenzar';

  @override
  String get emailVerifiedLabel => 'Correo (Verificado)';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get yourDisplayName => 'Tu nombre visible';

  @override
  String get atLeast8Characters => 'Al menos 8 caracteres';

  @override
  String get confirmPasswordHint => 'Confirmar contraseña';

  @override
  String get nextButton => 'Siguiente';

  @override
  String get pleaseEnterYourName => 'Por favor ingresa tu nombre';

  @override
  String get pleaseEnterAPassword => 'Por favor ingresa una contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get otherGender => 'Otro';

  @override
  String get continueWithGoogleAccount => 'Continúa con tu cuenta de Google\npara una experiencia fluida';

  @override
  String get signingYouIn => 'Iniciando sesión...';

  @override
  String get backToSignInMethods => 'Volver a métodos de inicio de sesión';

  @override
  String get securedByGoogle => 'Protegido por Google';

  @override
  String get dataProtectedEncryption => 'Tus datos están protegidos con encriptación estándar';

  @override
  String get welcomeCompleteProfile => '¡Bienvenido! Por favor completa tu perfil';

  @override
  String welcomeBackName(String name) {
    return '¡Bienvenido de vuelta, $name!';
  }

  @override
  String get continueWithAppleId => 'Continúa con tu Apple ID\npara una experiencia segura';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get securedByApple => 'Protegido por Apple';

  @override
  String get privacyProtectedApple => 'Tu privacidad está protegida con Apple Sign-In';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get enterEmailToGetStarted => 'Ingresa tu correo para comenzar';

  @override
  String get continueText => 'Continuar';

  @override
  String get pleaseEnterEmailAddress => 'Por favor ingresa tu correo electrónico';

  @override
  String get verificationCodeSent => '¡Código de verificación enviado a tu correo!';

  @override
  String get forgotPasswordTitle => 'Olvidé mi contraseña';

  @override
  String get resetPasswordTitle => 'Restablecer contraseña';

  @override
  String get enterEmailForResetCode => 'Ingresa tu correo y te enviaremos un código para restablecer tu contraseña';

  @override
  String get sendResetCode => 'Enviar código';

  @override
  String get resetCodeSent => '¡Código de restablecimiento enviado!';

  @override
  String get rememberYourPassword => '¿Recuerdas tu contraseña?';

  @override
  String get verifyCode => 'Verificar código';

  @override
  String get enterResetCode => 'Ingresa el código';

  @override
  String get weSentCodeTo => 'Enviamos un código de 6 dígitos a';

  @override
  String get pleaseEnterAll6Digits => 'Por favor ingresa los 6 dígitos';

  @override
  String get codeVerifiedCreatePassword => '¡Código verificado! Crea tu nueva contraseña';

  @override
  String get verify => 'Verificar';

  @override
  String get didntReceiveCode => '¿No recibiste el código?';

  @override
  String get resend => 'Reenviar';

  @override
  String resendWithTimer(String timer) {
    return 'Reenviar (${timer}s)';
  }

  @override
  String get resetCodeResent => '¡Código reenviado!';

  @override
  String get verifyEmail => 'Verificar correo';

  @override
  String get verifyYourEmail => 'Verifica tu correo';

  @override
  String get emailVerifiedSuccessfully => '¡Correo verificado exitosamente!';

  @override
  String get verificationCodeResent => '¡Código de verificación reenviado!';

  @override
  String get createNewPassword => 'Crear nueva contraseña';

  @override
  String get enterNewPasswordBelow => 'Ingresa tu nueva contraseña abajo';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get confirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get pleaseFillAllFields => 'Por favor completa todos los campos';

  @override
  String get passwordResetSuccessful => '¡Contraseña restablecida! Inicia sesión con tu nueva contraseña';

  @override
  String get privacyTitle => 'Privacidad';

  @override
  String get profileVisibility => 'Visibilidad del perfil';

  @override
  String get showCountryRegion => 'Mostrar país/región';

  @override
  String get showCountryRegionDesc => 'Muestra tu país en tu perfil';

  @override
  String get showCity => 'Mostrar ciudad';

  @override
  String get showCityDesc => 'Muestra tu ciudad en tu perfil';

  @override
  String get showAge => 'Mostrar edad';

  @override
  String get showAgeDesc => 'Muestra tu edad en tu perfil';

  @override
  String get showZodiacSign => 'Mostrar signo zodiacal';

  @override
  String get showZodiacSignDesc => 'Muestra tu signo zodiacal en tu perfil';

  @override
  String get onlineStatusSection => 'Estado en línea';

  @override
  String get showOnlineStatus => 'Mostrar estado en línea';

  @override
  String get showOnlineStatusDesc => 'Permite que otros vean cuando estás en línea';

  @override
  String get otherSettings => 'Otros ajustes';

  @override
  String get showGiftingLevel => 'Mostrar nivel de regalos';

  @override
  String get showGiftingLevelDesc => 'Muestra tu insignia de nivel de regalos';

  @override
  String get birthdayNotifications => 'Notificaciones de cumpleaños';

  @override
  String get birthdayNotificationsDesc => 'Recibe notificaciones en tu cumpleaños';

  @override
  String get personalizedAds => 'Anuncios personalizados';

  @override
  String get personalizedAdsDesc => 'Permitir anuncios personalizados';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get privacySettingsSaved => 'Configuración de privacidad guardada';

  @override
  String get locationSection => 'Ubicación';

  @override
  String get updateLocation => 'Actualizar ubicación';

  @override
  String get updateLocationDesc => 'Actualiza tu ubicación actual';

  @override
  String get currentLocation => 'Ubicación actual';

  @override
  String get locationNotAvailable => 'Ubicación no disponible';

  @override
  String get locationUpdated => 'Ubicación actualizada correctamente';

  @override
  String get locationPermissionDenied => 'Permiso de ubicación denegado. Actívalo en ajustes.';

  @override
  String get locationServiceDisabled => 'Los servicios de ubicación están desactivados. Actívalos.';

  @override
  String get updatingLocation => 'Actualizando ubicación...';

  @override
  String get locationCouldNotBeUpdated => 'No se pudo actualizar la ubicación';

  @override
  String get incomingAudioCall => 'Llamada de audio entrante';

  @override
  String get incomingVideoCall => 'Videollamada entrante';

  @override
  String get outgoingCall => 'Llamando...';

  @override
  String get callRinging => 'Sonando...';

  @override
  String get callConnecting => 'Conectando...';

  @override
  String get callConnected => 'Conectado';

  @override
  String get callReconnecting => 'Reconectando...';

  @override
  String get callEnded => 'Llamada finalizada';

  @override
  String get callFailed => 'Llamada fallida';

  @override
  String get callMissed => 'Llamada perdida';

  @override
  String get callDeclined => 'Llamada rechazada';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => 'Aceptar';

  @override
  String get declineCall => 'Rechazar';

  @override
  String get endCall => 'Finalizar';

  @override
  String get muteCall => 'Silenciar';

  @override
  String get unmuteCall => 'Activar sonido';

  @override
  String get speakerOn => 'Altavoz';

  @override
  String get speakerOff => 'Auricular';

  @override
  String get videoOn => 'Video activado';

  @override
  String get videoOff => 'Video desactivado';

  @override
  String get switchCamera => 'Cambiar cámara';

  @override
  String get callPermissionDenied => 'Se requiere permiso de micrófono para llamadas';

  @override
  String get cameraPermissionDenied => 'Se requiere permiso de cámara para videollamadas';

  @override
  String get callConnectionFailed => 'No se pudo conectar. Por favor, inténtalo de nuevo.';

  @override
  String get userBusy => 'Usuario ocupado';

  @override
  String get userOffline => 'Usuario desconectado';

  @override
  String get callHistory => 'Historial de llamadas';

  @override
  String get noCallHistory => 'Sin historial de llamadas';

  @override
  String get missedCalls => 'Llamadas perdidas';

  @override
  String get allCalls => 'Todas las llamadas';

  @override
  String get callBack => 'Devolver llamada';

  @override
  String callAt(String time) {
    return 'Llamada a las $time';
  }

  @override
  String get audioCall => 'Llamada de audio';

  @override
  String get voiceRoom => 'Sala de voz';

  @override
  String get noVoiceRooms => 'No hay salas de voz activas';

  @override
  String get createVoiceRoom => 'Crear sala de voz';

  @override
  String get joinRoom => 'Unirse a sala';

  @override
  String get leaveRoomConfirm => '¿Salir de la sala?';

  @override
  String get leaveRoomMessage => '¿Estás seguro de que quieres salir de esta sala?';

  @override
  String get roomTitle => 'Título de sala';

  @override
  String get roomTitleHint => 'Ingresa el título de la sala';

  @override
  String get roomTopic => 'Tema';

  @override
  String get roomLanguage => 'Idioma';

  @override
  String get roomHost => 'Anfitrión';

  @override
  String roomParticipants(int count) {
    return '$count participantes';
  }

  @override
  String roomMaxParticipants(int count) {
    return 'Máx. $count participantes';
  }

  @override
  String get selectTopic => 'Seleccionar tema';

  @override
  String get raiseHand => 'Levantar mano';

  @override
  String get lowerHand => 'Bajar mano';

  @override
  String get handRaisedNotification => '¡Mano levantada! El anfitrión verá tu solicitud.';

  @override
  String get handLoweredNotification => 'Mano bajada';

  @override
  String get muteParticipant => 'Silenciar participante';

  @override
  String get kickParticipant => 'Remover de la sala';

  @override
  String get promoteToCoHost => 'Hacer coanfitrión';

  @override
  String get endRoomConfirm => '¿Finalizar sala?';

  @override
  String get endRoomMessage => 'Esto finalizará la sala para todos los participantes.';

  @override
  String get roomEnded => 'Sala finalizada por el anfitrión';

  @override
  String get youWereRemoved => 'Fuiste removido de la sala';

  @override
  String get roomIsFull => 'La sala está llena';

  @override
  String get roomChat => 'Chat de sala';

  @override
  String get noMessages => 'Sin mensajes aún';

  @override
  String get typeMessage => 'Escribe un mensaje...';

  @override
  String get voiceRoomsDescription => 'Únete a conversaciones en vivo y practica hablando';

  @override
  String liveRoomsCount(int count) {
    return '$count en vivo';
  }

  @override
  String get noActiveRooms => 'Sin salas activas';

  @override
  String get noActiveRoomsDescription => '¡Sé el primero en iniciar una sala de voz y practica hablando con otros!';

  @override
  String get startRoom => 'Iniciar sala';

  @override
  String get createRoom => 'Crear sala';

  @override
  String get roomCreated => '¡Sala creada exitosamente!';

  @override
  String get failedToCreateRoom => 'Error al crear sala';

  @override
  String get errorLoadingRooms => 'Error al cargar salas';

  @override
  String get pleaseEnterRoomTitle => 'Por favor ingresa un título de sala';

  @override
  String get startLiveConversation => 'Iniciar conversación en vivo';

  @override
  String get maxParticipants => 'Máx. participantes';

  @override
  String nPeople(int count) {
    return '$count personas';
  }

  @override
  String hostedBy(String name) {
    return 'Organizado por $name';
  }

  @override
  String get liveLabel => 'EN VIVO';

  @override
  String get joinLabel => 'Unirse';

  @override
  String get fullLabel => 'Lleno';

  @override
  String get justStarted => 'Recién iniciado';

  @override
  String get allLanguages => 'Todos los idiomas';

  @override
  String get allTopics => 'Todos los temas';

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
  String get you => 'Tú';

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
  String get dataAndStorage => 'Datos y Almacenamiento';

  @override
  String get manageStorageAndDownloads => 'Gestionar almacenamiento y descargas';

  @override
  String get storageUsage => 'Uso del Almacenamiento';

  @override
  String get totalCacheSize => 'Tamaño Total de Caché';

  @override
  String get imageCache => 'Caché de Imágenes';

  @override
  String get voiceMessagesCache => 'Mensajes de Voz';

  @override
  String get videoCache => 'Caché de Videos';

  @override
  String get otherCache => 'Otro Caché';

  @override
  String get autoDownloadMedia => 'Descarga Automática de Medios';

  @override
  String get currentNetwork => 'Red Actual';

  @override
  String get images => 'Imágenes';

  @override
  String get videos => 'Videos';

  @override
  String get voiceMessagesShort => 'Mensajes de Voz';

  @override
  String get documentsLabel => 'Documentos';

  @override
  String get wifiOnly => 'Solo WiFi';

  @override
  String get never => 'Nunca';

  @override
  String get clearAllCache => 'Limpiar Todo el Caché';

  @override
  String get allCache => 'Todo el Caché';

  @override
  String get clearAllCacheConfirmation => 'Esto eliminará todas las imágenes, mensajes de voz, videos y otros archivos en caché. La app puede cargar contenido más lento temporalmente.';

  @override
  String clearCacheConfirmationFor(String category) {
    return '¿Limpiar $category?';
  }

  @override
  String storageToFree(String size) {
    return 'Se liberará $size';
  }

  @override
  String get calculating => 'Calculando...';

  @override
  String get noDataToShow => 'No hay datos para mostrar';

  @override
  String get profileCompletion => 'Perfil completado';

  @override
  String get justGettingStarted => 'Recién empezando';

  @override
  String get lookingGood => '¡Se ve bien!';

  @override
  String get almostThere => '¡Casi listo!';

  @override
  String addMissingFields(String fields, Object field) {
    return 'Añadir: $fields';
  }

  @override
  String get profilePicture => 'Foto de perfil';

  @override
  String get nativeSpeaker => 'Hablante nativo';

  @override
  String peopleInterestedInTopic(Object count) {
    return 'Personas interesadas en este tema';
  }

  @override
  String get beFirstToAddTopic => '¡Sé el primero en añadir este tema a tus intereses!';

  @override
  String get recentMoments => 'Momentos recientes';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get study => 'Estudiar';

  @override
  String get followerMoments => 'Momentos de seguidos';

  @override
  String get whenPeopleYouFollowPost => 'Cuando las personas que sigues publican nuevos momentos';

  @override
  String get noNotificationsYet => 'Aún no hay notificaciones';

  @override
  String get whenYouGetNotifications => 'Cuando recibas notificaciones, aparecerán aquí';

  @override
  String get failedToLoadNotifications => 'Error al cargar las notificaciones';

  @override
  String get clearAllNotificationsConfirm => '¿Estás seguro de que quieres borrar todas las notificaciones? Esta acción no se puede deshacer.';

  @override
  String get tapToChange => 'Toca para cambiar';

  @override
  String get noPictureSet => 'Sin foto';

  @override
  String get nameAndGender => 'Nombre y Género';

  @override
  String get languageLevel => 'Nivel de idioma';

  @override
  String get personalInformation => 'Información Personal';

  @override
  String get mbti => 'MBTI';

  @override
  String get topicsOfInterest => 'Temas de Interés';

  @override
  String get levelBeginner => 'Principiante';

  @override
  String get levelElementary => 'Elemental';

  @override
  String get levelIntermediate => 'Intermedio';

  @override
  String get levelUpperIntermediate => 'Intermedio Alto';

  @override
  String get levelAdvanced => 'Avanzado';

  @override
  String get levelProficient => 'Competente';

  @override
  String get selectYourLevel => 'Selecciona Tu Nivel';

  @override
  String howWellDoYouSpeak(String language) {
    return '¿Qué tan bien hablas $language?';
  }

  @override
  String get theLanguage => 'el idioma';

  @override
  String languageLevelSetTo(String level) {
    return 'Nivel de idioma establecido a $level';
  }

  @override
  String get failedToUpdate => 'Error al actualizar';

  @override
  String get profileUpdatedSuccessfully => 'Perfil actualizado correctamente';

  @override
  String get genderRequired => 'Género (Obligatorio)';

  @override
  String get editHometown => 'Editar Ciudad Natal';

  @override
  String get useCurrentLocation => 'Usar Ubicación Actual';

  @override
  String get detecting => 'Detectando...';

  @override
  String get getCurrentLocation => 'Obtener Ubicación Actual';

  @override
  String get country => 'País';

  @override
  String get city => 'Ciudad';

  @override
  String get coordinates => 'Coordenadas';

  @override
  String get noLocationDetectedYet => 'Aún no se detectó ubicación.';

  @override
  String get detected => 'Detectado';

  @override
  String get savedHometown => 'Ciudad natal guardada';

  @override
  String get locationServicesDisabled => 'Los servicios de ubicación están desactivados. Por favor actívalos.';

  @override
  String get locationPermissionPermanentlyDenied => 'Los permisos de ubicación están permanentemente denegados.';

  @override
  String get unknown => 'Desconocido';

  @override
  String get editBio => 'Editar Biografía';

  @override
  String get bioUpdatedSuccessfully => 'Biografía actualizada exitosamente';

  @override
  String get tellOthersAboutYourself => 'Cuéntanos sobre ti...';

  @override
  String charactersCount(int count) {
    return '$count/500 caracteres';
  }

  @override
  String get selectYourMbti => 'Selecciona Tu MBTI';

  @override
  String get myBloodType => 'Mi Tipo de Sangre';

  @override
  String get pleaseSelectABloodType => 'Por favor selecciona un tipo de sangre';

  @override
  String get bloodTypeSavedSuccessfully => 'Tipo de sangre guardado correctamente';

  @override
  String get hometownSavedSuccessfully => 'Ciudad natal guardada correctamente';

  @override
  String get nativeLanguageRequired => 'Idioma Nativo (Requerido)';

  @override
  String get languageToLearnRequired => 'Idioma a Aprender (Requerido)';

  @override
  String get nativeLanguageCannotBeSame => 'El idioma nativo no puede ser el mismo que el idioma que estás aprendiendo';

  @override
  String get learningLanguageCannotBeSame => 'El idioma a aprender no puede ser el mismo que tu idioma nativo';

  @override
  String get pleaseSelectALanguage => 'Por favor selecciona un idioma';

  @override
  String get editInterests => 'Editar Intereses';

  @override
  String maxTopicsAllowed(int count) {
    return 'Máximo $count temas permitidos';
  }

  @override
  String get topicsUpdatedSuccessfully => '¡Temas actualizados exitosamente!';

  @override
  String get failedToUpdateTopics => 'Error al actualizar temas';

  @override
  String selectedCount(int count, int max) {
    return '$count/$max seleccionados';
  }

  @override
  String get profilePictures => 'Fotos de Perfil';

  @override
  String get addImages => 'Agregar Imágenes';

  @override
  String get selectUpToImages => 'Selecciona hasta 5 imágenes';

  @override
  String get takeAPhoto => 'Tomar Foto';

  @override
  String get removeImage => 'Eliminar Imagen';

  @override
  String get removeImageConfirm => '¿Estás seguro de eliminar esta imagen?';

  @override
  String get removeAll => 'Eliminar Todo';

  @override
  String get removeAllSelectedImages => 'Eliminar Todas las Imágenes Seleccionadas';

  @override
  String get removeAllSelectedImagesConfirm => '¿Estás seguro de eliminar todas las imágenes seleccionadas?';

  @override
  String get yourProfilePictureWillBeKept => 'Tu foto de perfil existente se mantendrá';

  @override
  String get removeAllImages => 'Eliminar Todas las Imágenes';

  @override
  String get removeAllImagesConfirm => '¿Estás seguro de eliminar todas las fotos de perfil?';

  @override
  String get currentImages => 'Imágenes Actuales';

  @override
  String get newImages => 'Nuevas Imágenes';

  @override
  String get addMoreImages => 'Agregar Más Imágenes';

  @override
  String uploadImages(int count) {
    return 'Subir $count Imagen(es)';
  }

  @override
  String get imageRemovedSuccessfully => 'Imagen eliminada exitosamente';

  @override
  String get imagesUploadedSuccessfully => 'Imágenes subidas exitosamente';

  @override
  String get selectedImagesCleared => 'Imágenes seleccionadas eliminadas';

  @override
  String get extraImagesRemovedSuccessfully => 'Imágenes extra eliminadas exitosamente';

  @override
  String get mustKeepAtLeastOneProfilePicture => 'Debes mantener al menos una foto de perfil';

  @override
  String get noProfilePicturesToRemove => 'No hay fotos de perfil para eliminar';

  @override
  String get authenticationTokenNotFound => 'Token de autenticación no encontrado';

  @override
  String get saveChangesQuestion => '¿Guardar Cambios?';

  @override
  String youHaveUnuploadedImages(int count) {
    return 'Tienes $count imagen(es) seleccionadas pero no subidas. ¿Quieres subirlas ahora?';
  }

  @override
  String get discard => 'Descartar';

  @override
  String get upload => 'Subir';

  @override
  String maxImagesInfo(int max, int current) {
    return 'Puedes subir hasta $max imágenes. Actual: $current/$max\nMáx 5 imágenes por subida.';
  }

  @override
  String canOnlyAddMoreImages(int count, int max) {
    return 'Solo puedes agregar $count imagen(es) más. Máximo $max imágenes.';
  }

  @override
  String get maxImagesPerUpload => 'Puedes subir máximo 5 imágenes a la vez. Solo se agregarán las primeras 5.';

  @override
  String canOnlyHaveMaxImages(int max) {
    return 'Solo puedes tener hasta $max imágenes';
  }

  @override
  String get imageSizeExceedsLimit => 'El tamaño de imagen excede el límite de 10MB';

  @override
  String get unsupportedImageFormat => 'Formato de imagen no soportado';

  @override
  String get pleaseSelectAtLeastOneImage => 'Por favor selecciona al menos una imagen para subir';

  @override
  String get basicInformation => 'Información Básica';

  @override
  String get languageToLearn => 'Idioma a Aprender';

  @override
  String get hometown => 'Ciudad Natal';

  @override
  String get characters => 'caracteres';

  @override
  String get failedToLoadLanguages => 'Error al cargar idiomas';

  @override
  String get studyHub => 'Centro de estudio';

  @override
  String get dailyLearningJourney => 'Tu camino de aprendizaje diario';

  @override
  String get learnTab => 'Aprender';

  @override
  String get aiTools => 'Herramientas IA';

  @override
  String get streak => 'Racha';

  @override
  String get lessons => 'Lecciones';

  @override
  String get words => 'Palabras';

  @override
  String get quickActions => 'Acciones rápidas';

  @override
  String get review => 'Repasar';

  @override
  String wordsDue(int count) {
    return '$count palabras pendientes';
  }

  @override
  String get addWords => 'Agregar palabras';

  @override
  String get buildVocabulary => 'Construir vocabulario';

  @override
  String get practiceWithAI => 'Practicar con IA';

  @override
  String get aiPracticeDescription => 'Chat, cuestionarios, gramática y pronunciación';

  @override
  String get dailyChallenges => 'Desafíos diarios';

  @override
  String get allChallengesCompleted => '¡Todos los desafíos completados!';

  @override
  String get continueLearning => 'Continuar aprendiendo';

  @override
  String get structuredLearningPath => 'Ruta de aprendizaje estructurada';

  @override
  String get vocabulary => 'Vocabulario';

  @override
  String get yourWordCollection => 'Tu colección de palabras';

  @override
  String get achievements => 'Logros';

  @override
  String get badgesAndMilestones => 'Insignias e hitos';

  @override
  String get failedToLoadLearningData => 'Error al cargar datos de aprendizaje';

  @override
  String get startYourJourney => '¡Comienza tu viaje!';

  @override
  String get startJourneyDescription => 'Completa lecciones, construye vocabulario\ny rastrea tu progreso';

  @override
  String levelN(int level) {
    return 'Nivel $level';
  }

  @override
  String xpEarned(int xp) {
    return '$xp XP ganados';
  }

  @override
  String nextLevel(int level) {
    return 'Siguiente: Nivel $level';
  }

  @override
  String xpToGo(int xp) {
    return '$xp XP restantes';
  }

  @override
  String get aiConversationPartner => 'Compañero de conversación IA';

  @override
  String get practiceWithAITutor => 'Practica hablar con tu tutor IA';

  @override
  String get startConversation => 'Iniciar conversación';

  @override
  String get aiFeatures => 'Funciones de IA';

  @override
  String get aiLessons => 'Lecciones con IA';

  @override
  String get learnWithAI => 'Aprender con IA';

  @override
  String get grammar => 'Gramática';

  @override
  String get checkWriting => 'Revisar escritura';

  @override
  String get pronunciation => 'Pronunciación';

  @override
  String get improveSpeaking => 'Mejorar al hablar';

  @override
  String get translation => 'Traducción';

  @override
  String get smartTranslate => 'Traducción inteligente';

  @override
  String get aiQuizzes => 'Cuestionarios IA';

  @override
  String get testKnowledge => 'Poner a prueba conocimientos';

  @override
  String get lessonBuilder => 'Constructor de lecciones';

  @override
  String get customLessons => 'Lecciones personalizadas';

  @override
  String get yourAIProgress => 'Tu progreso con IA';

  @override
  String get quizzes => 'Cuestionarios';

  @override
  String get avgScore => 'Puntuación media';

  @override
  String get focusAreas => 'Áreas de enfoque';

  @override
  String accuracyPercent(String accuracy) {
    return '$accuracy% de precisión';
  }

  @override
  String get practice => 'Practicar';

  @override
  String get browse => 'Explorar';

  @override
  String get noRecommendedLessons => 'No hay lecciones recomendadas disponibles';

  @override
  String get noLessonsFound => 'No se encontraron lecciones';

  @override
  String get createCustomLessonDescription => 'Crea tu propia lección personalizada con IA';

  @override
  String get createLessonWithAI => 'Crear lección con IA';

  @override
  String get allLevels => 'Todos los niveles';

  @override
  String get levelA1 => 'A1 Principiante';

  @override
  String get levelA2 => 'A2 Elemental';

  @override
  String get levelB1 => 'B1 Intermedio';

  @override
  String get levelB2 => 'B2 Inter. alto';

  @override
  String get levelC1 => 'C1 Avanzado';

  @override
  String get levelC2 => 'C2 Competente';

  @override
  String get failedToLoadLessons => 'Error al cargar lecciones';

  @override
  String get pin => 'Fijar';

  @override
  String get unpin => 'Desfijar';

  @override
  String get editMessage => 'Editar mensaje';

  @override
  String get enterMessage => 'Escribe un mensaje...';

  @override
  String get deleteMessageTitle => 'Eliminar mensaje';

  @override
  String get actionCannotBeUndone => 'Esta acción no se puede deshacer.';

  @override
  String get onlyRemovesFromDevice => 'Solo se elimina de tu dispositivo';

  @override
  String get availableWithinOneHour => 'Solo disponible dentro de 1 hora';

  @override
  String get available => 'Disponible';

  @override
  String get forwardMessage => 'Reenviar mensaje';

  @override
  String get selectUsersToForward => 'Selecciona usuarios para reenviar:';

  @override
  String forwardCount(int count) {
    return 'Reenviar ($count)';
  }

  @override
  String get pinnedMessage => 'Mensaje fijado';

  @override
  String get photoMedia => 'Foto';

  @override
  String get videoMedia => 'Video';

  @override
  String get voiceMessageMedia => 'Mensaje de voz';

  @override
  String get documentMedia => 'Documento';

  @override
  String get locationMedia => 'Ubicación';

  @override
  String get stickerMedia => 'Sticker';

  @override
  String get smileys => 'Emoticonos';

  @override
  String get emotions => 'Emociones';

  @override
  String get handGestures => 'Gestos de mano';

  @override
  String get hearts => 'Corazones';

  @override
  String get tapToSayHi => '¡Toca para saludar!';

  @override
  String get sendWaveToStart => 'Envía un saludo para empezar a chatear';

  @override
  String get documentMustBeUnder50MB => 'El documento debe ser menor a 50MB.';

  @override
  String get editWithin15Minutes => 'Los mensajes solo se pueden editar dentro de 15 minutos';

  @override
  String messageForwardedTo(int count) {
    return 'Mensaje reenviado a $count usuario(s)';
  }

  @override
  String get failedToLoadUsers => 'Error al cargar usuarios';

  @override
  String get voice => 'Voz';

  @override
  String get searchGifs => 'Buscar GIFs...';

  @override
  String get trendingGifs => 'Tendencias';

  @override
  String get poweredByGiphy => 'Powered by GIPHY';

  @override
  String get gif => 'GIF';

  @override
  String get noGifsFound => 'No se encontraron GIFs';

  @override
  String get failedToLoadGifs => 'Error al cargar los GIFs';

  @override
  String get gifSent => 'GIF';

  @override
  String get filterCommunities => 'Filtrar';

  @override
  String get reset => 'Restablecer';

  @override
  String get findYourPerfect => 'Encuentra tu perfecto';

  @override
  String get languagePartner => 'Compañero de idioma';

  @override
  String get learningLanguageLabel => 'Idioma de aprendizaje';

  @override
  String get ageRange => 'Rango de edad';

  @override
  String get genderPreference => 'Preferencia de género';

  @override
  String get any => 'Cualquiera';

  @override
  String get showNewUsersSubtitle => 'Mostrar usuarios que se unieron en los últimos 6 días';

  @override
  String get autoDetectLocation => 'Detectar mi ubicación automáticamente';

  @override
  String get selectCountry => 'Seleccionar país';

  @override
  String get anyCountry => 'Cualquier país';

  @override
  String get loadingLanguages => 'Cargando idiomas...';

  @override
  String minAge(int age) {
    return 'Mín: $age';
  }

  @override
  String maxAge(int age) {
    return 'Máx: $age';
  }

  @override
  String get captionRequired => 'La descripción es obligatoria';

  @override
  String captionTooLong(int maxLength) {
    return 'La descripción debe tener $maxLength caracteres o menos';
  }

  @override
  String get maximumImagesReached => 'Máximo de imágenes alcanzado';

  @override
  String maximumImagesReachedDescription(int maxImages) {
    return 'Puedes subir hasta $maxImages imágenes por momento.';
  }

  @override
  String maximumImagesAddedPartial(int maxImages, int added) {
    return 'Máximo $maxImages imágenes. Solo se agregaron $added imágenes.';
  }

  @override
  String get locationAccessRestricted => 'Acceso a ubicación restringido';

  @override
  String get locationPermissionNeeded => 'Se necesita permiso de ubicación';

  @override
  String get addToYourMoment => 'Agregar a tu momento';

  @override
  String get categoryLabel => 'Categoría';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get scheduleOptional => 'Programar (opcional)';

  @override
  String get scheduleForLater => 'Programar para después';

  @override
  String get addMore => 'Agregar más';

  @override
  String get howAreYouFeeling => '¿Cómo te sientes?';

  @override
  String get pleaseWaitOptimizingVideo => 'Por favor espera mientras optimizamos tu video';

  @override
  String unsupportedVideoFormat(String formats) {
    return 'Formato no soportado. Usa: $formats';
  }

  @override
  String get chooseBackground => 'Elegir fondo';

  @override
  String likedByXPeople(int count) {
    return 'Le gustó a $count personas';
  }

  @override
  String xComments(int count) {
    return '$count comentarios';
  }

  @override
  String get oneComment => '1 comentario';

  @override
  String get addAComment => 'Añade un comentario...';

  @override
  String viewXReplies(int count) {
    return 'Ver $count respuestas';
  }

  @override
  String seenByX(int count) {
    return 'Visto por $count';
  }

  @override
  String xHoursAgo(int count) {
    return 'hace ${count}h';
  }

  @override
  String xMinutesAgo(int count) {
    return 'hace ${count}m';
  }

  @override
  String get repliedToYourStory => 'Respondió a tu historia';

  @override
  String mentionedYouInComment(String name) {
    return '$name te mencionó en un comentario';
  }

  @override
  String repliedToYourComment(String name) {
    return '$name respondió a tu comentario';
  }

  @override
  String reactedToYourComment(String name) {
    return '$name reaccionó a tu comentario';
  }

  @override
  String get addReaction => 'Añadir reacción';

  @override
  String get attachImage => 'Adjuntar imagen';

  @override
  String get pickGif => 'Elegir GIF';

  @override
  String get textStory => 'Texto';

  @override
  String get typeYourStory => 'Escribe tu historia...';

  @override
  String get selectBackground => 'Seleccionar fondo';

  @override
  String get highlightsTitle => 'Destacados';

  @override
  String get highlightTitle => 'Título del destacado';

  @override
  String get createNewHighlight => 'Crear nuevo';

  @override
  String get selectStories => 'Seleccionar historias';

  @override
  String get selectCover => 'Seleccionar portada';

  @override
  String get addText => 'Añadir texto';

  @override
  String get fontStyleLabel => 'Estilo de fuente';

  @override
  String get textColorLabel => 'Color de texto';

  @override
  String get dragToDelete => 'Arrastra aquí para eliminar';

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
  String get momentUpdatedSuccessfully => 'Momento actualizado con éxito';

  @override
  String get failedToDeleteMoment => 'Error al eliminar el momento';

  @override
  String get failedToUpdateMoment => 'Error al actualizar el momento';

  @override
  String get mbtiUpdatedSuccessfully => 'MBTI actualizado correctamente';

  @override
  String get pleaseSelectMbti => 'Por favor selecciona un tipo MBTI';

  @override
  String get languageUpdatedSuccessfully => 'Idioma actualizado correctamente';

  @override
  String get bioHintCard => 'Una buena bio ayuda a otros a conectar contigo. Comparte tus intereses, idiomas o lo que estás buscando.';

  @override
  String get bioCounterStartWriting => 'Empieza a escribir...';

  @override
  String get bioCounterABitMore => 'Un poco más estaría bien';

  @override
  String get bioCounterAlmostAtLimit => 'Casi en el límite';

  @override
  String get bioCounterTooLong => 'Demasiado largo';

  @override
  String get bioQuickStarters => 'Inicio rápido';

  @override
  String get rhPositive => 'Rh Positivo';

  @override
  String get rhNegative => 'Rh Negativo';

  @override
  String get rhPositiveDesc => 'El más común';

  @override
  String get rhNegativeDesc => 'Donantes universales / raro';

  @override
  String get yourBloodType => 'Tu grupo sanguíneo';

  @override
  String get noBloodTypeSelected => 'Ningún grupo sanguíneo seleccionado';

  @override
  String get tapTypeBelow => 'Toca un tipo abajo';

  @override
  String get tapButtonToDetectLocation => 'Toca el botón de abajo para detectar tu ubicación actual';

  @override
  String currentAddressLabel(String address) {
    return 'Actual: $address';
  }

  @override
  String get onlyCityCountryShown => 'Solo tu ciudad y país se muestran a los demás. Las coordenadas exactas permanecen privadas.';

  @override
  String get updateLocationCta => 'Actualizar ubicación';

  @override
  String get enterYourName => 'Ingresa tu nombre';

  @override
  String get unsavedChanges => 'Tienes cambios sin guardar';

  @override
  String tapBelowToBrowseLanguages(int count) {
    return 'Toca abajo para explorar $count idiomas';
  }

  @override
  String get changeLanguage => 'Cambiar idioma';

  @override
  String get browseLanguages => 'Explorar idiomas';

  @override
  String get yourLearningLanguageIsPrefix => 'Tu idioma de aprendizaje es ';

  @override
  String get yourNativeLanguageIsPrefix => 'Tu idioma nativo es ';

  @override
  String get profileCompleteProgress => 'completo';

  @override
  String get drawerPreferences => 'Preferencias';

  @override
  String get drawerStorage => 'Almacenamiento';

  @override
  String get drawerReports => 'Informes';

  @override
  String get drawerSupport => 'Soporte';

  @override
  String get drawerAccount => 'Cuenta';

  @override
  String get logoutConfirmBody => '¿Estás seguro de que quieres cerrar sesión en Bananatalk?';

  @override
  String get helpEmailSupport => 'Soporte por correo';

  @override
  String get helpEmailSupportSubtitle => 'support@bananatalk.com';

  @override
  String get helpReportBug => 'Reportar un error';

  @override
  String get helpReportBugSubtitle => 'Ayúdanos a mejorar Bananatalk';

  @override
  String get helpFaqs => 'Preguntas frecuentes';

  @override
  String get helpFaqsSubtitle => 'Preguntas más habituales';

  @override
  String get aboutDialogClose => 'Cerrar';

  @override
  String get aboutBananatalkTagline => 'Conéctate con estudiantes de idiomas de todo el mundo y mejora tus habilidades a través de conversaciones reales.';

  @override
  String get aboutCopyright => '© 2024 Bananatalk. Todos los derechos reservados.';

  @override
  String get logoutFailedPrefix => 'Error al cerrar sesión';

  @override
  String get profileVisitorsTitle => 'Visitantes del perfil';

  @override
  String get visitorStatistics => 'Estadísticas de visitantes';

  @override
  String get visitorsTotalVisits => 'Total de visitas';

  @override
  String get visitorsUniqueVisitors => 'Visitantes únicos';

  @override
  String get visitorsToday => 'Hoy';

  @override
  String get visitorsThisWeek => 'Esta semana';

  @override
  String get noVisitorsYet => 'Aún no hay visitantes';

  @override
  String get noVisitorsYetSubtitle => 'Cuando alguien visite tu perfil,\naparecerá aquí';

  @override
  String get visitedViaSearch => 'a través de Búsqueda';

  @override
  String get visitedViaMoments => 'a través de Momentos';

  @override
  String get visitedViaChat => 'a través de Chat';

  @override
  String get visitedDirect => 'Visita directa';

  @override
  String get visitorTrackingUnavailable => 'Función de seguimiento de visitantes no disponible. Por favor actualiza el servidor.';

  @override
  String get visitorTrackingNotAvailableYet => 'Seguimiento de visitantes aún no disponible';

  @override
  String get noFollowersYetSubtitle => '¡Empieza a conectar con otros!';

  @override
  String get partnerButton => 'Compañero';

  @override
  String get notFollowingAnyoneYetSubtitle => '¡Sigue a personas para ver sus actualizaciones!';

  @override
  String get unfollowButton => 'Dejar de seguir';

  @override
  String get profileThemeTitle => 'Tema del perfil';

  @override
  String get themeAutoSwitch => 'Cambio automático (Tema del sistema)';

  @override
  String get themeSystemHint => 'Cuando está activado, la app seguirá la configuración del tema de tu sistema';

  @override
  String get themeLightMode => 'Modo claro';

  @override
  String get themeDarkMode => 'Modo oscuro';

  @override
  String get myMoments => 'Mis momentos';

  @override
  String get momentListView => 'Vista de lista';

  @override
  String get momentGridView => 'Vista de cuadrícula';

  @override
  String get shareLanguageLearningJourney => '¡Comparte tu viaje de aprendizaje de idiomas!';

  @override
  String get deleteHighlightTitle => 'Eliminar destacado';

  @override
  String deleteHighlightConfirm(String title) {
    return '¿Eliminar \"$title\"? Las historias dentro no se eliminarán.';
  }

  @override
  String get highlightDeletedSuccess => 'Destacado eliminado';

  @override
  String get highlightNewBadge => 'Nuevo';

  @override
  String get editMoment => 'Editar momento';

  @override
  String get momentDescriptionLabel => 'Descripción';

  @override
  String get momentImagesLabel => 'Imágenes';

  @override
  String get noImagesYet => 'Aún no hay imágenes';

  @override
  String get momentEnterDescription => 'Por favor ingresa una descripción';

  @override
  String get momentUpdatedImageFailed => 'Momento actualizado pero la subida de imagen falló';

  @override
  String get updateRequiredTitle => 'Actualización requerida';

  @override
  String get updateAvailableTitle => 'Actualización disponible';

  @override
  String get updateRequiredBody => 'Esta versión de Bananatalk ya no está soportada. Por favor, actualiza para continuar.';

  @override
  String get updateAvailableBody => 'Hay una nueva versión de Bananatalk disponible con mejoras y correcciones de errores.';

  @override
  String get updateNow => 'Actualizar ahora';

  @override
  String get updateLater => 'Más tarde';

  @override
  String get updateOpenStoreFailed => 'No se pudo abrir la tienda. Por favor, actualiza desde el App Store o Play Store.';

  @override
  String get rememberMe => 'Recordarme';

  @override
  String get passwordWeak => 'Débil';

  @override
  String get passwordFair => 'Aceptable';

  @override
  String get passwordStrong => 'Fuerte';

  @override
  String get passwordVeryStrong => 'Muy fuerte';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String stepProgress(int current, int total) {
    return 'Paso $current de $total';
  }
}
