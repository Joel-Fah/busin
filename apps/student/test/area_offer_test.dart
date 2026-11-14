import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

// My area is offered once (ADR 0023): right after setup, or by a card for a student who never added it.

Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> open(WidgetTester tester, {required FakeProfileRepository profiles, required SharedPreferences prefs, FakeBackend? backend, FakeAreas? areas}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [
      ...overridesFor(FakeAuthService(signedInAs: 'u1'), profiles, backend: backend ?? FakeBackend(current: semester()), areas: areas),
      appPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const StudentApp(),
  ));
  await settle(tester);
}

Future<SharedPreferences> prefsWith([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  testWidgets('right after setup, My area is offered once, and "Not now" goes on to the subscription tab', (tester) async {
    final prefs = await prefsWith();
    final profiles = FakeProfileRepository({'u1': profile(complete: false)});
    await open(tester, profiles: profiles, prefs: prefs);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'ICT2026-0457');
    await tester.enterText(fields.at(2), '+237 677 12 34 56');
    await tester.tap(find.text('Save and continue'));
    await settle(tester);

    expect(find.text('One more thing: where do you live?'), findsOneWidget);
    expect(find.text('Are you home right now?'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await settle(tester);
    expect(find.text('Send request'), findsOneWidget, reason: 'on to the subscription tab');
    expect(find.text('Add your area'), findsNothing, reason: 'offered once is enough: no card after the invitation');

    // Opening the app again goes straight on.
    await open(tester, profiles: profiles, prefs: prefs);
    expect(find.text('One more thing: where do you live?'), findsNothing);
    expect(find.text('Send request'), findsOneWidget);
  });

  testWidgets('a student who never added an area gets one card on the subscription tab, until they answer', (tester) async {
    final prefs = await prefsWith();
    final profiles = FakeProfileRepository({'u1': profile()});
    await open(tester, profiles: profiles, prefs: prefs);
    expect(find.text('Add your area'), findsOneWidget);
    expect(find.text('One more thing: where do you live?'), findsNothing, reason: 'an existing student is not taken away from the app');

    await tester.scrollUntilVisible(find.text('Not now'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Not now'));
    await settle(tester);
    expect(find.text('Add your area'), findsNothing);
    expect(prefs.getBool('area.offered.u1'), isTrue);
  });

  testWidgets('the card opens My area', (tester) async {
    final prefs = await prefsWith();
    await open(tester, profiles: FakeProfileRepository({'u1': profile()}), prefs: prefs);
    await tester.scrollUntilVisible(find.text('Add my area'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Add my area'));
    await settle(tester);
    expect(find.text('Are you home right now?'), findsOneWidget);
  });

  testWidgets('a student who already has an area is never asked', (tester) async {
    final prefs = await prefsWith();
    final areas = FakeAreas(area: StudentArea(label: 'Bastos', lat: 3.86, lng: 11.52, source: AreaSource.device, updatedAt: DateTime.utc(2026, 11, 1)));
    await open(tester, profiles: FakeProfileRepository({'u1': profile()}), prefs: prefs, areas: areas);
    expect(find.text('Add your area'), findsNothing);
    BusinToast.dismiss();
  });
}
