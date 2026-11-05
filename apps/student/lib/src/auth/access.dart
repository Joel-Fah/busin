import 'package:busin_core/busin_core.dart';

/// Why a signed-in account cannot use the student app.
enum BlockReason { notStudent, pending, suspended }

/// What the app is allowed to show right now. Computed from the session and the profile, both of
/// which the server controls: nothing here comes from a field the user can edit.
sealed class AccessState {
  const AccessState();
}

class SignedOut extends AccessState {
  const SignedOut();
}

class AccessLoading extends AccessState {
  const AccessLoading();
}

class AccessLoadFailed extends AccessState {
  const AccessLoadFailed();
}

class Blocked extends AccessState {
  const Blocked(this.reason);

  final BlockReason reason;
}

/// A verified student who has not yet told the school who they are (student number, phone). They finish that first.
class NeedsSetup extends AccessState {
  const NeedsSetup(this.profile);

  final Profile profile;
}

class Allowed extends AccessState {
  const Allowed(this.profile);

  final Profile profile;
}

/// The rules, kept pure so every case is a unit test.
///
/// Only a verified student gets in. A staff or administrator account is turned away first, whatever its
/// status, because those people have their own tools.
AccessState accessFor({
  required bool sessionLoading,
  required String? userId,
  required bool profileLoading,
  required Object? profileError,
  required Profile? profile,
}) {
  if (sessionLoading) return const AccessLoading();
  if (userId == null) return const SignedOut();
  if (profileError != null) return const AccessLoadFailed();
  if (profileLoading || profile == null) return const AccessLoading();
  if (profile.role != UserRole.student) return const Blocked(BlockReason.notStudent);
  return switch (profile.status) {
    AccountStatus.pending => const Blocked(BlockReason.pending),
    AccountStatus.suspended => const Blocked(BlockReason.suspended),
    AccountStatus.verified => profile.isSetupComplete ? Allowed(profile) : NeedsSetup(profile),
  };
}
