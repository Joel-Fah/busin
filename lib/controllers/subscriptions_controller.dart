import 'dart:async';

import 'package:busin/models/subscription.dart';
import 'package:busin/services/subscription_service.dart';
import 'package:get/get.dart';

class BusSubscriptionsController extends GetxController {
  BusSubscriptionsController();

  final SubscriptionService _service = SubscriptionService.instance;

  final RxList<BusSubscription> _busSubscriptions = <BusSubscription>[].obs;
  final RxBool isBusy = false.obs;
  final RxnString errorMessage = RxnString();

  List<BusSubscription> get busSubscriptions => _busSubscriptions;

  // Firebase collection
  static const String kSubscriptionsCollection = 'subscriptions';

  StreamSubscription<List<BusSubscription>>? _watcher;
  String? _currentStudentId;
  BusSubscriptionStatus? _currentStatus;

  @override
  void onInit() {
    super.onInit();
    startWatching();
  }

  @override
  void onClose() {
    _watcher?.cancel();
    super.onClose();
  }

  void startWatching({
    String? studentId,
    BusSubscriptionStatus? status,
  }) {
    _currentStudentId = studentId;
    _currentStatus = status;
    _watcher?.cancel();
    _watcher = _service
        .watchSubscriptions(studentId: studentId, status: status)
        .listen(
      (data) => _busSubscriptions.assignAll(data),
      onError: (Object err) => errorMessage.value = err.toString(),
    );
  }

  /// Start watching all subscriptions (for admin purposes)
  void startWatchingAll() {
    _watcher?.cancel();
    _watcher = _service
        .watchAllSubscriptions()
        .listen(
      (data) => _busSubscriptions.assignAll(data),
      onError: (Object err) => errorMessage.value = err.toString(),
    );
  }

  /// Approve a subscription
  Future<void> approveSubscription({
    required String subscriptionId,
    required String reviewerId,
  }) async {
    await _guardedRequest(() => _service.approveSubscription(
          subscriptionId: subscriptionId,
          reviewerId: reviewerId,
        ));
  }

  /// Reject a subscription
  Future<void> rejectSubscription({
    required String subscriptionId,
    required String reviewerId,
    required String reason,
  }) async {
    await _guardedRequest(() => _service.rejectSubscription(
          subscriptionId: subscriptionId,
          reviewerId: reviewerId,
          reason: reason,
        ));
  }

  Future<void> refreshCurrentFilters() async {
    startWatching(studentId: _currentStudentId, status: _currentStatus);
  }

  Future<BusSubscription?> fetchSubscriptionById(String id) async {
    try {
      return await _service.fetchSubscription(id);
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

      final updatedSubscription = await _service.fetchSubscription(id);

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
    return _guardedRequest(() => _service.createSubscription(
          subscription: subscription,
          proofUrl: proofUrl,
        ));
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