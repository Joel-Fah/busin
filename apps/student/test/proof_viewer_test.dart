import 'dart:convert';

import 'package:busin_core/busin_core.dart';
import 'package:busin_student/src/app.dart';
import 'package:busin_student/src/subscription/proof_thumbnail.dart';
import 'package:busin_student/src/subscription/proof_viewer.dart';
import 'package:busin_student/src/subscription/subscription_providers.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

import 'support.dart';

/// A real, tiny picture, so the thumbnail has something to show (the network is not available in tests).
final photo = MemoryImage(base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='));

Widget host(Widget child) => MaterialApp(
      theme: BusinTheme.light(),
      localizationsDelegates: businLocalizationsDelegates,
      supportedLocales: businSupportedLocales,
      home: Scaffold(body: child),
    );

Future<void> load(WidgetTester tester) async {
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    await precacheImage(photo, context);
  });
  await tester.pump();
}

void main() {
  testWidgets('the thumbnail is as wide as its place and 160 high, and shows the open hint once the picture is there', (tester) async {
    await tester.pumpWidget(host(Padding(padding: const EdgeInsets.all(20), child: Column(children: [ProofThumbnail(image: photo)]))));
    await load(tester);
    final size = tester.getSize(find.byType(ProofThumbnail));
    expect(size.height, ProofThumbnail.height);
    expect(size.width, greaterThan(300));
    expect(find.byType(HugeIcon), findsOneWidget, reason: 'the expand hint');
  });

  testWidgets('tapping it opens the picture full screen, with zoom and a close button that returns', (tester) async {
    await tester.pumpWidget(host(Column(children: [ProofThumbnail(image: photo)])));
    await load(tester);
    await tester.tap(find.byType(ProofThumbnail));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).maxScale, greaterThan(1));

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.byType(ProofThumbnail), findsOneWidget);
  });

  testWidgets('the viewer can be opened on its own', (tester) async {
    await tester.pumpWidget(host(Builder(builder: (context) => TextButton(onPressed: () => showProofViewer(context, photo), child: const Text('Open')))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('on the subscription tab the sent proof is there to see, and to open', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          ...overridesFor(
            FakeAuthService(signedInAs: 'u1'),
            FakeProfileRepository({'u1': profile()}),
            backend: FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.pending, proofPath: 's1/u1/a.jpg')]),
          ),
          proofImageProvider.overrideWithValue((_) => photo),
        ],
        child: const StudentApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async => precacheImage(photo, tester.element(find.byType(Scaffold).first)));
    await tester.pump();

    expect(find.byType(ProofThumbnail), findsOneWidget);
    expect(tester.getSize(find.byType(ProofThumbnail)).height, ProofThumbnail.height, reason: 'it has its size: the card was showing nothing');

    await tester.tap(find.byType(ProofThumbnail));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('when the proof cannot be loaded a tile says so instead of the proof vanishing, and tapping it tries again', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend(current: semester(), mine: [subscription(stopId: 'stop2', status: SubscriptionStatus.approved, proofPath: 's1/u1/a.jpg')])..proofError = const Offline('x');
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          ...overridesFor(FakeAuthService(signedInAs: 'u1'), FakeProfileRepository({'u1': profile()}), backend: backend),
          proofImageProvider.overrideWithValue((_) => photo),
        ],
        child: const StudentApp(),
      ),
    );
    await tester.pumpAndSettle();
    // An approved student opens on the code; the proof is on the subscription tab.
    await tester.tap(find.text('Subscription'));
    await tester.pumpAndSettle();
    expect(find.byType(ProofThumbnail), findsNothing);
    expect(find.text('Your payment proof'), findsOneWidget);
    expect(find.text('It could not be loaded. Tap to try again.'), findsOneWidget);

    backend.proofError = null;
    await tester.tap(find.text('Your payment proof'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async => precacheImage(photo, tester.element(find.byType(Scaffold).first)));
    await tester.pump();
    expect(find.byType(ProofThumbnail), findsOneWidget);
    expect(find.text('Your payment proof'), findsNothing);
  });
}
