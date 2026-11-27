import 'dart:math' as math;

import 'package:busin_core/busin_core.dart';

import 'eta.dart';

/// The point a fraction [t] (0 to 1) of the way from [a] to [b]. Straight between two fixes a few seconds apart, which
/// is what the eye expects from a moving dot.
GeoPoint lerpPoint(GeoPoint a, GeoPoint b, double t) {
  final f = t.clamp(0.0, 1.0);
  return GeoPoint(a.latitude + (b.latitude - a.latitude) * f, a.longitude + (b.longitude - a.longitude) * f);
}

/// A marker moving smoothly from where it is drawn to its newest position, instead of jumping.
///
/// The bus reports every few seconds; gliding over about the time between its last two reports keeps it moving almost
/// all the time, at most one report behind. A long gap (the signal came back) or a far jump (a bad fix corrected) is
/// not glided: the marker goes straight there.
class Glide {
  Glide._(this.from, this.to, this.startedAt, this.duration);

  /// Starts at [to] with nothing to glide.
  Glide.at(GeoPoint to, DateTime now) : this._(to, to, now, Duration.zero);

  final GeoPoint from;
  final GeoPoint to;
  final DateTime startedAt;
  final Duration duration;

  /// The shortest and longest glides.
  static const shortest = Duration(milliseconds: 800);
  static const longest = Duration(seconds: 6);

  /// Further than this between two reports is a jump, not a movement (about 1.5 km).
  static const jumpMetres = 1500.0;

  /// Where to draw the marker at [now].
  GeoPoint at(DateTime now) {
    if (duration == Duration.zero) return to;
    final t = now.difference(startedAt).inMicroseconds / duration.inMicroseconds;
    return t >= 1 ? to : lerpPoint(from, to, _easeOut(t));
  }

  /// Whether the marker is still on its way at [now].
  bool movingAt(DateTime now) => duration > Duration.zero && now.difference(startedAt) < duration;

  /// The next glide: from where the marker is drawn now to [next], over about [sinceLastReport] (the time since the
  /// previous report), or straight there when [reduced] motion is asked for or it is a jump.
  Glide towards(GeoPoint next, {required DateTime now, required Duration sinceLastReport, bool reduced = false}) {
    final here = at(now);
    if (reduced || sinceLastReport > const Duration(seconds: 30) || distanceMetres(here, next) > jumpMetres) return Glide.at(next, now);
    final ms = (sinceLastReport.inMilliseconds * 0.9).round().clamp(shortest.inMilliseconds, longest.inMilliseconds);
    return Glide._(here, next, now, Duration(milliseconds: ms));
  }

  /// Gentle at the end, so the dot settles instead of stopping dead.
  static double _easeOut(double t) => 1 - math.pow(1 - t, 2).toDouble();
}

/// A ring growing out of a marker and fading, like a radar ping. [phase] runs from 0 to 1 over one ping; the ring starts
/// at the marker's [radius] and grows by [spread] while it fades from [opacity] to nothing.
({double radius, double opacity}) pulseAt(double phase, {required double radius, required double spread, double opacity = 0.45}) {
  final p = phase - phase.floorToDouble();
  final grown = 1 - math.pow(1 - p, 3).toDouble();
  return (radius: radius + spread * grown, opacity: opacity * (1 - p));
}
