import 'value_object.dart';

/// A WGS 84 position. Latitude comes first in the constructor; the API and
/// PostGIS put longitude first, which [GeoPoint.fromApi] and [toGeoJson] handle.
class GeoPoint extends ValueObject {
  GeoPoint(this.latitude, this.longitude) {
    if (latitude.isNaN || latitude < -90 || latitude > 90) {
      throw RangeError.range(latitude, -90, 90, 'latitude');
    }
    if (longitude.isNaN || longitude < -180 || longitude > 180) {
      throw RangeError.range(longitude, -180, 180, 'longitude');
    }
  }

  /// Reads what the API returns for a `geography(Point)` column: a GeoJSON
  /// map (`{"type":"Point","coordinates":[lng,lat]}`) or WKT text
  /// (`POINT(lng lat)`, optionally prefixed with `SRID=4326;`).
  factory GeoPoint.fromApi(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final coords = raw['coordinates'];
      if (raw['type'] == 'Point' && coords is List<dynamic> && coords.length >= 2) {
        final lng = coords[0];
        final lat = coords[1];
        if (lng is num && lat is num) {
          return GeoPoint(lat.toDouble(), lng.toDouble());
        }
      }
    } else if (raw is String) {
      final match = RegExp(
        r'^(?:SRID=\d+;)?POINT\s*\(\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s*\)$',
        caseSensitive: false,
      ).firstMatch(raw.trim());
      if (match != null) {
        return GeoPoint(
          double.parse(match.group(2)!),
          double.parse(match.group(1)!),
        );
      }
    }
    throw FormatException('Not a point: $raw');
  }

  final double latitude;
  final double longitude;

  /// GeoJSON for sending to the API.
  Map<String, dynamic> toGeoJson() => {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      };

  @override
  List<Object?> get props => [latitude, longitude];

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}
