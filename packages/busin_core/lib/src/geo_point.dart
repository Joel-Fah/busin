import 'dart:typed_data';

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

  /// Reads what the API returns for a `geography(Point)` column.
  ///
  /// PostgREST returns the hex-encoded binary form (EWKB), for example
  /// `0101000020E6100000...`. A GeoJSON map
  /// (`{"type":"Point","coordinates":[lng,lat]}`) and WKT text
  /// (`POINT(lng lat)`, optionally prefixed with `SRID=4326;`) are accepted too.
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
      final fromHex = _fromEwkbHex(raw.trim());
      if (fromHex != null) return fromHex;
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

  /// Parses a hex-encoded EWKB point. Returns null when the text is not hex or not a point,
  /// so the caller can try other formats. Throws [FormatException] for a point that is
  /// truncated or not in WGS 84 (SRID 4326).
  static GeoPoint? _fromEwkbHex(String text) {
    if (text.length < 42 || text.length.isOdd || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(text)) {
      return null;
    }
    final bytes = Uint8List(text.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(text.substring(i * 2, i * 2 + 2), radix: 16);
    }
    final data = ByteData.sublistView(bytes);

    final byteOrder = data.getUint8(0);
    if (byteOrder > 1) return null;
    final endian = byteOrder == 1 ? Endian.little : Endian.big;

    final type = data.getUint32(1, endian);
    const sridFlag = 0x20000000;
    const zFlag = 0x80000000;
    const mFlag = 0x40000000;
    if ((type & 0xFF) != 1) return null; // not a point

    var offset = 5;
    if (type & sridFlag != 0) {
      if (bytes.length < offset + 4) throw FormatException('Truncated point: $text');
      final srid = data.getUint32(offset, endian);
      if (srid != 4326) throw FormatException('Unsupported SRID $srid, expected 4326');
      offset += 4;
    }

    final ordinates = 2 + (type & zFlag != 0 ? 1 : 0) + (type & mFlag != 0 ? 1 : 0);
    if (bytes.length < offset + ordinates * 8) throw FormatException('Truncated point: $text');
    final longitude = data.getFloat64(offset, endian);
    final latitude = data.getFloat64(offset + 8, endian);
    return GeoPoint(latitude, longitude);
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
