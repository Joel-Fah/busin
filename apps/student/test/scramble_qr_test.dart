import 'package:busin_student/src/qr/boarding_code_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const a = 'busin1.00000000-0000-0000-0000-000000000001.58000000.AbCdEfGhIjKlMnOpQrStUvWxYz012345';
  const b = 'busin1.00000000-0000-0000-0000-000000000001.58000001.ZyXwVuTsRqPoNmLkJiHgFeDcBa543210';

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
