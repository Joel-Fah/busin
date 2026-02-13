import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/bus_update.dart';
import '../services/update_service.dart';
import 'auth_controller.dart';
import 'scanning_controller.dart';
import 'subscriptions_controller.dart';

class UpdateController extends GetxController {
  UpdateController();

  final UpdateService _service = UpdateService.instance;
  final GetStorage _storage = GetStorage();

  /// All today's updates (realtime)
  final RxList<BusUpdate> todayUpdates = <BusUpdate>[].obs;

  /// The latest update (first in list)
  final Rxn<BusUpdate> latestUpdate = Rxn<BusUpdate>();

  /// Older updates (all except latest)
  List<BusUpdate> get olderUpdates =>
      todayUpdates.length > 1 ? todayUpdates.sublist(1) : [];

  /// Loading & error state
  final RxBool isBusy = false.obs;
  final RxnString errorMessage = RxnString();

  /// Badge: number of new updates since last seen
  final RxInt unseenCount = 0.obs;
  bool get hasUnseenUpdates => unseenCount.value > 0;

  /// Currently selected update type for the input
  final Rx<BusUpdateType> selectedType = BusUpdateType.busLocation.obs;

  /// Whether the input field is focused (keyboard is open on Updates tab)
  final RxBool isInputFocused = false.obs;

  // ── Restriction state ──────────────────────────────────

  /// Whether the current user has an approved, in-window subscription.
  final RxBool hasActiveSubscription = false.obs;

  /// Whether the current user has at least one scan today.
  final RxBool hasScannedToday = false.obs;

  /// Whether the user is allowed to post a bus-location update.
  /// Admin/staff bypass all restrictions.
  bool get canPostUpdate {
    final auth = Get.find<AuthController>();
    if (auth.isAdmin || auth.isStaff) return true;
    return hasActiveSubscription.value && hasScannedToday.value;
  }

  // Internal state
  StreamSubscription<List<BusUpdate>>? _watcher;
  bool _isInitialized = false;

  // Storage key for last seen update timestamp
  static const String _lastSeenTimestampKey = 'last_seen_update_timestamp';

  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) {
      debugPrint('[UpdateController] onInit - waiting for initialize() call');
    }
  }

  @override
  void onClose() {
    _watcher?.cancel();
    super.onClose();
  }

  /// Initialize the controller – called from AuthController once user is ready
  void initialize() {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('[UpdateController] ⚠️ Already initialized, skipping');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint(
        '[UpdateController] ✅ Initializing – starting realtime stream',
      );
    }

    _startWatching();
    _refreshRestrictions();
    _isInitialized = true;
  }

  /// Recompute subscription & scan-today flags from sibling controllers.
  void _refreshRestrictions() {
    try {
      final auth = Get.find<AuthController>();

      // Admin/staff bypass – no need to compute further
      if (auth.isAdmin || auth.isStaff) {
        hasActiveSubscription.value = true;
        hasScannedToday.value = true;
        return;
      }

      // Check active subscription
      final subCtrl = Get.find<BusSubscriptionsController>();
      hasActiveSubscription.value = subCtrl.busSubscriptions.any(
        (s) => s.isCurrentlyActive,
      );

      // Check scanned today
      final scanCtrl = Get.find<ScanningController>();
      final now = DateTime.now();
      hasScannedToday.value = scanCtrl.scannings.any(
        (s) =>
            s.scannedAt.year == now.year &&
            s.scannedAt.month == now.month &&
            s.scannedAt.day == now.day,
      );

      if (kDebugMode) {
        debugPrint(
          '[UpdateController] Restrictions: '
          'subscription=${hasActiveSubscription.value}, '
          'scannedToday=${hasScannedToday.value}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UpdateController] ⚠️ Restriction check failed: $e');
      }
    }
  }

  /// Public helper so the UI can re-check restrictions when the tab is opened.
  void refreshRestrictions() => _refreshRestrictions();

  /// Start listening to today's updates in realtime
  void _startWatching() {
    _watcher?.cancel();

    _watcher = _service.streamTodayUpdates().listen(
      (updates) {
        if (kDebugMode) {
          debugPrint(
            '[UpdateController] Stream data: ${updates.length} updates today',
          );
        }

        // Calculate unseen count before updating the list
        _calculateUnseenCount(updates);

        todayUpdates.assignAll(updates);
        latestUpdate.value = updates.isNotEmpty ? updates.first : null;
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('[UpdateController] ❌ Stream error: $error');
        }
        errorMessage.value = error.toString();
      },
    );
  }

  /// Submit a new update
  Future<void> submitUpdate({
    required String authorId,
    required String authorName,
    String? authorPhotoUrl,
    required String message,
  }) async {
    if (message.trim().isEmpty) return;

    // Server-side guard: re-check restrictions before sending
    _refreshRestrictions();
    if (!canPostUpdate) {
      errorMessage.value =
          'Update blocked: subscription or scan requirement not met.';
      return;
    }

    isBusy.value = true;
    errorMessage.value = null;

    try {
      await _service.createUpdate(
        authorId: authorId,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        type: selectedType.value,
        message: message,
      );

      if (kDebugMode) {
        debugPrint('[UpdateController] ✅ Update submitted successfully');
      }

      // Mark the time we last interacted, so our own update doesn't badge
      _markAsSeen();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UpdateController] ❌ Submit error: $e');
      }
      errorMessage.value = e.toString();
    } finally {
      isBusy.value = false;
    }
  }

  /// Delete an update (only author or admin)
  Future<void> deleteUpdate(String updateId) async {
    try {
      await _service.deleteUpdate(updateId);
      if (kDebugMode) {
        debugPrint('[UpdateController] ✅ Deleted update $updateId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UpdateController] ❌ Delete error: $e');
      }
      errorMessage.value = e.toString();
    }
  }

  /// Change the selected update type
  void changeType(BusUpdateType type) {
    selectedType.value = type;
  }

  /// Mark all current updates as seen (resets the badge)
  void markAsSeen() {
    _markAsSeen();
    unseenCount.value = 0;
  }

  // --- Private helpers ---

  void _markAsSeen() {
    _storage.write(_lastSeenTimestampKey, DateTime.now().toIso8601String());
  }

  void _calculateUnseenCount(List<BusUpdate> updates) {
    final lastSeenStr = _storage.read<String>(_lastSeenTimestampKey);
    if (lastSeenStr == null) {
      // Never seen → all are new
      unseenCount.value = updates.length;
      return;
    }

    final lastSeen = DateTime.tryParse(lastSeenStr);
    if (lastSeen == null) {
      unseenCount.value = updates.length;
      return;
    }

    final newCount = updates.where((u) => u.createdAt.isAfter(lastSeen)).length;
    unseenCount.value = newCount;
  }

  /// Reset the controller state (e.g. on sign out)
  void reset() {
    _watcher?.cancel();
    _isInitialized = false;
    todayUpdates.clear();
    latestUpdate.value = null;
    unseenCount.value = 0;
    errorMessage.value = null;
  }
}
