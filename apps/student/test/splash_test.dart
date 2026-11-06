import 'package:busin_student/src/providers.dart';
import 'package:busin_student/src/screens/splash_screen.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: BusinTheme.light(),
        localizationsDelegates: businLocalizationsDelegates,
        supportedLocales: businSupportedLocales,
        home: const SplashScreen(),
      ),
    );

void main() {
  testWidgets('the logo draws once, then the finished mark and a progress bar stay', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(host(container));
    expect(container.read(introDoneProvider), isFalse);
    expect(find.byType(BrandIntro), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(container.read(introDoneProvider), isTrue);
    expect(find.byType(BrandIntro), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('a tap skips the drawing', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(host(container));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(BrandIntro));
    // The first frame after the tap starts the faster run; the next ones play it out.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(container.read(introDoneProvider), isTrue);
  });

  testWidgets('with the intro switched off, the splash shows the mark straight away', (tester) async {
    final container = ProviderContainer(overrides: [introEnabledProvider.overrideWithValue(false)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(host(container));
    expect(find.byType(BrandIntro), findsNothing);
    expect(find.byType(BrandMark), findsOneWidget);
  });
}
