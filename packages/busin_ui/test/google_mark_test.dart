import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the sign-in button can carry Google\'s own mark before its label, silent for screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: BusinTheme.light(),
      home: Scaffold(body: Center(child: BusinButton(label: 'Continue with Google', leading: const GoogleMark(), onPressed: () {}))),
    ));
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.getTopLeft(find.byType(GoogleMark)).dx, lessThan(tester.getTopLeft(find.text('Continue with Google')).dx));
    expect(find.bySemanticsLabel('Continue with Google'), findsOneWidget, reason: 'the label is what is read');
    semantics.dispose();
  });
}
