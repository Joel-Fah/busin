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
  String get fieldRequired => 'This field is required.';

  @override
  String get loadingLabel => 'Loading';

  @override
  String get appName => 'BusIn';

  @override
  String get signInTitle => 'Ride with BusIn';

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
  String get statusExpiredTitle => 'Subscription ended';

  @override
  String get statusExpiredBody =>
      'This subscription is no longer valid. You can send a new request.';

  @override
  String get qrTitle => 'Boarding code';

  @override
  String get qrHint => 'Show this code to the driver or staff when you board.';

  @override
  String get qrImageLabel => 'Your boarding code. It changes every 30 seconds.';

  @override
  String qrRefreshesIn(String seconds) {
    return 'New code in $seconds s';
  }

  @override
  String get qrScreenshotsOff =>
      'Screenshots are turned off here so a copy of your code cannot be shared.';

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
  String get historyEmptyTitle => 'No boardings yet';

  @override
  String get historyEmptyBody =>
      'Each time you board with your code, it appears here.';

  @override
  String get historyStopUnknown => 'Stop not recorded';

  @override
  String get historyLoadMoreFailed => 'Could not load more. Tap to try again.';

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
  String get pushForegroundView => 'View';
}
