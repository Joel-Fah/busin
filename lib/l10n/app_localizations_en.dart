// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language_english => 'English';

  @override
  String get language_french => 'French';

  @override
  String get weekday_monday => 'Monday';

  @override
  String get weekday_tuesday => 'Tuesday';

  @override
  String get weekday_wednesday => 'Wednesday';

  @override
  String get weekday_thursday => 'Thursday';

  @override
  String get weekday_friday => 'Friday';

  @override
  String get weekday_saturday => 'Saturday';

  @override
  String get weekday_sunday => 'Sunday';

  @override
  String get locale_popup_btn_tooltip => 'Change Language';

  @override
  String locale_popup_btn_label(String locale) {
    return 'Language changed to $locale';
  }

  @override
  String get onboarding_screen1_title =>
      'Staring at the clock, waiting for the bus to leave, knowing I\'ll be up early tomorrow — becomes difficult to sleep with endless school work piling up too ... frrrrrrrr';

  @override
  String get onboarding_screen1_subtitle => 'Na, e go pay off one day, sha.';

  @override
  String get onboarding_screen2_title =>
      'Wanna live and contribute to a better bus experience as from now on?';

  @override
  String get onboarding_screen2_subtitle => 'Hesitate no more...';

  @override
  String get onboarding_cta => 'Get Started';

  @override
  String get authModal_Step1_title => 'You\'re coming as a:';

  @override
  String get authModal_Step1_subtitle =>
      'Select the profile that best fits you below';

  @override
  String get authModal_Step1_option1 => 'Student';

  @override
  String get authModal_Step1_option2 => 'Staff';

  @override
  String get authModal_Step1_cta1Proceed => 'Proceed to Authentication';

  @override
  String get authModal_Step1_cta2Skip => 'Just skip for now';

  @override
  String get authModal_Step2_subtitle => 'Authentication happening within';

  @override
  String get authModal_Step2_title => 'The ICT University Organization';

  @override
  String get authModal_Step2_instruction_slice1 =>
      'You can authenticate with your';

  @override
  String get authModal_Step2_instruction_slice2 => 'google account';

  @override
  String get authModal_Step2_instruction_details =>
      'This means that only students and school admins having a valid access to their personal google account provided by The ICT University organization can log into BusIn.';

  @override
  String get authModal_Step2_instruction_detailsBullet1 =>
      'This helps us keep tract of our students’ data internally.';

  @override
  String get authModal_Step2_instruction_detailsBullet2 =>
      'Makes the authentication process friendly and quite easier for you.';

  @override
  String get authModal_Step2_cta1Back => 'Back';

  @override
  String get authModal_Step2_cta2Login => 'Login with Google';

  @override
  String get anonymousPage_appBar_title => 'Anonymous User';

  @override
  String get anonymousPage_appBar_subtitle => 'sign in now';

  @override
  String get anonymousPage_warningAlert => 'You\'re not authenticated';

  @override
  String get anonymousPage_headline =>
      'There’s surely a seat available for you';

  @override
  String get anonymousPage_listTitle => 'What does BusIn has to offer?';

  @override
  String get anonymousPage_list_option1Title => 'BusIn for students';

  @override
  String get anonymousPage_list_option1Subtitle =>
      'Discover how BusIn improves students\' engagement';

  @override
  String get anonymousPage_list_option2Title => 'BusIn for administrators';

  @override
  String get anonymousPage_list_option2Subtitle =>
      'Learn how BusIn serves the school administration';
}
