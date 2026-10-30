import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/value_objects/bus_stop_selection.dart';
import '../services/bus_stop_service.dart';
import 'auth_controller.dart';

class BusStopsController extends GetxController {
  final BusStopService _service = BusStopService.instance;
  final AuthController _authController = Get.find<AuthController>();

  final RxList<BusStop> busStops = <BusStop>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBusStops();
  }

  /// Fetch all bus stops
  Future<void> fetchBusStops() async {
    try {
      isLoading.value = true;
      error.value = '';
      final stops = await _service.fetchAllBusStops();
      busStops.value = stops;
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        debugPrint('[BusStopsController] fetchBusStops error: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new bus stop
  Future<BusStop?> createBusStop({
    required String name,
    String? pickupImageUrl,
    String? mapEmbedUrl,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final currentUserId = _authController.currentUser.value?.id ?? '';
      if (currentUserId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final newStop = BusStop(
        id: '',
        name: name,
        pickupImageUrl: pickupImageUrl,
        mapEmbedUrl: mapEmbedUrl,
        createdBy: currentUserId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdStop = await _service.createBusStop(newStop, currentUserId);
      busStops.add(createdStop);
      busStops.sort((a, b) => a.name.compareTo(b.name));

      return createdStop;
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        debugPrint('[BusStopsController] createBusStop error: $e');
      }
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update an existing bus stop
  Future<bool> updateBusStop(BusStop stop) async {
    try {
      isLoading.value = true;
      error.value = '';

      final currentUserId = _authController.currentUser.value?.id ?? '';
      if (currentUserId.isEmpty) {
        throw Exception('User not authenticated');
      }

      await _service.updateBusStop(stop, currentUserId);

      final index = busStops.indexWhere((s) => s.id == stop.id);
      if (index != -1) {
        busStops[index] = stop;
        busStops.sort((a, b) => a.name.compareTo(b.name));
      }

      return true;
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        debugPrint('[BusStopsController] updateBusStop error: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a bus stop
  Future<bool> deleteBusStop(String id) async {
    try {
      isLoading.value = true;
      error.value = '';

      await _service.deleteBusStop(id);
      busStops.removeWhere((s) => s.id == id);

      return true;
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
        debugPrint('[BusStopsController] deleteBusStop error: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Search bus stops
  void searchBusStops(String query) {
    searchQuery.value = query;
  }

  /// Get filtered bus stops based on search query
  List<BusStop> get filteredBusStops {
    if (searchQuery.value.isEmpty) {
      return busStops;
    }
    return busStops.where((stop) {
      return stop.name.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  /// Get bus stop by ID
  BusStop? getBusStopById(String id) {
    try {
      return busStops.firstWhere((stop) => stop.id == id);
    } catch (e) {
      return null;
    }
  }
}

