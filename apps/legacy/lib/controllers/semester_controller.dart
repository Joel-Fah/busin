import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/semester_config.dart';
import '../services/semester_service.dart';
import 'auth_controller.dart';

class SemesterController extends GetxController {
  final SemesterService _service = SemesterService.instance;
  final AuthController _authController = Get.find<AuthController>();

  final RxList<SemesterConfig> semesters = <SemesterConfig>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rxn<SemesterConfig> activeSemester = Rxn<SemesterConfig>();

  @override
  void onInit() {
    super.onInit();
    fetchSemesters();
    fetchActiveSemester();
  }

  /// Fetch all semesters
  Future<void> fetchSemesters() async {
    try {
      isLoading.value = true;
      error.value = '';
      final configs = await _service.fetchAllSemesters();
      semesters.value = configs;
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        debugPrint('[SemesterController] fetchSemesters error: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch active semester
  Future<void> fetchActiveSemester() async {
    try {
      final config = await _service.fetchActiveSemester();
      activeSemester.value = config;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SemesterController] fetchActiveSemester error: $e');
      }
    }
  }

  /// Create a new semester
  Future<SemesterConfig?> createSemester({
    required SemesterConfig config,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final currentUserId = _authController.currentUser.value?.id ?? '';
      if (currentUserId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final createdConfig = await _service.createSemester(
        config,
        currentUserId,
      );
      semesters.add(createdConfig);

      // Sort by year (descending) and then by semester
      semesters.sort((a, b) {
        final yearCompare = b.year.compareTo(a.year);
        if (yearCompare != 0) return yearCompare;
        return a.semester.index.compareTo(b.semester.index);
      });

      // Check if this is now the active semester
      if (createdConfig.isActive) {
        activeSemester.value = createdConfig;
      }

      return createdConfig;
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        debugPrint('[SemesterController] createSemester error: $e');
      }
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update an existing semester
  Future<SemesterConfig?> updateSemester({
    required SemesterConfig config,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final currentUserId = _authController.currentUser.value?.id ?? '';
      if (currentUserId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final updatedConfig = await _service.updateSemester(
        config,
        currentUserId,
      );

      final index = semesters.indexWhere((s) => s.id == updatedConfig.id);
      if (index != -1) {
        semesters[index] = updatedConfig;
      }

      // Update active semester if this was it
      if (activeSemester.value?.id == updatedConfig.id) {
        activeSemester.value = updatedConfig.isActive ? updatedConfig : null;
      }

      return updatedConfig;
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        debugPrint('[SemesterController] updateSemester error: $e');
      }
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a semester
  Future<bool> deleteSemester(String id) async {
    try {
      isLoading.value = true;
      error.value = '';

      await _service.deleteSemester(id);
      semesters.removeWhere((s) => s.id == id);

      // Clear active semester if this was it
      if (activeSemester.value?.id == id) {
        activeSemester.value = null;
        fetchActiveSemester(); // Try to find another active semester
      }

      return true;
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        debugPrint('[SemesterController] deleteSemester error: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch semesters for a specific year
  Future<List<SemesterConfig>> fetchSemestersByYear(int year) async {
    try {
      return await _service.fetchSemestersByYear(year);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SemesterController] fetchSemestersByYear error: $e');
      }
      return [];
    }
  }

  /// Get a semester by ID
  SemesterConfig? getSemesterById(String id) {
    try {
      return semesters.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if a semester already exists for a given semester and year
  bool semesterExists(String semesterName, int year) {
    return semesters.any(
      (s) =>
          s.semester.nameLower == semesterName.toLowerCase() && s.year == year,
    );
  }
}
