import 'package:busin_core/busin_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'maplibre_surface.dart';

/// Everything the map needs to draw, as plain data. The screen builds it; a map surface draws it.
/// Keeping the two apart means the screen is tested with a fake surface (a native map cannot run in a unit test).
class MapScene {
  const MapScene({required this.stops, this.myStopId, this.bus, this.busHeading});

  final List<Stop> stops;
  final String? myStopId;

  /// Where the bus is now, or null while it has not reported.
  final GeoPoint? bus;
  final double? busHeading;

  @override
  bool operator ==(Object other) =>
      other is MapScene &&
      other.myStopId == myStopId &&
      other.bus == bus &&
      other.busHeading == busHeading &&
      other.stops.length == stops.length &&
      Iterable<int>.generate(stops.length).every((i) => other.stops[i] == stops[i]);

  @override
  int get hashCode => Object.hash(myStopId, bus, busHeading, stops.length);
}

/// Draws a [MapScene]. The real one is MapLibre; tests replace it.
/// [recenter] ticks when the student asks to see the bus again; the surface moves the camera to the bus.
typedef MapSurfaceBuilder = Widget Function(BuildContext context, MapScene scene, ValueListenable<int> recenter);

final mapSurfaceBuilderProvider = Provider<MapSurfaceBuilder>((ref) {
  final style = ref.watch(appConfigProvider).mapStyleUrl;
  return (context, scene, recenter) => MapLibreSurface(scene: scene, styleUrl: style, recenter: recenter);
});
