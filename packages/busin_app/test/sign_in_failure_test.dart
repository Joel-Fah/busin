import 'package:busin_app/busin_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('an account no school allows is "not allowed", though Supabase reports it as a server error', () {
    final refused = AuthRetryableFetchException(message: '{"code":"unexpected_failure","message":"Database error saving new user"}', statusCode: '500');
    expect(signInFailureFor(refused), SignInFailure.notAllowed);
  });

  test('a server out of reach is a failure to try again', () {
    expect(signInFailureFor(AuthRetryableFetchException(message: 'Connection refused')), SignInFailure.failed);
  });

  test('any other refusal from the server is "not allowed"', () {
    expect(signInFailureFor(const AuthException('Invalid token', statusCode: '400')), SignInFailure.notAllowed);
  });
}
