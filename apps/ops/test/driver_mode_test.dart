import 'package:busin_core/busin_core.dart';
import 'package:busin_ops/src/app.dart';
import 'package:busin_ops/src/drive/position_publisher.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

({GeoPoint point, double accuracy, double? speed, double? heading}) at(double lat) => (point: GeoPoint(lat, 11.5), accuracy: 8.0, speed: 6.0, heading: 90.0);

void main() {
  group('the position publisher', () {
    test('sends at most every 10 seconds', () async {
      var clock = DateTime.utc(2026, 11, 12, 6);
      final live = FakeLive();
      final publisher = PositionPublisher(tripId: 't1', positions: live, now: () => clock);
      expect(await publisher.offer(at(3.85)), isTrue);
      clock = clock.add(const Duration(seconds: 4));
      expect(await publisher.offer(at(3.851)), isFalse);
      clock = clock.add(const Duration(seconds: 7));
      expect(await publisher.offer(at(3.852)), isTrue);
      expect(live.sent.map((p) => p.latitude), [3.85, 3.852]);
    });

    test('waits without a connection and resumes by itself', () async {
      var clock = DateTime.utc(2026, 11, 12, 6);
      final live = FakeLive()..error = const Offline('no connection');
      final publisher = PositionPublisher(tripId: 't1', positions: live, now: () => clock);
      await publisher.offer(at(3.85));
      expect(publisher.status, ShareStatus.waiting);
      live.error = null;
      clock = clock.add(const Duration(seconds: 1));
      expect(await publisher.offer(at(3.85)), isTrue, reason: 'nothing was sent, so no wait');
      expect(publisher.status, ShareStatus.sharing);
    });

    test('stops for good when the trip is over or the phone may not share it', () async {
      final live = FakeLive()..error = const Conflict('database 55000');
      final publisher = PositionPublisher(tripId: 't1', positions: live, now: DateTime.now);
      await publisher.offer(at(3.85));
      expect(publisher.status, ShareStatus.stopped);
      live.error = null;
      expect(await publisher.offer(at(3.85)), isFalse);
      final refused = PositionPublisher(tripId: 't1', positions: FakeLive()..error = const NotAllowed('database 42501'), now: DateTime.now);
      await refused.offer(at(3.85));
      expect(refused.status, ShareStatus.stopped);
    });
  });

  testWidgets('the assignee starts the trip, is offered sharing, and the bus position goes out', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final positions = FakePositions();
    final live = FakeLive();
    final trips = FakeTrips([trip('t1', driver: 'u1')]);
    await tester.pumpWidget(ProviderScope(
      overrides: overridesFor(auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, trips: trips, positions: positions, live: live),
      child: const OpsApp(),
    ));
    await settle(tester);
    await tester.tap(find.text('Bus B1'));
    await settle(tester);
    await tester.tap(find.text('Start trip'));
    await settle(tester);
    expect(find.text('Sharing the bus position'), findsOneWidget, reason: 'the explanation comes first');
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(positions.notification, contains('BusIn Ops is sharing the bus position'));

    positions.driving.add(at(3.85));
    await settle(tester);
    expect(live.sent, hasLength(1));
    expect(find.textContaining('Last sent'), findsOneWidget);
    BusinToast.dismiss();
    await settle(tester);

    // Off with the switch.
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(find.text('Not sharing'), findsOneWidget);
    positions.driving.add(at(3.86));
    await settle(tester);
    expect(live.sent, hasLength(1));
  });

  testWidgets('on a trip assigned to someone else there is no switch', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final trips = FakeTrips([trip('t1', driver: 'u2', status: TripStatus.active, startedBy: 'u2')]);
    await tester.pumpWidget(ProviderScope(
      overrides: overridesFor(auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, trips: trips),
      child: const OpsApp(),
    ));
    await settle(tester);
    await tester.tap(find.text('Bus B1'));
    await settle(tester);
    expect(find.text('Share the bus position'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(find.text('The staff member assigned to this trip shares its position.'), findsOneWidget);
  });
}
