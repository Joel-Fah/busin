import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/history/history_providers.dart';
import 'package:busin_student/src/history/history_stats.dart';
import 'package:busin_student/src/school_clock.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> openHistory(
  WidgetTester tester,
  FakeHistory history, {
  FakeBackend? backend,
  Locale locale = const Locale('en'),
  Size size = const Size(800, 1800),
  TestClock? clock,
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), history: history, backend: backend, clock: clock),
      child: const StudentApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(locale.languageCode == 'fr' ? 'Profil' : 'Profile'));
  await tester.pumpAndSettle();
  final tile = find.text(locale.languageCode == 'fr' ? 'Historique des trajets' : 'Boarding history');
  // On a small phone the tile is below the first screen of the profile.
  await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

/// A stop's name in a day's card (the same name may also be the most used stop at the top).
Finder inDays(String text) => find.descendant(of: find.byType(BusinCard), matching: find.text(text));

HistoryEntry entry(DateTime when) => HistoryEntry(scan: scan(0, at: when), when: when);

void main() {
  group('groupByDay', () {
    test('groups by calendar day and keeps the newest-first order', () {
      final days = groupByDay([
        entry(DateTime(2026, 11, 5, 18)),
        entry(DateTime(2026, 11, 5, 7)),
        entry(DateTime(2026, 11, 4, 18)),
        entry(DateTime(2026, 10, 30, 7)),
      ]);
      expect(days.map((d) => d.day), [DateTime(2026, 11, 5), DateTime(2026, 11, 4), DateTime(2026, 10, 30)]);
      expect(days.map((d) => d.entries.length), [2, 1, 1]);
    });

    test('nothing gives no days', () => expect(groupByDay(const []), isEmpty));
  });

  test('wallClock gives the time on the school\'s wall, across the day boundary', () {
    const clock = SchoolClock();
    expect(clock.wallClock('Africa/Douala', DateTime.utc(2026, 11, 4, 23, 30)), DateTime(2026, 11, 5, 0, 30));
    expect(clock.wallClock('America/New_York', DateTime.utc(2026, 7, 1, 3, 30)), DateTime(2026, 6, 30, 23, 30));
  });

  group('numbers', () {
    HistoryEntry at(DateTime when, {String? stop}) => HistoryEntry(scan: scan(0, at: when), when: when, stopName: stop);

    test('this week counts the last seven days, today included', () {
      final today = DateTime(2026, 11, 5);
      final stats = statsFor([
        at(DateTime(2026, 11, 5, 18), stop: 'A'),
        at(DateTime(2026, 11, 1, 7), stop: 'A'),
        at(DateTime(2026, 10, 30, 7), stop: 'B'), // the seventh day back
        at(DateTime(2026, 10, 29, 7), stop: 'B'), // the eighth: not this week
      ], today);
      expect(stats.thisWeek, 3);
    });

    test('the most used stop wins, and on a tie the most recent one', () {
      final today = DateTime(2026, 11, 5);
      expect(statsFor([at(DateTime(2026, 11, 5, 8), stop: 'A'), at(DateTime(2026, 11, 4, 8), stop: 'B'), at(DateTime(2026, 11, 3, 8), stop: 'B')], today).topStop, 'B');
      final tie = statsFor([at(DateTime(2026, 11, 5, 8), stop: 'A'), at(DateTime(2026, 11, 4, 8), stop: 'B')], today);
      expect(tie.topStop, 'A');
      expect(tie.topStopCount, 1);
      expect(statsFor([at(DateTime(2026, 11, 5, 8))], today).topStop, isNull);
      expect(statsFor(const [], today).thisWeek, 0);
    });

    test('a day is summarised by its first and last boarding and the stops used in order', () {
      final day = HistoryDay(DateTime(2026, 11, 5), [
        at(DateTime(2026, 11, 5, 17, 30), stop: 'B'),
        at(DateTime(2026, 11, 5, 12, 5), stop: 'A'),
        at(DateTime(2026, 11, 5, 7, 10), stop: 'A'),
      ]);
      final s = summarizeDay(day);
      expect(s.count, 3);
      expect(s.first, DateTime(2026, 11, 5, 7, 10));
      expect(s.last, DateTime(2026, 11, 5, 17, 30));
      expect(s.stops, ['A', 'B']);
    });
  });

  testWidgets('while the first page loads, grey shapes of the cards wait instead of a spinner', (tester) async {
    final history = FakeHistory(scans: [scan(1, at: DateTime.utc(2026, 11, 4, 8), stopId: 'stop1')])..hold = Completer<void>();
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), history: history),
        child: const StudentApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boarding history'));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(Skeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    history.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(Skeleton), findsNothing);
    expect(inDays('Carrefour Ekounou'), findsOneWidget);
  });

  testWidgets('two numbers sit on top: boardings this week and the most used stop', (tester) async {
    await openHistory(
      tester,
      FakeHistory(scans: [
        scan(1, at: DateTime.utc(2026, 11, 4, 17, 30), stopId: 'stop2', tripId: 'trip2'),
        scan(2, at: DateTime.utc(2026, 11, 4, 6, 40), stopId: 'stop2', tripId: 'trip1'),
        scan(3, at: DateTime.utc(2026, 10, 1, 6, 45), stopId: 'stop1', tripId: 'trip1'),
      ]),
      clock: TestClock(DateTime.utc(2026, 11, 5, 12)),
    );
    expect(find.text('Boardings this week'), findsOneWidget);
    expect(find.text('Most used stop'), findsOneWidget);
    expect(find.bySemanticsLabel('2 Boardings this week'), findsOneWidget);
    expect(find.text('2 boardings'), findsOneWidget, reason: 'a day card says how many');
  });

  testWidgets('on a landscape tablet the days are on the left and the chosen day is summarised on the right', (tester) async {
    await openHistory(
      tester,
      FakeHistory(scans: [
        scan(1, at: DateTime.utc(2026, 11, 4, 17), stopId: 'stop2', tripId: 'trip2'),
        scan(2, at: DateTime.utc(2026, 11, 4, 7), stopId: 'stop1', tripId: 'trip1'),
        scan(3, at: DateTime.utc(2026, 11, 3, 7), stopId: 'stop1', tripId: 'trip1'),
      ]),
      size: const Size(1280, 800),
      clock: TestClock(DateTime.utc(2026, 11, 5, 12)),
    );
    // The newest day is chosen at first, so its date is in the list and in the summary.
    expect(find.text('Wednesday, November 4, 2026'), findsNWidgets(2));
    final list = tester.getRect(find.text('Wednesday, November 4, 2026').first);
    final summaryTitle = tester.getRect(find.text('Selected day'));
    expect(summaryTitle.left, greaterThan(list.right), reason: 'the summary is in the right column');
    expect(find.text('First boarding'), findsOneWidget);
    expect(find.text('Last boarding'), findsOneWidget);

    // Tap the older day: the summary follows.
    await tester.tap(find.text('Tuesday, November 3, 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Tuesday, November 3, 2026'), findsNWidgets(2), reason: 'in the list and in the summary');
    expect(find.text('Wednesday, November 4, 2026'), findsOneWidget, reason: 'the summary moved away from it');
    expect(tester.takeException(), isNull);
  });

  for (final entry in {'a small phone': const Size(360, 640), 'a phone': const Size(412, 915), 'a portrait tablet': const Size(800, 1280), 'a landscape tablet': const Size(1280, 800)}.entries) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('lays out on ${entry.key} at text size $scale, in both languages', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        for (final locale in [const Locale('en'), const Locale('fr')]) {
          await openHistory(
            tester,
            FakeHistory(scans: [
              scan(1, at: DateTime.utc(2026, 11, 4, 17), stopId: 'stop2', tripId: 'trip2'),
              scan(2, at: DateTime.utc(2026, 11, 4, 7), stopId: 'stop1', tripId: 'trip1'),
              scan(3, at: DateTime.utc(2026, 11, 3, 7), stopId: null, tripId: 'trip1'),
            ]),
            size: entry.value,
            locale: locale,
            clock: TestClock(DateTime.utc(2026, 11, 5, 12)),
          );
          expect(tester.takeException(), isNull, reason: locale.languageCode);
        }
      });
    }
  }

  testWidgets('with no boardings it says so', (tester) async {
    await openHistory(tester, FakeHistory());
    expect(find.text('No boardings yet'), findsOneWidget);
  });

  testWidgets('boardings are grouped by the day at the school, with stop, direction and time', (tester) async {
    await openHistory(
      tester,
      FakeHistory(scans: [
        // 23:30 UTC on 4 Nov is 00:30 on 5 Nov in Douala.
        scan(1, at: DateTime.utc(2026, 11, 4, 23, 30), stopId: 'stop2', tripId: 'trip2'),
        scan(2, at: DateTime.utc(2026, 11, 4, 6, 40), stopId: 'stop1', tripId: 'trip1'),
        scan(3, at: DateTime.utc(2026, 11, 3, 6, 45), stopId: null, tripId: 'trip1'),
      ]),
    );

    expect(find.text('Thursday, November 5, 2026'), findsOneWidget);
    expect(find.text('Wednesday, November 4, 2026'), findsOneWidget);
    expect(find.text('Tuesday, November 3, 2026'), findsOneWidget);

    expect(inDays('Mvan'), findsOneWidget);
    expect(find.text('12:30 AM'), findsOneWidget);
    expect(find.text('Going home'), findsOneWidget, reason: 'trip2 is outbound');
    expect(inDays('Carrefour Ekounou'), findsOneWidget);
    expect(find.text('7:40 AM'), findsOneWidget);
    expect(find.text('Stop not recorded'), findsOneWidget);
  });

  testWidgets('a stop that is no longer active is still named', (tester) async {
    final backend = FakeBackend()..hiddenStops['old'] = stop('old', 'Old Market');
    await openHistory(tester, FakeHistory(scans: [scan(1, at: DateTime.utc(2026, 11, 4, 8), stopId: 'old')]), backend: backend);
    expect(inDays('Old Market'), findsOneWidget);
  });

  testWidgets('loads a page at a time as the list is scrolled, and stops at the end', (tester) async {
    final history = FakeHistory(scans: [for (var i = 0; i < 45; i++) scan(i, at: DateTime.utc(2026, 11, 4, 20).subtract(Duration(hours: i)))]);
    await openHistory(tester, history, size: const Size(800, 900));

    expect(history.offsets, [0], reason: 'only the first page up front');
    expect(history.limits, [20]);

    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -2500));
      await tester.pumpAndSettle();
    }
    expect(history.offsets, [0, 20, 40], reason: 'each page once, then it knows there is no more');
    expect(history.tripLookups, 3, reason: 'one trip request per page, not per row');
  });

  testWidgets('when the first page does not fill the screen the next one is loaded without scrolling', (tester) async {
    final history = FakeHistory(scans: [for (var i = 0; i < 25; i++) scan(i, at: DateTime.utc(2026, 11, 4, 20).subtract(Duration(hours: i)))]);
    await openHistory(tester, history, size: const Size(800, 4000));
    expect(history.offsets, [0, 20], reason: 'a tall screen shows all of page one, so page two is asked for at once');
  });

  testWidgets('a failed next page keeps the list and offers a retry', (tester) async {
    final history = FakeHistory(scans: [for (var i = 0; i < 25; i++) scan(i, at: DateTime.utc(2026, 11, 4, 20).subtract(Duration(hours: i)))])
      ..failOnceAtOffset = 20;
    await openHistory(tester, history, size: const Size(800, 900));

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -2500));
      await tester.pumpAndSettle();
    }
    expect(history.offsets, [0, 20], reason: 'the failure is not retried by scrolling');
    expect(find.text('Could not load more. Tap to try again.'), findsOneWidget);
    expect(find.text('Your boardings'), findsNothing, reason: 'scrolled past the title, the list is still there');

    await tester.tap(find.text('Could not load more. Tap to try again.'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load more. Tap to try again.'), findsNothing);
    expect(history.offsets, [0, 20, 20]);
  });

  testWidgets('a failed first page explains and can retry', (tester) async {
    final history = FakeHistory(scans: [scan(1, at: DateTime.utc(2026, 11, 4, 8))])..failAlways = const Offline('down');
    await openHistory(tester, history);
    expect(find.text('No connection. Check your network and try again.'), findsOneWidget);

    history.failAlways = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(inDays('Carrefour Ekounou'), findsOneWidget);
  });

  testWidgets('pulling down reloads from the first page', (tester) async {
    final history = FakeHistory(scans: [scan(1, at: DateTime.utc(2026, 11, 4, 8))]);
    await openHistory(tester, history);
    history.scans.insert(0, scan(2, at: DateTime.utc(2026, 11, 5, 8), stopId: 'stop2'));

    await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
    await tester.pumpAndSettle();
    expect(inDays('Mvan'), findsOneWidget);
    expect(history.offsets, [0, 0]);
  });

  testWidgets('speaks French', (tester) async {
    await openHistory(tester, FakeHistory(), locale: const Locale('fr'));
    expect(find.text('Aucun embarquement pour le moment'), findsOneWidget);
  });
}
