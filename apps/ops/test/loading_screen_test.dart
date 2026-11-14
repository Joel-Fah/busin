import 'package:busin_ops/src/access.dart';
import 'package:busin_ops/src/providers.dart';
import 'package:busin_ops/src/router.dart';
import 'package:busin_ops/src/screens/access_screens.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Widget host({required bool dark, bool intro = false}) => ProviderScope(
      overrides: [introEnabledProvider.overrideWithValue(intro)],
      child: MaterialApp(
        theme: dark ? BusinTheme.dark() : BusinTheme.light(),
        localizationsDelegates: businLocalizationsDelegates,
        supportedLocales: businSupportedLocales,
        home: const LoadingScreen(),
      ),
    );

void main() {
  for (final dark in [false, true]) {
    testWidgets('the loading screen picks up from the ${dark ? 'dark' : 'light'} native splash', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(dark: dark));
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, dark ? BusinRamps.seed : BusinPalette.light.bg);
      expect(tester.widget<BrandMark>(find.byType(BrandMark)).color, dark ? Colors.white : BusinRamps.seed);
      final mark = tester.getRect(find.byKey(const ValueKey('loading-mark')));
      expect(mark.width, LoadingScreen.markWidth, reason: 'the splash draws it 144 wide');
      expect(mark.center.dx, closeTo(screen.width / 2, 0.5));
      expect(mark.center.dy, closeTo(screen.height / 2, 0.5), reason: 'in the middle, where the splash left it');
    });
  }

  testWidgets('on a cold start the logo draws itself where the splash left it, then the mark and the spinner stay', (tester) async {
    await tester.pumpWidget(host(dark: false, intro: true));
    expect(find.byType(BrandIntro), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing, reason: 'no spinner while it draws');
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.byType(BrandIntro), findsNothing);
    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  test('the router waits on the loading screen until the drawing is over', () {
    expect(redirectFor(OpsAllowed(staff()), Routes.loading, introDone: false), isNull);
    expect(redirectFor(const OpsSignedOut(), Routes.loading, introDone: false), isNull);
    expect(redirectFor(OpsAllowed(staff()), Routes.loading), Routes.today);
  });
}
