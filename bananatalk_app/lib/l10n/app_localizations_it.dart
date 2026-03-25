// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'BananaTalk';

  @override
  String get login => 'Accedi';

  @override
  String get signUp => 'Registrati';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String get or => 'OPPURE';

  @override
  String get signInWithGoogle => 'Accedi con Google';

  @override
  String get signInWithApple => 'Accedi con Apple';

  @override
  String get signInWithFacebook => 'Accedi con Facebook';

  @override
  String get welcome => 'Benvenuto';

  @override
  String get home => 'Home';

  @override
  String get messages => 'Messaggi';

  @override
  String get moments => 'Momenti';

  @override
  String get profile => 'Profilo';

  @override
  String get settings => 'Impostazioni';

  @override
  String get logout => 'Esci';

  @override
  String get language => 'Lingua';

  @override
  String get selectLanguage => 'Seleziona lingua';

  @override
  String get autoTranslate => 'Traduzione automatica';

  @override
  String get autoTranslateMessages => 'Traduci automaticamente i messaggi';

  @override
  String get autoTranslateMoments => 'Traduci automaticamente i momenti';

  @override
  String get autoTranslateComments => 'Traduci automaticamente i commenti';

  @override
  String get translate => 'Traduci';

  @override
  String get translated => 'Tradotto';

  @override
  String get showOriginal => 'Mostra originale';

  @override
  String get showTranslation => 'Mostra traduzione';

  @override
  String get translating => 'Traduzione in corso...';

  @override
  String get translationFailed => 'Traduzione fallita';

  @override
  String get noTranslationAvailable => 'Nessuna traduzione disponibile';

  @override
  String translatedFrom(String language) {
    return 'Tradotto da $language';
  }

  @override
  String get save => 'Salva';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get edit => 'Modifica';

  @override
  String get share => 'Condividi';

  @override
  String get like => 'Mi piace';

  @override
  String get comment => 'Commenta';

  @override
  String get send => 'Invia';

  @override
  String get search => 'Cerca';

  @override
  String get notifications => 'Notifiche';

  @override
  String get followers => 'Follower';

  @override
  String get following => 'Seguiti';

  @override
  String get posts => 'Post';

  @override
  String get visitors => 'Visitatori';

  @override
  String get loading => 'Caricamento...';

  @override
  String get error => 'Errore';

  @override
  String get success => 'Successo';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get networkError => 'Errore di rete. Controlla la connessione.';

  @override
  String get somethingWentWrong => 'Qualcosa è andato storto';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get languageSettings => 'Impostazioni lingua';

  @override
  String get deviceLanguage => 'Lingua del dispositivo';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return 'Il tuo dispositivo è impostato su: $flag $name';
  }

  @override
  String get youCanOverride => 'Puoi sovrascrivere la lingua del dispositivo qui sotto.';

  @override
  String languageChangedTo(String name) {
    return 'Lingua cambiata in $name';
  }

  @override
  String get errorChangingLanguage => 'Errore nel cambio lingua';

  @override
  String get autoTranslateSettings => 'Impostazioni traduzione automatica';

  @override
  String get automaticallyTranslateIncomingMessages => 'Traduci automaticamente i messaggi in arrivo';

  @override
  String get automaticallyTranslateMomentsInFeed => 'Traduci automaticamente i momenti nel feed';

  @override
  String get automaticallyTranslateComments => 'Traduci automaticamente i commenti';

  @override
  String get translationServiceBeingConfigured => 'Il servizio di traduzione è in configurazione. Riprova più tardi.';

  @override
  String get translationUnavailable => 'Traduzione non disponibile';

  @override
  String get showLess => 'mostra meno';

  @override
  String get showMore => 'mostra di più';

  @override
  String get comments => 'Commenti';

  @override
  String get beTheFirstToComment => 'Sii il primo a commentare.';

  @override
  String get writeAComment => 'Scrivi un commento...';

  @override
  String get report => 'Segnala';

  @override
  String get reportMoment => 'Segnala momento';

  @override
  String get reportUser => 'Segnala utente';

  @override
  String get deleteMoment => 'Eliminare il momento?';

  @override
  String get thisActionCannotBeUndone => 'Questa azione non può essere annullata.';

  @override
  String get momentDeleted => 'Momento eliminato';

  @override
  String get deleteComment => 'Delete Comment?';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get editFeatureComingSoon => 'Funzione di modifica in arrivo';

  @override
  String get userNotFound => 'Utente non trovato';

  @override
  String get cannotReportYourOwnComment => 'Non puoi segnalare il tuo commento';

  @override
  String get profileSettings => 'Impostazioni profilo';

  @override
  String get editYourProfileInformation => 'Modifica le informazioni del profilo';

  @override
  String get blockedUsers => 'Utenti bloccati';

  @override
  String get manageBlockedUsers => 'Gestisci utenti bloccati';

  @override
  String get manageNotificationSettings => 'Gestisci impostazioni notifiche';

  @override
  String get privacySecurity => 'Privacy e sicurezza';

  @override
  String get controlYourPrivacy => 'Controlla la tua privacy';

  @override
  String get changeAppLanguage => 'Cambia lingua dell\'app';

  @override
  String get appearance => 'Aspetto';

  @override
  String get themeAndDisplaySettings => 'Impostazioni tema e visualizzazione';

  @override
  String get myReports => 'Le mie segnalazioni';

  @override
  String get viewYourSubmittedReports => 'Visualizza le tue segnalazioni';

  @override
  String get reportsManagement => 'Gestione segnalazioni';

  @override
  String get manageAllReportsAdmin => 'Gestisci tutte le segnalazioni (Admin)';

  @override
  String get legalPrivacy => 'Legale e Privacy';

  @override
  String get termsPrivacySubscriptionInfo => 'Termini, Privacy e info abbonamento';

  @override
  String get helpCenter => 'Centro assistenza';

  @override
  String get getHelpAndSupport => 'Ottieni aiuto e supporto';

  @override
  String get aboutBanaTalk => 'Informazioni su BanaTalk';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get permanentlyDeleteYourAccount => 'Elimina permanentemente il tuo account';

  @override
  String get loggedOutSuccessfully => 'Disconnessione riuscita';

  @override
  String get retry => 'Riprova';

  @override
  String get giftsLikes => 'Regali/Mi piace';

  @override
  String get details => 'Dettagli';

  @override
  String get to => 'a';

  @override
  String get banaTalk => 'BanaTalk';

  @override
  String get chats => 'Chat';

  @override
  String get community => 'Community';

  @override
  String get editProfile => 'Modifica profilo';

  @override
  String yearsOld(String age) {
    return '$age anni';
  }

  @override
  String get searchConversations => 'Cerca conversazioni...';

  @override
  String get visitorTrackingNotAvailable => 'Il tracciamento visitatori non è ancora disponibile. Aggiornamento backend richiesto.';

  @override
  String get chatList => 'Lista chat';

  @override
  String get languageExchange => 'Scambio linguistico';

  @override
  String get nativeLanguage => 'Lingua madre';

  @override
  String get learning => 'Imparando';

  @override
  String get notSet => 'Non impostato';

  @override
  String get about => 'Info';

  @override
  String get aboutMe => 'Su di me';

  @override
  String get bloodType => 'Gruppo sanguigno';

  @override
  String get photos => 'Foto';

  @override
  String get camera => 'Fotocamera';

  @override
  String get createMoment => 'Crea momento';

  @override
  String get addATitle => 'Aggiungi un titolo...';

  @override
  String get whatsOnYourMind => 'A cosa stai pensando?';

  @override
  String get addTags => 'Aggiungi tag';

  @override
  String get done => 'Fatto';

  @override
  String get add => 'Aggiungi';

  @override
  String get enterTag => 'Inserisci tag';

  @override
  String get post => 'Pubblica';

  @override
  String get commentAddedSuccessfully => 'Commento aggiunto con successo';

  @override
  String get clearFilters => 'Cancella filtri';

  @override
  String get notificationSettings => 'Impostazioni notifiche';

  @override
  String get enableNotifications => 'Abilita notifiche';

  @override
  String get turnAllNotificationsOnOrOff => 'Attiva o disattiva tutte le notifiche';

  @override
  String get notificationTypes => 'Tipi di notifiche';

  @override
  String get chatMessages => 'Messaggi chat';

  @override
  String get getNotifiedWhenYouReceiveMessages => 'Ricevi notifiche quando ricevi messaggi';

  @override
  String get likesAndCommentsOnYourMoments => 'Mi piace e commenti sui tuoi momenti';

  @override
  String get whenPeopleYouFollowPostMoments => 'Quando le persone che segui pubblicano momenti';

  @override
  String get friendRequests => 'Richieste di amicizia';

  @override
  String get whenSomeoneFollowsYou => 'Quando qualcuno ti segue';

  @override
  String get profileVisits => 'Visite al profilo';

  @override
  String get whenSomeoneViewsYourProfileVIP => 'Quando qualcuno visualizza il tuo profilo (VIP)';

  @override
  String get marketing => 'Marketing';

  @override
  String get updatesAndPromotionalMessages => 'Aggiornamenti e messaggi promozionali';

  @override
  String get notificationPreferences => 'Preferenze notifiche';

  @override
  String get sound => 'Suono';

  @override
  String get playNotificationSounds => 'Riproduci suoni di notifica';

  @override
  String get vibration => 'Vibrazione';

  @override
  String get vibrateOnNotifications => 'Vibra alle notifiche';

  @override
  String get showPreview => 'Mostra anteprima';

  @override
  String get showMessagePreviewInNotifications => 'Mostra anteprima messaggio nelle notifiche';

  @override
  String get mutedConversations => 'Conversazioni silenziate';

  @override
  String get conversation => 'Conversazione';

  @override
  String get unmute => 'Riattiva';

  @override
  String get systemNotificationSettings => 'Impostazioni notifiche di sistema';

  @override
  String get manageNotificationsInSystemSettings => 'Gestisci notifiche nelle impostazioni di sistema';

  @override
  String get errorLoadingSettings => 'Errore nel caricamento delle impostazioni';

  @override
  String get unblockUser => 'Sblocca utente';

  @override
  String get unblock => 'Sblocca';

  @override
  String get goBack => 'Torna indietro';

  @override
  String get messageSendTimeout => 'Timeout invio messaggio. Controlla la connessione.';

  @override
  String get failedToSendMessage => 'Invio messaggio fallito';

  @override
  String get dailyMessageLimitExceeded => 'Limite giornaliero messaggi superato. Passa a VIP per messaggi illimitati.';

  @override
  String get cannotSendMessageUserMayBeBlocked => 'Impossibile inviare messaggio. L\'utente potrebbe essere bloccato.';

  @override
  String get sessionExpired => 'Sessione scaduta. Accedi di nuovo.';

  @override
  String get sendThisSticker => 'Inviare questo sticker?';

  @override
  String get chooseHowYouWantToDeleteThisMessage => 'Scegli come vuoi eliminare questo messaggio:';

  @override
  String get deleteForEveryone => 'Elimina per tutti';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => 'Rimuove il messaggio per te e il destinatario';

  @override
  String get deleteForMe => 'Elimina per me';

  @override
  String get removesTheMessageOnlyFromYourChat => 'Rimuove il messaggio solo dalla tua chat';

  @override
  String get copy => 'Copia';

  @override
  String get reply => 'Rispondi';

  @override
  String get forward => 'Inoltra';

  @override
  String get moreOptions => 'Altre opzioni';

  @override
  String get noUsersAvailableToForwardTo => 'Nessun utente disponibile per l\'inoltro';

  @override
  String get searchMoments => 'Cerca momenti...';

  @override
  String searchInChatWith(String name) {
    return 'Cerca nella chat con $name';
  }

  @override
  String get typeAMessage => 'Scrivi un messaggio...';

  @override
  String get enterYourMessage => 'Inserisci il tuo messaggio';

  @override
  String get detectYourLocation => 'Rileva la tua posizione';

  @override
  String get tapToUpdateLocation => 'Tocca per aggiornare la posizione';

  @override
  String get helpOthersFindYouNearby => 'Aiuta gli altri a trovarti nelle vicinanze';

  @override
  String get selectYourNativeLanguage => 'Seleziona la tua lingua madre';

  @override
  String get whichLanguageDoYouWantToLearn => 'Quale lingua vuoi imparare?';

  @override
  String get selectYourGender => 'Seleziona il tuo genere';

  @override
  String get addACaption => 'Aggiungi una didascalia...';

  @override
  String get typeSomething => 'Scrivi qualcosa...';

  @override
  String get gallery => 'Galleria';

  @override
  String get video => 'Video';

  @override
  String get text => 'Testo';

  @override
  String get provideMoreInformation => 'Fornisci maggiori informazioni...';

  @override
  String get searchByNameLanguageOrInterests => 'Cerca per nome, lingua o interessi...';

  @override
  String get addTagAndPressEnter => 'Aggiungi tag e premi Invio';

  @override
  String replyTo(String name) {
    return 'Rispondi a $name...';
  }

  @override
  String get highlightName => 'Nome in evidenza';

  @override
  String get searchCloseFriends => 'Cerca amici stretti...';

  @override
  String get askAQuestion => 'Fai una domanda...';

  @override
  String option(String number) {
    return 'Opzione $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return 'Perché stai segnalando questo $type?';
  }

  @override
  String get additionalDetailsOptional => 'Dettagli aggiuntivi (opzionale)';

  @override
  String get warningThisActionIsPermanent => 'Attenzione: questa azione è permanente!';

  @override
  String get deletingYourAccountWillPermanentlyRemove => 'L\'eliminazione del tuo account rimuoverà permanentemente:\n\n• Il tuo profilo e tutti i dati personali\n• Tutti i tuoi messaggi e conversazioni\n• Tutti i tuoi momenti e storie\n• Il tuo abbonamento VIP (nessun rimborso)\n• Tutti i tuoi collegamenti e follower\n\nQuesta azione non può essere annullata.';

  @override
  String get clearAllNotifications => 'Cancellare tutte le notifiche?';

  @override
  String get clearAll => 'Cancella tutto';

  @override
  String get notificationDebug => 'Debug notifiche';

  @override
  String get markAllRead => 'Segna tutto come letto';

  @override
  String get clearAll2 => 'Cancella tutto';

  @override
  String get emailAddress => 'Indirizzo email';

  @override
  String get username => 'Nome utente';

  @override
  String get alreadyHaveAnAccount => 'Hai già un account?';

  @override
  String get login2 => 'Accedi';

  @override
  String get selectYourNativeLanguage2 => 'Seleziona la tua lingua madre';

  @override
  String get whichLanguageDoYouWantToLearn2 => 'Quale lingua vuoi imparare?';

  @override
  String get selectYourGender2 => 'Seleziona il tuo genere';

  @override
  String get dateFormat => 'GG.MM.AAAA';

  @override
  String get detectYourLocation2 => 'Rileva la tua posizione';

  @override
  String get tapToUpdateLocation2 => 'Tocca per aggiornare la posizione';

  @override
  String get helpOthersFindYouNearby2 => 'Aiuta gli altri a trovarti nelle vicinanze';

  @override
  String get couldNotOpenLink => 'Impossibile aprire il link';

  @override
  String get legalPrivacy2 => 'Legale e Privacy';

  @override
  String get termsOfUseEULA => 'Termini di utilizzo (EULA)';

  @override
  String get viewOurTermsAndConditions => 'Visualizza i nostri termini e condizioni';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get howWeHandleYourData => 'Come gestiamo i tuoi dati';

  @override
  String get emailNotifications => 'Notifiche email';

  @override
  String get receiveEmailNotificationsFromBananaTalk => 'Ricevi notifiche email da BananaTalk';

  @override
  String get weeklySummary => 'Riepilogo settimanale';

  @override
  String get activityRecapEverySunday => 'Riepilogo attività ogni domenica';

  @override
  String get newMessages => 'Nuovi messaggi';

  @override
  String get whenYoureAwayFor24PlusHours => 'Quando sei assente per 24+ ore';

  @override
  String get newFollowers => 'Nuovi follower';

  @override
  String get whenSomeoneFollowsYou2 => 'Quando qualcuno ti segue';

  @override
  String get securityAlerts => 'Avvisi di sicurezza';

  @override
  String get passwordLoginAlerts => 'Avvisi password e accesso';

  @override
  String get unblockUser2 => 'Sblocca utente';

  @override
  String get blockedUsers2 => 'Utenti bloccati';

  @override
  String get finalWarning => 'Ultimo avviso';

  @override
  String get deleteForever => 'Elimina per sempre';

  @override
  String get deleteAccount2 => 'Elimina account';

  @override
  String get enterYourPassword => 'Inserisci la tua password';

  @override
  String get yourPassword => 'La tua password';

  @override
  String get typeDELETEToConfirm => 'Digita ELIMINA per confermare';

  @override
  String get typeDELETEInCapitalLetters => 'Digita ELIMINA in maiuscolo';

  @override
  String sent(String emoji) {
    return '$emoji inviato!';
  }

  @override
  String get replySent => 'Risposta inviata!';

  @override
  String get deleteStory => 'Eliminare la storia?';

  @override
  String get thisStoryWillBeRemovedPermanently => 'Questa storia verrà rimossa permanentemente.';

  @override
  String get noStories => 'Nessuna storia';

  @override
  String views(String count) {
    return '$count visualizzazioni';
  }

  @override
  String get reportStory => 'Segnala storia';

  @override
  String get reply2 => 'Rispondi...';

  @override
  String get failedToPickImage => 'Impossibile selezionare l\'immagine';

  @override
  String get failedToTakePhoto => 'Impossibile scattare la foto';

  @override
  String get failedToPickVideo => 'Impossibile selezionare il video';

  @override
  String get pleaseEnterSomeText => 'Inserisci del testo';

  @override
  String get pleaseSelectMedia => 'Seleziona un media';

  @override
  String get storyPosted => 'Storia pubblicata!';

  @override
  String get textOnlyStoriesRequireAnImage => 'Le storie solo testo richiedono un\'immagine';

  @override
  String get createStory => 'Crea storia';

  @override
  String get change => 'Cambia';

  @override
  String get userIdNotFound => 'ID utente non trovato. Effettua nuovamente l\'accesso.';

  @override
  String get pleaseSelectAPaymentMethod => 'Seleziona un metodo di pagamento';

  @override
  String get startExploring => 'Inizia a esplorare';

  @override
  String get close => 'Chiudi';

  @override
  String get payment => 'Pagamento';

  @override
  String get upgradeToVIP => 'Passa a VIP';

  @override
  String get errorLoadingProducts => 'Errore nel caricamento dei prodotti';

  @override
  String get cancelVIPSubscription => 'Annulla abbonamento VIP';

  @override
  String get keepVIP => 'Mantieni VIP';

  @override
  String get cancelSubscription => 'Annulla abbonamento';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'Abbonamento VIP annullato con successo';

  @override
  String get vipStatus => 'Stato VIP';

  @override
  String get noActiveVIPSubscription => 'Nessun abbonamento VIP attivo';

  @override
  String get subscriptionExpired => 'Abbonamento scaduto';

  @override
  String get vipExpiredMessage => 'Il tuo abbonamento VIP è scaduto. Rinnova ora per continuare a goderti le funzionalità illimitate!';

  @override
  String get expiredOn => 'Scaduto il';

  @override
  String get renewVIP => 'Rinnova VIP';

  @override
  String get whatYoureMissing => 'Cosa ti stai perdendo';

  @override
  String get manageInAppStore => 'Gestisci nell\'App Store';

  @override
  String get becomeVIP => 'Diventa VIP';

  @override
  String get unlimitedMessages => 'Messaggi illimitati';

  @override
  String get unlimitedProfileViews => 'Visualizzazioni profilo illimitate';

  @override
  String get prioritySupport => 'Supporto prioritario';

  @override
  String get advancedSearch => 'Ricerca avanzata';

  @override
  String get profileBoost => 'Boost profilo';

  @override
  String get adFreeExperience => 'Esperienza senza pubblicità';

  @override
  String get upgradeYourAccount => 'Aggiorna il tuo account';

  @override
  String get moreMessages => 'Più messaggi';

  @override
  String get moreProfileViews => 'Più visualizzazioni profilo';

  @override
  String get connectWithFriends => 'Connettiti con gli amici';

  @override
  String get reviewStarted => 'Revisione iniziata';

  @override
  String get reportResolved => 'Segnalazione risolta';

  @override
  String get reportDismissed => 'Segnalazione respinta';

  @override
  String get selectAction => 'Seleziona azione';

  @override
  String get noViolation => 'Nessuna violazione';

  @override
  String get contentRemoved => 'Contenuto rimosso';

  @override
  String get userWarned => 'Utente avvisato';

  @override
  String get userSuspended => 'Utente sospeso';

  @override
  String get userBanned => 'Utente bannato';

  @override
  String get addNotesOptional => 'Aggiungi note (opzionale)';

  @override
  String get enterModeratorNotes => 'Inserisci note del moderatore...';

  @override
  String get skip => 'Salta';

  @override
  String get startReview => 'Inizia revisione';

  @override
  String get resolve => 'Risolvi';

  @override
  String get dismiss => 'Respingi';

  @override
  String get filterReports => 'Filtra segnalazioni';

  @override
  String get all => 'Tutti';

  @override
  String get clear => 'Cancella';

  @override
  String get apply => 'Applica';

  @override
  String get myReports2 => 'Le mie segnalazioni';

  @override
  String get blockUser => 'Blocca utente';

  @override
  String get block => 'Blocca';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => 'Vuoi anche bloccare questo utente?';

  @override
  String get noThanks => 'No, grazie';

  @override
  String get yesBlockThem => 'Sì, bloccalo';

  @override
  String get reportUser2 => 'Segnala utente';

  @override
  String get submitReport => 'Invia segnalazione';

  @override
  String get addAQuestionAndAtLeast2Options => 'Aggiungi una domanda e almeno 2 opzioni';

  @override
  String get addOption => 'Aggiungi opzione';

  @override
  String get anonymousVoting => 'Voto anonimo';

  @override
  String get create => 'Crea';

  @override
  String get typeYourAnswer => 'Scrivi la tua risposta...';

  @override
  String get send2 => 'Invia';

  @override
  String get yourPrompt => 'La tua domanda...';

  @override
  String get add2 => 'Aggiungi';

  @override
  String get contentNotAvailable => 'Contenuto non disponibile';

  @override
  String get profileNotAvailable => 'Profilo non disponibile';

  @override
  String get noMomentsToShow => 'Nessun momento da mostrare';

  @override
  String get storiesNotAvailable => 'Storie non disponibili';

  @override
  String get cantMessageThisUser => 'Impossibile inviare messaggi a questo utente';

  @override
  String get pleaseSelectAReason => 'Seleziona un motivo';

  @override
  String get reportSubmitted => 'Segnalazione inviata. Grazie per aiutare a mantenere sicura la nostra community.';

  @override
  String get youHaveAlreadyReportedThisMoment => 'Hai già segnalato questo momento';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => 'Dicci di più sul motivo della segnalazione';

  @override
  String get errorSharing => 'Errore nella condivisione';

  @override
  String get deviceInfo => 'Info dispositivo';

  @override
  String get recommended => 'Consigliato';

  @override
  String get anyLanguage => 'Qualsiasi lingua';

  @override
  String get noLanguagesFound => 'Nessuna lingua trovata';

  @override
  String get selectALanguage => 'Seleziona una lingua';

  @override
  String get languagesAreStillLoading => 'Le lingue sono ancora in caricamento...';

  @override
  String get selectNativeLanguage => 'Seleziona lingua madre';

  @override
  String get subscriptionDetails => 'Dettagli abbonamento';

  @override
  String get activeFeatures => 'Funzionalità attive';

  @override
  String get legalInformation => 'Informazioni legali';

  @override
  String get termsOfUse => 'Termini di utilizzo';

  @override
  String get manageSubscription => 'Gestisci abbonamento';

  @override
  String get manageSubscriptionInSettings => 'Per annullare l\'abbonamento, vai su Impostazioni > [Il tuo nome] > Abbonamenti sul dispositivo.';

  @override
  String get contactSupportToCancel => 'Per annullare l\'abbonamento, contatta il nostro team di supporto.';

  @override
  String get status => 'Stato';

  @override
  String get active => 'Attivo';

  @override
  String get plan => 'Piano';

  @override
  String get startDate => 'Data inizio';

  @override
  String get endDate => 'Data fine';

  @override
  String get nextBillingDate => 'Prossima fatturazione';

  @override
  String get autoRenew => 'Rinnovo automatico';

  @override
  String get pleaseLogInToContinue => 'Accedi per continuare';

  @override
  String get purchaseCanceledOrFailed => 'Acquisto annullato o fallito. Riprova.';

  @override
  String get maximumTagsAllowed => 'Massimo 5 tag consentiti';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => 'Rimuovi prima le immagini per aggiungere un video';

  @override
  String get unsupportedFormat => 'Formato non supportato';

  @override
  String get errorProcessingVideo => 'Errore nell\'elaborazione del video';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'Rimuovi prima le immagini per registrare un video';

  @override
  String get locationAdded => 'Posizione aggiunta';

  @override
  String get failedToGetLocation => 'Impossibile ottenere la posizione';

  @override
  String get notNow => 'Non ora';

  @override
  String get videoUploadFailed => 'Caricamento video fallito';

  @override
  String get skipVideo => 'Salta video';

  @override
  String get retryUpload => 'Riprova caricamento';

  @override
  String get momentCreatedSuccessfully => 'Momento creato con successo';

  @override
  String get uploadingMomentInBackground => 'Caricamento momento in background...';

  @override
  String get failedToQueueUpload => 'Impossibile mettere in coda il caricamento';

  @override
  String get viewProfile => 'Visualizza profilo';

  @override
  String get mediaLinksAndDocs => 'Media, link e documenti';

  @override
  String get wallpaper => 'Sfondo';

  @override
  String get userIdNotAvailable => 'ID utente non disponibile';

  @override
  String get cannotBlockYourself => 'Non puoi bloccare te stesso';

  @override
  String get chatWallpaper => 'Sfondo chat';

  @override
  String get wallpaperSavedLocally => 'Sfondo salvato localmente';

  @override
  String get messageCopied => 'Messaggio copiato';

  @override
  String get forwardFeatureComingSoon => 'Funzione inoltra in arrivo';

  @override
  String get momentUnsaved => 'Rimosso dai salvati';

  @override
  String get documentPickerComingSoon => 'Selettore documenti in arrivo';

  @override
  String get contactSharingComingSoon => 'Condivisione contatti in arrivo';

  @override
  String get featureComingSoon => 'Funzionalità in arrivo';

  @override
  String get answerSent => 'Risposta inviata!';

  @override
  String get noImagesAvailable => 'Nessuna immagine disponibile';

  @override
  String get mentionPickerComingSoon => 'Selettore menzioni in arrivo';

  @override
  String get musicPickerComingSoon => 'Selettore musica in arrivo';

  @override
  String get repostFeatureComingSoon => 'Funzione repost in arrivo';

  @override
  String get addFriendsFromYourProfile => 'Aggiungi amici dal tuo profilo';

  @override
  String get quickReplyAdded => 'Risposta rapida aggiunta';

  @override
  String get quickReplyDeleted => 'Risposta rapida eliminata';

  @override
  String get linkCopied => 'Link copiato!';

  @override
  String get maximumOptionsAllowed => 'Massimo 10 opzioni consentite';

  @override
  String get minimumOptionsRequired => 'Minimo 2 opzioni richieste';

  @override
  String get pleaseEnterAQuestion => 'Inserisci una domanda';

  @override
  String get pleaseAddAtLeast2Options => 'Aggiungi almeno 2 opzioni';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => 'Seleziona la risposta corretta per il quiz';

  @override
  String get correctionSent => 'Correzione inviata!';

  @override
  String get sort => 'Ordina';

  @override
  String get savedMoments => 'Momenti salvati';

  @override
  String get unsave => 'Rimuovi';

  @override
  String get playingAudio => 'Riproduzione audio...';

  @override
  String get failedToGenerateQuiz => 'Impossibile generare il quiz';

  @override
  String get failedToAddComment => 'Impossibile aggiungere il commento';

  @override
  String get hello => 'Ciao!';

  @override
  String get howAreYou => 'Come stai?';

  @override
  String get cannotOpen => 'Impossibile aprire';

  @override
  String get errorOpeningLink => 'Errore nell\'apertura del link';

  @override
  String get saved => 'Salvato';

  @override
  String get follow => 'Segui';

  @override
  String get unfollow => 'Smetti di seguire';

  @override
  String get mute => 'Silenzia';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get lastSeen => 'Ultimo accesso';

  @override
  String get justNow => 'adesso';

  @override
  String minutesAgo(String count) {
    return '$count minuti fa';
  }

  @override
  String hoursAgo(String count) {
    return '$count ore fa';
  }

  @override
  String get yesterday => 'Ieri';

  @override
  String get signInWithEmail => 'Accedi con email';

  @override
  String get partners => 'Partner';

  @override
  String get nearby => 'Nelle vicinanze';

  @override
  String get topics => 'Argomenti';

  @override
  String get waves => 'Saluti';

  @override
  String get voiceRooms => 'Voce';

  @override
  String get filters => 'Filtri';

  @override
  String get searchCommunity => 'Cerca per nome, lingua o interessi...';

  @override
  String get bio => 'Bio';

  @override
  String get noBioYet => 'Nessuna bio disponibile.';

  @override
  String get languages => 'Lingue';

  @override
  String get native => 'Madrelingua';

  @override
  String get interests => 'Interessi';

  @override
  String get noMomentsYet => 'Nessun momento ancora';

  @override
  String get unableToLoadMoments => 'Impossibile caricare i momenti';

  @override
  String get map => 'Mappa';

  @override
  String get mapUnavailable => 'Mappa non disponibile';

  @override
  String get location => 'Posizione';

  @override
  String get unknownLocation => 'Posizione sconosciuta';

  @override
  String get noImagesAvailable2 => 'Nessuna immagine disponibile';

  @override
  String get permissionsRequired => 'Permessi richiesti';

  @override
  String get openSettings => 'Apri impostazioni';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get videoCall => 'Video';

  @override
  String get voiceCall => 'Chiamata';

  @override
  String get message => 'Messaggio';

  @override
  String get pleaseLoginToFollow => 'Accedi per seguire gli utenti';

  @override
  String get pleaseLoginToCall => 'Accedi per effettuare una chiamata';

  @override
  String get cannotCallYourself => 'Non puoi chiamare te stesso';

  @override
  String get failedToFollowUser => 'Impossibile seguire l\'utente';

  @override
  String get failedToUnfollowUser => 'Impossibile smettere di seguire l\'utente';

  @override
  String get areYouSureUnfollow => 'Sei sicuro di voler smettere di seguire questo utente?';

  @override
  String get areYouSureUnblock => 'Sei sicuro di voler sbloccare questo utente?';

  @override
  String get youFollowed => 'Ora segui';

  @override
  String get youUnfollowed => 'Hai smesso di seguire';

  @override
  String get alreadyFollowing => 'Stai già seguendo';

  @override
  String get soon => 'Presto';

  @override
  String comingSoon(String feature) {
    return '$feature in arrivo!';
  }

  @override
  String get muteNotifications => 'Silenzia notifiche';

  @override
  String get unmuteNotifications => 'Riattiva notifiche';

  @override
  String get operationCompleted => 'Operazione completata';

  @override
  String get couldNotOpenMaps => 'Impossibile aprire le mappe';

  @override
  String hasntSharedMoments(Object name) {
    return '$name non ha condiviso momenti';
  }

  @override
  String messageUser(String name) {
    return 'Invia messaggio a $name';
  }

  @override
  String notFollowingUser(String name) {
    return 'Non stavi seguendo $name';
  }

  @override
  String youFollowedUser(String name) {
    return 'Ora segui $name';
  }

  @override
  String youUnfollowedUser(String name) {
    return 'Hai smesso di seguire $name';
  }

  @override
  String unfollowUser(String name) {
    return 'Smetti di seguire $name';
  }

  @override
  String get typing => 'sta scrivendo';

  @override
  String get connecting => 'Connessione...';

  @override
  String daysAgo(int count) {
    return '${count}g fa';
  }

  @override
  String get maxTagsAllowed => 'Massimo 5 tag consentiti';

  @override
  String maxImagesAllowed(int count) {
    return 'Massimo $count immagini consentite';
  }

  @override
  String get pleaseRemoveImagesFirst => 'Rimuovi prima le immagini per aggiungere un video';

  @override
  String get exchange3MessagesBeforeCall => 'Devi scambiare almeno 3 messaggi prima di poter chiamare questo utente';

  @override
  String mediaWithUser(String name) {
    return 'Media con $name';
  }

  @override
  String get errorLoadingMedia => 'Errore nel caricamento dei media';

  @override
  String get savedMomentsTitle => 'Momenti salvati';

  @override
  String get removeBookmark => 'Rimuovere segnalibro?';

  @override
  String get thisWillRemoveBookmark => 'Questo rimuoverà il messaggio dai tuoi segnalibri.';

  @override
  String get remove => 'Rimuovi';

  @override
  String get bookmarkRemoved => 'Segnalibro rimosso';

  @override
  String get bookmarkedMessages => 'Messaggi con segnalibro';

  @override
  String get wallpaperSaved => 'Sfondo salvato localmente';

  @override
  String get typeDeleteToConfirm => 'Type DELETE to confirm';

  @override
  String get storyArchive => 'Archivio storie';

  @override
  String get newHighlight => 'Nuovo in evidenza';

  @override
  String get addToHighlight => 'Aggiungi a in evidenza';

  @override
  String get repost => 'Ripubblica';

  @override
  String get repostFeatureSoon => 'Funzione ripubblica in arrivo';

  @override
  String get closeFriends => 'Amici stretti';

  @override
  String get addFriends => 'Aggiungi amici';

  @override
  String get highlights => 'In evidenza';

  @override
  String get createHighlight => 'Crea in evidenza';

  @override
  String get deleteHighlight => 'Eliminare in evidenza?';

  @override
  String get editHighlight => 'Modifica in evidenza';

  @override
  String get addMoreToStory => 'Aggiungi altro alla storia';

  @override
  String get noViewersYet => 'Nessun visualizzatore ancora';

  @override
  String get noReactionsYet => 'Nessuna reazione ancora';

  @override
  String get leaveRoom => 'Esci dalla stanza';

  @override
  String get areYouSureLeaveRoom => 'Sei sicuro di voler lasciare questa stanza vocale?';

  @override
  String get stay => 'Resta';

  @override
  String get leave => 'Esci';

  @override
  String get enableGPS => 'Abilita GPS';

  @override
  String wavedToUser(String name) {
    return 'Hai salutato $name!';
  }

  @override
  String get areYouSureFollow => 'Sei sicuro di voler seguire';

  @override
  String get failedToLoadProfile => 'Impossibile caricare il profilo';

  @override
  String get noFollowersYet => 'Nessun follower ancora';

  @override
  String get noFollowingYet => 'Non segue ancora nessuno';

  @override
  String get searchUsers => 'Cerca utenti...';

  @override
  String get noResultsFound => 'Nessun risultato trovato';

  @override
  String get loadingFailed => 'Caricamento fallito';

  @override
  String get copyLink => 'Copia link';

  @override
  String get shareStory => 'Condividi storia';

  @override
  String get thisWillDeleteStory => 'Questa storia verrà eliminata permanentemente.';

  @override
  String get storyDeleted => 'Storia eliminata';

  @override
  String get addCaption => 'Aggiungi didascalia...';

  @override
  String get yourStory => 'La tua storia';

  @override
  String get sendMessage => 'Invia messaggio';

  @override
  String get replyToStory => 'Rispondi alla storia...';

  @override
  String get viewAllReplies => 'Visualizza tutte le risposte';

  @override
  String get preparingVideo => 'Preparazione video...';

  @override
  String videoOptimized(String size, String savings) {
    return 'Video ottimizzato: ${size}MB (risparmiato $savings%)';
  }

  @override
  String get failedToProcessVideo => 'Impossibile elaborare il video';

  @override
  String get optimizingForBestExperience => 'Ottimizzazione per la migliore esperienza di storia';

  @override
  String get pleaseSelectImageOrVideo => 'Seleziona un\'immagine o un video per la tua storia';

  @override
  String get storyCreatedSuccessfully => 'Storia creata con successo!';

  @override
  String get uploadingStoryInBackground => 'Caricamento storia in background...';

  @override
  String get storyCreationFailed => 'Creazione storia fallita';

  @override
  String get pleaseCheckConnection => 'Controlla la connessione e riprova.';

  @override
  String get uploadFailed => 'Caricamento fallito';

  @override
  String get tryShorterVideo => 'Prova con un video più corto o riprova più tardi.';

  @override
  String get shareMomentsThatDisappear => 'Condividi momenti che scompaiono in 24 ore';

  @override
  String get photo => 'Foto';

  @override
  String get record => 'Registra';

  @override
  String get addSticker => 'Aggiungi sticker';

  @override
  String get poll => 'Sondaggio';

  @override
  String get question => 'Domanda';

  @override
  String get mention => 'Menzione';

  @override
  String get music => 'Musica';

  @override
  String get hashtag => 'Hashtag';

  @override
  String get whoCanSeeThis => 'Chi può vedere questo?';

  @override
  String get everyone => 'Tutti';

  @override
  String get anyoneCanSeeStory => 'Chiunque può vedere questa storia';

  @override
  String get friendsOnly => 'Solo amici';

  @override
  String get onlyFollowersCanSee => 'Solo i tuoi follower possono vedere';

  @override
  String get onlyCloseFriendsCanSee => 'Solo i tuoi amici stretti possono vedere';

  @override
  String get backgroundColor => 'Colore sfondo';

  @override
  String get fontStyle => 'Stile carattere';

  @override
  String get normal => 'Normale';

  @override
  String get bold => 'Grassetto';

  @override
  String get italic => 'Corsivo';

  @override
  String get handwriting => 'Scrittura a mano';

  @override
  String get addLocation => 'Aggiungi posizione';

  @override
  String get enterLocationName => 'Inserisci nome posizione';

  @override
  String get addLink => 'Aggiungi link';

  @override
  String get buttonText => 'Testo pulsante';

  @override
  String get learnMore => 'Scopri di più';

  @override
  String get addHashtags => 'Aggiungi hashtag';

  @override
  String get addHashtag => 'Aggiungi hashtag';

  @override
  String get sendAsMessage => 'Invia come messaggio';

  @override
  String get shareExternally => 'Condividi esternamente';

  @override
  String get checkOutStory => 'Guarda questa storia su BananaTalk!';

  @override
  String viewsTab(String count) {
    return 'Visualizzazioni ($count)';
  }

  @override
  String reactionsTab(String count) {
    return 'Reazioni ($count)';
  }

  @override
  String get processingVideo => 'Elaborazione video...';

  @override
  String get link => 'Link';

  @override
  String unmuteUser(String name) {
    return 'Riattivare $name?';
  }

  @override
  String get willReceiveNotifications => 'Riceverai notifiche per i nuovi messaggi.';

  @override
  String muteNotificationsFor(String name) {
    return 'Silenzia notifiche per $name';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return 'Notifiche riattivate per $name';
  }

  @override
  String notificationsMutedFor(String name) {
    return 'Notifiche silenziate per $name';
  }

  @override
  String get failedToUpdateMuteSettings => 'Impossibile aggiornare le impostazioni di silenziamento';

  @override
  String get oneHour => '1 ora';

  @override
  String get eightHours => '8 ore';

  @override
  String get oneWeek => '1 settimana';

  @override
  String get always => 'Sempre';

  @override
  String get failedToLoadBookmarks => 'Impossibile caricare i segnalibri';

  @override
  String get noBookmarkedMessages => 'Nessun messaggio con segnalibro';

  @override
  String get longPressToBookmark => 'Tieni premuto su un messaggio per aggiungerlo ai segnalibri';

  @override
  String get thisWillRemoveFromBookmarks => 'Questo rimuoverà il messaggio dai tuoi segnalibri.';

  @override
  String navigateToMessage(String name) {
    return 'Vai al messaggio nella chat con $name';
  }

  @override
  String bookmarkedOn(String date) {
    return 'Aggiunto ai segnalibri il $date';
  }

  @override
  String get voiceMessage => 'Messaggio vocale';

  @override
  String get document => 'Documento';

  @override
  String get attachment => 'Allegato';

  @override
  String get sendMeAMessage => 'Inviami un messaggio';

  @override
  String get shareWithFriends => 'Condividi con gli amici';

  @override
  String get shareAnywhere => 'Condividi ovunque';

  @override
  String get emailPreferences => 'Preferenze email';

  @override
  String get receiveEmailNotifications => 'Ricevi notifiche email da BananaTalk';

  @override
  String get whenAwayFor24Hours => 'Quando sei assente per 24+ ore';

  @override
  String get passwordAndLoginAlerts => 'Avvisi password e accesso';

  @override
  String get failedToLoadPreferences => 'Impossibile caricare le preferenze';

  @override
  String get failedToUpdateSetting => 'Impossibile aggiornare l\'impostazione';

  @override
  String get securityAlertsRecommended => 'Ti consigliamo di tenere attivi gli Avvisi di sicurezza per rimanere informato sulle attività importanti del tuo account.';

  @override
  String chatWallpaperFor(String name) {
    return 'Sfondo chat per $name';
  }

  @override
  String get solidColors => 'Colori solidi';

  @override
  String get gradients => 'Gradienti';

  @override
  String get customImage => 'Immagine personalizzata';

  @override
  String get chooseFromGallery => 'Scegli dalla galleria';

  @override
  String get preview => 'Anteprima';

  @override
  String get wallpaperUpdated => 'Sfondo aggiornato';

  @override
  String get category => 'Categoria';

  @override
  String get mood => 'Umore';

  @override
  String get sortBy => 'Ordina per';

  @override
  String get timePeriod => 'Periodo';

  @override
  String get searchLanguages => 'Cerca lingue...';

  @override
  String get selected => 'Selezionato';

  @override
  String get categories => 'Categorie';

  @override
  String get moods => 'Umori';

  @override
  String get applyFilters => 'Applica filtri';

  @override
  String applyNFilters(int count) {
    return 'Applica $count filtri';
  }

  @override
  String get videoMustBeUnder1GB => 'Il video deve essere inferiore a 1GB.';

  @override
  String get failedToRecordVideo => 'Impossibile registrare il video';

  @override
  String get errorSendingVideo => 'Errore nell\'invio del video';

  @override
  String get errorSendingVoiceMessage => 'Errore nell\'invio del messaggio vocale';

  @override
  String get errorSendingMedia => 'Errore nell\'invio del media';

  @override
  String get cameraPermissionRequired => 'I permessi di fotocamera e microfono sono necessari per registrare video.';

  @override
  String get locationPermissionRequired => 'Il permesso di posizione è necessario per condividere la tua posizione.';

  @override
  String get noInternetConnection => 'Nessuna connessione internet';

  @override
  String get tryAgainLater => 'Riprova più tardi';

  @override
  String get messageSent => 'Messaggio inviato';

  @override
  String get messageDeleted => 'Messaggio eliminato';

  @override
  String get messageEdited => 'Messaggio modificato';

  @override
  String get edited => '(modificato)';

  @override
  String get now => 'ora';

  @override
  String weeksAgo(int count) {
    return '${count}sett fa';
  }

  @override
  String viewRepliesCount(int count) {
    return '── Vedi $count risposte';
  }

  @override
  String get hideReplies => '── Nascondi risposte';

  @override
  String get saveMoment => 'Salva momento';

  @override
  String get removeFromSaved => 'Rimuovi dai salvati';

  @override
  String get momentSaved => 'Salvato';

  @override
  String get failedToSave => 'Salvataggio fallito';

  @override
  String checkOutMoment(String title) {
    return 'Dai un\'occhiata a questo momento: $title';
  }

  @override
  String get failedToLoadMoments => 'Impossibile caricare i momenti';

  @override
  String get noMomentsMatchFilters => 'Nessun momento corrisponde ai tuoi filtri';

  @override
  String get beFirstToShareMoment => 'Sii il primo a condividere un momento!';

  @override
  String get tryDifferentSearch => 'Prova un termine di ricerca diverso';

  @override
  String get tryAdjustingFilters => 'Prova a regolare i tuoi filtri';

  @override
  String get noSavedMoments => 'Nessun momento salvato';

  @override
  String get tapBookmarkToSave => 'Tocca l\'icona del segnalibro per salvare un momento';

  @override
  String get failedToLoadVideo => 'Impossibile caricare il video';

  @override
  String get titleRequired => 'Il titolo è obbligatorio';

  @override
  String titleTooLong(int max) {
    return 'Il titolo deve essere di $max caratteri o meno';
  }

  @override
  String get descriptionRequired => 'La descrizione è obbligatoria';

  @override
  String descriptionTooLong(int max) {
    return 'La descrizione deve essere di $max caratteri o meno';
  }

  @override
  String get scheduledDateMustBeFuture => 'La data programmata deve essere nel futuro';

  @override
  String get recent => 'Recente';

  @override
  String get popular => 'Popolare';

  @override
  String get trending => 'Di tendenza';

  @override
  String get mostRecent => 'Più recente';

  @override
  String get mostPopular => 'Più popolare';

  @override
  String get allTime => 'Tutto';

  @override
  String get today => 'Oggi';

  @override
  String get thisWeek => 'Questa settimana';

  @override
  String get thisMonth => 'Questo mese';

  @override
  String replyingTo(String userName) {
    return 'Rispondendo a $userName';
  }

  @override
  String get listView => 'Vista elenco';

  @override
  String get quickMatch => 'Match veloce';

  @override
  String get onlineNow => 'Online ora';

  @override
  String speaksLanguage(String language) {
    return 'Parla $language';
  }

  @override
  String learningLanguage(String language) {
    return 'Sta imparando $language';
  }

  @override
  String get noPartnersFound => 'Nessun partner trovato';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return 'Nessun utente trovato che parli $learning come madrelingua o voglia imparare $native.';
  }

  @override
  String get removeAllFilters => 'Rimuovi tutti i filtri';

  @override
  String get browseAllUsers => 'Sfoglia tutti gli utenti';

  @override
  String get allCaughtUp => 'Sei in pari!';

  @override
  String get loadingMore => 'Caricamento in corso...';

  @override
  String get findingMorePartners => 'Ricerca di altri partner...';

  @override
  String get seenAllPartners => 'Hai visto tutti i partner';

  @override
  String get startOver => 'Ricomincia';

  @override
  String get changeFilters => 'Cambia filtri';

  @override
  String get findingPartners => 'Ricerca partner in corso...';

  @override
  String get setLocationReminder => 'Imposta la tua posizione per trovare partner nelle vicinanze';

  @override
  String get updateLocationReminder => 'Aggiorna la tua posizione per risultati migliori';

  @override
  String get male => 'Maschio';

  @override
  String get female => 'Femmina';

  @override
  String get other => 'Altro';

  @override
  String get browseMen => 'Cerca uomini';

  @override
  String get browseWomen => 'Cerca donne';

  @override
  String get noMaleUsersFound => 'Nessun utente maschile trovato';

  @override
  String get noFemaleUsersFound => 'Nessun utente femminile trovato';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => 'Solo nuovi utenti';

  @override
  String get showNewUsers => 'Mostra nuovi utenti';

  @override
  String get prioritizeNearby => 'Dai priorità ai vicini';

  @override
  String get showNearbyFirst => 'Mostra prima i vicini';

  @override
  String get setLocationToEnable => 'Imposta la posizione per abilitare';

  @override
  String get radius => 'Raggio';

  @override
  String get findingYourLocation => 'Ricerca della tua posizione...';

  @override
  String get enableLocationForDistance => 'Abilita la posizione per la distanza';

  @override
  String get enableLocationDescription => 'Abilita i servizi di localizzazione per trovare partner linguistici nelle vicinanze';

  @override
  String get enableGps => 'Abilita GPS';

  @override
  String get browseByCityCountry => 'Cerca per città/paese';

  @override
  String get peopleNearby => 'Persone nelle vicinanze';

  @override
  String get noNearbyUsersFound => 'Nessun utente nelle vicinanze';

  @override
  String get tryExpandingSearch => 'Prova ad ampliare la ricerca';

  @override
  String get exploreByCity => 'Esplora per città';

  @override
  String get exploreByCurrentCity => 'Esplora per città attuale';

  @override
  String get interactiveWorldMap => 'Mappa interattiva del mondo';

  @override
  String get searchByCityName => 'Cerca per nome della città';

  @override
  String get seeUserCountsPerCountry => 'Vedi il numero di utenti per paese';

  @override
  String get upgradeToVip => 'Passa a VIP';

  @override
  String get searchByCity => 'Cerca per città';

  @override
  String usersWorldwide(String count) {
    return '$count utenti nel mondo';
  }

  @override
  String get noUsersFound => 'Nessun utente trovato';

  @override
  String get tryDifferentCity => 'Prova con una città diversa';

  @override
  String usersCount(String count) {
    return '$count utenti';
  }

  @override
  String get searchCountry => 'Cerca paese';

  @override
  String get wave => 'Saluta';

  @override
  String get newUser => 'Nuovo utente';

  @override
  String get warningPermanent => 'Attenzione: questa azione è permanente!';

  @override
  String get deleteAccountWarning => 'L\'eliminazione del tuo account rimuoverà permanentemente:\n\n• Il tuo profilo e tutti i dati personali\n• Tutti i tuoi messaggi e conversazioni\n• Tutti i tuoi momenti e storie\n• Il tuo abbonamento VIP (nessun rimborso)\n• Tutti i tuoi collegamenti e follower\n\nQuesta azione non può essere annullata.';

  @override
  String get requiredForEmailOnly => 'Richiesto solo per account email';

  @override
  String get pleaseEnterPassword => 'Inserisci la tua password';

  @override
  String get typeDELETE => 'Digita DELETE';

  @override
  String get mustTypeDELETE => 'Devi digitare DELETE per continuare';

  @override
  String get deletingAccount => 'Eliminazione account in corso...';

  @override
  String get deleteMyAccountPermanently => 'Elimina il mio account definitivamente';

  @override
  String get whatsYourNativeLanguage => 'Qual è la tua lingua madre?';

  @override
  String get helpsMatchWithLearners => 'Aiuta ad abbinarti con chi sta imparando';

  @override
  String get whatAreYouLearning => 'Cosa stai imparando?';

  @override
  String get connectWithNativeSpeakers => 'Connettiti con madrelingua';

  @override
  String get selectLearningLanguage => 'Seleziona la lingua da imparare';

  @override
  String get selectCurrentLevel => 'Seleziona il livello attuale';

  @override
  String get beginner => 'Principiante';

  @override
  String get elementary => 'Elementare';

  @override
  String get intermediate => 'Intermedio';

  @override
  String get upperIntermediate => 'Intermedio superiore';

  @override
  String get advanced => 'Avanzato';

  @override
  String get proficient => 'Esperto';

  @override
  String get showingPartnersByDistance => 'Partner mostrati per distanza';

  @override
  String get enableLocationForResults => 'Abilita la posizione per risultati migliori';

  @override
  String get enable => 'Abilita';

  @override
  String get locationNotSet => 'Posizione non impostata';

  @override
  String get tellUsAboutYourself => 'Parlaci di te';

  @override
  String get justACoupleQuickThings => 'Solo un paio di cose veloci';

  @override
  String get gender => 'Genere';

  @override
  String get birthDate => 'Data di nascita';

  @override
  String get selectYourBirthDate => 'Seleziona la tua data di nascita';

  @override
  String get continueButton => 'Continua';

  @override
  String get pleaseSelectGender => 'Seleziona il tuo genere';

  @override
  String get pleaseSelectBirthDate => 'Seleziona la tua data di nascita';

  @override
  String get mustBe18 => 'Devi avere almeno 18 anni';

  @override
  String get invalidDate => 'Data non valida';

  @override
  String get almostDone => 'Quasi finito!';

  @override
  String get addPhotoLocationForMatches => 'Aggiungi foto e posizione per abbinamenti migliori';

  @override
  String get addProfilePhoto => 'Aggiungi foto profilo';

  @override
  String get optionalUpTo6Photos => 'Facoltativo - fino a 6 foto';

  @override
  String get maximum6Photos => 'Massimo 6 foto';

  @override
  String get tapToDetectLocation => 'Tocca per rilevare la posizione';

  @override
  String get optionalHelpsNearbyPartners => 'Facoltativo - aiuta a trovare partner nelle vicinanze';

  @override
  String get startLearning => 'Inizia ad imparare';

  @override
  String get photoLocationOptional => 'Foto e posizione sono facoltativi';

  @override
  String get pleaseAcceptTerms => 'Accetta i termini di servizio';

  @override
  String get iAgreeToThe => 'Accetto i';

  @override
  String get termsOfService => 'Termini di servizio';

  @override
  String get tapToSelectLanguage => 'Tocca per selezionare una lingua';

  @override
  String yourLevelIn(String language) {
    return 'Il tuo livello in $language (facoltativo)';
  }

  @override
  String get yourCurrentLevel => 'Il tuo livello attuale';

  @override
  String get nativeCannotBeSameAsLearning => 'La lingua madre non può essere uguale a quella che stai imparando';

  @override
  String get learningCannotBeSameAsNative => 'La lingua che stai imparando non può essere uguale alla lingua madre';

  @override
  String stepOf(String current, String total) {
    return 'Passo $current di $total';
  }

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get registerLink => 'Registrati';

  @override
  String get pleaseEnterBothEmailAndPassword => 'Inserisci email e password';

  @override
  String get pleaseEnterValidEmail => 'Inserisci un\'email valida';

  @override
  String get loginSuccessful => 'Accesso riuscito!';

  @override
  String get stepOneOfTwo => 'Passo 1 di 2';

  @override
  String get createYourAccount => 'Crea il tuo account';

  @override
  String get basicInfoToGetStarted => 'Informazioni di base per iniziare';

  @override
  String get emailVerifiedLabel => 'Email (Verificata)';

  @override
  String get nameLabel => 'Nome';

  @override
  String get yourDisplayName => 'Il tuo nome visualizzato';

  @override
  String get atLeast8Characters => 'Almeno 8 caratteri';

  @override
  String get confirmPasswordHint => 'Conferma password';

  @override
  String get nextButton => 'Avanti';

  @override
  String get pleaseEnterYourName => 'Inserisci il tuo nome';

  @override
  String get pleaseEnterAPassword => 'Inserisci una password';

  @override
  String get passwordsDoNotMatch => 'Le password non corrispondono';

  @override
  String get otherGender => 'Altro';

  @override
  String get continueWithGoogleAccount => 'Continua con il tuo account Google\nper un\'esperienza fluida';

  @override
  String get signingYouIn => 'Accesso in corso...';

  @override
  String get backToSignInMethods => 'Torna ai metodi di accesso';

  @override
  String get securedByGoogle => 'Protetto da Google';

  @override
  String get dataProtectedEncryption => 'I tuoi dati sono protetti con crittografia standard';

  @override
  String get welcomeCompleteProfile => 'Benvenuto! Completa il tuo profilo';

  @override
  String welcomeBackName(String name) {
    return 'Bentornato, $name!';
  }

  @override
  String get continueWithAppleId => 'Continua con il tuo Apple ID\nper un\'esperienza sicura';

  @override
  String get continueWithApple => 'Continua con Apple';

  @override
  String get securedByApple => 'Protetto da Apple';

  @override
  String get privacyProtectedApple => 'La tua privacy è protetta con Apple Sign-In';

  @override
  String get createAccount => 'Crea account';

  @override
  String get enterEmailToGetStarted => 'Inserisci la tua email per iniziare';

  @override
  String get continueText => 'Continua';

  @override
  String get pleaseEnterEmailAddress => 'Inserisci il tuo indirizzo email';

  @override
  String get verificationCodeSent => 'Codice di verifica inviato!';

  @override
  String get forgotPasswordTitle => 'Password dimenticata';

  @override
  String get resetPasswordTitle => 'Reimposta password';

  @override
  String get enterEmailForResetCode => 'Inserisci la tua email e ti invieremo un codice di reimpostazione';

  @override
  String get sendResetCode => 'Invia codice';

  @override
  String get resetCodeSent => 'Codice di reimpostazione inviato!';

  @override
  String get rememberYourPassword => 'Ricordi la password?';

  @override
  String get verifyCode => 'Verifica codice';

  @override
  String get enterResetCode => 'Inserisci il codice';

  @override
  String get weSentCodeTo => 'Abbiamo inviato un codice a 6 cifre a';

  @override
  String get pleaseEnterAll6Digits => 'Inserisci tutte le 6 cifre';

  @override
  String get codeVerifiedCreatePassword => 'Codice verificato! Crea la nuova password';

  @override
  String get verify => 'Verifica';

  @override
  String get didntReceiveCode => 'Non hai ricevuto il codice?';

  @override
  String get resend => 'Reinvia';

  @override
  String resendWithTimer(String timer) {
    return 'Reinvia (${timer}s)';
  }

  @override
  String get resetCodeResent => 'Codice reinviato!';

  @override
  String get verifyEmail => 'Verifica email';

  @override
  String get verifyYourEmail => 'Verifica la tua email';

  @override
  String get emailVerifiedSuccessfully => 'Email verificata!';

  @override
  String get verificationCodeResent => 'Codice di verifica reinviato!';

  @override
  String get createNewPassword => 'Crea nuova password';

  @override
  String get enterNewPasswordBelow => 'Inserisci la nuova password qui sotto';

  @override
  String get newPassword => 'Nuova password';

  @override
  String get confirmPasswordLabel => 'Conferma password';

  @override
  String get pleaseFillAllFields => 'Compila tutti i campi';

  @override
  String get passwordResetSuccessful => 'Password reimpostata! Accedi con la nuova password';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get profileVisibility => 'Visibilità del profilo';

  @override
  String get showCountryRegion => 'Mostra paese/regione';

  @override
  String get showCountryRegionDesc => 'Mostra il tuo paese nel profilo';

  @override
  String get showCity => 'Mostra città';

  @override
  String get showCityDesc => 'Mostra la tua città nel profilo';

  @override
  String get showAge => 'Mostra età';

  @override
  String get showAgeDesc => 'Mostra la tua età nel profilo';

  @override
  String get showZodiacSign => 'Mostra segno zodiacale';

  @override
  String get showZodiacSignDesc => 'Mostra il tuo segno zodiacale nel profilo';

  @override
  String get onlineStatusSection => 'Stato online';

  @override
  String get showOnlineStatus => 'Mostra stato online';

  @override
  String get showOnlineStatusDesc => 'Permetti agli altri di vedere quando sei online';

  @override
  String get otherSettings => 'Altre impostazioni';

  @override
  String get showGiftingLevel => 'Mostra livello regali';

  @override
  String get showGiftingLevelDesc => 'Mostra il badge del livello regali';

  @override
  String get birthdayNotifications => 'Notifiche compleanno';

  @override
  String get birthdayNotificationsDesc => 'Ricevi notifiche per il tuo compleanno';

  @override
  String get personalizedAds => 'Annunci personalizzati';

  @override
  String get personalizedAdsDesc => 'Consenti annunci personalizzati';

  @override
  String get saveChanges => 'Salva modifiche';

  @override
  String get privacySettingsSaved => 'Impostazioni privacy salvate';

  @override
  String get locationSection => 'Posizione';

  @override
  String get updateLocation => 'Aggiorna posizione';

  @override
  String get updateLocationDesc => 'Aggiorna la tua posizione attuale';

  @override
  String get currentLocation => 'Posizione attuale';

  @override
  String get locationNotAvailable => 'Posizione non disponibile';

  @override
  String get locationUpdated => 'Posizione aggiornata con successo';

  @override
  String get locationPermissionDenied => 'Permesso posizione negato. Abilitalo nelle impostazioni.';

  @override
  String get locationServiceDisabled => 'I servizi di localizzazione sono disabilitati. Abilitali.';

  @override
  String get updatingLocation => 'Aggiornamento posizione...';

  @override
  String get locationCouldNotBeUpdated => 'Impossibile aggiornare la posizione';

  @override
  String get incomingAudioCall => 'Chiamata audio in arrivo';

  @override
  String get incomingVideoCall => 'Videochiamata in arrivo';

  @override
  String get outgoingCall => 'Chiamata in corso...';

  @override
  String get callRinging => 'Squilla...';

  @override
  String get callConnecting => 'Connessione...';

  @override
  String get callConnected => 'Connesso';

  @override
  String get callReconnecting => 'Riconnessione...';

  @override
  String get callEnded => 'Chiamata terminata';

  @override
  String get callFailed => 'Chiamata fallita';

  @override
  String get callMissed => 'Chiamata persa';

  @override
  String get callDeclined => 'Chiamata rifiutata';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => 'Accetta';

  @override
  String get declineCall => 'Rifiuta';

  @override
  String get endCall => 'Termina';

  @override
  String get muteCall => 'Muto';

  @override
  String get unmuteCall => 'Riattiva audio';

  @override
  String get speakerOn => 'Altoparlante';

  @override
  String get speakerOff => 'Auricolare';

  @override
  String get videoOn => 'Video attivo';

  @override
  String get videoOff => 'Video disattivo';

  @override
  String get switchCamera => 'Cambia fotocamera';

  @override
  String get callPermissionDenied => 'È richiesto il permesso del microfono per le chiamate';

  @override
  String get cameraPermissionDenied => 'È richiesto il permesso della fotocamera per le videochiamate';

  @override
  String get callConnectionFailed => 'Impossibile connettersi. Riprova.';

  @override
  String get userBusy => 'Utente occupato';

  @override
  String get userOffline => 'Utente offline';

  @override
  String get callHistory => 'Cronologia chiamate';

  @override
  String get noCallHistory => 'Nessuna cronologia chiamate';

  @override
  String get missedCalls => 'Chiamate perse';

  @override
  String get allCalls => 'Tutte le chiamate';

  @override
  String get callBack => 'Richiama';

  @override
  String callAt(String time) {
    return 'Chiamata alle $time';
  }

  @override
  String get audioCall => 'Chiamata audio';

  @override
  String get voiceRoom => 'Stanza vocale';

  @override
  String get noVoiceRooms => 'Nessuna stanza vocale attiva';

  @override
  String get createVoiceRoom => 'Crea stanza vocale';

  @override
  String get joinRoom => 'Entra nella stanza';

  @override
  String get leaveRoomConfirm => 'Uscire dalla stanza?';

  @override
  String get leaveRoomMessage => 'Sei sicuro di voler uscire da questa stanza?';

  @override
  String get roomTitle => 'Titolo stanza';

  @override
  String get roomTitleHint => 'Inserisci il titolo della stanza';

  @override
  String get roomTopic => 'Argomento';

  @override
  String get roomLanguage => 'Lingua';

  @override
  String get roomHost => 'Host';

  @override
  String roomParticipants(int count) {
    return '$count partecipanti';
  }

  @override
  String roomMaxParticipants(int count) {
    return 'Max $count partecipanti';
  }

  @override
  String get selectTopic => 'Seleziona argomento';

  @override
  String get raiseHand => 'Alza la mano';

  @override
  String get lowerHand => 'Abbassa la mano';

  @override
  String get handRaisedNotification => 'Mano alzata! L\'host vedrà la tua richiesta.';

  @override
  String get handLoweredNotification => 'Mano abbassata';

  @override
  String get muteParticipant => 'Silenzia partecipante';

  @override
  String get kickParticipant => 'Rimuovi dalla stanza';

  @override
  String get promoteToCoHost => 'Promuovi a co-host';

  @override
  String get endRoomConfirm => 'Terminare la stanza?';

  @override
  String get endRoomMessage => 'Questo terminerà la stanza per tutti i partecipanti.';

  @override
  String get roomEnded => 'Stanza terminata dall\'host';

  @override
  String get youWereRemoved => 'Sei stato rimosso dalla stanza';

  @override
  String get roomIsFull => 'La stanza è piena';

  @override
  String get roomChat => 'Chat della stanza';

  @override
  String get noMessages => 'Ancora nessun messaggio';

  @override
  String get typeMessage => 'Scrivi un messaggio...';

  @override
  String get voiceRoomsDescription => 'Partecipa a conversazioni dal vivo e pratica il parlato';

  @override
  String liveRoomsCount(int count) {
    return '$count Live';
  }

  @override
  String get noActiveRooms => 'Nessuna stanza attiva';

  @override
  String get noActiveRoomsDescription => 'Sii il primo a creare una stanza vocale e pratica con gli altri!';

  @override
  String get startRoom => 'Avvia stanza';

  @override
  String get createRoom => 'Crea stanza';

  @override
  String get roomCreated => 'Stanza creata con successo!';

  @override
  String get failedToCreateRoom => 'Creazione stanza fallita';

  @override
  String get errorLoadingRooms => 'Errore nel caricamento delle stanze';

  @override
  String get pleaseEnterRoomTitle => 'Inserisci un titolo per la stanza';

  @override
  String get startLiveConversation => 'Avvia una conversazione dal vivo';

  @override
  String get maxParticipants => 'Max partecipanti';

  @override
  String nPeople(int count) {
    return '$count persone';
  }
}
