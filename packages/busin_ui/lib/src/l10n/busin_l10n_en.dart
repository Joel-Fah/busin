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
}
