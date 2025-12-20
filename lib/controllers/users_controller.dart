import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import '../models/actors/base_user.dart';
import '../models/actors/roles.dart';
import '../services/users_service.dart';

class UsersController extends GetxController {
  UsersController();

  final UsersService _service = UsersService.instance;
  final GetStorage _storage = GetStorage();

  static const String _viewModeKey = 'people_view_mode';

  final RxList<BaseUser> _users = <BaseUser>[].obs;
  final RxBool isBusy = false.obs;
  final RxnString errorMessage = RxnString();

  // Current view mode: student or staff
  final Rx<UserRole> currentViewMode = UserRole.student.obs;

  // Cache for user stats to avoid repeated queries
  final Map<String, int> _subscriptionCountCache = {};
  final Map<String, int> _scanCountCache = {};

  List<BaseUser> get users => _users;

  StreamSubscription<List<BaseUser>>? _watcher;

  @override
  void onInit() {
    super.onInit();
    _loadViewPreference();
    startWatching(currentViewMode.value);
  }

  @override
  void onClose() {
    _watcher?.cancel();
    super.onClose();
  }

  /// Load saved view preference from storage
  void _loadViewPreference() {
    final savedView = _storage.read<String>(_viewModeKey);
    if (savedView != null) {
      if (savedView == UserRole.staff.name) {
        currentViewMode.value = UserRole.staff;
      } else {
        currentViewMode.value = UserRole.student;
      }
      if (kDebugMode) {
        debugPrint('[UsersController] Loaded view preference: ${currentViewMode.value.name}');
      }
    }
  }

  /// Switch view mode between students and staff
  void switchViewMode(UserRole role) {
    if (currentViewMode.value != role) {
      currentViewMode.value = role;
      _storage.write(_viewModeKey, role.name);
      startWatching(role);
      if (kDebugMode) {
        debugPrint('[UsersController] View mode switched to: ${role.name}');
      }
    }
  }

  /// Start watching users by role
  void startWatching(UserRole role) {
    _watcher?.cancel();
    isBusy.value = true;
    errorMessage.value = null;

    if (role == UserRole.staff) {
      // For staff view, show both staff and admin users
      _watcher = _service.streamAllStaff().listen(
        (data) {
          _users.assignAll(data);
          isBusy.value = false;
          if (kDebugMode) {
            debugPrint('[UsersController] Loaded ${data.length} staff/admin users');
          }
        },
        onError: (Object err) {
          errorMessage.value = err.toString();
          isBusy.value = false;
          if (kDebugMode) {
            debugPrint('[UsersController] Error watching users: $err');
          }
        },
      );
    } else {
      // For student view, show only students
      _watcher = _service.streamUsersByRole(role).listen(
        (data) {
          _users.assignAll(data);
          isBusy.value = false;
          if (kDebugMode) {
            debugPrint('[UsersController] Loaded ${data.length} ${role.name}s');
          }
        },
        onError: (Object err) {
          errorMessage.value = err.toString();
          isBusy.value = false;
          if (kDebugMode) {
            debugPrint('[UsersController] Error watching users: $err');
          }
        },
      );
    }
  }

  /// Fetch users by role (one-time)
  Future<void> fetchUsersByRole(UserRole role) async {
    try {
      isBusy.value = true;
      errorMessage.value = null;

      final List<BaseUser> data;
      if (role == UserRole.staff) {
        // For staff view, fetch both staff and admin users
        data = await _service.fetchAllStaff();
        if (kDebugMode) {
          debugPrint('[UsersController] Fetched ${data.length} staff/admin users');
        }
      } else {
        // For student view, fetch only students
        data = await _service.fetchUsersByRole(role);
        if (kDebugMode) {
          debugPrint('[UsersController] Fetched ${data.length} ${role.name}s');
        }
      }

      _users.assignAll(data);
    } catch (e) {
      errorMessage.value = e.toString();
      if (kDebugMode) {
        debugPrint('[UsersController] fetchUsersByRole error: $e');
      }
    } finally {
      isBusy.value = false;
    }
  }

  /// Get subscription count for a user (with caching)
  Future<int> getUserSubscriptionCount(String userId) async {
    // Check cache first
    if (_subscriptionCountCache.containsKey(userId)) {
      return _subscriptionCountCache[userId]!;
    }

    try {
      final count = await _service.getUserSubscriptionCount(userId);
      _subscriptionCountCache[userId] = count;
      return count;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UsersController] getUserSubscriptionCount error: $e');
      }
      return 0;
    }
  }

  /// Get scan count for a user (with caching)
  Future<int> getUserScanCount(String userId) async {
    // Check cache first
    if (_scanCountCache.containsKey(userId)) {
      return _scanCountCache[userId]!;
    }

    try {
      final count = await _service.getUserScanCount(userId);
      _scanCountCache[userId] = count;
      return count;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UsersController] getUserScanCount error: $e');
      }
      return 0;
    }
  }

  /// Clear cache
  void clearCache() {
    _subscriptionCountCache.clear();
    _scanCountCache.clear();
    if (kDebugMode) {
      debugPrint('[UsersController] Cache cleared');
    }
  }

  /// Refresh current view
  Future<void> refreshUsers() async {
    clearCache();
    await fetchUsersByRole(currentViewMode.value);
  }

  /// Update user status
  Future<void> updateUserStatus(String userId, AccountStatus status) async {
    try {
      await _service.updateUserStatus(userId, status);
      // Refresh to show updated status
      await refreshUsers();
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    }
  }

  /// Delete user (suspend)
  Future<void> deleteUser(String userId) async {
    try {
      await _service.deleteUser(userId);
      // Refresh to remove from list
      await refreshUsers();
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    }
  }
}

