import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// A school's logo on a white plate, or a building icon on a square tile when it has none (or it cannot load). The logo
/// is the school's own: it keeps its shape (wide, tall or square), fitted in the plate's height ([size]) and up to two
/// and a half times as wide, never cropped or stretched.
class SchoolLogo extends StatelessWidget {
  const SchoolLogo({super.key, required this.url, this.size = 48});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final fallback = Center(child: HugeIcon(icon: HugeIcons.strokeRoundedBuilding03, size: size * 0.45, color: p.muted));
    final logo = url;
    final inner = size * 0.8;
    // The corners belong to the plate; the padding keeps the logo itself clear of them.
    return Container(
      constraints: BoxConstraints(minWidth: size, maxWidth: size * 2.5, minHeight: size, maxHeight: size),
      decoration: BoxDecoration(color: logo == null ? p.surface2 : Colors.white, borderRadius: BorderRadius.circular(BusinRadius.xs)),
      padding: EdgeInsets.all(size * 0.1),
      // As wide as the logo needs (a centre that sizes to its child), never wider than the plate allows.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: logo == null
            ? SizedBox(width: inner, height: inner, child: fallback)
            : Image.network(logo, height: inner, fit: BoxFit.contain, semanticLabel: '', errorBuilder: (_, _, _) => SizedBox(width: inner, height: inner, child: fallback)),
      ),
    );
  }
}
