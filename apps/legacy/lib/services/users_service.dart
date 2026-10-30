import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/actors/base_user.dart';
import '../models/actors/student.dart';
import '../models/actors/staff.dart';
import '../models/actors/admin.dart';
import '../models/actors/roles.dart';
import 'scanning_service.dart';

class UsersService {
  UsersService._();

  static final UsersService instance = UsersService._();

  final _collection = FirebaseFirestore.instance.collection('users');
  final _subscriptionsCollection = FirebaseFirestore.instance.collection('subscriptions');

  /// Stream all users by role
  Stream<List<BaseUser>> streamUsersByRole(UserRole role) {
    return _collection
        .where('role', isEqualTo: role.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return _mapDocToUser(role, data);
      }).toList();
    });
  }

  /// Stream all staff (both staff and admin roles)
  Stream<List<BaseUser>> streamAllStaff() {
    return _collection
        .where('role', whereIn: [UserRole.staff.name, UserRole.admin.name])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        final roleStr = data['role'] as String;
        final role = UserRole.values.firstWhere(
          (r) => r.name == roleStr,
          orElse: () => UserRole.staff,
        );
        return _mapDocToUser(role, data);
      }).toList();
    });
  }

  /// Fetch all users by role (one-time)
  Future<List<BaseUser>> fetchUsersByRole(UserRole role) async {
    try {
      final snapshot = await _collection
          .where('role', isEqualTo: role.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return _mapDocToUser(role, data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UsersService] fetchUsersByRole error: $e');
      }
      rethrow;
    }
  }

  /// Fetch all staff (both staff and admin roles) - one-time
  Future<List<BaseUser>> fetchAllStaff() async {
    try {
      final snapshot = await _collection
          .where('role', whereIn: [UserRole.staff.name, UserRole.admin.name])
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        final roleStr = data['role'] as String;
        final role = UserRole.values.firstWhere(
          (r) => r.name == roleStr,
          orElse: () => UserRole.staff,
        );
        return _mapDocToUser(role, data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UsersService] fetchAllStaff error: $e');
      }
      rethrow;
    }
  }

  /// Get user subscription count
  Future<int> getUserSubscriptionCount(String userId) async {
    try {
      final snapshot = await _subscriptionsCollection
          .where('studentId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UsersService] getUserSubscriptionCount error: $e');
      }
      return 0;
    }
  }

  /// Get user scan count
  Future<int> getUserScanCount(String userId) async {
    try {
      return await ScanningService.instance.getStudentScanCount(userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UsersService] getUserScanCount error: $e');
      }
      return 0;
    }
  }

  /// Get staff scan count (number of scans performed by this staff member)
  Future<int> getStaffScanCount(String staffId) async {
    try {
      return await ScanningService.instance.getStaffScanCount(staffId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UsersService] getStaffScanCount error: $e');
      }
      return 0;
    }
  }

  /// Map Firestore document to proper user type
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

  /// Update user status
  Future<void> updateUserStatus(String userId, AccountStatus status) async {
    try {
      await _collection.doc(userId).update({'status': status.name});
      if (kDebugMode) {
        debugPrint('[UsersService] Updated user $userId status to ${status.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UsersService] updateUserStatus error: $e');
      }
      rethrow;
    }
  }

  /// Update user role (promote/demote staff <-> admin)
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      await _collection.doc(userId).update({
        'role': newRole.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        debugPrint('[UsersService] Updated user $userId role to ${newRole.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UsersService] updateUserRole error: $e');
      }
      rethrow;
    }
  }

  /// Delete user (soft delete by updating status)
  Future<void> deleteUser(String userId) async {
    try {
      await updateUserStatus(userId, AccountStatus.suspended);
      if (kDebugMode) {
        debugPrint('[UsersService] Deleted (suspended) user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UsersService] deleteUser error: $e');
      }
      rethrow;
    }
  }
}

