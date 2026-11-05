import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/history/history_providers.dart';
import 'package:busin_student/src/school_clock.dart';
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
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), history: history, backend: backend),
      child: const StudentApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(locale.languageCode == 'fr' ? 'Historique' : 'History'));
  await tester.pumpAndSettle();
}

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

    expect(find.text('Mvan'), findsOneWidget);
    expect(find.text('12:30 AM'), findsOneWidget);
    expect(find.text('Going home'), findsOneWidget, reason: 'trip2 is outbound');
    expect(find.text('Carrefour Ekounou'), findsOneWidget);
    expect(find.text('7:40 AM'), findsOneWidget);
    expect(find.text('Stop not recorded'), findsOneWidget);
  });

  testWidgets('a stop that is no longer active is still named', (tester) async {
    final backend = FakeBackend()..hiddenStops['old'] = stop('old', 'Old Market');
    await openHistory(tester, FakeHistory(scans: [scan(1, at: DateTime.utc(2026, 11, 4, 8), stopId: 'old')]), backend: backend);
    expect(find.text('Old Market'), findsOneWidget);
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
    expect(find.text('Carrefour Ekounou'), findsOneWidget);
  });

  testWidgets('pulling down reloads from the first page', (tester) async {
    final history = FakeHistory(scans: [scan(1, at: DateTime.utc(2026, 11, 4, 8))]);
    await openHistory(tester, history);
    history.scans.insert(0, scan(2, at: DateTime.utc(2026, 11, 5, 8), stopId: 'stop2'));

    await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
    await tester.pumpAndSettle();
    expect(find.text('Mvan'), findsOneWidget);
    expect(history.offsets, [0, 0]);
  });

  testWidgets('speaks French', (tester) async {
    await openHistory(tester, FakeHistory(), locale: const Locale('fr'));
    expect(find.text('Aucun embarquement pour le moment'), findsOneWidget);
  });
}
