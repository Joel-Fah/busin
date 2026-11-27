import 'package:busin_core/busin_core.dart';

/// The map's data as GeoJSON, ready for MapLibre sources. Pure, so the shapes are tested without a native map.

/// GeoJSON wants longitude first.
List<double> lngLat(GeoPoint p) => [p.longitude, p.latitude];

Map<String, dynamic> collection(List<Map<String, dynamic>> features) => {'type': 'FeatureCollection', 'features': features};

Map<String, dynamic> pointFeature(GeoPoint p, [Map<String, dynamic> properties = const {}]) =>
    {'type': 'Feature', 'properties': properties, 'geometry': {'type': 'Point', 'coordinates': lngLat(p)}};

/// The stops, each with its name (the label) and whether it is the student's own (orange instead of grey).
Map<String, dynamic> stopsData(List<Stop> stops, String? myStopId) =>
    collection([for (final s in stops) pointFeature(s.location, {'name': s.name, 'mine': s.id == myStopId})]);

/// One point, or nothing.
Map<String, dynamic> pointData(GeoPoint? p, [Map<String, dynamic> properties = const {}]) => collection([if (p != null) pointFeature(p, properties)]);

/// A line through the points, or nothing when there are fewer than two.
Map<String, dynamic> lineData(List<GeoPoint> points) => collection([
      if (points.length >= 2)
        {
          'type': 'Feature',
          'properties': <String, dynamic>{},
          'geometry': {'type': 'LineString', 'coordinates': [for (final p in points) lngLat(p)]},
        },
    ]);

/// The rings that ping out of the bus and the student's stop; `kind` picks the colour and the size.
Map<String, dynamic> pulseData({GeoPoint? bus, GeoPoint? myStop}) => collection([
      if (myStop != null) pointFeature(myStop, {'kind': 'stop'}),
      if (bus != null) pointFeature(bus, {'kind': 'bus'}),
    ]);
