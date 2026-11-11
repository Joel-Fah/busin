import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/boarding/boarding_binder.dart';
import 'package:busin_student/src/boarding/boarding_card.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

Future<FakeHistory> start(WidgetTester tester, {NotificationPreferences prefs = const NotificationPreferences(), Map<String, Object> saved = const {}}) async {
  SharedPreferences.setMockInitialValues(saved);
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final history = FakeHistory();
  await tester.pumpWidget(
    ProviderScope(
      overrides: overridesFor(
        FakeAuthService(signedInAs: 'u1'),
        FakeProfileRepository({'u1': profile()}),
        backend: FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.approved)]),
        history: history,
        notificationPreferences: FakeNotificationPreferences(prefs),
      ),
      child: const StudentApp(),
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  BusinToast.dismiss();
  return history;
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  testWidgets('the moment the code is scanned, the card says on board with a line, then closes by itself', (tester) async {
    final history = await start(tester);
    history.latest.add(null); // nothing yet on first arrival
    await settle(tester);
    expect(find.text('On board'), findsNothing);

    history.latest.add(scan(1, at: DateTime.now().toUtc()));
    await settle(tester);
    expect(find.text('On board'), findsOneWidget);
    final line = tester.widget<BoardingCard>(find.byType(BoardingCard)).line;
    expect(allBoardingLines('en'), contains(line));

    await tester.pump(const Duration(seconds: 5));
    await settle(tester);
    expect(find.text('On board'), findsNothing, reason: 'it closes by itself');
  });

  testWidgets('the tenth ride of the semester gets its milestone line', (tester) async {
    final history = await start(tester);
    history.ridesThisSemester = 10;
    history.latest.add(null);
    await settle(tester);
    history.latest.add(scan(2, at: DateTime.now().toUtc()));
    await settle(tester);
    expect(find.text('Ten rides this semester. You know the way by now.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a boarding missed while offline is told quietly with its time; one already told is not told again', (tester) async {
    final recent = DateTime.now().toUtc().subtract(const Duration(minutes: 40));
    final history = await start(tester);
    history.latest.add(scan(3, at: recent));
    await settle(tester);
    expect(find.textContaining('You boarded at'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);

    final again = await start(tester, saved: {seenBoardingKey('u1'): 'scan3'});
    again.latest.add(scan(3, at: recent));
    await settle(tester);
    expect(find.textContaining('You boarded at'), findsNothing);
  });

  testWidgets('a student who turned boarding messages off sees nothing', (tester) async {
    final history = await start(tester, prefs: const NotificationPreferences(boardingMessagesOn: false));
    history.latest.add(null);
    await settle(tester);
    history.latest.add(scan(4, at: DateTime.now().toUtc()));
    await settle(tester);
    expect(find.text('On board'), findsNothing);
  });
}
