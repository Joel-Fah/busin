import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:busin/models/actors/base_user.dart';

/// Lightweight authentication service wrapping firebase_auth.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  /// Firebase user stream (null when signed out).
  Stream<fb_auth.User?> authStateChanges() => _auth.authStateChanges();

  fb_auth.User? get currentUser => _auth.currentUser;

  /// Ensures account is from the allowed org domain and Google provider.
  Future<fb_auth.UserCredential> signInWithGoogle() async {
    final provider = fb_auth.GoogleAuthProvider();
    // Request basic scopes; keep minimal for school project.
    provider.setCustomParameters({
      'prompt': 'select_account',
    });

    final cred = await _auth.signInWithProvider(provider);
    final user = cred.user;

    if (user == null) {
      throw StateError('Google sign-in failed: no user info returned.');
    }

    // Enforce Google-only + org domain.
    try {
      BaseUser.assertGoogleOrgOrThrow(user);
    } catch (e) {
      // Cleanly sign out if constraints fail.
      await _auth.signOut();
      rethrow;
    }

    return cred;
  }

  /// Signs the current user out of Firebase.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

