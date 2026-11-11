import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/area/area_providers.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

Future<void> settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> openArea(WidgetTester tester, {required FakeAreas areas, FakeLocator? locator}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final profiles = FakeProfileRepository({'u1': profile()});
  await tester.pumpWidget(
    ProviderScope(
      overrides: overridesFor(
        FakeAuthService(signedInAs: 'u1'),
        profiles,
        backend: FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.approved)]),
        areas: areas,
        locator: locator,
      ),
      child: const StudentApp(),
    ),
  );
  await settle(tester, 12);
  BusinToast.dismiss();
  await tester.tap(find.text('Profile'));
  await settle(tester);
  await tester.scrollUntilVisible(find.text('My area'), 300, scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text('My area'));
  await settle(tester);
}

void main() {
  test('a point is rounded on the phone before it is sent', () {
    final point = roundForArea(3.86437, 11.51892);
    expect(point.lat, 3.86);
    expect(point.lng, 11.52);
  });

  testWidgets('at home: the app explains, reads once, and saves a named area', (tester) async {
    final areas = FakeAreas();
    final locator = FakeLocator(const Located(3.8643, 11.5189));
    await openArea(tester, areas: areas, locator: locator);
    expect(find.text('Are you home right now?'), findsOneWidget);
    expect(locator.reads, 0, reason: 'nothing is read before the student asks');

    await tester.tap(find.text('Yes, I am home'));
    await settle(tester);
    expect(find.text('One reading, roughly'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(locator.reads, 1);

    await tester.enterText(find.byType(TextField), 'Bastos');
    await tester.tap(find.text('Save my area'));
    await settle(tester);
    expect(areas.saved.single.label, 'Bastos');
    expect(areas.saved.single.source, AreaSource.device);
    expect(find.text('Remove my area'), findsOneWidget);
  });

  testWidgets('a refused permission reads nothing and says so', (tester) async {
    final areas = FakeAreas();
    await openArea(tester, areas: areas, locator: FakeLocator(const LocationDenied(forever: false)));
    await tester.tap(find.text('Yes, I am home'));
    await settle(tester);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.textContaining('cannot read your location'), findsOneWidget);
    expect(areas.saved, isEmpty);
    BusinToast.dismiss();
    await settle(tester);
  });

  testWidgets('not at home: search, pick a place, and it is saved', (tester) async {
    final areas = FakeAreas(places: const [PlaceResult(label: 'Etoudi', kind: PlaceKind.area, lat: 3.91, lng: 11.53)]);
    await openArea(tester, areas: areas);
    await tester.tap(find.text('No, search a place'));
    await settle(tester);
    expect(find.text('Not seeing your street?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Etou');
    await settle(tester, 4);
    expect(areas.queries, ['Etou']);
    expect(find.text('Neighbourhood'), findsOneWidget);
    expect(find.text('Places from OpenStreetMap contributors'), findsOneWidget);
    await tester.tap(find.text('Etoudi'));
    await settle(tester);
    expect(areas.saved.single.source, AreaSource.search);
    expect(areas.saved.single.label, 'Etoudi');
  });

  testWidgets('a place too far from the buses is refused with a reason', (tester) async {
    final areas = FakeAreas(places: const [PlaceResult(label: 'Paris', kind: PlaceKind.area, lat: 48.85, lng: 2.35)])
      ..saveError = const Invalid('database 22023');
    await openArea(tester, areas: areas);
    await tester.tap(find.text('No, search a place'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Pari');
    await settle(tester, 4);
    await tester.tap(find.text('Paris'));
    await settle(tester);
    expect(find.text("This place is too far from your school's buses."), findsOneWidget);
    BusinToast.dismiss();
    await settle(tester);
  });

  testWidgets('"Not seeing your street?" leaves a note on the profile', (tester) async {
    await openArea(tester, areas: FakeAreas());
    await tester.tap(find.text('No, search a place'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Remind me at home'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Remind me at home'));
    await settle(tester);
    expect(find.text('Add it when you are home.'), findsOneWidget);
  });

  testWidgets('a saved area can be removed', (tester) async {
    final areas = FakeAreas(
      area: StudentArea(label: 'Bastos', lat: 3.86, lng: 11.52, source: AreaSource.device, updatedAt: DateTime.utc(2026, 11, 1)),
    );
    await openArea(tester, areas: areas);
    expect(find.text('Bastos'), findsOneWidget);
    await tester.tap(find.text('Remove my area'));
    await settle(tester);
    expect(areas.area, isNull);
    expect(find.text('Are you home right now?'), findsOneWidget);
    BusinToast.dismiss();
    await settle(tester);
  });
}
