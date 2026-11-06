import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host({bool reduced = false}) => MaterialApp(
      theme: BusinTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                for (final tone in ToastTone.values)
                  TextButton(onPressed: () => BusinToast.show(context, 'Message ${tone.name}', tone: tone, title: tone == ToastTone.error ? 'Title' : null), child: Text(tone.name)),
              ],
            ),
          ),
        ),
      ),
    );

void main() {
  test('good news leaves quickly, problems stay longer', () {
    expect(BusinToast.durationFor(ToastTone.success), lessThan(BusinToast.durationFor(ToastTone.info)));
    expect(BusinToast.durationFor(ToastTone.info), lessThan(BusinToast.durationFor(ToastTone.warning)));
    expect(BusinToast.durationFor(ToastTone.warning), lessThan(BusinToast.durationFor(ToastTone.error)));
  });

  testWidgets('shows a message, then removes it after its duration', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('success'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Message success'), findsOneWidget);
    await tester.pump(BusinToast.durationFor(ToastTone.success));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Message success'), findsNothing);
  });

  testWidgets('a new toast replaces the one showing, and a title is shown', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('info'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('error'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Message info'), findsNothing);
    expect(find.text('Message error'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    BusinToast.dismiss();
    await tester.pump();
  });

  testWidgets('a tap dismisses it', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('warning'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Message warning'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Message warning'), findsNothing);
  });

  testWidgets('is announced to screen readers and works with reduced motion', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(reduced: true));
    await tester.tap(find.text('error'));
    await tester.pump(const Duration(milliseconds: 50));
    final live = find.byWidgetPredicate((w) => w is Semantics && w.properties.liveRegion == true);
    expect(live, findsOneWidget);
    expect(tester.widget<Semantics>(live).properties.label, 'Title. Message error');
    BusinToast.dismiss();
    await tester.pump();
    handle.dispose();
  });
}
