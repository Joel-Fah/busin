import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// A school's logo on a white tile, or a building icon when it has none (or it cannot load).
class SchoolLogo extends StatelessWidget {
  const SchoolLogo({super.key, required this.url, this.size = 48});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final fallback = Center(child: HugeIcon(icon: HugeIcons.strokeRoundedBuilding03, size: size * 0.45, color: p.muted));
    final logo = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(BusinRadius.xs),
      child: Container(
        width: size,
        height: size,
        color: logo == null ? p.surface2 : Colors.white,
        padding: EdgeInsets.all(size * 0.1),
        child: logo == null ? fallback : Image.network(logo, fit: BoxFit.contain, semanticLabel: '', errorBuilder: (_, _, _) => fallback),
      ),
    );
  }
}
