import 'package:busin_core/busin_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

import 'eta.dart';

/// The answer when Show me asks for the phone's position (ADR 0016).
enum MeAccess { granted, approximate, denied, deniedForever, off }

/// The phone's own position, for Show me on My bus. Precise when the student allows it; only ever read while the tab is
/// showing, never sent anywhere (ADR 0016).
abstract interface class MyLocationFeed {
  /// Asks for permission if needed (the explanation was shown before) and says what the student allowed.
  Future<MeAccess> request();

  /// Positions while listened to; stops when the subscription is cancelled.
  Stream<GeoPoint> watch();

  Future<void> openSettings();
}

class DeviceMyLocationFeed implements MyLocationFeed {
  GeolocatorPlatform get _geo => GeolocatorPlatform.instance;

  @override
  Future<MeAccess> request() async {
    try {
      if (!await _geo.isLocationServiceEnabled()) return MeAccess.off;
      var permission = await _geo.checkPermission();
      if (permission == LocationPermission.denied) permission = await _geo.requestPermission();
      if (permission == LocationPermission.denied) return MeAccess.denied;
      if (permission == LocationPermission.deniedForever) return MeAccess.deniedForever;
      final accuracy = await _geo.getLocationAccuracy();
      return accuracy == LocationAccuracyStatus.reduced ? MeAccess.approximate : MeAccess.granted;
    } on Object {
      return MeAccess.denied;
    }
  }

  @override
  Stream<GeoPoint> watch() => _geo
      .getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10))
      .map((p) => GeoPoint(p.latitude, p.longitude));

  @override
  Future<void> openSettings() async {
    await _geo.openAppSettings();
  }
}

final myLocationFeedProvider = Provider<MyLocationFeed>((ref) => DeviceMyLocationFeed());

/// Whether the student turned Show me on, and what the phone allowed. Kept until the app closes (not saved).
class ShowMe extends Notifier<MeAccess?> {
  @override
  MeAccess? build() => null;

  /// Turns Show me on: asks the phone, and stays on only if some position is allowed.
  Future<MeAccess> turnOn() async {
    final access = await ref.read(myLocationFeedProvider).request();
    state = access == MeAccess.granted || access == MeAccess.approximate ? access : null;
    return access;
  }

  void turnOff() => state = null;
}

final showMeProvider = NotifierProvider<ShowMe, MeAccess?>(ShowMe.new);

/// The student's position while Show me is on. Watched only while My bus is on screen, so leaving the tab stops it.
final myPositionProvider = StreamProvider.autoDispose<GeoPoint>((ref) {
  if (ref.watch(showMeProvider) == null) return const Stream.empty();
  return ref.watch(myLocationFeedProvider).watch();
});

/// A brisk walk, and the same allowance for streets as the bus estimate.
const walkingKmh = 4.8;

/// Metres to walk to [stop] from [me] (straight line with the road allowance) and about how many minutes, at least 1.
({double metres, int minutes}) walkTo(GeoPoint me, GeoPoint stop) {
  final metres = distanceMetres(me, stop) * roadFactor;
  final minutes = (metres / (walkingKmh * 1000 / 60)).ceil();
  return (metres: metres, minutes: minutes < 1 ? 1 : minutes);
}

/// "400 m" to the nearest 50 under a kilometre, then "1.2 km" (the decimal mark is the screen's business).
({String value, bool km}) roughWalk(double metres) {
  if (metres < 975) return (value: '${((metres / 50).round() * 50).clamp(50, 950)}', km: false);
  return (value: (metres / 1000).toStringAsFixed(1), km: true);
}
