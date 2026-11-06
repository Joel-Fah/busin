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
  String get fieldRequired => 'Ce champ est obligatoire.';

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
  String get statusExpiredTitle => 'Abonnement terminé';

  @override
  String get statusExpiredBody =>
      'Cet abonnement n’est plus valide. Vous pouvez envoyer une nouvelle demande.';

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
}
