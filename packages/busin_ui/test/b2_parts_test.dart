import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

Widget host(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme ?? BusinTheme.light(),
      localizationsDelegates: businLocalizationsDelegates,
      supportedLocales: businSupportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('BusinBanner', () {
    testWidgets('shows its words, always on the teal, in light and dark', (tester) async {
      for (final theme in [BusinTheme.light(), BusinTheme.dark()]) {
        await tester.pumpWidget(host(const BusinBanner(eyebrow: 'Today', title: 'Good morning, Joel', body: 'Subscribe for Fall 2026', art: BusinIllustration.ticket), theme: theme));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Good morning, Joel'), findsOneWidget);
        expect(find.text('Subscribe for Fall 2026'), findsOneWidget);
        expect(find.byType(Illustration), findsOneWidget);
        final color = tester.widget<ColoredBox>(find.descendant(of: find.byType(BusinBanner), matching: find.byType(ColoredBox)).first).color;
        expect(color, BusinRamps.seed);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('is at least its minimum height and grows with long words', (tester) async {
      await tester.pumpWidget(host(const BusinBanner(title: 'Hi', minHeight: 188)));
      expect(tester.getSize(find.byType(BusinBanner)).height, greaterThanOrEqualTo(188));
      await tester.pumpWidget(host(BusinBanner(title: 'A very long headline that needs several lines to be said in full on a narrow screen', body: List.filled(8, 'More words.').join(' '))));
      expect(tester.getSize(find.byType(BusinBanner)).height, greaterThan(188));
      expect(tester.takeException(), isNull);
    });
  });

  group('StepLine', () {
    Future<void> show(WidgetTester tester, {required int current, bool failed = false}) => tester.pumpWidget(
          host(Padding(padding: const EdgeInsets.all(16), child: StepLine(labels: const ['Sent', 'Checking', 'Decision'], current: current, failed: failed, stepSemantics: (n, t, l) => 'Step $n of $t: $l'))),
        );

    testWidgets('ticks the stages before the current one and rings the current one', (tester) async {
      await show(tester, current: 1);
      expect(find.byType(HugeIcon), findsNWidgets(2), reason: 'a tick for Sent and a clock for Checking; the last stage is quiet');
      for (final label in ['Sent', 'Checking', 'Decision']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('a rejection ends in a cross and does not claim the decision was good', (tester) async {
      await show(tester, current: 2, failed: true);
      expect(find.byType(HugeIcon), findsNWidgets(3), reason: 'two ticks and a cross');
    });

    testWidgets('everything done shows three ticks', (tester) async {
      await show(tester, current: 3);
      expect(find.byType(HugeIcon), findsNWidgets(3));
    });

    testWidgets('says each stage aloud with its place in the line', (tester) async {
      await show(tester, current: 1);
      expect(find.bySemanticsLabel('Step 2 of 3: Checking'), findsOneWidget);
      expect(find.bySemanticsLabel('Step 1 of 3: Sent'), findsOneWidget);
    });

    testWidgets('fits a very narrow screen at large text', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await show(tester, current: 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('FieldTile', () {
    testWidgets('shows the prompt, then the chosen value, and taps with a small haptic', (tester) async {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      var taps = 0;
      await tester.pumpWidget(host(FieldTile(label: 'Your stop', icon: HugeIcons.strokeRoundedFlag02, placeholder: 'Choose where you board', onTap: () => taps++)));
      expect(find.text('Choose where you board'), findsOneWidget);
      await tester.tap(find.text('Your stop'));
      expect(taps, 1);
      expect(haptics, contains('HapticFeedbackType.lightImpact'));

      await tester.pumpWidget(host(FieldTile(label: 'Your stop', icon: HugeIcons.strokeRoundedFlag02, placeholder: 'Choose where you board', value: 'Mvan', onTap: () {})));
      expect(find.text('Mvan'), findsOneWidget);
      expect(find.text('Choose where you board'), findsNothing);
    });

    testWidgets('without a tap handler it is inert and dimmed, and says so to a screen reader', (tester) async {
      await tester.pumpWidget(host(const FieldTile(label: 'Your stop', icon: HugeIcons.strokeRoundedFlag02, placeholder: 'Choose')));
      expect(tester.widget<Opacity>(find.descendant(of: find.byType(FieldTile), matching: find.byType(Opacity)).first).opacity, lessThan(1));
      expect(tester.getSemantics(find.bySemanticsLabel(RegExp('Your stop'))), isSemantics(isButton: true, isEnabled: false));
    });

    testWidgets('reads its label, value and error together', (tester) async {
      await tester.pumpWidget(host(FieldTile(label: 'Your stop', icon: HugeIcons.strokeRoundedFlag02, placeholder: 'Choose', value: 'Mvan', errorText: 'Required', onTap: () {})));
      expect(find.bySemanticsLabel('Your stop. Mvan. Required'), findsOneWidget);
    });

    testWidgets('shows a preview inside the tile', (tester) async {
      await tester.pumpWidget(host(FieldTile(label: 'Proof', icon: HugeIcons.strokeRoundedReceiptText, placeholder: 'Add', value: 'Photo added', preview: const SizedBox(key: ValueKey('preview'), height: 40, width: 40), onTap: () {})));
      expect(find.byKey(const ValueKey('preview')), findsOneWidget);
    });
  });

  group('Notice', () {
    testWidgets('every tone has an icon and its words, and only an error is announced', (tester) async {
      for (final tone in StatusTone.values) {
        await tester.pumpWidget(host(Notice(tone: tone, title: 'Title', child: const Text('Body'))));
        expect(find.byType(HugeIcon), findsOneWidget, reason: tone.name);
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Body'), findsOneWidget);
      }
      await tester.pumpWidget(host(const Notice(tone: StatusTone.bad, child: Text('Oops'))));
      expect(tester.getSemantics(find.text('Oops')), isNotNull);
    });
  });
}
