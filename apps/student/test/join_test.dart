import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/auth/access.dart';
import 'package:busin_student/src/router.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

const _hill = OpenSchool(id: 'hill', name: 'Hill University', city: 'Yaounde', country: 'Cameroon');
const _river = OpenSchool(id: 'river', name: 'River College', city: 'Douala');

Future<void> start(WidgetTester tester, FakeProfileRepository profiles, FakeJoin join) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), profiles, join: join, backend: FakeBackend(current: semester())),
      child: const StudentApp(),
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  BusinToast.dismiss();
}

void main() {
  test('the routes for the two new states', () {
    final pending = profile(status: AccountStatus.pending, schoolId: null);
    expect(redirectFor(NeedsSchool(pending), Routes.qr), Routes.join);
    expect(redirectFor(AwaitingSchool(profile(status: AccountStatus.pending)), Routes.join), Routes.waiting);
    expect(redirectFor(NeedsSchool(pending), Routes.join), isNull);
  });

  testWidgets('a student without a school email chooses a school, asks to join, and waits', (tester) async {
    final profiles = FakeProfileRepository({'u1': profile(status: AccountStatus.pending, schoolId: null, complete: false)});
    final join = FakeJoin(profiles, schools: const [_hill, _river]);
    await start(tester, profiles, join);

    expect(find.text('Choose your school'), findsOneWidget);
    expect(find.text('Hill University'), findsOneWidget);
    expect(find.text('Yaounde, Cameroon'), findsOneWidget);

    // Search narrows the list.
    await tester.enterText(find.byType(TextField), 'douala');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hill University'), findsNothing);
    expect(find.text('River College'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Hill University'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Ask to join Hill University?'), findsOneWidget);
    await tester.tap(find.text('Ask to join'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(join.asked, ['hill']);
    expect(find.text('Waiting for Hill University'), findsOneWidget);
    BusinToast.dismiss();

    // Changing their mind takes them back to the list.
    await tester.tap(find.text('Choose another school'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(join.asked, ['hill', null]);
    expect(find.text('Choose your school'), findsOneWidget);
    BusinToast.dismiss();
  });

  testWidgets('a declined student sees who declined and why, and when no school accepts their email, says so', (tester) async {
    final profiles = FakeProfileRepository({'u1': profile(status: AccountStatus.pending, schoolId: null, complete: false)});
    final join = FakeJoin(profiles, request: JoinRequest(declinedAt: DateTime.utc(2026, 11, 10), declinedSchoolName: 'Hill University', declineNote: 'We could not find you.'));
    await start(tester, profiles, join);
    expect(find.text('Hill University declined your request'), findsOneWidget);
    expect(find.text('Their reason: We could not find you.'), findsOneWidget);
    expect(find.text('No school accepts your email yet'), findsOneWidget);
  });

  testWidgets('a student with a school email is told which school they are joining, with a way out', (tester) async {
    final profiles = FakeProfileRepository({'u1': profile(complete: false)});
    await start(tester, profiles, FakeJoin(profiles));
    expect(find.text('You are joining Test School'), findsOneWidget);
    await tester.tap(find.text('Not my school?'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Not your school?'), findsOneWidget);
  });
}
