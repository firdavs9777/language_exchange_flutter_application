// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'BananaTalk';

  @override
  String get login => 'Connexion';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get or => 'OU';

  @override
  String get more => 'plus';

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String get signInWithApple => 'Se connecter avec Apple';

  @override
  String get signInWithFacebook => 'Se connecter avec Facebook';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get home => 'Accueil';

  @override
  String get messages => 'Messages';

  @override
  String get moments => 'Moments';

  @override
  String get overview => 'Aperçu';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get logout => 'Déconnexion';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get autoTranslate => 'Traduction automatique';

  @override
  String get autoTranslateMessages => 'Traduire automatiquement les messages';

  @override
  String get autoTranslateMoments => 'Traduire automatiquement les moments';

  @override
  String get autoTranslateComments => 'Traduire automatiquement les commentaires';

  @override
  String get translate => 'Traduire';

  @override
  String get translated => 'Traduit';

  @override
  String get showOriginal => 'Afficher l\'original';

  @override
  String get showTranslation => 'Afficher la traduction';

  @override
  String get translating => 'Traduction en cours...';

  @override
  String get translationFailed => 'Échec de la traduction';

  @override
  String get noTranslationAvailable => 'Aucune traduction disponible';

  @override
  String translatedFrom(String language) {
    return 'Traduit de $language';
  }

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get share => 'Partager';

  @override
  String get like => 'J\'aime';

  @override
  String get comment => 'Commenter';

  @override
  String get send => 'Envoyer';

  @override
  String get search => 'Rechercher';

  @override
  String get notifications => 'Notifications';

  @override
  String get followers => 'Abonnés';

  @override
  String get following => 'Abonnements';

  @override
  String get posts => 'Publications';

  @override
  String get visitors => 'Visiteurs';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get networkError => 'Erreur réseau. Veuillez vérifier votre connexion.';

  @override
  String get somethingWentWrong => 'Une erreur s\'est produite';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get languageSettings => 'Paramètres de langue';

  @override
  String get deviceLanguage => 'Langue de l\'appareil';

  @override
  String yourDeviceIsSetTo(String flag, String name) {
    return 'Votre appareil est configuré sur : $flag $name';
  }

  @override
  String get youCanOverride => 'Vous pouvez remplacer la langue de l\'appareil ci-dessous.';

  @override
  String languageChangedTo(String name) {
    return 'Langue changée en $name';
  }

  @override
  String get errorChangingLanguage => 'Erreur lors du changement de langue';

  @override
  String get autoTranslateSettings => 'Paramètres de traduction automatique';

  @override
  String get automaticallyTranslateIncomingMessages => 'Traduire automatiquement les messages entrants';

  @override
  String get automaticallyTranslateMomentsInFeed => 'Traduire automatiquement les moments dans le fil';

  @override
  String get automaticallyTranslateComments => 'Traduire automatiquement les commentaires';

  @override
  String get translationServiceBeingConfigured => 'Le service de traduction est en cours de configuration. Veuillez réessayer plus tard.';

  @override
  String get translationUnavailable => 'Traduction indisponible';

  @override
  String get showLess => 'voir moins';

  @override
  String get showMore => 'voir plus';

  @override
  String get comments => 'Commentaires';

  @override
  String get beTheFirstToComment => 'Soyez le premier à commenter.';

  @override
  String get writeAComment => 'Écrire un commentaire...';

  @override
  String get report => 'Signaler';

  @override
  String get reportMoment => 'Signaler le moment';

  @override
  String get reportUser => 'Signaler l\'utilisateur';

  @override
  String get deleteMoment => 'Supprimer le moment ?';

  @override
  String get thisActionCannotBeUndone => 'Cette action est irréversible.';

  @override
  String get momentDeleted => 'Moment supprimé';

  @override
  String get deleteComment => 'Delete Comment?';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get editFeatureComingSoon => 'Fonction de modification bientôt disponible';

  @override
  String get userNotFound => 'Utilisateur introuvable';

  @override
  String get cannotReportYourOwnComment => 'Impossible de signaler votre propre commentaire';

  @override
  String get profileSettings => 'Paramètres du profil';

  @override
  String get editYourProfileInformation => 'Modifier vos informations de profil';

  @override
  String get blockedUsers => 'Utilisateurs bloqués';

  @override
  String get manageBlockedUsers => 'Gérer les utilisateurs bloqués';

  @override
  String get manageNotificationSettings => 'Gérer les paramètres de notification';

  @override
  String get privacySecurity => 'Confidentialité et sécurité';

  @override
  String get controlYourPrivacy => 'Contrôlez votre confidentialité';

  @override
  String get changeAppLanguage => 'Changer la langue de l\'application';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeAndDisplaySettings => 'Paramètres de thème et d\'affichage';

  @override
  String get clearCache => 'Vider le cache';

  @override
  String get clearCacheSubtitle => 'Libérer de l\'espace de stockage';

  @override
  String get clearCacheDescription => 'Cela supprimera toutes les images, vidéos et fichiers audio mis en cache. L\'application peut charger le contenu plus lentement temporairement pendant le re-téléchargement des médias.';

  @override
  String get clearCacheHint => 'Utilisez ceci si les images ou l\'audio ne se chargent pas correctement.';

  @override
  String get clearingCache => 'Vidage du cache...';

  @override
  String get cacheCleared => 'Cache vidé avec succès ! Les images se rechargeront.';

  @override
  String get clearCacheFailed => 'Échec du vidage du cache';

  @override
  String get myReports => 'Mes signalements';

  @override
  String get viewYourSubmittedReports => 'Voir vos signalements soumis';

  @override
  String get reportsManagement => 'Gestion des signalements';

  @override
  String get manageAllReportsAdmin => 'Gérer tous les signalements (Admin)';

  @override
  String get legalPrivacy => 'Mentions légales et confidentialité';

  @override
  String get termsPrivacySubscriptionInfo => 'Conditions, confidentialité et infos d\'abonnement';

  @override
  String get helpCenter => 'Centre d\'aide';

  @override
  String get getHelpAndSupport => 'Obtenir de l\'aide et du support';

  @override
  String get aboutBanaTalk => 'À propos de BanaTalk';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get permanentlyDeleteYourAccount => 'Supprimer définitivement votre compte';

  @override
  String get loggedOutSuccessfully => 'Déconnexion réussie';

  @override
  String get retry => 'Réessayer';

  @override
  String get giftsLikes => 'Cadeaux/J\'aime';

  @override
  String get details => 'Détails';

  @override
  String get to => 'à';

  @override
  String get banaTalk => 'BanaTalk';

  @override
  String get chats => 'Discussions';

  @override
  String get community => 'Communauté';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String yearsOld(String age) {
    return '$age ans';
  }

  @override
  String get searchConversations => 'Rechercher des conversations...';

  @override
  String get visitorTrackingNotAvailable => 'La fonction de suivi des visiteurs n\'est pas encore disponible. Mise à jour du backend requise.';

  @override
  String get chatList => 'Liste des discussions';

  @override
  String get languageExchange => 'Échange linguistique';

  @override
  String get nativeLanguage => 'Langue maternelle';

  @override
  String get learning => 'Apprentissage';

  @override
  String get notSet => 'Non défini';

  @override
  String get about => 'À propos';

  @override
  String get aboutMe => 'À propos de moi';

  @override
  String get bloodType => 'Groupe sanguin';

  @override
  String get photos => 'Photos';

  @override
  String get camera => 'Appareil photo';

  @override
  String get createMoment => 'Créer un moment';

  @override
  String get addATitle => 'Ajouter un titre...';

  @override
  String get whatsOnYourMind => 'À quoi pensez-vous ?';

  @override
  String get addTags => 'Ajouter des tags';

  @override
  String get done => 'Terminé';

  @override
  String get add => 'Ajouter';

  @override
  String get enterTag => 'Entrer un tag';

  @override
  String get post => 'Publier';

  @override
  String get commentAddedSuccessfully => 'Commentaire ajouté avec succès';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get notificationSettings => 'Paramètres de notification';

  @override
  String get enableNotifications => 'Activer les notifications';

  @override
  String get turnAllNotificationsOnOrOff => 'Activer ou désactiver toutes les notifications';

  @override
  String get notificationTypes => 'Types de notifications';

  @override
  String get chatMessages => 'Messages de chat';

  @override
  String get getNotifiedWhenYouReceiveMessages => 'Être notifié lorsque vous recevez des messages';

  @override
  String get likesAndCommentsOnYourMoments => 'J\'aime et commentaires sur vos moments';

  @override
  String get whenPeopleYouFollowPostMoments => 'Lorsque les personnes que vous suivez publient des moments';

  @override
  String get friendRequests => 'Demandes d\'amis';

  @override
  String get whenSomeoneFollowsYou => 'Lorsque quelqu\'un vous suit';

  @override
  String get profileVisits => 'Visites de profil';

  @override
  String get whenSomeoneViewsYourProfileVIP => 'Lorsque quelqu\'un consulte votre profil (VIP)';

  @override
  String get marketing => 'Marketing';

  @override
  String get updatesAndPromotionalMessages => 'Mises à jour et messages promotionnels';

  @override
  String get notificationPreferences => 'Préférences de notification';

  @override
  String get sound => 'Son';

  @override
  String get playNotificationSounds => 'Jouer les sons de notification';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrateOnNotifications => 'Vibrer lors des notifications';

  @override
  String get showPreview => 'Afficher l\'aperçu';

  @override
  String get showMessagePreviewInNotifications => 'Afficher l\'aperçu du message dans les notifications';

  @override
  String get mutedConversations => 'Conversations en sourdine';

  @override
  String get conversation => 'Conversation';

  @override
  String get unmute => 'Réactiver';

  @override
  String get systemNotificationSettings => 'Paramètres de notification système';

  @override
  String get manageNotificationsInSystemSettings => 'Gérer les notifications dans les paramètres système';

  @override
  String get errorLoadingSettings => 'Erreur de chargement des paramètres';

  @override
  String get unblockUser => 'Débloquer l\'utilisateur';

  @override
  String get unblock => 'Débloquer';

  @override
  String get goBack => 'Retour';

  @override
  String get messageSendTimeout => 'Délai d\'envoi du message expiré. Veuillez vérifier votre connexion.';

  @override
  String get failedToSendMessage => 'Échec de l\'envoi du message';

  @override
  String get dailyMessageLimitExceeded => 'Limite quotidienne de messages dépassée. Passez au VIP pour des messages illimités.';

  @override
  String get cannotSendMessageUserMayBeBlocked => 'Impossible d\'envoyer le message. L\'utilisateur est peut-être bloqué.';

  @override
  String get sessionExpired => 'Session expirée. Veuillez vous reconnecter.';

  @override
  String get sendThisSticker => 'Envoyer cet autocollant ?';

  @override
  String get chooseHowYouWantToDeleteThisMessage => 'Choisissez comment vous voulez supprimer ce message :';

  @override
  String get deleteForEveryone => 'Supprimer pour tout le monde';

  @override
  String get removesTheMessageForBothYouAndTheRecipient => 'Supprime le message pour vous et le destinataire';

  @override
  String get deleteForMe => 'Supprimer pour moi';

  @override
  String get removesTheMessageOnlyFromYourChat => 'Supprime le message uniquement de votre chat';

  @override
  String get copy => 'Copier';

  @override
  String get reply => 'Répondre';

  @override
  String get forward => 'Transférer';

  @override
  String get moreOptions => 'Plus d\'options';

  @override
  String get noUsersAvailableToForwardTo => 'Aucun utilisateur disponible pour le transfert';

  @override
  String get searchMoments => 'Rechercher des moments...';

  @override
  String searchInChatWith(String name) {
    return 'Rechercher dans le chat avec $name';
  }

  @override
  String get typeAMessage => 'Tapez un message...';

  @override
  String get enterYourMessage => 'Entrez votre message';

  @override
  String get detectYourLocation => 'Détecter votre position';

  @override
  String get tapToUpdateLocation => 'Appuyez pour mettre à jour la position';

  @override
  String get helpOthersFindYouNearby => 'Aidez les autres à vous trouver à proximité';

  @override
  String get selectYourNativeLanguage => 'Sélectionnez votre langue maternelle';

  @override
  String get whichLanguageDoYouWantToLearn => 'Quelle langue voulez-vous apprendre ?';

  @override
  String get selectYourGender => 'Sélectionnez votre genre';

  @override
  String get addACaption => 'Ajouter une légende...';

  @override
  String get typeSomething => 'Tapez quelque chose...';

  @override
  String get gallery => 'Galerie';

  @override
  String get video => 'Vidéo';

  @override
  String get text => 'Texte';

  @override
  String get provideMoreInformation => 'Fournir plus d\'informations...';

  @override
  String get searchByNameLanguageOrInterests => 'Rechercher par nom, langue ou centres d\'intérêt...';

  @override
  String get addTagAndPressEnter => 'Ajouter un tag et appuyez sur Entrée';

  @override
  String replyTo(String name) {
    return 'Répondre à $name...';
  }

  @override
  String get highlightName => 'Nom du highlight';

  @override
  String get searchCloseFriends => 'Rechercher des amis proches...';

  @override
  String get askAQuestion => 'Poser une question...';

  @override
  String option(String number) {
    return 'Option $number';
  }

  @override
  String whyAreYouReportingThis(String type) {
    return 'Pourquoi signalez-vous ce $type ?';
  }

  @override
  String get additionalDetailsOptional => 'Détails supplémentaires (optionnel)';

  @override
  String get warningThisActionIsPermanent => 'Attention : cette action est irréversible !';

  @override
  String get deletingYourAccountWillPermanentlyRemove => 'La suppression de votre compte supprimera définitivement :\n\n• Votre profil et toutes vos données personnelles\n• Tous vos messages et conversations\n• Tous vos moments et stories\n• Votre abonnement VIP (non remboursable)\n• Toutes vos connexions et abonnés\n\nCette action est irréversible.';

  @override
  String get clearAllNotifications => 'Effacer toutes les notifications ?';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get notificationDebug => 'Débogage des notifications';

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get clearAll2 => 'Tout effacer';

  @override
  String get emailAddress => 'Adresse e-mail';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get alreadyHaveAnAccount => 'Vous avez déjà un compte ?';

  @override
  String get login2 => 'Connexion';

  @override
  String get selectYourNativeLanguage2 => 'Sélectionnez votre langue maternelle';

  @override
  String get whichLanguageDoYouWantToLearn2 => 'Quelle langue voulez-vous apprendre ?';

  @override
  String get selectYourGender2 => 'Sélectionnez votre genre';

  @override
  String get dateFormat => 'JJ.MM.AAAA';

  @override
  String get detectYourLocation2 => 'Détecter votre position';

  @override
  String get tapToUpdateLocation2 => 'Appuyez pour mettre à jour la position';

  @override
  String get helpOthersFindYouNearby2 => 'Aidez les autres à vous trouver à proximité';

  @override
  String get couldNotOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get legalPrivacy2 => 'Mentions légales et confidentialité';

  @override
  String get termsOfUseEULA => 'Conditions d\'utilisation (CLUF)';

  @override
  String get viewOurTermsAndConditions => 'Voir nos conditions générales';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get howWeHandleYourData => 'Comment nous gérons vos données';

  @override
  String get emailNotifications => 'Notifications par e-mail';

  @override
  String get receiveEmailNotificationsFromBananaTalk => 'Recevoir des notifications par e-mail de BananaTalk';

  @override
  String get weeklySummary => 'Résumé hebdomadaire';

  @override
  String get activityRecapEverySunday => 'Récapitulatif d\'activité chaque dimanche';

  @override
  String get newMessages => 'Nouveaux messages';

  @override
  String get whenYoureAwayFor24PlusHours => 'Lorsque vous êtes absent pendant plus de 24 heures';

  @override
  String get newFollowers => 'Nouveaux abonnés';

  @override
  String get whenSomeoneFollowsYou2 => 'Lorsque quelqu\'un vous suit';

  @override
  String get securityAlerts => 'Alertes de sécurité';

  @override
  String get passwordLoginAlerts => 'Alertes de mot de passe et de connexion';

  @override
  String get unblockUser2 => 'Débloquer l\'utilisateur';

  @override
  String get blockedUsers2 => 'Utilisateurs bloqués';

  @override
  String get finalWarning => 'Dernier avertissement';

  @override
  String get deleteForever => 'Supprimer définitivement';

  @override
  String get deleteAccount2 => 'Supprimer le compte';

  @override
  String get enterYourPassword => 'Entrez votre mot de passe';

  @override
  String get yourPassword => 'Votre mot de passe';

  @override
  String get typeDELETEToConfirm => 'Tapez SUPPRIMER pour confirmer';

  @override
  String get typeDELETEInCapitalLetters => 'Tapez SUPPRIMER en majuscules';

  @override
  String sent(String emoji) {
    return '$emoji envoyé !';
  }

  @override
  String get replySent => 'Réponse envoyée !';

  @override
  String get deleteStory => 'Supprimer la story ?';

  @override
  String get thisStoryWillBeRemovedPermanently => 'Cette story sera supprimée définitivement.';

  @override
  String get noStories => 'Aucune story';

  @override
  String views(String count) {
    return '$count vues';
  }

  @override
  String get reportStory => 'Signaler la story';

  @override
  String get reply2 => 'Répondre...';

  @override
  String get failedToPickImage => 'Échec de la sélection de l\'image';

  @override
  String get failedToTakePhoto => 'Échec de la prise de photo';

  @override
  String get failedToPickVideo => 'Échec de la sélection de la vidéo';

  @override
  String get pleaseEnterSomeText => 'Veuillez entrer du texte';

  @override
  String get pleaseSelectMedia => 'Veuillez sélectionner un média';

  @override
  String get storyPosted => 'Story publiée !';

  @override
  String get textOnlyStoriesRequireAnImage => 'Les stories textuelles nécessitent une image';

  @override
  String get createStory => 'Créer une story';

  @override
  String get change => 'Changer';

  @override
  String get userIdNotFound => 'ID utilisateur introuvable. Veuillez vous reconnecter.';

  @override
  String get pleaseSelectAPaymentMethod => 'Veuillez sélectionner un mode de paiement';

  @override
  String get startExploring => 'Commencer à explorer';

  @override
  String get close => 'Fermer';

  @override
  String get payment => 'Paiement';

  @override
  String get upgradeToVIP => 'Passer au VIP';

  @override
  String get errorLoadingProducts => 'Erreur de chargement des produits';

  @override
  String get cancelVIPSubscription => 'Annuler l\'abonnement VIP';

  @override
  String get keepVIP => 'Garder le VIP';

  @override
  String get cancelSubscription => 'Annuler l\'abonnement';

  @override
  String get vipSubscriptionCancelledSuccessfully => 'Abonnement VIP annulé avec succès';

  @override
  String get vipStatus => 'Statut VIP';

  @override
  String get noActiveVIPSubscription => 'Aucun abonnement VIP actif';

  @override
  String get subscriptionExpired => 'Abonnement expiré';

  @override
  String get vipExpiredMessage => 'Votre abonnement VIP a expiré. Renouvelez maintenant pour continuer à profiter des fonctionnalités illimitées !';

  @override
  String get expiredOn => 'Expiré le';

  @override
  String get renewVIP => 'Renouveler le VIP';

  @override
  String get whatYoureMissing => 'Ce que vous manquez';

  @override
  String get manageInAppStore => 'Gérer dans l\'App Store';

  @override
  String get becomeVIP => 'Devenir VIP';

  @override
  String get unlimitedMessages => 'Messages illimités';

  @override
  String get unlimitedProfileViews => 'Vues de profil illimitées';

  @override
  String get prioritySupport => 'Support prioritaire';

  @override
  String get advancedSearch => 'Recherche avancée';

  @override
  String get profileBoost => 'Boost de profil';

  @override
  String get adFreeExperience => 'Expérience sans publicité';

  @override
  String get upgradeYourAccount => 'Améliorez votre compte';

  @override
  String get moreMessages => 'Plus de messages';

  @override
  String get moreProfileViews => 'Plus de vues de profil';

  @override
  String get connectWithFriends => 'Connectez-vous avec des amis';

  @override
  String get reviewStarted => 'Révision commencée';

  @override
  String get reportResolved => 'Signalement résolu';

  @override
  String get reportDismissed => 'Signalement rejeté';

  @override
  String get selectAction => 'Sélectionner une action';

  @override
  String get noViolation => 'Aucune violation';

  @override
  String get contentRemoved => 'Contenu supprimé';

  @override
  String get userWarned => 'Utilisateur averti';

  @override
  String get userSuspended => 'Utilisateur suspendu';

  @override
  String get userBanned => 'Utilisateur banni';

  @override
  String get addNotesOptional => 'Ajouter des notes (optionnel)';

  @override
  String get enterModeratorNotes => 'Entrer les notes du modérateur...';

  @override
  String get skip => 'Passer';

  @override
  String get startReview => 'Commencer la révision';

  @override
  String get resolve => 'Résoudre';

  @override
  String get dismiss => 'Rejeter';

  @override
  String get filterReports => 'Filtrer les signalements';

  @override
  String get all => 'Tout';

  @override
  String get clear => 'Effacer';

  @override
  String get apply => 'Appliquer';

  @override
  String get myReports2 => 'Mes signalements';

  @override
  String get blockUser => 'Bloquer l\'utilisateur';

  @override
  String get block => 'Bloquer';

  @override
  String get wouldYouAlsoLikeToBlockThisUser => 'Voulez-vous également bloquer cet utilisateur ?';

  @override
  String get noThanks => 'Non, merci';

  @override
  String get yesBlockThem => 'Oui, le bloquer';

  @override
  String get reportUser2 => 'Signaler l\'utilisateur';

  @override
  String get submitReport => 'Soumettre le signalement';

  @override
  String get addAQuestionAndAtLeast2Options => 'Ajouter une question et au moins 2 options';

  @override
  String get addOption => 'Ajouter une option';

  @override
  String get anonymousVoting => 'Vote anonyme';

  @override
  String get create => 'Créer';

  @override
  String get typeYourAnswer => 'Tapez votre réponse...';

  @override
  String get send2 => 'Envoyer';

  @override
  String get yourPrompt => 'Votre question...';

  @override
  String get add2 => 'Ajouter';

  @override
  String get contentNotAvailable => 'Contenu non disponible';

  @override
  String get profileNotAvailable => 'Profil non disponible';

  @override
  String get noMomentsToShow => 'Aucun moment à afficher';

  @override
  String get storiesNotAvailable => 'Stories non disponibles';

  @override
  String get cantMessageThisUser => 'Impossible d\'envoyer un message à cet utilisateur';

  @override
  String get pleaseSelectAReason => 'Veuillez sélectionner une raison';

  @override
  String get reportSubmitted => 'Signalement soumis. Merci de contribuer à la sécurité de notre communauté.';

  @override
  String get youHaveAlreadyReportedThisMoment => 'Vous avez déjà signalé ce moment';

  @override
  String get tellUsMoreAboutWhyYouAreReportingThis => 'Dites-nous pourquoi vous signalez ceci';

  @override
  String get errorSharing => 'Erreur de partage';

  @override
  String get deviceInfo => 'Infos de l\'appareil';

  @override
  String get recommended => 'Recommandé';

  @override
  String get anyLanguage => 'Toute langue';

  @override
  String get noLanguagesFound => 'Aucune langue trouvée';

  @override
  String get selectALanguage => 'Sélectionner une langue';

  @override
  String get languagesAreStillLoading => 'Les langues sont en cours de chargement...';

  @override
  String get selectNativeLanguage => 'Sélectionner la langue maternelle';

  @override
  String get subscriptionDetails => 'Détails de l\'abonnement';

  @override
  String get activeFeatures => 'Fonctionnalités actives';

  @override
  String get legalInformation => 'Informations légales';

  @override
  String get termsOfUse => 'Conditions d\'utilisation';

  @override
  String get manageSubscription => 'Gérer l\'abonnement';

  @override
  String get manageSubscriptionInSettings => 'Pour annuler votre abonnement, accédez à Réglages > [Votre nom] > Abonnements sur votre appareil.';

  @override
  String get contactSupportToCancel => 'Pour annuler votre abonnement, veuillez contacter notre équipe d\'assistance.';

  @override
  String get status => 'Statut';

  @override
  String get active => 'Actif';

  @override
  String get plan => 'Forfait';

  @override
  String get startDate => 'Date de début';

  @override
  String get endDate => 'Date de fin';

  @override
  String get nextBillingDate => 'Prochaine facturation';

  @override
  String get autoRenew => 'Renouvellement auto';

  @override
  String get pleaseLogInToContinue => 'Veuillez vous connecter pour continuer';

  @override
  String get purchaseCanceledOrFailed => 'L\'achat a été annulé ou a échoué. Veuillez réessayer.';

  @override
  String get maximumTagsAllowed => 'Maximum 5 tags autorisés';

  @override
  String get pleaseRemoveImagesFirstToAddVideo => 'Veuillez d\'abord supprimer les images pour ajouter une vidéo';

  @override
  String get unsupportedFormat => 'Format non pris en charge';

  @override
  String get errorProcessingVideo => 'Erreur de traitement de la vidéo';

  @override
  String get pleaseRemoveImagesFirstToRecordVideo => 'Veuillez d\'abord supprimer les images pour enregistrer une vidéo';

  @override
  String get locationAdded => 'Position ajoutée';

  @override
  String get failedToGetLocation => 'Échec de l\'obtention de la position';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get videoUploadFailed => 'Échec du téléchargement de la vidéo';

  @override
  String get skipVideo => 'Passer la vidéo';

  @override
  String get retryUpload => 'Réessayer le téléchargement';

  @override
  String get momentCreatedSuccessfully => 'Moment créé avec succès';

  @override
  String get uploadingMomentInBackground => 'Téléchargement du moment en arrière-plan...';

  @override
  String get failedToQueueUpload => 'Échec de la mise en file d\'attente du téléchargement';

  @override
  String get viewProfile => 'Voir le profil';

  @override
  String get mediaLinksAndDocs => 'Médias, liens et documents';

  @override
  String get wallpaper => 'Fond d\'écran';

  @override
  String get userIdNotAvailable => 'ID utilisateur non disponible';

  @override
  String get cannotBlockYourself => 'Impossible de vous bloquer';

  @override
  String get chatWallpaper => 'Fond d\'écran du chat';

  @override
  String get wallpaperSavedLocally => 'Fond d\'écran enregistré localement';

  @override
  String get messageCopied => 'Message copié';

  @override
  String get forwardFeatureComingSoon => 'Fonction de transfert bientôt disponible';

  @override
  String get momentUnsaved => 'Retiré des enregistrés';

  @override
  String get documentPickerComingSoon => 'Sélecteur de document bientôt disponible';

  @override
  String get contactSharingComingSoon => 'Partage de contact bientôt disponible';

  @override
  String get featureComingSoon => 'Fonctionnalité bientôt disponible';

  @override
  String get answerSent => 'Réponse envoyée !';

  @override
  String get noImagesAvailable => 'Aucune image disponible';

  @override
  String get mentionPickerComingSoon => 'Sélecteur de mention bientôt disponible';

  @override
  String get musicPickerComingSoon => 'Sélecteur de musique bientôt disponible';

  @override
  String get repostFeatureComingSoon => 'Fonction de republication bientôt disponible';

  @override
  String get addFriendsFromYourProfile => 'Ajouter des amis depuis votre profil';

  @override
  String get quickReplyAdded => 'Réponse rapide ajoutée';

  @override
  String get quickReplyDeleted => 'Réponse rapide supprimée';

  @override
  String get linkCopied => 'Lien copié !';

  @override
  String get maximumOptionsAllowed => 'Maximum 10 options autorisées';

  @override
  String get minimumOptionsRequired => 'Minimum 2 options requises';

  @override
  String get pleaseEnterAQuestion => 'Veuillez entrer une question';

  @override
  String get pleaseAddAtLeast2Options => 'Veuillez ajouter au moins 2 options';

  @override
  String get pleaseSelectCorrectAnswerForQuiz => 'Veuillez sélectionner la bonne réponse pour le quiz';

  @override
  String get correctionSent => 'Correction envoyée !';

  @override
  String get sort => 'Trier';

  @override
  String get savedMoments => 'Moments enregistrés';

  @override
  String get unsave => 'Retirer';

  @override
  String get playingAudio => 'Lecture audio...';

  @override
  String get failedToGenerateQuiz => 'Échec de la génération du quiz';

  @override
  String get failedToAddComment => 'Échec de l\'ajout du commentaire';

  @override
  String get hello => 'Bonjour !';

  @override
  String get howAreYou => 'Comment allez-vous ?';

  @override
  String get cannotOpen => 'Impossible d\'ouvrir';

  @override
  String get errorOpeningLink => 'Erreur lors de l\'ouverture du lien';

  @override
  String get saved => 'Enregistré';

  @override
  String get follow => 'Suivre';

  @override
  String get unfollow => 'Ne plus suivre';

  @override
  String get mute => 'Sourdine';

  @override
  String get online => 'En ligne';

  @override
  String get offline => 'Hors ligne';

  @override
  String get lastSeen => 'Vu(e)';

  @override
  String get justNow => 'à l\'instant';

  @override
  String minutesAgo(String count) {
    return 'il y a $count minutes';
  }

  @override
  String hoursAgo(String count) {
    return 'il y a $count heures';
  }

  @override
  String get yesterday => 'Hier';

  @override
  String get signInWithEmail => 'Se connecter par e-mail';

  @override
  String get partners => 'Partenaires';

  @override
  String get nearby => 'À proximité';

  @override
  String get topics => 'Sujets';

  @override
  String get waves => 'Saluts';

  @override
  String get voiceRooms => 'Voix';

  @override
  String get filters => 'Filtres';

  @override
  String get searchCommunity => 'Rechercher par nom, langue ou centres d\'intérêt...';

  @override
  String get bio => 'Bio';

  @override
  String get noBioYet => 'Aucune bio disponible pour l\'instant.';

  @override
  String get languages => 'Langues';

  @override
  String get native => 'Maternelle';

  @override
  String get interests => 'Centres d\'intérêt';

  @override
  String get noMomentsYet => 'Aucun moment pour l\'instant';

  @override
  String get unableToLoadMoments => 'Impossible de charger les moments';

  @override
  String get map => 'Carte';

  @override
  String get mapUnavailable => 'Carte non disponible';

  @override
  String get location => 'Position';

  @override
  String get unknownLocation => 'Position inconnue';

  @override
  String get noImagesAvailable2 => 'Aucune image disponible';

  @override
  String get permissionsRequired => 'Autorisations requises';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get refresh => 'Actualiser';

  @override
  String get videoCall => 'Vidéo';

  @override
  String get voiceCall => 'Appel';

  @override
  String get message => 'Message';

  @override
  String get pleaseLoginToFollow => 'Veuillez vous connecter pour suivre des utilisateurs';

  @override
  String get pleaseLoginToCall => 'Veuillez vous connecter pour passer un appel';

  @override
  String get cannotCallYourself => 'Vous ne pouvez pas vous appeler';

  @override
  String get failedToFollowUser => 'Échec du suivi de l\'utilisateur';

  @override
  String get failedToUnfollowUser => 'Échec de l\'arrêt du suivi de l\'utilisateur';

  @override
  String get areYouSureUnfollow => 'Êtes-vous sûr de vouloir ne plus suivre cet utilisateur ?';

  @override
  String get areYouSureUnblock => 'Êtes-vous sûr de vouloir débloquer cet utilisateur ?';

  @override
  String get youFollowed => 'Vous suivez';

  @override
  String get youUnfollowed => 'Vous ne suivez plus';

  @override
  String get alreadyFollowing => 'Vous suivez déjà';

  @override
  String get soon => 'Bientôt';

  @override
  String comingSoon(String feature) {
    return '$feature arrive bientôt !';
  }

  @override
  String get muteNotifications => 'Mettre les notifications en sourdine';

  @override
  String get unmuteNotifications => 'Réactiver les notifications';

  @override
  String get operationCompleted => 'Opération terminée';

  @override
  String get couldNotOpenMaps => 'Impossible d\'ouvrir les cartes';

  @override
  String hasntSharedMoments(Object name) {
    return '$name n\'a partagé aucun moment';
  }

  @override
  String messageUser(String name) {
    return 'Envoyer un message à $name';
  }

  @override
  String notFollowingUser(String name) {
    return 'Vous ne suiviez pas $name';
  }

  @override
  String youFollowedUser(String name) {
    return 'Vous suivez $name';
  }

  @override
  String youUnfollowedUser(String name) {
    return 'Vous ne suivez plus $name';
  }

  @override
  String unfollowUser(String name) {
    return 'Ne plus suivre $name';
  }

  @override
  String get typing => 'écrit';

  @override
  String get connecting => 'Connexion...';

  @override
  String daysAgo(int count) {
    return 'il y a ${count}j';
  }

  @override
  String get maxTagsAllowed => 'Maximum 5 tags autorisés';

  @override
  String maxImagesAllowed(int count) {
    return 'Maximum $count images autorisées';
  }

  @override
  String get pleaseRemoveImagesFirst => 'Veuillez d\'abord supprimer les images pour ajouter une vidéo';

  @override
  String get exchange3MessagesBeforeCall => 'Vous devez échanger au moins 3 messages avant de pouvoir appeler cet utilisateur';

  @override
  String mediaWithUser(String name) {
    return 'Médias avec $name';
  }

  @override
  String get errorLoadingMedia => 'Erreur de chargement des médias';

  @override
  String get savedMomentsTitle => 'Moments enregistrés';

  @override
  String get removeBookmark => 'Supprimer le favori ?';

  @override
  String get thisWillRemoveBookmark => 'Cela supprimera le message de vos favoris.';

  @override
  String get remove => 'Supprimer';

  @override
  String get bookmarkRemoved => 'Favori supprimé';

  @override
  String get bookmarkedMessages => 'Messages favoris';

  @override
  String get wallpaperSaved => 'Fond d\'écran enregistré localement';

  @override
  String get typeDeleteToConfirm => 'Type DELETE to confirm';

  @override
  String get storyArchive => 'Archive de stories';

  @override
  String get newHighlight => 'Nouveau highlight';

  @override
  String get addToHighlight => 'Ajouter au highlight';

  @override
  String get repost => 'Republier';

  @override
  String get repostFeatureSoon => 'Fonction de republication bientôt disponible';

  @override
  String get closeFriends => 'Amis proches';

  @override
  String get addFriends => 'Ajouter des amis';

  @override
  String get highlights => 'Highlights';

  @override
  String get createHighlight => 'Créer un highlight';

  @override
  String get deleteHighlight => 'Supprimer le highlight ?';

  @override
  String get editHighlight => 'Modifier le highlight';

  @override
  String get addMoreToStory => 'Ajouter plus à la story';

  @override
  String get noViewersYet => 'Aucun spectateur pour l\'instant';

  @override
  String get noReactionsYet => 'Aucune réaction pour l\'instant';

  @override
  String get leaveRoom => 'Quitter le salon';

  @override
  String get areYouSureLeaveRoom => 'Êtes-vous sûr de vouloir quitter cette salle vocale ?';

  @override
  String get stay => 'Rester';

  @override
  String get leave => 'Quitter';

  @override
  String get enableGPS => 'Activer le GPS';

  @override
  String wavedToUser(String name) {
    return 'Vous avez salué $name !';
  }

  @override
  String get areYouSureFollow => 'Êtes-vous sûr de vouloir suivre';

  @override
  String get failedToLoadProfile => 'Échec du chargement du profil';

  @override
  String get noFollowersYet => 'Aucun abonné pour l\'instant';

  @override
  String get noFollowingYet => 'Vous ne suivez personne pour l\'instant';

  @override
  String get searchUsers => 'Rechercher des utilisateurs...';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get loadingFailed => 'Échec du chargement';

  @override
  String get copyLink => 'Copier le lien';

  @override
  String get shareStory => 'Partager la story';

  @override
  String get thisWillDeleteStory => 'Cela supprimera définitivement cette story.';

  @override
  String get storyDeleted => 'Story supprimée';

  @override
  String get addCaption => 'Ajouter une légende...';

  @override
  String get yourStory => 'Votre story';

  @override
  String get sendMessage => 'Envoyer un message';

  @override
  String get replyToStory => 'Répondre à la story...';

  @override
  String get viewAllReplies => 'Voir toutes les réponses';

  @override
  String get preparingVideo => 'Préparation de la vidéo...';

  @override
  String videoOptimized(String size, String savings) {
    return 'Vidéo optimisée : ${size}Mo (économie de $savings%)';
  }

  @override
  String get failedToProcessVideo => 'Échec du traitement de la vidéo';

  @override
  String get optimizingForBestExperience => 'Optimisation pour la meilleure expérience de story';

  @override
  String get pleaseSelectImageOrVideo => 'Veuillez sélectionner une image ou une vidéo pour votre story';

  @override
  String get storyCreatedSuccessfully => 'Story créée avec succès !';

  @override
  String get uploadingStoryInBackground => 'Téléchargement de la story en arrière-plan...';

  @override
  String get storyCreationFailed => 'Échec de la création de la story';

  @override
  String get pleaseCheckConnection => 'Veuillez vérifier votre connexion et réessayer.';

  @override
  String get uploadFailed => 'Échec du téléchargement';

  @override
  String get tryShorterVideo => 'Essayez une vidéo plus courte ou réessayez plus tard.';

  @override
  String get shareMomentsThatDisappear => 'Partagez des moments qui disparaissent en 24 heures';

  @override
  String get photo => 'Photo';

  @override
  String get record => 'Enregistrer';

  @override
  String get addSticker => 'Ajouter un autocollant';

  @override
  String get poll => 'Sondage';

  @override
  String get question => 'Question';

  @override
  String get mention => 'Mention';

  @override
  String get music => 'Musique';

  @override
  String get hashtag => 'Hashtag';

  @override
  String get whoCanSeeThis => 'Qui peut voir ceci ?';

  @override
  String get everyone => 'Tout le monde';

  @override
  String get anyoneCanSeeStory => 'Tout le monde peut voir cette story';

  @override
  String get friendsOnly => 'Amis uniquement';

  @override
  String get onlyFollowersCanSee => 'Seuls vos abonnés peuvent voir';

  @override
  String get onlyCloseFriendsCanSee => 'Seuls vos amis proches peuvent voir';

  @override
  String get backgroundColor => 'Couleur de fond';

  @override
  String get fontStyle => 'Style de police';

  @override
  String get normal => 'Normal';

  @override
  String get bold => 'Gras';

  @override
  String get italic => 'Italique';

  @override
  String get handwriting => 'Manuscrit';

  @override
  String get addLocation => 'Ajouter une position';

  @override
  String get enterLocationName => 'Entrer le nom de la position';

  @override
  String get addLink => 'Ajouter un lien';

  @override
  String get buttonText => 'Texte du bouton';

  @override
  String get learnMore => 'En savoir plus';

  @override
  String get addHashtags => 'Ajouter des hashtags';

  @override
  String get addHashtag => 'Ajouter un hashtag';

  @override
  String get sendAsMessage => 'Envoyer comme message';

  @override
  String get shareExternally => 'Partager en externe';

  @override
  String get checkOutStory => 'Découvrez cette story sur BananaTalk !';

  @override
  String viewsTab(String count) {
    return 'Vues ($count)';
  }

  @override
  String reactionsTab(String count) {
    return 'Réactions ($count)';
  }

  @override
  String get processingVideo => 'Traitement de la vidéo...';

  @override
  String get link => 'Lien';

  @override
  String unmuteUser(String name) {
    return 'Réactiver $name ?';
  }

  @override
  String get willReceiveNotifications => 'Vous recevrez des notifications pour les nouveaux messages.';

  @override
  String muteNotificationsFor(String name) {
    return 'Mettre en sourdine les notifications pour $name';
  }

  @override
  String notificationsUnmutedFor(String name) {
    return 'Notifications réactivées pour $name';
  }

  @override
  String notificationsMutedFor(String name) {
    return 'Notifications en sourdine pour $name';
  }

  @override
  String get failedToUpdateMuteSettings => 'Échec de la mise à jour des paramètres de sourdine';

  @override
  String get oneHour => '1 heure';

  @override
  String get eightHours => '8 heures';

  @override
  String get oneWeek => '1 semaine';

  @override
  String get always => 'Toujours';

  @override
  String get failedToLoadBookmarks => 'Échec du chargement des favoris';

  @override
  String get noBookmarkedMessages => 'Aucun message favori';

  @override
  String get longPressToBookmark => 'Appuyez longuement sur un message pour l\'ajouter aux favoris';

  @override
  String get thisWillRemoveFromBookmarks => 'Cela supprimera le message de vos favoris.';

  @override
  String navigateToMessage(String name) {
    return 'Accéder au message dans le chat avec $name';
  }

  @override
  String bookmarkedOn(String date) {
    return 'Ajouté aux favoris le $date';
  }

  @override
  String get voiceMessage => 'Message vocal';

  @override
  String get document => 'Document';

  @override
  String get attachment => 'Pièce jointe';

  @override
  String get sendMeAMessage => 'Envoyez-moi un message';

  @override
  String get shareWithFriends => 'Partager avec des amis';

  @override
  String get shareAnywhere => 'Partager n\'importe où';

  @override
  String get emailPreferences => 'Préférences e-mail';

  @override
  String get receiveEmailNotifications => 'Recevoir des notifications par e-mail de BananaTalk';

  @override
  String get whenAwayFor24Hours => 'Lorsque vous êtes absent pendant plus de 24 heures';

  @override
  String get passwordAndLoginAlerts => 'Alertes de mot de passe et de connexion';

  @override
  String get failedToLoadPreferences => 'Échec du chargement des préférences';

  @override
  String get failedToUpdateSetting => 'Échec de la mise à jour du paramètre';

  @override
  String get securityAlertsRecommended => 'Nous recommandons de garder les alertes de sécurité activées pour rester informé de l\'activité importante de votre compte.';

  @override
  String chatWallpaperFor(String name) {
    return 'Fond d\'écran du chat pour $name';
  }

  @override
  String get solidColors => 'Couleurs unies';

  @override
  String get gradients => 'Dégradés';

  @override
  String get customImage => 'Image personnalisée';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get preview => 'Aperçu';

  @override
  String get wallpaperUpdated => 'Fond d\'écran mis à jour';

  @override
  String get category => 'Catégorie';

  @override
  String get mood => 'Humeur';

  @override
  String get sortBy => 'Trier par';

  @override
  String get timePeriod => 'Période';

  @override
  String get searchLanguages => 'Rechercher des langues...';

  @override
  String get selected => 'Sélectionné';

  @override
  String get categories => 'Catégories';

  @override
  String get moods => 'Humeurs';

  @override
  String get applyFilters => 'Appliquer les filtres';

  @override
  String applyNFilters(int count) {
    return 'Appliquer $count filtres';
  }

  @override
  String get videoMustBeUnder1GB => 'La vidéo doit faire moins de 1 Go.';

  @override
  String get failedToRecordVideo => 'Échec de l\'enregistrement de la vidéo';

  @override
  String get errorSendingVideo => 'Erreur lors de l\'envoi de la vidéo';

  @override
  String get errorSendingVoiceMessage => 'Erreur lors de l\'envoi du message vocal';

  @override
  String get errorSendingMedia => 'Erreur lors de l\'envoi du média';

  @override
  String get cameraPermissionRequired => 'Les autorisations de l\'appareil photo et du microphone sont requises pour enregistrer des vidéos.';

  @override
  String get locationPermissionRequired => 'L\'autorisation de localisation est requise pour partager votre position.';

  @override
  String get noInternetConnection => 'Pas de connexion Internet';

  @override
  String get tryAgainLater => 'Veuillez réessayer plus tard';

  @override
  String get messageSent => 'Message envoyé';

  @override
  String get messageDeleted => 'Message supprimé';

  @override
  String get messageEdited => 'Message modifié';

  @override
  String get edited => '(modifié)';

  @override
  String get now => 'maintenant';

  @override
  String weeksAgo(int count) {
    return 'il y a ${count}sem';
  }

  @override
  String viewRepliesCount(int count) {
    return '── Voir $count réponses';
  }

  @override
  String get hideReplies => '── Masquer les réponses';

  @override
  String get saveMoment => 'Enregistrer le moment';

  @override
  String get removeFromSaved => 'Retirer des enregistrés';

  @override
  String get momentSaved => 'Enregistré';

  @override
  String get failedToSave => 'Échec de l\'enregistrement';

  @override
  String checkOutMoment(String title) {
    return 'Découvrez ce moment : $title';
  }

  @override
  String get failedToLoadMoments => 'Échec du chargement des moments';

  @override
  String get noMomentsMatchFilters => 'Aucun moment ne correspond à vos filtres';

  @override
  String get beFirstToShareMoment => 'Soyez le premier à partager un moment !';

  @override
  String get tryDifferentSearch => 'Essayez un autre terme de recherche';

  @override
  String get tryAdjustingFilters => 'Essayez d\'ajuster vos filtres';

  @override
  String get noSavedMoments => 'Aucun moment enregistré';

  @override
  String get tapBookmarkToSave => 'Appuyez sur l\'icône de signet pour enregistrer un moment';

  @override
  String get failedToLoadVideo => 'Échec du chargement de la vidéo';

  @override
  String get titleRequired => 'Le titre est obligatoire';

  @override
  String titleTooLong(int max) {
    return 'Le titre doit contenir $max caractères ou moins';
  }

  @override
  String get descriptionRequired => 'La description est obligatoire';

  @override
  String descriptionTooLong(int max) {
    return 'La description doit contenir $max caractères ou moins';
  }

  @override
  String get scheduledDateMustBeFuture => 'La date programmée doit être dans le futur';

  @override
  String get recent => 'Récent';

  @override
  String get popular => 'Populaire';

  @override
  String get trending => 'Tendance';

  @override
  String get mostRecent => 'Plus récent';

  @override
  String get mostPopular => 'Plus populaire';

  @override
  String get allTime => 'Tout';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get thisMonth => 'Ce mois';

  @override
  String replyingTo(String userName) {
    return 'Répondre à $userName';
  }

  @override
  String get listView => 'Vue en liste';

  @override
  String get quickMatch => 'Correspondance rapide';

  @override
  String get onlineNow => 'En ligne maintenant';

  @override
  String speaksLanguage(String language) {
    return 'Parle $language';
  }

  @override
  String learningLanguage(String language) {
    return 'Apprend $language';
  }

  @override
  String get noPartnersFound => 'Aucun partenaire trouvé';

  @override
  String noUsersFoundForLanguages(String learning, String native) {
    return 'Aucun utilisateur trouvé pour $learning et $native';
  }

  @override
  String get removeAllFilters => 'Supprimer tous les filtres';

  @override
  String get browseAllUsers => 'Parcourir tous les utilisateurs';

  @override
  String get allCaughtUp => 'Vous êtes à jour !';

  @override
  String get loadingMore => 'Chargement en cours...';

  @override
  String get findingMorePartners => 'Recherche de partenaires...';

  @override
  String get seenAllPartners => 'Vous avez vu tous les partenaires';

  @override
  String get startOver => 'Recommencer';

  @override
  String get changeFilters => 'Modifier les filtres';

  @override
  String get findingPartners => 'Recherche de partenaires...';

  @override
  String get setLocationReminder => 'Définissez votre position pour trouver des partenaires à proximité';

  @override
  String get updateLocationReminder => 'Mettez à jour votre position pour de meilleurs résultats';

  @override
  String get male => 'Homme';

  @override
  String get female => 'Femme';

  @override
  String get other => 'Autre';

  @override
  String get browseMen => 'Parcourir les hommes';

  @override
  String get browseWomen => 'Parcourir les femmes';

  @override
  String get noMaleUsersFound => 'Aucun utilisateur masculin trouvé';

  @override
  String get noFemaleUsersFound => 'Aucun utilisateur féminin trouvé';

  @override
  String get vip => 'VIP';

  @override
  String get newUsersOnly => 'Nouveaux utilisateurs uniquement';

  @override
  String get showNewUsers => 'Afficher les nouveaux utilisateurs';

  @override
  String get prioritizeNearby => 'Prioriser les proches';

  @override
  String get showNearbyFirst => 'Afficher les proches en premier';

  @override
  String get setLocationToEnable => 'Définissez votre position pour activer';

  @override
  String get radius => 'Rayon';

  @override
  String get findingYourLocation => 'Détection de votre position...';

  @override
  String get enableLocationForDistance => 'Activez la localisation pour voir les distances';

  @override
  String get enableLocationDescription => 'Autorisez l\'accès à la localisation pour trouver des partenaires linguistiques près de vous';

  @override
  String get enableGps => 'Activer le GPS';

  @override
  String get browseByCityCountry => 'Rechercher par ville ou pays';

  @override
  String get peopleNearby => 'Personnes à proximité';

  @override
  String get noNearbyUsersFound => 'Aucun utilisateur à proximité';

  @override
  String get tryExpandingSearch => 'Essayez d\'élargir votre recherche';

  @override
  String get exploreByCity => 'Explorer par ville';

  @override
  String get exploreByCurrentCity => 'Explorer par votre ville actuelle';

  @override
  String get interactiveWorldMap => 'Carte du monde interactive';

  @override
  String get searchByCityName => 'Rechercher par nom de ville';

  @override
  String get seeUserCountsPerCountry => 'Voir le nombre d\'utilisateurs par pays';

  @override
  String get upgradeToVip => 'Passer au VIP';

  @override
  String get searchByCity => 'Rechercher par ville';

  @override
  String usersWorldwide(String count) {
    return '$count utilisateurs dans le monde';
  }

  @override
  String get noUsersFound => 'Aucun utilisateur trouvé';

  @override
  String get tryDifferentCity => 'Essayez une autre ville';

  @override
  String usersCount(String count) {
    return '$count utilisateurs';
  }

  @override
  String get searchCountry => 'Rechercher un pays';

  @override
  String get wave => 'Saluer';

  @override
  String get newUser => 'Nouveau';

  @override
  String get warningPermanent => 'Attention : cette action est irréversible !';

  @override
  String get deleteAccountWarning => 'La suppression de votre compte effacera définitivement toutes vos données, messages, moments et connexions. Cette action est irréversible.';

  @override
  String get requiredForEmailOnly => 'Requis uniquement pour les comptes e-mail';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String get typeDELETE => 'Tapez DELETE';

  @override
  String get mustTypeDELETE => 'Vous devez taper DELETE pour confirmer';

  @override
  String get deletingAccount => 'Suppression du compte...';

  @override
  String get deleteMyAccountPermanently => 'Supprimer définitivement mon compte';

  @override
  String get whatsYourNativeLanguage => 'Quelle est votre langue maternelle ?';

  @override
  String get helpsMatchWithLearners => 'Aide à vous mettre en relation avec des apprenants de votre langue';

  @override
  String get whatAreYouLearning => 'Qu\'apprenez-vous ?';

  @override
  String get connectWithNativeSpeakers => 'Connectez-vous avec des locuteurs natifs';

  @override
  String get selectLearningLanguage => 'Sélectionnez la langue que vous apprenez';

  @override
  String get selectCurrentLevel => 'Sélectionnez votre niveau actuel';

  @override
  String get beginner => 'Débutant';

  @override
  String get elementary => 'Élémentaire';

  @override
  String get intermediate => 'Intermédiaire';

  @override
  String get upperIntermediate => 'Intermédiaire supérieur';

  @override
  String get advanced => 'Avancé';

  @override
  String get proficient => 'Maîtrise';

  @override
  String get showingPartnersByDistance => 'Affichage des partenaires par distance';

  @override
  String get enableLocationForResults => 'Activez la localisation pour obtenir des résultats';

  @override
  String get enable => 'Activer';

  @override
  String get locationNotSet => 'Position non définie';

  @override
  String get tellUsAboutYourself => 'Parlez-nous de vous';

  @override
  String get justACoupleQuickThings => 'Juste quelques petites choses';

  @override
  String get gender => 'Genre';

  @override
  String get birthDate => 'Date de naissance';

  @override
  String get selectYourBirthDate => 'Sélectionnez votre date de naissance';

  @override
  String get continueButton => 'Continuer';

  @override
  String get pleaseSelectGender => 'Veuillez sélectionner votre genre';

  @override
  String get pleaseSelectBirthDate => 'Veuillez sélectionner votre date de naissance';

  @override
  String get mustBe18 => 'Vous devez avoir au moins 18 ans';

  @override
  String get invalidDate => 'Date invalide';

  @override
  String get almostDone => 'Presque terminé !';

  @override
  String get addPhotoLocationForMatches => 'Ajoutez une photo et votre position pour de meilleures correspondances';

  @override
  String get addProfilePhoto => 'Ajouter une photo de profil';

  @override
  String get optionalUpTo6Photos => 'Facultatif — jusqu\'à 6 photos';

  @override
  String get maximum6Photos => '6 photos maximum';

  @override
  String get tapToDetectLocation => 'Appuyez pour détecter la position';

  @override
  String get optionalHelpsNearbyPartners => 'Facultatif — aide à trouver des partenaires à proximité';

  @override
  String get startLearning => 'Commencer à apprendre';

  @override
  String get photoLocationOptional => 'La photo et la position sont facultatives';

  @override
  String get pleaseAcceptTerms => 'Veuillez accepter les conditions d\'utilisation';

  @override
  String get iAgreeToThe => 'J\'accepte les';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get tapToSelectLanguage => 'Appuyez pour sélectionner une langue';

  @override
  String yourLevelIn(String language) {
    return 'Votre niveau en $language';
  }

  @override
  String get yourCurrentLevel => 'Votre niveau actuel';

  @override
  String get nativeCannotBeSameAsLearning => 'La langue maternelle ne peut pas être la même que la langue apprise';

  @override
  String get learningCannotBeSameAsNative => 'La langue apprise ne peut pas être la même que votre langue maternelle';

  @override
  String stepOf(String current, String total) {
    return 'Étape $current sur $total';
  }

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get registerLink => 'S\'inscrire';

  @override
  String get pleaseEnterBothEmailAndPassword => 'Veuillez entrer votre e-mail et mot de passe';

  @override
  String get pleaseEnterValidEmail => 'Veuillez entrer un e-mail valide';

  @override
  String get loginSuccessful => 'Connexion réussie !';

  @override
  String get stepOneOfTwo => 'Étape 1 sur 2';

  @override
  String get createYourAccount => 'Créez votre compte';

  @override
  String get basicInfoToGetStarted => 'Informations de base pour commencer';

  @override
  String get emailVerifiedLabel => 'E-mail (Vérifié)';

  @override
  String get nameLabel => 'Nom';

  @override
  String get yourDisplayName => 'Votre nom d\'affichage';

  @override
  String get atLeast8Characters => 'Au moins 8 caractères';

  @override
  String get confirmPasswordHint => 'Confirmer le mot de passe';

  @override
  String get nextButton => 'Suivant';

  @override
  String get pleaseEnterYourName => 'Veuillez entrer votre nom';

  @override
  String get pleaseEnterAPassword => 'Veuillez entrer un mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get otherGender => 'Autre';

  @override
  String get continueWithGoogleAccount => 'Continuez avec votre compte Google\npour une expérience fluide';

  @override
  String get signingYouIn => 'Connexion en cours...';

  @override
  String get backToSignInMethods => 'Retour aux méthodes de connexion';

  @override
  String get securedByGoogle => 'Sécurisé par Google';

  @override
  String get dataProtectedEncryption => 'Vos données sont protégées par un chiffrement standard';

  @override
  String get welcomeCompleteProfile => 'Bienvenue ! Veuillez compléter votre profil';

  @override
  String welcomeBackName(String name) {
    return 'Bon retour, $name !';
  }

  @override
  String get continueWithAppleId => 'Continuez avec votre Apple ID\npour une expérience sécurisée';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get securedByApple => 'Sécurisé par Apple';

  @override
  String get privacyProtectedApple => 'Votre vie privée est protégée avec Apple Sign-In';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get enterEmailToGetStarted => 'Entrez votre e-mail pour commencer';

  @override
  String get continueText => 'Continuer';

  @override
  String get pleaseEnterEmailAddress => 'Veuillez entrer votre adresse e-mail';

  @override
  String get verificationCodeSent => 'Code de vérification envoyé !';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get resetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get enterEmailForResetCode => 'Entrez votre e-mail et nous vous enverrons un code de réinitialisation';

  @override
  String get sendResetCode => 'Envoyer le code';

  @override
  String get resetCodeSent => 'Code de réinitialisation envoyé !';

  @override
  String get rememberYourPassword => 'Vous vous souvenez de votre mot de passe ?';

  @override
  String get verifyCode => 'Vérifier le code';

  @override
  String get enterResetCode => 'Entrer le code';

  @override
  String get weSentCodeTo => 'Nous avons envoyé un code à 6 chiffres à';

  @override
  String get pleaseEnterAll6Digits => 'Veuillez entrer les 6 chiffres';

  @override
  String get codeVerifiedCreatePassword => 'Code vérifié ! Créez votre nouveau mot de passe';

  @override
  String get verify => 'Vérifier';

  @override
  String get didntReceiveCode => 'Vous n\'avez pas reçu le code ?';

  @override
  String get resend => 'Renvoyer';

  @override
  String resendWithTimer(String timer) {
    return 'Renvoyer (${timer}s)';
  }

  @override
  String get resetCodeResent => 'Code renvoyé !';

  @override
  String get verifyEmail => 'Vérifier l\'e-mail';

  @override
  String get verifyYourEmail => 'Vérifiez votre e-mail';

  @override
  String get emailVerifiedSuccessfully => 'E-mail vérifié avec succès !';

  @override
  String get verificationCodeResent => 'Code de vérification renvoyé !';

  @override
  String get createNewPassword => 'Créer un nouveau mot de passe';

  @override
  String get enterNewPasswordBelow => 'Entrez votre nouveau mot de passe ci-dessous';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get pleaseFillAllFields => 'Veuillez remplir tous les champs';

  @override
  String get passwordResetSuccessful => 'Mot de passe réinitialisé ! Connectez-vous avec votre nouveau mot de passe';

  @override
  String get privacyTitle => 'Confidentialité';

  @override
  String get profileVisibility => 'Visibilité du profil';

  @override
  String get showCountryRegion => 'Afficher le pays/la région';

  @override
  String get showCountryRegionDesc => 'Affiche votre pays sur votre profil';

  @override
  String get showCity => 'Afficher la ville';

  @override
  String get showCityDesc => 'Affiche votre ville sur votre profil';

  @override
  String get showAge => 'Afficher l\'âge';

  @override
  String get showAgeDesc => 'Affiche votre âge sur votre profil';

  @override
  String get showZodiacSign => 'Afficher le signe du zodiaque';

  @override
  String get showZodiacSignDesc => 'Affiche votre signe du zodiaque sur votre profil';

  @override
  String get onlineStatusSection => 'Statut en ligne';

  @override
  String get showOnlineStatus => 'Afficher le statut en ligne';

  @override
  String get showOnlineStatusDesc => 'Permet aux autres de voir quand vous êtes en ligne';

  @override
  String get otherSettings => 'Autres paramètres';

  @override
  String get showGiftingLevel => 'Afficher le niveau de cadeaux';

  @override
  String get showGiftingLevelDesc => 'Affiche votre badge de niveau de cadeaux';

  @override
  String get birthdayNotifications => 'Notifications d\'anniversaire';

  @override
  String get birthdayNotificationsDesc => 'Recevoir des notifications pour votre anniversaire';

  @override
  String get personalizedAds => 'Publicités personnalisées';

  @override
  String get personalizedAdsDesc => 'Autoriser les publicités personnalisées';

  @override
  String get saveChanges => 'Enregistrer';

  @override
  String get privacySettingsSaved => 'Paramètres de confidentialité enregistrés';

  @override
  String get locationSection => 'Localisation';

  @override
  String get updateLocation => 'Mettre à jour la localisation';

  @override
  String get updateLocationDesc => 'Actualiser votre position actuelle';

  @override
  String get currentLocation => 'Position actuelle';

  @override
  String get locationNotAvailable => 'Position non disponible';

  @override
  String get locationUpdated => 'Position mise à jour avec succès';

  @override
  String get locationPermissionDenied => 'Autorisation de localisation refusée. Activez-la dans les paramètres.';

  @override
  String get locationServiceDisabled => 'Les services de localisation sont désactivés. Veuillez les activer.';

  @override
  String get updatingLocation => 'Mise à jour de la position...';

  @override
  String get locationCouldNotBeUpdated => 'Impossible de mettre à jour la position';

  @override
  String get incomingAudioCall => 'Appel audio entrant';

  @override
  String get incomingVideoCall => 'Appel vidéo entrant';

  @override
  String get outgoingCall => 'Appel en cours...';

  @override
  String get callRinging => 'Sonnerie...';

  @override
  String get callConnecting => 'Connexion...';

  @override
  String get callConnected => 'Connecté';

  @override
  String get callReconnecting => 'Reconnexion...';

  @override
  String get callEnded => 'Appel terminé';

  @override
  String get callFailed => 'Appel échoué';

  @override
  String get callMissed => 'Appel manqué';

  @override
  String get callDeclined => 'Appel refusé';

  @override
  String callDuration(String duration) {
    return '$duration';
  }

  @override
  String get acceptCall => 'Accepter';

  @override
  String get declineCall => 'Refuser';

  @override
  String get endCall => 'Terminer';

  @override
  String get muteCall => 'Muet';

  @override
  String get unmuteCall => 'Réactiver';

  @override
  String get speakerOn => 'Haut-parleur';

  @override
  String get speakerOff => 'Écouteur';

  @override
  String get videoOn => 'Vidéo activée';

  @override
  String get videoOff => 'Vidéo désactivée';

  @override
  String get switchCamera => 'Changer de caméra';

  @override
  String get callPermissionDenied => 'L\'autorisation du microphone est requise pour les appels';

  @override
  String get cameraPermissionDenied => 'L\'autorisation de la caméra est requise pour les appels vidéo';

  @override
  String get callConnectionFailed => 'Connexion impossible. Veuillez réessayer.';

  @override
  String get userBusy => 'Utilisateur occupé';

  @override
  String get userOffline => 'Utilisateur hors ligne';

  @override
  String get callHistory => 'Historique des appels';

  @override
  String get noCallHistory => 'Aucun historique d\'appels';

  @override
  String get missedCalls => 'Appels manqués';

  @override
  String get allCalls => 'Tous les appels';

  @override
  String get callBack => 'Rappeler';

  @override
  String callAt(String time) {
    return 'Appel à $time';
  }

  @override
  String get audioCall => 'Appel audio';

  @override
  String get voiceRoom => 'Salon vocal';

  @override
  String get noVoiceRooms => 'Aucun salon vocal actif';

  @override
  String get createVoiceRoom => 'Créer un salon vocal';

  @override
  String get joinRoom => 'Rejoindre le salon';

  @override
  String get leaveRoomConfirm => 'Quitter le salon?';

  @override
  String get leaveRoomMessage => 'Êtes-vous sûr de vouloir quitter ce salon?';

  @override
  String get roomTitle => 'Titre du salon';

  @override
  String get roomTitleHint => 'Entrez le titre du salon';

  @override
  String get roomTopic => 'Sujet';

  @override
  String get roomLanguage => 'Langue';

  @override
  String get roomHost => 'Hôte';

  @override
  String roomParticipants(int count) {
    return '$count participants';
  }

  @override
  String roomMaxParticipants(int count) {
    return 'Max. $count participants';
  }

  @override
  String get selectTopic => 'Sélectionner le sujet';

  @override
  String get raiseHand => 'Lever la main';

  @override
  String get lowerHand => 'Baisser la main';

  @override
  String get handRaisedNotification => 'Main levée! L\'hôte verra votre demande.';

  @override
  String get handLoweredNotification => 'Main baissée';

  @override
  String get muteParticipant => 'Mettre en sourdine';

  @override
  String get kickParticipant => 'Retirer du salon';

  @override
  String get promoteToCoHost => 'Promouvoir co-hôte';

  @override
  String get endRoomConfirm => 'Terminer le salon?';

  @override
  String get endRoomMessage => 'Cela terminera le salon pour tous les participants.';

  @override
  String get roomEnded => 'Salon fermé par l\'hôte';

  @override
  String get youWereRemoved => 'Vous avez été retiré du salon';

  @override
  String get roomIsFull => 'Le salon est plein';

  @override
  String get roomChat => 'Chat du salon';

  @override
  String get noMessages => 'Pas encore de messages';

  @override
  String get typeMessage => 'Tapez un message...';

  @override
  String get voiceRoomsDescription => 'Rejoignez des conversations en direct et pratiquez la parole';

  @override
  String liveRoomsCount(int count) {
    return '$count en direct';
  }

  @override
  String get noActiveRooms => 'Aucun salon actif';

  @override
  String get noActiveRoomsDescription => 'Soyez le premier à lancer un salon vocal et pratiquez avec les autres!';

  @override
  String get startRoom => 'Démarrer un salon';

  @override
  String get createRoom => 'Créer un salon';

  @override
  String get roomCreated => 'Salon créé avec succès!';

  @override
  String get failedToCreateRoom => 'Échec de création du salon';

  @override
  String get errorLoadingRooms => 'Erreur de chargement des salons';

  @override
  String get pleaseEnterRoomTitle => 'Veuillez entrer un titre de salon';

  @override
  String get startLiveConversation => 'Démarrer une conversation en direct';

  @override
  String get maxParticipants => 'Max. participants';

  @override
  String nPeople(int count) {
    return '$count personnes';
  }

  @override
  String hostedBy(String name) {
    return 'Hébergé par $name';
  }

  @override
  String get liveLabel => 'EN DIRECT';

  @override
  String get joinLabel => 'Rejoindre';

  @override
  String get fullLabel => 'Complet';

  @override
  String get justStarted => 'Vient de commencer';

  @override
  String get allLanguages => 'Toutes les langues';

  @override
  String get allTopics => 'Tous les sujets';

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
  String get you => 'Vous';

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
  String get dataAndStorage => 'Données et Stockage';

  @override
  String get manageStorageAndDownloads => 'Gérer le stockage et les téléchargements';

  @override
  String get storageUsage => 'Utilisation du Stockage';

  @override
  String get totalCacheSize => 'Taille Totale du Cache';

  @override
  String get imageCache => 'Cache d\'Images';

  @override
  String get voiceMessagesCache => 'Messages Vocaux';

  @override
  String get videoCache => 'Cache Vidéo';

  @override
  String get otherCache => 'Autre Cache';

  @override
  String get autoDownloadMedia => 'Téléchargement Auto des Médias';

  @override
  String get currentNetwork => 'Réseau Actuel';

  @override
  String get images => 'Images';

  @override
  String get videos => 'Vidéos';

  @override
  String get voiceMessagesShort => 'Messages Vocaux';

  @override
  String get documentsLabel => 'Documents';

  @override
  String get wifiOnly => 'WiFi Uniquement';

  @override
  String get never => 'Jamais';

  @override
  String get clearAllCache => 'Effacer Tout le Cache';

  @override
  String get allCache => 'Tout le Cache';

  @override
  String get clearAllCacheConfirmation => 'Cela supprimera toutes les images, messages vocaux, vidéos et autres fichiers en cache. L\'application peut charger le contenu plus lentement temporairement.';

  @override
  String clearCacheConfirmationFor(String category) {
    return 'Effacer $category?';
  }

  @override
  String storageToFree(String size) {
    return '$size seront libérés';
  }

  @override
  String get calculating => 'Calcul en cours...';

  @override
  String get noDataToShow => 'Aucune donnée à afficher';

  @override
  String get profileCompletion => 'Profil complété';

  @override
  String get justGettingStarted => 'Tout juste commencé';

  @override
  String get lookingGood => 'C\'est bien !';

  @override
  String get almostThere => 'Presque fini !';

  @override
  String addMissingFields(String fields, Object field) {
    return 'Ajouter : $fields';
  }

  @override
  String get profilePicture => 'Photo de profil';

  @override
  String get nativeSpeaker => 'Locuteur natif';

  @override
  String peopleInterestedInTopic(Object count) {
    return 'Personnes intéressées par ce sujet';
  }

  @override
  String get beFirstToAddTopic => 'Soyez le premier à ajouter ce sujet à vos intérêts !';

  @override
  String get recentMoments => 'Moments récents';

  @override
  String get seeAll => 'Voir tout';

  @override
  String get study => 'Étudier';

  @override
  String get followerMoments => 'Moments des abonnements';

  @override
  String get whenPeopleYouFollowPost => 'Quand les personnes que vous suivez publient de nouveaux moments';

  @override
  String get noNotificationsYet => 'Pas encore de notifications';

  @override
  String get whenYouGetNotifications => 'Quand vous recevrez des notifications, elles apparaîtront ici';

  @override
  String get failedToLoadNotifications => 'Échec du chargement des notifications';

  @override
  String get clearAllNotificationsConfirm => 'Êtes-vous sûr de vouloir effacer toutes les notifications ? Cette action est irréversible.';

  @override
  String get tapToChange => 'Appuyez pour modifier';

  @override
  String get noPictureSet => 'Aucune photo définie';

  @override
  String get nameAndGender => 'Nom et Genre';

  @override
  String get languageLevel => 'Niveau de Langue';

  @override
  String get personalInformation => 'Informations Personnelles';

  @override
  String get mbti => 'MBTI';

  @override
  String get topicsOfInterest => 'Centres d\'Intérêt';

  @override
  String get levelBeginner => 'Débutant';

  @override
  String get levelElementary => 'Élémentaire';

  @override
  String get levelIntermediate => 'Intermédiaire';

  @override
  String get levelUpperIntermediate => 'Intermédiaire Supérieur';

  @override
  String get levelAdvanced => 'Avancé';

  @override
  String get levelProficient => 'Maîtrise';

  @override
  String get selectYourLevel => 'Sélectionnez Votre Niveau';

  @override
  String howWellDoYouSpeak(String language) {
    return 'Quel est votre niveau en $language ?';
  }

  @override
  String get theLanguage => 'la langue';

  @override
  String languageLevelSetTo(String level) {
    return 'Niveau de langue défini sur $level';
  }

  @override
  String get failedToUpdate => 'Échec de la mise à jour';

  @override
  String get editHometown => 'Modifier la Ville d\'Origine';

  @override
  String get useCurrentLocation => 'Utiliser la Position Actuelle';

  @override
  String get detecting => 'Détection...';

  @override
  String get getCurrentLocation => 'Obtenir la Position Actuelle';

  @override
  String get country => 'Pays';

  @override
  String get city => 'Ville';

  @override
  String get coordinates => 'Coordonnées';

  @override
  String get noLocationDetectedYet => 'Aucune position détectée pour l\'instant.';

  @override
  String get detected => 'Détecté';

  @override
  String get savedHometown => 'Ville d\'origine enregistrée';

  @override
  String get locationServicesDisabled => 'Les services de localisation sont désactivés. Veuillez les activer.';

  @override
  String get locationPermissionPermanentlyDenied => 'Les autorisations de localisation sont définitivement refusées.';

  @override
  String get unknown => 'Inconnu';

  @override
  String get editBio => 'Modifier la Bio';

  @override
  String get bioUpdatedSuccessfully => 'Bio mise à jour avec succès';

  @override
  String get tellOthersAboutYourself => 'Parlez-nous de vous...';

  @override
  String charactersCount(int count) {
    return '$count/500 caractères';
  }

  @override
  String get selectYourMbti => 'Sélectionnez Votre MBTI';

  @override
  String get myBloodType => 'Mon Groupe Sanguin';

  @override
  String get pleaseSelectABloodType => 'Veuillez sélectionner un groupe sanguin';

  @override
  String get nativeLanguageRequired => 'Langue Maternelle (Obligatoire)';

  @override
  String get languageToLearnRequired => 'Langue à Apprendre (Obligatoire)';

  @override
  String get nativeLanguageCannotBeSame => 'La langue maternelle ne peut pas être la même que la langue que vous apprenez';

  @override
  String get learningLanguageCannotBeSame => 'La langue que vous apprenez ne peut pas être la même que votre langue maternelle';

  @override
  String get pleaseSelectALanguage => 'Veuillez sélectionner une langue';

  @override
  String get editInterests => 'Modifier les Intérêts';

  @override
  String maxTopicsAllowed(int count) {
    return 'Maximum $count sujets autorisés';
  }

  @override
  String get topicsUpdatedSuccessfully => 'Sujets mis à jour avec succès !';

  @override
  String get failedToUpdateTopics => 'Échec de la mise à jour des sujets';

  @override
  String selectedCount(int count, int max) {
    return '$count/$max sélectionnés';
  }

  @override
  String get profilePictures => 'Photos de Profil';

  @override
  String get addImages => 'Ajouter des Images';

  @override
  String get selectUpToImages => 'Sélectionnez jusqu\'à 5 images';

  @override
  String get takeAPhoto => 'Prendre une Photo';

  @override
  String get removeImage => 'Supprimer l\'Image';

  @override
  String get removeImageConfirm => 'Êtes-vous sûr de vouloir supprimer cette image ?';

  @override
  String get removeAll => 'Tout Supprimer';

  @override
  String get removeAllSelectedImages => 'Supprimer Toutes les Images Sélectionnées';

  @override
  String get removeAllSelectedImagesConfirm => 'Êtes-vous sûr de vouloir supprimer toutes les images sélectionnées ?';

  @override
  String get yourProfilePictureWillBeKept => 'Votre photo de profil existante sera conservée';

  @override
  String get removeAllImages => 'Supprimer Toutes les Images';

  @override
  String get removeAllImagesConfirm => 'Êtes-vous sûr de vouloir supprimer toutes les photos de profil ?';

  @override
  String get currentImages => 'Images Actuelles';

  @override
  String get newImages => 'Nouvelles Images';

  @override
  String get addMoreImages => 'Ajouter Plus d\'Images';

  @override
  String uploadImages(int count) {
    return 'Télécharger $count Image(s)';
  }

  @override
  String get imageRemovedSuccessfully => 'Image supprimée avec succès';

  @override
  String get imagesUploadedSuccessfully => 'Images téléchargées avec succès';

  @override
  String get selectedImagesCleared => 'Images sélectionnées supprimées';

  @override
  String get extraImagesRemovedSuccessfully => 'Images supplémentaires supprimées avec succès';

  @override
  String get mustKeepAtLeastOneProfilePicture => 'Vous devez garder au moins une photo de profil';

  @override
  String get noProfilePicturesToRemove => 'Aucune photo de profil à supprimer';

  @override
  String get authenticationTokenNotFound => 'Jeton d\'authentification non trouvé';

  @override
  String get saveChangesQuestion => 'Enregistrer les Modifications ?';

  @override
  String youHaveUnuploadedImages(int count) {
    return 'Vous avez $count image(s) sélectionnée(s) mais non téléchargée(s). Voulez-vous les télécharger maintenant ?';
  }

  @override
  String get discard => 'Abandonner';

  @override
  String get upload => 'Télécharger';

  @override
  String maxImagesInfo(int max, int current) {
    return 'Vous pouvez télécharger jusqu\'à $max images. Actuel : $current/$max\nMax 5 images par téléchargement.';
  }

  @override
  String canOnlyAddMoreImages(int count, int max) {
    return 'Vous ne pouvez ajouter que $count image(s) supplémentaire(s). Maximum $max images.';
  }

  @override
  String get maxImagesPerUpload => 'Vous ne pouvez télécharger que 5 images maximum à la fois. Seules les 5 premières seront ajoutées.';

  @override
  String canOnlyHaveMaxImages(int max) {
    return 'Vous ne pouvez avoir que $max images maximum';
  }

  @override
  String get imageSizeExceedsLimit => 'La taille de l\'image dépasse la limite de 10 Mo';

  @override
  String get unsupportedImageFormat => 'Format d\'image non pris en charge';

  @override
  String get pleaseSelectAtLeastOneImage => 'Veuillez sélectionner au moins une image à télécharger';

  @override
  String get basicInformation => 'Informations de Base';

  @override
  String get languageToLearn => 'Langue à Apprendre';

  @override
  String get hometown => 'Ville d\'Origine';

  @override
  String get characters => 'caractères';

  @override
  String get failedToLoadLanguages => 'Échec du chargement des langues';

  @override
  String get studyHub => 'Centre d\'études';

  @override
  String get dailyLearningJourney => 'Votre parcours d\'apprentissage quotidien';

  @override
  String get learnTab => 'Apprendre';

  @override
  String get aiTools => 'Outils IA';

  @override
  String get streak => 'Série';

  @override
  String get lessons => 'Leçons';

  @override
  String get words => 'Mots';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get review => 'Réviser';

  @override
  String wordsDue(int count) {
    return '$count mots à réviser';
  }

  @override
  String get addWords => 'Ajouter des mots';

  @override
  String get buildVocabulary => 'Enrichir le vocabulaire';

  @override
  String get practiceWithAI => 'Pratiquer avec l\'IA';

  @override
  String get aiPracticeDescription => 'Chat, quiz, grammaire et prononciation';

  @override
  String get dailyChallenges => 'Défis quotidiens';

  @override
  String get allChallengesCompleted => 'Tous les défis terminés !';

  @override
  String get continueLearning => 'Continuer l\'apprentissage';

  @override
  String get structuredLearningPath => 'Parcours d\'apprentissage structuré';

  @override
  String get vocabulary => 'Vocabulaire';

  @override
  String get yourWordCollection => 'Votre collection de mots';

  @override
  String get achievements => 'Succès';

  @override
  String get badgesAndMilestones => 'Badges et jalons';

  @override
  String get failedToLoadLearningData => 'Échec du chargement des données d\'apprentissage';

  @override
  String get startYourJourney => 'Commencez votre voyage !';

  @override
  String get startJourneyDescription => 'Terminez des leçons, enrichissez votre vocabulaire\net suivez vos progrès';

  @override
  String levelN(int level) {
    return 'Niveau $level';
  }

  @override
  String xpEarned(int xp) {
    return '$xp XP gagnés';
  }

  @override
  String nextLevel(int level) {
    return 'Suivant : Niveau $level';
  }

  @override
  String xpToGo(int xp) {
    return '$xp XP restants';
  }

  @override
  String get aiConversationPartner => 'Partenaire de conversation IA';

  @override
  String get practiceWithAITutor => 'Entraînez-vous à parler avec votre tuteur IA';

  @override
  String get startConversation => 'Démarrer la conversation';

  @override
  String get aiFeatures => 'Fonctionnalités IA';

  @override
  String get aiLessons => 'Leçons IA';

  @override
  String get learnWithAI => 'Apprendre avec l\'IA';

  @override
  String get grammar => 'Grammaire';

  @override
  String get checkWriting => 'Vérifier l\'écriture';

  @override
  String get pronunciation => 'Prononciation';

  @override
  String get improveSpeaking => 'Améliorer l\'expression orale';

  @override
  String get translation => 'Traduction';

  @override
  String get smartTranslate => 'Traduction intelligente';

  @override
  String get aiQuizzes => 'Quiz IA';

  @override
  String get testKnowledge => 'Tester les connaissances';

  @override
  String get lessonBuilder => 'Créateur de leçons';

  @override
  String get customLessons => 'Leçons personnalisées';

  @override
  String get yourAIProgress => 'Vos progrès IA';

  @override
  String get quizzes => 'Quiz';

  @override
  String get avgScore => 'Score moyen';

  @override
  String get focusAreas => 'Domaines à travailler';

  @override
  String accuracyPercent(String accuracy) {
    return '$accuracy% de précision';
  }

  @override
  String get practice => 'Pratiquer';

  @override
  String get browse => 'Parcourir';

  @override
  String get noRecommendedLessons => 'Aucune leçon recommandée disponible';

  @override
  String get noLessonsFound => 'Aucune leçon trouvée';

  @override
  String get createCustomLessonDescription => 'Créez votre propre leçon personnalisée avec l\'IA';

  @override
  String get createLessonWithAI => 'Créer une leçon avec l\'IA';

  @override
  String get allLevels => 'Tous les niveaux';

  @override
  String get levelA1 => 'A1 Débutant';

  @override
  String get levelA2 => 'A2 Élémentaire';

  @override
  String get levelB1 => 'B1 Intermédiaire';

  @override
  String get levelB2 => 'B2 Inter. avancé';

  @override
  String get levelC1 => 'C1 Avancé';

  @override
  String get levelC2 => 'C2 Maîtrise';

  @override
  String get failedToLoadLessons => 'Échec du chargement des leçons';

  @override
  String get pin => 'Épingler';

  @override
  String get unpin => 'Désépingler';

  @override
  String get editMessage => 'Modifier le message';

  @override
  String get enterMessage => 'Saisissez un message...';

  @override
  String get deleteMessageTitle => 'Supprimer le message';

  @override
  String get actionCannotBeUndone => 'Cette action est irréversible.';

  @override
  String get onlyRemovesFromDevice => 'Supprime uniquement de votre appareil';

  @override
  String get availableWithinOneHour => 'Disponible dans l\'heure uniquement';

  @override
  String get available => 'Disponible';

  @override
  String get forwardMessage => 'Transférer le message';

  @override
  String get selectUsersToForward => 'Sélectionnez les destinataires :';

  @override
  String forwardCount(int count) {
    return 'Transférer ($count)';
  }

  @override
  String get pinnedMessage => 'Message épinglé';

  @override
  String get photoMedia => 'Photo';

  @override
  String get videoMedia => 'Vidéo';

  @override
  String get voiceMessageMedia => 'Message vocal';

  @override
  String get documentMedia => 'Document';

  @override
  String get locationMedia => 'Position';

  @override
  String get stickerMedia => 'Autocollant';

  @override
  String get smileys => 'Smileys';

  @override
  String get emotions => 'Émotions';

  @override
  String get handGestures => 'Gestes de la main';

  @override
  String get hearts => 'Cœurs';

  @override
  String get tapToSayHi => 'Appuyez pour dire bonjour !';

  @override
  String get sendWaveToStart => 'Envoyez un signe pour commencer à discuter';

  @override
  String get documentMustBeUnder50MB => 'Le document doit faire moins de 50 Mo.';

  @override
  String get editWithin15Minutes => 'Les messages ne peuvent être modifiés que dans les 15 minutes';

  @override
  String messageForwardedTo(int count) {
    return 'Message transféré à $count utilisateur(s)';
  }

  @override
  String get failedToLoadUsers => 'Échec du chargement des utilisateurs';

  @override
  String get voice => 'Voix';
}
