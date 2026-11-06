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

String codeAt(DateTime at, {String studentId = 'u1'}) => QrCodeGenerator.generate(secret: testSecret(), studentId: studentId, now: at);

Future<void> openQr(
  WidgetTester tester, {
  FakeQr? qr,
  FakeSecretStore? store,
  FakeScreenSecurity? security,
  TestClock? clock,
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
    expect(shownCode(tester), startsWith('busin1.u1.'));
    expect(find.text('Test Person'), findsOneWidget);
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

  testWidgets('fetches the secret once, keeps it for this user, and later needs no connection', (tester) async {
    final qr = FakeQr();
    final store = FakeSecretStore();
    await openQr(tester, qr: qr, store: store);
    expect(qr.fetches, 1);
    expect(store.data.keys, ['u1']);
    expect(store.data['u1'], testSecret());

    // A later start finds it on the phone, even with the network gone.
    final offline = FakeQr()..error = const Offline('down');
    await openQr(tester, qr: offline, store: store);
    expect(offline.fetches, 0);
    expect(shownCode(tester), codeAt(noon));
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
