import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import '../services/analytics_service.dart';

class AnalyticsController extends GetxController {
  AnalyticsController();

  final AnalyticsService _service = AnalyticsService.instance;
  final GetStorage _storage = GetStorage();

  static const String _viewModeKey = 'analytics_view_mode';

  final Rx<AnalyticsData> analyticsData = AnalyticsData.empty().obs;
  final RxBool isBusy = false.obs;
  final RxnString errorMessage = RxnString();

  // View mode: false = numerical (default), true = graphical
  final RxBool showGraphical = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadViewPreference();
    fetchAnalytics();
  }

  /// Load saved view preference from storage
  void _loadViewPreference() {
    final savedView = _storage.read<bool>(_viewModeKey);
    if (savedView != null) {
      showGraphical.value = savedView;
      if (kDebugMode) {
        debugPrint('[AnalyticsController] Loaded view preference: ${savedView ? 'graphical' : 'numerical'}');
      }
    }
  }

  /// Toggle between numerical and graphical view
  void toggleView() {
    showGraphical.toggle();
    _storage.write(_viewModeKey, showGraphical.value);
    if (kDebugMode) {
      debugPrint('[AnalyticsController] View toggled to: ${showGraphical.value ? 'graphical' : 'numerical'}');
    }
  }

  /// Set view mode explicitly
  void setViewMode(bool isGraphical) {
    showGraphical.value = isGraphical;
    _storage.write(_viewModeKey, isGraphical);
    if (kDebugMode) {
      debugPrint('[AnalyticsController] View set to: ${isGraphical ? 'graphical' : 'numerical'}');
    }
  }

  /// Fetch analytics data
  Future<void> fetchAnalytics() async {
    try {
      isBusy.value = true;
      errorMessage.value = null;

      final data = await _service.fetchAnalytics();
      analyticsData.value = data;

      if (kDebugMode) {
        debugPrint('[AnalyticsController] Analytics fetched successfully');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      if (kDebugMode) {
        debugPrint('[AnalyticsController] fetchAnalytics error: $e');
      }
    } finally {
      isBusy.value = false;
    }
  }

  /// Refresh analytics
  Future<void> refreshAnalytics() async {
    await fetchAnalytics();
  }

  // Getters for quick access
  int get totalStudents => analyticsData.value.totalStudents;
  int get totalSubscriptions => analyticsData.value.totalSubscriptions;
  int get totalSemesters => analyticsData.value.totalSemesters;
  int get totalBusStops => analyticsData.value.totalBusStops;

  int get pendingSubscriptions => analyticsData.value.pendingSubscriptions;
  int get approvedSubscriptions => analyticsData.value.approvedSubscriptions;
  int get rejectedSubscriptions => analyticsData.value.rejectedSubscriptions;
  int get expiredSubscriptions => analyticsData.value.expiredSubscriptions;

  double get approvalRate {
    if (totalSubscriptions == 0) return 0.0;
    return (approvedSubscriptions / totalSubscriptions) * 100;
  }

  double get rejectionRate {
    if (totalSubscriptions == 0) return 0.0;
    return (rejectedSubscriptions / totalSubscriptions) * 100;
  }

  double get pendingRate {
    if (totalSubscriptions == 0) return 0.0;
    return (pendingSubscriptions / totalSubscriptions) * 100;
  }
}

