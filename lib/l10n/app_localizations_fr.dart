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
}
