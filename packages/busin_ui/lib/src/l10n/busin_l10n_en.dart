// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'busin_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class BusinL10nEn extends BusinL10n {
  BusinL10nEn([String locale = 'en']) : super(locale);

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionClose => 'Close';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionBack => 'Back';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get stateLoading => 'Loading...';

  @override
  String get stateEmpty => 'Nothing here yet';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get errorOffline => 'No connection. Check your network and try again.';

  @override
  String get errorNotAllowed => 'You do not have access to this.';

  @override
  String get errorNotFound => 'This could not be found.';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleStaff => 'Staff';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get accountPending => 'Pending';

  @override
  String get accountVerified => 'Active';

  @override
  String get accountSuspended => 'Suspended';

  @override
  String get subscriptionPending => 'Pending';

  @override
  String get subscriptionApproved => 'Approved';

  @override
  String get subscriptionRejected => 'Rejected';

  @override
  String get subscriptionRevoked => 'Revoked';

  @override
  String get subscriptionExpired => 'Expired';

  @override
  String get tripScheduled => 'Scheduled';

  @override
  String get tripActive => 'Running';

  @override
  String get tripCompleted => 'Completed';

  @override
  String get tripCancelled => 'Cancelled';

  @override
  String get directionInbound => 'Going to school';

  @override
  String get directionOutbound => 'Going home';

  @override
  String get semesterFall => 'Fall';

  @override
  String get semesterSpring => 'Spring';

  @override
  String get semesterSummer => 'Summer';

  @override
  String semesterLabel(String name, int year) {
    return '$name $year';
  }

  @override
  String avatarOf(String name) {
    return 'Picture of $name';
  }

  @override
  String setupWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get setupBody =>
      'Tell your school who you are so the driver can find you. It takes a minute.';

  @override
  String get setupSave => 'Save and continue';

  @override
  String get setupNotYou => 'Not you? Sign out';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldFullNameHint => 'As on your student card';

  @override
  String get fieldMatricule => 'Student number';

  @override
  String get fieldMatriculeHint => 'For example ICT2026-0001';

  @override
  String get fieldPhone => 'Phone number';

  @override
  String get fieldPhoneHint => 'For example 677 12 34 56';

  @override
  String get fieldDepartment => 'Department';

  @override
  String get fieldDepartmentHint => 'Choose your department';

  @override
  String get fieldProgram => 'Program';

  @override
  String get fieldProgramHint => 'Choose your degree level';

  @override
  String get fieldFaculty => 'Faculty';

  @override
  String get fieldFacultyHint => 'Choose your faculty';

  @override
  String get fieldDepartmentFirst => 'Choose a faculty first';

  @override
  String get choiceNone => 'Not chosen';

  @override
  String get fieldTooShort => 'That looks too short.';

  @override
  String get fieldTooLong => 'That is too long.';

  @override
  String get fieldInvalid => 'Check this one: it has characters we cannot use.';

  @override
  String get profileTitle => 'Your profile';

  @override
  String get profileOpen => 'Open your profile';

  @override
  String get profileDetails => 'Your details';

  @override
  String get profileEdit => 'Edit details';

  @override
  String get profileNotSet => 'Not set';

  @override
  String profileMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get profileSaved => 'Details saved.';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileSignOutTitle => 'Sign out of BusIn?';

  @override
  String get profileSignOutBody =>
      'You will need to sign in with Google again.';

  @override
  String get profileCredits => '3D illustrations by Thiings (thiings.co)';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get loadingSlowTitle => 'This is taking longer than usual';

  @override
  String get loadingSlowBody => 'Check your connection. BusIn keeps trying.';

  @override
  String get loadingLabel => 'Loading';

  @override
  String get appName => 'BusIn';

  @override
  String get signInTitle => 'Hop on. BusIn handles the rest.';

  @override
  String get signInSubtitle =>
      'Sign in with your school Google account to subscribe, show your boarding code and follow your bus.';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get signInCancelled => 'Sign-in was cancelled.';

  @override
  String get signInFailed => 'Sign-in did not work. Try again.';

  @override
  String get signInNotAllowed =>
      'This Google account is not allowed here. Use your school account.';

  @override
  String get blockedStaffTitle => 'This app is for students';

  @override
  String get blockedStaffBody =>
      'Your account is a staff or administrator account. Staff use the BusIn ops app, and administrators use the admin portal.';

  @override
  String get blockedPendingTitle => 'Your account is waiting for approval';

  @override
  String get blockedPendingBody =>
      'A school administrator needs to verify your account before you can use BusIn.';

  @override
  String get blockedSuspendedTitle => 'Your account is suspended';

  @override
  String get blockedSuspendedBody =>
      'Contact your school\'s transport office to find out why.';

  @override
  String get navSubscription => 'Subscription';

  @override
  String get navQr => 'Boarding code';

  @override
  String get navHistory => 'History';

  @override
  String get navProfile => 'Profile';

  @override
  String get profileAppearance => 'Appearance';

  @override
  String get profileAppearanceHint => 'Kept on this phone.';

  @override
  String get profileTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get profileLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get profileHistory => 'Boarding history';

  @override
  String get profileHistoryBody => 'Every time you boarded, newest first.';

  @override
  String get navBus => 'My bus';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonBody => 'This part of the app is being built.';

  @override
  String get subscriptionNoSemesterTitle => 'No semester open yet';

  @override
  String get subscriptionNoSemesterBody =>
      'You can subscribe as soon as your school adds the semester.';

  @override
  String subscriptionStarts(String date) {
    return 'Starts $date';
  }

  @override
  String subscribeHeading(String semester) {
    return 'Subscribe for $semester';
  }

  @override
  String get subscribeIntro =>
      'Choose where you board and add a photo of your payment receipt. Your school checks it and approves your request.';

  @override
  String get subscribeStopLabel => 'Your stop';

  @override
  String get subscribeStopHint => 'Choose where you board';

  @override
  String get subscribeStopSearch => 'Search stops';

  @override
  String get subscribeStopNone => 'No stop matches.';

  @override
  String get subscribeProofLabel => 'Payment proof';

  @override
  String get subscribeProofHint => 'Add a clear photo of your receipt';

  @override
  String get subscribeProofPrivacy =>
      'Only you and your school\'s administrators can see it.';

  @override
  String get proofTakePhoto => 'Take a photo';

  @override
  String get proofChoosePhoto => 'Choose from gallery';

  @override
  String get proofChange => 'Change photo';

  @override
  String get subscribeSubmit => 'Send request';

  @override
  String get subscribeErrorType => 'Use a JPEG, PNG or WebP photo.';

  @override
  String get subscribeErrorTooLarge =>
      'That photo is too large. Pick one under 5 MB.';

  @override
  String get subscribeErrorExists =>
      'You already have a request for this semester. Pull down to refresh.';

  @override
  String get subscriptionStop => 'Stop';

  @override
  String subscriptionSent(String date) {
    return 'Sent $date';
  }

  @override
  String get proofView => 'View your payment proof full screen';

  @override
  String get proofClose => 'Close';

  @override
  String get requestsTitle => 'Your requests this semester';

  @override
  String get requestsHint => 'Everything that happened, the latest first.';

  @override
  String requestOf(String date) {
    return 'Request of $date';
  }

  @override
  String get requestEventRequested => 'You sent the request';

  @override
  String get requestEventApproved => 'Your school approved it';

  @override
  String get requestEventRejected => 'Your school declined it';

  @override
  String get requestEventRevoked => 'Your school ended it';

  @override
  String get requestEventReinstated => 'Your school gave it back';

  @override
  String get subscriptionProofTitle => 'Your payment proof';

  @override
  String get statusPendingTitle => 'Request sent';

  @override
  String get statusPendingBody =>
      'Your school is checking your payment proof. Pull down to see if it has been decided.';

  @override
  String get statusApprovedTitle => 'You are subscribed';

  @override
  String statusApprovedBody(String stop) {
    return 'You can board at $stop.';
  }

  @override
  String get statusApprovedAction => 'Show boarding code';

  @override
  String get statusRejectedTitle => 'Request not approved';

  @override
  String get statusRejectedReason => 'Your school\'s reason:';

  @override
  String get statusRejectedNoReason => 'Your school did not give a reason.';

  @override
  String get statusRequestAgain => 'Request again';

  @override
  String get statusRevokedTitle => 'Subscription ended by your school';

  @override
  String get statusRevokedReason => 'Your school\'s reason:';

  @override
  String get statusExpiredTitle => 'Subscription ended';

  @override
  String get statusExpiredBody =>
      'This subscription is no longer valid. You can send a new request.';

  @override
  String get qrChecking => 'Checking your subscription';

  @override
  String get qrTitle => 'Boarding code';

  @override
  String get qrHint => 'Show this code to the driver or staff when you board.';

  @override
  String get qrImageLabel => 'Your boarding code. It changes every 30 seconds.';

  @override
  String get qrLive => 'Live code';

  @override
  String get qrPrivateTitle => 'Keep your code to yourself';

  @override
  String get qrPrivateBodyProtected =>
      'It changes by itself, and screenshots are turned off here.';

  @override
  String get qrPrivateBody => 'It changes by itself and only works for you.';

  @override
  String get qrRefreshed => 'Code refreshed.';

  @override
  String get boardTitle => 'How to board';

  @override
  String get boardStep1 => 'Have this screen open when you reach the door.';

  @override
  String get boardStep2 => 'Hold your phone to the scanner until it confirms.';

  @override
  String get boardStep3 => 'Take any seat. Your ride is saved in History.';

  @override
  String get qrNoSubscriptionTitle => 'No active subscription';

  @override
  String get qrNoSubscriptionBody =>
      'Your boarding code appears as soon as your subscription is approved.';

  @override
  String get qrGoToSubscription => 'Go to subscription';

  @override
  String get qrOfflineTitle => 'Connect once to set up your code';

  @override
  String get qrOfflineBody =>
      'Your phone needs the internet one time to get your boarding code. After that it works without a connection.';

  @override
  String get historyTitle => 'Your boardings';

  @override
  String get historyStatWeek => 'Boardings this week';

  @override
  String get historyStatStop => 'Most used stop';

  @override
  String get historyStatStopNone => 'None yet';

  @override
  String historyDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boardings',
      one: '1 boarding',
    );
    return '$_temp0';
  }

  @override
  String get historyDayFirst => 'First boarding';

  @override
  String get historyDayLast => 'Last boarding';

  @override
  String get historyDayStops => 'Stops used';

  @override
  String get historySelectedDay => 'Selected day';

  @override
  String get historyEmptyTitle => 'No boardings yet';

  @override
  String get historyEmptyBody =>
      'Each time you board with your code, it appears here.';

  @override
  String get historyStopUnknown => 'Stop not recorded';

  @override
  String get historyLoadMoreFailed => 'Could not load more. Tap to try again.';

  @override
  String get busLockedTitle => 'Following the bus is for subscribers';

  @override
  String get busLockedBody =>
      'Once your subscription is approved you can see where your bus is, live.';

  @override
  String get busLockedAction => 'Go to subscription';

  @override
  String get busNoneTitle => 'No bus is running right now';

  @override
  String get busNoneBody => 'When a trip starts you can follow its bus here.';

  @override
  String get busWaiting => 'Waiting for the bus to share its location.';

  @override
  String busUpdatedSeconds(String seconds) {
    return 'Updated $seconds s ago';
  }

  @override
  String busUpdatedMinutes(String minutes) {
    return 'Updated $minutes min ago';
  }

  @override
  String busStale(String minutes) {
    return 'Last seen $minutes min ago. The bus may be out of signal.';
  }

  @override
  String busSpeed(String kmh) {
    return '$kmh km/h';
  }

  @override
  String busEtaMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get busEtaArriving => 'Arriving';

  @override
  String busEtaCaption(String km, String stop) {
    return '$km km from $stop';
  }

  @override
  String busDistanceKm(String km) {
    return '$km km';
  }

  @override
  String get busEtaLabel => 'Estimated arrival';

  @override
  String get busRunning => 'Running buses';

  @override
  String get busYourStop => 'Your stop';

  @override
  String get busRecenter => 'Show the bus';

  @override
  String get busLiveFailed => 'Live updates are not available right now.';

  @override
  String get busMapLabel => 'Map of the bus and the stops';

  @override
  String get pushPromptTitle => 'Get notified';

  @override
  String get pushPromptBody =>
      'We can tell you as soon as your school decides on your request, even when the app is closed.';

  @override
  String get pushPromptEnable => 'Turn on notifications';

  @override
  String get pushPromptLater => 'Not now';

  @override
  String get pushPromptDenied =>
      'Notifications are off. You can turn them on in your phone\'s settings.';

  @override
  String get pushForegroundApproved => 'Your subscription was approved.';

  @override
  String get pushForegroundRejected =>
      'Your school has decided on your subscription.';

  @override
  String get liveReinstated => 'Your school gave your subscription back.';

  @override
  String get liveRevoked => 'Your school ended your subscription.';

  @override
  String get pushForegroundView => 'View';

  @override
  String get navQrShort => 'Code';

  @override
  String get greetMorning => 'Good morning';

  @override
  String get greetAfternoon => 'Good afternoon';

  @override
  String get greetEvening => 'Good evening';

  @override
  String get stageSent => 'Sent';

  @override
  String get stageChecking => 'Checking';

  @override
  String get stageDecided => 'Decision';

  @override
  String stageSemantics(String number, String total, String label) {
    return 'Step $number of $total: $label';
  }

  @override
  String get howTitle => 'How it works';

  @override
  String get howStep1 => 'Choose where you board.';

  @override
  String get howStep2 => 'Add a photo of your payment receipt.';

  @override
  String get howStep3 => 'Your school checks it and decides.';

  @override
  String get howStep4 => 'Show your boarding code and ride.';

  @override
  String get proofAdded => 'Photo added';

  @override
  String get legalTitle => 'Legal';

  @override
  String get legalHint =>
      'Terms and privacy. They are in the app, so you can read them offline.';

  @override
  String get legalTerms => 'Terms of use';

  @override
  String get legalTermsBody => 'The rules for using BusIn';

  @override
  String get legalPrivacy => 'Privacy policy';

  @override
  String get legalPrivacyBody => 'What we keep about you, and why';

  @override
  String get legalAcceptable => 'Acceptable use';

  @override
  String get legalAcceptableBody => 'What is and is not allowed';

  @override
  String get legalInShort => 'In short';

  @override
  String legalUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String legalAppliesTo(String school) {
    return 'Applies to $school';
  }

  @override
  String get legalAlsoRead => 'Also read';

  @override
  String get legalQuestionsTitle => 'Questions about your data?';

  @override
  String get legalQuestionsBody =>
      'Ask your school\'s administration. They can correct your details and answer requests about your account.';

  @override
  String legalReadTime(int minutes) {
    return '$minutes min read';
  }

  @override
  String get legalOnThisPage => 'On this page';

  @override
  String get offlineTitle => 'No connection';

  @override
  String offlineBody(String when) {
    return 'Your saved pass still works at the door. Last updated $when.';
  }

  @override
  String offlineSavedCopy(String when) {
    return 'This is the copy saved on this phone ($when). Connect to the internet to send or change a request.';
  }

  @override
  String get offlineNeedsConnection =>
      'Connect to the internet to send your request.';

  @override
  String get proofUnavailable => 'Your payment proof';

  @override
  String get proofUnavailableHint =>
      'It could not be loaded. Tap to try again.';

  @override
  String get joinTitle => 'Choose your school';

  @override
  String get joinBody =>
      'Your Google account is not a school email, so ask your school to let you in. An administrator there will check it is you.';

  @override
  String get joinSearch => 'Search for your school';

  @override
  String get joinSearchHint => 'Name or city';

  @override
  String get joinEmptyTitle => 'No school accepts your email yet';

  @override
  String get joinEmptyBody =>
      'Sign in with your school email, or ask your school to accept students with other email addresses.';

  @override
  String get joinNoMatch => 'No school matches your search.';

  @override
  String joinConfirmTitle(String school) {
    return 'Ask to join $school?';
  }

  @override
  String joinConfirmBody(String school) {
    return 'An administrator of $school will check that you are their student. You can change your request while you wait.';
  }

  @override
  String get joinConfirmAction => 'Ask to join';

  @override
  String get joinSent => 'Request sent.';

  @override
  String get joinTooSoon => 'Wait a few seconds before changing your request.';

  @override
  String joinDeclinedTitle(String school) {
    return '$school declined your request';
  }

  @override
  String get joinDeclinedNoReason =>
      'They did not give a reason. You can ask another school, or contact them.';

  @override
  String joinDeclinedReason(String reason) {
    return 'Their reason: $reason';
  }

  @override
  String waitingTitle(String school) {
    return 'Waiting for $school';
  }

  @override
  String waitingBody(String date) {
    return 'You asked to join on $date. An administrator of your school will check your request; you can use BusIn as soon as they accept it.';
  }

  @override
  String get waitingCheck => 'Check again';

  @override
  String get waitingStill =>
      'Still waiting. We will check again when you come back to the app.';

  @override
  String get waitingChange => 'Choose another school';

  @override
  String joiningTitle(String school) {
    return 'You are joining $school';
  }

  @override
  String get joiningBody => 'Your school email puts you in this school.';

  @override
  String get joiningNotMine => 'Not my school?';

  @override
  String get joiningNotMineTitle => 'Not your school?';

  @override
  String joiningNotMineBody(String school) {
    return 'You signed in with an email of $school. If you study somewhere else, sign out and sign in with your own school\'s account.';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsHint =>
      'Choose your bus days and what BusIn reminds you of.';

  @override
  String get notificationsDays => 'My bus days';

  @override
  String get notificationsDaysHint => 'Reminders come only on these days.';

  @override
  String get notificationsMorning => 'Morning reminder';

  @override
  String get notificationsMorningHint => 'A nudge before you leave home.';

  @override
  String get notificationsEvening => 'Evening reminder';

  @override
  String get notificationsEveningHint => 'Almost time to head back to the bus.';

  @override
  String get notificationsBusNear => 'Bus near my stop';

  @override
  String get notificationsBusNearHint =>
      'When your bus is about this far from your stop.';

  @override
  String notificationsBusNearMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get notificationsBoarding => 'A word when I board';

  @override
  String get notificationsBoardingHint =>
      'A short message on screen when your code is scanned.';

  @override
  String get notificationsSchool => 'From your school';

  @override
  String get notificationsSchoolHint =>
      'Changes to your semester or service. Always on.';

  @override
  String notificationsAt(String time) {
    return 'At $time';
  }

  @override
  String get notificationsSaved => 'Saved.';

  @override
  String get notificationsPermission =>
      'Allow notifications in your phone\'s settings so reminders can show.';

  @override
  String get reminderMorningTitle => 'Bus day';

  @override
  String get reminderMorningBody =>
      'Your pass is ready. Open BusIn to see where the bus is.';

  @override
  String get reminderEveningTitle => 'Heading home?';

  @override
  String get reminderEveningBody =>
      'Time to get ready for the bus. Open BusIn to see where it is.';

  @override
  String get boardedTitle => 'On board';

  @override
  String boardedEarlier(String time) {
    return 'You boarded at $time';
  }

  @override
  String get boardedClose => 'Close';

  @override
  String get streakTitle => 'Streaks';

  @override
  String get streakHint =>
      'Count the days you take the bus, and join your school\'s leaderboard.';

  @override
  String get streakOnTitle => 'Keep a streak?';

  @override
  String streakOnBody(String name) {
    return 'BusIn counts the days you board. Rest days and days without buses do not break it; only a bus day you miss does. You will also appear on your school\'s leaderboard as $name. You can turn it off at any time.';
  }

  @override
  String get streakOnAction => 'Turn on streaks';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
      zero: 'No streak yet',
    );
    return '$_temp0';
  }

  @override
  String streakBest(int count) {
    return 'Best $count';
  }

  @override
  String streakRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rides this semester',
      one: '1 ride this semester',
    );
    return '$_temp0';
  }

  @override
  String get streakSheetTitle => 'Your streak';

  @override
  String get streakRode => 'Rode';

  @override
  String get streakMissed => 'Missed';

  @override
  String get streakRest => 'Rest or no bus';

  @override
  String get streakToday => 'Today';

  @override
  String get streakViewLabel => 'Streak view';

  @override
  String get streakTabCalendar => 'Calendar';

  @override
  String get streakTabBoard => 'Leaderboard';

  @override
  String get leaderboardNote =>
      'Students of your school who keep a streak, by current streak.';

  @override
  String get leaderboardEmpty => 'No one is on the board yet.';

  @override
  String get leaderboardYou => 'You';

  @override
  String leaderboardRank(int rank) {
    return 'Rank $rank';
  }
}
