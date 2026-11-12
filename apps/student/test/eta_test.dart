import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/bus/eta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final yaounde = GeoPoint(3.848, 11.5021);

  test('the distance between two points is about right', () {
    // One degree of latitude is about 111 km.
    expect(distanceMetres(GeoPoint(0, 0), GeoPoint(1, 0)), closeTo(111195, 300));
    expect(distanceMetres(yaounde, yaounde), 0);
  });

  test('unknown places have no estimate', () {
    expect(estimateEta(bus: null, stop: yaounde), isNull);
    expect(estimateEta(bus: yaounde, stop: null), isNull);
  });

  test('a bus at the stop is arriving', () {
    final eta = estimateEta(bus: yaounde, stop: GeoPoint(3.8484, 11.5021))!;
    expect(eta.arriving, isTrue);
  });

  test('a moving bus uses its own speed, with the road allowance', () {
    // About 5.56 km straight north; 7.2 km by road at 36 km/h is 12 minutes.
    final stop = GeoPoint(3.848 + 5.56 / 111.195, 11.5021);
    final eta = estimateEta(bus: yaounde, stop: stop, speedMps: 10)!;
    expect(eta.minutes, closeTo(12, 1));
    expect(eta.kilometres, closeTo(7.2, 0.2));
  });

  test('a standing or crawling bus uses the city average, never infinity', () {
    final stop = GeoPoint(3.848 + 5.56 / 111.195, 11.5021);
    final standing = estimateEta(bus: yaounde, stop: stop, speedMps: 0)!;
    final unknown = estimateEta(bus: yaounde, stop: stop)!;
    final crawling = estimateEta(bus: yaounde, stop: stop, speedMps: 1)!;
    expect(standing.minutes, unknown.minutes);
    expect(crawling.minutes, unknown.minutes);
    expect(unknown.minutes, closeTo(22, 1));
  });

  test('never less than a minute unless it has arrived', () {
    final eta = estimateEta(bus: yaounde, stop: GeoPoint(3.8495, 11.5021), speedMps: 20)!;
    expect(eta.minutes, greaterThanOrEqualTo(1));
  });
}
