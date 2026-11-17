import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:busin_ops/src/app.dart';

import 'support.dart';

/// The app keeps animating (the scanner, the clock), so frames are pumped instead of waiting for it to settle.
Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a staff member asks for the deletion of their account from the profile (ADR 0028)', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: overridesFor(auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, trips: FakeTrips([])),
      child: const OpsApp(),
    ));
    await settle(tester);
    await tester.tap(find.byTooltip('Profile and settings'));
    await settle(tester);
    await tester.scrollUntilVisible(find.widgetWithText(BusinButton, 'Delete my account'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.widgetWithText(BusinButton, 'Delete my account'));
    await settle(tester);
    expect(find.textContaining('the trips you drove'), findsOneWidget);
    await tester.tap(find.text('Delete in 7 days'));
    await settle(tester);
    expect(find.textContaining('Your account will be deleted on'), findsOneWidget);
    BusinToast.dismiss();
    await settle(tester);
  });
}
