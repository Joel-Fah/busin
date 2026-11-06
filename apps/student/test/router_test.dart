import 'package:busin_student/src/auth/access.dart';
import 'package:busin_student/src/router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  final allowed = Allowed(profile());

  group('redirectFor', () {
    test('signed-out people can only be on sign-in', () {
      expect(redirectFor(const SignedOut(), Routes.qr), Routes.signIn);
      expect(redirectFor(const SignedOut(), Routes.history), Routes.signIn);
      expect(redirectFor(const SignedOut(), Routes.signIn), isNull);
    });

    test('loading, failure and blocked each have only their own page', () {
      expect(redirectFor(const AccessLoading(), Routes.subscription), Routes.loading);
      expect(redirectFor(const AccessLoading(), Routes.loading), isNull);
      expect(redirectFor(const AccessLoadFailed(), Routes.qr), Routes.problem);
      expect(redirectFor(const Blocked(BlockReason.pending), Routes.bus), Routes.blocked);
      expect(redirectFor(const Blocked(BlockReason.pending), Routes.blocked), isNull);
    });

    test('allowed students leave the gate pages and stay where they are otherwise', () {
      for (final gate in [Routes.signIn, Routes.loading, Routes.blocked, Routes.problem, '/']) {
        expect(redirectFor(allowed, gate), Routes.start);
      }
      expect(redirectFor(allowed, Routes.start), isNull, reason: 'the landing page decides where to go next');
      expect(redirectFor(allowed, Routes.qr), isNull);
      expect(redirectFor(allowed, Routes.history), isNull);
    });

    test('a student who has not finished setting up sees only the setup page', () {
      final setup = NeedsSetup(profile(complete: false));
      expect(redirectFor(setup, Routes.qr), Routes.setup);
      expect(redirectFor(setup, Routes.profile), Routes.setup);
      expect(redirectFor(setup, Routes.setup), isNull);
      // Once done they leave it, and cannot return by Back.
      expect(redirectFor(allowed, Routes.setup), Routes.start);
    });

    test('while the logo is drawing, every page waits on the splash screen', () {
      for (final access in [const SignedOut(), const AccessLoading(), allowed, const Blocked(BlockReason.pending)]) {
        expect(redirectFor(access, Routes.qr, introDone: false), Routes.loading);
        expect(redirectFor(access, Routes.signIn, introDone: false), Routes.loading);
        expect(redirectFor(access, Routes.loading, introDone: false), isNull);
      }
      // Once it ends, the usual rules decide.
      expect(redirectFor(const SignedOut(), Routes.loading), Routes.signIn);
      expect(redirectFor(allowed, Routes.loading), Routes.start);
    });
  });
}
