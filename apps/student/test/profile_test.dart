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

    testWidgets('the school lists come in the order program, faculty, department', (tester) async {
      final profiles = FakeProfileRepository({'u1': profile(complete: false)});
      await open(tester, FakeAuthService(signedInAs: 'u1'), profiles);
      final program = tester.getTopLeft(find.text('Program')).dy;
      final faculty = tester.getTopLeft(find.text('Faculty')).dy;
      final department = tester.getTopLeft(find.text('Department')).dy;
      expect(program, lessThan(faculty));
      expect(faculty, lessThan(department));
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
      // Letters never reach the field; a number too short for the country is called out.
      await tester.enterText(fields.at(2), 'call me 12345');
      expect(find.text('1 23 45'), findsNothing);
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

    testWidgets('gender is optional: skipped it sends nothing, chosen it is saved', (tester) async {
      final profiles = FakeProfileRepository({'u1': profile(complete: false)});
      await open(tester, FakeAuthService(signedInAs: 'u1'), profiles);
      expect(find.text('Gender (optional)'), findsOneWidget);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'ICT2026-0457');
      await tester.enterText(fields.at(2), '+237 677-123-456');
      await tester.ensureVisible(find.text('Female'));
      await tester.tap(find.text('Female'));
      await tester.pump();
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();
      expect(profiles.savedGenders, [Gender.female]);
      expect(find.text('Subscription'), findsWidgets, reason: 'in the app now');
    });

    testWidgets('a student who skips gender gets in all the same', (tester) async {
      final profiles = FakeProfileRepository({'u1': profile(complete: false)});
      await open(tester, FakeAuthService(signedInAs: 'u1'), profiles);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'ICT2026-0457');
      await tester.enterText(fields.at(2), '+237 677-123-456');
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();
      expect(profiles.savedGenders, isEmpty, reason: 'nothing to send');
      expect(find.text('Subscription'), findsWidgets);
    });

    testWidgets('a server refusal is shown and the student can try again', (tester) async {
      final profiles = FakeProfileRepository({'u1': profile(complete: false)});
      await open(tester, FakeAuthService(signedInAs: 'u1'), profiles);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'ICT2026-0457');
      await tester.enterText(fields.at(2), '+237 677 12 34 56');
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
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens from the bottom bar and shows the student\'s details', (tester) async {
      final handle = tester.ensureSemantics();
      await openProfile(tester, FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}));
      expect(find.text('Test Person'), findsOneWidget);
      expect(find.text('u1@school.edu'), findsOneWidget);
      expect(find.text('ICT2026-0001'), findsOneWidget);
      expect(find.text(PhoneNumbers.display('+237677123456')), findsOneWidget, reason: 'shown with spaces (ADR 0024)');
      expect(find.text('Not set'), findsNWidgets(3), reason: 'department, program and gender');
      handle.dispose();
    });

    testWidgets('the student asks for the deletion of their account, and can keep it (ADR 0028)', (tester) async {
      await openProfile(tester, FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}));
      final button = find.widgetWithText(BusinButton, 'Delete my account');
      await tester.scrollUntilVisible(button, 300, scrollable: find.byType(Scrollable).first);
      // Clear of the floating bottom bar before tapping.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.textContaining('Your school keeps its records without your name'), findsOneWidget);
      await tester.tap(find.text('Delete in 7 days'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Your account will be deleted on'), findsOneWidget);
      await tester.tap(find.text('Keep my account'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(BusinButton, 'Delete my account'), findsOneWidget);
      BusinToast.dismiss();
      await tester.pumpAndSettle();
    });

    testWidgets('tapping the school shows what its administrators wrote', (tester) async {
      await openProfile(tester, FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}));
      await tester.tap(find.text('Test School'));
      await tester.pumpAndSettle();
      expect(find.text('Test School'), findsNWidgets(2), reason: 'the badge and the sheet');
      expect(find.text('The school has not added its details yet.'), findsOneWidget);
    });

    testWidgets('the history is inside the profile, opens as its own page and comes back', (tester) async {
      await openProfile(tester, FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}));
      // Four tabs, and history is not one of them.
      for (final label in ['Subscription', 'Code', 'My bus', 'Profile']) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      expect(find.text('History'), findsNothing);

      await tester.tap(find.text('Boarding history'));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsOneWidget, reason: 'the page title');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Boarding history'), findsOneWidget);
    });

    testWidgets('editing saves and confirms with a toast', (tester) async {
      final handle = tester.ensureSemantics();
      final profiles = FakeProfileRepository({'u1': profile()});
      await openProfile(tester, FakeAuthService(signedInAs: 'u1'), profiles);
      await tester.tap(find.text('Edit details'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'ICT2026-0099');
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(profiles.lastUpdate?['matricule'], 'ICT2026-0099');
      expect(find.text('Details saved.'), findsOneWidget);
      BusinToast.dismiss();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      handle.dispose();
    });

    testWidgets('the gender is shown in the details, and tapping the chosen one again clears it', (tester) async {
      final profiles = FakeProfileRepository({'u1': Profile.fromJson({...profile().toJson(), 'gender': 'male'})});
      await openProfile(tester, FakeAuthService(signedInAs: 'u1'), profiles);
      expect(find.text('Male'), findsOneWidget);
      await tester.tap(find.text('Edit details'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Male').last);
      await tester.tap(find.text('Male').last);
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(profiles.savedGenders, [null]);
      BusinToast.dismiss();
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    testWidgets('the department list depends on the faculty, and the choice is saved', (tester) async {
      final profiles = FakeProfileRepository({'u1': profile()});
      await openProfile(tester, FakeAuthService(signedInAs: 'u1'), profiles);
      await tester.tap(find.text('Edit details'));
      await tester.pumpAndSettle();

      // Departments cannot be chosen before a faculty.
      expect(find.text('Choose a faculty first'), findsOneWidget);

      await tester.tap(find.text('Choose your faculty'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Faculty of Business'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose your department'));
      await tester.pumpAndSettle();
      expect(find.text('Accounting'), findsOneWidget);
      expect(find.text('Computer Science'), findsNothing, reason: 'that belongs to the other faculty');
      await tester.tap(find.text('Accounting'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose your degree level'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Master'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(profiles.lastAcademic, const AcademicChoice(departmentId: 'd3', programId: 'p2'));
      BusinToast.dismiss();
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Accounting'), findsOneWidget);
      expect(find.text('Master'), findsOneWidget);
    });

    testWidgets('changing the faculty forgets the department of the old one', (tester) async {
      final saved = profile(departmentId: 'd1', programId: 'p1');
      final profiles = FakeProfileRepository({'u1': saved});
      await openProfile(tester, FakeAuthService(signedInAs: 'u1'), profiles);
      await tester.tap(find.text('Edit details'));
      await tester.pumpAndSettle();
      expect(find.text('Faculty of Computing'), findsOneWidget, reason: 'derived from the saved department');
      expect(find.text('Computer Science'), findsWidgets);

      await tester.tap(find.text('Faculty of Computing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Faculty of Business'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your department'), findsOneWidget);
    });

    testWidgets('signing out asks first, and Cancel keeps the student signed in', (tester) async {
      final handle = tester.ensureSemantics();
      final auth = FakeAuthService(signedInAs: 'u1');
      await openProfile(tester, auth, FakeProfileRepository({'u1': profile()}));
      await tester.scrollUntilVisible(find.text('Sign out'), 300, scrollable: find.byType(Scrollable).first);
      // Clear of the floating bottom bar before tapping.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
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

    for (final locale in [const Locale('en'), const Locale('fr')]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('on a landscape tablet it is two columns, in ${locale.languageCode} at text size $scale', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await open(tester, FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), size: const Size(1280, 800), locale: locale);
          await tester.tap(find.text(locale.languageCode == 'fr' ? 'Profil' : 'Profile'));
          await tester.pumpAndSettle();

          final who = tester.getRect(find.text('Test Person'));
          final details = tester.getRect(find.text(locale.languageCode == 'fr' ? 'Vos informations' : 'Your details'));
          final history = tester.getRect(find.text(locale.languageCode == 'fr' ? 'Historique des trajets' : 'Boarding history'));
          expect(details.left, greaterThan(who.right), reason: 'the details are in the right column');
          expect(history.left, greaterThan(who.right), reason: 'and so is the history');
          expect(details.top, lessThan(history.top));
          expect(tester.takeException(), isNull);
        });
      }
    }

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
