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
  String get aiStudyPromoTitle => 'Practica con escenarios de IA';

  @override
  String get aiStudyPromoBody => 'Haz roleplay de conversaciones reales con tu tutor de IA y gana confianza al hablar.';

  @override
  String get aiStudyPromoCTA => 'Probar un escenario';

  @override
  String get aiStudyPromoDismiss => 'Quizás más tarde';

  @override
  String get promoSpotlightCoinsHeadline => 'Nunca te quedes sin monedas a mitad de conversación';

  @override
  String get promoSpotlightCoinsSubtitle => 'Consigue monedas para desbloquear traducciones extra, chats con el tutor y momentos cada vez que llegues al límite diario.';

  @override
  String get promoSpotlightRoomsHeadline => 'Únete a una sala temática';

  @override
  String get promoSpotlightRoomsSubtitle => 'Entra en una sala de texto en vivo y practica con estudiantes que hablan de temas que te interesan.';

  @override
  String get promoSpotlightVoiceHeadline => 'Entra en una sala de voz';

  @override
  String get promoSpotlightVoiceSubtitle => 'Habla en vivo con otros estudiantes y gana confianza real al hablar, conversación a conversación.';

  @override
  String get promoSpotlightTryIt => 'Probarlo';

  @override
  String get promoSpotlightMaybeLater => 'Quizás después';

  @override
  String get promoSpotlightDontShowAgain => 'No volver a mostrar esto';

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
  String get loadMoreComments => 'Cargar más comentarios';

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
  String get deleteComment => '¿Eliminar comentario?';

  @override
  String get commentDeleted => 'Comentario eliminado';

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
  String get aiTutorChangePersona => 'Cambiar tutor IA';

  @override
  String get aiTutorChangePersonaSubtitle => 'Cambia a Nana, Sensei o Riko';

  @override
  String aiTutorHeroTitleSet(String name) {
    return 'Tu tutor de IA · $name';
  }

  @override
  String get aiTutorHeroTitleNew => 'Conoce a tu tutor de IA';

  @override
  String get aiTutorHeroSubtitleSet => 'Toca para chatear o ver el plan de hoy';

  @override
  String aiTutorHeroSubtitleLast(String summary) {
    return 'La última vez: $summary';
  }

  @override
  String get aiTutorHeroSubtitleNew => 'Elige un personaje — Nana, Sensei o Riko';

  @override
  String get aiTutorChipChat => 'Chat';

  @override
  String get aiTutorChipRoleplay => 'Roleplay';

  @override
  String get aiTutorChipStory => 'Historia';

  @override
  String get aiTutorChipPhoto => 'Foto';

  @override
  String get aiToolsMoreSection => 'Más herramientas de IA';

  @override
  String get aiConversationPartnerTile => 'Conversación con IA';

  @override
  String get aiConversationPartnerTileSubtitle => 'Practica con un compañero IA';

  @override
  String get aiTutorPickerTitle => 'Elige tu tutor IA';

  @override
  String get aiTutorPickerHeader => '¿Con quién quieres aprender?';

  @override
  String get aiTutorPickerSubtitle => 'Puedes cambiarlo en cualquier momento en ajustes.';

  @override
  String get aiTutorPersonaNanaTagline => 'Cálida + alentadora';

  @override
  String get aiTutorPersonaNanaSample => 'Te animaré, sin presión.';

  @override
  String get aiTutorPersonaSenseiTagline => 'Preciso + enfocado al examen';

  @override
  String get aiTutorPersonaSenseiSample => 'Vamos a dominar las reglas.';

  @override
  String get aiTutorPersonaRikoTagline => 'Juguetón + casual';

  @override
  String get aiTutorPersonaRikoSample => 'vale, vamos a vibrar y aprender';

  @override
  String aiTutorPickerSaveError(String error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String get aiTutorHomeTitle => 'Tutor IA';

  @override
  String get aiTutorHomeChangeTutor => 'Cambiar tutor';

  @override
  String get aiTutorHomeGreetingDefault => '¡Hola! ¿Listo para aprender juntos?';

  @override
  String get aiTutorHomeTodaysPlan => 'Plan de hoy';

  @override
  String get aiTutorHomePlanEmpty => 'Sin plan para hoy — inicia un chat para empezar.';

  @override
  String get aiTutorHomeStartChat => 'Iniciar chat';

  @override
  String get aiTutorHomeRecent => 'Reciente';

  @override
  String get aiTutorHomePracticeScenarios => 'Escenarios de práctica';

  @override
  String get aiTutorHomePracticeScenariosSubtitle => 'Roleplay de conversaciones reales — restaurante, entrevista, hotel…';

  @override
  String get aiTutorHomeReadStory => 'Leer una historia';

  @override
  String get aiTutorHomeReadStorySubtitle => 'La IA escribe una historia corta con tu vocabulario — con preguntas rápidas de comprensión.';

  @override
  String get aiTutorHomeDescribePhoto => 'Describe una foto';

  @override
  String get aiTutorHomeDescribePhotoSubtitle => 'Toma una foto y descríbela — la IA evalúa vocabulario + gramática.';

  @override
  String get aiTutorChatTitle => 'Chat con el tutor';

  @override
  String get aiTutorChatVoiceOn => 'Voz activada';

  @override
  String get aiTutorChatVoiceOff => 'Voz desactivada';

  @override
  String get aiTutorChatStopRecording => 'Detener grabación';

  @override
  String get aiTutorChatHoldToTalk => 'Mantén para hablar';

  @override
  String get aiTutorChatTranscribing => 'Transcribiendo…';

  @override
  String get aiTutorChatListening => 'Escuchando…';

  @override
  String get aiTutorChatInputHint => 'Escribe un mensaje…';

  @override
  String get aiTutorChatTypeReplyHint => 'Escribe tu respuesta…';

  @override
  String get aiTutorChatMicPermissionDenied => 'Permiso de micrófono necesario para modo voz.';

  @override
  String get aiTutorChatTranscribeFailed => 'No entendí — inténtalo de nuevo.';

  @override
  String aiTutorChatStartFailed(String error) {
    return 'No se pudo iniciar: $error';
  }

  @override
  String get aiTutorRoleplayEnd => 'Terminar';

  @override
  String aiTutorRoleplayEndFailed(String error) {
    return 'No se pudo terminar: $error';
  }

  @override
  String get aiTutorRoleplayDone => 'Listo';

  @override
  String get aiTutorStoryTitle => 'Leer una historia';

  @override
  String get aiTutorStoryLength => 'Longitud';

  @override
  String get aiTutorStoryTheme => 'Tema';

  @override
  String aiTutorStoryWordCount(int count) {
    return '$count palabras';
  }

  @override
  String get aiTutorStoryWriting => 'Escribiendo…';

  @override
  String get aiTutorStoryGenerate => 'Generar historia';

  @override
  String aiTutorStoryGenerateFailed(String error) {
    return 'No se pudo generar: $error';
  }

  @override
  String aiTutorStoryWordCountHint(int n) {
    return 'La IA usará hasta $n palabras de tu lista de vocabulario.';
  }

  @override
  String get aiTutorStoryThemeFree => 'Libre';

  @override
  String get aiTutorStoryThemeAdventure => 'Aventura';

  @override
  String get aiTutorStoryThemeMystery => 'Misterio';

  @override
  String get aiTutorStoryThemeRomance => 'Romance';

  @override
  String get aiTutorStoryThemeSciFi => 'Ciencia ficción';

  @override
  String get aiTutorStoryThemeSliceOfLife => 'Vida cotidiana';

  @override
  String get aiTutorStoryReaderTitle => 'Historia';

  @override
  String get aiTutorStoryReaderVocab => 'Vocabulario';

  @override
  String get aiTutorStoryReaderVocabUsed => 'Vocabulario usado';

  @override
  String aiTutorStoryReaderPart(int n) {
    return 'Parte $n';
  }

  @override
  String get aiTutorStoryReaderWrongHint => 'No del todo — sigamos';

  @override
  String get aiTutorStoryReaderNiceWork => '¡Buen trabajo!';

  @override
  String aiTutorStoryReaderScore(int correct, int total) {
    return 'Acertaste $correct/$total preguntas de comprensión.';
  }

  @override
  String get aiTutorStoryReaderDone => 'Listo';

  @override
  String get aiTutorImageVocabTitle => 'Describe una foto';

  @override
  String get aiTutorImagePickHeader => 'Elige una foto para describir';

  @override
  String get aiTutorImagePickSubtitle => 'La IA te dará una indicación en tu idioma objetivo y evaluará tu descripción.';

  @override
  String get aiTutorImagePickCamera => 'Cámara';

  @override
  String get aiTutorImagePickGallery => 'Galería';

  @override
  String aiTutorImagePickError(String error) {
    return 'No se pudo abrir la imagen: $error';
  }

  @override
  String get aiTutorImageDescriptionHint => 'Escribe tu descripción…';

  @override
  String get aiTutorImageDifferentPhoto => 'Otra foto';

  @override
  String get aiTutorImageSubmit => 'Enviar';

  @override
  String get aiTutorImageGrammarNotes => 'Notas de gramática';

  @override
  String get aiTutorImageThingsYouMissed => 'Lo que omitiste';

  @override
  String get aiTutorImageTryAnother => 'Probar otra foto';

  @override
  String get aiTutorCardQuiz => 'Cuestionario';

  @override
  String get aiTutorCardVocab => 'Vocab';

  @override
  String get aiTutorCardGrammar => 'Gramática';

  @override
  String get aiTutorCardReviewDue => 'Repaso pendiente';

  @override
  String get aiTutorCardMiniLesson => 'Mini-lección';

  @override
  String get aiTutorCardAddToVocab => 'Añadir a vocab';

  @override
  String get aiTutorCardAddedToVocab => 'Añadido';

  @override
  String get aiTutorCardAdding => 'Añadiendo…';

  @override
  String aiTutorCardReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas esperándote',
      one: '$count tarjeta esperándote',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorCardReviewNow => 'Repasar ahora';

  @override
  String get aiTutorCardReviewStarting => 'Iniciando…';

  @override
  String get aiTutorCardTryIt => 'Pruébalo';

  @override
  String get aiTutorCardPracticing => 'Practicando…';

  @override
  String aiTutorPlanSrsReview(int count, int done) {
    return 'Repasa $count tarjetas SRS ($done hechas)';
  }

  @override
  String aiTutorPlanGrammar(String topic) {
    return 'Practicar: $topic';
  }

  @override
  String aiTutorPlanChat(int min, int done) {
    return 'Chatea $min min ($done hasta ahora)';
  }

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
  String get bloodType => 'Tipo de sangre';

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
  String get conversationHistory => 'Historial de conversaciones';

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
  String get chatSendTooFast => 'Estás enviando mensajes demasiado rápido. Espera un momento e inténtalo de nuevo.';

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
  String get languagesStepTitle => 'Tus idiomas';

  @override
  String get languagesStepSubtitle => 'Te emparejamos con quien aprende lo contrario';

  @override
  String get languagesISpeak => 'Hablo';

  @override
  String get languagesImLearning => 'Estoy aprendiendo';

  @override
  String get languagesSwap => 'Intercambiar';

  @override
  String get languagesChoose => 'Elige un idioma';

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
  String get communityTabRooms => 'Salas';

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
  String get noForYouMomentsTitle => 'Aún no hay momentos';

  @override
  String get noForYouMomentsBody => 'Responde la pregunta de hoy para comenzar la conversación.';

  @override
  String get noFollowingMomentsTitle => 'Aún no hay nada aquí';

  @override
  String get noFollowingMomentsBody => 'Sigue a personas de la Comunidad para ver sus momentos aquí.';

  @override
  String get goToCommunity => 'Ir a la Comunidad';

  @override
  String get unableToLoadMoments => 'No se pueden cargar los momentos';

  @override
  String get map => 'Mapa';

  @override
  String get mapUnavailable => 'Mapa no disponible';

  @override
  String get location => 'Ubicación';

  @override
  String get unknownLocation => 'Ubicación desconocida';

  @override
  String get noImagesAvailable2 => 'No hay imágenes disponibles';

  @override
  String get permissionsRequired => 'Permisos requeridos';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get refresh => 'Actualizar';

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
  String get cannotCallYourself => 'No puedes llamarte a ti mismo';

  @override
  String get failedToFollowUser => 'Error al seguir al usuario';

  @override
  String get failedToUnfollowUser => 'Error al dejar de seguir al usuario';

  @override
  String get areYouSureUnfollow => '¿Seguro que deseas dejar de seguir a este usuario?';

  @override
  String get areYouSureUnblock => '¿Seguro que deseas desbloquear a este usuario?';

  @override
  String get youFollowed => 'Empezaste a seguir a';

  @override
  String get youUnfollowed => 'Dejaste de seguir a';

  @override
  String get alreadyFollowing => 'Ya estás siguiendo a';

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
  String get exchange3MessagesBeforeCall => 'Necesitas intercambiar al menos 5 mensajes antes de llamar';

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
  String get whenAwayFor24Hours => 'Cuando estés ausente por más de 24 horas';

  @override
  String get passwordAndLoginAlerts => 'Alertas de contraseña e inicio de sesión';

  @override
  String get failedToLoadPreferences => 'Error al cargar las preferencias';

  @override
  String get failedToUpdateSetting => 'Error al actualizar la configuración';

  @override
  String get securityAlertsRecommended => 'Te recomendamos mantener activadas las Alertas de seguridad para estar informado sobre la actividad importante de tu cuenta.';

  @override
  String chatWallpaperFor(String name) {
    return 'Fondo de chat para $name';
  }

  @override
  String get solidColors => 'Colores sólidos';

  @override
  String get gradients => 'Degradados';

  @override
  String get customImage => 'Imagen personalizada';

  @override
  String get chooseFromGallery => 'Elegir de la galería';

  @override
  String get preview => 'Vista previa';

  @override
  String get wallpaperUpdated => 'Fondo de pantalla actualizado';

  @override
  String get category => 'Categoría';

  @override
  String get mood => 'Estado de ánimo';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get timePeriod => 'Período de tiempo';

  @override
  String get searchLanguages => 'Buscar idiomas...';

  @override
  String get selected => 'Seleccionado';

  @override
  String get categories => 'Categorías';

  @override
  String get moods => 'Estados de ánimo';

  @override
  String get applyFilters => 'Aplicar filtros';

  @override
  String applyNFilters(int count) {
    return 'Aplicar $count filtros';
  }

  @override
  String get videoMustBeUnder1GB => 'El video debe ser menor a 1GB.';

  @override
  String get failedToRecordVideo => 'Error al grabar el video';

  @override
  String get errorSendingVideo => 'Error al enviar el video';

  @override
  String get errorSendingVoiceMessage => 'Error al enviar el mensaje de voz';

  @override
  String get errorSendingMedia => 'Error al enviar el archivo multimedia';

  @override
  String get cameraPermissionRequired => 'Se requieren permisos de cámara y micrófono para grabar videos.';

  @override
  String get locationPermissionRequired => 'Se requiere permiso de ubicación para compartir tu ubicación.';

  @override
  String get noInternetConnection => 'Sin conexión a internet';

  @override
  String get tryAgainLater => 'Inténtalo de nuevo más tarde';

  @override
  String get messageSent => 'Mensaje enviado';

  @override
  String get messageDeleted => 'Mensaje eliminado';

  @override
  String get messageEdited => 'Mensaje editado';

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
  String get checkOutProfile => '¡Mira este perfil en Bananatalk!';

  @override
  String get checkOutCommunity => '¡Mira a este miembro en Bananatalk!';

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
  String get deletionReasonTitle => 'Antes de irte, ¿por qué te vas?';

  @override
  String get deletionReasonOptional => 'Opcional. Nos ayuda a arreglar lo que falló.';

  @override
  String get deletionReasonNoPeople => 'No encontré gente con quien hablar';

  @override
  String get deletionReasonNoContent => 'No hay contenido en mi idioma';

  @override
  String get deletionReasonNotUseful => 'No es lo que esperaba';

  @override
  String get deletionReasonBugs => 'La app no funcionó bien';

  @override
  String get deletionReasonNotifications => 'Demasiadas notificaciones';

  @override
  String get deletionReasonPrivacy => 'Preocupaciones de privacidad';

  @override
  String get deletionReasonOther => 'Otra cosa';

  @override
  String get deletionReasonHint => 'Cuéntanos más (opcional)';

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
  String get locationOptional => 'Por favor, establece tu ubicación para continuar';

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
  String get confirmPasswordHint => 'Vuelve a introducir la nueva contraseña';

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
  String get backToSignInMethods => 'Volver a los métodos de inicio de sesión';

  @override
  String get securedByGoogle => 'Protegido por Google';

  @override
  String get dataProtectedEncryption => 'Tus datos están protegidos con cifrado estándar del sector';

  @override
  String get welcomeCompleteProfile => '¡Bienvenido! Por favor completa tu perfil';

  @override
  String get authWelcomeTagline => 'CONOCE · CHATEA · CONECTA';

  @override
  String get authWelcomeCtaTitle => 'Haz amigos de todo el mundo en Bananatalk';

  @override
  String get authWelcomeCtaSubtitle => 'Únete hoy a millones de estudiantes de idiomas';

  @override
  String get authWelcomeFeatureConnectTitle => 'Conecta';

  @override
  String get authWelcomeFeatureConnectSubtitle => 'Conoce a compañeros de idiomas de más de 150 países de todo el mundo';

  @override
  String get authWelcomeFeatureLearnTitle => 'Aprende';

  @override
  String get authWelcomeFeatureLearnSubtitle => 'Tutor con IA, cuestionarios y práctica de pronunciación, todo en una sola app';

  @override
  String get authWelcomeFeatureGrowTitle => 'Crece';

  @override
  String get authWelcomeFeatureGrowSubtitle => 'Desarrolla fluidez real a través de conversaciones diarias y comunidad';

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
  String get allCategories => 'Todas las categorías';

  @override
  String get leaderboard => 'Clasificación';

  @override
  String get competeWithLearners => '¡Compite con otros estudiantes!';

  @override
  String get xpRankings => 'Clasificación de XP';

  @override
  String get streaks => 'Rachas';

  @override
  String get friends => 'Amigos';

  @override
  String get myRanks => 'Mis clasificaciones';

  @override
  String get currentStreak => 'Racha actual';

  @override
  String get longestStreak => 'Racha más larga';

  @override
  String get weekly => 'Semanal';

  @override
  String get monthly => 'Mensual';

  @override
  String get yourRank => 'Tu clasificación';

  @override
  String outOf(int total) {
    return 'de $total';
  }

  @override
  String topPercent(String percent) {
    return 'Top $percent%';
  }

  @override
  String get xpRank => 'Clasificación de XP';

  @override
  String get streakRank => 'Clasificación de racha';

  @override
  String get days => 'días';

  @override
  String get learningStats => 'Estadísticas de aprendizaje';

  @override
  String get totalXp => 'XP total';

  @override
  String get lessonsCompleted => 'Lecciones completadas';

  @override
  String get rankings => 'Clasificaciones';

  @override
  String get yourPosition => 'Tu posición';

  @override
  String get keepLearning => '¡Sigue aprendiendo para subir!';

  @override
  String get noRankingsYet => 'Aún no hay clasificaciones';

  @override
  String get startLearningToAppear => '¡Comienza a aprender para aparecer en la clasificación!';

  @override
  String get noFriendsYet => 'Aún no tienes amigos';

  @override
  String get addFriendsToCompete => '¡Agrega amigos para competir con ellos!';

  @override
  String get failedToLoadLeaderboard => 'Error al cargar la clasificación';

  @override
  String get you => 'Tú';

  @override
  String get findPartners => 'Buscar compañeros';

  @override
  String get discoverLanguagePartners => 'Descubre compañeros de idioma';

  @override
  String get byLanguage => 'Por idioma';

  @override
  String get match => 'coincidencia';

  @override
  String get matchScore => 'Puntuación de coincidencia';

  @override
  String get noMatchesFound => 'No se encontraron coincidencias';

  @override
  String get noUsersOnline => 'No hay usuarios en línea';

  @override
  String get checkBackLater => 'Vuelve más tarde';

  @override
  String get selectLanguagePrompt => 'Selecciona un idioma';

  @override
  String get findPartnersByLanguage => 'Encuentra compañeros que hablan o aprenden este idioma';

  @override
  String noPartnersForLanguage(String language) {
    return 'No hay compañeros para $language';
  }

  @override
  String get tryAnotherLanguage => 'Intenta seleccionar otro idioma';

  @override
  String get failedToLoadMatches => 'Error al cargar las coincidencias';

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
  String get aiTools => 'Práctica';

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
  String get noBlockedUsers => 'No hay usuarios bloqueados';

  @override
  String get usersYouBlockWillAppearHere => 'Los usuarios que bloquees aparecerán aquí';

  @override
  String unblockConfirm(String name) {
    return '¿Seguro que deseas desbloquear a $name?';
  }

  @override
  String reasonLabel(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String blockedAgo(String time) {
    return 'Bloqueado $time';
  }

  @override
  String errorLoadingBlockedUsers(String error) {
    return 'Error al cargar usuarios bloqueados: $error';
  }

  @override
  String get logoutConfirmMessage => '¿Seguro que deseas cerrar sesión en Bananatalk?';

  @override
  String get loggingOut => 'Cerrando sesión...';

  @override
  String get quietHours => 'Horas de silencio';

  @override
  String get quietHoursEnable => 'Activar horas de silencio';

  @override
  String get quietHoursSubtitle => 'Pausa las notificaciones no urgentes durante un período de tiempo';

  @override
  String get quietHoursStart => 'Hora de inicio';

  @override
  String get quietHoursEnd => 'Hora de finalización';

  @override
  String get quietHoursAllowUrgent => 'Permitir notificaciones urgentes';

  @override
  String get quietHoursAllowUrgentSubtitle => 'Las llamadas y mensajes de compañeros VIP igual llegarán';

  @override
  String get silencedByQuietHours => 'Silenciado por horas de silencio';

  @override
  String get silencedByCap => 'Silenciado por el límite diario';

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
  String get helpEmailSupportSubtitle => 'support@banatalk.com';

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

  @override
  String get usernameOptional => 'Nombre de usuario (opcional)';

  @override
  String get usernameAvailable => 'Disponible';

  @override
  String get usernameTaken => 'Ya está en uso';

  @override
  String get usernameNotAvailable => 'No disponible';

  @override
  String get usernameInvalidFormat => '3 a 20 caracteres, letras, números o guion bajo';

  @override
  String get usernameHint => '@nombredeusuario';

  @override
  String get enableBiometricTitle => '¿Usar Face ID para iniciar sesión la próxima vez?';

  @override
  String get enableBiometricBody => 'Inicia sesión con datos biométricos sin escribir tu contraseña.';

  @override
  String get enableBiometricCta => 'Activar';

  @override
  String get biometricSignInPrompt => 'Autentícate para iniciar sesión en Bananatalk';

  @override
  String get biometricNotAvailable => 'El inicio de sesión biométrico no está disponible en este dispositivo. Inicia sesión con tu contraseña.';

  @override
  String get biometricNotEnrolled => 'No hay Face ID ni huella configurados en este dispositivo. Añade uno en Ajustes o inicia sesión con tu contraseña.';

  @override
  String get biometricLockedOut => 'Demasiados intentos. La biometría está bloqueada temporalmente. Inténtalo más tarde o inicia sesión con tu contraseña.';

  @override
  String get biometricPermanentlyLockedOut => 'La biometría está bloqueada. Desbloquea el dispositivo con su código y vuelve a intentarlo.';

  @override
  String get biometricPasscodeNotSet => 'Configura un código en el dispositivo para usar el inicio de sesión biométrico.';

  @override
  String continueAs(String name) {
    return 'Continuar como $name';
  }

  @override
  String get addProfilePhotoTitle => 'Añade una foto de perfil';

  @override
  String get addProfilePhotoSkip => 'Omitir por ahora';

  @override
  String get wavesTab => 'Saludos';

  @override
  String get sendWave => 'Enviar saludo';

  @override
  String sendWaveTo(String name) {
    return 'Enviar saludo a $name';
  }

  @override
  String waveSent(String name) {
    return 'Saludo enviado a $name';
  }

  @override
  String waveCooldown(String name, String time) {
    return 'Puedes saludar a $name de nuevo en $time';
  }

  @override
  String get waveCouldntSend => 'No se pudo enviar el saludo';

  @override
  String get itsAMatch => '¡Es un match!';

  @override
  String itsAMatchSubtitle(String name) {
    return 'Tú y $name se saludaron mutuamente';
  }

  @override
  String get sendAMessage => 'Enviar mensaje';

  @override
  String get waveQuickReplyHi => '¡Hola!';

  @override
  String get waveQuickReplyCool => 'Pareces genial';

  @override
  String get waveQuickReplyHey => 'Hola';

  @override
  String get waveQuickReplyChat => 'Hablemos';

  @override
  String get waveQuickReplyHello => 'Buenos días';

  @override
  String waveQuickReplyFromCountry(String country) {
    return 'Hola desde $country';
  }

  @override
  String get waveCustomMessage => 'O escribe el tuyo…';

  @override
  String get voiceRoomChat => 'Chat';

  @override
  String get voiceRoomChatPlaceholder => 'Enviar mensaje…';

  @override
  String get voiceRoomChatEmpty => 'Sin mensajes aún — di hola';

  @override
  String get voiceRoomChatSend => 'Enviar';

  @override
  String voiceRoomChatNewBadge(int n) {
    return '$n';
  }

  @override
  String get voiceRoomEnd => 'Terminar sala';

  @override
  String get voiceRoomEndConfirm => '¿Terminar esta sala?';

  @override
  String get voiceRoomEndConfirmBody => 'Todos serán desconectados.';

  @override
  String get voiceRoomKick => 'Eliminar de la sala';

  @override
  String voiceRoomKickConfirm(String name) {
    return '¿Eliminar a $name?';
  }

  @override
  String get voiceRoomKicked => 'Eliminado';

  @override
  String get voiceRoomYouAreHostNow => 'Ahora eres el anfitrión';

  @override
  String voiceRoomHostChanged(String name) {
    return '$name es ahora el anfitrión';
  }

  @override
  String get voiceRoomHostMenuTitle => 'Acciones de sala';

  @override
  String get voiceRoomViewProfile => 'Ver perfil';

  @override
  String get voiceRoomReconnecting => 'Reconectando…';

  @override
  String get voiceRoomReconnected => 'Reconectado';

  @override
  String get voiceRoomEnded => 'La sala ha terminado';

  @override
  String get voiceRoomReconnectRetry => 'Reintentar';

  @override
  String get mutualInterests => 'Intereses en común';

  @override
  String interestsInCommon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count intereses en común',
      one: '1 interés en común',
      zero: 'Sin intereses en común aún',
    );
    return '$_temp0';
  }

  @override
  String get interestsInCommonSeeAll => 'Ver todo';

  @override
  String get interestsInCommonAddCta => 'Añadir temas';

  @override
  String get interestsInCommonAddSubtitle => 'Añade temas a tu perfil para encontrar puntos en común';

  @override
  String activeAgo(String time) {
    return 'Activo hace $time';
  }

  @override
  String get filterOnlineNow => 'En línea ahora';

  @override
  String get filterAge => 'Edad';

  @override
  String get filterGender => 'Género';

  @override
  String get filterLanguages => 'Idiomas';

  @override
  String get filterCountry => 'País';

  @override
  String get filterTopics => 'Temas';

  @override
  String get filterLevel => 'Nivel de idioma';

  @override
  String get filterToggles => 'Otros';

  @override
  String filterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compañeros coinciden',
      one: '1 compañero coincide',
      zero: 'Ningún compañero coincide',
    );
    return '$_temp0';
  }

  @override
  String get filterClearAll => 'Borrar todo';

  @override
  String get filterReset => 'Restablecer';

  @override
  String get filterApply => 'Aplicar';

  @override
  String get filterNewUsers => 'Solo nuevos usuarios';

  @override
  String get filterPrioritizeNearby => 'Priorizar cercanos';

  @override
  String get filterSheetTitle => 'Filtros';

  @override
  String get notificationPreferencesTitle => 'Notificaciones';

  @override
  String get notificationPreferencesSubtitle => 'Elige qué alertas recibes';

  @override
  String get notifPrefChat => 'Nuevos mensajes';

  @override
  String get notifPrefWave => 'Saludos';

  @override
  String get notifPrefVoiceRoomStart => 'Invitaciones a sala de voz';

  @override
  String get notifPrefScheduledRoomReminder => 'Recordatorios de salas programadas';

  @override
  String get notifPrefFollowerMoment => 'Nuevos momentos de personas que sigues';

  @override
  String get notifPrefVisitorAlert => 'Visitantes de perfil';

  @override
  String get notifPrefMatchAlert => 'Saludos mutuos';

  @override
  String get notifResetToDefaults => 'Restablecer valores predeterminados';

  @override
  String get themeMode => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get languageSettingsRow => 'Idioma';

  @override
  String get waveDailySummaryTitle => 'Nuevos saludos esperando';

  @override
  String waveDailySummaryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas te saludaron',
      one: '1 persona te saludó',
    );
    return '$_temp0';
  }

  @override
  String get filterTopicsTitle => 'Temas';

  @override
  String get filterTopicsEmpty => 'No se seleccionaron temas';

  @override
  String get storiesEmpty => 'Aún no hay historias';

  @override
  String get storiesLoadError => 'No se pudieron cargar las historias';

  @override
  String get storiesRetry => 'Intentar de nuevo';

  @override
  String get storiesNoMore => 'Estás al día';

  @override
  String get createTextStoryTab => 'Texto';

  @override
  String get createImageStoryTab => 'Foto';

  @override
  String get createVideoStoryTab => 'Video';

  @override
  String get enterTextHint => 'Toca para escribir';

  @override
  String get pickBackground => 'Fondo';

  @override
  String get pickFontStyle => 'Fuente';

  @override
  String get pickTextColor => 'Color';

  @override
  String get addEmoji => 'Agregar emoji';

  @override
  String get chooseFont => 'Elegir fuente';

  @override
  String get chooseColor => 'Elegir color';

  @override
  String get dragToMove => 'Arrastra para mover';

  @override
  String get pinchToScale => 'Pellizca para escalar';

  @override
  String get removeFromHighlight => 'Quitar del destacado';

  @override
  String get highlightDeleted => 'Destacado eliminado';

  @override
  String get storySaved => 'Guardado en tu historia';

  @override
  String get storyTooLong => 'El texto es demasiado largo';

  @override
  String get storyPostFailed => 'No se pudo publicar la historia';

  @override
  String get fontNormal => 'Normal';

  @override
  String get fontBold => 'Negrita';

  @override
  String get fontItalic => 'Cursiva';

  @override
  String get fontHandwriting => 'Escritura a mano';

  @override
  String get pickDate => 'Elegir fecha';

  @override
  String get pickTime => 'Elegir hora';

  @override
  String get upcomingRooms => 'Próximamente';

  @override
  String inHours(int h, int m) {
    return 'en ${h}h ${m}min';
  }

  @override
  String inMinutes(int m) {
    return 'en ${m}min';
  }

  @override
  String get startsNow => 'Comenzando ahora';

  @override
  String get iWillBeThere => 'Estaré allí';

  @override
  String get cantMakeIt => 'No puedo asistir';

  @override
  String rsvpCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmaciones',
      one: '1 confirmación',
      zero: 'Sin confirmaciones',
    );
    return '$_temp0';
  }

  @override
  String roomStartsIn1h(String title) {
    return '$title comienza en 1 hora';
  }

  @override
  String roomStartsIn15min(String title) {
    return '$title comienza en 15 minutos';
  }

  @override
  String roomStarted(String title) {
    return '$title está comenzando ahora';
  }

  @override
  String get cancelRoom => 'Cancelar sala';

  @override
  String get muteAll => 'Silenciar a todos';

  @override
  String get mutedByHost => 'El anfitrión silenció a todos';

  @override
  String get muteAllConfirm => '¿Silenciar a todos en la sala?';

  @override
  String get categoryCasual => 'Casual';

  @override
  String get categoryLanguagePractice => 'Práctica de idiomas';

  @override
  String get categoryTopic => 'Tema';

  @override
  String get categoryQA => 'Preguntas y respuestas';

  @override
  String get pickCategory => 'Categoría';

  @override
  String get sortRecentlyActive => 'Activo recientemente';

  @override
  String visitedYourProfile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas visitaron tu perfil',
      one: '1 persona visitó tu perfil',
    );
    return '$_temp0';
  }

  @override
  String get noRecentVisitors => 'Sin visitas recientes';

  @override
  String get viewArchive => 'Ver archivo';

  @override
  String get archivedWaves => 'Waves archivadas';

  @override
  String get noArchivedWaves => 'Sin waves archivadas';

  @override
  String get mutualInterestsMin => 'Intereses en común (mín)';

  @override
  String atLeastNTopics(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Al menos $n temas en común',
      one: 'Al menos 1 tema en común',
      zero: 'Cualquiera',
    );
    return '$_temp0';
  }

  @override
  String get starterAskMoment => 'Pregunta por su último momento';

  @override
  String get starterSayHi => 'Saluda en su idioma';

  @override
  String get starterCurious => '¿Qué les genera curiosidad?';

  @override
  String starterFromCountry(String country) {
    return '¡Hola desde $country!';
  }

  @override
  String starterPracticeLang(String language) {
    return '¡Ayúdales a practicar $language!';
  }

  @override
  String get momentsLoadError => 'No se pudieron cargar los momentos';

  @override
  String get momentsRetry => 'Reintentar';

  @override
  String get recentTags => 'Etiquetas recientes';

  @override
  String get noRecentTags => 'Aún no hay etiquetas recientes';

  @override
  String get hideMomentsFromUser => 'Ocultar momentos de este usuario';

  @override
  String get momentsHidden => 'Los momentos de este usuario se ocultarán';

  @override
  String get unhideMoments => 'Mostrar momentos de este usuario';

  @override
  String momentsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count usuarios ocultos',
      one: '1 usuario oculto',
      zero: 'Sin usuarios ocultos',
    );
    return '$_temp0';
  }

  @override
  String get momentSaveFailed => 'No se pudo guardar el momento';

  @override
  String get tagAlreadyAdded => 'Etiqueta ya agregada';

  @override
  String get tagLimitReached => 'Máximo de etiquetas alcanzado';

  @override
  String get hideThisUser => 'Ocultar las publicaciones de este usuario';

  @override
  String get transcribeMessage => 'Transcribir';

  @override
  String get transcribing => 'Transcribiendo…';

  @override
  String get transcriptionFailed => 'No se pudo transcribir el mensaje';

  @override
  String saveToVocabulary(String word) {
    return 'Guardar \'$word\' en vocabulario';
  }

  @override
  String get addedToVocabulary => 'Agregado a tu vocabulario';

  @override
  String get alreadyInVocabulary => 'Ya está en tu vocabulario';

  @override
  String get tapWordToSave => 'Mantén presionada una palabra para guardarla';

  @override
  String get autoTranslateChatHint => 'Los mensajes entrantes se traducirán automáticamente';

  @override
  String get noConversationsYet => 'Aún no hay conversaciones';

  @override
  String get chatRetry => 'Reintentar';

  @override
  String get learningHubTitle => 'Aprender';

  @override
  String get learningCommonRetry => 'Reintentar';

  @override
  String get learningCommonContinue => 'Continuar';

  @override
  String get learningCommonAwesome => '¡Increíble!';

  @override
  String get learningErrorGeneric => 'Algo salió mal';

  @override
  String get learningStreakCurrent => 'Racha actual';

  @override
  String get learningStreakLongest => 'Racha más larga';

  @override
  String learningStreakDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
      zero: '0 días',
    );
    return '$_temp0';
  }

  @override
  String learningStreakFreezeAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count congelaciones disponibles',
      one: '1 congelación disponible',
      zero: 'Sin congelaciones disponibles',
    );
    return '$_temp0';
  }

  @override
  String get learningStreakFreezeUse => 'Usar congelación';

  @override
  String get learningStreakFreezeDescription => 'Las congelaciones protegen tu racha cuando fallas un día.';

  @override
  String get learningStreakFreezeProtected => '¡Racha protegida!';

  @override
  String get learningStreakMilestone7 => '¡Racha de 7 días!';

  @override
  String get learningStreakMilestone30 => '¡Racha de 30 días!';

  @override
  String get learningStreakMilestone100 => '¡Racha de 100 días!';

  @override
  String get learningStreakMilestone365 => '¡Racha de 365 días!';

  @override
  String get learningWeeklyDigestTitle => 'Esta semana';

  @override
  String learningWeeklyDigestXp(int xp) {
    return '$xp XP ganados';
  }

  @override
  String learningWeeklyDigestLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lecciones',
      one: '1 lección',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestVocab(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palabras aprendidas',
      one: '1 palabra aprendida',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestDaysActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días activos',
      one: '1 día activo',
    );
    return '$_temp0';
  }

  @override
  String get learningWeeklyDigestTopAchievement => 'Mejor logro';

  @override
  String learningWeeklyDigestTrendUp(int pct) {
    return '$pct% más que la semana pasada';
  }

  @override
  String learningWeeklyDigestTrendDown(int pct) {
    return '$pct% menos que la semana pasada';
  }

  @override
  String get learningWeeklyDigestTrendFlat => 'Igual que la semana pasada';

  @override
  String get learningSrsDashboardTitle => 'Repaso diario';

  @override
  String learningSrsDueToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tarjetas hoy',
      one: '1 tarjeta hoy',
      zero: 'Sin tarjetas hoy',
    );
    return '$_temp0';
  }

  @override
  String learningSrsDueTomorrow(int count) {
    return '$count para mañana';
  }

  @override
  String learningSrsDueThisWeek(int count) {
    return '$count esta semana';
  }

  @override
  String get learningSrsStartReview => 'Iniciar repaso';

  @override
  String get learningSrsAllCaughtUp => '¡Estás al día!';

  @override
  String get learningSrsKeepGoing => 'Sigue adelante';

  @override
  String get learningLeaderboardXpTab => 'XP';

  @override
  String get learningLeaderboardStreakTab => 'Racha';

  @override
  String get learningLeaderboardLanguageTab => 'Idioma';

  @override
  String get learningLeaderboardFriendsTab => 'Amigos';

  @override
  String get learningLeaderboardEmpty => 'Aún no hay clasificaciones';

  @override
  String get learningLeaderboardYouLabel => 'Tú';

  @override
  String get learningLeaderboardFriendBadge => 'Amigo';

  @override
  String get learningEmptyVocab => 'Agrega palabras que quieres recordar';

  @override
  String get learningEmptyLessons => 'Aún no hay lecciones disponibles';

  @override
  String get learningEmptyQuizzes => 'No hay cuestionarios disponibles';

  @override
  String get learningEmptyChallenges => 'Vuelve mañana';

  @override
  String get learningEmptyAchievements => 'Gana tu primer logro';

  @override
  String get learningEmptySearchResults => 'No se encontraron resultados';

  @override
  String learningXpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String get learningLevelUp => '¡Subiste de nivel!';

  @override
  String learningLevelReached(String level) {
    return 'Alcanzaste $level';
  }

  @override
  String get learningAchievementUnlocked => 'Logro desbloqueado';

  @override
  String get learningVocabularySearchHint => 'Buscar vocabulario';

  @override
  String get learningVocabularyFilterAll => 'Todo';

  @override
  String get learningVocabularyFilterNew => 'Nuevo';

  @override
  String get learningVocabularyFilterLearning => 'Aprendiendo';

  @override
  String get learningVocabularyFilterMastered => 'Dominado';

  @override
  String get learningVocabularySortRecent => 'Reciente';

  @override
  String get learningVocabularySortAlphabetical => 'Alfabético';

  @override
  String get learningVocabularySortMastery => 'Dominio';

  @override
  String get learningVocabularyMasteryNew => 'Nuevo';

  @override
  String get learningVocabularyMasteryLearning => 'Aprendiendo';

  @override
  String get learningVocabularyMasteryMastered => 'Dominado';

  @override
  String get learningProgressLevelLabel => 'Nivel';

  @override
  String learningProgressXpToNextLevel(int xp) {
    return '$xp XP para el siguiente nivel';
  }

  @override
  String get learningProgressWeeklyChartTitle => 'Últimos 7 días';

  @override
  String get aiTutorPronounceLoading => 'Eligiendo una oración para ti…';

  @override
  String get aiTutorPronounceTapToRecord => 'Toca para grabar';

  @override
  String get aiTutorPronounceTapToStop => 'Toca para detener';

  @override
  String get aiTutorPronounceTranscribing => 'Escuchándote…';

  @override
  String get aiTutorPronounceTryAgain => 'Reintentar';

  @override
  String get aiTutorPronounceNext => 'Siguiente';

  @override
  String get aiTutorPronounceUseYourOwn => 'Usar la mía ✏️';

  @override
  String get aiTutorPronounceCustomHint => 'Escribe una oración para practicar';

  @override
  String get aiTutorPronounceCustomCancel => 'Cancelar';

  @override
  String get aiTutorPronounceCustomUse => 'Usar';

  @override
  String get aiTutorPronounceQuitConfirm => '¿Salir del ejercicio? Tu progreso no se guardará.';

  @override
  String get aiTutorPronounceQuitYes => 'Sí';

  @override
  String get aiTutorPronounceQuitNo => 'No';

  @override
  String aiTutorPronounceSentenceOf(int current, int total) {
    return 'Oración $current de $total';
  }

  @override
  String get aiTutorPronounceSummaryTitle => 'Ejercicio completo';

  @override
  String get aiTutorPronounceSummaryAvg => 'Puntuación media';

  @override
  String get aiTutorPronounceSummaryWeak => 'Palabras a practicar';

  @override
  String get aiTutorPronounceSaveClose => 'Guardar y cerrar';

  @override
  String get aiTutorPronounceSaving => 'Guardando…';

  @override
  String get aiTutorChipPronounce => 'Pronunciación';

  @override
  String aiTutorPlanPronunciation(int count, int completed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ejercicios de pronunciación ($completed/$count)',
      one: 'Ejercicio de pronunciación ($completed/1)',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorPronounceStartHeadline => '¿Cómo quieres practicar?';

  @override
  String get aiTutorPronounceStartSubhead => 'Elige una para comenzar un ejercicio de 5 oraciones.';

  @override
  String get aiTutorPronounceStartAITitle => 'La IA genera oraciones';

  @override
  String get aiTutorPronounceStartAISubtitle => 'Ajustado a tu nivel, con foco en tus palabras difíciles';

  @override
  String get aiTutorPronounceStartCustomTitle => 'Usar mi propia oración';

  @override
  String get aiTutorPronounceStartCustomSubtitle => 'Escribe o pega una frase que quieras dominar';

  @override
  String aiTutorQuotaRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count hoy',
      one: 'Queda 1 hoy',
    );
    return '$_temp0';
  }

  @override
  String get submit => 'Enviar';

  @override
  String get exit => 'Salir';

  @override
  String get previous => 'Anterior';

  @override
  String get aiDailyPracticeTitle => 'Práctica diaria';

  @override
  String get aiDailyPracticeTranslateThis => 'Traduce esto:';

  @override
  String get aiDailyPracticeSuggested => 'Sugerido:';

  @override
  String get aiDailyPracticeHint => 'Tu traducción';

  @override
  String get aiLanguagesLoading => 'Idiomas aún cargando...';

  @override
  String get aiCopiedToClipboard => 'Copiado al portapapeles';

  @override
  String get aiGrammarHint => 'Introduce texto para analizar...';

  @override
  String get aiGrammarSectionOriginal => 'Texto original';

  @override
  String get aiGrammarSectionCorrected => 'Texto corregido';

  @override
  String aiGrammarSectionIssues(int count) {
    return 'Problemas encontrados ($count)';
  }

  @override
  String get aiGrammarSectionWell => 'Lo que hiciste bien';

  @override
  String get aiGrammarSectionSuggestions => 'Sugerencias';

  @override
  String get aiGrammarSectionSummary => 'Resumen';

  @override
  String get aiLessonBuilderLabelLanguage => 'Idioma';

  @override
  String get aiLessonBuilderLabelLevel => 'Nivel';

  @override
  String get aiLessonBuilderTopicHint => 'Introduce un tema (p. ej., \"Comida y restaurantes\")';

  @override
  String aiLessonBuilderSaved(String title) {
    return '¡Lección \"$title\" guardada!';
  }

  @override
  String get aiLessonBuilderBackToLessons => 'Volver a las lecciones';

  @override
  String get aiTranslationHint => 'Introduce texto para traducir...';

  @override
  String get aiTranslationSavedToVocab => 'Guardado en tu vocabulario';

  @override
  String aiTranslationCouldNotSave(String error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String get aiQuizTitle => 'Cuestionario';

  @override
  String get aiQuizFailedToGenerate => 'No se pudo generar el cuestionario';

  @override
  String get aiQuizSubmitTitle => '¿Enviar cuestionario?';

  @override
  String get aiQuizSubmitBody => '¿Seguro que quieres enviar tus respuestas?';

  @override
  String get aiQuizExitTitle => '¿Salir del cuestionario?';

  @override
  String get aiQuizExitBody => 'Perderás tu progreso.';

  @override
  String get aiQuizAnswerHint => 'Escribe tu respuesta...';

  @override
  String get aiQuizTranslationHint => 'Escribe tu traducción...';

  @override
  String get aiPronunciationPlayingAudio => 'Reproduciendo audio...';

  @override
  String get aiPronunciationListenFirst => 'Escucha primero';

  @override
  String get aiPronunciationHint => 'Introduce texto para practicar...';

  @override
  String aiTutorCouldNotLoad(String error) {
    return 'No se pudo cargar el tutor: $error';
  }

  @override
  String aiTutorPlanUnavailable(String error) {
    return 'Plan no disponible: $error';
  }

  @override
  String get aiTutorReplay => 'Repetir';

  @override
  String get aiScenariosTitle => 'Escenarios de práctica';

  @override
  String aiScenariosCouldNotLoad(String error) {
    return 'No se pudieron cargar los escenarios: $error';
  }

  @override
  String get aiScenariosNoneAvailable => 'Aún no hay escenarios.';

  @override
  String aiScenariosCouldNotStart(String error) {
    return 'No se pudo iniciar: $error';
  }

  @override
  String aiScenariosForYourLevel(String level) {
    return 'Para tu nivel ($level)';
  }

  @override
  String get aiScenariosEasier => 'Más fácil — calentamiento';

  @override
  String get aiScenariosHarder => 'Más difícil — desafío';

  @override
  String get aiRoleplayStillStarting => 'El escenario aún se inicia — inténtalo en un momento.';

  @override
  String aiRoleplaySendFailed(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get aiRoleplayCouldNotGrade => 'No se pudo calificar esta vez — inténtalo la próxima.';

  @override
  String get aiConversationHistoryCompleted => 'Completada';

  @override
  String get aiConversationHistoryInProgress => 'En curso';

  @override
  String get aiConversationMessageHint => 'Escribe un mensaje...';

  @override
  String get aiConversationTopicSpeak => 'Hablo';

  @override
  String get aiConversationTopicPractice => 'Practica';

  @override
  String aiToolsVipUpgradeDescription(String feature) {
    return '¡Mejora a VIP para desbloquear $feature!';
  }

  @override
  String get aiToolsVipBadge => 'VIP';

  @override
  String aiScenariosBannerPracticingIn(String language) {
    return 'Practicando en $language';
  }

  @override
  String get aiScenariosBannerSubhead => 'Elige un escenario de tu nivel o uno más arriba.';

  @override
  String get chatListSearchHint => 'Buscar o escribir @usuario';

  @override
  String get chatListFilterAll => 'Todos';

  @override
  String get chatListFilterUnread => 'No leídos';

  @override
  String get chatListFilterOnline => 'En línea';

  @override
  String get chatListNewChat => 'Nuevo chat';

  @override
  String get chatListNewChatByUsernameTooltip => 'Nuevo chat por usuario';

  @override
  String get chatListFindUser => 'Buscar usuario';

  @override
  String chatListFindUserSearchTerm(String term) {
    return 'Buscar @$term';
  }

  @override
  String get chatListDeleteConversation => 'Eliminar conversación';

  @override
  String chatListMediaTitle(String name) {
    return 'Medios con $name';
  }

  @override
  String get chatListMediaError => 'Error al cargar medios';

  @override
  String get chatDetailViewFullProfile => 'Ver perfil completo';

  @override
  String get chatMessageReply => 'Responder';

  @override
  String get chatMessageCopy => 'Copiar';

  @override
  String get chatMessageCorrect => 'Corregir';

  @override
  String get chatMessageTranslate => 'Traducir';

  @override
  String get chatMessageSavePhrase => 'Guardar frase';

  @override
  String get chatMessageEdit => 'Editar';

  @override
  String get chatMessageDelete => 'Eliminar';

  @override
  String get chatMessageRetrySubtitle => 'Intentar enviar este mensaje de nuevo';

  @override
  String get chatMessageRemoveSubtitle => 'Eliminar este mensaje';

  @override
  String get chatWallpaperPreviewHello => '¡Hola! 👋';

  @override
  String get chatWallpaperPreviewHow => '¿Cómo estás?';

  @override
  String get chatGifSearchHint => 'Buscar GIFs...';

  @override
  String get communitySearchHint => 'Buscar o escribir @usuario';

  @override
  String communityUserNotFound(String name) {
    return 'Usuario @$name no encontrado';
  }

  @override
  String get communityTabAll => 'Todos';

  @override
  String get communityTabGender => 'Género';

  @override
  String get communityTabCity => 'Ciudad';

  @override
  String get communityRefresh => 'Actualizar';

  @override
  String get communityNoUsersFound => 'No se encontraron usuarios';

  @override
  String communityUnblockConfirm(String name) {
    return '¿Seguro que quieres desbloquear a $name?';
  }

  @override
  String get communityUsernameCopied => '¡Usuario copiado!';

  @override
  String communityLocationDetected(String country) {
    return 'Ubicación: $country';
  }

  @override
  String get communityWaveLater => 'Más tarde';

  @override
  String get communityAboutMBTI => 'MBTI';

  @override
  String get voiceRoomReactTooltip => 'Reaccionar';

  @override
  String get momentsCancel => 'Cancelar';

  @override
  String get momentsNotNow => 'Ahora no';

  @override
  String get commonOK => 'OK';

  @override
  String commonError(String error) {
    return 'Error: $error';
  }

  @override
  String get chatActiveJustNow => 'Activo ahora';

  @override
  String chatActiveMinAgo(int min) {
    return 'Activo hace $min min';
  }

  @override
  String get chatActiveHourAgo => 'Activo hace 1 hora';

  @override
  String chatActiveHoursAgo(int hours) {
    return 'Activo hace $hours h';
  }

  @override
  String get chatActiveYesterday => 'Activo ayer';

  @override
  String chatActiveDaysAgo(int days) {
    return 'Activo hace ${days}d';
  }

  @override
  String get chatSayHiPrompt => '¡Saluda y comienza una conversación!';

  @override
  String get communityConversationStartersTitle => 'Inicios de conversación';

  @override
  String communityConversationStartersTopic(String topic) {
    return 'A ambos les encanta $topic — ¡pregunta por su favorito!';
  }

  @override
  String get communityConversationStartersDefault => '¡Saluda y preséntate!';

  @override
  String get communityConversationChatAction => 'Chat';

  @override
  String get communityConversationMessageCopied => '¡Mensaje copiado! Pégalo para enviar.';

  @override
  String get communityConversationCopiedToast => '¡Copiado!';

  @override
  String get communityLanguageMatchTitle => 'Coincidencia de idioma';

  @override
  String get communityLanguageMatchNative => 'Nativo';

  @override
  String get communityLanguageMatchLearning => 'Aprendiendo';

  @override
  String get communityLanguageMatchPerfect => '¡Intercambio lingüístico perfecto!';

  @override
  String get communityLanguageMatchSameNative => 'Comparten el mismo idioma nativo';

  @override
  String get momentsFilterApply => 'Aplicar';

  @override
  String get momentsCreateAddTo => 'Añadir a tu momento';

  @override
  String get momentsCreateCategory => 'Categoría';

  @override
  String get momentsCreateLanguage => 'Idioma';

  @override
  String get momentsCreateSchedule => 'Programar (opcional)';

  @override
  String get momentsCreateScheduleForLater => 'Programar para luego';

  @override
  String get momentsPrivacyPublic => 'Público';

  @override
  String get momentsPrivacyFriends => 'Amigos';

  @override
  String get momentsPrivacyPrivate => 'Privado';

  @override
  String get splashTagline => 'Aprender · Chatear · Conocer';

  @override
  String get splashLoading => 'Cargando…';

  @override
  String get supportSheetGreeting => 'Hola, soy Firdavs 👋';

  @override
  String get supportSheetStory => 'Construí Bananatalk completamente por mi cuenta — cada pantalla, cada función, cada corrección de errores a altas horas de la noche. Mi objetivo es ayudar a los estudiantes de idiomas de todo el mundo a conectarse y crecer, y constantemente estoy agregando nuevas funciones.\n\nSi Bananatalk te ha ayudado de alguna manera, incluso un pequeño café me mantiene motivado para seguir construyendo. Cada contribución significa el mundo para un desarrollador en solitario. 🙏';

  @override
  String get supportSheetDonateButton => 'Donar via PayPal';

  @override
  String get supportSheetWatchAd => 'Ver un anuncio para apoyar';

  @override
  String get occupation => 'Ocupación';

  @override
  String get school => 'Escuela / Universidad';

  @override
  String get occupationSearchHint => 'Buscar ocupaciones';

  @override
  String get occupationSelectedLabel => 'Seleccionado';

  @override
  String get occupationCustomLabel => 'Selección personalizada';

  @override
  String get occupationNoMatches => 'Sin coincidencias en la lista';

  @override
  String get occupationCatTech => 'Tecnología y software';

  @override
  String get occupationCatHealthcare => 'Salud y medicina';

  @override
  String get occupationCatEducation => 'Educación y academia';

  @override
  String get occupationCatBusiness => 'Negocios y finanzas';

  @override
  String get occupationCatCreative => 'Creatividad y diseño';

  @override
  String get occupationCatMedia => 'Medios y comunicación';

  @override
  String get occupationCatEngineering => 'Ingeniería';

  @override
  String get occupationCatScience => 'Ciencia e investigación';

  @override
  String get occupationCatLegal => 'Legal';

  @override
  String get occupationCatHospitality => 'Hostelería y restauración';

  @override
  String get occupationCatTrades => 'Oficios cualificados';

  @override
  String get occupationCatTransport => 'Transporte y logística';

  @override
  String get occupationCatGovernment => 'Gobierno y servicio público';

  @override
  String get occupationCatRetail => 'Comercio y atención al cliente';

  @override
  String get occupationCatAgriculture => 'Agricultura y medio ambiente';

  @override
  String get occupationCatSports => 'Deportes y fitness';

  @override
  String get occupationCatBeauty => 'Belleza y cuidado personal';

  @override
  String get occupationCatRealEstate => 'Inmobiliaria y construcción';

  @override
  String get occupationCatReligion => 'Religión y espiritualidad';

  @override
  String get occupationCatStudent => 'Estudiante';

  @override
  String get occupationCatOther => 'Otro';

  @override
  String get schoolHint => 'p. ej. Universidad de Salamanca, Instituto Cervantes';

  @override
  String get birthdate => 'Fecha de nacimiento';

  @override
  String get birthdateSelectHelp => 'Selecciona tu fecha de nacimiento';

  @override
  String get birthdateSelectPlaceholder => 'Selecciona una fecha';

  @override
  String birthdateMinAgeError(int age) {
    return 'Debes tener al menos $age años.';
  }

  @override
  String birthdateQuotaRemaining(int remaining, int max) {
    return 'Te quedan $remaining de $max cambios de fecha de nacimiento en los próximos 60 días.';
  }

  @override
  String birthdateQuotaLocked(int max) {
    return 'Has usado los $max cambios de fecha de nacimiento de este periodo de 60 días.';
  }

  @override
  String birthdateNextChangeOn(String date) {
    return 'Próximo cambio disponible el $date.';
  }

  @override
  String get birthdateRateLimited => 'La fecha de nacimiento solo se puede cambiar 3 veces cada 60 días.';

  @override
  String birthdateRateLimitedUntil(String date) {
    return 'La fecha de nacimiento solo se puede cambiar 3 veces cada 60 días. Inténtalo de nuevo el $date.';
  }

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get currentPassword => 'Contraseña actual';

  @override
  String get newPasswordLabel => 'Nueva contraseña';

  @override
  String get confirmNewPassword => 'Confirmar nueva contraseña';

  @override
  String get currentPasswordHint => 'Introduce tu contraseña actual';

  @override
  String get newPasswordHint => 'Mínimo 8 caracteres, A-Z, a-z, 0-9';

  @override
  String get passwordsDontMatch => 'Las contraseñas no coinciden.';

  @override
  String get newPasswordSameAsCurrent => 'La nueva contraseña debe ser distinta de la actual.';

  @override
  String get passwordChangedSuccess => 'Contraseña cambiada correctamente';

  @override
  String get passwordRule8Chars => 'Al menos 8 caracteres';

  @override
  String get passwordRuleLowercase => 'Una letra minúscula';

  @override
  String get passwordRuleUppercase => 'Una letra mayúscula';

  @override
  String get passwordRuleNumber => 'Un número';

  @override
  String get settingsAccountSection => 'Cuenta';

  @override
  String get changePasswordTileSubtitle => 'Actualiza la contraseña de tu cuenta';

  @override
  String get occupationCustomTab => 'Personalizado';

  @override
  String get occupationCustomTabHint => '¿No encuentras tu profesión? Escríbela aquí.';

  @override
  String get occupationCustomInputHint => 'p. ej. Biólogo marino, Actor de voz';

  @override
  String get occupationCustomSaveCTA => 'Usar como mi ocupación';

  @override
  String get vipSelectPlan => 'Elegir plan';

  @override
  String get vipBenefits => 'Beneficios';

  @override
  String get vipBestValue => 'MEJOR OFERTA';

  @override
  String get vipPlanMonth => '1 mes';

  @override
  String get vipPlanThreeMonths => '3 meses';

  @override
  String get vipPlanTwelveMonths => '12 meses';

  @override
  String get vipOneTime => 'Pago único';

  @override
  String get vipNonVip => 'Sin VIP';

  @override
  String get vipBenefitDailyTranslations => 'Traducciones diarias';

  @override
  String get vipBenefitTranslationsLimit => '5 / día';

  @override
  String get vipBenefitUnlimited => 'Ilimitadas';

  @override
  String get vipBenefitAdvancedFilters => 'Filtros avanzados';

  @override
  String get vipBenefitAdFree => 'Sin anuncios';

  @override
  String get vipBenefitVipBadge => 'Insignia VIP en el perfil';

  @override
  String get vipBenefitPrioritySupport => 'Soporte prioritario';

  @override
  String get vipBrandTitle => 'BananaTalk VIP';

  @override
  String get vipTagline => 'Tu pasaporte a conexiones globales: conversaciones auténticas y amistades duraderas.';

  @override
  String get vipDisclosure => 'Se renueva automáticamente salvo cancelación 24 h antes del fin del período. El pago se cargará a tu cuenta de iTunes o Google Play.';

  @override
  String get vipLoginRequired => 'Inicia sesión para continuar';

  @override
  String get chatListMenu => 'Menu';

  @override
  String get chatListNewMessageAlertsTitle => 'Avisos de mensajes nuevos';

  @override
  String get chatListNewMessageAlertsBody => 'Toca para activar las notificaciones y no perderte ningún mensaje';

  @override
  String get chatListFilterMyTurn => 'Mi turno';

  @override
  String get partnerTagActiveNow => 'Activo ahora';

  @override
  String get partnerTagVeryResponsive => 'Muy receptivo';

  @override
  String get partnerTagQuickToReply => 'Responde rápido';

  @override
  String vipSavePercent(int pct) {
    return 'Ahorra $pct%';
  }

  @override
  String vipPerMonth(String price) {
    return '$price / mes';
  }

  @override
  String partnerTagBothLike(String topic) {
    return 'A los dos les gusta $topic';
  }

  @override
  String partnerTagSpeaks(String language) {
    return 'Habla $language';
  }

  @override
  String partnerTagLearning(String language) {
    return 'Aprende $language';
  }

  @override
  String partnerTagJoinedDaysAgo(int days) {
    return 'Se unió hace $days d';
  }

  @override
  String get vipPaymentPlanSummary => 'Resumen del plan';

  @override
  String get vipPaymentSelectMethod => 'Elige el método de pago';

  @override
  String get vipPaymentPurchaseAppStore => 'Comprar con App Store';

  @override
  String get vipPaymentPurchaseGooglePlay => 'Comprar con Google Play';

  @override
  String get vipPaymentSecureAppStore => 'Tu compra se procesará de forma segura a través de App Store.';

  @override
  String get vipPaymentSecureGooglePlay => 'Tu compra se procesará de forma segura a través de Google Play.';

  @override
  String get vipPaymentSubscriptionInfo => 'Información de la suscripción';

  @override
  String get vipPaymentInfoLabelTitle => 'Título';

  @override
  String get vipPaymentInfoLabelLength => 'Duración';

  @override
  String get vipPaymentInfoLabelPrice => 'Precio';

  @override
  String get vipPaymentDisclosure => 'Al completar esta compra aceptas nuestros Términos de uso y la Política de privacidad. Tu suscripción se renovará automáticamente salvo que la canceles al menos 24 horas antes del final del período actual.';

  @override
  String get vipSuccessTitle => '¡Bienvenido a VIP!';

  @override
  String get vipSuccessBody => 'Tu suscripción VIP está activa. ¡Disfruta de todas las funciones premium!';

  @override
  String get vipPendingTitle => 'Casi listo';

  @override
  String get vipPendingBody => 'Tu suscripción se está procesando — intenta actualizar en un momento.';

  @override
  String get vipErrorPaymentTitle => 'Error de pago';

  @override
  String get vipErrorPurchaseTitle => 'Error de compra';

  @override
  String get vipErrorVerifyTitle => 'No se pudo verificar la compra';

  @override
  String get vipErrorPaymentFailed => 'Pago fallido';

  @override
  String get vipErrorBodyPrefix => 'Ocurrió un error al procesar tu pago:';

  @override
  String get vipErrorPurchaseCanceled => 'La compra se canceló o falló. Inténtalo de nuevo.';

  @override
  String get vipErrorVerifyServer => 'No se pudo verificar la compra con el servidor. Contacta con soporte.';

  @override
  String get vipPlanLengthOneMonth => '1 mes';

  @override
  String get vipPlanLengthThreeMonths => '3 meses';

  @override
  String get vipPlanLengthOneYear => '1 año';

  @override
  String vipPaymentPayPrice(String price) {
    return 'Pagar $price';
  }

  @override
  String get vipExpired => 'VIP caducado';

  @override
  String get vipMember => 'Miembro VIP';

  @override
  String get chatPhrasesMostUsed => 'Más usadas';

  @override
  String get chatPhrasesTopics => 'Temas';

  @override
  String get chatPhrasesAddPhrase => 'Añadir frase';

  @override
  String get chatPhrasesChange => 'Cambiar';

  @override
  String get chatPhrasesAddTitle => 'Añadir una frase';

  @override
  String get chatPhrasesAddHint => 'Escribe una frase que uses a menudo';

  @override
  String get chatPhrasesEmptyMostUsed => 'Aún no hay frases guardadas. Pulsa + para añadir una.';

  @override
  String get chatPhrasesDeleteTitle => '¿Eliminar esta frase?';

  @override
  String get filterVipPromoTitle => 'Encuentra tu pareja perfecta más rápido';

  @override
  String get filterVipPromoSubtitle => 'Desbloquea descubrimiento prioritario, filtros avanzados y chats sin anuncios con VIP.';

  @override
  String get filterVipPromoCta => 'Ser VIP';

  @override
  String get examStudy => 'Preparación de examen';

  @override
  String get examStudyChooseLanguage => 'Elige tu idioma de estudio';

  @override
  String get examStudyChooseLanguageSubtitle => 'Elige el idioma en el que quieres preparar un examen.';

  @override
  String get examStudyLoading => 'Loading…';

  @override
  String get examStudyEmptyLanguages => 'Aún no hay idiomas de estudio disponibles.';

  @override
  String get examStudyError => 'No se pudo cargar: inténtalo de nuevo.';

  @override
  String get examStudyRetry => 'Retry';

  @override
  String get examPickExam => 'Elige un examen';

  @override
  String get examPickExamSubtitle => 'Elige el examen para el que quieres prepararte.';

  @override
  String get examPickEmpty => 'Todavía no hay exámenes para este idioma.';

  @override
  String get examDashboardSections => 'Sections';

  @override
  String get examDashboardEmptySections => 'Aún no hay secciones para practicar.';

  @override
  String get examDashboardContinue => 'Seguir practicando';

  @override
  String get examDashboardStartStudyPlan => 'Empezar plan de estudio';

  @override
  String get examDashboardViewProgress => 'Ver progreso';

  @override
  String examMetaDuration(int minutes) {
    return '$minutes min';
  }

  @override
  String examMetaMaxScore(String score) {
    return 'Máx. $score';
  }

  @override
  String examMetaSections(int count) {
    return '$count secciones';
  }

  @override
  String get examSectionNotStarted => 'Sin empezar';

  @override
  String examSectionProgress(int done, int total) {
    return '$done/$total hechas';
  }

  @override
  String get examQuestionSubmit => 'Enviar respuesta';

  @override
  String get examQuestionNext => 'Siguiente pregunta';

  @override
  String get examQuestionCorrect => 'Correct!';

  @override
  String get examQuestionIncorrect => 'Incorrecta';

  @override
  String get examQuestionExplanation => 'Explicación';

  @override
  String get examQuestionNoQuestions => 'Aún no hay preguntas en esta sección.';

  @override
  String get examQuestionEssayComingSoon => 'La evaluación de redacciones llegará pronto. Prueba una sección de lectura por ahora.';

  @override
  String get examQuestionUnsupported => 'Este tipo de pregunta todavía no es compatible.';

  @override
  String get examPracticeFinishedTitle => 'Sección completada';

  @override
  String get examPracticeFinishedBody => 'Buen trabajo: has completado todas las preguntas de esta sección.';

  @override
  String get examPracticeBackToDashboard => 'Volver al panel';

  @override
  String examPracticeProgress(int current, int total) {
    return '$current de $total';
  }

  @override
  String get examEssayPrompt => 'Escribe tu redacción';

  @override
  String examEssayMinChars(int min) {
    return 'La redacción debe tener al menos $min caracteres';
  }

  @override
  String examEssayMaxChars(int max) {
    return 'La redacción no puede superar los $max caracteres';
  }

  @override
  String examEssayWordCount(int count) {
    return '$count palabras';
  }

  @override
  String examEssayCharCount(int count) {
    return '$count caracteres';
  }

  @override
  String get examEssaySubmit => 'Enviar redacción';

  @override
  String get examEssayEvaluating => 'Evaluando tu redacción…';

  @override
  String get examEssayEvaluatingHint => 'Suele tardar entre 10 y 30 segundos. Puedes salir de esta pantalla: seguiremos evaluando en segundo plano.';

  @override
  String get examEssayResultTitle => 'Evaluación';

  @override
  String get examEssayResultStrengths => 'Puntos fuertes';

  @override
  String get examEssayResultImprovements => 'Sugerencias';

  @override
  String get examEssayResultScore => 'Score';

  @override
  String get examEssayResultFailed => 'No se pudo evaluar esta redacción.';

  @override
  String get examEssayResultRetry => 'Inténtalo de nuevo';

  @override
  String get examEssayResultDone => 'Done';

  @override
  String get examEssayPollTimeout => 'Todavía evaluando: vuelve en un minuto.';

  @override
  String get examEssayPollRefresh => 'Comprobar de nuevo';

  @override
  String examEssayQuotaUsed(int used, int limit) {
    return 'Evaluaciones de redacción hoy: $used/$limit';
  }

  @override
  String get examEssayQuotaExhausted => 'Has usado las evaluaciones gratuitas de hoy. Hazte VIP para tenerlas sin límite.';

  @override
  String get examEssayQuotaUpgrade => 'Pasar a VIP';

  @override
  String get examEssayDraftRestored => 'Borrador recuperado';

  @override
  String get examProgressTitle => 'Progress';

  @override
  String get examProgressOverall => 'Puntuación general';

  @override
  String get examProgressNotStartedTitle => 'Aún sin práctica';

  @override
  String get examProgressNotStartedBody => 'Responde algunas preguntas en cualquier sección para ver tu progreso aquí.';

  @override
  String get examProgressFocusAreas => 'Áreas de mejora';

  @override
  String examProgressSectionAttempts(int done, int total) {
    return '$done de $total intentadas';
  }

  @override
  String get examProgressNoFocusAreas => 'Vas bien en todas las secciones: ¡sigue practicando!';

  @override
  String get examPlanSetupTitle => 'Empezar plan de estudio';

  @override
  String get examPlanTargetScore => 'Puntuación objetivo';

  @override
  String get examPlanExamDate => 'Fecha del examen';

  @override
  String get examPlanPickDate => 'Elegir fecha';

  @override
  String get examPlanGenerate => 'Generar plan';

  @override
  String get examPlanGenerating => 'Generando tu plan…';

  @override
  String get examPlanInvalidDate => 'Elige una fecha de examen futura.';

  @override
  String get examPlanInvalidScore => 'Introduce una puntuación objetivo válida.';

  @override
  String get examPlanTitle => 'Plan de estudio';

  @override
  String get examPlanEmptyTitle => 'Sin plan activo';

  @override
  String get examPlanEmptyBody => 'Genera un plan para tener objetivos semanales adaptados a tus puntos débiles.';

  @override
  String get examPlanRegenerate => 'Volver a generar el plan';

  @override
  String examPlanWeek(int n) {
    return 'Semana $n';
  }

  @override
  String examPlanWeekEstimate(String hours) {
    return '${hours}h';
  }

  @override
  String examPlanTotalHours(int hours) {
    return '$hours horas en total';
  }

  @override
  String get examPlanDailyHeading => 'Lecciones diarias sugeridas';

  @override
  String examPlanLessonMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get examTopicPickerTitle => 'Elige un tema';

  @override
  String get examTopicPickerSubtitle => 'Practica preguntas de un tema concreto o ve a todas las preguntas.';

  @override
  String get examTopicAllTopics => 'Todos los temas';

  @override
  String get examTopicAllTopicsDescription => 'Mezcla de todos los temas disponibles';

  @override
  String get examTopicEmpty => 'No topical content yet. Tap All topics to start practicing.';

  @override
  String examTopicQuestionCount(int count) {
    return '$count preguntas';
  }

  @override
  String get examTopicOneQuestion => '1 pregunta';

  @override
  String get examSpeakingPrompt => 'Di tu respuesta';

  @override
  String get examSpeakingListenToPrompt => 'Listen to prompt';

  @override
  String get examSpeakingTapToRecord => 'Toca para grabar tu respuesta';

  @override
  String get examSpeakingTranscriptHeading => 'Lo que hemos oído';

  @override
  String get examSpeakingPart1 => 'Speaking — Part 1';

  @override
  String get examSpeakingPart2 => 'Speaking — Part 2';

  @override
  String get examSpeakingPart3 => 'Speaking — Part 3';

  @override
  String get examSpeakingSubmit => 'Enviar grabación';

  @override
  String get examSpeakingUploading => 'Subiendo…';

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
      other: '$count tareas',
      one: '1 tarea',
    );
    return '$_temp0';
  }

  @override
  String examGroupSpeakingSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partes',
      one: '1 parte',
    );
    return '$_temp0';
  }

  @override
  String get examVocabLevelPickerTitle => 'Elige un nivel';

  @override
  String get examVocabLevelPickerSubtitle => 'Explora palabras y cuestionarios por nivel MCER.';

  @override
  String get examVocabTopicPickerTitle => 'Elige un tema';

  @override
  String get examVocabAllTopics => 'Todos los temas';

  @override
  String get examVocabBrowse => 'Browse';

  @override
  String get examVocabPractice => 'Practice';

  @override
  String get examVocabEmptyList => 'Aún no hay palabras para este nivel y tema.';

  @override
  String get examVocabQuizComplete => 'Cuestionario completado';

  @override
  String examVocabQuizScore(int correct, int total) {
    return 'Has acertado $correct de $total';
  }

  @override
  String get examVocabQuizYourAnswer => 'Tu respuesta';

  @override
  String get examVocabQuizCorrectAnswer => 'Respuesta correcta';

  @override
  String get examVocabQuizSubmit => 'Submit';

  @override
  String get examVocabQuizSubmitting => 'Enviando…';

  @override
  String get examVocabQuizNext => 'Next';

  @override
  String get examVocabQuizPrev => 'Back';

  @override
  String get examVocabQuizRestart => 'Restart';

  @override
  String get examVocabQuizEmpty => 'No se han podido generar preguntas. Prueba con otro tema o nivel.';

  @override
  String get examVocabQuizNotEnough => 'No hay suficientes palabras en este nivel y tema para crear un cuestionario.';

  @override
  String get examVocabQuizExpiredTitle => 'Cuestionario caducado';

  @override
  String get examVocabQuizExpiredBody => 'Este cuestionario estuvo inactivo demasiado tiempo. Reinícialo para empezar uno nuevo.';

  @override
  String get examVocabTranslate => 'Traducir';

  @override
  String get examVocabTranslateFailed => 'Traducción no disponible. Inténtalo más tarde.';

  @override
  String get examDashboardTips => 'Tips';

  @override
  String get examTipsTitle => 'Consejos y técnicas';

  @override
  String examTipsSubtitle(String examName) {
    return 'Notas de estrategia seleccionadas para $examName.';
  }

  @override
  String get examTipsEmpty => 'Aún no hay consejos publicados para este examen.';

  @override
  String get examTipsCategoryStrategy => 'Strategy';

  @override
  String get examTipsCategoryGrammar => 'Grammar';

  @override
  String get examTipsCategoryVocabulary => 'Vocabulario';

  @override
  String get examTipsCategoryTimeManagement => 'Gestión del tiempo';

  @override
  String get examTipsCategoryCommonMistakes => 'Errores comunes';

  @override
  String get examTipsCategoryBandBooster => 'Sube de nivel';

  @override
  String get examTipsCategoryCulturalNotes => 'Notas culturales';

  @override
  String get examTipsCategoryPronunciation => 'Pronunciación';

  @override
  String get examTipsCategoryFluency => 'Fluency';

  @override
  String get roomsNewRoom => 'Nueva sala';

  @override
  String get roomsCouldNotLoad => 'No se pudieron cargar las salas';

  @override
  String get roomsEmptyTitle => 'Aún no hay salas de idiomas';

  @override
  String get roomsEmptySubtitle => 'Vuelve pronto — los hubs se están configurando.';

  @override
  String get roomCreateTitle => 'Nueva sala temática';

  @override
  String get roomCreateSubtitle => 'Inicia un chat enfocado dentro de un idioma';

  @override
  String get roomNameLabel => 'Nombre de la sala';

  @override
  String get roomNameHint => 'p. ej. Práctica de conversación diaria';

  @override
  String get roomDescriptionLabel => 'Descripción (opcional)';

  @override
  String get roomDescriptionHint => '¿De qué trata esta sala?';

  @override
  String get roomCreateSubmit => 'Crear sala';

  @override
  String get roomNameRequired => 'Por favor ingresa un nombre para la sala';

  @override
  String get roomCreateError => 'No se pudo crear la sala. Inténtalo de nuevo.';

  @override
  String get roomUsEnglish => 'Inglés estadounidense';

  @override
  String get roomUkEnglish => 'Inglés británico';

  @override
  String get roomFailedLoadMessages => 'No se pudieron cargar los mensajes';

  @override
  String get roomReportMessageTitle => 'Reportar mensaje';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Acoso o intimidación';

  @override
  String get reportReasonHateSpeech => 'Discurso de odio';

  @override
  String get reportReasonViolence => 'Violencia o amenazas';

  @override
  String get reportReasonNudity => 'Desnudez o contenido sexual';

  @override
  String get reportReasonFalseInformation => 'Información falsa';

  @override
  String get roomReportSubmitted => 'Reporte enviado';

  @override
  String get roomReportSubmitFailed => 'Error al enviar el reporte';

  @override
  String get roomLeaveHubTitle => '¿Salir del hub?';

  @override
  String roomLeaveHubMessage(String title) {
    return 'Puedes volver a unirte a $title más tarde desde el directorio de salas.';
  }

  @override
  String get roomLeaveHubFailed => 'Error al salir del hub';

  @override
  String get roomJoinRequestSent => 'Solicitud enviada — se te notificará si es aprobada';

  @override
  String get roomJoinRequestFailed => 'Error al enviar la solicitud';

  @override
  String roomRequestsMenuItem(int count) {
    return 'Solicitudes ($count)';
  }

  @override
  String get roomViewMembers => 'Ver miembros';

  @override
  String get roomLeaveHubMenuItem => 'Salir del hub';

  @override
  String roomMemberOnlineCount(int members, int online) {
    return '$members miembros · $online en línea';
  }

  @override
  String get roomBannedRequestMessage => 'Fuiste eliminado de esta sala. Envía una solicitud para volver a unirte — el propietario debe aprobarla.';

  @override
  String get roomModeratedRequestMessage => 'Esta es una sala moderada. Solicita unirte para empezar a chatear.';

  @override
  String get roomRequestPending => 'Solicitud pendiente';

  @override
  String get roomRequestToJoin => 'Solicitar unirse';

  @override
  String get roomDailyPromptLabel => 'Tema de hoy';

  @override
  String get roomSomeoneFallback => 'Alguien';

  @override
  String get roomRequestsLoadError => 'No se pudieron cargar las solicitudes de unión';

  @override
  String get roomRequestApproved => 'Solicitud aprobada';

  @override
  String get roomRequestDenied => 'Solicitud rechazada';

  @override
  String get roomRequestApproveFailed => 'Error al aprobar la solicitud';

  @override
  String get roomRequestDenyFailed => 'Error al rechazar la solicitud';

  @override
  String roomRequestsAppBarTitle(String title) {
    return '$title · Solicitudes';
  }

  @override
  String get roomRequestsEmpty => 'No hay solicitudes pendientes';

  @override
  String get roomRequestDeny => 'Rechazar';

  @override
  String get roomRequestApprove => 'Aprobar';

  @override
  String get roomMembersLoadError => 'No se pudieron cargar los miembros';

  @override
  String get roomRemoveBanTitle => '¿Eliminar y bloquear al miembro?';

  @override
  String get roomRemoveTitle => '¿Eliminar al miembro?';

  @override
  String roomRemoveBanConfirm(String name) {
    return '¿Eliminar y bloquear a $name? No podrá volver a unirse a menos que apruebes una solicitud.';
  }

  @override
  String roomRemoveConfirm(String name, String title) {
    return '¿Eliminar a $name de $title?';
  }

  @override
  String get roomRemoveBanButton => 'Eliminar y bloquear';

  @override
  String get roomRemoveButton => 'Eliminar';

  @override
  String get roomMemberRemovedBanned => 'Miembro eliminado y bloqueado';

  @override
  String get roomMemberRemoved => 'Miembro eliminado';

  @override
  String get roomMemberRemoveFailed => 'Error al eliminar al miembro';

  @override
  String get roomMemberMuted => 'Miembro silenciado';

  @override
  String get roomMemberUnmuted => 'Miembro reactivado';

  @override
  String get roomMemberMuteFailed => 'Error al actualizar el estado de silencio';

  @override
  String roomMembersAppBarTitle(String title) {
    return '$title · Miembros';
  }

  @override
  String get roomMembersEmpty => 'Aún no hay miembros para mostrar';

  @override
  String get roomMemberMutedLabel => 'Silenciado';

  @override
  String get roomMemberFallbackName => 'Miembro';

  @override
  String get roomYourHub => 'Tu hub';

  @override
  String roomOnlineCount(int count) {
    return '$count en línea';
  }

  @override
  String get roomNotAvailable => 'Esta sala ya no está disponible.';

  @override
  String get roomGoToRooms => 'Ir a Salas';

  @override
  String get todayTab => 'Hoy';

  @override
  String get todaysGrammar => 'Gramática de hoy';

  @override
  String get todaysVocabulary => 'Vocabulario de hoy';

  @override
  String todayMinutes(int count) {
    return '$count min';
  }

  @override
  String get todayPickLanguage => '¿Qué estás aprendiendo?';

  @override
  String todayLevelFallback(String served, String requested) {
    return 'Mostrando $served — aún no hay contenido de $requested';
  }

  @override
  String get packTakePlacement => 'Descubre tu nivel';

  @override
  String todayContentLanguage(String language) {
    return 'Las lecciones de hoy están en $language';
  }

  @override
  String get dailyCheck => 'Comprobar';

  @override
  String get dailyTooEasy => 'Demasiado fácil';

  @override
  String get dailyTooHard => 'Demasiado difícil';

  @override
  String dailyScore(int score, int total) {
    return '$score/$total';
  }

  @override
  String dailyStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Racha de $count días',
      one: 'Racha de 1 día',
    );
    return '$_temp0';
  }

  @override
  String dailyXpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String get todayEmpty => 'El contenido de hoy aún se está preparando. Vuelve pronto.';

  @override
  String todayLanguageUnsupported(String language) {
    return 'El estudio diario aún no está disponible para $language.';
  }

  @override
  String get packContinue => 'Continuar';

  @override
  String get packGotIt => 'Entendido';

  @override
  String get packSubmitFailed => 'No se pudo guardar: revisa tu conexión e inténtalo de nuevo.';

  @override
  String packWordProgress(int current, int total) {
    return 'Palabra $current de $total';
  }

  @override
  String packGrammarUnit(int unit) {
    return 'Unidad $unit';
  }

  @override
  String get packListeningPrompt => '¿Qué palabra escuchaste?';

  @override
  String packPlayClip(int number) {
    return 'Reproducir clip $number';
  }

  @override
  String get packReveal => 'Ver respuesta';

  @override
  String get packKnewIt => 'La sabía';

  @override
  String get packMissed => 'No la sabía';

  @override
  String get packTranslatePrompt => 'Traduce esta frase';

  @override
  String get packTranslateHint => 'Escribe tu traducción';

  @override
  String get packDone => 'Listo';

  @override
  String packTomorrowTeaser(String topic) {
    return 'Mañana: más de $topic';
  }

  @override
  String packContinueTo(String station) {
    return 'Continuar · $station';
  }

  @override
  String get packDoneForToday => 'Listo por hoy';

  @override
  String get packStationVocabulary => 'Vocabulario';

  @override
  String get packStationGrammar => 'Gramática';

  @override
  String get packStationListening => 'Comprensión auditiva';

  @override
  String get packStationReview => 'Repaso';

  @override
  String get packStationWrap => 'Examen semanal';

  @override
  String get packStationTranslate => 'Traducir';

  @override
  String get masteryTitle => 'Tu progreso';

  @override
  String get masteryEmpty => 'Completa un día de estudio y tu progreso aparecerá aquí.';

  @override
  String get masteryYourLevel => 'tu nivel';

  @override
  String get masteryRetake => 'Repetir';

  @override
  String get masteryVocabulary => 'Vocabulario';

  @override
  String get masteryGrammar => 'Gramática';

  @override
  String get masteryListening => 'Comprensión auditiva';

  @override
  String get masteryTranslate => 'Traducción';

  @override
  String get masteryNotStarted => 'Aún sin empezar';

  @override
  String masteryVocabularyCaption(int mastered, int learning, int due) {
    return '$mastered dominadas · $learning en curso · $due pendientes';
  }

  @override
  String masteryGrammarCaption(int mastered, int total) {
    return 'Unidad $mastered de $total';
  }

  @override
  String masteryAccuracyCaption(int percent, int samples) {
    return '$percent% en $samples sesiones';
  }

  @override
  String get masteryConsistency => 'Últimos 30 días';

  @override
  String masteryDueCta(int count) {
    return 'Repasar $count palabras ahora';
  }

  @override
  String get placementTitle => 'Encuentra tu nivel';

  @override
  String get placementSkip => 'Omitir';

  @override
  String placementProgress(int current, int total) {
    return 'Pregunta $current de $total';
  }

  @override
  String get placementResult => 'Empezaremos aquí. Puedes cambiarlo cuando quieras.';

  @override
  String get placementStart => 'Empezar a aprender';

  @override
  String get packNotGraded => 'Guardado: no pudimos corregirlo ahora mismo.';

  @override
  String packSuggestedTranslation(String translation) {
    return 'Sugerencia: $translation';
  }

  @override
  String get weeklyReportTitle => 'Tu semana';

  @override
  String weeklyReportRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get weeklyReportDays => 'días de estudio';

  @override
  String get weeklyReportStations => 'estaciones completadas';

  @override
  String get weeklyReportUnits => 'unidades de gramática dominadas';

  @override
  String get weeklyReportWords => 'palabras nuevas';

  @override
  String get weeklyReportAccuracy => 'correcto';

  @override
  String weeklyReportBestDay(String day, int count) {
    return 'Tu mejor día fue el $day: $count estaciones completadas';
  }

  @override
  String get weeklyReportEmpty => 'Aún no has estudiado esta semana. Con un día basta para empezar.';

  @override
  String get weeklyReportStart => 'Empezar el pack de hoy';

  @override
  String get gatheringsTabLabel => 'Encuentros';

  @override
  String get gatheringClubs => 'Clubes';

  @override
  String get gatheringNewClub => 'Nuevo club';

  @override
  String get gatheringStartingSoon => 'Empiezan pronto';

  @override
  String get gatheringCreateShort => 'Nuevo';

  @override
  String get gatheringLoadFailed => 'No se pudieron cargar los encuentros';

  @override
  String get gatheringEmptyTitle => 'Organiza el primero';

  @override
  String get gatheringEmptyBody => 'Todavía no hay nada programado. Elige una hora y publícalo: la gente se apunta a los encuentros que ya tienen anfitrión.';

  @override
  String get gatheringStartAClub => 'Mejor crear un club';

  @override
  String get gatheringToday => 'Hoy';

  @override
  String get gatheringTomorrow => 'Mañana';

  @override
  String get gatheringHappeningNow => 'Sucediendo ahora';

  @override
  String gatheringStartsIn(int minutes) {
    return 'Empieza en $minutes min';
  }

  @override
  String gatheringHostZone(String zone) {
    return 'Zona horaria del anfitrión: $zone';
  }

  @override
  String gatheringHostedBy(String name) {
    return 'Organiza $name';
  }

  @override
  String gatheringQuorumNeeded(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltan $countLabel personas para confirmar',
      one: 'Falta $countLabel persona para confirmar',
      zero: 'Listo para confirmarse',
    );
    return '$_temp0';
  }

  @override
  String gatheringConfirmed(int count) {
    return 'Confirmado · $count asistirán';
  }

  @override
  String get gatheringYouHost => 'Eres el anfitrión';

  @override
  String get gatheringGoingYou => 'Asistirás';

  @override
  String get gatheringFull => 'Completo';

  @override
  String get gatheringJoin => 'Apuntarme';

  @override
  String get gatheringAskToJoin => 'Pedir unirme';

  @override
  String get gatheringRequested => 'Has pedido unirte: el anfitrión decidirá';

  @override
  String get gatheringCreateTitle => 'Nuevo encuentro';

  @override
  String get gatheringCreateSubtitle => 'Una hora, un idioma y unas plazas. Lo demás es opcional.';

  @override
  String gatheringDefaultTitle(String language) {
    return 'Práctica de $language';
  }

  @override
  String get gatheringTitleLabel => '¿Qué vais a hacer?';

  @override
  String get gatheringLanguageLabel => 'Idioma';

  @override
  String get gatheringWhenLabel => 'Cuándo';

  @override
  String get gatheringSeatsLabel => 'Plazas';

  @override
  String get gatheringQuorumLabel => 'Confirmar con';

  @override
  String get gatheringQuorumExplainer => 'Cuentas como la primera persona que asiste. El encuentro se confirma cuando se apunte ese número de personas.';

  @override
  String get gatheringPost => 'Publicarlo';

  @override
  String get gatheringPosted => 'Publicado: ahora compártelo';

  @override
  String get gatheringNeedsTitle => 'Primero ponle un nombre';

  @override
  String get gatheringNeedsLanguage => 'Primero elige un idioma';

  @override
  String get gatheringNeedsFuture => 'Elige una hora futura';

  @override
  String get gatheringDetailTitle => 'Encuentro';

  @override
  String get gatheringNotFound => 'Este encuentro ya no está disponible';

  @override
  String gatheringDuration(int minutes) {
    return '$minutes minutos';
  }

  @override
  String gatheringSeatsTaken(int going, int capacity) {
    return '$going de $capacity plazas ocupadas';
  }

  @override
  String get gatheringCancelled => 'Cancelado';

  @override
  String get gatheringEnded => 'Este encuentro ha terminado';

  @override
  String get gatheringCancelRsvp => 'Cancelar mi asistencia';

  @override
  String gatheringHostDecision(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Por ahora solo van $countLabel personas. ¿Lo haces igualmente o lo cancelas?',
    );
    return '$_temp0';
  }

  @override
  String get gatheringHostDecisionAlone => 'Por ahora solo vas tú. ¿Lo haces igualmente o lo cancelas?';

  @override
  String get gatheringRunAnyway => 'Hacerlo igualmente';

  @override
  String get gatheringCallItOff => 'Cancelarlo';

  @override
  String get gatheringEnd => 'Terminar encuentro';

  @override
  String get gatheringEndedThanks => 'Terminado: escribir a quien conociste es gratis';

  @override
  String get gatheringCancelIt => 'Cancelar encuentro';

  @override
  String get gatheringKeepIt => 'Mantenerlo';

  @override
  String gatheringCancelConfirm(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countLabel personas lo están esperando. Les avisaremos de que se cancela.',
      one: '$countLabel persona lo está esperando. Le avisaremos de que se cancela.',
    );
    return '$_temp0';
  }

  @override
  String get clubDetailTitle => 'Club';

  @override
  String get clubNotFound => 'Este club ya no está disponible';

  @override
  String clubMembers(num count, String countLabel) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countLabel miembros',
      one: '$countLabel miembro',
    );
    return '$_temp0';
  }

  @override
  String get clubJoin => 'Unirme al club';

  @override
  String get clubLeave => 'Salir del club';

  @override
  String get clubUpcoming => 'Próximamente';

  @override
  String get clubNothingScheduled => 'Todavía no hay nada programado.';

  @override
  String get clubHostGathering => 'Organizar un encuentro';

  @override
  String get clubCreateTitle => 'Nuevo club';

  @override
  String get clubCreateSubtitle => 'Un club mantiene unida a su gente entre encuentro y encuentro. Ponle el nombre de lo que realmente vais a hacer.';

  @override
  String get clubNameLabel => 'Nombre del club';

  @override
  String get clubInterestLabel => 'Interés';

  @override
  String get clubInterestHint => 'Opcional: correr, K-pop, HSK4';

  @override
  String get clubDescriptionLabel => 'Acerca de';

  @override
  String get clubCreate => 'Crear club';

  @override
  String get clubNeedsName => 'Primero ponle un nombre al club';

  @override
  String gatheringRequests(int count) {
    return '$count esperando unirse';
  }

  @override
  String get gatheringAdmit => 'Admitir';

  @override
  String get gatheringDeny => 'Rechazar';

  @override
  String get gatheringsMine => 'Mis quedadas';

  @override
  String get gatheringsMineEmpty => 'Nada todavía. Aquí aparecerán las quedadas que organices o a las que te unas.';

  @override
  String get gatheringsMineSubtitle => 'Quedadas que organizas o a las que te uniste';

  @override
  String get gatheringSave => 'Guardar';

  @override
  String get gatheringSaved => 'Cambios guardados';

  @override
  String get gatheringEditIt => 'Editar';

  @override
  String get intentSectionTitle => 'Para qué estás aquí';

  @override
  String get intentLearn => 'Aquí para aprender';

  @override
  String get intentMeet => 'Abierto a conocer gente';

  @override
  String get intentDate => 'Abierto a citas';

  @override
  String get intentPrivacyNote => 'Los demás ven lo que elijas, salvo las citas, que son privadas.';

  @override
  String get gatheringNoClubsYet => 'Aún no hay clubes: crea uno y tus quedadas tendrán un hogar.';

  @override
  String get topicConversation => 'Conversación';

  @override
  String get topicExamPrep => 'Preparación de examen';

  @override
  String get topicGrammar => 'Gramática';

  @override
  String get topicPronunciation => 'Pronunciación';

  @override
  String get topicCulture => 'Cultura';

  @override
  String get topicMedia => 'Música y cine';

  @override
  String get topicGames => 'Juegos';

  @override
  String get topicBusiness => 'Negocios';

  @override
  String get topicTravel => 'Viajes';

  @override
  String get filterThisWeek => 'Esta semana';

  @override
  String get filterThisWeekend => 'Este fin de semana';

  @override
  String get filterHasSeat => 'Con plazas';

  @override
  String filterClear(int count) {
    return 'Borrar $count';
  }

  @override
  String get filterNoMatches => 'Nada coincide con esos filtros todavía.';

  @override
  String get gatheringTopicLabel => 'Tema (opcional)';

  @override
  String get avatarViewStory => 'Ver historia';

  @override
  String get avatarViewPhoto => 'Ver foto de perfil';

  @override
  String get composerNext => 'Siguiente';

  @override
  String get notifyRepliesTitle => 'Recibe un aviso cuando alguien responda';

  @override
  String get notifyRepliesBody => 'Te avisaremos de los mensajes nuevos y de tu recordatorio diario de estudio. Puedes desactivar cualquiera cuando quieras.';

  @override
  String get notifyRepliesEnable => 'Activar';

  @override
  String get notifyRepliesLater => 'Ahora no';

  @override
  String get notificationsOffTitle => 'Las notificaciones están desactivadas';

  @override
  String get notificationsOffBody => 'Tu dispositivo bloquea las notificaciones de BananaTalk, así que los recordatorios y mensajes no pueden llegarte. Los ajustes de abajo no se aplicarán hasta que las actives.';

  @override
  String get notificationsOffOpen => 'Abrir ajustes';

  @override
  String get reportGathering => 'Denunciar quedada';

  @override
  String get reportClub => 'Denunciar club';

  @override
  String get finishProfileTitle => 'Termina de configurar tu perfil';

  @override
  String get finishProfileBody => 'Necesitamos tu fecha de nacimiento para que BananaTalk sea seguro para todos. Puedes cerrar sesión si prefieres no continuar.';

  @override
  String get finishProfileContinue => 'Continuar';

  @override
  String get finishProfileSignOut => 'Cerrar sesión';

  @override
  String packReviewProgress(int current, int total) {
    return 'Repaso $current de $total';
  }

  @override
  String get packReviewRecall => '¿Recuerdas esta palabra?';

  @override
  String get clubOrganizers => 'Organizadores';

  @override
  String get clubMembersLabel => 'Miembros';

  @override
  String clubMeetsIn(String city) {
    return 'Se reúne en $city';
  }

  @override
  String clubEventsHeld(int count) {
    return '$count eventos realizados';
  }

  @override
  String get clubEdit => 'Editar club';

  @override
  String get clubDelete => 'Eliminar club';

  @override
  String get clubDeleteConfirmTitle => '¿Eliminar este club?';

  @override
  String get clubDeleteConfirmBody => 'Sus eventos programados se mantienen: ya hay gente apuntada. Solo se elimina el club.';

  @override
  String get clubRemoveMember => 'Expulsar del club';

  @override
  String get clubMakeOrganizer => 'Hacer organizador';

  @override
  String get clubRemoveOrganizer => 'Quitar organizador';

  @override
  String clubSince(String date) {
    return 'Club desde $date';
  }

  @override
  String get clubNoEventsHeld => 'Aún no se han realizado eventos';

  @override
  String get clubPlaceLabel => 'Lugar habitual';

  @override
  String get groupCoverChange => 'Cambiar foto';

  @override
  String get groupCoverFromLibrary => 'Elegir de la galería';

  @override
  String get groupCoverTakePhoto => 'Hacer una foto';

  @override
  String get groupCoverRemove => 'Quitar foto';

  @override
  String get groupCoverAddOptional => 'Añadir una foto (opcional)';

  @override
  String get clubsMine => 'Mis clubes';

  @override
  String get clubsMineEmpty => 'Aún no te has unido a ningún club';

  @override
  String get storyLink => 'Enlace';

  @override
  String get storyLinkSubtitle => 'Lleva a quien lo vea a una página';

  @override
  String get storyLinkAdd => 'Añadir un enlace';

  @override
  String get storyLinkUrlLabel => 'Dirección del enlace';

  @override
  String get storyLinkButtonLabel => 'Texto del botón';

  @override
  String get storyLinkButtonDefault => 'Ver ahora';

  @override
  String storyLinkOpensHost(String host) {
    return 'Abre $host';
  }

  @override
  String get storyLinkInvalid => 'Introduce una dirección http o https válida';

  @override
  String get storyStickerPoll => 'Encuesta';

  @override
  String get storyStickerPollSubtitle => 'Haz una pregunta con opciones';

  @override
  String get storyStickerQuestion => 'Pregunta';

  @override
  String get storyStickerQuestionSubtitle => 'Deja que te envíen respuestas';

  @override
  String get storyStickerLocation => 'Ubicación';

  @override
  String get storyStickerLocationSubtitle => 'Etiqueta dónde se tomó esta historia';

  @override
  String get storyStickerMention => 'Mención';

  @override
  String get storyStickerMentionSubtitle => 'Etiqueta a alguien que sigues';

  @override
  String get storyToolDraw => 'Dibujar';

  @override
  String get momentsTabForYou => 'Para ti';

  @override
  String get momentsTabReels => 'Reels';

  @override
  String get storyArchiveTitle => 'Archivo';

  @override
  String get storyArchiveSubtitle => 'Tus historias caducadas, solo visibles para ti';

  @override
  String get storyArchiveEmpty => 'Nada archivado todavía';

  @override
  String get storyArchiveEmptyBody => 'Las historias pasan aquí tras 24 horas. Añade una a destacadas para mantenerla en tu perfil.';

  @override
  String get storyArchiveAddHighlight => 'Añadir a destacadas';

  @override
  String get storyArchiveAdded => 'Añadida a destacadas';

  @override
  String get doneAction => 'Listo';

  @override
  String get noneOption => 'Ninguno';

  @override
  String get stopAction => 'Detener';

  @override
  String get selectPlaceholder => 'Seleccionar...';

  @override
  String get goVip => 'Hazte VIP';

  @override
  String get logoutFailed => 'Error al cerrar sesión';

  @override
  String get vocabularyPacks => 'Paquetes de vocabulario';

  @override
  String get noVocabPacksYet => 'Aún no hay paquetes disponibles.';

  @override
  String get addWord => 'Añadir palabra';

  @override
  String get deleteWord => 'Eliminar palabra';

  @override
  String get shuffleAction => 'Mezclar';

  @override
  String get exitLessonTitle => '¿Salir de la lección?';

  @override
  String get exitQuizTitle => '¿Salir del cuestionario?';

  @override
  String get quizNotFound => 'Cuestionario no encontrado';

  @override
  String get vocabPackAddFailed => 'No se pudo añadir el paquete';

  @override
  String get vocabPackLoadFailed => 'No se pudo cargar el paquete';

  @override
  String get addToMyVocab => 'Añadir a mi vocabulario';

  @override
  String get viewAiSummary => 'Ver resumen de IA';

  @override
  String get reRecord => 'Volver a grabar';

  @override
  String get practiceComplete => 'Práctica completada';

  @override
  String get micPermissionNeeded => 'Se necesita permiso del micrófono';

  @override
  String get thanksForParticipating => '¡Gracias por participar! +10 XP 🎉';

  @override
  String deleteWordConfirm(String word) {
    return '¿Eliminar “$word” de tu vocabulario?';
  }

  @override
  String get wordDeleted => 'Palabra eliminada';

  @override
  String get vocabularyLoadFailed => 'No se pudo cargar tu vocabulario';

  @override
  String get savedTitle => 'Guardados';

  @override
  String get savedSubtitle => 'Reels y momentos que guardaste';

  @override
  String get introRequests => 'Solicitudes de presentación';

  @override
  String get icebreakerWhyLearn => '¿Qué te llevó a aprender un nuevo idioma?';

  @override
  String get icebreakerCanHelp => '¡Hola! Puedo ayudarte a practicar 😊';

  @override
  String get icebreakerFavoriteWord => '¿Cuál es tu palabra favorita en tu idioma?';

  @override
  String get icebreakerCoffeeChat => '¿Charlamos en un descanso para el café?';

  @override
  String get icebreakerHowsWeek => '¿Qué tal va tu semana?';

  @override
  String get failedToLoadReels => 'No se pudieron cargar los reels';

  @override
  String get failedToLoadSavedMoments => 'No se pudieron cargar tus guardados';

  @override
  String get adNotReady => 'El anuncio aún no está listo: inténtalo en un momento';

  @override
  String get addQuickReply => 'Añadir respuesta rápida';

  @override
  String get pollNeedQuestionAndOptions => 'Añade una pregunta y al menos 2 opciones';

  @override
  String get addOne => 'Añadir uno';

  @override
  String get addScreenshotsOrPhotos => 'Añade capturas o fotos';

  @override
  String get allowMultipleVotes => 'Permitir varios votos';

  @override
  String get attachImageOrTxt => 'Adjunta una imagen o un archivo .txt';

  @override
  String get audioUploadFailed => 'Error al subir el audio';

  @override
  String get browseFiles => 'Explorar archivos';

  @override
  String get clearCompleted => 'Borrar completados';

  @override
  String get closePollTitle => '¿Cerrar la encuesta?';

  @override
  String get coinHistory => 'Historial de monedas';

  @override
  String get coinShop => 'Tienda de monedas';

  @override
  String get conversationSummary => 'Resumen de la conversación';

  @override
  String get couldNotLoadFollowings => 'No se pudo cargar tu lista de seguidos';

  @override
  String get couldNotLoadMoreHistory => 'No se pudo cargar más historial.';

  @override
  String get couldNotLoadChats => 'No se pudieron cargar tus chats';

  @override
  String get decline => 'Rechazar';

  @override
  String get endConversationTitle => '¿Terminar la conversación?';

  @override
  String get explainAction => 'Explicar';

  @override
  String get failedToPlayAudio => 'No se pudo reproducir el audio';

  @override
  String get failedToSavePhrase => 'No se pudo guardar la frase';

  @override
  String get freeRetryUnlocked => '¡Reintento gratis desbloqueado! 🎉';

  @override
  String get getAnotherHint => 'Obtener otra pista';

  @override
  String get hideWhoVoted => 'Ocultar quién votó cada opción';

  @override
  String get invalidQrCode => 'Código QR no válido';

  @override
  String get linkCopiedToClipboard => 'Enlace copiado al portapapeles';

  @override
  String get loadMore => 'Cargar más';

  @override
  String get manage => 'Gestionar';

  @override
  String get maxTenOptions => 'Máximo 10 opciones';

  @override
  String get maybeLater => 'Quizá más tarde';

  @override
  String get minTwoOptions => 'Se requieren al menos 2 opciones';

  @override
  String get noMoreVotesAfterClosing => 'No se aceptarán más votos tras cerrarla.';

  @override
  String get noOneToMention => 'Aún no hay a quién mencionar';

  @override
  String get noRecentChatsToSendTo => 'No hay chats recientes a los que enviar';

  @override
  String get notEnoughCoins => 'No tienes monedas suficientes.';

  @override
  String get oneOptionIsCorrect => 'Una opción es la respuesta correcta';

  @override
  String get photoLibrary => 'Fototeca';

  @override
  String get phraseSavedToStudyQueue => 'Frase guardada en la cola de estudio';

  @override
  String get pleaseAddTwoOptions => 'Añade al menos 2 opciones';

  @override
  String get pleaseAttachEvidence => 'Adjunta al menos un archivo como prueba';

  @override
  String get pleaseEnterQuestion => 'Introduce una pregunta';

  @override
  String get pleaseSelectReportReason => 'Selecciona un motivo para el reporte';

  @override
  String get pleaseSelectCorrectAnswer => 'Selecciona la respuesta correcta del cuestionario';

  @override
  String get pollExpires => 'La encuesta expira';

  @override
  String get quizMode => 'Modo cuestionario';

  @override
  String get recordAReel => 'Graba un reel';

  @override
  String get reelsContentGuidelines => 'Normas de contenido para reels';

  @override
  String get reportTypeMissing => 'Falta el tipo de reporte';

  @override
  String get reportedContentIdMissing => 'Falta el ID del contenido reportado';

  @override
  String get reportedUserIdMissing => 'Falta el ID del usuario reportado';

  @override
  String get retryAll => 'Reintentar todo';

  @override
  String get savedToVocabulary => '¡Guardado en tu vocabulario!';

  @override
  String get savedFindInProfile => 'Guardado. Búscalo en Perfil → Guardados.';

  @override
  String get shareVia => 'Compartir mediante...';

  @override
  String get shareYourLocation => '¿Compartir tu ubicación?';

  @override
  String get suggestACorrection => 'Sugerir una corrección';

  @override
  String get translationCopied => 'Traducción copiada';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get unlockPremiumWallpapers => 'Desbloquea fondos premium';

  @override
  String get uploadQueue => 'Cola de subida';

  @override
  String get usersCanVoteMultiple => 'Los usuarios pueden votar varias opciones';

  @override
  String get watchAd => 'Ver anuncio';

  @override
  String get matchReasonReciprocal => 'Cada uno aprende el idioma del otro';

  @override
  String matchReasonSameTarget(String language) {
    return 'También aprende $language';
  }

  @override
  String matchReasonSharedTopic(String topic) {
    return 'Interés en común: $topic';
  }

  @override
  String get matchReasonActiveToday => 'Activo hoy';

  @override
  String get matchReasonSameCity => 'Vive en tu ciudad';

  @override
  String get matchRepliesFast => 'Responde rápido';

  @override
  String matchesTodayTitle(int count) {
    return 'Tus $count matches de hoy';
  }

  @override
  String matchesRefreshHint(String time) {
    return 'se renueva a las $time';
  }

  @override
  String get matchesRefreshHintFallback => 'se renueva a medianoche';

  @override
  String get matchesEmptyTitle => 'Eso es todo por hoy';

  @override
  String get matchesEmptyBody => 'Mañana hay matches nuevos. Mientras tanto, explora todos los compañeros.';

  @override
  String get matchesEmptyCta => 'Ver compañeros';

  @override
  String get matchSayHi => 'Saludar';

  @override
  String get communityTabMatches => 'Matches';

  @override
  String get communityTabPartners => 'Partners';

  @override
  String get segmentAll => 'All';

  @override
  String get segmentSerious => 'Estudiantes constantes';

  @override
  String get segmentNew => 'Miembros nuevos';

  @override
  String get segmentSeriousHint => 'Perfil completo · activo esta semana';

  @override
  String get segmentNewHint => 'Se unieron en los últimos 7 días';

  @override
  String openerReciprocal(String theirLanguage, String myLanguage) {
    return '¿Y si escribimos mitad en $theirLanguage y mitad en $myLanguage? Yo te corrijo y tú a mí 😄';
  }

  @override
  String openerSharedTopic(String topic) {
    return 'Vi que te gusta $topic, ¿cómo empezaste?';
  }

  @override
  String openerGeneric(String name, String language) {
    return '¡Hola $name! Estoy aprendiendo $language, ¿tienes algún consejo? 👋';
  }

  @override
  String get openerChipsTitle => 'Frases para romper el hielo: toca para editarlas';

  @override
  String stallRescueTitle(String name) {
    return '$name te preguntó algo 👀';
  }

  @override
  String get stallRescueHint => '¡Perdón por tardar! ¿Seguimos hablando? 😊';

  @override
  String get referralTitle => 'Invitar amigos';

  @override
  String get referralSubtitle => 'Gana monedas cuando un amigo se une';

  @override
  String get referralYourCode => 'Tu código de invitación';

  @override
  String referralInvitedCount(int count) {
    return 'Invitados: $count';
  }

  @override
  String referralShareText(String code, String link) {
    return 'Únete a mí en BananaTalk — practica idiomas con personas reales. Usa mi código de invitación $code: $link';
  }

  @override
  String get referralCopy => 'Copiar';

  @override
  String get referralShare => 'Compartir';

  @override
  String get referralCopied => 'Copiado';

  @override
  String referralClaimed(int coins) {
    String _temp0 = intl.Intl.pluralLogic(
      coins,
      locale: localeName,
      other: '¡Ganaste $coins monedas!',
      one: '¡Ganaste $coins moneda!',
    );
    return '$_temp0';
  }

  @override
  String get referralHowItWorks => 'Cuando un amigo se registra con tu código y completa su perfil, ambos reciben monedas.';

  @override
  String get boostTitle => 'Impulsar mi perfil';

  @override
  String get boostSubtitle => 'Que te vean más compañeros durante 24 h';

  @override
  String get boostFromMatches => 'Que te vea más gente';

  @override
  String get boostedChip => 'Impulsado';

  @override
  String get boostCapacityFull => 'Todos los cupos de impulso están ocupados ahora — inténtalo de nuevo en unas horas';

  @override
  String extraMatchesCta(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '+3 coincidencias más — $cost monedas',
      one: '+3 coincidencias más — $cost moneda',
    );
    return '$_temp0';
  }

  @override
  String get boostExplain => 'Sé la 6.ª coincidencia de todos los que encajan con tus idiomas durante 24 horas.';

  @override
  String boostCostLine(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Coste: $cost monedas',
      one: 'Coste: $cost moneda',
    );
    return '$_temp0';
  }

  @override
  String boostBalanceLine(int balance) {
    String _temp0 = intl.Intl.pluralLogic(
      balance,
      locale: localeName,
      other: 'Tu saldo: $balance monedas',
      one: 'Tu saldo: $balance moneda',
    );
    return '$_temp0';
  }

  @override
  String get boostConfirm => 'Confirmar impulso';

  @override
  String get boostActiveTitle => 'Tu impulso está activo';

  @override
  String boostTimeLeft(String time) {
    return 'Quedan $time';
  }

  @override
  String boostSeenBy(int count) {
    return 'Visto por $count personas hasta ahora';
  }

  @override
  String get boostFailed => 'No se pudo iniciar tu impulso. Inténtalo de nuevo.';

  @override
  String get rewardedLimitReached => 'Has usado los desbloqueos gratuitos de hoy para esto — inténtalo de nuevo mañana';

  @override
  String get wavesMaskedTitle => 'Alguien te saludó';

  @override
  String wavesMaskedBody(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Descubre quién por $cost monedas, o hazte VIP',
      one: 'Descubre quién por $cost moneda, o hazte VIP',
    );
    return '$_temp0';
  }

  @override
  String get wavesMaskedBodyVip => 'Hazte VIP para ver quién te saludó';

  @override
  String get perkAdFree => 'Sin anuncios';

  @override
  String get perkUnlimitedMatches => 'Coincidencias diarias ilimitadas';

  @override
  String get perkRevealWaves => 'Mira quién te saludó y vio tu perfil';

  @override
  String get perkUnlimitedWaves => 'Saludos ilimitados';

  @override
  String get perkAdvancedFilters => 'Filtros avanzados de compañeros';

  @override
  String get vipFromMatches => 'VIP: coincidencias ilimitadas';

  @override
  String get vipRemoveAds => 'Quitar anuncios';

  @override
  String get limitUnlockedRetry => 'Desbloqueado — enviando de nuevo';

  @override
  String get rewardedUnlockSuccess => '¡Desbloqueado! Ya puedes intentarlo de nuevo.';

  @override
  String get extraMatchesMaxed => 'Ya tienes el máximo de coincidencias extra por hoy';

  @override
  String wavesMaskedTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas te saludaron',
      one: 'Alguien te saludó',
    );
    return '$_temp0';
  }

  @override
  String visitorsMaskedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas vieron tu perfil',
      one: 'Alguien vio tu perfil',
    );
    return '$_temp0';
  }

  @override
  String visitorsMaskedBody(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: 'Descubre quién por $cost monedas, o hazte VIP',
      one: 'Descubre quién por $cost moneda, o hazte VIP',
    );
    return '$_temp0';
  }

  @override
  String get visitorsMaskedBodyVip => 'Hazte VIP para ver quién vio tu perfil';

  @override
  String boostDurationHm(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String boostDurationM(int minutes) {
    return '$minutes min';
  }

  @override
  String get boostEndingSoon => 'Termina pronto';

  @override
  String coinAmount(int cost) {
    return '💎$cost';
  }

  @override
  String unlockedMore(int count) {
    return '¡Desbloqueadas +$count más!';
  }

  @override
  String get getMoreCoins => 'Conseguir más monedas';

  @override
  String get unlockFailed => 'No se pudo desbloquear ahora.';

  @override
  String unlockGrantForCoins(int count, int cost) {
    return 'Desbloquear $count por 💎$cost';
  }

  @override
  String get waveLimitTitle => 'Has usado tus saludos de hoy';

  @override
  String get waveLimitBody => 'Consigue un saludo más ahora o vuelve mañana.';

  @override
  String get limitDailyReachedTitle => 'Límite diario alcanzado';

  @override
  String get limitLabelMessages => 'Mensajes';

  @override
  String get limitLabelMoments => 'Momentos';

  @override
  String get limitLabelStories => 'Historias';

  @override
  String get limitLabelComments => 'Comentarios';

  @override
  String get limitLabelProfileViews => 'Visitas de perfil';

  @override
  String get limitLabelWaves => 'Saludos';

  @override
  String limitUsedLabel(String label) {
    return '$label usados';
  }

  @override
  String get limitDescMessages => 'Has alcanzado tu límite diario de mensajes. ¡Hazte VIP para enviar mensajes ilimitados!';

  @override
  String get limitDescMoments => 'Has alcanzado tu límite diario de momentos. ¡Hazte VIP para publicar momentos ilimitados!';

  @override
  String get limitDescStories => 'Has alcanzado tu límite diario de historias. ¡Hazte VIP para publicar historias ilimitadas!';

  @override
  String get limitDescComments => 'Has alcanzado tu límite diario de comentarios. ¡Hazte VIP para comentar sin límite!';

  @override
  String get limitDescProfileViews => 'Has alcanzado tu límite diario de visitas de perfil. ¡Hazte VIP para ver perfiles sin límite!';

  @override
  String get limitDescDefault => 'Has alcanzado tu límite diario. ¡Hazte VIP para tener acceso ilimitado!';

  @override
  String get limitResetsAt => 'El límite se reinicia el';

  @override
  String get vipMembersGet => 'Los miembros VIP obtienen';

  @override
  String get vipBenefitUnlimitedMessages => 'Mensajes ilimitados';

  @override
  String get vipBenefitUnlimitedProfileViews => 'Visitas de perfil ilimitadas';

  @override
  String get vipBenefitAiStudyTools => 'Herramientas de estudio con IA';

  @override
  String chatBonusMessagesUnlocked(int count) {
    return '¡Desbloqueaste $count mensajes extra! Sigue chateando.';
  }

  @override
  String callLabelOutgoing(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Videollamada saliente',
        'other': 'Llamada de voz saliente',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelIncoming(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Videollamada entrante',
        'other': 'Llamada de voz entrante',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelNoAnswer(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Videollamada · Sin respuesta',
        'other': 'Llamada de voz · Sin respuesta',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelMissed(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Videollamada perdida',
        'other': 'Llamada de voz perdida',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelCancelled(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Videollamada cancelada',
        'other': 'Llamada de voz cancelada',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelDeclinedOutgoing(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Videollamada rechazada',
        'other': 'Llamada de voz rechazada',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelDeclinedIncoming(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'video': 'Rechazaste una videollamada',
        'other': 'Rechazaste una llamada de voz',
      },
    );
    return '$_temp0';
  }

  @override
  String callLabelBusy(String name) {
    return '$name estaba en otra llamada';
  }

  @override
  String get callsTitle => 'Llamadas';

  @override
  String get callsEmpty => 'Aún no hay llamadas';

  @override
  String get callCameraPaused => 'Cámara en pausa';

  @override
  String get callFullScreenIntentTitle => 'Mostrar llamadas en la pantalla de bloqueo';

  @override
  String get callFullScreenIntentBody => 'Permite que BananaTalk muestre las llamadas entrantes a pantalla completa para que no te las pierdas con el teléfono bloqueado.';

  @override
  String get callForegroundTitle => 'Llamada en curso';

  @override
  String get callForegroundBody => 'Toca para volver a la llamada';

  @override
  String get callServiceChannelName => 'Llamada en curso';

  @override
  String get callServiceChannelDescription => 'Mantiene tu llamada activa mientras BananaTalk está en segundo plano';

  @override
  String firstSessionMatchesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas elegidas para ti hoy',
      one: '1 persona elegida para ti hoy',
    );
    return '$_temp0';
  }

  @override
  String get firstSessionMatchesBody => 'Saluda: basta con un primer mensaje.';

  @override
  String get guideAiStudyTitle => 'Practica antes de tener que hacerlo';

  @override
  String get guideAiStudyBody => 'Practica con el tutor de IA o prepárate para un examen real. Dos minutos son una sesión.';

  @override
  String get guideAiStudyCta => 'Abrir herramientas de IA';

  @override
  String get guideChatsTitle => 'Aquí viven tus conversaciones';

  @override
  String get guideChatsBody => 'Nada todavía. Saluda a alguno de los matches de hoy y esta lista se llenará.';

  @override
  String get guideChatsCta => 'Buscar a alguien';

  @override
  String get guideMomentsTitle => 'Publica algo en el idioma que estás aprendiendo';

  @override
  String get guideMomentsBody => 'Una foto o una línea. Los nativos corrigen lo que escribes aquí.';

  @override
  String get guideMomentsCta => 'Publicar un momento';

  @override
  String get guideProfileTitle => 'Completa tu perfil';

  @override
  String get guideProfileBody => 'Una foto y una línea sobre ti. Los perfiles a medias se pasan por alto.';

  @override
  String get guideProfileCta => 'Editar perfil';

  @override
  String get conversationEmptyTitle => 'Aún no hay mensajes';

  @override
  String conversationEmptyBody(String name) {
    return 'Envía un mensaje para empezar la conversación con $name';
  }

  @override
  String get conversationEmptySayHi => '¡Toca para saludar!';

  @override
  String get momentVideoOptimizing => 'Espera mientras optimizamos tu vídeo';

  @override
  String get momentPostedWithoutVoiceNote => 'Tu momento se publicó sin la nota de voz.';

  @override
  String get momentAnsweringPromptOfDay => 'Respondiendo a la pregunta del día';

  @override
  String get momentVideoReady => 'Vídeo listo';

  @override
  String get momentReadyToUpload => 'Listo para subir';

  @override
  String get locationServicesDisabledTitle => 'Servicios de ubicación desactivados';

  @override
  String get locationServicesDisabledBody => 'Activa los servicios de ubicación en los ajustes de tu dispositivo para usar esta función.';

  @override
  String get locationPermissionNeededBody => 'Bananatalk necesita permiso de ubicación para etiquetar tus momentos con tu ubicación actual.';

  @override
  String get locationPermissionRequiredTitle => 'Permiso de ubicación necesario';

  @override
  String get locationPermissionPermanentlyDeniedBody => 'El permiso de ubicación se denegó de forma permanente. Actívalo en los ajustes de la app para etiquetar tu ubicación en los momentos.';

  @override
  String get termsSnackAcceptFirst => 'Acepta los Términos del Servicio para continuar';

  @override
  String get termsErrorAccepting => 'Error al aceptar los términos. Inténtalo de nuevo.';

  @override
  String get termsEulaTitle => 'Acuerdo de licencia de usuario final (EULA)';

  @override
  String get termsWelcomeHeading => 'Te damos la bienvenida a Bananatalk';

  @override
  String get termsWelcomeBody => 'Al usar Bananatalk aceptas quedar sujeto a estos Términos del Servicio. Léelos con atención antes de usar nuestro servicio.';

  @override
  String get termsZeroToleranceHeading => 'Política de tolerancia cero';

  @override
  String get termsZeroToleranceIntro => 'Bananatalk aplica una política de TOLERANCIA CERO con el contenido ofensivo y los usuarios abusivos. No permitimos, aprobamos ni toleramos:';

  @override
  String get termsZeroToleranceItem1 => 'Acoso, intimidación o amenazas de cualquier tipo';

  @override
  String get termsZeroToleranceItem2 => 'Discurso de odio, discriminación o contenido que promueva la violencia';

  @override
  String get termsZeroToleranceItem3 => 'Contenido sexualmente explícito, pornográfico o inapropiado';

  @override
  String get termsZeroToleranceItem4 => 'Spam, estafas o actividades fraudulentas';

  @override
  String get termsZeroToleranceItem5 => 'Suplantación de identidad o representación falsa';

  @override
  String get termsZeroToleranceItem6 => 'Cualquier contenido que infrinja las leyes o normativas aplicables';

  @override
  String get termsZeroToleranceEnforcement => 'Los usuarios que infrinjan estas políticas serán expulsados de inmediato de la plataforma. Nos reservamos el derecho de eliminar cualquier contenido y cerrar cualquier cuenta que incumpla estos términos sin aviso previo.';

  @override
  String get termsUgcHeading => 'Contenido generado por el usuario';

  @override
  String get termsUgcBody => 'Bananatalk permite a los usuarios crear y compartir contenido, incluidos mensajes, publicaciones, imágenes y otros materiales. Eres el único responsable de todo el contenido que crees, subas o compartas a través del servicio.';

  @override
  String get termsUgcAgreeIntro => 'Al usar Bananatalk, aceptas que:';

  @override
  String get termsUgcItem1 => 'No publicarás contenido ofensivo, dañino o ilegal';

  @override
  String get termsUgcItem2 => 'No tendrás conductas abusivas hacia otros usuarios';

  @override
  String get termsUgcItem3 => 'Respetarás los derechos y la dignidad de todos los usuarios';

  @override
  String get termsUgcItem4 => 'Denunciarás cualquier contenido ofensivo o usuario abusivo que encuentres';

  @override
  String get termsModerationHeading => 'Moderación de contenido';

  @override
  String get termsModerationBody => 'Bananatalk modera activamente el contenido de los usuarios para mantener un entorno seguro y respetuoso. Usamos sistemas automatizados y moderadores humanos para revisar y retirar el contenido que infrinja nuestras políticas.';

  @override
  String get termsModerationReport => 'Si encuentras contenido ofensivo o comportamiento abusivo, denúncialo de inmediato con las herramientas de denuncia de la app. Tomamos todas las denuncias en serio y las investigaremos con prontitud.';

  @override
  String get termsAccountHeading => 'Responsabilidad de la cuenta';

  @override
  String get termsAccountBody => 'Eres responsable de mantener la seguridad de tu cuenta y de toda la actividad que ocurra en ella. Te comprometes a avisarnos de inmediato de cualquier uso no autorizado de tu cuenta.';

  @override
  String get termsProhibitedHeading => 'Actividades prohibidas';

  @override
  String get termsProhibitedIntro => 'Además de la política de tolerancia cero anterior, aceptas no:';

  @override
  String get termsProhibitedItem1 => 'Infringir ninguna ley local, estatal, nacional o internacional aplicable';

  @override
  String get termsProhibitedItem2 => 'Vulnerar los derechos de terceros, incluidos los de propiedad intelectual';

  @override
  String get termsProhibitedItem3 => 'Transmitir virus, malware o código dañino';

  @override
  String get termsProhibitedItem4 => 'Intentar acceder sin autorización al servicio o a otras cuentas';

  @override
  String get termsProhibitedItem5 => 'Usar el servicio con fines comerciales sin autorización';

  @override
  String get termsTerminationHeading => 'Cancelación';

  @override
  String get termsTerminationBody => 'Nos reservamos el derecho de suspender o cerrar tu cuenta en cualquier momento, con o sin aviso, por cualquier incumplimiento de estos Términos del Servicio, incluidos, entre otros, publicar contenido ofensivo o incurrir en conductas abusivas.';

  @override
  String get termsChangesHeading => 'Cambios en los términos';

  @override
  String get termsChangesBody => 'Podemos actualizar estos Términos del Servicio de vez en cuando. Seguir usando el servicio tras los cambios supone la aceptación de los términos actualizados.';

  @override
  String get termsContactHeading => 'Contacto';

  @override
  String get termsContactBody => 'Si tienes preguntas sobre estos Términos del Servicio o necesitas denunciar una infracción, contáctanos mediante las funciones de soporte de la app.';

  @override
  String get termsAgreeCheckbox => 'Acepto los Términos del Servicio y la Política de tolerancia cero';

  @override
  String get termsProcessing => 'Procesando...';

  @override
  String get termsAcceptAndContinue => 'Aceptar y continuar';

  @override
  String termsLastUpdated(int year) {
    return 'Última actualización: $year';
  }

  @override
  String get wavesFailedToLoad => 'No se pudieron cargar los saludos';

  @override
  String get wavesEmptyTitle => 'Aún no hay saludos';

  @override
  String get wavesEmptyBody => 'Cuando alguien te salude,\nlo verás aquí';

  @override
  String get wavesWavedAtYou => 'Te ha saludado';

  @override
  String get lessonYourTranslation => 'Tu traducción:';

  @override
  String get lessonTapWordsToBuild => 'Toca las palabras de abajo para construir tu traducción';

  @override
  String get lessonWordBank => 'Banco de palabras:';

  @override
  String get lessonTypeTranslationHint => 'Escribe aquí tu traducción...';

  @override
  String get lessonCorrect => '¡Correcto!';

  @override
  String get lessonIncorrect => 'Incorrecto';

  @override
  String get lessonCheck => 'Comprobar';

  @override
  String get lessonTitle => 'Lección';

  @override
  String get lessonFailedToLoad => 'No se pudo cargar la lección';

  @override
  String get lessonResultCorrect => 'Correctas';

  @override
  String get lessonResultIncorrect => 'Incorrectas';

  @override
  String get lessonDone => 'Listo';

  @override
  String get lessonPraiseExcellent => '¡Excelente!';

  @override
  String get lessonPraiseGreat => '¡Buen trabajo!';

  @override
  String get lessonPraiseGood => '¡Buen intento!';

  @override
  String get lessonPraiseKeepPracticing => '¡Sigue practicando!';

  @override
  String get lessonPraiseTryAgain => '¡Inténtalo otra vez!';

  @override
  String get lessonExitWarning => 'Tu progreso no se guardará si sales ahora.';

  @override
  String get lessonNotFound => 'Lección no encontrada';

  @override
  String get lessonMayHaveBeenRemoved => 'Puede que esta lección se haya eliminado';

  @override
  String get lessonNoExercises => 'Esta lección aún no tiene ejercicios';

  @override
  String get quizTitle => 'Cuestionario';

  @override
  String get quizFailedToLoad => 'No se pudo cargar el cuestionario';

  @override
  String get quizSubmit => 'Enviar';

  @override
  String get quizScore => 'Puntuación';

  @override
  String get quizCorrect => 'Correctas';

  @override
  String get quizWrong => 'Incorrectas';

  @override
  String get quizYourLevel => 'Tu nivel';

  @override
  String get quizPraiseKeepLearning => '¡Sigue aprendiendo!';

  @override
  String get quizExitWarning => 'Perderás tu progreso si sales ahora.';

  @override
  String get vocabFailedToLoad => 'No se pudieron cargar los repasos';

  @override
  String get vocabNoneDue => 'Ahora mismo no hay palabras para repasar';

  @override
  String get vocabGotIt => '¡Entendido!';

  @override
  String get vocabTapToReveal => 'Toca la tarjeta para ver la respuesta';

  @override
  String get vocabSessionComplete => '¡Sesión completada!';

  @override
  String get wavesEmptyBody2 => 'Cuando alguien te salude,\nlo verás aquí';

  @override
  String lessonCorrectAnswer(String answer) {
    return 'Respuesta correcta: $answer';
  }

  @override
  String quizQuestionOfTotal(int current, int total) {
    return 'Pregunta $current de $total';
  }

  @override
  String get vocabXpEarned => 'XP ganada';

  @override
  String get vocabWatchAdBonus => 'Ver anuncio por +10 XP extra';

  @override
  String get vocabBonusEarned => '¡+10 XP extra conseguida! 🎉';

  @override
  String vipBannerIsMember(String userName) {
    return '$userName es miembro VIP';
  }

  @override
  String get vipBannerGetBenefits => '¡Consigue las ventajas VIP como él!';

  @override
  String get vipUpgrade => 'Mejorar';

  @override
  String get vipUnlockAllFeatures => 'Desbloquea todas las funciones';

  @override
  String get chatFailedToLoadUser => 'No se pudieron cargar los datos del usuario';

  @override
  String get chatDailyLimitTitle => 'Has alcanzado el límite diario de chats';

  @override
  String get chatUnlimitedTitle => 'Chats ilimitados';

  @override
  String get chatUnlimitedBody => '¡Habla con toda la gente que quieras! Los miembros VIP tienen conversaciones diarias ilimitadas.';

  @override
  String get coinsStoreUnavailable => 'Las compras de monedas solo están disponibles en iOS y Android.';

  @override
  String get coinsPurchaseCanceled => 'La compra se canceló o no se pudo iniciar.';

  @override
  String get coinsReceiptUnreadable => 'No se pudo leer el recibo de compra. Inténtalo de nuevo.';

  @override
  String get coinsAdded => '¡Monedas añadidas! 💎';

  @override
  String get coinsVerifyRetry => 'No se pudo verificar la compra. Se reintentará automáticamente; prueba a restaurar las compras si no aparecen las monedas.';

  @override
  String get coinsAlreadyClaimed => 'Ya lo reclamaste hoy: vuelve mañana.';

  @override
  String get coinsDailyClaimed => '¡Recompensa diaria reclamada! +10 💎';

  @override
  String get coinsClaimFailed => 'No se pudo reclamar la recompensa diaria.';

  @override
  String get coinsAdThanks => '¡Gracias por verlo! +5 💎';

  @override
  String get coinsAdCreditFailed => 'No se pudo acreditar la recompensa del anuncio.';

  @override
  String get coinsGetCoins => 'Conseguir monedas';

  @override
  String get coinsGetCoinsSubtitle => 'Desbloquea al instante traducciones, chats con el tutor y momentos extra.';

  @override
  String get coinsYourBalance => 'Tu saldo';

  @override
  String get coinsEarnFree => 'Consigue monedas gratis';

  @override
  String get coinsDailyReward => 'Recompensa diaria';

  @override
  String get coinsComeBackTomorrow => 'Vuelve mañana';

  @override
  String get coinsDailyRewardSubtitle => '+10 monedas, una vez al día';

  @override
  String get coinsClaimed => 'Reclamada';

  @override
  String get coinsClaim => 'Reclamar';

  @override
  String get coinsWatchAd => 'Ver un anuncio';

  @override
  String get coinsAdLimitReached => 'Límite diario alcanzado: vuelve mañana';

  @override
  String get exploreTitle => 'Explorar';

  @override
  String get exploreNoMoments => 'No hay momentos que explorar';

  @override
  String get exploreFailedToLoad => 'No se pudo cargar';

  @override
  String get exploreNoTrending => 'Aún no hay momentos en tendencia';

  @override
  String get exploreNoVideos => 'Aún no hay vídeos';

  @override
  String get exploreBeFirstVideo => '¡Sé el primero en compartir un vídeo!';

  @override
  String get exploreFailedVideos => 'No se pudieron cargar los vídeos';

  @override
  String get facebookLoginSubtitle => 'Continúa con tu cuenta de Facebook\npara una experiencia fluida';

  @override
  String get securedByFacebook => 'Protegido por Facebook';

  @override
  String get continueWithEmail => 'Continuar con correo';

  @override
  String get continueWithFacebook => 'Continuar con Facebook';

  @override
  String get suspendedTitle => 'Tu cuenta ha sido suspendida';

  @override
  String get suspendedContact => 'Si crees que ha sido un error, escribe a appeal@banatalk.com indicando tu nombre de usuario.';

  @override
  String get suspendedNoAccess => 'Tu cuenta ya no está accesible.';

  @override
  String get suspendedReason => 'Motivo:';

  @override
  String get correctionSuggestTitle => 'Sugerir una corrección';

  @override
  String get correctionOriginal => 'Original';

  @override
  String get correctionYours => 'Tu corrección';

  @override
  String get correctionTypeHint => 'Escribe la versión corregida...';

  @override
  String get correctionChanges => 'Cambios';

  @override
  String get correctionExplanationOptional => 'Explicación (opcional)';

  @override
  String get correctionWhyHint => '¿Por qué hiciste esta corrección?';

  @override
  String get correctionSend => 'Enviar corrección';

  @override
  String get correctionSuggested => 'Corrección sugerida';

  @override
  String get correctionFailedToSend => 'No se pudo enviar la corrección';

  @override
  String get ttsUnavailable => 'Lectura en voz alta no disponible';

  @override
  String get translationDailyLimitTitle => 'Has alcanzado el límite diario de traducciones';

  @override
  String get translationDailyLimitBody => 'Los usuarios gratuitos tienen 5 traducciones al día.\n¡Hazte VIP para tenerlas sin límite!';

  @override
  String get ttsListen => 'Escuchar';

  @override
  String correctionOfMessage(String name) {
    return 'Corregir el mensaje de $name';
  }

  @override
  String translatedToLanguage(String language) {
    return 'Traducido a $language';
  }

  @override
  String guideProgress(int count) {
    return 'Primeros pasos · $count de 4';
  }

  @override
  String get guideChatTip => 'Mantén pulsado para traducir o corregir';

  @override
  String get announcementTitle => 'Anuncio';

  @override
  String get announcementUnavailable => 'Este anuncio ya no está disponible.';

  @override
  String get notifyAnnouncementsTitle => 'Anuncios';

  @override
  String get notifyAnnouncementsSubtitle => 'Noticias y novedades del equipo de BananaTalk';

  @override
  String chatDailyLimitBody(Object count) {
    return 'Los usuarios gratuitos pueden chatear con hasta $count personas al día.\n¡Hazte VIP para conversaciones ilimitadas!';
  }

  @override
  String get chatCompressingVideo => 'Comprimiendo video...';

  @override
  String chatShareLocationBody(Object name) {
    return 'Envía tu ubicación actual a $name. Hazlo solo con personas de confianza.';
  }

  @override
  String get chatShareLocationThisChat => 'este chat';

  @override
  String get chatTranslationLimitReached => 'Límite de traducción alcanzado';

  @override
  String get chatTranslateLimitBody => 'Has usado las traducciones gratuitas de hoy en este chat. Desbloquea más al instante con monedas.';

  @override
  String chatReplyingTo(Object name) {
    return 'Respondiendo a $name';
  }

  @override
  String get chatReplyingToFallback => 'usuario';

  @override
  String chatSendingMedia(Object mediaType) {
    return 'Enviando $mediaType...';
  }

  @override
  String get chatEnterUsernameStart => 'Introduce un nombre de usuario para iniciar un chat';

  @override
  String chatSearching(Object username) {
    return 'Buscando a @$username...';
  }

  @override
  String chatDeleteConversationBody(Object name) {
    return '¿Eliminar tu conversación con $name? Esta acción no se puede deshacer.';
  }

  @override
  String get chatQrCode => 'Código QR';

  @override
  String get chatDraft => 'Borrador: ';

  @override
  String get chatTyping => 'escribiendo...';

  @override
  String get chatPoweredBy => 'Con tecnología de ';

  @override
  String get chatReconnecting => 'Reconectando al chat...';

  @override
  String get chatDailyLimitReached => 'Límite diario de mensajes alcanzado';

  @override
  String chatMessagesRemainingToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes restantes hoy',
      one: '1 mensaje restante hoy',
    );
    return '$_temp0';
  }

  @override
  String get chatTranslatePreviewHint => 'Empieza a escribir para ver la traducción';

  @override
  String get chatNoMessagesYet => 'Aún no hay mensajes';

  @override
  String get chatMediaPhoto => 'foto';

  @override
  String get chatMediaVideo => 'video';

  @override
  String get chatMediaAudio => 'audio';

  @override
  String get chatMediaFile => 'archivo';

  @override
  String get chatMediaGeneric => 'contenido';

  @override
  String get chatMessageFailedToSend => 'No se pudo enviar el mensaje';

  @override
  String get chatSendingEllipsis => 'Enviando...';

  @override
  String get chatFailedTapOptions => 'Error · Toca para ver opciones';

  @override
  String get chatMessageWasDeleted => 'Este mensaje fue eliminado';

  @override
  String get chatStory => 'Historia';

  @override
  String get chatHi => '¡Hola!';

  @override
  String get chatEdited => 'editado';

  @override
  String get chatPremium => 'Premium ✨';

  @override
  String chatUnlockPremiumWallpapers(int cost) {
    String _temp0 = intl.Intl.pluralLogic(
      cost,
      locale: localeName,
      other: '¿Desbloquear todos los fondos Premium ✨ por 💎$cost monedas? Esto desbloquea todo el paquete para siempre.',
      one: '¿Desbloquear todos los fondos Premium ✨ por 💎$cost moneda? Esto desbloquea todo el paquete para siempre.',
    );
    return '$_temp0';
  }

  @override
  String chatWallpaperForName(Object userName) {
    return 'Fondo de chat para $userName';
  }

  @override
  String get chatChooseGallery => 'Elegir de la galería';

  @override
  String get chatHiThere => '¡Hola! 😊';

  @override
  String chatCorrected(Object correctorName) {
    return '$correctorName corrigió';
  }

  @override
  String get chatCorrectionAccepted => 'Corrección aceptada ✓';

  @override
  String chatForwarded(Object senderName) {
    return 'Reenviado de $senderName';
  }

  @override
  String get chatCached => 'En caché';

  @override
  String get chatWordBreakdown => 'Desglose de palabras';

  @override
  String get chatAlternatives => 'Alternativas';

  @override
  String chatTranslationAlso(Object items) {
    return 'También: $items';
  }

  @override
  String get chatAudioUnavailable => 'Audio no disponible';

  @override
  String get chatHideTranslation => 'Ocultar traducción';

  @override
  String get chatStoryExpired => 'Historia caducada';

  @override
  String get chatAcceptCorrection => 'Aceptar corrección';

  @override
  String get chatAccepting => 'Aceptando…';

  @override
  String get chatSaveToVocabularyAction => 'Guardar en vocabulario';

  @override
  String momentsMore(Object hidden) {
    return '+$hidden más';
  }

  @override
  String get momentsAllow => 'Permitir';

  @override
  String get momentsCompressed => 'Comprimido';

  @override
  String get momentsPromptDay => 'Tema del día';

  @override
  String get momentsAnswer => 'Responder';

  @override
  String get momentsAnswerCamera => '🎥 Responder con cámara';

  @override
  String momentsPracticeWriting(Object langName) {
    return 'Practica escribiendo en $langName';
  }

  @override
  String get momentsReelPolicyBody => 'Los reels son vídeos cortos para aprender idiomas: respuestas al tema del día, práctica de conversación, explicaciones de hablantes nativos y clips de cultura.\n\nBananatalk tiene tolerancia cero con el contenido inapropiado: nada de desnudos, discurso de odio, acoso, violencia ni contenido ilegal. Los vídeos denunciados se ocultan automáticamente hasta su revisión tras 2 denuncias, y las infracciones pueden suponer la eliminación del contenido o la suspensión de la cuenta.\n\nPuedes denunciar o bloquear desde cualquier reel en cualquier momento.';

  @override
  String get momentsIAgree => 'Acepto';

  @override
  String get momentsWhyReportingReel => '¿Por qué denuncias este reel?';

  @override
  String get momentsNoReelsYet => 'Aún no hay reels';

  @override
  String get momentsNoReelsBody => 'Sé el primero en responder con la cámara al tema de hoy, o graba un clip libre para aprender idiomas.';

  @override
  String get momentsPullDownRefresh => 'Desliza hacia abajo para actualizar';

  @override
  String get momentsErrorLoadingVideo => 'Error al cargar el vídeo';

  @override
  String get momentsLoadingVideo => 'Cargando vídeo...';

  @override
  String momentsFileSizeMb(Object size) {
    return '$size MB';
  }

  @override
  String momentsMaxDuration(Object duration) {
    return 'Máx. $duration';
  }

  @override
  String get momentsReportSubmitted => 'Denuncia enviada';

  @override
  String communityLive(Object count) {
    return '$count en vivo';
  }

  @override
  String get communityFind => 'Buscar';

  @override
  String communityFinding(Object username) {
    return 'Buscando a @$username...';
  }

  @override
  String get communitySeeAll => 'Ver todo';

  @override
  String get communitySeeWhoLikes => 'Descubre a quién le gustas';

  @override
  String get communityUnlimitedBrowsingNoAds => 'Navegación ilimitada, sin anuncios y emparejamiento prioritario';

  @override
  String communityMembersCount(Object count) {
    return '$count miembros';
  }

  @override
  String communityPeopleCount(Object count) {
    return '$count personas';
  }

  @override
  String get communityFailedLoadArchivedWaves => 'No se pudieron cargar los saludos archivados';

  @override
  String get communityGreatChat => '¡Gran charla! 🎉';

  @override
  String get communityStayTouchPeopleJust => 'Mantén el contacto con las personas con las que acabas de hablar';

  @override
  String get communityNotNow => 'Ahora no';

  @override
  String get communityPerfect => 'Perfecto';

  @override
  String communityLv(Object level) {
    return 'Nv.$level';
  }

  @override
  String get communityReact => 'Reaccionar';

  @override
  String get communityWavedAtYou => 'Te saludó';

  @override
  String get communitySomeone => 'Alguien';

  @override
  String get communityPeopleInterestedInTopic => 'Personas interesadas en este tema';

  @override
  String get learnThemedWordSetsBuild => 'Conjuntos de palabras temáticos para ampliar tu vocabulario';

  @override
  String get learnTapStartRecording => 'Toca para empezar a grabar';

  @override
  String get learnWordBank => 'Banco de palabras';

  @override
  String learnCorrectAnswer(Object correctAnswer) {
    return 'Respuesta correcta: $correctAnswer';
  }

  @override
  String get learnMatchingDataNotAvailable => 'Datos de emparejamiento no disponibles';

  @override
  String get learnExerciseCouldNotLoad => 'Este ejercicio no pudo cargar los pares. Intenta regenerar la lección.';

  @override
  String get learnSkipExercise => 'Omitir ejercicio';

  @override
  String get learnTapItemLeftThen => 'Toca un elemento a la izquierda y luego su pareja a la derecha';

  @override
  String learnMatchedOfTotal(Object count, Object count2) {
    return '$count/$count2 emparejados';
  }

  @override
  String learnCorrectOfTotal(Object correctCount, Object count) {
    return '$correctCount/$count correctas';
  }

  @override
  String get learnDragDropReorderItems => 'Arrastra y suelta para reordenar los elementos';

  @override
  String learnCorrectOrder(Object order) {
    return 'Orden correcto: $order';
  }

  @override
  String learnWordsToReview(int dueCount) {
    String _temp0 = intl.Intl.pluralLogic(
      dueCount,
      locale: localeName,
      other: '$dueCount palabras para repasar',
      one: '1 palabra para repasar',
    );
    return '$_temp0';
  }

  @override
  String learnScore(Object score) {
    return 'Puntuación: $score / 100';
  }

  @override
  String learnGotCorrect(Object correct, Object count) {
    return 'Acertaste $correct de $count.';
  }

  @override
  String learnQuestionOf(Object number, Object total) {
    return 'Pregunta $number de $total';
  }

  @override
  String get learnMatchEachWordIts => 'Une cada palabra con su significado';

  @override
  String get learnCouldNotLoadPacks => 'No se pudieron cargar los paquetes';

  @override
  String learnWordsExercises(Object wordCount, Object exerciseCount) {
    return '$wordCount palabras · $exerciseCount ejercicios';
  }

  @override
  String get learnAiAutoFill => 'Autocompletar con IA';

  @override
  String get learnPlay => 'Reproducir';

  @override
  String get learnFinish => 'Finalizar';

  @override
  String get learnNotQuite => 'No exactamente.';

  @override
  String get learnUnsupportedExercise => 'Ejercicio no compatible';

  @override
  String get learnFailedLoadAchievements => 'No se pudieron cargar los logros';

  @override
  String learnUnlockedOn(Object date) {
    return 'Desbloqueado el $date';
  }

  @override
  String get learnChallenges => 'Desafíos';

  @override
  String get learnFailedLoadChallenges => 'No se pudieron cargar los desafíos';

  @override
  String learnNoChallenges(Object type) {
    return 'No hay desafíos $type';
  }

  @override
  String get learnCheckBackLater => '¡Vuelve más tarde!';

  @override
  String learnActiveCount(Object count) {
    return 'Activos ($count)';
  }

  @override
  String learnCompletedCount(Object count) {
    return 'Completados ($count)';
  }

  @override
  String get learnProgress => 'Progreso';

  @override
  String get learnXpReward => 'Recompensa de XP';

  @override
  String get learnBonus => 'Bonificación';

  @override
  String learnExpires(Object timeRemainingFormatted) {
    return 'Caduca en $timeRemainingFormatted';
  }

  @override
  String get learnAchievementUnlocked => '¡Logro desbloqueado!';

  @override
  String get learnTapContinue => 'Toca para continuar';

  @override
  String get learnChallengeCompleted => 'Completado';

  @override
  String get learnDailyGoals => 'Metas diarias';

  @override
  String learnLessons(Object completedCount, Object lessonsCount) {
    return '$completedCount/$lessonsCount lecciones';
  }

  @override
  String learnLongestDays(Object longestStreak) {
    return 'Más larga: $longestStreak días';
  }

  @override
  String get learnTapReveal => 'Toca para revelar';

  @override
  String get learnNoAchievements => 'Sin logros';

  @override
  String get learnDayStreak => 'Días de racha';

  @override
  String get learnDueForReview => 'Pendiente de repaso';

  @override
  String learnNextReview(Object date) {
    return 'Próximo: $date';
  }

  @override
  String get learnChallengeDaily => 'Diarios';

  @override
  String get learnChallengeWeekly => 'Semanales';

  @override
  String get learnChallengeSpecial => 'Especiales';

  @override
  String get learnChallengeDailyDesc => '¡Completa desafíos a diario para ganar XP y recompensas!';

  @override
  String get learnChallengeWeeklyDesc => 'Los desafíos semanales se renuevan cada lunes';

  @override
  String get learnChallengeSpecialDesc => '¡Desafíos por tiempo limitado con recompensas extra!';

  @override
  String get learnDateToday => 'Hoy';

  @override
  String get learnDateTomorrow => 'Mañana';

  @override
  String learnInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En $count días',
      one: 'En $count día',
    );
    return '$_temp0';
  }

  @override
  String learnInWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En $count semanas',
      one: 'En $count semana',
    );
    return '$_temp0';
  }

  @override
  String learnInMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En $count meses',
      one: 'En $count mes',
    );
    return '$_temp0';
  }

  @override
  String get aiGenerateNewQuiz => 'Generar nuevo quiz';

  @override
  String get aiPreviousQuizzes => 'Quizzes anteriores';

  @override
  String get aiGeneratingQuiz => 'Generando tu quiz…';

  @override
  String aiFocusArea(Object name) {
    return 'Área de enfoque: $name';
  }

  @override
  String get aiQuizType => 'Tipo de quiz';

  @override
  String get aiDifficulty => 'Dificultad';

  @override
  String get aiQuestionsLabel => 'Preguntas:';

  @override
  String get aiGenerateQuiz => 'Generar quiz';

  @override
  String aiQuizQuestionCount(int questionCount) {
    String _temp0 = intl.Intl.pluralLogic(
      questionCount,
      locale: localeName,
      other: '$questionCount preguntas',
      one: '1 pregunta',
    );
    return '$_temp0';
  }

  @override
  String aiCorrectOfTotal(Object correctCount, Object totalQuestions) {
    return '$correctCount/$totalQuestions correctas';
  }

  @override
  String get aiNoQuizzesYet => 'Aún no hay quizzes';

  @override
  String get aiGenerateFirstQuizAbove => '¡Genera tu primer quiz arriba!';

  @override
  String aiCorrectOutOf(Object correctCount, Object totalQuestions) {
    return '$correctCount de $totalQuestions correctas';
  }

  @override
  String get aiBackQuizHub => 'Volver al centro de quizzes';

  @override
  String get aiNoQuestionsAvailable => 'No hay preguntas disponibles';

  @override
  String get aiQuizHasNoQuestions => 'Este quiz no tiene preguntas que mostrar.';

  @override
  String aiQuestionOf(Object number, Object count) {
    return 'Pregunta $number de $count';
  }

  @override
  String get aiYourAnswerLabel => 'Tu respuesta:';

  @override
  String get aiBonusXpWatching => '🎉 ¡+10 XP de bonificación por mirar!';

  @override
  String get aiNotQuiteRight => 'No del todo correcto';

  @override
  String get aiWhy => '¿Por qué?';

  @override
  String get aiGotIt => 'Entendido';

  @override
  String get aiHint => 'Pista';

  @override
  String aiLevel(Object hintLevel) {
    return 'Nivel $hintLevel/3';
  }

  @override
  String get aiAskQuestion => 'Hacer una pregunta';

  @override
  String get aiAsk => 'Preguntar';

  @override
  String get aiAssistantExamples => 'Ejemplos';

  @override
  String get aiExplainConcept => 'Explicar concepto';

  @override
  String get aiRelatedConcepts => 'Conceptos relacionados';

  @override
  String get aiGeneratingLessonSummary => 'Generando el resumen de tu lección...';

  @override
  String get aiLessonSummary => 'Resumen de la lección';

  @override
  String get aiKeyPoints => 'Puntos clave';

  @override
  String get aiVocabularyRemember => 'Vocabulario para recordar';

  @override
  String get aiGrammarRules => 'Reglas gramaticales';

  @override
  String get aiWhatPracticeNext => 'Qué practicar a continuación';

  @override
  String get aiPerfectScore => '¡Puntuación perfecta!';

  @override
  String get aiGreatJob => '¡Buen trabajo!';

  @override
  String get aiGoodEffort => '¡Buen esfuerzo!';

  @override
  String get aiKeepPracticing => '¡Sigue practicando!';

  @override
  String get aiFailedToGetHint => 'No se pudo obtener la pista';

  @override
  String get aiFailedToGetAnswer => 'No se pudo obtener la respuesta';

  @override
  String get aiFailedToExplain => 'No se pudo explicar';

  @override
  String get aiFailedLoadHistory => 'No se pudo cargar el historial';

  @override
  String aiConversationMessageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes',
      one: '1 mensaje',
    );
    return '$_temp0';
  }

  @override
  String get aiStartNewConversationSee => 'Inicia una nueva conversación para verla aquí';

  @override
  String get aiLoadingMessages => 'Cargando mensajes...';

  @override
  String get aiNoMessagesConversation => 'No hay mensajes en esta conversación';

  @override
  String get aiDifficultyLevel => 'Nivel de dificultad';

  @override
  String get aiScenarios => 'Escenarios';

  @override
  String get aiGrammarCheck => 'Revisión gramatical';

  @override
  String get aiRecentAnalysis => 'Análisis recientes';

  @override
  String get aiCheckGrammar => 'Revisar gramática';

  @override
  String get aiLanguageLabel => 'Idioma:';

  @override
  String aiGrammarIssuesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errores encontrados',
      one: '1 error encontrado',
    );
    return '$_temp0';
  }

  @override
  String get aiPerfect => '¡Perfecto!';

  @override
  String get aiNoGrammarIssuesFound => 'No se encontraron errores gramaticales en tu texto.';

  @override
  String aiIssuesFound(Object count) {
    return 'Errores encontrados ($count)';
  }

  @override
  String get aiCorrected => 'Corregido';

  @override
  String get aiGrammarExamples => 'Ejemplos:';

  @override
  String get aiImprovedSuggestions => 'Sugerencias mejoradas';

  @override
  String get aiNoAnalysisHistoryYet => 'Aún no hay historial de análisis';

  @override
  String get aiLessonBuilder => 'Creador de lecciones con IA';

  @override
  String get aiGenerateCustomLessons => 'Genera lecciones personalizadas';

  @override
  String get aiCreatesPersonalizedLessonsAny => 'La IA crea lecciones personalizadas sobre cualquier tema';

  @override
  String aiExercises(Object exerciseCount) {
    return 'Ejercicios: $exerciseCount';
  }

  @override
  String get aiSuggestedTopics => 'Temas sugeridos';

  @override
  String get aiCreatingLesson => 'Creando tu lección...';

  @override
  String get aiGeneratingExercisesContent => 'La IA está generando ejercicios y contenido';

  @override
  String get aiLessonGenerated => '¡Lección generada!';

  @override
  String get aiGenerateAnother => 'Generar otra';

  @override
  String get aiStartLesson => 'Empezar lección';

  @override
  String get aiPronunciationPractice => 'Práctica de pronunciación';

  @override
  String get aiPracticeHistory => 'Historial de práctica';

  @override
  String get aiTextPractice => 'Texto para practicar';

  @override
  String get aiWordAnalysis => 'Análisis de palabras';

  @override
  String get aiNoPracticeHistoryYet => 'Aún no hay historial de práctica';

  @override
  String get aiSmartTranslation => 'Traducción inteligente';

  @override
  String get aiWordBreakdown => 'Desglose de palabras';

  @override
  String get aiAlternativeTranslations => 'Traducciones alternativas';

  @override
  String get aiGrammarNotes => 'Notas gramaticales';

  @override
  String get aiIdiomsExpressions => 'Modismos y expresiones';

  @override
  String aiLiteral(Object literalTranslation) {
    return 'Literal: $literalTranslation';
  }

  @override
  String aiMeaning(Object meaning) {
    return 'Significado: $meaning';
  }

  @override
  String aiEquivalent(Object equivalentIdiom) {
    return 'Equivalente: $equivalentIdiom';
  }

  @override
  String get aiCulturalContext => 'Contexto cultural';

  @override
  String get aiNoCompletedConversations => 'No hay conversaciones completadas';

  @override
  String get aiNoActiveConversations => 'No hay conversaciones activas';

  @override
  String aiStartInLanguage(Object language) {
    return 'Empezar en $language';
  }

  @override
  String get aiSelect => 'Seleccionar';

  @override
  String aiIssuesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errores',
      one: '1 error',
    );
    return '$_temp0';
  }

  @override
  String get aiGenerateLesson => 'Generar lección';

  @override
  String get aiGeneratingEllipsis => 'Generando...';

  @override
  String get aiAnalyzing => 'Analizando...';

  @override
  String get aiExcellentPronunciation => '¡Excelente pronunciación!';

  @override
  String get aiGoodJob => '¡Buen trabajo!';

  @override
  String get profileBuyMeCoffee => 'Invítame a un café';

  @override
  String get profileOr => 'o';

  @override
  String get profileLoadingNotifications => 'Cargando notificaciones...';

  @override
  String get profileLoadingSettings => 'Cargando ajustes...';

  @override
  String get profileAdmin => 'ADMIN';

  @override
  String get profileSelected => 'SELECCIONADO';

  @override
  String get profilePrivacyIntro => 'Tú controlas lo que otros pueden ver. Desactiva elementos para ocultarlos de tu perfil público.';

  @override
  String get profileUpdate => 'Actualizar';

  @override
  String get profileNoTopicsCategory => 'No hay temas en esta categoría';

  @override
  String get profileAdminTools => 'Herramientas de administración';

  @override
  String profileCompletionAdd(Object items) {
    return 'Añadir: $items';
  }

  @override
  String get profileActive => 'ACTIVO';

  @override
  String get profileAutoSaveEnabled => 'Guardado automático activado';

  @override
  String get profileChangesSavedInstantlyWhen => 'Los cambios se guardan al instante cuando los activas o desactivas.';

  @override
  String get profileCurrentTheme => 'Tema actual';

  @override
  String get profileThemeChangesApplyInstantly => 'Los cambios de tema se aplican al instante en toda la app.';

  @override
  String get profileLoadingVisitors => 'Cargando visitantes...';

  @override
  String get profileSeeWhoChecked => 'Mira quién ha visto tu perfil';

  @override
  String get profileRecentVisitors => 'Visitantes recientes';

  @override
  String get profileNoReportsSubmitted => 'No has enviado ningún reporte';

  @override
  String get profileReportsSubmitWillAppear => 'Los reportes que envíes aparecerán aquí';

  @override
  String profileReportTypeTitle(Object type) {
    return 'Reporte de $type';
  }

  @override
  String profileReportReason(Object reason) {
    return 'Motivo: $reason';
  }

  @override
  String get profileDeleteAccountFinalBody => 'Todos tus datos se eliminarán de forma permanente.\n\n¿Estás completamente seguro?';

  @override
  String get profileThanksForWatching => '¡Gracias por ver! 🙏';

  @override
  String get profileNotificationsOn => 'Notificaciones activadas';

  @override
  String get profileNotificationsOff => 'Notificaciones desactivadas';

  @override
  String get profileMaximumReached => 'Máximo alcanzado';

  @override
  String get profilePickYourInterests => 'Elige tus intereses';

  @override
  String get profileDeselectToChooseAnother => 'Deselecciona uno para elegir otro';

  @override
  String get profileTapTopicsMatchVibe => 'Toca los temas que van contigo';

  @override
  String get profileEnjoyingPremium => 'Disfrutando de las funciones premium';

  @override
  String get profileUnlockUnlimited => 'Desbloquea mensajes ilimitados y herramientas de IA';

  @override
  String get profileBirthYear => 'Año de nacimiento';

  @override
  String get profileReportTypeUser => 'Usuario';

  @override
  String get profileReportTypeMoment => 'Momento';

  @override
  String get profileReportTypeComment => 'Comentario';

  @override
  String get profileReportTypeMessage => 'Mensaje';

  @override
  String get profileReportTypeStory => 'Historia';

  @override
  String get profileReportReasonCopyright => 'Derechos de autor';

  @override
  String get storyOptimizingBestExperience => 'Optimizando para la mejor experiencia';

  @override
  String get storyCreate => 'Crear una historia';

  @override
  String get storyAddTags => 'Añadir etiquetas';

  @override
  String get storyVideoSelected => 'Vídeo seleccionado';

  @override
  String get storyAddPoll => 'Añadir encuesta';

  @override
  String get storyOptions => 'Opciones';

  @override
  String get storyAddQuestion => 'Añadir pregunta';

  @override
  String get storyPrompt => 'Pregunta guía';

  @override
  String get storyTapAnywhereAddText => 'Toca en cualquier lugar para añadir texto';

  @override
  String storyHighlightStoryCount(int storyCount) {
    String _temp0 = intl.Intl.pluralLogic(
      storyCount,
      locale: localeName,
      other: '$storyCount historias',
      one: '1 historia',
    );
    return '$_temp0';
  }

  @override
  String get storySendFriends => 'Enviar a amigos';

  @override
  String storySelected(Object count) {
    return '$count seleccionados';
  }

  @override
  String get storyShareSave => 'Compartir/Guardar';

  @override
  String storySeenBy(Object viewCount) {
    return 'Visto por $viewCount';
  }

  @override
  String get storyNoViewsYet => 'Aún no hay visualizaciones';

  @override
  String get storyEditVideo => 'Editar vídeo';

  @override
  String storyVotes(Object totalVotes) {
    return '$totalVotes votos';
  }

  @override
  String get storyCreatePoll => 'Crear encuesta';

  @override
  String get storySendAnonymously => 'Enviar de forma anónima';

  @override
  String storyResponseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respuestas',
      one: '1 respuesta',
    );
    return '$_temp0';
  }

  @override
  String get storyViewResponses => 'Ver respuestas';

  @override
  String get storyResponsesTitle => 'Respuestas';

  @override
  String get storyNoResponsesYet => 'Aún no hay respuestas';

  @override
  String get storyQuestionBox => 'Caja de preguntas';

  @override
  String get storySent => '¡Enviado!';

  @override
  String get storyProcessing => 'Procesando...';

  @override
  String get storyHd => 'HD';

  @override
  String storyVideoMeta(Object duration, Object size) {
    return '$duration | $size MB';
  }

  @override
  String get storyUserFallback => 'Usuario';

  @override
  String storySendCount(int count) {
    return 'Enviar ($count)';
  }

  @override
  String get storyFailedToDelete => 'No se pudo eliminar la historia';

  @override
  String get storyAnonymous => 'Anónimo';

  @override
  String get vipNoCoinActivityYet => 'Aún no hay actividad de monedas';

  @override
  String get vipCoinShopExplainer => 'Las monedas se usan para desbloquear usos adicionales de traducciones, chats con el tutor de IA y momentos cuando alcanzas tu límite diario gratuito. Las compras no son reembolsables una vez gastadas las monedas.';

  @override
  String get vipLimitReached => 'Límite alcanzado';

  @override
  String get vipCoins => 'monedas';

  @override
  String vipBonusIncluded(Object bonusCoins) {
    return '+$bonusCoins de bonificación incluidas';
  }

  @override
  String get vipVisitorModeLimitReached => 'Límite del modo visitante alcanzado';

  @override
  String get vipWhatGetFreeAccount => 'Lo que obtienes con una cuenta gratuita';

  @override
  String get vipCreateFreeAccount => 'Crear cuenta gratuita';

  @override
  String get vipGoUnlimitedAccess => 'Hazte VIP para acceso ilimitado';

  @override
  String get vipContinueAsVisitor => 'Continuar como visitante';

  @override
  String vipResets(Object resetTime) {
    return 'Se restablece a las: $resetTime';
  }

  @override
  String vipUsedToday(Object currentUsage, Object maxAllowed) {
    return '$currentUsage / $maxAllowed usados hoy';
  }

  @override
  String get vipTierVisitor => 'Visitante';

  @override
  String get vipTierMember => 'Miembro';

  @override
  String get vipAd => 'Anuncio';

  @override
  String get promoAdsNoticeTitle => 'Una nota del desarrollador';

  @override
  String get promoAdsNoticeBody => '¡Hola! Soy Firdavs, el desarrollador independiente detrás de Bananatalk. He añadido algunos anuncios pequeños a la app para ayudar a mantenerla gratis y financiar su desarrollo continuo.\n\nSé que los anuncios pueden ser molestos, así que los he hecho opcionales y con recompensa. Mira un anuncio para desbloquear mensajes extra, filtros de la comunidad, XP de bonificación tras los cuestionarios y más.\n\nGracias por usar Bananatalk. Tu apoyo lo significa todo. 🙏';

  @override
  String get promoAdsNoticeGotIt => '¡Entendido, gracias! 👍';

  @override
  String get vipOnly => 'Solo VIP';

  @override
  String get vipTapUpgrade => 'Toca para mejorar';

  @override
  String get vipUnlockFeatures => 'Desbloquea las funciones VIP';

  @override
  String get vipUpPillUp => 'Subir';

  @override
  String get vipChooseOption => 'Elige una opción:';

  @override
  String get promoWelcomeBackTitle => '¡Bienvenido de nuevo! 👋';

  @override
  String get promoWelcomeBackBody => 'Te echamos de menos. Esto es lo que te espera:';

  @override
  String get promoWelcomeBackCta => '¡Vamos! 🚀';

  @override
  String get vipCoinsPerAdInfo => '+5 monedas por anuncio, hasta 5 al día';

  @override
  String get vipUpgradeUnlockMore => 'Mejora para desbloquear más funciones y acceso ilimitado';

  @override
  String get vipUpgradeNow => 'Mejorar ahora';

  @override
  String get commonContinueWhereLeftOff => '¿Continuar donde lo dejaste?';

  @override
  String get commonLanguageNotProvided => 'Idioma no indicado';

  @override
  String get commonExamNotProvided => 'Examen no indicado';

  @override
  String get commonMuted => 'Silenciado';

  @override
  String get commonPoorConnection => 'Conexión deficiente';

  @override
  String commonBlockUserConfirmBody(Object targetUserName) {
    return '¿Seguro que quieres bloquear a $targetUserName?\n\nYa no verás sus mensajes ni publicaciones, y no aparecerán en las búsquedas del otro.';
  }

  @override
  String get commonVideoFile => 'Archivo de video';

  @override
  String get commonPointCameraBananatalkQr => 'Apunta tu cámara a un código QR de Bananatalk';

  @override
  String get commonReportSubmittedButSome => 'Denuncia enviada, pero algunas pruebas no se pudieron subir';

  @override
  String commonReportTitle(Object typeLabel) {
    return 'Denunciar $typeLabel';
  }

  @override
  String commonWhyReporting(Object typeLabel) {
    return '¿Por qué denuncias este $typeLabel?';
  }

  @override
  String get commonAddEvidenceRequired => 'Añadir pruebas (obligatorio)';

  @override
  String get commonUploadScreenshotsTextFiles => 'Sube capturas de pantalla o archivos de texto para respaldar tu denuncia';

  @override
  String commonAddEvidenceCount(Object count, Object maxFiles) {
    return 'Añadir pruebas ($count/$maxFiles)';
  }

  @override
  String commonReportTotalSize(Object max, Object used) {
    return 'Total: $used / $max';
  }

  @override
  String get commonEvidence => 'Pruebas';

  @override
  String get commonImageFailed => 'Error en la imagen';

  @override
  String get commonShowMore => 'Ver más';

  @override
  String get commonVoiceRecordingNotAvailable => 'Grabación de voz no disponible';

  @override
  String get commonVoiceRecordingOnlyAvailable => 'La grabación de voz solo está disponible en dispositivos móviles.';

  @override
  String get commonReportSubmittedSuccessfully => 'Denuncia enviada correctamente';

  @override
  String get commonErrorLoadingFile => 'Error al cargar el archivo';

  @override
  String get commonReportTypeUser => 'usuario';

  @override
  String get commonReportTypeMoment => 'momento';

  @override
  String get commonReportTypeComment => 'comentario';

  @override
  String get commonReportTypeMessage => 'mensaje';

  @override
  String get commonReportTypeStory => 'historia';

  @override
  String get commonReportTypeContent => 'contenido';

  @override
  String get commonReportReasonCopyright => 'Infracción de derechos de autor';

  @override
  String get momentsRemoveVoiceNote => 'Quitar nota de voz';

  @override
  String get vocabPackLevelProficiency => 'Dominio';

  @override
  String get aiFailedToLoadFeedback => 'No se pudo cargar la retroalimentación';

  @override
  String get aiFailedToLoadSummary => 'No se pudo cargar el resumen';

  @override
  String get momentFailedToLoad => 'No se pudo cargar el momento';

  @override
  String get aiPronunciationWatchAdRetry => 'Mira un anuncio para otro intento gratis';

  @override
  String aiErrorLoadingLanguages(Object error) {
    return 'Error al cargar los idiomas: $error';
  }

  @override
  String get aiSelectSourceTargetLanguages => 'Selecciona el idioma de origen y el de destino';

  @override
  String get aiUnexpectedResponseFormat => 'Formato de respuesta inesperado';

  @override
  String get aiFailedToLoadConversation => 'No se pudo cargar la conversación';

  @override
  String get aiMicPermissionDeniedSettings => 'Permiso de micrófono denegado. Actívalo en Ajustes.';

  @override
  String get aiFailedToEvaluatePronunciation => 'No se pudo evaluar la pronunciación';

  @override
  String get aiFailedToGenerateSpeech => 'No se pudo generar el audio';

  @override
  String get aiFailedToGenerateLesson => 'No se pudo generar la lección';

  @override
  String get aiLessonTopicRequired => 'Introduce un tema';

  @override
  String get aiFailedToLoadTopics => 'No se pudieron cargar los temas';

  @override
  String get aiFailedToLoadScenarios => 'No se pudieron cargar los escenarios';

  @override
  String get aiAnalysisFailed => 'Error en el análisis';

  @override
  String get storySearchPlaceHint => 'Buscar un lugar…';

  @override
  String get storySearchRecentChatsHint => 'Buscar chats recientes…';

  @override
  String get storySearchFollowingHint => 'Buscar personas que sigues…';

  @override
  String get storyAddHashtagsHint => 'Añade hashtags...';

  @override
  String get storyHighlightCreateFailed => 'No se pudo crear el destacado';

  @override
  String get storyHighlightRenameFailed => 'No se pudo renombrar el destacado';

  @override
  String get storyHighlightDeleteFailed => 'No se pudo eliminar el destacado';

  @override
  String get storyViewersLoadFailed => 'No se pudieron cargar los espectadores';

  @override
  String get storyShareSent => 'Enviado 💛';

  @override
  String storyShareSentPartial(Object names) {
    return 'Enviado 💛 — falló para $names';
  }

  @override
  String get storyVoteFailed => 'No se pudo enviar el voto';

  @override
  String get storyAnswerFailed => 'No se pudo enviar la respuesta';

  @override
  String get storyAlreadyInHighlight => 'Ya está guardada en un destacado';

  @override
  String get storyAddedToHighlight => 'Añadido al destacado';

  @override
  String storyMaxHashtags(int max) {
    return 'Puedes añadir hasta $max hashtags';
  }

  @override
  String storyMaxMentions(int max) {
    return 'Puedes mencionar hasta a $max personas';
  }

  @override
  String get coinHistoryActivity => 'Actividad de monedas';

  @override
  String get coinHistoryAdReward => 'Viste un anuncio';

  @override
  String get coinHistoryPurchase => 'Compra de monedas';

  @override
  String coinHistoryUnlocked(Object feature) {
    return 'Desbloqueaste $feature';
  }

  @override
  String get vipVisitorMessagesBenefit => 'Envía hasta 50 mensajes al día';

  @override
  String get vipVisitorProfilesBenefit => 'Consulta hasta 100 perfiles al día';

  @override
  String get vipVisitorFriendsBenefit => 'Añade amigos y amplía tu red';

  @override
  String get vipVisitorCommunitiesTitle => 'Únete a comunidades';

  @override
  String get vipVisitorCommunitiesBenefit => 'Participa en las conversaciones de la comunidad';

  @override
  String get vipVisitorMomentsTitle => 'Comparte momentos';

  @override
  String get vipVisitorMomentsBenefit => 'Publica y comparte tus momentos';

  @override
  String get vipUnlimitedEverythingTitle => 'Todo ilimitado';

  @override
  String get vipUnlimitedEverythingBenefit => 'Sin límites diarios de mensajes ni de vistas de perfil';

  @override
  String get vipProfileBoostBenefit => 'Consigue más visibilidad en los resultados de búsqueda';

  @override
  String get vipAdFreeExperienceBenefit => 'Disfruta de la app sin anuncios';

  @override
  String get featureGateUpgradeToUnlock => 'Mejora tu plan para desbloquear esta función';

  @override
  String get featureGateVipOnly => 'Función solo para VIP';

  @override
  String get adsRewardedButtonLabel => 'Mira un anuncio para obtener un bonus';

  @override
  String get promoAdsPerkMessages => '+3 mensajes\nextra';

  @override
  String get promoAdsPerkFilters => 'Desbloquea\nfiltros';

  @override
  String get promoAdsPerkXp => '+10 XP\nextra';

  @override
  String get promoAdsPerkRetry => 'Reintento\ngratis';

  @override
  String get visitorLimitMessagesTitle => 'Límite diario de mensajes alcanzado';

  @override
  String visitorLimitMessagesBody(int count) {
    return 'Hoy has enviado $count mensajes. ¡Mejora tu plan para enviar más!';
  }

  @override
  String get visitorLimitProfilesTitle => 'Límite diario de vistas de perfil alcanzado';

  @override
  String visitorLimitProfilesBody(int count) {
    return 'Hoy has visto $count perfiles. ¡Mejora tu plan para ver más!';
  }

  @override
  String get visitorLimitFreeAccountBenefit => 'Límites diarios más altos';

  @override
  String get visitorLimitVipBenefit => 'Acceso ilimitado';

  @override
  String get promoWelcomeBackTutorSubtitle => 'Practica conversaciones, pronunciación y cuestionarios';

  @override
  String get promoWelcomeBackCommunitySubtitle => 'Encuentra compañeros de idiomas cerca de ti';

  @override
  String get promoWelcomeBackMomentsSubtitle => 'Comparte tu viaje de aprendizaje de idiomas';

  @override
  String get myReportsReportedId => 'ID reportado';

  @override
  String get myReportsReason => 'Motivo';

  @override
  String get myReportsSubmitted => 'Enviado';

  @override
  String get myReportsResolved => 'Resuelto';

  @override
  String get myReportsModeratorNotes => 'Notas del moderador';

  @override
  String get myReportsNotAvailable => 'N/D';

  @override
  String get myReportsFailedToLoad => 'No se pudieron cargar los reportes';

  @override
  String get voiceRecorderUnavailableDesktop => 'La grabación de voz no está disponible en escritorio';

  @override
  String get adminPageUnavailable => 'Esta página no está disponible.';

  @override
  String storyShareSendFailedTo(Object names) {
    return 'No se pudo enviar a $names';
  }

  @override
  String get storyCantReact => 'No puedes reaccionar a esta historia';

  @override
  String get storyCantReply => 'No puedes responder a esta historia';

  @override
  String get storyNoMediaToSave => 'Esta historia no tiene contenido para guardar';

  @override
  String get coinsAdCrediting => 'Acreditando…';

  @override
  String get coinsWatchAdReward => 'Mira un anuncio (+5 💎)';

  @override
  String callUnavailable(String name) {
    return '$name no está aceptando llamadas ahora mismo';
  }

  @override
  String get callDeclineWithMessage => 'Mensaje';

  @override
  String get callDeclineSheetTitle => 'Rechazar con un mensaje';

  @override
  String get callDeclineCannedLater => 'No puedo hablar ahora. Te devuelvo la llamada.';

  @override
  String get callDeclineCannedText => 'No puedo hablar ahora. ¿Me escribes?';

  @override
  String get callDeclineCustomHint => 'Escribe un mensaje…';

  @override
  String get callDeclineSend => 'Enviar';

  @override
  String get callBackAction => 'Devolver llamada';

  @override
  String get callMessageAction => 'Mensaje';

  @override
  String get callsAllowTitle => 'Permitir llamadas';

  @override
  String get callsAllowSubtitle => 'Si está desactivado, las llamadas no te sonarán. Quien llame verá que no aceptas llamadas.';

  @override
  String get callsQuietHoursNote => 'Con «Permitir notificaciones urgentes» desactivado, las llamadas también se retienen durante las horas de silencio.';

  @override
  String get callTurnOnCamera => 'Cámara';

  @override
  String get callCameraFailed => 'No se pudo encender la cámara';

  @override
  String get callSelfViewLabel => 'Tu cámara. Arrastra para moverla.';

  @override
  String get callSelfViewSwapHint => 'Toca dos veces para cambiar con el otro vídeo';

  @override
  String get studyGroupTalk => 'Conversa';

  @override
  String get studyGroupPractice => 'Practica';

  @override
  String get studyGroupPrepare => 'Prepárate y compite';

  @override
  String get studyTileTutor => 'Tutor IA';

  @override
  String get studyTileTutorDesc => 'Charla sobre lo que quieras';

  @override
  String get studyTileRoleplay => 'Juego de roles';

  @override
  String get studyTileRoleplayDesc => 'Escenas de la vida real';

  @override
  String get studyTileStory => 'Historia';

  @override
  String get studyTileStoryDesc => 'Escribe una historia juntos';

  @override
  String get studyTilePhoto => 'Foto';

  @override
  String get studyTilePhotoDesc => 'Aprende palabras con una foto';

  @override
  String get studyTileSpeak => 'Habla';

  @override
  String get studyTileSpeakDesc => 'Revisa tu pronunciación';

  @override
  String get studyTileReview => 'Repaso';

  @override
  String get studyTileReviewDesc => 'Palabras de hoy';

  @override
  String get studyTileWriting => 'Escritura';

  @override
  String get studyTileWritingDesc => 'Feedback de gramática';

  @override
  String get studyTileQuizzes => 'Cuestionarios';

  @override
  String get studyTileQuizzesDesc => 'Quizzes rápidos con IA';

  @override
  String get studyTileExam => 'Preparar exámenes';

  @override
  String get studyTileExamDesc => 'TOPIK, JLPT, IELTS…';

  @override
  String get studyTileLessons => 'Lecciones';

  @override
  String get studyTileLessonsDesc => 'Unidades paso a paso';

  @override
  String get studyTileChallenges => 'Retos';

  @override
  String get studyTileChallengesDesc => 'Metas diarias para ganar XP';

  @override
  String get studyTileLeaderboard => 'Clasificación';

  @override
  String get studyTileLeaderboardDesc => 'Mira el ranking de la semana';

  @override
  String get studyBadgeVip => 'VIP';

  @override
  String studyBadgeLeft(int count) {
    return 'Quedan $count';
  }

  @override
  String studyBadgeDue(int count) {
    return '$count pendientes';
  }

  @override
  String get studyBadgeNew => 'NUEVO';

  @override
  String get studyEnglishOnly => 'Solo en inglés por ahora';

  @override
  String get studyTodayPack => 'Pack de hoy';

  @override
  String get studyTodayStart => 'Empezar';

  @override
  String studyRecommended(String name, int percent) {
    return 'Para ti: $name — $percent % de aciertos · quiz de 5 min';
  }

  @override
  String get studyProgressTitle => 'Tu progreso';

  @override
  String get studyFullReport => 'Informe completo';

  @override
  String studyStreakDays(int count) {
    return 'Racha de $count días';
  }

  @override
  String studyLevelShort(int level) {
    return 'Nv $level';
  }

  @override
  String studyUpgradeLockedTitle(String feature) {
    return '$feature es una función VIP';
  }

  @override
  String studyUpgradeExhaustedTitle(String feature) {
    return 'Ya usaste $feature de hoy';
  }

  @override
  String get studyUpgradeBenefitUnlimited => 'Práctica con IA ilimitada cada día';

  @override
  String get studyUpgradeBenefitNoAds => 'Sin anuncios en toda la app';

  @override
  String get studyUpgradeGetVip => 'Hazte VIP — sin límites';

  @override
  String get guideStudyHubTitle => 'Tu gimnasio diario de idiomas';

  @override
  String get guideStudyHubBody => 'Un pack de 5 minutos al día y un tutor IA cuando quieras hablar.';

  @override
  String get guideStudyHubCta => 'Empezar el pack de hoy';

  @override
  String get guideStudyHubSecondary => 'Ver todas las funciones';

  @override
  String get supportBananaTalkRow => 'Apoya a BananaTalk';

  @override
  String get supportBananaTalkRowSubtitle => 'Ayuda a un desarrollador independiente a seguir creando';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get restorePurchasesInProgress => 'Restaurando compras…';

  @override
  String get restorePurchasesSuccess => 'Compras restauradas. Tu VIP está activo.';

  @override
  String get restorePurchasesAlreadyActive => 'Tu suscripción VIP ya está activa.';

  @override
  String get restorePurchasesNothing => 'No hay compras para restaurar.';

  @override
  String get restorePurchasesFailed => 'No se pudieron restaurar las compras. Inténtalo de nuevo.';

  @override
  String get callVoiceCallButton => 'Llamada de voz';

  @override
  String get callVideoCallButton => 'Videollamada';

  @override
  String get callPermissionMicSettings => 'Activa el acceso al micrófono en Ajustes para las llamadas.';

  @override
  String get callPermissionCameraSettings => 'Activa el acceso a la cámara en Ajustes para las videollamadas.';

  @override
  String get callPermissionMicCameraSettings => 'Activa el acceso al micrófono y a la cámara en Ajustes para las videollamadas.';

  @override
  String get callQualityExcellent => 'Calidad excelente';

  @override
  String get callQualityGood => 'Buena calidad';

  @override
  String get callConnectionLost => 'Conexión perdida';

  @override
  String get biometricLoginSetting => 'Iniciar sesión con Face ID / huella';

  @override
  String get biometricLoginSettingDesc => 'Mostrar \"Continuar como\" en la pantalla de inicio de sesión después de cerrar sesión';

  @override
  String get personaUpgradeNana => '¿Quieres seguir charlando con Nana? 🐻\nMejora para uso ilimitado.';

  @override
  String get personaUpgradeSensei => 'Continúa tu entrenamiento con Sensei. 🤖\nMejora para practicar sin límites.';

  @override
  String get personaUpgradeRiko => '¡Riko apenas está calentando! 🐙\nMejora y sigamos.';

  @override
  String get personaUpgradeGeneric => '¿Quieres continuar?\nMejora para estudiar con IA sin límites.';

  @override
  String get chatListConversationPinned => 'Conversación fijada';

  @override
  String get chatListConversationUnpinned => 'Conversación desfijada';

  @override
  String get chatListConversationDeleted => 'Conversación eliminada';

  @override
  String get chatListConversationActionFailed => 'No se pudo actualizar esta conversación. Inténtalo de nuevo.';

  @override
  String get coinsPurchaseLinkedElsewhere => 'Esta compra ya está vinculada a otra cuenta de BananaTalk, así que no se añadieron monedas aquí.';

  @override
  String get coinsAlreadyCredited => 'Estas monedas ya se añadieron a tu cuenta.';

  @override
  String get pleaseRemoveImagesFirstToAddVoiceNote => 'Elimina primero las imágenes para añadir una nota de voz';

  @override
  String get authLockedTitle => 'Cuenta bloqueada temporalmente';

  @override
  String authLockedBodyMinutes(Object minutes) {
    return 'Demasiados intentos fallidos. Inténtalo de nuevo en $minutes min.';
  }

  @override
  String get authLockedBodyLater => 'Demasiados intentos fallidos. Inténtalo de nuevo más tarde.';

  @override
  String get authRateLimitedTitle => 'Espera un momento';

  @override
  String authRateLimitedBodySeconds(Object seconds) {
    return 'Demasiados intentos. Inténtalo de nuevo en $seconds s.';
  }

  @override
  String get authRateLimitedBodyShortly => 'Demasiados intentos. Inténtalo de nuevo en breve.';

  @override
  String get passwordErrorLength => 'La contraseña debe tener al menos 8 caracteres';

  @override
  String get passwordErrorUppercase => 'La contraseña debe contener al menos una letra mayúscula';

  @override
  String get passwordErrorLowercase => 'La contraseña debe contener al menos una letra minúscula';

  @override
  String get passwordErrorNumber => 'La contraseña debe contener al menos un número';

  @override
  String get authCodeExpired => 'Este código ha caducado. Solicita uno nuevo.';

  @override
  String get authCodeIncorrect => 'Código incorrecto. Inténtalo de nuevo.';

  @override
  String get authVerificationFailed => 'Error de verificación';

  @override
  String get authResendCodeFailed => 'No se pudo reenviar el código';

  @override
  String get authSendResetCodeFailed => 'No se pudo enviar el código de restablecimiento';

  @override
  String get authResetPasswordFailed => 'No se pudo restablecer la contraseña';

  @override
  String get enableBiometricTitleAndroid => '¿Usar huella o desbloqueo facial para iniciar sesión la próxima vez?';

  @override
  String chatLastSeenDate(Object date) {
    return 'Última vez $date';
  }

  @override
  String get chatLastSeenRecently => 'Visto recientemente';

  @override
  String chatMediaTabMedia(Object count) {
    return 'Multimedia ($count)';
  }

  @override
  String chatMediaTabLinks(Object count) {
    return 'Enlaces ($count)';
  }

  @override
  String chatMediaTabDocs(Object count) {
    return 'Documentos ($count)';
  }

  @override
  String get chatMediaNoMedia => 'Aún no se han compartido fotos ni videos';

  @override
  String get chatMediaNoLinks => 'Aún no se han compartido enlaces';

  @override
  String get chatMediaNoDocs => 'Aún no se han compartido documentos';

  @override
  String get chatMediaUnknownSize => 'Tamaño desconocido';

  @override
  String chatDeleteMinutesLeft(Object minutes) {
    return 'quedan $minutes min';
  }

  @override
  String chatDeleteRemovesForBoth(Object name) {
    return 'Se elimina para ti y para $name';
  }

  @override
  String get chatUnsupportedMessageType => 'Tipo de mensaje no compatible';

  @override
  String get chatStoryUnavailable => 'Esta historia ya no está disponible';

  @override
  String get chatWallpapersUnlocked => '¡Fondos premium desbloqueados!';

  @override
  String get chatEditFailed => 'No se pudo editar el mensaje';

  @override
  String get chatPinFailed => 'No se pudo actualizar el fijado';

  @override
  String get chatMessagePinned => 'Mensaje fijado';

  @override
  String get chatMessageUnpinned => 'Mensaje desfijado';

  @override
  String get chatForwardFailed => 'No se pudo reenviar el mensaje';

  @override
  String get chatShareLocationFailed => 'No se pudo compartir la ubicación';

  @override
  String chatFileTooLarge(Object size) {
    return 'Este archivo es demasiado grande. El límite es de $size MB.';
  }

  @override
  String get chatSendMediaFailed => 'No se pudo enviar el archivo';

  @override
  String get chatSendVideoFailed => 'No se pudo enviar el video';

  @override
  String get chatVideoTooLong => 'El video debe durar menos de 10 minutos';

  @override
  String get chatVideoTooLarge => 'El video debe pesar menos de 1 GB. Comprímelo, por favor.';

  @override
  String get chatSendVoiceFailed => 'No se pudo enviar el mensaje de voz';

  @override
  String get chatVoiceTooLong => 'El mensaje de voz debe durar menos de 5 minutos';

  @override
  String get chatVoiceTooLarge => 'El archivo del mensaje de voz es demasiado grande';

  @override
  String get voiceRecorderInitFailed => 'No se pudo iniciar la grabadora';

  @override
  String get voiceRecorderStartFailed => 'No se pudo empezar a grabar';

  @override
  String get voiceRecorderFileMissing => 'No se encontró el archivo de la grabación';

  @override
  String get voiceRecorderTooShort => 'Grabación demasiado corta (mínimo 1 segundo)';

  @override
  String get voiceRecorderResume => 'Reanudar';

  @override
  String get voiceRecorderPause => 'Pausar';

  @override
  String get voiceRecorderPaused => 'Grabación en pausa: toca reproducir para continuar';

  @override
  String get voiceRecorderRecording => 'Grabando... toca pausa o enviar cuando termines';

  @override
  String get voiceRecorderInitializing => 'Iniciando...';

  @override
  String get chatGifSearchFailed => 'La búsqueda falló. Inténtalo de nuevo.';

  @override
  String chatGifResultsFor(Object query) {
    return 'Resultados para «$query»';
  }

  @override
  String get chatYouSharedStory => 'Compartiste una historia';

  @override
  String chatUserSharedStory(Object name) {
    return '$name compartió una historia';
  }

  @override
  String chatUserNotInChats(Object name) {
    return '@$name no está en tus chats';
  }

  @override
  String get chatDeleteMessageFailed => 'No se pudo eliminar el mensaje';

  @override
  String get themeAutomatic => 'Automático';

  @override
  String get themeManual => 'Manual';

  @override
  String get themeFollowingSystem => 'Según el sistema';

  @override
  String get profileAdminToolsSubtitle => 'Reportes, usuarios, registro de auditoría';

  @override
  String appVersionLabel(Object version) {
    return 'Versión $version';
  }

  @override
  String get privacyVisitAnonymously => 'Visitar perfiles de forma anónima';

  @override
  String get privacyVisitAnonymouslyDesc => 'Tu nombre no aparecerá en la lista de visitantes recientes de esa persona.';

  @override
  String get profilePhotoUploading => 'Subiendo...';

  @override
  String get profilePhotoRemoving => 'Eliminando...';

  @override
  String get profileCropPhoto => 'Recortar foto';

  @override
  String get networkWifi => 'Wi-Fi';

  @override
  String get networkMobileData => 'Datos móviles';

  @override
  String get networkEthernet => 'Ethernet';

  @override
  String get notifPrefResetFailed => 'No se pudieron restablecer las preferencias';

  @override
  String get notifPrefNewFollower => 'Nuevo seguidor';

  @override
  String get notifPrefVipRenewalWarning => 'Recordatorios de renovación VIP';

  @override
  String get accountDeletedSuccess => 'Cuenta eliminada correctamente';

  @override
  String get accountDeleteFailed => 'No se pudo eliminar la cuenta';

  @override
  String get coinHistoryLoadFailed => 'No se pudo cargar el historial de monedas.';

  @override
  String get waveAlreadySentTooltip => 'Ya saludaste — envía un mensaje';

  @override
  String waveAlreadySentTo(Object name) {
    return 'Ya saludaste a $name: envíale un mensaje.';
  }

  @override
  String get waveAlreadyWaved => 'Ya saludaste';

  @override
  String get communityCountryDetectFailed => 'No se pudo detectar el país';

  @override
  String get roomPickCategoryError => 'Elige una categoría';

  @override
  String get blockUserSuccess => 'Usuario bloqueado';

  @override
  String get blockUserFailed => 'No se pudo bloquear a este usuario';

  @override
  String get unblockUserSuccess => 'Usuario desbloqueado';

  @override
  String get unblockUserFailed => 'No se pudo desbloquear a este usuario';

  @override
  String get clubDeleteFailed => 'No se pudo eliminar el club';

  @override
  String get clubMemberUpdateFailed => 'No se pudo actualizar a este miembro';

  @override
  String get groupCoverUploadFailed => 'No se pudo subir la foto';

  @override
  String get groupCoverRemoveFailed => 'No se pudo quitar la foto';

  @override
  String get clubStatusArchived => 'Archivado';

  @override
  String get matchTagSimilarAge => 'Edad similar';

  @override
  String matchTagBothLike(Object topic) {
    return 'A ambos les gusta $topic';
  }

  @override
  String get topicNameCooking => 'Cocina';

  @override
  String get topicNameCoffee => 'Café y té';

  @override
  String get topicNameEatingOut => 'Comer fuera';

  @override
  String get topicNameBaking => 'Repostería';

  @override
  String get topicNameDrinking => 'Bebidas';

  @override
  String get topicNameStreetFood => 'Comida callejera';

  @override
  String get topicNameTravel => 'Viajes';

  @override
  String get topicNameBackpacking => 'Mochilero';

  @override
  String get topicNameBeaches => 'Playas';

  @override
  String get topicNameMountains => 'Montañas';

  @override
  String get topicNameCamping => 'Acampada';

  @override
  String get topicNameGym => 'Gimnasio';

  @override
  String get topicNameRunning => 'Correr';

  @override
  String get topicNameYoga => 'Yoga';

  @override
  String get topicNameFootball => 'Fútbol';

  @override
  String get topicNameBasketball => 'Baloncesto';

  @override
  String get topicNameHiking => 'Senderismo';

  @override
  String get topicNameCycling => 'Ciclismo';

  @override
  String get topicNameDancing => 'Baile';

  @override
  String get topicNameSwimming => 'Natación';

  @override
  String get topicNameMovies => 'Películas';

  @override
  String get topicNameTvShows => 'Series';

  @override
  String get topicNameMusic => 'Música';

  @override
  String get topicNameGaming => 'Videojuegos';

  @override
  String get topicNameAnime => 'Anime y manga';

  @override
  String get topicNameKpop => 'K-pop';

  @override
  String get topicNameKdrama => 'K-drama';

  @override
  String get topicNamePodcasts => 'Pódcasts';

  @override
  String get topicNameArt => 'Arte';

  @override
  String get topicNamePhotography => 'Fotografía';

  @override
  String get topicNameBooks => 'Libros';

  @override
  String get topicNameWriting => 'Escritura';

  @override
  String get topicNameHistory => 'Historia';

  @override
  String get topicNameDesign => 'Diseño';

  @override
  String get topicNameFashion => 'Moda';

  @override
  String get topicNameBeauty => 'Belleza y cuidado de la piel';

  @override
  String get topicNameShopping => 'Compras';

  @override
  String get topicNameGardening => 'Jardinería';

  @override
  String get topicNameDiy => 'Bricolaje';

  @override
  String get topicNameDogs => 'Perros';

  @override
  String get topicNameCats => 'Gatos';

  @override
  String get topicNameNature => 'Naturaleza';

  @override
  String get topicNameAnimals => 'Animales';

  @override
  String get topicNameLanguageExchange => 'Intercambio de idiomas';

  @override
  String get topicNameStudyAbroad => 'Estudiar en el extranjero';

  @override
  String get topicNameTechnology => 'Tecnología';

  @override
  String get topicNameProgramming => 'Programación';

  @override
  String get topicNameBusiness => 'Negocios';

  @override
  String get topicNameScience => 'Ciencia';

  @override
  String get topicNameDailyLife => 'Vida diaria';

  @override
  String get topicNameMakingFriends => 'Hacer amigos';

  @override
  String get topicNameRelationships => 'Relaciones';

  @override
  String get topicNameFamily => 'Familia';

  @override
  String get topicNameNightlife => 'Vida nocturna';

  @override
  String get topicNameMentalHealth => 'Salud mental';

  @override
  String get topicNameMeditation => 'Meditación';

  @override
  String get topicNameNutrition => 'Nutrición';

  @override
  String get topicNameSelfImprovement => 'Superación personal';

  @override
  String get topicCategoryFoodDrink => 'Comida y bebida';

  @override
  String get topicCategoryTravel => 'Viajes y aventura';

  @override
  String get topicCategorySports => 'Deporte y fitness';

  @override
  String get topicCategoryEntertainment => 'Entretenimiento y música';

  @override
  String get topicCategoryArts => 'Arte y cultura';

  @override
  String get topicCategoryLifestyle => 'Estilo de vida';

  @override
  String get topicCategoryPetsNature => 'Mascotas y naturaleza';

  @override
  String get topicCategoryLearning => 'Aprendizaje y carrera';

  @override
  String get topicCategorySocial => 'Social';

  @override
  String get topicCategoryHealth => 'Salud y bienestar';

  @override
  String get waveTooMany => 'Demasiados saludos. ¡Ve más despacio!';

  @override
  String get aiTutorNoSummary => '(sin resumen)';

  @override
  String vocabPackAllSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Las $count palabras ya están en tu vocabulario',
      one: 'Esta palabra ya está en tu vocabulario',
    );
    return '$_temp0';
  }

  @override
  String vocabPackAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se añadieron $count palabras a tu vocabulario',
      one: 'Se añadió 1 palabra a tu vocabulario',
    );
    return '$_temp0';
  }

  @override
  String vocabPackAddedSomeSaved(int count, int saved) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se añadieron $count palabras a tu vocabulario ($saved ya guardadas)',
      one: 'Se añadió 1 palabra a tu vocabulario ($saved ya guardadas)',
    );
    return '$_temp0';
  }

  @override
  String get vocabPackNoExercises => 'Sin ejercicios';

  @override
  String vocabPackPractice(int count) {
    return 'Practicar ($count)';
  }

  @override
  String get aiQuizPlayAgain => 'Jugar de nuevo';

  @override
  String get aiLessonAskHint => 'Pregunta lo que quieras sobre esta lección...';

  @override
  String get aiLessonConceptHint => '¿Qué concepto quieres que te expliquen?';

  @override
  String examTargetScoreHint(Object score) {
    return 'p. ej. $score';
  }

  @override
  String get vocabWordAdded => '¡Palabra añadida!';

  @override
  String get vocabWordAddFailed => 'No se pudo añadir la palabra';

  @override
  String get vocabEnterWordFirst => 'Escribe una palabra primero';

  @override
  String get vocabAiFilled => '¡La IA lo completó!';

  @override
  String get vocabAiFillFailed => 'La IA no pudo completarlo. Inténtalo de nuevo.';

  @override
  String get authSendCodeFailed => 'No se pudo enviar el código de verificación';

  @override
  String get authServerConfigError => 'Error de configuración del servidor. Contacta con soporte.';

  @override
  String get authAppleTokenFailed => 'No se pudo iniciar sesión con Apple. Inténtalo de nuevo.';

  @override
  String get authRegistrationFailed => 'Error en el registro';

  @override
  String get authEmailAlreadyExists => 'Ese correo ya existe. Usa otro.';

  @override
  String get reportEvidenceAddFailed => 'No se pudieron añadir las fotos';

  @override
  String reportEvidenceMaxFiles(int count) {
    return 'Máximo $count archivos por reporte';
  }

  @override
  String reportEvidenceFileTooLarge(Object name) {
    return '$name es demasiado grande (máx. 5 MB)';
  }

  @override
  String get reportEvidenceTotalTooLarge => 'El tamaño total superaría los 25 MB';

  @override
  String get blockedContentUnavailableToYou => 'Este contenido no está disponible para ti.';

  @override
  String blockedCantViewUserContent(Object name) {
    return 'No puedes ver el contenido de $name.';
  }

  @override
  String get blockedCantViewThisUserContent => 'No puedes ver el contenido de este usuario.';

  @override
  String blockedCantViewUserProfile(Object name) {
    return 'No puedes ver el perfil de $name.';
  }

  @override
  String get blockedProfileUnavailable => 'Este perfil no está disponible.';

  @override
  String get blockedContentUnavailable => 'Este contenido no está disponible.';

  @override
  String get blockedCantViewStories => 'No puedes ver estas historias.';

  @override
  String blockedCantMessageUser(Object name) {
    return 'No puedes enviar mensajes a $name.';
  }

  @override
  String get blockedCantMessageThisUser => 'No puedes enviar mensajes a este usuario.';

  @override
  String get blockedActionNotAllowed => 'No puedes realizar esta acción';

  @override
  String get blockedCantLike => 'No puedes dar me gusta a este contenido';

  @override
  String get blockedCantComment => 'No puedes comentar este contenido';
}
