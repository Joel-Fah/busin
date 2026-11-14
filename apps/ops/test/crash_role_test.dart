import 'package:busin_app/busin_app.dart';
import 'package:busin_core/busin_core.dart';
import 'package:busin_ops/src/app.dart';
import 'package:busin_ops/src/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

class _Roles implements CrashReporter {
  final roles = <String?>[];

  @override
  Future<void> setRole(String? role) async => roles.add(role);
}

void main() {
  testWidgets('crash reports learn the role once access is granted, and nothing else about the person', (tester) async {
    final crashes = _Roles();
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...overridesFor(auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff(role: UserRole.admin)}, trips: FakeTrips([])),
        crashReporterProvider.overrideWithValue(crashes),
      ],
      child: const OpsApp(),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(crashes.roles, ['admin']);
  });
}
