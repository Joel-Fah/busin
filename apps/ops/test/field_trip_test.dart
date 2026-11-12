import 'package:busin_core/busin_core.dart';
import 'package:busin_ops/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<void> settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> open(WidgetTester tester, FakeTrips trips) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: overridesFor(auth: FakeAuth(signedInAs: 'u1'), profiles: {'u1': staff()}, trips: trips, positions: FakePositions(), live: FakeLive()),
    child: const OpsApp(),
  ));
  await settle(tester);
}

void main() {
  testWidgets('a trip nobody scheduled is started as the assistant, with the driver picked, and opens marked (ADR 0020)', (tester) async {
    final trips = FakeTrips([]);
    await open(tester, trips);
    expect(find.text('Start a trip that is not listed'), findsOneWidget, reason: 'the button is there even when the list is empty');

    await tester.tap(find.text('Start a trip that is not listed'));
    await settle(tester);
    expect(find.text('Start a trip'), findsOneWidget);
    expect(find.text('Start the trip'), findsOneWidget);

    await tester.tap(find.text('Express'));
    await tester.tap(find.text('Going home').evaluate().isNotEmpty ? find.text('Going home') : find.text('Outbound'));
    await tester.tap(find.text('The assistant'));
    await settle(tester);
    expect(find.text('Who is the driver?'), findsOneWidget, reason: 'the question follows the role');
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await settle(tester);
    await tester.tap(find.text('Dina Driver').last);
    await settle(tester);
    await tester.tap(find.text('Start the trip'));
    await settle(tester);

    final request = trips.fieldStarts.single;
    expect(request.busId, 'b2');
    expect(request.role, CrewRole.assistant);
    expect(request.otherId, 'u2');
    expect(find.text('Started in the field'), findsOneWidget, reason: 'the trip opens with its mark');
    expect(find.text('Sharing the bus position'), findsOneWidget, reason: 'and sharing is offered at once');
  });

  testWidgets('each refusal is explained and the sheet stays open', (tester) async {
    final trips = FakeTrips([])..fieldError = const Conflict('database 55000', reason: 'use_scheduled_trip');
    await open(tester, trips);
    await tester.tap(find.text('Start a trip that is not listed'));
    await settle(tester);
    await tester.tap(find.text('B1'));
    await settle(tester);
    await tester.tap(find.text('Start the trip'));
    await settle(tester);
    expect(find.text('A trip for this bus and direction is already scheduled today. Start that one from the list.'), findsOneWidget);
    expect(find.text('Start the trip'), findsOneWidget, reason: 'the sheet is still open to change the choices');
    expect(trips.fieldStarts, isEmpty);
  });

  testWidgets('the button is not there when the school has turned field trips off', (tester) async {
    final trips = FakeTrips([])..fieldOptions = const FieldTripOptions(allowed: false);
    await open(tester, trips);
    expect(find.text('Start a trip that is not listed'), findsNothing);
  });
}
