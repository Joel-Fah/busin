import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/actors/student.dart';
import '../models/subscription.dart';

class ScanResult {
  final bool isValid;
  final bool hasActiveSubscription;
  final Student? student;
  final BusSubscription? subscription;
  final String? errorMessage;

  ScanResult({
    required this.isValid,
    required this.hasActiveSubscription,
    this.student,
    this.subscription,
    this.errorMessage,
  });

  factory ScanResult.invalid(String message) {
    return ScanResult(
      isValid: false,
      hasActiveSubscription: false,
      errorMessage: message,
    );
  }

  factory ScanResult.valid({
    required Student student,
    required bool hasActiveSubscription,
    BusSubscription? subscription,
  }) {
    return ScanResult(
      isValid: true,
      hasActiveSubscription: hasActiveSubscription,
      student: student,
      subscription: subscription,
    );
  }
}

class ScannerService {
  ScannerService._();

  static final ScannerService instance = ScannerService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Verify student and check for active subscription
  Future<ScanResult> verifyStudentQRCode(String studentId) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[ScannerService] Starting verification for student ID: $studentId',
        );
      }

      if (studentId.isEmpty) {
        if (kDebugMode) {
          debugPrint('[ScannerService] Empty student ID');
        }
        return ScanResult.invalid('Invalid QR code: Empty student ID');
      }

      // Fetch student data
      final studentDoc = await _db.collection('users').doc(studentId).get();

      if (kDebugMode) {
        debugPrint('[ScannerService] Student doc exists: ${studentDoc.exists}');
      }

      if (!studentDoc.exists) {
        return ScanResult.invalid('Student not found');
      }

      final studentData = studentDoc.data();
      if (studentData == null) {
        if (kDebugMode) {
          debugPrint('[ScannerService] Student data is null');
        }
        return ScanResult.invalid('Invalid student data');
      }

      // Verify it's a student
      final role = studentData['role'] as String?;
      if (kDebugMode) {
        debugPrint('[ScannerService] User role: $role');
      }

      if (role != 'student') {
        return ScanResult.invalid('User is not a student');
      }

      // Parse student
      studentData['id'] = studentDoc.id;
      final student = Student.fromMap(studentData);

      if (kDebugMode) {
        debugPrint(
          '[ScannerService] Student parsed successfully: ${student.id}',
        );
      }

      // Check for active subscription
      final now = DateTime.now();
      final subscriptionsSnapshot = await _db
          .collection('subscriptions')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'approved')
          .get();

      if (kDebugMode) {
        debugPrint(
          '[ScannerService] Found ${subscriptionsSnapshot.docs.length} approved subscriptions',
        );
      }

      BusSubscription? activeSubscription;
      bool hasActive = false;

      for (var doc in subscriptionsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final subscription = BusSubscription.fromMap(data);

        if (kDebugMode) {
          debugPrint(
            '[ScannerService] Checking subscription ${subscription.id}:',
          );
          debugPrint('  - Status: ${subscription.status}');
          debugPrint('  - Start: ${subscription.startDate}');
          debugPrint('  - End: ${subscription.endDate}');
          debugPrint('  - Now: $now');
        }

        // Check if subscription is within valid date range
        if (subscription.status.isApproved) {
          // Check if current date is within semester dates
          final startDate = subscription.startDate;
          final endDate = subscription.endDate;

          final isAfterStart =
              now.isAfter(startDate) || now.isAtSameMomentAs(startDate);
          final isBeforeEnd =
              now.isBefore(endDate) || now.isAtSameMomentAs(endDate);

          if (kDebugMode) {
            debugPrint('  - Is after start: $isAfterStart');
            debugPrint('  - Is before end: $isBeforeEnd');
          }

          if (isAfterStart && isBeforeEnd) {
            hasActive = true;
            activeSubscription = subscription;
            if (kDebugMode) {
              debugPrint('[ScannerService] Active subscription found!');
            }
            break;
          }
        }
      }

      if (kDebugMode) {
        debugPrint('[ScannerService] Final result - Has active: $hasActive');
      }

      return ScanResult.valid(
        student: student,
        hasActiveSubscription: hasActive,
        subscription: activeSubscription,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScannerService] verifyStudentQRCode error: $e');
      }
      return ScanResult.invalid('Error verifying student: ${e.toString()}');
    }
  }
}
