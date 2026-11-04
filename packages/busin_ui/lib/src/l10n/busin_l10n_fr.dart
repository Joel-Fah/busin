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
}
