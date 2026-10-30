import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/scannings.dart';
import '../services/scanning_service.dart';

class ScanningController extends GetxController {
  ScanningController();

  final ScanningService _service = ScanningService.instance;
  final GetStorage _storage = GetStorage();

  final RxList<Scanning> _scannings = <Scanning>[].obs;
  final Rxn<Scanning> lastScan = Rxn<Scanning>();
  final RxBool isBusy = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool hasLocationPermission = false.obs;

  // Flag to prevent multiple initializations
  bool _isWatchingInitialized = false;

  // Storage key for screenshot warning
  static const String _screenshotWarningShownKey = 'screenshot_warning_shown';

  List<Scanning> get scannings => _scannings;

  StreamSubscription<List<Scanning>>? _watcher;

  @override
  void onInit() {
    super.onInit();
    _checkLocationPermission();

    if (kDebugMode) {
      debugPrint('[ScanningController] onInit called - waiting for initialize() to be called with user data');
    }
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

  /// Initialize watching with user data from AuthController
  /// This should be called from AuthController when user data is ready
  void initialize({
    required String userId,
    required bool isStudent,
    required bool isAdmin,
    required bool isStaff,
  }) {
    // Prevent multiple initializations
    if (_isWatchingInitialized) {
      if (kDebugMode) {
        debugPrint('[ScanningController] ⚠️ Already initialized, skipping');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('[ScanningController] ========== INITIALIZING WITH USER DATA ==========');
      debugPrint('[ScanningController] User ID: $userId');
      debugPrint('[ScanningController] Is Student: $isStudent');
      debugPrint('[ScanningController] Is Admin: $isAdmin');
      debugPrint('[ScanningController] Is Staff: $isStaff');
    }

    if (userId.isEmpty) {
      if (kDebugMode) {
        debugPrint('[ScanningController] ❌ ERROR: User ID is empty!');
      }
      return;
    }

    if (isStudent) {
      if (kDebugMode) {
        debugPrint('[ScanningController] ✅ Starting watch for student: $userId');
      }
      startWatchingStudent(userId);
      _loadLastScan(userId);
      _isWatchingInitialized = true;
    } else if (isAdmin || isStaff) {
      if (kDebugMode) {
        debugPrint('[ScanningController] ✅ Starting watch for admin/staff (all scans)');
      }
      startWatchingAll();
      _isWatchingInitialized = true;
    } else {
      if (kDebugMode) {
        debugPrint('[ScanningController] ⚠️ WARNING: Unknown user role, no watching initialized');
      }
    }
  }

  /// Start watching scans for a specific student
  void startWatchingStudent(String studentId) {
    _watcher?.cancel();

    if (kDebugMode) {
      debugPrint('[ScanningController] ========== SETTING UP STREAM ==========');
      debugPrint('[ScanningController] Student ID: $studentId');
      debugPrint('[ScanningController] Timestamp: ${DateTime.now()}');
    }

    _watcher = _service
        .streamStudentScannings(studentId)
        .listen(
          (data) {
            if (kDebugMode) {
              debugPrint('[ScanningController] ========== STREAM DATA RECEIVED ==========');
              debugPrint('[ScanningController] Timestamp: ${DateTime.now()}');
              debugPrint('[ScanningController] Number of scans: ${data.length}');

              if (data.isNotEmpty) {
                debugPrint('[ScanningController] First scan details:');
                debugPrint('[ScanningController]   - ID: ${data.first.id}');
                debugPrint('[ScanningController]   - Student ID: ${data.first.studentId}');
                debugPrint('[ScanningController]   - Scanned At: ${data.first.scannedAt}');
                debugPrint('[ScanningController]   - Has Location: ${data.first.hasLocation}');
                if (data.first.hasLocation) {
                  debugPrint('[ScanningController]   - Location: ${data.first.locationString}');
                }
              } else {
                debugPrint('[ScanningController] ⚠️ No scans in the list!');
                debugPrint('[ScanningController] This could mean:');
                debugPrint('[ScanningController]   1. No scans exist in Firestore for this student');
                debugPrint('[ScanningController]   2. Firestore query is not returning data');
                debugPrint('[ScanningController]   3. studentId mismatch in Firestore documents');
              }
            }

            _scannings.assignAll(data);

            // Update last scan with the most recent one
            if (data.isNotEmpty) {
              lastScan.value = data.first;
              if (kDebugMode) {
                debugPrint('[ScanningController] ✅ lastScan.value updated: ${data.first.id}');
                debugPrint('[ScanningController] lastScan.value is now: ${lastScan.value?.id}');
              }
            } else {
              lastScan.value = null;
              if (kDebugMode) {
                debugPrint('[ScanningController] ⚠️ lastScan.value set to null (no scans)');
              }
            }

            if (kDebugMode) {
              debugPrint('[ScanningController] Current _scannings list length: ${_scannings.length}');
              debugPrint('[ScanningController] Current lastScan: ${lastScan.value?.id ?? "null"}');
              debugPrint('[ScanningController] ========================================');
            }
          },
          onError: (Object err) {
            errorMessage.value = err.toString();
            if (kDebugMode) {
              debugPrint('[ScanningController] ❌❌❌ ERROR IN STREAM ❌❌❌');
              debugPrint('[ScanningController] Error: $err');
              debugPrint('[ScanningController] Error Type: ${err.runtimeType}');
              debugPrint('[ScanningController] ========================================');
            }
          },
        );

    if (kDebugMode) {
      debugPrint('[ScanningController] ✅ Stream listener attached successfully');
      debugPrint('[ScanningController] ========================================');
    }
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
  Future<void> refreshLastScan(String studentId) async {
    await _loadLastScan(studentId);
  }

  /// Create a new scanning record (called from scanner)
  Future<Scanning?> createScanning({
    required String studentId,
    required String subscriptionId,
    required String scannedBy,
    String? deviceInfo,
    String? notes,
  }) async {
    try {
      isBusy.value = true;
      errorMessage.value = null;

      final scanning = await _service.createScanning(
        studentId: studentId,
        subscriptionId: subscriptionId,
        scannedBy: scannedBy,
        deviceInfo: deviceInfo,
        notes: notes,
      );


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
