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

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Status: Pending'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Status: Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Status: Rejected'**
  String get statusRejected;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @accountPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get accountPending;

  /// No description provided for @accountVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get accountVerified;

  /// No description provided for @accountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get accountSuspended;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @scannings.
  ///
  /// In en, this message translates to:
  /// **'Scannings'**
  String get scannings;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @lastSignIn.
  ///
  /// In en, this message translates to:
  /// **'Last sign in'**
  String get lastSignIn;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

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

  /// No description provided for @authModal_initialPage_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BusIn'**
  String get authModal_initialPage_title;

  /// No description provided for @authModal_initialPage_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your smart bus subscription manager'**
  String get authModal_initialPage_subtitle;

  /// No description provided for @authModal_initialPage_question.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authModal_initialPage_question;

  /// No description provided for @authModal_actions_login.
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get authModal_actions_login;

  /// No description provided for @authModal_actions_signup.
  ///
  /// In en, this message translates to:
  /// **'New here? Sign Up'**
  String get authModal_actions_signup;

  /// No description provided for @authModal_actions_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get authModal_actions_skip;

  /// No description provided for @authModal_loginStep_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get authModal_loginStep_title;

  /// No description provided for @authModal_loginStep_subtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re happy to see you again. Sign in to access your account'**
  String get authModal_loginStep_subtitle;

  /// No description provided for @authModal_loginStep_info.
  ///
  /// In en, this message translates to:
  /// **'Use your ICT University email (@ictuniversity.edu.cm) to sign in'**
  String get authModal_loginStep_info;

  /// No description provided for @authModal_loginStep_ctaLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get authModal_loginStep_ctaLogin;

  /// No description provided for @authModal_loginStep_ctaLoginLoading.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get authModal_loginStep_ctaLoginLoading;

  /// No description provided for @authModal_signupStep_ctaSignup.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get authModal_signupStep_ctaSignup;

  /// No description provided for @authModal_signupStep_ctaSignupLoading.
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get authModal_signupStep_ctaSignupLoading;

  /// No description provided for @verificationPage_titlePending.
  ///
  /// In en, this message translates to:
  /// **'Pending Verification'**
  String get verificationPage_titlePending;

  /// No description provided for @verificationPage_titleRejected.
  ///
  /// In en, this message translates to:
  /// **'Verification Rejected'**
  String get verificationPage_titleRejected;

  /// No description provided for @verificationPage_titleComplete.
  ///
  /// In en, this message translates to:
  /// **'Verification Complete'**
  String get verificationPage_titleComplete;

  /// No description provided for @verificationPage_descriptionRejected.
  ///
  /// In en, this message translates to:
  /// **'Your staff account request has been declined by an administrator. Please contact support for more information.'**
  String get verificationPage_descriptionRejected;

  /// No description provided for @verificationPage_descriptionPending.
  ///
  /// In en, this message translates to:
  /// **'Your staff account is awaiting admin approval. You will be notified once your account has been verified.'**
  String get verificationPage_descriptionPending;

  /// No description provided for @verificationPage_descriptionComplete.
  ///
  /// In en, this message translates to:
  /// **'Your account has been verified! You can now access the application.'**
  String get verificationPage_descriptionComplete;

  /// No description provided for @verificationPage_infoAlert_descriptionRejected.
  ///
  /// In en, this message translates to:
  /// **'Your request was not approved. You can try again by creating a new account or contact an administrator for assistance.'**
  String get verificationPage_infoAlert_descriptionRejected;

  /// No description provided for @verificationPage_infoAlert_descriptionVerified.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready! Click below to access the application.'**
  String get verificationPage_infoAlert_descriptionVerified;

  /// No description provided for @verificationPage_infoAlert_descriptionPending.
  ///
  /// In en, this message translates to:
  /// **'An admin will review your account shortly. This usually takes less than 24 hours.'**
  String get verificationPage_infoAlert_descriptionPending;

  /// No description provided for @verificationPage_ctaVerified.
  ///
  /// In en, this message translates to:
  /// **'Continue to App'**
  String get verificationPage_ctaVerified;

  /// No description provided for @verificationPage_ctaPending.
  ///
  /// In en, this message translates to:
  /// **'Check Status'**
  String get verificationPage_ctaPending;

  /// No description provided for @verificationPage_ctaPendingLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get verificationPage_ctaPendingLoading;

  /// No description provided for @verificationPage_ctaSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get verificationPage_ctaSignOut;

  /// No description provided for @verificationPage_labelSupport.
  ///
  /// In en, this message translates to:
  /// **'Need help? Contact an administrator.'**
  String get verificationPage_labelSupport;

  /// No description provided for @verificationPage_rejectMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been rejected.'**
  String get verificationPage_rejectMessage;

  /// No description provided for @verificationPage_checkStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error checking status:'**
  String get verificationPage_checkStatusError;

  /// No description provided for @verificationPage_approvedMessage.
  ///
  /// In en, this message translates to:
  /// **'Account verified! You now have staff access.'**
  String get verificationPage_approvedMessage;

  /// No description provided for @verificationPage_navigationError.
  ///
  /// In en, this message translates to:
  /// **'Error navigating:'**
  String get verificationPage_navigationError;

  /// No description provided for @verificationPage_signOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully.'**
  String get verificationPage_signOutMessage;

  /// No description provided for @welcomeModal_titleStudent.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BusIn!'**
  String get welcomeModal_titleStudent;

  /// No description provided for @welcomeModal_messageStudent.
  ///
  /// In en, this message translates to:
  /// **'Hey there! We\'re excited to have you on board. Managing your bus subscriptions ath the ICT University just got way easier. Ready to hop on?'**
  String get welcomeModal_messageStudent;

  /// No description provided for @welcomeModal_ctaStudent.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Explore!'**
  String get welcomeModal_ctaStudent;

  /// No description provided for @welcomeModal_titleStaff.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BusIn Staff Portal'**
  String get welcomeModal_titleStaff;

  /// No description provided for @welcomeModal_messageStaff.
  ///
  /// In en, this message translates to:
  /// **'Thank you for joining the BusIn team. You now have access to scan student QR codes and verify bus access. Let\'s make transportation management seamless at the ICT University.'**
  String get welcomeModal_messageStaff;

  /// No description provided for @welcomeModal_ctaStaff.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get welcomeModal_ctaStaff;

  /// No description provided for @welcomeModal_titleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BusIn Admin Panel'**
  String get welcomeModal_titleAdmin;

  /// No description provided for @welcomeModal_messageAdmin.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the BusIn management dashboard. You have full access to manage subscriptions, bus stops, semesters, and oversee the entire transportation system. Let\'s streamline operations for the ICT University.'**
  String get welcomeModal_messageAdmin;

  /// No description provided for @welcomeModal_ctaAdmin.
  ///
  /// In en, this message translates to:
  /// **'Access Dashboard'**
  String get welcomeModal_ctaAdmin;

  /// No description provided for @homeNav_analyticsTab.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get homeNav_analyticsTab;

  /// No description provided for @homeNav_studentHomeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNav_studentHomeTab;

  /// No description provided for @homeNav_subscriptionsTab.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get homeNav_subscriptionsTab;

  /// No description provided for @homeNav_scanningsTab.
  ///
  /// In en, this message translates to:
  /// **'Scannings'**
  String get homeNav_scanningsTab;

  /// No description provided for @homeNav_peopleTab.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get homeNav_peopleTab;

  /// No description provided for @profilePage_appBar_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profilePage_appBar_title;

  /// No description provided for @profilePage_subHeading_yourData.
  ///
  /// In en, this message translates to:
  /// **'Your data on BusIn'**
  String get profilePage_subHeading_yourData;

  /// No description provided for @profilePage_listTile_accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get profilePage_listTile_accountInfo;

  /// No description provided for @profilePage_accountInfo_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile information'**
  String get profilePage_accountInfo_subtitle;

  /// No description provided for @profilePage_accountInfo_badge.
  ///
  /// In en, this message translates to:
  /// **'Action required'**
  String get profilePage_accountInfo_badge;

  /// No description provided for @profilePage_listTile_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profilePage_listTile_appearance;

  /// No description provided for @profilePage_listTile_legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get profilePage_listTile_legal;

  /// No description provided for @profilePage_subHeading_busManagement.
  ///
  /// In en, this message translates to:
  /// **'Bus Management'**
  String get profilePage_subHeading_busManagement;

  /// No description provided for @profilePage_listTile_busStops.
  ///
  /// In en, this message translates to:
  /// **'Bus Stops'**
  String get profilePage_listTile_busStops;

  /// No description provided for @profilePage_busStops_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage places where the bus picks up students'**
  String get profilePage_busStops_subtitle;

  /// No description provided for @profilePage_listTile_semesters.
  ///
  /// In en, this message translates to:
  /// **'Semesters'**
  String get profilePage_listTile_semesters;

  /// No description provided for @profilePage_semesters_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage bus semesters duration and more'**
  String get profilePage_semesters_subtitle;

  /// No description provided for @profilePage_listTile_signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profilePage_listTile_signOut;

  /// No description provided for @profilePage_listTile_signOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully'**
  String get profilePage_listTile_signOutMessage;

  /// No description provided for @profilePage_appInfo_rights.
  ///
  /// In en, this message translates to:
  /// **'All rights reserved'**
  String get profilePage_appInfo_rights;

  /// No description provided for @loadingPage_label.
  ///
  /// In en, this message translates to:
  /// **'Loading your journey...'**
  String get loadingPage_label;

  /// No description provided for @accountInfoPage_missingLabel.
  ///
  /// In en, this message translates to:
  /// **'Missing: '**
  String get accountInfoPage_missingLabel;

  /// No description provided for @accountInfoPage_sectionHeader_google.
  ///
  /// In en, this message translates to:
  /// **'Google Account Information'**
  String get accountInfoPage_sectionHeader_google;

  /// No description provided for @accountInfoPage_googleSection_provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get accountInfoPage_googleSection_provider;

  /// No description provided for @accountInfoPage_googleSection_displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get accountInfoPage_googleSection_displayName;

  /// No description provided for @accountInfoPage_googleSection_displayNameWarning.
  ///
  /// In en, this message translates to:
  /// **'No display name set. Using email username as fallback. Update your Google account to set a display name.'**
  String get accountInfoPage_googleSection_displayNameWarning;

  /// No description provided for @accountInfoPage_googleSection_email.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get accountInfoPage_googleSection_email;

  /// No description provided for @accountInfoPage_googleSection_accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get accountInfoPage_googleSection_accountStatus;

  /// No description provided for @accountInfoPage_sectionHeader_contact.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get accountInfoPage_sectionHeader_contact;

  /// No description provided for @accountInfoPage_sectionHeader_update.
  ///
  /// In en, this message translates to:
  /// **'Update Your Information'**
  String get accountInfoPage_sectionHeader_update;

  /// No description provided for @accountInfoPage_editableField_phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get accountInfoPage_editableField_phoneNumber;

  /// No description provided for @accountInfoPage_editableField_gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get accountInfoPage_editableField_gender;

  /// No description provided for @accountInfoPage_editableField_genderNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get accountInfoPage_editableField_genderNotSpecified;

  /// No description provided for @accountInfoPage_sectionHeader_studentInfo.
  ///
  /// In en, this message translates to:
  /// **'Student Information'**
  String get accountInfoPage_sectionHeader_studentInfo;

  /// No description provided for @accountInfoPage_sectionHeader_studentDetails.
  ///
  /// In en, this message translates to:
  /// **'Student Details'**
  String get accountInfoPage_sectionHeader_studentDetails;

  /// No description provided for @accountInfoPage_editableField_studentID.
  ///
  /// In en, this message translates to:
  /// **'Student ID (Matricule)'**
  String get accountInfoPage_editableField_studentID;

  /// No description provided for @accountInfoPage_editableField_department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get accountInfoPage_editableField_department;

  /// No description provided for @accountInfoPage_editableField_departmentNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get accountInfoPage_editableField_departmentNotProvided;

  /// No description provided for @accountInfoPage_editableField_program.
  ///
  /// In en, this message translates to:
  /// **'Program (Major)'**
  String get accountInfoPage_editableField_program;

  /// No description provided for @accountInfoPage_editableField_programInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please select a department first'**
  String get accountInfoPage_editableField_programInstruction;

  /// No description provided for @accountInfoPage_editableField_programNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get accountInfoPage_editableField_programNotProvided;

  /// No description provided for @accountInfoPage_editableField_streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get accountInfoPage_editableField_streetAddress;

  /// No description provided for @accountInfoPage_editableField_streetAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your street address'**
  String get accountInfoPage_editableField_streetAddressHint;

  /// No description provided for @accountInfoPage_updateSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Account information updated successfully'**
  String get accountInfoPage_updateSuccessful;

  /// No description provided for @accountInfoPage_updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update:'**
  String get accountInfoPage_updateFailed;

  /// No description provided for @accountInfoPage_ctaSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get accountInfoPage_ctaSaveChanges;

  /// No description provided for @accountInfoPage_ctaSaveChangesLoading.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get accountInfoPage_ctaSaveChangesLoading;

  /// No description provided for @accountInfoPage_roleBadge_labelStudent.
  ///
  /// In en, this message translates to:
  /// **'Student Account'**
  String get accountInfoPage_roleBadge_labelStudent;

  /// No description provided for @accountInfoPage_roleBadge_descriptionStudent.
  ///
  /// In en, this message translates to:
  /// **'Make subscriptions to the bus service and make the most out of BusIn.\''**
  String get accountInfoPage_roleBadge_descriptionStudent;

  /// No description provided for @accountInfoPage_roleBadge_labelStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff Member'**
  String get accountInfoPage_roleBadge_labelStaff;

  /// No description provided for @accountInfoPage_roleBadge_descriptionStaff.
  ///
  /// In en, this message translates to:
  /// **'Manage bus services and assist students with their transportation needs.'**
  String get accountInfoPage_roleBadge_descriptionStaff;

  /// No description provided for @accountInfoPage_roleBadge_labelAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get accountInfoPage_roleBadge_labelAdmin;

  /// No description provided for @accountInfoPage_roleBadge_descriptionAdmin.
  ///
  /// In en, this message translates to:
  /// **'Oversee the entire bus management system and ensure smooth operations.'**
  String get accountInfoPage_roleBadge_descriptionAdmin;

  /// Error message indicating that a required field is missing
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String accountInfoPage_editableField_errorRequired(String field);

  /// No description provided for @appearance_appBar_title.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance_appBar_title;

  /// No description provided for @appearance_listTile_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appearance_listTile_theme;

  /// No description provided for @appearance_listTile_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get appearance_listTile_language;

  /// No description provided for @appearance_listTile_themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearance_listTile_themeSystem;

  /// No description provided for @appearance_listTile_themeSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically adjust to system settings'**
  String get appearance_listTile_themeSystemSubtitle;

  /// No description provided for @appearance_listTile_themeLight.
  ///
  /// In en, this message translates to:
  /// **'Bright'**
  String get appearance_listTile_themeLight;

  /// No description provided for @appearance_listTile_themeLightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sets the app’s theme to light with brighter colors. Suitable for daytime.'**
  String get appearance_listTile_themeLightSubtitle;

  /// No description provided for @appearance_listTile_themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dimmed'**
  String get appearance_listTile_themeDark;

  /// No description provided for @appearance_listTile_themeDarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sets the app’s theme to dark with darker colors. Easy on the eyes in low light'**
  String get appearance_listTile_themeDarkSubtitle;

  /// No description provided for @appearance_listTile_selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get appearance_listTile_selected;

  /// No description provided for @legalPage_appBar_title.
  ///
  /// In en, this message translates to:
  /// **'Legal Information'**
  String get legalPage_appBar_title;

  /// No description provided for @legalPage_loadingInfo.
  ///
  /// In en, this message translates to:
  /// **'Loading legal information...'**
  String get legalPage_loadingInfo;

  /// No description provided for @legalPage_offlineContent.
  ///
  /// In en, this message translates to:
  /// **'Using offline content'**
  String get legalPage_offlineContent;

  /// No description provided for @legalPage_loadingError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the latest legal information. Showing cached version.'**
  String get legalPage_loadingError;
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
