import 'package:busin_student/src/auth/auth_service.dart';
import 'package:busin_student/src/providers.dart';
import 'package:busin_student/src/screens/sign_in_screen.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Widget host(ProviderContainer container) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: BusinTheme.light(),
        localizationsDelegates: businLocalizationsDelegates,
        supportedLocales: businSupportedLocales,
        home: const SignInScreen(),
      ),
    );

ProviderContainer containerFor() => ProviderContainer(overrides: [authServiceProvider.overrideWithValue(FakeAuthService())]);

void main() {
  testWidgets('the end of the opening animation arms the hand-off, once', (tester) async {
    final container = ProviderContainer(overrides: [introEnabledProvider.overrideWithValue(true)]);
    addTearDown(container.dispose);
    expect(container.read(logoHandoffProvider), isFalse);
    container.read(introDoneProvider.notifier).finish();
    expect(container.read(logoHandoffProvider), isTrue);
  });

  testWidgets('the mark leaves the centre and lands in the top left corner while the screen appears', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final container = containerFor();
    addTearDown(container.dispose);
    container.read(logoHandoffProvider.notifier).arm();

    await tester.pumpWidget(host(container));
    await tester.pump();
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    final traveller = find.byKey(const ValueKey('logo-handoff'));
    final first = tester.getRect(traveller);
    expect(first.center.dx, closeTo(screen.width / 2, 1), reason: 'starts where the splash left it');
    expect(first.center.dy, closeTo(screen.height / 2, 1));
    expect(first.width, closeTo(splashWidth, 1));
    expect(container.read(logoHandoffProvider), isFalse, reason: 'taken: only this arrival does it');

    await tester.pump(const Duration(milliseconds: 600));
    final middle = tester.getRect(traveller);
    expect(middle.center.dy, lessThan(first.center.dy));
    expect(middle.width, lessThan(first.width));

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(traveller, findsNothing, reason: 'the screen\'s own mark takes over exactly where it landed');
    final own = tester.getRect(find.byType(BrandMark).first);
    expect(own.left, lessThan(60));
    expect(own.top, lessThan(80));
  });

  testWidgets('without the hand-off the screen is simply there', (tester) async {
    final container = containerFor();
    addTearDown(container.dispose);
    await tester.pumpWidget(host(container));
    await tester.pump();
    expect(find.byKey(const ValueKey('logo-handoff')), findsNothing);
    expect(find.byType(BrandMark), findsOneWidget);
  });
}

const splashWidth = 144.0;
