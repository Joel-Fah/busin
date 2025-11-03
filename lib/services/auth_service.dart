import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:busin/models/actors/base_user.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  // Use the singleton GoogleSignIn instance
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Initialize GoogleSignIn — must call this before sign-in attempts.
  Future<void> initializeGoogleSignIn() async {
    await _googleSignIn.initialize();
  }

  Stream<fb_auth.User?> authStateChanges() => _auth.authStateChanges();

  fb_auth.User? get currentUser => _auth.currentUser;

  /// Attempt lightweight (silent) auth first, then fallback to interactive.
  Future<fb_auth.UserCredential> signInWithGoogle() async {
    await initializeGoogleSignIn();

    GoogleSignInAccount? account;

    // Try lightweight/ silent sign-in first
    try {
      account = await _googleSignIn.attemptLightweightAuthentication();
    } catch (e) {
      account = null;
      if (kDebugMode) {
        debugPrint(
          '[AuthService] signInWithGoogle: Lightweight auth failed: ${e.toString()}',
        );
      }
    }

    // If lightweight failed or returned null, use full interactive sign-in
    if (account == null) {
      account = await _googleSignIn.authenticate();
    }

    final GoogleSignInAuthentication gAuth = await account.authentication;
    final String? idToken = gAuth.idToken;
    final String? accessToken = gAuth.idToken;

    if (idToken == null) {
      if (kDebugMode) {
        debugPrint(
          '[AuthService] signInWithGoogle: Failed to obtain Google ID token.',
        );
      }
      throw StateError('Failed to obtain Google ID token.');
    }

    final fb_auth.OAuthCredential credential =
        fb_auth.GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: accessToken,
        );

    final fb_auth.UserCredential userCred = await _auth.signInWithCredential(
      credential,
    );

    final fb_auth.User? user = userCred.user;
    if (user == null) {
      await _cleanupOnFailure();
      if (kDebugMode) {
        debugPrint(
          '[AuthService] signInWithGoogle: No user info returned after sign-in.',
        );
      }
      throw StateError('Google sign-in failed: no user info returned.');
    }

    try {
      BaseUser.assertGoogleOrgOrThrow(user);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AuthService] signInWithGoogle: Auth assertion failed: ${e.toString()}',
        );
      }
      await _cleanupOnFailure();
      rethrow;
    }

    return userCred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AuthService] signOut: Google signOut error: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _cleanupOnFailure() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AuthService] Cleanup: Google signOut error: ${e.toString()}',
        );
      }
    }
  }
}
