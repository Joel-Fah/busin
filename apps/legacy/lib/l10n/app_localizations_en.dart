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
  String get subscriptionPending => 'Pending';

  @override
  String get subscriptionApproved => 'Approved';

  @override
  String get subscriptionRejected => 'Rejected';

  @override
  String get subscriptionExpired => 'Expired';

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
  String get delete => 'Delete';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get createdAt => 'Created at';

  @override
  String get updatedAt => 'Updated at';

  @override
  String get map => 'Map';

  @override
  String get image => 'Image';

  @override
  String get unknown => 'Unknown user';

  @override
  String get loading => 'Loading...';

  @override
  String get by => 'By';

  @override
  String get days => 'days';

  @override
  String get newLabel => 'New';

  @override
  String get viewAll => 'View all';

  @override
  String get userProfile => 'User Profile';

  @override
  String get morning => 'Morning';

  @override
  String get closing => 'Closing';

  @override
  String get close => 'Close';

  @override
  String get download => 'Download';

  @override
  String get allLabel => 'All';

  @override
  String get filter => 'Filter';

  @override
  String get search => 'Search';

  @override
  String get year => 'Year';

  @override
  String get semester => 'Semester';

  @override
  String get stop => 'Stop';

  @override
  String get naLabel => 'N/A';

  @override
  String get week => 'week';

  @override
  String get monthly => 'Monthly';

  @override
  String get busStops => 'Bus Stops';

  @override
  String get submit => 'Submit';

  @override
  String get next => 'Next';

  @override
  String get selected => 'Selected';

  @override
  String get remove => 'Remove';

  @override
  String get add => 'Add';

  @override
  String get users => 'user(s)';

  @override
  String get change => 'Change';

  @override
  String get updatedBy => 'Updated by:';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get error => 'Error:';

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
  String get signOut_confirmTitle => 'Sign Out?';

  @override
  String get signOut_confirmMessage =>
      'Are you sure you want to sign out? You can always sign back in.';

  @override
  String get signOut_confirmButton => 'Sign Out';

  @override
  String get signOut_cancelButton => 'Cancel';

  @override
  String get signOut_dontShowAgain => 'Don\'t ask me again';

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

  @override
  String get stopsPage_appBar_title => 'Stops';

  @override
  String get stopsPage_appBar_actionsNew => 'New stop';

  @override
  String get stopsPage_appBar_searchHint => 'Filter bus stops...';

  @override
  String get stopsPage_statItem_total => 'Total stops';

  @override
  String get stopsPage_statItem_withImages => 'With images';

  @override
  String get stopsPage_statItem_withMaps => 'With maps';

  @override
  String get stopsPage_loadingError => 'Error loading bus stops';

  @override
  String get stopsPage_emptyListMessageTitle => 'No bus stops yet';

  @override
  String get stopsPage_emptyQueryMessageTitle => 'No bus stops found';

  @override
  String get stopsPage_emptyListMessageSubtitle => 'Add your first bus stop';

  @override
  String get stopsPage_emptyQueryMessageSubtitle =>
      'Try a different search query';

  @override
  String get stopsPage_stopCard_deleteModalTitle => 'Delete Bus Stop';

  @override
  String get stopsPage_stopCard_deleteModalMessage =>
      'This action cannot be undone';

  @override
  String get stopsPage_stopCard_deleteModalWarning =>
      'All data associated with this stop will be permanently deleted.';

  @override
  String stopsPage_stopCard_deleteSuccess(String stop) {
    return 'Bus stop \"$stop\" removed successfully';
  }

  @override
  String get stopsPage_stopCard_deleteError => 'Failed to delete bus stop';

  @override
  String get stopsPage_stopCard_imageUnavailable => 'Image not available';

  @override
  String get stopsPage_stopCard_noPreview => 'No preview available';

  @override
  String get semestersPage_appBar_title => 'Semesters';

  @override
  String get semestersPage_appBar_actionsAdd => 'Add semester';

  @override
  String get semestersPage_appBar_activeSemester => 'Active semester';

  @override
  String get semestersPage_infoBubble =>
      'Define start and end dates for each semester. These dates will be used for subscription validity periods.';

  @override
  String get semestersPage_statItem_total => 'Total';

  @override
  String get semestersPage_statItem_upcoming => 'Upcoming';

  @override
  String get semestersPage_loadingError => 'Error loading semesters';

  @override
  String get semestersPage_emptyList_title => 'No semesters configured';

  @override
  String get semestersPage_emptyList_subtitle =>
      'Add your first semester to get started';

  @override
  String get semestersPage_handleDelete_successful =>
      'Semester deleted successfully';

  @override
  String get semestersPage_handleDelete_failed => 'Failed to delete semester';

  @override
  String get semestersPage_handleDelete_title => 'Delete Semester';

  @override
  String get semestersPage_handleDelete_subtitle =>
      'This action cannot be undone';

  @override
  String get semestersPage_detailRow_startDate => 'Start date';

  @override
  String get semestersPage_detailRow_endDate => 'End date';

  @override
  String get semestersPage_detailRow_duration => 'Duration';

  @override
  String get semestersPage_detailRow_statusActive => 'Active';

  @override
  String get semestersPage_detailRow_statusEnded => 'Ended';

  @override
  String get semestersPage_detailRow_statusUpcoming => 'Upcoming';

  @override
  String get semestersPage_deleteModal_warning =>
      'All data associated with this semester will be permanently deleted.';

  @override
  String get homeTab_title => 'Recent Activity';

  @override
  String get homeTab_subscriptionTile_start => 'Start:';

  @override
  String get homeTab_subscriptionTile_end => 'End:';

  @override
  String get homeTab_emptySubscriptionCard_title => 'No subscriptions yet';

  @override
  String get homeTab_emptySubscriptionCard_message =>
      'Create your first bus subscription to see it here.';

  @override
  String get homeTab_scanningsTile_on => 'On:';

  @override
  String get homeTab_scanningsTile_titleUnavailable => 'Location unavailable';

  @override
  String get homeTab_emptyScanningsCard_title => 'No scans yet';

  @override
  String get homeTab_emptyScanningsCard_message =>
      'Your QR code hasn\'t been scanned yet.';

  @override
  String get subscriptionTab_emptyState_ctaLabel => 'Subscribe now for';

  @override
  String get subscriptionTab_activeCta_message =>
      'You don\'t have any subscription running currently. Maybe, subscribe now to the bus services for the ongoing semester';

  @override
  String get subscriptionTab_emptyList_message => 'No other subscriptions yet.';

  @override
  String subscriptionTab_emptyList_messageFilter(String status) {
    return 'No $status subscriptions match the filter.';
  }

  @override
  String get subscriptionTab_emptyState_supertitle =>
      'Seems like it’s your first time around';

  @override
  String get subscriptionTab_emptyState_title =>
      'You don’t have any subscriptions yet';

  @override
  String get subscriptionTab_emptyState_subtitle =>
      'Let’s get you started with a bus subscription so you can ride this semester.';

  @override
  String get scanningsTab_screenshotsWarning =>
      'Hey! Screenshots aren\'t allowed here to keep your QR code safe';

  @override
  String get subscriptionDetailPage_appBar_title => 'Subscription Details';

  @override
  String get subscriptionDetailPage_nullContent_title =>
      'Subscription not found';

  @override
  String get subscriptionDetailPage_nullContent_message =>
      'The subscription you are looking for does not exist or has been removed.';

  @override
  String get subscriptionDetailPage_handleRefresh_error => 'Failed to refresh:';

  @override
  String get subscriptionDetailPage_handleApprove_success =>
      'Subscription approved';

  @override
  String get subscriptionDetailPage_handleApprove_error =>
      'Failed to approve subscription:';

  @override
  String get subscriptionDetailPage_handleReject_success =>
      'Subscription rejected';

  @override
  String get subscriptionDetailPage_handleReject_error =>
      'Failed to reject subscription:';

  @override
  String get subscriptionDetailPage_rejectDialog_title => 'Reject Subscription';

  @override
  String get subscriptionDetailPage_rejectDialog_instruction =>
      'Please provide a reason for rejecting this subscription. This will be shown to the student.';

  @override
  String get subscriptionDetailPage_rejectDialog_reasonLabel =>
      'Rejection Reason';

  @override
  String get subscriptionDetailPage_rejectDialog_reasonValidatorEmpty =>
      'Please provide a reason for rejection';

  @override
  String get subscriptionDetailPage_rejectDialog_reasonValidatorLength =>
      'Reason must be at least 10 characters long';

  @override
  String get subscriptionDetailPage_rejectDialog_ctaReject =>
      'Reject Subscription';

  @override
  String get subscriptionDetailPage_reviewInfo_sectionTitle =>
      'Review Information';

  @override
  String get subscriptionDetailPage_reviewInfo_reviewedOn => 'Reviewed on';

  @override
  String get subscriptionDetailPage_reviewInfo_reviewedBy => 'Reviewed by';

  @override
  String get subscriptionDetailPage_statusDates_startLabel => 'Start Date';

  @override
  String get subscriptionDetailPage_statusDates_endLabel => 'End Date';

  @override
  String get subscriptionDetailPage_statusDates_durationLabel =>
      'Time remaining';

  @override
  String get subscriptionDetailPage_weeklySchedule_title => 'Weekly Schedule';

  @override
  String get subscriptionDetailPage_adminAction_approve => 'Approve';

  @override
  String get subscriptionDetailPage_adminAction_reject => 'Reject';

  @override
  String get subscriptionDetailPage_paymentProof_placeholder =>
      'No proof of payment';

  @override
  String get subscriptionDetailPage_statusLabel_approved =>
      'Subscription Approved';

  @override
  String get subscriptionDetailPage_statusLabel_pending => 'Pending Validation';

  @override
  String get subscriptionDetailPage_statusLabel_rejected =>
      'Rejected Subscription';

  @override
  String get subscriptionDetailPage_statusLabel_expired =>
      'Expired Subscription';

  @override
  String get subscriptionDetailPage_mapView_title => 'Bus stop';

  @override
  String get subscriptionDetailPage_mapView_openMessageSuccess =>
      'Opened in Google Maps';

  @override
  String get subscriptionDetailPage_mapView_openMessageError =>
      'Could not open Google Maps';

  @override
  String get subscriptionDetailPage_mapView_ctaLabel =>
      'Tap to open on Google Maps';

  @override
  String get subscriptionDetailPage_mapView_ctaTooltip => 'Open in Google Maps';

  @override
  String get subscriptionDetailPage_mapView_pickupImageUnavailable =>
      'Image not available';

  @override
  String get subscriptionDetailPage_mapView_pickupImagePreview =>
      'Pickup point preview';

  @override
  String get subscriptionDetailPage_studentSection_title =>
      'Student Information';

  @override
  String get subscriptionDetailPage_studentSection_loadingError =>
      'Failed to load student information';

  @override
  String get subscriptionDetailPage_studentSection_subtitle =>
      'Subscriber details';

  @override
  String get subscriptionDetailPage_studentSection_name => 'Name';

  @override
  String get subscriptionDetailPage_studentSection_email => 'Email';

  @override
  String get subscriptionDetailPage_studentSection_status => 'Status';

  @override
  String get subscriptionDetailPage_studentSection_phone => 'Phone Number';

  @override
  String get peopleTab_appBar_title => 'People';

  @override
  String get peopleTab_loadingState => 'Loading users...';

  @override
  String get peopleTab_loadError => 'Error loading users';

  @override
  String get peopleTab_loadError_unknown => 'Unknown error';

  @override
  String get peopleTab_emptyStudents_title => 'No Students Yet';

  @override
  String get peopleTab_emptyStaff_title => 'No Staff Yet';

  @override
  String get peopleTab_emptyStudents_subtitle =>
      'There are no students registered yet';

  @override
  String get peopleTab_emptyStaff_subtitle =>
      'There are no staff members registered yet';

  @override
  String get peopleTab_handleApprove_success => 'has been approved!';

  @override
  String get peopleTab_handleApprove_error => 'Failed to approve user:';

  @override
  String get peopleTab_handleReject_success => 'has been rejected!';

  @override
  String get peopleTab_handleReject_error => 'Failed to reject user:';

  @override
  String get subscriptionAdminTab_searchHint => 'Search subscriptions...';

  @override
  String get subscriptionAdminTab_subsList_pending => 'Pending Review';

  @override
  String get subscriptionAdminTab_subsList_emptyCard =>
      'No pending subscriptions';

  @override
  String get subscriptionAdminTab_filterMenu_title => 'Filter Subscriptions';

  @override
  String get subscriptionAdminTab_filterMenu_ctaLabel => 'Clear Filters';

  @override
  String get subscriptionAdminTab_approveSub_exception =>
      'User not authenticated';

  @override
  String get subscriptionAdminTab_errorWidget_message =>
      'Error loading subscriptions';

  @override
  String get subscriptionAdminTab_emptyWidget_title => 'No subscriptions yet';

  @override
  String get subscriptionAdminTab_emptyWidget_searchTitle =>
      'No subscriptions found';

  @override
  String get subscriptionAdminTab_emptyWidget_subtitle =>
      'Subscriptions will appear here';

  @override
  String get subscriptionAdminTab_emptyWidget_searchSubtitle =>
      'Try adjusting your filters';

  @override
  String get scannerPage_viewArea_pausedTitle => 'Scanner paused';

  @override
  String get scannerPage_infoBubble => 'Scan student QR codes';

  @override
  String get scannerPage_controls_toggleFlash => 'Toggle flash';

  @override
  String get scannerPage_controls_pauseScanner => 'Pause scanner';

  @override
  String get scannerPage_controls_resumeScanner => 'Resume scanner';

  @override
  String get scannerPage_controls_resetScanner => 'Reset scanner';

  @override
  String get scannerPage_idleState_title => 'Ready to scan';

  @override
  String get scannerPage_idleState_subtitle =>
      'Point the camera at a student\'s QR code to verify their bus access';

  @override
  String get scannerPage_progressingState_title => 'Verifying...';

  @override
  String get scannerPage_progressingState_wait => 'Please wait';

  @override
  String get scannerPage_resultState_statusGranted => 'ACCESS GRANTED';

  @override
  String get scannerPage_resultState_statusDenied => 'ACCESS DENIED';

  @override
  String get scannerPage_resultState_errorUnknown => 'Unknown error';

  @override
  String get scannerPage_resultState_ctaLabel => 'Next Scan';

  @override
  String get scannerPage_compactInfo_email => 'Email';

  @override
  String get scannerPage_compactInfo_subscription => 'Subscription';

  @override
  String get scannerPage_compactInfo_busStop => 'Bus Stop';

  @override
  String get scannerPage_compactInfo_validity => 'Valid Until';

  @override
  String get scannerPage_compactInfo_emptySub => 'No active subscription found';

  @override
  String get scannerPage_errorCard_title => 'Error';

  @override
  String get analyticsTab_appBar_title => 'Analytics Dashboard';

  @override
  String get analyticsTab_appBar_actionNumView => 'Numerical View';

  @override
  String get analyticsTab_appBar_actionGraphView => 'Graphical View';

  @override
  String get analyticsTab_loadingError => 'Failed to load analytics data';

  @override
  String get analyticsTab_subStatusSection_title =>
      'Subscription Status Overview';

  @override
  String get analyticsTab_subStatusSection_subtitle =>
      'Current distribution of subscription statuses';

  @override
  String get analyticsTab_subStatusSection_pendingReview => 'Pending Review';

  @override
  String get analyticsTab_subStatusSection_approvalRate => 'Approval Rate:';

  @override
  String get analyticsTab_emptyData => 'No data available';

  @override
  String get analyticsTab_semesterSection_title => 'Semester Analytics';

  @override
  String get analyticsTab_semesterSection_chartTitle =>
      'Subscriptions by Semester';

  @override
  String get analyticsTab_semesterSection_subtitle =>
      'Subscriptions per semester this year';

  @override
  String get analyticsTab_semesterSection_empty =>
      'No semester data available for';

  @override
  String get analyticsTab_subByYear_title => 'Subscriptions by Year';

  @override
  String get analyticsTab_recentActivitySection_title => 'Recent Subscriptions';

  @override
  String get analyticsTab_recentActivitySection_subtitle =>
      'Last 10 submissions';

  @override
  String get analyticsTab_recentActivitySection_noData =>
      'No recent subscription';

  @override
  String get analyticsTab_topBusStopsSection_title => 'Most Popular Bus Stops';

  @override
  String get analyticsTab_topBusStopsSection_subtitle =>
      'Top 5 by subscription count';

  @override
  String get analyticsTab_topBusStopsSection_ctaLabel => 'Manage stops';

  @override
  String get analyticsTab_topBusStopsSection_noData =>
      'No bus stop data available';

  @override
  String get analyticsTab_quickActionsSection_title => 'Quick Actions';

  @override
  String get analyticsTab_quickActionsSection_subtitle =>
      'Manage your system efficiently';

  @override
  String get analyticsTab_quickActionsSection_subscriptions =>
      'Review Subscriptions';

  @override
  String get analyticsTab_quickActionsSection_subscriptionsSubtitle =>
      'Approve or reject pending subscriptions';

  @override
  String get analyticsTab_quickActionsSection_busStops => 'Manage Bus Stops';

  @override
  String get analyticsTab_quickActionsSection_busStopsSubtitle =>
      'Add, edit, or remove bus stops';

  @override
  String get analyticsTab_quickActionsSection_semesters => 'Manage Semesters';

  @override
  String get analyticsTab_quickActionsSection_semestersSubtitle =>
      'Configure semester dates and settings';

  @override
  String get newSubscriptionPage_scheduleTime_earlyError =>
      'Earliest morning time is 6:30 AM.';

  @override
  String get newSubscriptionPage_scheduleTime_morningError =>
      'Morning time must be <= closing time..';

  @override
  String get newSubscriptionPage_scheduleTime_latestError =>
      'Latest close time is 5:00 PM.';

  @override
  String get newSubscriptionPage_scheduleTime_closingError =>
      'Close time must be >= morning time.';

  @override
  String get newSubscriptionPage_validateStep_proofUpload =>
      'Please upload a proof of payment to proceed.';

  @override
  String get newSubscriptionPage_validateStep_semester =>
      'Please wait for active semester to load or contact administrator.';

  @override
  String get newSubscriptionPage_validateStep_stop =>
      'Select a preferred stop to proceed.';

  @override
  String get newSubscriptionPage_validateStep_schedule =>
      'Add at least one schedule.';

  @override
  String get newSubscriptionPage_validateStep_scheduleInvalid =>
      'One or more schedule times are invalid.';

  @override
  String get newSubscriptionPage_submit_validateSteps =>
      'Fill out every step before submitting.';

  @override
  String get newSubscriptionPage_submit_validateStop =>
      'Unable to resolve selected stop.';

  @override
  String get newSubscriptionPage_validateStep_proofUploadException =>
      'Proof file not found. Please re-upload.';

  @override
  String get newSubscriptionPage_validateStep_proofUploadMessage =>
      'Unable to upload proof:';

  @override
  String get newSubscriptionPage_submit_success =>
      'Subscription created (pending review)';

  @override
  String get newSubscriptionPage_submit_failed =>
      'Failed to submit subscription:';

  @override
  String get newSubscriptionPage_appBar_title => 'New Subscription';

  @override
  String get newSubscriptionPage_semesterStep_refreshSuccess =>
      'Semesters refreshed';

  @override
  String get newSubscriptionPage_stopStep_refreshSuccess => 'Stops refreshed';

  @override
  String get newSubscriptionPage_semesterStep_refresh => 'Refresh Semesters';

  @override
  String get newSubscriptionPage_stopStep_refresh => 'Refresh Stops';

  @override
  String get newSubscriptionPage_proofStep_title => 'Receipt';

  @override
  String get newSubscriptionPage_proofStep_subtitle => 'Proof of payment';

  @override
  String get newSubscriptionPage_proofStep_imageBox =>
      'Upload a copy of your receipt';

  @override
  String get newSubscriptionPage_semesterStep_emptyActive =>
      'No active semester available. Please contact the administrator.';

  @override
  String get newSubscriptionPage_semesterStep_activeSemester =>
      'Active semester';

  @override
  String get newSubscriptionPage_semesterStep_infoBubble =>
      'Your subscription will be valid for the active semester shown above.';

  @override
  String get newSubscriptionPage_stopStep_title => 'Preferred stop';

  @override
  String get newSubscriptionPage_stopStep_validatorEmpty =>
      'Select a bus stop.';

  @override
  String get newSubscriptionPage_stopStep_label => 'Select stop';

  @override
  String get newSubscriptionPage_scheduleStep_title => 'Weekly schedules';

  @override
  String get newSubscriptionPage_scheduleStep_optionEveryday => 'Everyday';

  @override
  String get newSubscriptionPage_scheduleStep_optionNormal => 'Normal week';

  @override
  String get newSubscriptionPage_scheduleStep_optionCustom => 'Custom';

  @override
  String get newSubscriptionPage_scheduleStep_empty =>
      'No schedules added. Add the days you take the bus.';

  @override
  String get newSubscriptionPage_scheduleStep_maxReached =>
      'Maximum of 6 days reached (Mon - Sat).';

  @override
  String get newSubscriptionPage_reviewStep_title => 'Review & Submit';

  @override
  String get newSubscriptionPage_reviewStep_subtitle =>
      'Review Your Subscription Details';

  @override
  String get newSubscriptionPage_reviewStep_description =>
      'Please verify all details before submitting';

  @override
  String get newSubscriptionPage_reviewStep_studentInfo =>
      'Student Information';

  @override
  String get newSubscriptionPage_reviewStep_studentName => 'Name';

  @override
  String get newSubscriptionPage_reviewStep_studentEmail => 'Email';

  @override
  String get newSubscriptionPage_reviewStep_semesterDetails =>
      'Semester Details';

  @override
  String get newSubscriptionPage_reviewStep_semesterEmpty =>
      'No semester selected';

  @override
  String get newSubscriptionPage_reviewStep_stopTitle => 'Pickup Stop';

  @override
  String get newSubscriptionPage_reviewStep_stopName => 'Stop Name';

  @override
  String get newSubscriptionPage_reviewStep_stopEmpty => 'No stop selected';

  @override
  String get newSubscriptionPage_reviewStep_weeklyScheduleTitle =>
      'Weekly Schedule';

  @override
  String get newSubscriptionPage_reviewStep_weeklyScheduleDay => 'Day';

  @override
  String get newSubscriptionPage_reviewStep_weeklyScheduleEmpty =>
      'No schedules added';

  @override
  String get newSubscriptionPage_reviewStep_infoBubbleTitle =>
      'Review Required';

  @override
  String get newSubscriptionPage_reviewStep_infoBubbleDescription =>
      'Your subscription will be reviewed by our team. You will receive a notification once it has been approved or if any changes are needed.';

  @override
  String get newSubscriptionPage_overlay_title =>
      'Submitting your subscription...';

  @override
  String get newSubscriptionPage_overlay_subtitle =>
      'We are securing your seat on the bus...';

  @override
  String get newSubscriptionPage_stopPreview_noLink =>
      'No map link available for this stop.';

  @override
  String get newSubscriptionPage_stopPreview_noImage => 'Image not available';

  @override
  String get newSubscriptionPage_stopPreview_mapsCta => 'View on Google Maps';

  @override
  String get newSubscriptionPage_stopPreview_noMedia => 'No media';

  @override
  String get newStopForm_handleSubmit_success =>
      'Bus stop created successfully';

  @override
  String get newStopForm_handleSubmit_failed => 'Failed to create bus stop';

  @override
  String get newStopForm_appBar_title => 'New Bus Stop';

  @override
  String get newStopForm_listTile_infoBubble =>
      'The form below allows you to create a new bus stop. This will be added to the list of available stops for users to select when subscribing to bus routes.';

  @override
  String get newStopForm_stopDetails => 'Bus Stop Details';

  @override
  String get newStopForm_stopDetails_image =>
      'Upload a capture of the place (optional)';

  @override
  String get newStopForm_stopDetails_nameLabel => 'Pickup place name *';

  @override
  String get newStopForm_stopDetails_nameHint => 'Name of the place';

  @override
  String get newStopForm_stopDetails_nameValidator =>
      'Please enter the name of the bus stop';

  @override
  String get newStopForm_stopDetails_mapsLabel => 'Maps URL (optional)';

  @override
  String get newStopForm_stopDetails_mapsHint =>
      'A Google maps link to the place';

  @override
  String get newStopForm_stopDetails_mapsValidator =>
      'Please enter a valid Google Maps link';

  @override
  String get newStopForm_handleSubmit_labelLoading => 'Adding...';

  @override
  String get newStopForm_handleSubmit_label => 'Add stop';

  @override
  String get editStopForm_handleSubmit_success =>
      'Bus stop updated successfully';

  @override
  String get editStopForm_handleSubmit_failed => 'Failed to update bus stop';

  @override
  String get editStopForm_appBar_title => 'Edit Bus Stop';

  @override
  String get editStopForm_notFound => 'Bus stop not found';

  @override
  String get editStopForm_notFound_ctaLabel => 'Go Back';

  @override
  String get editStopForm_listTile_infoBubble =>
      'Update the information for this bus stop. Changes will be reflected for all users who have subscribed to this stop.';

  @override
  String get editStopForm_metaData => 'Metadata';

  @override
  String get editStopForm_handleSubmit_labelLoading => 'Updating...';

  @override
  String get editStopForm_handleSubmit_label => 'Update stop';

  @override
  String get semesterFormPage_selectYear_null => 'Please select a year first';

  @override
  String get semesterFormPage_selectSemester_null =>
      'Please select a semester first';

  @override
  String get semesterFormPage_pickedDate_null => 'Start date must be in';

  @override
  String semesterFormPage_validateDate(
    String selectedYear1,
    String selectedYear2,
  ) {
    return 'End date must be in $selectedYear1 or $selectedYear2';
  }

  @override
  String get semesterFormPage_handleSubmit_yearNull => 'Please select a year';

  @override
  String get semesterFormPage_handleSubmit_semesterNull =>
      'Please select a semester';

  @override
  String get semesterFormPage_handleSubmit_datesNull =>
      'Please select start and end dates';

  @override
  String get semesterFormPage_handleSubmit_startIsAfter =>
      'Start date must be before end date';

  @override
  String get semesterFormPage_handleSubmit_semesterDurationDays =>
      'Semester must be at least 30 days long';

  @override
  String get semesterFormPage_handleSubmit_semesterDurationMonths =>
      'Semester cannot be longer than 6 months';

  @override
  String get semesterFormPage_handleSubmit_successCreated =>
      'Semester created successfully';

  @override
  String get semesterFormPage_handleSubmit_successUpdated =>
      'Semester updated successfully';

  @override
  String get semesterFormPage_handleSubmit_failedCreated =>
      'Failed to create semester';

  @override
  String get semesterFormPage_handleSubmit_failedUpdated =>
      'Failed to update semester';

  @override
  String get semesterFormPage_appBar_titleCreate => 'Add Semester';

  @override
  String get semesterFormPage_appBar_titleEdit => 'Edit Semester';

  @override
  String get semesterFormPage_infoBanner_update =>
      'Update the date range for this semester. Changes will affect all subscriptions using these dates.';

  @override
  String get semesterFormPage_infoBanner_create =>
      'Define the start and end dates for a semester. These dates will be used for subscription validity periods.';

  @override
  String get semesterFormPage_sectionHeader_semesterDetails =>
      'Semester Details';

  @override
  String get semesterFormPage_semesterDetails_type => 'Semester Type';

  @override
  String get semesterFormPage_semesterDetails_semesterSelected =>
      'is already registered for';

  @override
  String get semesterFormPage_sectionHeader_dateRange => 'Date Range';

  @override
  String get semesterFormPage_dateRange_startDate => 'Start Date';

  @override
  String get semesterFormPage_dateRange_startDateHint => 'Select start date';

  @override
  String get semesterFormPage_dateRange_endDate => 'End Date';

  @override
  String get semesterFormPage_dateRange_endDateHint => 'Select end date';

  @override
  String get semesterFormPage_sectionHeader_durationPreview => 'Duration';

  @override
  String get semesterFormPage_submit_update => 'Update Semester';

  @override
  String get semesterFormPage_submit_create => 'Add Semester';

  @override
  String get imageBox_sizeLimit => 'The image size should not be more than';

  @override
  String get imageBox_uploadError => 'Error during image upload:';

  @override
  String get imageBox_loadingError => 'Loading error';

  @override
  String get peopleTab_emptySearchState_title => 'No results found';

  @override
  String get peopleTab_emptySearchState_subtitle => 'Try adjusting your search';

  @override
  String get peopleTab_handlePromote_onlyAdmin =>
      'Only admins can promote/demote staff members';

  @override
  String get peopleTab_handlePromote_successPromote =>
      'has been promoted to Admin';

  @override
  String get peopleTab_handlePromote_successDemote =>
      'has been demoted to Staff';

  @override
  String get peopleTab_promoteModal_titlePromote => 'Promote to Admin';

  @override
  String get peopleTab_promoteModal_titleDemote => 'Demote to Staff';

  @override
  String get peopleTab_promoteModal_infoWarningTitle => 'Important Information';

  @override
  String get peopleTab_promoteModal_infoWarningSubtitlePromote =>
      'This user will gain full administrative access:';

  @override
  String get peopleTab_promoteModal_infoWarningSubtitleDemote =>
      'This user will lose administrative access:';

  @override
  String get peopleTab_promoteModal_ctaPromote => 'Promote';

  @override
  String get peopleTab_promoteModal_ctaDemote => 'Demote';

  @override
  String get peopleTab_accessList_promote1 => 'Manage all subscriptions';

  @override
  String get peopleTab_accessList_promote2 => 'Approve/Reject staff members';

  @override
  String get peopleTab_accessList_promote3 => 'Promote/Demote staff members';

  @override
  String get peopleTab_accessList_promote4 => 'Manage semesters and bus stops';

  @override
  String get peopleTab_accessList_promote5 => 'View all analytics';

  @override
  String get peopleTab_accessList_promote6 => 'Full system access';

  @override
  String get peopleTab_accessList_demote1 => 'Can only verify subscriptions';

  @override
  String get peopleTab_accessList_demote2 => 'Cannot approve staff members';

  @override
  String get peopleTab_accessList_demote3 => 'Cannot promote/demote users';

  @override
  String get peopleTab_accessList_demote4 => 'Limited management access';

  @override
  String get peopleTab_accessList_demote5 => 'Restricted analytics view';

  @override
  String get homeNav_updatesTab => 'Updates';

  @override
  String get checkInSheet_title => 'Today\'s Boarding List';

  @override
  String checkInSheet_subtitle(int count) {
    return '$count student(s) checked in';
  }

  @override
  String get checkInSheet_searchHint => 'Search student...';

  @override
  String get checkInSheet_emptyTitle => 'No check-ins yet';

  @override
  String get checkInSheet_emptySubtitle => 'Scan student QR codes to start';

  @override
  String get checkInSheet_noMatch => 'No matching students';

  @override
  String get checkInSheet_allTab => 'All';

  @override
  String get checkInSheet_morningTab => 'Morning';

  @override
  String get checkInSheet_closingTab => 'Closing';

  @override
  String get updatesTab_earlierToday => 'Earlier today';

  @override
  String get updatesTab_emptyState =>
      'No updates yet today.\nBe the first to share one!';

  @override
  String get updatesTab_genericHint => 'Send an update to your mates...';

  @override
  String get updatesTab_notSubscribed =>
      'You need an active subscription to send updates';

  @override
  String get updatesTab_needScanForLocation =>
      'You must board the bus (scan QR) before sharing location';

  @override
  String peopleTab_subscriptionCount(int count) {
    return '$count sub(s)';
  }

  @override
  String get scanner_checkInListTooltip => 'Boarding List';

  @override
  String get scanner_cameraPermissionDenied => 'Camera permission denied';

  @override
  String get scanner_cameraPermissionMessage =>
      'Camera access is required to scan QR codes. Please allow camera access in your device settings.';

  @override
  String get scanner_openSettings => 'Open Settings';

  @override
  String get scanner_maxScansReached =>
      'This student has already been scanned twice today';

  @override
  String get profilePage_listTile_myReports => 'My Reports';

  @override
  String get profilePage_listTile_studentReports => 'Student Reports';

  @override
  String get profilePage_studentReports_subtitle =>
      'View and resolve student complaints';

  @override
  String get profilePage_pendingBadge => 'pending';

  @override
  String get profilePage_listTile_checkInHistory => 'Check-in History';

  @override
  String get profilePage_checkInHistory_subtitle =>
      'View daily attendance trends & records';

  @override
  String get reportsPage_title => 'My Reports';

  @override
  String get reportsPage_newReport => 'New Report';

  @override
  String get reportsPage_emptyTitle => 'No reports yet';

  @override
  String get reportsPage_emptySubtitle =>
      'Submit a report to share your concerns about the bus service.';

  @override
  String get reportsPage_adminResponse => 'Admin Response';

  @override
  String get reportSheet_title => 'Submit a Report';

  @override
  String get reportSheet_subtitle =>
      'Tell us about any concern regarding the bus service.';

  @override
  String get reportSheet_subject => 'Subject';

  @override
  String get reportSheet_customSubjectHint => 'Custom subject title...';

  @override
  String get reportSheet_description => 'Description';

  @override
  String reportSheet_priority(String priority) {
    return 'Priority: $priority';
  }

  @override
  String get reportsAdminPage_title => 'Student Reports';

  @override
  String get reportsAdmin_tabPending => 'Pending';

  @override
  String get reportsAdmin_tabInReview => 'In Review';

  @override
  String get reportsAdmin_tabResolved => 'Resolved';

  @override
  String get reportsAdmin_emptyPending => 'No pending reports';

  @override
  String get reportsAdmin_emptyInReview => 'No reports in review';

  @override
  String get reportsAdmin_emptyResolved => 'No resolved reports';

  @override
  String get reportsAdmin_response => 'Response';

  @override
  String get reportsAdmin_review => 'Review';

  @override
  String get reportsAdmin_resolve => 'Resolve';

  @override
  String get reportsAdmin_resolveTitle => 'Resolve Report';

  @override
  String get reportsAdmin_responseHint =>
      'Add a response for the student (optional)...';

  @override
  String get reportsAdmin_markResolved => 'Mark as Resolved';

  @override
  String get checkInHistory_title => 'Check-in History';

  @override
  String get checkInHistory_dailyLists => 'Daily Lists';

  @override
  String get checkInHistory_emptyTitle => 'No check-in history';

  @override
  String get checkInHistory_emptySubtitle =>
      'Start scanning students to build attendance records.';

  @override
  String get checkInHistory_trendTitle => 'Attendance Trend';

  @override
  String checkInHistory_trendSubtitle(int count) {
    return 'Last $count days';
  }

  @override
  String get checkInHistory_total => 'Total';

  @override
  String get checkInHistory_morning => 'Morning';

  @override
  String get checkInHistory_evening => 'Closing';

  @override
  String get checkInHistory_days => 'Days';

  @override
  String get checkInHistory_totalScans => 'Total Scans';

  @override
  String get checkInHistory_avgPerDay => 'Avg / Day';

  @override
  String get checkInHistory_today => 'Today';

  @override
  String checkInHistory_studentCount(int count) {
    return '$count student(s)';
  }

  @override
  String get greeting_morning => 'Good morning! ☀️';

  @override
  String get greeting_afternoon => 'Good afternoon! 🌤️';

  @override
  String get greeting_evening => 'Good evening! 🌙';

  @override
  String get validation_phoneRequired => 'Phone number is required';

  @override
  String get validation_phoneInvalid =>
      'Please enter a valid Cameroon phone number';

  @override
  String get validation_matriculeRequired => 'Student ID is required';

  @override
  String get validation_matriculeLength =>
      'Student ID must be 12 characters long';

  @override
  String get validation_matriculePrefix => 'Student ID must start with ICTU';

  @override
  String get validation_matriculeYear => 'Invalid year in Student ID';

  @override
  String get validation_matriculeDigits => 'Last 4 characters must be digits';

  @override
  String get semesterPage_viewStudents => 'View registered students';

  @override
  String get semesterPage_studentsTitle => 'Registered Students';

  @override
  String semesterPage_studentsSubtitle(int count) {
    return '$count student(s) registered';
  }

  @override
  String get semesterPage_noStudents =>
      'No students registered for this semester';

  @override
  String get semesterPage_searchStudents => 'Search students...';
}
