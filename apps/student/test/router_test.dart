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
        expect(redirectFor(allowed, gate), Routes.subscription);
      }
      expect(redirectFor(allowed, Routes.qr), isNull);
      expect(redirectFor(allowed, Routes.history), isNull);
    });
  });
}
