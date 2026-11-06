import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> open(
  WidgetTester tester,
  FakeAuthService auth,
  FakeProfileRepository profiles, {
  Locale locale = const Locale('en'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(auth, profiles),
      child: const StudentApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a signed-out person sees sign-in, and signing in opens the app', (tester) async {
    final auth = FakeAuthService();
    await open(tester, auth, FakeProfileRepository({'u1': profile()}));

    expect(find.text('Hop on. BusIn handles the rest.'), findsOneWidget);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Hop on. BusIn handles the rest.'), findsNothing);
  });

  testWidgets('each failed sign-in says what happened and stays on the page', (tester) async {
    final cases = {
      SignInFailure.cancelled: 'Sign-in was cancelled.',
      SignInFailure.notAllowed: 'This Google account is not allowed here. Use your school account.',
      SignInFailure.failed: 'Sign-in did not work. Try again.',
    };
    for (final entry in cases.entries) {
      final auth = FakeAuthService(failWith: entry.key);
      await open(tester, auth, FakeProfileRepository({}));
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget, reason: '${entry.key}');
      expect(find.byType(NavigationBar), findsNothing);
    }
  });

  testWidgets('a returning student goes straight in', (tester) async {
    await open(tester, FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}));
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('staff are told this app is for students, and can sign out', (tester) async {
    final auth = FakeAuthService(signedInAs: 'u1');
    await open(tester, auth, FakeProfileRepository({'u1': profile(role: UserRole.staff)}));

    expect(find.text('This app is for students'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(auth.signOuts, 1);
    expect(find.text('Hop on. BusIn handles the rest.'), findsOneWidget);
  });

  testWidgets('pending and suspended students see their own explanation', (tester) async {
    await open(tester, FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile(status: AccountStatus.pending)}));
    expect(find.text('Your account is waiting for approval'), findsOneWidget);

    await open(tester, FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile(status: AccountStatus.suspended)}));
    expect(find.text('Your account is suspended'), findsOneWidget);
  });

  testWidgets('a profile that cannot be loaded offers retry and never the app', (tester) async {
    final profiles = FakeProfileRepository({'u1': profile()})..error = const Offline('no network');
    await open(tester, FakeAuthService(signedInAs: 'u1'), profiles);

    expect(find.text('Something went wrong. Try again.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    profiles.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('all four destinations are reachable and the app speaks French', (tester) async {
    await open(tester, FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), locale: const Locale('fr'));
    for (final label in ['Code d’embarquement', 'Historique', 'Mon bus', 'Abonnement']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget, reason: label);
    }
    expect(find.text('Aucun semestre ouvert pour le moment'), findsOneWidget, reason: 'back on the first tab');
  });

  testWidgets('signing out of the app returns to sign-in and drops the profile', (tester) async {
    final auth = FakeAuthService(signedInAs: 'u1');
    await open(tester, auth, FakeProfileRepository({'u1': profile()}));
    expect(find.byType(NavigationBar), findsOneWidget);

    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Hop on. BusIn handles the rest.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
