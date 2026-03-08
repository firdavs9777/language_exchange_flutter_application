// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'BananaTalk';

  @override
  String get login => 'Anmelden';

  @override
  String get signUp => 'Registrieren';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get or => 'ODER';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get signInWithApple => 'Mit Apple anmelden';

  @override
  String get signInWithFacebook => 'Mit Facebook anmelden';

  @override
  String get welcome => 'Willkommen';

  @override
  String get home => 'Startseite';

  @override
  String get messages => 'Nachrichten';

  @override
  String get moments => 'Momente';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Einstellungen';

  @override
  String get logout => 'Abmelden';

  @override
  String get language => 'Sprache';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get autoTranslate => 'Automatisch übersetzen';

  @override
  String get autoTranslateMessages => 'Nachrichten automatisch übersetzen';

  @override
  String get autoTranslateMoments => 'Momente automatisch übersetzen';

  @override
  String get autoTranslateComments => 'Kommentare automatisch übersetzen';

  @override
  String get translate => 'Übersetzen';

  @override
  String get translated => 'Übersetzt';

  @override
  String get showOriginal => 'Original anzeigen';

  @override
  String get showTranslation => 'Übersetzung anzeigen';

  @override
  String get translating => 'Wird übersetzt...';

  @override
  String get translationFailed => 'Übersetzung fehlgeschlagen';

  @override
  String get noTranslationAvailable => 'Keine Übersetzung verfügbar';

  @override
  String translatedFrom(String language) {
    return 'Übersetzt aus $language';
  }

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get share => 'Teilen';

  @override
  String get like => 'Gefällt mir';

  @override
  String get comment => 'Kommentieren';

  @override
  String get send => 'Senden';

  @override
  String get search => 'Suchen';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get followers => 'Follower';

  @override
  String get following => 'Folge ich';

  @override
  String get posts => 'Beiträge';

  @override
  String get visitors => 'Besucher';

  @override
  String get loading => 'Wird geladen...';

  @override
  String get error => 'Fehler';

  @override
  String get success => 'Erfolg';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get networkError => 'Netzwerkfehler. Bitte überprüfen Sie Ihre Verbindung.';

  @override
  String get somethingWentWrong => 'Etwas ist schief gelaufen';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get languageSettings => 'Spracheinstellungen';

  @override
  String get deviceLanguage => 'Gerätesprache';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return 'Ihr Gerät ist eingestellt auf: $flag $name';
  }

  @override
  String get youCanOverride => 'Sie können die Gerätesprache unten überschreiben.';

  @override
  String languageChangedTo(String name) {
    return 'Sprache geändert zu $name';
  }

  @override
  String get errorChangingLanguage => 'Fehler beim Ändern der Sprache';

  @override
  String get autoTranslateSettings => 'Auto-Übersetzung Einstellungen';

  @override
  String get automaticallyTranslateIncomingMessages => 'Eingehende Nachrichten automatisch übersetzen';

  @override
  String get automaticallyTranslateMomentsInFeed => 'Momente im Feed automatisch übersetzen';

  @override
  String get automaticallyTranslateComments => 'Kommentare automatisch übersetzen';

  @override
  String get translationServiceBeingConfigured => 'Übersetzungsdienst wird konfiguriert. Bitte versuchen Sie es später erneut.';

  @override
  String get translationUnavailable => 'Übersetzung nicht verfügbar';

  @override
  String get showLess => 'weniger anzeigen';

  @override
  String get showMore => 'mehr anzeigen';

  @override
  String get comments => 'Kommentare';

  @override
  String get beTheFirstToComment => 'Sei der Erste, der kommentiert.';

  @override
  String get writeAComment => 'Schreibe einen Kommentar...';

  @override
  String get report => 'Melden';

  @override
  String get reportMoment => 'Moment melden';

  @override
  String get reportUser => 'Benutzer melden';

  @override
  String get deleteMoment => 'Moment löschen?';

  @override
  String get thisActionCannotBeUndone => 'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get momentDeleted => 'Moment gelöscht';

  @override
  String get editFeatureComingSoon => 'Bearbeitungsfunktion kommt bald';

  @override
  String get userNotFound => 'Benutzer nicht gefunden';

  @override
  String get cannotReportYourOwnComment => 'Sie können Ihren eigenen Kommentar nicht melden';

  @override
  String get profileSettings => 'Profileinstellungen';

  @override
  String get editYourProfileInformation => 'Bearbeiten Sie Ihre Profilinformationen';

  @override
  String get blockedUsers => 'Blockierte Benutzer';

  @override
  String get manageBlockedUsers => 'Blockierte Benutzer verwalten';

  @override
  String get manageNotificationSettings => 'Benachrichtigungseinstellungen verwalten';

  @override
  String get privacySecurity => 'Datenschutz & Sicherheit';

  @override
  String get controlYourPrivacy => 'Kontrollieren Sie Ihre Privatsphäre';

  @override
  String get changeAppLanguage => 'App-Sprache ändern';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get themeAndDisplaySettings => 'Design- und Anzeigeeinstellungen';

  @override
  String get myReports => 'Meine Meldungen';

  @override
  String get viewYourSubmittedReports => 'Ihre eingereichten Meldungen anzeigen';

  @override
  String get reportsManagement => 'Meldungsverwaltung';

  @override
  String get manageAllReportsAdmin => 'Alle Meldungen verwalten (Admin)';

  @override
  String get legalPrivacy => 'Rechtliches & Datenschutz';

  @override
  String get termsPrivacySubscriptionInfo => 'AGB, Datenschutz & Abo-Infos';

  @override
  String get helpCenter => 'Hilfecenter';

  @override
  String get getHelpAndSupport => 'Hilfe und Support erhalten';

  @override
  String get aboutBanaTalk => 'Über BanaTalk';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get permanentlyDeleteYourAccount => 'Ihr Konto dauerhaft löschen';

  @override
  String get loggedOutSuccessfully => 'Erfolgreich abgemeldet';

  @override
  String get retry => 'Wiederholen';

  @override
  String get giftsLikes => 'Geschenke/Likes';

  @override
  String get details => 'Details';

  @override
  String get to => 'an';

  @override
  String get banaTalk => 'BanaTalk';

  @override
  String get community => 'Community';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String yearsOld(String age) {
    return '$age Jahre alt';
  }

  @override
  String get searchConversations => 'Unterhaltungen suchen...';

  @override
  String get visitorTrackingNotAvailable => 'Besucherverfolgung ist noch nicht verfügbar. Backend-Update erforderlich.';

  @override
  String get chatList => 'Chat-Liste';

  @override
  String get languageExchange => 'Sprachaustausch';

  @override
  String get nativeLanguage => 'Muttersprache';

  @override
  String get learning => 'Lernen';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String get about => 'Über';

  @override
  String get aboutMe => 'Über mich';

  @override
  String get bloodType => 'Blutgruppe';

  @override
  String get photos => 'Fotos';

  @override
  String get camera => 'Kamera';

  @override
  String get createMoment => 'Moment erstellen';

  @override
  String get addATitle => 'Titel hinzufügen...';

  @override
  String get whatsOnYourMind => 'Was beschäftigt dich?';

  @override
  String get addTags => 'Tags hinzufügen';

  @override
  String get done => 'Fertig';

  @override
  String get add => 'Hinzufügen';

  @override
  String get enterTag => 'Tag eingeben';

  @override
  String get post => 'Posten';

  @override
  String get commentAddedSuccessfully => 'Kommentar erfolgreich hinzugefügt';

  @override
  String get clearFilters => 'Filter löschen';

  @override
  String get notificationSettings => 'Benachrichtigungseinstellungen';

  @override
  String get enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get turnAllNotificationsOnOrOff => 'Alle Benachrichtigungen ein- oder ausschalten';

  @override
  String get notificationTypes => 'Benachrichtigungstypen';

  @override
  String get chatMessages => 'Chat-Nachrichten';

  @override
  String get getNotifiedWhenYouReceiveMessages => 'Benachrichtigung bei neuen Nachrichten';

  @override
  String get likesAndCommentsOnYourMoments => 'Likes und Kommentare zu Ihren Momenten';

  @override
  String get whenPeopleYouFollowPostMoments => 'Wenn Personen, denen Sie folgen, Momente posten';

  @override
  String get friendRequests => 'Freundschaftsanfragen';

  @override
  String get whenSomeoneFollowsYou => 'Wenn jemand Ihnen folgt';

  @override
  String get profileVisits => 'Profilbesuche';

  @override
  String get whenSomeoneViewsYourProfileVIP => 'Wenn jemand Ihr Profil ansieht (VIP)';

  @override
  String get marketing => 'Marketing';

  @override
  String get updatesAndPromotionalMessages => 'Updates und Werbemitteilungen';

  @override
  String get notificationPreferences => 'Benachrichtigungseinstellungen';

  @override
  String get sound => 'Ton';

  @override
  String get playNotificationSounds => 'Benachrichtigungstöne abspielen';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrateOnNotifications => 'Bei Benachrichtigungen vibrieren';

  @override
  String get showPreview => 'Vorschau anzeigen';

  @override
  String get showMessagePreviewInNotifications => 'Nachrichtenvorschau in Benachrichtigungen anzeigen';

  @override
  String get mutedConversations => 'Stummgeschaltete Unterhaltungen';

  @override
  String get conversation => 'Unterhaltung';

  @override
  String get unmute => 'Stummschaltung aufheben';

  @override
  String get systemNotificationSettings => 'System-Benachrichtigungseinstellungen';

  @override
  String get manageNotificationsInSystemSettings => 'Benachrichtigungen in Systemeinstellungen verwalten';

  @override
  String get errorLoadingSettings => 'Fehler beim Laden der Einstellungen';

  @override
  String get unblockUser => 'Benutzer entsperren';

  @override
  String get unblock => 'Entsperren';

  @override
  String get goBack => 'Zurück';

  @override
  String get messageSendTimeout => 'Zeitüberschreitung beim Senden. Bitte überprüfen Sie Ihre Verbindung.';

  @override
  String get failedToSendMessage => 'Nachricht konnte nicht gesendet werden';

  @override
  String get dailyMessageLimitExceeded => 'Tägliches Nachrichtenlimit überschritten. Upgrade auf VIP für unbegrenzte Nachrichten.';

  @override
  String get cannotSendMessageUserMayBeBlocked => 'Nachricht kann nicht gesendet werden. Benutzer ist möglicherweise blockiert.';

  @override
  String get sessionExpired => 'Sitzung abgelaufen. Bitte melden Sie sich erneut an.';

  @override
  String get sendThisSticker => 'Diesen Sticker senden?';

  @override
  String get chooseHowYouWantToDeleteThisMessage => 'Wählen Sie, wie Sie diese Nachricht löschen möchten:';

  @override
  String get deleteForEveryone => 'Für alle löschen';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => 'Entfernt die Nachricht für Sie und den Empfänger';

  @override
  String get deleteForMe => 'Für mich löschen';

  @override
  String get removesTheMessageOnlyFromYourChat => 'Entfernt die Nachricht nur aus Ihrem Chat';

  @override
  String get copy => 'Kopieren';

  @override
  String get reply => 'Antworten';

  @override
  String get forward => 'Weiterleiten';

  @override
  String get moreOptions => 'Weitere Optionen';

  @override
  String get noUsersAvailableToForwardTo => 'Keine Benutzer zum Weiterleiten verfügbar';

  @override
  String get searchMoments => 'Momente suchen...';

  @override
  String searchInChatWith(String name) {
    return 'Im Chat mit $name suchen';
  }

  @override
  String get typeAMessage => 'Nachricht eingeben...';

  @override
  String get enterYourMessage => 'Geben Sie Ihre Nachricht ein';

  @override
  String get detectYourLocation => 'Standort ermitteln';

  @override
  String get tapToUpdateLocation => 'Tippen zum Aktualisieren des Standorts';

  @override
  String get helpOthersFindYouNearby => 'Helfen Sie anderen, Sie in der Nähe zu finden';

  @override
  String get selectYourNativeLanguage => 'Wählen Sie Ihre Muttersprache';

  @override
  String get whichLanguageDoYouWantToLearn => 'Welche Sprache möchten Sie lernen?';

  @override
  String get selectYourGender => 'Wählen Sie Ihr Geschlecht';

  @override
  String get addACaption => 'Bildunterschrift hinzufügen...';

  @override
  String get typeSomething => 'Etwas eingeben...';

  @override
  String get gallery => 'Galerie';

  @override
  String get video => 'Video';

  @override
  String get text => 'Text';

  @override
  String get provideMoreInformation => 'Weitere Informationen angeben...';

  @override
  String get searchByNameLanguageOrInterests => 'Nach Name, Sprache oder Interessen suchen...';

  @override
  String get addTagAndPressEnter => 'Tag hinzufügen und Enter drücken';

  @override
  String replyTo(String name) {
    return 'Antworten an $name...';
  }

  @override
  String get highlightName => 'Highlight-Name';

  @override
  String get searchCloseFriends => 'Enge Freunde suchen...';

  @override
  String get askAQuestion => 'Eine Frage stellen...';

  @override
  String option(String number) {
    return 'Option $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return 'Warum melden Sie diesen $type?';
  }

  @override
  String get additionalDetailsOptional => 'Zusätzliche Details (optional)';

  @override
  String get warningThisActionIsPermanent => 'Warnung: Diese Aktion ist dauerhaft!';

  @override
  String get deletingYourAccountWillPermanentlyRemove => 'Das Löschen Ihres Kontos entfernt dauerhaft:\n\n• Ihr Profil und alle persönlichen Daten\n• Alle Ihre Nachrichten und Unterhaltungen\n• Alle Ihre Momente und Stories\n• Ihr VIP-Abonnement (keine Rückerstattung)\n• Alle Ihre Verbindungen und Follower\n\nDiese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get clearAllNotifications => 'Alle Benachrichtigungen löschen?';

  @override
  String get clearAll => 'Alle löschen';

  @override
  String get notificationDebug => 'Benachrichtigungs-Debug';

  @override
  String get markAllRead => 'Alle als gelesen markieren';

  @override
  String get clearAll2 => 'Alle löschen';

  @override
  String get emailAddress => 'E-Mail-Adresse';

  @override
  String get username => 'Benutzername';

  @override
  String get alreadyHaveAnAccount => 'Haben Sie bereits ein Konto?';

  @override
  String get login2 => 'Anmelden';

  @override
  String get selectYourNativeLanguage2 => 'Wählen Sie Ihre Muttersprache';

  @override
  String get whichLanguageDoYouWantToLearn2 => 'Welche Sprache möchten Sie lernen?';

  @override
  String get selectYourGender2 => 'Wählen Sie Ihr Geschlecht';

  @override
  String get dateFormat => 'TT.MM.JJJJ';

  @override
  String get detectYourLocation2 => 'Standort ermitteln';

  @override
  String get tapToUpdateLocation2 => 'Tippen zum Aktualisieren des Standorts';

  @override
  String get helpOthersFindYouNearby2 => 'Helfen Sie anderen, Sie in der Nähe zu finden';

  @override
  String get couldNotOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get legalPrivacy2 => 'Rechtliches & Datenschutz';

  @override
  String get termsOfUseEULA => 'Nutzungsbedingungen (EULA)';

  @override
  String get viewOurTermsAndConditions => 'Unsere AGB ansehen';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get howWeHandleYourData => 'Wie wir mit Ihren Daten umgehen';

  @override
  String get emailNotifications => 'E-Mail-Benachrichtigungen';

  @override
  String get receiveEmailNotificationsFromBananaTalk => 'E-Mail-Benachrichtigungen von BananaTalk erhalten';

  @override
  String get weeklySummary => 'Wöchentliche Zusammenfassung';

  @override
  String get activityRecapEverySunday => 'Aktivitätszusammenfassung jeden Sonntag';

  @override
  String get newMessages => 'Neue Nachrichten';

  @override
  String get whenYoureAwayFor24PlusHours => 'Wenn Sie 24+ Stunden abwesend sind';

  @override
  String get newFollowers => 'Neue Follower';

  @override
  String get whenSomeoneFollowsYou2 => 'Wenn jemand Ihnen folgt';

  @override
  String get securityAlerts => 'Sicherheitswarnungen';

  @override
  String get passwordLoginAlerts => 'Passwort- und Anmeldewarnungen';

  @override
  String get unblockUser2 => 'Benutzer entsperren';

  @override
  String get blockedUsers2 => 'Blockierte Benutzer';

  @override
  String get finalWarning => 'Letzte Warnung';

  @override
  String get deleteForever => 'Dauerhaft löschen';

  @override
  String get deleteAccount2 => 'Konto löschen';

  @override
  String get enterYourPassword => 'Geben Sie Ihr Passwort ein';

  @override
  String get yourPassword => 'Ihr Passwort';

  @override
  String get typeDELETEToConfirm => 'Geben Sie LÖSCHEN zur Bestätigung ein';

  @override
  String get typeDELETEInCapitalLetters => 'Geben Sie LÖSCHEN in Großbuchstaben ein';

  @override
  String sent(String emoji) {
    return '$emoji gesendet!';
  }

  @override
  String get replySent => 'Antwort gesendet!';

  @override
  String get deleteStory => 'Story löschen?';

  @override
  String get thisStoryWillBeRemovedPermanently => 'Diese Story wird dauerhaft entfernt.';

  @override
  String get noStories => 'Keine Stories';

  @override
  String views(String count) {
    return '$count Aufrufe';
  }

  @override
  String get reportStory => 'Story melden';

  @override
  String get reply2 => 'Antworten...';

  @override
  String get failedToPickImage => 'Bild konnte nicht ausgewählt werden';

  @override
  String get failedToTakePhoto => 'Foto konnte nicht aufgenommen werden';

  @override
  String get failedToPickVideo => 'Video konnte nicht ausgewählt werden';

  @override
  String get pleaseEnterSomeText => 'Bitte geben Sie Text ein';

  @override
  String get pleaseSelectMedia => 'Bitte wählen Sie Medien aus';

  @override
  String get storyPosted => 'Story gepostet!';

  @override
  String get textOnlyStoriesRequireAnImage => 'Nur-Text-Stories benötigen ein Bild';

  @override
  String get createStory => 'Story erstellen';

  @override
  String get change => 'Ändern';

  @override
  String get userIdNotFound => 'Benutzer-ID nicht gefunden. Bitte melden Sie sich erneut an.';

  @override
  String get pleaseSelectAPaymentMethod => 'Bitte wählen Sie eine Zahlungsmethode';

  @override
  String get startExploring => 'Entdecken starten';

  @override
  String get close => 'Schließen';

  @override
  String get payment => 'Zahlung';

  @override
  String get upgradeToVIP => 'Auf VIP upgraden';

  @override
  String get errorLoadingProducts => 'Fehler beim Laden der Produkte';

  @override
  String get cancelVIPSubscription => 'VIP-Abonnement kündigen';

  @override
  String get keepVIP => 'VIP behalten';

  @override
  String get cancelSubscription => 'Abonnement kündigen';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'VIP-Abonnement erfolgreich gekündigt';

  @override
  String get vipStatus => 'VIP-Status';

  @override
  String get noActiveVIPSubscription => 'Kein aktives VIP-Abonnement';

  @override
  String get subscriptionExpired => 'Abonnement abgelaufen';

  @override
  String get vipExpiredMessage => 'Ihr VIP-Abonnement ist abgelaufen. Erneuern Sie jetzt, um weiterhin unbegrenzte Funktionen zu genießen!';

  @override
  String get expiredOn => 'Abgelaufen am';

  @override
  String get renewVIP => 'VIP erneuern';

  @override
  String get whatYoureMissing => 'Was Sie verpassen';

  @override
  String get manageInAppStore => 'Im App Store verwalten';

  @override
  String get becomeVIP => 'VIP werden';

  @override
  String get unlimitedMessages => 'Unbegrenzte Nachrichten';

  @override
  String get unlimitedProfileViews => 'Unbegrenzte Profilaufrufe';

  @override
  String get prioritySupport => 'Prioritäts-Support';

  @override
  String get advancedSearch => 'Erweiterte Suche';

  @override
  String get profileBoost => 'Profil-Boost';

  @override
  String get adFreeExperience => 'Werbefreies Erlebnis';

  @override
  String get upgradeYourAccount => 'Konto upgraden';

  @override
  String get moreMessages => 'Mehr Nachrichten';

  @override
  String get moreProfileViews => 'Mehr Profilaufrufe';

  @override
  String get connectWithFriends => 'Mit Freunden verbinden';

  @override
  String get reviewStarted => 'Überprüfung gestartet';

  @override
  String get reportResolved => 'Meldung gelöst';

  @override
  String get reportDismissed => 'Meldung abgewiesen';

  @override
  String get selectAction => 'Aktion auswählen';

  @override
  String get noViolation => 'Kein Verstoß';

  @override
  String get contentRemoved => 'Inhalt entfernt';

  @override
  String get userWarned => 'Benutzer gewarnt';

  @override
  String get userSuspended => 'Benutzer gesperrt';

  @override
  String get userBanned => 'Benutzer gebannt';

  @override
  String get addNotesOptional => 'Notizen hinzufügen (optional)';

  @override
  String get enterModeratorNotes => 'Moderatornotizen eingeben...';

  @override
  String get skip => 'Überspringen';

  @override
  String get startReview => 'Überprüfung starten';

  @override
  String get resolve => 'Lösen';

  @override
  String get dismiss => 'Abweisen';

  @override
  String get filterReports => 'Meldungen filtern';

  @override
  String get all => 'Alle';

  @override
  String get clear => 'Löschen';

  @override
  String get apply => 'Anwenden';

  @override
  String get myReports2 => 'Meine Meldungen';

  @override
  String get blockUser => 'Benutzer blockieren';

  @override
  String get block => 'Blockieren';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => 'Möchten Sie diesen Benutzer auch blockieren?';

  @override
  String get noThanks => 'Nein, danke';

  @override
  String get yesBlockThem => 'Ja, blockieren';

  @override
  String get reportUser2 => 'Benutzer melden';

  @override
  String get submitReport => 'Meldung senden';

  @override
  String get addAQuestionAndAtLeast2Options => 'Frage und mindestens 2 Optionen hinzufügen';

  @override
  String get addOption => 'Option hinzufügen';

  @override
  String get anonymousVoting => 'Anonyme Abstimmung';

  @override
  String get create => 'Erstellen';

  @override
  String get typeYourAnswer => 'Ihre Antwort eingeben...';

  @override
  String get send2 => 'Senden';

  @override
  String get yourPrompt => 'Ihre Frage...';

  @override
  String get add2 => 'Hinzufügen';

  @override
  String get contentNotAvailable => 'Inhalt nicht verfügbar';

  @override
  String get profileNotAvailable => 'Profil nicht verfügbar';

  @override
  String get noMomentsToShow => 'Keine Momente anzuzeigen';

  @override
  String get storiesNotAvailable => 'Stories nicht verfügbar';

  @override
  String get cantMessageThisUser => 'Kann diesem Benutzer keine Nachricht senden';

  @override
  String get pleaseSelectAReason => 'Bitte wählen Sie einen Grund';

  @override
  String get reportSubmitted => 'Meldung gesendet. Danke, dass Sie unsere Community sicher halten.';

  @override
  String get youHaveAlreadyReportedThisMoment => 'Sie haben diesen Moment bereits gemeldet';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => 'Erzählen Sie uns mehr, warum Sie dies melden';

  @override
  String get errorSharing => 'Fehler beim Teilen';

  @override
  String get deviceInfo => 'Geräteinformationen';

  @override
  String get recommended => 'Empfohlen';

  @override
  String get anyLanguage => 'Jede Sprache';

  @override
  String get noLanguagesFound => 'Keine Sprachen gefunden';

  @override
  String get selectALanguage => 'Sprache auswählen';

  @override
  String get languagesAreStillLoading => 'Sprachen werden noch geladen...';

  @override
  String get selectNativeLanguage => 'Muttersprache auswählen';

  @override
  String get subscriptionDetails => 'Abonnementdetails';

  @override
  String get activeFeatures => 'Aktive Funktionen';

  @override
  String get legalInformation => 'Rechtliche Informationen';

  @override
  String get termsOfUse => 'Nutzungsbedingungen';

  @override
  String get manageSubscription => 'Abonnement verwalten';

  @override
  String get manageSubscriptionInSettings => 'Um Ihr Abonnement zu kündigen, gehen Sie zu Einstellungen > [Ihr Name] > Abonnements auf Ihrem Gerät.';

  @override
  String get contactSupportToCancel => 'Um Ihr Abonnement zu kündigen, kontaktieren Sie bitte unser Support-Team.';

  @override
  String get status => 'Status';

  @override
  String get active => 'Aktiv';

  @override
  String get plan => 'Plan';

  @override
  String get startDate => 'Startdatum';

  @override
  String get endDate => 'Enddatum';

  @override
  String get nextBillingDate => 'Nächstes Abrechnungsdatum';

  @override
  String get autoRenew => 'Automatisch erneuern';

  @override
  String get pleaseLogInToContinue => 'Bitte melden Sie sich an, um fortzufahren';

  @override
  String get purchaseCanceledOrFailed => 'Kauf wurde abgebrochen oder ist fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get maximumTagsAllowed => 'Maximal 5 Tags erlaubt';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => 'Bitte entfernen Sie zuerst Bilder, um ein Video hinzuzufügen';

  @override
  String get unsupportedFormat => 'Nicht unterstütztes Format';

  @override
  String get errorProcessingVideo => 'Fehler bei der Videoverarbeitung';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'Bitte entfernen Sie zuerst Bilder, um ein Video aufzunehmen';

  @override
  String get locationAdded => 'Standort hinzugefügt';

  @override
  String get failedToGetLocation => 'Standort konnte nicht ermittelt werden';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get videoUploadFailed => 'Video-Upload fehlgeschlagen';

  @override
  String get skipVideo => 'Video überspringen';

  @override
  String get retryUpload => 'Upload wiederholen';

  @override
  String get momentCreatedSuccessfully => 'Moment erfolgreich erstellt';

  @override
  String get uploadingMomentInBackground => 'Moment wird im Hintergrund hochgeladen...';

  @override
  String get failedToQueueUpload => 'Upload konnte nicht in die Warteschlange gestellt werden';

  @override
  String get viewProfile => 'Profil anzeigen';

  @override
  String get mediaLinksAndDocs => 'Medien, Links und Dokumente';

  @override
  String get wallpaper => 'Hintergrundbild';

  @override
  String get userIdNotAvailable => 'Benutzer-ID nicht verfügbar';

  @override
  String get cannotBlockYourself => 'Sie können sich nicht selbst blockieren';

  @override
  String get chatWallpaper => 'Chat-Hintergrundbild';

  @override
  String get wallpaperSavedLocally => 'Hintergrundbild lokal gespeichert';

  @override
  String get messageCopied => 'Nachricht kopiert';

  @override
  String get forwardFeatureComingSoon => 'Weiterleitungsfunktion kommt bald';

  @override
  String get momentUnsaved => 'Moment nicht gespeichert';

  @override
  String get documentPickerComingSoon => 'Dokumentenauswahl kommt bald';

  @override
  String get contactSharingComingSoon => 'Kontaktfreigabe kommt bald';

  @override
  String get featureComingSoon => 'Funktion kommt bald';

  @override
  String get answerSent => 'Antwort gesendet!';

  @override
  String get noImagesAvailable => 'Keine Bilder verfügbar';

  @override
  String get mentionPickerComingSoon => 'Erwähnungsauswahl kommt bald';

  @override
  String get musicPickerComingSoon => 'Musikauswahl kommt bald';

  @override
  String get repostFeatureComingSoon => 'Repost-Funktion kommt bald';

  @override
  String get addFriendsFromYourProfile => 'Freunde über Ihr Profil hinzufügen';

  @override
  String get quickReplyAdded => 'Schnellantwort hinzugefügt';

  @override
  String get quickReplyDeleted => 'Schnellantwort gelöscht';

  @override
  String get linkCopied => 'Link kopiert!';

  @override
  String get maximumOptionsAllowed => 'Maximal 10 Optionen erlaubt';

  @override
  String get minimumOptionsRequired => 'Mindestens 2 Optionen erforderlich';

  @override
  String get pleaseEnterAQuestion => 'Bitte geben Sie eine Frage ein';

  @override
  String get pleaseAddAtLeast2Options => 'Bitte fügen Sie mindestens 2 Optionen hinzu';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => 'Bitte wählen Sie die richtige Antwort für das Quiz';

  @override
  String get correctionSent => 'Korrektur gesendet!';

  @override
  String get sort => 'Sortieren';

  @override
  String get savedMoments => 'Gespeicherte Momente';

  @override
  String get unsave => 'Nicht speichern';

  @override
  String get playingAudio => 'Audio wird abgespielt...';

  @override
  String get failedToGenerateQuiz => 'Quiz konnte nicht generiert werden';

  @override
  String get failedToAddComment => 'Kommentar konnte nicht hinzugefügt werden';

  @override
  String get hello => 'Hallo!';

  @override
  String get howAreYou => 'Wie geht es dir?';

  @override
  String get cannotOpen => 'Kann nicht öffnen';

  @override
  String get errorOpeningLink => 'Fehler beim Öffnen des Links';

  @override
  String get saved => 'Gespeichert';

  @override
  String get follow => 'Folgen';

  @override
  String get unfollow => 'Entfolgen';

  @override
  String get mute => 'Stummschalten';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get lastSeen => 'Zuletzt gesehen';

  @override
  String get justNow => 'gerade eben';

  @override
  String minutesAgo(String count) {
    return 'vor $count Minuten';
  }

  @override
  String hoursAgo(String count) {
    return 'vor $count Stunden';
  }

  @override
  String get yesterday => 'Gestern';

  @override
  String get signInWithEmail => 'Mit E-Mail anmelden';

  @override
  String get partners => 'Partner';

  @override
  String get nearby => 'In der Nähe';

  @override
  String get topics => 'Themen';

  @override
  String get waves => 'Winken';

  @override
  String get voiceRooms => 'Sprache';

  @override
  String get filters => 'Filter';

  @override
  String get searchCommunity => 'Nach Name, Sprache oder Interessen suchen...';

  @override
  String get bio => 'Bio';

  @override
  String get noBioYet => 'Noch keine Bio verfügbar.';

  @override
  String get languages => 'Sprachen';

  @override
  String get native => 'Muttersprache';

  @override
  String get interests => 'Interessen';

  @override
  String get noMomentsYet => 'Noch keine Momente';

  @override
  String get unableToLoadMoments => 'Momente können nicht geladen werden';

  @override
  String get map => 'Karte';

  @override
  String get mapUnavailable => 'Karte nicht verfügbar';

  @override
  String get location => 'Standort';

  @override
  String get unknownLocation => 'Unbekannter Standort';

  @override
  String get noImagesAvailable2 => 'Keine Bilder verfügbar';

  @override
  String get permissionsRequired => 'Berechtigungen erforderlich';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get videoCall => 'Video';

  @override
  String get voiceCall => 'Anruf';

  @override
  String get message => 'Nachricht';

  @override
  String get pleaseLoginToFollow => 'Bitte melden Sie sich an, um Benutzern zu folgen';

  @override
  String get pleaseLoginToCall => 'Bitte melden Sie sich an, um anzurufen';

  @override
  String get cannotCallYourself => 'Sie können sich nicht selbst anrufen';

  @override
  String get failedToFollowUser => 'Folgen fehlgeschlagen';

  @override
  String get failedToUnfollowUser => 'Entfolgen fehlgeschlagen';

  @override
  String get areYouSureUnfollow => 'Möchten Sie diesem Benutzer wirklich entfolgen?';

  @override
  String get areYouSureUnblock => 'Möchten Sie diesen Benutzer wirklich entsperren?';

  @override
  String get youFollowed => 'Sie folgen jetzt';

  @override
  String get youUnfollowed => 'Sie folgen nicht mehr';

  @override
  String get alreadyFollowing => 'Sie folgen bereits';

  @override
  String get soon => 'Bald';

  @override
  String comingSoon(String feature) {
    return '$feature kommt bald!';
  }

  @override
  String get muteNotifications => 'Benachrichtigungen stummschalten';

  @override
  String get unmuteNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get operationCompleted => 'Vorgang abgeschlossen';

  @override
  String get couldNotOpenMaps => 'Karten konnten nicht geöffnet werden';

  @override
  String hasntSharedMoments(Object name) {
    return '$name hat keine Momente geteilt';
  }

  @override
  String messageUser(String name) {
    return 'Nachricht an $name';
  }

  @override
  String notFollowingUser(String name) {
    return 'Sie folgten $name nicht';
  }

  @override
  String youFollowedUser(String name) {
    return 'Sie folgen jetzt $name';
  }

  @override
  String youUnfollowedUser(String name) {
    return 'Sie folgen $name nicht mehr';
  }

  @override
  String unfollowUser(String name) {
    return '$name entfolgen';
  }

  @override
  String get typing => 'schreibt';

  @override
  String get connecting => 'Verbinden...';

  @override
  String daysAgo(int count) {
    return 'vor ${count}T';
  }

  @override
  String get maxTagsAllowed => 'Maximal 5 Tags erlaubt';

  @override
  String maxImagesAllowed(int count) {
    return 'Maximal $count Bilder erlaubt';
  }

  @override
  String get pleaseRemoveImagesFirst => 'Bitte entfernen Sie zuerst Bilder, um ein Video hinzuzufügen';

  @override
  String get exchange3MessagesBeforeCall => 'Sie müssen mindestens 3 Nachrichten austauschen, bevor Sie diesen Benutzer anrufen können';

  @override
  String mediaWithUser(String name) {
    return 'Medien mit $name';
  }

  @override
  String get errorLoadingMedia => 'Fehler beim Laden der Medien';

  @override
  String get savedMomentsTitle => 'Gespeicherte Momente';

  @override
  String get removeBookmark => 'Lesezeichen entfernen?';

  @override
  String get thisWillRemoveBookmark => 'Dadurch wird die Nachricht aus Ihren Lesezeichen entfernt.';

  @override
  String get remove => 'Entfernen';

  @override
  String get bookmarkRemoved => 'Lesezeichen entfernt';

  @override
  String get bookmarkedMessages => 'Mit Lesezeichen versehene Nachrichten';

  @override
  String get wallpaperSaved => 'Hintergrundbild lokal gespeichert';

  @override
  String get typeDeleteToConfirm => 'Type DELETE to confirm';

  @override
  String get storyArchive => 'Story-Archiv';

  @override
  String get newHighlight => 'Neues Highlight';

  @override
  String get addToHighlight => 'Zu Highlight hinzufügen';

  @override
  String get repost => 'Reposten';

  @override
  String get repostFeatureSoon => 'Repost-Funktion kommt bald';

  @override
  String get closeFriends => 'Enge Freunde';

  @override
  String get addFriends => 'Freunde hinzufügen';

  @override
  String get highlights => 'Highlights';

  @override
  String get createHighlight => 'Highlight erstellen';

  @override
  String get deleteHighlight => 'Highlight löschen?';

  @override
  String get editHighlight => 'Highlight bearbeiten';

  @override
  String get addMoreToStory => 'Mehr zur Story hinzufügen';

  @override
  String get noViewersYet => 'Noch keine Zuschauer';

  @override
  String get noReactionsYet => 'Noch keine Reaktionen';

  @override
  String get leaveRoom => 'Raum verlassen?';

  @override
  String get areYouSureLeaveRoom => 'Möchten Sie diesen Sprachraum wirklich verlassen?';

  @override
  String get stay => 'Bleiben';

  @override
  String get leave => 'Verlassen';

  @override
  String get enableGPS => 'GPS aktivieren';

  @override
  String wavedToUser(String name) {
    return 'Sie haben $name zugewinkt!';
  }

  @override
  String get areYouSureFollow => 'Möchten Sie wirklich folgen';

  @override
  String get failedToLoadProfile => 'Profil konnte nicht geladen werden';

  @override
  String get noFollowersYet => 'Noch keine Follower';

  @override
  String get noFollowingYet => 'Folgt noch niemandem';

  @override
  String get searchUsers => 'Benutzer suchen...';

  @override
  String get noResultsFound => 'Keine Ergebnisse gefunden';

  @override
  String get loadingFailed => 'Laden fehlgeschlagen';

  @override
  String get copyLink => 'Link kopieren';

  @override
  String get shareStory => 'Story teilen';

  @override
  String get thisWillDeleteStory => 'Dadurch wird diese Story dauerhaft gelöscht.';

  @override
  String get storyDeleted => 'Story gelöscht';

  @override
  String get addCaption => 'Bildunterschrift hinzufügen...';

  @override
  String get yourStory => 'Ihre Story';

  @override
  String get sendMessage => 'Nachricht senden';

  @override
  String get replyToStory => 'Auf Story antworten...';

  @override
  String get viewAllReplies => 'Alle Antworten anzeigen';

  @override
  String get preparingVideo => 'Video wird vorbereitet...';

  @override
  String videoOptimized(String size, String savings) {
    return 'Video optimiert: ${size}MB (gespart $savings%)';
  }

  @override
  String get failedToProcessVideo => 'Video konnte nicht verarbeitet werden';

  @override
  String get optimizingForBestExperience => 'Optimierung für das beste Story-Erlebnis';

  @override
  String get pleaseSelectImageOrVideo => 'Bitte wählen Sie ein Bild oder Video für Ihre Story';

  @override
  String get storyCreatedSuccessfully => 'Story erfolgreich erstellt!';

  @override
  String get uploadingStoryInBackground => 'Story wird im Hintergrund hochgeladen...';

  @override
  String get storyCreationFailed => 'Story-Erstellung fehlgeschlagen';

  @override
  String get pleaseCheckConnection => 'Bitte überprüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get uploadFailed => 'Upload fehlgeschlagen';

  @override
  String get tryShorterVideo => 'Versuchen Sie ein kürzeres Video oder versuchen Sie es später erneut.';

  @override
  String get shareMomentsThatDisappear => 'Teilen Sie Momente, die in 24 Stunden verschwinden';

  @override
  String get photo => 'Foto';

  @override
  String get record => 'Aufnehmen';

  @override
  String get addSticker => 'Sticker hinzufügen';

  @override
  String get poll => 'Umfrage';

  @override
  String get question => 'Frage';

  @override
  String get mention => 'Erwähnung';

  @override
  String get music => 'Musik';

  @override
  String get hashtag => 'Hashtag';

  @override
  String get whoCanSeeThis => 'Wer kann das sehen?';

  @override
  String get everyone => 'Jeder';

  @override
  String get anyoneCanSeeStory => 'Jeder kann diese Story sehen';

  @override
  String get friendsOnly => 'Nur Freunde';

  @override
  String get onlyFollowersCanSee => 'Nur Ihre Follower können sehen';

  @override
  String get onlyCloseFriendsCanSee => 'Nur Ihre engen Freunde können sehen';

  @override
  String get backgroundColor => 'Hintergrundfarbe';

  @override
  String get fontStyle => 'Schriftstil';

  @override
  String get normal => 'Normal';

  @override
  String get bold => 'Fett';

  @override
  String get italic => 'Kursiv';

  @override
  String get handwriting => 'Handschrift';

  @override
  String get addLocation => 'Standort hinzufügen';

  @override
  String get enterLocationName => 'Standortname eingeben';

  @override
  String get addLink => 'Link hinzufügen';

  @override
  String get buttonText => 'Schaltflächentext';

  @override
  String get learnMore => 'Mehr erfahren';

  @override
  String get addHashtags => 'Hashtags hinzufügen';

  @override
  String get addHashtag => 'Hashtag hinzufügen';

  @override
  String get sendAsMessage => 'Als Nachricht senden';

  @override
  String get shareExternally => 'Extern teilen';

  @override
  String get checkOutStory => 'Schau dir diese Story auf BananaTalk an!';

  @override
  String viewsTab(String count) {
    return 'Aufrufe ($count)';
  }

  @override
  String reactionsTab(String count) {
    return 'Reaktionen ($count)';
  }

  @override
  String get processingVideo => 'Video wird verarbeitet...';

  @override
  String get link => 'Link';

  @override
  String unmuteUser(String name) {
    return '$name Stummschaltung aufheben?';
  }

  @override
  String get willReceiveNotifications => 'Sie erhalten Benachrichtigungen für neue Nachrichten.';

  @override
  String muteNotificationsFor(String name) {
    return 'Benachrichtigungen für $name stummschalten';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return 'Benachrichtigungen für $name aktiviert';
  }

  @override
  String notificationsMutedFor(String name) {
    return 'Benachrichtigungen für $name stummgeschaltet';
  }

  @override
  String get failedToUpdateMuteSettings => 'Stummschaltungseinstellungen konnten nicht aktualisiert werden';

  @override
  String get oneHour => '1 Stunde';

  @override
  String get eightHours => '8 Stunden';

  @override
  String get oneWeek => '1 Woche';

  @override
  String get always => 'Immer';

  @override
  String get failedToLoadBookmarks => 'Lesezeichen konnten nicht geladen werden';

  @override
  String get noBookmarkedMessages => 'Keine Nachrichten mit Lesezeichen';

  @override
  String get longPressToBookmark => 'Lange auf eine Nachricht drücken, um ein Lesezeichen zu setzen';

  @override
  String get thisWillRemoveFromBookmarks => 'Dadurch wird die Nachricht aus Ihren Lesezeichen entfernt.';

  @override
  String navigateToMessage(String name) {
    return 'Zur Nachricht im Chat mit $name navigieren';
  }

  @override
  String bookmarkedOn(String date) {
    return 'Lesezeichen gesetzt am $date';
  }

  @override
  String get voiceMessage => 'Sprachnachricht';

  @override
  String get document => 'Dokument';

  @override
  String get attachment => 'Anhang';

  @override
  String get sendMeAMessage => 'Schreib mir eine Nachricht';

  @override
  String get shareWithFriends => 'Mit Freunden teilen';

  @override
  String get shareAnywhere => 'Überall teilen';

  @override
  String get emailPreferences => 'E-Mail-Einstellungen';

  @override
  String get receiveEmailNotifications => 'E-Mail-Benachrichtigungen von BananaTalk erhalten';

  @override
  String get whenAwayFor24Hours => 'Wenn Sie 24+ Stunden abwesend sind';

  @override
  String get passwordAndLoginAlerts => 'Passwort- und Anmeldewarnungen';

  @override
  String get failedToLoadPreferences => 'Einstellungen konnten nicht geladen werden';

  @override
  String get failedToUpdateSetting => 'Einstellung konnte nicht aktualisiert werden';

  @override
  String get securityAlertsRecommended => 'Wir empfehlen, Sicherheitswarnungen aktiviert zu lassen, um über wichtige Kontoaktivitäten informiert zu bleiben.';

  @override
  String chatWallpaperFor(String name) {
    return 'Chat-Hintergrundbild für $name';
  }

  @override
  String get solidColors => 'Einfarbig';

  @override
  String get gradients => 'Farbverläufe';

  @override
  String get customImage => 'Benutzerdefiniertes Bild';

  @override
  String get chooseFromGallery => 'Aus Galerie auswählen';

  @override
  String get preview => 'Vorschau';

  @override
  String get wallpaperUpdated => 'Hintergrundbild aktualisiert';

  @override
  String get category => 'Kategorie';

  @override
  String get mood => 'Stimmung';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get timePeriod => 'Zeitraum';

  @override
  String get searchLanguages => 'Sprachen suchen...';

  @override
  String get selected => 'Ausgewählt';

  @override
  String get categories => 'Kategorien';

  @override
  String get moods => 'Stimmungen';

  @override
  String get applyFilters => 'Filter anwenden';

  @override
  String applyNFilters(int count) {
    return '$count Filter anwenden';
  }

  @override
  String get videoMustBeUnder1GB => 'Video muss unter 1GB sein.';

  @override
  String get failedToRecordVideo => 'Video konnte nicht aufgenommen werden';

  @override
  String get errorSendingVideo => 'Fehler beim Senden des Videos';

  @override
  String get errorSendingVoiceMessage => 'Fehler beim Senden der Sprachnachricht';

  @override
  String get errorSendingMedia => 'Fehler beim Senden der Medien';

  @override
  String get cameraPermissionRequired => 'Kamera- und Mikrofonberechtigungen sind für Videoaufnahmen erforderlich.';

  @override
  String get locationPermissionRequired => 'Standortberechtigung ist erforderlich, um Ihren Standort zu teilen.';

  @override
  String get noInternetConnection => 'Keine Internetverbindung';

  @override
  String get tryAgainLater => 'Bitte versuchen Sie es später erneut';

  @override
  String get messageSent => 'Nachricht gesendet';

  @override
  String get messageDeleted => 'Nachricht gelöscht';

  @override
  String get messageEdited => 'Nachricht bearbeitet';
}
