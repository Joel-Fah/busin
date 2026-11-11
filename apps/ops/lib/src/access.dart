import 'package:busin_core/busin_core.dart';

/// What the ops app may show, worked out from the session and the profile. The server enforces every rule again; this
/// only decides which screen to show.
sealed class OpsAccess {
  const OpsAccess();
}

class OpsSignedOut extends OpsAccess {
  const OpsSignedOut();
}

class OpsLoading extends OpsAccess {
  const OpsLoading();
}

/// The profile could not be read (offline at first launch, or a server problem).
class OpsLoadFailed extends OpsAccess {
  const OpsLoadFailed(this.error);
  final Object error;
}

enum OpsBlockReason { notStaff, suspended }

class OpsBlocked extends OpsAccess {
  const OpsBlocked(this.reason);
  final OpsBlockReason reason;
}

/// A verified staff member or administrator of a school.
class OpsAllowed extends OpsAccess {
  const OpsAllowed(this.profile);
  final Profile profile;

  bool get isAdmin => profile.role == UserRole.admin;
}

/// The rules, as a pure function so they are tested on their own.
OpsAccess opsAccessFor({
  required bool sessionLoading,
  required String? userId,
  required bool profileLoading,
  required Object? profileError,
  required Profile? profile,
}) {
  if (sessionLoading) return const OpsLoading();
  if (userId == null) return const OpsSignedOut();
  if (profileLoading) return const OpsLoading();
  if (profileError != null) return OpsLoadFailed(profileError);
  if (profile == null) return const OpsSignedOut();
  if (!profile.role.isStaffOrAdmin || profile.schoolId == null) return const OpsBlocked(OpsBlockReason.notStaff);
  if (profile.status != AccountStatus.verified) return const OpsBlocked(OpsBlockReason.suspended);
  return OpsAllowed(profile);
}
