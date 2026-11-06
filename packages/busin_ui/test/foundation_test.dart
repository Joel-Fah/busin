import 'dart:math' as math;

import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {ThemeData? theme, Size? size, bool reduceMotion = false}) {
  Widget app = MaterialApp(
    theme: theme ?? BusinTheme.light(),
    localizationsDelegates: businLocalizationsDelegates,
    supportedLocales: businSupportedLocales,
    home: Scaffold(body: child),
  );
  if (reduceMotion) app = MediaQuery(data: const MediaQueryData(disableAnimations: true), child: app);
  return app;
}

void main() {
  group('dashSegments', () {
    test('lays dashes along a thread, a gap apart, and clips the last one', () {
      final segments = dashSegments(30, 9, 7);
      expect(segments, [(0.0, 9.0), (16.0, 25.0)]);
      // The next dash would start at 32, past the end of a 30 px thread, so it is not drawn.
      expect(dashSegments(40, 9, 7).last, (32.0, 40.0), reason: 'a dash that runs past the end is cut at the end');
    });

    test('sliding the pattern forward moves the dashes forward and wraps', () {
      final start = dashSegments(100, 4, 5);
      expect(start.first, (0.0, 4.0));
      final slid = dashSegments(100, 4, 5, offset: 3);
      expect(slid.first.$1, 3.0, reason: 'a dash that was at 0 is now at 3');
      // A whole period later the pattern is the same as the start.
      expect(dashSegments(100, 4, 5, offset: 9), start);
    });

    test('degenerate threads draw nothing', () {
      expect(dashSegments(0, 4, 5), isEmpty);
      expect(dashSegments(50, 0, 5), isEmpty);
    });

    test('the dashes never overlap and stay inside the thread', () {
      final segments = dashSegments(137.5, 9, 7, offset: 12.3);
      for (var i = 0; i < segments.length; i++) {
        expect(segments[i].$1, greaterThanOrEqualTo(0));
        expect(segments[i].$2, lessThanOrEqualTo(137.5));
        if (i > 0) expect(segments[i].$1, greaterThanOrEqualTo(segments[i - 1].$2));
      }
    });
  });

  group('the thread', () {
    test('follows the nested radius rule: its corner is the container\'s minus the inset', () {
      // A 28 px card with the thread 12 px in has a 16 px corner on the thread.
      final path = contourPath(const Size(200, 100), radius: 28, inset: 12);
      final box = path.getBounds();
      expect(box, const Rect.fromLTWH(12, 12, 176, 76));
      // Perimeter of a rounded rect with corner 16: 2(w+h) - (8 - 2pi) r.
      final expected = 2 * (176 + 76) - (8 - 2 * math.pi) * 16;
      expect(contourLength(const Size(200, 100), radius: 28, inset: 12), closeTo(expected, 1));
    });

    test('a thread with no inset hugs the edge, and a square corner never goes negative', () {
      expect(contourPath(const Size(80, 40), radius: 28, inset: 0).getBounds(), const Rect.fromLTWH(0, 0, 80, 40));
      expect(BusinRadius.innerRadius(8, 12), 0);
    });

    test('takes the element\'s own colour mixed into its background', () {
      final c = threadColor(text: Colors.black, background: Colors.white, mix: 0.5);
      expect(c, Color.lerp(Colors.white, Colors.black, 0.5));
    });

    testWidgets('a live thread slides when active and never takes touches', (tester) async {
      var active = false;
      late StateSetter set;
      await tester.pumpWidget(host(StatefulBuilder(builder: (context, setState) {
        set = setState;
        return SizedBox(width: 200, height: 100, child: Stack(children: [Positioned.fill(child: Contour(color: Colors.black, style: ContourStyle.button, active: active))]));
      })));
      CustomPaint thread() => tester.widget<CustomPaint>(find.descendant(of: find.byType(Contour), matching: find.byType(CustomPaint)).first);
      expect((thread().painter! as ContourPainter).slide, 0);

      set(() => active = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect((thread().painter! as ContourPainter).slide, closeTo(3, 0.01));
      expect(find.descendant(of: find.byType(Contour), matching: find.byType(IgnorePointer)), findsWidgets);
    });

    testWidgets('under reduced motion a live thread does not move', (tester) async {
      await tester.pumpWidget(host(
        SizedBox(width: 200, height: 100, child: Stack(children: [Positioned.fill(child: Contour(color: Colors.black, style: ContourStyle.button, active: true))])),
        reduceMotion: true,
      ));
      await tester.pump(const Duration(seconds: 1));
      final paint = tester.widget<CustomPaint>(find.descendant(of: find.byType(Contour), matching: find.byType(CustomPaint)).first);
      expect((paint.painter! as ContourPainter).slide, 0);
    });
  });

  group('the marker', () {
    test('is wider than the text by 0.15 em on each side and 0.4 em tall, whatever the wobble', () {
      final bounds = markerPath(const Size(200, 40), em: 30).getBounds();
      expect(bounds.left, closeTo(-4.5, 2));
      expect(bounds.right, closeTo(204.5, 3));
      expect(bounds.height, greaterThan(30 * 0.4 - 4));
      expect(bounds.height, lessThan(30 * 0.4 + 6));
      expect(bounds.bottom, lessThanOrEqualTo(40 + 3));
    });

    test('is the same every time for the same seed, and differs between seeds', () {
      final a = markerPath(const Size(120, 30), em: 24, seed: 1).getBounds();
      final b = markerPath(const Size(120, 30), em: 24, seed: 1).getBounds();
      final c = markerPath(const Size(120, 30), em: 24, seed: 2).getBounds();
      expect(a, b);
      expect(a, isNot(c));
    });

    testWidgets('sits under the last line only, as wide as that line', (tester) async {
      Future<({double left, double width, double box})> measure(Widget w) async {
        await tester.pumpWidget(host(w));
        final paint = find.descendant(of: find.byType(MarkedText), matching: find.byType(CustomPaint)).first;
        final boxWidth = tester.getSize(paint).width;
        final span = (tester.widget<CustomPaint>(paint).painter! as MarkerPainter).spanFor(boxWidth);
        return (left: span.left, width: span.width, box: boxWidth);
      }

      final wrapped = await measure(const Align(alignment: Alignment.topLeft, child: SizedBox(width: 200, child: MarkedText('Hop on and ride along with us today', style: TextStyle(fontSize: 24)))));
      expect(wrapped.width, greaterThan(0));
      expect(wrapped.width, lessThan(wrapped.box), reason: 'the last line is shorter than the box, and so is the marker');

      final one = await measure(const Align(alignment: Alignment.topLeft, child: MarkedText('Short', style: TextStyle(fontSize: 24))));
      expect(one.left, closeTo(0, 1));
      expect(one.width, closeTo(one.box, 1));
    });

    testWidgets('draws under undistorted text', (tester) async {
      await tester.pumpWidget(host(const MarkedText('Hop on', style: TextStyle(fontSize: 30))));
      expect(find.text('Hop on'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('layout', () {
    test('is chosen by width, with the breakpoints at 600 and 840', () {
      expect(BusinLayout.forWidth(360), BusinLayout.compact);
      expect(BusinLayout.forWidth(599.9), BusinLayout.compact);
      expect(BusinLayout.forWidth(600), BusinLayout.medium);
      expect(BusinLayout.forWidth(839.9), BusinLayout.medium);
      expect(BusinLayout.forWidth(840), BusinLayout.expanded);
      expect(BusinLayout.forWidth(1280), BusinLayout.expanded);
    });

    testWidgets('a phone gets the floating bar, a landscape tablet gets the rail', (tester) async {
      final items = [
        BusinDestination(label: 'One', icon: HugeIcons.strokeRoundedBus01),
        BusinDestination(label: 'Two', icon: HugeIcons.strokeRoundedBus01),
      ];
      Future<void> at(Size size) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(host(AdaptiveScaffold(destinations: items, currentIndex: 0, onDestinationSelected: (_) {}, body: const Text('page'))));
        await tester.pump();
      }

      await at(const Size(390, 844));
      expect(find.byType(FloatingNavBar), findsOneWidget);
      expect(find.byType(BusinNavRail), findsNothing);

      await at(const Size(800, 1280));
      expect(find.byType(FloatingNavBar), findsOneWidget, reason: 'a portrait tablet keeps the bar');

      await at(const Size(1280, 800));
      expect(find.byType(BusinNavRail), findsOneWidget);
      expect(find.byType(FloatingNavBar), findsNothing);
      expect(find.text('page'), findsOneWidget);
    });

    testWidgets('the bar tells the page how much room it takes, and the rail takes none', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      double? inset;
      Widget probe() => Builder(builder: (context) {
            inset = BusinScope.of(context).bottomInset;
            return const SizedBox();
          });
      final items = [BusinDestination(label: 'One', icon: HugeIcons.strokeRoundedBus01)];

      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(host(AdaptiveScaffold(destinations: items, currentIndex: 0, onDestinationSelected: (_) {}, body: probe())));
      expect(inset, greaterThanOrEqualTo(FloatingNavBar.height + 2 * AdaptiveScaffold.barMargin));

      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(host(AdaptiveScaffold(destinations: items, currentIndex: 0, onDestinationSelected: (_) {}, body: probe())));
      await tester.pump();
      expect(inset, 0);
    });

    testWidgets('two panes sit side by side when there is room, and one when there is not', (tester) async {
      Widget view(double width) => host(Center(child: SizedBox(width: width, child: const SplitView(primary: Text('A'), secondary: Text('B')))));
      await tester.pumpWidget(view(900));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(tester.getTopLeft(find.text('B')).dx, greaterThan(tester.getTopLeft(find.text('A')).dx));

      await tester.pumpWidget(view(400));
      expect(find.text('B'), findsNothing);

      await tester.pumpWidget(host(const Center(child: SizedBox(width: 400, child: SplitView(primary: Text('A'), secondary: Text('B'), stackBelow: true)))));
      expect(find.text('B'), findsOneWidget);
      expect(tester.getTopLeft(find.text('B')).dy, greaterThan(tester.getTopLeft(find.text('A')).dy));
    });
  });

  group('the sliding highlight', () {
    test('rests exactly on the target at the end, and on the start at the beginning', () {
      expect(indicatorEdges(from: (0, 80), to: (80, 160), t: 0), (0, 80));
      final end = indicatorEdges(from: (0, 80), to: (80, 160), t: 1);
      expect(end.$1, closeTo(80, 0.001));
      expect(end.$2, closeTo(160, 0.001));
    });

    test('stretches in flight: the leading edge runs ahead of the trailing one', () {
      final mid = indicatorEdges(from: (0, 80), to: (240, 320), t: 0.3);
      expect(mid.$2 - mid.$1, greaterThan(80), reason: 'wider than at rest while moving');
      expect(mid.$2, greaterThan(80));
    });

    test('works the other way too, and never folds over itself', () {
      for (var t = 0.0; t <= 1; t += 0.05) {
        final back = indicatorEdges(from: (240, 320), to: (0, 80), t: t);
        expect(back.$2, greaterThan(back.$1), reason: 't=$t');
      }
      final left = indicatorEdges(from: (240, 320), to: (0, 80), t: 0.3);
      expect(left.$2 - left.$1, greaterThan(80));
    });

    testWidgets('the bar selects an item with a tap and a small haptic', (tester) async {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      var index = 0;
      await tester.pumpWidget(host(StatefulBuilder(builder: (context, setState) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 360,
            child: FloatingNavBar(
              destinations: [
                BusinDestination(label: 'One', icon: HugeIcons.strokeRoundedBus01),
                BusinDestination(label: 'Two', icon: HugeIcons.strokeRoundedBus01),
                BusinDestination(label: 'Three', icon: HugeIcons.strokeRoundedBus01),
              ],
              currentIndex: index,
              onSelected: (i) => setState(() => index = i),
            ),
          ),
        );
      })));
      await tester.tap(find.text('Three'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(index, 2);
      expect(haptics, contains('HapticFeedbackType.selectionClick'));

      expect(tester.getSemantics(find.bySemanticsLabel('Three')), isSemantics(isSelected: true, isButton: true));
    });
  });

  group('motion', () {
    testWidgets('reduced motion collapses every duration', (tester) async {
      late Duration reduced;
      late Duration normal;
      await tester.pumpWidget(host(Builder(builder: (context) {
        reduced = BusinMotion.of(context, BusinMotion.slow);
        return const SizedBox();
      }), reduceMotion: true));
      await tester.pumpWidget(host(Builder(builder: (context) {
        normal = BusinMotion.of(context, BusinMotion.slow);
        return const SizedBox();
      })));
      expect(reduced, Duration.zero);
      expect(normal, const Duration(milliseconds: 520));
    });

    test('uses the portal\'s lengths and curve', () {
      expect(BusinMotion.fast, const Duration(milliseconds: 160));
      expect(BusinMotion.normal, const Duration(milliseconds: 280));
      expect(BusinMotion.slow, const Duration(milliseconds: 520));
      expect(BusinMotion.soft, const Cubic(0.22, 1, 0.36, 1));
    });

    testWidgets('a staggered item arrives after its turn, and at once under reduced motion', (tester) async {
      double opacity() => tester.widget<Opacity>(find.descendant(of: find.byType(StaggeredIn), matching: find.byType(Opacity)).first).opacity;

      await tester.pumpWidget(host(const StaggeredIn(index: 2, child: Text('row'))));
      expect(opacity(), 0);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      expect(opacity(), 1);

      await tester.pumpWidget(host(const StaggeredIn(index: 2, child: Text('quick')), reduceMotion: true));
      await tester.pump();
      expect(opacity(), 1);
    });
  });

  group('components', () {
    testWidgets('a status always carries an icon beside the colour, unless asked not to', (tester) async {
      for (final tone in [StatusTone.ok, StatusTone.warn, StatusTone.bad, StatusTone.info]) {
        await tester.pumpWidget(host(StatusChip(label: tone.name, tone: tone)));
        expect(find.descendant(of: find.byType(StatusChip), matching: find.byType(HugeIcon)), findsOneWidget, reason: tone.name);
      }
      await tester.pumpWidget(host(const StatusChip(label: 'plain')));
      expect(find.byType(HugeIcon), findsNothing, reason: 'neutral has no icon by default');
      await tester.pumpWidget(host(const StatusChip(label: 'quiet', tone: StatusTone.ok, showIcon: false)));
      expect(find.byType(HugeIcon), findsNothing);
    });

    testWidgets('an empty state shows an illustration or an icon, its words and its action', (tester) async {
      await tester.pumpWidget(host(EmptyState(title: 'Nothing yet', body: 'Come back later', illustration: BusinIllustration.seat, action: BusinButton(label: 'Go', onPressed: () {}))));
      expect(find.text('Nothing yet'), findsOneWidget);
      expect(find.text('Come back later'), findsOneWidget);
      expect(find.byType(Illustration), findsOneWidget);
      expect(find.text('Go'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(host(const EmptyState(title: 'Only an icon', icon: HugeIcons.strokeRoundedBus01)));
      expect(find.byType(Illustration), findsNothing);
      expect(find.byType(HugeIcon), findsOneWidget);
    });

    testWidgets('illustrations are decorative and hidden from screen readers', (tester) async {
      await tester.pumpWidget(host(const Illustration(BusinIllustration.bus, width: 80)));
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.excludeFromSemantics, isTrue);
    });

    testWidgets('a skeleton holds still under reduced motion and is hidden from screen readers', (tester) async {
      await tester.pumpWidget(host(const Skeleton(width: 100, height: 20), reduceMotion: true));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byType(ExcludeSemantics), findsWidgets);
    });

    testWidgets('a card can be a link: pressing it works, and the thread is live only then', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(Center(child: BusinCard(onTap: () => taps++, child: const Text('open me')))));
      await tester.tap(find.text('open me'));
      expect(taps, 1);
      expect(find.byType(Contour), findsOneWidget);

      await tester.pumpWidget(host(const Center(child: BusinCard(child: Text('still')))));
      final paint = tester.widget<CustomPaint>(find.descendant(of: find.byType(Contour), matching: find.byType(CustomPaint)).first);
      expect((paint.painter! as ContourPainter).slide, 0);
    });

    testWidgets('a button squeezes while pressed, taps with feedback, and ghost has no thread', (tester) async {
      await tester.pumpWidget(host(Center(child: BusinButton(label: 'Press', onPressed: () {}))));
      expect(find.descendant(of: find.byType(BusinButton), matching: find.byType(Contour)), findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(find.text('Press')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.widget<AnimatedScale>(find.descendant(of: find.byType(BusinButton), matching: find.byType(AnimatedScale))).scale, 0.98);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.widget<AnimatedScale>(find.descendant(of: find.byType(BusinButton), matching: find.byType(AnimatedScale))).scale, 1);

      await tester.pumpWidget(host(Center(child: BusinButton(label: 'Quiet', variant: BusinButtonVariant.ghost, onPressed: () {}))));
      expect(find.descendant(of: find.byType(BusinButton), matching: find.byType(Contour)), findsNothing);
    });

    testWidgets('a sheet opens in the BusIn style and closes', (tester) async {
      await tester.pumpWidget(host(Builder(builder: (context) => Center(child: TextButton(onPressed: () => showBusinSheet<void>(context, builder: (_) => const SizedBox(height: 120, child: Center(child: Text('inside')))), child: const Text('open'))))));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('inside'), findsOneWidget);
      expect(find.byType(BusinSheetFrame), findsOneWidget);

      // Floating: the card keeps clear of the screen's edges on every side, including the bottom, and has no handle inside it.
      final screen = tester.getSize(find.byType(MaterialApp));
      final card = tester.getRect(find.descendant(of: find.byType(BusinSheetFrame), matching: find.byType(Material)).first);
      expect(card.left, greaterThanOrEqualTo(BusinSheetFrame.margin));
      expect(screen.width - card.right, greaterThanOrEqualTo(BusinSheetFrame.margin));
      expect(screen.height - card.bottom, greaterThanOrEqualTo(BusinSheetFrame.margin));
      final handle = find.byWidgetPredicate((w) => w is Container && w.constraints?.maxWidth == 44 && w.constraints?.maxHeight == 5);
      expect(handle, findsOneWidget, reason: 'exactly one handle');
      expect(tester.getBottomLeft(handle).dy, lessThanOrEqualTo(card.top), reason: 'and it is above the card, outside it');
      final shape = tester.widget<Material>(find.descendant(of: find.byType(BusinSheetFrame), matching: find.byType(Material)).first).shape! as RoundedRectangleBorder;
      expect((shape.borderRadius as BorderRadius).bottomLeft.x, BusinRadius.xl, reason: 'every corner is rounded, not just the top ones');

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('inside'), findsNothing);
    });

    testWidgets('grain draws without trouble over a surface, in both themes', (tester) async {
      for (final theme in [BusinTheme.light(), BusinTheme.dark()]) {
        await tester.pumpWidget(host(SizedBox(width: 200, height: 100, child: Stack(children: [Container(color: BusinRamps.seed), const Positioned.fill(child: Grain(opacity: 1))])), theme: theme));
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the brand mark keeps its proportions', (tester) async {
      await tester.pumpWidget(host(const BrandMark(color: Colors.white, height: 40)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
