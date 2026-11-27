import 'package:busin_core/busin_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'maplibre_surface.dart';

/// Everything the map needs to draw, as plain data. The screen builds it; a map surface draws it.
/// Keeping the two apart means the screen is tested with a fake surface (a native map cannot run in a unit test).
class MapScene {
  const MapScene({
    required this.stops,
    this.myStopId,
    this.bus,
    this.busHeading,
    this.me,
    this.focusMe = 0,
    this.coveredBottom = 0,
    this.route = const [],
    this.trail = const [],
    this.campus,
    this.campusName,
  });

  final List<Stop> stops;
  final String? myStopId;

  /// Where the bus is now, or null while it has not reported.
  final GeoPoint? bus;
  final double? busHeading;

  /// Where the student is, while they use Show me (ADR 0016); null otherwise.
  final GeoPoint? me;

  /// Grows each time the student asks to see themselves: the map then moves to [me].
  final int focusMe;

  /// How much of the map's bottom edge something floats over (the details card), so the camera frames the bus and the
  /// stop above it. Logical pixels (the map plugin reads its camera padding in them).
  final double coveredBottom;

  /// The school's planned route along roads, first stop to campus; empty when it has not been drawn.
  final List<GeoPoint> route;

  /// Where the bus has been on this trip, oldest first.
  final List<GeoPoint> trail;

  /// The campus, where inbound trips end.
  final GeoPoint? campus;
  final String? campusName;

  @override
  bool operator ==(Object other) =>
      other is MapScene &&
      other.myStopId == myStopId &&
      other.bus == bus &&
      other.busHeading == busHeading &&
      other.me == me &&
      other.focusMe == focusMe &&
      other.coveredBottom == coveredBottom &&
      other.campus == campus &&
      other.campusName == campusName &&
      identical(other.route, route) &&
      other.trail.length == trail.length &&
      (trail.isEmpty || other.trail.last == trail.last) &&
      other.stops.length == stops.length &&
      Iterable<int>.generate(stops.length).every((i) => other.stops[i] == stops[i]);

  @override
  int get hashCode => Object.hash(myStopId, bus, busHeading, me, focusMe, coveredBottom, stops.length, campus, route.length, trail.length);
}

/// Draws a [MapScene]. The real one is MapLibre; tests replace it.
/// [recenter] ticks when the student asks to see the bus again; the surface moves the camera to the bus.
///
/// The surface tells the screen through [busInView] whether the bus is inside the part of the map the student can see
/// (not behind the floating card, not off the edge), so the "Show the bus" button only appears when it is not.
typedef MapSurfaceBuilder = Widget Function(BuildContext context, MapScene scene, ValueListenable<int> recenter, ValueNotifier<bool> busInView);

final mapSurfaceBuilderProvider = Provider<MapSurfaceBuilder>((ref) {
  final config = ref.watch(appConfigProvider);
  return (context, scene, recenter, busInView) =>
      MapLibreSurface(scene: scene, styleUrl: config.mapStyleUrl, darkStyleUrl: config.darkMapStyleUrl, recenter: recenter, busInView: busInView);
});
