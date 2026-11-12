import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

import '../auth/access.dart';
import '../providers.dart';
import '../push/push_providers.dart';

final areaRepositoryProvider = Provider<AreaRepository>((ref) => ref.watch(repositoriesProvider).areas);

/// The student's area, or null when they have not given one. Only loaded for an allowed student.
final myAreaProvider = FutureProvider.autoDispose<StudentArea?>((ref) async {
  if (ref.watch(accessProvider) is! Allowed) return null;
  return ref.watch(areaRepositoryProvider).myArea();
}, retry: noAutomaticRetry);

/// What one reading of the phone's location gave.
sealed class LocatorResult {
  const LocatorResult();
}

class Located extends LocatorResult {
  const Located(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// The student said no, or said never (then only the phone's settings can change it).
class LocationDenied extends LocatorResult {
  const LocationDenied({required this.forever});
  final bool forever;
}

/// Location is switched off on the phone.
class LocationOff extends LocatorResult {
  const LocationOff();
}

class LocationFailed extends LocatorResult {
  const LocationFailed();
}

/// Reads the phone's approximate location once (ADR 0013). Never listens, never in the background.
abstract interface class AreaLocator {
  Future<LocatorResult> readOnce();
  Future<void> openSettings();
}

class DeviceAreaLocator implements AreaLocator {
  GeolocatorPlatform get _geo => GeolocatorPlatform.instance;

  @override
  Future<LocatorResult> readOnce() async {
    try {
      if (!await _geo.isLocationServiceEnabled()) return const LocationOff();
      var permission = await _geo.checkPermission();
      if (permission == LocationPermission.denied) permission = await _geo.requestPermission();
      if (permission == LocationPermission.denied) return const LocationDenied(forever: false);
      if (permission == LocationPermission.deniedForever) return const LocationDenied(forever: true);
      final position = await _geo.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 20)),
      );
      return Located(position.latitude, position.longitude);
    } on Object {
      return const LocationFailed();
    }
  }

  @override
  Future<void> openSettings() async {
    await _geo.openAppSettings();
  }
}

final areaLocatorProvider = Provider<AreaLocator>((ref) => DeviceAreaLocator());

/// Set when the student chose "Not seeing your street?": the profile then suggests doing it at home.
const areaLaterKey = 'area.later';

final areaLaterProvider = FutureProvider.autoDispose<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool(areaLaterKey) ?? false;
});

/// Remembers (or forgets) that the student wants to add their area later, at home.
final setAreaLaterProvider = Provider<Future<void> Function(bool later)>((ref) {
  return (later) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (later) {
      await prefs.setBool(areaLaterKey, true);
    } else {
      await prefs.remove(areaLaterKey);
    }
    ref.invalidate(areaLaterProvider);
  };
});
