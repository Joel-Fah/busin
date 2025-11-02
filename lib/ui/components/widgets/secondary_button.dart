import 'package:busin/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Color? bgColor;
  final bool enableHaptics;
  final IconAlignment? iconAlignment;

  // Content variants
  final Widget? child;
  final Widget? icon;
  final Widget? labelWidget;

  const SecondaryButton._({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.bgColor,
    this.child,
    this.icon,
    this.labelWidget,
    this.enableHaptics = true,
    this.iconAlignment,
  });

  factory SecondaryButton.label({
    Key? key,
    required String label,
    Color? labelColor,
    Color? bgColor,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    bool enableHaptics = true,
  }) {
    return SecondaryButton._(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      bgColor: bgColor,
      child: Text(label),
      enableHaptics: enableHaptics,
    );
  }

  factory SecondaryButton.icon({
    Key? key,
    required Widget icon,
    required Widget label,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    Color? bgColor,
    bool enableHaptics = true,
    IconAlignment iconAlignment = IconAlignment.start,
  }) {
    return SecondaryButton._(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      bgColor: bgColor,
      icon: icon,
      labelWidget: label,
      enableHaptics: enableHaptics,
      iconAlignment: iconAlignment,
    );
  }

  factory SecondaryButton.child({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    Color? bgColor,
    bool enableHaptics = true,
  }) {
    return SecondaryButton._(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      bgColor: bgColor,
      child: child,
      enableHaptics: enableHaptics,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      iconAlignment: iconAlignment,
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return (bgColor ?? Colors.transparent).withValues(alpha: 0.5);
        }
        return bgColor ?? Colors.transparent;
      }),
      overlayColor: WidgetStatePropertyAll<Color>(accentColor.withValues(alpha: 0.1)),
    );

    final wrappedOnPressed = _withHaptics(onPressed);
    final wrappedOnLongPress = _withHaptics(onLongPress);

    final btn = (icon != null && labelWidget != null)
        ? TextButton.icon(
            onPressed: wrappedOnPressed,
            onLongPress: wrappedOnLongPress,
            style: style,
            icon: icon!,
            label: labelWidget!,
          )
        : TextButton(
            onPressed: wrappedOnPressed,
            onLongPress: wrappedOnLongPress,
            style: style,
            child: child ?? const SizedBox.shrink(),
          );

    return SizedBox(height: 60, child: btn);
  }

  VoidCallback? _withHaptics(VoidCallback? cb) {
    if (cb == null) return null;
    if (!enableHaptics) return cb;
    return () async {
      await HapticFeedback.selectionClick();
      cb();
    };
  }
}

