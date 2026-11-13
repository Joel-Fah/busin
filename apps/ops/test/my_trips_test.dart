import 'package:busin_core/busin_core.dart';
import 'package:busin_ops/src/app.dart';
import 'package:busin_ops/src/trips/my_trips_providers.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> open(WidgetTester tester, FakeTrips trips, {Profile? me}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: overridesFor(auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': me ?? staff()}, trips: trips),
    child: const OpsApp(),
  ));
  await settle(tester);
}

TripHistoryEntry past(String id, DateTime at, {DateTime? started, TripStatus status = TripStatus.completed, int boarded = 0}) => TripHistoryEntry(
      id: id,
      busId: 'b1',
      busLabel: 'Bus $id',
      direction: TripDirection.inbound,
      status: status,
      scheduledStart: at,
      startedAt: started,
      endedAt: started?.add(const Duration(minutes: 50)),
      part: CrewPart.driver,
      boarded: boarded,
    );

void main() {
  group('weeks', () {
    test('a week runs Monday to Sunday at the school', () {
      expect(mondayOf(DateTime(2026, 11, 12)), DateTime(2026, 11, 9), reason: 'a Thursday');
      expect(mondayOf(DateTime(2026, 11, 9)), DateTime(2026, 11, 9), reason: 'a Monday is its own');
      expect(mondayOf(DateTime(2026, 11, 15)), DateTime(2026, 11, 9), reason: 'a Sunday ends the week');
    });

    test('items are grouped by their week in the school\'s time', () {
      // 23:30 UTC on Sunday 15 November is already Monday 16 at the school (UTC+1).
      final at = [DateTime.utc(2026, 11, 10, 6), DateTime.utc(2026, 11, 15, 22, 30), DateTime.utc(2026, 11, 15, 23, 30), DateTime.utc(2026, 11, 18, 6)];
      final groups = groupByWeek(at, (DateTime d) => d, zone: 'Africa/Douala');
      expect(groups.map((g) => g.monday), [DateTime(2026, 11, 9), DateTime(2026, 11, 16)]);
      expect(groups.map((g) => g.items.length), [2, 2]);
    });

    test('punctuality goes up, down or holds over the last 8 weeks', () {
      WeekStats w(int onTime, int late) => WeekStats(weekStart: DateTime.utc(2026, 9, 7), onTime: onTime, late: late);
      expect(punctualityTrend([for (var i = 0; i < 4; i++) w(1, 1), for (var i = 0; i < 4; i++) w(2, 0)]), Trend.up);
      expect(punctualityTrend([for (var i = 0; i < 4; i++) w(2, 0), for (var i = 0; i < 4; i++) w(1, 1)]), Trend.down);
      expect(punctualityTrend([for (var i = 0; i < 8; i++) w(3, 1)]), Trend.steady);
      expect(punctualityTrend([for (var i = 0; i < 8; i++) w(0, 0)]), isNull, reason: 'nothing timed');
      expect(punctualityTrend([w(1, 0)]), isNull, reason: 'too few weeks');
    });
  });

  testWidgets('the Trips tab lists the trips ahead by week, after today\'s', (tester) async {
    final trips = FakeTrips([
      trip('today', bus: 'b1', driver: 'u1'),
      trip('fri', bus: 'b2', driver: 'u1', at: DateTime.utc(2026, 11, 13, 6, 30)),
      trip('tue', bus: 'b3', assistant: 'u1', at: DateTime.utc(2026, 11, 17, 15)),
      trip('notmine', bus: 'b4', driver: 'u2', at: DateTime.utc(2026, 11, 17, 6)),
    ]);
    await open(tester, trips);
    expect(find.text('Coming up'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Next week'), findsOneWidget);
    expect(find.text('Bus B3'), findsOneWidget, reason: 'a trip they assist on is theirs too');
    expect(find.text('Bus B4'), findsNothing, reason: 'not a colleague\'s');
    expect(tester.getTopLeft(find.text('This week')).dy, lessThan(tester.getTopLeft(find.text('Next week')).dy));
  });

  testWidgets('the person\'s own picture opens their profile', (tester) async {
    final me = Profile(
      id: 'u1',
      schoolId: schoolId,
      email: 'u1@school.edu',
      fullName: 'Sam Staff',
      role: UserRole.staff,
      status: AccountStatus.verified,
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
      avatarUrl: 'https://example.com/sam.png',
    );
    await open(tester, FakeTrips([]), me: me);
    final avatar = find.byWidgetPredicate((w) => w is UserAvatar && w.imageUrl == 'https://example.com/sam.png');
    expect(avatar, findsOneWidget, reason: 'the Google picture is in the top bar');
    await tester.tap(find.byTooltip('Profile and settings'));
    await settle(tester);
    expect(find.text('Your profile'), findsOneWidget);
    expect(avatar, findsWidgets, reason: 'and on the profile');
  });

  testWidgets('History lists past trips by week with how each went, and loads more at the end', (tester) async {
    final trips = FakeTrips([])
      ..history = [
        past('h1', DateTime.utc(2026, 11, 11, 6), started: DateTime.utc(2026, 11, 11, 6, 4), boarded: 12),
        past('h2', DateTime.utc(2026, 11, 10, 6), started: DateTime.utc(2026, 11, 10, 6, 25)),
        past('h3', DateTime.utc(2026, 11, 3, 6), status: TripStatus.scheduled),
        for (var i = 0; i < 30; i++) past('o$i', DateTime.utc(2026, 10, 30, 6).subtract(Duration(days: i)), started: DateTime.utc(2026, 10, 30, 6).subtract(Duration(days: i))),
      ];
    await open(tester, trips);
    await tester.tap(find.text('History'));
    await settle(tester);
    expect(find.text('Your trips'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Last week'), findsOneWidget);
    expect(find.text('On time'), findsWidgets);
    expect(find.text('25 min late'), findsOneWidget);
    expect(find.text('12 boarded'), findsOneWidget);
    expect(find.text('Not run'), findsOneWidget);
    expect(trips.historyAsked.first, DateTime.utc(2026, 11, 11, 23), reason: 'history starts before today at the school');

    await tester.scrollUntilVisible(find.text('That is everything.'), 600, scrollable: find.byType(Scrollable).last, maxScrolls: 80);
    expect(trips.historyAsked.length, greaterThan(1), reason: 'the next page was asked for');
    expect(find.text('Bus o29'), findsOneWidget, reason: 'the pages reached the oldest trip');
  });

  testWidgets('Stats shows the totals, the punctuality and the charts', (tester) async {
    final trips = FakeTrips([])
      ..stats = [
        for (var i = 0; i < 12; i++)
          WeekStats(
            weekStart: DateTime.utc(2026, 8, 24).add(Duration(days: 7 * i)),
            trips: 4,
            completed: 4,
            onTime: i < 8 ? 2 : 4,
            late: i < 8 ? 2 : 0,
            avgDelayMinutes: 6,
            boarded: 30,
            minutesOnRoad: 120,
            asDriver: 3,
            asAssistant: 1,
          ),
      ];
    await open(tester, trips);
    await tester.tap(find.text('Stats'));
    await settle(tester);
    expect(find.text('Your stats'), findsOneWidget);
    expect(find.text('48'), findsOneWidget, reason: 'trips over 12 weeks');
    expect(find.text('67%'), findsOneWidget, reason: '32 of 48 on time');
    expect(find.text('Better than the 4 weeks before'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('48 trips in 12 weeks')), findsOneWidget);
    expect(find.text('As driver: 36. As assistant: 12.'), findsOneWidget);
  });

  testWidgets('Stats before any trip says they will come', (tester) async {
    await open(tester, FakeTrips([])..stats = [for (var i = 0; i < 12; i++) WeekStats(weekStart: DateTime.utc(2026, 8, 24).add(Duration(days: 7 * i)))]);
    await tester.tap(find.text('Stats'));
    await settle(tester);
    expect(find.text('Your stats appear after your first trips.'), findsOneWidget);
  });
}
