// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'busin_l10n.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class BusinL10nFr extends BusinL10n {
  BusinL10nFr([String locale = 'fr']) : super(locale);

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionConfirm => 'Confirmer';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get actionSignOut => 'Se déconnecter';

  @override
  String get stateLoading => 'Chargement...';

  @override
  String get stateEmpty => 'Rien ici pour l\'instant';

  @override
  String get errorGeneric => 'Une erreur s\'est produite. Réessayez.';

  @override
  String get errorOffline =>
      'Pas de connexion. Vérifiez votre réseau et réessayez.';

  @override
  String get errorNotAllowed => 'Vous n\'avez pas accès à ceci.';

  @override
  String get errorNotFound => 'Introuvable.';

  @override
  String get roleStudent => 'Étudiant';

  @override
  String get roleStaff => 'Personnel';

  @override
  String get roleAdmin => 'Administrateur';

  @override
  String get accountPending => 'En attente';

  @override
  String get accountVerified => 'Actif';

  @override
  String get accountSuspended => 'Suspendu';

  @override
  String get subscriptionPending => 'En attente';

  @override
  String get subscriptionApproved => 'Approuvé';

  @override
  String get subscriptionRejected => 'Refusé';

  @override
  String get subscriptionRevoked => 'Révoqué';

  @override
  String get subscriptionExpired => 'Expiré';

  @override
  String get tripScheduled => 'Planifié';

  @override
  String get tripActive => 'En cours';

  @override
  String get tripCompleted => 'Terminé';

  @override
  String get tripCancelled => 'Annulé';

  @override
  String get directionInbound => 'Vers l\'école';

  @override
  String get directionOutbound => 'Retour à la maison';

  @override
  String get semesterFall => 'Automne';

  @override
  String get semesterSpring => 'Printemps';

  @override
  String get semesterSummer => 'Été';

  @override
  String semesterLabel(String name, int year) {
    return '$name $year';
  }

  @override
  String avatarOf(String name) {
    return 'Photo de $name';
  }

  @override
  String setupWelcome(String name) {
    return 'Bienvenue, $name';
  }

  @override
  String get setupBody =>
      'Dites à votre école qui vous êtes pour que le conducteur puisse vous retrouver. Cela prend une minute.';

  @override
  String get setupSave => 'Enregistrer et continuer';

  @override
  String get setupNotYou => 'Ce n’est pas vous ? Se déconnecter';

  @override
  String get fieldFullName => 'Nom complet';

  @override
  String get fieldFullNameHint => 'Comme sur votre carte d’étudiant';

  @override
  String get fieldMatricule => 'Matricule';

  @override
  String get fieldMatriculeHint => 'Par exemple ICT2026-0001';

  @override
  String get fieldPhone => 'Numéro de téléphone';

  @override
  String get fieldPhoneHint => 'Par exemple 677 12 34 56';

  @override
  String get fieldDepartment => 'Département';

  @override
  String get fieldDepartmentHint => 'Choisissez votre département';

  @override
  String get fieldProgram => 'Programme';

  @override
  String get fieldProgramHint => 'Choisissez votre niveau d\'études';

  @override
  String get fieldFaculty => 'Faculté';

  @override
  String get fieldFacultyHint => 'Choisissez votre faculté';

  @override
  String get fieldDepartmentFirst => 'Choisissez d\'abord une faculté';

  @override
  String get choiceNone => 'Non renseigné';

  @override
  String get fieldTooShort => 'Cela semble trop court.';

  @override
  String get fieldTooLong => 'C’est trop long.';

  @override
  String get fieldInvalid =>
      'Vérifiez ce champ : il contient des caractères non acceptés.';

  @override
  String get profileTitle => 'Votre profil';

  @override
  String get profileOpen => 'Ouvrir votre profil';

  @override
  String get profileDetails => 'Vos informations';

  @override
  String get profileEdit => 'Modifier';

  @override
  String get profileNotSet => 'Non renseigné';

  @override
  String profileMemberSince(String date) {
    return 'Membre depuis le $date';
  }

  @override
  String get profileSaved => 'Informations enregistrées.';

  @override
  String get profileSignOut => 'Se déconnecter';

  @override
  String get profileSignOutTitle => 'Se déconnecter de BusIn ?';

  @override
  String get profileSignOutBody => 'Vous devrez vous reconnecter avec Google.';

  @override
  String get profileCredits => 'Illustrations 3D par Thiings (thiings.co)';

  @override
  String get fieldRequired => 'Ce champ est obligatoire.';

  @override
  String get loadingSlowTitle => 'Cela prend plus de temps que d’habitude';

  @override
  String get loadingSlowBody =>
      'Vérifiez votre connexion. BusIn continue d’essayer.';

  @override
  String get loadingLabel => 'Chargement';

  @override
  String get appName => 'BusIn';

  @override
  String get signInTitle => 'Montez à bord. BusIn s’occupe du reste.';

  @override
  String get signInSubtitle =>
      'Connectez-vous avec votre compte Google de l’école pour vous abonner, présenter votre code d’embarquement et suivre votre bus.';

  @override
  String get signInWithGoogle => 'Continuer avec Google';

  @override
  String get signInCancelled => 'La connexion a été annulée.';

  @override
  String get signInFailed => 'La connexion n’a pas fonctionné. Réessayez.';

  @override
  String get signInNotAllowed =>
      'Ce compte Google n’est pas autorisé ici. Utilisez votre compte de l’école.';

  @override
  String get blockedStaffTitle =>
      'Cette application est réservée aux étudiants';

  @override
  String get blockedStaffBody =>
      'Votre compte est un compte de personnel ou d’administrateur. Le personnel utilise l’application BusIn Ops et les administrateurs le portail d’administration.';

  @override
  String get blockedPendingTitle => 'Votre compte attend d’être approuvé';

  @override
  String get blockedPendingBody =>
      'Un administrateur de l’école doit vérifier votre compte avant que vous puissiez utiliser BusIn.';

  @override
  String get blockedSuspendedTitle => 'Votre compte est suspendu';

  @override
  String get blockedSuspendedBody =>
      'Contactez le service transport de votre école pour en connaître la raison.';

  @override
  String get navSubscription => 'Abonnement';

  @override
  String get navQr => 'Code d’embarquement';

  @override
  String get navHistory => 'Historique';

  @override
  String get navProfile => 'Profil';

  @override
  String get profileAppearance => 'Apparence';

  @override
  String get profileAppearanceHint => 'Conservé sur ce téléphone.';

  @override
  String get profileTheme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get profileLanguage => 'Langue';

  @override
  String get languageSystem => 'Système';

  @override
  String get profileHistory => 'Historique des trajets';

  @override
  String get profileHistoryBody =>
      'Chacune de vos montées, de la plus récente à la plus ancienne.';

  @override
  String get navBus => 'Mon bus';

  @override
  String get comingSoonTitle => 'Bientôt disponible';

  @override
  String get comingSoonBody =>
      'Cette partie de l’application est en cours de création.';

  @override
  String get subscriptionNoSemesterTitle =>
      'Aucun semestre ouvert pour le moment';

  @override
  String get subscriptionNoSemesterBody =>
      'Vous pourrez vous abonner dès que votre école aura ajouté le semestre.';

  @override
  String subscriptionStarts(String date) {
    return 'Commence le $date';
  }

  @override
  String subscribeHeading(String semester) {
    return 'S’abonner pour $semester';
  }

  @override
  String get subscribeIntro =>
      'Choisissez où vous montez et ajoutez une photo de votre reçu de paiement. Votre école la vérifie et approuve votre demande.';

  @override
  String get subscribeStopLabel => 'Votre arrêt';

  @override
  String get subscribeStopHint => 'Choisissez où vous montez';

  @override
  String get subscribeStopSearch => 'Rechercher un arrêt';

  @override
  String get subscribeStopNone => 'Aucun arrêt ne correspond.';

  @override
  String get subscribeProofLabel => 'Preuve de paiement';

  @override
  String get subscribeProofHint => 'Ajoutez une photo nette de votre reçu';

  @override
  String get subscribeProofPrivacy =>
      'Seuls vous et les administrateurs de votre école peuvent la voir.';

  @override
  String get proofTakePhoto => 'Prendre une photo';

  @override
  String get proofChoosePhoto => 'Choisir dans la galerie';

  @override
  String get proofChange => 'Changer de photo';

  @override
  String get subscribeSubmit => 'Envoyer la demande';

  @override
  String get subscribeErrorType => 'Utilisez une photo JPEG, PNG ou WebP.';

  @override
  String get subscribeErrorTooLarge =>
      'Cette photo est trop volumineuse. Choisissez-en une de moins de 5 Mo.';

  @override
  String get subscribeErrorExists =>
      'Vous avez déjà une demande pour ce semestre. Tirez vers le bas pour actualiser.';

  @override
  String get subscriptionStop => 'Arrêt';

  @override
  String subscriptionSent(String date) {
    return 'Envoyée le $date';
  }

  @override
  String get proofView => 'Voir votre preuve de paiement en plein écran';

  @override
  String get proofClose => 'Fermer';

  @override
  String get requestsTitle => 'Vos demandes ce semestre';

  @override
  String get requestsHint =>
      'Tout ce qui s’est passé, le plus récent en premier.';

  @override
  String requestOf(String date) {
    return 'Demande du $date';
  }

  @override
  String get requestEventRequested => 'Vous avez envoyé la demande';

  @override
  String get requestEventApproved => 'Votre école l’a approuvée';

  @override
  String get requestEventRejected => 'Votre école l’a refusée';

  @override
  String get requestEventRevoked => 'Votre école y a mis fin';

  @override
  String get requestEventReinstated => 'Votre école vous l’a rendue';

  @override
  String get subscriptionProofTitle => 'Votre preuve de paiement';

  @override
  String get statusPendingTitle => 'Demande envoyée';

  @override
  String get statusPendingBody =>
      'Votre école vérifie votre preuve de paiement. Tirez vers le bas pour voir si une décision a été prise.';

  @override
  String get statusApprovedTitle => 'Vous êtes abonné';

  @override
  String statusApprovedBody(String stop) {
    return 'Vous pouvez monter à l’arrêt $stop.';
  }

  @override
  String get statusApprovedAction => 'Afficher le code d’embarquement';

  @override
  String get statusRejectedTitle => 'Demande non approuvée';

  @override
  String get statusRejectedReason => 'Motif de votre école :';

  @override
  String get statusRejectedNoReason => 'Votre école n’a pas donné de motif.';

  @override
  String get statusRequestAgain => 'Refaire une demande';

  @override
  String get statusRevokedTitle => 'Abonnement terminé par votre école';

  @override
  String get statusRevokedReason => 'Motif de votre école :';

  @override
  String get statusExpiredTitle => 'Abonnement terminé';

  @override
  String get statusExpiredBody =>
      'Cet abonnement n’est plus valide. Vous pouvez envoyer une nouvelle demande.';

  @override
  String get qrChecking => 'Vérification de votre abonnement';

  @override
  String get qrTitle => 'Code d’embarquement';

  @override
  String get qrHint =>
      'Présentez ce code au conducteur ou au personnel au moment de monter.';

  @override
  String get qrImageLabel =>
      'Votre code d’embarquement. Il change toutes les 30 secondes.';

  @override
  String get qrLive => 'Code en direct';

  @override
  String get qrPrivateTitle => 'Gardez votre code pour vous';

  @override
  String get qrPrivateBodyProtected =>
      'Il change tout seul, et les captures d’écran sont désactivées ici.';

  @override
  String get qrPrivateBody =>
      'Il change tout seul et ne fonctionne que pour vous.';

  @override
  String get qrRefreshed => 'Code actualisé.';

  @override
  String get boardTitle => 'Comment monter';

  @override
  String get boardStep1 => 'Ayez cet écran ouvert en arrivant à la porte.';

  @override
  String get boardStep2 =>
      'Approchez votre téléphone du lecteur jusqu’à la confirmation.';

  @override
  String get boardStep3 =>
      'Prenez n’importe quelle place. Votre trajet est enregistré dans l’historique.';

  @override
  String get qrNoSubscriptionTitle => 'Aucun abonnement actif';

  @override
  String get qrNoSubscriptionBody =>
      'Votre code d’embarquement apparaît dès que votre abonnement est approuvé.';

  @override
  String get qrGoToSubscription => 'Aller à l’abonnement';

  @override
  String get qrOfflineTitle =>
      'Connectez-vous une fois pour configurer votre code';

  @override
  String get qrOfflineBody =>
      'Votre téléphone a besoin d’internet une seule fois pour obtenir votre code d’embarquement. Ensuite, il fonctionne sans connexion.';

  @override
  String get historyTitle => 'Vos embarquements';

  @override
  String get historyStatWeek => 'Montées cette semaine';

  @override
  String get historyStatStop => 'Arrêt le plus utilisé';

  @override
  String get historyStatStopNone => 'Aucun pour l’instant';

  @override
  String historyDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count montées',
      one: '1 montée',
    );
    return '$_temp0';
  }

  @override
  String get historyDayFirst => 'Première montée';

  @override
  String get historyDayLast => 'Dernière montée';

  @override
  String get historyDayStops => 'Arrêts utilisés';

  @override
  String get historySelectedDay => 'Jour choisi';

  @override
  String get historyEmptyTitle => 'Aucun embarquement pour le moment';

  @override
  String get historyEmptyBody =>
      'Chaque fois que vous montez avec votre code, il apparaît ici.';

  @override
  String get historyStopUnknown => 'Arrêt non enregistré';

  @override
  String get historyLoadMoreFailed =>
      'Impossible de charger la suite. Touchez pour réessayer.';

  @override
  String get busLockedTitle => 'Le suivi du bus est réservé aux abonnés';

  @override
  String get busLockedBody =>
      'Dès que votre abonnement est approuvé, vous voyez où est votre bus, en direct.';

  @override
  String get busLockedAction => 'Aller à l’abonnement';

  @override
  String get busNoneTitle => 'Aucun bus n’est en service pour le moment';

  @override
  String get busNoneBody =>
      'Dès qu’un trajet démarre, vous pouvez suivre son bus ici.';

  @override
  String get busWaiting => 'En attente de la position du bus.';

  @override
  String busUpdatedSeconds(String seconds) {
    return 'Mis à jour il y a $seconds s';
  }

  @override
  String busUpdatedMinutes(String minutes) {
    return 'Mis à jour il y a $minutes min';
  }

  @override
  String busStale(String minutes) {
    return 'Dernière position il y a $minutes min. Le bus est peut-être hors réseau.';
  }

  @override
  String busSpeed(String kmh) {
    return '$kmh km/h';
  }

  @override
  String busEtaMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get busEtaArriving => 'Arrive';

  @override
  String busEtaCaption(String km, String stop) {
    return '$km km de $stop';
  }

  @override
  String busDistanceKm(String km) {
    return '$km km';
  }

  @override
  String get busEtaLabel => 'Arrivée estimée';

  @override
  String get busRunning => 'Bus en service';

  @override
  String get busYourStop => 'Votre arrêt';

  @override
  String get busRecenter => 'Afficher le bus';

  @override
  String get busLiveFailed =>
      'Les mises à jour en direct ne sont pas disponibles pour le moment.';

  @override
  String get busMapLabel => 'Carte du bus et des arrêts';

  @override
  String get pushPromptTitle => 'Soyez prévenu';

  @override
  String get pushPromptBody =>
      'Nous pouvons vous prévenir dès que votre école statue sur votre demande, même lorsque l’application est fermée.';

  @override
  String get pushPromptEnable => 'Activer les notifications';

  @override
  String get pushPromptLater => 'Plus tard';

  @override
  String get pushPromptDenied =>
      'Les notifications sont désactivées. Vous pouvez les activer dans les réglages de votre téléphone.';

  @override
  String get pushForegroundApproved => 'Votre abonnement a été approuvé.';

  @override
  String get pushForegroundRejected =>
      'Votre école a statué sur votre abonnement.';

  @override
  String get liveReinstated => 'Votre école vous a rendu votre abonnement.';

  @override
  String get liveRevoked => 'Votre école a mis fin à votre abonnement.';

  @override
  String get pushForegroundView => 'Voir';

  @override
  String get navQrShort => 'Code';

  @override
  String get greetMorning => 'Bonjour';

  @override
  String get greetAfternoon => 'Bon après-midi';

  @override
  String get greetEvening => 'Bonsoir';

  @override
  String get stageSent => 'Envoyée';

  @override
  String get stageChecking => 'Vérification';

  @override
  String get stageDecided => 'Décision';

  @override
  String stageSemantics(String number, String total, String label) {
    return 'Étape $number sur $total : $label';
  }

  @override
  String get howTitle => 'Comment ça marche';

  @override
  String get howStep1 => 'Choisissez où vous montez.';

  @override
  String get howStep2 => 'Ajoutez une photo de votre reçu de paiement.';

  @override
  String get howStep3 => 'Votre école la vérifie et décide.';

  @override
  String get howStep4 => 'Présentez votre code d’embarquement et voyagez.';

  @override
  String get proofAdded => 'Photo ajoutée';

  @override
  String get legalTitle => 'Mentions légales';

  @override
  String get legalHint =>
      'Conditions et confidentialité. Elles sont dans l’application, donc lisibles hors connexion.';

  @override
  String get legalTerms => 'Conditions d’utilisation';

  @override
  String get legalTermsBody => 'Les règles pour utiliser BusIn';

  @override
  String get legalPrivacy => 'Politique de confidentialité';

  @override
  String get legalPrivacyBody => 'Ce que nous gardons sur vous, et pourquoi';

  @override
  String get legalAcceptable => 'Usage acceptable';

  @override
  String get legalAcceptableBody => 'Ce qui est permis et ce qui ne l’est pas';

  @override
  String get legalInShort => 'En bref';

  @override
  String legalUpdated(String date) {
    return 'Mis à jour le $date';
  }

  @override
  String legalAppliesTo(String school) {
    return 'S’applique à $school';
  }

  @override
  String get legalAlsoRead => 'À lire aussi';

  @override
  String get legalQuestionsTitle => 'Des questions sur vos données ?';

  @override
  String get legalQuestionsBody =>
      'Adressez-vous à l’administration de votre école. Elle peut corriger vos informations et répondre aux demandes concernant votre compte.';

  @override
  String legalReadTime(int minutes) {
    return '$minutes min de lecture';
  }

  @override
  String get legalOnThisPage => 'Sur cette page';

  @override
  String get offlineTitle => 'Pas de connexion';

  @override
  String offlineBody(String when) {
    return 'Votre pass enregistré fonctionne toujours à la porte. Dernière mise à jour : $when.';
  }

  @override
  String offlineSavedCopy(String when) {
    return 'Ceci est la copie enregistrée sur ce téléphone ($when). Connectez-vous à Internet pour envoyer ou modifier une demande.';
  }

  @override
  String get offlineNeedsConnection =>
      'Connectez-vous à Internet pour envoyer votre demande.';

  @override
  String get proofUnavailable => 'Votre preuve de paiement';

  @override
  String get proofUnavailableHint =>
      'Elle n’a pas pu être chargée. Touchez pour réessayer.';

  @override
  String get joinTitle => 'Choisissez votre école';

  @override
  String get joinBody =>
      'Votre compte Google n\'est pas un e-mail d\'école : demandez à votre école de vous accepter. Un administrateur vérifiera que c\'est bien vous.';

  @override
  String get joinSearch => 'Rechercher votre école';

  @override
  String get joinSearchHint => 'Nom ou ville';

  @override
  String get joinEmptyTitle => 'Aucune école n\'accepte encore votre e-mail';

  @override
  String get joinEmptyBody =>
      'Connectez-vous avec l\'e-mail de votre école, ou demandez à votre école d\'accepter les étudiants avec d\'autres adresses.';

  @override
  String get joinNoMatch => 'Aucune école ne correspond à votre recherche.';

  @override
  String joinConfirmTitle(String school) {
    return 'Demander à rejoindre $school ?';
  }

  @override
  String joinConfirmBody(String school) {
    return 'Un administrateur de $school vérifiera que vous êtes bien son étudiant. Vous pouvez changer votre demande pendant l\'attente.';
  }

  @override
  String get joinConfirmAction => 'Demander à rejoindre';

  @override
  String get joinSent => 'Demande envoyée.';

  @override
  String get joinTooSoon =>
      'Attendez quelques secondes avant de changer votre demande.';

  @override
  String joinDeclinedTitle(String school) {
    return '$school a refusé votre demande';
  }

  @override
  String get joinDeclinedNoReason =>
      'Aucune raison n\'a été donnée. Vous pouvez demander une autre école, ou la contacter.';

  @override
  String joinDeclinedReason(String reason) {
    return 'Leur raison : $reason';
  }

  @override
  String waitingTitle(String school) {
    return 'En attente de $school';
  }

  @override
  String waitingBody(String date) {
    return 'Vous avez demandé à rejoindre le $date. Un administrateur de votre école vérifiera votre demande ; vous pourrez utiliser BusIn dès qu\'il l\'acceptera.';
  }

  @override
  String get waitingCheck => 'Vérifier à nouveau';

  @override
  String get waitingStill =>
      'Toujours en attente. Nous vérifierons à nouveau quand vous reviendrez dans l\'application.';

  @override
  String get waitingChange => 'Choisir une autre école';

  @override
  String joiningTitle(String school) {
    return 'Vous rejoignez $school';
  }

  @override
  String get joiningBody =>
      'L\'e-mail de votre école vous place dans cette école.';

  @override
  String get joiningNotMine => 'Pas mon école ?';

  @override
  String get joiningNotMineTitle => 'Pas votre école ?';

  @override
  String joiningNotMineBody(String school) {
    return 'Vous vous êtes connecté avec un e-mail de $school. Si vous étudiez ailleurs, déconnectez-vous et connectez-vous avec le compte de votre école.';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsHint =>
      'Choisissez vos jours de bus et ce que BusIn vous rappelle.';

  @override
  String get notificationsDays => 'Mes jours de bus';

  @override
  String get notificationsDaysHint =>
      'Les rappels ne viennent que ces jours-là.';

  @override
  String get notificationsMorning => 'Rappel du matin';

  @override
  String get notificationsMorningHint => 'Un petit signe avant de partir.';

  @override
  String get notificationsEvening => 'Rappel du soir';

  @override
  String get notificationsEveningHint =>
      'Bientôt l\'heure de reprendre le bus.';

  @override
  String get notificationsBusNear => 'Bus proche de mon arrêt';

  @override
  String get notificationsBusNearHint =>
      'Quand votre bus est à peu près à ce temps de votre arrêt.';

  @override
  String notificationsBusNearMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get notificationsBoarding => 'Un mot quand je monte';

  @override
  String get notificationsBoardingHint =>
      'Un court message à l\'écran quand votre code est scanné.';

  @override
  String get notificationsSchool => 'De votre école';

  @override
  String get notificationsSchoolHint =>
      'Changements de votre semestre ou du service. Toujours activé.';

  @override
  String notificationsAt(String time) {
    return 'À $time';
  }

  @override
  String get notificationsSaved => 'Enregistré.';

  @override
  String get notificationsPermission =>
      'Autorisez les notifications dans les réglages de votre téléphone pour voir les rappels.';

  @override
  String get reminderMorningTitle => 'Jour de bus';

  @override
  String get reminderMorningBody =>
      'Votre pass est prêt. Ouvrez BusIn pour voir où est le bus.';

  @override
  String get reminderEveningTitle => 'Vous rentrez ?';

  @override
  String get reminderEveningBody =>
      'C\'est bientôt l\'heure du bus. Ouvrez BusIn pour voir où il est.';

  @override
  String get boardedTitle => 'À bord';

  @override
  String boardedEarlier(String time) {
    return 'Vous êtes monté à $time';
  }

  @override
  String get boardedClose => 'Fermer';

  @override
  String get streakTitle => 'Séries';

  @override
  String get streakHint =>
      'Comptez les jours où vous prenez le bus, et rejoignez le classement de votre école.';

  @override
  String get streakOnTitle => 'Garder une série ?';

  @override
  String streakOnBody(String name) {
    return 'BusIn compte les jours où vous montez. Les jours de repos et les jours sans bus ne la cassent pas ; seul un jour de bus manqué la casse. Vous apparaîtrez aussi dans le classement de votre école sous le nom $name. Vous pouvez la désactiver à tout moment.';
  }

  @override
  String get streakOnAction => 'Activer les séries';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série de $count jours',
      one: 'Série de 1 jour',
      zero: 'Pas encore de série',
    );
    return '$_temp0';
  }

  @override
  String streakBest(int count) {
    return 'Record $count';
  }

  @override
  String streakRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trajets ce semestre',
      one: '1 trajet ce semestre',
    );
    return '$_temp0';
  }

  @override
  String get streakSheetTitle => 'Votre série';

  @override
  String get streakRode => 'Monté';

  @override
  String get streakMissed => 'Manqué';

  @override
  String get streakRest => 'Repos ou pas de bus';

  @override
  String get streakToday => 'Aujourd\'hui';

  @override
  String get streakViewLabel => 'Vue de la série';

  @override
  String get streakTabCalendar => 'Calendrier';

  @override
  String get streakTabBoard => 'Classement';

  @override
  String get leaderboardNote =>
      'Les étudiants de votre école qui tiennent une série, par série en cours.';

  @override
  String get leaderboardEmpty => 'Personne n’est encore au classement.';

  @override
  String get leaderboardYou => 'Vous';

  @override
  String leaderboardRank(int rank) {
    return 'Rang $rank';
  }

  @override
  String get pushForegroundBusNear =>
      'Votre bus est à quelques minutes de votre arrêt.';

  @override
  String get areaTitle => 'Ma zone';

  @override
  String get areaHint =>
      'À peu près où vous habitez, pour aider votre école à placer les arrêts. Facultatif.';

  @override
  String get areaLaterHint => 'Ajoutez-la quand vous serez chez vous.';

  @override
  String get areaIntro =>
      'Indiquez à votre école à peu près où vous habitez, pour qu\'elle place les arrêts et prévoie les trajets près des étudiants. C\'est arrondi à environ 500 mètres, jamais suivi, et vous seul pouvez le voir. Votre école ne voit que le nombre d\'étudiants par zone.';

  @override
  String get areaAtHome => 'Êtes-vous chez vous en ce moment ?';

  @override
  String get areaYesHome => 'Oui, je suis chez moi';

  @override
  String get areaNoSearch => 'Non, chercher un lieu';

  @override
  String get areaExplainTitle => 'Une seule lecture, approximative';

  @override
  String get areaExplainBody =>
      'BusIn va demander votre position approximative et la lire une fois. Elle est arrondie à environ 500 mètres avant d\'être enregistrée, et l\'application ne la relit jamais sans que vous le demandiez.';

  @override
  String get areaContinue => 'Continuer';

  @override
  String get areaNameLabel => 'Comment appelez-vous ce coin ?';

  @override
  String get areaNameHint => 'Par exemple votre quartier';

  @override
  String get areaDefaultName => 'Maison';

  @override
  String get areaSave => 'Enregistrer ma zone';

  @override
  String get areaSearchLabel => 'Chercher un quartier ou une rue';

  @override
  String get areaSearchEmpty => 'Aucun lieu trouvé.';

  @override
  String get areaNotSeeing => 'Vous ne trouvez pas votre rue ?';

  @override
  String get areaNotSeeingBody =>
      'Faites-le plutôt depuis chez vous : BusIn lira alors votre position approximative une fois. Votre profil vous le rappellera.';

  @override
  String get areaRemindMe => 'Me le rappeler à la maison';

  @override
  String get areaSaved => 'Votre zone est enregistrée.';

  @override
  String get areaRemoved => 'Votre zone a été supprimée.';

  @override
  String get areaRemove => 'Supprimer ma zone';

  @override
  String get areaChange => 'Modifier';

  @override
  String get areaRounded =>
      'Arrondie à environ 500 mètres. Vous seul pouvez la voir.';

  @override
  String get areaTooFar => 'Ce lieu est trop loin des bus de votre école.';

  @override
  String get areaDenied =>
      'BusIn ne peut pas lire votre position. Vous pouvez chercher un lieu à la place.';

  @override
  String get areaDeniedForever =>
      'La position est bloquée pour BusIn. Autorisez-la dans les réglages du téléphone, ou cherchez un lieu.';

  @override
  String get areaOpenSettings => 'Ouvrir les réglages';

  @override
  String get areaOff => 'La localisation est désactivée sur votre téléphone.';

  @override
  String get areaFailed =>
      'Votre position n\'a pas pu être lue. Réessayez ou cherchez un lieu.';

  @override
  String get areaTooMany =>
      'Trop de recherches. Attendez une minute et réessayez.';

  @override
  String get notificationsSampleSent =>
      'Nous vous avons envoyé un exemple, pour que vous voyiez à quoi il ressemble.';

  @override
  String get sampleBusNearTitle => 'Votre bus arrive';

  @override
  String get sampleBusNearBody =>
      'Il est à quelques minutes de votre arrêt. Ouvrez BusIn pour le suivre.';

  @override
  String get areaOsmCredit => 'Lieux issus des contributeurs OpenStreetMap';

  @override
  String get placeKindArea => 'Quartier';

  @override
  String get placeKindVillage => 'Village ou lieu-dit';

  @override
  String get placeKindStreet => 'Rue';

  @override
  String get placeKindLandmark => 'Lieu connu';

  @override
  String get opsAppName => 'BusIn Ops';

  @override
  String get opsSignInTitle =>
      'Faites rouler les trajets. Vérifiez chaque embarquement.';

  @override
  String get opsSignInSubtitle =>
      'Connexion du personnel. Utilisez votre compte Google de l\'école pour démarrer les trajets, scanner les codes d\'embarquement et partager la position du bus.';

  @override
  String get opsNotStaffTitle => 'Cette application est réservée au personnel';

  @override
  String get opsNotStaffBody =>
      'Les étudiants utilisent l\'application BusIn pour montrer leur code d\'embarquement. Si vous devriez avoir un accès personnel, demandez à l\'administrateur de votre école.';

  @override
  String get opsProblemTitle => 'BusIn Ops n\'a pas pu charger votre compte';

  @override
  String get opsTodayTitle => 'Trajets du jour';

  @override
  String get opsTodayEmpty => 'Aucun trajet n\'est prévu aujourd\'hui.';

  @override
  String get opsTodayMine => 'Qui vous sont confiés';

  @override
  String get opsTodayOthers => 'Autres trajets';

  @override
  String opsDeparts(String time) {
    return 'Départ à $time';
  }

  @override
  String get opsTripTitle => 'Trajet';

  @override
  String get opsStart => 'Démarrer le trajet';

  @override
  String get opsEnd => 'Terminer le trajet';

  @override
  String get opsEndTitle => 'Terminer ce trajet ?';

  @override
  String get opsEndBody =>
      'Plus personne ne pourra y monter, et la position du bus ne sera plus partagée.';

  @override
  String get opsStarted => 'Trajet démarré.';

  @override
  String get opsEnded => 'Trajet terminé.';

  @override
  String get opsAssignedElsewhere =>
      'Confié à un autre membre du personnel. Seuls cette personne ou un administrateur peuvent le démarrer.';

  @override
  String get opsBusBusy =>
      'Ce bus est déjà sur un autre trajet. Terminez d\'abord celui-là.';

  @override
  String get opsNotToday => 'Ce trajet n\'est pas prévu aujourd\'hui.';

  @override
  String get opsNotScheduled => 'Ce trajet a déjà commencé ou est terminé.';

  @override
  String opsBoarded(int count, int capacity) {
    return '$count sur $capacity à bord';
  }

  @override
  String get opsScannerSoon =>
      'Démarrez le trajet pour scanner les codes d\'embarquement.';

  @override
  String get opsProblemBody =>
      'Vérifiez la connexion et réessayez. La première connexion sur un téléphone a besoin d\'une connexion.';

  @override
  String get opsScan => 'Scanner les codes d\'embarquement';

  @override
  String get opsScanHint =>
      'Visez le code d\'embarquement de l\'étudiant avec l\'appareil photo.';

  @override
  String get opsResultBoarded => 'À bord';

  @override
  String get opsResultAlready => 'Déjà à bord';

  @override
  String get opsResultInvalid => 'Code d\'embarquement non valide';

  @override
  String get opsResultExpired =>
      'Ce code a expiré. Demandez à l\'étudiant de rouvrir son code.';

  @override
  String get opsResultNotOnList =>
      'Absent de la liste du jour. Aucun abonnement valide aujourd\'hui.';

  @override
  String get opsResultNoKeys =>
      'La liste du jour manque. Connectez-vous à internet pour la télécharger.';

  @override
  String get opsResultChecking => 'Vérification auprès du serveur...';

  @override
  String get opsResultNotVerified => 'Ce compte n\'est pas actif.';

  @override
  String get opsResultNoSubscription => 'Aucun abonnement valide aujourd\'hui.';

  @override
  String get opsResultUnknown => 'Pas un étudiant de cette école.';

  @override
  String opsKeysStatus(int count, String time) {
    return 'Liste du jour : $count passagers, mise à jour à $time';
  }

  @override
  String get opsKeysMissing =>
      'Pas encore de liste pour aujourd\'hui. Connectez-vous pour la télécharger.';

  @override
  String get opsKeysRefresh => 'Mettre la liste à jour';

  @override
  String opsPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scans en attente d\'envoi',
      one: '1 scan en attente d\'envoi',
      zero: 'Tous les scans sont envoyés',
    );
    return '$_temp0';
  }

  @override
  String get opsRefusedLaterTitle =>
      'Refusés par le serveur après l\'embarquement';

  @override
  String get opsRefusedLaterBody =>
      'Le téléphone a laissé monter ces étudiants, mais le serveur n\'a pas accepté l\'embarquement (par exemple un abonnement révoqué depuis ce matin).';

  @override
  String get opsCameraDenied =>
      'Autorisez l\'appareil photo pour scanner les codes d\'embarquement.';

  @override
  String get opsLocationWhyTitle => 'Où chaque embarquement a lieu';

  @override
  String get opsLocationWhyBody =>
      'BusIn Ops enregistre l\'arrêt où chaque étudiant monte, à partir de la position de ce téléphone pendant que le scanner est ouvert. Elle sert à ce trajet et à la planification des arrêts, jamais à vous suivre.';

  @override
  String get opsLocationContinue => 'Continuer';

  @override
  String opsSignOutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count scans attendent encore d\'être envoyés. Connectez-vous d\'abord à internet, puis déconnectez-vous.',
      one: '1 scan attend encore d\'être envoyé. Connectez-vous d\'abord à internet, puis déconnectez-vous.',
    );
    return '$_temp0';
  }

  @override
  String opsAtStop(String stop) {
    return 'À $stop';
  }
}
