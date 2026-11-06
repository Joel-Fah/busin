import 'package:busin_student/src/subscription/proof_viewer.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens full screen with a way to zoom and a close button that returns', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BusinTheme.light(),
        localizationsDelegates: businLocalizationsDelegates,
        supportedLocales: businSupportedLocales,
        home: Builder(builder: (context) => Scaffold(body: TextButton(onPressed: () => showProofViewer(context, 'http://localhost/proof.jpg'), child: const Text('Open')))),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    expect(viewer.maxScale, greaterThan(1));

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });
}
