import 'package:busin_ops/src/profile/ops_settings.dart';
import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_ops/src/access.dart';
import 'package:busin_ops/src/app.dart';
import 'package:busin_ops/src/router.dart';
import 'package:busin_ops/src/trips/trip_providers.dart';
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

Future<void> open(WidgetTester tester, {required FakeAuth auth, required Map<String, Profile> profiles, required FakeTrips trips}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(overrides: overridesFor(auth: auth, profiles: profiles, trips: trips), child: const OpsApp()));
  await settle(tester);
}

void main() {
  group('who may use the ops app', () {
    OpsAccess of(Profile? profile, {String? userId = 'u1'}) =>
        opsAccessFor(sessionLoading: false, userId: userId, profileLoading: false, profileError: null, profile: profile);

    test('verified staff and admins are in', () {
      expect(of(staff()), isA<OpsAllowed>());
      expect((of(staff(role: UserRole.admin)) as OpsAllowed).isAdmin, isTrue);
    });

    test('students and suspended staff are not', () {
      expect((of(staff(role: UserRole.student)) as OpsBlocked).reason, OpsBlockReason.notStaff);
      expect((of(staff(status: AccountStatus.suspended)) as OpsBlocked).reason, OpsBlockReason.suspended);
      expect(of(null, userId: null), isA<OpsSignedOut>());
    });

    test('each state has its screen, and staff never see the gates', () {
      expect(redirectFor(const OpsSignedOut(), Routes.today), Routes.signIn);
      expect(redirectFor(const OpsBlocked(OpsBlockReason.notStaff), Routes.today), Routes.blocked);
      expect(redirectFor(OpsAllowed(staff()), Routes.signIn), Routes.today);
      expect(redirectFor(OpsAllowed(staff()), Routes.trip('t1')), isNull);
      expect(redirectFor(const OpsSignedOut(), Routes.legal(LegalDoc.privacy)), isNull, reason: 'readable before sign-in');
      expect(redirectFor(const OpsLoading(), Routes.legal(LegalDoc.terms)), isNull);
    });
  });

  group('today\'s trips', () {
    test('mine first, then the others', () {
      final split = splitTrips([trip('a'), trip('b', driver: 'u1'), trip('c', driver: 'u2')], 'u1');
      expect(split.mine.map((t) => t.id), ['b']);
      expect(split.others.map((t) => t.id), ['a', 'c']);
    });

    test('Start is only for a trip scheduled for the school\'s today, in the school\'s own timezone', () {
      const clock = SchoolClock();
      // 23:30 UTC on 12 November is already 13 November at Douala (UTC+1).
      final now = DateTime.utc(2026, 11, 12, 23, 30);
      expect(tripIsToday(clock: clock, zone: 'Africa/Douala', scheduledStart: DateTime.utc(2026, 11, 13, 6), now: now), isTrue);
      expect(tripIsToday(clock: clock, zone: 'Africa/Douala', scheduledStart: DateTime.utc(2026, 11, 12, 6), now: now), isFalse, reason: 'yesterday at the school');
      expect(tripIsToday(clock: clock, zone: 'Africa/Douala', scheduledStart: DateTime.utc(2026, 11, 14, 6), now: now), isFalse, reason: 'tomorrow');
    });

    test('a trip is mine when I am its assistant too', () {
      final split = splitTrips([trip('a', driver: 'u2', assistant: 'u1'), trip('b', driver: 'u2')], 'u1');
      expect(split.mine.map((t) => t.id), ['a']);
      expect(split.others.map((t) => t.id), ['b']);
    });

    test('a refused start is explained from what the app knows', () {
      final busy = [trip('a', bus: 'b1', status: TripStatus.active), trip('b', bus: 'b1')];
      expect(startRefusal(trip: busy[1], today: busy, isToday: true), StartRefusal.busBusy);
      expect(startRefusal(trip: busy[1], today: busy, isToday: false), StartRefusal.notToday);
      expect(startRefusal(trip: trip('c', bus: 'b2'), today: busy, isToday: true), StartRefusal.notScheduled);
    });

    testWidgets('the privacy policy opens from sign-in, with the part for staff and drivers', (tester) async {
      await open(tester, auth: FakeAuth(), profiles: {}, trips: FakeTrips([]));
      await tester.scrollUntilVisible(find.text('Privacy policy'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Privacy policy'));
      await tester.pumpAndSettle();
      expect(find.text('In short'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('If you are staff or a driver'), 300, scrollable: find.byType(Scrollable).last);
      expect(find.text('If you are staff or a driver'), findsOneWidget);
    });

    testWidgets('the profile shows who is signed in and keeps the scanning and driving choices', (tester) async {
      await open(tester, auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, trips: FakeTrips([]));
      await tester.tap(find.byTooltip('Profile and settings'));
      await settle(tester);
      expect(find.text('Your profile'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);

      final container = ProviderScope.containerOf(tester.element(find.text('Your profile')));
      expect(container.read(opsSettingsProvider).vibrate, isTrue);
      await tester.scrollUntilVisible(find.text('Vibrate on each scan'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Vibrate on each scan'));
      await settle(tester);
      expect(container.read(opsSettingsProvider).vibrate, isFalse);

      await tester.scrollUntilVisible(find.text('Offer to share the bus position when I start a trip'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Offer to share the bus position when I start a trip'));
      await settle(tester);
      expect(container.read(opsSettingsProvider).offerShare, isFalse);
    });

    testWidgets('with the offer turned off, starting a trip does not open the sharing sheet', (tester) async {
      final trips = FakeTrips([trip('t1', driver: 'u1')]);
      await open(tester, auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, trips: trips);
      ProviderScope.containerOf(tester.element(find.text('Bus B1'))).read(opsSettingsProvider.notifier).setOfferShare(false);
      await tester.tap(find.text('Bus B1'));
      await settle(tester);
      await tester.tap(find.text('Start trip'));
      await settle(tester);
      expect(trips.started, ['t1']);
      expect(find.text('Sharing the bus position'), findsNothing);
      BusinToast.dismiss();
      await settle(tester);
    });

    testWidgets('a student is told this app is for staff', (tester) async {
      await open(tester, auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff(role: UserRole.student)}, trips: FakeTrips([]));
      expect(find.text('This app is for staff'), findsOneWidget);
    });

    testWidgets('staff see today\'s trips, theirs first, in the school\'s time', (tester) async {
      final trips = FakeTrips([trip('t1', bus: 'b1'), trip('t2', bus: 'b2', driver: 'u1')]);
      await open(tester, auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, trips: trips);
      expect(find.text('Today\'s trips'), findsOneWidget);
      expect(find.text('Assigned to you'), findsOneWidget);
      final mine = tester.getTopLeft(find.text('Bus B2')).dy;
      final other = tester.getTopLeft(find.text('Bus B1')).dy;
      expect(mine, lessThan(other));
      // 06:30 UTC is 07:30 at the school.
      expect(find.textContaining('7:30'), findsNWidgets(2));
    });

    testWidgets('the assignee starts a trip, and ends it after confirming', (tester) async {
      final trips = FakeTrips([trip('t1', driver: 'u1')]);
      await open(tester, auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, trips: trips);
      await tester.tap(find.text('Bus B1'));
      await settle(tester);
      await tester.tap(find.text('Start trip'));
      await settle(tester);
      expect(trips.started, ['t1']);
      // Sharing the position is offered next; not this time.
      expect(find.text('Sharing the bus position'), findsOneWidget);
      await tester.tapAt(const Offset(20, 20));
      await settle(tester);
      expect(find.text('0 of 50 on board'), findsOneWidget);
      BusinToast.dismiss();
      await settle(tester);

      await tester.tap(find.text('End trip'));
      await settle(tester);
      expect(find.text('End this trip?'), findsOneWidget);
      await tester.tap(find.text('End trip').last);
      await settle(tester);
      expect(trips.ended, ['t1']);
      BusinToast.dismiss();
      await settle(tester);
    });

    testWidgets('a trip assigned to someone else cannot be started here', (tester) async {
      final trips = FakeTrips([trip('t1', driver: 'u2')]);
      await open(tester, auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, trips: trips);
      await tester.tap(find.text('Bus B1'));
      await settle(tester);
      expect(find.text('Start trip'), findsNothing);
      expect(find.textContaining('Assigned to other staff members'), findsOneWidget);
    });

    testWidgets('a bus already on a trip is explained', (tester) async {
      final trips = FakeTrips([trip('t0', bus: 'b1', status: TripStatus.active), trip('t1', bus: 'b1', driver: 'u1')])
        ..startError = const Conflict('database 55000');
      await open(tester, auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, trips: trips);
      await tester.tap(find.text('Bus B1').first); // mine, listed first
      await settle(tester);
      await tester.tap(find.text('Start trip'));
      await settle(tester);
      expect(find.text('This bus is already on another trip. End that one first.'), findsOneWidget);
      BusinToast.dismiss();
      await settle(tester);
    });
  });
}
