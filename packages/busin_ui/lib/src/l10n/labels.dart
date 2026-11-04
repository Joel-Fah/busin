import 'package:busin_core/busin_core.dart';

import '../widgets/status_chip.dart';
import 'busin_l10n.dart';

/// The words and tones for the domain enums, so every app names things the same way.
extension BusinLabels on BusinL10n {
  String role(UserRole role) => switch (role) {
        UserRole.student => roleStudent,
        UserRole.staff => roleStaff,
        UserRole.admin => roleAdmin,
      };

  String accountStatus(AccountStatus status) => switch (status) {
        AccountStatus.pending => accountPending,
        AccountStatus.verified => accountVerified,
        AccountStatus.suspended => accountSuspended,
      };

  String subscriptionStatus(SubscriptionStatus status) => switch (status) {
        SubscriptionStatus.pending => subscriptionPending,
        SubscriptionStatus.approved => subscriptionApproved,
        SubscriptionStatus.rejected => subscriptionRejected,
        SubscriptionStatus.expired => subscriptionExpired,
      };

  String tripStatus(TripStatus status) => switch (status) {
        TripStatus.scheduled => tripScheduled,
        TripStatus.active => tripActive,
        TripStatus.completed => tripCompleted,
        TripStatus.cancelled => tripCancelled,
      };

  String direction(TripDirection direction) => switch (direction) {
        TripDirection.inbound => directionInbound,
        TripDirection.outbound => directionOutbound,
      };

  String semester(SemesterName name, int year) => semesterLabel(
        switch (name) {
          SemesterName.fall => semesterFall,
          SemesterName.spring => semesterSpring,
          SemesterName.summer => semesterSummer,
        },
        year,
      );

  /// A message for a failure, in the person's language. Screens show this, never the exception text.
  String failure(RepositoryException error) => switch (error) {
        Offline() => errorOffline,
        NotAllowed() => errorNotAllowed,
        NotFound() => errorNotFound,
        _ => errorGeneric,
      };
}

/// The tone each status takes, the same as the admin portal's chips.
StatusTone subscriptionTone(SubscriptionStatus status) => switch (status) {
      SubscriptionStatus.approved => StatusTone.ok,
      SubscriptionStatus.rejected => StatusTone.bad,
      SubscriptionStatus.expired => StatusTone.neutral,
      SubscriptionStatus.pending => StatusTone.warn,
    };

StatusTone tripTone(TripStatus status) => switch (status) {
      TripStatus.active => StatusTone.ok,
      TripStatus.scheduled => StatusTone.info,
      TripStatus.cancelled => StatusTone.bad,
      TripStatus.completed => StatusTone.neutral,
    };

StatusTone accountTone(AccountStatus status) => switch (status) {
      AccountStatus.verified => StatusTone.ok,
      AccountStatus.suspended => StatusTone.bad,
      AccountStatus.pending => StatusTone.warn,
    };
