import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<List<String>> open(WidgetTester tester, FakeBackend backend, {Size size = const Size(800, 1800)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // What the system is asked to do when nothing in the app takes the back gesture.
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'SystemNavigator.pop') calls.add(call.method);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), backend: backend),
      child: const StudentApp(),
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  return calls;
}

Future<void> back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('a subscriber: back from another tab goes to the code, and from the code it leaves the app', (tester) async {
    final calls = await open(tester, FakeBackend(current: semester(), mine: [subscription(status: SubscriptionStatus.approved)]));
    expect(find.text('Boarding code'), findsOneWidget);
    BusinToast.dismiss();

    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Edit details'), findsOneWidget);

    await back(tester);
    expect(find.text('Boarding code'), findsOneWidget, reason: 'back from the profile returns to the main tab');
    expect(calls, isEmpty, reason: 'and the app stays open');

    await tester.tap(find.text('My bus'));
    await tester.pump(const Duration(milliseconds: 600));
    await back(tester);
    expect(find.text('Boarding code'), findsOneWidget);
    expect(calls, isEmpty);

    await back(tester);
    expect(calls, contains('SystemNavigator.pop'), reason: 'on the main tab back leaves the app');
    BusinToast.dismiss();
    await tester.pump();
  });

  testWidgets('someone without a subscription: the main tab is the subscription', (tester) async {
    final calls = await open(tester, FakeBackend(current: semester()));
    expect(find.text('Boarding code'), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 600));
    await back(tester);
    expect(find.textContaining('Subscribe for'), findsWidgets, reason: 'back returns to the subscription tab');
    expect(calls, isEmpty);

    await tester.tap(find.text('Code'));
    await tester.pump(const Duration(milliseconds: 600));
    await back(tester);
    expect(find.text('Boarding code'), findsNothing);
    expect(calls, isEmpty);

    await back(tester);
    expect(calls, contains('SystemNavigator.pop'));
  });

  testWidgets('a page above the tabs (the history) goes back to the profile first', (tester) async {
    final calls = await open(tester, FakeBackend(current: semester()));
    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Boarding history'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(BackButton), findsOneWidget);

    await back(tester);
    expect(find.text('Boarding history'), findsOneWidget, reason: 'the profile again, not another tab');
    expect(calls, isEmpty);
  });

  testWidgets('on a landscape tablet the profile sits at the bottom end of the rail, apart from the others', (tester) async {
    await open(tester, FakeBackend(current: semester()), size: const Size(1280, 800));
    final subscription = tester.getRect(find.text('Subscription').first);
    final code = tester.getRect(find.text('Code').first);
    final bus = tester.getRect(find.text('My bus').first);
    final profile = tester.getRect(find.text('Profile').first);

    expect(subscription.top, lessThan(code.top));
    expect(code.top, lessThan(bus.top));
    expect(profile.top, greaterThan(bus.top + 150), reason: 'a gap separates it from the rest');
    expect(profile.bottom, greaterThan(700), reason: 'near the bottom of the screen');
    expect(profile.center.dx, closeTo(bus.center.dx, 1), reason: 'in the same rail');
  });
}
