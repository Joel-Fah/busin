import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/providers.dart';
import 'package:busin_student/src/screens/splash_screen.dart';
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

  Future<FakeProfileRepository> openApp(WidgetTester tester) async {
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
    expect(find.byType(SplashScreen), findsNothing, reason: 'the student is in');
    return profiles;
  }

  testWidgets('reloading the profile in the background keeps the screen instead of going back to the loading screen', (tester) async {
    final profiles = await openApp(tester);
    // The backend is unreachable: the reload hangs.
    profiles.hold = Completer<void>();
    ProviderScope.containerOf(tester.element(find.byType(StudentApp))).invalidate(profileProvider);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SplashScreen), findsNothing, reason: 'the profile in hand is kept while it reloads');
    profiles.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('only a real return from the background rechecks the account, not a focus blip', (tester) async {
    final profiles = await openApp(tester);
    final before = profiles.reads;
    // A system dialog or the screenshot flag: the window loses and gets back its focus.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(profiles.reads, before, reason: 'a focus blip is not a return');

    for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused, AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(profiles.reads, greaterThan(before), reason: 'back from the background, the account is checked');
  });
}
