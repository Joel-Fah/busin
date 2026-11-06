import 'dart:math' as math;

import 'package:busin_core/busin_core.dart';

/// How far a bus is from a stop and roughly how long it will take. An estimate, and the screen says so: it uses the
/// straight line (with an allowance for roads) and the bus's own speed when it is moving, otherwise a city average.
class Eta {
  const Eta({required this.minutes, required this.kilometres});

  /// Whole minutes, 0 when the bus is practically at the stop.
  final int minutes;
  final double kilometres;

  bool get arriving => minutes == 0;
}

/// A road is longer than the straight line between two points.
const roadFactor = 1.3;

/// Used when the bus is standing or slower than a walk (a red light must not read as "never").
const cityAverageKmh = 20.0;

/// Below this the bus is taken to be at the stop.
const arrivedWithinMetres = 80.0;

/// Great-circle distance in metres.
double distanceMetres(GeoPoint a, GeoPoint b) {
  const earth = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.latitude - a.latitude);
  final dLon = rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(a.latitude)) * math.cos(rad(b.latitude)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * earth * math.asin(math.min(1, math.sqrt(h.toDouble())));
}

/// The estimate for [bus] reaching [stop], or null if either is unknown. [speedMps] is the bus's speed if reported.
Eta? estimateEta({required GeoPoint? bus, required GeoPoint? stop, double? speedMps}) {
  if (bus == null || stop == null) return null;
  final straight = distanceMetres(bus, stop);
  final road = straight * roadFactor;
  if (straight <= arrivedWithinMetres) return Eta(minutes: 0, kilometres: straight / 1000);
  final moving = speedMps != null && speedMps * 3.6 >= 8;
  final metresPerSecond = moving ? speedMps : cityAverageKmh / 3.6;
  final minutes = (road / metresPerSecond / 60).ceil();
  return Eta(minutes: math.max(1, minutes), kilometres: road / 1000);
}
