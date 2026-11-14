import 'package:busin_core/busin_core.dart';
import 'package:busin_ops/src/app.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> open(WidgetTester tester, FakeStaffAccess staffAccess) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: overridesFor(auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff(role: UserRole.student)}, trips: FakeTrips([]), staffAccess: staffAccess),
    child: const OpsApp(),
  ));
  await settle(tester);
}

void main() {
  testWidgets('a student account asks a school for staff access, sees it waiting, and can withdraw it', (tester) async {
    final staffAccess = FakeStaffAccess();
    await open(tester, staffAccess);
    expect(find.text('This app is for staff'), findsOneWidget);

    await tester.tap(find.text('Ask for staff access'));
    await settle(tester);
    expect(find.text('Which school do you work for?'), findsOneWidget);
    await tester.tap(find.text('Test School'));
    await settle(tester);
    expect(staffAccess.asked, [schoolId]);
    expect(find.textContaining('Your request is with Test School'), findsOneWidget);
    BusinToast.dismiss();
    await settle(tester, 3);

    await tester.tap(find.text('Withdraw the request'));
    await settle(tester);
    expect(staffAccess.asked.last, isNull);
    expect(find.text('Ask for staff access'), findsOneWidget);
  });

  testWidgets('a declined request shows the school and its note, and the person can ask again', (tester) async {
    final staffAccess = FakeStaffAccess(request: JoinRequest(declinedAt: DateTime.utc(2026, 11, 15), declinedSchoolName: 'Test School', declineNote: 'We did not invite you.'));
    await open(tester, staffAccess);
    expect(find.text('Test School declined your request.'), findsOneWidget);
    expect(find.text('Their note: We did not invite you.'), findsOneWidget);
    expect(find.text('Ask again'), findsOneWidget);
  });

  testWidgets('asking again too soon says so', (tester) async {
    final staffAccess = FakeStaffAccess()..error = const NotAllowed('database 54000', reason: 'too_many');
    await open(tester, staffAccess);
    await tester.tap(find.text('Ask for staff access'));
    await settle(tester);
    await tester.tap(find.text('Test School'));
    await settle(tester, 3);
    expect(find.text('Wait a few seconds before asking again.'), findsOneWidget);
    BusinToast.dismiss();
    await settle(tester, 3);
  });
}
