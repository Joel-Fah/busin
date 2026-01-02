import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/scannings.dart';
import '../services/scanning_service.dart';
import 'auth_controller.dart';

class ScanningController extends GetxController {
  ScanningController();

  final ScanningService _service = ScanningService.instance;
  final AuthController _authController = Get.find<AuthController>();
  final GetStorage _storage = GetStorage();

  final RxList<Scanning> _scannings = <Scanning>[].obs;
  final Rxn<Scanning> lastScan = Rxn<Scanning>();
  final RxBool isBusy = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool hasLocationPermission = false.obs;

  // Storage key for screenshot warning
  static const String _screenshotWarningShownKey = 'screenshot_warning_shown';

  List<Scanning> get scannings => _scannings;

  String get currentUserId => _authController.userId;

  StreamSubscription<List<Scanning>>? _watcher;

  @override
  void onInit() {
    super.onInit();
    _checkLocationPermission();
    _initializeWatching();
  }

  @override
  void onClose() {
    _watcher?.cancel();
    super.onClose();
  }

  /// Check location permission status
  Future<void> _checkLocationPermission() async {
    final hasPermission = await _service.requestLocationPermission();
    hasLocationPermission.value = hasPermission;
    if (kDebugMode) {
      debugPrint('[ScanningController] Location permission: $hasPermission');
    }
  }

  /// Initialize watching based on user role
  void _initializeWatching() {
    if (_authController.isStudent) {
      // Students see only their own scans
      final studentId = _authController.userId;
      if (studentId.isEmpty) {
        if (kDebugMode) {
          debugPrint('[ScanningController] Warning: Student ID is empty');
        }
        return;
      }
      startWatchingStudent(studentId);
      _loadLastScan(studentId);
    } else if (_authController.isAdmin || _authController.isStaff) {
      // Admins and staff can see all scans
      startWatchingAll();
    }
  }

  /// Start watching scans for a specific student
  void startWatchingStudent(String studentId) {
    _watcher?.cancel();
    _watcher = _service
        .streamStudentScannings(studentId)
        .listen(
          (data) {
            _scannings.assignAll(data);
            if (kDebugMode) {
              debugPrint(
                '[ScanningController] Loaded ${data.length} scans for student $studentId',
              );
            }
          },
          onError: (Object err) {
            errorMessage.value = err.toString();
            if (kDebugMode) {
              debugPrint('[ScanningController] Error watching scans: $err');
            }
          },
        );
  }

  /// Start watching all scans (admin/staff only)
  void startWatchingAll() {
    _watcher?.cancel();
    _watcher = _service.streamAllScannings().listen(
      (data) {
        _scannings.assignAll(data);
        if (kDebugMode) {
          debugPrint('[ScanningController] Loaded ${data.length} total scans');
        }
      },
      onError: (Object err) {
        errorMessage.value = err.toString();
        if (kDebugMode) {
          debugPrint('[ScanningController] Error watching scans: $err');
        }
      },
    );
  }

  /// Load last scan for a student
  Future<void> _loadLastScan(String studentId) async {
    try {
      final scan = await _service.getLastScan(studentId);
      lastScan.value = scan;
      if (kDebugMode) {
        debugPrint(
          '[ScanningController] Last scan loaded: ${scan?.id ?? 'none'}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScanningController] _loadLastScan error: $e');
      }
    }
  }

  /// Refresh last scan
  Future<void> refreshLastScan() async {
    if (_authController.isStudent) {
      await _loadLastScan(_authController.userId);
    }
  }

  /// Create a new scanning record (called from scanner)
  Future<Scanning?> createScanning({
    required String studentId,
    required String subscriptionId,
    String? deviceInfo,
    String? notes,
  }) async {
    try {
      isBusy.value = true;
      errorMessage.value = null;

      final scanning = await _service.createScanning(
        studentId: studentId,
        subscriptionId: subscriptionId,
        scannedBy: _authController.userId,
        deviceInfo: deviceInfo,
        notes: notes,
      );

      // Update last scan if it's the current student
      if (studentId == _authController.userId) {
        lastScan.value = scanning;
      }

      if (kDebugMode) {
        debugPrint('[ScanningController] Scanning created: ${scanning.id}');
      }

      return scanning;
    } catch (e) {
      errorMessage.value = e.toString();
      if (kDebugMode) {
        debugPrint('[ScanningController] createScanning error: $e');
      }
      return null;
    } finally {
      isBusy.value = false;
    }
  }

  /// Get scan count for a student
  Future<int> getStudentScanCount(String studentId) async {
    try {
      return await _service.getStudentScanCount(studentId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScanningController] getStudentScanCount error: $e');
      }
      return 0;
    }
  }

  /// Watch scans for a specific subscription
  Stream<List<Scanning>> watchSubscriptionScannings(String subscriptionId) {
    return _service.streamSubscriptionScannings(subscriptionId);
  }

  /// Fetch scans for a specific subscription
  Future<List<Scanning>> fetchSubscriptionScannings(
    String subscriptionId,
  ) async {
    try {
      return await _service.fetchSubscriptionScannings(subscriptionId);
    } catch (e) {
      errorMessage.value = e.toString();
      if (kDebugMode) {
        debugPrint('[ScanningController] fetchSubscriptionScannings error: $e');
      }
      rethrow;
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final hasPermission = await _service.requestLocationPermission();
    hasLocationPermission.value = hasPermission;
    return hasPermission;
  }

  /// Get current location
  Future<Map<String, double>?> getCurrentLocation() async {
    return await _service.getCurrentLocation();
  }

  /// Check if screenshot warning has already been shown
  bool hasShownScreenshotWarning() {
    return _storage.read<bool>(_screenshotWarningShownKey) ?? false;
  }

  /// Mark screenshot warning as shown
  void markScreenshotWarningShown() {
    _storage.write(_screenshotWarningShownKey, true);
    if (kDebugMode) {
      debugPrint('[ScanningController] Screenshot warning marked as shown');
    }
  }
}
