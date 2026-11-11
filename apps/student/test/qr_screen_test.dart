import 'dart:async';
import 'dart:typed_data';

import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/qr/boarding_code_image.dart';
import 'package:busin_student/src/providers.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

// 12:00:07 UTC: 23 seconds left in this 30-second window.
final noon = DateTime.utc(2026, 11, 5, 12, 0, 7);

// The test school is in Africa/Douala (UTC+1 all year).
DateTime doualaDate(DateTime instant) {
  final local = instant.toUtc().add(const Duration(hours: 1));
  return DateTime(local.year, local.month, local.day);
}

String codeAt(DateTime at, {String studentId = 'u1'}) =>
    QrCodeGenerator.generate(secret: testSecret(), studentId: studentId, now: at, schoolDate: doualaDate);

Future<void> openQr(
  WidgetTester tester, {
  FakeQr? qr,
  FakeSecretStore? store,
  FakeScreenSecurity? security,
  TestClock? clock,
  FakeBackend? backend,
  Locale locale = const Locale('en'),
  bool goToQr = true,
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(
        FakeAuthService(signedInAs: 'u1'),
        FakeProfileRepository({'u1': profile()}),
        backend: backend,
        qr: qr,
        store: store,
        security: security,
        clock: clock ?? TestClock(noon),
      ),
      child: const StudentApp(),
    ),
  );
  await tester.pumpAndSettle();
  if (goToQr) {
    await tester.tap(find.text('Code'));
    await tester.pumpAndSettle();
  }
}

String shownCode(WidgetTester tester) => tester.widget<BoardingCodeImage>(find.byKey(const ValueKey('boarding-code'))).data;

void main() {
  testWidgets('shows the code the database will accept for this student and moment', (tester) async {
    await openQr(tester);
    expect(shownCode(tester), codeAt(noon));
    expect(shownCode(tester), startsWith('busin2.u1.'));
    expect(find.text('Test Person'), findsOneWidget);
  });

  testWidgets('while it checks the subscription a skeleton the shape of the ticket waits, then the real page replaces it', (tester) async {
    final qr = FakeQr()..hold = Completer<void>();
    await openQr(tester, qr: qr, goToQr: false);
    await tester.tap(find.text('Code'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Skeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing, reason: 'not a lone spinner');
    expect(find.byKey(const ValueKey('boarding-code')), findsNothing);

    qr.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(Skeleton), findsNothing);
    expect(shownCode(tester), codeAt(noon));
  });

  testWidgets('on a landscape tablet it is two columns with the ticket alone in the right one', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), clock: TestClock(noon)),
        child: const StudentApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Code'));
    await tester.pumpAndSettle();

    final ticket = tester.getRect(find.byKey(const ValueKey('boarding-code')));
    final steps = tester.getRect(find.text('How to board'));
    final heading = tester.getRect(find.text('Boarding code').first);
    expect(ticket.center.dx, greaterThan(steps.center.dx), reason: 'the ticket is in the right column');
    expect(ticket.left, greaterThan(steps.right), reason: 'and nothing else shares that column');
    expect(heading.left, lessThan(ticket.left), reason: 'the heading is in the left column');
    expect(tester.takeException(), isNull);
  });

  testWidgets('no countdown is shown: the student does not need to know about it', (tester) async {
    await openQr(tester);
    expect(find.textContaining('New code in'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Live code'), findsOneWidget);
  });

  testWidgets('a new code appears when the 30-second window changes', (tester) async {
    final clock = TestClock(noon);
    await openQr(tester, clock: clock);
    final first = shownCode(tester);

    clock.now = DateTime.utc(2026, 11, 5, 12, 0, 31);
    await tester.pump(const Duration(seconds: 1));
    final second = shownCode(tester);

    expect(second, isNot(first));
    expect(second, codeAt(clock.now));
  });

  testWidgets('within a window the code stays the same', (tester) async {
    final clock = TestClock(noon);
    await openQr(tester, clock: clock);
    final first = shownCode(tester);
    clock.now = DateTime.utc(2026, 11, 5, 12, 0, 20);
    await tester.pump(const Duration(seconds: 1));
    expect(shownCode(tester), first);
  });

  testWidgets('the server is asked, the secret is kept for this user, and without a connection the kept one is used', (tester) async {
    final qr = FakeQr();
    final store = FakeSecretStore();
    await openQr(tester, qr: qr, store: store);
    expect(qr.fetches, 1);
    expect(store.data.keys, ['u1']);
    expect(store.data['u1'], testSecret());

    // Later with no network at all: the phone's own copy keeps the code working, because the saved pass says it is approved
    // for a semester that is running.
    final offline = FakeQr()..error = const Offline('down');
    await openQr(tester, qr: offline, store: store, backend: FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.approved)]));
    expect(offline.fetches, 1, reason: 'it asked first');
    expect(shownCode(tester), codeAt(noon));
  });

  testWidgets('a student whose subscription was taken away loses the code and the phone forgets the secret', (tester) async {
    final store = FakeSecretStore()..data['u1'] = testSecret();
    await openQr(tester, qr: FakeQr()..error = const NotAllowed('no sub'), store: store);

    expect(find.byKey(const ValueKey('boarding-code')), findsNothing, reason: 'the kept secret is not enough');
    expect(find.text('No active subscription'), findsOneWidget);
    expect(store.deleted, ['u1']);
    expect(store.data, isEmpty);
  });

  testWidgets('a refusal is asked once, not again and again in the background', (tester) async {
    final qr = FakeQr()..error = const NotAllowed('no sub');
    await openQr(tester, qr: qr);
    final after = qr.fetches;
    await tester.pump(const Duration(seconds: 30));
    expect(qr.fetches, after, reason: 'only the person asking again (Try again, pull down, coming back) asks again');
  });

  testWidgets('a server error is not a reason to show the kept code', (tester) async {
    final store = FakeSecretStore()..data['u1'] = testSecret();
    await openQr(tester, qr: FakeQr()..error = const Unexpected('boom'), store: store);
    expect(find.byKey(const ValueKey('boarding-code')), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    expect(store.data, isNotEmpty, reason: 'nothing was deleted: it may be a hiccup');
  });

  testWidgets('revoked while the code is on screen: it locks at once', (tester) async {
    final qr = FakeQr();
    final backend = FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.approved)]);
    final store = FakeSecretStore();
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), qr: qr, store: store, backend: backend, clock: TestClock(noon)),
        child: const StudentApp(),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(shownCode(tester), codeAt(noon));

    // The school revokes: the server now refuses, and the live feed tells the app.
    qr.error = const NotAllowed('revoked');
    final ended = subscription(status: SubscriptionStatus.revoked, note: 'Payment reversed');
    backend.mine[0] = ended;
    backend.emitLive([ended]);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byKey(const ValueKey('boarding-code')), findsNothing, reason: 'the pass is locked');
    expect(find.text('No active subscription'), findsOneWidget);
    expect(store.data, isEmpty);
    BusinToast.dismiss();
    await tester.pump();
  });

  testWidgets('coming back to the tab asks again, so a revoke while away is noticed', (tester) async {
    final qr = FakeQr();
    await openQr(tester, qr: qr);
    expect(shownCode(tester), codeAt(noon));

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    qr.error = const NotAllowed('revoked');
    await tester.tap(find.text('Code'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('boarding-code')), findsNothing);
    expect(find.text('No active subscription'), findsOneWidget);
  });

  testWidgets('another user\'s stored secret is never used', (tester) async {
    final qr = FakeQr();
    final store = FakeSecretStore()..data['someone-else'] = Uint8List.fromList(List.filled(32, 9));
    await openQr(tester, qr: qr, store: store);
    expect(qr.fetches, 1);
    expect(shownCode(tester), codeAt(noon));
  });

  testWidgets('no approved subscription: says so and leads to the subscription', (tester) async {
    final store = FakeSecretStore();
    await openQr(tester, qr: FakeQr()..error = const NotAllowed('no sub'), store: store);

    expect(find.text('No active subscription'), findsOneWidget);
    expect(find.byKey(const ValueKey('boarding-code')), findsNothing);
    expect(store.data, isEmpty);

    await tester.tap(find.text('Go to subscription'));
    await tester.pumpAndSettle();
    expect(find.text('Subscribe for Fall 2026').evaluate().isNotEmpty || find.text('No semester open yet').evaluate().isNotEmpty, isTrue);
  });

  testWidgets('coming back to the tab after the subscription was approved shows the code without a tap', (tester) async {
    final qr = FakeQr()..error = const NotAllowed('no sub');
    await openQr(tester, qr: qr);
    expect(find.text('No active subscription'), findsOneWidget);

    qr.error = null;
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Code'));
    await tester.pumpAndSettle();
    expect(shownCode(tester), codeAt(noon));
  });

  testWidgets('first use without a connection explains and can retry', (tester) async {
    final qr = FakeQr()..error = const Offline('down');
    await openQr(tester, qr: qr);
    expect(find.text('Connect once to set up your code'), findsOneWidget);

    qr.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(shownCode(tester), codeAt(noon));
  });

  testWidgets('an unexpected failure offers retry', (tester) async {
    await openQr(tester, qr: FakeQr()..error = const Unexpected('x'));
    expect(find.text('Something went wrong. Try again.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('screenshots are blocked only while this tab is showing', (tester) async {
    final security = FakeScreenSecurity();
    await openQr(tester, security: security, goToQr: false);
    expect(security.calls.where((c) => c), isEmpty, reason: 'not blocked on the first tab');

    await tester.tap(find.text('Code'));
    await tester.pumpAndSettle();
    expect(security.calls.last, isTrue);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(security.calls.last, isFalse);

    await tester.tap(find.text('Code'));
    await tester.pumpAndSettle();
    expect(security.calls.last, isTrue);
  });

  testWidgets('a reminder toast mentions screenshots only where blocking works, and shows once per session', (tester) async {
    Future<void> openTab(FakeScreenSecurity security) async {
      await openQr(tester, security: security, goToQr: false);
      await tester.tap(find.text('Code'));
      // Not settled: the toast leaves by itself after a few seconds.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    await openTab(FakeScreenSecurity());
    expect(find.text('Keep your code to yourself'), findsOneWidget);
    expect(find.textContaining('screenshots are turned off'), findsOneWidget);
    BusinToast.dismiss();
    await tester.pump();

    await openTab(FakeScreenSecurity(supported: false));
    expect(find.text('Keep your code to yourself'), findsOneWidget);
    expect(find.textContaining('screenshots are turned off'), findsNothing);
    BusinToast.dismiss();
    await tester.pump();
  });

  testWidgets('the code is drawn dark on white in the dark theme too', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await openQr(tester);
    final painter = tester.widget<CustomPaint>(find.descendant(of: find.byKey(const ValueKey('boarding-code')), matching: find.byType(CustomPaint)).first).painter! as ScrambleQrPainter;
    expect(painter.color, BoardingCodeImage.ink);
    expect(BoardingCodeImage.paper, Colors.white);
    expect(contrastRatio(BoardingCodeImage.ink, BoardingCodeImage.paper), greaterThan(12));
  });

  testWidgets('speaks French', (tester) async {
    await openQr(tester, locale: const Locale('fr'));
    expect(find.text('Code en direct'), findsOneWidget);
  });

  test('signing out forgets the stored secret before ending the session', () async {
    final auth = FakeAuthService(signedInAs: 'u1');
    final store = FakeSecretStore()..data['u1'] = testSecret();
    final container = ProviderContainer(overrides: overridesFor(auth, FakeProfileRepository({'u1': profile()}), store: store));
    addTearDown(container.dispose);

    await container.read(signOutProvider)();
    expect(store.deleteAllCalls, 1);
    expect(store.data, isEmpty);
    expect(auth.signOuts, 1);
  });
}
