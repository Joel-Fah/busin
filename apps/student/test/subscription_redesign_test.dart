import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/greeting.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> run(
  WidgetTester tester,
  Size size, {
  FakeBackend? backend,
  TestClock? clock,
  double textScale = 1,
  Locale locale = const Locale('en'),
  Profile? who,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(
        FakeAuthService(signedInAs: 'u1'),
        FakeProfileRepository({'u1': who ?? profile()}),
        backend: backend ?? FakeBackend(current: semester()),
        clock: clock,
      ),
      child: const StudentApp(),
    ),
  );
  await tester.pumpAndSettle();
  // A student with an approved subscription opens on the boarding code; these tests look at the subscription tab.
  final tab = find.text('Subscription');
  if (tab.evaluate().isNotEmpty) {
    await tester.tap(tab.first);
    await tester.pumpAndSettle();
  }
}

void main() {
  group('greeting', () {
    test('follows the hour at the school', () {
      expect(greetingForHour(0), Greeting.morning);
      expect(greetingForHour(11), Greeting.morning);
      expect(greetingForHour(12), Greeting.afternoon);
      expect(greetingForHour(17), Greeting.afternoon);
      expect(greetingForHour(18), Greeting.evening);
      expect(greetingForHour(23), Greeting.evening);
    });

    test('takes the first word of a name, and nothing when there is none', () {
      expect(firstNameOf('  Joel Fah '), 'Joel');
      expect(firstNameOf('Madonna'), 'Madonna');
      expect(firstNameOf(''), '');
    });

    testWidgets('the banner greets by first name for the hour at the school, not the phone', (tester) async {
      // 22:30 UTC is 23:30 in Douala (evening); 06:30 UTC is 07:30 (morning).
      await run(tester, const Size(412, 915), clock: TestClock(DateTime.utc(2026, 11, 5, 22, 30)));
      expect(find.text('Good evening, Test'), findsOneWidget);

      await run(tester, const Size(412, 915), clock: TestClock(DateTime.utc(2026, 11, 5, 6, 30)));
      expect(find.text('Good morning, Test'), findsOneWidget);

      await run(tester, const Size(412, 915), clock: TestClock(DateTime.utc(2026, 11, 5, 13, 0)), locale: const Locale('fr'));
      expect(find.text('Bon après-midi, Test'), findsOneWidget);
    });
  });

  group('the stage line', () {
    testWidgets('a pending request is being checked', (tester) async {
      await run(tester, const Size(412, 915), backend: FakeBackend(current: semester(), mine: [subscription()]));
      expect(find.bySemanticsLabel('Step 1 of 3: Sent'), findsOneWidget);
      expect(find.bySemanticsLabel('Step 2 of 3: Checking'), findsOneWidget);
      expect(find.bySemanticsLabel('Step 3 of 3: Decision'), findsOneWidget);
    });

    testWidgets('a rejection shows the reason in a notice, with the stage line ending badly', (tester) async {
      await run(tester, const Size(412, 915), backend: FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.rejected, note: 'The receipt is unreadable.')]));
      expect(find.byType(Notice), findsOneWidget);
      expect(find.text('The receipt is unreadable.'), findsOneWidget);
      expect(find.byType(StepLine), findsOneWidget);
    });

    testWidgets('an approved subscription is all done and offers the boarding code', (tester) async {
      await run(tester, const Size(412, 915), backend: FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.approved)]));
      expect(find.byType(StepLine), findsOneWidget);
      expect(find.text('Show boarding code'), findsOneWidget);
    });

    testWidgets('an expired one has no stage line, only the way to ask again', (tester) async {
      await run(tester, const Size(412, 915), backend: FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.expired)]));
      expect(find.byType(StepLine), findsNothing);
      expect(find.text('Request again'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('the how-it-works guide appears beside the form on a wide screen and not on a phone', (tester) async {
      await run(tester, const Size(1280, 800));
      expect(find.text('How it works'), findsOneWidget);
      expect(find.text('Add a photo of your payment receipt.'), findsOneWidget);
      // Side by side: the guide sits to the right of the form.
      expect(tester.getTopLeft(find.text('How it works')).dx, greaterThan(tester.getTopLeft(find.text('Your stop')).dx));

      await run(tester, const Size(412, 915));
      expect(find.text('How it works'), findsNothing);
    });

    final sizes = {
      'a small phone': const Size(360, 640),
      'a phone': const Size(412, 915),
      'a portrait tablet': const Size(800, 1280),
      'a landscape tablet': const Size(1280, 800),
    };
    final states = <String, FakeBackend Function()>{
      'the form': () => FakeBackend(current: semester()),
      'an upcoming semester': () => FakeBackend(next: semester(start: '2030-09-01', end: '2031-01-31')),
      'pending': () => FakeBackend(current: semester(), mine: [subscription(proofPath: 's1/u1/a.jpg')]),
      'approved': () => FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.approved)]),
      'rejected': () => FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.rejected, note: 'A long reason that needs more than one line to be said in full on a narrow phone screen.')]),
      'expired': () => FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.expired)]),
      'no semester': () => FakeBackend(),
    };

    for (final size in sizes.entries) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('every state lays out on ${size.key} at text size $scale, in both languages', (tester) async {
          for (final state in states.entries) {
            for (final locale in [const Locale('en'), const Locale('fr')]) {
              await run(tester, size.value, backend: state.value(), textScale: scale, locale: locale);
              expect(tester.takeException(), isNull, reason: '${state.key} on ${size.key} at $scale in ${locale.languageCode}');
            }
          }
        });
      }
    }
  });
}
