import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// A sheet listing the school's stops with a search box. Returns the stop the person taps, or null.
Future<Stop?> showStopPicker(BuildContext context, List<Stop> stops, {String? selectedId}) {
  return showBusinSheet<Stop>(
    context,
    isScrollControlled: true,
    builder: (_) => _StopPicker(stops: stops, selectedId: selectedId),
  );
}

class _StopPicker extends StatefulWidget {
  const _StopPicker({required this.stops, this.selectedId});

  final List<Stop> stops;
  final String? selectedId;

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
    final shown = needle.isEmpty ? widget.stops : widget.stops.where((s) => s.name.toLowerCase().contains(needle)).toList();

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
              Expanded(
                child: shown.isEmpty
                    ? Center(child: Text(l10n.subscribeStopNone, style: TextStyle(color: palette.muted)))
                    : ListView.builder(
                        itemCount: shown.length,
                        itemBuilder: (context, index) {
                          final stop = shown[index];
                          final selected = stop.id == widget.selectedId;
                          return ListTile(
                            title: Text(stop.name),
                            trailing: selected ? HugeIcon(icon: HugeIcons.strokeRoundedTick02, color: palette.ok) : null,
                            selected: selected,
                            onTap: () => Navigator.of(context).pop(stop),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
