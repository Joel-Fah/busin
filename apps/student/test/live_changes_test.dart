import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/subscription/live_changes.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> open(WidgetTester tester, FakeBackend backend, FakePushService push, {FakeAuthService? auth}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(auth ?? FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), backend: backend, push: push),
      child: const StudentApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('changesSince', () {
    final a = subscription(id: 'a', status: SubscriptionStatus.pending);

    test('the first arrival only fills what is known', () {
      final known = <String, SubscriptionStatus>{};
      expect(changesSince(known, [a], first: true), isEmpty);
      expect(known['a'], SubscriptionStatus.pending);
    });

    test('a different status is a change, the same one is not', () {
      final known = {'a': SubscriptionStatus.pending};
      expect(changesSince(known, [a], first: false), isEmpty);
      final approved = subscription(id: 'a', status: SubscriptionStatus.approved);
      final changes = changesSince(known, [approved], first: false);
      expect(changes.single.status, SubscriptionStatus.approved);
      expect(known['a'], SubscriptionStatus.approved);
    });

    test('a subscription that was not there before is a change', () {
      final known = <String, SubscriptionStatus>{};
      expect(changesSince(known, [a], first: false).length, 1);
    });
  });

  testWidgets('while the app is open, an approval shows at once: the screens refresh and a toast says so', (tester) async {
    final backend = FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.pending)]);
    await open(tester, backend, FakePushService());
    expect(find.text('You are subscribed'), findsNothing);
    expect(backend.liveListeners, 1, reason: 'one live feed, for this student');

    // The school approves: the database changes and the live feed delivers the row.
    final approved = subscription(stopId: 'stop2', status: SubscriptionStatus.approved);
    backend.mine[0] = approved;
    backend.emitLive([approved]);
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Your subscription was approved.'), findsOneWidget);
    expect(find.text('You are subscribed'), findsOneWidget, reason: 'the subscription tab was read again without a tap');
    BusinToast.dismiss();
    await tester.pump();
  });

  testWidgets('a push and the live feed arriving together say it once', (tester) async {
    final push = FakePushService();
    final backend = FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.pending)]);
    await open(tester, backend, push);

    final approved = subscription(stopId: 'stop2', status: SubscriptionStatus.approved);
    backend.mine[0] = approved;
    backend.emitLive([approved]);
    await tester.pump();
    push.arrived.add(PushMessage(kind: 'subscription_approved', refId: approved.id));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Your subscription was approved.'), findsOneWidget, reason: 'the toast');
    expect(find.byType(SnackBar), findsNothing, reason: 'the push did not repeat it');
    BusinToast.dismiss();
    await tester.pump();
  });

  testWidgets('an ended subscription is told too', (tester) async {
    final backend = FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.approved)]);
    await open(tester, backend, FakePushService());
    BusinToast.dismiss();
    await tester.pump();

    final ended = subscription(stopId: 'stop2', status: SubscriptionStatus.revoked, note: 'Payment was reversed.');
    backend.mine[0] = ended;
    backend.emitLive([ended]);
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Your school ended your subscription.'), findsOneWidget);
    BusinToast.dismiss();
    await tester.pump();
  });

  testWidgets('a subscription given back says so, and a push for it does not repeat it', (tester) async {
    final push = FakePushService();
    final backend = FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.revoked, note: 'Payment reversed')]);
    await open(tester, backend, push);

    final back = subscription(stopId: 'stop2', status: SubscriptionStatus.approved);
    backend.mine[0] = back;
    backend.emitLive([back]);
    await tester.pump();
    push.arrived.add(PushMessage(kind: 'subscription_approved', refId: back.id));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Your school gave your subscription back.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    BusinToast.dismiss();
    await tester.pump();
  });

  test('an approval after an ending is a reinstatement', () {
    final known = {'a': SubscriptionStatus.revoked};
    final change = changesSince(known, [subscription(id: 'a', status: SubscriptionStatus.approved)], first: false).single;
    expect(change.isReinstatement, isTrue);
    expect(changesSince({'a': SubscriptionStatus.pending}, [subscription(id: 'a', status: SubscriptionStatus.approved)], first: false).single.isReinstatement, isFalse);
  });

  testWidgets('nobody signed in, nothing is followed', (tester) async {
    final backend = FakeBackend(current: semester());
    await open(tester, backend, FakePushService(), auth: FakeAuthService());
    expect(backend.liveListeners, 0);
  });
}
