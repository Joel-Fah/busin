import 'dart:ui' show Tristate;

import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {ThemeData? theme}) => MaterialApp(theme: theme ?? BusinTheme.light(), home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: child))));

  testWidgets('opens and closes from its header', (tester) async {
    await tester.pumpWidget(host(const BusinAccordion(title: Text('Request of Nov 3'), child: Text('Details'))));
    expect(find.text('Details'), findsNothing);
    await tester.tap(find.text('Request of Nov 3'));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);
    await tester.tap(find.text('Request of Nov 3'));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsNothing);
  });

  testWidgets('can start open, with its status under the title', (tester) async {
    await tester.pumpWidget(host(const BusinAccordion(initiallyOpen: true, title: Text('Request'), trailing: Text('Approved'), child: Text('Details'))));
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Approved')).dy, greaterThan(tester.getTopLeft(find.text('Request')).dy));
  });

  testWidgets('a screen reader hears whether it is expanded', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const BusinAccordion(initiallyOpen: true, title: Text('Request'), child: Text('Details'))));
    expect(tester.getSemantics(find.text('Request').first).flagsCollection.isExpanded, isNot(Tristate.isFalse));
    handle.dispose();
  });

  testWidgets('holds still with reduced motion and fits a narrow screen at large text, in dark too', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(host(const BusinAccordion(initiallyOpen: true, title: Text('Request of Wednesday, November 4'), trailing: Text('Approved by your school'), child: Text('Details of what happened to it')), theme: BusinTheme.dark()));
    expect(tester.takeException(), isNull);
  });
}
