import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import '../models/report.dart';
import '../services/report_service.dart';

/// GetX controller for the Report feature.
///
/// Students use this to submit reports and see their own history.
/// Admins use it to view all reports, see pending counts, and resolve them.
class ReportController extends GetxController {
  ReportController();

  final ReportService _service = ReportService.instance;

  // ── Reactive state ──
  final RxList<Report> reports = <Report>[].obs;
  final RxInt pendingCount = 0.obs;
  final RxBool isBusy = false.obs;
  final RxnString errorMessage = RxnString();

  // ── Subscriptions ──
  StreamSubscription<List<Report>>? _reportsSub;
  StreamSubscription<int>? _pendingCountSub;

  bool _isInitialized = false;

  @override
  void onClose() {
    _reportsSub?.cancel();
    _pendingCountSub?.cancel();
    super.onClose();
  }

  // ── Initialization ──

  /// Called from [AuthController] once user data is ready.
  void initialize({
    required String userId,
    required bool isStudent,
    required bool isAdmin,
    required bool isStaff,
  }) {
    if (_isInitialized) return;
    _isInitialized = true;

    if (isStudent) {
      _watchStudentReports(userId);
    } else if (isAdmin || isStaff) {
      _watchAllReports();
      _watchPendingCount();
    }

    if (kDebugMode) {
      debugPrint(
        '[ReportController] ✅ Initialized '
        '(student=$isStudent, admin=$isAdmin)',
      );
    }
  }

  void _watchStudentReports(String studentId) {
    _reportsSub?.cancel();
    _reportsSub = _service
        .streamStudentReports(studentId)
        .listen(
          (data) {
            reports.assignAll(data);
            // For students, pending = their own non-resolved reports
            pendingCount.value = data.where((r) => !r.status.isResolved).length;
          },
          onError: (Object err) {
            errorMessage.value = err.toString();
            if (kDebugMode) {
              debugPrint('[ReportController] ❌ Stream error: $err');
            }
          },
        );
  }

  void _watchAllReports() {
    _reportsSub?.cancel();
    _reportsSub = _service.streamAllReports().listen(
      (data) => reports.assignAll(data),
      onError: (Object err) {
        errorMessage.value = err.toString();
        if (kDebugMode) {
          debugPrint('[ReportController] ❌ Stream error: $err');
        }
      },
    );
  }

  void _watchPendingCount() {
    _pendingCountSub?.cancel();
    _pendingCountSub = _service.streamPendingCount().listen(
      (count) => pendingCount.value = count,
      onError: (Object err) {
        if (kDebugMode) {
          debugPrint('[ReportController] ❌ Pending-count stream error: $err');
        }
      },
    );
  }

  // ── Student actions ──

  /// Submit a new report.
  Future<void> submitReport({
    required String studentId,
    required String studentName,
    String? studentPhotoUrl,
    required ReportSubject subject,
    String? customSubject,
    required String description,
  }) async {
    if (description.trim().isEmpty) return;

    isBusy.value = true;
    errorMessage.value = null;

    try {
      await _service.createReport(
        studentId: studentId,
        studentName: studentName,
        studentPhotoUrl: studentPhotoUrl,
        subject: subject,
        customSubject: customSubject,
        description: description,
      );

      if (kDebugMode) {
        debugPrint('[ReportController] ✅ Report submitted');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      if (kDebugMode) {
        debugPrint('[ReportController] ❌ Submit error: $e');
      }
    } finally {
      isBusy.value = false;
    }
  }

  // ── Admin actions ──

  /// Mark a report as in-review.
  Future<void> markInReview(String reportId) async {
    try {
      await _service.markInReview(reportId);
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  /// Resolve a report.
  Future<void> resolveReport({
    required String reportId,
    required String adminId,
    required String adminName,
    String? response,
  }) async {
    try {
      await _service.resolveReport(
        reportId: reportId,
        adminId: adminId,
        adminName: adminName,
        response: response,
      );
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  /// Change priority.
  Future<void> updatePriority(String reportId, ReportPriority priority) async {
    try {
      await _service.updatePriority(reportId, priority);
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  /// Delete a report.
  Future<void> deleteReport(String reportId) async {
    try {
      await _service.deleteReport(reportId);
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  // ── Computed getters ──

  /// Reports grouped by subject for admin overview.
  Map<ReportSubject, List<Report>> get reportsBySubject {
    final map = <ReportSubject, List<Report>>{};
    for (final r in reports) {
      map.putIfAbsent(r.subject, () => []).add(r);
    }
    return map;
  }

  /// Only pending/in-review reports.
  List<Report> get activeReports =>
      reports.where((r) => !r.status.isResolved).toList();

  /// Only resolved reports.
  List<Report> get resolvedReports =>
      reports.where((r) => r.status.isResolved).toList();

  /// Reset the controller state (e.g. on sign out)
  void reset() {
    _reportsSub?.cancel();
    _pendingCountSub?.cancel();
    _isInitialized = false;
    reports.clear();
    pendingCount.value = 0;
    errorMessage.value = null;
    if (kDebugMode) {
      debugPrint('[ReportController] ✅ Reset complete');
    }
  }
}
