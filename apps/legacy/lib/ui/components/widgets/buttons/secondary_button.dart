// lib/ui/components/widgets/secondary_button.dart
import 'package:busin/utils/constants.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Color? borderColor;
  final Color? foregroundColor;
  final bool showDottedBorder;
  final Color dottedColor;
  final bool enableHaptics;
  final IconAlignment? iconAlignment;
  final double? borderWidth;

  // Content variants
  final Widget? child;
  final Widget? icon;
  final Widget? labelWidget;

  const SecondaryButton._({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.borderColor,
    this.foregroundColor,
    this.showDottedBorder = true,
    this.dottedColor = const Color(0xFFFEF8EC),
    this.child,
    this.icon,
    this.labelWidget,
    this.enableHaptics = true,
    this.iconAlignment,
    this.borderWidth,
  });

  factory SecondaryButton.label({
    Key? key,
    required String label,
    Color? borderColor,
    Color? foregroundColor,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    bool showDottedBorder = true,
    Color dottedColor = const Color(0xFFFEF8EC),
    bool enableHaptics = true,
    double? borderWidth,
  }) {
    return SecondaryButton._(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      borderColor: borderColor,
      foregroundColor: foregroundColor,
      showDottedBorder: showDottedBorder,
      dottedColor: dottedColor,
      child: Text(label),
      enableHaptics: enableHaptics,
      borderWidth: borderWidth,
    );
  }

  factory SecondaryButton.icon({
    Key? key,
    required Widget icon,
    required Widget label,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    Color? borderColor,
    Color? foregroundColor,
    bool showDottedBorder = true,
    Color dottedColor = const Color(0xFFFEF8EC),
    bool enableHaptics = true,
    IconAlignment iconAlignment = IconAlignment.start,
    double? borderWidth,
  }) {
    return SecondaryButton._(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      borderColor: borderColor,
      foregroundColor: foregroundColor,
      showDottedBorder: showDottedBorder,
      dottedColor: dottedColor,
      icon: icon,
      labelWidget: label,
      enableHaptics: enableHaptics,
      iconAlignment: iconAlignment,
      borderWidth: borderWidth,
    );
  }

  factory SecondaryButton.child({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    Color? borderColor,
    Color? foregroundColor,
    bool showDottedBorder = true,
    Color dottedColor = const Color(0xFFFEF8EC),
    bool enableHaptics = true,
    double? borderWidth,
  }) {
    return SecondaryButton._(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      borderColor: borderColor,
      foregroundColor: foregroundColor,
      showDottedBorder: showDottedBorder,
      dottedColor: dottedColor,
      child: child,
      enableHaptics: enableHaptics,
      borderWidth: borderWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      iconAlignment: iconAlignment,
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return foregroundColor?.withValues(alpha: 0.5) ??
                 accentColor.withValues(alpha: 0.5);
        }
        return foregroundColor ?? accentColor;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(
            color: borderColor?.withValues(alpha: 0.5) ??
                   accentColor.withValues(alpha: 0.5),
            width: borderWidth ?? 1.5,
          );
        }
        return BorderSide(
          color: borderColor ?? accentColor,
          width: borderWidth ?? 1.5,
        );
      }),
    );

    final wrappedOnPressed = _withHaptics(onPressed);
    final wrappedOnLongPress = _withHaptics(onLongPress);
    final btn = (icon != null && labelWidget != null)
        ? OutlinedButton.icon(
            onPressed: wrappedOnPressed,
            onLongPress: wrappedOnLongPress,
            style: style,
            icon: icon!,
            label: labelWidget!,
          )
        : OutlinedButton(
            onPressed: wrappedOnPressed,
            onLongPress: wrappedOnLongPress,
            style: style,
            child: child ?? const SizedBox.shrink(),
          );

    Widget content = SizedBox(height: 60.0, child: btn);

    if (showDottedBorder) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                    radius: Radius.circular(12),
                    dashPattern: const [2, 4, 6, 8],
                    strokeWidth: 1,
                    strokeCap: StrokeCap.round,
                    color: dottedColor,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return content;
  }

  VoidCallback? _withHaptics(VoidCallback? cb) {
    if (cb == null) return null;
    if (!enableHaptics) return cb;
    return () async {
      await HapticFeedback.lightImpact();
      cb();
    };
  }
}

