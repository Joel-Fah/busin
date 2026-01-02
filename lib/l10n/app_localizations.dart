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

  /// No description provided for @subscriptionPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get subscriptionPending;

  /// No description provided for @subscriptionApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get subscriptionApproved;

  /// No description provided for @subscriptionRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get subscriptionRejected;

  /// No description provided for @subscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get subscriptionExpired;

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

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

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

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at'**
  String get updatedAt;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknown;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get by;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @closing.
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get closing;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @semester.
  ///
  /// In en, this message translates to:
  /// **'Semester'**
  String get semester;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @naLabel.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get naLabel;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get week;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @busStops.
  ///
  /// In en, this message translates to:
  /// **'Bus Stops'**
  String get busStops;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'user(s)'**
  String get users;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @updatedBy.
  ///
  /// In en, this message translates to:
  /// **'Updated by:'**
  String get updatedBy;

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

  /// No description provided for @stopsPage_appBar_title.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get stopsPage_appBar_title;

  /// No description provided for @stopsPage_appBar_actionsNew.
  ///
  /// In en, this message translates to:
  /// **'New stop'**
  String get stopsPage_appBar_actionsNew;

  /// No description provided for @stopsPage_appBar_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter bus stops...'**
  String get stopsPage_appBar_searchHint;

  /// No description provided for @stopsPage_statItem_total.
  ///
  /// In en, this message translates to:
  /// **'Total stops'**
  String get stopsPage_statItem_total;

  /// No description provided for @stopsPage_statItem_withImages.
  ///
  /// In en, this message translates to:
  /// **'With images'**
  String get stopsPage_statItem_withImages;

  /// No description provided for @stopsPage_statItem_withMaps.
  ///
  /// In en, this message translates to:
  /// **'With maps'**
  String get stopsPage_statItem_withMaps;

  /// No description provided for @stopsPage_loadingError.
  ///
  /// In en, this message translates to:
  /// **'Error loading bus stops'**
  String get stopsPage_loadingError;

  /// No description provided for @stopsPage_emptyListMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'No bus stops yet'**
  String get stopsPage_emptyListMessageTitle;

  /// No description provided for @stopsPage_emptyQueryMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'No bus stops found'**
  String get stopsPage_emptyQueryMessageTitle;

  /// No description provided for @stopsPage_emptyListMessageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first bus stop'**
  String get stopsPage_emptyListMessageSubtitle;

  /// No description provided for @stopsPage_emptyQueryMessageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different search query'**
  String get stopsPage_emptyQueryMessageSubtitle;

  /// No description provided for @stopsPage_stopCard_deleteModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Bus Stop'**
  String get stopsPage_stopCard_deleteModalTitle;

  /// No description provided for @stopsPage_stopCard_deleteModalMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get stopsPage_stopCard_deleteModalMessage;

  /// No description provided for @stopsPage_stopCard_deleteModalWarning.
  ///
  /// In en, this message translates to:
  /// **'All data associated with this stop will be permanently deleted.'**
  String get stopsPage_stopCard_deleteModalWarning;

  /// Confirmation message after successfully deleting a bus stop
  ///
  /// In en, this message translates to:
  /// **'Bus stop \"{stop}\" removed successfully'**
  String stopsPage_stopCard_deleteSuccess(String stop);

  /// No description provided for @stopsPage_stopCard_deleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete bus stop'**
  String get stopsPage_stopCard_deleteError;

  /// No description provided for @stopsPage_stopCard_imageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get stopsPage_stopCard_imageUnavailable;

  /// No description provided for @stopsPage_stopCard_noPreview.
  ///
  /// In en, this message translates to:
  /// **'No preview available'**
  String get stopsPage_stopCard_noPreview;

  /// No description provided for @semestersPage_appBar_title.
  ///
  /// In en, this message translates to:
  /// **'Semesters'**
  String get semestersPage_appBar_title;

  /// No description provided for @semestersPage_appBar_actionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add semester'**
  String get semestersPage_appBar_actionsAdd;

  /// No description provided for @semestersPage_appBar_activeSemester.
  ///
  /// In en, this message translates to:
  /// **'Active semester'**
  String get semestersPage_appBar_activeSemester;

  /// No description provided for @semestersPage_infoBubble.
  ///
  /// In en, this message translates to:
  /// **'Define start and end dates for each semester. These dates will be used for subscription validity periods.'**
  String get semestersPage_infoBubble;

  /// No description provided for @semestersPage_statItem_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get semestersPage_statItem_total;

  /// No description provided for @semestersPage_statItem_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get semestersPage_statItem_upcoming;

  /// No description provided for @semestersPage_loadingError.
  ///
  /// In en, this message translates to:
  /// **'Error loading semesters'**
  String get semestersPage_loadingError;

  /// No description provided for @semestersPage_emptyList_title.
  ///
  /// In en, this message translates to:
  /// **'No semesters configured'**
  String get semestersPage_emptyList_title;

  /// No description provided for @semestersPage_emptyList_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first semester to get started'**
  String get semestersPage_emptyList_subtitle;

  /// No description provided for @semestersPage_handleDelete_successful.
  ///
  /// In en, this message translates to:
  /// **'Semester deleted successfully'**
  String get semestersPage_handleDelete_successful;

  /// No description provided for @semestersPage_handleDelete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete semester'**
  String get semestersPage_handleDelete_failed;

  /// No description provided for @semestersPage_handleDelete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Semester'**
  String get semestersPage_handleDelete_title;

  /// No description provided for @semestersPage_handleDelete_subtitle.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get semestersPage_handleDelete_subtitle;

  /// No description provided for @semestersPage_detailRow_startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get semestersPage_detailRow_startDate;

  /// No description provided for @semestersPage_detailRow_endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get semestersPage_detailRow_endDate;

  /// No description provided for @semestersPage_detailRow_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get semestersPage_detailRow_duration;

  /// No description provided for @semestersPage_detailRow_statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get semestersPage_detailRow_statusActive;

  /// No description provided for @semestersPage_detailRow_statusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get semestersPage_detailRow_statusEnded;

  /// No description provided for @semestersPage_detailRow_statusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get semestersPage_detailRow_statusUpcoming;

  /// No description provided for @semestersPage_deleteModal_warning.
  ///
  /// In en, this message translates to:
  /// **'All data associated with this semester will be permanently deleted.'**
  String get semestersPage_deleteModal_warning;

  /// No description provided for @homeTab_title.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get homeTab_title;

  /// No description provided for @homeTab_subscriptionTile_start.
  ///
  /// In en, this message translates to:
  /// **'Start:'**
  String get homeTab_subscriptionTile_start;

  /// No description provided for @homeTab_subscriptionTile_end.
  ///
  /// In en, this message translates to:
  /// **'End:'**
  String get homeTab_subscriptionTile_end;

  /// No description provided for @homeTab_emptySubscriptionCard_title.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get homeTab_emptySubscriptionCard_title;

  /// No description provided for @homeTab_emptySubscriptionCard_message.
  ///
  /// In en, this message translates to:
  /// **'Create your first bus subscription to see it here.'**
  String get homeTab_emptySubscriptionCard_message;

  /// No description provided for @homeTab_scanningsTile_on.
  ///
  /// In en, this message translates to:
  /// **'On:'**
  String get homeTab_scanningsTile_on;

  /// No description provided for @homeTab_scanningsTile_titleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get homeTab_scanningsTile_titleUnavailable;

  /// No description provided for @homeTab_emptyScanningsCard_title.
  ///
  /// In en, this message translates to:
  /// **'No scans yet'**
  String get homeTab_emptyScanningsCard_title;

  /// No description provided for @homeTab_emptyScanningsCard_message.
  ///
  /// In en, this message translates to:
  /// **'Your QR code hasn\'t been scanned yet.'**
  String get homeTab_emptyScanningsCard_message;

  /// No description provided for @subscriptionTab_emptyState_ctaLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscribe now for'**
  String get subscriptionTab_emptyState_ctaLabel;

  /// No description provided for @subscriptionTab_activeCta_message.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any subscription running currently. Maybe, subscribe now to the bus services for the ongoing semester'**
  String get subscriptionTab_activeCta_message;

  /// No description provided for @subscriptionTab_emptyList_message.
  ///
  /// In en, this message translates to:
  /// **'No other subscriptions yet.'**
  String get subscriptionTab_emptyList_message;

  /// Display message after applying a search filter
  ///
  /// In en, this message translates to:
  /// **'No {status} subscriptions match the filter.'**
  String subscriptionTab_emptyList_messageFilter(String status);

  /// No description provided for @subscriptionTab_emptyState_supertitle.
  ///
  /// In en, this message translates to:
  /// **'Seems like it’s your first time around'**
  String get subscriptionTab_emptyState_supertitle;

  /// No description provided for @subscriptionTab_emptyState_title.
  ///
  /// In en, this message translates to:
  /// **'You don’t have any subscriptions yet'**
  String get subscriptionTab_emptyState_title;

  /// No description provided for @subscriptionTab_emptyState_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Let’s get you started with a bus subscription so you can ride this semester.'**
  String get subscriptionTab_emptyState_subtitle;

  /// No description provided for @scanningsTab_screenshotsWarning.
  ///
  /// In en, this message translates to:
  /// **'Hey! Screenshots aren\'t allowed here to keep your QR code safe'**
  String get scanningsTab_screenshotsWarning;

  /// No description provided for @subscriptionDetailPage_appBar_title.
  ///
  /// In en, this message translates to:
  /// **'Subscription Details'**
  String get subscriptionDetailPage_appBar_title;

  /// No description provided for @subscriptionDetailPage_nullContent_title.
  ///
  /// In en, this message translates to:
  /// **'Subscription not found'**
  String get subscriptionDetailPage_nullContent_title;

  /// No description provided for @subscriptionDetailPage_nullContent_message.
  ///
  /// In en, this message translates to:
  /// **'The subscription you are looking for does not exist or has been removed.'**
  String get subscriptionDetailPage_nullContent_message;

  /// No description provided for @subscriptionDetailPage_handleRefresh_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh:'**
  String get subscriptionDetailPage_handleRefresh_error;

  /// No description provided for @subscriptionDetailPage_handleApprove_success.
  ///
  /// In en, this message translates to:
  /// **'Subscription approved'**
  String get subscriptionDetailPage_handleApprove_success;

  /// No description provided for @subscriptionDetailPage_handleApprove_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve subscription:'**
  String get subscriptionDetailPage_handleApprove_error;

  /// No description provided for @subscriptionDetailPage_handleReject_success.
  ///
  /// In en, this message translates to:
  /// **'Subscription rejected'**
  String get subscriptionDetailPage_handleReject_success;

  /// No description provided for @subscriptionDetailPage_handleReject_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject subscription:'**
  String get subscriptionDetailPage_handleReject_error;

  /// No description provided for @subscriptionDetailPage_rejectDialog_title.
  ///
  /// In en, this message translates to:
  /// **'Reject Subscription'**
  String get subscriptionDetailPage_rejectDialog_title;

  /// No description provided for @subscriptionDetailPage_rejectDialog_instruction.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejecting this subscription. This will be shown to the student.'**
  String get subscriptionDetailPage_rejectDialog_instruction;

  /// No description provided for @subscriptionDetailPage_rejectDialog_reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get subscriptionDetailPage_rejectDialog_reasonLabel;

  /// No description provided for @subscriptionDetailPage_rejectDialog_reasonValidatorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejection'**
  String get subscriptionDetailPage_rejectDialog_reasonValidatorEmpty;

  /// No description provided for @subscriptionDetailPage_rejectDialog_reasonValidatorLength.
  ///
  /// In en, this message translates to:
  /// **'Reason must be at least 10 characters long'**
  String get subscriptionDetailPage_rejectDialog_reasonValidatorLength;

  /// No description provided for @subscriptionDetailPage_rejectDialog_ctaReject.
  ///
  /// In en, this message translates to:
  /// **'Reject Subscription'**
  String get subscriptionDetailPage_rejectDialog_ctaReject;

  /// No description provided for @subscriptionDetailPage_reviewInfo_sectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Information'**
  String get subscriptionDetailPage_reviewInfo_sectionTitle;

  /// No description provided for @subscriptionDetailPage_reviewInfo_reviewedOn.
  ///
  /// In en, this message translates to:
  /// **'Reviewed on'**
  String get subscriptionDetailPage_reviewInfo_reviewedOn;

  /// No description provided for @subscriptionDetailPage_reviewInfo_reviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by'**
  String get subscriptionDetailPage_reviewInfo_reviewedBy;

  /// No description provided for @subscriptionDetailPage_statusDates_startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get subscriptionDetailPage_statusDates_startLabel;

  /// No description provided for @subscriptionDetailPage_statusDates_endLabel.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get subscriptionDetailPage_statusDates_endLabel;

  /// No description provided for @subscriptionDetailPage_statusDates_durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get subscriptionDetailPage_statusDates_durationLabel;

  /// No description provided for @subscriptionDetailPage_weeklySchedule_title.
  ///
  /// In en, this message translates to:
  /// **'Weekly Schedule'**
  String get subscriptionDetailPage_weeklySchedule_title;

  /// No description provided for @subscriptionDetailPage_adminAction_approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get subscriptionDetailPage_adminAction_approve;

  /// No description provided for @subscriptionDetailPage_adminAction_reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get subscriptionDetailPage_adminAction_reject;

  /// No description provided for @subscriptionDetailPage_paymentProof_placeholder.
  ///
  /// In en, this message translates to:
  /// **'No proof of payment'**
  String get subscriptionDetailPage_paymentProof_placeholder;

  /// No description provided for @subscriptionDetailPage_statusLabel_approved.
  ///
  /// In en, this message translates to:
  /// **'Subscription Approved'**
  String get subscriptionDetailPage_statusLabel_approved;

  /// No description provided for @subscriptionDetailPage_statusLabel_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending Validation'**
  String get subscriptionDetailPage_statusLabel_pending;

  /// No description provided for @subscriptionDetailPage_statusLabel_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected Subscription'**
  String get subscriptionDetailPage_statusLabel_rejected;

  /// No description provided for @subscriptionDetailPage_statusLabel_expired.
  ///
  /// In en, this message translates to:
  /// **'Expired Subscription'**
  String get subscriptionDetailPage_statusLabel_expired;

  /// No description provided for @subscriptionDetailPage_mapView_title.
  ///
  /// In en, this message translates to:
  /// **'Bus stop'**
  String get subscriptionDetailPage_mapView_title;

  /// No description provided for @subscriptionDetailPage_mapView_openMessageSuccess.
  ///
  /// In en, this message translates to:
  /// **'Opened in Google Maps'**
  String get subscriptionDetailPage_mapView_openMessageSuccess;

  /// No description provided for @subscriptionDetailPage_mapView_openMessageError.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps'**
  String get subscriptionDetailPage_mapView_openMessageError;

  /// No description provided for @subscriptionDetailPage_mapView_ctaLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to open on Google Maps'**
  String get subscriptionDetailPage_mapView_ctaLabel;

  /// No description provided for @subscriptionDetailPage_mapView_ctaTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get subscriptionDetailPage_mapView_ctaTooltip;

  /// No description provided for @subscriptionDetailPage_mapView_pickupImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get subscriptionDetailPage_mapView_pickupImageUnavailable;

  /// No description provided for @subscriptionDetailPage_mapView_pickupImagePreview.
  ///
  /// In en, this message translates to:
  /// **'Pickup point preview'**
  String get subscriptionDetailPage_mapView_pickupImagePreview;

  /// No description provided for @subscriptionDetailPage_studentSection_title.
  ///
  /// In en, this message translates to:
  /// **'Student Information'**
  String get subscriptionDetailPage_studentSection_title;

  /// No description provided for @subscriptionDetailPage_studentSection_loadingError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load student information'**
  String get subscriptionDetailPage_studentSection_loadingError;

  /// No description provided for @subscriptionDetailPage_studentSection_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Subscriber details'**
  String get subscriptionDetailPage_studentSection_subtitle;

  /// No description provided for @subscriptionDetailPage_studentSection_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get subscriptionDetailPage_studentSection_name;

  /// No description provided for @subscriptionDetailPage_studentSection_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get subscriptionDetailPage_studentSection_email;

  /// No description provided for @subscriptionDetailPage_studentSection_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get subscriptionDetailPage_studentSection_status;

  /// No description provided for @subscriptionDetailPage_studentSection_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get subscriptionDetailPage_studentSection_phone;

  /// No description provided for @peopleTab_appBar_title.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get peopleTab_appBar_title;

  /// No description provided for @peopleTab_loadingState.
  ///
  /// In en, this message translates to:
  /// **'Loading users...'**
  String get peopleTab_loadingState;

  /// No description provided for @peopleTab_loadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading users'**
  String get peopleTab_loadError;

  /// No description provided for @peopleTab_loadError_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get peopleTab_loadError_unknown;

  /// No description provided for @peopleTab_emptyStudents_title.
  ///
  /// In en, this message translates to:
  /// **'No Students Yet'**
  String get peopleTab_emptyStudents_title;

  /// No description provided for @peopleTab_emptyStaff_title.
  ///
  /// In en, this message translates to:
  /// **'No Staff Yet'**
  String get peopleTab_emptyStaff_title;

  /// No description provided for @peopleTab_emptyStudents_subtitle.
  ///
  /// In en, this message translates to:
  /// **'There are no students registered yet'**
  String get peopleTab_emptyStudents_subtitle;

  /// No description provided for @peopleTab_emptyStaff_subtitle.
  ///
  /// In en, this message translates to:
  /// **'There are no staff members registered yet'**
  String get peopleTab_emptyStaff_subtitle;

  /// No description provided for @peopleTab_handleApprove_success.
  ///
  /// In en, this message translates to:
  /// **'has been approved!'**
  String get peopleTab_handleApprove_success;

  /// No description provided for @peopleTab_handleApprove_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve user:'**
  String get peopleTab_handleApprove_error;

  /// No description provided for @peopleTab_handleReject_success.
  ///
  /// In en, this message translates to:
  /// **'has been rejected!'**
  String get peopleTab_handleReject_success;

  /// No description provided for @peopleTab_handleReject_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject user:'**
  String get peopleTab_handleReject_error;

  /// No description provided for @subscriptionAdminTab_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search subscriptions...'**
  String get subscriptionAdminTab_searchHint;

  /// No description provided for @subscriptionAdminTab_subsList_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get subscriptionAdminTab_subsList_pending;

  /// No description provided for @subscriptionAdminTab_subsList_emptyCard.
  ///
  /// In en, this message translates to:
  /// **'No pending subscriptions'**
  String get subscriptionAdminTab_subsList_emptyCard;

  /// No description provided for @subscriptionAdminTab_filterMenu_title.
  ///
  /// In en, this message translates to:
  /// **'Filter Subscriptions'**
  String get subscriptionAdminTab_filterMenu_title;

  /// No description provided for @subscriptionAdminTab_filterMenu_ctaLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get subscriptionAdminTab_filterMenu_ctaLabel;

  /// No description provided for @subscriptionAdminTab_approveSub_exception.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get subscriptionAdminTab_approveSub_exception;

  /// No description provided for @subscriptionAdminTab_errorWidget_message.
  ///
  /// In en, this message translates to:
  /// **'Error loading subscriptions'**
  String get subscriptionAdminTab_errorWidget_message;

  /// No description provided for @subscriptionAdminTab_emptyWidget_title.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get subscriptionAdminTab_emptyWidget_title;

  /// No description provided for @subscriptionAdminTab_emptyWidget_searchTitle.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions found'**
  String get subscriptionAdminTab_emptyWidget_searchTitle;

  /// No description provided for @subscriptionAdminTab_emptyWidget_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions will appear here'**
  String get subscriptionAdminTab_emptyWidget_subtitle;

  /// No description provided for @subscriptionAdminTab_emptyWidget_searchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get subscriptionAdminTab_emptyWidget_searchSubtitle;

  /// No description provided for @scannerPage_viewArea_pausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Scanner paused'**
  String get scannerPage_viewArea_pausedTitle;

  /// No description provided for @scannerPage_infoBubble.
  ///
  /// In en, this message translates to:
  /// **'Scan student QR codes'**
  String get scannerPage_infoBubble;

  /// No description provided for @scannerPage_controls_toggleFlash.
  ///
  /// In en, this message translates to:
  /// **'Toggle flash'**
  String get scannerPage_controls_toggleFlash;

  /// No description provided for @scannerPage_controls_pauseScanner.
  ///
  /// In en, this message translates to:
  /// **'Pause scanner'**
  String get scannerPage_controls_pauseScanner;

  /// No description provided for @scannerPage_controls_resumeScanner.
  ///
  /// In en, this message translates to:
  /// **'Resume scanner'**
  String get scannerPage_controls_resumeScanner;

  /// No description provided for @scannerPage_controls_resetScanner.
  ///
  /// In en, this message translates to:
  /// **'Reset scanner'**
  String get scannerPage_controls_resetScanner;

  /// No description provided for @scannerPage_idleState_title.
  ///
  /// In en, this message translates to:
  /// **'Ready to scan'**
  String get scannerPage_idleState_title;

  /// No description provided for @scannerPage_idleState_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a student\'s QR code to verify their bus access'**
  String get scannerPage_idleState_subtitle;

  /// No description provided for @scannerPage_progressingState_title.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get scannerPage_progressingState_title;

  /// No description provided for @scannerPage_progressingState_wait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get scannerPage_progressingState_wait;

  /// No description provided for @scannerPage_resultState_statusGranted.
  ///
  /// In en, this message translates to:
  /// **'ACCESS GRANTED'**
  String get scannerPage_resultState_statusGranted;

  /// No description provided for @scannerPage_resultState_statusDenied.
  ///
  /// In en, this message translates to:
  /// **'ACCESS DENIED'**
  String get scannerPage_resultState_statusDenied;

  /// No description provided for @scannerPage_resultState_errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get scannerPage_resultState_errorUnknown;

  /// No description provided for @scannerPage_resultState_ctaLabel.
  ///
  /// In en, this message translates to:
  /// **'Next Scan'**
  String get scannerPage_resultState_ctaLabel;

  /// No description provided for @scannerPage_compactInfo_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get scannerPage_compactInfo_email;

  /// No description provided for @scannerPage_compactInfo_subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get scannerPage_compactInfo_subscription;

  /// No description provided for @scannerPage_compactInfo_busStop.
  ///
  /// In en, this message translates to:
  /// **'Bus Stop'**
  String get scannerPage_compactInfo_busStop;

  /// No description provided for @scannerPage_compactInfo_validity.
  ///
  /// In en, this message translates to:
  /// **'Valid Until'**
  String get scannerPage_compactInfo_validity;

  /// No description provided for @scannerPage_compactInfo_emptySub.
  ///
  /// In en, this message translates to:
  /// **'No active subscription found'**
  String get scannerPage_compactInfo_emptySub;

  /// No description provided for @scannerPage_errorCard_title.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get scannerPage_errorCard_title;

  /// No description provided for @analyticsTab_appBar_title.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get analyticsTab_appBar_title;

  /// No description provided for @analyticsTab_appBar_actionNumView.
  ///
  /// In en, this message translates to:
  /// **'Numerical View'**
  String get analyticsTab_appBar_actionNumView;

  /// No description provided for @analyticsTab_appBar_actionGraphView.
  ///
  /// In en, this message translates to:
  /// **'Graphical View'**
  String get analyticsTab_appBar_actionGraphView;

  /// No description provided for @analyticsTab_loadingError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load analytics data'**
  String get analyticsTab_loadingError;

  /// No description provided for @analyticsTab_subStatusSection_title.
  ///
  /// In en, this message translates to:
  /// **'Subscription Status Overview'**
  String get analyticsTab_subStatusSection_title;

  /// No description provided for @analyticsTab_subStatusSection_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Current distribution of subscription statuses'**
  String get analyticsTab_subStatusSection_subtitle;

  /// No description provided for @analyticsTab_subStatusSection_pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get analyticsTab_subStatusSection_pendingReview;

  /// No description provided for @analyticsTab_subStatusSection_approvalRate.
  ///
  /// In en, this message translates to:
  /// **'Approval Rate:'**
  String get analyticsTab_subStatusSection_approvalRate;

  /// No description provided for @analyticsTab_emptyData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get analyticsTab_emptyData;

  /// No description provided for @analyticsTab_semesterSection_title.
  ///
  /// In en, this message translates to:
  /// **'Semester Analytics'**
  String get analyticsTab_semesterSection_title;

  /// No description provided for @analyticsTab_semesterSection_chartTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions by Semester'**
  String get analyticsTab_semesterSection_chartTitle;

  /// No description provided for @analyticsTab_semesterSection_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions per semester this year'**
  String get analyticsTab_semesterSection_subtitle;

  /// No description provided for @analyticsTab_semesterSection_empty.
  ///
  /// In en, this message translates to:
  /// **'No semester data available for'**
  String get analyticsTab_semesterSection_empty;

  /// No description provided for @analyticsTab_subByYear_title.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions by Year'**
  String get analyticsTab_subByYear_title;

  /// No description provided for @analyticsTab_recentActivitySection_title.
  ///
  /// In en, this message translates to:
  /// **'Recent Subscriptions'**
  String get analyticsTab_recentActivitySection_title;

  /// No description provided for @analyticsTab_recentActivitySection_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Last 10 submissions'**
  String get analyticsTab_recentActivitySection_subtitle;

  /// No description provided for @analyticsTab_recentActivitySection_noData.
  ///
  /// In en, this message translates to:
  /// **'No recent subscription'**
  String get analyticsTab_recentActivitySection_noData;

  /// No description provided for @analyticsTab_topBusStopsSection_title.
  ///
  /// In en, this message translates to:
  /// **'Most Popular Bus Stops'**
  String get analyticsTab_topBusStopsSection_title;

  /// No description provided for @analyticsTab_topBusStopsSection_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Top 5 by subscription count'**
  String get analyticsTab_topBusStopsSection_subtitle;

  /// No description provided for @analyticsTab_topBusStopsSection_ctaLabel.
  ///
  /// In en, this message translates to:
  /// **'Manage stops'**
  String get analyticsTab_topBusStopsSection_ctaLabel;

  /// No description provided for @analyticsTab_topBusStopsSection_noData.
  ///
  /// In en, this message translates to:
  /// **'No bus stop data available'**
  String get analyticsTab_topBusStopsSection_noData;

  /// No description provided for @analyticsTab_quickActionsSection_title.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get analyticsTab_quickActionsSection_title;

  /// No description provided for @analyticsTab_quickActionsSection_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your system efficiently'**
  String get analyticsTab_quickActionsSection_subtitle;

  /// No description provided for @analyticsTab_quickActionsSection_subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Review Subscriptions'**
  String get analyticsTab_quickActionsSection_subscriptions;

  /// No description provided for @analyticsTab_quickActionsSection_subscriptionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Approve or reject pending subscriptions'**
  String get analyticsTab_quickActionsSection_subscriptionsSubtitle;

  /// No description provided for @analyticsTab_quickActionsSection_busStops.
  ///
  /// In en, this message translates to:
  /// **'Manage Bus Stops'**
  String get analyticsTab_quickActionsSection_busStops;

  /// No description provided for @analyticsTab_quickActionsSection_busStopsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, or remove bus stops'**
  String get analyticsTab_quickActionsSection_busStopsSubtitle;

  /// No description provided for @analyticsTab_quickActionsSection_semesters.
  ///
  /// In en, this message translates to:
  /// **'Manage Semesters'**
  String get analyticsTab_quickActionsSection_semesters;

  /// No description provided for @analyticsTab_quickActionsSection_semestersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure semester dates and settings'**
  String get analyticsTab_quickActionsSection_semestersSubtitle;

  /// No description provided for @newSubscriptionPage_scheduleTime_earlyError.
  ///
  /// In en, this message translates to:
  /// **'Earliest morning time is 6:30 AM.'**
  String get newSubscriptionPage_scheduleTime_earlyError;

  /// No description provided for @newSubscriptionPage_scheduleTime_morningError.
  ///
  /// In en, this message translates to:
  /// **'Morning time must be <= closing time..'**
  String get newSubscriptionPage_scheduleTime_morningError;

  /// No description provided for @newSubscriptionPage_scheduleTime_latestError.
  ///
  /// In en, this message translates to:
  /// **'Latest close time is 5:00 PM.'**
  String get newSubscriptionPage_scheduleTime_latestError;

  /// No description provided for @newSubscriptionPage_scheduleTime_closingError.
  ///
  /// In en, this message translates to:
  /// **'Close time must be >= morning time.'**
  String get newSubscriptionPage_scheduleTime_closingError;

  /// No description provided for @newSubscriptionPage_validateStep_proofUpload.
  ///
  /// In en, this message translates to:
  /// **'Please upload a proof of payment to proceed.'**
  String get newSubscriptionPage_validateStep_proofUpload;

  /// No description provided for @newSubscriptionPage_validateStep_semester.
  ///
  /// In en, this message translates to:
  /// **'Please wait for active semester to load or contact administrator.'**
  String get newSubscriptionPage_validateStep_semester;

  /// No description provided for @newSubscriptionPage_validateStep_stop.
  ///
  /// In en, this message translates to:
  /// **'Select a preferred stop to proceed.'**
  String get newSubscriptionPage_validateStep_stop;

  /// No description provided for @newSubscriptionPage_validateStep_schedule.
  ///
  /// In en, this message translates to:
  /// **'Add at least one schedule.'**
  String get newSubscriptionPage_validateStep_schedule;

  /// No description provided for @newSubscriptionPage_validateStep_scheduleInvalid.
  ///
  /// In en, this message translates to:
  /// **'One or more schedule times are invalid.'**
  String get newSubscriptionPage_validateStep_scheduleInvalid;

  /// No description provided for @newSubscriptionPage_submit_validateSteps.
  ///
  /// In en, this message translates to:
  /// **'Fill out every step before submitting.'**
  String get newSubscriptionPage_submit_validateSteps;

  /// No description provided for @newSubscriptionPage_submit_validateStop.
  ///
  /// In en, this message translates to:
  /// **'Unable to resolve selected stop.'**
  String get newSubscriptionPage_submit_validateStop;

  /// No description provided for @newSubscriptionPage_validateStep_proofUploadException.
  ///
  /// In en, this message translates to:
  /// **'Proof file not found. Please re-upload.'**
  String get newSubscriptionPage_validateStep_proofUploadException;

  /// No description provided for @newSubscriptionPage_validateStep_proofUploadMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload proof:'**
  String get newSubscriptionPage_validateStep_proofUploadMessage;

  /// No description provided for @newSubscriptionPage_submit_success.
  ///
  /// In en, this message translates to:
  /// **'Subscription created (pending review)'**
  String get newSubscriptionPage_submit_success;

  /// No description provided for @newSubscriptionPage_submit_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit subscription:'**
  String get newSubscriptionPage_submit_failed;

  /// No description provided for @newSubscriptionPage_appBar_title.
  ///
  /// In en, this message translates to:
  /// **'New Subscription'**
  String get newSubscriptionPage_appBar_title;

  /// No description provided for @newSubscriptionPage_semesterStep_refreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Semesters refreshed'**
  String get newSubscriptionPage_semesterStep_refreshSuccess;

  /// No description provided for @newSubscriptionPage_stopStep_refreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Stops refreshed'**
  String get newSubscriptionPage_stopStep_refreshSuccess;

  /// No description provided for @newSubscriptionPage_semesterStep_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh Semesters'**
  String get newSubscriptionPage_semesterStep_refresh;

  /// No description provided for @newSubscriptionPage_stopStep_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh Stops'**
  String get newSubscriptionPage_stopStep_refresh;

  /// No description provided for @newSubscriptionPage_proofStep_title.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get newSubscriptionPage_proofStep_title;

  /// No description provided for @newSubscriptionPage_proofStep_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Proof of payment'**
  String get newSubscriptionPage_proofStep_subtitle;

  /// No description provided for @newSubscriptionPage_proofStep_imageBox.
  ///
  /// In en, this message translates to:
  /// **'Upload a copy of your receipt'**
  String get newSubscriptionPage_proofStep_imageBox;

  /// No description provided for @newSubscriptionPage_semesterStep_emptyActive.
  ///
  /// In en, this message translates to:
  /// **'No active semester available. Please contact the administrator.'**
  String get newSubscriptionPage_semesterStep_emptyActive;

  /// No description provided for @newSubscriptionPage_semesterStep_activeSemester.
  ///
  /// In en, this message translates to:
  /// **'Active semester'**
  String get newSubscriptionPage_semesterStep_activeSemester;

  /// No description provided for @newSubscriptionPage_semesterStep_infoBubble.
  ///
  /// In en, this message translates to:
  /// **'Your subscription will be valid for the active semester shown above.'**
  String get newSubscriptionPage_semesterStep_infoBubble;

  /// No description provided for @newSubscriptionPage_stopStep_title.
  ///
  /// In en, this message translates to:
  /// **'Preferred stop'**
  String get newSubscriptionPage_stopStep_title;

  /// No description provided for @newSubscriptionPage_stopStep_validatorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select a bus stop.'**
  String get newSubscriptionPage_stopStep_validatorEmpty;

  /// No description provided for @newSubscriptionPage_stopStep_label.
  ///
  /// In en, this message translates to:
  /// **'Select stop'**
  String get newSubscriptionPage_stopStep_label;

  /// No description provided for @newSubscriptionPage_scheduleStep_title.
  ///
  /// In en, this message translates to:
  /// **'Weekly schedules'**
  String get newSubscriptionPage_scheduleStep_title;

  /// No description provided for @newSubscriptionPage_scheduleStep_optionEveryday.
  ///
  /// In en, this message translates to:
  /// **'Everyday'**
  String get newSubscriptionPage_scheduleStep_optionEveryday;

  /// No description provided for @newSubscriptionPage_scheduleStep_optionNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal week'**
  String get newSubscriptionPage_scheduleStep_optionNormal;

  /// No description provided for @newSubscriptionPage_scheduleStep_optionCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get newSubscriptionPage_scheduleStep_optionCustom;

  /// No description provided for @newSubscriptionPage_scheduleStep_empty.
  ///
  /// In en, this message translates to:
  /// **'No schedules added. Add the days you take the bus.'**
  String get newSubscriptionPage_scheduleStep_empty;

  /// No description provided for @newSubscriptionPage_scheduleStep_maxReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum of 6 days reached (Mon - Sat).'**
  String get newSubscriptionPage_scheduleStep_maxReached;

  /// No description provided for @newSubscriptionPage_reviewStep_title.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get newSubscriptionPage_reviewStep_title;

  /// No description provided for @newSubscriptionPage_reviewStep_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Review Your Subscription Details'**
  String get newSubscriptionPage_reviewStep_subtitle;

  /// No description provided for @newSubscriptionPage_reviewStep_description.
  ///
  /// In en, this message translates to:
  /// **'Please verify all details before submitting'**
  String get newSubscriptionPage_reviewStep_description;

  /// No description provided for @newSubscriptionPage_reviewStep_studentInfo.
  ///
  /// In en, this message translates to:
  /// **'Student Information'**
  String get newSubscriptionPage_reviewStep_studentInfo;

  /// No description provided for @newSubscriptionPage_reviewStep_studentName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get newSubscriptionPage_reviewStep_studentName;

  /// No description provided for @newSubscriptionPage_reviewStep_studentEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get newSubscriptionPage_reviewStep_studentEmail;

  /// No description provided for @newSubscriptionPage_reviewStep_semesterDetails.
  ///
  /// In en, this message translates to:
  /// **'Semester Details'**
  String get newSubscriptionPage_reviewStep_semesterDetails;

  /// No description provided for @newSubscriptionPage_reviewStep_semesterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No semester selected'**
  String get newSubscriptionPage_reviewStep_semesterEmpty;

  /// No description provided for @newSubscriptionPage_reviewStep_stopTitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup Stop'**
  String get newSubscriptionPage_reviewStep_stopTitle;

  /// No description provided for @newSubscriptionPage_reviewStep_stopName.
  ///
  /// In en, this message translates to:
  /// **'Stop Name'**
  String get newSubscriptionPage_reviewStep_stopName;

  /// No description provided for @newSubscriptionPage_reviewStep_stopEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stop selected'**
  String get newSubscriptionPage_reviewStep_stopEmpty;

  /// No description provided for @newSubscriptionPage_reviewStep_weeklyScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Schedule'**
  String get newSubscriptionPage_reviewStep_weeklyScheduleTitle;

  /// No description provided for @newSubscriptionPage_reviewStep_weeklyScheduleDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get newSubscriptionPage_reviewStep_weeklyScheduleDay;

  /// No description provided for @newSubscriptionPage_reviewStep_weeklyScheduleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No schedules added'**
  String get newSubscriptionPage_reviewStep_weeklyScheduleEmpty;

  /// No description provided for @newSubscriptionPage_reviewStep_infoBubbleTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Required'**
  String get newSubscriptionPage_reviewStep_infoBubbleTitle;

  /// No description provided for @newSubscriptionPage_reviewStep_infoBubbleDescription.
  ///
  /// In en, this message translates to:
  /// **'Your subscription will be reviewed by our team. You will receive a notification once it has been approved or if any changes are needed.'**
  String get newSubscriptionPage_reviewStep_infoBubbleDescription;

  /// No description provided for @newSubscriptionPage_overlay_title.
  ///
  /// In en, this message translates to:
  /// **'Submitting your subscription...'**
  String get newSubscriptionPage_overlay_title;

  /// No description provided for @newSubscriptionPage_overlay_subtitle.
  ///
  /// In en, this message translates to:
  /// **'We are securing your seat on the bus...'**
  String get newSubscriptionPage_overlay_subtitle;

  /// No description provided for @newSubscriptionPage_stopPreview_noLink.
  ///
  /// In en, this message translates to:
  /// **'No map link available for this stop.'**
  String get newSubscriptionPage_stopPreview_noLink;

  /// No description provided for @newSubscriptionPage_stopPreview_noImage.
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get newSubscriptionPage_stopPreview_noImage;

  /// No description provided for @newSubscriptionPage_stopPreview_mapsCta.
  ///
  /// In en, this message translates to:
  /// **'View on Google Maps'**
  String get newSubscriptionPage_stopPreview_mapsCta;

  /// No description provided for @newSubscriptionPage_stopPreview_noMedia.
  ///
  /// In en, this message translates to:
  /// **'No media'**
  String get newSubscriptionPage_stopPreview_noMedia;

  /// No description provided for @newStopForm_handleSubmit_success.
  ///
  /// In en, this message translates to:
  /// **'Bus stop created successfully'**
  String get newStopForm_handleSubmit_success;

  /// No description provided for @newStopForm_handleSubmit_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create bus stop'**
  String get newStopForm_handleSubmit_failed;

  /// No description provided for @newStopForm_appBar_title.
  ///
  /// In en, this message translates to:
  /// **'New Bus Stop'**
  String get newStopForm_appBar_title;

  /// No description provided for @newStopForm_listTile_infoBubble.
  ///
  /// In en, this message translates to:
  /// **'The form below allows you to create a new bus stop. This will be added to the list of available stops for users to select when subscribing to bus routes.'**
  String get newStopForm_listTile_infoBubble;

  /// No description provided for @newStopForm_stopDetails.
  ///
  /// In en, this message translates to:
  /// **'Bus Stop Details'**
  String get newStopForm_stopDetails;

  /// No description provided for @newStopForm_stopDetails_image.
  ///
  /// In en, this message translates to:
  /// **'Upload a capture of the place (optional)'**
  String get newStopForm_stopDetails_image;

  /// No description provided for @newStopForm_stopDetails_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup place name *'**
  String get newStopForm_stopDetails_nameLabel;

  /// No description provided for @newStopForm_stopDetails_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of the place'**
  String get newStopForm_stopDetails_nameHint;

  /// No description provided for @newStopForm_stopDetails_nameValidator.
  ///
  /// In en, this message translates to:
  /// **'Please enter the name of the bus stop'**
  String get newStopForm_stopDetails_nameValidator;

  /// No description provided for @newStopForm_stopDetails_mapsLabel.
  ///
  /// In en, this message translates to:
  /// **'Maps URL (optional)'**
  String get newStopForm_stopDetails_mapsLabel;

  /// No description provided for @newStopForm_stopDetails_mapsHint.
  ///
  /// In en, this message translates to:
  /// **'A Google maps link to the place'**
  String get newStopForm_stopDetails_mapsHint;

  /// No description provided for @newStopForm_stopDetails_mapsValidator.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Google Maps link'**
  String get newStopForm_stopDetails_mapsValidator;

  /// No description provided for @newStopForm_handleSubmit_labelLoading.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get newStopForm_handleSubmit_labelLoading;

  /// No description provided for @newStopForm_handleSubmit_label.
  ///
  /// In en, this message translates to:
  /// **'Add stop'**
  String get newStopForm_handleSubmit_label;

  /// No description provided for @editStopForm_handleSubmit_success.
  ///
  /// In en, this message translates to:
  /// **'Bus stop updated successfully'**
  String get editStopForm_handleSubmit_success;

  /// No description provided for @editStopForm_handleSubmit_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update bus stop'**
  String get editStopForm_handleSubmit_failed;

  /// No description provided for @editStopForm_appBar_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Bus Stop'**
  String get editStopForm_appBar_title;

  /// No description provided for @editStopForm_notFound.
  ///
  /// In en, this message translates to:
  /// **'Bus stop not found'**
  String get editStopForm_notFound;

  /// No description provided for @editStopForm_notFound_ctaLabel.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get editStopForm_notFound_ctaLabel;

  /// No description provided for @editStopForm_listTile_infoBubble.
  ///
  /// In en, this message translates to:
  /// **'Update the information for this bus stop. Changes will be reflected for all users who have subscribed to this stop.'**
  String get editStopForm_listTile_infoBubble;

  /// No description provided for @editStopForm_metaData.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get editStopForm_metaData;

  /// No description provided for @editStopForm_handleSubmit_labelLoading.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get editStopForm_handleSubmit_labelLoading;

  /// No description provided for @editStopForm_handleSubmit_label.
  ///
  /// In en, this message translates to:
  /// **'Update stop'**
  String get editStopForm_handleSubmit_label;

  /// No description provided for @semesterFormPage_selectYear_null.
  ///
  /// In en, this message translates to:
  /// **'Please select a year first'**
  String get semesterFormPage_selectYear_null;

  /// No description provided for @semesterFormPage_selectSemester_null.
  ///
  /// In en, this message translates to:
  /// **'Please select a semester first'**
  String get semesterFormPage_selectSemester_null;

  /// No description provided for @semesterFormPage_pickedDate_null.
  ///
  /// In en, this message translates to:
  /// **'Start date must be in'**
  String get semesterFormPage_pickedDate_null;

  /// Error message indicating that the end date must be within the selected years
  ///
  /// In en, this message translates to:
  /// **'End date must be in {selectedYear1} or {selectedYear2}'**
  String semesterFormPage_validateDate(
    String selectedYear1,
    String selectedYear2,
  );

  /// No description provided for @semesterFormPage_handleSubmit_yearNull.
  ///
  /// In en, this message translates to:
  /// **'Please select a year'**
  String get semesterFormPage_handleSubmit_yearNull;

  /// No description provided for @semesterFormPage_handleSubmit_semesterNull.
  ///
  /// In en, this message translates to:
  /// **'Please select a semester'**
  String get semesterFormPage_handleSubmit_semesterNull;

  /// No description provided for @semesterFormPage_handleSubmit_datesNull.
  ///
  /// In en, this message translates to:
  /// **'Please select start and end dates'**
  String get semesterFormPage_handleSubmit_datesNull;

  /// No description provided for @semesterFormPage_handleSubmit_startIsAfter.
  ///
  /// In en, this message translates to:
  /// **'Start date must be before end date'**
  String get semesterFormPage_handleSubmit_startIsAfter;

  /// No description provided for @semesterFormPage_handleSubmit_semesterDurationDays.
  ///
  /// In en, this message translates to:
  /// **'Semester must be at least 30 days long'**
  String get semesterFormPage_handleSubmit_semesterDurationDays;

  /// No description provided for @semesterFormPage_handleSubmit_semesterDurationMonths.
  ///
  /// In en, this message translates to:
  /// **'Semester cannot be longer than 6 months'**
  String get semesterFormPage_handleSubmit_semesterDurationMonths;

  /// No description provided for @semesterFormPage_handleSubmit_successCreated.
  ///
  /// In en, this message translates to:
  /// **'Semester created successfully'**
  String get semesterFormPage_handleSubmit_successCreated;

  /// No description provided for @semesterFormPage_handleSubmit_successUpdated.
  ///
  /// In en, this message translates to:
  /// **'Semester updated successfully'**
  String get semesterFormPage_handleSubmit_successUpdated;

  /// No description provided for @semesterFormPage_handleSubmit_failedCreated.
  ///
  /// In en, this message translates to:
  /// **'Failed to create semester'**
  String get semesterFormPage_handleSubmit_failedCreated;

  /// No description provided for @semesterFormPage_handleSubmit_failedUpdated.
  ///
  /// In en, this message translates to:
  /// **'Failed to update semester'**
  String get semesterFormPage_handleSubmit_failedUpdated;

  /// No description provided for @semesterFormPage_appBar_titleCreate.
  ///
  /// In en, this message translates to:
  /// **'Add Semester'**
  String get semesterFormPage_appBar_titleCreate;

  /// No description provided for @semesterFormPage_appBar_titleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Semester'**
  String get semesterFormPage_appBar_titleEdit;

  /// No description provided for @semesterFormPage_infoBanner_update.
  ///
  /// In en, this message translates to:
  /// **'Update the date range for this semester. Changes will affect all subscriptions using these dates.'**
  String get semesterFormPage_infoBanner_update;

  /// No description provided for @semesterFormPage_infoBanner_create.
  ///
  /// In en, this message translates to:
  /// **'Define the start and end dates for a semester. These dates will be used for subscription validity periods.'**
  String get semesterFormPage_infoBanner_create;

  /// No description provided for @semesterFormPage_sectionHeader_semesterDetails.
  ///
  /// In en, this message translates to:
  /// **'Semester Details'**
  String get semesterFormPage_sectionHeader_semesterDetails;

  /// No description provided for @semesterFormPage_semesterDetails_type.
  ///
  /// In en, this message translates to:
  /// **'Semester Type'**
  String get semesterFormPage_semesterDetails_type;

  /// No description provided for @semesterFormPage_semesterDetails_semesterSelected.
  ///
  /// In en, this message translates to:
  /// **'is already registered for'**
  String get semesterFormPage_semesterDetails_semesterSelected;

  /// No description provided for @semesterFormPage_sectionHeader_dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get semesterFormPage_sectionHeader_dateRange;

  /// No description provided for @semesterFormPage_dateRange_startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get semesterFormPage_dateRange_startDate;

  /// No description provided for @semesterFormPage_dateRange_startDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select start date'**
  String get semesterFormPage_dateRange_startDateHint;

  /// No description provided for @semesterFormPage_dateRange_endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get semesterFormPage_dateRange_endDate;

  /// No description provided for @semesterFormPage_dateRange_endDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select end date'**
  String get semesterFormPage_dateRange_endDateHint;

  /// No description provided for @semesterFormPage_sectionHeader_durationPreview.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get semesterFormPage_sectionHeader_durationPreview;

  /// No description provided for @semesterFormPage_submit_update.
  ///
  /// In en, this message translates to:
  /// **'Update Semester'**
  String get semesterFormPage_submit_update;

  /// No description provided for @semesterFormPage_submit_create.
  ///
  /// In en, this message translates to:
  /// **'Add Semester'**
  String get semesterFormPage_submit_create;

  /// No description provided for @imageBox_sizeLimit.
  ///
  /// In en, this message translates to:
  /// **'The image size should not be more than'**
  String get imageBox_sizeLimit;

  /// No description provided for @imageBox_uploadError.
  ///
  /// In en, this message translates to:
  /// **'Error during image upload:'**
  String get imageBox_uploadError;

  /// No description provided for @imageBox_loadingError.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get imageBox_loadingError;
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
