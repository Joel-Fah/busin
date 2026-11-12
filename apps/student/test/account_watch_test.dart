import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  testWidgets('a school suspending the account takes effect while the app is open', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final profiles = FakeProfileRepository({'u1': profile()});
    await tester.pumpWidget(ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), profiles, backend: FakeBackend(current: semester())),
      child: const StudentApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Your account is suspended'), findsNothing, reason: 'a verified student is in');
    final readsBefore = profiles.reads;

    // The school suspends the account; the server reports the change.
    profiles.byId['u1'] = profile(status: AccountStatus.suspended);
    profiles.changes.add(profiles.byId['u1']!);
    await tester.pumpAndSettle();

    expect(profiles.reads, greaterThan(readsBefore), reason: 'the app looked again');
    expect(find.text('Your account is suspended'), findsOneWidget, reason: 'and now shows it, without a restart');
  });
}
