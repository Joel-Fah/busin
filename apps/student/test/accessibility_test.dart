import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/settings/appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

/// Opens the app on a phone in [mode] and goes to [tab] (null: where it opens), then runs [check].
Future<void> onScreen(
  WidgetTester tester, {
  required ThemeMode mode,
  String? tab,
  FakeBackend? backend,
  FakeAuthService? auth,
  FakeHistory? history,
}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'theme_mode': mode.name});
  final store = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        ...overridesFor(auth ?? FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), backend: backend, history: history),
        appPreferencesProvider.overrideWithValue(store),
      ],
      child: const StudentApp(),
    ),
  );
  await tester.pumpAndSettle();
  if (tab != null) {
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
  }
}

Future<void> checkGuidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    group('accessibility in ${mode.name}', () {
      testWidgets('sign-in', (tester) async {
        await onScreen(tester, mode: mode, auth: FakeAuthService());
        await checkGuidelines(tester);
      });

      testWidgets('subscription, with a request sent', (tester) async {
        await onScreen(tester, mode: mode, backend: FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.pending)]));
        await checkGuidelines(tester);
      });

      testWidgets('the form to subscribe', (tester) async {
        await onScreen(tester, mode: mode, backend: FakeBackend(current: semester()));
        await checkGuidelines(tester);
      });

      testWidgets('the boarding code', (tester) async {
        await onScreen(tester, mode: mode, tab: 'Code', backend: FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.approved)]));
        await tester.pump(const Duration(seconds: 1));
        await checkGuidelines(tester);
      });

      testWidgets('my bus, without a subscription', (tester) async {
        await onScreen(tester, mode: mode, tab: 'My bus');
        await checkGuidelines(tester);
      });

      testWidgets('the profile', (tester) async {
        await onScreen(tester, mode: mode, tab: 'Profile');
        await checkGuidelines(tester);
      });

      testWidgets('the history', (tester) async {
        await onScreen(
          tester,
          mode: mode,
          tab: 'Profile',
          history: FakeHistory(scans: [
            scan(1, at: DateTime.utc(2026, 11, 4, 17), stopId: 'stop2', tripId: 'trip2'),
            scan(2, at: DateTime.utc(2026, 11, 3, 7), stopId: 'stop1', tripId: 'trip1'),
          ]),
        );
        await tester.scrollUntilVisible(find.text('Boarding history'), 200, scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text('Boarding history'));
        await tester.pumpAndSettle();
        await checkGuidelines(tester);
      });
    });
  }

  testWidgets('with animations switched off the main screens settle at once and nothing moves on its own', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await onScreen(tester, mode: ThemeMode.light, tab: 'Code', backend: FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.approved)]));
    // Settles: no endless animation is left running (the live dot and the shimmer hold still).
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
