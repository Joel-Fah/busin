import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// One thing in a [showChoiceSheet] list.
class Choice {
  const Choice({required this.id, required this.title, this.subtitle});

  final String id;
  final String title;

  /// A short code or note shown under the title.
  final String? subtitle;
}

/// Wrapping a result so "nothing" (cleared) can be told apart from the sheet being dismissed.
class ChoiceResult {
  const ChoiceResult(this.id);

  final String? id;
}

/// A sheet with a short list to pick from (a faculty, a department, a degree level). Returns the choice, a result with a
/// null id when the person clears it (only offered with [clearLabel]), or null if the sheet is dismissed.
Future<ChoiceResult?> showChoiceSheet(
  BuildContext context, {
  required String title,
  required List<Choice> choices,
  String? selectedId,
  String? clearLabel,
}) {
  return showBusinSheet<ChoiceResult>(
    context,
    isScrollControlled: true,
    builder: (context) {
      final p = BusinPalette.of(context);
      final text = Theme.of(context).textTheme;
      Widget row({required String label, String? note, required bool selected, required VoidCallback onTap, List<List<dynamic>>? icon}) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x3, vertical: 2),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: selected ? p.okBg : p.surface2, borderRadius: BorderRadius.circular(BusinRadius.sm)),
              child: Center(child: HugeIcon(icon: icon ?? HugeIcons.strokeRoundedBuilding03, size: 20, color: selected ? p.ok : p.muted)),
            ),
            title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
            subtitle: note == null ? null : Text(note, style: TextStyle(color: p.muted)),
            trailing: selected ? HugeIcon(icon: HugeIcons.strokeRoundedTick02, color: p.ok) : null,
            selected: selected,
            onTap: onTap,
          ),
        );
      }

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(BusinSpace.x5, 0, BusinSpace.x5, BusinSpace.x3),
                child: Text(title, style: text.titleLarge),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (clearLabel != null)
                      row(
                        label: clearLabel,
                        selected: selectedId == null,
                        icon: HugeIcons.strokeRoundedCancel01,
                        onTap: () => Navigator.of(context).pop(const ChoiceResult(null)),
                      ),
                    for (final c in choices)
                      row(label: c.title, note: c.subtitle, selected: c.id == selectedId, onTap: () => Navigator.of(context).pop(ChoiceResult(c.id))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
