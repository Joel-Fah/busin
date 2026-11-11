import 'package:busin_student/src/auth/access.dart';
import 'package:busin_student/src/router.dart';
import 'package:busin_student/src/styleguide/styleguide_screen.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> show(WidgetTester tester, Size size, {double textScale = 1, Brightness brightness = Brightness.light}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: BusinTheme.light(),
      darkTheme: BusinTheme.dark(),
      localizationsDelegates: businLocalizationsDelegates,
      supportedLocales: businSupportedLocales,
      home: const StyleguideScreen(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  final sizes = {
    'a small phone': const Size(360, 640),
    'a phone': const Size(412, 915),
    'a portrait tablet': const Size(800, 1280),
    'a landscape tablet': const Size(1280, 800),
  };

  for (final entry in sizes.entries) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('every section lays out on ${entry.key} at text size $scale without overflow', (tester) async {
        await show(tester, entry.value, textScale: scale);
        final wide = entry.value.width >= BusinLayout.expandedFrom;
        expect(find.byType(BusinNavRail), wide ? findsOneWidget : findsNothing);
        expect(find.byType(FloatingNavBar), wide ? findsNothing : findsOneWidget);

        for (final label in ['Basics', 'Parts', 'Layout', 'Motion']) {
          await tester.tap(find.text(label).first);
          await tester.pump(const Duration(milliseconds: 700));
          // Scroll to the bottom of the section so every part is built at least once.
          final scroll = find.byType(ListView).hitTestable();
          if (scroll.evaluate().isNotEmpty) {
            await tester.drag(scroll.first, const Offset(0, -6000));
            await tester.pump(const Duration(milliseconds: 400));
          }
          expect(tester.takeException(), isNull, reason: '$label on ${entry.key} at $scale');
        }
      });
    }
  }

  testWidgets('both themes draw every section', (tester) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await show(tester, const Size(412, 915), brightness: brightness);
      for (final label in ['Basics', 'Parts', 'Layout', 'Motion']) {
        await tester.tap(find.text(label).first);
        await tester.pump(const Duration(milliseconds: 700));
      }
      expect(tester.takeException(), isNull, reason: brightness.name);
    }
  });

  testWidgets('the theme switch overrides the system theme', (tester) async {
    await show(tester, const Size(412, 915), brightness: Brightness.light);
    Color background() => Theme.of(tester.element(find.text('Styleguide'))).scaffoldBackgroundColor;
    final light = background();
    await tester.tap(find.text('Dark'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(background(), isNot(light));
    expect(background(), BusinPalette.dark.bg);
  });

  testWidgets('the layout name follows the window', (tester) async {
    await show(tester, const Size(1280, 800));
    expect(find.textContaining('expanded layout'), findsOneWidget);
    await show(tester, const Size(360, 640));
    expect(find.textContaining('compact layout'), findsOneWidget);
  });

  group('the debug route', () {
    test('is reachable without an account in a debug build and never otherwise', () {
      for (final access in [const SignedOut(), const AccessLoading(), const AccessLoadFailed(), const Blocked(BlockReason.suspended)]) {
        expect(redirectFor(access, Routes.styleguide, debug: true), isNull, reason: '$access');
      }
      expect(redirectFor(const SignedOut(), Routes.styleguide, debug: false), Routes.signIn, reason: 'release builds do not serve it');
    });
  });
}
