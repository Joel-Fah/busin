// lib/ui/components/widgets/primary_button.dart
import 'package:busin/utils/constants.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Color? bgColor;
  final bool showDottedBorder;
  final Color dottedColor;
  final bool enableHaptics;
  final IconAlignment? iconAlignment;

  // Content variants
  final Widget? child;
  final Widget? icon;
  final Widget? labelWidget;

  const PrimaryButton._({
    super.key,
    required this.onPressed,
    this.onLongPress,
    this.bgColor,
    this.showDottedBorder = true,
    this.dottedColor = const Color(0xFFFEF8EC),
    this.child,
    this.icon,
    this.labelWidget,
    this.enableHaptics = true,
    this.iconAlignment,
  });

  factory PrimaryButton.label({
    Key? key,
    required String label,
    Color? labelColor,
    Color? bgColor,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    bool showDottedBorder = true,
    Color dottedColor = const Color(0xFFFEF8EC),
    bool enableHaptics = true,
  }) {
    return PrimaryButton._(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      bgColor: bgColor,
      showDottedBorder: showDottedBorder,
      dottedColor: dottedColor,
      child: Text(label),
      enableHaptics: enableHaptics,
    );
  }

  factory PrimaryButton.icon({
    Key? key,
    required Widget icon,
    required Widget label,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    Color? bgColor,
    bool showDottedBorder = true,
    Color dottedColor = const Color(0xFFFEF8EC),
    bool enableHaptics = true,
    IconAlignment iconAlignment = IconAlignment.start,
  }) {
    return PrimaryButton._(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      bgColor: bgColor,
      showDottedBorder: showDottedBorder,
      dottedColor: dottedColor,
      icon: icon,
      labelWidget: label,
      enableHaptics: enableHaptics,
      iconAlignment: iconAlignment,
    );
  }

  factory PrimaryButton.child({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    Color? bgColor,
    bool showDottedBorder = true,
    Color dottedColor = const Color(0xFFFEF8EC),
    bool enableHaptics = true,
  }) {
    return PrimaryButton._(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      bgColor: bgColor,
      showDottedBorder: showDottedBorder,
      dottedColor: dottedColor,
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
          return bgColor?.withValues(alpha: 0.5) ?? accentColor.withValues(alpha: 0.5);
        }
        return bgColor ?? accentColor;
      }),
    );

    final wrappedOnPressed = _withHaptics(onPressed);
    final wrappedOnLongPress = _withHaptics(onLongPress);
    final btn = (icon != null && labelWidget != null)
        ? ElevatedButton.icon(
      onPressed: wrappedOnPressed,
      onLongPress: wrappedOnLongPress,
      style: style,
      icon: icon!,
      label: labelWidget!,
    )
        : ElevatedButton(
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
