import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {bool reduceMotion = false}) {
  Widget app = MaterialApp(home: Scaffold(backgroundColor: BusinRamps.seed, body: Center(child: child)));
  if (reduceMotion) app = MediaQuery(data: const MediaQueryData(disableAnimations: true), child: app);
  return app;
}

void main() {
  const n = 5;

  group('the timeline', () {
    test('starts empty, with nothing drawn and nothing filled', () {
      final frame = introFrame(0, n);
      expect(frame.stroke, everyElement(0));
      expect(frame.fill, 0);
      expect(frame.strokeOpacity, 1);
    });

    test('draws each outline a tenth of a second after the one before', () {
      final frame = introFrame(0.6, n);
      for (var i = 1; i < n; i++) {
        expect(frame.stroke[i], lessThanOrEqualTo(frame.stroke[i - 1]), reason: 'outline $i starts later than outline ${i - 1}');
      }
      expect(frame.stroke.first, greaterThan(0));
      expect(frame.stroke.last, lessThan(frame.stroke.first));
    });

    test('has drawn every outline completely when the last one ends', () {
      final frame = introFrame(IntroTiming.drawEnd(n), n);
      expect(frame.stroke, everyElement(closeTo(1, 1e-3)));
    });

    test('fills in while the outline fades, starting a quarter second before the last outline ends', () {
      expect(introFrame(IntroTiming.fillStart(n) - 0.01, n).fill, 0);
      final middle = introFrame(IntroTiming.fillStart(n) + 0.3, n);
      expect(middle.fill, inExclusiveRange(0, 1));
      expect(middle.strokeOpacity, inExclusiveRange(0, 1));
      final end = introFrame(IntroTiming.fillStart(n) + IntroTiming.fillDuration, n);
      expect(end.fill, closeTo(1, 1e-3));
      expect(end.strokeOpacity, closeTo(0, 1e-3));
    });

    test('adds up to about two and three quarter seconds, with a short hold on the finished mark', () {
      expect(IntroTiming.total(n), closeTo(2.78, 0.01));
      final held = introFrame(IntroTiming.total(n), n);
      expect(held.fill, 1);
    });

    test('never goes outside 0 to 1', () {
      for (var t = -1.0; t < 5; t += 0.05) {
        final f = introFrame(t, n);
        for (final s in f.stroke) {
          expect(s, inInclusiveRange(0, 1));
        }
        expect(f.fill, inInclusiveRange(0, 1));
        expect(f.strokeOpacity, inInclusiveRange(0, 1));
      }
    });
  });

  group('the logo data', () {
    test('is the portal\'s wordmark: five shapes in a 205 by 126 box', () {
      expect(brandPaths, hasLength(5));
      expect(brandWidth, 205);
      expect(brandHeight, 126);
      expect(brandPaths.every((p) => p.d.startsWith('M')), isTrue);
    });
  });

  group('the widget', () {
    testWidgets('takes the size it is given and keeps the logo\'s proportions', (tester) async {
      await tester.pumpWidget(host(BrandIntro(color: Colors.white, width: 144, onDone: () {})));
      final size = tester.getSize(find.descendant(of: find.byType(BrandIntro), matching: find.byType(CustomPaint)).first);
      expect(size.width, 144);
      expect(size.height, closeTo(144 * 126 / 205, 0.01));
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('plays through and reports it is done once, about when the timeline says', (tester) async {
      var done = 0;
      await tester.pumpWidget(host(BrandIntro(color: Colors.white, onDone: () => done++)));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(done, 0);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(done, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(done, 1, reason: 'only once');
    });

    testWidgets('tapping skips ahead quickly', (tester) async {
      var done = 0;
      await tester.pumpWidget(host(BrandIntro(color: Colors.white, onDone: () => done++)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byType(BrandIntro));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 700));
      expect(done, 1);
    });

    testWidgets('under reduced motion it shows the finished mark, does not move, and moves on after half a second', (tester) async {
      var done = 0;
      await tester.pumpWidget(host(BrandIntro(color: Colors.white, onDone: () => done++), reduceMotion: true));
      BrandIntroPainter painter() => tester.widget<CustomPaint>(find.descendant(of: find.byType(BrandIntro), matching: find.byType(CustomPaint)).first).painter! as BrandIntroPainter;
      expect(painter().frame.fill, closeTo(1, 1e-3));
      expect(painter().frame.strokeOpacity, closeTo(0, 1e-3));
      expect(done, 0);
      await tester.pump(const Duration(milliseconds: 600));
      expect(done, 1);
      expect(painter().frame.fill, closeTo(1, 1e-3), reason: 'it never animated');
    });

    testWidgets('is decorative: hidden from screen readers', (tester) async {
      await tester.pumpWidget(host(BrandIntro(color: Colors.white, onDone: () {})));
      expect(find.descendant(of: find.byType(BrandIntro), matching: find.byType(ExcludeSemantics)), findsWidgets);
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
