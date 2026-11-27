import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/bus/map_layers.dart';
import 'package:busin_student/src/bus/map_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 27, 7);
  final a = GeoPoint(3.85, 11.50);
  final b = GeoPoint(3.851, 11.501);

  group('gliding between positions', () {
    test('a new position is reached over about the time since the last one, not at once', () {
      final glide = Glide.at(a, t0).towards(b, now: t0, sinceLastReport: const Duration(seconds: 3));
      expect(glide.duration, const Duration(milliseconds: 2700));
      expect(glide.at(t0), a);
      final half = glide.at(t0.add(const Duration(milliseconds: 1350)));
      expect(half.latitude, greaterThan(a.latitude));
      expect(half.latitude, lessThan(b.latitude));
      expect(glide.at(t0.add(const Duration(seconds: 3))), b);
      expect(glide.movingAt(t0.add(const Duration(seconds: 1))), isTrue);
      expect(glide.movingAt(t0.add(const Duration(seconds: 3))), isFalse);
    });

    test('a position arriving mid-glide starts from where the marker is drawn', () {
      final first = Glide.at(a, t0).towards(b, now: t0, sinceLastReport: const Duration(seconds: 4));
      final mid = t0.add(const Duration(seconds: 1));
      final next = first.towards(GeoPoint(3.852, 11.502), now: mid, sinceLastReport: const Duration(seconds: 1));
      expect(next.from, first.at(mid));
    });

    test('glides stay between the shortest and longest', () {
      expect(Glide.at(a, t0).towards(b, now: t0, sinceLastReport: const Duration(milliseconds: 100)).duration, Glide.shortest);
      expect(Glide.at(a, t0).towards(b, now: t0, sinceLastReport: const Duration(seconds: 20)).duration, Glide.longest);
    });

    test('a jump, a long silence or reduced motion goes straight there', () {
      final far = GeoPoint(3.90, 11.60);
      expect(Glide.at(a, t0).towards(far, now: t0, sinceLastReport: const Duration(seconds: 3)).at(t0), far, reason: 'over 1.5 km');
      expect(Glide.at(a, t0).towards(b, now: t0, sinceLastReport: const Duration(minutes: 2)).at(t0), b, reason: 'the signal came back');
      expect(Glide.at(a, t0).towards(b, now: t0, sinceLastReport: const Duration(seconds: 3), reduced: true).at(t0), b);
    });
  });

  test('a ping grows from the marker and fades out, then starts again', () {
    final start = pulseAt(0, radius: 9, spread: 14);
    final end = pulseAt(0.999, radius: 9, spread: 14);
    expect(start.radius, 9);
    expect(start.opacity, closeTo(0.45, 0.001));
    expect(end.radius, closeTo(23, 0.01));
    expect(end.opacity, closeTo(0, 0.001));
    expect(pulseAt(1.25, radius: 9, spread: 14).radius, pulseAt(0.25, radius: 9, spread: 14).radius);
  });

  group('the map data', () {
    final stops = [
      Stop(id: 's1', schoolId: 'sc', name: 'Poste Centrale', location: a, active: true),
      Stop(id: 's2', schoolId: 'sc', name: 'Carrefour Vogt', location: b, active: true),
    ];

    test('stops carry their name and whether they are the student\'s own, longitude first', () {
      final data = stopsData(stops, 's2');
      final features = data['features'] as List;
      expect(features, hasLength(2));
      expect(features[0]['properties'], {'name': 'Poste Centrale', 'mine': false});
      expect(features[1]['properties'], {'name': 'Carrefour Vogt', 'mine': true});
      expect(features[0]['geometry']['coordinates'], [11.50, 3.85]);
    });

    test('a line needs two points; nothing is drawn otherwise', () {
      expect((lineData([a, b])['features'] as List).single['geometry']['type'], 'LineString');
      expect(lineData([a])['features'], isEmpty);
      expect(pointData(null)['features'], isEmpty);
    });

    test('the rings follow the bus and the student\'s stop', () {
      final kinds = [for (final f in pulseData(bus: a, myStop: b)['features'] as List) f['properties']['kind']];
      expect(kinds, ['stop', 'bus']);
      expect(pulseData()['features'], isEmpty);
    });
  });
}
