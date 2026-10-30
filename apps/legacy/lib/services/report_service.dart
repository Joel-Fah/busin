import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/report.dart';

/// Firestore service for student reports / complaints.
class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  final _collection = FirebaseFirestore.instance.collection('reports');

  // ── Create ──

  /// Submit a new report.
  Future<Report> createReport({
    required String studentId,
    required String studentName,
    String? studentPhotoUrl,
    required ReportSubject subject,
    String? customSubject,
    required String description,
  }) async {
    final now = DateTime.now();
    final reportId = _generateReportId(now);
    final docRef = _collection.doc(reportId);

    final report = Report(
      id: docRef.id,
      studentId: studentId,
      studentName: studentName,
      studentPhotoUrl: studentPhotoUrl,
      subject: subject,
      customSubject: customSubject,
      priority: subject.defaultPriority,
      description: description,
      status: ReportStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(report.toMap());

    if (kDebugMode) {
      debugPrint('[ReportService] ✅ Report created: ${report.id}');
    }

    return report;
  }

  // ── Read — streams ──

  /// Stream all reports for a specific student, newest first.
  Stream<List<Report>> streamStudentReports(String studentId) {
    return _collection.where('studentId', isEqualTo: studentId).snapshots().map(
      (snap) {
        final list = snap.docs.map((d) => Report.fromMap(d.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      },
    );
  }

  /// Stream ALL reports (for admin view), newest first.
  Stream<List<Report>> streamAllReports() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Report.fromMap(d.data())).toList());
  }

  /// Stream only pending / in-review reports (admin badge count).
  Stream<int> streamPendingCount() {
    return _collection
        .where(
          'status',
          whereIn: [ReportStatus.pending.value, ReportStatus.inReview.value],
        )
        .snapshots()
        .map((snap) => snap.size);
  }

  // ── Update ──

  /// Admin marks a report as in-review.
  Future<void> markInReview(String reportId) async {
    await _collection.doc(reportId).update({
      'status': ReportStatus.inReview.value,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    if (kDebugMode) {
      debugPrint('[ReportService] ✅ Report $reportId → in_review');
    }
  }

  /// Admin resolves a report with an optional response message.
  Future<void> resolveReport({
    required String reportId,
    required String adminId,
    required String adminName,
    String? response,
  }) async {
    final now = DateTime.now();
    await _collection.doc(reportId).update({
      'status': ReportStatus.resolved.value,
      'adminResponse': response,
      'resolvedByAdminId': adminId,
      'resolvedByAdminName': adminName,
      'resolvedAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    if (kDebugMode) {
      debugPrint('[ReportService] ✅ Report $reportId → resolved');
    }
  }

  /// Admin can change priority.
  Future<void> updatePriority(String reportId, ReportPriority priority) async {
    await _collection.doc(reportId).update({
      'priority': priority.value,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ── Delete ──

  Future<void> deleteReport(String reportId) async {
    await _collection.doc(reportId).delete();

    if (kDebugMode) {
      debugPrint('[ReportService] ✅ Report $reportId deleted');
    }
  }

  // ── Helpers ──

  /// Generate a human-readable report ID.
  /// Format: `RPT-YYYYMMDD-XXXX` where XXXX is a random alphanumeric suffix.
  String _generateReportId(DateTime now) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final suffix = List.generate(
      4,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
    final date =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    return 'RPT-$date-$suffix';
  }
}
