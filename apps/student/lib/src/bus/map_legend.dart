import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';

import 'maplibre_surface.dart' show MapColors;

/// What the bus map shows, opened from its info button: each marker and line in its own colour, then how the tab works.
Future<void> showMapLegend(BuildContext context) {
  return showBusinSheet<void>(context, isScrollControlled: true, builder: (context) => const MapLegend());
}

class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final text = Theme.of(context).textTheme;
    Widget row(Widget swatch, String words) => Padding(
          padding: const EdgeInsets.symmetric(vertical: BusinSpace.x2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 36, height: 22, child: Center(child: swatch)),
              const SizedBox(width: BusinSpace.x3),
              Expanded(child: Text(words, style: text.bodyMedium)),
            ],
          ),
        );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(BusinSpace.x5, 0, BusinSpace.x5, BusinSpace.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.busLegendTitle, style: text.titleLarge),
            const SizedBox(height: BusinSpace.x3),
            row(const _Dot(MapColors.myStop, size: 16, ring: true), l10n.busLegendMyStop),
            row(const _Dot(MapColors.stop, size: 11), l10n.busLegendStop),
            row(const _Dot(MapColors.bus, size: 18, ring: true), l10n.busLegendBus),
            row(const _Dot(MapColors.me, size: 15), l10n.busLegendMe),
            row(const _Dot(MapColors.campus, size: 18), l10n.busLegendCampus),
            row(const _Line(MapColors.route), l10n.busLegendRoute),
            row(const _Line(MapColors.trail, dashed: true), l10n.busLegendTrail),
            const SizedBox(height: BusinSpace.x3),
            Notice(child: Text(l10n.busLegendHow)),
          ],
        ),
      ),
    );
  }
}

/// A marker as the map draws it: a filled circle with a white edge, and a soft ring for those that ping.
class _Dot extends StatelessWidget {
  const _Dot(this.hex, {required this.size, this.ring = false});

  final String hex;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final color = MapColors.of(hex);
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5), boxShadow: BusinElevation.float),
    );
    if (!ring) return dot;
    return Container(
      width: size + 10,
      height: size + 10,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.22), shape: BoxShape.circle),
      child: dot,
    );
  }
}

/// A short stretch of line, as the route (solid) or the trail (dashed).
class _Line extends StatelessWidget {
  const _Line(this.hex, {this.dashed = false});

  final String hex;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final color = MapColors.of(hex);
    if (!dashed) {
      return Container(width: 32, height: 4, decoration: BoxDecoration(color: color.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(2)));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Container(width: 5, height: 3, decoration: BoxDecoration(color: color.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(2))),
        ],
      ],
    );
  }
}
