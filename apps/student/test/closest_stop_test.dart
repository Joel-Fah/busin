import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/subscription/stop_distances.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

// When subscribing, the stops are listed nearest first from the student's area, each with its distance; the nearest is
// pointed out, never chosen. Without an area the school's order stays.

final near = Stop(id: 'near', schoolId: 's1', name: 'Bastos', location: GeoPoint(3.890, 11.510), active: true);
final far = Stop(id: 'far', schoolId: 's1', name: 'Acacias', location: GeoPoint(3.830, 11.490), active: true);
final home = StudentArea(label: 'Home', lat: 3.88, lng: 11.51, source: AreaSource.device, updatedAt: DateTime.utc(2026, 11, 1));

Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> openPicker(WidgetTester tester, {StudentArea? area}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: overridesFor(
      FakeAuthService(signedInAs: 'u1'),
      FakeProfileRepository({'u1': profile()}),
      backend: FakeBackend(current: semester(), stops: [far, near]),
      areas: FakeAreas(area: area),
    ),
    child: const StudentApp(),
  ));
  await settle(tester);
  await tester.tap(find.text('Your stop'));
  await settle(tester, 6);
}

void main() {
  test('distances by road from the area, rounded to 0.1 km, and the nearest pointed out', () {
    final ranked = stopsWithDistance([far, near], GeoPoint(home.lat, home.lng));
    expect(ranked.map((r) => r.stop.id), ['near', 'far'], reason: 'nearest first');
    expect(ranked.first.km, closeTo(1.4, 0.05), reason: '1.1 km in a straight line, times 1.3');
    expect(stopsWithDistance([far, near], null).map((r) => r.stop.id), ['far', 'near'], reason: "without an area, the school's order");
    expect(closestStop(ranked)!.stop.id, 'near');
    expect(closestStop(stopsWithDistance([far, near], null)), isNull);
  });

  test("stops at the same distance keep the school's order", () {
    final twin = Stop(id: 'twin', schoolId: 's1', name: 'Bastos 2', location: GeoPoint(3.890, 11.510), active: true);
    expect(stopsWithDistance([far, twin, near], GeoPoint(home.lat, home.lng)).map((r) => r.stop.id), ['twin', 'near', 'far']);
  });

  testWidgets('with an area, the stops are listed nearest first, each says how far it is; nothing is chosen', (tester) async {
    await openPicker(tester, area: home);
    expect(find.text('Closest to your area'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Bastos')).dy, lessThan(tester.getTopLeft(find.text('Acacias')).dy));
    expect(find.textContaining('km from your area'), findsNWidgets(2));
    // Closing the list chooses nothing.
    await tester.tapAt(const Offset(400, 20));
    await settle(tester, 6);
    expect(find.text('Choose where you board'), findsOneWidget);
  });

  testWidgets('without an area, the list is as before with a way to add one', (tester) async {
    await openPicker(tester);
    expect(find.text('Closest to your area'), findsNothing);
    expect(tester.getTopLeft(find.text('Acacias')).dy, lessThan(tester.getTopLeft(find.text('Bastos')).dy), reason: "the school's order");
    expect(find.textContaining('km from your area'), findsNothing);
    expect(find.text('Add your area to see which stop is closest'), findsOneWidget);
  });
}
