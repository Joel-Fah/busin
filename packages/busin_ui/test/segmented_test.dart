import 'dart:ui' show Tristate;

import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {ThemeData? theme}) => MaterialApp(theme: theme ?? BusinTheme.light(), home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)));

  const segments = [
    BusinSegment(value: 1, label: 'System'),
    BusinSegment(value: 2, label: 'Light'),
    BusinSegment(value: 3, label: 'Dark'),
  ];

  testWidgets('shows every choice and reports the one tapped', (tester) async {
    var chosen = 1;
    await tester.pumpWidget(host(StatefulBuilder(builder: (context, set) => BusinSegmented<int>(groupLabel: 'Theme', segments: segments, selected: chosen, onChanged: (v) => set(() => chosen = v)))));
    for (final label in ['System', 'Light', 'Dark']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(chosen, 3);
  });

  testWidgets('the chosen choice is bold and the others quiet, in light and dark', (tester) async {
    for (final theme in [BusinTheme.light(), BusinTheme.dark()]) {
      await tester.pumpWidget(host(BusinSegmented<int>(groupLabel: 'Theme', segments: segments, selected: 2, onChanged: (_) {}), theme: theme));
      expect(tester.widget<Text>(find.text('Light')).style?.fontWeight, FontWeight.w800);
      expect(tester.widget<Text>(find.text('Dark')).style?.fontWeight, FontWeight.w600);
    }
  });

  testWidgets('a screen reader hears a group with one choice selected', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(BusinSegmented<int>(groupLabel: 'Theme', segments: segments, selected: 2, onChanged: (_) {})));
    final light = tester.getSemantics(find.bySemanticsLabel('Light'));
    expect(light.flagsCollection.isSelected, Tristate.isTrue);
    expect(light.flagsCollection.isButton, isTrue);
    expect(light.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    expect(tester.getSemantics(find.bySemanticsLabel('Dark')).flagsCollection.isSelected, Tristate.isFalse);
    expect(find.bySemanticsLabel('Theme'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('every choice is a comfortable tap target, also with long words at large text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(host(BusinSegmented<int>(groupLabel: 'Langue', segments: const [BusinSegment(value: 1, label: 'Système'), BusinSegment(value: 2, label: 'English'), BusinSegment(value: 3, label: 'Français')], selected: 1, onChanged: (_) {})));
    expect(tester.takeException(), isNull);
    for (final label in ['Système', 'English', 'Français']) {
      expect(tester.getSize(find.ancestor(of: find.text(label), matching: find.byType(ConstrainedBox)).first).height, greaterThanOrEqualTo(44));
    }
  });
}
