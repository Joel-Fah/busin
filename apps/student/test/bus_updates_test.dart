import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/bus/bus_updates.dart';
import 'package:flutter_test/flutter_test.dart';

final t0 = DateTime.utc(2026, 11, 11, 7);

// Along a north-south road: 0.0009 degrees of latitude is about 100 m.
GeoPoint north(double metres) => GeoPoint(3.80 + metres / 100 * 0.0009, 11.50);

Stop stop(String id, String name, double atMetres, {bool active = true}) =>
    Stop(id: id, schoolId: 's', name: name, location: north(atMetres), active: active);

LivePosition at(double metres, int seconds, {double? speed, String trip = 't1'}) => LivePosition(
      busId: 'b1',
      schoolId: 's',
      tripId: trip,
      location: north(metres),
      speedMps: speed,
      source: PositionSource.phone,
      recordedAt: t0.add(Duration(seconds: seconds)),
    );

/// Feeds positions and returns the kinds said, in order.
List<BusUpdateKind> run(BusUpdateDetector d, List<LivePosition> positions) => [
      for (final p in positions) ?d.onPosition(p, p.recordedAt)?.kind,
    ];

void main() {
  final a = stop('a', 'Alpha', 1000);
  final mine = stop('m', 'Mine', 3000);
  final closed = stop('x', 'Closed', 2000, active: false);

  test('the first position says the bus is followed', () {
    final d = BusUpdateDetector(stops: [a, mine]);
    expect(d.onPosition(at(0, 0, speed: 8), t0)?.kind, BusUpdateKind.following);
    expect(d.onPosition(at(80, 10, speed: 8), t0.add(const Duration(seconds: 10))), isNull, reason: 'nothing new');
  });

  test('arriving at a stop and leaving it, by name; inactive stops are ignored', () {
    final d = BusUpdateDetector(stops: [a, mine, closed]);
    final said = <BusUpdate>[];
    for (final p in [at(0, 0, speed: 8), at(960, 120, speed: 2), at(1010, 130, speed: 0), at(1200, 160, speed: 8), at(2000, 260, speed: 8)]) {
      final u = d.onPosition(p, p.recordedAt);
      if (u != null) said.add(u);
    }
    expect([for (final u in said) (u.kind, u.stopName)], [
      (BusUpdateKind.following, null),
      (BusUpdateKind.atStop, 'Alpha'),
      (BusUpdateKind.leftStop, 'Alpha'),
    ]);
  });

  test('standing still away from a stop for 90 s says stopped, then moving again', () {
    final d = BusUpdateDetector(stops: [a]);
    final kinds = run(d, [
      at(0, 0, speed: 8),
      at(500, 60, speed: 0),
      at(505, 100, speed: 0.3),
      at(510, 150, speed: 0), // 90 s after it stood still at 60
      at(512, 170, speed: 0),
      at(600, 190, speed: 6),
    ]);
    expect(kinds, [BusUpdateKind.following, BusUpdateKind.stopped, BusUpdateKind.moving]);
  });

  test('standing at a stop is normal and says nothing more', () {
    final d = BusUpdateDetector(stops: [a]);
    final kinds = run(d, [at(0, 0, speed: 8), at(1000, 100, speed: 0), at(1002, 200, speed: 0), at(1003, 300, speed: 0)]);
    expect(kinds, [BusUpdateKind.following, BusUpdateKind.atStop]);
  });

  test('near my stop once per trip, then at it, then passed it', () {
    final d = BusUpdateDetector(stops: [a, mine], myStop: mine);
    final said = <BusUpdate>[];
    for (final p in [
      at(1500, 0, speed: 10), // 1.5 km at 36 km/h: more than 3 min
      at(2500, 60, speed: 10), // 500 m (650 m by road): about 2 min
      at(2600, 70, speed: 10),
      at(2990, 110, speed: 2),
      at(3200, 140, speed: 8),
      at(3400, 160, speed: 8),
    ]) {
      final u = d.onPosition(p, p.recordedAt);
      if (u != null) said.add(u);
    }
    expect([for (final u in said) u.kind], [
      BusUpdateKind.following,
      BusUpdateKind.nearMyStop,
      BusUpdateKind.atStop,
      BusUpdateKind.passedMyStop,
    ]);
    expect(said[1].minutes, lessThanOrEqualTo(3));
  });

  test('no position for 2 minutes says no signal once, and the next position says it is back', () {
    final d = BusUpdateDetector(stops: [a]);
    d.onPosition(at(0, 0, speed: 8), t0);
    expect(d.onTick(t0.add(const Duration(seconds: 100))), isNull);
    final lost = d.onTick(t0.add(const Duration(minutes: 3)));
    expect(lost?.kind, BusUpdateKind.signalLost);
    expect(lost?.since, t0);
    expect(d.onTick(t0.add(const Duration(minutes: 4))), isNull, reason: 'said once');
    expect(d.onPosition(at(300, 250, speed: 8), t0.add(const Duration(seconds: 250)))?.kind, BusUpdateKind.signalBack);
  });

  test('a new trip starts over, and an old or repeated position is ignored', () {
    final d = BusUpdateDetector(stops: [a]);
    expect(d.onPosition(at(0, 0, speed: 8), t0)?.kind, BusUpdateKind.following);
    expect(d.onPosition(at(0, 0, speed: 8), t0), isNull);
    expect(d.onPosition(at(10, 20, speed: 8, trip: 't2'), t0.add(const Duration(seconds: 20)))?.kind, BusUpdateKind.following);
  });

  test('every update has a new number, and the end of the trip is said', () {
    final d = BusUpdateDetector(stops: [a]);
    final first = d.onPosition(at(0, 0, speed: 8), t0)!;
    final end = d.onTripEnded(t0.add(const Duration(minutes: 1)));
    expect(end.kind, BusUpdateKind.tripEnded);
    expect(end.seq, greaterThan(first.seq));
  });
}
