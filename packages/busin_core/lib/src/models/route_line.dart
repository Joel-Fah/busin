import '../geo_point.dart';

/// The school's bus route as the student's map draws it: the road line from the first stop to the campus, and the
/// campus itself. Either can be missing (no route drawn yet, no campus set).
class RouteLine {
  const RouteLine({this.line = const [], this.campus, this.campusName});

  /// The road geometry, in order. Empty when the route has not been drawn along roads.
  final List<GeoPoint> line;
  final GeoPoint? campus;
  final String? campusName;

  bool get isEmpty => line.length < 2 && campus == null;

  /// Reads a row of `school_route()`: a GeoJSON LineString in `geometry`, the campus in `campus_lat`/`campus_lng`.
  factory RouteLine.fromRow(Map<String, dynamic> row) {
    final lat = row['campus_lat'];
    final lng = row['campus_lng'];
    return RouteLine(
      line: lineFromGeoJson(row['geometry']),
      campus: lat is num && lng is num ? GeoPoint(lat.toDouble(), lng.toDouble()) : null,
      campusName: row['campus_name'] as String?,
    );
  }
}

/// The points of a GeoJSON LineString (`{"type": "LineString", "coordinates": [[lng, lat], ...]}`), or of every part of
/// a MultiLineString joined. Anything else, or a point out of range, gives an empty list: the map then draws no line.
List<GeoPoint> lineFromGeoJson(Object? json) {
  if (json is! Map) return const [];
  final type = json['type'];
  final coordinates = json['coordinates'];
  if (coordinates is! List) return const [];
  final parts = switch (type) {
    'LineString' => [coordinates],
    'MultiLineString' => coordinates,
    _ => const <Object?>[],
  };
  final points = <GeoPoint>[];
  try {
    for (final part in parts) {
      if (part is! List) return const [];
      for (final c in part) {
        if (c is! List || c.length < 2 || c[0] is! num || c[1] is! num) return const [];
        points.add(GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()));
      }
    }
  } on RangeError {
    return const [];
  }
  return points;
}
