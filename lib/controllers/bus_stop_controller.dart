import 'package:get/get.dart';

import '../models/value_objects/bus_stop_selection.dart';

class BusStopController extends GetxController {
  BusStopController({List<BusStop>? initialStops}) {
    if (initialStops?.isNotEmpty ?? false) {
      setStops(initialStops!);
    }
  }

  final RxList<BusStop> stops = dummyBusStops.obs;
  final RxList<BusStop> filteredStops = <BusStop>[].obs;
  final Rxn<BusStop> selectedStop = Rxn<BusStop>();
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxString query = ''.obs;
  Worker? _searchWorker;

  @override
  void onInit() {
    super.onInit();
    _searchWorker = debounce<String>(
      query,
      _applyFilter,
      time: const Duration(milliseconds: 200),
    );
  }

  @override
  void onClose() {
    _searchWorker?.dispose();
    super.onClose();
  }

  Future<void> fetchStops(Future<List<BusStop>> Function() loader) async {
    if (isLoading.value) return;
    errorMessage.value = null;
    isLoading.value = true;
    try {
      final fetched = await loader();
      setStops(fetched);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshStops(Future<List<BusStop>> Function() loader) =>
      fetchStops(loader);

  void setStops(List<BusStop> data) {
    data.sort((a, b) => a.name.compareTo(b.name));
    stops.assignAll(data);
    _applyFilter(query.value);
    final current = selectedStop.value;
    if (current != null) {
      selectStop(current.id);
    }
  }

  void setQuery(String value) => query.value = value.trim();

  void _applyFilter(String term) {
    if (term.isEmpty) {
      filteredStops.assignAll(stops);
      return;
    }
    final lower = term.toLowerCase();
    filteredStops.assignAll(
      stops.where((stop) => stop.name.toLowerCase().contains(lower)),
    );
  }

  void selectStop(String stopId) {
    final match = _findById(stopId);
    if (match != null) {
      selectedStop.value = match;
    }
  }

  void clearSelection() => selectedStop.value = null;

  void addStop(BusStop stop) {
    if (_findById(stop.id) != null) return;
    stops.add(stop);
    stops.sort((a, b) => a.name.compareTo(b.name));
    _applyFilter(query.value);
  }

  void updateStop(BusStop updated) {
    final index = stops.indexWhere((s) => s.id == updated.id);
    if (index == -1) return;
    stops[index] = updated;
    stops.sort((a, b) => a.name.compareTo(b.name));
    _applyFilter(query.value);
    if (selectedStop.value?.id == updated.id) {
      selectedStop.value = updated;
    }
  }

  void removeStop(String stopId) {
    stops.removeWhere((s) => s.id == stopId);
    _applyFilter(query.value);
    if (selectedStop.value?.id == stopId) {
      selectedStop.value = null;
    }
  }

  BusStop? _findById(String stopId) {
    for (final stop in stops) {
      if (stop.id == stopId) return stop;
    }
    return null;
  }

  List<BusStop> get highlightedStops =>
      filteredStops.take(5).toList(growable: false);
}
