import 'dart:async';

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'package:busin/models/actors/base_user.dart';
import 'package:busin/models/actors/roles.dart';
import 'package:busin/models/actors/student.dart';
import 'package:busin/models/actors/staff.dart';
import 'package:busin/models/actors/admin.dart';
import 'package:busin/services/auth_service.dart';

/// Firestore collection names
const String kUsersCollection = 'users';

/// Keys inside a user document
const String kRoleField = 'role';

class AuthController extends GetxController {
  final _auth = AuthService.instance;
  final _db = FirebaseFirestore.instance;

  final Rxn<BaseUser> currentUser = Rxn<BaseUser>();
  final RxBool isLoading = false.obs;
  final RxString? errorMessage = RxString('');

  // Bootstrapping gate: true once we handled the first auth state and doc load
  final RxBool _bootstrapped = false.obs;
  bool get isBootstrapped => _bootstrapped.value;
  Stream<bool> get bootstrappedStream => _bootstrapped.stream;

  // Pending onboarding choice (applied only on first user creation)
  UserRole? _pendingInitialRole;
  AccountStatus? _pendingInitialStatus;

  StreamSubscription<fb_auth.User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  @override
  void onInit() {
    super.onInit();
    // Listen to Firebase auth state and sync with Firestore + local model
    _authSub =
        _auth.authStateChanges().listen(_onAuthStateChanged, onError: (e, st) {
          errorMessage?.value = e.toString();
        });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.onClose();
  }

  // --- Public Methods ---

  /// Set the initial role/status to be used when creating the user document
  /// for the first time (on first login). Ignored if the user document exists.
  void setFirstLoginProfile(UserRole role, AccountStatus status) {
    _pendingInitialRole = role;
    _pendingInitialStatus = status;
  }

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    errorMessage?.value = '';
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      errorMessage?.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    isLoading.value = true;
    errorMessage?.value = '';
    try {
      await _auth.signOut();
    } catch (e) {
      errorMessage?.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  bool get isAuthenticated => currentUser.value != null;
  bool get isStudent => currentUser.value?.role == UserRole.student;
  bool get isStaff => currentUser.value?.role == UserRole.staff;
  bool get isAdmin => currentUser.value?.role == UserRole.admin;
  String get userDisplayName => currentUser.value?.name ?? '';
  String get userEmail => currentUser.value?.email ?? '';
  String get userProfileImage => currentUser.value?.photoUrl ?? '';
  bool get isVerified => currentUser.value?.isVerified ?? false;

  // --- Internals ---

  Future<void> _onAuthStateChanged(fb_auth.User? fbUser) async {
    _bootstrapped.value = false;
    _userDocSub?.cancel();

    if (fbUser == null) {
      currentUser.value = null;
      _bootstrapped.value = true; // done bootstrapping for signed-out state
      return;
    }

    // Enforce Google-only + org domain
    BaseUser.assertGoogleOrgOrThrow(fbUser);

    final docRef = _db.collection(kUsersCollection).doc(fbUser.uid);

    // Create the user doc if not present
    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      final roleToUse = _pendingInitialRole ?? UserRole.student;
      final statusToUse = _pendingInitialStatus ?? AccountStatus.verified;

      BaseUser newUser;
      switch (roleToUse) {
        case UserRole.student:
          newUser = Student.fromFirebaseUser(
            fbUser,
            status: statusToUse,
          );
          break;
        case UserRole.staff:
          newUser = Staff.fromFirebaseUser(
            fbUser,
            status: statusToUse,
          );
          break;
        case UserRole.admin:
          newUser = Admin.fromFirebaseUser(
            fbUser,
            status: statusToUse,
          );
          break;
      }

      // Persist new user
      Map<String, dynamic> initialMap;
      if (newUser is Student) {
        initialMap = newUser.toMap();
      } else if (newUser is Staff) {
        initialMap = newUser.toMap();
      } else {
        initialMap = (newUser as Admin).toMap();
      }
      await docRef.set(initialMap);

      // Set current user immediately (without waiting for snapshot)
      currentUser.value = _mapDocToUser(roleToUse, initialMap);

      // Clear pending onboarding choice after first use
      _pendingInitialRole = null;
      _pendingInitialStatus = null;

      // Subscribe for future updates
      _userDocSub = docRef.snapshots().listen(_onUserDoc, onError: (e, st) {
        errorMessage?.value = e.toString();
      });

      await Future.delayed(const Duration(milliseconds: 100));
      _bootstrapped.value = true;
      return;
    }

    // Doc exists: set current user immediately from the snapshot data
    final data = docSnap.data()!;
    final role = UserRole.from((data[kRoleField] as String?) ?? 'student');
    currentUser.value = _mapDocToUser(role, data);

    // Subscribe to live updates
    _userDocSub = docRef.snapshots().listen(_onUserDoc, onError: (e, st) {
      errorMessage?.value = e.toString();
    });

    await Future.delayed(const Duration(milliseconds: 100));
    _bootstrapped.value = true;
  }

  void _onUserDoc(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      currentUser.value = null;
      return;
    }
    final role = UserRole.from((data[kRoleField] as String?) ?? 'student');
    currentUser.value = _mapDocToUser(role, data);
  }

  BaseUser _mapDocToUser(UserRole role, Map<String, dynamic> data) {
    switch (role) {
      case UserRole.student:
        return Student.fromMap(data);
      case UserRole.staff:
        return Staff.fromMap(data);
      case UserRole.admin:
        return Admin.fromMap(data);
    }
  }

  // --- Utility methods over the user doc ---

  /// Get user info from Firestore by user ID
  /// Returns a properly typed BaseUser (Student, Staff, or Admin)
  Future<BaseUser?> getUserById(String userId) async {
    try {
      final data = await _auth.getUserById(userId);
      if (data == null) return null;

      final role = UserRole.from((data[kRoleField] as String?) ?? 'student');
      return _mapDocToUser(role, data);
    } catch (e) {
      errorMessage?.value = e.toString();
      return null;
    }
  }

  Future<void> updateDisplayName(String name) async {
    final user = currentUser.value;
    if (user == null) return;
    await _db.collection(kUsersCollection).doc(user.id).update({'name': name});
  }

  Future<void> updatePhone(String phone) async {
    final user = currentUser.value;
    if (user == null) return;
    await _db.collection(kUsersCollection).doc(user.id).update({'phone': phone});
  }

  Future<void> setRole(UserRole role) async {
    final user = currentUser.value;
    if (user == null) return;
    await _db.collection(kUsersCollection).doc(user.id).update({'role': role.name});
  }

  Future<void> setStatus(AccountStatus status) async {
    final user = currentUser.value;
    if (user == null) return;
    await _db.collection(kUsersCollection).doc(user.id).update({'status': status.name});
  }
}
