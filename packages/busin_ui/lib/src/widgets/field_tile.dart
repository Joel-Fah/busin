import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../painters/contour.dart';
import '../tokens/palette.dart';
import '../tokens/shape.dart';
import 'haptics.dart';

/// A form field you tap to fill in with something that is not typing (a stop, a photo): a threaded tile with the field's
/// icon in a tinted square, its label above the chosen value (or a prompt when there is none), and an arrow. The thread
/// slides when you press it. An optional [preview] (a photo) sits under the words inside the same tile.
class FieldTile extends StatefulWidget {
  const FieldTile({super.key, required this.label, required this.icon, required this.placeholder, this.value, this.onTap, this.preview, this.errorText});

  final String label;
  final List<List<dynamic>> icon;

  /// Shown when nothing is chosen yet.
  final String placeholder;
  final String? value;

  /// Null makes it inert and dimmed (while loading or sending).
  final VoidCallback? onTap;
  final Widget? preview;
  final String? errorText;

  @override
  State<FieldTile> createState() => _FieldTileState();
}

class _FieldTileState extends State<FieldTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final text = Theme.of(context).textTheme;
    final chosen = widget.value != null;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(BusinRadius.md));
    final border = widget.errorText != null ? p.bad : p.line;

    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: '${widget.label}. ${widget.value ?? widget.placeholder}${widget.errorText != null ? '. ${widget.errorText}' : ''}',
      excludeSemantics: true,
      onTap: widget.onTap,
      child: Opacity(
        opacity: widget.onTap == null ? 0.6 : 1,
        child: Material(
          color: p.surface,
          shape: shape.copyWith(side: BorderSide(color: border)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              InkWell(
                customBorder: shape,
                onTap: widget.onTap == null
                    ? null
                    : () {
                        BusinHaptics.light();
                        widget.onTap!();
                      },
                onHighlightChanged: (down) => setState(() => _pressed = down),
                child: Padding(
                  padding: const EdgeInsets.all(BusinSpace.x4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: chosen ? p.okBg : p.surface2, borderRadius: BorderRadius.circular(BusinRadius.sm)),
                            child: Center(child: HugeIcon(icon: widget.icon, size: 22, color: chosen ? p.ok : p.muted)),
                          ),
                          const SizedBox(width: BusinSpace.x3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.label, style: text.labelMedium?.copyWith(color: p.muted)),
                                const SizedBox(height: 2),
                                Text(widget.value ?? widget.placeholder, style: text.bodyLarge?.copyWith(color: chosen ? p.fg : p.muted, fontWeight: chosen ? FontWeight.w600 : FontWeight.w400)),
                              ],
                            ),
                          ),
                          HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 20, color: p.muted),
                        ],
                      ),
                      if (widget.preview != null) ...[
                        const SizedBox(height: BusinSpace.x3),
                        ClipRRect(borderRadius: BorderRadius.circular(BusinRadius.xs), child: widget.preview!),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned.fill(child: Contour(color: threadColor(text: p.fg, background: p.surface, mix: 0.16), style: const ContourStyle(radius: 20, inset: 4, dash: 4, gap: 5, live: true), active: _pressed)),
            ],
          ),
        ),
      ),
    );
  }
}
