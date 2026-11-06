import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../painters/contour.dart';
import '../tokens/palette.dart';
import '../tokens/shape.dart';
import 'haptics.dart';

enum BusinButtonVariant {
  /// The main action of a screen, in the brand orange.
  primary,

  /// A calm alternative.
  secondary,

  /// A destructive action (sign out, cancel, suspend), in the danger colours.
  danger,

  /// A quiet action with no fill.
  ghost,
}

/// A button with an optional leading icon and a busy state. While [loading] the button cannot be
/// pressed again and says so to screen readers. Pass a null [onPressed] to disable it.
/// The portal's button, on a phone: a 16 px corner, a stitched thread that slides when you press it, a small press
/// squeeze (0.98) and a light tap of feedback. Ghost buttons have no fill and no thread.
class BusinButton extends StatefulWidget {
  const BusinButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BusinButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final BusinButtonVariant variant;
  final List<List<dynamic>>? icon;

  /// Shows progress and ignores presses.
  final bool loading;

  /// Fill the width of the parent.
  final bool expand;

  @override
  State<BusinButton> createState() => _BusinButtonState();
}

class _BusinButtonState extends State<BusinButton> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final (Color fill, Color ink) = switch (widget.variant) {
      BusinButtonVariant.primary => (p.accent, p.onAccent),
      BusinButtonVariant.secondary => (p.surface2, p.fg),
      BusinButtonVariant.danger => (p.badBg, p.bad),
      BusinButtonVariant.ghost => (Colors.transparent, p.fg),
    };
    final ghost = widget.variant == BusinButtonVariant.ghost;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(BusinRadius.sm));
    // The thread takes the button's own text colour mixed into its own fill, so it is tonal and never shifts.
    final thread = threadColor(text: ink, background: ghost ? p.surface : fill, mix: widget.variant == BusinButtonVariant.primary ? 0.38 : 0.28);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x5),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.loading)
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: ink))
          else if (widget.icon != null)
            HugeIcon(icon: widget.icon!, size: 18, color: ink),
          if (widget.loading || widget.icon != null) const SizedBox(width: BusinSpace.x2),
          Flexible(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              // A little heavier than body text, so a button reads as a button on a small, bright screen.
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: ink),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      excludeSemantics: true,
      label: widget.label,
      child: AnimatedScale(
        scale: _pressed && _enabled ? 0.98 : 1,
        duration: BusinMotion.of(context, BusinMotion.fast),
        curve: BusinMotion.soft,
        child: Opacity(
          opacity: widget.onPressed == null && !widget.loading ? 0.5 : 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 48, minWidth: widget.expand ? double.infinity : 64),
            child: Material(
              color: fill,
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  InkWell(
                    customBorder: shape,
                    onTap: _enabled
                        ? () {
                            BusinHaptics.light();
                            widget.onPressed!();
                          }
                        : null,
                    onHighlightChanged: (down) => setState(() => _pressed = down),
                    onFocusChange: (focus) => setState(() => _focused = focus),
                    child: Center(widthFactor: widget.expand ? null : 1, heightFactor: 1, child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: content)),
                  ),
                  if (!ghost) Positioned.fill(child: Contour(color: thread, style: ContourStyle.button, active: _pressed || _focused)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
