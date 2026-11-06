import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> open(WidgetTester tester, FakeBackend backend) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), backend: backend),
      child: const StudentApp(),
    ),
  );
  // Not settled: the boarding code's live dot animates for a while.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('a student with an approved subscription opens on the boarding code', (tester) async {
    await open(tester, FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.approved)]));
    expect(find.text('Boarding code'), findsOneWidget);
    expect(find.textContaining('Subscribe for'), findsNothing);
    BusinToast.dismiss();
    await tester.pump();
  });

  testWidgets('a student whose request is still pending opens on the subscription tab', (tester) async {
    await open(tester, FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.pending)]));
    expect(find.text('Boarding code'), findsNothing);
    expect(find.textContaining('Fall 2026'), findsWidgets);
  });

  testWidgets('a student whose subscription was revoked opens on the subscription tab, not the code', (tester) async {
    await open(tester, FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.revoked, note: 'Payment was reversed.')]));
    expect(find.text('Boarding code'), findsNothing);
    expect(find.text('Subscription ended by your school'), findsOneWidget);
  });

  testWidgets('a student with no subscription opens on the subscription tab', (tester) async {
    await open(tester, FakeBackend(current: semester()));
    expect(find.text('Boarding code'), findsNothing);
    expect(find.text('Send request'), findsOneWidget);
  });
}
