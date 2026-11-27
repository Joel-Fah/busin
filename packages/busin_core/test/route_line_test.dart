import 'package:busin_core/busin_core.dart';
import 'package:test/test.dart';

void main() {
  test('a GeoJSON line is read as points, latitude first', () {
    final points = lineFromGeoJson({
      'type': 'LineString',
      'coordinates': [
        [11.5, 3.85],
        [11.502, 3.851],
      ],
    });
    expect(points, [GeoPoint(3.85, 11.5), GeoPoint(3.851, 11.502)]);
  });

  test('the parts of a multi-line are joined; anything else is no line', () {
    expect(
        lineFromGeoJson({
          'type': 'MultiLineString',
          'coordinates': [
            [
              [11.5, 3.85],
              [11.6, 3.86],
            ],
            [
              [11.7, 3.87],
            ],
          ],
        }).length,
        3);
    expect(lineFromGeoJson(null), isEmpty);
    expect(lineFromGeoJson({'type': 'Point', 'coordinates': [11.5, 3.85]}), isEmpty);
    expect(lineFromGeoJson({'type': 'LineString', 'coordinates': [['x', 3.85]]}), isEmpty);
    expect(lineFromGeoJson({'type': 'LineString', 'coordinates': [[11.5, 95.0]]}), isEmpty, reason: 'out of range');
  });

  test('a route row gives the road line and the campus', () {
    final route = RouteLine.fromRow({
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [11.5, 3.85],
          [11.6, 3.86],
        ],
      },
      'campus_lat': 3.87,
      'campus_lng': 11.61,
      'campus_name': 'Main campus',
    });
    expect(route.line, hasLength(2));
    expect(route.campus, GeoPoint(3.87, 11.61));
    expect(route.campusName, 'Main campus');
    expect(route.isEmpty, isFalse);
    expect(RouteLine.fromRow({'geometry': null, 'campus_lat': null, 'campus_lng': null}).isEmpty, isTrue);
  });
}
