/// Why a sign-in did not complete. The screen turns each into a plain message.
enum SignInFailure {
  /// The person closed the Google sheet.
  cancelled,

  /// Google accepted the account but the school does not: its email domain is not on the allow-list.
  notAllowed,

  /// Anything else, including no network.
  failed,
}

class SignInException implements Exception {
  const SignInException(this.reason);

  final SignInFailure reason;

  @override
  String toString() => 'SignInException($reason)';
}

/// Who is signed in, and how to sign in and out. The app talks to this, never to Supabase or Google
/// directly, so screens and routing are tested with a fake.
abstract interface class AuthService {
  /// The signed-in user's id, or null.
  String? get currentUserId;

  /// The signed-in user's id now and every time it changes; null when signed out.
  Stream<String?> get userIdChanges;

  /// Throws [SignInException].
  Future<void> signInWithGoogle();

  Future<void> signOut();
}
