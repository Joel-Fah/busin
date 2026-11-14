import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import 'stop_distances.dart';

/// A sheet listing the school's stops with a search box. Returns the stop the person taps, or null. With the student's
/// [area] (ADR 0013, rounded to about 500 m), each stop says how far it is and the nearest is suggested first; nothing
/// is ever chosen for them. Without one, [onAddArea] offers to add it.
Future<Stop?> showStopPicker(BuildContext context, List<Stop> stops, {String? selectedId, GeoPoint? area, VoidCallback? onAddArea}) {
  return showBusinSheet<Stop>(
    context,
    isScrollControlled: true,
    builder: (_) => _StopPicker(stops: stops, selectedId: selectedId, area: area, onAddArea: onAddArea),
  );
}

class _StopPicker extends StatefulWidget {
  const _StopPicker({required this.stops, this.selectedId, this.area, this.onAddArea});

  final List<Stop> stops;
  final String? selectedId;
  final GeoPoint? area;
  final VoidCallback? onAddArea;

  @override
  State<_StopPicker> createState() => _StopPickerState();
}

class _StopPickerState extends State<_StopPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    final palette = BusinPalette.of(context);
    final needle = _query.trim().toLowerCase();
    final ranked = stopsWithDistance(widget.stops, widget.area);
    // The nearest is suggested above the list while nothing is searched; it is not repeated below.
    final closest = needle.isEmpty ? closestStop(ranked) : null;
    final shown = [
      for (final r in ranked)
        if ((needle.isEmpty || r.stop.name.toLowerCase().contains(needle)) && r.stop.id != closest?.stop.id) r,
    ];
    final km = NumberFormat('0.0', Localizations.localeOf(context).toLanguageTag());
    final text = Theme.of(context).textTheme;

    Widget tile(RankedStop r, {bool suggested = false}) {
      final stop = r.stop;
      final selected = stop.id == widget.selectedId;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x3, vertical: 2),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: selected ? palette.okBg : palette.surface2, borderRadius: BorderRadius.circular(BusinRadius.sm)),
            child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedFlag02, size: 20, color: selected ? palette.ok : palette.muted)),
          ),
          title: Text(stop.name, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          subtitle: r.km == null
              ? null
              : Wrap(
                  spacing: BusinSpace.x2,
                  runSpacing: BusinSpace.x1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(l10n.stopDistance(km.format(r.km)), style: text.bodySmall?.copyWith(color: palette.muted)),
                    if (suggested) StatusChip(label: l10n.stopClosest, tone: StatusTone.info),
                  ],
                ),
          trailing: selected ? HugeIcon(icon: HugeIcons.strokeRoundedTick02, color: palette.ok) : null,
          selected: selected,
          onTap: () => Navigator.of(context).pop(stop),
        ),
      );
    }

    Widget heading(String label) => Padding(
          padding: const EdgeInsets.fromLTRB(BusinSpace.x5, BusinSpace.x2, BusinSpace.x5, BusinSpace.x1),
          child: Text(label, style: text.labelLarge?.copyWith(color: palette.muted)),
        );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(BusinSpace.x4, 0, BusinSpace.x4, BusinSpace.x3),
                child: BusinTextField(
                  label: l10n.subscribeStopSearch,
                  icon: HugeIcons.strokeRoundedSearch01,
                  hint: l10n.subscribeStopSearch,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              if (widget.area == null && widget.onAddArea != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(BusinSpace.x4, 0, BusinSpace.x4, BusinSpace.x2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: widget.onAddArea,
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedHome01, size: 18),
                      label: Text(l10n.stopAddArea),
                    ),
                  ),
                ),
              Expanded(
                child: shown.isEmpty && closest == null
                    ? Center(child: Text(l10n.subscribeStopNone, style: TextStyle(color: palette.muted)))
                    : ListView(
                        children: [
                          if (closest != null) ...[
                            heading(l10n.stopSuggested),
                            tile(closest, suggested: true),
                            heading(l10n.stopAll),
                          ],
                          for (final r in shown) tile(r),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
