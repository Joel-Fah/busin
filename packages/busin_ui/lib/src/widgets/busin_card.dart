import 'package:flutter/material.dart';

import '../painters/contour.dart';
import '../painters/grain.dart';
import '../tokens/elevation.dart';
import '../tokens/palette.dart';
import '../tokens/shape.dart';

/// A raised surface, the portal's card: 28 px corner, soft shadow, and the stitched thread inside it (still, because
/// a card is not interactive). Pass [onTap] to make it a link: the thread then slides when it is pressed. [grain] adds
/// fine noise for feature cards and banners, never for cards that hold forms or small text.
class BusinCard extends StatefulWidget {
  const BusinCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BusinSpace.x6),
    this.radius = BusinRadius.lg,
    this.contour = true,
    this.grain = false,
    this.color,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;

  /// Keep it larger than the thread's inset (12) so content sits clear of the stitching.
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool contour;
  final bool grain;

  /// The surface colour; the palette's surface by default.
  final Color? color;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<BusinCard> createState() => _BusinCardState();
}

class _BusinCardState extends State<BusinCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final surface = widget.color ?? p.surface;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.radius));
    final style = ContourStyle(
      radius: widget.radius,
      inset: ContourStyle.card.inset,
      dash: ContourStyle.card.dash,
      gap: ContourStyle.card.gap,
      live: widget.onTap != null,
    );

    Widget card = DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(widget.radius), boxShadow: BusinElevation.soft(Theme.of(context).brightness)),
      child: Material(
        color: surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (widget.grain) const Positioned.fill(child: Grain(opacity: 0.8)),
            InkWell(
              customBorder: shape,
              onTap: widget.onTap,
              onHighlightChanged: widget.onTap == null ? null : (down) => setState(() => _pressed = down),
              child: Padding(padding: widget.padding, child: widget.child),
            ),
            if (widget.contour)
              Positioned.fill(child: Contour(color: threadColor(text: p.fg, background: surface, mix: 0.16), style: style, active: _pressed)),
          ],
        ),
      ),
    );

    if (widget.semanticLabel != null) card = Semantics(container: true, label: widget.semanticLabel, child: card);
    return card;
  }
}
