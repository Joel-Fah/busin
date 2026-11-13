import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme ?? BusinTheme.light(),
      localizationsDelegates: businLocalizationsDelegates,
      supportedLocales: businSupportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: SizedBox(width: 360, child: child))),
    );

void main() {
  testWidgets('the charts draw in both themes, with gaps and empty data, and speak their summary', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final theme in [BusinTheme.light(), BusinTheme.dark()]) {
      await tester.pumpWidget(app(
        Column(children: [
          BusinBarChart(
            bars: [
              for (var i = 0; i < 12; i++) ChartBar(label: 'W$i', segments: [i.toDouble(), (i % 3).toDouble()]),
            ],
            colors: const [Colors.green, Colors.orange],
            semanticLabel: 'Trips per week',
          ),
          BusinLineChart(
            points: const [0.5, null, 0.75, 1, null, null, 0.9],
            labels: const ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
            color: Colors.teal,
            format: (v) => '${(v * 100).round()}%',
            target: 0.9,
            semanticLabel: 'On time per week',
          ),
          const BusinBarChart(bars: [], colors: [Colors.green], semanticLabel: 'Nothing yet'),
          BusinLineChart(points: const [null, null], labels: const ['a', 'b'], color: Colors.teal, format: (v) => '$v', semanticLabel: 'No line'),
          const ChartLegend(items: [(color: Colors.green, label: 'On time'), (color: Colors.orange, label: 'Late')]),
        ]),
        theme: theme,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.bySemanticsLabel('Trips per week'), findsOneWidget);
    expect(find.bySemanticsLabel('On time per week'), findsOneWidget);
    expect(find.text('Late'), findsOneWidget, reason: 'every colour has its label');
    semantics.dispose();
  });
}
