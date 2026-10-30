import 'dart:async';

import 'package:busin/models/subscription.dart';
import 'package:busin/services/subscription_service.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import 'auth_controller.dart';
import 'bus_stops_controller.dart';
import 'semester_controller.dart';

class BusSubscriptionsController extends GetxController {
  BusSubscriptionsController();

  final SubscriptionService _service = SubscriptionService.instance;
  final AuthController _authController = Get.find<AuthController>();

  // Lazy-loaded references for resolving semester/stop IDs.
  SemesterController get _semesterController => Get.find<SemesterController>();
  BusStopsController get _busStopsController => Get.find<BusStopsController>();

  final RxList<BusSubscription> _busSubscriptions = <BusSubscription>[].obs;
  final RxBool isBusy = false.obs;
  final RxnString errorMessage = RxnString();

  List<BusSubscription> get busSubscriptions => _busSubscriptions;
  bool get isStudent => _authController.isStudent;

  // Firebase collection
  static const String kSubscriptionsCollection = 'subscriptions';

  StreamSubscription<List<BusSubscription>>? _watcher;
  String? _currentStudentId;
  BusSubscriptionStatus? _currentStatus;

  @override
  void onInit() {
    super.onInit();
    // Start watching with proper filtering based on user role
    _initializeWatching();

    // Re-initialize watching when user authentication state changes
    ever(_authController.currentUser, (_) {
      if (kDebugMode) {
        debugPrint(
          '[BusSubscriptionsController] Auth state changed, reinitializing...',
        );
      }
      _initializeWatching();
    });
  }

  @override
  void onClose() {
    _watcher?.cancel();
    super.onClose();
  }

  /// Initialize watching based on user role
  /// Students: Only watch their own subscriptions
  /// Admins/Staff: Watch all subscriptions
  void _initializeWatching() {
    if (_authController.isStudent) {
      // SECURITY: Students can ONLY see their own subscriptions
      final studentId = _authController.userId;
      if (studentId.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[BusSubscriptionsController] Warning: Student ID is empty, cannot watch subscriptions',
          );
        }
        errorMessage.value =
            'Unable to load subscriptions: User not properly authenticated';
        return;
      }
      startWatching(studentId: studentId);
      if (kDebugMode) {
        debugPrint(
          '[BusSubscriptionsController] Watching subscriptions for student: $studentId',
        );
      }
    } else if (_authController.isAdmin || _authController.isStaff) {
      // Admins and staff can see all subscriptions
      startWatchingAll();
      if (kDebugMode) {
        debugPrint(
          '[BusSubscriptionsController] Watching all subscriptions (Admin/Staff)',
        );
      }
    } else {
      // Fallback for unauthenticated or unknown roles
      if (kDebugMode) {
        debugPrint(
          '[BusSubscriptionsController] Warning: Unknown user role, not watching subscriptions',
        );
      }
    }
  }

  void startWatching({String? studentId, BusSubscriptionStatus? status}) {
    // SECURITY: For students, always ensure we're using their ID
    String? finalStudentId = studentId;
    if (_authController.isStudent) {
      finalStudentId = _authController.userId;
      if (kDebugMode) {
        debugPrint(
          '[BusSubscriptionsController] SECURITY: Enforcing student filter for ${finalStudentId}',
        );
      }
    }

    _currentStudentId = finalStudentId;
    _currentStatus = status;
    _watcher?.cancel();
    _watcher = _service
        .watchSubscriptions(studentId: finalStudentId, status: status)
        .listen((data) {
          if (kDebugMode) {
            debugPrint(
              '[BusSubscriptionsController] Received ${data.length} subscriptions',
            );
          }
          _busSubscriptions.assignAll(_resolveSubscriptions(data));
        }, onError: (Object err) => errorMessage.value = err.toString());
  }

  /// Start watching all subscriptions (for admin purposes)
  void startWatchingAll() {
    _watcher?.cancel();
    _watcher = _service.watchAllSubscriptions().listen(
      (data) => _busSubscriptions.assignAll(_resolveSubscriptions(data)),
      onError: (Object err) => errorMessage.value = err.toString(),
    );
  }

  /// Resolve [semesterId] and [stopId] references on every subscription
  /// using the in-memory caches from [SemesterController] and
  /// [BusStopsController]. This is synchronous because both controllers
  /// load their data once on init and keep it in memory.
  List<BusSubscription> _resolveSubscriptions(List<BusSubscription> subs) {
    return subs.map((sub) {
      final semester = _semesterController.getSemesterById(sub.semesterId);
      final stop = sub.stopId != null
          ? _busStopsController.getBusStopById(sub.stopId!)
          : null;
      return sub.resolve(semester: semester, busStop: stop);
    }).toList();
  }

  /// Approve a subscription
  Future<void> approveSubscription({
    required String subscriptionId,
    required String reviewerId,
  }) async {
    await _guardedRequest(
      () => _service.approveSubscription(
        subscriptionId: subscriptionId,
        reviewerId: reviewerId,
      ),
    );
  }

  /// Reject a subscription
  Future<void> rejectSubscription({
    required String subscriptionId,
    required String reviewerId,
    required String reason,
  }) async {
    await _guardedRequest(
      () => _service.rejectSubscription(
        subscriptionId: subscriptionId,
        reviewerId: reviewerId,
        reason: reason,
      ),
    );
  }

  Future<void> refreshCurrentFilters() async {
    // For students, always ensure their ID is used
    if (_authController.isStudent) {
      final studentId = _authController.userId;
      startWatching(studentId: studentId, status: _currentStatus);
    } else if (_authController.isAdmin || _authController.isStaff) {
      startWatchingAll();
    } else {
      startWatching(studentId: _currentStudentId, status: _currentStatus);
    }
  }

  Future<BusSubscription?> fetchSubscriptionById(String id) async {
    try {
      // For students, pass their ID for security validation
      final requesterStudentId = _authController.isStudent
          ? _authController.userId
          : null;
      final sub = await _service.fetchSubscription(
        id,
        requesterStudentId: requesterStudentId,
      );
      return sub != null ? _resolveSubscriptions([sub]).first : null;
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    }
  }

  /// Refresh a specific subscription by fetching latest data from the server
  /// and updating the local list
  Future<BusSubscription?> refreshSubscription(String id) async {
    try {
      isBusy.value = true;
      errorMessage.value = null;

      // For students, pass their ID for security validation
      final requesterStudentId = _authController.isStudent
          ? _authController.userId
          : null;
      final rawSubscription = await _service.fetchSubscription(
        id,
        requesterStudentId: requesterStudentId,
      );

      final updatedSubscription = rawSubscription != null
          ? _resolveSubscriptions([rawSubscription]).first
          : null;

      if (updatedSubscription != null) {
        // Update the subscription in the local list
        final index = _busSubscriptions.indexWhere((sub) => sub.id == id);
        if (index != -1) {
          _busSubscriptions[index] = updatedSubscription;
        } else {
          // If not found in list, add it
          _busSubscriptions.add(updatedSubscription);
        }
      }

      return updatedSubscription;
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      isBusy.value = false;
    }
  }

  Future<BusSubscription> createSubscription({
    required BusSubscription subscription,
    String? proofUrl,
  }) async {
    return _guardedRequest(
      () => _service.createSubscription(
        subscription: subscription,
        proofUrl: proofUrl,
        studentName: _authController.userDisplayName,
      ),
    );
  }

  Future<void> updateSubscription(BusSubscription subscription) async {
    await _guardedRequest(() => _service.updateSubscription(subscription));
  }

  Future<void> deleteSubscription(String id) async {
    await _guardedRequest(() => _service.deleteSubscription(id));
  }

  BusSubscription? getSubscriptionById(String id) {
    try {
      return _busSubscriptions.firstWhere((sub) => sub.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<T> _guardedRequest<T>(Future<T> Function() action) async {
    if (isBusy.value) {
      return action();
    }
    isBusy.value = true;
    errorMessage.value = null;
    try {
      return await action();
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      isBusy.value = false;
    }
  }
}
