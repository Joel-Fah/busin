import 'package:busin_core/busin_core.dart';
import 'package:busin_ops/src/app.dart';
import 'package:busin_ops/src/queue/scan_queue.dart';
import 'package:busin_ops/src/scan/scan_sound.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

const ada = 'a1000000-0000-4000-8000-000000000001';
const ben = 'a1000000-0000-4000-8000-000000000002';

Future<void> settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Opens the scanner of a running trip assigned to the signed-in staff member.
Future<void> openScanner(
  WidgetTester tester, {
  required MemoryScanQueue queue,
  FakeScans? scans,
  FakeQr? qr,
  bool online = false,
  FakeRosterStore? rosters,
  FakeSoundPlayer? sounds,
  Size size = const Size(800, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final trips = FakeTrips([trip('t1', driver: 'u1', status: TripStatus.active, startedBy: 'u1')]);
  await tester.pumpWidget(ProviderScope(
    overrides: overridesFor(
      auth: FakeAuth(signedInAs: 'u1'),
      profiles: {'u1': staff()},
      trips: trips,
      qr: qr ?? FakeQr([riderKey(ada, 1, 'Ada Lovelace')]),
      rosters: rosters,
      queue: queue,
      scans: scans,
      sounds: sounds,
      online: online,
    ),
    child: const OpsApp(),
  ));
  await settle(tester);
  await tester.tap(find.text('Bus B1'));
  await settle(tester);
  await tester.tap(find.text('Scan boarding codes'));
  await settle(tester);
}

void main() {
  testWidgets('offline: a rider on today\'s list is let on, queued with the time and stop, and counted once', (tester) async {
    final queue = MemoryScanQueue();
    // The list was downloaded earlier; now there is no connection.
    final rosters = FakeRosterStore();
    // The connection is gone: sending waits (the list was downloaded before).
    final scans = FakeScans()..error = const Offline('no connection');
    final sounds = FakeSoundPlayer();
    await openScanner(tester, queue: queue, qr: FakeQr([riderKey(ada, 1, 'Ada Lovelace')]), online: true, rosters: rosters, scans: scans, sounds: sounds);
    expect(sounds.preloads, 1, reason: 'loaded when the scanner opens, so the first sound is not late');
    expect(find.textContaining('Today\'s list: 1 riders'), findsOneWidget);

    feed(codeOf(ada, 1));
    await settle(tester);
    expect(find.text('On board'), findsOneWidget);
    expect(find.text('Ada Lovelace · M1'), findsOneWidget);
    expect(queue.all.single.studentId, ada);
    expect(queue.all.single.stopId, 'stop1', reason: 'the nearest stop to the phone');
    expect(queue.all.single.scannedAt, morning);

    // The next window's code of the same student: already on board, not queued twice.
    feed(codeOf(ada, 1, at: morning.add(const Duration(seconds: 30))));
    await settle(tester);
    expect(find.text('Already on board'), findsOneWidget);
    expect(queue.all, hasLength(1));
    expect(queue.all.single.state, QueuedState.pending, reason: 'kept until the connection is back');
    expect(sounds.played, [ScanSound.admit, ScanSound.again]);
  });

  testWidgets('a forged code is refused at the door', (tester) async {
    final queue = MemoryScanQueue();
    final sounds = FakeSoundPlayer();
    await openScanner(tester, queue: queue, online: true, sounds: sounds);
    feed(codeOf(ada, 99));
    await settle(tester);
    expect(find.text('Not a valid boarding code'), findsOneWidget);
    expect(queue.all, isEmpty);
    expect(sounds.played, [ScanSound.suspect]);
  });

  testWidgets('when the server cannot be reached for a student missing from the list, staff still hear it', (tester) async {
    final queue = MemoryScanQueue();
    final scans = FakeScans()..error = const Offline('no connection');
    final sounds = FakeSoundPlayer();
    await openScanner(tester, queue: queue, scans: scans, online: true, sounds: sounds);
    feed(codeOf(ben, 2));
    await settle(tester);
    expect(sounds.played, [ScanSound.error]);
  });

  testWidgets('the server refusing a student without a subscription plays the refusal sound', (tester) async {
    final queue = MemoryScanQueue();
    final scans = FakeScans()..answer = const ScanRefused(ScanFailure.noActiveSubscription);
    final sounds = FakeSoundPlayer();
    await openScanner(tester, queue: queue, scans: scans, online: true, sounds: sounds);
    feed(codeOf(ben, 2));
    await settle(tester);
    expect(sounds.played, [ScanSound.refused]);
  });

  testWidgets('online, a student missing from the list is checked by the server', (tester) async {
    final queue = MemoryScanQueue();
    final scans = FakeScans()..answer = const ScanAccepted(student: StudentSummary(fullName: 'Ben Okafor', matricule: 'M2'), duplicate: false, scanId: 's');
    await openScanner(tester, queue: queue, scans: scans, online: true);
    feed(codeOf(ben, 2));
    await settle(tester);
    expect(find.text('On board'), findsOneWidget);
    expect(find.text('Ben Okafor · M2'), findsOneWidget);
    expect(scans.sent.where((s) => s.at == null), hasLength(1), reason: 'a live check, timed by the server');
    expect(queue.all.single.state, QueuedState.accepted, reason: 'counted on board, nothing left to send');
  });

  testWidgets('scans waiting to be sent keep staff from signing out', (tester) async {
    final queue = MemoryScanQueue();
    await queue.add(QueuedScan(clientId: 'c1', tripId: 't1', code: 'busin2.x', studentId: ada, scannedAt: morning));
    final scans = FakeScans()..error = const Offline('no connection');
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = FakeAuth(signedInAs: 'u1');
    await tester.pumpWidget(ProviderScope(
      overrides: overridesFor(auth: auth, profiles: {'u1': staff()}, trips: FakeTrips([]), queue: queue, scans: scans, online: false),
      child: const OpsApp(),
    ));
    await settle(tester);
    await tester.tap(find.byTooltip('Profile and settings'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Sign out'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Sign out'));
    await settle(tester);
    expect(find.textContaining('1 scan is still waiting to send'), findsOneWidget);
    expect(auth.signOuts, 0);
    BusinToast.dismiss();
    await settle(tester);
  });

  testWidgets('a tablet in landscape puts the camera on one side and the result and counts on the other', (tester) async {
    final queue = MemoryScanQueue();
    await openScanner(tester, queue: queue, online: true, size: const Size(1600, 1000));
    final side = find.byKey(const ValueKey('scanner-side'));
    expect(side, findsOneWidget);
    expect(find.descendant(of: side, matching: find.textContaining('Today\'s list: 1 riders')), findsOneWidget);
    expect(tester.getTopLeft(side).dx, greaterThan(800), reason: 'beside the camera, on the right');

    feed(codeOf(ada, 1));
    await settle(tester);
    expect(find.descendant(of: side, matching: find.text('On board')), findsOneWidget);
  });
}
