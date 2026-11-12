import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/providers.dart';
import 'package:busin_student/src/screens/splash_screen.dart';
import 'package:busin_student/src/subscription/subscription_status_card.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

final sizes = {
  'a small phone': const Size(360, 640),
  'a phone': const Size(412, 915),
  'a portrait tablet': const Size(800, 1280),
  'a landscape tablet': const Size(1280, 800),
};

Future<void> run(
  WidgetTester tester,
  Size size, {
  FakeAuthService? auth,
  FakeProfileRepository? profiles,
  FakeBackend? backend,
  double textScale = 1,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(
        auth ?? FakeAuthService(),
        profiles ?? FakeProfileRepository({'u1': profile()}),
        backend: backend ?? FakeBackend(current: semester(), mine: [subscription()]),
      ),
      child: const StudentApp(),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  // The landing page looks up where to go, then moves on.
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  for (final entry in sizes.entries) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('sign-in lays out on ${entry.key} at text size $scale, in both languages', (tester) async {
        for (final locale in [const Locale('en'), const Locale('fr')]) {
          await run(tester, entry.value, textScale: scale, locale: locale);
          expect(tester.takeException(), isNull, reason: locale.languageCode);
          expect(find.text(locale.languageCode == 'fr' ? 'Continuer avec Google' : 'Continue with Google'), findsOneWidget);
          expect(find.byType(BrandMark), findsWidgets);
        }
      });

      testWidgets('the blocked screens lay out on ${entry.key} at text size $scale', (tester) async {
        final cases = {
          'staff': profile(role: UserRole.staff),
          'pending': profile(status: AccountStatus.pending),
          'suspended': profile(status: AccountStatus.suspended),
        };
        for (final entryCase in cases.entries) {
          await run(tester, entry.value, auth: FakeAuthService(signedInAs: 'u1'), profiles: FakeProfileRepository({'u1': entryCase.value}), textScale: scale);
          expect(tester.takeException(), isNull, reason: entryCase.key);
          expect(find.text('Sign out', skipOffstage: false), findsOneWidget, reason: entryCase.key);
          expect(find.byType(Illustration), findsOneWidget, reason: entryCase.key);
        }
      });

      testWidgets('the signed-in frame fits ${entry.key} at text size $scale: every tab opens with no overflow', (tester) async {
        await run(tester, entry.value, auth: FakeAuthService(signedInAs: 'u1'), textScale: scale);
        final wide = entry.value.width >= BusinLayout.expandedFrom;
        expect(find.byType(BusinNavRail), wide ? findsOneWidget : findsNothing);
        expect(find.byType(FloatingNavBar), wide ? findsNothing : findsOneWidget);

        for (final label in ['Code', 'Profile', 'My bus', 'Subscription']) {
          await tester.tap(find.text(label).first);
          await tester.pump(const Duration(milliseconds: 700));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull, reason: '$label on ${entry.key} at $scale');
        }
      });
    }
  }

  testWidgets('the splash lays out and says it is loading to a screen reader', (tester) async {
    await run(tester, const Size(412, 915), auth: FakeAuthService(signedInAs: 'u1'));
    // The splash is only up while the profile loads, so render it directly as well.
    await tester.pumpWidget(ProviderScope(
      overrides: [introEnabledProvider.overrideWithValue(false)],
      child: MaterialApp(theme: BusinTheme.dark(), localizationsDelegates: businLocalizationsDelegates, supportedLocales: businSupportedLocales, home: const SplashScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('tapping the call to action signs in', (tester) async {
    final auth = FakeAuthService();
    await run(tester, const Size(412, 915), auth: auth);
    await tester.tap(find.text('Continue with Google'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(FloatingNavBar), findsOneWidget, reason: 'signed in, so the app opens');
  });

  testWidgets('a failed sign-in is explained on the photo and the button comes back', (tester) async {
    final auth = FakeAuthService(failWith: SignInFailure.notAllowed);
    await run(tester, const Size(412, 915), auth: auth);
    await tester.tap(find.text('Continue with Google'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('not allowed'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('on a portrait tablet the page is a reading column, not stretched across the screen', (tester) async {
    await run(tester, const Size(800, 1280), auth: FakeAuthService(signedInAs: 'u1'));
    await tester.pump(const Duration(seconds: 1));
    final width = tester.getSize(find.byType(SubscriptionStatusCard)).width;
    expect(width, lessThanOrEqualTo(BusinLayout.maxColumn));
  });

  testWidgets('scrolling content ends clear of the floating bar on a phone, and the rail takes no room on a landscape tablet', (tester) async {
    await run(tester, const Size(412, 915), auth: FakeAuthService(signedInAs: 'u1'));
    final listView = tester.widget<ListView>(find.byType(ListView).first);
    expect((listView.padding! as EdgeInsets).bottom, greaterThanOrEqualTo(FloatingNavBar.height));

    await run(tester, const Size(1280, 800), auth: FakeAuthService(signedInAs: 'u1'));
    final wide = tester.widget<ListView>(find.byType(ListView).first);
    expect((wide.padding! as EdgeInsets).bottom, lessThan(FloatingNavBar.height));
  });

  testWidgets('a sheet opens above the floating bar, not under it', (tester) async {
    await run(tester, const Size(412, 915), auth: FakeAuthService(signedInAs: 'u1'), backend: FakeBackend(current: semester()));
    await tester.pumpAndSettle(); // the stop list has loaded
    await tester.tap(find.text('Your stop'));
    await tester.pumpAndSettle();
    expect(find.byType(BusinSheetFrame), findsOneWidget);
    // The sheet's own list is tappable even at the bottom, where the bar would have been.
    await tester.tap(find.text('Carrefour Vogt'));
    await tester.pumpAndSettle();
    expect(find.byType(BusinSheetFrame), findsNothing);
    expect(find.text('Carrefour Vogt'), findsOneWidget);
  });
}
