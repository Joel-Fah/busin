import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// Google sign-in on the device, then `signInWithIdToken` so Supabase verifies the token itself.
/// The server decides who may have an account (the sign-up trigger checks the school's email domains);
/// the app only reports what happened.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client, {required String googleServerClientId}) : _serverClientId = googleServerClientId;

  final SupabaseClient _client;
  final String _serverClientId;
  Future<void>? _googleReady;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Stream<String?> get userIdChanges async* {
    yield currentUserId;
    yield* _client.auth.onAuthStateChange.map((state) => state.session?.user.id).distinct();
  }

  Future<void> _initGoogle() => _googleReady ??= GoogleSignIn.instance.initialize(serverClientId: _serverClientId);

  @override
  Future<void> signInWithGoogle() async {
    final String idToken;
    try {
      await _initGoogle();
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null) throw const SignInException(SignInFailure.failed);
      idToken = token;
    } on GoogleSignInException catch (e) {
      throw SignInException(e.code == GoogleSignInExceptionCode.canceled ? SignInFailure.cancelled : SignInFailure.failed);
    }

    try {
      await _client.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);
    } on AuthRetryableFetchException {
      throw const SignInException(SignInFailure.failed);
    } on AuthException {
      // The network worked and the server said no: the account is not allowed.
      throw const SignInException(SignInFailure.notAllowed);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _initGoogle();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Leaving Google's own session is a courtesy; BusIn's session is what matters.
    }
    await _client.auth.signOut();
  }
}
