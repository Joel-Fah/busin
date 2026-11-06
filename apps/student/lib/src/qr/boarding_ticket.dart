import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';

import 'boarding_code_image.dart';

/// The boarding pass: a teal ticket with grain and the stitched thread, the code on a white sticker, a perforation
/// with a notch on each side, and the student's name below. The "live" pill pulses so the code feels alive without a
/// countdown. When the code changes the sticker gives a small pulse (and the phone a tick).
class BoardingTicket extends StatefulWidget {
  const BoardingTicket({super.key, required this.code, required this.name, this.matricule, required this.size, required this.liveLabel, required this.imageLabel});

  final String code;
  final String name;
  final String? matricule;

  /// The side of the QR image.
  final double size;
  final String liveLabel;
  final String imageLabel;

  @override
  State<BoardingTicket> createState() => _BoardingTicketState();
}

class _BoardingTicketState extends State<BoardingTicket> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: BusinMotion.slow);
  late final AnimationController _live = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  bool _started = false;

  /// The live dot glows a few times when the code appears or changes, then rests (no endless animation).
  void _breathe() => _live.repeat(reverse: true, count: 6);

  @override
  void initState() {
    super.initState();
    _pulse.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (BusinMotion.reduced(context)) {
      _live.stop();
    } else if (!_started) {
      _started = true;
      _breathe();
    }
  }

  @override
  void didUpdateWidget(BoardingTicket old) {
    super.didUpdateWidget(old);
    if (old.code != widget.code) {
      BusinHaptics.selection();
      if (!BusinMotion.reduced(context)) {
        _pulse.forward(from: 0);
        _breathe();
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    const radius = BorderRadius.all(Radius.circular(BusinRadius.xl));
    const notch = 16.0;

    return DecoratedBox(
      decoration: const BoxDecoration(borderRadius: radius, boxShadow: BusinElevation.float),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [BusinRamps.seed, Color(0xFF0A4452)]),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: Grain(opacity: 1)),
              Positioned.fill(child: Contour(color: BannerInk.thread, style: const ContourStyle(radius: BusinRadius.xl, inset: 8, dash: 9, gap: 7))),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(BusinSpace.x6, BusinSpace.x6, BusinSpace.x6, BusinSpace.x4),
                    child: Row(
                      children: [
                        const BrandMark(color: Colors.white, height: 26),
                        const Spacer(),
                        _LivePill(label: widget.liveLabel, animation: _live),
                      ],
                    ),
                  ),
                  Center(
                    child: Semantics(
                      image: true,
                      label: widget.imageLabel,
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, child) {
                          // A quick dip and return when the code changes.
                          final t = Curves.easeOutBack.transform(_pulse.value);
                          return Transform.scale(scale: 0.94 + 0.06 * t, child: child);
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(BusinRadius.lg)),
                          child: Padding(
                            padding: const EdgeInsets.all(BusinSpace.x5),
                            child: ExcludeSemantics(child: BoardingCodeImage(key: const ValueKey('boarding-code'), data: widget.code, size: widget.size)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: BusinSpace.x5),
                  // The perforation, with a bite out of each side in the page's colour.
                  SizedBox(
                    height: notch * 2,
                    child: Row(
                      children: [
                        CustomPaint(size: const Size(notch, notch * 2), painter: _NotchPainter(color: p.bg, left: true)),
                        const Expanded(child: _Perforation()),
                        CustomPaint(size: const Size(notch, notch * 2), painter: _NotchPainter(color: p.bg, left: false)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(BusinSpace.x6, BusinSpace.x2, BusinSpace.x6, BusinSpace.x6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name, style: text.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                        if (widget.matricule != null) ...[
                          const SizedBox(height: BusinSpace.x1),
                          Text(widget.matricule!, style: text.titleMedium?.copyWith(color: BannerInk.soft, letterSpacing: 1.2)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.label, required this.animation});

  final String label;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(BusinRadius.xs)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x3, vertical: BusinSpace.x1 + 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BusinPalette.orange,
                  boxShadow: [BoxShadow(color: BusinPalette.orange.withValues(alpha: 0.6 * (1 - animation.value)), blurRadius: 6, spreadRadius: 4 * animation.value)],
                ),
              ),
            ),
            const SizedBox(width: BusinSpace.x2),
            Text(label, style: text.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _NotchPainter extends CustomPainter {
  const _NotchPainter({required this.color, required this.left});

  final Color color;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    canvas.drawCircle(Offset(left ? 0 : size.width, r), r, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_NotchPainter old) => old.color != color || old.left != left;
}

class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _PerforationPainter(color: Colors.white.withValues(alpha: 0.35)));
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (double x = 4; x < size.width - 4; x += 12) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), paint);
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter old) => old.color != color;
}
