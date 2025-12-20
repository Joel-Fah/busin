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
      if (studentId.isEmpty) {
        return ScanResult.invalid('Invalid QR code: Empty student ID');
      }

      // Fetch student data
      final studentDoc = await _db.collection('users').doc(studentId).get();

      if (!studentDoc.exists) {
        return ScanResult.invalid('Student not found');
      }

      final studentData = studentDoc.data();
      if (studentData == null) {
        return ScanResult.invalid('Invalid student data');
      }

      // Verify it's a student
      final role = studentData['role'] as String?;
      if (role != 'student') {
        return ScanResult.invalid('User is not a student');
      }

      // Parse student
      studentData['id'] = studentDoc.id;
      final student = Student.fromMap(studentData);

      // Check for active subscription
      final now = DateTime.now();
      final subscriptionsSnapshot = await _db
          .collection('subscriptions')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'approved')
          .get();

      BusSubscription? activeSubscription;
      bool hasActive = false;

      for (var doc in subscriptionsSnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final subscription = BusSubscription.fromMap(data);

        // Check if subscription is within valid date range
        if (subscription.status.isApproved) {
          // Check if current date is within semester dates
          final startDate = subscription.startDate;
          final endDate = subscription.endDate;

          if (now.isAfter(startDate) && now.isBefore(endDate)) {
            hasActive = true;
            activeSubscription = subscription;
            break;
          }
        }
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

