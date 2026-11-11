import 'package:busin_student/src/qr/boarding_code_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const a = 'busin2.00000000-0000-0000-0000-000000000001.58000000.AbCdEfGhIjKlMnOpQrStUvWxYz012345';
  const b = 'busin2.00000000-0000-0000-0000-000000000001.58000001.ZyXwVuTsRqPoNmLkJiHgFeDcBa543210';

  test('two codes of the same length make grids of the same size', () {
    expect(QrGrid.of(a).count, QrGrid.of(b).count);
  });

  test('the three corner squares are finders, the fourth corner is not', () {
    final grid = QrGrid.of(a);
    final n = grid.count;
    expect(grid.isFinder(0, 0), isTrue);
    expect(grid.isFinder(0, n - 1), isTrue);
    expect(grid.isFinder(n - 1, 0), isTrue);
    expect(grid.isFinder(n - 1, n - 1), isFalse);
    expect(grid.isFinder(n ~/ 2, n ~/ 2), isFalse);
  });

  test('the corner markers are rings with a dot, not squares', () {
    final canvas = _Recorder();
    const n = 29;
    const cell = 10.0;
    ScrambleQrPainter.paintFinders(canvas, cell, n, Paint()..color = Colors.black);

    // Per corner: a stroked ring one module thick and a filled dot three modules across.
    expect(canvas.circles.length, 6);
    final rings = canvas.circles.where((c) => c.paint.style == PaintingStyle.stroke).toList();
    final dots = canvas.circles.where((c) => c.paint.style == PaintingStyle.fill).toList();
    expect(rings.length, 3);
    expect(dots.length, 3);
    for (final ring in rings) {
      expect(ring.radius, cell * 3);
      expect(ring.paint.strokeWidth, cell);
    }
    for (final dot in dots) {
      expect(dot.radius, cell * 1.5);
    }
    expect({for (final r in rings) r.center}, {const Offset(35, 35), const Offset(35 + 22 * cell, 35), const Offset(35, 35 + 22 * cell)});
    expect(canvas.otherShapes, 0, reason: 'no squares');
  });

  test('every code has its finder squares drawn the same way', () {
    final x = QrGrid.of(a), y = QrGrid.of(b);
    for (var r = 0; r < 7; r++) {
      for (var c = 0; c < 7; c++) {
        expect(x.isDark(r, c), y.isDark(r, c));
      }
    }
  });

  group('a dot in the transition', () {
    test('that does not change never moves', () {
      for (final t in [0.0, 0.3, 0.7, 1.0]) {
        expect(ScrambleQrPainter.dotAt(true, true, 5, 5, t), 1);
        expect(ScrambleQrPainter.dotAt(false, false, 5, 5, t), 0);
      }
    });

    test('that changes starts as the old one and ends as the new one', () {
      expect(ScrambleQrPainter.dotAt(true, false, 9, 4, 0), 1);
      expect(ScrambleQrPainter.dotAt(false, true, 9, 4, 0), 0);
      expect(ScrambleQrPainter.dotAt(true, false, 9, 4, 1), 0);
      expect(ScrambleQrPainter.dotAt(false, true, 9, 4, 1), 1);
    });

    test('every dot has settled well before the end, so the new code is steady at the finish', () {
      for (var r = 0; r < 60; r++) {
        for (var c = 0; c < 60; c++) {
          expect(ScrambleQrPainter.delayOf(r, c) + 0.3, lessThanOrEqualTo(0.85 + 1e-9));
        }
      }
    });

    test('shuffles in between (not simply fading)', () {
      final seen = <double>{};
      for (var t = 0.0; t <= 1.0; t += 0.02) {
        seen.add(ScrambleQrPainter.dotAt(true, false, 12, 3, t));
      }
      expect(seen.length, greaterThan(1));
      expect(seen.every((v) => v == 0 || v == 1 || v == 0.85), isTrue);
    });
  });
}

class _Circle {
  _Circle(this.center, this.radius, this.paint);
  final Offset center;
  final double radius;
  final Paint paint;
}

/// A canvas that only remembers what was drawn.
class _Recorder implements Canvas {
  final circles = <_Circle>[];
  int otherShapes = 0;

  @override
  void drawCircle(Offset c, double radius, Paint paint) => circles.add(_Circle(c, radius, paint));

  @override
  void drawRect(Rect rect, Paint paint) => otherShapes++;

  @override
  void drawRRect(RRect rrect, Paint paint) => otherShapes++;

  @override
  void drawPath(Path path, Paint paint) => otherShapes++;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
