import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/push/push_routes.dart';
import 'package:busin_student/src/subscription/billing_choices.dart';
import 'package:busin_student/src/subscription/request_history.dart';
import 'package:busin_student/src/subscription/subscription_providers.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

// School billing in the student app (ADR 0022): the price, the month, how the student pays, the preference, the parts.

const installmentsSchool = School(
  id: 's1',
  name: 'Test School',
  timezone: 'Africa/Douala',
  isActive: true,
  billingPeriod: BillingPeriod.semester,
  priceXaf: 30000,
  installmentPlan: InstallmentPlan.thirds,
);
const monthlySchool = School(id: 's1', name: 'Test School', timezone: 'Africa/Douala', isActive: true, billingPeriod: BillingPeriod.month, priceXaf: 5000);

/// 14 November 2026, mid-morning in Douala.
final midNovember = DateTime.utc(2026, 11, 14, 9);

Subscription monthOf(String id, int month, {SubscriptionStatus status = SubscriptionStatus.approved}) => Subscription.fromJson({
      ...subscription(id: id, status: status).toJson(),
      'billing_period': 'month',
      'amount_xaf': 5000,
      'period_start': '2026-${'$month'.padLeft(2, '0')}-01',
      'period_end': '2026-${'$month'.padLeft(2, '0')}-${month == 11 ? 30 : 31}',
    });

Installment part(int seq, {String status = 'due', String due = '2026-12-01'}) => Installment.fromJson({
      'id': 'part$seq',
      'subscription_id': 'sub1',
      'seq': seq,
      'percent': seq == 1 ? 40 : 30,
      'amount_xaf': seq == 1 ? 12000 : 9000,
      'due_date': due,
      'status': status,
    });

Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> open(
  WidgetTester tester,
  FakeBackend backend, {
  FakeProfileRepository? profiles,
  FakeProofPicker? picker,
  FakeInstallments? installments,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: overridesFor(
      FakeAuthService(signedInAs: 'u1'),
      profiles ?? FakeProfileRepository({'u1': profile()}),
      backend: backend,
      picker: picker,
      installments: installments,
      clock: TestClock(midNovember),
    ),
    child: const StudentApp(),
  ));
  await settle(tester);
  if (find.text('Boarding code').evaluate().isNotEmpty) {
    await tester.tap(find.text('Subscription').first);
    await settle(tester);
  }
}

Future<void> fillRequest(WidgetTester tester) async {
  await tester.tap(find.text('Your stop'));
  await settle(tester, 4);
  await tester.tap(find.text('Carrefour Vogt'));
  await settle(tester, 4);
  await tester.tap(find.text('Payment proof'));
  await settle(tester, 4);
  await tester.tap(find.text('Choose from gallery'));
  await settle(tester, 4);
}

Future<void> send(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Send request'));
  await tester.tap(find.text('Send request'));
  await settle(tester);
}

void main() {
  group('the rules', () {
    final fall = semester();
    test('a month can be asked for this month and the next, inside the semester, not twice', () {
      expect(monthChoices(semester: fall, today: DateTime(2026, 11, 14), live: const []), [DateTime.utc(2026, 11), DateTime.utc(2026, 12)]);
      expect(monthChoices(semester: fall, today: DateTime(2026, 11, 14), live: [monthOf('a', 11)]), [DateTime.utc(2026, 12)]);
      // The semester ends on 31 January: February is not offered.
      expect(monthChoices(semester: fall, today: DateTime(2027, 1, 20), live: const []), [DateTime.utc(2027, 1)]);
    });

    test('a month that has ended is no longer live: the form offers the new one', () {
      final october = monthOf('oct', 10);
      expect(stillRunning(october, DateTime(2026, 11, 1)), isFalse);
      expect(subscriptionToShow([october], 'sem1', today: DateTime(2026, 11, 1)), isNull);
      expect(subscriptionToShow([monthOf('dec', 12, status: SubscriptionStatus.pending), monthOf('nov', 11)], 'sem1', today: DateTime(2026, 11, 14))!.id, 'nov',
          reason: 'this month first, next month after it');
    });

    test('the pass stops at the end of its month', () {
      final overview = SubscriptionOverview(semester: fall, subscription: monthOf('nov', 11));
      expect(overview.passUsable(DateTime(2026, 11, 30)), isTrue);
      expect(overview.passUsable(DateTime(2026, 12, 1)), isFalse);
    });

    test('what is paid with the request', () {
      expect(dueNow(price: 30000, plan: InstallmentPlan.thirds, mode: PaymentMode.installments), 12000);
      expect(dueNow(price: 30000, plan: InstallmentPlan.thirds, mode: PaymentMode.full), 30000);
    });

    test('payment notifications open the subscription tab', () {
      for (final kind in ['installment_paid', 'installment_rejected', 'installment_due']) {
        expect(routeForPush(PushMessage(kind: kind, refId: 'sub1')), '/subscription', reason: kind);
      }
    });
  });

  test('every receipt of a part stays in the history, with its decision, the latest first', () {
    final sub = subscription(status: SubscriptionStatus.approved);
    final first = InstallmentReceipt(
      id: 'r1', subscriptionId: 'sub1', seq: 2, proofPath: 'p/1.jpg', sentAt: DateTime.utc(2026, 11, 1),
      decision: InstallmentStatus.rejected, note: 'Blurry', decidedAt: DateTime.utc(2026, 11, 2),
    );
    final second = InstallmentReceipt(
      id: 'r2', subscriptionId: 'sub1', seq: 2, proofPath: 'p/2.jpg', sentAt: DateTime.utc(2026, 11, 3),
      decision: InstallmentStatus.paid, decidedAt: DateTime.utc(2026, 11, 4),
    );
    final office = InstallmentReceipt(id: 'r3', subscriptionId: 'sub1', seq: 3, sentAt: DateTime.utc(2026, 11, 5), decision: InstallmentStatus.paid, decidedAt: DateTime.utc(2026, 11, 5));
    final entries = buildRequestHistory([sub], const [], [first, second, office]).single.entries;
    expect([for (final e in entries.cast<ReceiptEntry>()) '${e.receipt.id}:${e.step.name}'],
        ['r3:paid', 'r2:paid', 'r2:sent', 'r1:rejected', 'r1:sent'], reason: 'paid at the office has no sent step');
  });

  testWidgets('the price is shown, and a school without billing yet cannot be asked', (tester) async {
    final backend = FakeBackend(current: semester())..school = const School(id: 's1', name: 'Test School', timezone: 'Africa/Douala', isActive: true);
    await open(tester, backend, picker: FakeProofPicker(samplePhoto()));
    expect(find.textContaining('still setting up payments'), findsOneWidget);
    await fillRequest(tester);
    expect(tester.widget<BusinButton>(find.widgetWithText(BusinButton, 'Send request')).onPressed, isNull);
  });

  testWidgets('without a saved preference it starts on In full, and sending in full asks nothing', (tester) async {
    final backend = FakeBackend(current: semester())..school = installmentsSchool;
    final profiles = FakeProfileRepository({'u1': profile()});
    await open(tester, backend, profiles: profiles, picker: FakeProofPicker(samplePhoto()));
    expect(find.text('30,000 XAF for the semester'), findsOneWidget);
    expect(find.text('30,000 XAF with this request.'), findsOneWidget, reason: 'In full is chosen by default');
    await fillRequest(tester);
    await send(tester);
    expect(backend.requests.single.paymentMode, PaymentMode.full);
    expect(find.text('Pay this way next time?'), findsNothing);
    expect(profiles.savedPreferences, isEmpty);
  });

  testWidgets('switching to installments without a preference offers to keep it', (tester) async {
    final backend = FakeBackend(current: semester())..school = installmentsSchool;
    final profiles = FakeProfileRepository({'u1': profile()});
    await open(tester, backend, profiles: profiles, picker: FakeProofPicker(samplePhoto()));
    await tester.tap(find.text('In installments'));
    await settle(tester, 4);
    expect(find.textContaining('12,000 XAF, 9,000 XAF, 9,000 XAF'), findsOneWidget);
    await fillRequest(tester);
    await send(tester);
    expect(backend.requests.single.paymentMode, PaymentMode.installments);
    expect(find.text('Pay this way next time?'), findsOneWidget);
    await tester.tap(find.text('Save as my preference'));
    await settle(tester);
    expect(profiles.savedPreferences, [PaymentMode.installments]);
    BusinToast.dismiss();
    await settle(tester, 2);
  });

  testWidgets('a saved preference is filled in, and nothing more is asked', (tester) async {
    final backend = FakeBackend(current: semester())..school = installmentsSchool;
    final profiles = FakeProfileRepository({'u1': Profile.fromJson({...profile().toJson(), 'payment_preference': 'full'})});
    await open(tester, backend, profiles: profiles, picker: FakeProofPicker(samplePhoto()));
    expect(find.text('30,000 XAF with this request.'), findsOneWidget);
    await fillRequest(tester);
    await send(tester);
    expect(backend.requests.single.paymentMode, PaymentMode.full);
    expect(find.text('Pay this way next time?'), findsNothing);
    expect(profiles.savedPreferences, isEmpty);
  });

  testWidgets('with monthly billing the student asks for a month, and can ask for the next from a running one', (tester) async {
    final backend = FakeBackend(current: semester())..school = monthlySchool;
    await open(tester, backend, picker: FakeProofPicker(samplePhoto()));
    expect(find.text('5,000 XAF a month'), findsOneWidget);
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('December 2026'), findsOneWidget);
    await tester.tap(find.text('December 2026'));
    await settle(tester, 4);
    await fillRequest(tester);
    await send(tester);
    expect(backend.requests.single.periodStart, DateTime.utc(2026, 12));

    final running = FakeBackend(current: semester(), mine: [monthOf('nov', 11)])..school = monthlySchool;
    await open(tester, running, picker: FakeProofPicker(samplePhoto()));
    await tester.ensureVisible(find.text('Ask for December 2026'));
    await tester.tap(find.text('Ask for December 2026'));
    await settle(tester, 4);
    expect(find.text('Send request'), findsOneWidget);
    expect(find.text('November 2026'), findsNothing, reason: 'November is already covered');
  });

  testWidgets('a subscription paid in installments lists its parts, and the next one takes a proof', (tester) async {
    final sub = Subscription.fromJson({...subscription(status: SubscriptionStatus.approved).toJson(), 'payment_mode': 'installments', 'installment_plan': '40-30-30', 'amount_xaf': 30000});
    final backend = FakeBackend(current: semester(), mine: [sub])..school = installmentsSchool;
    final installments = FakeInstallments({'sub1': [part(1, status: 'paid', due: '2026-09-01'), part(2, due: '2026-11-10'), part(3, due: '2026-12-20')]});
    await open(tester, backend, picker: FakeProofPicker(samplePhoto()), installments: installments);

    await tester.ensureVisible(find.text('Installments'));
    expect(find.text('Part 1 · 12,000 XAF'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Late'), findsOneWidget, reason: 'part 2 was due on 10 November');
    expect(find.text('Send proof of payment'), findsNWidgets(2));

    await tester.ensureVisible(find.text('Send proof of payment').first);
    await tester.tap(find.text('Send proof of payment').first);
    await settle(tester, 4);
    await tester.tap(find.text('Choose from gallery'));
    await settle(tester);
    expect(installments.sent.single.installmentId, 'part2');
    expect(find.text('Proof sent, waiting for the school'), findsOneWidget);
    // The receipt stays in the request's history.
    await tester.scrollUntilVisible(find.text('Proof for part 2 sent'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Proof for part 2 sent'), findsOneWidget);
    BusinToast.dismiss();
    await settle(tester, 2);
  });

  testWidgets('the profile keeps how the student prefers to pay, where the school offers installments', (tester) async {
    final backend = FakeBackend(current: semester())..school = installmentsSchool;
    final profiles = FakeProfileRepository({'u1': profile()});
    await open(tester, backend, profiles: profiles);
    await tester.tap(find.text('Profile').first);
    await settle(tester);
    await tester.scrollUntilVisible(find.text('How you prefer to pay'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('In installments'));
    await settle(tester);
    expect(profiles.savedPreferences, [PaymentMode.installments]);
    BusinToast.dismiss();
    await settle(tester, 2);
  });
}
