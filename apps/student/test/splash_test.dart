import 'dart:async';

import 'package:busin_student/src/providers.dart';
import 'package:busin_student/src/screens/splash_screen.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// The splash reads the access state, so it needs a (fake) sign-in and profile behind it.
ProviderContainer containerFor({bool introEnabled = true, FakeAuthService? auth, FakeProfileRepository? profiles}) => ProviderContainer(overrides: [
      introEnabledProvider.overrideWithValue(introEnabled),
      authServiceProvider.overrideWithValue(auth ?? FakeAuthService()),
      profileRepositoryProvider.overrideWithValue(profiles ?? FakeProfileRepository({})),
    ]);

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
    final container = containerFor();
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
    final container = containerFor();
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
    final container = containerFor(introEnabled: false);
    addTearDown(container.dispose);
    await tester.pumpWidget(host(container));
    expect(find.byType(BrandIntro), findsNothing);
    expect(find.byType(BrandMark), findsOneWidget);
  });

  group('when the backend is slow', () {
    ProviderContainer slow(Completer<void> hold, FakeProfileRepository profiles) {
      profiles.hold = hold;
      return containerFor(introEnabled: false, auth: FakeAuthService(signedInAs: 'u1'), profiles: profiles);
    }

    testWidgets('it stays quiet at first, then says it is taking longer and offers to try again', (tester) async {
      final profiles = FakeProfileRepository({'u1': profile()});
      final container = slow(Completer<void>(), profiles);
      addTearDown(container.dispose);
      await tester.pumpWidget(host(container));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('This is taking longer than usual'), findsNothing);

      await tester.pump(const Duration(seconds: 6));
      expect(find.text('This is taking longer than usual'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      final before = profiles.reads;
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(profiles.reads, greaterThan(before), reason: 'the profile is asked for again');
      expect(find.text('This is taking longer than usual'), findsNothing, reason: 'and the wait starts over');
    });

    testWidgets('it never speaks if the wait ends in time', (tester) async {
      final hold = Completer<void>();
      final container = slow(hold, FakeProfileRepository({'u1': profile()}));
      addTearDown(container.dispose);
      await tester.pumpWidget(host(container));
      await tester.pump(const Duration(seconds: 4));
      hold.complete();
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('This is taking longer than usual'), findsNothing);
    });

    testWidgets('it speaks French', (tester) async {
      tester.platformDispatcher.localesTestValue = [const Locale('fr')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final container = slow(Completer<void>(), FakeProfileRepository({'u1': profile()}));
      addTearDown(container.dispose);
      await tester.pumpWidget(host(container));
      await tester.pump(const Duration(seconds: 11));
      expect(find.text('Cela prend plus de temps que d’habitude'), findsOneWidget);
    });
  });
}
