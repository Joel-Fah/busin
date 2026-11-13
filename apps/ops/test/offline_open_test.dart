import 'package:busin_core/busin_core.dart';
import 'package:busin_ops/src/app.dart';
import 'package:busin_ops/src/offline/ops_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {

  ({FakeProfiles profiles, FakeTrips trips, FakeSchools schools, FakeBuses buses}) backend() => (
        profiles: FakeProfiles({'u1': staff()}),
        trips: FakeTrips([trip('t1', driver: 'u1')]),
        schools: FakeSchools(),
        buses: FakeBuses(),
      );

  Future<void> open(WidgetTester tester, MemoryOpsSnapshotStore store, ({FakeProfiles profiles, FakeTrips trips, FakeSchools schools, FakeBuses buses}) b, {Duration? gateTimeout = const Duration(seconds: 15)}) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(
        auth: FakeAuth(signedInAs: 'u1'),
        profiles: {'u1': staff()},
        profileRepository: b.profiles,
        trips: b.trips,
        schools: b.schools,
        buses: b.buses,
        snapshots: store,
        gateTimeout: gateTimeout,
      ),
      child: const OpsApp(),
    ));
    await settle(tester, 25);
  }

  void goOffline(({FakeProfiles profiles, FakeTrips trips, FakeSchools schools, FakeBuses buses}) b) {
    b.profiles.offline = true;
    b.trips.offline = true;
    b.schools.offline = true;
    b.buses.offline = true;
  }

  testWidgets('opened once online, the app opens offline from the copy saved on the phone and says so', (tester) async {
    final store = MemoryOpsSnapshotStore();
    await open(tester, store, backend());
    expect(find.text("Today's trips"), findsOneWidget);
    expect(find.text('No connection'), findsNothing);
    expect(store.byUser['u1']?.trips?.map((t) => t.id), ['t1'], reason: "today's trips are kept");

    final b = backend();
    goOffline(b);
    await open(tester, store, b);
    expect(find.text("Today's trips"), findsOneWidget, reason: 'the app opens');
    expect(find.text('Bus B1'), findsOneWidget, reason: 'with the trip and its bus from the copy');
    expect(find.text('No connection'), findsOneWidget, reason: 'and says it is the saved copy');
  });

  testWidgets('without a copy and without a connection, it stops waiting and says what is wrong', (tester) async {
    final b = backend();
    goOffline(b);
    await open(tester, MemoryOpsSnapshotStore(), b, gateTimeout: const Duration(seconds: 2));
    expect(find.text('BusIn Ops could not load your account'), findsOneWidget);
  });

  testWidgets("another day's saved trips are never shown as today's", (tester) async {
    final store = MemoryOpsSnapshotStore();
    store.byUser['u1'] = OpsSnapshot(
      userId: 'u1',
      savedAt: morning.subtract(const Duration(days: 1)),
      profile: staff(),
      school: const School(id: schoolId, name: 'Test School', timezone: 'Africa/Douala', isActive: true),
      tripsDay: '2026-11-11',
      trips: [trip('old', driver: 'u1')],
    );
    final b = backend();
    goOffline(b);
    await open(tester, store, b, gateTimeout: const Duration(seconds: 2));
    expect(find.text("Today's trips"), findsOneWidget, reason: 'the profile copy still opens the app');
    expect(find.text('Bus B1'), findsNothing, reason: "yesterday's list is not today's");
  });

  testWidgets('a suspended account loses the copy, so it cannot open offline', (tester) async {
    final store = MemoryOpsSnapshotStore();
    final b = backend();
    await open(tester, store, b);
    expect(store.byUser['u1'], isNotNull);
    b.profiles.byId['u1'] = staff(status: AccountStatus.suspended);
    b.profiles.changes.add(b.profiles.byId['u1']!);
    await settle(tester, 15);
    expect(find.text('Your account is suspended'), findsOneWidget);
    expect(store.byUser['u1'], isNull, reason: 'the copy is wiped');
  });
}
