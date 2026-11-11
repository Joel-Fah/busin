import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/reminders/reminder_plan.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  group('planning reminders', () {
    // Wednesday 11 November 2026, 07:00 at the school.
    final now = DateTime(2026, 11, 11, 7);
    final semesterStart = DateTime(2026, 9, 1);
    final semesterEnd = DateTime(2027, 1, 31);

    test('mornings on weekdays only, from tomorrow since this morning has passed', () {
      final plan = planReminders(preferences: const NotificationPreferences(), semesterStart: semesterStart, semesterEnd: semesterEnd, now: now, days: 7);
      expect(plan.map((r) => r.at.weekday).toSet(), {DateTime.monday, DateTime.tuesday, DateTime.thursday, DateTime.friday});
      expect(plan.every((r) => r.kind == ReminderKind.morning && r.at.hour == 6 && r.at.minute == 30), isTrue);
      expect(plan.first.at, DateTime(2026, 11, 12, 6, 30), reason: 'today at 6:30 is already past');
      expect(plan.length, 4, reason: 'Thursday, Friday, Monday, Tuesday within seven days from Wednesday');
    });

    test('an evening reminder later today is still placed, and the student\'s own days count', () {
      const prefs = NotificationPreferences(ridingDays: {DateTime.wednesday, DateTime.saturday}, morningOn: false, eveningOn: true, eveningTime: TimeOfDayValue(17, 15));
      final plan = planReminders(preferences: prefs, semesterStart: semesterStart, semesterEnd: semesterEnd, now: now, days: 7);
      expect(plan.map((r) => r.at), [DateTime(2026, 11, 11, 17, 15), DateTime(2026, 11, 14, 17, 15)]);
      expect(plan.map((r) => r.id).toSet().length, plan.length, reason: 'ids are unique');
    });

    test('nothing outside the semester, nothing when everything is off', () {
      final ending = planReminders(preferences: const NotificationPreferences(), semesterStart: semesterStart, semesterEnd: DateTime(2026, 11, 13), now: now);
      expect(ending.map((r) => r.at.day), [12, 13]);
      final notYet = planReminders(preferences: const NotificationPreferences(), semesterStart: DateTime(2027, 2, 1), semesterEnd: DateTime(2027, 6, 1), now: now);
      expect(notYet, isEmpty);
      expect(planReminders(preferences: const NotificationPreferences(morningOn: false), semesterStart: semesterStart, semesterEnd: semesterEnd, now: now), isEmpty);
    });
  });

  group('the notifications page', () {
    Future<(FakeNotificationPreferences, FakeReminderScheduler)> openPage(WidgetTester tester, {bool approved = true}) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final prefs = FakeNotificationPreferences();
      final reminders = FakeReminderScheduler();
      final backend = FakeBackend(current: semester(), mine: [subscription(status: approved ? SubscriptionStatus.approved : SubscriptionStatus.pending)]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), backend: backend, notificationPreferences: prefs, reminders: reminders),
          child: const StudentApp(),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      BusinToast.dismiss();
      await tester.tap(find.text('Profile'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.scrollUntilVisible(find.text('Notifications'), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Notifications'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      return (prefs, reminders);
    }

    testWidgets('an approved student gets morning reminders placed, and changes are saved and placed again', (tester) async {
      final (prefs, reminders) = await openPage(tester);
      expect(find.text('My bus days'), findsOneWidget);
      expect(find.text('From your school'), findsOneWidget, reason: 'school notices are listed, always on');
      expect(reminders.placed, isNotEmpty, reason: 'weekday mornings in the running semester');
      expect(reminders.zone, 'Africa/Douala');

      // Turn the evening reminder on.
      await tester.tap(find.byType(Switch).at(1));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(prefs.stored.eveningOn, isTrue);
      expect(reminders.placed.any((r) => r.kind == ReminderKind.evening), isTrue);
      expect(reminders.samples.single.title, 'Heading home?', reason: 'an example of the evening reminder is shown at once');
      BusinToast.dismiss();
    });

    testWidgets('no example without the permission, and turning one off sends none', (tester) async {
      final (prefs, reminders) = await openPage(tester);
      reminders.allow = false;
      await tester.tap(find.byType(Switch).at(1));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(reminders.samples, isEmpty);
      await tester.tap(find.byType(Switch).first);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(prefs.stored.morningOn, isFalse);
      expect(reminders.samples, isEmpty);
      BusinToast.dismiss();
    });

    testWidgets('without an approved subscription nothing is placed', (tester) async {
      final (_, reminders) = await openPage(tester, approved: false);
      expect(reminders.replaced, greaterThan(0));
      expect(reminders.placed, isEmpty);
    });
  });
}
