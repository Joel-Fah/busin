import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/subscription/request_history.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

SubscriptionEvent event(int id, String sub, SubscriptionEventAction action, DateTime at, {String? note}) =>
    SubscriptionEvent(id: id, subscriptionId: sub, action: action, createdAt: at, note: note);

/// A request approved, then ended, then given back; and a later request that was declined.
FakeBackend busy() {
  final first = subscription(id: 'a', stopId: 'stop2', status: SubscriptionStatus.approved, createdAt: DateTime.utc(2026, 11, 1, 8));
  final second = subscription(id: 'b', stopId: 'stop2', status: SubscriptionStatus.rejected, note: 'Receipt unreadable', createdAt: DateTime.utc(2026, 11, 3, 8));
  final backend = FakeBackend(current: semester(), mine: [second, first]);
  backend.events.addAll([
    event(1, 'a', SubscriptionEventAction.requested, DateTime.utc(2026, 11, 1, 8)),
    event(2, 'a', SubscriptionEventAction.approved, DateTime.utc(2026, 11, 1, 9)),
    event(3, 'a', SubscriptionEventAction.revoked, DateTime.utc(2026, 11, 2, 9), note: 'Payment reversed'),
    event(4, 'a', SubscriptionEventAction.reinstated, DateTime.utc(2026, 11, 4, 9), note: 'Paid in cash'),
    event(5, 'b', SubscriptionEventAction.requested, DateTime.utc(2026, 11, 3, 8)),
    event(6, 'b', SubscriptionEventAction.rejected, DateTime.utc(2026, 11, 3, 10), note: 'Receipt unreadable'),
  ]);
  return backend;
}

Future<void> open(WidgetTester tester, FakeBackend backend, {Size size = const Size(800, 2400), Locale locale = const Locale('en')}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), backend: backend),
      child: const StudentApp(),
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  // The landing may have gone to the code: this page is on the subscription tab.
  await tester.tap(find.text(locale.languageCode == 'fr' ? 'Abonnement' : 'Subscription'));
  await tester.pumpAndSettle();
}

void main() {
  group('buildRequestHistory', () {
    test('the latest request comes first and, inside each, the latest operation', () {
      final a = subscription(id: 'a', createdAt: DateTime.utc(2026, 11, 1));
      final b = subscription(id: 'b', createdAt: DateTime.utc(2026, 11, 3));
      final history = buildRequestHistory([
        a,
        b
      ], [
        event(1, 'a', SubscriptionEventAction.requested, DateTime.utc(2026, 11, 1)),
        event(2, 'a', SubscriptionEventAction.approved, DateTime.utc(2026, 11, 2)),
        event(3, 'b', SubscriptionEventAction.requested, DateTime.utc(2026, 11, 3)),
      ]);
      expect(history.map((r) => r.subscription.id), ['b', 'a']);
      expect(history[1].events.map((e) => e.action), [SubscriptionEventAction.approved, SubscriptionEventAction.requested]);
      expect(history[0].events.single.subscriptionId, 'b', reason: 'operations stay with their own request');
    });

    test('operations at the same moment keep a stable order, the later one first', () {
      final a = subscription(id: 'a');
      final at = DateTime.utc(2026, 11, 3);
      final history = buildRequestHistory([a], [event(1, 'a', SubscriptionEventAction.requested, at), event(2, 'a', SubscriptionEventAction.approved, at)]);
      expect(history.single.events.first.action, SubscriptionEventAction.approved);
    });

    test('a request nothing is recorded for has an empty list', () {
      expect(buildRequestHistory([subscription(id: 'a')], const []).single.events, isEmpty);
    });
  });

  testWidgets('every request of the semester is an accordion, the latest open with its operations, the older closed', (tester) async {
    await open(tester, busy());
    expect(find.text('Your requests this semester'), findsOneWidget);
    expect(find.byType(BusinAccordion), findsNWidgets(2));

    // The latest request (declined) is open: its operations show, the older one's do not.
    expect(find.text('Your school declined it'), findsOneWidget);
    expect(find.text('Receipt unreadable'), findsWidgets);
    expect(find.text('Your school gave it back'), findsNothing);

    // Open the earlier one: all four operations, the latest first.
    await tester.tap(find.text('Request of Sun, Nov 1'));
    await tester.pumpAndSettle();
    final labels = ['Your school gave it back', 'Your school ended it', 'Your school approved it', 'You sent the request'];
    // The later request has a "You sent the request" of its own, higher up: the earlier one is the last on the page.
    final positions = [for (final l in labels) tester.getTopLeft(find.text(l).last).dy];
    expect(positions, orderedEquals([...positions]..sort()), reason: 'newest at the top');
    expect(find.text('Payment reversed'), findsOneWidget);
    expect(find.text('Paid in cash'), findsOneWidget);
  });

  testWidgets('a single request still shows its history', (tester) async {
    final backend = FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.pending)]);
    backend.events.add(event(1, 'sub1', SubscriptionEventAction.requested, DateTime.utc(2026, 11, 3, 9)));
    await open(tester, backend);
    expect(find.byType(BusinAccordion), findsOneWidget);
    expect(find.text('You sent the request'), findsOneWidget);
  });

  testWidgets('a student who never asked has no history section', (tester) async {
    await open(tester, FakeBackend(current: semester()));
    expect(find.text('Your requests this semester'), findsNothing);
  });

  testWidgets('a new request appears in the history at once', (tester) async {
    final backend = busy();
    await open(tester, backend);
    expect(find.byType(BusinAccordion), findsNWidgets(2));
    // The school gave the first one back while the app was open: the live feed refreshes everything.
    backend.events.add(event(7, 'a', SubscriptionEventAction.revoked, DateTime.utc(2026, 11, 5, 9), note: 'Again'));
    final ended = subscription(id: 'a', stopId: 'stop2', status: SubscriptionStatus.revoked, createdAt: DateTime.utc(2026, 11, 1, 8));
    backend.mine[1] = ended;
    backend.emitLive([backend.mine[0], ended]);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request of Sun, Nov 1'));
    await tester.pumpAndSettle();
    expect(find.text('Again'), findsOneWidget);
    BusinToast.dismiss();
    await tester.pump();
  });

  for (final entry in {'a small phone': const Size(360, 640), 'a landscape tablet': const Size(1280, 800)}.entries) {
    testWidgets('lays out on ${entry.key} at large text, in French', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester, busy(), size: entry.value, locale: const Locale('fr'));
      expect(find.text('Vos demandes ce semestre'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
