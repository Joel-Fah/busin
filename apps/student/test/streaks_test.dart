import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/streaks/streak_providers.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

Future<void> start(WidgetTester tester, FakeProfileRepository profiles, FakeStreaks streaks) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overridesFor(
        FakeAuthService(signedInAs: 'u1'),
        profiles,
        backend: FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.approved)]),
        streaks: streaks,
      ),
      child: const StudentApp(),
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  BusinToast.dismiss();
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  test('the leaderboard name is the first name and the initial of the last', () {
    expect(leaderboardName('Amara Ngono Ekotto'), 'Amara E.');
    expect(leaderboardName('  Kofi  '), 'Kofi');
    expect(leaderboardName(''), '');
  });

  testWidgets('a student who keeps a streak sees it on the pass, and its calendar', (tester) async {
    final profiles = FakeProfileRepository({'u1': profile(streakOptIn: true)});
    final streaks = FakeStreaks(profiles, current: const Streak(current: 4, best: 6, rides: 12), days: [
      RideDay(DateTime(2026, 11, 9), RideDayState.rode),
      RideDay(DateTime(2026, 11, 10), RideDayState.missed),
      RideDay(DateTime(2026, 11, 11), RideDayState.today),
    ]);
    await start(tester, profiles, streaks);
    await tester.tap(find.text('Code'));
    await settle(tester);
    expect(find.text('4-day streak'), findsOneWidget);

    await tester.tap(find.text('4-day streak'));
    await settle(tester);
    expect(find.text('Your streak'), findsOneWidget);
    expect(find.text('Best 6'), findsOneWidget);
    expect(find.text('12 rides this semester'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('November 10, Missed')), findsOneWidget);
  });

  testWidgets('without a streak the pass shows no chip; turning it on explains the leaderboard first', (tester) async {
    final profiles = FakeProfileRepository({'u1': profile(streakOptIn: false)});
    final streaks = FakeStreaks(profiles, current: const Streak(current: 0, best: 0, rides: 0));
    await start(tester, profiles, streaks);
    await tester.tap(find.text('Code'));
    await settle(tester);
    expect(find.textContaining('streak'), findsNothing);

    await tester.tap(find.text('Profile'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Streaks'), 300, scrollable: find.byType(Scrollable).first);
    final row = find.ancestor(of: find.text('Streaks'), matching: find.byType(Row)).first;
    await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
    await settle(tester);
    expect(find.textContaining("leaderboard as Test P."), findsOneWidget);
    await tester.tap(find.text('Turn on streaks'));
    await settle(tester);
    expect(streaks.optIns, [true]);
  });
}
