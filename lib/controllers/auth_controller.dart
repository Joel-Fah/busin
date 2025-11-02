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

  StreamSubscription<fb_auth.User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  @override
  void onInit() {
    super.onInit();
    // Listen to Firebase auth state and sync with Firestore + local model
    _authSub = _auth.authStateChanges().listen(_onAuthStateChanged, onError: (e, st) {
      errorMessage?.value = e.toString();
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.onClose();
  }

  // --- Public API ---

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

  // --- Internals ---

  Future<void> _onAuthStateChanged(fb_auth.User? fbUser) async {
    _userDocSub?.cancel();

    if (fbUser == null) {
      currentUser.value = null;
      return;
    }

    // Enforce Google-only + org domain
    BaseUser.assertGoogleOrgOrThrow(fbUser);

    final docRef = _db.collection(kUsersCollection).doc(fbUser.uid);

    // Create the user doc if not present
    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      // Default all new logins to Student; you can elevate via admin later.
      final student = Student.fromFirebaseUser(
        fbUser,
        status: AccountStatus.verified,
      );
      await docRef.set(student.toMap());
    }

    // Subscribe to live updates for that user doc to keep state reactive
    _userDocSub = docRef.snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        currentUser.value = null;
        return;
      }
      final role = UserRole.from((data[kRoleField] as String?) ?? 'student');
      currentUser.value = _mapDocToUser(role, data);
    }, onError: (e, st) {
      errorMessage?.value = e.toString();
    });
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

