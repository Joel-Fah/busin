import 'package:busin_core/busin_core.dart';
import 'package:busin_app/busin_app.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/nav/tab_badges.dart';
import 'package:busin_student/src/push/push_routes.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

// Paying by mobile money in the student app (ADR 0029): the choice beside the receipt, the number and its operator, the
// price and the fee, the wait for the PIN, and how it ends.

Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> open(WidgetTester tester, FakeBackend backend, FakePayments payments, {FakeProofPicker? picker}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: overridesFor(
      FakeAuthService(signedInAs: 'u1'),
      FakeProfileRepository({'u1': profile()}),
      backend: backend,
      payments: payments,
      picker: picker,
      clock: TestClock(DateTime.utc(2026, 11, 14, 9)),
    ),
    child: const StudentApp(),
  ));
  await settle(tester);
  if (find.text('Boarding code').evaluate().isNotEmpty) {
    await tester.tap(find.text('Subscription').first);
    await settle(tester);
  }
}

Future<void> chooseStop(WidgetTester tester) async {
  await tester.tap(find.text('Your stop'));
  await settle(tester, 4);
  await tester.tap(find.text('Carrefour Vogt'));
  await settle(tester, 4);
}

/// The Pay button of the sheet, whose label carries the total.
Finder payButton() => find.byWidgetPredicate((w) => w is BusinButton && w.label.startsWith('Pay ') && w.label.endsWith('XAF'));

Future<void> askAndOpenPayment(WidgetTester tester) async {
  await chooseStop(tester);
  await tester.ensureVisible(find.text('Pay now'));
  await tester.tap(find.text('Pay now'));
  await settle(tester);
}

void main() {
  testWidgets('where the school offers it, mobile money comes first and needs no receipt', (tester) async {
    final backend = FakeBackend(current: semester());
    final payments = FakePayments(mobileMoney: true);
    await open(tester, backend, payments);

    expect(find.text('How will you pay?'), findsOneWidget);
    expect(find.text('Payment proof'), findsNothing, reason: 'paying in the app needs no photo of a receipt');

    await askAndOpenPayment(tester);
    expect(backend.requests.single.paymentMethod, PaymentMethod.mobileMoney);
    expect(backend.requests.single.proofPath, isNull);

    // The student's own number is filled in, and its operator recognised.
    expect(find.text('6 77 12 34 56'), findsOneWidget);
    expect(find.text('MTN MoMo'), findsOneWidget);
    expect(find.text('Mobile money fee'), findsOneWidget);
    expect(find.text('30,690 XAF'), findsWidgets);

    await tester.tap(payButton());
    await settle(tester);
    expect(payments.started.single.phone, '237677123456');
    // Recognised, not picked: pawaPay confirms the operator itself.
    expect(payments.started.single.operator, isNull);
    expect(find.text('Check your phone'), findsOneWidget);

    payments.finish('pay1', PaymentStatus.completed);
    await settle(tester);
    expect(find.text('Payment received'), findsOneWidget);
    expect(find.text('Your bus pass is active.'), findsOneWidget);
    expect(find.text('Receipt BI-2026-000042'), findsOneWidget);
  });

  testWidgets('another number is recognised as it is typed, and the operator can be changed', (tester) async {
    final payments = FakePayments(mobileMoney: true);
    await open(tester, FakeBackend(current: semester()), payments);
    await askAndOpenPayment(tester);

    await tester.enterText(find.byType(TextField).last, '69');
    await settle(tester, 2);
    expect(find.text('Orange Money'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '662 00 11 2');
    await settle(tester, 2);
    expect(find.text('Which operator is this number with?'), findsOneWidget);
    expect(payButton(), findsOneWidget);
    expect(tester.widget<BusinButton>(payButton()).onPressed, isNull, reason: 'not a valid number yet');

    await tester.enterText(find.byType(TextField).last, '662 00 11 22');
    await tester.tap(find.byTooltip('Orange Money'));
    await settle(tester, 2);
    await tester.tap(payButton());
    await settle(tester);
    expect(payments.started.single.operator, MobileMoneyOperator.orange, reason: 'picked by the student, so sent');
  });

  testWidgets('a payment that does not go through says why, that nothing was taken, and can be tried again', (tester) async {
    final payments = FakePayments(mobileMoney: true);
    await open(tester, FakeBackend(current: semester()), payments);
    await askAndOpenPayment(tester);
    await tester.tap(payButton());
    await settle(tester);

    payments.finish('pay1', PaymentStatus.failed, failureCode: 'PAYMENT_NOT_APPROVED');
    await settle(tester);
    expect(find.text('Payment not completed'), findsOneWidget);
    expect(find.textContaining('not confirmed with your PIN'), findsOneWidget);
    expect(find.textContaining('Nothing was taken'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await settle(tester);
    await tester.tap(payButton());
    await settle(tester);
    expect(payments.started, hasLength(2));
  });

  testWidgets('when mobile money cannot be used, the student is told a receipt still works', (tester) async {
    final payments = FakePayments(mobileMoney: true)..startError = const Unexpected('function 503', reason: 'payments_unavailable');
    await open(tester, FakeBackend(current: semester()), payments);
    await askAndOpenPayment(tester);
    await tester.tap(payButton());
    await settle(tester);
    expect(find.text('Mobile money is not available right now. You can upload a receipt instead.'), findsOneWidget);
  });

  testWidgets('a request waiting for its payment says so, and takes a receipt instead', (tester) async {
    final backend = FakeBackend(current: semester(), mine: [subscription(paymentMethod: PaymentMethod.mobileMoney)]);
    final picker = FakeProofPicker(samplePhoto());
    await open(tester, backend, FakePayments(mobileMoney: true), picker: picker);

    expect(find.text('Waiting for your payment'), findsOneWidget);
    expect(find.text('Pay now'), findsOneWidget);
    await tester.ensureVisible(find.text('Send a receipt instead'));
    await tester.tap(find.text('Send a receipt instead'));
    await settle(tester, 4);
    await tester.tap(find.text('Choose from gallery'));
    await settle(tester);
    expect(backend.attached['sub1'], startsWith('s1/u1/'));
  });

  testWidgets('without mobile money at the school, the form is the receipt one as before', (tester) async {
    await open(tester, FakeBackend(current: semester()), FakePayments());
    expect(find.text('How will you pay?'), findsNothing);
    expect(find.text('Payment proof'), findsOneWidget);
  });

  test('a notification about a payment or a refund opens the subscription tab and marks it', () {
    for (final kind in ['payment_completed', 'payment_failed', 'refund_completed', 'refund_failed']) {
      expect(routeForPush(PushMessage(kind: kind, refId: 'pay1')), '/subscription', reason: kind);
      expect(tabsForPush(kind), contains(StudentTabs.subscription), reason: kind);
    }
    // A completed payment activates the pass: the code tab too.
    expect(tabsForPush('payment_completed'), contains(StudentTabs.code));
  });
}
