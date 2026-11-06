import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/auth/access.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

AccessState check({
  bool sessionLoading = false,
  String? userId = 'u1',
  bool profileLoading = false,
  Object? profileError,
  Profile? loaded,
}) =>
    accessFor(
      sessionLoading: sessionLoading,
      userId: userId,
      profileLoading: profileLoading,
      profileError: profileError,
      profile: loaded,
    );

void main() {
  test('waits while the session is being read', () {
    expect(check(sessionLoading: true, userId: null), isA<AccessLoading>());
  });

  test('signed out when there is no user', () {
    expect(check(userId: null), isA<SignedOut>());
  });

  test('waits while the profile loads, and when it has not arrived', () {
    expect(check(profileLoading: true), isA<AccessLoading>());
    expect(check(), isA<AccessLoading>());
  });

  test('a profile that cannot be read is a failure, not a way in', () {
    expect(check(profileError: Exception('x'), loaded: profile()), isA<AccessLoadFailed>());
  });

  test('a verified student is allowed', () {
    final state = check(loaded: profile());
    expect(state, isA<Allowed>());
    expect((state as Allowed).profile.id, 'u1');
  });

  test('a verified student who has not finished setting up goes to set up first', () {
    final state = check(loaded: profile(complete: false));
    expect(state, isA<NeedsSetup>());
    expect((state as NeedsSetup).profile.id, 'u1');
  });

  test('a blocked account is blocked before setup is asked of it', () {
    expect(check(loaded: profile(status: AccountStatus.pending, complete: false)), isA<Blocked>());
    expect(check(loaded: profile(role: UserRole.admin, complete: false)), isA<Blocked>());
  });

  test('a pending or suspended student is blocked with the reason', () {
    expect((check(loaded: profile(status: AccountStatus.pending)) as Blocked).reason, BlockReason.pending);
    expect((check(loaded: profile(status: AccountStatus.suspended)) as Blocked).reason, BlockReason.suspended);
  });

  test('staff and administrators are turned away whatever their status', () {
    for (final role in [UserRole.staff, UserRole.admin]) {
      for (final status in AccountStatus.values) {
        expect((check(loaded: profile(role: role, status: status)) as Blocked).reason, BlockReason.notStudent);
      }
    }
  });
}
