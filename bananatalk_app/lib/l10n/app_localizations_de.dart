// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'package:bananatalk_app/l10n/app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Bananatalk';

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
  String get more => 'mehr';

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
  String get overview => 'Übersicht';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Einstellungen';

  @override
  String get logout => 'Abmelden';

  @override
  String get language => 'Sprache';

  @override
  String get selectLanguage => 'Sprache wählen';

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
  String get deleteComment => 'Delete Comment?';

  @override
  String get commentDeleted => 'Comment deleted';

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
  String get clearCache => 'Cache leeren';

  @override
  String get clearCacheSubtitle => 'Speicherplatz freigeben';

  @override
  String get clearCacheDescription => 'Dadurch werden alle zwischengespeicherten Bilder, Videos und Audiodateien gelöscht. Die App lädt Inhalte möglicherweise vorübergehend langsamer, während Medien erneut heruntergeladen werden.';

  @override
  String get clearCacheHint => 'Verwenden Sie dies, wenn Bilder oder Audio nicht richtig geladen werden.';

  @override
  String get clearingCache => 'Cache wird geleert...';

  @override
  String get cacheCleared => 'Cache erfolgreich geleert! Bilder werden neu geladen.';

  @override
  String get clearCacheFailed => 'Cache konnte nicht geleert werden';

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
  String get aiTutorChangePersona => 'Change AI tutor';

  @override
  String get aiTutorChangePersonaSubtitle => 'Switch to Nana, Sensei or Riko';

  @override
  String aiTutorHeroTitleSet(String name) {
    return 'Your AI Tutor · $name';
  }

  @override
  String get aiTutorHeroTitleNew => 'Meet your AI Tutor';

  @override
  String get aiTutorHeroSubtitleSet => 'Tap to chat or see today\'s plan';

  @override
  String aiTutorHeroSubtitleLast(String summary) {
    return 'Last time: $summary';
  }

  @override
  String get aiTutorHeroSubtitleNew => 'Pick a persona — Nana, Sensei, or Riko';

  @override
  String get aiTutorChipChat => 'Chat';

  @override
  String get aiTutorChipRoleplay => 'Roleplay';

  @override
  String get aiTutorChipStory => 'Story';

  @override
  String get aiTutorChipPhoto => 'Photo';

  @override
  String get aiToolsMoreSection => 'More AI tools';

  @override
  String get aiConversationPartnerTile => 'AI Conversation';

  @override
  String get aiConversationPartnerTileSubtitle => 'Practice with an AI partner';

  @override
  String get aiTutorPickerTitle => 'Pick your AI tutor';

  @override
  String get aiTutorPickerHeader => 'Who do you want to learn with?';

  @override
  String get aiTutorPickerSubtitle => 'You can change this anytime in settings.';

  @override
  String get aiTutorPersonaNanaTagline => 'Warm + encouraging';

  @override
  String get aiTutorPersonaNanaSample => 'I\'ll cheer you on, no pressure.';

  @override
  String get aiTutorPersonaSenseiTagline => 'Precise + exam-focused';

  @override
  String get aiTutorPersonaSenseiSample => 'We will master the rules.';

  @override
  String get aiTutorPersonaRikoTagline => 'Playful + slangy';

  @override
  String get aiTutorPersonaRikoSample => 'lol let\'s vibe and learn';

  @override
  String aiTutorPickerSaveError(String error) {
    return 'Could not save: $error';
  }

  @override
  String get aiTutorHomeTitle => 'AI Tutor';

  @override
  String get aiTutorHomeChangeTutor => 'Change tutor';

  @override
  String get aiTutorHomeGreetingDefault => 'Hey! Ready to learn together?';

  @override
  String get aiTutorHomeTodaysPlan => 'Today\'s plan';

  @override
  String get aiTutorHomePlanEmpty => 'No plan for today — start a chat to begin.';

  @override
  String get aiTutorHomeStartChat => 'Start chat';

  @override
  String get aiTutorHomeRecent => 'Recent';

  @override
  String get aiTutorHomePracticeScenarios => 'Practice scenarios';

  @override
  String get aiTutorHomePracticeScenariosSubtitle => 'Roleplay real-world conversations — restaurant, interview, hotel…';

  @override
  String get aiTutorHomeReadStory => 'Read a story';

  @override
  String get aiTutorHomeReadStorySubtitle => 'AI writes a short story using your vocab — with quick comprehension checks.';

  @override
  String get aiTutorHomeDescribePhoto => 'Describe a photo';

  @override
  String get aiTutorHomeDescribePhotoSubtitle => 'Snap a picture and describe it — AI grades your vocab + grammar.';

  @override
  String get aiTutorChatTitle => 'Chat with tutor';

  @override
  String get aiTutorChatVoiceOn => 'Voice on';

  @override
  String get aiTutorChatVoiceOff => 'Voice off';

  @override
  String get aiTutorChatStopRecording => 'Stop recording';

  @override
  String get aiTutorChatHoldToTalk => 'Hold to talk';

  @override
  String get aiTutorChatTranscribing => 'Transcribing…';

  @override
  String get aiTutorChatListening => 'Listening…';

  @override
  String get aiTutorChatInputHint => 'Type a message…';

  @override
  String get aiTutorChatTypeReplyHint => 'Type your reply…';

  @override
  String get aiTutorChatMicPermissionDenied => 'Microphone permission needed for voice mode.';

  @override
  String get aiTutorChatTranscribeFailed => 'Didn\'t catch that — try again.';

  @override
  String aiTutorChatStartFailed(String error) {
    return 'Failed to start: $error';
  }

  @override
  String get aiTutorRoleplayEnd => 'End';

  @override
  String aiTutorRoleplayEndFailed(String error) {
    return 'End failed: $error';
  }

  @override
  String get aiTutorRoleplayDone => 'Done';

  @override
  String get aiTutorStoryTitle => 'Read a story';

  @override
  String get aiTutorStoryLength => 'Length';

  @override
  String get aiTutorStoryTheme => 'Theme';

  @override
  String aiTutorStoryWordCount(int count) {
    return '$count words';
  }

  @override
  String get aiTutorStoryWriting => 'Writing…';

  @override
  String get aiTutorStoryGenerate => 'Generate story';

  @override
  String aiTutorStoryGenerateFailed(String error) {
    return 'Could not generate: $error';
  }

  @override
  String aiTutorStoryWordCountHint(int n) {
    return 'The AI will use up to $n words from your vocab list.';
  }

  @override
  String get aiTutorStoryThemeFree => 'Free';

  @override
  String get aiTutorStoryThemeAdventure => 'Adventure';

  @override
  String get aiTutorStoryThemeMystery => 'Mystery';

  @override
  String get aiTutorStoryThemeRomance => 'Romance';

  @override
  String get aiTutorStoryThemeSciFi => 'Sci-fi';

  @override
  String get aiTutorStoryThemeSliceOfLife => 'Slice of life';

  @override
  String get aiTutorStoryReaderTitle => 'Story';

  @override
  String get aiTutorStoryReaderVocab => 'Vocabulary';

  @override
  String get aiTutorStoryReaderVocabUsed => 'Vocabulary used';

  @override
  String aiTutorStoryReaderPart(int n) {
    return 'Part $n';
  }

  @override
  String get aiTutorStoryReaderWrongHint => 'Not quite — moving on';

  @override
  String get aiTutorStoryReaderNiceWork => 'Nice work!';

  @override
  String aiTutorStoryReaderScore(int correct, int total) {
    return 'You got $correct/$total comprehension questions right.';
  }

  @override
  String get aiTutorStoryReaderDone => 'Done';

  @override
  String get aiTutorImageVocabTitle => 'Describe a photo';

  @override
  String get aiTutorImagePickHeader => 'Pick a photo to describe';

  @override
  String get aiTutorImagePickSubtitle => 'The AI will give you a prompt in your target language, then grade your description.';

  @override
  String get aiTutorImagePickCamera => 'Camera';

  @override
  String get aiTutorImagePickGallery => 'Gallery';

  @override
  String aiTutorImagePickError(String error) {
    return 'Could not open image: $error';
  }

  @override
  String get aiTutorImageDescriptionHint => 'Type your description…';

  @override
  String get aiTutorImageDifferentPhoto => 'Different photo';

  @override
  String get aiTutorImageSubmit => 'Submit';

  @override
  String get aiTutorImageGrammarNotes => 'Grammar notes';

  @override
  String get aiTutorImageThingsYouMissed => 'Things you missed';

  @override
  String get aiTutorImageTryAnother => 'Try another photo';

  @override
  String get aiTutorCardQuiz => 'Quiz';

  @override
  String get aiTutorCardVocab => 'Vocab';

  @override
  String get aiTutorCardGrammar => 'Grammar';

  @override
  String get aiTutorCardReviewDue => 'Review due';

  @override
  String get aiTutorCardMiniLesson => 'Mini-lesson';

  @override
  String get aiTutorCardAddToVocab => 'Add to vocab';

  @override
  String get aiTutorCardAddedToVocab => 'Added to vocab';

  @override
  String get aiTutorCardAdding => 'Adding…';

  @override
  String aiTutorCardReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards waiting for you',
      one: '$count card waiting for you',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorCardReviewNow => 'Review now';

  @override
  String get aiTutorCardReviewStarting => 'Starting…';

  @override
  String get aiTutorCardTryIt => 'Try it';

  @override
  String get aiTutorCardPracticing => 'Practicing…';

  @override
  String aiTutorPlanSrsReview(int count, int done) {
    return 'Review $count SRS cards ($done done)';
  }

  @override
  String aiTutorPlanGrammar(String topic) {
    return 'Practice: $topic';
  }

  @override
  String aiTutorPlanChat(int min, int done) {
    return 'Chat for $min min ($done so far)';
  }

  @override
  String get aboutBananatalk => 'Über Bananatalk';

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
  String get banaTalk => 'Bananatalk';

  @override
  String get chats => 'Chats';

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
  String get sessionExpired => 'Sitzung abgelaufen. Bitte erneut anmelden.';

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
  String get receiveEmailNotificationsFromBananatalk => 'E-Mail-Benachrichtigungen von Bananatalk erhalten';

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
  String get momentUnsaved => 'Aus Gespeicherten entfernt';

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
  String get addToHighlight => 'Zum Highlight hinzufügen';

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
  String get deleteHighlight => 'Highlight löschen';

  @override
  String get editHighlight => 'Highlight bearbeiten';

  @override
  String get addMoreToStory => 'Mehr zur Story hinzufügen';

  @override
  String get noViewersYet => 'Noch keine Zuschauer';

  @override
  String get noReactionsYet => 'Noch keine Reaktionen';

  @override
  String get leaveRoom => 'Raum verlassen';

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
  String get checkOutStory => 'Schau dir diese Story auf Bananatalk an!';

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
  String get receiveEmailNotifications => 'E-Mail-Benachrichtigungen von Bananatalk erhalten';

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
  String get videoMustBeUnder1GB => 'Das Video muss kleiner als 1 GB sein.';

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

  @override
  String get edited => '(bearbeitet)';

  @override
  String get now => 'jetzt';

  @override
  String weeksAgo(int count) {
    return 'vor ${count}W';
  }

  @override
  String viewRepliesCount(int count) {
    return '── $count Antworten anzeigen';
  }

  @override
  String get hideReplies => '── Antworten ausblenden';

  @override
  String get saveMoment => 'Moment speichern';

  @override
  String get removeFromSaved => 'Aus Gespeicherten entfernen';

  @override
  String get momentSaved => 'Gespeichert';

  @override
  String get failedToSave => 'Speichern fehlgeschlagen';

  @override
  String get checkOutMoment => 'Schau dir diesen Moment auf Bananatalk an!';

  @override
  String get failedToLoadMoments => 'Momente konnten nicht geladen werden';

  @override
  String get noMomentsMatchFilters => 'Keine Momente entsprechen deinen Filtern';

  @override
  String get beFirstToShareMoment => 'Sei der Erste, der einen Moment teilt!';

  @override
  String get tryDifferentSearch => 'Versuche einen anderen Suchbegriff';

  @override
  String get tryAdjustingFilters => 'Versuche deine Filter anzupassen';

  @override
  String get noSavedMoments => 'Keine gespeicherten Momente';

  @override
  String get tapBookmarkToSave => 'Tippe auf das Lesezeichen-Symbol, um einen Moment zu speichern';

  @override
  String get failedToLoadVideo => 'Video konnte nicht geladen werden';

  @override
  String get titleRequired => 'Titel ist erforderlich';

  @override
  String titleTooLong(int max) {
    return 'Titel darf maximal $max Zeichen haben';
  }

  @override
  String get descriptionRequired => 'Beschreibung ist erforderlich';

  @override
  String descriptionTooLong(int max) {
    return 'Beschreibung darf maximal $max Zeichen haben';
  }

  @override
  String get scheduledDateMustBeFuture => 'Geplantes Datum muss in der Zukunft liegen';

  @override
  String get recent => 'Neueste';

  @override
  String get popular => 'Beliebt';

  @override
  String get trending => 'Trending';

  @override
  String get mostRecent => 'Neueste';

  @override
  String get mostPopular => 'Beliebteste';

  @override
  String get allTime => 'Alle Zeit';

  @override
  String get today => 'Heute';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get thisMonth => 'Diesen Monat';

  @override
  String replyingTo(String userName) {
    return 'Antwort an $userName';
  }

  @override
  String get listView => 'Listenansicht';

  @override
  String get quickMatch => 'Schnellzuordnung';

  @override
  String get onlineNow => 'Jetzt online';

  @override
  String speaksLanguage(String language) {
    return 'Spricht $language';
  }

  @override
  String learningLanguage(String language) {
    return 'Lernt $language';
  }

  @override
  String get noPartnersFound => 'Keine Partner gefunden';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return 'Keine Benutzer für $learning und $native gefunden';
  }

  @override
  String get removeAllFilters => 'Alle Filter entfernen';

  @override
  String get browseAllUsers => 'Alle Benutzer durchsuchen';

  @override
  String get allCaughtUp => 'Du bist auf dem neuesten Stand!';

  @override
  String get loadingMore => 'Mehr laden...';

  @override
  String get findingMorePartners => 'Weitere Partner suchen...';

  @override
  String get seenAllPartners => 'Du hast alle Partner gesehen';

  @override
  String get startOver => 'Von vorne beginnen';

  @override
  String get changeFilters => 'Filter ändern';

  @override
  String get findingPartners => 'Partner suchen...';

  @override
  String get setLocationReminder => 'Lege deinen Standort fest, um Partner in der Nähe zu finden';

  @override
  String get updateLocationReminder => 'Aktualisiere deinen Standort für bessere Ergebnisse';

  @override
  String get male => 'Männlich';

  @override
  String get female => 'Weiblich';

  @override
  String get other => 'Andere';

  @override
  String get browseMen => 'Männer durchsuchen';

  @override
  String get browseWomen => 'Frauen durchsuchen';

  @override
  String get noMaleUsersFound => 'Keine männlichen Benutzer gefunden';

  @override
  String get noFemaleUsersFound => 'Keine weiblichen Benutzer gefunden';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => 'Nur neue Benutzer';

  @override
  String get showNewUsers => 'Neue Benutzer anzeigen';

  @override
  String get prioritizeNearby => 'Nahe bevorzugen';

  @override
  String get showNearbyFirst => 'Nahe zuerst anzeigen';

  @override
  String get setLocationToEnable => 'Standort festlegen zum Aktivieren';

  @override
  String get radius => 'Radius';

  @override
  String get findingYourLocation => 'Standort wird ermittelt...';

  @override
  String get enableLocationForDistance => 'Standort aktivieren, um Entfernungen zu sehen';

  @override
  String get enableLocationDescription => 'Erlaube den Standortzugriff, um Sprachpartner in deiner Nähe zu finden';

  @override
  String get enableGps => 'GPS aktivieren';

  @override
  String get browseByCityCountry => 'Nach Stadt oder Land suchen';

  @override
  String get peopleNearby => 'Personen in der Nähe';

  @override
  String get noNearbyUsersFound => 'Keine Benutzer in der Nähe gefunden';

  @override
  String get tryExpandingSearch => 'Versuche, deine Suche zu erweitern';

  @override
  String get exploreByCity => 'Nach Stadt erkunden';

  @override
  String get exploreByCurrentCity => 'Nach aktueller Stadt erkunden';

  @override
  String get interactiveWorldMap => 'Interaktive Weltkarte';

  @override
  String get searchByCityName => 'Nach Stadtname suchen';

  @override
  String get seeUserCountsPerCountry => 'Benutzeranzahl pro Land anzeigen';

  @override
  String get upgradeToVip => 'Auf VIP upgraden';

  @override
  String get searchByCity => 'Nach Stadt suchen';

  @override
  String usersWorldwide(String count) {
    return '$count Benutzer weltweit';
  }

  @override
  String get noUsersFound => 'Keine Benutzer gefunden';

  @override
  String get tryDifferentCity => 'Versuche eine andere Stadt';

  @override
  String usersCount(String count) {
    return '$count Benutzer';
  }

  @override
  String get searchCountry => 'Land suchen...';

  @override
  String get wave => 'Winken';

  @override
  String get newUser => 'Neu';

  @override
  String get warningPermanent => 'Warnung: Diese Aktion ist dauerhaft!';

  @override
  String get deleteAccountWarning => 'Das Löschen deines Kontos entfernt dauerhaft alle deine Daten, Nachrichten, Momente und Verbindungen. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get requiredForEmailOnly => 'Nur für E-Mail-Konten erforderlich';

  @override
  String get pleaseEnterPassword => 'Bitte gib dein Passwort ein';

  @override
  String get typeDELETE => 'Gib DELETE ein';

  @override
  String get mustTypeDELETE => 'Du musst DELETE eingeben, um zu bestätigen';

  @override
  String get deletingAccount => 'Konto wird gelöscht...';

  @override
  String get deleteMyAccountPermanently => 'Mein Konto dauerhaft löschen';

  @override
  String get whatsYourNativeLanguage => 'Was ist deine Muttersprache?';

  @override
  String get helpsMatchWithLearners => 'Hilft, dich mit Lernenden deiner Sprache zu verbinden';

  @override
  String get whatAreYouLearning => 'Was lernst du?';

  @override
  String get connectWithNativeSpeakers => 'Verbinde dich mit Muttersprachlern';

  @override
  String get selectLearningLanguage => 'Wähle die Sprache, die du lernst';

  @override
  String get selectCurrentLevel => 'Wähle dein aktuelles Niveau';

  @override
  String get beginner => 'Anfänger';

  @override
  String get elementary => 'Grundkenntnisse';

  @override
  String get intermediate => 'Mittelstufe';

  @override
  String get upperIntermediate => 'Gehobene Mittelstufe';

  @override
  String get advanced => 'Fortgeschritten';

  @override
  String get proficient => 'Fließend';

  @override
  String get showingPartnersByDistance => 'Partner nach Entfernung anzeigen';

  @override
  String get enableLocationForResults => 'Standort aktivieren für Ergebnisse';

  @override
  String get enable => 'Aktivieren';

  @override
  String get locationNotSet => 'Standort nicht festgelegt';

  @override
  String get tellUsAboutYourself => 'Erzähl uns etwas über dich';

  @override
  String get justACoupleQuickThings => 'Nur ein paar kurze Fragen';

  @override
  String get gender => 'Geschlecht';

  @override
  String get birthDate => 'Geburtsdatum';

  @override
  String get selectYourBirthDate => 'Wähle dein Geburtsdatum';

  @override
  String get continueButton => 'Weiter';

  @override
  String get pleaseSelectGender => 'Bitte wähle dein Geschlecht';

  @override
  String get pleaseSelectBirthDate => 'Bitte wähle dein Geburtsdatum';

  @override
  String get mustBe18 => 'Du musst mindestens 18 Jahre alt sein';

  @override
  String get invalidDate => 'Ungültiges Datum';

  @override
  String get almostDone => 'Fast geschafft!';

  @override
  String get addPhotoLocationForMatches => 'Füge ein Foto und deinen Standort hinzu für bessere Treffer';

  @override
  String get addProfilePhoto => 'Profilfoto hinzufügen';

  @override
  String get optionalUpTo6Photos => 'Optional — bis zu 6 Fotos';

  @override
  String get requiredUpTo6Photos => 'Erforderlich — bis zu 6 Fotos';

  @override
  String get profilePhotoRequired => 'Bitte füge mindestens ein Profilfoto hinzu';

  @override
  String get locationOptional => 'Standort ist optional — du kannst ihn später hinzufügen';

  @override
  String get maximum6Photos => 'Maximal 6 Fotos';

  @override
  String get tapToDetectLocation => 'Tippen, um Standort zu erkennen';

  @override
  String get optionalHelpsNearbyPartners => 'Optional — hilft, Partner in der Nähe zu finden';

  @override
  String get startLearning => 'Lernen beginnen';

  @override
  String get photoLocationOptional => 'Foto und Standort sind optional';

  @override
  String get pleaseAcceptTerms => 'Bitte akzeptiere die Nutzungsbedingungen';

  @override
  String get iAgreeToThe => 'Ich stimme den';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get tapToSelectLanguage => 'Tippen, um Sprache auszuwählen';

  @override
  String yourLevelIn(String language) {
    return 'Dein Niveau in $language';
  }

  @override
  String get yourCurrentLevel => 'Dein aktuelles Niveau';

  @override
  String get nativeCannotBeSameAsLearning => 'Muttersprache darf nicht gleich der Lernsprache sein';

  @override
  String get learningCannotBeSameAsNative => 'Lernsprache darf nicht gleich der Muttersprache sein';

  @override
  String stepOf(String current, String total) {
    return 'Schritt $current von $total';
  }

  @override
  String get continueWithGoogle => 'Weiter mit Google';

  @override
  String get registerLink => 'Registrieren';

  @override
  String get pleaseEnterBothEmailAndPassword => 'Bitte E-Mail und Passwort eingeben';

  @override
  String get pleaseEnterValidEmail => 'Bitte gültige E-Mail eingeben';

  @override
  String get loginSuccessful => 'Anmeldung erfolgreich!';

  @override
  String get stepOneOfTwo => 'Schritt 1 von 2';

  @override
  String get createYourAccount => 'Konto erstellen';

  @override
  String get basicInfoToGetStarted => 'Grundlegende Infos zum Starten';

  @override
  String get emailVerifiedLabel => 'E-Mail (Verifiziert)';

  @override
  String get nameLabel => 'Name';

  @override
  String get yourDisplayName => 'Dein Anzeigename';

  @override
  String get atLeast8Characters => 'Mindestens 8 Zeichen';

  @override
  String get confirmPasswordHint => 'Passwort bestätigen';

  @override
  String get nextButton => 'Weiter';

  @override
  String get pleaseEnterYourName => 'Bitte gib deinen Namen ein';

  @override
  String get pleaseEnterAPassword => 'Bitte gib ein Passwort ein';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get otherGender => 'Andere';

  @override
  String get continueWithGoogleAccount => 'Weiter mit deinem Google-Konto\nfür ein nahtloses Erlebnis';

  @override
  String get signingYouIn => 'Anmeldung läuft...';

  @override
  String get backToSignInMethods => 'Zurück zu Anmeldemethoden';

  @override
  String get securedByGoogle => 'Gesichert durch Google';

  @override
  String get dataProtectedEncryption => 'Deine Daten sind mit Standardverschlüsselung geschützt';

  @override
  String get welcomeCompleteProfile => 'Willkommen! Bitte vervollständige dein Profil';

  @override
  String welcomeBackName(String name) {
    return 'Willkommen zurück, $name!';
  }

  @override
  String get continueWithAppleId => 'Weiter mit deiner Apple ID\nfür ein sicheres Erlebnis';

  @override
  String get continueWithApple => 'Weiter mit Apple';

  @override
  String get securedByApple => 'Gesichert durch Apple';

  @override
  String get privacyProtectedApple => 'Deine Privatsphäre ist mit Apple Sign-In geschützt';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get enterEmailToGetStarted => 'E-Mail eingeben zum Starten';

  @override
  String get continueText => 'Weiter';

  @override
  String get pleaseEnterEmailAddress => 'Bitte gib deine E-Mail-Adresse ein';

  @override
  String get verificationCodeSent => 'Bestätigungscode gesendet!';

  @override
  String get forgotPasswordTitle => 'Passwort vergessen';

  @override
  String get resetPasswordTitle => 'Passwort zurücksetzen';

  @override
  String get enterEmailForResetCode => 'Gib deine E-Mail ein und wir senden dir einen Code zum Zurücksetzen';

  @override
  String get sendResetCode => 'Code senden';

  @override
  String get resetCodeSent => 'Code zum Zurücksetzen gesendet!';

  @override
  String get rememberYourPassword => 'Erinnerst du dich an dein Passwort?';

  @override
  String get verifyCode => 'Code überprüfen';

  @override
  String get enterResetCode => 'Code eingeben';

  @override
  String get weSentCodeTo => 'Wir haben einen 6-stelligen Code gesendet an';

  @override
  String get pleaseEnterAll6Digits => 'Bitte alle 6 Ziffern eingeben';

  @override
  String get codeVerifiedCreatePassword => 'Code bestätigt! Erstelle dein neues Passwort';

  @override
  String get verify => 'Überprüfen';

  @override
  String get didntReceiveCode => 'Code nicht erhalten?';

  @override
  String get resend => 'Erneut senden';

  @override
  String resendWithTimer(String timer) {
    return 'Erneut senden (${timer}s)';
  }

  @override
  String get resetCodeResent => 'Code erneut gesendet!';

  @override
  String get verifyEmail => 'E-Mail bestätigen';

  @override
  String get verifyYourEmail => 'Bestätige deine E-Mail';

  @override
  String get emailVerifiedSuccessfully => 'E-Mail erfolgreich bestätigt!';

  @override
  String get verificationCodeResent => 'Bestätigungscode erneut gesendet!';

  @override
  String get createNewPassword => 'Neues Passwort erstellen';

  @override
  String get enterNewPasswordBelow => 'Gib dein neues Passwort ein';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get confirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get pleaseFillAllFields => 'Bitte alle Felder ausfüllen';

  @override
  String get passwordResetSuccessful => 'Passwort zurückgesetzt! Melde dich mit deinem neuen Passwort an';

  @override
  String get privacyTitle => 'Datenschutz';

  @override
  String get profileVisibility => 'Profil-Sichtbarkeit';

  @override
  String get showCountryRegion => 'Land/Region anzeigen';

  @override
  String get showCountryRegionDesc => 'Zeigt dein Land in deinem Profil an';

  @override
  String get showCity => 'Stadt anzeigen';

  @override
  String get showCityDesc => 'Zeigt deine Stadt in deinem Profil an';

  @override
  String get showAge => 'Alter anzeigen';

  @override
  String get showAgeDesc => 'Zeigt dein Alter in deinem Profil an';

  @override
  String get showZodiacSign => 'Sternzeichen anzeigen';

  @override
  String get showZodiacSignDesc => 'Zeigt dein Sternzeichen in deinem Profil an';

  @override
  String get onlineStatusSection => 'Online-Status';

  @override
  String get showOnlineStatus => 'Online-Status anzeigen';

  @override
  String get showOnlineStatusDesc => 'Andere sehen lassen, wenn du online bist';

  @override
  String get otherSettings => 'Andere Einstellungen';

  @override
  String get showGiftingLevel => 'Geschenk-Level anzeigen';

  @override
  String get showGiftingLevelDesc => 'Zeigt dein Geschenk-Level-Abzeichen an';

  @override
  String get birthdayNotifications => 'Geburtstags-Benachrichtigungen';

  @override
  String get birthdayNotificationsDesc => 'Benachrichtigungen an deinem Geburtstag erhalten';

  @override
  String get personalizedAds => 'Personalisierte Werbung';

  @override
  String get personalizedAdsDesc => 'Personalisierte Werbung erlauben';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get privacySettingsSaved => 'Datenschutzeinstellungen gespeichert';

  @override
  String get locationSection => 'Standort';

  @override
  String get updateLocation => 'Standort aktualisieren';

  @override
  String get updateLocationDesc => 'Aktuellen Standort aktualisieren';

  @override
  String get currentLocation => 'Aktueller Standort';

  @override
  String get locationNotAvailable => 'Standort nicht verfügbar';

  @override
  String get locationUpdated => 'Standort erfolgreich aktualisiert';

  @override
  String get locationPermissionDenied => 'Standortberechtigung verweigert. Bitte in den Einstellungen aktivieren.';

  @override
  String get locationServiceDisabled => 'Standortdienste sind deaktiviert. Bitte aktivieren.';

  @override
  String get updatingLocation => 'Standort wird aktualisiert...';

  @override
  String get locationCouldNotBeUpdated => 'Standort konnte nicht aktualisiert werden';

  @override
  String get incomingAudioCall => 'Eingehender Audioanruf';

  @override
  String get incomingVideoCall => 'Eingehender Videoanruf';

  @override
  String get outgoingCall => 'Rufe an...';

  @override
  String get callRinging => 'Klingelt...';

  @override
  String get callConnecting => 'Verbinde...';

  @override
  String get callConnected => 'Verbunden';

  @override
  String get callReconnecting => 'Verbinde erneut...';

  @override
  String get callEnded => 'Anruf beendet';

  @override
  String get callFailed => 'Anruf fehlgeschlagen';

  @override
  String get callMissed => 'Verpasster Anruf';

  @override
  String get callDeclined => 'Anruf abgelehnt';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => 'Annehmen';

  @override
  String get declineCall => 'Ablehnen';

  @override
  String get endCall => 'Beenden';

  @override
  String get muteCall => 'Stumm';

  @override
  String get unmuteCall => 'Ton an';

  @override
  String get speakerOn => 'Lautsprecher';

  @override
  String get speakerOff => 'Ohrhörer';

  @override
  String get videoOn => 'Video an';

  @override
  String get videoOff => 'Video aus';

  @override
  String get switchCamera => 'Kamera wechseln';

  @override
  String get callPermissionDenied => 'Mikrofonberechtigung für Anrufe erforderlich';

  @override
  String get cameraPermissionDenied => 'Kameraberechtigung für Videoanrufe erforderlich';

  @override
  String get callConnectionFailed => 'Verbindung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get userBusy => 'Benutzer ist beschäftigt';

  @override
  String get userOffline => 'Benutzer ist offline';

  @override
  String get callHistory => 'Anrufverlauf';

  @override
  String get noCallHistory => 'Keine Anrufe';

  @override
  String get missedCalls => 'Verpasste Anrufe';

  @override
  String get allCalls => 'Alle Anrufe';

  @override
  String get callBack => 'Zurückrufen';

  @override
  String callAt(String time) {
    return 'Anruf um $time';
  }

  @override
  String get audioCall => 'Audioanruf';

  @override
  String get voiceRoom => 'Sprachraum';

  @override
  String get noVoiceRooms => 'Keine aktiven Sprachräume';

  @override
  String get createVoiceRoom => 'Sprachraum erstellen';

  @override
  String get joinRoom => 'Raum beitreten';

  @override
  String get leaveRoomConfirm => 'Raum verlassen?';

  @override
  String get leaveRoomMessage => 'Möchtest du diesen Raum wirklich verlassen?';

  @override
  String get roomTitle => 'Raumtitel';

  @override
  String get roomTitleHint => 'Raumtitel eingeben';

  @override
  String get roomTopic => 'Thema';

  @override
  String get roomLanguage => 'Sprache';

  @override
  String get roomHost => 'Gastgeber';

  @override
  String roomParticipants(int count) {
    return '$count Teilnehmer';
  }

  @override
  String roomMaxParticipants(int count) {
    return 'Max. $count Teilnehmer';
  }

  @override
  String get selectTopic => 'Thema wählen';

  @override
  String get raiseHand => 'Hand heben';

  @override
  String get lowerHand => 'Hand senken';

  @override
  String get handRaisedNotification => 'Hand gehoben! Der Gastgeber sieht deine Anfrage.';

  @override
  String get handLoweredNotification => 'Hand gesenkt';

  @override
  String get muteParticipant => 'Teilnehmer stummschalten';

  @override
  String get kickParticipant => 'Aus Raum entfernen';

  @override
  String get promoteToCoHost => 'Zum Co-Host machen';

  @override
  String get endRoomConfirm => 'Raum beenden?';

  @override
  String get endRoomMessage => 'Dies beendet den Raum für alle Teilnehmer.';

  @override
  String get roomEnded => 'Raum vom Gastgeber beendet';

  @override
  String get youWereRemoved => 'Du wurdest aus dem Raum entfernt';

  @override
  String get roomIsFull => 'Raum ist voll';

  @override
  String get roomChat => 'Raum-Chat';

  @override
  String get noMessages => 'Noch keine Nachrichten';

  @override
  String get typeMessage => 'Nachricht eingeben...';

  @override
  String get voiceRoomsDescription => 'Nimm an Live-Gesprächen teil und übe das Sprechen';

  @override
  String liveRoomsCount(int count) {
    return '$count Live';
  }

  @override
  String get noActiveRooms => 'Keine aktiven Räume';

  @override
  String get noActiveRoomsDescription => 'Sei der Erste, der einen Sprachraum startet und übe mit anderen!';

  @override
  String get startRoom => 'Raum starten';

  @override
  String get createRoom => 'Raum erstellen';

  @override
  String get roomCreated => 'Raum erfolgreich erstellt!';

  @override
  String get failedToCreateRoom => 'Raum erstellen fehlgeschlagen';

  @override
  String get errorLoadingRooms => 'Fehler beim Laden der Räume';

  @override
  String get pleaseEnterRoomTitle => 'Bitte Raumtitel eingeben';

  @override
  String get startLiveConversation => 'Live-Gespräch starten';

  @override
  String get maxParticipants => 'Max. Teilnehmer';

  @override
  String nPeople(int count) {
    return '$count Personen';
  }

  @override
  String hostedBy(String name) {
    return 'Gehostet von $name';
  }

  @override
  String get liveLabel => 'LIVE';

  @override
  String get joinLabel => 'Beitreten';

  @override
  String get fullLabel => 'Voll';

  @override
  String get justStarted => 'Gerade gestartet';

  @override
  String get allLanguages => 'Alle Sprachen';

  @override
  String get allTopics => 'Alle Themen';

  @override
  String get allCategories => 'Alle Kategorien';

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
  String get you => 'Du';

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
  String get dataAndStorage => 'Daten und Speicher';

  @override
  String get manageStorageAndDownloads => 'Speicher und Downloads verwalten';

  @override
  String get storageUsage => 'Speichernutzung';

  @override
  String get totalCacheSize => 'Gesamte Cache-Größe';

  @override
  String get imageCache => 'Bilder-Cache';

  @override
  String get voiceMessagesCache => 'Sprachnachrichten';

  @override
  String get videoCache => 'Video-Cache';

  @override
  String get otherCache => 'Anderer Cache';

  @override
  String get autoDownloadMedia => 'Medien automatisch herunterladen';

  @override
  String get currentNetwork => 'Aktuelles Netzwerk';

  @override
  String get images => 'Bilder';

  @override
  String get videos => 'Videos';

  @override
  String get voiceMessagesShort => 'Sprachnachrichten';

  @override
  String get documentsLabel => 'Dokumente';

  @override
  String get wifiOnly => 'Nur WLAN';

  @override
  String get never => 'Nie';

  @override
  String get clearAllCache => 'Gesamten Cache löschen';

  @override
  String get allCache => 'Gesamter Cache';

  @override
  String get clearAllCacheConfirmation => 'Dadurch werden alle zwischengespeicherten Bilder, Sprachnachrichten, Videos und andere Dateien gelöscht. Die App lädt Inhalte vorübergehend möglicherweise langsamer.';

  @override
  String clearCacheConfirmationFor(String category) {
    return '$category löschen?';
  }

  @override
  String storageToFree(String size) {
    return '$size wird freigegeben';
  }

  @override
  String get calculating => 'Wird berechnet...';

  @override
  String get noDataToShow => 'Keine Daten vorhanden';

  @override
  String get profileCompletion => 'Profil-Vervollständigung';

  @override
  String get justGettingStarted => 'Gerade erst angefangen';

  @override
  String get lookingGood => 'Sieht gut aus!';

  @override
  String get almostThere => 'Fast geschafft!';

  @override
  String addMissingFields(String fields, Object field) {
    return 'Hinzufügen: $fields';
  }

  @override
  String get profilePicture => 'Profilbild';

  @override
  String get nativeSpeaker => 'Muttersprachler';

  @override
  String peopleInterestedInTopic(Object count) {
    return 'Personen, die sich für dieses Thema interessieren';
  }

  @override
  String get beFirstToAddTopic => 'Sei der Erste, der dieses Thema zu seinen Interessen hinzufügt!';

  @override
  String get recentMoments => 'Neueste Momente';

  @override
  String get seeAll => 'Alle anzeigen';

  @override
  String get study => 'Lernen';

  @override
  String get followerMoments => 'Follower-Momente';

  @override
  String get whenPeopleYouFollowPost => 'Wenn Personen, denen du folgst, neue Momente posten';

  @override
  String get noNotificationsYet => 'Noch keine Benachrichtigungen';

  @override
  String get whenYouGetNotifications => 'Wenn du Benachrichtigungen erhältst, werden sie hier angezeigt';

  @override
  String get failedToLoadNotifications => 'Fehler beim Laden der Benachrichtigungen';

  @override
  String get clearAllNotificationsConfirm => 'Möchtest du wirklich alle Benachrichtigungen löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get tapToChange => 'Tippen zum Ändern';

  @override
  String get noPictureSet => 'Kein Bild festgelegt';

  @override
  String get nameAndGender => 'Name und Geschlecht';

  @override
  String get languageLevel => 'Sprachniveau';

  @override
  String get personalInformation => 'Persönliche Informationen';

  @override
  String get mbti => 'MBTI';

  @override
  String get topicsOfInterest => 'Interessengebiete';

  @override
  String get levelBeginner => 'Anfänger';

  @override
  String get levelElementary => 'Grundkenntnisse';

  @override
  String get levelIntermediate => 'Mittelstufe';

  @override
  String get levelUpperIntermediate => 'Gehobene Mittelstufe';

  @override
  String get levelAdvanced => 'Fortgeschritten';

  @override
  String get levelProficient => 'Fließend';

  @override
  String get selectYourLevel => 'Wähle Dein Niveau';

  @override
  String howWellDoYouSpeak(String language) {
    return 'Wie gut sprichst du $language?';
  }

  @override
  String get theLanguage => 'die Sprache';

  @override
  String languageLevelSetTo(String level) {
    return 'Sprachniveau auf $level gesetzt';
  }

  @override
  String get failedToUpdate => 'Aktualisierung fehlgeschlagen';

  @override
  String get profileUpdatedSuccessfully => 'Profil erfolgreich aktualisiert';

  @override
  String get genderRequired => 'Geschlecht (Erforderlich)';

  @override
  String get editHometown => 'Heimatstadt Bearbeiten';

  @override
  String get useCurrentLocation => 'Aktuellen Standort Verwenden';

  @override
  String get detecting => 'Wird erkannt...';

  @override
  String get getCurrentLocation => 'Aktuellen Standort Abrufen';

  @override
  String get country => 'Land';

  @override
  String get city => 'Stadt';

  @override
  String get coordinates => 'Koordinaten';

  @override
  String get noLocationDetectedYet => 'Noch kein Standort erkannt.';

  @override
  String get detected => 'Erkannt';

  @override
  String get savedHometown => 'Heimatstadt gespeichert';

  @override
  String get locationServicesDisabled => 'Standortdienste sind deaktiviert. Bitte aktiviere sie.';

  @override
  String get locationPermissionPermanentlyDenied => 'Standortberechtigungen sind dauerhaft verweigert.';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get editBio => 'Bio Bearbeiten';

  @override
  String get bioUpdatedSuccessfully => 'Bio erfolgreich aktualisiert';

  @override
  String get tellOthersAboutYourself => 'Erzähle anderen von dir...';

  @override
  String charactersCount(int count) {
    return '$count/500 Zeichen';
  }

  @override
  String get selectYourMbti => 'Wähle Dein MBTI';

  @override
  String get myBloodType => 'Meine Blutgruppe';

  @override
  String get pleaseSelectABloodType => 'Bitte wähle eine Blutgruppe';

  @override
  String get bloodTypeSavedSuccessfully => 'Blutgruppe erfolgreich gespeichert';

  @override
  String get hometownSavedSuccessfully => 'Heimatstadt erfolgreich gespeichert';

  @override
  String get nativeLanguageRequired => 'Muttersprache (Erforderlich)';

  @override
  String get languageToLearnRequired => 'Sprache zum Lernen (Erforderlich)';

  @override
  String get nativeLanguageCannotBeSame => 'Die Muttersprache darf nicht dieselbe sein wie die Sprache, die du lernst';

  @override
  String get learningLanguageCannotBeSame => 'Die Lernsprache darf nicht dieselbe sein wie deine Muttersprache';

  @override
  String get pleaseSelectALanguage => 'Bitte wähle eine Sprache';

  @override
  String get editInterests => 'Interessen Bearbeiten';

  @override
  String maxTopicsAllowed(int count) {
    return 'Maximal $count Themen erlaubt';
  }

  @override
  String get topicsUpdatedSuccessfully => 'Themen erfolgreich aktualisiert!';

  @override
  String get failedToUpdateTopics => 'Themen konnten nicht aktualisiert werden';

  @override
  String selectedCount(int count, int max) {
    return '$count/$max ausgewählt';
  }

  @override
  String get profilePictures => 'Profilbilder';

  @override
  String get addImages => 'Bilder Hinzufügen';

  @override
  String get selectUpToImages => 'Wähle bis zu 5 Bilder';

  @override
  String get takeAPhoto => 'Foto Aufnehmen';

  @override
  String get removeImage => 'Bild Entfernen';

  @override
  String get removeImageConfirm => 'Möchtest du dieses Bild wirklich entfernen?';

  @override
  String get removeAll => 'Alle Entfernen';

  @override
  String get removeAllSelectedImages => 'Alle Ausgewählten Bilder Entfernen';

  @override
  String get removeAllSelectedImagesConfirm => 'Möchtest du wirklich alle ausgewählten Bilder entfernen?';

  @override
  String get yourProfilePictureWillBeKept => 'Dein bestehendes Profilbild wird beibehalten';

  @override
  String get removeAllImages => 'Alle Bilder Entfernen';

  @override
  String get removeAllImagesConfirm => 'Möchtest du wirklich alle Profilbilder entfernen?';

  @override
  String get currentImages => 'Aktuelle Bilder';

  @override
  String get newImages => 'Neue Bilder';

  @override
  String get addMoreImages => 'Weitere Bilder Hinzufügen';

  @override
  String uploadImages(int count) {
    return '$count Bild(er) Hochladen';
  }

  @override
  String get imageRemovedSuccessfully => 'Bild erfolgreich entfernt';

  @override
  String get imagesUploadedSuccessfully => 'Bilder erfolgreich hochgeladen';

  @override
  String get selectedImagesCleared => 'Ausgewählte Bilder gelöscht';

  @override
  String get extraImagesRemovedSuccessfully => 'Zusätzliche Bilder erfolgreich entfernt';

  @override
  String get mustKeepAtLeastOneProfilePicture => 'Du musst mindestens ein Profilbild behalten';

  @override
  String get noProfilePicturesToRemove => 'Keine Profilbilder zum Entfernen';

  @override
  String get authenticationTokenNotFound => 'Authentifizierungs-Token nicht gefunden';

  @override
  String get saveChangesQuestion => 'Änderungen Speichern?';

  @override
  String youHaveUnuploadedImages(int count) {
    return 'Du hast $count Bild(er) ausgewählt aber nicht hochgeladen. Möchtest du sie jetzt hochladen?';
  }

  @override
  String get discard => 'Verwerfen';

  @override
  String get upload => 'Hochladen';

  @override
  String maxImagesInfo(int max, int current) {
    return 'Du kannst bis zu $max Bilder hochladen. Aktuell: $current/$max\nMax 5 Bilder pro Upload.';
  }

  @override
  String canOnlyAddMoreImages(int count, int max) {
    return 'Du kannst nur noch $count weitere(s) Bild(er) hinzufügen. Maximum ist $max Bilder.';
  }

  @override
  String get maxImagesPerUpload => 'Du kannst maximal 5 Bilder auf einmal hochladen. Nur die ersten 5 werden hinzugefügt.';

  @override
  String canOnlyHaveMaxImages(int max) {
    return 'Du kannst nur bis zu $max Bilder haben';
  }

  @override
  String get imageSizeExceedsLimit => 'Bildgröße überschreitet das 10MB-Limit';

  @override
  String get unsupportedImageFormat => 'Nicht unterstütztes Bildformat';

  @override
  String get pleaseSelectAtLeastOneImage => 'Bitte wähle mindestens ein Bild zum Hochladen';

  @override
  String get basicInformation => 'Grundlegende Informationen';

  @override
  String get languageToLearn => 'Sprache zum Lernen';

  @override
  String get hometown => 'Heimatstadt';

  @override
  String get characters => 'Zeichen';

  @override
  String get failedToLoadLanguages => 'Sprachen konnten nicht geladen werden';

  @override
  String get studyHub => 'Lernzentrum';

  @override
  String get dailyLearningJourney => 'Deine tägliche Lernreise';

  @override
  String get learnTab => 'Lernen';

  @override
  String get aiTools => 'KI-Werkzeuge';

  @override
  String get streak => 'Serie';

  @override
  String get lessons => 'Lektionen';

  @override
  String get words => 'Wörter';

  @override
  String get quickActions => 'Schnellaktionen';

  @override
  String get review => 'Wiederholen';

  @override
  String wordsDue(int count) {
    return '$count Wörter fällig';
  }

  @override
  String get addWords => 'Wörter hinzufügen';

  @override
  String get buildVocabulary => 'Vokabular aufbauen';

  @override
  String get practiceWithAI => 'Mit KI üben';

  @override
  String get aiPracticeDescription => 'Chat, Quiz, Grammatik und Aussprache';

  @override
  String get dailyChallenges => 'Tägliche Herausforderungen';

  @override
  String get allChallengesCompleted => 'Alle Herausforderungen abgeschlossen!';

  @override
  String get continueLearning => 'Weiter lernen';

  @override
  String get structuredLearningPath => 'Strukturierter Lernpfad';

  @override
  String get vocabulary => 'Vokabular';

  @override
  String get yourWordCollection => 'Deine Wortsammlung';

  @override
  String get achievements => 'Erfolge';

  @override
  String get badgesAndMilestones => 'Abzeichen und Meilensteine';

  @override
  String get failedToLoadLearningData => 'Lerndaten konnten nicht geladen werden';

  @override
  String get startYourJourney => 'Starte deine Reise!';

  @override
  String get startJourneyDescription => 'Schließe Lektionen ab, baue Vokabular auf\nund verfolge deinen Fortschritt';

  @override
  String levelN(int level) {
    return 'Level $level';
  }

  @override
  String xpEarned(int xp) {
    return '$xp XP verdient';
  }

  @override
  String nextLevel(int level) {
    return 'Nächstes: Level $level';
  }

  @override
  String xpToGo(int xp) {
    return '$xp XP noch nötig';
  }

  @override
  String get aiConversationPartner => 'KI-Gesprächspartner';

  @override
  String get practiceWithAITutor => 'Übe das Sprechen mit deinem KI-Tutor';

  @override
  String get startConversation => 'Gespräch starten';

  @override
  String get aiFeatures => 'KI-Funktionen';

  @override
  String get aiLessons => 'KI-Lektionen';

  @override
  String get learnWithAI => 'Mit KI lernen';

  @override
  String get grammar => 'Grammatik';

  @override
  String get checkWriting => 'Schreiben prüfen';

  @override
  String get pronunciation => 'Aussprache';

  @override
  String get improveSpeaking => 'Sprechen verbessern';

  @override
  String get translation => 'Übersetzung';

  @override
  String get smartTranslate => 'Intelligente Übersetzung';

  @override
  String get aiQuizzes => 'KI-Quiz';

  @override
  String get testKnowledge => 'Wissen testen';

  @override
  String get lessonBuilder => 'Lektions-Builder';

  @override
  String get customLessons => 'Eigene Lektionen';

  @override
  String get yourAIProgress => 'Dein KI-Fortschritt';

  @override
  String get quizzes => 'Quiz';

  @override
  String get avgScore => 'Durchschnittspunktzahl';

  @override
  String get focusAreas => 'Schwerpunktbereiche';

  @override
  String accuracyPercent(String accuracy) {
    return '$accuracy% Genauigkeit';
  }

  @override
  String get practice => 'Üben';

  @override
  String get browse => 'Durchsuchen';

  @override
  String get noRecommendedLessons => 'Keine empfohlenen Lektionen verfügbar';

  @override
  String get noLessonsFound => 'Keine Lektionen gefunden';

  @override
  String get createCustomLessonDescription => 'Erstelle deine eigene Lektion mit KI';

  @override
  String get createLessonWithAI => 'Lektion mit KI erstellen';

  @override
  String get allLevels => 'Alle Niveaus';

  @override
  String get levelA1 => 'A1 Anfänger';

  @override
  String get levelA2 => 'A2 Grundkenntnisse';

  @override
  String get levelB1 => 'B1 Mittelstufe';

  @override
  String get levelB2 => 'B2 Gute Mittelstufe';

  @override
  String get levelC1 => 'C1 Fortgeschritten';

  @override
  String get levelC2 => 'C2 Beherrschung';

  @override
  String get failedToLoadLessons => 'Lektionen konnten nicht geladen werden';

  @override
  String get pin => 'Anheften';

  @override
  String get unpin => 'Lösen';

  @override
  String get editMessage => 'Nachricht bearbeiten';

  @override
  String get enterMessage => 'Nachricht eingeben...';

  @override
  String get deleteMessageTitle => 'Nachricht löschen';

  @override
  String get actionCannotBeUndone => 'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get onlyRemovesFromDevice => 'Wird nur von Ihrem Gerät entfernt';

  @override
  String get availableWithinOneHour => 'Nur innerhalb von 1 Stunde verfügbar';

  @override
  String get available => 'Verfügbar';

  @override
  String get forwardMessage => 'Nachricht weiterleiten';

  @override
  String get selectUsersToForward => 'Benutzer zum Weiterleiten auswählen:';

  @override
  String forwardCount(int count) {
    return 'Weiterleiten ($count)';
  }

  @override
  String get pinnedMessage => 'Angeheftete Nachricht';

  @override
  String get photoMedia => 'Foto';

  @override
  String get videoMedia => 'Video';

  @override
  String get voiceMessageMedia => 'Sprachnachricht';

  @override
  String get documentMedia => 'Dokument';

  @override
  String get locationMedia => 'Standort';

  @override
  String get stickerMedia => 'Sticker';

  @override
  String get smileys => 'Smileys';

  @override
  String get emotions => 'Emotionen';

  @override
  String get handGestures => 'Handgesten';

  @override
  String get hearts => 'Herzen';

  @override
  String get tapToSayHi => 'Tippen Sie, um Hallo zu sagen!';

  @override
  String get sendWaveToStart => 'Senden Sie ein Winken, um zu chatten';

  @override
  String get documentMustBeUnder50MB => 'Das Dokument muss kleiner als 50 MB sein.';

  @override
  String get editWithin15Minutes => 'Nachrichten können nur innerhalb von 15 Minuten bearbeitet werden';

  @override
  String messageForwardedTo(int count) {
    return 'Nachricht an $count Benutzer weitergeleitet';
  }

  @override
  String get failedToLoadUsers => 'Benutzer konnten nicht geladen werden';

  @override
  String get voice => 'Stimme';

  @override
  String get searchGifs => 'GIFs suchen...';

  @override
  String get trendingGifs => 'Trending';

  @override
  String get poweredByGiphy => 'Powered by GIPHY';

  @override
  String get gif => 'GIF';

  @override
  String get noGifsFound => 'Keine GIFs gefunden';

  @override
  String get failedToLoadGifs => 'GIFs konnten nicht geladen werden';

  @override
  String get gifSent => 'GIF';

  @override
  String get filterCommunities => 'Filtern';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get findYourPerfect => 'Finde deinen perfekten';

  @override
  String get languagePartner => 'Sprachpartner';

  @override
  String get learningLanguageLabel => 'Lernsprache';

  @override
  String get ageRange => 'Altersbereich';

  @override
  String get genderPreference => 'Geschlechtspräferenz';

  @override
  String get any => 'Beliebig';

  @override
  String get showNewUsersSubtitle => 'Benutzer anzeigen, die in den letzten 6 Tagen beigetreten sind';

  @override
  String get autoDetectLocation => 'Meinen Standort automatisch erkennen';

  @override
  String get selectCountry => 'Land auswählen';

  @override
  String get anyCountry => 'Beliebiges Land';

  @override
  String get loadingLanguages => 'Sprachen werden geladen...';

  @override
  String minAge(int age) {
    return 'Min: $age';
  }

  @override
  String maxAge(int age) {
    return 'Max: $age';
  }

  @override
  String get captionRequired => 'Beschreibung ist erforderlich';

  @override
  String captionTooLong(int maxLength) {
    return 'Beschreibung darf maximal $maxLength Zeichen lang sein';
  }

  @override
  String get maximumImagesReached => 'Maximale Bildanzahl erreicht';

  @override
  String maximumImagesReachedDescription(int maxImages) {
    return 'Du kannst bis zu $maxImages Bilder pro Moment hochladen.';
  }

  @override
  String maximumImagesAddedPartial(int maxImages, int added) {
    return 'Maximum $maxImages Bilder erlaubt. Nur $added Bilder hinzugefügt.';
  }

  @override
  String get locationAccessRestricted => 'Standortzugriff eingeschränkt';

  @override
  String get locationPermissionNeeded => 'Standortberechtigung erforderlich';

  @override
  String get addToYourMoment => 'Zu deinem Moment hinzufügen';

  @override
  String get categoryLabel => 'Kategorie';

  @override
  String get languageLabel => 'Sprache';

  @override
  String get scheduleOptional => 'Planen (optional)';

  @override
  String get scheduleForLater => 'Für später planen';

  @override
  String get addMore => 'Mehr hinzufügen';

  @override
  String get howAreYouFeeling => 'Wie fühlst du dich?';

  @override
  String get pleaseWaitOptimizingVideo => 'Bitte warten, während wir dein Video optimieren';

  @override
  String unsupportedVideoFormat(String formats) {
    return 'Nicht unterstütztes Format. Verwende: $formats';
  }

  @override
  String get chooseBackground => 'Hintergrund wählen';

  @override
  String likedByXPeople(int count) {
    return 'Von $count Personen geliked';
  }

  @override
  String xComments(int count) {
    return '$count Kommentare';
  }

  @override
  String get oneComment => '1 Kommentar';

  @override
  String get addAComment => 'Kommentar hinzufügen...';

  @override
  String viewXReplies(int count) {
    return '$count Antworten anzeigen';
  }

  @override
  String seenByX(int count) {
    return 'Gesehen von $count';
  }

  @override
  String xHoursAgo(int count) {
    return 'vor $count Std.';
  }

  @override
  String xMinutesAgo(int count) {
    return 'vor $count Min.';
  }

  @override
  String get repliedToYourStory => 'Hat auf deine Story geantwortet';

  @override
  String mentionedYouInComment(String name) {
    return '$name hat dich in einem Kommentar erwähnt';
  }

  @override
  String repliedToYourComment(String name) {
    return '$name hat auf deinen Kommentar geantwortet';
  }

  @override
  String reactedToYourComment(String name) {
    return '$name hat auf deinen Kommentar reagiert';
  }

  @override
  String get addReaction => 'Reaktion hinzufügen';

  @override
  String get attachImage => 'Bild anhängen';

  @override
  String get pickGif => 'GIF auswählen';

  @override
  String get textStory => 'Text';

  @override
  String get typeYourStory => 'Schreibe deine Story...';

  @override
  String get selectBackground => 'Hintergrund wählen';

  @override
  String get highlightsTitle => 'Highlights';

  @override
  String get highlightTitle => 'Highlight-Titel';

  @override
  String get createNewHighlight => 'Neu erstellen';

  @override
  String get selectStories => 'Stories auswählen';

  @override
  String get selectCover => 'Cover auswählen';

  @override
  String get addText => 'Text hinzufügen';

  @override
  String get fontStyleLabel => 'Schriftart';

  @override
  String get textColorLabel => 'Textfarbe';

  @override
  String get dragToDelete => 'Zum Löschen hierher ziehen';

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
  String get momentUpdatedSuccessfully => 'Moment erfolgreich aktualisiert';

  @override
  String get failedToDeleteMoment => 'Moment konnte nicht gelöscht werden';

  @override
  String get failedToUpdateMoment => 'Moment konnte nicht aktualisiert werden';

  @override
  String get mbtiUpdatedSuccessfully => 'MBTI erfolgreich aktualisiert';

  @override
  String get pleaseSelectMbti => 'Bitte wähle einen MBTI-Typ aus';

  @override
  String get languageUpdatedSuccessfully => 'Sprache erfolgreich aktualisiert';

  @override
  String get bioHintCard => 'Eine gute Bio hilft anderen, mit dir in Kontakt zu treten. Teile deine Interessen, Sprachen oder wonach du suchst.';

  @override
  String get bioCounterStartWriting => 'Fang an zu schreiben...';

  @override
  String get bioCounterABitMore => 'Noch etwas mehr wäre toll';

  @override
  String get bioCounterAlmostAtLimit => 'Fast am Limit';

  @override
  String get bioCounterTooLong => 'Zu lang';

  @override
  String get bioQuickStarters => 'Schnellstarter';

  @override
  String get rhPositive => 'Rh Positiv';

  @override
  String get rhNegative => 'Rh Negativ';

  @override
  String get rhPositiveDesc => 'Am häufigsten';

  @override
  String get rhNegativeDesc => 'Universalspender / selten';

  @override
  String get yourBloodType => 'Deine Blutgruppe';

  @override
  String get noBloodTypeSelected => 'Keine Blutgruppe ausgewählt';

  @override
  String get tapTypeBelow => 'Tippe unten auf einen Typ';

  @override
  String get tapButtonToDetectLocation => 'Tippe auf die Schaltfläche unten, um deinen aktuellen Standort zu ermitteln';

  @override
  String currentAddressLabel(String address) {
    return 'Aktuell: $address';
  }

  @override
  String get onlyCityCountryShown => 'Nur deine Stadt und dein Land werden anderen angezeigt. Genaue Koordinaten bleiben privat.';

  @override
  String get updateLocationCta => 'Standort aktualisieren';

  @override
  String get enterYourName => 'Gib deinen Namen ein';

  @override
  String get unsavedChanges => 'Du hast ungespeicherte Änderungen';

  @override
  String tapBelowToBrowseLanguages(int count) {
    return 'Tippe unten, um aus $count Sprachen zu wählen';
  }

  @override
  String get changeLanguage => 'Sprache ändern';

  @override
  String get browseLanguages => 'Sprachen durchsuchen';

  @override
  String get yourLearningLanguageIsPrefix => 'Deine Lernsprache ist ';

  @override
  String get yourNativeLanguageIsPrefix => 'Deine Muttersprache ist ';

  @override
  String get profileCompleteProgress => 'vollständig';

  @override
  String get drawerPreferences => 'Einstellungen';

  @override
  String get drawerStorage => 'Speicher';

  @override
  String get drawerReports => 'Berichte';

  @override
  String get drawerSupport => 'Support';

  @override
  String get drawerAccount => 'Konto';

  @override
  String get logoutConfirmBody => 'Bist du sicher, dass du dich von Bananatalk abmelden möchtest?';

  @override
  String get helpEmailSupport => 'E-Mail-Support';

  @override
  String get helpEmailSupportSubtitle => 'support@bananatalk.com';

  @override
  String get helpReportBug => 'Fehler melden';

  @override
  String get helpReportBugSubtitle => 'Hilf uns, Bananatalk zu verbessern';

  @override
  String get helpFaqs => 'FAQs';

  @override
  String get helpFaqsSubtitle => 'Häufig gestellte Fragen';

  @override
  String get aboutDialogClose => 'Schließen';

  @override
  String get aboutBananatalkTagline => 'Verbinde dich mit Sprachlernenden weltweit und verbessere deine Fähigkeiten durch echte Gespräche.';

  @override
  String get aboutCopyright => '© 2024 Bananatalk. Alle Rechte vorbehalten.';

  @override
  String get logoutFailedPrefix => 'Abmeldung fehlgeschlagen';

  @override
  String get profileVisitorsTitle => 'Profilbesucher';

  @override
  String get visitorStatistics => 'Besucherstatistiken';

  @override
  String get visitorsTotalVisits => 'Besuche gesamt';

  @override
  String get visitorsUniqueVisitors => 'Eindeutige Besucher';

  @override
  String get visitorsToday => 'Heute';

  @override
  String get visitorsThisWeek => 'Diese Woche';

  @override
  String get noVisitorsYet => 'Noch keine Besucher';

  @override
  String get noVisitorsYetSubtitle => 'Wenn jemand dein Profil besucht,\nerscheinen sie hier';

  @override
  String get visitedViaSearch => 'über Suche';

  @override
  String get visitedViaMoments => 'über Momente';

  @override
  String get visitedViaChat => 'über Chat';

  @override
  String get visitedDirect => 'Direktbesuch';

  @override
  String get visitorTrackingUnavailable => 'Besucherverfolgung nicht verfügbar. Bitte Backend aktualisieren.';

  @override
  String get visitorTrackingNotAvailableYet => 'Besucherverfolgung noch nicht verfügbar';

  @override
  String get noFollowersYetSubtitle => 'Fang an, dich mit anderen zu vernetzen!';

  @override
  String get partnerButton => 'Partner';

  @override
  String get notFollowingAnyoneYetSubtitle => 'Folge Personen, um ihre Updates zu sehen!';

  @override
  String get unfollowButton => 'Nicht mehr folgen';

  @override
  String get profileThemeTitle => 'Profildesign';

  @override
  String get themeAutoSwitch => 'Automatisch wechseln (Systemdesign)';

  @override
  String get themeSystemHint => 'Wenn aktiviert, folgt die App deinen Systemdesign-Einstellungen';

  @override
  String get themeLightMode => 'Heller Modus';

  @override
  String get themeDarkMode => 'Dunkler Modus';

  @override
  String get myMoments => 'Meine Momente';

  @override
  String get momentListView => 'Listenansicht';

  @override
  String get momentGridView => 'Rasteransicht';

  @override
  String get shareLanguageLearningJourney => 'Teile deine Sprachlernreise!';

  @override
  String get deleteHighlightTitle => 'Highlight löschen';

  @override
  String deleteHighlightConfirm(String title) {
    return '\"$title\" löschen? Die enthaltenen Stories werden nicht gelöscht.';
  }

  @override
  String get highlightDeletedSuccess => 'Highlight gelöscht';

  @override
  String get highlightNewBadge => 'Neu';

  @override
  String get editMoment => 'Moment bearbeiten';

  @override
  String get momentDescriptionLabel => 'Beschreibung';

  @override
  String get momentImagesLabel => 'Bilder';

  @override
  String get noImagesYet => 'Noch keine Bilder';

  @override
  String get momentEnterDescription => 'Bitte gib eine Beschreibung ein';

  @override
  String get momentUpdatedImageFailed => 'Moment aktualisiert, aber Bild-Upload fehlgeschlagen';

  @override
  String get updateRequiredTitle => 'Update erforderlich';

  @override
  String get updateAvailableTitle => 'Update verfügbar';

  @override
  String get updateRequiredBody => 'Diese Version von Bananatalk wird nicht mehr unterstützt. Bitte aktualisiere, um fortzufahren.';

  @override
  String get updateAvailableBody => 'Eine neue Version von Bananatalk mit Verbesserungen und Fehlerbehebungen ist verfügbar.';

  @override
  String get updateNow => 'Jetzt aktualisieren';

  @override
  String get updateLater => 'Später';

  @override
  String get updateOpenStoreFailed => 'Der Store konnte nicht geöffnet werden. Bitte aktualisiere über den App Store oder Play Store.';

  @override
  String get rememberMe => 'Angemeldet bleiben';

  @override
  String get passwordWeak => 'Schwach';

  @override
  String get passwordFair => 'Mittel';

  @override
  String get passwordStrong => 'Stark';

  @override
  String get passwordVeryStrong => 'Sehr stark';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort verbergen';

  @override
  String stepProgress(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get usernameOptional => 'Benutzername (optional)';

  @override
  String get usernameAvailable => 'Verfügbar';

  @override
  String get usernameTaken => 'Bereits vergeben';

  @override
  String get usernameNotAvailable => 'Nicht verfügbar';

  @override
  String get usernameInvalidFormat => '3–20 Zeichen, Buchstaben, Zahlen oder Unterstrich';

  @override
  String get usernameHint => '@benutzername';

  @override
  String get enableBiometricTitle => 'Beim nächsten Mal mit Face ID anmelden?';

  @override
  String get enableBiometricBody => 'Melde dich biometrisch an, ohne dein Passwort einzugeben.';

  @override
  String get enableBiometricCta => 'Aktivieren';

  @override
  String get biometricSignInPrompt => 'Authentifiziere dich, um dich bei Bananatalk anzumelden';

  @override
  String continueAs(String name) {
    return 'Als $name fortfahren';
  }

  @override
  String get addProfilePhotoTitle => 'Profilfoto hinzufügen';

  @override
  String get addProfilePhotoSkip => 'Vorerst überspringen';

  @override
  String get wavesTab => 'Winken';

  @override
  String get sendWave => 'Winken senden';

  @override
  String sendWaveTo(String name) {
    return '$name zuwinken';
  }

  @override
  String waveSent(String name) {
    return 'Du hast $name zugewinkt';
  }

  @override
  String waveCooldown(String name, String time) {
    return 'Du kannst $name in $time erneut zuwinken';
  }

  @override
  String get waveCouldntSend => 'Winken konnte nicht gesendet werden';

  @override
  String get itsAMatch => 'Ein Match!';

  @override
  String itsAMatchSubtitle(String name) {
    return 'Du und $name habt euch gegenseitig zugewinkt';
  }

  @override
  String get sendAMessage => 'Nachricht senden';

  @override
  String get waveQuickReplyHi => 'Hi!';

  @override
  String get waveQuickReplyCool => 'Du wirkst cool';

  @override
  String get waveQuickReplyHey => 'Hey';

  @override
  String get waveQuickReplyChat => 'Lass uns reden';

  @override
  String get waveQuickReplyHello => 'Hallo';

  @override
  String waveQuickReplyFromCountry(String country) {
    return 'Hallo aus $country';
  }

  @override
  String get waveCustomMessage => 'Oder schreib deine eigene Nachricht…';

  @override
  String get voiceRoomChat => 'Chat';

  @override
  String get voiceRoomChatPlaceholder => 'Nachricht senden…';

  @override
  String get voiceRoomChatEmpty => 'Noch keine Nachrichten — sag Hallo';

  @override
  String get voiceRoomChatSend => 'Senden';

  @override
  String voiceRoomChatNewBadge(int n) {
    return '$n';
  }

  @override
  String get voiceRoomEnd => 'Raum beenden';

  @override
  String get voiceRoomEndConfirm => 'Diesen Raum beenden?';

  @override
  String get voiceRoomEndConfirmBody => 'Alle werden getrennt.';

  @override
  String get voiceRoomKick => 'Aus Raum entfernen';

  @override
  String voiceRoomKickConfirm(String name) {
    return '$name entfernen?';
  }

  @override
  String get voiceRoomKicked => 'Entfernt';

  @override
  String get voiceRoomYouAreHostNow => 'Du bist jetzt der Gastgeber';

  @override
  String voiceRoomHostChanged(String name) {
    return '$name ist jetzt der Gastgeber';
  }

  @override
  String get voiceRoomHostMenuTitle => 'Raumaktionen';

  @override
  String get voiceRoomViewProfile => 'Profil ansehen';

  @override
  String get voiceRoomReconnecting => 'Verbindung wird wiederhergestellt…';

  @override
  String get voiceRoomReconnected => 'Verbindung wiederhergestellt';

  @override
  String get voiceRoomEnded => 'Raum beendet';

  @override
  String get voiceRoomReconnectRetry => 'Erneut versuchen';

  @override
  String get mutualInterests => 'Gemeinsame Interessen';

  @override
  String interestsInCommon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gemeinsame Interessen',
      one: '1 gemeinsames Interesse',
      zero: 'Noch keine gemeinsamen Interessen',
    );
    return '$_temp0';
  }

  @override
  String get interestsInCommonSeeAll => 'Alle anzeigen';

  @override
  String get interestsInCommonAddCta => 'Themen hinzufügen';

  @override
  String get interestsInCommonAddSubtitle => 'Füge Themen zu deinem Profil hinzu, um Gemeinsamkeiten zu finden';

  @override
  String activeAgo(String time) {
    return 'Vor $time aktiv';
  }

  @override
  String get filterOnlineNow => 'Jetzt online';

  @override
  String get filterAge => 'Alter';

  @override
  String get filterGender => 'Geschlecht';

  @override
  String get filterLanguages => 'Sprachen';

  @override
  String get filterCountry => 'Land';

  @override
  String get filterTopics => 'Themen';

  @override
  String get filterLevel => 'Sprachniveau';

  @override
  String get filterToggles => 'Sonstige';

  @override
  String filterMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Partner passen',
      one: '1 Partner passt',
      zero: 'Keine passenden Partner',
    );
    return '$_temp0';
  }

  @override
  String get filterClearAll => 'Alle löschen';

  @override
  String get filterReset => 'Zurücksetzen';

  @override
  String get filterApply => 'Anwenden';

  @override
  String get filterNewUsers => 'Nur neue Nutzer';

  @override
  String get filterPrioritizeNearby => 'Nahegelegene bevorzugen';

  @override
  String get filterSheetTitle => 'Filter';

  @override
  String get notificationPreferencesTitle => 'Benachrichtigungen';

  @override
  String get notificationPreferencesSubtitle => 'Wählen Sie, welche Benachrichtigungen Sie erhalten';

  @override
  String get notifPrefChat => 'Neue Nachrichten';

  @override
  String get notifPrefWave => 'Wellen';

  @override
  String get notifPrefVoiceRoomStart => 'Sprachraum-Einladungen';

  @override
  String get notifPrefScheduledRoomReminder => 'Erinnerungen für geplante Räume';

  @override
  String get notifPrefFollowerMoment => 'Neue Momente von Personen, denen Sie folgen';

  @override
  String get notifPrefVisitorAlert => 'Profilbesucher';

  @override
  String get notifPrefMatchAlert => 'Gegenseitige Wellen';

  @override
  String get notifResetToDefaults => 'Auf Standard zurücksetzen';

  @override
  String get themeMode => 'Design';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSystem => 'System';

  @override
  String get languageSettingsRow => 'Sprache';

  @override
  String get waveDailySummaryTitle => 'Neue Wellen warten';

  @override
  String waveDailySummaryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen haben Sie angewinkt',
      one: '1 Person hat Sie angewinkt',
    );
    return '$_temp0';
  }

  @override
  String get filterTopicsTitle => 'Themen';

  @override
  String get filterTopicsEmpty => 'Keine Themen ausgewählt';

  @override
  String get storiesEmpty => 'Noch keine Storys';

  @override
  String get storiesLoadError => 'Storys konnten nicht geladen werden';

  @override
  String get storiesRetry => 'Erneut versuchen';

  @override
  String get storiesNoMore => 'Du bist auf dem neuesten Stand';

  @override
  String get createTextStoryTab => 'Text';

  @override
  String get createImageStoryTab => 'Foto';

  @override
  String get createVideoStoryTab => 'Video';

  @override
  String get enterTextHint => 'Tippen zum Schreiben';

  @override
  String get pickBackground => 'Hintergrund';

  @override
  String get pickFontStyle => 'Schrift';

  @override
  String get pickTextColor => 'Farbe';

  @override
  String get addEmoji => 'Emoji hinzufügen';

  @override
  String get chooseFont => 'Schrift wählen';

  @override
  String get chooseColor => 'Farbe wählen';

  @override
  String get dragToMove => 'Ziehen zum Verschieben';

  @override
  String get pinchToScale => 'Zusammendrücken zum Skalieren';

  @override
  String get removeFromHighlight => 'Aus Highlight entfernen';

  @override
  String get highlightDeleted => 'Highlight gelöscht';

  @override
  String get storySaved => 'In deiner Story gespeichert';

  @override
  String get storyTooLong => 'Text ist zu lang';

  @override
  String get storyPostFailed => 'Story konnte nicht gepostet werden';

  @override
  String get fontNormal => 'Normal';

  @override
  String get fontBold => 'Fett';

  @override
  String get fontItalic => 'Kursiv';

  @override
  String get fontHandwriting => 'Handschrift';

  @override
  String get pickDate => 'Datum auswählen';

  @override
  String get pickTime => 'Zeit auswählen';

  @override
  String get upcomingRooms => 'Bevorstehend';

  @override
  String inHours(int h, int m) {
    return 'in ${h}Std. ${m}Min.';
  }

  @override
  String inMinutes(int m) {
    return 'in ${m}Min.';
  }

  @override
  String get startsNow => 'Beginnt jetzt';

  @override
  String get iWillBeThere => 'Ich bin dabei';

  @override
  String get cantMakeIt => 'Ich kann nicht kommen';

  @override
  String rsvpCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zusagen',
      one: '1 Zusage',
      zero: 'Keine Zusagen',
    );
    return '$_temp0';
  }

  @override
  String roomStartsIn1h(String title) {
    return '$title beginnt in 1 Stunde';
  }

  @override
  String roomStartsIn15min(String title) {
    return '$title beginnt in 15 Minuten';
  }

  @override
  String roomStarted(String title) {
    return '$title beginnt jetzt';
  }

  @override
  String get cancelRoom => 'Raum abbrechen';

  @override
  String get muteAll => 'Alle stummschalten';

  @override
  String get mutedByHost => 'Host hat alle stummgeschaltet';

  @override
  String get muteAllConfirm => 'Alle im Raum stummschalten?';

  @override
  String get categoryCasual => 'Locker';

  @override
  String get categoryLanguagePractice => 'Sprachübung';

  @override
  String get categoryTopic => 'Thema';

  @override
  String get categoryQA => 'Fragen & Antworten';

  @override
  String get pickCategory => 'Kategorie';

  @override
  String get sortRecentlyActive => 'Kürzlich aktiv';

  @override
  String visitedYourProfile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen haben dein Profil besucht',
      one: '1 Person hat dein Profil besucht',
    );
    return '$_temp0';
  }

  @override
  String get noRecentVisitors => 'Keine kürzlichen Besucher';

  @override
  String get viewArchive => 'Archiv anzeigen';

  @override
  String get archivedWaves => 'Archivierte Waves';

  @override
  String get noArchivedWaves => 'Keine archivierten Waves';

  @override
  String get mutualInterestsMin => 'Gemeinsame Interessen (min)';

  @override
  String atLeastNTopics(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Mindestens $n gemeinsame Themen',
      one: 'Mindestens 1 gemeinsames Thema',
      zero: 'Beliebig',
    );
    return '$_temp0';
  }

  @override
  String get starterAskMoment => 'Nach ihrem letzten Moment fragen';

  @override
  String get starterSayHi => 'Hallo in ihrer Sprache sagen';

  @override
  String get starterCurious => 'Was interessiert sie?';

  @override
  String starterFromCountry(String country) {
    return 'Hallo aus $country!';
  }

  @override
  String starterPracticeLang(String language) {
    return 'Hilf ihnen, $language zu üben!';
  }

  @override
  String get momentsLoadError => 'Momente konnten nicht geladen werden';

  @override
  String get momentsRetry => 'Erneut versuchen';

  @override
  String get recentTags => 'Letzte Tags';

  @override
  String get noRecentTags => 'Noch keine letzten Tags';

  @override
  String get hideMomentsFromUser => 'Momente dieses Nutzers ausblenden';

  @override
  String get momentsHidden => 'Momente dieses Nutzers werden ausgeblendet';

  @override
  String get unhideMoments => 'Momente dieses Nutzers anzeigen';

  @override
  String momentsHiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nutzer ausgeblendet',
      one: '1 Nutzer ausgeblendet',
      zero: 'Keine ausgeblendeten Nutzer',
    );
    return '$_temp0';
  }

  @override
  String get momentSaveFailed => 'Moment konnte nicht gespeichert werden';

  @override
  String get tagAlreadyAdded => 'Tag bereits hinzugefügt';

  @override
  String get tagLimitReached => 'Maximale Tag-Anzahl erreicht';

  @override
  String get hideThisUser => 'Beiträge dieses Nutzers ausblenden';

  @override
  String get transcribeMessage => 'Transkribieren';

  @override
  String get transcribing => 'Transkribiere…';

  @override
  String get transcriptionFailed => 'Nachricht konnte nicht transkribiert werden';

  @override
  String saveToVocabulary(String word) {
    return '\'$word\' im Vokabular speichern';
  }

  @override
  String get addedToVocabulary => 'Zu deinem Vokabular hinzugefügt';

  @override
  String get alreadyInVocabulary => 'Bereits in deinem Vokabular';

  @override
  String get tapWordToSave => 'Halte ein Wort gedrückt, um es zu speichern';

  @override
  String get autoTranslateChatHint => 'Eingehende Nachrichten werden automatisch übersetzt';

  @override
  String get noConversationsYet => 'Noch keine Konversationen';

  @override
  String get chatRetry => 'Erneut versuchen';

  @override
  String get learningHubTitle => 'Lernen';

  @override
  String get learningCommonRetry => 'Erneut versuchen';

  @override
  String get learningCommonContinue => 'Weiter';

  @override
  String get learningCommonAwesome => 'Toll!';

  @override
  String get learningErrorGeneric => 'Etwas ist schiefgelaufen';

  @override
  String get learningStreakCurrent => 'Aktuelle Serie';

  @override
  String get learningStreakLongest => 'Längste Serie';

  @override
  String learningStreakDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
      zero: '0 Tage',
    );
    return '$_temp0';
  }

  @override
  String learningStreakFreezeAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Freezes verfügbar',
      one: '1 Freeze verfügbar',
      zero: 'Kein Freeze verfügbar',
    );
    return '$_temp0';
  }

  @override
  String get learningStreakFreezeUse => 'Freeze einsetzen';

  @override
  String get learningStreakFreezeDescription => 'Freezes schützen deine Serie, wenn du einen Tag verpasst.';

  @override
  String get learningStreakFreezeProtected => 'Serie geschützt!';

  @override
  String get learningStreakMilestone7 => '7-Tage-Serie!';

  @override
  String get learningStreakMilestone30 => '30-Tage-Serie!';

  @override
  String get learningStreakMilestone100 => '100-Tage-Serie!';

  @override
  String get learningStreakMilestone365 => '365-Tage-Serie!';

  @override
  String get learningWeeklyDigestTitle => 'Diese Woche';

  @override
  String learningWeeklyDigestXp(int xp) {
    return '$xp XP verdient';
  }

  @override
  String learningWeeklyDigestLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Lektionen',
      one: '1 Lektion',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestVocab(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wörter gelernt',
      one: '1 Wort gelernt',
    );
    return '$_temp0';
  }

  @override
  String learningWeeklyDigestDaysActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aktive Tage',
      one: '1 aktiver Tag',
    );
    return '$_temp0';
  }

  @override
  String get learningWeeklyDigestTopAchievement => 'Top-Erfolg';

  @override
  String learningWeeklyDigestTrendUp(int pct) {
    return '$pct% mehr als letzte Woche';
  }

  @override
  String learningWeeklyDigestTrendDown(int pct) {
    return '$pct% weniger als letzte Woche';
  }

  @override
  String get learningWeeklyDigestTrendFlat => 'Gleich wie letzte Woche';

  @override
  String get learningSrsDashboardTitle => 'Tägliche Wiederholung';

  @override
  String learningSrsDueToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten heute fällig',
      one: '1 Karte heute fällig',
      zero: 'Keine Karten heute fällig',
    );
    return '$_temp0';
  }

  @override
  String learningSrsDueTomorrow(int count) {
    return '$count morgen fällig';
  }

  @override
  String learningSrsDueThisWeek(int count) {
    return '$count diese Woche fällig';
  }

  @override
  String get learningSrsStartReview => 'Wiederholung starten';

  @override
  String get learningSrsAllCaughtUp => 'Du bist auf dem neuesten Stand!';

  @override
  String get learningSrsKeepGoing => 'Weitermachen';

  @override
  String get learningLeaderboardXpTab => 'XP';

  @override
  String get learningLeaderboardStreakTab => 'Serie';

  @override
  String get learningLeaderboardLanguageTab => 'Sprache';

  @override
  String get learningLeaderboardFriendsTab => 'Freunde';

  @override
  String get learningLeaderboardEmpty => 'Noch keine Rangliste';

  @override
  String get learningLeaderboardYouLabel => 'Du';

  @override
  String get learningLeaderboardFriendBadge => 'Freund';

  @override
  String get learningEmptyVocab => 'Füge Wörter hinzu, die du dir merken möchtest';

  @override
  String get learningEmptyLessons => 'Noch keine Lektionen verfügbar';

  @override
  String get learningEmptyQuizzes => 'Keine Quiz verfügbar';

  @override
  String get learningEmptyChallenges => 'Schau morgen wieder vorbei';

  @override
  String get learningEmptyAchievements => 'Verdiene deinen ersten Erfolg';

  @override
  String get learningEmptySearchResults => 'Keine Ergebnisse gefunden';

  @override
  String learningXpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String get learningLevelUp => 'Level aufgestiegen!';

  @override
  String learningLevelReached(String level) {
    return 'Du hast $level erreicht';
  }

  @override
  String get learningAchievementUnlocked => 'Erfolg freigeschaltet';

  @override
  String get learningVocabularySearchHint => 'Vokabular durchsuchen';

  @override
  String get learningVocabularyFilterAll => 'Alle';

  @override
  String get learningVocabularyFilterNew => 'Neu';

  @override
  String get learningVocabularyFilterLearning => 'Lernend';

  @override
  String get learningVocabularyFilterMastered => 'Gemeistert';

  @override
  String get learningVocabularySortRecent => 'Neueste';

  @override
  String get learningVocabularySortAlphabetical => 'Alphabetisch';

  @override
  String get learningVocabularySortMastery => 'Kenntnisstand';

  @override
  String get learningVocabularyMasteryNew => 'Neu';

  @override
  String get learningVocabularyMasteryLearning => 'Lernend';

  @override
  String get learningVocabularyMasteryMastered => 'Gemeistert';

  @override
  String get learningProgressLevelLabel => 'Level';

  @override
  String learningProgressXpToNextLevel(int xp) {
    return '$xp XP bis zum nächsten Level';
  }

  @override
  String get learningProgressWeeklyChartTitle => 'Letzte 7 Tage';

  @override
  String get aiTutorPronounceLoading => 'Picking a sentence for you…';

  @override
  String get aiTutorPronounceTapToRecord => 'Tap to record';

  @override
  String get aiTutorPronounceTapToStop => 'Tap to stop';

  @override
  String get aiTutorPronounceTranscribing => 'Listening to you…';

  @override
  String get aiTutorPronounceTryAgain => 'Try Again';

  @override
  String get aiTutorPronounceNext => 'Next';

  @override
  String get aiTutorPronounceUseYourOwn => 'Use my own ✏️';

  @override
  String get aiTutorPronounceCustomHint => 'Type a sentence you want to practice';

  @override
  String get aiTutorPronounceCustomCancel => 'Cancel';

  @override
  String get aiTutorPronounceCustomUse => 'Use';

  @override
  String get aiTutorPronounceQuitConfirm => 'Quit drill? Your progress won\'t be saved.';

  @override
  String get aiTutorPronounceQuitYes => 'Yes';

  @override
  String get aiTutorPronounceQuitNo => 'No';

  @override
  String aiTutorPronounceSentenceOf(int current, int total) {
    return 'Sentence $current of $total';
  }

  @override
  String get aiTutorPronounceSummaryTitle => 'Drill complete';

  @override
  String get aiTutorPronounceSummaryAvg => 'Average score';

  @override
  String get aiTutorPronounceSummaryWeak => 'Words to practice';

  @override
  String get aiTutorPronounceSaveClose => 'Save & Close';

  @override
  String get aiTutorPronounceSaving => 'Saving…';

  @override
  String get aiTutorChipPronounce => 'Pronounce';

  @override
  String aiTutorPlanPronunciation(int count, int completed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pronunciation drills ($completed/$count)',
      one: 'Pronunciation drill ($completed/1)',
    );
    return '$_temp0';
  }

  @override
  String get aiTutorPronounceStartHeadline => 'How do you want to practice?';

  @override
  String get aiTutorPronounceStartSubhead => 'Pick one to begin a 5-sentence drill.';

  @override
  String get aiTutorPronounceStartAITitle => 'AI generates sentences';

  @override
  String get aiTutorPronounceStartAISubtitle => 'Level-tuned, biased toward your tricky words';

  @override
  String get aiTutorPronounceStartCustomTitle => 'Use my own sentence';

  @override
  String get aiTutorPronounceStartCustomSubtitle => 'Type or paste a phrase you want to nail';
}
