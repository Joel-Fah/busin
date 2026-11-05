import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/screens/profile_screen.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> open(
  WidgetTester tester,
  FakeAuthService auth,
  FakeProfileRepository profiles, {
  Size size = const Size(800, 1800),
  Locale locale = const Locale('en'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(key: UniqueKey(), overrides: overridesFor(auth, profiles), child: const StudentApp()));
  await tester.pumpAndSettle();
}


void main() {
  group('first login setup', () {
    testWidgets('a new student is taken to set up, and nothing else is reachable', (tester) async {
      final profiles = FakeProfileRepository({'u1': profile(complete: false)});
      await open(tester, FakeAuthService(signedInAs: 'u1'), profiles);
      expect(find.text('Welcome, Test'), findsOneWidget);
      expect(find.text('Save and continue'), findsOneWidget);
      expect(find.text('Subscription'), findsNothing, reason: 'no tabs yet');
    });

    testWidgets('empty required fields are explained and nothing is sent', (tester) async {
      final profiles = FakeProfileRepository({'u1': profile(complete: false)});
      await open(tester, FakeAuthService(signedInAs: 'u1'), profiles);
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsNWidgets(2), reason: 'student number and phone');
      expect(profiles.lastUpdate, isNull);
    });

    testWidgets('a bad phone number is called out, a good form saves and lets the student in', (tester) async {
      final profiles = FakeProfileRepository({'u1': profile(complete: false)});
      await open(tester, FakeAuthService(signedInAs: 'u1'), profiles);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'ICT2026-0457');
      await tester.enterText(fields.at(2), 'call me');
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();
      expect(find.text('Check this one: it has characters we cannot use.'), findsOneWidget);
      expect(profiles.lastUpdate, isNull);

      await tester.enterText(fields.at(2), '+237 677-123-456');
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();
      expect(profiles.lastUpdate?['matricule'], 'ICT2026-0457');
      expect(profiles.lastUpdate?['phone'], '+237677123456');
      expect(find.text('Subscription'), findsWidgets, reason: 'in the app now');
      expect(find.text('Save and continue'), findsNothing);
    });

    testWidgets('a server refusal is shown and the student can try again', (tester) async {
      final profiles = FakeProfileRepository({'u1': profile(complete: false)});
      await open(tester, FakeAuthService(signedInAs: 'u1'), profiles);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'ICT2026-0457');
      await tester.enterText(fields.at(2), '677123456');
      profiles.error = const Offline('x');
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();
      expect(find.text('No connection. Check your network and try again.'), findsOneWidget);
      expect(find.text('Save and continue'), findsOneWidget);
    });

    testWidgets('a student who is not the account can sign out from here', (tester) async {
      final auth = FakeAuthService(signedInAs: 'u1');
      await open(tester, auth, FakeProfileRepository({'u1': profile(complete: false)}));
      await tester.ensureVisible(find.text('Not you? Sign out'));
      await tester.tap(find.text('Not you? Sign out'));
      await tester.pumpAndSettle();
      expect(auth.signOuts, 1);
    });

    testWidgets('speaks French and fits a small phone at large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester, FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile(complete: false)}), size: const Size(360, 640), locale: const Locale('fr'));
      expect(find.text('Bienvenue, Test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('profile', () {
    Future<void> openProfile(WidgetTester tester, FakeAuthService auth, FakeProfileRepository profiles, {Size size = const Size(800, 1800)}) async {
      await open(tester, auth, profiles, size: size);
      expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Open your profile' && w.properties.button == true), findsOneWidget);
      await tester.tap(find.text('TP'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens from the avatar and shows the student\'s details', (tester) async {
      final handle = tester.ensureSemantics();
      await openProfile(tester, FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}));
      expect(find.text('Your profile'), findsOneWidget);
      expect(find.text('Test Person'), findsOneWidget);
      expect(find.text('u1@school.edu'), findsOneWidget);
      expect(find.text('ICT2026-0001'), findsOneWidget);
      expect(find.text('677123456'), findsOneWidget);
      expect(find.text('Not set'), findsNWidgets(2), reason: 'department and program');
      handle.dispose();
    });

    testWidgets('editing saves and confirms with a toast', (tester) async {
      final handle = tester.ensureSemantics();
      final profiles = FakeProfileRepository({'u1': profile()});
      await openProfile(tester, FakeAuthService(signedInAs: 'u1'), profiles);
      await tester.tap(find.text('Edit details'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(3), 'Engineering');
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(profiles.lastUpdate?['department'], 'Engineering');
      expect(find.text('Details saved.'), findsOneWidget);
      BusinToast.dismiss();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Engineering'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('signing out asks first, and Cancel keeps the student signed in', (tester) async {
      final handle = tester.ensureSemantics();
      final auth = FakeAuthService(signedInAs: 'u1');
      await openProfile(tester, auth, FakeProfileRepository({'u1': profile()}));
      await tester.ensureVisible(find.text('Sign out'));
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out of BusIn?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(auth.signOuts, 0);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Sign out')));
      await tester.pumpAndSettle();
      expect(auth.signOuts, 1);
      handle.dispose();
    });

    testWidgets('fits a small phone at large text and credits the 3D art', (tester) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openProfile(tester, FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), size: const Size(360, 640));
      await tester.scrollUntilVisible(find.textContaining('Thiings'), 300, scrollable: find.descendant(of: find.byType(ProfileScreen), matching: find.byType(Scrollable)).first);
      expect(find.textContaining('Thiings'), findsOneWidget);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });
}
