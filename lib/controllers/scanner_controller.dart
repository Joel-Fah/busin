import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import '../services/scanner_service.dart';
import 'scanning_controller.dart';
import 'auth_controller.dart';

class ScannerController extends GetxController {
  ScannerController();

  final ScannerService _service = ScannerService.instance;
  final AuthController _authController = Get.find<AuthController>();

  final Rxn<ScanResult> currentScanResult = Rxn<ScanResult>();
  final RxBool isProcessing = false.obs;
  final RxBool isScannerActive = true.obs;
  final RxnString lastScannedCode = RxnString();

  /// Process scanned QR code
  Future<void> processScan(String qrCode) async {
    // Prevent duplicate scans
    if (lastScannedCode.value == qrCode && currentScanResult.value != null) {
      if (kDebugMode) {
        debugPrint('[ScannerController] Duplicate scan ignored: $qrCode');
      }
      return;
    }

    try {
      isProcessing.value = true;
      lastScannedCode.value = qrCode;

      if (kDebugMode) {
        debugPrint('[ScannerController] Processing QR code: $qrCode');
      }

      final result = await _service.verifyStudentQRCode(qrCode);
      currentScanResult.value = result;

      if (kDebugMode) {
        debugPrint(
          '[ScannerController] Scan result - Valid: ${result.isValid}, '
          'Active: ${result.hasActiveSubscription}',
        );
      }

      // If scan is successful, create a scanning record
      if (result.isValid && result.hasActiveSubscription && result.student != null) {
        await _createScanningRecord(result);
      }

      // Result persists until next scan or manual clear - no auto-clear
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScannerController] processScan error: $e');
      }
      currentScanResult.value = ScanResult.invalid('Error: ${e.toString()}');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Create a scanning record in Firestore
  Future<void> _createScanningRecord(ScanResult result) async {
    try {
      // Try to get ScanningController, or create one if it doesn't exist
      ScanningController scanningController;
      try {
        scanningController = Get.find<ScanningController>();
      } catch (e) {
        scanningController = Get.put(ScanningController());
      }

      await scanningController.createScanning(
        studentId: result.student!.id,
        subscriptionId: result.subscription!.id,
        deviceInfo: 'Scanner App - ${_authController.userDisplayName}',
        notes: 'Scanned by ${_authController.userDisplayName}',
      );

      if (kDebugMode) {
        debugPrint('[ScannerController] Scanning record created for student: ${result.student!.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScannerController] _createScanningRecord error: $e');
      }
      // Don't fail the whole scan if recording fails
    }
  }

  /// Clear current scan result
  void clearScanResult() {
    currentScanResult.value = null;
    lastScannedCode.value = null;
  }

  /// Toggle scanner active state
  void toggleScanner() {
    isScannerActive.toggle();
  }

  /// Reset scanner
  void resetScanner() {
    clearScanResult();
    isScannerActive.value = true;
  }

  @override
  void onClose() {
    clearScanResult();
    super.onClose();
  }
}

