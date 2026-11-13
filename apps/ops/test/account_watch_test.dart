import 'dart:async';

import 'package:busin_core/busin_core.dart';
import 'package:busin_ops/src/app.dart';
import 'package:busin_ops/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('an administrator suspending the account takes effect while the app is open', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final profiles = FakeProfiles({'u1': staff()});
    final rosters = FakeRosterStore();
    await tester.pumpWidget(ProviderScope(
      overrides: overridesFor(auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, profileRepository: profiles, trips: FakeTrips([trip('t1', driver: 'u1')]), rosters: rosters),
      child: const OpsApp(),
    ));
    await settle(tester);
    expect(find.text("Today's trips"), findsOneWidget, reason: 'a verified staff member is in');
    final readsBefore = profiles.reads;

    // The school suspends the account; the server reports the change.
    profiles.byId['u1'] = staff(status: AccountStatus.suspended);
    profiles.changes.add(profiles.byId['u1']!);
    await settle(tester);

    expect(profiles.reads, greaterThan(readsBefore), reason: 'the app looked again');
    expect(find.text('Your account is suspended'), findsOneWidget, reason: 'and now shows it, without a restart');
    expect(find.text("Today's trips"), findsNothing);
    expect(rosters.clears, greaterThan(0), reason: 'the day keys that check codes offline are removed');
  });

  testWidgets('a change that does not touch access does not reload the app', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final profiles = FakeProfiles({'u1': staff()});
    await tester.pumpWidget(ProviderScope(
      overrides: overridesFor(auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, profileRepository: profiles, trips: FakeTrips([trip('t1', driver: 'u1')])),
      child: const OpsApp(),
    ));
    await settle(tester);
    // Only the phone number changed: it asks, finds nothing new, and the screen stays as it is.
    profiles.changes.add(staff());
    await settle(tester);
    expect(find.text("Today's trips"), findsOneWidget);
  });

  testWidgets('reloading the profile in the background keeps the screen', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final profiles = FakeProfiles({'u1': staff()});
    await tester.pumpWidget(ProviderScope(
      overrides: overridesFor(auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, profileRepository: profiles, trips: FakeTrips([trip('t1', driver: 'u1')])),
      child: const OpsApp(),
    ));
    await settle(tester);
    expect(find.text("Today's trips"), findsOneWidget);

    // The backend is unreachable: the reload hangs, and the list stays.
    profiles.hold = Completer<void>();
    ProviderScope.containerOf(tester.element(find.byType(OpsApp))).invalidate(profileProvider);
    await settle(tester, 3);
    expect(find.text("Today's trips"), findsOneWidget, reason: 'the profile in hand is kept while it reloads');
    profiles.hold!.complete();
    await settle(tester);
    expect(find.text("Today's trips"), findsOneWidget);
  });
}
