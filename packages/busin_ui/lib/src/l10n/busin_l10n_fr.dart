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
  String get signInTitle => 'Voyagez avec BusIn';

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
}
