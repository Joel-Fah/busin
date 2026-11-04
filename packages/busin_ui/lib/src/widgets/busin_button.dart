import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../tokens/palette.dart';
import '../tokens/shape.dart';

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
class BusinButton extends StatelessWidget {
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
  final bool loading;

  /// Fill the width of the parent.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = BusinPalette.of(context);
    final (Color fill, Color ink) = switch (variant) {
      BusinButtonVariant.primary => (p.accent, p.onAccent),
      BusinButtonVariant.secondary => (p.surface2, p.fg),
      BusinButtonVariant.danger => (p.badBg, p.bad),
      BusinButtonVariant.ghost => (Colors.transparent, p.fg),
    };

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: ink),
          )
        else if (icon != null)
          HugeIcon(icon: icon!, size: 18, color: ink),
        if (loading || icon != null) const SizedBox(width: BusinSpace.x2),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    return Semantics(
      button: true,
      enabled: onPressed != null && !loading,
      child: TextButton(
        onPressed: loading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: fill,
          foregroundColor: ink,
          disabledBackgroundColor: fill.withValues(alpha: 0.5),
          disabledForegroundColor: ink.withValues(alpha: 0.6),
          minimumSize: Size(expand ? double.infinity : 64, 48),
          padding: const EdgeInsets.symmetric(horizontal: BusinSpace.x5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BusinRadius.sm)),
        ),
        child: child,
      ),
    );
  }
}
