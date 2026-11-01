import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

/// Builds the hex form of a point the way PostGIS writes it.
String ewkbHex({
  required double lng,
  required double lat,
  Endian endian = Endian.little,
  int? srid = 4326,
  bool withZ = false,
  int baseType = 1,
}) {
  var type = baseType;
  if (srid != null) type |= 0x20000000;
  if (withZ) type |= 0x80000000;

  final data = ByteData(1 + 4 + (srid != null ? 4 : 0) + 8 * (withZ ? 3 : 2));
  var offset = 0;
  data.setUint8(offset++, endian == Endian.little ? 1 : 0);
  data.setUint32(offset, type, endian);
  offset += 4;
  if (srid != null) {
    data.setUint32(offset, srid, endian);
    offset += 4;
  }
  data.setFloat64(offset, lng, endian);
  offset += 8;
  data.setFloat64(offset, lat, endian);
  offset += 8;
  if (withZ) data.setFloat64(offset, 12.5, endian);

  return [
    for (final b in data.buffer.asUint8List()) b.toRadixString(16).padLeft(2, '0'),
  ].join().toUpperCase();
}

void main() {
  group('GeoPoint.fromApi with the binary form PostgREST returns', () {
    test('reads real values returned by the local backend', () {
      // Seed stop "Sample stop A": st_point(11.5021, 3.8480).
      final seed = GeoPoint.fromApi('0101000020E6100000A9A44E401301274062105839B4C80E40');
      expect(seed.longitude, 11.5021);
      expect(seed.latitude, 3.848);

      // A point inserted as SRID=4326;POINT(11.51 3.86).
      final probe = GeoPoint.fromApi('0101000020E610000085EB51B81E052740E17A14AE47E10E40');
      expect(probe.longitude, closeTo(11.51, 1e-9));
      expect(probe.latitude, closeTo(3.86, 1e-9));
    });

    test('reads either byte order, with or without the SRID flag', () {
      for (final endian in [Endian.little, Endian.big]) {
        for (final srid in [4326, null]) {
          final p = GeoPoint.fromApi(ewkbHex(lng: -122.4194, lat: 37.7749, endian: endian, srid: srid));
          expect(p, GeoPoint(37.7749, -122.4194), reason: '$endian srid=$srid');
        }
      }
    });

    test('ignores a Z ordinate and accepts lower case hex', () {
      final hex = ewkbHex(lng: 11.5, lat: 3.85, withZ: true);
      expect(GeoPoint.fromApi(hex), GeoPoint(3.85, 11.5));
      expect(GeoPoint.fromApi(hex.toLowerCase()), GeoPoint(3.85, 11.5));
    });

    test('refuses a point that is not in WGS 84', () {
      expect(
        () => GeoPoint.fromApi(ewkbHex(lng: 11.5, lat: 3.85, srid: 3857)),
        throwsFormatException,
      );
    });

    test('refuses truncated data', () {
      final full = ewkbHex(lng: 11.5, lat: 3.85);
      expect(() => GeoPoint.fromApi(full.substring(0, full.length - 2)), throwsFormatException);
    });

    test('refuses shapes that are not points and out of range values', () {
      // Type 2 is a line string; the parser does not guess, so it falls through to an error.
      expect(() => GeoPoint.fromApi(ewkbHex(lng: 1, lat: 1, baseType: 2)), throwsFormatException);
      expect(() => GeoPoint.fromApi(ewkbHex(lng: 200, lat: 3.85)), throwsRangeError);
      expect(() => GeoPoint.fromApi('zz'), throwsFormatException);
    });

    test('still reads GeoJSON and WKT', () {
      expect(
        GeoPoint.fromApi({'type': 'Point', 'coordinates': [11.5, 3.85]}),
        GeoPoint(3.85, 11.5),
      );
      expect(GeoPoint.fromApi('SRID=4326;POINT(11.5 3.85)'), GeoPoint(3.85, 11.5));
    });
  });
}
