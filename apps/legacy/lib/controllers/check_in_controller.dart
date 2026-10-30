import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import '../models/check_in.dart';
import '../services/check_in_service.dart';

/// GetX controller for the daily Check-In (attendance) feature.
///
/// Used by admin/staff to view today's live check-in list, add entries
/// when scanning, and browse historical check-in data with trends.
class CheckInController extends GetxController {
  CheckInController();

  final CheckInService _service = CheckInService.instance;

  // ── Reactive state ──

  /// Today's check-in list (null until the first entry is created).
  final Rxn<CheckInList> todayCheckIns = Rxn<CheckInList>();

  /// Historical check-in lists for the trends page.
  final RxList<CheckInList> history = <CheckInList>[].obs;

  final RxBool isBusy = false.obs;
  final RxnString errorMessage = RxnString();

  // ── Subscriptions ──
  StreamSubscription<CheckInList?>? _todaySub;
  StreamSubscription<List<CheckInList>>? _historySub;

  bool _isInitialized = false;

  @override
  void onClose() {
    _todaySub?.cancel();
    _historySub?.cancel();
    super.onClose();
  }

  // ── Initialization ──

  /// Called from [AuthController] when an admin/staff user is ready.
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    _watchToday();
    _watchHistory();

    if (kDebugMode) {
      debugPrint('[CheckInController] ✅ Initialized');
    }
  }

  void _watchToday() {
    _todaySub?.cancel();
    _todaySub = _service.streamTodayCheckIns().listen(
      (data) => todayCheckIns.value = data,
      onError: (Object err) {
        errorMessage.value = err.toString();
        if (kDebugMode) {
          debugPrint('[CheckInController] ❌ Today stream error: $err');
        }
      },
    );
  }

  void _watchHistory() {
    _historySub?.cancel();
    _historySub = _service
        .streamCheckInHistory(limit: 30)
        .listen(
          (data) => history.assignAll(data),
          onError: (Object err) {
            if (kDebugMode) {
              debugPrint('[CheckInController] ❌ History stream error: $err');
            }
          },
        );
  }

  // ── Actions ──

  /// Add a student entry to today's check-in list.
  Future<CheckInEntry?> addEntry({
    required String studentId,
    required String studentName,
    String? studentPhotoUrl,
    required String subscriptionId,
    required String scannedBy,
    required String scannedByName,
    required CheckInPeriod period,
    String? notes,
  }) async {
    isBusy.value = true;
    errorMessage.value = null;

    try {
      final entry = await _service.addEntry(
        studentId: studentId,
        studentName: studentName,
        studentPhotoUrl: studentPhotoUrl,
        subscriptionId: subscriptionId,
        scannedBy: scannedBy,
        scannedByName: scannedByName,
        period: period,
        notes: notes,
      );

      if (kDebugMode) {
        debugPrint(
          '[CheckInController] ✅ Added $studentName (order #${entry.arrivalOrder})',
        );
      }
      return entry;
    } catch (e) {
      errorMessage.value = e.toString();
      if (kDebugMode) {
        debugPrint('[CheckInController] ❌ Add entry error: $e');
      }
      return null;
    } finally {
      isBusy.value = false;
    }
  }

  /// Remove an entry from today's list.
  Future<void> removeEntry(String entryId) async {
    try {
      await _service.removeEntry(entryId);
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  // ── Computed helpers ──

  /// Today's entries sorted by arrival order.
  List<CheckInEntry> get todayEntries {
    final list = todayCheckIns.value;
    if (list == null) return [];
    final sorted = List<CheckInEntry>.from(list.entries)
      ..sort((a, b) => a.arrivalOrder.compareTo(b.arrivalOrder));
    return sorted;
  }

  /// Today's entries for a specific period.
  List<CheckInEntry> todayEntriesForPeriod(CheckInPeriod period) =>
      todayEntries.where((e) => e.period == period).toList();

  /// Check if a student is already checked in for the given period today.
  bool isStudentCheckedInToday(String studentId, CheckInPeriod period) {
    final list = todayCheckIns.value;
    if (list == null) return false;
    return list.isStudentCheckedIn(studentId, period);
  }

  /// Determine the current period based on time of day.
  /// Before 14:00 → morning, after → evening.
  CheckInPeriod get currentPeriod {
    final hour = DateTime.now().hour;
    return hour < 14 ? CheckInPeriod.morning : CheckInPeriod.evening;
  }

  /// Total unique students checked in today.
  int get todayTotalStudents => todayCheckIns.value?.totalStudents ?? 0;

  /// Reset the controller state (e.g. on sign out)
  void reset() {
    _todaySub?.cancel();
    _historySub?.cancel();
    _isInitialized = false;
    todayCheckIns.value = null;
    history.clear();
    errorMessage.value = null;
    if (kDebugMode) {
      debugPrint('[CheckInController] ✅ Reset complete');
    }
  }
}
