import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/bus/bus_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

final noon = DateTime.utc(2026, 11, 5, 12);

class Rig {
  Rig({List<Trip>? active, FakeBackend? backend, FakeHistory? history})
      : history = (history ?? FakeHistory())..active.addAll(active ?? []),
        backend = backend ?? FakeBackend();

  final FakeHistory history;
  final FakeBackend backend;
  final live = FakeLive();
  final map = FakeMapSurface();
  final clock = TestClock(noon);
}

Future<void> openBus(WidgetTester tester, Rig rig, {Locale locale = const Locale('en'), bool goToBus = true}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(
        FakeAuthService(signedInAs: 'u1'),
        FakeProfileRepository({'u1': profile()}),
        history: rig.history,
        backend: rig.backend,
        live: rig.live,
        map: rig.map,
        clock: rig.clock,
      ),
      child: const StudentApp(),
    ),
  );
  await tester.pumpAndSettle();
  if (goToBus) {
    await tester.tap(find.text(locale.languageCode == 'fr' ? 'Mon bus' : 'My bus'));
    await tester.pumpAndSettle();
  }
}

String mapText(WidgetTester tester) => tester.widget<Text>(find.descendant(of: find.byKey(const ValueKey('fake-map')), matching: find.byType(Text))).data!;

void main() {
  group('helpers', () {
    final p = position('bus1', 3.85, 11.5, at: noon);
    test('age is never negative', () {
      expect(positionAge(p, noon.add(const Duration(seconds: 30))), const Duration(seconds: 30));
      expect(positionAge(p, noon.subtract(const Duration(seconds: 5))), Duration.zero);
    });
    test('a position is stale after two minutes', () {
      expect(isStale(const Duration(seconds: 119)), isFalse);
      expect(isStale(const Duration(minutes: 2)), isTrue);
    });
    test('speed is whole km/h, and nothing when unknown or standing', () {
      expect(speedKmh(10), 36);
      expect(speedKmh(null), isNull);
      expect(speedKmh(0), isNull);
      expect(speedKmh(0.1), isNull);
    });
  });

  testWidgets('with no trip running it says so and listens to nothing', (tester) async {
    final rig = Rig();
    await openBus(tester, rig);
    expect(find.text('No bus is running right now'), findsOneWidget);
    expect(rig.live.subscribed, isEmpty);
  });

  testWidgets('a running bus with no position yet shows the stops and says it is waiting', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    await openBus(tester, rig);

    expect(find.text('DEMO-101'), findsOneWidget);
    expect(find.text('Waiting for the bus to share its location.'), findsOneWidget);
    expect(mapText(tester), 'map stops=3 mine=- bus=-');
    expect(find.text('Show the bus'), findsNothing);
    expect(rig.live.subscribed, ['bus1']);
  });

  testWidgets('a position puts the bus on the map with its age and speed, and follows it as it moves', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    await openBus(tester, rig);

    rig.live.emit(position('bus1', 3.85, 11.5, at: noon.subtract(const Duration(seconds: 12)), speed: 10));
    await tester.pumpAndSettle();
    expect(mapText(tester), 'map stops=3 mine=- bus=3.85,11.5');
    expect(find.textContaining('Updated 12 s ago'), findsOneWidget);
    expect(find.textContaining('36 km/h'), findsOneWidget);
    expect(find.text('Waiting for the bus to share its location.'), findsNothing);
    expect(find.text('Show the bus'), findsOneWidget);

    rig.live.emit(position('bus1', 3.86, 11.51, at: noon, speed: 5));
    await tester.pumpAndSettle();
    expect(mapText(tester), 'map stops=3 mine=- bus=3.86,11.51');
    expect(find.textContaining('18 km/h'), findsOneWidget);
  });

  testWidgets('a position that has gone quiet is marked as stale, not shown as fresh', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    await openBus(tester, rig);
    rig.live.emit(position('bus1', 3.85, 11.5, at: noon.subtract(const Duration(minutes: 3))));
    await tester.pumpAndSettle();

    expect(find.text('Last seen 3 min ago. The bus may be out of signal.'), findsOneWidget);
    expect(find.textContaining('Updated'), findsNothing);
  });

  testWidgets('the student\'s own stop is marked and named', (tester) async {
    final rig = Rig(
      active: [activeTrip('t1', 'bus1')],
      backend: FakeBackend(mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.approved)]),
    );
    await openBus(tester, rig);
    expect(mapText(tester), contains('mine=stop2'));
    expect(find.text('Your stop: Mvan'), findsOneWidget);
  });

  testWidgets('with several buses the one the student last boarded is shown first, and only that one is listened to', (tester) async {
    final rig = Rig(
      active: [activeTrip('t1', 'bus1', direction: TripDirection.inbound), activeTrip('t2', 'bus2', direction: TripDirection.outbound)],
      history: FakeHistory(scans: [scan(1, at: noon.subtract(const Duration(hours: 1)), tripId: 't2')]),
    );
    await openBus(tester, rig);

    expect(find.text('DEMO-101 · Going to school'), findsOneWidget, reason: 'a chip for each bus');
    expect(find.text('DEMO-102 · Going home'), findsOneWidget);
    expect(rig.live.subscribed, ['bus2'], reason: 'the bus of the last boarding, not all of them');
  });

  testWidgets('without a boarding the most recently started bus is shown', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1'), activeTrip('t2', 'bus2')]);
    await openBus(tester, rig);
    expect(rig.live.subscribed, ['bus1']);
  });

  testWidgets('choosing another bus listens to that one and lets go of the first', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1'), activeTrip('t2', 'bus2', direction: TripDirection.outbound)]);
    await openBus(tester, rig);
    expect(rig.live.subscribed, ['bus1']);

    await tester.tap(find.text('DEMO-102 · Going home'));
    await tester.pumpAndSettle();
    expect(rig.live.subscribed, ['bus1', 'bus2']);
    expect(rig.live.cancelled, contains('bus1'));
  });

  testWidgets('the live subscription is dropped while another tab shows and taken up again on return', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    await openBus(tester, rig);
    expect(rig.live.subscribed, ['bus1']);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(rig.live.cancelled, ['bus1'], reason: 'nothing is listening in the background');

    final lookups = rig.history.activeLookups;
    await tester.tap(find.text('My bus'));
    await tester.pumpAndSettle();
    expect(rig.live.subscribed, ['bus1', 'bus1']);
    expect(rig.history.activeLookups, greaterThan(lookups), reason: 'the running trips are checked again');
  });

  testWidgets('a failed live feed says so and can be retried', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    await openBus(tester, rig);
    rig.live.fail('bus1', Exception('realtime down'));
    await tester.pumpAndSettle();

    expect(find.text('Live updates are not available right now.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(rig.live.subscribed, ['bus1', 'bus1']);

    rig.live.emit(position('bus1', 3.85, 11.5, at: noon));
    await tester.pumpAndSettle();
    expect(find.text('Live updates are not available right now.'), findsNothing);
  });

  testWidgets('"Show the bus" asks the map to look at the bus again', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    await openBus(tester, rig);
    rig.live.emit(position('bus1', 3.85, 11.5, at: noon));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show the bus'));
    await tester.pumpAndSettle();
    expect(rig.map.recenters, 1);
  });

  testWidgets('a failed trip lookup explains and can retry', (tester) async {
    final rig = Rig()..history.activeError = const Offline('down');
    await openBus(tester, rig);
    expect(find.text('No connection. Check your network and try again.'), findsOneWidget);

    rig.history.activeError = null;
    rig.history.active.add(activeTrip('t1', 'bus1'));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('DEMO-101'), findsOneWidget);
  });

  testWidgets('speaks French', (tester) async {
    await openBus(tester, Rig(), locale: const Locale('fr'));
    expect(find.text('Aucun bus n’est en service pour le moment'), findsOneWidget);
  });
}
