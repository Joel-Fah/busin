import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/offline/pass_snapshot.dart';
import 'package:busin_student/src/subscription/subscription_overview.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// Everything the phone keeps between two runs of the app, so a test can "close" the app and open it again.
class Phone {
  final snapshots = FakeSnapshotStore();
  final secrets = FakeSecretStore();
}

Future<void> launch(
  WidgetTester tester,
  Phone phone, {
  required FakeProfileRepository profiles,
  required FakeBackend backend,
  FakeQr? qr,
  TestClock? clock,
  Stream<bool>? connectivity,
  Duration? gateTimeout,
  FakeAuthService? auth,
}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(
        auth ?? FakeAuthService(signedInAs: 'u1'),
        profiles,
        backend: backend,
        qr: qr,
        store: phone.secrets,
        snapshots: phone.snapshots,
        clock: clock,
        connectivity: connectivity,
        gateTimeout: gateTimeout,
      ),
      child: const StudentApp(),
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  BusinToast.dismiss();
  await tester.pump();
}

FakeProfileRepository students() => FakeProfileRepository({'u1': profile()});

FakeBackend approvedBackend({String end = '2027-01-31'}) => FakeBackend(
      current: semester(end: end),
      mine: [subscription(status: SubscriptionStatus.approved)],
    );

/// Opens the app once with a connection, as a student with an approved pass would.
Future<Phone> usedOnline(WidgetTester tester, {String end = '2027-01-31', TestClock? clock}) async {
  final phone = Phone();
  await launch(tester, phone, profiles: students(), backend: approvedBackend(end: end), clock: clock);
  expect(find.text('Boarding code'), findsOneWidget, reason: 'online, an approved student lands on the code');
  return phone;
}

void main() {
  group('opening the app with no connection', () {
    testWidgets('a student who used the app before gets straight to the code, with a notice', (tester) async {
      final phone = await usedOnline(tester);
      expect(phone.snapshots.kept['u1'], isNotNull, reason: 'what the server said was saved');

      final profiles = students()..error = const Offline('x');
      final backend = approvedBackend()..readError = const Offline('x');
      final qr = FakeQr()..error = const Offline('x');
      // The secret the phone kept from the last time (the fake store holds it already).
      await launch(tester, phone, profiles: profiles, backend: backend, qr: qr);

      expect(find.text('Boarding code'), findsOneWidget);
      expect(find.text('No connection'), findsOneWidget);
      expect(find.textContaining('Your saved pass still works at the door'), findsOneWidget);
      expect(find.text('Something went wrong. Try again.'), findsNothing);
    });

    testWidgets('someone who never opened it online sees the problem screen and can try again', (tester) async {
      final profiles = students()..error = const Offline('x');
      await launch(tester, Phone(), profiles: profiles, backend: approvedBackend()..readError = const Offline('x'));
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Boarding code'), findsNothing);
    });

    testWidgets('a connection that never answers falls back to the saved copy after the timeout', (tester) async {
      final phone = await usedOnline(tester);
      final profiles = students()..hold = Completer<void>();
      await launch(tester, phone, profiles: profiles, backend: approvedBackend()..readError = const Offline('x'), qr: FakeQr()..error = const Offline('x'), gateTimeout: const Duration(seconds: 1));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('Boarding code'), findsOneWidget);
      expect(find.text('No connection'), findsOneWidget);
    });

    testWidgets('once the semester has ended the saved pass is no longer shown as working', (tester) async {
      final phone = await usedOnline(tester, end: '2026-10-31', clock: TestClock(DateTime.utc(2026, 10, 15, 9)));

      final backend = approvedBackend(end: '2026-10-31')..readError = const Offline('x');
      await launch(tester, phone, profiles: students()..error = const Offline('x'), backend: backend, qr: FakeQr()..error = const Offline('x'), clock: TestClock(DateTime.utc(2026, 11, 6, 9)));

      // It lands on the subscription tab, which says this is the saved copy and asks to reconnect.
      expect(find.text('Boarding code'), findsNothing);
      expect(find.textContaining('copy saved on this phone'), findsOneWidget);
    });

    testWidgets('a saved copy that is not approved does not open the code', (tester) async {
      final phone = Phone();
      await launch(tester, phone, profiles: students(), backend: FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.pending)]));
      await launch(tester, phone, profiles: students()..error = const Offline('x'), backend: FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.pending)])..readError = const Offline('x'));
      expect(find.text('Boarding code'), findsNothing);
      expect(find.textContaining('copy saved on this phone'), findsOneWidget);
    });

    testWidgets('with no subscription saved, the form cannot send while offline and says why', (tester) async {
      final phone = Phone();
      await launch(tester, phone, profiles: students(), backend: FakeBackend(current: semester()));
      await launch(tester, phone, profiles: students()..error = const Offline('x'), backend: FakeBackend(current: semester())..readError = const Offline('x'));
      expect(find.text('Connect to the internet to send your request.'), findsOneWidget);
      final send = tester.widget<BusinButton>(find.widgetWithText(BusinButton, 'Send request'));
      expect(send.onPressed, isNull);
    });
  });

  group('a refusal is never hidden by the saved copy', () {
    testWidgets('a server refusal of the profile shows the problem screen even when a copy exists', (tester) async {
      final phone = await usedOnline(tester);
      await launch(tester, phone, profiles: students()..error = const NotAllowed('x'), backend: approvedBackend());
      expect(find.text('Boarding code'), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('an account the school has blocked loses its saved copy and cannot open offline', (tester) async {
      final phone = await usedOnline(tester);
      final suspended = FakeProfileRepository({'u1': profile(status: AccountStatus.suspended)});
      await launch(tester, phone, profiles: suspended, backend: approvedBackend());
      expect(phone.snapshots.kept, isEmpty);

      await launch(tester, phone, profiles: students()..error = const Offline('x'), backend: approvedBackend()..readError = const Offline('x'));
      expect(find.text('Boarding code'), findsNothing, reason: 'nothing saved, so nothing opens');
    });

    testWidgets('signing out forgets the saved copy', (tester) async {
      final phone = await usedOnline(tester);
      expect(phone.snapshots.kept, isNotEmpty);
      await tester.tap(find.text('Profile'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.scrollUntilVisible(find.text('Sign out'), 300, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text('Sign out'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Sign out'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('Sign out').last);
      await tester.pump(const Duration(milliseconds: 600));
      expect(phone.snapshots.kept, isEmpty);
    });
  });

  group('coming back online', () {
    testWidgets('the notice goes away by itself and a decision made meanwhile locks the pass', (tester) async {
      final phone = await usedOnline(tester);

      final profiles = students()..error = const Offline('x');
      final backend = approvedBackend()..readError = const Offline('x');
      final qr = FakeQr()..error = const Offline('x');
      final network = StreamController<bool>.broadcast();
      addTearDown(network.close);
      await launch(tester, phone, profiles: profiles, backend: backend, qr: qr, connectivity: network.stream);
      expect(find.text('No connection'), findsOneWidget);

      // The network returns; meanwhile the school took the subscription away.
      profiles.error = null;
      backend
        ..readError = null
        ..mine.clear()
        ..mine.add(subscription(status: SubscriptionStatus.revoked));
      qr.error = const NotAllowed('revoked');
      network.add(false);
      await tester.pump();
      network.add(true);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('No connection'), findsNothing);
      expect(phone.secrets.data, isEmpty, reason: 'the refused pass loses the secret kept on the phone');
    });

    testWidgets('while everything is fresh there is no notice', (tester) async {
      await usedOnline(tester);
      expect(find.text('No connection'), findsNothing);
    });
  });

  group('the saved copy itself', () {
    final created = DateTime.utc(2026, 11, 1);
    final student = profile();

    test('belongs to one user: another account never gets it', () async {
      final store = FakeSnapshotStore();
      final keeper = SnapshotKeeper(store, () => created);
      await keeper.saveProfile('u1', student);
      expect((await keeper.load('u1'))?.profile, student);
      expect(await keeper.load('someone-else'), isNull);
      expect(keeper.peek('someone-else'), isNull);
    });

    test('pieces are saved as the server answers, and clearing forgets them', () async {
      final store = FakeSnapshotStore();
      final keeper = SnapshotKeeper(store, () => created);
      await keeper.saveProfile('u1', student);
      await keeper.saveSchool('u1', const School(id: 's1', name: 'Test School', timezone: 'Africa/Douala', isActive: true));
      await keeper.saveOverview('u1', SubscriptionOverview(semester: semester(), subscription: subscription(status: SubscriptionStatus.approved), stop: stop('stop1', 'A')).toJson());
      final fresh = SnapshotKeeper(store, () => created);
      final loaded = await fresh.load('u1');
      expect(loaded?.profile, student);
      expect(loaded?.school?.timezone, 'Africa/Douala');
      expect(SubscriptionOverview.fromJson(loaded!.overview!, savedAt: created).subscription?.status, SubscriptionStatus.approved);

      await keeper.clear('u1');
      expect(store.kept, isEmpty);
      expect(await SnapshotKeeper(store, () => created).load('u1'), isNull);
    });

    test('a copy that cannot be written does not break the screen that has the answer', () async {
      final store = FakeSnapshotStore()..failWrites = true;
      final keeper = SnapshotKeeper(store, () => created);
      await keeper.saveProfile('u1', student);
      expect(keeper.peek('u1')?.profile, student, reason: 'still in memory');
    });

    test('a copy from another version or damaged text is ignored', () {
      expect(PassSnapshot.tryParse({'version': 99, 'user_id': 'u1', 'saved_at': created.toIso8601String()}), isNull);
      expect(PassSnapshot.tryParse('not a map'), isNull);
      expect(PassSnapshot.tryParse({'version': PassSnapshot.version, 'user_id': 'u1', 'saved_at': 'yesterday'}), isNull);
    });

    test('a saved pass is usable only while its semester runs at the school', () {
      final approved = subscription(status: SubscriptionStatus.approved);
      // Dates as the model reads them: midnight UTC, whatever zone the phone is in.
      final running = Semester(id: 'sem1', schoolId: 's1', name: SemesterName.fall, year: 2026, startDate: DateTime.utc(2026, 9, 1), endDate: DateTime.utc(2026, 12, 15));
      final overview = SubscriptionOverview(semester: running, subscription: approved, savedAt: created);
      expect(overview.passUsable(DateTime(2026, 11, 6)), isTrue);
      expect(overview.passUsable(DateTime(2026, 12, 15)), isTrue, reason: 'the last day counts');
      expect(overview.passUsable(DateTime(2026, 12, 16)), isFalse);
      expect(overview.passUsable(DateTime(2026, 8, 31)), isFalse, reason: 'not started yet');
      // A fresh answer from the server is taken as it is; anything but approved is never a working pass.
      expect(SubscriptionOverview(semester: semester(end: '2026-01-01'), subscription: approved).passUsable(DateTime(2026, 11, 6)), isTrue);
      expect(SubscriptionOverview(semester: semester(), subscription: subscription(), savedAt: created).passUsable(DateTime(2026, 11, 6)), isFalse);
      expect(const SubscriptionOverview.none().passUsable(DateTime(2026, 11, 6)), isFalse);
    });
  });
}
