import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:busin/models/actors/base_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/id_generator.dart';
import '../models/actors/roles.dart';


class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
      if (kDebugMode) {
        debugPrint(
          '[AuthService] signInWithGoogle Success: ${account.toString()}',
        );
      }
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
      if (kDebugMode) {
        debugPrint(
          '[AuthService] signInWithGoogle Success: ${account.toString()}',
        );
      }
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

  /// Fetch user data from Firestore by user ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final docSnap = await _db.collection('users').doc(userId).get();
      if (!docSnap.exists) {
        if (kDebugMode) {
          debugPrint('[AuthService] getUserById: User not found for ID: $userId');
        }
        return null;
      }
      return docSnap.data();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] getUserById error: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Create a new user document in Firestore with custom ID
  /// Format: STU-{EMAIL_PREFIX}-{HASH} or ADM-{EMAIL_PREFIX}-{HASH}
  Future<String> createUserDocument({
    required String email,
    required String name,
    required UserRole role,
    String? photoUrl,
    String? phone,
    String? matricule,
    String? department,
    String? program,
    String? address,
  }) async {
    try {
      // Generate custom ID based on role and email
      final customId = role == UserRole.admin
          ? IdGenerator.generateAdminId(email)
          : IdGenerator.generateStudentId(email);

      // Ensure uniqueness
      final userId = await IdGenerator.generateUniqueId(
        collection: 'users',
        baseId: customId,
      );

      final now = DateTime.now();
      final Map<String, dynamic> userData = {
        'id': userId,
        'email': email,
        'name': name,
        'role': role.name,
        'status': AccountStatus.verified.name,
        'photoUrl': photoUrl,
        'phone': phone,
        'createdAt': now.toIso8601String(),
        'lastSignInAt': now.toIso8601String(),
      };

      // Add role-specific fields
      if (role == UserRole.student) {
        userData.addAll({
          'matricule': matricule,
          'department': department,
          'program': program,
          'address': address,
          'subscriptionIds': <String>[],
          'currentSubscriptionId': null,
        });
      }

      await _db.collection('users').doc(userId).set(userData);

      if (kDebugMode) {
        debugPrint('[AuthService] Created user document: $userId');
      }

      return userId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] createUserDocument error: $e');
      }
      rethrow;
    }
  }

  /// Update existing user document or create if not exists
  Future<void> updateOrCreateUserDocument({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _db.collection('users').doc(userId).set(
        userData,
        SetOptions(merge: true),
      );

      if (kDebugMode) {
        debugPrint('[AuthService] Updated/created user document: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] updateOrCreateUserDocument error: $e');
      }
      rethrow;
    }
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
