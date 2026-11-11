import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/bus/bus_providers.dart';
import 'package:busin_student/src/bus/my_location.dart';
import 'package:busin_ui/busin_ui.dart';
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
  final me = FakeMyLocation();
}

Future<void> openBus(WidgetTester tester, Rig rig, {Locale locale = const Locale('en'), bool goToBus = true, Size size = const Size(800, 1800)}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = size;
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
        myLocation: rig.me,
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

  testWidgets('the estimated arrival at the student\'s stop is shown from a fresh position, and not from a stale one', (tester) async {
    final rig = Rig(
      active: [activeTrip('t1', 'bus1')],
      backend: FakeBackend(mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.approved)]),
    );
    await openBus(tester, rig);
    expect(find.text('Estimated arrival'), findsNothing, reason: 'nothing to estimate before the bus reports');

    rig.live.emit(position('bus1', 3.86, 11.5, at: noon, speed: 10));
    await tester.pumpAndSettle();
    expect(find.text('3 min'), findsOneWidget);
    expect(find.text('1.4 km'), findsOneWidget);

    rig.live.emit(position('bus1', 3.86, 11.5, at: noon.subtract(const Duration(minutes: 3)), speed: 10));
    await tester.pumpAndSettle();
    expect(find.text('3 min'), findsNothing);
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

  testWidgets('a student without a valid subscription is told, no bus is looked up and the way to subscribe is offered', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    rig.live.canFollow = false;
    await openBus(tester, rig);

    expect(find.text('Following the bus is for subscribers'), findsOneWidget);
    expect(find.byKey(const ValueKey('fake-map')), findsNothing);
    expect(rig.live.subscribed, isEmpty, reason: 'nothing is listened to');
    expect(rig.history.activeLookups, 0, reason: 'not even the running trips are asked for');

    await tester.tap(find.text('Go to subscription'));
    await tester.pumpAndSettle();
    expect(find.text('Following the bus is for subscribers'), findsNothing);
  });

  testWidgets('once the subscription is approved, coming back to the tab shows the bus', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    rig.live.canFollow = false;
    await openBus(tester, rig);
    expect(find.text('Following the bus is for subscribers'), findsOneWidget);

    rig.live.canFollow = true;
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My bus'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fake-map')), findsOneWidget);
  });

  testWidgets('if the check fails it says so and can be retried', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    rig.live.canFollowError = const Offline('down');
    await openBus(tester, rig);
    expect(find.text('Try again'), findsOneWidget);

    rig.live.canFollowError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fake-map')), findsOneWidget);
  });

  testWidgets('the live subscription is dropped while another tab shows and taken up again on return', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    await openBus(tester, rig);
    expect(rig.live.subscribed, ['bus1']);

    await tester.tap(find.text('Profile'));
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

  testWidgets('"Show the bus" appears only when the bus is out of frame', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    await openBus(tester, rig);
    rig.live.emit(position('bus1', 3.85, 11.5, at: noon));
    await tester.pumpAndSettle();
    expect(find.text('Show the bus'), findsOneWidget, reason: 'until the map says the bus is in view');

    rig.map.busInView!.value = true;
    await tester.pumpAndSettle();
    expect(find.text('Show the bus'), findsNothing);

    rig.map.busInView!.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Show the bus'), findsOneWidget);
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

  testWidgets('short updates replace each other, can be hidden, and the end of the trip is said', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    await openBus(tester, rig);

    // Far from every stop: the first position says the bus is followed.
    rig.live.emit(position('bus1', 3.90, 11.5, at: noon, speed: 9));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Following DEMO-101 · Going to school'), findsOneWidget);

    // At the stops: the update is replaced, not added.
    rig.clock.now = noon.add(const Duration(seconds: 40));
    rig.live.emit(position('bus1', 3.85, 11.5, at: rig.clock.now, speed: 1));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('Following'), findsNothing);
    expect(find.textContaining(RegExp(r'^At ')), findsOneWidget);

    // Hidden until the next update.
    await tester.tap(find.byTooltip('Hide this update'));
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'^At ')), findsNothing);

    // The trip ends: noticed at the next check of the running trips (once a minute).
    rig.history.active.clear();
    for (var i = 0; i < 13; i++) {
      await tester.pump(const Duration(seconds: 5));
    }
    await tester.pumpAndSettle();
    expect(find.text('No bus is running right now'), findsOneWidget);
    expect(find.text('The trip of DEMO-101 has ended'), findsOneWidget);
  });

  testWidgets('Show me explains first, then puts the student on the map with the walk to their stop, until hidden', (tester) async {
    final rig = Rig(
      active: [activeTrip('t1', 'bus1')],
      backend: FakeBackend(mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.approved)]),
    );
    await openBus(tester, rig);
    rig.live.emit(position('bus1', 3.86, 11.5, at: noon, speed: 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show me'));
    await tester.pumpAndSettle();
    expect(find.text('See yourself on the map'), findsOneWidget);
    expect(rig.me.requests, 0, reason: 'nothing is asked before the explanation');

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(rig.me.requests, 1);
    expect(rig.me.listeners, 1);

    rig.me.emit(GeoPoint(3.8505, 11.5));
    await tester.pumpAndSettle();
    expect(mapText(tester), contains('me=3.8505,11.5'));
    expect(find.textContaining('min on foot'), findsOneWidget);

    await tester.tap(find.text('Hide me'));
    await tester.pumpAndSettle();
    expect(mapText(tester), isNot(contains('me=')));
    expect(find.textContaining('min on foot'), findsNothing);
    expect(find.text('Show me'), findsOneWidget);
  });

  testWidgets('Show me says so when location is refused, and offers the settings when refused for good', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    rig.me.access = MeAccess.denied;
    await openBus(tester, rig);

    await tester.tap(find.text('Show me'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Location is not allowed for BusIn, so you are not shown.'), findsOneWidget);
    expect(find.text('Show me'), findsOneWidget);
    BusinToast.dismiss();
    await tester.pumpAndSettle();

    rig.me.access = MeAccess.deniedForever;
    await tester.tap(find.text('Show me'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(rig.me.settingsOpened, 1);
    expect(rig.me.listeners, 0, reason: 'never listened without permission');
  });

  test('the walk to the stop is rounded and never under a minute', () {
    final w = walkTo(GeoPoint(3.85, 11.5), GeoPoint(3.8536, 11.5));
    expect(w.metres, closeTo(520, 15));
    expect(w.minutes, 7);
    expect(roughWalk(w.metres), (value: '500', km: false));
    expect(roughWalk(1260), (value: '1.3', km: true));
    expect(walkTo(GeoPoint(3.85, 11.5), GeoPoint(3.85, 11.5)).minutes, 1);
  });

  testWidgets('a wide screen lists the latest updates beside the map, newest first, instead of over it', (tester) async {
    final rig = Rig(active: [activeTrip('t1', 'bus1')]);
    await openBus(tester, rig, size: const Size(1600, 1000));
    expect(find.text('Live updates'), findsOneWidget);
    expect(find.text('What the bus does appears here while you follow it.'), findsOneWidget);

    rig.live.emit(position('bus1', 3.90, 11.5, at: noon, speed: 9));
    await tester.pump();
    await tester.pumpAndSettle();
    rig.clock.now = noon.add(const Duration(seconds: 40));
    rig.live.emit(position('bus1', 3.85, 11.5, at: rig.clock.now, speed: 1));
    await tester.pump();
    await tester.pumpAndSettle();

    final follow = find.text('Following DEMO-101 · Going to school');
    final atStop = find.textContaining(RegExp(r'^At '));
    expect(follow, findsOneWidget, reason: 'the earlier update stays listed');
    expect(atStop, findsOneWidget);
    expect(tester.getTopLeft(atStop).dy, lessThan(tester.getTopLeft(follow).dy), reason: 'newest first');
    expect(find.byTooltip('Hide this update'), findsNothing, reason: 'no strip over the map');
  });
}
