import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @language_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_english;

  /// No description provided for @language_french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get language_french;

  /// No description provided for @weekday_monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekday_monday;

  /// No description provided for @weekday_tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekday_tuesday;

  /// No description provided for @weekday_wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekday_wednesday;

  /// No description provided for @weekday_thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekday_thursday;

  /// No description provided for @weekday_friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekday_friday;

  /// No description provided for @weekday_saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekday_saturday;

  /// No description provided for @weekday_sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekday_sunday;

  /// No description provided for @locale_popup_btn_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get locale_popup_btn_tooltip;

  /// Indicates that the language has been successfully changed
  ///
  /// In en, this message translates to:
  /// **'Language changed to {locale}'**
  String locale_popup_btn_label(String locale);

  /// No description provided for @onboarding_screen1_title.
  ///
  /// In en, this message translates to:
  /// **'Staring at the clock, waiting for the bus to leave, knowing I\'ll be up early tomorrow — becomes difficult to sleep with endless school work piling up too ... frrrrrrrr'**
  String get onboarding_screen1_title;

  /// No description provided for @onboarding_screen1_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Na, e go pay off one day, sha.'**
  String get onboarding_screen1_subtitle;

  /// No description provided for @onboarding_screen2_title.
  ///
  /// In en, this message translates to:
  /// **'Wanna live and contribute to a better bus experience as from now on?'**
  String get onboarding_screen2_title;

  /// No description provided for @onboarding_screen2_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Hesitate no more...'**
  String get onboarding_screen2_subtitle;

  /// No description provided for @onboarding_cta.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboarding_cta;

  /// No description provided for @authModal_Step1_title.
  ///
  /// In en, this message translates to:
  /// **'You\'re coming as a:'**
  String get authModal_Step1_title;

  /// No description provided for @authModal_Step1_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the profile that best fits you below'**
  String get authModal_Step1_subtitle;

  /// No description provided for @authModal_Step1_option1.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get authModal_Step1_option1;

  /// No description provided for @authModal_Step1_option2.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get authModal_Step1_option2;

  /// No description provided for @authModal_Step1_cta1Proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Authentication'**
  String get authModal_Step1_cta1Proceed;

  /// No description provided for @authModal_Step1_cta2Skip.
  ///
  /// In en, this message translates to:
  /// **'Just skip for now'**
  String get authModal_Step1_cta2Skip;

  /// No description provided for @authModal_Step2_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication happening within'**
  String get authModal_Step2_subtitle;

  /// No description provided for @authModal_Step2_title.
  ///
  /// In en, this message translates to:
  /// **'The ICT University Organization'**
  String get authModal_Step2_title;

  /// No description provided for @authModal_Step2_instruction_slice1.
  ///
  /// In en, this message translates to:
  /// **'You can authenticate with your'**
  String get authModal_Step2_instruction_slice1;

  /// No description provided for @authModal_Step2_instruction_slice2.
  ///
  /// In en, this message translates to:
  /// **'google account'**
  String get authModal_Step2_instruction_slice2;

  /// No description provided for @authModal_Step2_instruction_details.
  ///
  /// In en, this message translates to:
  /// **'This means that only students and school admins having a valid access to their personal google account provided by The ICT University organization can log into BusIn.'**
  String get authModal_Step2_instruction_details;

  /// No description provided for @authModal_Step2_instruction_detailsBullet1.
  ///
  /// In en, this message translates to:
  /// **'This helps us keep tract of our students’ data internally.'**
  String get authModal_Step2_instruction_detailsBullet1;

  /// No description provided for @authModal_Step2_instruction_detailsBullet2.
  ///
  /// In en, this message translates to:
  /// **'Makes the authentication process friendly and quite easier for you.'**
  String get authModal_Step2_instruction_detailsBullet2;

  /// No description provided for @authModal_Step2_cta1Back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get authModal_Step2_cta1Back;

  /// No description provided for @authModal_Step2_cta2Login.
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get authModal_Step2_cta2Login;

  /// No description provided for @anonymousPage_appBar_title.
  ///
  /// In en, this message translates to:
  /// **'Anonymous User'**
  String get anonymousPage_appBar_title;

  /// No description provided for @anonymousPage_appBar_subtitle.
  ///
  /// In en, this message translates to:
  /// **'sign in now'**
  String get anonymousPage_appBar_subtitle;

  /// No description provided for @anonymousPage_warningAlert.
  ///
  /// In en, this message translates to:
  /// **'You\'re not authenticated'**
  String get anonymousPage_warningAlert;

  /// No description provided for @anonymousPage_headline.
  ///
  /// In en, this message translates to:
  /// **'There’s surely a seat available for you'**
  String get anonymousPage_headline;

  /// No description provided for @anonymousPage_listTitle.
  ///
  /// In en, this message translates to:
  /// **'What does BusIn has to offer?'**
  String get anonymousPage_listTitle;

  /// No description provided for @anonymousPage_list_option1Title.
  ///
  /// In en, this message translates to:
  /// **'BusIn for students'**
  String get anonymousPage_list_option1Title;

  /// No description provided for @anonymousPage_list_option1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover how BusIn improves students\' engagement'**
  String get anonymousPage_list_option1Subtitle;

  /// No description provided for @anonymousPage_list_option2Title.
  ///
  /// In en, this message translates to:
  /// **'BusIn for administrators'**
  String get anonymousPage_list_option2Title;

  /// No description provided for @anonymousPage_list_option2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn how BusIn serves the school administration'**
  String get anonymousPage_list_option2Subtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
