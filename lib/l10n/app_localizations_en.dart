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
  String get backButton => 'Back';

  @override
  String get continueButton => 'Continue';

  @override
  String get status => 'Status';

  @override
  String get statusPending => 'Status: Pending';

  @override
  String get statusApproved => 'Status: Approved';

  @override
  String get statusRejected => 'Status: Rejected';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleStaff => 'Staff';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get accountPending => 'Pending';

  @override
  String get accountVerified => 'Verified';

  @override
  String get accountSuspended => 'Suspended';

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get scannings => 'Scannings';

  @override
  String get joined => 'Joined';

  @override
  String get lastSignIn => 'Last sign in';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

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

  @override
  String get authModal_initialPage_title => 'Welcome to BusIn';

  @override
  String get authModal_initialPage_subtitle =>
      'Your smart bus subscription manager';

  @override
  String get authModal_initialPage_question => 'Already have an account?';

  @override
  String get authModal_actions_login => 'Login with Google';

  @override
  String get authModal_actions_signup => 'New here? Sign Up';

  @override
  String get authModal_actions_skip => 'Skip for now';

  @override
  String get authModal_loginStep_title => 'Welcome back!';

  @override
  String get authModal_loginStep_subtitle =>
      'We\'re happy to see you again. Sign in to access your account';

  @override
  String get authModal_loginStep_info =>
      'Use your ICT University email (@ictuniversity.edu.cm) to sign in';

  @override
  String get authModal_loginStep_ctaLogin => 'Sign in with Google';

  @override
  String get authModal_loginStep_ctaLoginLoading => 'Signing in...';

  @override
  String get authModal_signupStep_ctaSignup => 'Sign up with Google';

  @override
  String get authModal_signupStep_ctaSignupLoading => 'Creating account...';

  @override
  String get verificationPage_titlePending => 'Pending Verification';

  @override
  String get verificationPage_titleRejected => 'Verification Rejected';

  @override
  String get verificationPage_titleComplete => 'Verification Complete';

  @override
  String get verificationPage_descriptionRejected =>
      'Your staff account request has been declined by an administrator. Please contact support for more information.';

  @override
  String get verificationPage_descriptionPending =>
      'Your staff account is awaiting admin approval. You will be notified once your account has been verified.';

  @override
  String get verificationPage_descriptionComplete =>
      'Your account has been verified! You can now access the application.';

  @override
  String get verificationPage_infoAlert_descriptionRejected =>
      'Your request was not approved. You can try again by creating a new account or contact an administrator for assistance.';

  @override
  String get verificationPage_infoAlert_descriptionVerified =>
      'Your account is ready! Click below to access the application.';

  @override
  String get verificationPage_infoAlert_descriptionPending =>
      'An admin will review your account shortly. This usually takes less than 24 hours.';

  @override
  String get verificationPage_ctaVerified => 'Continue to App';

  @override
  String get verificationPage_ctaPending => 'Check Status';

  @override
  String get verificationPage_ctaPendingLoading => 'Checking...';

  @override
  String get verificationPage_ctaSignOut => 'Sign Out';

  @override
  String get verificationPage_labelSupport =>
      'Need help? Contact an administrator.';

  @override
  String get verificationPage_rejectMessage =>
      'Your account has been rejected.';

  @override
  String get verificationPage_checkStatusError => 'Error checking status:';

  @override
  String get verificationPage_approvedMessage =>
      'Account verified! You now have staff access.';

  @override
  String get verificationPage_navigationError => 'Error navigating:';

  @override
  String get verificationPage_signOutMessage => 'Signed out successfully.';

  @override
  String get welcomeModal_titleStudent => 'Welcome to BusIn!';

  @override
  String get welcomeModal_messageStudent =>
      'Hey there! We\'re excited to have you on board. Managing your bus subscriptions ath the ICT University just got way easier. Ready to hop on?';

  @override
  String get welcomeModal_ctaStudent => 'Let\'s Explore!';

  @override
  String get welcomeModal_titleStaff => 'Welcome to BusIn Staff Portal';

  @override
  String get welcomeModal_messageStaff =>
      'Thank you for joining the BusIn team. You now have access to scan student QR codes and verify bus access. Let\'s make transportation management seamless at the ICT University.';

  @override
  String get welcomeModal_ctaStaff => 'Get Started';

  @override
  String get welcomeModal_titleAdmin => 'Welcome to BusIn Admin Panel';

  @override
  String get welcomeModal_messageAdmin =>
      'Welcome to the BusIn management dashboard. You have full access to manage subscriptions, bus stops, semesters, and oversee the entire transportation system. Let\'s streamline operations for the ICT University.';

  @override
  String get welcomeModal_ctaAdmin => 'Access Dashboard';

  @override
  String get homeNav_analyticsTab => 'Analytics';

  @override
  String get homeNav_studentHomeTab => 'Home';

  @override
  String get homeNav_subscriptionsTab => 'Subscriptions';

  @override
  String get homeNav_scanningsTab => 'Scannings';

  @override
  String get homeNav_peopleTab => 'People';

  @override
  String get profilePage_appBar_title => 'Profile';

  @override
  String get profilePage_subHeading_yourData => 'Your data on BusIn';

  @override
  String get profilePage_listTile_accountInfo => 'Account Info';

  @override
  String get profilePage_accountInfo_subtitle =>
      'Complete your profile information';

  @override
  String get profilePage_accountInfo_badge => 'Action required';

  @override
  String get profilePage_listTile_appearance => 'Appearance';

  @override
  String get profilePage_listTile_legal => 'Legal';

  @override
  String get profilePage_subHeading_busManagement => 'Bus Management';

  @override
  String get profilePage_listTile_busStops => 'Bus Stops';

  @override
  String get profilePage_busStops_subtitle =>
      'Manage places where the bus picks up students';

  @override
  String get profilePage_listTile_semesters => 'Semesters';

  @override
  String get profilePage_semesters_subtitle =>
      'Manage bus semesters duration and more';

  @override
  String get profilePage_listTile_signOut => 'Sign out';

  @override
  String get profilePage_listTile_signOutMessage => 'Signed out successfully';

  @override
  String get profilePage_appInfo_rights => 'All rights reserved';

  @override
  String get loadingPage_label => 'Loading your journey...';

  @override
  String get accountInfoPage_missingLabel => 'Missing: ';

  @override
  String get accountInfoPage_sectionHeader_google =>
      'Google Account Information';

  @override
  String get accountInfoPage_googleSection_provider => 'Provider';

  @override
  String get accountInfoPage_googleSection_displayName => 'Display Name';

  @override
  String get accountInfoPage_googleSection_displayNameWarning =>
      'No display name set. Using email username as fallback. Update your Google account to set a display name.';

  @override
  String get accountInfoPage_googleSection_email => 'Email address';

  @override
  String get accountInfoPage_googleSection_accountStatus => 'Account status';

  @override
  String get accountInfoPage_sectionHeader_contact => 'Contact Information';

  @override
  String get accountInfoPage_sectionHeader_update => 'Update Your Information';

  @override
  String get accountInfoPage_editableField_phoneNumber => 'Phone Number';

  @override
  String get accountInfoPage_editableField_gender => 'Gender';

  @override
  String get accountInfoPage_editableField_genderNotSpecified =>
      'Not specified';

  @override
  String get accountInfoPage_sectionHeader_studentInfo => 'Student Information';

  @override
  String get accountInfoPage_sectionHeader_studentDetails => 'Student Details';

  @override
  String get accountInfoPage_editableField_studentID =>
      'Student ID (Matricule)';

  @override
  String get accountInfoPage_editableField_department => 'Department';

  @override
  String get accountInfoPage_editableField_departmentNotProvided =>
      'Not provided';

  @override
  String get accountInfoPage_editableField_program => 'Program (Major)';

  @override
  String get accountInfoPage_editableField_programInstruction =>
      'Please select a department first';

  @override
  String get accountInfoPage_editableField_programNotProvided => 'Not provided';

  @override
  String get accountInfoPage_editableField_streetAddress => 'Street Address';

  @override
  String get accountInfoPage_editableField_streetAddressHint =>
      'Enter your street address';

  @override
  String get accountInfoPage_updateSuccessful =>
      'Account information updated successfully';

  @override
  String get accountInfoPage_updateFailed => 'Failed to update:';

  @override
  String get accountInfoPage_ctaSaveChanges => 'Save Changes';

  @override
  String get accountInfoPage_ctaSaveChangesLoading => 'Saving...';

  @override
  String get accountInfoPage_roleBadge_labelStudent => 'Student Account';

  @override
  String get accountInfoPage_roleBadge_descriptionStudent =>
      'Make subscriptions to the bus service and make the most out of BusIn.\'';

  @override
  String get accountInfoPage_roleBadge_labelStaff => 'Staff Member';

  @override
  String get accountInfoPage_roleBadge_descriptionStaff =>
      'Manage bus services and assist students with their transportation needs.';

  @override
  String get accountInfoPage_roleBadge_labelAdmin => 'Administrator';

  @override
  String get accountInfoPage_roleBadge_descriptionAdmin =>
      'Oversee the entire bus management system and ensure smooth operations.';

  @override
  String accountInfoPage_editableField_errorRequired(String field) {
    return '$field is required';
  }

  @override
  String get appearance_appBar_title => 'Appearance';

  @override
  String get appearance_listTile_theme => 'Theme';

  @override
  String get appearance_listTile_language => 'Language';

  @override
  String get appearance_listTile_themeSystem => 'System';

  @override
  String get appearance_listTile_themeSystemSubtitle =>
      'Automatically adjust to system settings';

  @override
  String get appearance_listTile_themeLight => 'Bright';

  @override
  String get appearance_listTile_themeLightSubtitle =>
      'Sets the app’s theme to light with brighter colors. Suitable for daytime.';

  @override
  String get appearance_listTile_themeDark => 'Dimmed';

  @override
  String get appearance_listTile_themeDarkSubtitle =>
      'Sets the app’s theme to dark with darker colors. Easy on the eyes in low light';

  @override
  String get appearance_listTile_selected => 'Selected';

  @override
  String get legalPage_appBar_title => 'Legal Information';

  @override
  String get legalPage_loadingInfo => 'Loading legal information...';

  @override
  String get legalPage_offlineContent => 'Using offline content';

  @override
  String get legalPage_loadingError =>
      'Could not load the latest legal information. Showing cached version.';
}
