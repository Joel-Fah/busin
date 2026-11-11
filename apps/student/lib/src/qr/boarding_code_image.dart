import 'dart:math' as math;

import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// The modules of a QR code, as a grid of dark and light squares.
class QrGrid {
  QrGrid._(this.count, this._dark);

  /// Builds the grid for [data] at error correction level Q (enough for round dots to read well).
  factory QrGrid.of(String data) {
    final image = QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.Q));
    final n = image.moduleCount;
    return QrGrid._(n, [for (var r = 0; r < n; r++) [for (var c = 0; c < n; c++) image.isDark(r, c)]]);
  }

  /// Modules on a side.
  final int count;
  final List<List<bool>> _dark;

  bool isDark(int row, int col) => _dark[row][col];

  /// The three big squares in the corners that a scanner locks onto. They never change between codes.
  bool isFinder(int row, int col) {
    final n = count;
    final inRows = row < 7 || row >= n - 7;
    final inCols = col < 7 || col >= n - 7;
    return inRows && inCols && !(row >= n - 7 && col >= n - 7);
  }
}

/// How the dots move from one code to the next: the dots that differ shuffle for a moment (each starts a little after
/// its neighbours and flickers between on and off), then settle. The corner squares and every dot that stays the same
/// do not move, so it is a quick ripple across the code and not a flash. [t] is 0 to 1.
class ScrambleQrPainter extends CustomPainter {
  const ScrambleQrPainter({required this.from, required this.to, required this.t, required this.color});

  final QrGrid from;
  final QrGrid to;
  final double t;
  final Color color;

  /// Where in the transition a dot starts (0 to 0.55) and how long it shuffles for (0.3), from its place alone.
  static double delayOf(int row, int col) => (_hash(row * 131 + col * 7919) % 1000) / 1000 * 0.55;

  static int _hash(int x) {
    var h = x * 2654435761;
    h = (h ^ (h >> 15)) & 0x7fffffff;
    return h;
  }

  /// What a dot is drawn as at [t]: 0 for light, 1 for dark, in between while it is settling.
  static double dotAt(bool before, bool after, int row, int col, double t) {
    if (before == after) return after ? 1 : 0;
    final local = ((t - delayOf(row, col)) / 0.3).clamp(0.0, 1.0);
    if (local <= 0) return before ? 1 : 0;
    if (local >= 1) return after ? 1 : 0;
    // Shuffling: it flickers on and off a few times before settling.
    final step = (local * 6).floor();
    final flicker = _hash(row * 977 + col * 31 + step * 7001) % 2 == 0;
    return flicker ? 0.85 : 0.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = to.count;
    if (from.count != n) {
      return _paintStatic(canvas, size, to);
    }
    final cell = size.width / n;
    final paint = Paint()..color = color;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
        if (to.isFinder(r, c)) continue;
        final v = dotAt(from.isDark(r, c), to.isDark(r, c), r, c, t);
        if (v > 0) canvas.drawCircle(rect.center, cell * 0.47 * v, paint);
      }
    }
    paintFinders(canvas, cell, n, paint);
  }

  /// The three corner markers as rings with a dot in the middle: the same 1 : 1 : 3 : 1 : 1 rhythm a scanner looks for
  /// along any line through the centre, drawn round like the rest. They never change from one code to the next.
  static void paintFinders(Canvas canvas, double cell, int n, Paint fill) {
    final ring = Paint()
      ..color = fill.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell;
    for (final (row, col) in [(0, 0), (0, n - 7), (n - 7, 0)]) {
      final center = Offset((col + 3.5) * cell, (row + 3.5) * cell);
      canvas.drawCircle(center, cell * 3, ring);
      canvas.drawCircle(center, cell * 1.5, fill);
    }
  }

  void _paintStatic(Canvas canvas, Size size, QrGrid grid) {
    final n = grid.count;
    final cell = size.width / n;
    final paint = Paint()..color = color;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (!grid.isDark(r, c) || grid.isFinder(r, c)) continue;
        canvas.drawCircle(Rect.fromLTWH(c * cell, r * cell, cell, cell).center, cell * 0.47, paint);
      }
    }
    paintFinders(canvas, cell, n, paint);
  }

  @override
  bool shouldRepaint(ScrambleQrPainter old) => old.t != t || old.from != from || old.to != to || old.color != color;
}

/// The boarding code as a QR image: round dots in the brand's deep teal on white, in both themes (the contrast is
/// about 14 to 1, and scanners need a light ground). When the code changes the dots that differ shuffle and settle
/// (see [ScrambleQrPainter]); with reduced motion it just changes. Drawn by us so the new code is exactly what
/// [data] says, whatever the animation is doing.
class BoardingCodeImage extends StatefulWidget {
  const BoardingCodeImage({super.key, required this.data, required this.size});

  /// The code text, `busin2.<student>.<window>.<mac>`.
  final String data;
  final double size;

  /// The ink and the paper, the same in light and dark.
  static const ink = BusinRamps.seed;
  static const paper = Colors.white;

  /// How long the shuffle takes.
  static const transition = Duration(milliseconds: 650);

  @override
  State<BoardingCodeImage> createState() => _BoardingCodeImageState();
}

class _BoardingCodeImageState extends State<BoardingCodeImage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: BoardingCodeImage.transition);
  late QrGrid _to = QrGrid.of(widget.data);
  late QrGrid _from = _to;

  @override
  void initState() {
    super.initState();
    _controller.value = 1;
  }

  @override
  void didUpdateWidget(BoardingCodeImage old) {
    super.didUpdateWidget(old);
    if (old.data == widget.data) return;
    _from = _to;
    _to = QrGrid.of(widget.data);
    if (BusinMotion.reduced(context) || _from.count != _to.count) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: ScrambleQrPainter(from: _from, to: _to, t: math.min(1.0, _controller.value), color: BoardingCodeImage.ink),
        ),
      ),
    );
  }
}
