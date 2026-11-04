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
}
