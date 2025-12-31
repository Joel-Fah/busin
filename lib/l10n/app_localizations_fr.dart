// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get language_english => 'Anglais';

  @override
  String get language_french => 'Français';

  @override
  String get weekday_monday => 'Lundi';

  @override
  String get weekday_tuesday => 'Mardi';

  @override
  String get weekday_wednesday => 'Mercredi';

  @override
  String get weekday_thursday => 'Jeudi';

  @override
  String get weekday_friday => 'Vendredi';

  @override
  String get weekday_saturday => 'Samedi';

  @override
  String get weekday_sunday => 'Dimanche';

  @override
  String get locale_popup_btn_tooltip => 'Changez la langue';

  @override
  String locale_popup_btn_label(String locale) {
    return 'Langue changée en $locale';
  }

  @override
  String get backButton => 'Retour';

  @override
  String get continueButton => 'Continuer';

  @override
  String get status => 'Statut';

  @override
  String get statusPending => 'Statut : En attente';

  @override
  String get statusApproved => 'Statut : Approuvé';

  @override
  String get statusRejected => 'Statut : Rejeté';

  @override
  String get roleStudent => 'Etudiant';

  @override
  String get roleStaff => 'Staff';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get accountPending => 'En attente';

  @override
  String get accountVerified => 'Verifié';

  @override
  String get accountSuspended => 'Suspendu';

  @override
  String get subscriptions => 'Abonnements';

  @override
  String get scannings => 'Scans';

  @override
  String get joined => 'Rejoint';

  @override
  String get lastSignIn => 'Dernière connexion';

  @override
  String get lastUpdated => 'Dernière mise à jour';

  @override
  String get start => 'Début';

  @override
  String get end => 'Fin';

  @override
  String get cancel => 'Annuler';

  @override
  String get edit => 'Modifier';

  @override
  String get refresh => 'Rafraîchir';

  @override
  String get retry => 'Réessayer';

  @override
  String get onboarding_screen1_title =>
      'Regarder l\'horloge en attendant le départ du bus, sachant que je devrai me lever tôt demain... Difficile de dormir avec tous ces devoirs qui s\'accumulent… pffffffff';

  @override
  String get onboarding_screen1_subtitle => 'Ça finira par payer un jour.';

  @override
  String get onboarding_screen2_title =>
      'Envie de vivre et de contribuer à une meilleure expérience de bus à partir de maintenant ?';

  @override
  String get onboarding_screen2_subtitle => 'N\'hésitez plus...';

  @override
  String get onboarding_cta => 'Commencer';

  @override
  String get authModal_Step1_title => 'Vous êtes un :';

  @override
  String get authModal_Step1_subtitle =>
      'Sélectionnez le profil qui vous correspond le mieux ci-dessous';

  @override
  String get authModal_Step1_option1 => 'Étudiant';

  @override
  String get authModal_Step1_option2 => 'Staff';

  @override
  String get authModal_Step1_cta1Proceed => 'Procéder à l\'authentification';

  @override
  String get authModal_Step1_cta2Skip => 'Ignorer pour le moment';

  @override
  String get authModal_Step2_subtitle =>
      'Authentification effectuée au sein de';

  @override
  String get authModal_Step2_title => 'L\'organisation, The ICT University';

  @override
  String get authModal_Step2_instruction_slice1 =>
      'Vous pouvez vous authentifier avec votre compte Google : ';

  @override
  String get authModal_Step2_instruction_slice2 => '';

  @override
  String get authModal_Step2_instruction_details =>
      'Cela signifie que seuls les étudiants et les administrateurs de l\'établissement disposant d\'un accès valide à Leur compte Google personnel fourni par l\'organisation ICT University peut se connecter à BusIn.';

  @override
  String get authModal_Step2_instruction_detailsBullet1 =>
      'Cela nous permet de suivre les données de nos étudiants en interne.';

  @override
  String get authModal_Step2_instruction_detailsBullet2 =>
      'Rend le processus d\'authentification plus convivial et plus simple pour vous.';

  @override
  String get authModal_Step2_cta1Back => 'Retour';

  @override
  String get authModal_Step2_cta2Login => 'Se connecter avec Google';

  @override
  String get anonymousPage_appBar_title => 'Utilisateur Anonyme';

  @override
  String get anonymousPage_appBar_subtitle => 'connexion';

  @override
  String get anonymousPage_warningAlert => 'Vous n\'êtes pas authentifié';

  @override
  String get anonymousPage_headline =>
      'Il y a sûrement une place de libre pour vous';

  @override
  String get anonymousPage_listTitle => 'Qu\'est-ce que BusIn a à offrir ?';

  @override
  String get anonymousPage_list_option1Title => 'BusIn pour les étudiants';

  @override
  String get anonymousPage_list_option1Subtitle =>
      'Découvrez comment BusIn améliore l\'engagement des étudiants';

  @override
  String get anonymousPage_list_option2Title =>
      'BusIn pour les administrateurs';

  @override
  String get anonymousPage_list_option2Subtitle =>
      'Apprenez comment BusIn se met au service de l\'administration';

  @override
  String get authModal_initialPage_title => 'Bienvenue sur BusIn';

  @override
  String get authModal_initialPage_subtitle =>
      'Votre gestionnaire intelligent d\'abonnement de bus';

  @override
  String get authModal_initialPage_question => 'Vous avez déjà un compte ?';

  @override
  String get authModal_actions_login => 'Se connecter avec Google';

  @override
  String get authModal_actions_signup => 'Nouveau ici ? S\'inscrire';

  @override
  String get authModal_actions_skip => 'Ignorer pour le moment';

  @override
  String get authModal_loginStep_title => 'Bon retour parmi nous !';

  @override
  String get authModal_loginStep_subtitle =>
      'Nous sommes ravis de vous revoir. Connectez-vous pour continuer.';

  @override
  String get authModal_loginStep_info =>
      'Utilisez votre addresse email (@ictuniversity.ed.cm) pour vous connecter en toute sécurité.';

  @override
  String get authModal_loginStep_ctaLogin => 'Se connecter avec Google';

  @override
  String get authModal_loginStep_ctaLoginLoading => 'Connexion ...';

  @override
  String get authModal_signupStep_ctaSignup => 'S\'inscrire avec Google';

  @override
  String get authModal_signupStep_ctaSignupLoading => 'Inscription ...';

  @override
  String get verificationPage_titlePending => 'Vérification en cours';

  @override
  String get verificationPage_titleRejected => 'Vérification refusée';

  @override
  String get verificationPage_titleComplete => 'Vérification terminée';

  @override
  String get verificationPage_descriptionRejected =>
      'Votre demande de compte a été refusée par un administrateur. Veuillez contacter l\'assistance pour plus d\'informations.';

  @override
  String get verificationPage_descriptionPending =>
      'Votre compte est en attente de validation. Vous serez averti(e) dès qu\'il sera validé.';

  @override
  String get verificationPage_descriptionComplete =>
      'Votre compte a été validé ! Vous pouvez maintenant accéder à l\'application.';

  @override
  String get verificationPage_infoAlert_descriptionRejected =>
      'Votre demande n\'a pas été approuvée. Vous pouvez réessayer en créant un nouveau compte ou en contactant un administrateur.';

  @override
  String get verificationPage_infoAlert_descriptionVerified =>
      'Votre compte est prêt ! Cliquez ci-dessous pour accéder à l\'application.';

  @override
  String get verificationPage_infoAlert_descriptionPending =>
      'Un administrateur examinera votre compte prochainement. Cela prend généralement moins de 24 heures.';

  @override
  String get verificationPage_ctaVerified => 'Continuer vers l\'application';

  @override
  String get verificationPage_ctaPending => 'Vérifier le statut';

  @override
  String get verificationPage_ctaPendingLoading => 'Vérification en cours...';

  @override
  String get verificationPage_ctaSignOut => 'Déconnexion';

  @override
  String get verificationPage_labelSupport =>
      'Besoin d\'aide ? Contactez un administrateur.';

  @override
  String get verificationPage_rejectMessage => 'Votre compte a été refusé.';

  @override
  String get verificationPage_checkStatusError =>
      'Erreur lors de la vérification du statut :';

  @override
  String get verificationPage_approvedMessage =>
      'Compte vérifié ! Vous disposez désormais d\'un accès administrateur.';

  @override
  String get verificationPage_navigationError => 'Erreur de navigation :';

  @override
  String get verificationPage_signOutMessage => 'Déconnexion réussie.';

  @override
  String get welcomeModal_titleStudent => 'Bienvenue sur BusIn !';

  @override
  String get welcomeModal_messageStudent =>
      'Salut ! Nous sommes ravis de vous accueillir. La gestion de vos abonnements de bus à ICT University est désormais beaucoup plus simple. Prêt à monter à bord ?';

  @override
  String get welcomeModal_ctaStudent => 'Allons-y !';

  @override
  String get welcomeModal_titleStaff =>
      'Bienvenue sur le portail BusIn pour le personnel';

  @override
  String get welcomeModal_messageStaff =>
      'Merci de rejoindre l\'équipe BusIn. Vous pouvez désormais scanner les codes QR étudiants et vérifier l\'accès aux bus. Simplifions la gestion des transports à ICT University.';

  @override
  String get welcomeModal_ctaStaff => 'Commencer';

  @override
  String get welcomeModal_titleAdmin =>
      'Bienvenue sur le panneau d\'administration BusIn';

  @override
  String get welcomeModal_messageAdmin =>
      'Bienvenue sur le tableau de bord de gestion BusIn. Vous avez un accès complet pour gérer les abonnements, les arrêts de bus, semestres, et superviser l\'ensemble du système de transport. Rationalisons les opérations de ICT University.';

  @override
  String get welcomeModal_ctaAdmin => 'Accéder au tableau de bord';

  @override
  String get homeNav_analyticsTab => 'Analyses';

  @override
  String get homeNav_studentHomeTab => 'Accueil';

  @override
  String get homeNav_subscriptionsTab => 'Abonnements';

  @override
  String get homeNav_scanningsTab => 'Scans';

  @override
  String get homeNav_peopleTab => 'Personnes';

  @override
  String get profilePage_appBar_title => 'Profil';

  @override
  String get profilePage_subHeading_yourData => 'Vos données sur BusIn';

  @override
  String get profilePage_listTile_accountInfo => 'Information du Compte';

  @override
  String get profilePage_accountInfo_subtitle => 'Complétez votre profil';

  @override
  String get profilePage_accountInfo_badge => 'Action requise';

  @override
  String get profilePage_listTile_appearance => 'Apparences';

  @override
  String get profilePage_listTile_legal => 'Légal';

  @override
  String get profilePage_subHeading_busManagement => 'Gestion des bus';

  @override
  String get profilePage_listTile_busStops => 'Arrêts de bus';

  @override
  String get profilePage_busStops_subtitle =>
      'Gérer les lieux de prise en charge des élèves par le bus';

  @override
  String get profilePage_listTile_semesters => 'Semestres';

  @override
  String get profilePage_semesters_subtitle =>
      'Gérer la durée des semestres de bus et plus encore';

  @override
  String get profilePage_listTile_signOut => 'Se déconnecter';

  @override
  String get profilePage_listTile_signOutMessage => 'Déconnexion réussie';

  @override
  String get profilePage_appInfo_rights => 'Tous droits réservés';

  @override
  String get loadingPage_label => 'Chargement de votre aventure...';

  @override
  String get accountInfoPage_missingLabel => 'Manquant : ';

  @override
  String get accountInfoPage_sectionHeader_google =>
      'Informations du compte Google';

  @override
  String get accountInfoPage_googleSection_provider => 'Fournisseur';

  @override
  String get accountInfoPage_googleSection_displayName => 'Nom d\'affichage';

  @override
  String get accountInfoPage_googleSection_displayNameWarning =>
      'Aucun nom d\'affichage défini. Utilisation du nom d\'utilisateur de l\'adresse e-mail par défaut. Mettez à jour votre compte Google pour définir un nom d\'affichage.';

  @override
  String get accountInfoPage_googleSection_email => 'Adresse e-mail';

  @override
  String get accountInfoPage_googleSection_accountStatus => 'Statut du compte';

  @override
  String get accountInfoPage_sectionHeader_contact => 'Informations de contact';

  @override
  String get accountInfoPage_sectionHeader_update =>
      'Mettre à jour vos informations';

  @override
  String get accountInfoPage_editableField_phoneNumber => 'Numéro de téléphone';

  @override
  String get accountInfoPage_editableField_gender => 'Sexe';

  @override
  String get accountInfoPage_editableField_genderNotSpecified => 'Non spécifié';

  @override
  String get accountInfoPage_sectionHeader_studentInfo =>
      'Informations sur l\'étudiant';

  @override
  String get accountInfoPage_sectionHeader_studentDetails =>
      'Détails de l\'étudiant';

  @override
  String get accountInfoPage_editableField_studentID =>
      'Numéro d\'étudiant (matricule)';

  @override
  String get accountInfoPage_editableField_department => 'Département';

  @override
  String get accountInfoPage_editableField_departmentNotProvided =>
      'Non renseigné';

  @override
  String get accountInfoPage_editableField_program =>
      'Programme (spécialisation)';

  @override
  String get accountInfoPage_editableField_programInstruction =>
      'Veuillez d\'abord sélectionner un département';

  @override
  String get accountInfoPage_editableField_programNotProvided =>
      'Non renseigné';

  @override
  String get accountInfoPage_editableField_streetAddress => 'Rue/Quartier';

  @override
  String get accountInfoPage_editableField_streetAddressHint =>
      'Renseignez votre quartier ou rue';

  @override
  String get accountInfoPage_updateSuccessful =>
      'Informations du compte mises à jour avec succès';

  @override
  String get accountInfoPage_updateFailed => 'Échec de la mise à jour :';

  @override
  String get accountInfoPage_ctaSaveChanges => 'Enregistrer les modifications';

  @override
  String get accountInfoPage_ctaSaveChangesLoading => 'Enregistrement...';

  @override
  String get accountInfoPage_roleBadge_labelStudent => 'Compte étudiant';

  @override
  String get accountInfoPage_roleBadge_descriptionStudent =>
      'Souscrivez à un abonnement de bus et profitez pleinement de BusIn.';

  @override
  String get accountInfoPage_roleBadge_labelStaff => 'Membre du Staff';

  @override
  String get accountInfoPage_roleBadge_descriptionStaff =>
      'Gérez les services de bus et aidez les étudiants à répondre à leurs besoins en matière de transport.';

  @override
  String get accountInfoPage_roleBadge_labelAdmin => 'Administrateur';

  @override
  String get accountInfoPage_roleBadge_descriptionAdmin =>
      'Supervisez l\'ensemble du système de gestion des bus et assurez son bon fonctionnement.';

  @override
  String accountInfoPage_editableField_errorRequired(String field) {
    return '$field est obligatoire';
  }

  @override
  String get appearance_appBar_title => 'Apparence';

  @override
  String get appearance_listTile_theme => 'Thème';

  @override
  String get appearance_listTile_language => 'Langue';

  @override
  String get appearance_listTile_themeSystem => 'Système';

  @override
  String get appearance_listTile_themeSystemSubtitle =>
      'S\'adapte automatiquement aux paramètres système';

  @override
  String get appearance_listTile_themeLight => 'Lumineux';

  @override
  String get appearance_listTile_themeLightSubtitle =>
      'Définit le thème de l\'application sur clair avec des couleurs plus vives. Convient pour la journée.';

  @override
  String get appearance_listTile_themeDark => 'Sombre';

  @override
  String get appearance_listTile_themeDarkSubtitle =>
      'Définit le thème de l\'application sur sombre avec des couleurs plus sombres. Confortable pour les yeux en faible luminosité';

  @override
  String get appearance_listTile_selected => 'Sélectionné';

  @override
  String get legalPage_appBar_title => 'Informations légales';

  @override
  String get legalPage_loadingInfo => 'Chargement des informations légales...';

  @override
  String get legalPage_offlineContent => 'Utilisation du contenu hors ligne';

  @override
  String get legalPage_loadingError =>
      'Impossible de charger les informations légales les plus récentes. Affichage de la version en cache.';
}
